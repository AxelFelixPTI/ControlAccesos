-- =============================================================================
-- SP_CAF_SOLICITUD_PROVEEDOR_DATOS_ALL.sql   (2026-11-13, D-237)
-- Datos propios del formulario de entrega de proveedor (Entrega 2C-0):
--   1 ERP_CAF_FN_TELEFONOS_NORMALIZAR / ERP_CAF_FN_TELEFONOS_VALIDAR   celulares del responsable (9 dígitos o más, 1 a 5)
--   2 ERP_CAF_FN_OC_NORMALIZAR / ERP_CAF_FN_OC_VALIDAR                  números de OC (1 a 5)
--   3 ERP_CAF_FN_PROVEEDOR_DATOS_VALIDAR                                OC + empresa transportista + franja + correos del responsable
--   4 ERP_CAF_SOLICITUD_PROVEEDOR_DATOS_GUARDAR                         guarda esos datos en una solicitud existente (edición)
-- En la creación los valida y guarda ERP_CAF_SOLICITUD_CREAR_PROVEEDOR (todo o nada). Códigos: 100, 101, 400, 404, 409, 500.
-- Schema: TRIANONSATELITAL_CAF_PRODD. Requiere el script 31.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. Teléfonos: «999 111 222; +51 987-654-321» -> «999111222;51987654321»
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_TELEFONOS_NORMALIZAR"("HV_Texto" VARCHAR)
RETURNS VARCHAR(100)
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    lv_r VARCHAR(500) := '';
    lv_t TEXT;
    lv_d TEXT;
BEGIN
    -- V1.0 2026-11-13
    FOR lv_t IN SELECT REGEXP_SPLIT_TO_TABLE(COALESCE("HV_Texto", ''), '[;,]') LOOP
        lv_d := REGEXP_REPLACE(lv_t, '[^0-9]', '', 'g');
        IF lv_d <> '' AND POSITION(';' || lv_d || ';' IN ';' || lv_r || ';') = 0 THEN
            lv_r := lv_r || CASE WHEN lv_r = '' THEN '' ELSE ';' END || lv_d;
        END IF;
    END LOOP;
    RETURN NULLIF(lv_r, '');
END;
$$;

-- '' si está bien o el mensaje. Cada teléfono: solo números (se aceptan espacios, «+», guiones y paréntesis), de 9 a 15 dígitos.
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_TELEFONOS_VALIDAR"("HV_Texto" VARCHAR)
RETURNS VARCHAR(250)
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    lv_t    TEXT;
    lv_d    TEXT;
    lv_norm VARCHAR(100);
    lv_n    INT;
BEGIN
    -- V1.0 2026-11-13
    FOR lv_t IN SELECT REGEXP_SPLIT_TO_TABLE(COALESCE("HV_Texto", ''), '[;,]') LOOP
        IF TRIM(lv_t) = '' THEN CONTINUE; END IF;
        lv_d := REGEXP_REPLACE(lv_t, '[^0-9]', '', 'g');
        IF TRIM(lv_t) !~ '^[0-9 +()-]+$' OR LENGTH(lv_d) < 9 OR LENGTH(lv_d) > 15 THEN
            RETURN 'El teléfono «' || TRIM(lv_t) || '» no es válido: debe tener 9 dígitos o más (solo números).';
        END IF;
    END LOOP;
    lv_norm := "ERP_CAF_FN_TELEFONOS_NORMALIZAR"("HV_Texto");
    IF lv_norm IS NULL THEN RETURN 'Indique al menos un teléfono celular de contacto (9 dígitos o más).'; END IF;
    lv_n := LENGTH(lv_norm) - LENGTH(REPLACE(lv_norm, ';', '')) + 1;
    IF lv_n > 5 THEN RETURN 'Indique como máximo 5 teléfonos.'; END IF;
    RETURN '';
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. OC: «oc-35563, 35564;oc-35563» -> «OC-35563;35564»
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_OC_NORMALIZAR"("HV_Texto" VARCHAR)
RETURNS VARCHAR(200)
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    lv_r VARCHAR(500) := '';
    lv_t TEXT;
    lv_d TEXT;
BEGIN
    -- V1.0 2026-11-13
    FOR lv_t IN SELECT REGEXP_SPLIT_TO_TABLE(COALESCE("HV_Texto", ''), '[;,]') LOOP
        lv_d := UPPER(REGEXP_REPLACE(TRIM(lv_t), '[[:space:]]+', '', 'g'));
        IF lv_d <> '' AND POSITION(';' || lv_d || ';' IN ';' || lv_r || ';') = 0 THEN
            lv_r := lv_r || CASE WHEN lv_r = '' THEN '' ELSE ';' END || lv_d;
        END IF;
    END LOOP;
    RETURN NULLIF(lv_r, '');
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_OC_VALIDAR"("HV_Texto" VARCHAR)
RETURNS VARCHAR(250)
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    lv_norm VARCHAR(200);
    lv_t    TEXT;
    lv_n    INT;
BEGIN
    -- V1.0 2026-11-13
    lv_norm := "ERP_CAF_FN_OC_NORMALIZAR"("HV_Texto");
    IF lv_norm IS NULL THEN RETURN 'Indique el número de la OC de esta entrega (al menos una).'; END IF;
    FOR lv_t IN SELECT REGEXP_SPLIT_TO_TABLE(lv_norm, ';') LOOP
        IF lv_t !~ '^[A-Z0-9][-A-Z0-9/.]{2,19}$' THEN
            RETURN 'La OC «' || lv_t || '» no es válida: use de 3 a 20 letras, números, guion o barra.';
        END IF;
    END LOOP;
    lv_n := LENGTH(lv_norm) - LENGTH(REPLACE(lv_norm, ';', '')) + 1;
    IF lv_n > 5 THEN RETURN 'Indique como máximo 5 OC por entrega.'; END IF;
    RETURN '';
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_FN_PROVEEDOR_DATOS_VALIDAR   ('' si está bien o el mensaje)
--    OC obligatoria; empresa transportista opcional (hasta 200); franja «Hasta» opcional, posterior a la hora estimada;
--    correos del responsable opcionales y válidos.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_PROVEEDOR_DATOS_VALIDAR"(
    "HV_Numeros_OC"            VARCHAR,
    "HV_Empresa_Transportista" VARCHAR,
    "HV_Fecha_Hora_Prevista"   TIMESTAMP,
    "HV_Hora_Hasta"            VARCHAR,
    "HV_Contacto_Correos"      VARCHAR
)
RETURNS VARCHAR(250)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_err VARCHAR(250);
    lv_h   VARCHAR(10);
BEGIN
    -- V1.0 2026-11-13
    lv_err := "ERP_CAF_FN_OC_VALIDAR"("HV_Numeros_OC");
    IF lv_err <> '' THEN RETURN lv_err; END IF;
    IF LENGTH(TRIM(COALESCE("HV_Empresa_Transportista", ''))) > 200 THEN
        RETURN 'La empresa transportista no puede superar 200 caracteres.';
    END IF;
    lv_h := NULLIF(TRIM(COALESCE("HV_Hora_Hasta", '')), '');
    IF lv_h IS NOT NULL THEN
        IF lv_h !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' THEN RETURN 'La hora final de la franja no es válida (use HH:MM).'; END IF;
        IF "HV_Fecha_Hora_Prevista" IS NOT NULL AND CAST(lv_h AS TIME) <= CAST("HV_Fecha_Hora_Prevista" AS TIME) THEN
            RETURN 'La hora final de la franja debe ser posterior a la hora estimada de llegada.';
        END IF;
    END IF;
    IF NULLIF(TRIM(COALESCE("HV_Contacto_Correos", '')), '') IS NOT NULL
       AND (LENGTH(TRIM("HV_Contacto_Correos")) > 500 OR "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Contacto_Correos") <> 'Y') THEN
        RETURN 'Los correos del responsable no son válidos (uno por etiqueta o separados por «;»).';
    END IF;
    RETURN '';
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_SOLICITUD_PROVEEDOR_DATOS_GUARDAR
--    Edición: guarda OC, empresa transportista, franja «Hasta» y correos del responsable de una entrega de proveedor.
--    Lo llama la web DESPUÉS de ERP_CAF_SOLICITUD_EDITAR_DATOS (que ya decidió si la solicitud se puede editar); aquí se
--    repiten las condiciones básicas para que no sea una puerta lateral. También deja los teléfonos del responsable normalizados.
--    Estos datos son informativos: no reabren la aprobación.
--    100 ok | 101 no es suya | 400 validación | 404 no existe | 409 cancelada, rechazada o ya con ingreso | 500
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_PROVEEDOR_DATOS_GUARDAR"(
    IN    "HV_ID_Solicitud"          BIGINT,
    IN    "HV_Numeros_OC"            VARCHAR(200),
    IN    "HV_Empresa_Transportista" VARCHAR(200),
    IN    "HV_Hora_Hasta"            VARCHAR(5),
    IN    "HV_Contacto_Correos"      VARCHAR(500),
    IN    "HV_UsuarioID"             BIGINT,
    INOUT "HV_Codigo_Resp"           INT DEFAULT NULL,
    INOUT "HV_Mensaje"               VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_tipo   VARCHAR(50);
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_err    VARCHAR(250);
BEGIN
    -- V1.0 2026-11-13 (D-237)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PROVEEDOR_DATOS_GUARDAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";   -- serializa por solicitud
        SELECT COUNT(*), MAX(TA."Codigo"), MAX(S."ID_Usuario_Solicitante"), MAX(S."Estado"), MAX(S."Fecha_Hora_Prevista")
          INTO lv_n, lv_tipo, lv_owner, lv_estado, lv_fecha
          FROM "CAF_Solicitud" S JOIN "Catalogo_Tipo_Acceso" TA ON TA."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso"
         WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN; END IF;
        IF lv_tipo <> 'PROVEEDOR' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Estos datos corresponden solo a las entregas de proveedor.'; RETURN; END IF;
        IF lv_owner <> "HV_UsuarioID" THEN "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya.'; RETURN; END IF;
        IF lv_estado IN ('CANCELADA','RECHAZADA') THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud ya no admite cambios.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Estado" <> 'ESPERADA';
        IF lv_n > 0 THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Ya ingresó una persona: estos datos no se cambian.'; RETURN; END IF;

        lv_err := "ERP_CAF_FN_PROVEEDOR_DATOS_VALIDAR"("HV_Numeros_OC", "HV_Empresa_Transportista", lv_fecha, "HV_Hora_Hasta", "HV_Contacto_Correos");
        IF lv_err <> '' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := lv_err; RETURN; END IF;
        lv_err := "ERP_CAF_FN_TELEFONOS_VALIDAR"((SELECT S."Contacto_Telefonos" FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud"));
        IF lv_err <> '' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := lv_err; RETURN; END IF;

        UPDATE "CAF_Solicitud"
           SET "Numeros_OC"            = "ERP_CAF_FN_OC_NORMALIZAR"("HV_Numeros_OC"),
               "Empresa_Transportista" = NULLIF(TRIM("HV_Empresa_Transportista"), ''),
               "Hora_Hasta_Prevista"   = CASE WHEN NULLIF(TRIM(COALESCE("HV_Hora_Hasta", '')), '') IS NULL THEN NULL ELSE CAST(TRIM("HV_Hora_Hasta") AS TIME) END,
               "Contacto_Correos"      = NULLIF(TRIM("HV_Contacto_Correos"), ''),
               "Contacto_Telefonos"    = "ERP_CAF_FN_TELEFONOS_NORMALIZAR"("Contacto_Telefonos"),
               "UsuarioID_Update"      = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'EDITAR',
             'Actualizó la OC, la empresa transportista, la franja horaria o el correo del responsable de la entrega', "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Datos de la entrega actualizados.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PROVEEDOR_DATOS_GUARDAR';
    END;
END;
$$;
