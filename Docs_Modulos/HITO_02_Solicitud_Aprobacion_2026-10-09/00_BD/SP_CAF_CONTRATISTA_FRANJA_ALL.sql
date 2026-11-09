-- =============================================================================
-- Archivo : SP_CAF_CONTRATISTA_FRANJA_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Hito    : 2 - Solicitud y aprobación | Fase 1 - SP   (D-227)
-- Versión : V1.0 2026-11-09
-- Estado  : CANDIDATO - probado en PostgreSQL 16
-- Requiere: scripts 01 a 25 y los SP de solicitud, portería y proveedor (ERP_CAF_PROVEEDOR_CIERRE_DIA llama al cierre).
-- Contenido
--   1 ERP_CAF_FN_ES_FRANJA        'Y' si la solicitud tiene días autorizados (contratista por franja)
--   1b ERP_CAF_FN_FRANJA_FIN      último día autorizado (NULL si no es de franja)
--   2 ERP_CAF_FN_FRANJA_ESTADO    NA / DENTRO / FUERA para un momento dado
--   3 ERP_CAF_SOLICITUD_CREAR_CONTRATISTA   crea la solicitud con su lista de días (todo o nada)
--   4 ERP_CAF_SOLICITUD_DIAS_EXTENDER       el Coordinador agrega días a una solicitud aprobada (emergencia)
--   5 ERP_CAF_CONTRATISTA_CIERRE_DIA        cierre forzado del día: quien siguió dentro sale a las 23:59 del día de su ingreso
--   6 ERP_CAF_SOLICITUD_DIAS                lista de días de una solicitud (lectura)
-- HANA (T-38): los SP usan STRING_TO_ARRAY/UNNEST/STRING_AGG, ::DATE y aritmética de INTERVAL; se reescriben con
--   SERIES_GENERATE / SUBSTR_REGEXPR / STRING_AGG nativo / ADD_SECONDS.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_FN_ES_FRANJA
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ES_FRANJA"("HV_ID_Solicitud" BIGINT)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-11-09 (D-227)
    SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Dia" D WHERE D."ID_Solicitud" = "HV_ID_Solicitud" AND D."Eliminado" = 'N';
    RETURN CASE WHEN lv_n > 0 THEN 'Y' ELSE 'N' END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 1b. ERP_CAF_FN_FRANJA_FIN
--     Último día autorizado de una solicitud de franja; NULL si no es de franja. Los SP de corrección y de lectura lo usan
--     para decir «la fecha ya pasó» contra el FINAL de la franja y no contra su primer día.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_FRANJA_FIN"("HV_ID_Solicitud" BIGINT)
RETURNS DATE
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_f DATE;
BEGIN
    SELECT MAX(D."Fecha") INTO lv_f FROM "CAF_Solicitud_Dia" D WHERE D."ID_Solicitud" = "HV_ID_Solicitud" AND D."Eliminado" = 'N';
    RETURN lv_f;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_FN_FRANJA_ESTADO
--    NA     la solicitud no es de franja (se rige por su fecha única de siempre)
--    DENTRO el momento cae en un día autorizado (las horas indicadas son aproximadas y NO restringen)
--    FUERA  otro día
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_FRANJA_ESTADO"("HV_ID_Solicitud" BIGINT, "HV_Momento" TIMESTAMP)
RETURNS VARCHAR(6)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT := 0;
    lv_h INT := 0;
BEGIN
    -- V1.0 2026-11-09 (D-227)
    IF "ERP_CAF_FN_ES_FRANJA"("HV_ID_Solicitud") <> 'Y' THEN RETURN 'NA'; END IF;
    SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Dia" D
     WHERE D."ID_Solicitud" = "HV_ID_Solicitud" AND D."Eliminado" = 'N' AND D."Fecha" = CAST("HV_Momento" AS DATE);
    RETURN CASE WHEN lv_n > 0 THEN 'DENTRO' ELSE 'FUERA' END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_SOLICITUD_CREAR_CONTRATISTA
--    HV_Dias: «AAAA-MM-DD,AAAA-MM-DD,...» (la web expande rangos y días sueltos a esta lista). Entre 1 y 92 días,
--    sin repetir, ninguno anterior a hoy. HV_Hora_Desde / HV_Hora_Hasta «HH:MM»: hora aproximada de ingreso y de salida, opcionales e independientes.
--    El responsable de atención es OPCIONAL para el contratista. Todo lo demás lo valida ERP_CAF_SOLICITUD_CREAR.
--    400 validación | 101 sin permiso (lo decide CREAR) | 500 error. Todo o nada.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(
    IN    "HV_ID_Catalogo_Sede"         BIGINT,
    IN    "HV_ID_Personal_Responsable"  BIGINT,
    IN    "HV_Empresa_Visitante"        VARCHAR(500),
    IN    "HV_Motivo_Detalle"           VARCHAR(500),
    IN    "HV_Observaciones"            VARCHAR(2000),
    IN    "HV_IDs_Zona"                 VARCHAR(2000),
    IN    "HV_IDs_Persona_Externa"      VARCHAR(2000),
    IN    "HV_Copias"                   VARCHAR(2000),
    IN    "HV_ID_Solicitud_Origen"      BIGINT,
    IN    "HV_Requiere_Cochera"         CHAR(1),
    IN    "HV_Placa_Vehiculo"           VARCHAR(15),
    IN    "HV_Area_Detalle"             VARCHAR(300),
    IN    "HV_Contacto_Nombre"          VARCHAR(200),
    IN    "HV_Contacto_Telefonos"       VARCHAR(100),
    IN    "HV_Contacto_Correos"         VARCHAR(500),
    IN    "HV_Dias"                     VARCHAR(2000),
    IN    "HV_Hora_Desde"               VARCHAR(5),
    IN    "HV_Hora_Hasta"               VARCHAR(5),
    IN    "HV_UsuarioID"                BIGINT,
    INOUT "HV_ID_Solicitud_Result"      BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Solicitud_Result"  VARCHAR(20) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"              INT DEFAULT NULL,
    INOUT "HV_Mensaje"                  VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_tipo   BIGINT;
    lv_toks   TEXT[];
    lv_n      INT;
    lv_i      INT;
    lv_t      TEXT;
    lv_f      DATE;
    lv_min    DATE;
    lv_desde  TIME;
    lv_hasta  TIME;
    lv_hd     VARCHAR(5) := NULLIF(TRIM(COALESCE("HV_Hora_Desde", '')), '');
    lv_hh     VARCHAR(5) := NULLIF(TRIM(COALESCE("HV_Hora_Hasta", '')), '');
    lv_prev   TIMESTAMP;
    lv_c      INT;
    lv_m      VARCHAR(250);
BEGIN
    -- V1.0 2026-11-09 (D-227)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR_CONTRATISTA';
    "HV_ID_Solicitud_Result" := 0;
    BEGIN
        SELECT MAX("ID_Catalogo_Tipo_Acceso") INTO lv_tipo FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'CONTRATISTA' AND "Eliminado" = 'N';
        IF lv_tipo IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de acceso de contratistas no existe.'; RETURN;
        END IF;

        -- Horas aproximadas de ingreso y de salida: opcionales e independientes, HH:MM; si van las dos, la salida es posterior
        IF (lv_hd IS NOT NULL AND lv_hd !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$') OR (lv_hh IS NOT NULL AND lv_hh !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Las horas deben tener el formato HH:MM.'; RETURN;
        END IF;
        IF lv_hd IS NOT NULL THEN lv_desde := CAST(lv_hd AS TIME); END IF;
        IF lv_hh IS NOT NULL THEN lv_hasta := CAST(lv_hh AS TIME); END IF;
        IF lv_desde IS NOT NULL AND lv_hasta IS NOT NULL AND lv_desde >= lv_hasta THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La hora de salida debe ser posterior a la de ingreso.'; RETURN;
        END IF;

        -- Días: formato, existencia real de la fecha, sin repetir, no anteriores a hoy
        lv_toks := STRING_TO_ARRAY(NULLIF(REPLACE(REPLACE(COALESCE("HV_Dias", ''), ' ', ''), ';', ','), ''), ',');
        lv_n := COALESCE(ARRAY_LENGTH(lv_toks, 1), 0);
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique al menos un día de trabajo.'; RETURN;
        END IF;
        IF lv_n > 92 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Una solicitud no puede pasar de 92 días. Para más tiempo, cree otra solicitud.'; RETURN;
        END IF;
        FOR lv_i IN 1..lv_n LOOP
            lv_t := lv_toks[lv_i];
            IF lv_t !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Cada día debe tener el formato AAAA-MM-DD.'; RETURN;
            END IF;
            BEGIN
                lv_f := CAST(lv_t AS DATE);
            EXCEPTION WHEN OTHERS THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Hay un día que no existe en el calendario: ' || lv_t || '.'; RETURN;
            END;
            IF lv_f < CURRENT_DATE THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Los días de trabajo no pueden ser anteriores a hoy.'; RETURN;
            END IF;
            IF lv_i > 1 AND lv_t = ANY (lv_toks[1:lv_i - 1]) THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El día ' || lv_t || ' está repetido.'; RETURN;
            END IF;
            IF lv_min IS NULL OR lv_f < lv_min THEN lv_min := lv_f; END IF;
        END LOOP;
        lv_prev := CAST(lv_min AS TIMESTAMP) + COALESCE(CAST(lv_desde AS INTERVAL), INTERVAL '0 hours');

        CALL "ERP_CAF_SOLICITUD_CREAR"("HV_ID_Catalogo_Sede", lv_tipo, "HV_ID_Personal_Responsable", lv_prev, "HV_Empresa_Visitante", NULL,
                                       "HV_Motivo_Detalle", "HV_Observaciones", "HV_IDs_Zona", "HV_IDs_Persona_Externa", "HV_Copias",
                                       "HV_ID_Solicitud_Origen", "HV_Requiere_Cochera", "HV_Placa_Vehiculo", "HV_Area_Detalle",
                                       "HV_Contacto_Nombre", "HV_Contacto_Telefonos", "HV_Contacto_Correos", NULL, NULL, NULL, NULL, NULL,
                                       NULL, "HV_UsuarioID", "HV_ID_Solicitud_Result", "HV_Codigo_Solicitud_Result", lv_c, lv_m);
        IF lv_c <> 100 THEN
            "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; "HV_ID_Solicitud_Result" := 0; "HV_Codigo_Solicitud_Result" := NULL; RETURN;
        END IF;

        INSERT INTO "CAF_Solicitud_Dia" ("ID_Solicitud","Fecha","Hora_Desde","Hora_Hasta","Origen","UsuarioID_Create")
        SELECT "HV_ID_Solicitud_Result", CAST(X.t AS DATE), lv_desde, lv_hasta, 'SOLICITUD', "HV_UsuarioID"
          FROM UNNEST(lv_toks) AS X(t);

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := lv_m;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR_CONTRATISTA';
        "HV_ID_Solicitud_Result" := 0;
        "HV_Codigo_Solicitud_Result" := NULL;
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_SOLICITUD_DIAS_EXTENDER   (D-227)
--    El Coordinador agrega días a una solicitud de contratista YA aprobada. No cambia el estado ni toca lo registrado:
--    solo suma días (Origen = 'EXTENSION'), con el mismo horario opcional que indique. Exige sustento. No se quitan días.
--    Solo mientras la franja no haya terminado (queda algún día de hoy en adelante) y con los días nuevos desde hoy.
--    Mismo permiso y rol que la corrección de emergencia. Avisa por correo al solicitante y a Vigilancia.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_DIAS_EXTENDER"(
    IN    "HV_ID_Solicitud"   BIGINT,
    IN    "HV_Dias"           VARCHAR(2000),
    IN    "HV_Hora_Desde"     VARCHAR(5),
    IN    "HV_Hora_Hasta"     VARCHAR(5),
    IN    "HV_Sustento"       VARCHAR(2000),
    IN    "HV_UsuarioID"      BIGINT,
    INOUT "HV_Agregados"      INT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"    INT DEFAULT NULL,
    INOUT "HV_Mensaje"        VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_sede   BIGINT;
    lv_tipo   BIGINT;
    lv_estado VARCHAR(20);
    lv_codsol VARCHAR(20);
    lv_tcod   VARCHAR(30);
    lv_sus    VARCHAR(2000);
    lv_toks   TEXT[];
    lv_i      INT;
    lv_t      TEXT;
    lv_f      DATE;
    lv_desde  TIME;
    lv_hasta  TIME;
    lv_hd     VARCHAR(5) := NULLIF(TRIM(COALESCE("HV_Hora_Desde", '')), '');
    lv_hh     VARCHAR(5) := NULLIF(TRIM(COALESCE("HV_Hora_Hasta", '')), '');
    lv_quien  VARCHAR(400);
    lv_dest   VARCHAR(2000);
    lv_dest2  VARCHAR(2000);
    lv_lista  VARCHAR(2000);
    lv_c      INT;
    lv_m      VARCHAR(250);
BEGIN
    -- V1.0 2026-11-09 (D-227)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DIAS_EXTENDER';
    "HV_Agregados"   := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        lv_sus := TRIM(COALESCE("HV_Sustento", ''));
        IF LENGTH(lv_sus) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Escriba el sustento de la extensión.'; RETURN;
        END IF;
        IF LENGTH(lv_sus) > 300 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El sustento no puede pasar de 300 caracteres.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("Estado"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_tipo, lv_estado, lv_codsol
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_APROBAR', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para aprobar en esta sede.'; RETURN;
        END IF;
        SELECT MAX("Codigo") INTO lv_tcod FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo;
        IF lv_tcod <> 'CONTRATISTA' OR "ERP_CAF_FN_ES_FRANJA"("HV_ID_Solicitud") <> 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Solo se amplían los días de una solicitud de contratista con franja de tiempo.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
           AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", S."ID_Catalogo_Licencia", lv_sede) = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Su rol no decide ningún paso de este tipo de acceso.'; RETURN;
        END IF;
        IF lv_estado NOT IN ('APROBADA','APROBADA_PARCIAL') THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE WHEN lv_estado = 'CANCELADA' THEN 'La solicitud está cancelada.'
                                 ELSE 'Solo se amplía una solicitud ya aprobada.' END;
            RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Dia" D
         WHERE D."ID_Solicitud" = "HV_ID_Solicitud" AND D."Eliminado" = 'N' AND D."Fecha" >= CURRENT_DATE;
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La franja ya terminó: el solicitante debe crear una nueva solicitud.'; RETURN;
        END IF;

        IF (lv_hd IS NOT NULL AND lv_hd !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$') OR (lv_hh IS NOT NULL AND lv_hh !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Las horas deben tener el formato HH:MM.'; RETURN;
        END IF;
        IF lv_hd IS NOT NULL THEN lv_desde := CAST(lv_hd AS TIME); END IF;
        IF lv_hh IS NOT NULL THEN lv_hasta := CAST(lv_hh AS TIME); END IF;
        IF lv_desde IS NOT NULL AND lv_hasta IS NOT NULL AND lv_desde >= lv_hasta THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La hora de salida debe ser posterior a la de ingreso.'; RETURN;
        END IF;

        lv_toks := STRING_TO_ARRAY(NULLIF(REPLACE(REPLACE(COALESCE("HV_Dias", ''), ' ', ''), ';', ','), ''), ',');
        lv_n := COALESCE(ARRAY_LENGTH(lv_toks, 1), 0);
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique al menos un día para agregar.'; RETURN;
        END IF;
        IF lv_n > 92 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'No se pueden agregar más de 92 días a la vez.'; RETURN;
        END IF;
        lv_lista := '';
        FOR lv_i IN 1..lv_n LOOP
            lv_t := lv_toks[lv_i];
            IF lv_t !~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Cada día debe tener el formato AAAA-MM-DD.'; RETURN;
            END IF;
            BEGIN
                lv_f := CAST(lv_t AS DATE);
            EXCEPTION WHEN OTHERS THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Hay un día que no existe en el calendario: ' || lv_t || '.'; RETURN;
            END;
            IF lv_f < CURRENT_DATE THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Los días nuevos no pueden ser anteriores a hoy.'; RETURN;
            END IF;
            IF lv_i > 1 AND lv_t = ANY (lv_toks[1:lv_i - 1]) THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El día ' || lv_t || ' está repetido.'; RETURN;
            END IF;
            IF EXISTS (SELECT 1 FROM "CAF_Solicitud_Dia" D WHERE D."ID_Solicitud" = "HV_ID_Solicitud" AND D."Fecha" = lv_f) THEN
                "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'El día ' || TO_CHAR(lv_f, 'DD/MM/YYYY') || ' ya está autorizado.'; RETURN;
            END IF;
            lv_lista := lv_lista || CASE WHEN lv_i > 1 THEN ', ' ELSE '' END || TO_CHAR(lv_f, 'DD/MM');
        END LOOP;

        INSERT INTO "CAF_Solicitud_Dia" ("ID_Solicitud","Fecha","Hora_Desde","Hora_Hasta","Origen","UsuarioID_Create")
        SELECT "HV_ID_Solicitud", CAST(X.t AS DATE), lv_desde, lv_hasta, 'EXTENSION', "HV_UsuarioID"
          FROM UNNEST(lv_toks) AS X(t);
        "HV_Agregados" := lv_n;

        CALL "ERP_CAF_SOLICITUD_VERSION_GUARDAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'version: %', lv_m; END IF;
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'EXTENDER_DIAS',
             'Se agregaron ' || CAST(lv_n AS VARCHAR) || ' día(s): ' || lv_lista || ' · Sustento: ' || lv_sus, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        SELECT U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" INTO lv_quien
          FROM "CAF_GOVERNANCE"."Usuario" U WHERE U."ID_Usuario" = "HV_UsuarioID";
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'SOLICITANTE', NULL, lv_dest, lv_c, lv_m);
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PORTERIA', NULL, lv_dest2, lv_c, lv_m);
        lv_dest := CASE WHEN lv_dest IS NULL THEN lv_dest2 WHEN lv_dest2 IS NULL THEN lv_dest ELSE lv_dest || '; ' || lv_dest2 END;
        CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_CORRECCION', "HV_ID_Solicitud", lv_dest,
             "ERP_CAF_FN_COPIA_CORREO"("HV_ID_Solicitud", 'N', 'Y', 'N', 'Y'),
             'Se amplió el plazo autorizado de ' || lv_codsol,
             'EXTENSIÓN DE DÍAS AUTORIZADOS' || CHR(10)
             || 'Se agregaron ' || CAST(lv_n AS VARCHAR) || ' día(s) a la solicitud ' || lv_codsol || ': ' || lv_lista || '.' || CHR(10)
             || 'Sustento: ' || lv_sus || CHR(10)
             || 'Registrado por: ' || COALESCE(lv_quien, 'el Coordinador') || '.',
             "HV_UsuarioID", lv_c, lv_m);

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Se agregaron ' || CAST(lv_n AS VARCHAR) || ' día(s) a la franja.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DIAS_EXTENDER';
        "HV_Agregados"   := 0;
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_CONTRATISTA_CIERRE_DIA   (D-227)
--    Cierre forzado del día del contratista. HV_Dia = día operativo actual (lo calcula ERP_CAF_PROVEEDOR_CIERRE_DIA con la
--    misma hora de corte): quien siguió DENTRO desde un día anterior sale «a las 23:59 del día de su ingreso» con un registro
--    de salida tardío del sistema (observación «Cierre forzado»), y queda ESPERADA si le quedan días (de HV_Dia en adelante) o
--    SALIO si era el último. Cierra solo ESE día: la solicitud sigue vigente. Avisa al Coordinador (una vez por solicitud).
--    Idempotente. Lo ejecuta el sistema (HV_UsuarioID = 0).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_CONTRATISTA_CIERRE_DIA"(
    IN    "HV_Dia"            DATE,
    IN    "HV_UsuarioID"      BIGINT,
    INOUT "HV_Cerradas"       INT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"    INT DEFAULT NULL,
    INOUT "HV_Mensaje"        VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_id     BIGINT := 0;
    lv_sol    BIGINT;
    lv_sede   BIGINT;
    lv_nom    VARCHAR(400);
    lv_ing    TIMESTAMP;
    lv_fin    TIMESTAMP;
    lv_quedan INT;
    lv_reg    BIGINT;
    lv_cod    VARCHAR(20);
    lv_dest   VARCHAR(2000);
    lv_nombres VARCHAR(2000);
    lv_c      INT;
    lv_m      VARCHAR(250);
BEGIN
    -- V1.0 2026-11-09 (D-227)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_CONTRATISTA_CIERRE_DIA';
    "HV_Cerradas"    := 0;
    BEGIN
        CREATE TEMP TABLE IF NOT EXISTS "tmp_cierre_contr" ("ID_Solicitud" BIGINT, "Nombre" VARCHAR(400)) ON COMMIT DROP;
        DELETE FROM "tmp_cierre_contr";

        LOOP
            SELECT MIN(P."ID_Solicitud_Persona") INTO lv_id
              FROM "CAF_Solicitud_Persona" P
              JOIN "CAF_Solicitud_Dia" D0 ON D0."ID_Solicitud" = P."ID_Solicitud" AND D0."Eliminado" = 'N'
             WHERE P."ID_Solicitud_Persona" > lv_id AND P."Eliminado" = 'N' AND P."Estado" = 'DENTRO'
               AND P."Fecha_Hora_Ingreso" IS NOT NULL AND CAST(P."Fecha_Hora_Ingreso" AS DATE) < "HV_Dia";
            EXIT WHEN lv_id IS NULL;

            SELECT S."ID_Solicitud", S."ID_Catalogo_Sede", P."Fecha_Hora_Ingreso",
                   PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres"
              INTO lv_sol, lv_sede, lv_ing, lv_nom
              FROM "CAF_Solicitud_Persona" P
              JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
              JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
             WHERE P."ID_Solicitud_Persona" = lv_id;

            lv_fin := CAST(CAST(lv_ing AS DATE) AS TIMESTAMP) + INTERVAL '23 hours 59 minutes';
            INSERT INTO "CAF_Registro_Acceso" ("ID_Solicitud_Persona","ID_Catalogo_Sede","Tipo_Movimiento","Resultado","Fecha_Hora",
                                               "Es_Registro_Tardio","ID_Usuario_Vigilante","Observacion","UsuarioID_Create")
            VALUES (lv_id, lv_sede, 'SALIDA', 'SALE', lv_fin, 'Y', "HV_UsuarioID",
                    'Cierre forzado del día ' || TO_CHAR(lv_ing, 'DD/MM/YYYY') || ': no se registró la salida', "HV_UsuarioID")
            RETURNING "ID_Registro_Acceso" INTO lv_reg;

            SELECT COUNT(*) INTO lv_quedan FROM "CAF_Solicitud_Dia" D
             WHERE D."ID_Solicitud" = lv_sol AND D."Eliminado" = 'N' AND D."Fecha" >= "HV_Dia";
            UPDATE "CAF_Solicitud_Persona"
               SET "Estado" = CASE WHEN lv_quedan > 0 THEN 'ESPERADA' ELSE 'SALIO' END, "Fecha_Hora_Salida" = lv_fin,
                   "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = lv_id;

            CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', lv_id, lv_sol, 'CIERRE_FORZADO',
                 lv_nom || ' · salida forzada del día ' || TO_CHAR(lv_ing, 'DD/MM/YYYY'), "HV_UsuarioID", lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;
            INSERT INTO "tmp_cierre_contr" ("ID_Solicitud","Nombre") VALUES (lv_sol, lv_nom);
            "HV_Cerradas" := "HV_Cerradas" + 1;
        END LOOP;

        -- Un aviso por solicitud con el nombre de quienes se cerraron
        lv_sol := 0;
        LOOP
            SELECT MIN(T."ID_Solicitud") INTO lv_sol FROM "tmp_cierre_contr" T WHERE T."ID_Solicitud" > lv_sol;
            EXIT WHEN lv_sol IS NULL;
            SELECT STRING_AGG(T."Nombre", '; ' ORDER BY T."Nombre") INTO lv_nombres FROM "tmp_cierre_contr" T WHERE T."ID_Solicitud" = lv_sol;
            SELECT S."Codigo" INTO lv_cod FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = lv_sol;
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_sol, 'APROBADORES', NULL, lv_dest, lv_c, lv_m);
            IF lv_dest IS NOT NULL AND LENGTH(lv_dest) > 0 THEN
                CALL "ERP_CAF_CORREO_ENCOLAR"('PROVEEDOR_AVISO', lv_sol, lv_dest, NULL,
                     'Salida no registrada de contratista en ' || lv_cod || ': se cerró el día a la fuerza',
                     'CIERRE FORZADO DEL DÍA' || CHR(10)
                     || 'Al terminar el día seguían dentro y no tenían salida registrada: ' || lv_nombres || '.' || CHR(10)
                     || 'El sistema registró su salida a las 23:59 del día de su ingreso. La solicitud ' || lv_cod || ' sigue vigente para los días que le queden.' || CHR(10)
                     || 'Se informa para que tome las medidas que correspondan.',
                     "HV_UsuarioID", lv_c, lv_m);
            END IF;
        END LOOP;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Cierre de contratistas revisado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_CONTRATISTA_CIERRE_DIA';
        "HV_Cerradas"    := 0;
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CAF_SOLICITUD_DIAS   (lectura: vacío si el usuario no puede ver la solicitud)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_DIAS"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("Fecha" DATE, "Hora_Desde" VARCHAR, "Hora_Hasta" VARCHAR, "Origen" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-09 (D-227)
    IF "ERP_CAF_FN_ADJUNTO_VISIBLE"("HV_UsuarioID", "HV_ID_Solicitud") <> 'Y' THEN
        IF NOT EXISTS (SELECT 1 FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N'
                          AND S."ID_Usuario_Solicitante" = "HV_UsuarioID") THEN
            RETURN;
        END IF;
    END IF;
    RETURN QUERY
    SELECT D."Fecha", CAST(TO_CHAR(D."Hora_Desde", 'HH24:MI') AS VARCHAR), CAST(TO_CHAR(D."Hora_Hasta", 'HH24:MI') AS VARCHAR), D."Origen"
      FROM "CAF_Solicitud_Dia" D
     WHERE D."ID_Solicitud" = "HV_ID_Solicitud" AND D."Eliminado" = 'N'
     ORDER BY D."Fecha";
END;
$$;
