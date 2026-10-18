-- =============================================================================
-- Archivo : SP_CAF_RESPALDO_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 3 - Portería y desviaciones | Fase 1 - Procedimientos (respaldos)
-- Entidad : CAF_Respaldo, CAF_Respaldo_Persona
-- Versión : V1.0 2026-10-17
-- Requiere: scripts 01 a 10 y los SP de los Hitos 0, 1 y 2.
-- =============================================================================
-- ERP_CAF_RESPALDO_REGISTRAR
--   Vigilancia deja constancia del documento que respalda lo que entra con las personas.
--   Combinaciones válidas (RN-14):
--     EQUIPOS                 + G_FSCA_009
--     HERRAMIENTAS_MATERIALES + GUIA_REMISION (exige número de documento) | GUIA_MANUAL_G_FSCA_010
--   HV_IDs_Solicitud_Persona: «12,15,18» (una o varias personas, todas de la misma sede,
--   autorizadas y con estado ESPERADA o DENTRO). Una persona no se repite en un mismo respaldo.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

CREATE OR REPLACE PROCEDURE "ERP_CAF_RESPALDO_REGISTRAR"(
    IN    "HV_Categoria"              VARCHAR(30),
    IN    "HV_Tipo_Respaldo"          VARCHAR(30),
    IN    "HV_Numero_Documento"       VARCHAR(50),
    IN    "HV_IDs_Solicitud_Persona"  VARCHAR(500),
    IN    "HV_Observacion"            VARCHAR(500),
    IN    "HV_UsuarioID"              BIGINT,
    INOUT "HV_ID_Respaldo_Result"     BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"            INT DEFAULT NULL,
    INOUT "HV_Mensaje"                VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_cat    VARCHAR(30) := UPPER(TRIM(COALESCE("HV_Categoria", '')));
    lv_tipo   VARCHAR(30) := UPPER(TRIM(COALESCE("HV_Tipo_Respaldo", '')));
    lv_num    VARCHAR(50) := NULLIF(TRIM(COALESCE("HV_Numero_Documento", '')), '');
    lv_lista  VARCHAR(600) := ',' || REPLACE(COALESCE("HV_IDs_Solicitud_Persona", ''), ' ', '') || ',';
    lv_tokens INT;
    lv_dbl    VARCHAR(1200);
    lv_dup    INT := 0;
    lv_id     BIGINT := 0;
    lv_total  INT := 0;
    lv_validas INT := 0;
    lv_sedes  INT := 0;
    lv_sede   BIGINT;
    lv_resp   BIGINT;
BEGIN
    -- V1.0 2026-10-17
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_RESPALDO_REGISTRAR';
    "HV_ID_Respaldo_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF lv_cat NOT IN ('EQUIPOS','HERRAMIENTAS_MATERIALES') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La categoría debe ser EQUIPOS o HERRAMIENTAS_MATERIALES.'; RETURN;
        END IF;
        IF NOT ((lv_cat = 'EQUIPOS' AND lv_tipo = 'G_FSCA_009')
             OR (lv_cat = 'HERRAMIENTAS_MATERIALES' AND lv_tipo IN ('GUIA_REMISION','GUIA_MANUAL_G_FSCA_010'))) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de respaldo no corresponde a la categoría.'; RETURN;
        END IF;
        IF lv_tipo = 'GUIA_REMISION' AND lv_num IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el número de la guía de remisión.'; RETURN;
        END IF;
        IF lv_tipo <> 'GUIA_REMISION' AND lv_num IS NOT NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Solo la guía de remisión lleva número de documento.'; RETURN;
        END IF;
        IF "HV_Observacion" IS NOT NULL AND LENGTH(TRIM("HV_Observacion")) > 500 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La observación no puede superar 500 caracteres.'; RETURN;
        END IF;
        IF lv_lista !~ '^,([0-9]+,)+$' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique las personas como lista de números separados por coma.'; RETURN;
        END IF;
        lv_tokens := LENGTH(lv_lista) - LENGTH(REPLACE(lv_lista, ',', '')) - 1;

        lv_dbl := REPLACE(lv_lista, ',', ',,');
        -- Recorre las personas (sin cursor): cuenta, valida estado y sede
        LOOP
            SELECT MIN(P."ID_Solicitud_Persona") INTO lv_id
              FROM "CAF_Solicitud_Persona" P
             WHERE P."ID_Solicitud_Persona" > lv_id AND lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';
            EXIT WHEN lv_id IS NULL;
            lv_total := lv_total + 1;
            -- ¿repetida? (en el texto con las comas duplicadas, ',id,' no se superpone consigo mismo)
            IF LENGTH(lv_dbl) - LENGTH(REPLACE(lv_dbl, ',' || CAST(lv_id AS VARCHAR) || ',', '')) > LENGTH(',' || CAST(lv_id AS VARCHAR) || ',') THEN
                lv_dup := 1;
            END IF;
        END LOOP;
        SELECT COUNT(*), COUNT(DISTINCT S."ID_Catalogo_Sede"), MAX(S."ID_Catalogo_Sede")
          INTO lv_validas, lv_sedes, lv_sede
          FROM "CAF_Solicitud_Persona" P
          JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud" AND S."Eliminado" = 'N' AND S."Estado" <> 'CANCELADA'
         WHERE P."Eliminado" = 'N' AND P."Aprobacion" = 'APROBADA' AND P."Estado" IN ('ESPERADA','DENTRO')
           AND lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';

        IF lv_dup = 1 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Una persona está repetida en la lista.'; RETURN;
        END IF;
        IF lv_total <> lv_tokens THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'Alguna persona indicada no existe.'; RETURN;
        END IF;
        IF lv_validas <> lv_total THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'Todas las personas deben estar autorizadas, en una visita vigente y sin haber salido ni sido denegadas.'; RETURN;
        END IF;
        IF lv_sedes <> 1 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Todas las personas deben ser de la misma sede.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para registrar respaldos en esta sede.'; RETURN;
        END IF;

        INSERT INTO "CAF_Respaldo" ("ID_Catalogo_Sede","Categoria","Tipo_Respaldo","Numero_Documento","Fecha_Hora",
                                    "ID_Usuario_Vigilante","Observacion","UsuarioID_Create")
        VALUES (lv_sede, lv_cat, lv_tipo, lv_num, CURRENT_TIMESTAMP, "HV_UsuarioID",
                NULLIF(TRIM(COALESCE("HV_Observacion", '')), ''), "HV_UsuarioID")
        RETURNING "ID_Respaldo" INTO lv_resp;

        INSERT INTO "CAF_Respaldo_Persona" ("ID_Respaldo","ID_Solicitud_Persona","UsuarioID_Create")
        SELECT lv_resp, P."ID_Solicitud_Persona", "HV_UsuarioID"
          FROM "CAF_Solicitud_Persona" P
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';

        "HV_ID_Respaldo_Result" := lv_resp;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje" := 'Respaldo registrado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_ID_Respaldo_Result" := 0;
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_RESPALDO_REGISTRAR';
    END;
END;
$$;
