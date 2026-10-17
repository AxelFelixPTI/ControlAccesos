-- =============================================================================
-- Archivo : SP_CAF_TIPO_ACCESO_PASO_APROBACION_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobación | Fase 1 - Procedimientos
-- Entidad : Tipo_Acceso_Paso_Aprobacion (los pasos de aprobación de cada flujo)
-- Versión : V1.0 2026-10-16
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_PERMISOS.sql)
-- Requiere: script 09 ejecutado.
-- =============================================================================
-- Es un catálogo hijo de Catalogo_Tipo_Acceso, así que sigue el patrón PIVOT
-- (LISTAR_POR_PADRE, AGREGAR, ACTUALIZAR, QUITAR) y no los 5 del CRUD.
--
-- 1 ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE  pasos de un tipo de acceso
-- 2 ERP_CAF_TIPO_ACCESO_PASO_AGREGAR           agregar un paso
-- 3 ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR        editar un paso
-- 4 ERP_CAF_TIPO_ACCESO_PASO_QUITAR            quitar un paso (borrado lógico)
--
-- Agregar un flujo nuevo = insertar filas aquí, sin tocar el programa.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE
--    Trae el nombre del rol desde el schema transversal, para la pantalla.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE"(
    "HV_ID_Catalogo_Tipo_Acceso" BIGINT,
    "HV_Incluir_Inactivos"       CHAR(1) DEFAULT 'N'
)
RETURNS TABLE ("ID_Tipo_Acceso_Paso_Aprobacion" BIGINT, "ID_Catalogo_Tipo_Acceso" BIGINT, "Orden" BIGINT,
               "Codigo" VARCHAR, "Descripcion" VARCHAR, "Alcance" VARCHAR, "Tipo_Aprobador" VARCHAR,
               "ID_Catalogo_Licencia" BIGINT, "Codigo_Licencia" VARCHAR, "Rol" VARCHAR,
               "Condicion" VARCHAR, "Obligatorio" CHAR(1), "Activo" CHAR(1), "CreateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-16
    RETURN QUERY
    SELECT T0."ID_Tipo_Acceso_Paso_Aprobacion", T0."ID_Catalogo_Tipo_Acceso", T0."Orden",
           T0."Codigo", T0."Descripcion", T0."Alcance", T0."Tipo_Aprobador",
           T0."ID_Catalogo_Licencia", L."Codigo", L."Descripcion",
           T0."Condicion", T0."Obligatorio", T0."Activo", T0."CreateDate"
      FROM "Tipo_Acceso_Paso_Aprobacion" T0
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = T0."ID_Catalogo_Licencia"
     WHERE T0."ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso"
       AND T0."Eliminado" = 'N'
       AND ("HV_Incluir_Inactivos" = 'Y' OR T0."Activo" = 'Y')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE"(1);

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_TIPO_ACCESO_PASO_AGREGAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(
    IN    "HV_ID_Catalogo_Tipo_Acceso" BIGINT,
    IN    "HV_Orden"                   BIGINT,
    IN    "HV_Codigo"                  VARCHAR(50),
    IN    "HV_Descripcion"             VARCHAR(500),
    IN    "HV_Alcance"                 VARCHAR(20),
    IN    "HV_Tipo_Aprobador"          VARCHAR(20),
    IN    "HV_ID_Catalogo_Licencia"    BIGINT,
    IN    "HV_Condicion"               VARCHAR(30),
    IN    "HV_Obligatorio"             CHAR(1),
    IN    "HV_UsuarioID_Create"        BIGINT,
    INOUT "HV_ID_Tipo_Acceso_Paso_Aprobacion_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"             INT DEFAULT NULL,
    INOUT "HV_Mensaje"                 VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_AGREGAR';
    "HV_ID_Tipo_Acceso_Paso_Aprobacion_Result" := 0;
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código del paso es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF "HV_Orden" IS NULL OR "HV_Orden" < 1 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El orden debe ser 1 o más.'; RETURN;
        END IF;
        IF COALESCE("HV_Alcance",'PERSONA') NOT IN ('PERSONA','SOLICITUD') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El alcance debe ser PERSONA o SOLICITUD.'; RETURN;
        END IF;
        IF COALESCE("HV_Tipo_Aprobador",'ROL') NOT IN ('ROL') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Tipo de aprobador no admitido todavía.'; RETURN;
        END IF;
        IF COALESCE("HV_Condicion",'SIEMPRE') NOT IN ('SIEMPRE') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Condición no admitida todavía.'; RETURN;
        END IF;
        IF COALESCE("HV_Obligatorio",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Obligatorio debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Tipo_Acceso"
         WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de acceso no existe.'; RETURN;
        END IF;

        IF COALESCE("HV_Tipo_Aprobador",'ROL') = 'ROL' THEN
            SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Catalogo_Licencia"
             WHERE "ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia" AND "Eliminado" = 'N' AND "Activo" = 'Y';
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El rol que aprueba no existe o está inactivo.'; RETURN;
            END IF;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion"
         WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso"
           AND UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ese tipo de acceso ya tiene un paso con ese código.'; RETURN;
        END IF;

        INSERT INTO "Tipo_Acceso_Paso_Aprobacion"
          ("ID_Catalogo_Tipo_Acceso","Orden","Codigo","Descripcion","Alcance","Tipo_Aprobador","ID_Catalogo_Licencia","Condicion","Obligatorio","UsuarioID_Create")
        VALUES ("HV_ID_Catalogo_Tipo_Acceso", "HV_Orden", UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"),
                COALESCE("HV_Alcance",'PERSONA'), COALESCE("HV_Tipo_Aprobador",'ROL'), "HV_ID_Catalogo_Licencia",
                COALESCE("HV_Condicion",'SIEMPRE'), COALESCE("HV_Obligatorio",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Tipo_Acceso_Paso_Aprobacion" INTO "HV_ID_Tipo_Acceso_Paso_Aprobacion_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Paso de aprobación agregado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_AGREGAR';
        "HV_ID_Tipo_Acceso_Paso_Aprobacion_Result" := 0;
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR
--    No se permite cambiar el alcance ni el tipo de acceso de un paso que ya
--    tiene decisiones: cambiaría el significado de lo ya aprobado.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR"(
    IN    "HV_ID_Tipo_Acceso_Paso_Aprobacion" BIGINT,
    IN    "HV_Orden"                BIGINT,
    IN    "HV_Descripcion"          VARCHAR(500),
    IN    "HV_Alcance"              VARCHAR(20),
    IN    "HV_ID_Catalogo_Licencia" BIGINT,
    IN    "HV_Obligatorio"          CHAR(1),
    IN    "HV_Activo"               CHAR(1),
    IN    "HV_UsuarioID"            BIGINT,
    INOUT "HV_Codigo_Resp"          INT DEFAULT NULL,
    INOUT "HV_Mensaje"              VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n          INT := 0;
    lv_decisiones INT := 0;
    lv_alcance    VARCHAR(20);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR';
    BEGIN
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF "HV_Orden" IS NULL OR "HV_Orden" < 1 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El orden debe ser 1 o más.'; RETURN;
        END IF;
        IF COALESCE("HV_Alcance",'PERSONA') NOT IN ('PERSONA','SOLICITUD') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El alcance debe ser PERSONA o SOLICITUD.'; RETURN;
        END IF;
        IF COALESCE("HV_Obligatorio",'Y') NOT IN ('Y','N') OR COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Obligatorio y Activo deben ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("Alcance") INTO lv_n, lv_alcance FROM "Tipo_Acceso_Paso_Aprobacion"
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El paso no existe o ya fue quitado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_decisiones FROM "CAF_Solicitud_Decision"
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion" AND "Eliminado" = 'N';
        IF lv_decisiones > 0 AND lv_alcance <> COALESCE("HV_Alcance", lv_alcance) THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Ya tiene ' || lv_decisiones || ' decisiones: no se puede cambiar su alcance.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Catalogo_Licencia"
         WHERE "ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El rol que aprueba no existe.'; RETURN;
        END IF;

        UPDATE "Tipo_Acceso_Paso_Aprobacion"
           SET "Orden" = "HV_Orden", "Descripcion" = TRIM("HV_Descripcion"),
               "Alcance" = COALESCE("HV_Alcance", "Alcance"), "ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia",
               "Obligatorio" = COALESCE("HV_Obligatorio",'Y'), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Paso de aprobación actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_TIPO_ACCESO_PASO_QUITAR
--    Un paso con decisiones no se quita: se desactiva (misma idea que D-30).
--    Tampoco se deja un tipo de acceso disponible sin ningún paso obligatorio.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_TIPO_ACCESO_PASO_QUITAR"(
    IN    "HV_ID_Tipo_Acceso_Paso_Aprobacion" BIGINT,
    IN    "HV_UsuarioID_Update" BIGINT,
    INOUT "HV_Codigo_Resp"      INT DEFAULT NULL,
    INOUT "HV_Mensaje"          VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n          INT := 0;
    lv_tipo       BIGINT;
    lv_decisiones INT := 0;
    lv_quedan     INT := 0;
    lv_disponible CHAR(1);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_QUITAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("ID_Catalogo_Tipo_Acceso") INTO lv_n, lv_tipo
          FROM "Tipo_Acceso_Paso_Aprobacion"
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El paso no existe o ya fue quitado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_decisiones FROM "CAF_Solicitud_Decision"
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion" AND "Eliminado" = 'N';
        IF lv_decisiones > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Tiene ' || lv_decisiones || ' decisiones registradas. Desactívelo en vez de quitarlo.'; RETURN;
        END IF;

        SELECT MAX("Disponible") INTO lv_disponible FROM "Catalogo_Tipo_Acceso"
         WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo;
        SELECT COUNT(*) INTO lv_quedan FROM "Tipo_Acceso_Paso_Aprobacion"
         WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo AND "Eliminado" = 'N' AND "Activo" = 'Y' AND "Obligatorio" = 'Y'
           AND "ID_Tipo_Acceso_Paso_Aprobacion" <> "HV_ID_Tipo_Acceso_Paso_Aprobacion";
        IF lv_disponible = 'Y' AND lv_quedan = 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Es el único paso obligatorio de un tipo de acceso disponible; no se puede quitar.'; RETURN;
        END IF;

        UPDATE "Tipo_Acceso_Paso_Aprobacion"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Paso de aprobación quitado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_QUITAR';
    END;
END;
$$;
