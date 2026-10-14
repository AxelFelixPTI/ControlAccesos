-- =============================================================================
-- Archivo : SP_GOVERNANCE_PERSONAL_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : CAF_GOVERNANCE
-- Hito    : 0 - Base | Fase 1 - Procedimientos
-- Entidad : Personal (trabajadores; de aquí sale el responsable de atención)
-- Versión : V1.0 2026-10-11
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO0.sql)
-- =============================================================================
-- 1 LISTAR · 2 CREAR · 3 DETALLE · 4 ACTUALIZAR · 5 ELIMINAR
-- Especiales: 6 DETALLE_POR_DOCUMENTO ("¿quién es este DNI?", identidad exacta)
--             7 BUSCAR (candidatos para responsable de atención, máx. 6; HU-02)
-- LISTAR filtra por nombre SOLO contra el nombre; el documento se busca con
-- DETALLE_POR_DOCUMENTO (regla Trianon §3.1: identidad nunca por texto libre).
-- =============================================================================

SET search_path TO "CAF_GOVERNANCE";

-- -----------------------------------------------------------------------------
-- 1. ERP_PERSONAL_LISTAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_PERSONAL_LISTAR"(
    "HV_Filtro_Nombre"      VARCHAR DEFAULT NULL,
    "HV_ID_Catalogo_Area"   BIGINT  DEFAULT NULL,
    "HV_ID_Catalogo_Sede"   BIGINT  DEFAULT NULL,
    "HV_Incluir_Eliminados" CHAR(1) DEFAULT 'N'
)
RETURNS TABLE ("ID_Personal" BIGINT, "ID_Catalogo_Tipo_Documento" BIGINT, "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR,
               "Apellido_Paterno" VARCHAR, "Apellido_Materno" VARCHAR, "Nombres" VARCHAR, "Nombre_Completo" VARCHAR,
               "ID_Catalogo_Area" BIGINT, "Area" VARCHAR, "ID_Catalogo_Cargo" BIGINT, "Cargo" VARCHAR,
               "ID_Catalogo_Empresa_Grupo" BIGINT, "Empresa" VARCHAR, "ID_Catalogo_Sede" BIGINT, "Sede" VARCHAR,
               "Correo" VARCHAR, "Anexo" VARCHAR, "Tiene_Usuario" CHAR(1),
               "Activo" CHAR(1), "Eliminado" CHAR(1), "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR,
               "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Personal", T0."ID_Catalogo_Tipo_Documento", TD."Codigo", T0."Numero_Documento",
           T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres",
           CAST(T0."Apellido_Paterno" || COALESCE(' ' || T0."Apellido_Materno", '') || ', ' || T0."Nombres" AS VARCHAR),
           T0."ID_Catalogo_Area", A."Descripcion", T0."ID_Catalogo_Cargo", CG."Descripcion",
           T0."ID_Catalogo_Empresa_Grupo", E."Descripcion", T0."ID_Catalogo_Sede", S."Descripcion",
           T0."Correo", T0."Anexo",
           CAST(CASE WHEN EXISTS (SELECT 1 FROM "Usuario" U WHERE U."ID_Personal" = T0."ID_Personal" AND U."Eliminado" = 'N') THEN 'Y' ELSE 'N' END AS CHAR(1)),
           T0."Activo", T0."Eliminado", T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Personal" T0
      JOIN "Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = T0."ID_Catalogo_Tipo_Documento"
      JOIN "Catalogo_Area" A           ON A."ID_Catalogo_Area" = T0."ID_Catalogo_Area"
      LEFT JOIN "Catalogo_Cargo" CG    ON CG."ID_Catalogo_Cargo" = T0."ID_Catalogo_Cargo"
      JOIN "Catalogo_Empresa_Grupo" E  ON E."ID_Catalogo_Empresa_Grupo" = T0."ID_Catalogo_Empresa_Grupo"
      JOIN "Catalogo_Sede" S           ON S."ID_Catalogo_Sede" = T0."ID_Catalogo_Sede"
      LEFT JOIN "Usuario" T1           ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
       AND ("HV_Filtro_Nombre" IS NULL OR UPPER(T0."Apellido_Paterno" || ' ' || COALESCE(T0."Apellido_Materno",'') || ' ' || T0."Nombres") LIKE '%' || UPPER(TRIM("HV_Filtro_Nombre")) || '%')
       AND ("HV_ID_Catalogo_Area" IS NULL OR T0."ID_Catalogo_Area" = "HV_ID_Catalogo_Area")
       AND ("HV_ID_Catalogo_Sede" IS NULL OR T0."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede")
     ORDER BY T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres";
END;
$$;
-- Prueba: SELECT * FROM "ERP_PERSONAL_LISTAR"('nuñez');

-- -----------------------------------------------------------------------------
-- 2. ERP_PERSONAL_CREAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_PERSONAL_CREAR"(
    IN    "HV_ID_Catalogo_Tipo_Documento" BIGINT,
    IN    "HV_Numero_Documento"           VARCHAR(20),
    IN    "HV_Apellido_Paterno"           VARCHAR(100),
    IN    "HV_Apellido_Materno"           VARCHAR(100),
    IN    "HV_Nombres"                    VARCHAR(200),
    IN    "HV_ID_Catalogo_Area"           BIGINT,
    IN    "HV_ID_Catalogo_Cargo"          BIGINT,
    IN    "HV_ID_Catalogo_Empresa_Grupo"  BIGINT,
    IN    "HV_ID_Catalogo_Sede"           BIGINT,
    IN    "HV_Correo"                     VARCHAR(200),
    IN    "HV_Anexo"                      VARCHAR(20),
    IN    "HV_Activo"                     CHAR(1),
    IN    "HV_UsuarioID_Create"           BIGINT,
    INOUT "HV_ID_Personal_Result"         BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"                INT DEFAULT NULL,
    INOUT "HV_Mensaje"                    VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
DECLARE
    lv_min  BIGINT;
    lv_max  BIGINT;
    lv_solo CHAR(1);
    lv_n    INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_PERSONAL_CREAR';
    "HV_ID_Personal_Result" := 0;
    BEGIN
        -- Obligatorios
        IF "HV_Apellido_Paterno" IS NULL OR LENGTH(TRIM("HV_Apellido_Paterno")) = 0
        OR "HV_Nombres" IS NULL OR LENGTH(TRIM("HV_Nombres")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Apellido paterno y nombres son obligatorios.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_Correo" IS NOT NULL AND LENGTH(TRIM("HV_Correo")) > 0 AND POSITION('@' IN "HV_Correo") = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El correo no es válido.'; RETURN;
        END IF;

        -- Documento según su tipo
        SELECT MAX("Longitud_Min"), MAX("Longitud_Max"), MAX("Solo_Numeros") INTO lv_min, lv_max, lv_solo
          FROM "Catalogo_Tipo_Documento"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_min IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de documento no existe o está inactivo.'; RETURN;
        END IF;
        IF "HV_Numero_Documento" IS NULL OR LENGTH(TRIM("HV_Numero_Documento")) NOT BETWEEN lv_min AND lv_max THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El documento debe tener entre ' || lv_min || ' y ' || lv_max || ' caracteres.'; RETURN;
        END IF;
        IF lv_solo = 'Y' AND LTRIM(TRIM("HV_Numero_Documento"), '0123456789') <> '' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El documento solo admite números.'; RETURN;
        END IF;

        -- Catálogos referenciados
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Area" WHERE "ID_Catalogo_Area" = "HV_ID_Catalogo_Area" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El área no existe o está inactiva.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Empresa_Grupo" WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Catalogo_Empresa_Grupo" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La empresa no existe o está inactiva.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Sede" WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La sede no existe o está inactiva.'; RETURN; END IF;
        IF "HV_ID_Catalogo_Cargo" IS NOT NULL THEN
            SELECT COUNT(*) INTO lv_n FROM "Catalogo_Cargo" WHERE "ID_Catalogo_Cargo" = "HV_ID_Catalogo_Cargo" AND "Eliminado" = 'N' AND "Activo" = 'Y';
            IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El cargo no existe o está inactivo.'; RETURN; END IF;
        END IF;

        -- Duplicado (el UNIQUE incluye eliminados)
        SELECT COUNT(*) INTO lv_n FROM "Personal"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Numero_Documento" = TRIM("HV_Numero_Documento");
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un trabajador con ese documento (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres",
                                "ID_Catalogo_Area","ID_Catalogo_Cargo","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede",
                                "Correo","Anexo","Activo","UsuarioID_Create")
        VALUES ("HV_ID_Catalogo_Tipo_Documento", TRIM("HV_Numero_Documento"), TRIM("HV_Apellido_Paterno"), NULLIF(TRIM("HV_Apellido_Materno"),''), TRIM("HV_Nombres"),
                "HV_ID_Catalogo_Area", "HV_ID_Catalogo_Cargo", "HV_ID_Catalogo_Empresa_Grupo", "HV_ID_Catalogo_Sede",
                NULLIF(LOWER(TRIM("HV_Correo")),''), NULLIF(TRIM("HV_Anexo"),''), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Personal" INTO "HV_ID_Personal_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Trabajador registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_PERSONAL_CREAR';
        "HV_ID_Personal_Result" := 0;
    END;
END;
$$;
-- Prueba: CALL "ERP_PERSONAL_CREAR"(1,'12345678','Prueba','Test','Ana',1,NULL,1,1,'ana@ejemplo.pe','100','Y',0);

-- -----------------------------------------------------------------------------
-- 3. ERP_PERSONAL_DETALLE  (no filtra Eliminado; mismas columnas que LISTAR)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_PERSONAL_DETALLE"("HV_ID_Personal" BIGINT)
RETURNS TABLE ("ID_Personal" BIGINT, "ID_Catalogo_Tipo_Documento" BIGINT, "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR,
               "Apellido_Paterno" VARCHAR, "Apellido_Materno" VARCHAR, "Nombres" VARCHAR, "Nombre_Completo" VARCHAR,
               "ID_Catalogo_Area" BIGINT, "Area" VARCHAR, "ID_Catalogo_Cargo" BIGINT, "Cargo" VARCHAR,
               "ID_Catalogo_Empresa_Grupo" BIGINT, "Empresa" VARCHAR, "ID_Catalogo_Sede" BIGINT, "Sede" VARCHAR,
               "Correo" VARCHAR, "Anexo" VARCHAR, "Tiene_Usuario" CHAR(1),
               "Activo" CHAR(1), "Eliminado" CHAR(1), "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR,
               "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Personal", T0."ID_Catalogo_Tipo_Documento", TD."Codigo", T0."Numero_Documento",
           T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres",
           CAST(T0."Apellido_Paterno" || COALESCE(' ' || T0."Apellido_Materno", '') || ', ' || T0."Nombres" AS VARCHAR),
           T0."ID_Catalogo_Area", A."Descripcion", T0."ID_Catalogo_Cargo", CG."Descripcion",
           T0."ID_Catalogo_Empresa_Grupo", E."Descripcion", T0."ID_Catalogo_Sede", S."Descripcion",
           T0."Correo", T0."Anexo",
           CAST(CASE WHEN EXISTS (SELECT 1 FROM "Usuario" U WHERE U."ID_Personal" = T0."ID_Personal" AND U."Eliminado" = 'N') THEN 'Y' ELSE 'N' END AS CHAR(1)),
           T0."Activo", T0."Eliminado", T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Personal" T0
      JOIN "Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = T0."ID_Catalogo_Tipo_Documento"
      JOIN "Catalogo_Area" A           ON A."ID_Catalogo_Area" = T0."ID_Catalogo_Area"
      LEFT JOIN "Catalogo_Cargo" CG    ON CG."ID_Catalogo_Cargo" = T0."ID_Catalogo_Cargo"
      JOIN "Catalogo_Empresa_Grupo" E  ON E."ID_Catalogo_Empresa_Grupo" = T0."ID_Catalogo_Empresa_Grupo"
      JOIN "Catalogo_Sede" S           ON S."ID_Catalogo_Sede" = T0."ID_Catalogo_Sede"
      LEFT JOIN "Usuario" T1           ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Personal" = "HV_ID_Personal";
END;
$$;
-- Prueba: SELECT * FROM "ERP_PERSONAL_DETALLE"(1);

-- -----------------------------------------------------------------------------
-- 4. ERP_PERSONAL_ACTUALIZAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_PERSONAL_ACTUALIZAR"(
    IN    "HV_ID_Personal"                BIGINT,
    IN    "HV_ID_Catalogo_Tipo_Documento" BIGINT,
    IN    "HV_Numero_Documento"           VARCHAR(20),
    IN    "HV_Apellido_Paterno"           VARCHAR(100),
    IN    "HV_Apellido_Materno"           VARCHAR(100),
    IN    "HV_Nombres"                    VARCHAR(200),
    IN    "HV_ID_Catalogo_Area"           BIGINT,
    IN    "HV_ID_Catalogo_Cargo"          BIGINT,
    IN    "HV_ID_Catalogo_Empresa_Grupo"  BIGINT,
    IN    "HV_ID_Catalogo_Sede"           BIGINT,
    IN    "HV_Correo"                     VARCHAR(200),
    IN    "HV_Anexo"                      VARCHAR(20),
    IN    "HV_Activo"                     CHAR(1),
    IN    "HV_UsuarioID"                  BIGINT,
    INOUT "HV_Codigo_Resp"                INT DEFAULT NULL,
    INOUT "HV_Mensaje"                    VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
DECLARE
    lv_min  BIGINT;
    lv_max  BIGINT;
    lv_solo CHAR(1);
    lv_n    INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_PERSONAL_ACTUALIZAR';
    BEGIN
        IF "HV_Apellido_Paterno" IS NULL OR LENGTH(TRIM("HV_Apellido_Paterno")) = 0
        OR "HV_Nombres" IS NULL OR LENGTH(TRIM("HV_Nombres")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Apellido paterno y nombres son obligatorios.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_Correo" IS NOT NULL AND LENGTH(TRIM("HV_Correo")) > 0 AND POSITION('@' IN "HV_Correo") = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El correo no es válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Personal" WHERE "ID_Personal" = "HV_ID_Personal" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El trabajador no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT MAX("Longitud_Min"), MAX("Longitud_Max"), MAX("Solo_Numeros") INTO lv_min, lv_max, lv_solo
          FROM "Catalogo_Tipo_Documento"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_min IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de documento no existe o está inactivo.'; RETURN;
        END IF;
        IF "HV_Numero_Documento" IS NULL OR LENGTH(TRIM("HV_Numero_Documento")) NOT BETWEEN lv_min AND lv_max THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El documento debe tener entre ' || lv_min || ' y ' || lv_max || ' caracteres.'; RETURN;
        END IF;
        IF lv_solo = 'Y' AND LTRIM(TRIM("HV_Numero_Documento"), '0123456789') <> '' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El documento solo admite números.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Area" WHERE "ID_Catalogo_Area" = "HV_ID_Catalogo_Area" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El área no existe.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Empresa_Grupo" WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Catalogo_Empresa_Grupo" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La empresa no existe.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Sede" WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La sede no existe.'; RETURN; END IF;
        IF "HV_ID_Catalogo_Cargo" IS NOT NULL THEN
            SELECT COUNT(*) INTO lv_n FROM "Catalogo_Cargo" WHERE "ID_Catalogo_Cargo" = "HV_ID_Catalogo_Cargo" AND "Eliminado" = 'N';
            IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El cargo no existe.'; RETURN; END IF;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Personal"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Numero_Documento" = TRIM("HV_Numero_Documento")
           AND "ID_Personal" <> "HV_ID_Personal";
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro trabajador con ese documento.'; RETURN;
        END IF;

        UPDATE "Personal"
           SET "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento", "Numero_Documento" = TRIM("HV_Numero_Documento"),
               "Apellido_Paterno" = TRIM("HV_Apellido_Paterno"), "Apellido_Materno" = NULLIF(TRIM("HV_Apellido_Materno"),''),
               "Nombres" = TRIM("HV_Nombres"), "ID_Catalogo_Area" = "HV_ID_Catalogo_Area", "ID_Catalogo_Cargo" = "HV_ID_Catalogo_Cargo",
               "ID_Catalogo_Empresa_Grupo" = "HV_ID_Catalogo_Empresa_Grupo", "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede",
               "Correo" = NULLIF(LOWER(TRIM("HV_Correo")),''), "Anexo" = NULLIF(TRIM("HV_Anexo"),''),
               "Activo" = COALESCE("HV_Activo",'Y'), "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Personal" = "HV_ID_Personal";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Trabajador actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_PERSONAL_ACTUALIZAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_PERSONAL_ELIMINAR  (no si tiene una cuenta de usuario vigente)
--    Un trabajador que cesa se DESACTIVA (Activo = 'N'); eliminar es para errores.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_PERSONAL_ELIMINAR"(
    IN    "HV_ID_Personal"      BIGINT,
    IN    "HV_UsuarioID_Update" BIGINT,
    INOUT "HV_Codigo_Resp"      INT DEFAULT NULL,
    INOUT "HV_Mensaje"          VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_PERSONAL_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Personal" WHERE "ID_Personal" = "HV_ID_Personal" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El trabajador no existe o ya fue eliminado.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Usuario" WHERE "ID_Personal" = "HV_ID_Personal" AND "Eliminado" = 'N';
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Tiene una cuenta de usuario vigente. Desactívelo en vez de eliminarlo.'; RETURN;
        END IF;

        UPDATE "Personal"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Personal" = "HV_ID_Personal";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Trabajador eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_PERSONAL_ELIMINAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_PERSONAL_DETALLE_POR_DOCUMENTO  (identidad exacta; solo no eliminados)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_PERSONAL_DETALLE_POR_DOCUMENTO"(
    "HV_ID_Catalogo_Tipo_Documento" BIGINT,
    "HV_Numero_Documento"           VARCHAR
)
RETURNS TABLE ("ID_Personal" BIGINT, "ID_Catalogo_Tipo_Documento" BIGINT, "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR,
               "Apellido_Paterno" VARCHAR, "Apellido_Materno" VARCHAR, "Nombres" VARCHAR, "Nombre_Completo" VARCHAR,
               "ID_Catalogo_Area" BIGINT, "Area" VARCHAR, "ID_Catalogo_Cargo" BIGINT, "Cargo" VARCHAR,
               "ID_Catalogo_Empresa_Grupo" BIGINT, "Empresa" VARCHAR, "ID_Catalogo_Sede" BIGINT, "Sede" VARCHAR,
               "Correo" VARCHAR, "Anexo" VARCHAR, "Tiene_Usuario" CHAR(1),
               "Activo" CHAR(1), "Eliminado" CHAR(1), "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR,
               "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Personal", T0."ID_Catalogo_Tipo_Documento", TD."Codigo", T0."Numero_Documento",
           T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres",
           CAST(T0."Apellido_Paterno" || COALESCE(' ' || T0."Apellido_Materno", '') || ', ' || T0."Nombres" AS VARCHAR),
           T0."ID_Catalogo_Area", A."Descripcion", T0."ID_Catalogo_Cargo", CG."Descripcion",
           T0."ID_Catalogo_Empresa_Grupo", E."Descripcion", T0."ID_Catalogo_Sede", S."Descripcion",
           T0."Correo", T0."Anexo",
           CAST(CASE WHEN EXISTS (SELECT 1 FROM "Usuario" U WHERE U."ID_Personal" = T0."ID_Personal" AND U."Eliminado" = 'N') THEN 'Y' ELSE 'N' END AS CHAR(1)),
           T0."Activo", T0."Eliminado", T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Personal" T0
      JOIN "Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = T0."ID_Catalogo_Tipo_Documento"
      JOIN "Catalogo_Area" A           ON A."ID_Catalogo_Area" = T0."ID_Catalogo_Area"
      LEFT JOIN "Catalogo_Cargo" CG    ON CG."ID_Catalogo_Cargo" = T0."ID_Catalogo_Cargo"
      JOIN "Catalogo_Empresa_Grupo" E  ON E."ID_Catalogo_Empresa_Grupo" = T0."ID_Catalogo_Empresa_Grupo"
      JOIN "Catalogo_Sede" S           ON S."ID_Catalogo_Sede" = T0."ID_Catalogo_Sede"
      LEFT JOIN "Usuario" T1           ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento"
       AND T0."Numero_Documento" = TRIM("HV_Numero_Documento")
       AND T0."Eliminado" = 'N';
END;
$$;
-- Prueba: SELECT * FROM "ERP_PERSONAL_DETALLE_POR_DOCUMENTO"(1,'45120933');

-- -----------------------------------------------------------------------------
-- 7. ERP_PERSONAL_BUSCAR  (responsable de atención: por nombre o área; máx. 6)
--    Solo trabajadores activos. Requiere al menos 2 caracteres.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_PERSONAL_BUSCAR"(
    "HV_Texto"            VARCHAR,
    "HV_ID_Catalogo_Sede" BIGINT DEFAULT NULL
)
RETURNS TABLE ("ID_Personal" BIGINT, "Nombre_Completo" VARCHAR, "Area" VARCHAR, "Cargo" VARCHAR, "Anexo" VARCHAR, "Sede" VARCHAR)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    IF "HV_Texto" IS NULL OR LENGTH(TRIM("HV_Texto")) < 2 THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT T0."ID_Personal",
           CAST(T0."Apellido_Paterno" || COALESCE(' ' || T0."Apellido_Materno", '') || ', ' || T0."Nombres" AS VARCHAR),
           A."Descripcion", CG."Descripcion", T0."Anexo", S."Codigo"
      FROM "Personal" T0
      JOIN "Catalogo_Area" A        ON A."ID_Catalogo_Area" = T0."ID_Catalogo_Area"
      LEFT JOIN "Catalogo_Cargo" CG ON CG."ID_Catalogo_Cargo" = T0."ID_Catalogo_Cargo"
      JOIN "Catalogo_Sede" S        ON S."ID_Catalogo_Sede" = T0."ID_Catalogo_Sede"
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
       AND ("HV_ID_Catalogo_Sede" IS NULL OR T0."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede")
       AND (UPPER(T0."Apellido_Paterno" || ' ' || COALESCE(T0."Apellido_Materno",'') || ' ' || T0."Nombres") LIKE '%' || UPPER(TRIM("HV_Texto")) || '%'
            OR UPPER(A."Descripcion") LIKE '%' || UPPER(TRIM("HV_Texto")) || '%')
     ORDER BY T0."Apellido_Paterno", T0."Nombres"
     LIMIT 6;
END;
$$;
-- Prueba: SELECT * FROM "ERP_PERSONAL_BUSCAR"('nu');
