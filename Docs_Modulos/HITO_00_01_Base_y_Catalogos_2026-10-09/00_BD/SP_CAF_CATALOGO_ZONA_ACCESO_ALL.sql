-- =============================================================================
-- Archivo : SP_CAF_CATALOGO_ZONA_ACCESO_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 1 - Catálogos del módulo | Fase 1 - Procedimientos
-- Entidad : Catalogo_Zona_Acceso (catálogo)
-- Versión : V1.0 2026-10-11
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO1.sql)
-- Generado: gen_catalogos.py V1.1 (misma plantilla que los catálogos transversales del Hito 0)
-- =============================================================================
-- Orden: 1 LISTAR · 2 CREAR · 3 DETALLE · 4 ACTUALIZAR · 5 ELIMINAR · 6 DROPDOWN
-- Lectura (LISTAR, DETALLE, DROPDOWN): funciones RETURNS TABLE, sin contrato ni
-- manejo de error (en HANA: procedimientos sin OUT ni EXIT HANDLER).
-- Escritura: procedimientos con HV_Codigo_Resp / HV_Mensaje.
-- DETALLE no filtra Eliminado (default del proyecto).
-- Los códigos se guardan en MAYÚSCULAS y no se reutilizan aunque el registro
-- esté eliminado (el UNIQUE de la tabla no distingue eliminados) - D-24.
-- Referencias a CAF_GOVERNANCE (Usuario, Catalogo_Sede) siempre calificadas: no
-- hay llave foránea entre schemas y se validan aquí (D-06). El schema del módulo
-- no se escribe en el cuerpo: lo fija el search_path de cada rutina (D-28).
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CATALOGO_ZONA_ACCESO_LISTAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_ZONA_ACCESO_LISTAR"("HV_ID_Catalogo_Sede" BIGINT DEFAULT NULL, "HV_Incluir_Eliminados" CHAR(1) DEFAULT 'N')
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Tipo_Entidad" VARCHAR, "ID_Catalogo_Sede" BIGINT, "Codigo_Sede" VARCHAR, "Sede" VARCHAR, "Tipo_Zona" VARCHAR, "Exige_SCTR" CHAR(1), "Exige_EPP" CHAR(1), "Orden" BIGINT, "Activo" CHAR(1), "Eliminado" CHAR(1),
                "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR, "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Zona_Acceso", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."ID_Catalogo_Sede", S."Codigo", S."Descripcion", T0."Tipo_Zona", T0."Exige_SCTR", T0."Exige_EPP", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Zona_Acceso" T0
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Sede" S ON S."ID_Catalogo_Sede" = T0."ID_Catalogo_Sede"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
       AND ("HV_ID_Catalogo_Sede" IS NULL OR T0."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede")
     ORDER BY S."Orden", S."Codigo", T0."Orden", T0."Codigo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_ZONA_ACCESO_LISTAR"();

-- -----------------------------------------------------------------------------
-- 2. ERP_CATALOGO_ZONA_ACCESO_CREAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_ZONA_ACCESO_CREAR"(
    IN    "HV_Codigo" VARCHAR(50),
    IN    "HV_Descripcion" VARCHAR(500),
    IN    "HV_ID_Catalogo_Sede" BIGINT,
    IN    "HV_Tipo_Zona" VARCHAR(20),
    IN    "HV_Exige_SCTR" CHAR(1),
    IN    "HV_Exige_EPP" CHAR(1),
    IN    "HV_Orden" BIGINT,
    IN    "HV_Activo" CHAR(1),
    IN    "HV_UsuarioID_Create" BIGINT,
    INOUT "HV_ID_Catalogo_Zona_Acceso_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_duplicado INT := 0;
    lv_n         INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_CREAR';
    "HV_ID_Catalogo_Zona_Acceso_Result" := 0;
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
        IF "HV_Tipo_Zona" IS NULL OR UPPER(TRIM("HV_Tipo_Zona")) NOT IN ('ADMINISTRATIVA','OPERATIVA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de zona debe ser ADMINISTRATIVA u OPERATIVA.'; RETURN;
        END IF;
        IF COALESCE("HV_Exige_SCTR",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Exige_SCTR debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Exige_EPP",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Exige_EPP debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Catalogo_Sede"
         WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La sede no existe o está inactiva.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Zona_Acceso"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe una zona con ese código en esa sede (puede estar eliminada).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Zona_Acceso" ("Codigo","Descripcion","ID_Catalogo_Sede","Tipo_Zona","Exige_SCTR","Exige_EPP","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), "HV_ID_Catalogo_Sede", UPPER(TRIM("HV_Tipo_Zona")), COALESCE("HV_Exige_SCTR",'N'), COALESCE("HV_Exige_EPP",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Zona_Acceso" INTO "HV_ID_Catalogo_Zona_Acceso_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Zona registrada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_CREAR';
        "HV_ID_Catalogo_Zona_Acceso_Result" := 0;
    END;
END;
$$;
-- Prueba: CALL "ERP_CATALOGO_ZONA_ACCESO_CREAR"('ALMACEN_PRUEBA','Almacén de prueba',1,'OPERATIVA','Y','Y',10,'Y',0);

-- -----------------------------------------------------------------------------
-- 3. ERP_CATALOGO_ZONA_ACCESO_DETALLE  (no filtra Eliminado)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_ZONA_ACCESO_DETALLE"("HV_ID_Catalogo_Zona_Acceso" BIGINT)
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Tipo_Entidad" VARCHAR, "ID_Catalogo_Sede" BIGINT, "Codigo_Sede" VARCHAR, "Sede" VARCHAR, "Tipo_Zona" VARCHAR, "Exige_SCTR" CHAR(1), "Exige_EPP" CHAR(1), "Orden" BIGINT, "Activo" CHAR(1), "Eliminado" CHAR(1),
                "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR, "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Zona_Acceso", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."ID_Catalogo_Sede", S."Codigo", S."Descripcion", T0."Tipo_Zona", T0."Exige_SCTR", T0."Exige_EPP", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Zona_Acceso" T0
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Sede" S ON S."ID_Catalogo_Sede" = T0."ID_Catalogo_Sede"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_ZONA_ACCESO_DETALLE"(1);

-- -----------------------------------------------------------------------------
-- 4. ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR"(
    IN    "HV_ID_Catalogo_Zona_Acceso" BIGINT,
    IN    "HV_Codigo" VARCHAR(50),
    IN    "HV_Descripcion" VARCHAR(500),
    IN    "HV_ID_Catalogo_Sede" BIGINT,
    IN    "HV_Tipo_Zona" VARCHAR(20),
    IN    "HV_Exige_SCTR" CHAR(1),
    IN    "HV_Exige_EPP" CHAR(1),
    IN    "HV_Orden" BIGINT,
    IN    "HV_Activo" CHAR(1),
    IN    "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
    lv_n         INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR';
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
        IF "HV_Tipo_Zona" IS NULL OR UPPER(TRIM("HV_Tipo_Zona")) NOT IN ('ADMINISTRATIVA','OPERATIVA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de zona debe ser ADMINISTRATIVA u OPERATIVA.'; RETURN;
        END IF;
        IF COALESCE("HV_Exige_SCTR",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Exige_SCTR debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Exige_EPP",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Exige_EPP debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Zona_Acceso" WHERE "ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Catalogo_Sede"
         WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La sede no existe.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Zona_Acceso"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "ID_Catalogo_Zona_Acceso" <> "HV_ID_Catalogo_Zona_Acceso";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otra zona con ese código en esa sede.'; RETURN;
        END IF;

        UPDATE "Catalogo_Zona_Acceso"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede", "Tipo_Zona" = UPPER(TRIM("HV_Tipo_Zona")), "Exige_SCTR" = COALESCE("HV_Exige_SCTR",'N'), "Exige_EPP" = COALESCE("HV_Exige_EPP",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Zona actualizada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CATALOGO_ZONA_ACCESO_ELIMINAR  (borrado lógico; no si está en uso)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_ZONA_ACCESO_ELIMINAR"(
    IN    "HV_ID_Catalogo_Zona_Acceso" BIGINT,
    IN    "HV_UsuarioID_Update" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Zona_Acceso" WHERE "ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        -- Uso por tablas de los Hitos 2 a 4 (CAF_Solicitud_Zona): se agrega aquí cuando existan.

        UPDATE "Catalogo_Zona_Acceso"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Zona eliminada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_ELIMINAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CATALOGO_ZONA_ACCESO_DROPDOWN  (solo activos de UNA sede)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_ZONA_ACCESO_DROPDOWN"("HV_ID_Catalogo_Sede" BIGINT)
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Tipo_Zona" VARCHAR, "Exige_SCTR" CHAR(1), "Exige_EPP" CHAR(1))
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Zona_Acceso", T0."Codigo", T0."Descripcion", T0."Tipo_Zona", T0."Exige_SCTR", T0."Exige_EPP"
      FROM "Catalogo_Zona_Acceso" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y' AND T0."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_ZONA_ACCESO_DROPDOWN"(1);
