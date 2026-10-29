-- =============================================================================
-- Archivo : SP_CAF_SOLICITUD_ADJUNTO_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobación | Documentos adjuntos de la solicitud (D-183, D-184)
-- Versión : V1.0 2026-10-29
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO2_ADJUNTOS.sql)
-- Requiere: 15_CAF_SOLICITUD_ADJUNTO.sql, SP_CAF_SOLICITUD_BASE_ALL.sql, SP_CAF_SOLICITUD_LECTURA_ALL.sql
-- =============================================================================
--   1 ERP_CAF_FN_ADJUNTO_VISIBLE          quién puede ver los documentos de una solicitud
--   2 ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR   el solicitante adjunta un documento (máx. 2, 5 MB)
--   3 ERP_CAF_SOLICITUD_ADJUNTO_QUITAR    el solicitante retira un documento (borrado lógico)
--   4 ERP_CAF_SOLICITUD_ADJUNTO_LISTAR    lista (sin contenido) lo que el usuario puede ver
--   5 ERP_CAF_SOLICITUD_ADJUNTO_OBTENER   un documento con su contenido, si el usuario puede verlo
--   6 ERP_CAF_SOLICITUD_ADJUNTO_CORREO    solo el proceso de envío (UsuarioID 0): documentos para el correo
-- Quién ve los documentos (D-184): el solicitante dueño, quien ve la solicitud (Coordinación o aprobador de
-- un paso) y Vigilancia (PER_CAF_PORTERIA_VER/REGISTRAR en la sede) desde que haya AL MENOS UNA persona
-- aprobada, aunque otras sigan observadas: no espera a que toda la solicitud esté aprobada.
-- Quién modifica: solo el dueño y solo mientras puede editar los datos de la solicitud.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_FN_ADJUNTO_VISIBLE
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ADJUNTO_VISIBLE"("HV_ID_Usuario" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n    INT := 0;
    lv_sede BIGINT;
    lv_est  VARCHAR(20);
BEGIN
    -- V1.0 2026-10-29
    IF "HV_ID_Usuario" IS NULL OR "HV_ID_Usuario" <= 0 THEN RETURN 'N'; END IF;
    IF "ERP_CAF_FN_SOLICITUD_VISIBLE"("HV_ID_Usuario", "HV_ID_Solicitud") = 'Y' THEN RETURN 'Y'; END IF;
    SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("Estado") INTO lv_n, lv_sede, lv_est
      FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
    IF lv_n = 0 OR lv_est = 'CANCELADA' THEN RETURN 'N'; END IF;
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_ID_Usuario", 'PER_CAF_PORTERIA_VER', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_ID_Usuario", 'PER_CAF_PORTERIA_REGISTRAR', lv_sede) = 'Y' THEN
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona" P
         WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'APROBADA';
        IF lv_n > 0 THEN RETURN 'Y'; END IF;
    END IF;
    RETURN 'N';
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR
--    101 no es el dueño | 404 | 409 no se puede editar / ya hay 2 / ya está adjunto | 400 validación
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(
    IN    "HV_ID_Solicitud"      BIGINT,
    IN    "HV_Nombre_Archivo"    VARCHAR(500),
    IN    "HV_Tipo_Contenido"    VARCHAR(100),
    IN    "HV_Contenido"         BYTEA,
    IN    "HV_UsuarioID"         BIGINT,
    INOUT "HV_ID_Adjunto_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"       INT DEFAULT NULL,
    INOUT "HV_Mensaje"           VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_owner  BIGINT;
    lv_nombre VARCHAR(500);
    lv_ext    VARCHAR(10);
    lv_hash   VARCHAR(64);
    lv_ed     CHAR(1);
    lv_motivo VARCHAR(250);
    lv_c      INT;
    lv_m      VARCHAR(250);
BEGIN
    -- V1.0 2026-10-29
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR';
    "HV_ID_Adjunto_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <= 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("ID_Usuario_Solicitante") INTO lv_n, lv_owner
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN; END IF;
        IF lv_owner <> "HV_UsuarioID" THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo quien creó la solicitud puede adjuntar documentos.'; RETURN;
        END IF;
        SELECT I."Editar_Datos", I."Motivo_Editar_Datos" INTO lv_ed, lv_motivo FROM "ERP_CAF_SOLICITUD_INDICADORES"("HV_ID_Solicitud") I;
        IF lv_ed IS DISTINCT FROM 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := LEFT('No se pueden modificar los documentos: ' || COALESCE(lv_motivo, 'la solicitud ya no admite cambios.'), 250); RETURN;
        END IF;

        -- Nombre: sin carpetas, sin caracteres de control, con extensión permitida
        lv_nombre := TRIM(REGEXP_REPLACE(COALESCE("HV_Nombre_Archivo", ''), '^.*[\\/]', ''));
        lv_nombre := REGEXP_REPLACE(lv_nombre, '[[:cntrl:]]', '', 'g');
        IF LENGTH(lv_nombre) = 0 OR LENGTH(lv_nombre) > 200 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El nombre del archivo debe tener entre 1 y 200 caracteres.'; RETURN;
        END IF;
        lv_ext := LOWER(SUBSTRING(lv_nombre FROM '\.([^.]+)$'));
        IF lv_ext IS NULL OR lv_ext NOT IN ('pdf','doc','docx','xls','xlsx') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Solo se permiten archivos PDF, Word (DOC, DOCX) y Excel (XLS, XLSX).'; RETURN;
        END IF;
        IF "HV_Contenido" IS NULL OR LENGTH("HV_Contenido") = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El archivo está vacío.'; RETURN;
        END IF;
        IF LENGTH("HV_Contenido") > 5242880 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El archivo supera el máximo de 5 MB.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Adjunto" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n >= 2 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Una solicitud admite como máximo 2 documentos. Retire uno para agregar otro.'; RETURN;
        END IF;
        lv_hash := ENCODE(SHA256("HV_Contenido"), 'hex');
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Adjunto" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Hash_SHA256" = lv_hash;
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Ese documento ya está adjunto a la solicitud.'; RETURN;
        END IF;

        INSERT INTO "CAF_Solicitud_Adjunto" ("ID_Solicitud","Nombre_Archivo","Extension","Tipo_Contenido","Tamano_Bytes","Hash_SHA256","Contenido","UsuarioID_Create")
        VALUES ("HV_ID_Solicitud", lv_nombre, lv_ext, LEFT(COALESCE("HV_Tipo_Contenido", 'application/octet-stream'), 100), LENGTH("HV_Contenido"), lv_hash, "HV_Contenido", "HV_UsuarioID")
        RETURNING "ID_Solicitud_Adjunto" INTO "HV_ID_Adjunto_Result";

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'ADJUNTO_AGREGAR', 'Documento: ' || lv_nombre, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Documento adjuntado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR';
        "HV_ID_Adjunto_Result" := 0;
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_SOLICITUD_ADJUNTO_QUITAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_ADJUNTO_QUITAR"(
    IN    "HV_ID_Solicitud_Adjunto" BIGINT,
    IN    "HV_UsuarioID"            BIGINT,
    INOUT "HV_Codigo_Resp"          INT DEFAULT NULL,
    INOUT "HV_Mensaje"              VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sol    BIGINT;
    lv_nombre VARCHAR(200);
    lv_owner  BIGINT;
    lv_ed     CHAR(1);
    lv_motivo VARCHAR(250);
    lv_c      INT;
    lv_m      VARCHAR(250);
BEGIN
    -- V1.0 2026-10-29
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_ADJUNTO_QUITAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <= 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT A."ID_Solicitud", A."Nombre_Archivo", S."ID_Usuario_Solicitante" INTO lv_sol, lv_nombre, lv_owner
          FROM "CAF_Solicitud_Adjunto" A JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = A."ID_Solicitud"
         WHERE A."ID_Solicitud_Adjunto" = "HV_ID_Solicitud_Adjunto" AND A."Eliminado" = 'N';
        IF lv_sol IS NULL THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El documento no existe.'; RETURN; END IF;
        IF lv_owner <> "HV_UsuarioID" THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo quien creó la solicitud puede retirar documentos.'; RETURN;
        END IF;
        SELECT I."Editar_Datos", I."Motivo_Editar_Datos" INTO lv_ed, lv_motivo FROM "ERP_CAF_SOLICITUD_INDICADORES"(lv_sol) I;
        IF lv_ed IS DISTINCT FROM 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := LEFT('No se pueden modificar los documentos: ' || COALESCE(lv_motivo, 'la solicitud ya no admite cambios.'), 250); RETURN;
        END IF;

        UPDATE "CAF_Solicitud_Adjunto" SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Adjunto" = "HV_ID_Solicitud_Adjunto";
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', lv_sol, lv_sol, 'ADJUNTO_QUITAR', 'Documento: ' || lv_nombre, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Documento retirado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_ADJUNTO_QUITAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_SOLICITUD_ADJUNTO_LISTAR   (sin contenido; vacío si el usuario no puede ver)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Solicitud_Adjunto" BIGINT, "ID_Solicitud" BIGINT, "Nombre_Archivo" VARCHAR, "Extension" VARCHAR,
               "Tamano_Bytes" BIGINT, "Fecha" TIMESTAMP, "Puede_Quitar" CHAR(1))
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_owner BIGINT;
    lv_ed    CHAR(1);
BEGIN
    -- V1.0 2026-10-29
    IF "ERP_CAF_FN_ADJUNTO_VISIBLE"("HV_UsuarioID", "HV_ID_Solicitud") <> 'Y' THEN RETURN; END IF;
    SELECT S."ID_Usuario_Solicitante" INTO lv_owner FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud";
    SELECT I."Editar_Datos" INTO lv_ed FROM "ERP_CAF_SOLICITUD_INDICADORES"("HV_ID_Solicitud") I;
    RETURN QUERY
    SELECT A."ID_Solicitud_Adjunto", A."ID_Solicitud", A."Nombre_Archivo", A."Extension", A."Tamano_Bytes", A."CreateDate",
           CAST(CASE WHEN lv_owner = "HV_UsuarioID" AND lv_ed = 'Y' THEN 'Y' ELSE 'N' END AS CHAR(1))
      FROM "CAF_Solicitud_Adjunto" A
     WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."Eliminado" = 'N'
     ORDER BY A."ID_Solicitud_Adjunto";
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_SOLICITUD_ADJUNTO_OBTENER   (con contenido; vacío si el usuario no puede ver)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_ADJUNTO_OBTENER"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud_Adjunto" BIGINT)
RETURNS TABLE ("ID_Solicitud_Adjunto" BIGINT, "ID_Solicitud" BIGINT, "Nombre_Archivo" VARCHAR, "Extension" VARCHAR,
               "Tamano_Bytes" BIGINT, "Contenido" BYTEA)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_sol BIGINT;
BEGIN
    -- V1.0 2026-10-29
    SELECT A."ID_Solicitud" INTO lv_sol FROM "CAF_Solicitud_Adjunto" A WHERE A."ID_Solicitud_Adjunto" = "HV_ID_Solicitud_Adjunto" AND A."Eliminado" = 'N';
    IF lv_sol IS NULL OR "ERP_CAF_FN_ADJUNTO_VISIBLE"("HV_UsuarioID", lv_sol) <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT A."ID_Solicitud_Adjunto", A."ID_Solicitud", A."Nombre_Archivo", A."Extension", A."Tamano_Bytes", A."Contenido"
      FROM "CAF_Solicitud_Adjunto" A WHERE A."ID_Solicitud_Adjunto" = "HV_ID_Solicitud_Adjunto" AND A."Eliminado" = 'N';
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CAF_SOLICITUD_ADJUNTO_CORREO   (solo el proceso de envío, UsuarioID 0, D-12)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_ADJUNTO_CORREO"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Solicitud_Adjunto" BIGINT, "Nombre_Archivo" VARCHAR, "Extension" VARCHAR, "Contenido" BYTEA)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-29
    IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <> 0 THEN RETURN; END IF;
    RETURN QUERY
    SELECT A."ID_Solicitud_Adjunto", A."Nombre_Archivo", A."Extension", A."Contenido"
      FROM "CAF_Solicitud_Adjunto" A WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."Eliminado" = 'N'
     ORDER BY A."ID_Solicitud_Adjunto";
END;
$$;
