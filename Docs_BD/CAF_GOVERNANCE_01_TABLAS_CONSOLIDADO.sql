-- Docs_BD · CAF_GOVERNANCE · TABLAS · export 2026-10-12 11:36
-- ÍNDICE
--  1. Catalogo_Area
--  2. Catalogo_Cargo
--  3. Catalogo_Empresa_Grupo
--  4. Catalogo_Licencia
--  5. Catalogo_Sede
--  6. Catalogo_Tipo_Documento
--  7. Personal
--  8. Usuario
--  9. Usuario_Licencia

-- PostgreSQL database dump

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

-- Name: CAF_GOVERNANCE; Type: SCHEMA; Schema: -; Owner: -

CREATE SCHEMA "CAF_GOVERNANCE";

-- Name: ERP_CATALOGO_AREA_ACTUALIZAR(bigint, character varying, character varying, bigint, character, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_AREA_ACTUALIZAR"(IN "HV_ID_Catalogo_Area" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_AREA_ACTUALIZAR';
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
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Area" WHERE "ID_Catalogo_Area" = "HV_ID_Catalogo_Area" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Area"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Area" <> "HV_ID_Catalogo_Area";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Area"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Area" = "HV_ID_Catalogo_Area";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Área actualizada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_AREA_ACTUALIZAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_AREA_CREAR(character varying, character varying, bigint, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_AREA_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Area_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_AREA_CREAR';
    "HV_ID_Catalogo_Area_Result" := 0;
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
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Area"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Area" ("Codigo","Descripcion","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Area" INTO "HV_ID_Catalogo_Area_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Área registrada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_AREA_CREAR';
        "HV_ID_Catalogo_Area_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CATALOGO_AREA_DETALLE(bigint); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_AREA_DETALLE"("HV_ID_Catalogo_Area" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Area", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Area" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Area" = "HV_ID_Catalogo_Area";
END;
$$;

-- Name: ERP_CATALOGO_AREA_DROPDOWN(); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_AREA_DROPDOWN"() RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Area", T0."Codigo", T0."Descripcion"
      FROM "Catalogo_Area" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_AREA_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_AREA_ELIMINAR"(IN "HV_ID_Catalogo_Area" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_AREA_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Area" WHERE "ID_Catalogo_Area" = "HV_ID_Catalogo_Area" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_en_uso FROM "Personal" WHERE "ID_Catalogo_Area" = "HV_ID_Catalogo_Area" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' trabajador(es). Desactívela en vez de eliminarla.'; RETURN;
        END IF;

        UPDATE "Catalogo_Area"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Area" = "HV_ID_Catalogo_Area";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Área eliminada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_AREA_ELIMINAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_AREA_LISTAR(character); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_AREA_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Area", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Area" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_CARGO_ACTUALIZAR(bigint, character varying, character varying, bigint, character, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_CARGO_ACTUALIZAR"(IN "HV_ID_Catalogo_Cargo" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_CARGO_ACTUALIZAR';
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
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Cargo" WHERE "ID_Catalogo_Cargo" = "HV_ID_Catalogo_Cargo" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Cargo"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Cargo" <> "HV_ID_Catalogo_Cargo";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Cargo"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Cargo" = "HV_ID_Catalogo_Cargo";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Cargo actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_CARGO_ACTUALIZAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_CARGO_CREAR(character varying, character varying, bigint, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_CARGO_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Cargo_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_CARGO_CREAR';
    "HV_ID_Catalogo_Cargo_Result" := 0;
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
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Cargo"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Cargo" ("Codigo","Descripcion","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Cargo" INTO "HV_ID_Catalogo_Cargo_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Cargo registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_CARGO_CREAR';
        "HV_ID_Catalogo_Cargo_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CATALOGO_CARGO_DETALLE(bigint); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_CARGO_DETALLE"("HV_ID_Catalogo_Cargo" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Cargo", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Cargo" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Cargo" = "HV_ID_Catalogo_Cargo";
END;
$$;

-- Name: ERP_CATALOGO_CARGO_DROPDOWN(); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_CARGO_DROPDOWN"() RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Cargo", T0."Codigo", T0."Descripcion"
      FROM "Catalogo_Cargo" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_CARGO_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_CARGO_ELIMINAR"(IN "HV_ID_Catalogo_Cargo" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_CARGO_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Cargo" WHERE "ID_Catalogo_Cargo" = "HV_ID_Catalogo_Cargo" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_en_uso FROM "Personal" WHERE "ID_Catalogo_Cargo" = "HV_ID_Catalogo_Cargo" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' trabajador(es). Desactívelo en vez de eliminarlo.'; RETURN;
        END IF;

        UPDATE "Catalogo_Cargo"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Cargo" = "HV_ID_Catalogo_Cargo";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Cargo eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_CARGO_ELIMINAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_CARGO_LISTAR(character); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_CARGO_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Cargo", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Cargo" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_EMPRESA_GRUPO_ACTUALIZAR(bigint, character varying, character varying, character varying, bigint, character, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_EMPRESA_GRUPO_ACTUALIZAR"(IN "HV_ID_Catalogo_Empresa_Grupo" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_RUC" character varying, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_EMPRESA_GRUPO_ACTUALIZAR';
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
        IF "HV_RUC" IS NOT NULL AND LENGTH(TRIM("HV_RUC")) > 0
           AND (LENGTH(TRIM("HV_RUC")) <> 11 OR LTRIM(TRIM("HV_RUC"),'0123456789') <> '') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El RUC debe tener 11 dígitos.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Empresa_Grupo" WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Catalogo_Empresa_Grupo" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Empresa_Grupo"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Empresa_Grupo" <> "HV_ID_Catalogo_Empresa_Grupo";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Empresa_Grupo"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "RUC" = NULLIF(TRIM("HV_RUC"),''), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Catalogo_Empresa_Grupo";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Empresa actualizada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_EMPRESA_GRUPO_ACTUALIZAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_EMPRESA_GRUPO_CREAR(character varying, character varying, character varying, bigint, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_EMPRESA_GRUPO_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_RUC" character varying, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Empresa_Grupo_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_EMPRESA_GRUPO_CREAR';
    "HV_ID_Catalogo_Empresa_Grupo_Result" := 0;
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
        IF "HV_RUC" IS NOT NULL AND LENGTH(TRIM("HV_RUC")) > 0
           AND (LENGTH(TRIM("HV_RUC")) <> 11 OR LTRIM(TRIM("HV_RUC"),'0123456789') <> '') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El RUC debe tener 11 dígitos.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Empresa_Grupo"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Empresa_Grupo" ("Codigo","Descripcion","RUC","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), NULLIF(TRIM("HV_RUC"),''), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Empresa_Grupo" INTO "HV_ID_Catalogo_Empresa_Grupo_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Empresa registrada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_EMPRESA_GRUPO_CREAR';
        "HV_ID_Catalogo_Empresa_Grupo_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CATALOGO_EMPRESA_GRUPO_DETALLE(bigint); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_EMPRESA_GRUPO_DETALLE"("HV_ID_Catalogo_Empresa_Grupo" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "RUC" character varying, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Empresa_Grupo", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."RUC", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Empresa_Grupo" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Empresa_Grupo" = "HV_ID_Catalogo_Empresa_Grupo";
END;
$$;

-- Name: ERP_CATALOGO_EMPRESA_GRUPO_DROPDOWN(); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_EMPRESA_GRUPO_DROPDOWN"() RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Empresa_Grupo", T0."Codigo", T0."Descripcion"
      FROM "Catalogo_Empresa_Grupo" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_EMPRESA_GRUPO_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_EMPRESA_GRUPO_ELIMINAR"(IN "HV_ID_Catalogo_Empresa_Grupo" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_EMPRESA_GRUPO_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Empresa_Grupo" WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Catalogo_Empresa_Grupo" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_en_uso FROM "Personal" WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Catalogo_Empresa_Grupo" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' trabajador(es). Desactívela en vez de eliminarla.'; RETURN;
        END IF;

        UPDATE "Catalogo_Empresa_Grupo"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Catalogo_Empresa_Grupo";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Empresa eliminada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_EMPRESA_GRUPO_ELIMINAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_EMPRESA_GRUPO_LISTAR(character); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_EMPRESA_GRUPO_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "RUC" character varying, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Empresa_Grupo", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."RUC", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Empresa_Grupo" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_LICENCIA_DROPDOWN(); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_LICENCIA_DROPDOWN"() RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Licencia", T0."Codigo", T0."Descripcion"
      FROM "Catalogo_Licencia" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_LICENCIA_LISTAR(character); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_LICENCIA_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Licencia", T0."Codigo", T0."Descripcion", T0."Modulo",
           T0."Orden", T0."Activo", T0."Eliminado", T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Licencia" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_SEDE_ACTUALIZAR(bigint, character varying, character varying, character varying, bigint, character, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_SEDE_ACTUALIZAR"(IN "HV_ID_Catalogo_Sede" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Direccion" character varying, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_SEDE_ACTUALIZAR';
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
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Sede" WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Sede"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Sede" <> "HV_ID_Catalogo_Sede";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Sede"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Direccion" = NULLIF(TRIM("HV_Direccion"),''), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Sede actualizada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_SEDE_ACTUALIZAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_SEDE_CREAR(character varying, character varying, character varying, bigint, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_SEDE_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Direccion" character varying, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Sede_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_SEDE_CREAR';
    "HV_ID_Catalogo_Sede_Result" := 0;
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
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Sede"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Sede" ("Codigo","Descripcion","Direccion","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), NULLIF(TRIM("HV_Direccion"),''), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Sede" INTO "HV_ID_Catalogo_Sede_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Sede registrada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_SEDE_CREAR';
        "HV_ID_Catalogo_Sede_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CATALOGO_SEDE_DETALLE(bigint); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_SEDE_DETALLE"("HV_ID_Catalogo_Sede" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Direccion" character varying, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Sede", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Direccion", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Sede" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede";
END;
$$;

-- Name: ERP_CATALOGO_SEDE_DROPDOWN(); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_SEDE_DROPDOWN"() RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Sede", T0."Codigo", T0."Descripcion"
      FROM "Catalogo_Sede" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_SEDE_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_SEDE_ELIMINAR"(IN "HV_ID_Catalogo_Sede" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_SEDE_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Sede" WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_en_uso FROM "Personal" WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' trabajador(es). Desactívela en vez de eliminarla.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_en_uso FROM "Usuario_Licencia" WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' permiso(s) de usuario. Desactívela en vez de eliminarla.'; RETURN;
        END IF;

        UPDATE "Catalogo_Sede"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Sede eliminada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_SEDE_ELIMINAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_SEDE_LISTAR(character); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_SEDE_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Direccion" character varying, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Sede", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Direccion", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Sede" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_TIPO_DOCUMENTO_ACTUALIZAR(bigint, character varying, character varying, bigint, bigint, character, bigint, character, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_TIPO_DOCUMENTO_ACTUALIZAR"(IN "HV_ID_Catalogo_Tipo_Documento" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Longitud_Min" bigint, IN "HV_Longitud_Max" bigint, IN "HV_Solo_Numeros" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_CATALOGO_TIPO_DOCUMENTO_CREAR(character varying, character varying, bigint, bigint, character, bigint, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_TIPO_DOCUMENTO_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Longitud_Min" bigint, IN "HV_Longitud_Max" bigint, IN "HV_Solo_Numeros" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Tipo_Documento_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_CATALOGO_TIPO_DOCUMENTO_DETALLE(bigint); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_TIPO_DOCUMENTO_DETALLE"("HV_ID_Catalogo_Tipo_Documento" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Longitud_Min" bigint, "Longitud_Max" bigint, "Solo_Numeros" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_CATALOGO_TIPO_DOCUMENTO_DROPDOWN(); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_TIPO_DOCUMENTO_DROPDOWN"() RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_CATALOGO_TIPO_DOCUMENTO_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_CATALOGO_TIPO_DOCUMENTO_ELIMINAR"(IN "HV_ID_Catalogo_Tipo_Documento" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_CATALOGO_TIPO_DOCUMENTO_LISTAR(character); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_CATALOGO_TIPO_DOCUMENTO_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Longitud_Min" bigint, "Longitud_Max" bigint, "Solo_Numeros" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_PERSONAL_ACTUALIZAR(bigint, bigint, character varying, character varying, character varying, character varying, bigint, bigint, bigint, bigint, character varying, character varying, character, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_PERSONAL_ACTUALIZAR"(IN "HV_ID_Personal" bigint, IN "HV_ID_Catalogo_Tipo_Documento" bigint, IN "HV_Numero_Documento" character varying, IN "HV_Apellido_Paterno" character varying, IN "HV_Apellido_Materno" character varying, IN "HV_Nombres" character varying, IN "HV_ID_Catalogo_Area" bigint, IN "HV_ID_Catalogo_Cargo" bigint, IN "HV_ID_Catalogo_Empresa_Grupo" bigint, IN "HV_ID_Catalogo_Sede" bigint, IN "HV_Correo" character varying, IN "HV_Anexo" character varying, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_PERSONAL_BUSCAR(character varying, bigint); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_PERSONAL_BUSCAR"("HV_Texto" character varying, "HV_ID_Catalogo_Sede" bigint DEFAULT NULL::bigint) RETURNS TABLE("ID_Personal" bigint, "Nombre_Completo" character varying, "Area" character varying, "Cargo" character varying, "Anexo" character varying, "Sede" character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_PERSONAL_CREAR(bigint, character varying, character varying, character varying, character varying, bigint, bigint, bigint, bigint, character varying, character varying, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_PERSONAL_CREAR"(IN "HV_ID_Catalogo_Tipo_Documento" bigint, IN "HV_Numero_Documento" character varying, IN "HV_Apellido_Paterno" character varying, IN "HV_Apellido_Materno" character varying, IN "HV_Nombres" character varying, IN "HV_ID_Catalogo_Area" bigint, IN "HV_ID_Catalogo_Cargo" bigint, IN "HV_ID_Catalogo_Empresa_Grupo" bigint, IN "HV_ID_Catalogo_Sede" bigint, IN "HV_Correo" character varying, IN "HV_Anexo" character varying, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Personal_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_PERSONAL_DETALLE(bigint); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_PERSONAL_DETALLE"("HV_ID_Personal" bigint) RETURNS TABLE("ID_Personal" bigint, "ID_Catalogo_Tipo_Documento" bigint, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Apellido_Paterno" character varying, "Apellido_Materno" character varying, "Nombres" character varying, "Nombre_Completo" character varying, "ID_Catalogo_Area" bigint, "Area" character varying, "ID_Catalogo_Cargo" bigint, "Cargo" character varying, "ID_Catalogo_Empresa_Grupo" bigint, "Empresa" character varying, "ID_Catalogo_Sede" bigint, "Sede" character varying, "Correo" character varying, "Anexo" character varying, "Tiene_Usuario" character, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_PERSONAL_DETALLE_POR_DOCUMENTO(bigint, character varying); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_PERSONAL_DETALLE_POR_DOCUMENTO"("HV_ID_Catalogo_Tipo_Documento" bigint, "HV_Numero_Documento" character varying) RETURNS TABLE("ID_Personal" bigint, "ID_Catalogo_Tipo_Documento" bigint, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Apellido_Paterno" character varying, "Apellido_Materno" character varying, "Nombres" character varying, "Nombre_Completo" character varying, "ID_Catalogo_Area" bigint, "Area" character varying, "ID_Catalogo_Cargo" bigint, "Cargo" character varying, "ID_Catalogo_Empresa_Grupo" bigint, "Empresa" character varying, "ID_Catalogo_Sede" bigint, "Sede" character varying, "Correo" character varying, "Anexo" character varying, "Tiene_Usuario" character, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_PERSONAL_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_PERSONAL_ELIMINAR"(IN "HV_ID_Personal" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_PERSONAL_LISTAR(character varying, bigint, bigint, character); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_PERSONAL_LISTAR"("HV_Filtro_Nombre" character varying DEFAULT NULL::character varying, "HV_ID_Catalogo_Area" bigint DEFAULT NULL::bigint, "HV_ID_Catalogo_Sede" bigint DEFAULT NULL::bigint, "HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Personal" bigint, "ID_Catalogo_Tipo_Documento" bigint, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Apellido_Paterno" character varying, "Apellido_Materno" character varying, "Nombres" character varying, "Nombre_Completo" character varying, "ID_Catalogo_Area" bigint, "Area" character varying, "ID_Catalogo_Cargo" bigint, "Cargo" character varying, "ID_Catalogo_Empresa_Grupo" bigint, "Empresa" character varying, "ID_Catalogo_Sede" bigint, "Sede" character varying, "Correo" character varying, "Anexo" character varying, "Tiene_Usuario" character, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
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

-- Name: ERP_USUARIO_ACTUALIZAR(bigint, character varying, bigint, character varying, character varying, character varying, character varying, bigint, character varying, character, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_USUARIO_ACTUALIZAR"(IN "HV_ID_Usuario" bigint, IN "HV_Correo" character varying, IN "HV_ID_Catalogo_Tipo_Documento" bigint, IN "HV_Numero_Documento" character varying, IN "HV_Apellido_Paterno" character varying, IN "HV_Apellido_Materno" character varying, IN "HV_Nombres" character varying, IN "HV_ID_Personal" bigint, IN "HV_Empresa_Externa" character varying, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_min       BIGINT;
    lv_max       BIGINT;
    lv_solo      CHAR(1);
    lv_n         INT := 0;
    lv_es_admin  INT := 0;
    lv_otros_adm INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_USUARIO_ACTUALIZAR';
    BEGIN
        IF "HV_Correo" IS NULL OR POSITION('@' IN "HV_Correo") < 2 OR POSITION('.' IN SUBSTRING("HV_Correo" FROM POSITION('@' IN "HV_Correo"))) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El correo no es válido.'; RETURN;
        END IF;
        IF "HV_Apellido_Paterno" IS NULL OR LENGTH(TRIM("HV_Apellido_Paterno")) = 0
        OR "HV_Nombres" IS NULL OR LENGTH(TRIM("HV_Nombres")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Apellido paterno y nombres son obligatorios.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Usuario" WHERE "ID_Usuario" = "HV_ID_Usuario" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El usuario no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT MAX("Longitud_Min"), MAX("Longitud_Max"), MAX("Solo_Numeros") INTO lv_min, lv_max, lv_solo
          FROM "Catalogo_Tipo_Documento"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Eliminado" = 'N';
        IF lv_min IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de documento no existe.'; RETURN;
        END IF;
        IF "HV_Numero_Documento" IS NULL OR LENGTH(TRIM("HV_Numero_Documento")) NOT BETWEEN lv_min AND lv_max THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El documento debe tener entre ' || lv_min || ' y ' || lv_max || ' caracteres.'; RETURN;
        END IF;
        IF lv_solo = 'Y' AND LTRIM(TRIM("HV_Numero_Documento"), '0123456789') <> '' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El documento solo admite números.'; RETURN;
        END IF;

        IF "HV_ID_Personal" IS NOT NULL THEN
            SELECT COUNT(*) INTO lv_n FROM "Personal" WHERE "ID_Personal" = "HV_ID_Personal" AND "Eliminado" = 'N';
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El trabajador vinculado no existe.'; RETURN;
            END IF;
            SELECT COUNT(*) INTO lv_n FROM "Usuario"
             WHERE "ID_Personal" = "HV_ID_Personal" AND "Eliminado" = 'N' AND "ID_Usuario" <> "HV_ID_Usuario";
            IF lv_n > 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ese trabajador ya tiene otra cuenta de usuario.'; RETURN;
            END IF;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Usuario" WHERE LOWER("Correo") = LOWER(TRIM("HV_Correo")) AND "ID_Usuario" <> "HV_ID_Usuario";
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro usuario con ese correo.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Usuario"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Numero_Documento" = TRIM("HV_Numero_Documento")
           AND "ID_Usuario" <> "HV_ID_Usuario";
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro usuario con ese documento.'; RETURN;
        END IF;

        -- Desactivar: nunca a uno mismo, nunca al último administrador
        IF COALESCE("HV_Activo",'Y') = 'N' THEN
            IF "HV_ID_Usuario" = "HV_UsuarioID" THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No puede desactivar su propia cuenta.'; RETURN;
            END IF;
            SELECT COUNT(*) INTO lv_es_admin FROM "Usuario_Licencia" UL
              JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Codigo" = 'LIC_CAF_ADMIN'
             WHERE UL."ID_Usuario" = "HV_ID_Usuario" AND UL."Eliminado" = 'N';
            SELECT COUNT(DISTINCT UL."ID_Usuario") INTO lv_otros_adm FROM "Usuario_Licencia" UL
              JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Codigo" = 'LIC_CAF_ADMIN'
              JOIN "Usuario" U ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
             WHERE UL."Eliminado" = 'N' AND UL."ID_Usuario" <> "HV_ID_Usuario";
            IF lv_es_admin > 0 AND lv_otros_adm = 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Es el último administrador activo; no se puede desactivar.'; RETURN;
            END IF;
        END IF;

        UPDATE "Usuario"
           SET "Correo" = LOWER(TRIM("HV_Correo")), "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento",
               "Numero_Documento" = TRIM("HV_Numero_Documento"), "Apellido_Paterno" = TRIM("HV_Apellido_Paterno"),
               "Apellido_Materno" = NULLIF(TRIM("HV_Apellido_Materno"),''), "Nombres" = TRIM("HV_Nombres"),
               "ID_Personal" = "HV_ID_Personal", "Empresa_Externa" = NULLIF(TRIM("HV_Empresa_Externa"),''),
               "Activo" = COALESCE("HV_Activo",'Y'), "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Usuario" = "HV_ID_Usuario";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Usuario actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_USUARIO_ACTUALIZAR';
    END;
END;
$$;

-- Name: ERP_USUARIO_AUTENTICACION_POR_CORREO(character varying); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_USUARIO_AUTENTICACION_POR_CORREO"("HV_Correo" character varying) RETURNS TABLE("ID_Usuario" bigint, "Correo" character varying, "Nombre_Completo" character varying, "Password_Hash" character varying, "Password_Requiere_Cambio" character, "Intentos_Fallidos" bigint, "Bloqueado_Hasta" timestamp without time zone, "Activo" character)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Usuario", T0."Correo",
           CAST(T0."Nombres" || ' ' || T0."Apellido_Paterno" AS VARCHAR),
           T0."Password_Hash", T0."Password_Requiere_Cambio", T0."Intentos_Fallidos", T0."Bloqueado_Hasta", T0."Activo"
      FROM "Usuario" T0
     WHERE T0."Correo" = LOWER(TRIM("HV_Correo")) AND T0."Eliminado" = 'N';
END;
$$;

-- Name: ERP_USUARIO_AUTENTICACION_POR_DOCUMENTO(bigint, character varying); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_USUARIO_AUTENTICACION_POR_DOCUMENTO"("HV_ID_Catalogo_Tipo_Documento" bigint, "HV_Numero_Documento" character varying) RETURNS TABLE("ID_Usuario" bigint, "Correo" character varying, "Nombre_Completo" character varying, "Password_Hash" character varying, "Password_Requiere_Cambio" character, "Intentos_Fallidos" bigint, "Bloqueado_Hasta" timestamp without time zone, "Activo" character)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Usuario", T0."Correo",
           CAST(T0."Nombres" || ' ' || T0."Apellido_Paterno" AS VARCHAR),
           T0."Password_Hash", T0."Password_Requiere_Cambio", T0."Intentos_Fallidos", T0."Bloqueado_Hasta", T0."Activo"
      FROM "Usuario" T0
     WHERE T0."ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento"
       AND T0."Numero_Documento" = TRIM("HV_Numero_Documento") AND T0."Eliminado" = 'N';
END;
$$;

-- Name: ERP_USUARIO_AUTENTICACION_POR_TOKEN(character varying); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_USUARIO_AUTENTICACION_POR_TOKEN"("HV_Token_Hash" character varying) RETURNS TABLE("ID_Usuario" bigint, "Correo" character varying, "Nombre_Completo" character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Usuario", T0."Correo", CAST(T0."Nombres" || ' ' || T0."Apellido_Paterno" AS VARCHAR)
      FROM "Usuario" T0
     WHERE T0."Token_Restablecer_Hash" = "HV_Token_Hash"
       AND T0."Token_Restablecer_Expira" > CURRENT_TIMESTAMP
       AND T0."Eliminado" = 'N' AND T0."Activo" = 'Y';
END;
$$;

-- Name: ERP_USUARIO_CREAR(character varying, bigint, character varying, character varying, character varying, character varying, bigint, character varying, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_USUARIO_CREAR"(IN "HV_Correo" character varying, IN "HV_ID_Catalogo_Tipo_Documento" bigint, IN "HV_Numero_Documento" character varying, IN "HV_Apellido_Paterno" character varying, IN "HV_Apellido_Materno" character varying, IN "HV_Nombres" character varying, IN "HV_ID_Personal" bigint, IN "HV_Empresa_Externa" character varying, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Usuario_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_min  BIGINT;
    lv_max  BIGINT;
    lv_solo CHAR(1);
    lv_n    INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_USUARIO_CREAR';
    "HV_ID_Usuario_Result" := 0;
    BEGIN
        IF "HV_Correo" IS NULL OR POSITION('@' IN "HV_Correo") < 2 OR POSITION('.' IN SUBSTRING("HV_Correo" FROM POSITION('@' IN "HV_Correo"))) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El correo no es válido.'; RETURN;
        END IF;
        IF "HV_Apellido_Paterno" IS NULL OR LENGTH(TRIM("HV_Apellido_Paterno")) = 0
        OR "HV_Nombres" IS NULL OR LENGTH(TRIM("HV_Nombres")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Apellido paterno y nombres son obligatorios.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
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

        IF "HV_ID_Personal" IS NOT NULL THEN
            SELECT COUNT(*) INTO lv_n FROM "Personal" WHERE "ID_Personal" = "HV_ID_Personal" AND "Eliminado" = 'N';
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El trabajador vinculado no existe.'; RETURN;
            END IF;
            SELECT COUNT(*) INTO lv_n FROM "Usuario" WHERE "ID_Personal" = "HV_ID_Personal" AND "Eliminado" = 'N';
            IF lv_n > 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ese trabajador ya tiene una cuenta de usuario.'; RETURN;
            END IF;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Usuario" WHERE LOWER("Correo") = LOWER(TRIM("HV_Correo"));
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un usuario con ese correo (puede estar eliminado).'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Usuario"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Numero_Documento" = TRIM("HV_Numero_Documento");
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un usuario con ese documento (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Usuario" ("Correo","ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres",
                               "ID_Personal","Empresa_Externa","Activo","UsuarioID_Create")
        VALUES (LOWER(TRIM("HV_Correo")), "HV_ID_Catalogo_Tipo_Documento", TRIM("HV_Numero_Documento"), TRIM("HV_Apellido_Paterno"),
                NULLIF(TRIM("HV_Apellido_Materno"),''), TRIM("HV_Nombres"), "HV_ID_Personal", NULLIF(TRIM("HV_Empresa_Externa"),''),
                COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Usuario" INTO "HV_ID_Usuario_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Usuario registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_USUARIO_CREAR';
        "HV_ID_Usuario_Result" := 0;
    END;
END;
$$;

-- Name: ERP_USUARIO_DETALLE(bigint); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_USUARIO_DETALLE"("HV_ID_Usuario" bigint) RETURNS TABLE("ID_Usuario" bigint, "Correo" character varying, "ID_Catalogo_Tipo_Documento" bigint, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Apellido_Paterno" character varying, "Apellido_Materno" character varying, "Nombres" character varying, "Nombre_Completo" character varying, "ID_Personal" bigint, "Area" character varying, "Empresa_Externa" character varying, "Licencias" character varying, "Tiene_Password" character, "Password_Requiere_Cambio" character, "Bloqueado" character, "Ultimo_Acceso" timestamp without time zone, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Usuario", T0."Correo", T0."ID_Catalogo_Tipo_Documento", TD."Codigo", T0."Numero_Documento",
           T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres",
           CAST(T0."Apellido_Paterno" || COALESCE(' ' || T0."Apellido_Materno", '') || ', ' || T0."Nombres" AS VARCHAR),
           T0."ID_Personal", A."Descripcion", T0."Empresa_Externa",
           CAST((SELECT STRING_AGG(L."Codigo" || '@' || S."Codigo", ', ' ORDER BY L."Orden", S."Orden")
                   FROM "Usuario_Licencia" UL
                   JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia"
                   JOIN "Catalogo_Sede" S     ON S."ID_Catalogo_Sede" = UL."ID_Catalogo_Sede"
                  WHERE UL."ID_Usuario" = T0."ID_Usuario" AND UL."Eliminado" = 'N') AS VARCHAR),
           CAST(CASE WHEN T0."Password_Hash" IS NULL THEN 'N' ELSE 'Y' END AS CHAR(1)),
           T0."Password_Requiere_Cambio",
           CAST(CASE WHEN T0."Bloqueado_Hasta" IS NOT NULL AND T0."Bloqueado_Hasta" > CURRENT_TIMESTAMP THEN 'Y' ELSE 'N' END AS CHAR(1)),
           T0."Ultimo_Acceso",
           T0."Activo", T0."Eliminado", T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Usuario" T0
      JOIN "Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = T0."ID_Catalogo_Tipo_Documento"
      LEFT JOIN "Personal" P      ON P."ID_Personal" = T0."ID_Personal"
      LEFT JOIN "Catalogo_Area" A ON A."ID_Catalogo_Area" = P."ID_Catalogo_Area"
      LEFT JOIN "Usuario" T1      ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Usuario" = "HV_ID_Usuario";
END;
$$;

-- Name: ERP_USUARIO_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_USUARIO_ELIMINAR"(IN "HV_ID_Usuario" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_n         INT := 0;
    lv_es_admin  INT := 0;
    lv_otros_adm INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_USUARIO_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Usuario" WHERE "ID_Usuario" = "HV_ID_Usuario" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El usuario no existe o ya fue eliminado.'; RETURN;
        END IF;
        IF "HV_ID_Usuario" = "HV_UsuarioID_Update" THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No puede eliminar su propia cuenta.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_es_admin FROM "Usuario_Licencia" UL
          JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Codigo" = 'LIC_CAF_ADMIN'
         WHERE UL."ID_Usuario" = "HV_ID_Usuario" AND UL."Eliminado" = 'N';
        SELECT COUNT(DISTINCT UL."ID_Usuario") INTO lv_otros_adm FROM "Usuario_Licencia" UL
          JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Codigo" = 'LIC_CAF_ADMIN'
          JOIN "Usuario" U ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
         WHERE UL."Eliminado" = 'N' AND UL."ID_Usuario" <> "HV_ID_Usuario";
        IF lv_es_admin > 0 AND lv_otros_adm = 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Es el último administrador activo; no se puede eliminar.'; RETURN;
        END IF;

        UPDATE "Usuario_Licencia"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Usuario" = "HV_ID_Usuario" AND "Eliminado" = 'N';
        UPDATE "Usuario"
           SET "Eliminado" = 'Y', "Token_Restablecer_Hash" = NULL, "Token_Restablecer_Expira" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Usuario" = "HV_ID_Usuario";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Usuario eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_USUARIO_ELIMINAR';
    END;
END;
$$;

-- Name: ERP_USUARIO_LICENCIA_AGREGAR(bigint, bigint, bigint, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(IN "HV_ID_Usuario" bigint, IN "HV_ID_Catalogo_Licencia" bigint, IN "HV_ID_Catalogo_Sede" bigint, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Usuario_Licencia_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_n         INT := 0;
    lv_id        BIGINT;
    lv_eliminado CHAR(1);
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_USUARIO_LICENCIA_AGREGAR';
    "HV_ID_Usuario_Licencia_Result" := 0;
    BEGIN
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Usuario" WHERE "ID_Usuario" = "HV_ID_Usuario" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El usuario no existe.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Licencia" WHERE "ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La licencia no existe o está inactiva.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Sede" WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La sede no existe o está inactiva.'; RETURN; END IF;

        SELECT MAX("ID_Usuario_Licencia"), MAX("Eliminado") INTO lv_id, lv_eliminado
          FROM "Usuario_Licencia"
         WHERE "ID_Usuario" = "HV_ID_Usuario" AND "ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia" AND "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede";

        IF lv_id IS NOT NULL AND lv_eliminado = 'N' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'El usuario ya tiene esa licencia en esa sede.'; RETURN;
        ELSIF lv_id IS NOT NULL THEN
            UPDATE "Usuario_Licencia"
               SET "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID_Create", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Usuario_Licencia" = lv_id;
            "HV_ID_Usuario_Licencia_Result" := lv_id;
        ELSE
            INSERT INTO "Usuario_Licencia" ("ID_Usuario","ID_Catalogo_Licencia","ID_Catalogo_Sede","UsuarioID_Create")
            VALUES ("HV_ID_Usuario", "HV_ID_Catalogo_Licencia", "HV_ID_Catalogo_Sede", "HV_UsuarioID_Create")
            RETURNING "ID_Usuario_Licencia" INTO "HV_ID_Usuario_Licencia_Result";
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Licencia asignada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_USUARIO_LICENCIA_AGREGAR';
        "HV_ID_Usuario_Licencia_Result" := 0;
    END;
END;
$$;

-- Name: ERP_USUARIO_LICENCIA_LISTAR_POR_PADRE(bigint); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_LISTAR_POR_PADRE"("HV_ID_Usuario" bigint) RETURNS TABLE("ID_Usuario_Licencia" bigint, "ID_Usuario" bigint, "ID_Catalogo_Licencia" bigint, "Codigo_Licencia" character varying, "Licencia" character varying, "ID_Catalogo_Sede" bigint, "Codigo_Sede" character varying, "Sede" character varying, "CreateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Usuario_Licencia", T0."ID_Usuario", T0."ID_Catalogo_Licencia", L."Codigo", L."Descripcion",
           T0."ID_Catalogo_Sede", S."Codigo", S."Descripcion", T0."CreateDate"
      FROM "Usuario_Licencia" T0
      JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = T0."ID_Catalogo_Licencia"
      JOIN "Catalogo_Sede" S     ON S."ID_Catalogo_Sede" = T0."ID_Catalogo_Sede"
     WHERE T0."ID_Usuario" = "HV_ID_Usuario" AND T0."Eliminado" = 'N'
     ORDER BY L."Orden", S."Orden";
END;
$$;

-- Name: ERP_USUARIO_LICENCIA_QUITAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_QUITAR"(IN "HV_ID_Usuario_Licencia" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_usuario   BIGINT;
    lv_codigo    VARCHAR(50);
    lv_otros_adm INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_USUARIO_LICENCIA_QUITAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT MAX(UL."ID_Usuario"), MAX(L."Codigo") INTO lv_usuario, lv_codigo
          FROM "Usuario_Licencia" UL
          JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia"
         WHERE UL."ID_Usuario_Licencia" = "HV_ID_Usuario_Licencia" AND UL."Eliminado" = 'N';
        IF lv_usuario IS NULL THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La asignación no existe o ya fue quitada.'; RETURN;
        END IF;

        IF lv_codigo = 'LIC_CAF_ADMIN' THEN
            SELECT COUNT(DISTINCT UL."ID_Usuario") INTO lv_otros_adm FROM "Usuario_Licencia" UL
              JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Codigo" = 'LIC_CAF_ADMIN'
              JOIN "Usuario" U ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
             WHERE UL."Eliminado" = 'N' AND UL."ID_Usuario_Licencia" <> "HV_ID_Usuario_Licencia";
            IF lv_otros_adm = 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Es la última licencia de administrador activa; no se puede quitar.'; RETURN;
            END IF;
        END IF;

        UPDATE "Usuario_Licencia"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Usuario_Licencia" = "HV_ID_Usuario_Licencia";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Licencia retirada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_USUARIO_LICENCIA_QUITAR';
    END;
END;
$$;

-- Name: ERP_USUARIO_LICENCIA_VERIFICAR(bigint, character varying, bigint); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_VERIFICAR"("HV_ID_Usuario" bigint, "HV_Codigo_Licencia" character varying, "HV_ID_Catalogo_Sede" bigint) RETURNS TABLE("Tiene" character)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT CAST(CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END AS CHAR(1))
      FROM "Usuario_Licencia" UL
      JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia"
      JOIN "Usuario" U           ON U."ID_Usuario" = UL."ID_Usuario"
     WHERE UL."ID_Usuario" = "HV_ID_Usuario"
       AND L."Codigo" = "HV_Codigo_Licencia"
       AND UL."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
       AND UL."Eliminado" = 'N' AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
       AND U."Eliminado" = 'N' AND U."Activo" = 'Y';
END;
$$;

-- Name: ERP_USUARIO_LISTAR(character varying, character varying, character); Type: FUNCTION; Schema: CAF_GOVERNANCE; Owner: -

CREATE FUNCTION "CAF_GOVERNANCE"."ERP_USUARIO_LISTAR"("HV_Filtro_Texto" character varying DEFAULT NULL::character varying, "HV_Codigo_Licencia" character varying DEFAULT NULL::character varying, "HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Usuario" bigint, "Correo" character varying, "ID_Catalogo_Tipo_Documento" bigint, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Apellido_Paterno" character varying, "Apellido_Materno" character varying, "Nombres" character varying, "Nombre_Completo" character varying, "ID_Personal" bigint, "Area" character varying, "Empresa_Externa" character varying, "Licencias" character varying, "Tiene_Password" character, "Password_Requiere_Cambio" character, "Bloqueado" character, "Ultimo_Acceso" timestamp without time zone, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Usuario", T0."Correo", T0."ID_Catalogo_Tipo_Documento", TD."Codigo", T0."Numero_Documento",
           T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres",
           CAST(T0."Apellido_Paterno" || COALESCE(' ' || T0."Apellido_Materno", '') || ', ' || T0."Nombres" AS VARCHAR),
           T0."ID_Personal", A."Descripcion", T0."Empresa_Externa",
           CAST((SELECT STRING_AGG(L."Codigo" || '@' || S."Codigo", ', ' ORDER BY L."Orden", S."Orden")
                   FROM "Usuario_Licencia" UL
                   JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia"
                   JOIN "Catalogo_Sede" S     ON S."ID_Catalogo_Sede" = UL."ID_Catalogo_Sede"
                  WHERE UL."ID_Usuario" = T0."ID_Usuario" AND UL."Eliminado" = 'N') AS VARCHAR),
           CAST(CASE WHEN T0."Password_Hash" IS NULL THEN 'N' ELSE 'Y' END AS CHAR(1)),
           T0."Password_Requiere_Cambio",
           CAST(CASE WHEN T0."Bloqueado_Hasta" IS NOT NULL AND T0."Bloqueado_Hasta" > CURRENT_TIMESTAMP THEN 'Y' ELSE 'N' END AS CHAR(1)),
           T0."Ultimo_Acceso",
           T0."Activo", T0."Eliminado", T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Usuario" T0
      JOIN "Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = T0."ID_Catalogo_Tipo_Documento"
      LEFT JOIN "Personal" P      ON P."ID_Personal" = T0."ID_Personal"
      LEFT JOIN "Catalogo_Area" A ON A."ID_Catalogo_Area" = P."ID_Catalogo_Area"
      LEFT JOIN "Usuario" T1      ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
       AND ("HV_Filtro_Texto" IS NULL
            OR UPPER(T0."Apellido_Paterno" || ' ' || COALESCE(T0."Apellido_Materno",'') || ' ' || T0."Nombres" || ' ' || T0."Correo")
               LIKE '%' || UPPER(TRIM("HV_Filtro_Texto")) || '%')
       AND ("HV_Codigo_Licencia" IS NULL OR EXISTS (
                SELECT 1 FROM "Usuario_Licencia" UL
                  JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia"
                 WHERE UL."ID_Usuario" = T0."ID_Usuario" AND UL."Eliminado" = 'N' AND L."Codigo" = "HV_Codigo_Licencia"))
     ORDER BY T0."Apellido_Paterno", T0."Nombres";
END;
$$;

-- Name: ERP_USUARIO_LOGIN_REGISTRAR(bigint, character, bigint, bigint, bigint, timestamp without time zone, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_USUARIO_LOGIN_REGISTRAR"(IN "HV_ID_Usuario" bigint, IN "HV_Exitoso" character, IN "HV_Max_Intentos" bigint, IN "HV_Minutos_Bloqueo" bigint, INOUT "HV_Intentos_Fallidos" bigint DEFAULT NULL::bigint, INOUT "HV_Bloqueado_Hasta" timestamp without time zone DEFAULT NULL::timestamp without time zone, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_n        INT := 0;
    lv_intentos BIGINT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_USUARIO_LOGIN_REGISTRAR';
    BEGIN
        IF "HV_Exitoso" IS NULL OR "HV_Exitoso" NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Exitoso debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_Max_Intentos" IS NULL OR "HV_Max_Intentos" < 1 OR "HV_Minutos_Bloqueo" IS NULL OR "HV_Minutos_Bloqueo" < 1 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Parámetros de bloqueo no válidos.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Usuario" WHERE "ID_Usuario" = "HV_ID_Usuario" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El usuario no existe.'; RETURN;
        END IF;

        IF "HV_Exitoso" = 'Y' THEN
            UPDATE "Usuario"
               SET "Intentos_Fallidos" = 0, "Bloqueado_Hasta" = NULL, "Ultimo_Acceso" = CURRENT_TIMESTAMP
             WHERE "ID_Usuario" = "HV_ID_Usuario";
            "HV_Intentos_Fallidos" := 0;
            "HV_Bloqueado_Hasta"   := NULL;
            "HV_Mensaje"           := 'Acceso registrado.';
        ELSE
            SELECT "Intentos_Fallidos" + 1 INTO lv_intentos FROM "Usuario" WHERE "ID_Usuario" = "HV_ID_Usuario";
            IF lv_intentos >= "HV_Max_Intentos" THEN
                UPDATE "Usuario"
                   SET "Intentos_Fallidos" = 0,
                       "Bloqueado_Hasta" = CURRENT_TIMESTAMP + ("HV_Minutos_Bloqueo" * INTERVAL '1 minute')
                 WHERE "ID_Usuario" = "HV_ID_Usuario";
                SELECT "Bloqueado_Hasta" INTO "HV_Bloqueado_Hasta" FROM "Usuario" WHERE "ID_Usuario" = "HV_ID_Usuario";
                "HV_Intentos_Fallidos" := lv_intentos;
                "HV_Mensaje" := 'Cuenta bloqueada temporalmente por intentos fallidos.';
            ELSE
                UPDATE "Usuario" SET "Intentos_Fallidos" = lv_intentos WHERE "ID_Usuario" = "HV_ID_Usuario";
                "HV_Intentos_Fallidos" := lv_intentos;
                "HV_Bloqueado_Hasta"   := NULL;
                "HV_Mensaje" := 'Intento fallido registrado.';
            END IF;
        END IF;
        "HV_Codigo_Resp" := 100;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_USUARIO_LOGIN_REGISTRAR';
    END;
END;
$$;

-- Name: ERP_USUARIO_PASSWORD_ACTUALIZAR(bigint, character varying, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_USUARIO_PASSWORD_ACTUALIZAR"(IN "HV_ID_Usuario" bigint, IN "HV_Password_Hash" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_USUARIO_PASSWORD_ACTUALIZAR';
    BEGIN
        IF "HV_Password_Hash" IS NULL OR LENGTH(TRIM("HV_Password_Hash")) < 20 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Hash de contraseña no válido.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Usuario" WHERE "ID_Usuario" = "HV_ID_Usuario" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El usuario no existe o está inactivo.'; RETURN;
        END IF;

        UPDATE "Usuario"
           SET "Password_Hash" = "HV_Password_Hash", "Password_Requiere_Cambio" = 'N',
               "Token_Restablecer_Hash" = NULL, "Token_Restablecer_Expira" = NULL,
               "Intentos_Fallidos" = 0, "Bloqueado_Hasta" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Usuario" = "HV_ID_Usuario";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Contraseña actualizada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_USUARIO_PASSWORD_ACTUALIZAR';
    END;
END;
$$;

-- Name: ERP_USUARIO_TOKEN_REGISTRAR(bigint, character varying, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: CAF_GOVERNANCE; Owner: -

CREATE PROCEDURE "CAF_GOVERNANCE"."ERP_USUARIO_TOKEN_REGISTRAR"(IN "HV_ID_Usuario" bigint, IN "HV_Token_Hash" character varying, IN "HV_Minutos_Vigencia" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'CAF_GOVERNANCE'
    AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_USUARIO_TOKEN_REGISTRAR';
    BEGIN
        IF "HV_Token_Hash" IS NULL OR LENGTH(TRIM("HV_Token_Hash")) < 20 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Token no válido.'; RETURN;
        END IF;
        IF "HV_Minutos_Vigencia" IS NULL OR "HV_Minutos_Vigencia" < 1 OR "HV_Minutos_Vigencia" > 10080 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La vigencia debe estar entre 1 minuto y 7 días.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Usuario" WHERE "ID_Usuario" = "HV_ID_Usuario" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El usuario no existe o está inactivo.'; RETURN;
        END IF;

        UPDATE "Usuario"
           SET "Token_Restablecer_Hash" = "HV_Token_Hash",
               "Token_Restablecer_Expira" = CURRENT_TIMESTAMP + ("HV_Minutos_Vigencia" * INTERVAL '1 minute'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Usuario" = "HV_ID_Usuario";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Token registrado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_USUARIO_TOKEN_REGISTRAR';
    END;
END;
$$;

-- Name: Catalogo_Area; Type: TABLE; Schema: CAF_GOVERNANCE; Owner: -

CREATE TABLE "CAF_GOVERNANCE"."Catalogo_Area" (
    "ID_Catalogo_Area" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Area_Flags" CHECK ((("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))))
);

-- Name: Catalogo_Area_ID_Catalogo_Area_seq; Type: SEQUENCE; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE "CAF_GOVERNANCE"."Catalogo_Area" ALTER COLUMN "ID_Catalogo_Area" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "CAF_GOVERNANCE"."Catalogo_Area_ID_Catalogo_Area_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Cargo; Type: TABLE; Schema: CAF_GOVERNANCE; Owner: -

CREATE TABLE "CAF_GOVERNANCE"."Catalogo_Cargo" (
    "ID_Catalogo_Cargo" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Cargo_Flags" CHECK ((("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))))
);

-- Name: Catalogo_Cargo_ID_Catalogo_Cargo_seq; Type: SEQUENCE; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE "CAF_GOVERNANCE"."Catalogo_Cargo" ALTER COLUMN "ID_Catalogo_Cargo" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "CAF_GOVERNANCE"."Catalogo_Cargo_ID_Catalogo_Cargo_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Empresa_Grupo; Type: TABLE; Schema: CAF_GOVERNANCE; Owner: -

CREATE TABLE "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" (
    "ID_Catalogo_Empresa_Grupo" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "RUC" character varying(11),
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Empresa_Grupo_Flags" CHECK ((("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))))
);

-- Name: Catalogo_Empresa_Grupo_ID_Catalogo_Empresa_Grupo_seq; Type: SEQUENCE; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" ALTER COLUMN "ID_Catalogo_Empresa_Grupo" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo_ID_Catalogo_Empresa_Grupo_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Licencia; Type: TABLE; Schema: CAF_GOVERNANCE; Owner: -

CREATE TABLE "CAF_GOVERNANCE"."Catalogo_Licencia" (
    "ID_Catalogo_Licencia" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Modulo" character varying(50) NOT NULL,
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Licencia_Flags" CHECK ((("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))))
);

-- Name: Catalogo_Licencia_ID_Catalogo_Licencia_seq; Type: SEQUENCE; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE "CAF_GOVERNANCE"."Catalogo_Licencia" ALTER COLUMN "ID_Catalogo_Licencia" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "CAF_GOVERNANCE"."Catalogo_Licencia_ID_Catalogo_Licencia_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Sede; Type: TABLE; Schema: CAF_GOVERNANCE; Owner: -

CREATE TABLE "CAF_GOVERNANCE"."Catalogo_Sede" (
    "ID_Catalogo_Sede" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Direccion" character varying(500),
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Sede_Flags" CHECK ((("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))))
);

-- Name: Catalogo_Sede_ID_Catalogo_Sede_seq; Type: SEQUENCE; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE "CAF_GOVERNANCE"."Catalogo_Sede" ALTER COLUMN "ID_Catalogo_Sede" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "CAF_GOVERNANCE"."Catalogo_Sede_ID_Catalogo_Sede_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Tipo_Documento; Type: TABLE; Schema: CAF_GOVERNANCE; Owner: -

CREATE TABLE "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" (
    "ID_Catalogo_Tipo_Documento" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Longitud_Min" bigint NOT NULL,
    "Longitud_Max" bigint NOT NULL,
    "Solo_Numeros" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Tipo_Documento_Flags" CHECK ((("Solo_Numeros" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))),
    CONSTRAINT "CK_Catalogo_Tipo_Documento_Longitud" CHECK ((("Longitud_Min" > 0) AND ("Longitud_Max" >= "Longitud_Min")))
);

-- Name: Catalogo_Tipo_Documento_ID_Catalogo_Tipo_Documento_seq; Type: SEQUENCE; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" ALTER COLUMN "ID_Catalogo_Tipo_Documento" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "CAF_GOVERNANCE"."Catalogo_Tipo_Documento_ID_Catalogo_Tipo_Documento_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Personal; Type: TABLE; Schema: CAF_GOVERNANCE; Owner: -

CREATE TABLE "CAF_GOVERNANCE"."Personal" (
    "ID_Personal" bigint NOT NULL,
    "ID_Catalogo_Tipo_Documento" bigint NOT NULL,
    "Numero_Documento" character varying(20) NOT NULL,
    "Apellido_Paterno" character varying(100) NOT NULL,
    "Apellido_Materno" character varying(100),
    "Nombres" character varying(200) NOT NULL,
    "ID_Catalogo_Area" bigint NOT NULL,
    "ID_Catalogo_Cargo" bigint,
    "ID_Catalogo_Empresa_Grupo" bigint NOT NULL,
    "ID_Catalogo_Sede" bigint NOT NULL,
    "Correo" character varying(200),
    "Anexo" character varying(20),
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Personal_Flags" CHECK ((("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))))
);

-- Name: Personal_ID_Personal_seq; Type: SEQUENCE; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE "CAF_GOVERNANCE"."Personal" ALTER COLUMN "ID_Personal" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "CAF_GOVERNANCE"."Personal_ID_Personal_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Usuario; Type: TABLE; Schema: CAF_GOVERNANCE; Owner: -

CREATE TABLE "CAF_GOVERNANCE"."Usuario" (
    "ID_Usuario" bigint NOT NULL,
    "Correo" character varying(200) NOT NULL,
    "ID_Catalogo_Tipo_Documento" bigint NOT NULL,
    "Numero_Documento" character varying(20) NOT NULL,
    "Apellido_Paterno" character varying(100) NOT NULL,
    "Apellido_Materno" character varying(100),
    "Nombres" character varying(200) NOT NULL,
    "ID_Personal" bigint,
    "Empresa_Externa" character varying(500),
    "Password_Hash" character varying(500),
    "Password_Requiere_Cambio" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Token_Restablecer_Hash" character varying(500),
    "Token_Restablecer_Expira" timestamp without time zone,
    "Intentos_Fallidos" bigint DEFAULT 0 NOT NULL,
    "Bloqueado_Hasta" timestamp without time zone,
    "Ultimo_Acceso" timestamp without time zone,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Usuario_Flags" CHECK ((("Password_Requiere_Cambio" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))),
    CONSTRAINT "CK_Usuario_Intentos" CHECK (("Intentos_Fallidos" >= 0))
);

-- Name: Usuario_ID_Usuario_seq; Type: SEQUENCE; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE "CAF_GOVERNANCE"."Usuario" ALTER COLUMN "ID_Usuario" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "CAF_GOVERNANCE"."Usuario_ID_Usuario_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Usuario_Licencia; Type: TABLE; Schema: CAF_GOVERNANCE; Owner: -

CREATE TABLE "CAF_GOVERNANCE"."Usuario_Licencia" (
    "ID_Usuario_Licencia" bigint NOT NULL,
    "ID_Usuario" bigint NOT NULL,
    "ID_Catalogo_Licencia" bigint NOT NULL,
    "ID_Catalogo_Sede" bigint NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Usuario_Licencia_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);

-- Name: Usuario_Licencia_ID_Usuario_Licencia_seq; Type: SEQUENCE; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE "CAF_GOVERNANCE"."Usuario_Licencia" ALTER COLUMN "ID_Usuario_Licencia" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "CAF_GOVERNANCE"."Usuario_Licencia_ID_Usuario_Licencia_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Area PK_Catalogo_Area; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Area"
    ADD CONSTRAINT "PK_Catalogo_Area" PRIMARY KEY ("ID_Catalogo_Area");

-- Name: Catalogo_Cargo PK_Catalogo_Cargo; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Cargo"
    ADD CONSTRAINT "PK_Catalogo_Cargo" PRIMARY KEY ("ID_Catalogo_Cargo");

-- Name: Catalogo_Empresa_Grupo PK_Catalogo_Empresa_Grupo; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo"
    ADD CONSTRAINT "PK_Catalogo_Empresa_Grupo" PRIMARY KEY ("ID_Catalogo_Empresa_Grupo");

-- Name: Catalogo_Licencia PK_Catalogo_Licencia; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Licencia"
    ADD CONSTRAINT "PK_Catalogo_Licencia" PRIMARY KEY ("ID_Catalogo_Licencia");

-- Name: Catalogo_Sede PK_Catalogo_Sede; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Sede"
    ADD CONSTRAINT "PK_Catalogo_Sede" PRIMARY KEY ("ID_Catalogo_Sede");

-- Name: Catalogo_Tipo_Documento PK_Catalogo_Tipo_Documento; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Tipo_Documento"
    ADD CONSTRAINT "PK_Catalogo_Tipo_Documento" PRIMARY KEY ("ID_Catalogo_Tipo_Documento");

-- Name: Personal PK_Personal; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Personal"
    ADD CONSTRAINT "PK_Personal" PRIMARY KEY ("ID_Personal");

-- Name: Usuario PK_Usuario; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Usuario"
    ADD CONSTRAINT "PK_Usuario" PRIMARY KEY ("ID_Usuario");

-- Name: Usuario_Licencia PK_Usuario_Licencia; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Usuario_Licencia"
    ADD CONSTRAINT "PK_Usuario_Licencia" PRIMARY KEY ("ID_Usuario_Licencia");

-- Name: Catalogo_Area UQ_Catalogo_Area_Codigo; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Area"
    ADD CONSTRAINT "UQ_Catalogo_Area_Codigo" UNIQUE ("Codigo");

-- Name: Catalogo_Cargo UQ_Catalogo_Cargo_Codigo; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Cargo"
    ADD CONSTRAINT "UQ_Catalogo_Cargo_Codigo" UNIQUE ("Codigo");

-- Name: Catalogo_Empresa_Grupo UQ_Catalogo_Empresa_Grupo_Codigo; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo"
    ADD CONSTRAINT "UQ_Catalogo_Empresa_Grupo_Codigo" UNIQUE ("Codigo");

-- Name: Catalogo_Licencia UQ_Catalogo_Licencia_Codigo; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Licencia"
    ADD CONSTRAINT "UQ_Catalogo_Licencia_Codigo" UNIQUE ("Codigo");

-- Name: Catalogo_Sede UQ_Catalogo_Sede_Codigo; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Sede"
    ADD CONSTRAINT "UQ_Catalogo_Sede_Codigo" UNIQUE ("Codigo");

-- Name: Catalogo_Tipo_Documento UQ_Catalogo_Tipo_Documento_Codigo; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Catalogo_Tipo_Documento"
    ADD CONSTRAINT "UQ_Catalogo_Tipo_Documento_Codigo" UNIQUE ("Codigo");

-- Name: Personal UQ_Personal_Documento; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Personal"
    ADD CONSTRAINT "UQ_Personal_Documento" UNIQUE ("ID_Catalogo_Tipo_Documento", "Numero_Documento");

-- Name: Usuario UQ_Usuario_Correo; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Usuario"
    ADD CONSTRAINT "UQ_Usuario_Correo" UNIQUE ("Correo");

-- Name: Usuario UQ_Usuario_Documento; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Usuario"
    ADD CONSTRAINT "UQ_Usuario_Documento" UNIQUE ("ID_Catalogo_Tipo_Documento", "Numero_Documento");

-- Name: Usuario_Licencia UQ_Usuario_Licencia; Type: CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Usuario_Licencia"
    ADD CONSTRAINT "UQ_Usuario_Licencia" UNIQUE ("ID_Usuario", "ID_Catalogo_Licencia", "ID_Catalogo_Sede");

-- Name: IX_Catalogo_Area_Activa; Type: INDEX; Schema: CAF_GOVERNANCE; Owner: -

CREATE INDEX "IX_Catalogo_Area_Activa" ON "CAF_GOVERNANCE"."Catalogo_Area" USING btree ("Eliminado", "Activo", "Orden");

-- Name: IX_Catalogo_Cargo_Activa; Type: INDEX; Schema: CAF_GOVERNANCE; Owner: -

CREATE INDEX "IX_Catalogo_Cargo_Activa" ON "CAF_GOVERNANCE"."Catalogo_Cargo" USING btree ("Eliminado", "Activo", "Orden");

-- Name: IX_Catalogo_Empresa_Grupo_Activa; Type: INDEX; Schema: CAF_GOVERNANCE; Owner: -

CREATE INDEX "IX_Catalogo_Empresa_Grupo_Activa" ON "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" USING btree ("Eliminado", "Activo", "Orden");

-- Name: IX_Catalogo_Licencia_Activa; Type: INDEX; Schema: CAF_GOVERNANCE; Owner: -

CREATE INDEX "IX_Catalogo_Licencia_Activa" ON "CAF_GOVERNANCE"."Catalogo_Licencia" USING btree ("Eliminado", "Activo", "Orden");

-- Name: IX_Catalogo_Sede_Activa; Type: INDEX; Schema: CAF_GOVERNANCE; Owner: -

CREATE INDEX "IX_Catalogo_Sede_Activa" ON "CAF_GOVERNANCE"."Catalogo_Sede" USING btree ("Eliminado", "Activo", "Orden");

-- Name: IX_Catalogo_Tipo_Documento_Activa; Type: INDEX; Schema: CAF_GOVERNANCE; Owner: -

CREATE INDEX "IX_Catalogo_Tipo_Documento_Activa" ON "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" USING btree ("Eliminado", "Activo", "Orden");

-- Name: IX_Personal_Busqueda; Type: INDEX; Schema: CAF_GOVERNANCE; Owner: -

CREATE INDEX "IX_Personal_Busqueda" ON "CAF_GOVERNANCE"."Personal" USING btree ("Eliminado", "Activo", "Apellido_Paterno", "Nombres");

-- Name: IX_Personal_Sede_Area; Type: INDEX; Schema: CAF_GOVERNANCE; Owner: -

CREATE INDEX "IX_Personal_Sede_Area" ON "CAF_GOVERNANCE"."Personal" USING btree ("ID_Catalogo_Sede", "ID_Catalogo_Area");

-- Name: IX_Usuario_Activo; Type: INDEX; Schema: CAF_GOVERNANCE; Owner: -

CREATE INDEX "IX_Usuario_Activo" ON "CAF_GOVERNANCE"."Usuario" USING btree ("Eliminado", "Activo", "Apellido_Paterno");

-- Name: IX_Usuario_Licencia_Usuario; Type: INDEX; Schema: CAF_GOVERNANCE; Owner: -

CREATE INDEX "IX_Usuario_Licencia_Usuario" ON "CAF_GOVERNANCE"."Usuario_Licencia" USING btree ("ID_Usuario", "Eliminado");

-- Name: Personal FK_Personal_Area; Type: FK CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Personal"
    ADD CONSTRAINT "FK_Personal_Area" FOREIGN KEY ("ID_Catalogo_Area") REFERENCES "CAF_GOVERNANCE"."Catalogo_Area"("ID_Catalogo_Area");

-- Name: Personal FK_Personal_Cargo; Type: FK CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Personal"
    ADD CONSTRAINT "FK_Personal_Cargo" FOREIGN KEY ("ID_Catalogo_Cargo") REFERENCES "CAF_GOVERNANCE"."Catalogo_Cargo"("ID_Catalogo_Cargo");

-- Name: Personal FK_Personal_Empresa_Grupo; Type: FK CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Personal"
    ADD CONSTRAINT "FK_Personal_Empresa_Grupo" FOREIGN KEY ("ID_Catalogo_Empresa_Grupo") REFERENCES "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo"("ID_Catalogo_Empresa_Grupo");

-- Name: Personal FK_Personal_Sede; Type: FK CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Personal"
    ADD CONSTRAINT "FK_Personal_Sede" FOREIGN KEY ("ID_Catalogo_Sede") REFERENCES "CAF_GOVERNANCE"."Catalogo_Sede"("ID_Catalogo_Sede");

-- Name: Personal FK_Personal_Tipo_Documento; Type: FK CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Personal"
    ADD CONSTRAINT "FK_Personal_Tipo_Documento" FOREIGN KEY ("ID_Catalogo_Tipo_Documento") REFERENCES "CAF_GOVERNANCE"."Catalogo_Tipo_Documento"("ID_Catalogo_Tipo_Documento");

-- Name: Usuario_Licencia FK_Usuario_Licencia_Licencia; Type: FK CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Usuario_Licencia"
    ADD CONSTRAINT "FK_Usuario_Licencia_Licencia" FOREIGN KEY ("ID_Catalogo_Licencia") REFERENCES "CAF_GOVERNANCE"."Catalogo_Licencia"("ID_Catalogo_Licencia");

-- Name: Usuario_Licencia FK_Usuario_Licencia_Sede; Type: FK CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Usuario_Licencia"
    ADD CONSTRAINT "FK_Usuario_Licencia_Sede" FOREIGN KEY ("ID_Catalogo_Sede") REFERENCES "CAF_GOVERNANCE"."Catalogo_Sede"("ID_Catalogo_Sede");

-- Name: Usuario_Licencia FK_Usuario_Licencia_Usuario; Type: FK CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Usuario_Licencia"
    ADD CONSTRAINT "FK_Usuario_Licencia_Usuario" FOREIGN KEY ("ID_Usuario") REFERENCES "CAF_GOVERNANCE"."Usuario"("ID_Usuario");

-- Name: Usuario FK_Usuario_Personal; Type: FK CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Usuario"
    ADD CONSTRAINT "FK_Usuario_Personal" FOREIGN KEY ("ID_Personal") REFERENCES "CAF_GOVERNANCE"."Personal"("ID_Personal");

-- Name: Usuario FK_Usuario_Tipo_Documento; Type: FK CONSTRAINT; Schema: CAF_GOVERNANCE; Owner: -

ALTER TABLE ONLY "CAF_GOVERNANCE"."Usuario"
    ADD CONSTRAINT "FK_Usuario_Tipo_Documento" FOREIGN KEY ("ID_Catalogo_Tipo_Documento") REFERENCES "CAF_GOVERNANCE"."Catalogo_Tipo_Documento"("ID_Catalogo_Tipo_Documento");

-- PostgreSQL database dump complete

