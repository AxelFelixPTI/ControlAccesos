-- =============================================================================
-- SP_CAF_SOLICITUD_CORREO_ALL.sql   (2026-11-19, D-252, Entrega 2C-3b)
-- Correos de una solicitud: lista de envíos con su resultado y reenvío manual.
--   0. ERP_CAF_FN_SOLICITUD_CORREO_ESTADO  resumen del último envío (lo usan Mis solicitudes, la Bandeja y el Detalle)
--   1. ERP_CAF_SOLICITUD_CORREOS_LISTAR   quien puede ver la solicitud ve sus correos (sin el cuerpo)
--   2. ERP_CAF_SOLICITUD_CORREO_REENVIAR  encola un aviso con el estado ACTUAL de la solicitud
-- Schema: TRIANONSATELITAL_CAF_PRODD. Requiere 37_ALTER_CORREO_REENVIO.sql.
-- HANA: RETURNS TABLE pasa a procedimiento con parámetro de salida; REGEXP_REPLACE/SUBSTR_REGEXPR en lugar de
--       regexp_split_to_table (T-54); sin sobrecargas.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 0. ERP_CAF_FN_SOLICITUD_CORREO_ESTADO
--    Cómo le fue al ÚLTIMO correo de la solicitud: '<ESTADO>:<A|M>' donde ESTADO = ENVIADO, ERROR o PENDIENTE y
--    A = envío automático, M = reenvío manual. NULL si la solicitud no tiene correos. Si un correo falló y luego un
--    reenvío manual sale bien, el último es el reenvío: queda «ENVIADO:M».
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_SOLICITUD_CORREO_ESTADO"("HV_ID_Solicitud" BIGINT)
RETURNS VARCHAR LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    r VARCHAR;
BEGIN
    -- V1.0 2026-11-19
    SELECT CAST(C."Estado" || ':' || CASE WHEN C."Tipo" = 'SOLICITUD_REENVIO' THEN 'M' ELSE 'A' END AS VARCHAR) INTO r
      FROM "CAF_Correo_Pendiente" C
     WHERE C."ID_Solicitud" = "HV_ID_Solicitud" AND C."Eliminado" = 'N'
     ORDER BY C."CreateDate" DESC, C."ID_Correo_Pendiente" DESC
     LIMIT 1;
    RETURN r;
END;
$$;

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_SOLICITUD_CORREOS_LISTAR
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS "ERP_CAF_SOLICITUD_CORREOS_LISTAR"(BIGINT, BIGINT);
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_CORREOS_LISTAR"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Correo_Pendiente" BIGINT, "Tipo" VARCHAR, "Destinatarios" VARCHAR, "Copia" VARCHAR, "Asunto" VARCHAR,
               "Estado" VARCHAR, "Intentos" BIGINT, "Ultimo_Error" VARCHAR, "CreateDate" TIMESTAMP, "Fecha_Envio" TIMESTAMP,
               "Es_Reenvio" CHAR(1), "Enviado_Por" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-19
    IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <= 0
       OR "ERP_CAF_FN_SOLICITUD_VISIBLE"("HV_UsuarioID", "HV_ID_Solicitud") <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT C."ID_Correo_Pendiente", C."Tipo", C."Destinatarios", C."Copia", C."Asunto", C."Estado", C."Intentos",
           CAST(CASE WHEN C."Estado" = 'ERROR' THEN LEFT(C."Ultimo_Error", 400) ELSE NULL END AS VARCHAR),
           C."CreateDate", C."Fecha_Envio",
           CAST(CASE WHEN C."Tipo" = 'SOLICITUD_REENVIO' THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN C."Tipo" = 'SOLICITUD_REENVIO' AND U."ID_Usuario" IS NOT NULL
                     THEN U."Nombres" || ' ' || U."Apellido_Paterno" ELSE NULL END AS VARCHAR)
      FROM "CAF_Correo_Pendiente" C
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = C."UsuarioID_Create" AND C."UsuarioID_Create" > 0
     WHERE C."ID_Solicitud" = "HV_ID_Solicitud" AND C."Eliminado" = 'N'
     ORDER BY C."CreateDate" DESC, C."ID_Correo_Pendiente" DESC;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_SOLICITUD_CORREO_REENVIAR
--    HV_Mismos = 'Y' : va a los mismos destinatarios que ya recibieron correos de la solicitud (más el solicitante y las
--                      copias) y a los HV_Adicionales.
--    HV_Mismos = 'N' : va solo a los HV_Adicionales (al menos uno).
--    Devuelve en HV_Destinatarios la lista final (separada por «; »).
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(BIGINT, BIGINT, CHAR, VARCHAR, VARCHAR, INT, VARCHAR);
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(
    IN    "HV_UsuarioID"      BIGINT,
    IN    "HV_ID_Solicitud"   BIGINT,
    IN    "HV_Mismos"         CHAR(1),
    IN    "HV_Adicionales"    VARCHAR(2000),
    INOUT "HV_Destinatarios"  VARCHAR(2000) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"    INT DEFAULT NULL,
    INOUT "HV_Mensaje"        VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_mismos  CHAR(1) := UPPER(COALESCE("HV_Mismos", ''));
    lv_adic    VARCHAR(2000) := LOWER(TRIM(COALESCE("HV_Adicionales", '')));
    lv_malo    VARCHAR(200);
    lv_n_adic  INT := 0;
    lv_lista   VARCHAR(4000);
    lv_cod     VARCHAR(30);
    lv_nom     VARCHAR(200);
    lv_cor     VARCHAR(200);
    lv_c       INT;
    lv_m       VARCHAR(250);
BEGIN
    -- V1.0 2026-11-19
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CORREO_REENVIAR';
    "HV_Destinatarios" := NULL;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <= 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_SOLICITUD_VISIBLE"("HV_UsuarioID", "HV_ID_Solicitud") <> 'Y' THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe o no puede verla.'; RETURN;
        END IF;
        IF lv_mismos NOT IN ('Y', 'N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique si se reenvía a los mismos destinatarios.'; RETURN;
        END IF;

        -- Correos adicionales: separados por «;», «,» o espacios; cada uno debe tener formato de correo.
        DROP TABLE IF EXISTS tmp_reenvio_dest;
        CREATE TEMP TABLE tmp_reenvio_dest ("Correo" VARCHAR(200) NOT NULL) ON COMMIT DROP;
        IF lv_adic <> '' THEN
            INSERT INTO tmp_reenvio_dest ("Correo")
            SELECT DISTINCT TRIM(x) FROM regexp_split_to_table(lv_adic, '[;,[:space:]]+') AS x WHERE TRIM(x) <> '';
            SELECT MAX("Correo") INTO lv_malo FROM tmp_reenvio_dest WHERE "Correo" !~ '^[^[:space:]@;,]+@[^[:space:]@;,]+\.[^[:space:]@;,]+$';
            IF lv_malo IS NOT NULL THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := LEFT('«' || lv_malo || '» no parece un correo válido.', 250); RETURN;
            END IF;
            SELECT COUNT(*) INTO lv_n_adic FROM tmp_reenvio_dest;
        END IF;
        IF lv_mismos = 'N' AND lv_n_adic = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Si no reenvía a los mismos destinatarios, indique al menos un correo adicional.'; RETURN;
        END IF;

        -- Un reenvío a la vez: si el anterior sigue en cola, se espera a que salga.
        IF EXISTS (SELECT 1 FROM "CAF_Correo_Pendiente"
                    WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Tipo" = 'SOLICITUD_REENVIO' AND "Estado" = 'PENDIENTE' AND "Eliminado" = 'N') THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Ya hay un reenvío en cola para esta solicitud. Espere a que se envíe.'; RETURN;
        END IF;

        IF lv_mismos = 'Y' THEN
            -- Los que ya recibieron algún correo de esta solicitud (Para y Cc), el solicitante y las copias.
            INSERT INTO tmp_reenvio_dest ("Correo")
            SELECT DISTINCT LOWER(TRIM(x))
              FROM "CAF_Correo_Pendiente" C,
                   LATERAL regexp_split_to_table(COALESCE(C."Destinatarios", '') || ';' || COALESCE(C."Copia", ''), '[;,[:space:]]+') AS x
             WHERE C."ID_Solicitud" = "HV_ID_Solicitud" AND C."Eliminado" = 'N' AND C."Tipo" <> 'SOLICITUD_REENVIO' AND TRIM(x) <> '';
            INSERT INTO tmp_reenvio_dest ("Correo")
            SELECT LOWER(TRIM(U."Correo")) FROM "CAF_Solicitud" S
              JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = S."ID_Usuario_Solicitante" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
             WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND COALESCE(TRIM(U."Correo"), '') <> '';
            INSERT INTO tmp_reenvio_dest ("Correo")
            SELECT LOWER(TRIM(K."Correo")) FROM "CAF_Solicitud_Copia_Correo" K
             WHERE K."ID_Solicitud" = "HV_ID_Solicitud" AND K."Eliminado" = 'N' AND COALESCE(TRIM(K."Correo"), '') <> '';
        END IF;

        SELECT STRING_AGG(Z."Correo", '; ' ORDER BY Z."Correo") INTO lv_lista
          FROM (SELECT DISTINCT "Correo" FROM tmp_reenvio_dest) Z;
        IF lv_lista IS NULL OR LENGTH(lv_lista) = 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'No hay destinatarios para reenviar. Agregue al menos un correo adicional.'; RETURN;
        END IF;
        IF LENGTH(lv_lista) > 2000 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Son demasiados destinatarios para un solo reenvío.'; RETURN;
        END IF;

        SELECT S."Codigo" INTO lv_cod FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud";
        SELECT U."Nombres" || ' ' || U."Apellido_Paterno", U."Correo" INTO lv_nom, lv_cor
          FROM "CAF_GOVERNANCE"."Usuario" U WHERE U."ID_Usuario" = "HV_UsuarioID";

        INSERT INTO "CAF_Correo_Pendiente" ("Tipo","ID_Solicitud","Destinatarios","Asunto","Cuerpo","UsuarioID_Create")
        VALUES ('SOLICITUD_REENVIO', "HV_ID_Solicitud", lv_lista, LEFT('Reenvío de la solicitud ' || lv_cod, 500),
                'Este aviso fue reenviado manualmente por ' || COALESCE(lv_nom, 'un usuario') || '.' || CHR(10)
                || 'Muestra el estado de la solicitud al momento del reenvío.', "HV_UsuarioID");

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'CORREO_REENVIAR',
             'Reenvió el correo con el estado actual a: ' || lv_lista || CASE WHEN lv_mismos = 'N' THEN ' (solo a los correos indicados)' ELSE '' END,
             "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_Destinatarios" := lv_lista;
        "HV_Codigo_Resp"   := 100;
        "HV_Mensaje"       := 'Reenvío en cola. Saldrá en unos instantes.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CORREO_REENVIAR';
    END;
END;
$$;
