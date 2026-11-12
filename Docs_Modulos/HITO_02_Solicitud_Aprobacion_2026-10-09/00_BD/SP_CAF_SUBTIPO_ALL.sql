-- =============================================================================
-- Archivo : SP_CAF_SUBTIPO_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Versión : V1.0 2026-11-12 (D-234)
-- Qué hace: administración de los subtipos (roles de persona) de cada tipo de ingreso y su asignación a la persona de una solicitud.
--   1 ERP_CAF_SUBTIPO_LISTAR                    subtipos (activos; con HV_Incluir_Inactivos = 'Y' también los desactivados)
--   2 ERP_CAF_SUBTIPO_CREAR                     alta; el primero de un tipo se vuelve predeterminado y hereda el checklist del tipo;
--                                               los siguientes pueden copiar el checklist de otro subtipo
--   3 ERP_CAF_SUBTIPO_ACTUALIZAR                nombre y orden (el código no cambia)
--   4 ERP_CAF_SUBTIPO_ESTADO                    activar / desactivar (nunca se borra; el predeterminado y TRANSPORTISTA no se desactivan)
--   5 ERP_CAF_SUBTIPO_PREDETERMINADO            cambia el subtipo predeterminado del tipo
--   6 ERP_CAF_SOLICITUD_PERSONA_SUBTIPO_ASIGNAR rol de una persona de una solicitud (lo usan Nueva solicitud y «Agregar persona»)
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_SUBTIPO_LISTAR  (reemplaza la V1.0 sin parámetros)
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS "ERP_CAF_SUBTIPO_LISTAR"();
CREATE OR REPLACE FUNCTION "ERP_CAF_SUBTIPO_LISTAR"("HV_Incluir_Inactivos" CHAR(1) DEFAULT 'N')
RETURNS TABLE ("ID_Tipo_Acceso_Subtipo" BIGINT, "ID_Catalogo_Tipo_Acceso" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR,
               "Orden" BIGINT, "Activo" CHAR(1), "Es_Predeterminado" CHAR(1), "Es_Sistema" CHAR(1), "Personas" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.1 2026-11-12 (D-234: + Orden, Activo, Es_Predeterminado, Es_Sistema, Personas) · V1.0 2026-11-11
    RETURN QUERY
    SELECT X."ID_Tipo_Acceso_Subtipo", X."ID_Catalogo_Tipo_Acceso", X."Codigo", X."Descripcion", X."Orden", X."Activo", X."Es_Predeterminado",
           CAST(CASE WHEN X."Codigo" = 'TRANSPORTISTA' THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST((SELECT COUNT(*) FROM "CAF_Solicitud_Persona" P WHERE P."ID_Tipo_Acceso_Subtipo" = X."ID_Tipo_Acceso_Subtipo") AS BIGINT)
      FROM "Tipo_Acceso_Subtipo" X
     WHERE X."Eliminado" = 'N' AND (X."Activo" = 'Y' OR COALESCE("HV_Incluir_Inactivos", 'N') = 'Y')
     ORDER BY X."ID_Catalogo_Tipo_Acceso", X."Orden", X."ID_Tipo_Acceso_Subtipo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SUBTIPO_LISTAR"('Y');

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_SUBTIPO_CREAR
--    Reglas: si el tipo aún no tiene subtipos, el nuevo es el predeterminado, recibe el checklist que el tipo tenía «para todos» y las
--    personas ya registradas pasan a ser de este subtipo. Si ya tiene, HV_ID_Subtipo_Copiar (opcional) copia el checklist de otro subtipo
--    del mismo tipo; sin él, el subtipo nace con el checklist vacío.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SUBTIPO_CREAR"(
    IN    "HV_ID_Catalogo_Tipo_Acceso" BIGINT,
    IN    "HV_Codigo"                  VARCHAR(50),
    IN    "HV_Descripcion"             VARCHAR(200),
    IN    "HV_ID_Subtipo_Copiar"       BIGINT,
    IN    "HV_UsuarioID"               BIGINT,
    INOUT "HV_ID_Subtipo_Result"       BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"             INT DEFAULT NULL,
    INOUT "HV_Mensaje"                 VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT;
    lv_cod    VARCHAR(50);
    lv_desc   VARCHAR(200);
    lv_primer BOOLEAN;
    lv_id     BIGINT;
    lv_orden  BIGINT;
BEGIN
    -- V1.0 2026-11-12
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SUBTIPO_CREAR'; "HV_ID_Subtipo_Result" := NULL;
    BEGIN
        lv_cod  := UPPER(TRIM(COALESCE("HV_Codigo", '')));
        lv_desc := TRIM(COALESCE("HV_Descripcion", ''));
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        IF lv_cod !~ '^[A-Z][A-Z0-9_]{1,49}$' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código admite letras, números y guion bajo (2 a 50), empezando por letra.'; RETURN; END IF;
        IF lv_desc = '' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Escriba el nombre del subtipo.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El tipo de ingreso no existe.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Subtipo" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Codigo" = lv_cod;
        IF lv_n > 0 THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Ya existe un subtipo con ese código en este tipo de ingreso.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Subtipo" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        lv_primer := (lv_n = 0);
        IF "HV_ID_Subtipo_Copiar" IS NOT NULL AND NOT lv_primer THEN
            SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Subtipo"
             WHERE "ID_Tipo_Acceso_Subtipo" = "HV_ID_Subtipo_Copiar" AND "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
            IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El subtipo del que se copia el checklist no pertenece a este tipo de ingreso.'; RETURN; END IF;
        END IF;

        SELECT COALESCE(MAX("Orden"), 0) + 1 INTO lv_orden FROM "Tipo_Acceso_Subtipo" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso";
        INSERT INTO "Tipo_Acceso_Subtipo" ("ID_Catalogo_Tipo_Acceso","Codigo","Descripcion","Orden","Es_Predeterminado","UsuarioID_Create")
        VALUES ("HV_ID_Catalogo_Tipo_Acceso", lv_cod, lv_desc, lv_orden, CASE WHEN lv_primer THEN 'Y' ELSE 'N' END, "HV_UsuarioID")
        RETURNING "ID_Tipo_Acceso_Subtipo" INTO lv_id;

        IF lv_primer THEN
            -- El checklist «de todo el tipo» pasa a este subtipo y las personas ya registradas son de este subtipo
            UPDATE "Tipo_Acceso_Item_Checklist" SET "ID_Tipo_Acceso_Subtipo" = lv_id, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "ID_Tipo_Acceso_Subtipo" IS NULL;
            UPDATE "CAF_Solicitud_Persona" P SET "ID_Tipo_Acceso_Subtipo" = lv_id
              FROM "CAF_Solicitud" S
             WHERE S."ID_Solicitud" = P."ID_Solicitud" AND S."ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND P."ID_Tipo_Acceso_Subtipo" IS NULL;
        ELSIF "HV_ID_Subtipo_Copiar" IS NOT NULL THEN
            INSERT INTO "Tipo_Acceso_Item_Checklist" ("ID_Catalogo_Tipo_Acceso","ID_Catalogo_Item_Checklist","ID_Tipo_Acceso_Subtipo","UsuarioID_Create")
            SELECT O."ID_Catalogo_Tipo_Acceso", O."ID_Catalogo_Item_Checklist", lv_id, "HV_UsuarioID"
              FROM "Tipo_Acceso_Item_Checklist" O
             WHERE O."ID_Tipo_Acceso_Subtipo" = "HV_ID_Subtipo_Copiar" AND O."Eliminado" = 'N';
        END IF;

        "HV_ID_Subtipo_Result" := lv_id; "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Subtipo creado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SUBTIPO_CREAR'; "HV_ID_Subtipo_Result" := NULL;
    END;
END;
$$;
-- Prueba: CALL "ERP_CAF_SUBTIPO_CREAR"(3, 'CONDUCTOR', 'Conductor', NULL, 0);

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_SUBTIPO_ACTUALIZAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SUBTIPO_ACTUALIZAR"(
    IN    "HV_ID_Tipo_Acceso_Subtipo" BIGINT,
    IN    "HV_Descripcion"            VARCHAR(200),
    IN    "HV_Orden"                  BIGINT,
    IN    "HV_UsuarioID"              BIGINT,
    INOUT "HV_Codigo_Resp"            INT DEFAULT NULL,
    INOUT "HV_Mensaje"                VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT;
BEGIN
    -- V1.0 2026-11-12
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SUBTIPO_ACTUALIZAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        IF TRIM(COALESCE("HV_Descripcion", '')) = '' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Escriba el nombre del subtipo.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Subtipo" WHERE "ID_Tipo_Acceso_Subtipo" = "HV_ID_Tipo_Acceso_Subtipo" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El subtipo no existe.'; RETURN; END IF;
        UPDATE "Tipo_Acceso_Subtipo" SET "Descripcion" = TRIM("HV_Descripcion"), "Orden" = COALESCE("HV_Orden", "Orden"),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Tipo_Acceso_Subtipo" = "HV_ID_Tipo_Acceso_Subtipo";
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Subtipo actualizado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SUBTIPO_ACTUALIZAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_SUBTIPO_ESTADO   (nunca se borra: las personas ya registradas conservan su rol)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SUBTIPO_ESTADO"(
    IN    "HV_ID_Tipo_Acceso_Subtipo" BIGINT,
    IN    "HV_Activo"                 CHAR(1),
    IN    "HV_UsuarioID"              BIGINT,
    INOUT "HV_Codigo_Resp"            INT DEFAULT NULL,
    INOUT "HV_Mensaje"                VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_cod  VARCHAR(50);
    lv_pred CHAR(1);
    lv_n    INT;
BEGIN
    -- V1.0 2026-11-12
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SUBTIPO_ESTADO';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        IF "HV_Activo" IS NULL OR "HV_Activo" NOT IN ('Y','N') THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Estado no válido.'; RETURN; END IF;
        SELECT "Codigo", "Es_Predeterminado" INTO lv_cod, lv_pred FROM "Tipo_Acceso_Subtipo" WHERE "ID_Tipo_Acceso_Subtipo" = "HV_ID_Tipo_Acceso_Subtipo" AND "Eliminado" = 'N';
        IF lv_cod IS NULL THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El subtipo no existe.'; RETURN; END IF;
        IF "HV_Activo" = 'N' THEN
            IF lv_pred = 'Y' THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Es el subtipo predeterminado: marque antes otro como predeterminado.'; RETURN; END IF;
            IF lv_cod = 'TRANSPORTISTA' THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'El subtipo Transportista lo usa el flujo de proveedores y no se desactiva.'; RETURN; END IF;
        END IF;
        UPDATE "Tipo_Acceso_Subtipo" SET "Activo" = "HV_Activo", "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Tipo_Acceso_Subtipo" = "HV_ID_Tipo_Acceso_Subtipo";
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := CASE WHEN "HV_Activo" = 'Y' THEN 'Subtipo activado.' ELSE 'Subtipo desactivado.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SUBTIPO_ESTADO';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_SUBTIPO_PREDETERMINADO
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SUBTIPO_PREDETERMINADO"(
    IN    "HV_ID_Tipo_Acceso_Subtipo" BIGINT,
    IN    "HV_UsuarioID"              BIGINT,
    INOUT "HV_Codigo_Resp"            INT DEFAULT NULL,
    INOUT "HV_Mensaje"                VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_tipo BIGINT;
    lv_act  CHAR(1);
BEGIN
    -- V1.0 2026-11-12
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SUBTIPO_PREDETERMINADO';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        SELECT "ID_Catalogo_Tipo_Acceso", "Activo" INTO lv_tipo, lv_act FROM "Tipo_Acceso_Subtipo" WHERE "ID_Tipo_Acceso_Subtipo" = "HV_ID_Tipo_Acceso_Subtipo" AND "Eliminado" = 'N';
        IF lv_tipo IS NULL THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El subtipo no existe.'; RETURN; END IF;
        IF lv_act <> 'Y' THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Active el subtipo antes de marcarlo como predeterminado.'; RETURN; END IF;
        UPDATE "Tipo_Acceso_Subtipo" SET "Es_Predeterminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo AND "Es_Predeterminado" = 'Y' AND "ID_Tipo_Acceso_Subtipo" <> "HV_ID_Tipo_Acceso_Subtipo";
        UPDATE "Tipo_Acceso_Subtipo" SET "Es_Predeterminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Tipo_Acceso_Subtipo" = "HV_ID_Tipo_Acceso_Subtipo";
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Subtipo predeterminado actualizado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SUBTIPO_PREDETERMINADO';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CAF_SOLICITUD_PERSONA_SUBTIPO_ASIGNAR
--    Fija el rol de una persona de la solicitud (se llama justo después de crear la solicitud o de agregar la persona).
--    La seguridad por usuario/solicitud la aplica la capa .NET (igual que el resto de rutinas de la solicitud).
--    Proveedor: TRANSPORTISTA va siempre con los datos del transportista (CAF_Solicitud_Transportista); no se asigna aquí.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_PERSONA_SUBTIPO_ASIGNAR"(
    IN    "HV_ID_Solicitud"           BIGINT,
    IN    "HV_ID_Persona_Externa"     BIGINT,
    IN    "HV_ID_Tipo_Acceso_Subtipo" BIGINT,
    IN    "HV_UsuarioID"              BIGINT,
    INOUT "HV_Codigo_Resp"            INT DEFAULT NULL,
    INOUT "HV_Mensaje"                VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_tipo   BIGINT;
    lv_estado VARCHAR(30);
    lv_sp     BIGINT;
    lv_cod    VARCHAR(50);
    lv_es_tr  INT;
BEGIN
    -- V1.0 2026-11-12
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_SUBTIPO_ASIGNAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        SELECT S."ID_Catalogo_Tipo_Acceso", S."Estado" INTO lv_tipo, lv_estado FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_tipo IS NULL THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN; END IF;
        IF lv_estado = 'CANCELADA' THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN; END IF;
        SELECT MAX(P."ID_Solicitud_Persona") INTO lv_sp FROM "CAF_Solicitud_Persona" P
         WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."ID_Persona_Externa" = "HV_ID_Persona_Externa" AND P."Eliminado" = 'N' AND P."Aprobacion" <> 'RETIRADA';
        IF lv_sp IS NULL THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no figura en la solicitud.'; RETURN; END IF;
        SELECT X."Codigo" INTO lv_cod FROM "Tipo_Acceso_Subtipo" X
         WHERE X."ID_Tipo_Acceso_Subtipo" = "HV_ID_Tipo_Acceso_Subtipo" AND X."ID_Catalogo_Tipo_Acceso" = lv_tipo AND X."Eliminado" = 'N' AND X."Activo" = 'Y';
        IF lv_cod IS NULL THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El rol elegido no es válido para este tipo de ingreso.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_es_tr FROM "CAF_Solicitud_Transportista" T WHERE T."ID_Solicitud_Persona" = lv_sp AND T."Eliminado" = 'N';
        IF lv_cod = 'TRANSPORTISTA' AND lv_es_tr = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El rol Transportista requiere los datos del transportista.'; RETURN;
        END IF;
        IF lv_cod <> 'TRANSPORTISTA' AND lv_es_tr > 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La persona figura como transportista: su rol no se cambia desde aquí.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud_Persona" SET "ID_Tipo_Acceso_Subtipo" = "HV_ID_Tipo_Acceso_Subtipo", "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = lv_sp AND "ID_Tipo_Acceso_Subtipo" IS DISTINCT FROM "HV_ID_Tipo_Acceso_Subtipo";
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Rol de la persona registrado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_SUBTIPO_ASIGNAR';
    END;
END;
$$;
