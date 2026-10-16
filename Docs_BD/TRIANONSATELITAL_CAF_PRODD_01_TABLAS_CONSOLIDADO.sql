-- Docs_BD · TRIANONSATELITAL_CAF_PRODD · TABLAS · export 2026-10-16 17:24
-- ÍNDICE
--  1. CAF_Correo_Pendiente
--  2. CAF_Desviacion
--  3. CAF_Evento
--  4. CAF_Incidencia
--  5. CAF_Incidencia_Persona
--  6. CAF_Persona_Externa
--  7. CAF_Registro_Acceso
--  8. CAF_Registro_Checklist
--  9. CAF_Respaldo
--  10. CAF_Respaldo_Persona
--  11. CAF_Solicitud
--  12. CAF_Solicitud_Copia_Correo
--  13. CAF_Solicitud_Decision
--  14. CAF_Solicitud_Persona
--  15. CAF_Solicitud_Version
--  16. CAF_Solicitud_Zona
--  17. Catalogo_Item_Checklist
--  18. Catalogo_Motivo_Visita
--  19. Catalogo_Tipo_Acceso
--  20. Catalogo_Tipo_Incidencia
--  21. Catalogo_Tratamiento_Desviacion
--  22. Catalogo_Zona_Acceso
--  23. Tipo_Acceso_Item_Checklist
--  24. Tipo_Acceso_Paso_Aprobacion

-- PostgreSQL database dump

-- Dumped from database version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)

-- Name: TRIANONSATELITAL_CAF_PRODD; Type: SCHEMA; Schema: -; Owner: -

CREATE SCHEMA "TRIANONSATELITAL_CAF_PRODD";

-- Name: SCHEMA "TRIANONSATELITAL_CAF_PRODD"; Type: COMMENT; Schema: -; Owner: -

COMMENT ON SCHEMA "TRIANONSATELITAL_CAF_PRODD" IS 'Módulo Control de Accesos: catálogos propios y tablas transaccionales CAF_*.';

-- Name: ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR(bigint, bigint, character varying, character varying, character varying, character varying, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR"(IN "HV_ID_Persona_Externa" bigint, IN "HV_ID_Catalogo_Tipo_Documento" bigint, IN "HV_Numero_Documento" character varying, IN "HV_Apellido_Paterno" character varying, IN "HV_Apellido_Materno" character varying, IN "HV_Nombres" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_min  BIGINT;
    lv_max  BIGINT;
    lv_solo CHAR(1);
    lv_n    INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR';
    BEGIN
        IF "HV_Apellido_Paterno" IS NULL OR LENGTH(TRIM("HV_Apellido_Paterno")) = 0
        OR "HV_Nombres" IS NULL OR LENGTH(TRIM("HV_Nombres")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Apellido paterno y nombres son obligatorios.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_Persona_Externa" WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no existe.'; RETURN;
        END IF;

        SELECT MAX("Longitud_Min"), MAX("Longitud_Max"), MAX("Solo_Numeros") INTO lv_min, lv_max, lv_solo
          FROM "CAF_GOVERNANCE"."Catalogo_Tipo_Documento"
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

        SELECT COUNT(*) INTO lv_n FROM "CAF_Persona_Externa"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Numero_Documento" = TRIM("HV_Numero_Documento")
           AND "ID_Persona_Externa" <> "HV_ID_Persona_Externa";
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otra persona con ese documento.'; RETURN;
        END IF;

        UPDATE "CAF_Persona_Externa"
           SET "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento", "Numero_Documento" = TRIM("HV_Numero_Documento"),
               "Apellido_Paterno" = TRIM("HV_Apellido_Paterno"), "Apellido_Materno" = NULLIF(TRIM("HV_Apellido_Materno"),''),
               "Nombres" = TRIM("HV_Nombres"), "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Persona actualizada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR';
    END;
END;
$$;

-- Name: ERP_CAF_PERSONA_EXTERNA_CREAR(bigint, character varying, character varying, character varying, character varying, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_PERSONA_EXTERNA_CREAR"(IN "HV_ID_Catalogo_Tipo_Documento" bigint, IN "HV_Numero_Documento" character varying, IN "HV_Apellido_Paterno" character varying, IN "HV_Apellido_Materno" character varying, IN "HV_Nombres" character varying, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Persona_Externa_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_min  BIGINT;
    lv_max  BIGINT;
    lv_solo CHAR(1);
    lv_n    INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PERSONA_EXTERNA_CREAR';
    "HV_ID_Persona_Externa_Result" := 0;
    BEGIN
        -- Obligatorios
        IF "HV_Apellido_Paterno" IS NULL OR LENGTH(TRIM("HV_Apellido_Paterno")) = 0
        OR "HV_Nombres" IS NULL OR LENGTH(TRIM("HV_Nombres")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Apellido paterno y nombres son obligatorios.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        -- Documento según su tipo (schema transversal)
        SELECT MAX("Longitud_Min"), MAX("Longitud_Max"), MAX("Solo_Numeros") INTO lv_min, lv_max, lv_solo
          FROM "CAF_GOVERNANCE"."Catalogo_Tipo_Documento"
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

        -- Duplicado (el UNIQUE es tipo + número)
        SELECT COUNT(*) INTO lv_n FROM "CAF_Persona_Externa"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Numero_Documento" = TRIM("HV_Numero_Documento");
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe una persona con ese documento. Búsquela por documento y actualice sus datos.'; RETURN;
        END IF;

        INSERT INTO "CAF_Persona_Externa" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","UsuarioID_Create")
        VALUES ("HV_ID_Catalogo_Tipo_Documento", TRIM("HV_Numero_Documento"), TRIM("HV_Apellido_Paterno"),
                NULLIF(TRIM("HV_Apellido_Materno"),''), TRIM("HV_Nombres"), "HV_UsuarioID_Create")
        RETURNING "ID_Persona_Externa" INTO "HV_ID_Persona_Externa_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Persona registrada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PERSONA_EXTERNA_CREAR';
        "HV_ID_Persona_Externa_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO(bigint, character varying); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO"("HV_ID_Catalogo_Tipo_Documento" bigint, "HV_Numero_Documento" character varying) RETURNS TABLE("ID_Persona_Externa" bigint, "ID_Catalogo_Tipo_Documento" bigint, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Apellido_Paterno" character varying, "Apellido_Materno" character varying, "Nombres" character varying, "Nombre_Completo" character varying, "Fecha_Ultima_Visita" timestamp without time zone, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Persona_Externa", T0."ID_Catalogo_Tipo_Documento", TD."Codigo", T0."Numero_Documento",
           T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres",
           CAST(T0."Apellido_Paterno" || COALESCE(' ' || T0."Apellido_Materno", '') || ', ' || T0."Nombres" AS VARCHAR),
           T0."Fecha_Ultima_Visita", T0."Eliminado", T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "CAF_Persona_Externa" T0
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = T0."ID_Catalogo_Tipo_Documento"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1                 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento"
       AND T0."Numero_Documento" = TRIM("HV_Numero_Documento")
       AND T0."Eliminado" = 'N';
END;
$$;

-- Name: ERP_CAF_PERSONA_EXTERNA_LISTAR(character varying, character); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_PERSONA_EXTERNA_LISTAR"("HV_Filtro_Nombre" character varying DEFAULT NULL::character varying, "HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Persona_Externa" bigint, "ID_Catalogo_Tipo_Documento" bigint, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Apellido_Paterno" character varying, "Apellido_Materno" character varying, "Nombres" character varying, "Nombre_Completo" character varying, "Fecha_Ultima_Visita" timestamp without time zone, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Persona_Externa", T0."ID_Catalogo_Tipo_Documento", TD."Codigo", T0."Numero_Documento",
           T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres",
           CAST(T0."Apellido_Paterno" || COALESCE(' ' || T0."Apellido_Materno", '') || ', ' || T0."Nombres" AS VARCHAR),
           T0."Fecha_Ultima_Visita", T0."Eliminado", T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "CAF_Persona_Externa" T0
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = T0."ID_Catalogo_Tipo_Documento"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1                 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
       AND ("HV_Filtro_Nombre" IS NULL OR UPPER(T0."Apellido_Paterno" || ' ' || COALESCE(T0."Apellido_Materno",'') || ' ' || T0."Nombres") LIKE '%' || UPPER(TRIM("HV_Filtro_Nombre")) || '%')
     ORDER BY T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres";
END;
$$;

-- Name: ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR(bigint, bigint, character varying, character varying, bigint, character, character, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR"(IN "HV_ID_Tipo_Acceso_Paso_Aprobacion" bigint, IN "HV_Orden" bigint, IN "HV_Descripcion" character varying, IN "HV_Alcance" character varying, IN "HV_ID_Catalogo_Licencia" bigint, IN "HV_Obligatorio" character, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CAF_TIPO_ACCESO_PASO_AGREGAR(bigint, bigint, character varying, character varying, character varying, character varying, bigint, character varying, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(IN "HV_ID_Catalogo_Tipo_Acceso" bigint, IN "HV_Orden" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Alcance" character varying, IN "HV_Tipo_Aprobador" character varying, IN "HV_ID_Catalogo_Licencia" bigint, IN "HV_Condicion" character varying, IN "HV_Obligatorio" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Tipo_Acceso_Paso_Aprobacion_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE(bigint, character); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE"("HV_ID_Catalogo_Tipo_Acceso" bigint, "HV_Incluir_Inactivos" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Tipo_Acceso_Paso_Aprobacion" bigint, "ID_Catalogo_Tipo_Acceso" bigint, "Orden" bigint, "Codigo" character varying, "Descripcion" character varying, "Alcance" character varying, "Tipo_Aprobador" character varying, "ID_Catalogo_Licencia" bigint, "Codigo_Licencia" character varying, "Rol" character varying, "Condicion" character varying, "Obligatorio" character, "Activo" character, "CreateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CAF_TIPO_ACCESO_PASO_QUITAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_QUITAR"(IN "HV_ID_Tipo_Acceso_Paso_Aprobacion" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR(bigint, character varying, character varying, character varying, character varying, character varying, character, bigint, character, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR"(IN "HV_ID_Catalogo_Item_Checklist" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Ayuda" character varying, IN "HV_Etapa" character varying, IN "HV_Condicion" character varying, IN "HV_Es_Critico" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR';
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
        IF "HV_Etapa" IS NULL OR UPPER(TRIM("HV_Etapa")) NOT IN ('INGRESO','SALIDA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La etapa debe ser INGRESO o SALIDA.'; RETURN;
        END IF;
        IF "HV_Condicion" IS NULL OR UPPER(TRIM("HV_Condicion")) NOT IN ('SIEMPRE','ZONA_EXIGE_SCTR','ZONA_EXIGE_EPP','TRAE_EQUIPOS','TRAE_HERRAMIENTAS') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La condición debe ser SIEMPRE, ZONA_EXIGE_SCTR, ZONA_EXIGE_EPP, TRAE_EQUIPOS o TRAE_HERRAMIENTAS.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Critico",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Critico debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Item_Checklist"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Item_Checklist" <> "HV_ID_Catalogo_Item_Checklist";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Item_Checklist"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Ayuda" = NULLIF(TRIM("HV_Ayuda"),''), "Etapa" = UPPER(TRIM("HV_Etapa")), "Condicion" = UPPER(TRIM("HV_Condicion")), "Es_Critico" = COALESCE("HV_Es_Critico",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ítem de checklist actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_ITEM_CHECKLIST_CREAR(character varying, character varying, character varying, character varying, character varying, character, bigint, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Ayuda" character varying, IN "HV_Etapa" character varying, IN "HV_Condicion" character varying, IN "HV_Es_Critico" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Item_Checklist_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_CREAR';
    "HV_ID_Catalogo_Item_Checklist_Result" := 0;
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
        IF "HV_Etapa" IS NULL OR UPPER(TRIM("HV_Etapa")) NOT IN ('INGRESO','SALIDA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La etapa debe ser INGRESO o SALIDA.'; RETURN;
        END IF;
        IF "HV_Condicion" IS NULL OR UPPER(TRIM("HV_Condicion")) NOT IN ('SIEMPRE','ZONA_EXIGE_SCTR','ZONA_EXIGE_EPP','TRAE_EQUIPOS','TRAE_HERRAMIENTAS') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La condición debe ser SIEMPRE, ZONA_EXIGE_SCTR, ZONA_EXIGE_EPP, TRAE_EQUIPOS o TRAE_HERRAMIENTAS.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Critico",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Critico debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Item_Checklist"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Item_Checklist" ("Codigo","Descripcion","Ayuda","Etapa","Condicion","Es_Critico","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), NULLIF(TRIM("HV_Ayuda"),''), UPPER(TRIM("HV_Etapa")), UPPER(TRIM("HV_Condicion")), COALESCE("HV_Es_Critico",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Item_Checklist" INTO "HV_ID_Catalogo_Item_Checklist_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ítem de checklist registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_CREAR';
        "HV_ID_Catalogo_Item_Checklist_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CATALOGO_ITEM_CHECKLIST_DETALLE(bigint); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_DETALLE"("HV_ID_Catalogo_Item_Checklist" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Ayuda" character varying, "Etapa" character varying, "Condicion" character varying, "Es_Critico" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Item_Checklist", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Ayuda", T0."Etapa", T0."Condicion", T0."Es_Critico", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Item_Checklist" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist";
END;
$$;

-- Name: ERP_CATALOGO_ITEM_CHECKLIST_DROPDOWN(character varying); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_DROPDOWN"("HV_Etapa" character varying DEFAULT NULL::character varying) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Ayuda" character varying, "Etapa" character varying, "Condicion" character varying, "Es_Critico" character)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
DECLARE
    lv_etapa VARCHAR(10) := '%';
BEGIN
    -- V1.0 2026-10-11
    IF LENGTH(TRIM("HV_Etapa")) > 0 THEN
        lv_etapa := UPPER(TRIM("HV_Etapa"));
    END IF;
    RETURN QUERY
    SELECT T0."ID_Catalogo_Item_Checklist", T0."Codigo", T0."Descripcion", T0."Ayuda", T0."Etapa", T0."Condicion", T0."Es_Critico"
      FROM "Catalogo_Item_Checklist" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y' AND T0."Etapa" LIKE lv_etapa
     ORDER BY T0."Etapa", T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR"(IN "HV_ID_Catalogo_Item_Checklist" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_en_uso FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' tipo(s) de acceso. Desactívelo en vez de eliminarlo.'; RETURN;
        END IF;
        -- Uso por tablas de los Hitos 2 a 4 (CAF_Registro_Checklist): se agrega aquí cuando existan.

        UPDATE "Catalogo_Item_Checklist"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ítem de checklist eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_ITEM_CHECKLIST_LISTAR(character); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Ayuda" character varying, "Etapa" character varying, "Condicion" character varying, "Es_Critico" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Item_Checklist", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Ayuda", T0."Etapa", T0."Condicion", T0."Es_Critico", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Item_Checklist" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Etapa", T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_MOTIVO_VISITA_ACTUALIZAR(bigint, character varying, character varying, character, bigint, character, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_ACTUALIZAR"(IN "HV_ID_Catalogo_Motivo_Visita" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_ACTUALIZAR';
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
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Motivo_Visita" WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Motivo_Visita"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Motivo_Visita" <> "HV_ID_Catalogo_Motivo_Visita";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Motivo_Visita"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Es_Otro" = COALESCE("HV_Es_Otro",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Motivo de visita actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_ACTUALIZAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_MOTIVO_VISITA_CREAR(character varying, character varying, character, bigint, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Motivo_Visita_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_CREAR';
    "HV_ID_Catalogo_Motivo_Visita_Result" := 0;
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
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Motivo_Visita"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Motivo_Visita" ("Codigo","Descripcion","Es_Otro","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), COALESCE("HV_Es_Otro",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Motivo_Visita" INTO "HV_ID_Catalogo_Motivo_Visita_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Motivo de visita registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_CREAR';
        "HV_ID_Catalogo_Motivo_Visita_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CATALOGO_MOTIVO_VISITA_DETALLE(bigint); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_DETALLE"("HV_ID_Catalogo_Motivo_Visita" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Motivo_Visita", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Motivo_Visita" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita";
END;
$$;

-- Name: ERP_CATALOGO_MOTIVO_VISITA_DROPDOWN(); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_DROPDOWN"() RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Es_Otro" character)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Motivo_Visita", T0."Codigo", T0."Descripcion", T0."Es_Otro"
      FROM "Catalogo_Motivo_Visita" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_MOTIVO_VISITA_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_ELIMINAR"(IN "HV_ID_Catalogo_Motivo_Visita" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Motivo_Visita" WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        -- Uso por tablas de los Hitos 2 a 4 (CAF_Solicitud): se agrega aquí cuando existan.

        UPDATE "Catalogo_Motivo_Visita"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Motivo de visita eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_ELIMINAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_MOTIVO_VISITA_LISTAR(character); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Motivo_Visita", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Motivo_Visita" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR(bigint, character varying, character varying, character, character, bigint, character, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR"(IN "HV_ID_Catalogo_Tipo_Acceso" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Requiere_Aprobacion" character, IN "HV_Disponible" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR';
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
        IF COALESCE("HV_Requiere_Aprobacion",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Requiere_Aprobacion debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Disponible",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Disponible debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tipo_Acceso"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Tipo_Acceso" <> "HV_ID_Catalogo_Tipo_Acceso";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Tipo_Acceso"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Requiere_Aprobacion" = COALESCE("HV_Requiere_Aprobacion",'Y'), "Disponible" = COALESCE("HV_Disponible",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de acceso actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_TIPO_ACCESO_CREAR(character varying, character varying, character, character, bigint, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Requiere_Aprobacion" character, IN "HV_Disponible" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Tipo_Acceso_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_CREAR';
    "HV_ID_Catalogo_Tipo_Acceso_Result" := 0;
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
        IF COALESCE("HV_Requiere_Aprobacion",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Requiere_Aprobacion debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Disponible",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Disponible debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tipo_Acceso"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Tipo_Acceso" ("Codigo","Descripcion","Requiere_Aprobacion","Disponible","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), COALESCE("HV_Requiere_Aprobacion",'Y'), COALESCE("HV_Disponible",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Tipo_Acceso" INTO "HV_ID_Catalogo_Tipo_Acceso_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de acceso registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_CREAR';
        "HV_ID_Catalogo_Tipo_Acceso_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CATALOGO_TIPO_ACCESO_DETALLE(bigint); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_DETALLE"("HV_ID_Catalogo_Tipo_Acceso" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Requiere_Aprobacion" character, "Disponible" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Acceso", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Requiere_Aprobacion", T0."Disponible", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tipo_Acceso" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso";
END;
$$;

-- Name: ERP_CATALOGO_TIPO_ACCESO_DROPDOWN(); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_DROPDOWN"() RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Requiere_Aprobacion" character, "Disponible" character)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Acceso", T0."Codigo", T0."Descripcion", T0."Requiere_Aprobacion", T0."Disponible"
      FROM "Catalogo_Tipo_Acceso" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_TIPO_ACCESO_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_ELIMINAR"(IN "HV_ID_Catalogo_Tipo_Acceso" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_en_uso FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' ítem(s) de checklist asignado(s). Desactívelo en vez de eliminarlo.'; RETURN;
        END IF;
        -- Uso por tablas de los Hitos 2 a 4 (CAF_Solicitud): se agrega aquí cuando existan.

        UPDATE "Catalogo_Tipo_Acceso"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de acceso eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_ELIMINAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_TIPO_ACCESO_LISTAR(character); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Requiere_Aprobacion" character, "Disponible" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Acceso", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Requiere_Aprobacion", T0."Disponible", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tipo_Acceso" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR(bigint, character varying, character varying, character, bigint, character, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR"(IN "HV_ID_Catalogo_Tipo_Incidencia" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR';
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
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tipo_Incidencia" WHERE "ID_Catalogo_Tipo_Incidencia" = "HV_ID_Catalogo_Tipo_Incidencia" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tipo_Incidencia"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Tipo_Incidencia" <> "HV_ID_Catalogo_Tipo_Incidencia";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Tipo_Incidencia"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Es_Otro" = COALESCE("HV_Es_Otro",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tipo_Incidencia" = "HV_ID_Catalogo_Tipo_Incidencia";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de incidencia actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_TIPO_INCIDENCIA_CREAR(character varying, character varying, character, bigint, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Tipo_Incidencia_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_CREAR';
    "HV_ID_Catalogo_Tipo_Incidencia_Result" := 0;
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
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tipo_Incidencia"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Tipo_Incidencia" ("Codigo","Descripcion","Es_Otro","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), COALESCE("HV_Es_Otro",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Tipo_Incidencia" INTO "HV_ID_Catalogo_Tipo_Incidencia_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de incidencia registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_CREAR';
        "HV_ID_Catalogo_Tipo_Incidencia_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CATALOGO_TIPO_INCIDENCIA_DETALLE(bigint); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_DETALLE"("HV_ID_Catalogo_Tipo_Incidencia" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Incidencia", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tipo_Incidencia" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Tipo_Incidencia" = "HV_ID_Catalogo_Tipo_Incidencia";
END;
$$;

-- Name: ERP_CATALOGO_TIPO_INCIDENCIA_DROPDOWN(); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_DROPDOWN"() RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Es_Otro" character)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Incidencia", T0."Codigo", T0."Descripcion", T0."Es_Otro"
      FROM "Catalogo_Tipo_Incidencia" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR"(IN "HV_ID_Catalogo_Tipo_Incidencia" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tipo_Incidencia" WHERE "ID_Catalogo_Tipo_Incidencia" = "HV_ID_Catalogo_Tipo_Incidencia" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        -- Uso por tablas de los Hitos 2 a 4 (CAF_Incidencia): se agrega aquí cuando existan.

        UPDATE "Catalogo_Tipo_Incidencia"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tipo_Incidencia" = "HV_ID_Catalogo_Tipo_Incidencia";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de incidencia eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR';
    END;
END;
$$;

-- Name: ERP_CATALOGO_TIPO_INCIDENCIA_LISTAR(character); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Incidencia", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tipo_Incidencia" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;

-- Name: ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR(bigint, character varying, character varying, character, character, character varying, character varying, character, bigint, character, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR"(IN "HV_ID_Catalogo_Tratamiento_Desviacion" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Aplica_Ingreso" character, IN "HV_Aplica_Salida" character, IN "HV_Resultado_Ingreso" character varying, IN "HV_Resultado_Salida" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR(character varying, character varying, character, character, character varying, character varying, character, bigint, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Aplica_Ingreso" character, IN "HV_Aplica_Salida" character, IN "HV_Resultado_Ingreso" character varying, IN "HV_Resultado_Salida" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Tratamiento_Desviacion_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_TRATAMIENTO_DESVIACION_DETALLE(bigint); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_DETALLE"("HV_ID_Catalogo_Tratamiento_Desviacion" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Aplica_Ingreso" character, "Aplica_Salida" character, "Resultado_Ingreso" character varying, "Resultado_Salida" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN(character varying); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN"("HV_Etapa" character varying DEFAULT NULL::character varying) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Aplica_Ingreso" character, "Aplica_Salida" character, "Resultado_Ingreso" character varying, "Resultado_Salida" character varying, "Es_Otro" character)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR"(IN "HV_ID_Catalogo_Tratamiento_Desviacion" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_TRATAMIENTO_DESVIACION_LISTAR(character); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Aplica_Ingreso" character, "Aplica_Salida" character, "Resultado_Ingreso" character varying, "Resultado_Salida" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR(bigint, character varying, character varying, bigint, character varying, character, character, bigint, character, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR"(IN "HV_ID_Catalogo_Zona_Acceso" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_ID_Catalogo_Sede" bigint, IN "HV_Tipo_Zona" character varying, IN "HV_Exige_SCTR" character, IN "HV_Exige_EPP" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_ZONA_ACCESO_CREAR(character varying, character varying, bigint, character varying, character, character, bigint, character, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_ID_Catalogo_Sede" bigint, IN "HV_Tipo_Zona" character varying, IN "HV_Exige_SCTR" character, IN "HV_Exige_EPP" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Zona_Acceso_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_ZONA_ACCESO_DETALLE(bigint); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_DETALLE"("HV_ID_Catalogo_Zona_Acceso" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "ID_Catalogo_Sede" bigint, "Codigo_Sede" character varying, "Sede" character varying, "Tipo_Zona" character varying, "Exige_SCTR" character, "Exige_EPP" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_ZONA_ACCESO_DROPDOWN(bigint); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_DROPDOWN"("HV_ID_Catalogo_Sede" bigint) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Zona" character varying, "Exige_SCTR" character, "Exige_EPP" character)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_ZONA_ACCESO_ELIMINAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_ELIMINAR"(IN "HV_ID_Catalogo_Zona_Acceso" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_CATALOGO_ZONA_ACCESO_LISTAR(bigint, character); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_LISTAR"("HV_ID_Catalogo_Sede" bigint DEFAULT NULL::bigint, "HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar) RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "ID_Catalogo_Sede" bigint, "Codigo_Sede" character varying, "Sede" character varying, "Tipo_Zona" character varying, "Exige_SCTR" character, "Exige_EPP" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
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

-- Name: ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR(bigint, bigint, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(IN "HV_ID_Catalogo_Tipo_Acceso" bigint, IN "HV_ID_Catalogo_Item_Checklist" bigint, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Tipo_Acceso_Item_Checklist_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n         INT := 0;
    lv_id        BIGINT;
    lv_eliminado CHAR(1);
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR';
    "HV_ID_Tipo_Acceso_Item_Checklist_Result" := 0;
    BEGIN
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- El tipo de acceso puede estar inactivo o no disponible: su checklist se prepara antes de habilitarlo
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El tipo de acceso no existe.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El ítem de checklist no existe o está inactivo.'; RETURN; END IF;

        SELECT MAX("ID_Tipo_Acceso_Item_Checklist"), MAX("Eliminado") INTO lv_id, lv_eliminado
          FROM "Tipo_Acceso_Item_Checklist"
         WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist";

        IF lv_id IS NOT NULL AND lv_eliminado = 'N' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'El ítem ya está asignado a ese tipo de acceso.'; RETURN;
        ELSIF lv_id IS NOT NULL THEN
            UPDATE "Tipo_Acceso_Item_Checklist"
               SET "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID_Create", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Tipo_Acceso_Item_Checklist" = lv_id;
            "HV_ID_Tipo_Acceso_Item_Checklist_Result" := lv_id;
        ELSE
            INSERT INTO "Tipo_Acceso_Item_Checklist" ("ID_Catalogo_Tipo_Acceso","ID_Catalogo_Item_Checklist","UsuarioID_Create")
            VALUES ("HV_ID_Catalogo_Tipo_Acceso", "HV_ID_Catalogo_Item_Checklist", "HV_UsuarioID_Create")
            RETURNING "ID_Tipo_Acceso_Item_Checklist" INTO "HV_ID_Tipo_Acceso_Item_Checklist_Result";
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ítem asignado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR';
        "HV_ID_Tipo_Acceso_Item_Checklist_Result" := 0;
    END;
END;
$$;

-- Name: ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE(bigint); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE"("HV_ID_Catalogo_Tipo_Acceso" bigint) RETURNS TABLE("ID_Tipo_Acceso_Item_Checklist" bigint, "ID_Catalogo_Tipo_Acceso" bigint, "ID_Catalogo_Item_Checklist" bigint, "Codigo_Item_Checklist" character varying, "Item_Checklist" character varying, "Ayuda" character varying, "Etapa" character varying, "Condicion" character varying, "Es_Critico" character, "Orden" bigint, "Activo" character, "CreateDate" timestamp without time zone)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Tipo_Acceso_Item_Checklist", T0."ID_Catalogo_Tipo_Acceso", T0."ID_Catalogo_Item_Checklist",
           I."Codigo", I."Descripcion", I."Ayuda", I."Etapa", I."Condicion", I."Es_Critico", I."Orden", I."Activo",
           T0."CreateDate"
      FROM "Tipo_Acceso_Item_Checklist" T0
      JOIN "Catalogo_Item_Checklist" I ON I."ID_Catalogo_Item_Checklist" = T0."ID_Catalogo_Item_Checklist"
     WHERE T0."ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND T0."Eliminado" = 'N'
     ORDER BY I."Etapa", I."Orden", I."Codigo";
END;
$$;

-- Name: ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR"(IN "HV_ID_Tipo_Acceso_Item_Checklist" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Item_Checklist"
         WHERE "ID_Tipo_Acceso_Item_Checklist" = "HV_ID_Tipo_Acceso_Item_Checklist" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La asignación no existe o ya fue quitada.'; RETURN;
        END IF;

        UPDATE "Tipo_Acceso_Item_Checklist"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Tipo_Acceso_Item_Checklist" = "HV_ID_Tipo_Acceso_Item_Checklist";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ítem retirado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR';
    END;
END;
$$;

-- Name: CAF_Correo_Pendiente; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Correo_Pendiente" (
    "ID_Correo_Pendiente" bigint NOT NULL,
    "Tipo" character varying(50) NOT NULL,
    "ID_Solicitud" bigint,
    "Destinatarios" character varying(2000) NOT NULL,
    "Copia" character varying(2000),
    "Asunto" character varying(500) NOT NULL,
    "Cuerpo" text NOT NULL,
    "Estado" character varying(20) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    "Intentos" bigint DEFAULT 0 NOT NULL,
    "Ultimo_Error" character varying(1000),
    "Fecha_Envio" timestamp without time zone,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Correo_Pendiente_Estado" CHECK ((("Estado")::text = ANY ((ARRAY['PENDIENTE'::character varying, 'ENVIADO'::character varying, 'ERROR'::character varying])::text[]))),
    CONSTRAINT "CK_CAF_Correo_Pendiente_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT "CK_CAF_Correo_Pendiente_Intentos" CHECK (("Intentos" >= 0)),
    CONSTRAINT "CK_CAF_Correo_Pendiente_Tipo" CHECK ((("Tipo")::text = ANY ((ARRAY['SOLICITUD_NUEVA'::character varying, 'SOLICITUD_EDITADA'::character varying, 'SOLICITUD_OBSERVADA'::character varying, 'SOLICITUD_APROBADA'::character varying, 'SOLICITUD_CANCELADA'::character varying, 'USUARIO_DEFINIR_PASSWORD'::character varying])::text[])))
);

-- Name: CAF_Correo_Pendiente_ID_Correo_Pendiente_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Correo_Pendiente" ALTER COLUMN "ID_Correo_Pendiente" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Correo_Pendiente_ID_Correo_Pendiente_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Desviacion; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Desviacion" (
    "ID_Desviacion" bigint NOT NULL,
    "Codigo" character varying(20),
    "ID_Registro_Acceso" bigint NOT NULL,
    "Descripcion" character varying(2000) NOT NULL,
    "ID_Usuario_Coordinador_Consultado" bigint NOT NULL,
    "ID_Catalogo_Tratamiento_Desviacion" bigint NOT NULL,
    "Tratamiento_Detalle" character varying(500),
    "Resultado" character varying(30) NOT NULL,
    "Estado" character varying(20) DEFAULT 'POR_REVISAR'::character varying NOT NULL,
    "ID_Usuario_Conformidad" bigint,
    "Fecha_Conformidad" timestamp without time zone,
    "Comentario_Conformidad" character varying(1000),
    "ID_Incidencia" bigint,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Desviacion_Conformidad" CHECK (((("Estado")::text = 'POR_REVISAR'::text) OR (("ID_Usuario_Conformidad" IS NOT NULL) AND ("Fecha_Conformidad" IS NOT NULL)))),
    CONSTRAINT "CK_CAF_Desviacion_Estado" CHECK ((("Estado")::text = ANY ((ARRAY['POR_REVISAR'::character varying, 'REVISADA'::character varying])::text[]))),
    CONSTRAINT "CK_CAF_Desviacion_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT "CK_CAF_Desviacion_Resultado" CHECK ((("Resultado")::text = ANY ((ARRAY['INGRESA'::character varying, 'INGRESA_RESTRINGIDO'::character varying, 'NO_INGRESA'::character varying, 'SALE'::character varying, 'SALE_RETIENE_ELEMENTO'::character varying])::text[])))
);

-- Name: CAF_Desviacion_ID_Desviacion_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Desviacion" ALTER COLUMN "ID_Desviacion" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Desviacion_ID_Desviacion_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Evento; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Evento" (
    "ID_Evento" bigint NOT NULL,
    "Entidad" character varying(50) NOT NULL,
    "ID_Entidad" bigint NOT NULL,
    "ID_Solicitud" bigint,
    "Accion" character varying(50) NOT NULL,
    "Detalle" character varying(2000),
    "ID_Usuario" bigint NOT NULL,
    "Fecha_Evento" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT "CK_CAF_Evento_Entidad" CHECK ((("Entidad")::text = ANY ((ARRAY['SOLICITUD'::character varying, 'SOLICITUD_PERSONA'::character varying, 'SOLICITUD_DECISION'::character varying, 'REGISTRO_ACCESO'::character varying, 'DESVIACION'::character varying, 'INCIDENCIA'::character varying, 'PERSONA_EXTERNA'::character varying])::text[])))
);

-- Name: CAF_Evento_ID_Evento_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Evento" ALTER COLUMN "ID_Evento" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Evento_ID_Evento_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Incidencia; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia" (
    "ID_Incidencia" bigint NOT NULL,
    "Codigo" character varying(20),
    "ID_Catalogo_Sede" bigint NOT NULL,
    "ID_Catalogo_Tipo_Incidencia" bigint NOT NULL,
    "Tipo_Detalle" character varying(500),
    "Fecha_Hora_Hecho" timestamp without time zone NOT NULL,
    "ID_Catalogo_Zona_Acceso" bigint,
    "Lugar_Detalle" character varying(200),
    "Descripcion" character varying(2000) NOT NULL,
    "Origen" character varying(20) NOT NULL,
    "ID_Usuario_Registro" bigint NOT NULL,
    "Estado" character varying(20) NOT NULL,
    "ID_Usuario_Decision" bigint,
    "Fecha_Decision" timestamp without time zone,
    "Sustento_Decision" character varying(2000),
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Incidencia_Decision" CHECK (((("Estado")::text = 'REGISTRADA'::text) OR (("ID_Usuario_Decision" IS NOT NULL) AND ("Fecha_Decision" IS NOT NULL)))),
    CONSTRAINT "CK_CAF_Incidencia_Estado" CHECK ((("Estado")::text = ANY ((ARRAY['REGISTRADA'::character varying, 'CONFIRMADA'::character varying, 'DESESTIMADA'::character varying])::text[]))),
    CONSTRAINT "CK_CAF_Incidencia_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT "CK_CAF_Incidencia_Lugar" CHECK ((("ID_Catalogo_Zona_Acceso" IS NOT NULL) OR ("Lugar_Detalle" IS NOT NULL))),
    CONSTRAINT "CK_CAF_Incidencia_Origen" CHECK ((("Origen")::text = ANY ((ARRAY['VIGILANCIA'::character varying, 'COORDINADOR'::character varying])::text[])))
);

-- Name: CAF_Incidencia_ID_Incidencia_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia" ALTER COLUMN "ID_Incidencia" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia_ID_Incidencia_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Incidencia_Persona; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia_Persona" (
    "ID_Incidencia_Persona" bigint NOT NULL,
    "ID_Incidencia" bigint NOT NULL,
    "ID_Solicitud_Persona" bigint NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Incidencia_Persona_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);

-- Name: CAF_Incidencia_Persona_ID_Incidencia_Persona_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia_Persona" ALTER COLUMN "ID_Incidencia_Persona" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia_Persona_ID_Incidencia_Persona_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Persona_Externa; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Persona_Externa" (
    "ID_Persona_Externa" bigint NOT NULL,
    "ID_Catalogo_Tipo_Documento" bigint NOT NULL,
    "Numero_Documento" character varying(20) NOT NULL,
    "Apellido_Paterno" character varying(100) NOT NULL,
    "Apellido_Materno" character varying(100),
    "Nombres" character varying(200) NOT NULL,
    "Fecha_Ultima_Visita" timestamp without time zone,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Persona_Externa_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);

-- Name: CAF_Persona_Externa_ID_Persona_Externa_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Persona_Externa" ALTER COLUMN "ID_Persona_Externa" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Persona_Externa_ID_Persona_Externa_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Registro_Acceso; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Acceso" (
    "ID_Registro_Acceso" bigint NOT NULL,
    "ID_Solicitud_Persona" bigint NOT NULL,
    "ID_Catalogo_Sede" bigint NOT NULL,
    "Tipo_Movimiento" character varying(10) NOT NULL,
    "Resultado" character varying(30) NOT NULL,
    "Fecha_Hora" timestamp without time zone NOT NULL,
    "Es_Registro_Tardio" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Fecha_Hora_Sistema" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "ID_Usuario_Vigilante" bigint NOT NULL,
    "Observacion" character varying(1000),
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Registro_Acceso_Flags" CHECK ((("Es_Registro_Tardio" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))),
    CONSTRAINT "CK_CAF_Registro_Acceso_Resultado" CHECK ((((("Tipo_Movimiento")::text = 'INGRESO'::text) AND (("Resultado")::text = ANY ((ARRAY['INGRESA'::character varying, 'INGRESA_RESTRINGIDO'::character varying, 'NO_INGRESA'::character varying])::text[]))) OR ((("Tipo_Movimiento")::text = 'SALIDA'::text) AND (("Resultado")::text = ANY ((ARRAY['SALE'::character varying, 'SALE_RETIENE_ELEMENTO'::character varying])::text[]))))),
    CONSTRAINT "CK_CAF_Registro_Acceso_Tipo" CHECK ((("Tipo_Movimiento")::text = ANY ((ARRAY['INGRESO'::character varying, 'SALIDA'::character varying])::text[])))
);

-- Name: CAF_Registro_Acceso_ID_Registro_Acceso_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Acceso" ALTER COLUMN "ID_Registro_Acceso" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Acceso_ID_Registro_Acceso_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Registro_Checklist; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Checklist" (
    "ID_Registro_Checklist" bigint NOT NULL,
    "ID_Registro_Acceso" bigint NOT NULL,
    "ID_Catalogo_Item_Checklist" bigint NOT NULL,
    "Cumple" character(1) NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Registro_Checklist_Flags" CHECK ((("Cumple" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))))
);

-- Name: CAF_Registro_Checklist_ID_Registro_Checklist_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Checklist" ALTER COLUMN "ID_Registro_Checklist" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Checklist_ID_Registro_Checklist_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Respaldo; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo" (
    "ID_Respaldo" bigint NOT NULL,
    "ID_Catalogo_Sede" bigint NOT NULL,
    "Categoria" character varying(30) NOT NULL,
    "Tipo_Respaldo" character varying(30) NOT NULL,
    "Numero_Documento" character varying(50),
    "Fecha_Hora" timestamp without time zone NOT NULL,
    "ID_Usuario_Vigilante" bigint NOT NULL,
    "Observacion" character varying(1000),
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Respaldo_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))),
    CONSTRAINT "CK_CAF_Respaldo_Tipo" CHECK ((((("Categoria")::text = 'EQUIPOS'::text) AND (("Tipo_Respaldo")::text = 'G_FSCA_009'::text)) OR ((("Categoria")::text = 'HERRAMIENTAS_MATERIALES'::text) AND (("Tipo_Respaldo")::text = ANY ((ARRAY['GUIA_REMISION'::character varying, 'GUIA_MANUAL_G_FSCA_010'::character varying])::text[])))))
);

-- Name: CAF_Respaldo_ID_Respaldo_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo" ALTER COLUMN "ID_Respaldo" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo_ID_Respaldo_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Respaldo_Persona; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo_Persona" (
    "ID_Respaldo_Persona" bigint NOT NULL,
    "ID_Respaldo" bigint NOT NULL,
    "ID_Solicitud_Persona" bigint NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Respaldo_Persona_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);

-- Name: CAF_Respaldo_Persona_ID_Respaldo_Persona_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo_Persona" ALTER COLUMN "ID_Respaldo_Persona" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo_Persona_ID_Respaldo_Persona_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Solicitud; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud" (
    "ID_Solicitud" bigint NOT NULL,
    "Codigo" character varying(20),
    "ID_Catalogo_Sede" bigint NOT NULL,
    "ID_Catalogo_Tipo_Acceso" bigint NOT NULL,
    "ID_Usuario_Solicitante" bigint NOT NULL,
    "ID_Personal_Responsable" bigint NOT NULL,
    "Fecha_Hora_Prevista" timestamp without time zone NOT NULL,
    "Empresa_Visitante" character varying(500) NOT NULL,
    "ID_Catalogo_Motivo_Visita" bigint NOT NULL,
    "Motivo_Detalle" character varying(500),
    "Observaciones" character varying(2000),
    "Exige_SCTR" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Exige_EPP" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Estado" character varying(20) NOT NULL,
    "Version" bigint DEFAULT 1 NOT NULL,
    "Fecha_Envio" timestamp without time zone,
    "ID_Usuario_Decision" bigint,
    "Fecha_Decision" timestamp without time zone,
    "Observacion_Coordinador" character varying(2000),
    "Motivo_Cancelacion" character varying(500),
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    "ID_Solicitud_Origen" bigint,
    CONSTRAINT "CK_CAF_Solicitud_Estado" CHECK ((("Estado")::text = ANY ((ARRAY['PENDIENTE'::character varying, 'OBSERVADA'::character varying, 'APROBADA'::character varying, 'APROBADA_PARCIAL'::character varying, 'RECHAZADA'::character varying, 'CANCELADA'::character varying])::text[]))),
    CONSTRAINT "CK_CAF_Solicitud_Flags" CHECK ((("Exige_SCTR" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Exige_EPP" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))),
    CONSTRAINT "CK_CAF_Solicitud_Version" CHECK (("Version" >= 1))
);

-- Name: CAF_Solicitud_Copia_Correo; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Copia_Correo" (
    "ID_Solicitud_Copia_Correo" bigint NOT NULL,
    "ID_Solicitud" bigint NOT NULL,
    "Correo" character varying(200) NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Solicitud_Copia_Correo_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);

-- Name: CAF_Solicitud_Copia_Correo_ID_Solicitud_Copia_Correo_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Copia_Correo" ALTER COLUMN "ID_Solicitud_Copia_Correo" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Copia_Correo_ID_Solicitud_Copia_Correo_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Solicitud_Decision; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Decision" (
    "ID_Solicitud_Decision" bigint NOT NULL,
    "ID_Solicitud_Persona" bigint NOT NULL,
    "ID_Tipo_Acceso_Paso_Aprobacion" bigint NOT NULL,
    "Decision" character varying(20) NOT NULL,
    "Mensaje" character varying(2000),
    "ID_Usuario" bigint NOT NULL,
    "Fecha_Decision" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "Vigente" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Solicitud_Decision_Flags" CHECK ((("Vigente" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))),
    CONSTRAINT "CK_CAF_Solicitud_Decision_Motivo" CHECK (((("Decision")::text = 'APROBADA'::text) OR (("Mensaje" IS NOT NULL) AND (length(TRIM(BOTH FROM "Mensaje")) > 0)))),
    CONSTRAINT "CK_CAF_Solicitud_Decision_Valor" CHECK ((("Decision")::text = ANY ((ARRAY['APROBADA'::character varying, 'OBSERVADA'::character varying, 'RECHAZADA'::character varying])::text[])))
);

-- Name: CAF_Solicitud_Decision_ID_Solicitud_Decision_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Decision" ALTER COLUMN "ID_Solicitud_Decision" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Decision_ID_Solicitud_Decision_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Solicitud_ID_Solicitud_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud" ALTER COLUMN "ID_Solicitud" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_ID_Solicitud_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Solicitud_Persona; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona" (
    "ID_Solicitud_Persona" bigint NOT NULL,
    "ID_Solicitud" bigint NOT NULL,
    "ID_Persona_Externa" bigint NOT NULL,
    "Estado" character varying(20) DEFAULT 'ESPERADA'::character varying NOT NULL,
    "Acceso_Restringido" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Trae_Equipos" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Trae_Herramientas" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Fecha_Hora_Ingreso" timestamp without time zone,
    "Fecha_Hora_Salida" timestamp without time zone,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    "Aprobacion" character varying(20) DEFAULT 'PENDIENTE'::character varying NOT NULL,
    "Aprobacion_Mensaje" character varying(2000),
    "ID_Usuario_Aprobacion" bigint,
    "Fecha_Aprobacion" timestamp without time zone,
    "Origen" character varying(20) DEFAULT 'SOLICITUD'::character varying NOT NULL,
    CONSTRAINT "CK_CAF_Solicitud_Persona_Aprobacion" CHECK ((("Aprobacion")::text = ANY ((ARRAY['PENDIENTE'::character varying, 'APROBADA'::character varying, 'OBSERVADA'::character varying, 'RECHAZADA'::character varying, 'RETIRADA'::character varying])::text[]))),
    CONSTRAINT "CK_CAF_Solicitud_Persona_Estado" CHECK ((("Estado")::text = ANY ((ARRAY['ESPERADA'::character varying, 'DENTRO'::character varying, 'SALIO'::character varying, 'DENEGADA'::character varying, 'NO_SE_PRESENTO'::character varying])::text[]))),
    CONSTRAINT "CK_CAF_Solicitud_Persona_Flags" CHECK ((("Acceso_Restringido" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Trae_Equipos" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Trae_Herramientas" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))),
    CONSTRAINT "CK_CAF_Solicitud_Persona_Ingreso" CHECK (((("Estado")::text = 'ESPERADA'::text) OR (("Aprobacion")::text = 'APROBADA'::text))),
    CONSTRAINT "CK_CAF_Solicitud_Persona_Motivo" CHECK (((("Aprobacion")::text <> ALL ((ARRAY['OBSERVADA'::character varying, 'RECHAZADA'::character varying])::text[])) OR (("Aprobacion_Mensaje" IS NOT NULL) AND (length(TRIM(BOTH FROM "Aprobacion_Mensaje")) > 0)))),
    CONSTRAINT "CK_CAF_Solicitud_Persona_Origen" CHECK ((("Origen")::text = ANY ((ARRAY['SOLICITUD'::character varying, 'AGREGADA'::character varying, 'AGREGADA_COORDINADOR'::character varying, 'REENVIADA'::character varying, 'REABIERTA'::character varying])::text[])))
);

-- Name: CAF_Solicitud_Persona_ID_Solicitud_Persona_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona" ALTER COLUMN "ID_Solicitud_Persona" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona_ID_Solicitud_Persona_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Solicitud_Version; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Version" (
    "ID_Solicitud_Version" bigint NOT NULL,
    "ID_Solicitud" bigint NOT NULL,
    "Version" bigint NOT NULL,
    "Contenido_JSON" text NOT NULL,
    "ID_Usuario_Aprobador" bigint,
    "Fecha_Aprobacion" timestamp without time zone NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Solicitud_Version_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);

-- Name: CAF_Solicitud_Version_ID_Solicitud_Version_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Version" ALTER COLUMN "ID_Solicitud_Version" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Version_ID_Solicitud_Version_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Solicitud_Zona; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Zona" (
    "ID_Solicitud_Zona" bigint NOT NULL,
    "ID_Solicitud" bigint NOT NULL,
    "ID_Catalogo_Zona_Acceso" bigint NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_CAF_Solicitud_Zona_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);

-- Name: CAF_Solicitud_Zona_ID_Solicitud_Zona_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Zona" ALTER COLUMN "ID_Solicitud_Zona" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Zona_ID_Solicitud_Zona_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Item_Checklist; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Item_Checklist" (
    "ID_Catalogo_Item_Checklist" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Ayuda" character varying(500),
    "Etapa" character varying(10) NOT NULL,
    "Condicion" character varying(30) NOT NULL,
    "Es_Critico" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Item_Checklist_Condicion" CHECK ((("Condicion")::text = ANY ((ARRAY['SIEMPRE'::character varying, 'ZONA_EXIGE_SCTR'::character varying, 'ZONA_EXIGE_EPP'::character varying, 'TRAE_EQUIPOS'::character varying, 'TRAE_HERRAMIENTAS'::character varying])::text[]))),
    CONSTRAINT "CK_Catalogo_Item_Checklist_Etapa" CHECK ((("Etapa")::text = ANY ((ARRAY['INGRESO'::character varying, 'SALIDA'::character varying])::text[]))),
    CONSTRAINT "CK_Catalogo_Item_Checklist_Flags" CHECK ((("Es_Critico" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))))
);

-- Name: Catalogo_Item_Checklist_ID_Catalogo_Item_Checklist_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Item_Checklist" ALTER COLUMN "ID_Catalogo_Item_Checklist" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Item_Checklist_ID_Catalogo_Item_Checklist_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Motivo_Visita; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Motivo_Visita" (
    "ID_Catalogo_Motivo_Visita" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Es_Otro" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Motivo_Visita_Flags" CHECK ((("Es_Otro" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))))
);

-- Name: Catalogo_Motivo_Visita_ID_Catalogo_Motivo_Visita_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Motivo_Visita" ALTER COLUMN "ID_Catalogo_Motivo_Visita" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Motivo_Visita_ID_Catalogo_Motivo_Visita_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Tipo_Acceso; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Acceso" (
    "ID_Catalogo_Tipo_Acceso" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Requiere_Aprobacion" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Disponible" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Tipo_Acceso_Flags" CHECK ((("Requiere_Aprobacion" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Disponible" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))))
);

-- Name: Catalogo_Tipo_Acceso_ID_Catalogo_Tipo_Acceso_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Acceso" ALTER COLUMN "ID_Catalogo_Tipo_Acceso" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Acceso_ID_Catalogo_Tipo_Acceso_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Tipo_Incidencia; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Incidencia" (
    "ID_Catalogo_Tipo_Incidencia" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Es_Otro" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Tipo_Incidencia_Flags" CHECK ((("Es_Otro" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar]))))
);

-- Name: Catalogo_Tipo_Incidencia_ID_Catalogo_Tipo_Incidencia_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Incidencia" ALTER COLUMN "ID_Catalogo_Tipo_Incidencia" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Incidencia_ID_Catalogo_Tipo_Incidencia_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Tratamiento_Desviacion; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tratamiento_Desviacion" (
    "ID_Catalogo_Tratamiento_Desviacion" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Aplica_Ingreso" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Aplica_Salida" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Resultado_Ingreso" character varying(30),
    "Resultado_Salida" character varying(30),
    "Es_Otro" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Tratamiento_Desviacion_Flags" CHECK ((("Aplica_Ingreso" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Aplica_Salida" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Es_Otro" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))),
    CONSTRAINT "CK_Catalogo_Tratamiento_Desviacion_Res_Ing" CHECK ((("Resultado_Ingreso" IS NULL) OR (("Resultado_Ingreso")::text = ANY ((ARRAY['INGRESA'::character varying, 'INGRESA_RESTRINGIDO'::character varying, 'NO_INGRESA'::character varying])::text[])))),
    CONSTRAINT "CK_Catalogo_Tratamiento_Desviacion_Res_Sal" CHECK ((("Resultado_Salida" IS NULL) OR (("Resultado_Salida")::text = ANY ((ARRAY['SALE'::character varying, 'SALE_RETIENE_ELEMENTO'::character varying])::text[]))))
);

-- Name: Catalogo_Tratamiento_Desviaci_ID_Catalogo_Tratamiento_Desvi_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tratamiento_Desviacion" ALTER COLUMN "ID_Catalogo_Tratamiento_Desviacion" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tratamiento_Desviaci_ID_Catalogo_Tratamiento_Desvi_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Catalogo_Zona_Acceso; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Zona_Acceso" (
    "ID_Catalogo_Zona_Acceso" bigint NOT NULL,
    "ID_Catalogo_Sede" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Tipo_Zona" character varying(20) NOT NULL,
    "Exige_SCTR" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Exige_EPP" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "Orden" bigint DEFAULT 0 NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Catalogo_Zona_Acceso_Flags" CHECK ((("Exige_SCTR" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Exige_EPP" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))),
    CONSTRAINT "CK_Catalogo_Zona_Acceso_Tipo" CHECK ((("Tipo_Zona")::text = ANY ((ARRAY['ADMINISTRATIVA'::character varying, 'OPERATIVA'::character varying])::text[])))
);

-- Name: Catalogo_Zona_Acceso_ID_Catalogo_Zona_Acceso_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Zona_Acceso" ALTER COLUMN "ID_Catalogo_Zona_Acceso" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Zona_Acceso_ID_Catalogo_Zona_Acceso_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Tipo_Acceso_Item_Checklist; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Item_Checklist" (
    "ID_Tipo_Acceso_Item_Checklist" bigint NOT NULL,
    "ID_Catalogo_Tipo_Acceso" bigint NOT NULL,
    "ID_Catalogo_Item_Checklist" bigint NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Tipo_Acceso_Item_Checklist_Flags" CHECK (("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);

-- Name: Tipo_Acceso_Item_Checklist_ID_Tipo_Acceso_Item_Checklist_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Item_Checklist" ALTER COLUMN "ID_Tipo_Acceso_Item_Checklist" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Item_Checklist_ID_Tipo_Acceso_Item_Checklist_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: Tipo_Acceso_Paso_Aprobacion; Type: TABLE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE TABLE "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Paso_Aprobacion" (
    "ID_Tipo_Acceso_Paso_Aprobacion" bigint NOT NULL,
    "ID_Catalogo_Tipo_Acceso" bigint NOT NULL,
    "Orden" bigint NOT NULL,
    "Codigo" character varying(50) NOT NULL,
    "Descripcion" character varying(500) NOT NULL,
    "Alcance" character varying(20) DEFAULT 'PERSONA'::character varying NOT NULL,
    "Tipo_Aprobador" character varying(20) DEFAULT 'ROL'::character varying NOT NULL,
    "ID_Catalogo_Licencia" bigint,
    "Condicion" character varying(30) DEFAULT 'SIEMPRE'::character varying NOT NULL,
    "Obligatorio" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Activo" character(1) DEFAULT 'Y'::bpchar NOT NULL,
    "Eliminado" character(1) DEFAULT 'N'::bpchar NOT NULL,
    "UsuarioID_Create" bigint NOT NULL,
    "UsuarioID_Update" bigint,
    "CreateDate" timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "UpdateDate" timestamp without time zone,
    CONSTRAINT "CK_Tipo_Acceso_Paso_Alcance" CHECK ((("Alcance")::text = ANY ((ARRAY['PERSONA'::character varying, 'SOLICITUD'::character varying])::text[]))),
    CONSTRAINT "CK_Tipo_Acceso_Paso_Aprobador" CHECK ((("Tipo_Aprobador")::text = 'ROL'::text)),
    CONSTRAINT "CK_Tipo_Acceso_Paso_Condicion" CHECK ((("Condicion")::text = 'SIEMPRE'::text)),
    CONSTRAINT "CK_Tipo_Acceso_Paso_Flags" CHECK ((("Obligatorio" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Activo" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])) AND ("Eliminado" = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))),
    CONSTRAINT "CK_Tipo_Acceso_Paso_Orden" CHECK (("Orden" >= 1)),
    CONSTRAINT "CK_Tipo_Acceso_Paso_Rol" CHECK (((("Tipo_Aprobador")::text <> 'ROL'::text) OR ("ID_Catalogo_Licencia" IS NOT NULL)))
);

-- Name: Tipo_Acceso_Paso_Aprobacion_ID_Tipo_Acceso_Paso_Aprobacion_seq; Type: SEQUENCE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Paso_Aprobacion" ALTER COLUMN "ID_Tipo_Acceso_Paso_Aprobacion" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Paso_Aprobacion_ID_Tipo_Acceso_Paso_Aprobacion_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

-- Name: CAF_Correo_Pendiente PK_CAF_Correo_Pendiente; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Correo_Pendiente"
    ADD CONSTRAINT "PK_CAF_Correo_Pendiente" PRIMARY KEY ("ID_Correo_Pendiente");

-- Name: CAF_Desviacion PK_CAF_Desviacion; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Desviacion"
    ADD CONSTRAINT "PK_CAF_Desviacion" PRIMARY KEY ("ID_Desviacion");

-- Name: CAF_Evento PK_CAF_Evento; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Evento"
    ADD CONSTRAINT "PK_CAF_Evento" PRIMARY KEY ("ID_Evento");

-- Name: CAF_Incidencia PK_CAF_Incidencia; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia"
    ADD CONSTRAINT "PK_CAF_Incidencia" PRIMARY KEY ("ID_Incidencia");

-- Name: CAF_Incidencia_Persona PK_CAF_Incidencia_Persona; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia_Persona"
    ADD CONSTRAINT "PK_CAF_Incidencia_Persona" PRIMARY KEY ("ID_Incidencia_Persona");

-- Name: CAF_Persona_Externa PK_CAF_Persona_Externa; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Persona_Externa"
    ADD CONSTRAINT "PK_CAF_Persona_Externa" PRIMARY KEY ("ID_Persona_Externa");

-- Name: CAF_Registro_Acceso PK_CAF_Registro_Acceso; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Acceso"
    ADD CONSTRAINT "PK_CAF_Registro_Acceso" PRIMARY KEY ("ID_Registro_Acceso");

-- Name: CAF_Registro_Checklist PK_CAF_Registro_Checklist; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Checklist"
    ADD CONSTRAINT "PK_CAF_Registro_Checklist" PRIMARY KEY ("ID_Registro_Checklist");

-- Name: CAF_Respaldo PK_CAF_Respaldo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo"
    ADD CONSTRAINT "PK_CAF_Respaldo" PRIMARY KEY ("ID_Respaldo");

-- Name: CAF_Respaldo_Persona PK_CAF_Respaldo_Persona; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo_Persona"
    ADD CONSTRAINT "PK_CAF_Respaldo_Persona" PRIMARY KEY ("ID_Respaldo_Persona");

-- Name: CAF_Solicitud PK_CAF_Solicitud; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud"
    ADD CONSTRAINT "PK_CAF_Solicitud" PRIMARY KEY ("ID_Solicitud");

-- Name: CAF_Solicitud_Copia_Correo PK_CAF_Solicitud_Copia_Correo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Copia_Correo"
    ADD CONSTRAINT "PK_CAF_Solicitud_Copia_Correo" PRIMARY KEY ("ID_Solicitud_Copia_Correo");

-- Name: CAF_Solicitud_Decision PK_CAF_Solicitud_Decision; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Decision"
    ADD CONSTRAINT "PK_CAF_Solicitud_Decision" PRIMARY KEY ("ID_Solicitud_Decision");

-- Name: CAF_Solicitud_Persona PK_CAF_Solicitud_Persona; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona"
    ADD CONSTRAINT "PK_CAF_Solicitud_Persona" PRIMARY KEY ("ID_Solicitud_Persona");

-- Name: CAF_Solicitud_Version PK_CAF_Solicitud_Version; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Version"
    ADD CONSTRAINT "PK_CAF_Solicitud_Version" PRIMARY KEY ("ID_Solicitud_Version");

-- Name: CAF_Solicitud_Zona PK_CAF_Solicitud_Zona; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Zona"
    ADD CONSTRAINT "PK_CAF_Solicitud_Zona" PRIMARY KEY ("ID_Solicitud_Zona");

-- Name: Catalogo_Item_Checklist PK_Catalogo_Item_Checklist; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Item_Checklist"
    ADD CONSTRAINT "PK_Catalogo_Item_Checklist" PRIMARY KEY ("ID_Catalogo_Item_Checklist");

-- Name: Catalogo_Motivo_Visita PK_Catalogo_Motivo_Visita; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Motivo_Visita"
    ADD CONSTRAINT "PK_Catalogo_Motivo_Visita" PRIMARY KEY ("ID_Catalogo_Motivo_Visita");

-- Name: Catalogo_Tipo_Acceso PK_Catalogo_Tipo_Acceso; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Acceso"
    ADD CONSTRAINT "PK_Catalogo_Tipo_Acceso" PRIMARY KEY ("ID_Catalogo_Tipo_Acceso");

-- Name: Catalogo_Tipo_Incidencia PK_Catalogo_Tipo_Incidencia; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Incidencia"
    ADD CONSTRAINT "PK_Catalogo_Tipo_Incidencia" PRIMARY KEY ("ID_Catalogo_Tipo_Incidencia");

-- Name: Catalogo_Tratamiento_Desviacion PK_Catalogo_Tratamiento_Desviacion; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tratamiento_Desviacion"
    ADD CONSTRAINT "PK_Catalogo_Tratamiento_Desviacion" PRIMARY KEY ("ID_Catalogo_Tratamiento_Desviacion");

-- Name: Catalogo_Zona_Acceso PK_Catalogo_Zona_Acceso; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Zona_Acceso"
    ADD CONSTRAINT "PK_Catalogo_Zona_Acceso" PRIMARY KEY ("ID_Catalogo_Zona_Acceso");

-- Name: Tipo_Acceso_Item_Checklist PK_Tipo_Acceso_Item_Checklist; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Item_Checklist"
    ADD CONSTRAINT "PK_Tipo_Acceso_Item_Checklist" PRIMARY KEY ("ID_Tipo_Acceso_Item_Checklist");

-- Name: Tipo_Acceso_Paso_Aprobacion PK_Tipo_Acceso_Paso_Aprobacion; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Paso_Aprobacion"
    ADD CONSTRAINT "PK_Tipo_Acceso_Paso_Aprobacion" PRIMARY KEY ("ID_Tipo_Acceso_Paso_Aprobacion");

-- Name: CAF_Desviacion UQ_CAF_Desviacion_Codigo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Desviacion"
    ADD CONSTRAINT "UQ_CAF_Desviacion_Codigo" UNIQUE ("Codigo");

-- Name: CAF_Desviacion UQ_CAF_Desviacion_Registro; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Desviacion"
    ADD CONSTRAINT "UQ_CAF_Desviacion_Registro" UNIQUE ("ID_Registro_Acceso");

-- Name: CAF_Incidencia UQ_CAF_Incidencia_Codigo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia"
    ADD CONSTRAINT "UQ_CAF_Incidencia_Codigo" UNIQUE ("Codigo");

-- Name: CAF_Incidencia_Persona UQ_CAF_Incidencia_Persona; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia_Persona"
    ADD CONSTRAINT "UQ_CAF_Incidencia_Persona" UNIQUE ("ID_Incidencia", "ID_Solicitud_Persona");

-- Name: CAF_Persona_Externa UQ_CAF_Persona_Externa_Documento; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Persona_Externa"
    ADD CONSTRAINT "UQ_CAF_Persona_Externa_Documento" UNIQUE ("ID_Catalogo_Tipo_Documento", "Numero_Documento");

-- Name: CAF_Registro_Checklist UQ_CAF_Registro_Checklist; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Checklist"
    ADD CONSTRAINT "UQ_CAF_Registro_Checklist" UNIQUE ("ID_Registro_Acceso", "ID_Catalogo_Item_Checklist");

-- Name: CAF_Respaldo_Persona UQ_CAF_Respaldo_Persona; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo_Persona"
    ADD CONSTRAINT "UQ_CAF_Respaldo_Persona" UNIQUE ("ID_Respaldo", "ID_Solicitud_Persona");

-- Name: CAF_Solicitud UQ_CAF_Solicitud_Codigo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud"
    ADD CONSTRAINT "UQ_CAF_Solicitud_Codigo" UNIQUE ("Codigo");

-- Name: CAF_Solicitud_Copia_Correo UQ_CAF_Solicitud_Copia_Correo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Copia_Correo"
    ADD CONSTRAINT "UQ_CAF_Solicitud_Copia_Correo" UNIQUE ("ID_Solicitud", "Correo");

-- Name: CAF_Solicitud_Persona UQ_CAF_Solicitud_Persona; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona"
    ADD CONSTRAINT "UQ_CAF_Solicitud_Persona" UNIQUE ("ID_Solicitud", "ID_Persona_Externa");

-- Name: CAF_Solicitud_Version UQ_CAF_Solicitud_Version; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Version"
    ADD CONSTRAINT "UQ_CAF_Solicitud_Version" UNIQUE ("ID_Solicitud", "Version");

-- Name: CAF_Solicitud_Zona UQ_CAF_Solicitud_Zona; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Zona"
    ADD CONSTRAINT "UQ_CAF_Solicitud_Zona" UNIQUE ("ID_Solicitud", "ID_Catalogo_Zona_Acceso");

-- Name: Catalogo_Item_Checklist UQ_Catalogo_Item_Checklist_Codigo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Item_Checklist"
    ADD CONSTRAINT "UQ_Catalogo_Item_Checklist_Codigo" UNIQUE ("Codigo");

-- Name: Catalogo_Motivo_Visita UQ_Catalogo_Motivo_Visita_Codigo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Motivo_Visita"
    ADD CONSTRAINT "UQ_Catalogo_Motivo_Visita_Codigo" UNIQUE ("Codigo");

-- Name: Catalogo_Tipo_Acceso UQ_Catalogo_Tipo_Acceso_Codigo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Acceso"
    ADD CONSTRAINT "UQ_Catalogo_Tipo_Acceso_Codigo" UNIQUE ("Codigo");

-- Name: Catalogo_Tipo_Incidencia UQ_Catalogo_Tipo_Incidencia_Codigo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Incidencia"
    ADD CONSTRAINT "UQ_Catalogo_Tipo_Incidencia_Codigo" UNIQUE ("Codigo");

-- Name: Catalogo_Tratamiento_Desviacion UQ_Catalogo_Tratamiento_Desviacion_Codigo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tratamiento_Desviacion"
    ADD CONSTRAINT "UQ_Catalogo_Tratamiento_Desviacion_Codigo" UNIQUE ("Codigo");

-- Name: Catalogo_Zona_Acceso UQ_Catalogo_Zona_Acceso_Sede_Codigo; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Zona_Acceso"
    ADD CONSTRAINT "UQ_Catalogo_Zona_Acceso_Sede_Codigo" UNIQUE ("ID_Catalogo_Sede", "Codigo");

-- Name: Tipo_Acceso_Item_Checklist UQ_Tipo_Acceso_Item_Checklist; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Item_Checklist"
    ADD CONSTRAINT "UQ_Tipo_Acceso_Item_Checklist" UNIQUE ("ID_Catalogo_Tipo_Acceso", "ID_Catalogo_Item_Checklist");

-- Name: Tipo_Acceso_Paso_Aprobacion UQ_Tipo_Acceso_Paso_Aprobacion; Type: CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Paso_Aprobacion"
    ADD CONSTRAINT "UQ_Tipo_Acceso_Paso_Aprobacion" UNIQUE ("ID_Catalogo_Tipo_Acceso", "Codigo");

-- Name: IX_CAF_Correo_Pendiente_Estado; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Correo_Pendiente_Estado" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Correo_Pendiente" USING btree ("Estado", "CreateDate");

-- Name: IX_CAF_Desviacion_Estado; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Desviacion_Estado" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Desviacion" USING btree ("Estado", "Eliminado", "CreateDate");

-- Name: IX_CAF_Evento_Entidad; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Evento_Entidad" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Evento" USING btree ("Entidad", "ID_Entidad");

-- Name: IX_CAF_Evento_Solicitud; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Evento_Solicitud" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Evento" USING btree ("ID_Solicitud", "Fecha_Evento");

-- Name: IX_CAF_Incidencia_Estado; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Incidencia_Estado" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia" USING btree ("ID_Catalogo_Sede", "Estado", "Fecha_Hora_Hecho");

-- Name: IX_CAF_Incidencia_Persona_Persona; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Incidencia_Persona_Persona" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia_Persona" USING btree ("ID_Solicitud_Persona");

-- Name: IX_CAF_Persona_Externa_Nombre; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Persona_Externa_Nombre" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Persona_Externa" USING btree ("Apellido_Paterno", "Nombres");

-- Name: IX_CAF_Registro_Acceso_Persona; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Registro_Acceso_Persona" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Acceso" USING btree ("ID_Solicitud_Persona", "Tipo_Movimiento");

-- Name: IX_CAF_Registro_Acceso_Reporte; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Registro_Acceso_Reporte" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Acceso" USING btree ("ID_Catalogo_Sede", "Fecha_Hora");

-- Name: IX_CAF_Respaldo_Persona_Persona; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Respaldo_Persona_Persona" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo_Persona" USING btree ("ID_Solicitud_Persona");

-- Name: IX_CAF_Respaldo_Sede_Fecha; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Respaldo_Sede_Fecha" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo" USING btree ("ID_Catalogo_Sede", "Fecha_Hora");

-- Name: IX_CAF_Solicitud_Decision_Paso; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Solicitud_Decision_Paso" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Decision" USING btree ("ID_Tipo_Acceso_Paso_Aprobacion", "Vigente");

-- Name: IX_CAF_Solicitud_Decision_Persona; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Solicitud_Decision_Persona" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Decision" USING btree ("ID_Solicitud_Persona", "Vigente");

-- Name: IX_CAF_Solicitud_Persona_Aprobacion; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Solicitud_Persona_Aprobacion" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona" USING btree ("ID_Solicitud", "Aprobacion", "Eliminado");

-- Name: IX_CAF_Solicitud_Persona_Estado; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Solicitud_Persona_Estado" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona" USING btree ("Estado", "Eliminado");

-- Name: IX_CAF_Solicitud_Persona_Persona; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Solicitud_Persona_Persona" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona" USING btree ("ID_Persona_Externa", "Estado");

-- Name: IX_CAF_Solicitud_Sede_Estado_Fecha; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Solicitud_Sede_Estado_Fecha" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud" USING btree ("ID_Catalogo_Sede", "Estado", "Fecha_Hora_Prevista");

-- Name: IX_CAF_Solicitud_Solicitante; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_CAF_Solicitud_Solicitante" ON "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud" USING btree ("ID_Usuario_Solicitante", "Eliminado", "Fecha_Hora_Prevista");

-- Name: IX_Catalogo_Item_Checklist_Activa; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_Catalogo_Item_Checklist_Activa" ON "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Item_Checklist" USING btree ("Etapa", "Eliminado", "Activo", "Orden");

-- Name: IX_Catalogo_Motivo_Visita_Activa; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_Catalogo_Motivo_Visita_Activa" ON "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Motivo_Visita" USING btree ("Eliminado", "Activo", "Orden");

-- Name: IX_Catalogo_Tipo_Acceso_Activa; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_Catalogo_Tipo_Acceso_Activa" ON "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Acceso" USING btree ("Eliminado", "Activo", "Orden");

-- Name: IX_Catalogo_Tipo_Incidencia_Activa; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_Catalogo_Tipo_Incidencia_Activa" ON "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Incidencia" USING btree ("Eliminado", "Activo", "Orden");

-- Name: IX_Catalogo_Tratamiento_Desviacion_Activa; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_Catalogo_Tratamiento_Desviacion_Activa" ON "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tratamiento_Desviacion" USING btree ("Eliminado", "Activo", "Orden");

-- Name: IX_Catalogo_Zona_Acceso_Activa; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_Catalogo_Zona_Acceso_Activa" ON "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Zona_Acceso" USING btree ("ID_Catalogo_Sede", "Eliminado", "Activo", "Orden");

-- Name: IX_Tipo_Acceso_Item_Checklist_Tipo; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_Tipo_Acceso_Item_Checklist_Tipo" ON "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Item_Checklist" USING btree ("ID_Catalogo_Tipo_Acceso", "Eliminado");

-- Name: IX_Tipo_Acceso_Paso_Tipo; Type: INDEX; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE INDEX "IX_Tipo_Acceso_Paso_Tipo" ON "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Paso_Aprobacion" USING btree ("ID_Catalogo_Tipo_Acceso", "Eliminado", "Orden");

-- Name: CAF_Correo_Pendiente FK_CAF_Correo_Pendiente_Solicitud; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Correo_Pendiente"
    ADD CONSTRAINT "FK_CAF_Correo_Pendiente_Solicitud" FOREIGN KEY ("ID_Solicitud") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud"("ID_Solicitud");

-- Name: CAF_Desviacion FK_CAF_Desviacion_Incidencia; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Desviacion"
    ADD CONSTRAINT "FK_CAF_Desviacion_Incidencia" FOREIGN KEY ("ID_Incidencia") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia"("ID_Incidencia");

-- Name: CAF_Desviacion FK_CAF_Desviacion_Registro; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Desviacion"
    ADD CONSTRAINT "FK_CAF_Desviacion_Registro" FOREIGN KEY ("ID_Registro_Acceso") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Acceso"("ID_Registro_Acceso");

-- Name: CAF_Desviacion FK_CAF_Desviacion_Tratamiento; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Desviacion"
    ADD CONSTRAINT "FK_CAF_Desviacion_Tratamiento" FOREIGN KEY ("ID_Catalogo_Tratamiento_Desviacion") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tratamiento_Desviacion"("ID_Catalogo_Tratamiento_Desviacion");

-- Name: CAF_Incidencia_Persona FK_CAF_Incidencia_Persona_Incidencia; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia_Persona"
    ADD CONSTRAINT "FK_CAF_Incidencia_Persona_Incidencia" FOREIGN KEY ("ID_Incidencia") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia"("ID_Incidencia");

-- Name: CAF_Incidencia_Persona FK_CAF_Incidencia_Persona_Persona; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia_Persona"
    ADD CONSTRAINT "FK_CAF_Incidencia_Persona_Persona" FOREIGN KEY ("ID_Solicitud_Persona") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona"("ID_Solicitud_Persona");

-- Name: CAF_Incidencia FK_CAF_Incidencia_Tipo; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia"
    ADD CONSTRAINT "FK_CAF_Incidencia_Tipo" FOREIGN KEY ("ID_Catalogo_Tipo_Incidencia") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Incidencia"("ID_Catalogo_Tipo_Incidencia");

-- Name: CAF_Incidencia FK_CAF_Incidencia_Zona; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia"
    ADD CONSTRAINT "FK_CAF_Incidencia_Zona" FOREIGN KEY ("ID_Catalogo_Zona_Acceso") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Zona_Acceso"("ID_Catalogo_Zona_Acceso");

-- Name: CAF_Registro_Acceso FK_CAF_Registro_Acceso_Solicitud_Persona; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Acceso"
    ADD CONSTRAINT "FK_CAF_Registro_Acceso_Solicitud_Persona" FOREIGN KEY ("ID_Solicitud_Persona") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona"("ID_Solicitud_Persona");

-- Name: CAF_Registro_Checklist FK_CAF_Registro_Checklist_Item; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Checklist"
    ADD CONSTRAINT "FK_CAF_Registro_Checklist_Item" FOREIGN KEY ("ID_Catalogo_Item_Checklist") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Item_Checklist"("ID_Catalogo_Item_Checklist");

-- Name: CAF_Registro_Checklist FK_CAF_Registro_Checklist_Registro; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Checklist"
    ADD CONSTRAINT "FK_CAF_Registro_Checklist_Registro" FOREIGN KEY ("ID_Registro_Acceso") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Acceso"("ID_Registro_Acceso");

-- Name: CAF_Respaldo_Persona FK_CAF_Respaldo_Persona_Persona; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo_Persona"
    ADD CONSTRAINT "FK_CAF_Respaldo_Persona_Persona" FOREIGN KEY ("ID_Solicitud_Persona") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona"("ID_Solicitud_Persona");

-- Name: CAF_Respaldo_Persona FK_CAF_Respaldo_Persona_Respaldo; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo_Persona"
    ADD CONSTRAINT "FK_CAF_Respaldo_Persona_Respaldo" FOREIGN KEY ("ID_Respaldo") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo"("ID_Respaldo");

-- Name: CAF_Solicitud_Copia_Correo FK_CAF_Solicitud_Copia_Correo_Solicitud; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Copia_Correo"
    ADD CONSTRAINT "FK_CAF_Solicitud_Copia_Correo_Solicitud" FOREIGN KEY ("ID_Solicitud") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud"("ID_Solicitud");

-- Name: CAF_Solicitud_Decision FK_CAF_Solicitud_Decision_Paso; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Decision"
    ADD CONSTRAINT "FK_CAF_Solicitud_Decision_Paso" FOREIGN KEY ("ID_Tipo_Acceso_Paso_Aprobacion") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Paso_Aprobacion"("ID_Tipo_Acceso_Paso_Aprobacion");

-- Name: CAF_Solicitud_Decision FK_CAF_Solicitud_Decision_Persona; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Decision"
    ADD CONSTRAINT "FK_CAF_Solicitud_Decision_Persona" FOREIGN KEY ("ID_Solicitud_Persona") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona"("ID_Solicitud_Persona");

-- Name: CAF_Solicitud FK_CAF_Solicitud_Motivo; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud"
    ADD CONSTRAINT "FK_CAF_Solicitud_Motivo" FOREIGN KEY ("ID_Catalogo_Motivo_Visita") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Motivo_Visita"("ID_Catalogo_Motivo_Visita");

-- Name: CAF_Solicitud FK_CAF_Solicitud_Origen; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud"
    ADD CONSTRAINT "FK_CAF_Solicitud_Origen" FOREIGN KEY ("ID_Solicitud_Origen") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud"("ID_Solicitud");

-- Name: CAF_Solicitud_Persona FK_CAF_Solicitud_Persona_Persona; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona"
    ADD CONSTRAINT "FK_CAF_Solicitud_Persona_Persona" FOREIGN KEY ("ID_Persona_Externa") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Persona_Externa"("ID_Persona_Externa");

-- Name: CAF_Solicitud_Persona FK_CAF_Solicitud_Persona_Solicitud; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona"
    ADD CONSTRAINT "FK_CAF_Solicitud_Persona_Solicitud" FOREIGN KEY ("ID_Solicitud") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud"("ID_Solicitud");

-- Name: CAF_Solicitud FK_CAF_Solicitud_Tipo_Acceso; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud"
    ADD CONSTRAINT "FK_CAF_Solicitud_Tipo_Acceso" FOREIGN KEY ("ID_Catalogo_Tipo_Acceso") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Acceso"("ID_Catalogo_Tipo_Acceso");

-- Name: CAF_Solicitud_Version FK_CAF_Solicitud_Version_Solicitud; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Version"
    ADD CONSTRAINT "FK_CAF_Solicitud_Version_Solicitud" FOREIGN KEY ("ID_Solicitud") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud"("ID_Solicitud");

-- Name: CAF_Solicitud_Zona FK_CAF_Solicitud_Zona_Solicitud; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Zona"
    ADD CONSTRAINT "FK_CAF_Solicitud_Zona_Solicitud" FOREIGN KEY ("ID_Solicitud") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud"("ID_Solicitud");

-- Name: CAF_Solicitud_Zona FK_CAF_Solicitud_Zona_Zona; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Zona"
    ADD CONSTRAINT "FK_CAF_Solicitud_Zona_Zona" FOREIGN KEY ("ID_Catalogo_Zona_Acceso") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Zona_Acceso"("ID_Catalogo_Zona_Acceso");

-- Name: Tipo_Acceso_Item_Checklist FK_Tipo_Acceso_Item_Checklist_Item; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Item_Checklist"
    ADD CONSTRAINT "FK_Tipo_Acceso_Item_Checklist_Item" FOREIGN KEY ("ID_Catalogo_Item_Checklist") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Item_Checklist"("ID_Catalogo_Item_Checklist");

-- Name: Tipo_Acceso_Item_Checklist FK_Tipo_Acceso_Item_Checklist_Tipo; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Item_Checklist"
    ADD CONSTRAINT "FK_Tipo_Acceso_Item_Checklist_Tipo" FOREIGN KEY ("ID_Catalogo_Tipo_Acceso") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Acceso"("ID_Catalogo_Tipo_Acceso");

-- Name: Tipo_Acceso_Paso_Aprobacion FK_Tipo_Acceso_Paso_Tipo; Type: FK CONSTRAINT; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

ALTER TABLE ONLY "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Paso_Aprobacion"
    ADD CONSTRAINT "FK_Tipo_Acceso_Paso_Tipo" FOREIGN KEY ("ID_Catalogo_Tipo_Acceso") REFERENCES "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Acceso"("ID_Catalogo_Tipo_Acceso");

-- PostgreSQL database dump complete

