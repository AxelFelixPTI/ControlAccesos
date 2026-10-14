-- =============================================================================
-- Archivo : SP_GOVERNANCE_CATALOGO_TIPO_DOCUMENTO_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : CAF_GOVERNANCE
-- Hito    : 0 - Base | Fase 1 - Procedimientos
-- Entidad : Catalogo_Tipo_Documento (catálogo)
-- Versión : V1.0 2026-10-11
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO0.sql)
-- Generado: gen_catalogos.py (misma plantilla para los 5 catálogos transversales)
-- =============================================================================
-- Orden: 1 LISTAR · 2 CREAR · 3 DETALLE · 4 ACTUALIZAR · 5 ELIMINAR · 6 DROPDOWN
-- Lectura (LISTAR, DETALLE, DROPDOWN): funciones RETURNS TABLE, sin contrato ni
-- manejo de error (en HANA: procedimientos sin OUT ni EXIT HANDLER).
-- Escritura: procedimientos con HV_Codigo_Resp / HV_Mensaje.
-- DETALLE no filtra Eliminado (default del proyecto).
-- Los códigos se guardan en MAYÚSCULAS y no se reutilizan aunque el registro
-- esté eliminado (el UNIQUE de la tabla no distingue eliminados) - D-24.
-- =============================================================================

SET search_path TO "CAF_GOVERNANCE";

-- -----------------------------------------------------------------------------
-- 1. ERP_CATALOGO_TIPO_DOCUMENTO_LISTAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_TIPO_DOCUMENTO_LISTAR"("HV_Incluir_Eliminados" CHAR(1) DEFAULT 'N')
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Tipo_Entidad" VARCHAR, "Longitud_Min" BIGINT, "Longitud_Max" BIGINT, "Solo_Numeros" CHAR(1), "Orden" BIGINT, "Activo" CHAR(1), "Eliminado" CHAR(1),
                "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR, "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Documento", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Longitud_Min", T0."Longitud_Max", T0."Solo_Numeros", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tipo_Documento" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_TIPO_DOCUMENTO_LISTAR"();

-- -----------------------------------------------------------------------------
-- 2. ERP_CATALOGO_TIPO_DOCUMENTO_CREAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_TIPO_DOCUMENTO_CREAR"(
    IN    "HV_Codigo" VARCHAR(50),
    IN    "HV_Descripcion" VARCHAR(500),
    IN    "HV_Longitud_Min" BIGINT,
    IN    "HV_Longitud_Max" BIGINT,
    IN    "HV_Solo_Numeros" CHAR(1),
    IN    "HV_Orden" BIGINT,
    IN    "HV_Activo" CHAR(1),
    IN    "HV_UsuarioID_Create" BIGINT,
    INOUT "HV_ID_Catalogo_Tipo_Documento_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_DOCUMENTO_CREAR';
    "HV_ID_Catalogo_Tipo_Documento_Result" := 0;
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_Longitud_Min" IS NULL OR "HV_Longitud_Min" < 1 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La longitud mínima debe ser 1 o más.'; RETURN;
        END IF;
        IF "HV_Longitud_Max" IS NULL OR "HV_Longitud_Max" < "HV_Longitud_Min" THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La longitud máxima no puede ser menor que la mínima.'; RETURN;
        END IF;
        IF COALESCE("HV_Solo_Numeros",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Solo_Numeros debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tipo_Documento"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Tipo_Documento" ("Codigo","Descripcion","Longitud_Min","Longitud_Max","Solo_Numeros","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), "HV_Longitud_Min", "HV_Longitud_Max", COALESCE("HV_Solo_Numeros",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Tipo_Documento" INTO "HV_ID_Catalogo_Tipo_Documento_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de documento registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_DOCUMENTO_CREAR';
        "HV_ID_Catalogo_Tipo_Documento_Result" := 0;
    END;
END;
$$;
-- Prueba: CALL "ERP_CATALOGO_TIPO_DOCUMENTO_CREAR"('RUC_DOC','RUC como documento',11,11,'Y',10,'Y',0);

-- -----------------------------------------------------------------------------
-- 3. ERP_CATALOGO_TIPO_DOCUMENTO_DETALLE  (no filtra Eliminado)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_TIPO_DOCUMENTO_DETALLE"("HV_ID_Catalogo_Tipo_Documento" BIGINT)
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Tipo_Entidad" VARCHAR, "Longitud_Min" BIGINT, "Longitud_Max" BIGINT, "Solo_Numeros" CHAR(1), "Orden" BIGINT, "Activo" CHAR(1), "Eliminado" CHAR(1),
                "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR, "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Documento", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Longitud_Min", T0."Longitud_Max", T0."Solo_Numeros", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tipo_Documento" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_TIPO_DOCUMENTO_DETALLE"(1);

-- -----------------------------------------------------------------------------
-- 4. ERP_CATALOGO_TIPO_DOCUMENTO_ACTUALIZAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_TIPO_DOCUMENTO_ACTUALIZAR"(
    IN    "HV_ID_Catalogo_Tipo_Documento" BIGINT,
    IN    "HV_Codigo" VARCHAR(50),
    IN    "HV_Descripcion" VARCHAR(500),
    IN    "HV_Longitud_Min" BIGINT,
    IN    "HV_Longitud_Max" BIGINT,
    IN    "HV_Solo_Numeros" CHAR(1),
    IN    "HV_Orden" BIGINT,
    IN    "HV_Activo" CHAR(1),
    IN    "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_DOCUMENTO_ACTUALIZAR';
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_Longitud_Min" IS NULL OR "HV_Longitud_Min" < 1 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La longitud mínima debe ser 1 o más.'; RETURN;
        END IF;
        IF "HV_Longitud_Max" IS NULL OR "HV_Longitud_Max" < "HV_Longitud_Min" THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La longitud máxima no puede ser menor que la mínima.'; RETURN;
        END IF;
        IF COALESCE("HV_Solo_Numeros",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Solo_Numeros debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tipo_Documento" WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tipo_Documento"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Tipo_Documento" <> "HV_ID_Catalogo_Tipo_Documento";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Tipo_Documento"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Longitud_Min" = "HV_Longitud_Min", "Longitud_Max" = "HV_Longitud_Max", "Solo_Numeros" = COALESCE("HV_Solo_Numeros",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de documento actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_DOCUMENTO_ACTUALIZAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CATALOGO_TIPO_DOCUMENTO_ELIMINAR  (borrado lógico; no si está en uso)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_TIPO_DOCUMENTO_ELIMINAR"(
    IN    "HV_ID_Catalogo_Tipo_Documento" BIGINT,
    IN    "HV_UsuarioID_Update" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_DOCUMENTO_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tipo_Documento" WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_en_uso FROM "Personal" WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' trabajador(es). Desactívelo en vez de eliminarlo.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_en_uso FROM "Usuario" WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' usuario(s). Desactívelo en vez de eliminarlo.'; RETURN;
        END IF;

        UPDATE "Catalogo_Tipo_Documento"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de documento eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_DOCUMENTO_ELIMINAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CATALOGO_TIPO_DOCUMENTO_DROPDOWN  (solo activos, para listas desplegables)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_TIPO_DOCUMENTO_DROPDOWN"()
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Documento", T0."Codigo", T0."Descripcion"
      FROM "Catalogo_Tipo_Documento" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_TIPO_DOCUMENTO_DROPDOWN"();
