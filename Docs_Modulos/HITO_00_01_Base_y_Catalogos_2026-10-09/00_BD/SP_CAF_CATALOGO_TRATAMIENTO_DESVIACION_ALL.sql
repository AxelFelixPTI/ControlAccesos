-- =============================================================================
-- Archivo : SP_CAF_CATALOGO_TRATAMIENTO_DESVIACION_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 1 - Catálogos del módulo | Fase 1 - Procedimientos
-- Entidad : Catalogo_Tratamiento_Desviacion (catálogo)
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
-- 1. ERP_CATALOGO_TRATAMIENTO_DESVIACION_LISTAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_TRATAMIENTO_DESVIACION_LISTAR"("HV_Incluir_Eliminados" CHAR(1) DEFAULT 'N')
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Tipo_Entidad" VARCHAR, "Aplica_Ingreso" CHAR(1), "Aplica_Salida" CHAR(1), "Resultado_Ingreso" VARCHAR, "Resultado_Salida" VARCHAR, "Es_Otro" CHAR(1), "Orden" BIGINT, "Activo" CHAR(1), "Eliminado" CHAR(1),
                "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR, "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tratamiento_Desviacion", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Aplica_Ingreso", T0."Aplica_Salida", T0."Resultado_Ingreso", T0."Resultado_Salida", T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tratamiento_Desviacion" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_TRATAMIENTO_DESVIACION_LISTAR"();

-- -----------------------------------------------------------------------------
-- 2. ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"(
    IN    "HV_Codigo" VARCHAR(50),
    IN    "HV_Descripcion" VARCHAR(500),
    IN    "HV_Aplica_Ingreso" CHAR(1),
    IN    "HV_Aplica_Salida" CHAR(1),
    IN    "HV_Resultado_Ingreso" VARCHAR(30),
    IN    "HV_Resultado_Salida" VARCHAR(30),
    IN    "HV_Es_Otro" CHAR(1),
    IN    "HV_Orden" BIGINT,
    IN    "HV_Activo" CHAR(1),
    IN    "HV_UsuarioID_Create" BIGINT,
    INOUT "HV_ID_Catalogo_Tratamiento_Desviacion_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR';
    "HV_ID_Catalogo_Tratamiento_Desviacion_Result" := 0;
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
        IF COALESCE("HV_Aplica_Ingreso",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Aplica_Ingreso debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Salida",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Aplica_Salida debe ser Y o N.'; RETURN;
        END IF;
        IF NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL AND UPPER(TRIM("HV_Resultado_Ingreso")) NOT IN ('INGRESA','INGRESA_RESTRINGIDO','NO_INGRESA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El resultado de ingreso debe ser INGRESA, INGRESA_RESTRINGIDO o NO_INGRESA.'; RETURN;
        END IF;
        IF NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL AND UPPER(TRIM("HV_Resultado_Salida")) NOT IN ('SALE','SALE_RETIENE_ELEMENTO') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El resultado de salida debe ser SALE o SALE_RETIENE_ELEMENTO.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Ingreso",'N') = 'N' AND COALESCE("HV_Aplica_Salida",'N') = 'N' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tratamiento debe aplicar al ingreso, a la salida o a ambos.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Ingreso",'N') = 'N' AND NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Si no aplica al ingreso, no lleva resultado de ingreso.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Salida",'N') = 'N' AND NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Si no aplica a la salida, no lleva resultado de salida.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'Y'
           AND (NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL OR NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tratamiento "Otro" no lleva resultado fijo: Vigilancia lo elige al registrar.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'N' AND COALESCE("HV_Aplica_Ingreso",'N') = 'Y' AND NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el resultado al ingreso.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'N' AND COALESCE("HV_Aplica_Salida",'N') = 'Y' AND NULLIF(TRIM("HV_Resultado_Salida"),'') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el resultado a la salida.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tratamiento_Desviacion"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Tratamiento_Desviacion" ("Codigo","Descripcion","Aplica_Ingreso","Aplica_Salida","Resultado_Ingreso","Resultado_Salida","Es_Otro","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), COALESCE("HV_Aplica_Ingreso",'N'), COALESCE("HV_Aplica_Salida",'N'), NULLIF(UPPER(TRIM("HV_Resultado_Ingreso")),''), NULLIF(UPPER(TRIM("HV_Resultado_Salida")),''), COALESCE("HV_Es_Otro",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Tratamiento_Desviacion" INTO "HV_ID_Catalogo_Tratamiento_Desviacion_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tratamiento registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR';
        "HV_ID_Catalogo_Tratamiento_Desviacion_Result" := 0;
    END;
END;
$$;
-- Prueba: CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"('RETIENE_PRUEBA','Retiene el elemento','N','Y',NULL,'SALE_RETIENE_ELEMENTO','N',10,'Y',0);

-- -----------------------------------------------------------------------------
-- 3. ERP_CATALOGO_TRATAMIENTO_DESVIACION_DETALLE  (no filtra Eliminado)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_TRATAMIENTO_DESVIACION_DETALLE"("HV_ID_Catalogo_Tratamiento_Desviacion" BIGINT)
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Tipo_Entidad" VARCHAR, "Aplica_Ingreso" CHAR(1), "Aplica_Salida" CHAR(1), "Resultado_Ingreso" VARCHAR, "Resultado_Salida" VARCHAR, "Es_Otro" CHAR(1), "Orden" BIGINT, "Activo" CHAR(1), "Eliminado" CHAR(1),
                "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR, "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tratamiento_Desviacion", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Aplica_Ingreso", T0."Aplica_Salida", T0."Resultado_Ingreso", T0."Resultado_Salida", T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tratamiento_Desviacion" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Tratamiento_Desviacion" = "HV_ID_Catalogo_Tratamiento_Desviacion";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_TRATAMIENTO_DESVIACION_DETALLE"(1);

-- -----------------------------------------------------------------------------
-- 4. ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR"(
    IN    "HV_ID_Catalogo_Tratamiento_Desviacion" BIGINT,
    IN    "HV_Codigo" VARCHAR(50),
    IN    "HV_Descripcion" VARCHAR(500),
    IN    "HV_Aplica_Ingreso" CHAR(1),
    IN    "HV_Aplica_Salida" CHAR(1),
    IN    "HV_Resultado_Ingreso" VARCHAR(30),
    IN    "HV_Resultado_Salida" VARCHAR(30),
    IN    "HV_Es_Otro" CHAR(1),
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
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR';
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
        IF COALESCE("HV_Aplica_Ingreso",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Aplica_Ingreso debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Salida",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Aplica_Salida debe ser Y o N.'; RETURN;
        END IF;
        IF NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL AND UPPER(TRIM("HV_Resultado_Ingreso")) NOT IN ('INGRESA','INGRESA_RESTRINGIDO','NO_INGRESA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El resultado de ingreso debe ser INGRESA, INGRESA_RESTRINGIDO o NO_INGRESA.'; RETURN;
        END IF;
        IF NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL AND UPPER(TRIM("HV_Resultado_Salida")) NOT IN ('SALE','SALE_RETIENE_ELEMENTO') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El resultado de salida debe ser SALE o SALE_RETIENE_ELEMENTO.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Ingreso",'N') = 'N' AND COALESCE("HV_Aplica_Salida",'N') = 'N' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tratamiento debe aplicar al ingreso, a la salida o a ambos.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Ingreso",'N') = 'N' AND NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Si no aplica al ingreso, no lleva resultado de ingreso.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Salida",'N') = 'N' AND NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Si no aplica a la salida, no lleva resultado de salida.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'Y'
           AND (NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL OR NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tratamiento "Otro" no lleva resultado fijo: Vigilancia lo elige al registrar.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'N' AND COALESCE("HV_Aplica_Ingreso",'N') = 'Y' AND NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el resultado al ingreso.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'N' AND COALESCE("HV_Aplica_Salida",'N') = 'Y' AND NULLIF(TRIM("HV_Resultado_Salida"),'') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el resultado a la salida.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tratamiento_Desviacion" WHERE "ID_Catalogo_Tratamiento_Desviacion" = "HV_ID_Catalogo_Tratamiento_Desviacion" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tratamiento_Desviacion"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Tratamiento_Desviacion" <> "HV_ID_Catalogo_Tratamiento_Desviacion";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Tratamiento_Desviacion"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Aplica_Ingreso" = COALESCE("HV_Aplica_Ingreso",'N'), "Aplica_Salida" = COALESCE("HV_Aplica_Salida",'N'), "Resultado_Ingreso" = NULLIF(UPPER(TRIM("HV_Resultado_Ingreso")),''), "Resultado_Salida" = NULLIF(UPPER(TRIM("HV_Resultado_Salida")),''), "Es_Otro" = COALESCE("HV_Es_Otro",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tratamiento_Desviacion" = "HV_ID_Catalogo_Tratamiento_Desviacion";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tratamiento actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR  (borrado lógico; no si está en uso)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR"(
    IN    "HV_ID_Catalogo_Tratamiento_Desviacion" BIGINT,
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
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tratamiento_Desviacion" WHERE "ID_Catalogo_Tratamiento_Desviacion" = "HV_ID_Catalogo_Tratamiento_Desviacion" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        -- Uso por tablas de los Hitos 2 a 4 (CAF_Desviacion): se agrega aquí cuando existan.

        UPDATE "Catalogo_Tratamiento_Desviacion"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tratamiento_Desviacion" = "HV_ID_Catalogo_Tratamiento_Desviacion";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tratamiento eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN  (solo activos; HV_Etapa INGRESO / SALIDA / NULL = todos)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN"("HV_Etapa" VARCHAR DEFAULT NULL)
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Aplica_Ingreso" CHAR(1), "Aplica_Salida" CHAR(1), "Resultado_Ingreso" VARCHAR, "Resultado_Salida" VARCHAR, "Es_Otro" CHAR(1))
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_ingreso VARCHAR(1) := '%';
    lv_salida  VARCHAR(1) := '%';
BEGIN
    -- V1.0 2026-10-11
    IF UPPER(TRIM("HV_Etapa")) = 'INGRESO' THEN
        lv_ingreso := 'Y';
    ELSIF UPPER(TRIM("HV_Etapa")) = 'SALIDA' THEN
        lv_salida := 'Y';
    ELSIF LENGTH(TRIM("HV_Etapa")) > 0 THEN
        lv_ingreso := '~';   -- etapa desconocida: ninguna fila
    END IF;
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tratamiento_Desviacion", T0."Codigo", T0."Descripcion", T0."Aplica_Ingreso", T0."Aplica_Salida", T0."Resultado_Ingreso", T0."Resultado_Salida", T0."Es_Otro"
      FROM "Catalogo_Tratamiento_Desviacion" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y' AND T0."Aplica_Ingreso" LIKE lv_ingreso AND T0."Aplica_Salida" LIKE lv_salida
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN"('INGRESO');
