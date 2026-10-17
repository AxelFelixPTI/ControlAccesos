-- Docs_BD · TRIANONSATELITAL_CAF_PRODD · TABLAS · export 2026-10-16 22:20
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

-- Name: ERP_CAF_CORREO_ENCOLAR(character varying, bigint, character varying, character varying, character varying, character varying, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_CORREO_ENCOLAR"(IN "HV_Tipo" character varying, IN "HV_ID_Solicitud" bigint, IN "HV_Destinatarios" character varying, IN "HV_Copia" character varying, IN "HV_Asunto" character varying, IN "HV_Cuerpo" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_CORREO_ENCOLAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "HV_Destinatarios" IS NULL OR LENGTH(TRIM("HV_Destinatarios")) = 0 THEN
            "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Sin destinatarios: no se encoló ningún correo.'; RETURN;
        END IF;

        INSERT INTO "CAF_Correo_Pendiente" ("Tipo","ID_Solicitud","Destinatarios","Copia","Asunto","Cuerpo","UsuarioID_Create")
        VALUES ("HV_Tipo", "HV_ID_Solicitud", LEFT("HV_Destinatarios", 2000), NULLIF(LEFT("HV_Copia", 2000), ''),
                LEFT("HV_Asunto", 500), COALESCE("HV_Cuerpo", ''), "HV_UsuarioID");

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Correo encolado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_CORREO_ENCOLAR';
    END;
END;
$$;

-- Name: ERP_CAF_EVENTO_REGISTRAR(character varying, bigint, bigint, character varying, character varying, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_EVENTO_REGISTRAR"(IN "HV_Entidad" character varying, IN "HV_ID_Entidad" bigint, IN "HV_ID_Solicitud" bigint, IN "HV_Accion" character varying, IN "HV_Detalle" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_matriz VARCHAR(2000) := '|SOLICITUD:CREAR|SOLICITUD:EDITAR|SOLICITUD:CANCELAR'
        || '|SOLICITUD_PERSONA:AGREGAR|SOLICITUD_PERSONA:AGREGAR_APROBADA|SOLICITUD_PERSONA:RETIRAR'
        || '|SOLICITUD_PERSONA:CORREGIR|SOLICITUD_PERSONA:REENVIAR|SOLICITUD_PERSONA:NO_SE_PRESENTO'
        || '|SOLICITUD_DECISION:APROBAR|SOLICITUD_DECISION:OBSERVAR|SOLICITUD_DECISION:RECHAZAR'
        || '|REGISTRO_ACCESO:INGRESO|REGISTRO_ACCESO:SALIDA|REGISTRO_ACCESO:DENEGAR'
        || '|DESVIACION:REGISTRAR|DESVIACION:CONFORMIDAD'
        || '|INCIDENCIA:REGISTRAR|INCIDENCIA:CONFIRMAR|INCIDENCIA:DESESTIMAR'
        || '|PERSONA_EXTERNA:CREAR|PERSONA_EXTERNA:CORREGIR_DATOS|';
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_EVENTO_REGISTRAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "HV_ID_Entidad" IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Falta el identificador de la entidad.'; RETURN;
        END IF;
        IF POSITION('|' || UPPER(TRIM(COALESCE("HV_Entidad",''))) || ':' || UPPER(TRIM(COALESCE("HV_Accion",''))) || '|' IN lv_matriz) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La combinación de entidad y acción no está permitida en la bitácora.'; RETURN;
        END IF;

        INSERT INTO "CAF_Evento" ("Entidad","ID_Entidad","ID_Solicitud","Accion","Detalle","ID_Usuario","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Entidad")), "HV_ID_Entidad", "HV_ID_Solicitud", UPPER(TRIM("HV_Accion")),
                LEFT("HV_Detalle", 2000), "HV_UsuarioID", "HV_UsuarioID");

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Evento registrado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_EVENTO_REGISTRAR';
    END;
END;
$$;

-- Name: ERP_CAF_FN_COPIAS_VALIDAS(character varying); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_FN_COPIAS_VALIDAS"("HV_Copias" character varying) RETURNS character
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
DECLARE
    lv_x VARCHAR(2100);
BEGIN
    -- V1.0 2026-10-16
    lv_x := REPLACE(REPLACE(COALESCE("HV_Copias", ''), ' ', ''), ';', ',');
    IF LENGTH(lv_x) = 0 THEN RETURN 'Y'; END IF;
    IF LENGTH(lv_x) > 2000 THEN RETURN 'N'; END IF;
    IF lv_x ~ '^[^@,]+@[^@,.]+(\.[^@,.]+)+(,[^@,]+@[^@,.]+(\.[^@,.]+)+)*$' THEN RETURN 'Y'; END IF;
    RETURN 'N';
END;
$_$;

-- Name: ERP_CAF_FN_USUARIO_TIENE_PERMISO(bigint, character varying, bigint); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_ID_Usuario" bigint, "HV_Codigo_Permiso" character varying, "HV_ID_Catalogo_Sede" bigint) RETURNS character
    LANGUAGE plpgsql STABLE
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-10-16
    SELECT COUNT(*) INTO lv_n
      FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
      JOIN "CAF_GOVERNANCE"."Usuario" U           ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
      JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
      JOIN "CAF_GOVERNANCE"."Licencia_Permiso" LP ON LP."ID_Catalogo_Licencia" = L."ID_Catalogo_Licencia" AND LP."Eliminado" = 'N'
      JOIN "CAF_GOVERNANCE"."Catalogo_Permiso" P  ON P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso" AND P."Eliminado" = 'N' AND P."Activo" = 'Y'
     WHERE UL."ID_Usuario" = "HV_ID_Usuario" AND UL."Eliminado" = 'N'
       AND UL."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND P."Codigo" = "HV_Codigo_Permiso";
    IF lv_n > 0 THEN RETURN 'Y'; END IF;
    RETURN 'N';
END;
$$;

-- Name: ERP_CAF_FN_USUARIO_TIENE_ROL(bigint, bigint, bigint); Type: FUNCTION; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_ID_Usuario" bigint, "HV_ID_Catalogo_Licencia" bigint, "HV_ID_Catalogo_Sede" bigint) RETURNS character
    LANGUAGE plpgsql STABLE
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-10-16
    SELECT COUNT(*) INTO lv_n
      FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
      JOIN "CAF_GOVERNANCE"."Usuario" U           ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
      JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
     WHERE UL."ID_Usuario" = "HV_ID_Usuario" AND UL."Eliminado" = 'N'
       AND UL."ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia"
       AND UL."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede";
    IF lv_n > 0 THEN RETURN 'Y'; END IF;
    RETURN 'N';
END;
$$;

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

-- Name: ERP_CAF_SOLICITUD_CANCELAR(bigint, character varying, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_CANCELAR"(IN "HV_ID_Solicitud" bigint, IN "HV_Motivo_Cancelacion" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n      INT := 0;
    lv_sede   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_aut    INT := 0;
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_dest   VARCHAR(2000);
    lv_port   VARCHAR(2000);
    lv_copia  VARCHAR(2000);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CANCELAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_owner, lv_estado, lv_fecha, lv_codsol
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para cancelarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud ya está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Estado" <> 'ESPERADA';
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Ya ingresó una persona: no se puede cancelar. Retire a quienes faltan.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_aut FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'APROBADA';

        UPDATE "CAF_Solicitud"
           SET "Estado" = 'CANCELADA', "Motivo_Cancelacion" = NULLIF(TRIM("HV_Motivo_Cancelacion"), ''),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'CANCELAR',
             COALESCE(NULLIF(TRIM("HV_Motivo_Cancelacion"), ''), 'Sin motivo indicado'), "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        -- Si ya había personas autorizadas, Vigilancia y los aprobadores deben enterarse
        IF lv_aut > 0 THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'APROBADORES', NULL, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PORTERIA', NULL, lv_port, lv_c, lv_m);
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'COPIAS', NULL, lv_copia, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_CANCELADA', "HV_ID_Solicitud",
                 CASE WHEN lv_dest IS NULL THEN lv_port WHEN lv_port IS NULL THEN lv_dest ELSE lv_dest || '; ' || lv_port END,
                 lv_copia, 'Solicitud ' || lv_codsol || ' cancelada',
                 '<p>La solicitud ' || lv_codsol || ' fue cancelada. ' || COALESCE(NULLIF(TRIM("HV_Motivo_Cancelacion"), ''), '') || '</p>',
                 "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Solicitud cancelada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CANCELAR';
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_COPIAS_GUARDAR(bigint, character varying, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_COPIAS_GUARDAR"(IN "HV_ID_Solicitud" bigint, IN "HV_Copias" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_resto VARCHAR(2100);
    lv_item  VARCHAR(200);
    lv_pos   INT := 0;
    lv_n     INT := 0;
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_COPIAS_GUARDAR';
    BEGIN
        IF "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Copias") <> 'Y' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de correos en copia no es válida.'; RETURN;
        END IF;

        lv_resto := LOWER(REPLACE(REPLACE(COALESCE("HV_Copias", ''), ' ', ''), ';', ','));

        -- Se retiran todas; luego se reactivan o agregan las que vienen
        UPDATE "CAF_Solicitud_Copia_Correo"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';

        WHILE LENGTH(lv_resto) > 0 LOOP
            lv_pos := POSITION(',' IN lv_resto);
            IF lv_pos = 0 THEN
                lv_item  := lv_resto;
                lv_resto := '';
            ELSE
                lv_item  := SUBSTRING(lv_resto FROM 1 FOR lv_pos - 1);
                lv_resto := SUBSTRING(lv_resto FROM lv_pos + 1);
            END IF;

            SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Copia_Correo"
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND LOWER("Correo") = lv_item;
            IF lv_n > 0 THEN
                UPDATE "CAF_Solicitud_Copia_Correo"
                   SET "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND LOWER("Correo") = lv_item;
            ELSE
                INSERT INTO "CAF_Solicitud_Copia_Correo" ("ID_Solicitud","Correo","UsuarioID_Create")
                VALUES ("HV_ID_Solicitud", lv_item, "HV_UsuarioID");
            END IF;
        END LOOP;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Copias de correo guardadas.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_COPIAS_GUARDAR';
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_CREAR(bigint, bigint, bigint, timestamp without time zone, character varying, bigint, character varying, character varying, character varying, character varying, character varying, bigint, bigint, bigint, character varying, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_CREAR"(IN "HV_ID_Catalogo_Sede" bigint, IN "HV_ID_Catalogo_Tipo_Acceso" bigint, IN "HV_ID_Personal_Responsable" bigint, IN "HV_Fecha_Hora_Prevista" timestamp without time zone, IN "HV_Empresa_Visitante" character varying, IN "HV_ID_Catalogo_Motivo_Visita" bigint, IN "HV_Motivo_Detalle" character varying, IN "HV_Observaciones" character varying, IN "HV_IDs_Zona" character varying, IN "HV_IDs_Persona_Externa" character varying, IN "HV_Copias" character varying, IN "HV_ID_Solicitud_Origen" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_ID_Solicitud_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Solicitud_Result" character varying DEFAULT NULL::character varying, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n       INT := 0;
    lv_otro    CHAR(1);
    lv_disp    CHAR(1);
    lv_req     CHAR(1);
    lv_z       VARCHAR(2100);
    lv_p       VARCHAR(2100);
    lv_listaZ  VARCHAR(2100);
    lv_listaP  VARCHAR(2100);
    lv_cntZ    INT := 0;
    lv_cntP    INT := 0;
    lv_sctr    CHAR(1);
    lv_epp     CHAR(1);
    lv_id      BIGINT;
    lv_codsol  VARCHAR(20);
    lv_c       INT;
    lv_m       VARCHAR(250);
    lv_estado  VARCHAR(20);
    lv_dest    VARCHAR(2000);
    lv_copia   VARCHAR(2000);
    lv_detalle VARCHAR(500);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR';
    "HV_ID_Solicitud_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', "HV_ID_Catalogo_Sede") <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para crear solicitudes en esta sede.'; RETURN;
        END IF;

        -- Tipo de acceso: debe estar habilitado y tener pasos de aprobación
        SELECT COUNT(*), MAX("Disponible"), MAX("Requiere_Aprobacion") INTO lv_n, lv_disp, lv_req
          FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de acceso no existe o está inactivo.'; RETURN;
        END IF;
        IF lv_disp <> 'Y' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Ese tipo de acceso todavía no está disponible.'; RETURN;
        END IF;
        IF lv_req = 'Y' THEN
            SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion"
             WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N' AND "Activo" = 'Y' AND "Obligatorio" = 'Y';
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'El tipo de acceso no tiene pasos de aprobación configurados.'; RETURN;
            END IF;
        END IF;

        -- Datos de la visita
        IF "HV_Fecha_Hora_Prevista" IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique la fecha y la hora de la visita.'; RETURN;
        END IF;
        IF CAST("HV_Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La fecha de la visita no puede ser anterior a hoy.'; RETURN;
        END IF;
        IF "HV_Empresa_Visitante" IS NULL OR LENGTH(TRIM("HV_Empresa_Visitante")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La empresa o procedencia es obligatoria.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Personal"
         WHERE "ID_Personal" = "HV_ID_Personal_Responsable" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El responsable de atención no existe o está inactivo.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Es_Otro") INTO lv_n, lv_otro FROM "Catalogo_Motivo_Visita"
         WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El motivo no existe o está inactivo.'; RETURN;
        END IF;
        IF lv_otro = 'Y' AND ("HV_Motivo_Detalle" IS NULL OR LENGTH(TRIM("HV_Motivo_Detalle")) = 0) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Describa el motivo de la visita.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Copias") <> 'Y' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de correos en copia no es válida.'; RETURN;
        END IF;

        -- Zonas: al menos una, todas activas y de esa sede
        lv_z := REPLACE(REPLACE(COALESCE("HV_IDs_Zona", ''), ' ', ''), ';', ',');
        lv_cntZ := CASE WHEN LENGTH(lv_z) = 0 THEN 0 ELSE LENGTH(lv_z) - LENGTH(REPLACE(lv_z, ',', '')) + 1 END;
        lv_listaZ := ',' || lv_z || ',';
        IF lv_cntZ = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Marque al menos una zona.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Zona_Acceso" Z
         WHERE Z."Eliminado" = 'N' AND Z."Activo" = 'Y' AND Z."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
           AND lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        IF lv_n <> lv_cntZ THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Alguna zona no existe, está inactiva, está repetida o es de otra sede.'; RETURN;
        END IF;

        -- Personas: al menos una, todas en el registro de personas externas
        lv_p := REPLACE(REPLACE(COALESCE("HV_IDs_Persona_Externa", ''), ' ', ''), ';', ',');
        lv_cntP := CASE WHEN LENGTH(lv_p) = 0 THEN 0 ELSE LENGTH(lv_p) - LENGTH(REPLACE(lv_p, ',', '')) + 1 END;
        lv_listaP := ',' || lv_p || ',';
        IF lv_cntP = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Agregue al menos una persona.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Persona_Externa" PE
         WHERE PE."Eliminado" = 'N' AND lv_listaP LIKE '%,' || CAST(PE."ID_Persona_Externa" AS VARCHAR) || ',%';
        IF lv_n <> lv_cntP THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Alguna persona no está registrada o está repetida.'; RETURN;
        END IF;

        -- Origen («Reutilizar»): debe ser una solicitud del mismo usuario
        IF "HV_ID_Solicitud_Origen" IS NOT NULL THEN
            SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud"
             WHERE "ID_Solicitud" = "HV_ID_Solicitud_Origen" AND "Eliminado" = 'N' AND "ID_Usuario_Solicitante" = "HV_UsuarioID";
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud de origen no existe o no es suya.'; RETURN;
            END IF;
        END IF;

        -- Qué exigen las zonas elegidas (se copia: un cambio posterior en el catálogo no altera lo ya enviado, D-18)
        SELECT CASE WHEN SUM(CASE WHEN Z."Exige_SCTR" = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END,
               CASE WHEN SUM(CASE WHEN Z."Exige_EPP"  = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END
          INTO lv_sctr, lv_epp
          FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';

        lv_detalle := CASE WHEN lv_otro = 'Y' THEN TRIM("HV_Motivo_Detalle") ELSE NULL END;

        INSERT INTO "CAF_Solicitud" ("ID_Catalogo_Sede","ID_Catalogo_Tipo_Acceso","ID_Usuario_Solicitante","ID_Personal_Responsable",
                                     "Fecha_Hora_Prevista","Empresa_Visitante","ID_Catalogo_Motivo_Visita","Motivo_Detalle","Observaciones",
                                     "Exige_SCTR","Exige_EPP","Estado","Version","Fecha_Envio","ID_Solicitud_Origen","UsuarioID_Create")
        VALUES ("HV_ID_Catalogo_Sede", "HV_ID_Catalogo_Tipo_Acceso", "HV_UsuarioID", "HV_ID_Personal_Responsable",
                "HV_Fecha_Hora_Prevista", TRIM("HV_Empresa_Visitante"), "HV_ID_Catalogo_Motivo_Visita", lv_detalle, NULLIF(TRIM("HV_Observaciones"), ''),
                lv_sctr, lv_epp, 'PENDIENTE', 1, CURRENT_TIMESTAMP, "HV_ID_Solicitud_Origen", "HV_UsuarioID")
        RETURNING "ID_Solicitud" INTO lv_id;

        -- El código visible se deriva del identificador (D-15)
        lv_codsol := 'SOL-' || LPAD(CAST(lv_id AS VARCHAR), 5, '0');
        UPDATE "CAF_Solicitud" SET "Codigo" = lv_codsol WHERE "ID_Solicitud" = lv_id;

        INSERT INTO "CAF_Solicitud_Zona" ("ID_Solicitud","ID_Catalogo_Zona_Acceso","UsuarioID_Create")
        SELECT lv_id, Z."ID_Catalogo_Zona_Acceso", "HV_UsuarioID" FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';

        INSERT INTO "CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","Origen","UsuarioID_Create")
        SELECT lv_id, PE."ID_Persona_Externa", 'PENDIENTE', 'SOLICITUD', "HV_UsuarioID" FROM "CAF_Persona_Externa" PE
         WHERE lv_listaP LIKE '%,' || CAST(PE."ID_Persona_Externa" AS VARCHAR) || ',%';

        CALL "ERP_CAF_SOLICITUD_COPIAS_GUARDAR"(lv_id, "HV_Copias", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'copias: %', lv_m; END IF;

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"(lv_id, "HV_UsuarioID", lv_estado, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', lv_id, lv_id, 'CREAR',
             'Creó y envió la solicitud' || CASE WHEN "HV_ID_Solicitud_Origen" IS NULL THEN '' ELSE ' a partir de la solicitud ' || "HV_ID_Solicitud_Origen" END,
             "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        -- Aviso a quienes deciden el primer paso (si el flujo no requería aprobación ya quedó aprobada)
        IF lv_estado = 'PENDIENTE' THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_id, 'PRIMER_PASO', NULL, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_id, 'COPIAS', NULL, lv_copia, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_NUEVA', lv_id, lv_dest, lv_copia,
                 'Nueva solicitud ' || lv_codsol || ' por aprobar',
                 '<p>La solicitud ' || lv_codsol || ' de ' || TRIM("HV_Empresa_Visitante") || ' (visita el '
                 || TO_CHAR("HV_Fecha_Hora_Prevista", 'DD/MM/YYYY HH24:MI') || ') tiene ' || lv_cntP || ' persona(s) por aprobar.</p>',
                 "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_ID_Solicitud_Result"     := lv_id;
        "HV_Codigo_Solicitud_Result" := lv_codsol;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Solicitud ' || lv_codsol || ' registrada y enviada a aprobación.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR';
        "HV_ID_Solicitud_Result" := 0;
        "HV_Codigo_Solicitud_Result" := NULL;
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_DECIDIR(bigint, bigint, character varying, character varying, character varying, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_DECIDIR"(IN "HV_ID_Solicitud" bigint, IN "HV_ID_Tipo_Acceso_Paso_Aprobacion" bigint, IN "HV_Decision" character varying, IN "HV_Mensaje_Decision" character varying, IN "HV_IDs_Solicitud_Persona" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Cantidad_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n        INT := 0;
    lv_sede     BIGINT;
    lv_tipo     BIGINT;
    lv_estado   VARCHAR(20);
    lv_fecha    TIMESTAMP;
    lv_codsol   VARCHAR(20);
    lv_solic    BIGINT;
    lv_p_tipo   BIGINT;
    lv_alcance  VARCHAR(20);
    lv_orden    BIGINT;
    lv_lic      BIGINT;
    lv_codpaso  VARCHAR(50);
    lv_ids      VARCHAR(4000);
    lv_lista    VARCHAR(4100);
    lv_cnt      INT := 0;
    lv_tokens   INT := 0;
    lv_viol     INT := 0;
    lv_acc      VARCHAR(20);
    lv_c        INT;
    lv_m        VARCHAR(250);
    lv_est2     VARCHAR(20);
    lv_nombres  VARCHAR(2000);
    lv_dest     VARCHAR(2000);
    lv_pend     INT := 0;
    lv_texto    VARCHAR(500);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DECIDIR';
    "HV_Cantidad_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "HV_Decision" IS NULL OR "HV_Decision" NOT IN ('APROBADA','OBSERVADA','RECHAZADA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La decisión debe ser APROBADA, OBSERVADA o RECHAZADA.'; RETURN;
        END IF;
        IF "HV_Decision" <> 'APROBADA' AND ("HV_Mensaje_Decision" IS NULL OR LENGTH(TRIM("HV_Mensaje_Decision")) = 0) THEN
            "HV_Codigo_Resp" := 400;
            "HV_Mensaje" := CASE WHEN "HV_Decision" = 'OBSERVADA' THEN 'Escriba qué debe corregir el solicitante.' ELSE 'Escriba el motivo del rechazo.' END;
            RETURN;
        END IF;

        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo"), MAX("ID_Usuario_Solicitante")
          INTO lv_n, lv_sede, lv_tipo, lv_estado, lv_fecha, lv_codsol, lv_solic
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("ID_Catalogo_Tipo_Acceso"), MAX("Alcance"), MAX("Orden"), MAX("ID_Catalogo_Licencia"), MAX("Codigo")
          INTO lv_n, lv_p_tipo, lv_alcance, lv_orden, lv_lic, lv_codpaso
          FROM "Tipo_Acceso_Paso_Aprobacion"
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 OR lv_p_tipo <> lv_tipo THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El paso no existe, está inactivo o no corresponde al tipo de acceso de esta solicitud.'; RETURN;
        END IF;

        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_APROBAR', lv_sede) <> 'Y'
           OR "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", lv_lic, lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No le corresponde decidir este paso de la solicitud.'; RETURN;
        END IF;

        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;

        -- A quiénes se decide
        IF lv_alcance = 'PERSONA' THEN
            lv_ids := REPLACE(REPLACE(COALESCE("HV_IDs_Solicitud_Persona", ''), ' ', ''), ';', ',');
            lv_tokens := CASE WHEN LENGTH(lv_ids) = 0 THEN 0 ELSE LENGTH(lv_ids) - LENGTH(REPLACE(lv_ids, ',', '')) + 1 END;
            IF lv_tokens = 0 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Elija al menos una persona.'; RETURN;
            END IF;
            lv_lista := ',' || lv_ids || ',';
            SELECT COUNT(*) INTO lv_cnt FROM "CAF_Solicitud_Persona" P
             WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'PENDIENTE' AND P."Estado" = 'ESPERADA'
               AND lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';
            IF lv_cnt <> lv_tokens THEN
                "HV_Codigo_Resp" := 409;
                "HV_Mensaje" := 'Alguna persona no está en la solicitud, está repetida o ya no está pendiente.'; RETURN;
            END IF;
        ELSE
            -- Paso por solicitud: todas las pendientes que aún no tienen decisión en ese paso
            SELECT STRING_AGG(CAST(P."ID_Solicitud_Persona" AS VARCHAR), ',' ORDER BY P."ID_Solicitud_Persona"), COUNT(*)
              INTO lv_ids, lv_cnt
              FROM "CAF_Solicitud_Persona" P
             WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'PENDIENTE' AND P."Estado" = 'ESPERADA'
               AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                                WHERE D."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                                  AND D."ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion"
                                  AND D."Vigente" = 'Y' AND D."Eliminado" = 'N');
            IF lv_cnt = 0 THEN
                "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'No hay personas pendientes en este paso.'; RETURN;
            END IF;
            lv_lista := ',' || lv_ids || ',';
        END IF;

        -- Ninguna debe tener ya decisión en este paso
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona" P
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%'
           AND EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                        WHERE D."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                          AND D."ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion"
                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N');
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Alguna persona ya tiene decisión en este paso.'; RETURN;
        END IF;

        -- Los pasos anteriores deben estar aprobados para cada persona
        SELECT COUNT(*) INTO lv_viol FROM "CAF_Solicitud_Persona" P
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%'
           AND EXISTS (SELECT 1 FROM "Tipo_Acceso_Paso_Aprobacion" L
                        WHERE L."ID_Catalogo_Tipo_Acceso" = lv_tipo AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
                          AND L."Obligatorio" = 'Y' AND L."Orden" < lv_orden
                          AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D2
                                           WHERE D2."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                                             AND D2."ID_Tipo_Acceso_Paso_Aprobacion" = L."ID_Tipo_Acceso_Paso_Aprobacion"
                                             AND D2."Vigente" = 'Y' AND D2."Eliminado" = 'N' AND D2."Decision" = 'APROBADA'));
        IF lv_viol > 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Falta aprobar un paso anterior para alguna de las personas.'; RETURN;
        END IF;

        -- Se registran las decisiones
        INSERT INTO "CAF_Solicitud_Decision"
               ("ID_Solicitud_Persona","ID_Tipo_Acceso_Paso_Aprobacion","Decision","Mensaje","ID_Usuario","Fecha_Decision","UsuarioID_Create")
        SELECT P."ID_Solicitud_Persona", "HV_ID_Tipo_Acceso_Paso_Aprobacion", "HV_Decision",
               CASE WHEN "HV_Decision" = 'APROBADA' THEN NULL ELSE TRIM("HV_Mensaje_Decision") END,
               "HV_UsuarioID", CURRENT_TIMESTAMP, "HV_UsuarioID"
          FROM "CAF_Solicitud_Persona" P
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';

        -- Resumen de la última decisión en la cabecera (D-35)
        UPDATE "CAF_Solicitud"
           SET "ID_Usuario_Decision" = "HV_UsuarioID", "Fecha_Decision" = CURRENT_TIMESTAMP,
               "Observacion_Coordinador" = CASE WHEN "HV_Decision" = 'APROBADA' THEN "Observacion_Coordinador" ELSE TRIM("HV_Mensaje_Decision") END,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_SOLICITUD_VERSION_GUARDAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'version: %', lv_m; END IF;

        -- Bitácora
        lv_acc := CASE "HV_Decision" WHEN 'APROBADA' THEN 'APROBAR' WHEN 'OBSERVADA' THEN 'OBSERVAR' ELSE 'RECHAZAR' END;
        SELECT STRING_AGG(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres", '; ' ORDER BY P."ID_Solicitud_Persona")
          INTO lv_nombres
          FROM "CAF_Solicitud_Persona" P JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_DECISION', "HV_ID_Tipo_Acceso_Paso_Aprobacion", "HV_ID_Solicitud", lv_acc,
             'Paso ' || lv_codpaso || ': ' || LEFT(lv_nombres, 1400)
             || CASE WHEN "HV_Decision" = 'APROBADA' THEN '' ELSE ' · ' || TRIM("HV_Mensaje_Decision") END,
             "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        -- Aviso al solicitante con el resumen de lo decidido
        lv_texto := lv_cnt || CASE WHEN lv_cnt = 1 THEN ' persona ' ELSE ' personas ' END
                    || CASE "HV_Decision" WHEN 'APROBADA' THEN 'aprobada(s)' WHEN 'OBSERVADA' THEN 'observada(s)' ELSE 'rechazada(s)' END;
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'SOLICITANTE', NULL, lv_dest, lv_c, lv_m);
        CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_DECISION', "HV_ID_Solicitud", lv_dest, NULL,
             'Decisión sobre ' || lv_codsol || ': ' || lv_texto,
             '<p>Sobre la solicitud ' || lv_codsol || ': ' || lv_texto || '.</p>'
             || CASE WHEN "HV_Decision" = 'APROBADA' THEN '' ELSE '<p>' || TRIM("HV_Mensaje_Decision") || '</p>' END
             || '<p>Estado de la solicitud: ' || lv_est2 || '.</p>',
             "HV_UsuarioID", lv_c, lv_m);

        -- Si aprobó y todavía faltan pasos, se avisa a quienes deciden el siguiente
        IF "HV_Decision" = 'APROBADA' THEN
            SELECT COUNT(*) INTO lv_pend FROM "CAF_Solicitud_Persona"
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'PENDIENTE';
            IF lv_pend > 0 THEN
                CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'SIGUIENTE_PASO', lv_orden, lv_dest, lv_c, lv_m);
                CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', "HV_ID_Solicitud", lv_dest, NULL,
                     'Personas por aprobar en ' || lv_codsol,
                     '<p>La solicitud ' || lv_codsol || ' tiene ' || lv_pend || ' persona(s) esperando el siguiente paso.</p>',
                     "HV_UsuarioID", lv_c, lv_m);
            END IF;
        END IF;

        "HV_Cantidad_Result" := lv_cnt;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Decisión registrada: ' || lv_texto || '. Estado de la solicitud: ' || lv_est2 || '.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DECIDIR';
        "HV_Cantidad_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_DESTINATARIOS(bigint, character varying, bigint, character varying, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_DESTINATARIOS"(IN "HV_ID_Solicitud" bigint, IN "HV_Modo" character varying, IN "HV_Referencia" bigint, INOUT "HV_Destinatarios" character varying DEFAULT NULL::character varying, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_sede   BIGINT;
    lv_tipo   BIGINT;
    lv_solic  BIGINT;
    lv_orden  BIGINT;
    lv_n      INT := 0;
    lv_dest   VARCHAR(4000);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DESTINATARIOS';
    "HV_Destinatarios" := NULL;
    BEGIN
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("ID_Usuario_Solicitante")
          INTO lv_n, lv_sede, lv_tipo, lv_solic
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;

        IF "HV_Modo" = 'SOLICITANTE' THEN
            SELECT U."Correo" INTO lv_dest FROM "CAF_GOVERNANCE"."Usuario" U
             WHERE U."ID_Usuario" = lv_solic AND U."Eliminado" = 'N' AND U."Activo" = 'Y';

        ELSIF "HV_Modo" = 'COPIAS' THEN
            SELECT STRING_AGG(C."Correo", '; ' ORDER BY C."Correo") INTO lv_dest
              FROM "CAF_Solicitud_Copia_Correo" C
             WHERE C."ID_Solicitud" = "HV_ID_Solicitud" AND C."Eliminado" = 'N';

        ELSIF "HV_Modo" = 'PORTERIA' THEN
            SELECT STRING_AGG(X."Correo", '; ' ORDER BY X."Correo") INTO lv_dest
              FROM (SELECT DISTINCT U."Correo"
                      FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
                      JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
                      JOIN "CAF_GOVERNANCE"."Licencia_Permiso" LP ON LP."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND LP."Eliminado" = 'N'
                      JOIN "CAF_GOVERNANCE"."Catalogo_Permiso" P ON P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso" AND P."Codigo" = 'PER_CAF_PORTERIA_REGISTRAR'
                     WHERE UL."Eliminado" = 'N' AND UL."ID_Catalogo_Sede" = lv_sede) X;

        ELSE
            IF "HV_Modo" = 'PRIMER_PASO' THEN
                SELECT MIN(S."Orden") INTO lv_orden FROM "Tipo_Acceso_Paso_Aprobacion" S
                 WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y';
            ELSIF "HV_Modo" = 'PASO_PENDIENTE' THEN
                SELECT MIN(S."Orden") INTO lv_orden FROM "Tipo_Acceso_Paso_Aprobacion" S
                 WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
                   AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                                    WHERE D."ID_Solicitud_Persona" = "HV_Referencia"
                                      AND D."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                                      AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'APROBADA');
            ELSIF "HV_Modo" = 'SIGUIENTE_PASO' THEN
                SELECT MIN(S."Orden") INTO lv_orden FROM "Tipo_Acceso_Paso_Aprobacion" S
                 WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
                   AND S."Orden" > "HV_Referencia";
            ELSIF "HV_Modo" <> 'APROBADORES' THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Modo de destinatarios no reconocido.'; RETURN;
            END IF;

            IF "HV_Modo" = 'APROBADORES' OR lv_orden IS NOT NULL THEN
                SELECT STRING_AGG(X."Correo", '; ' ORDER BY X."Correo") INTO lv_dest
                  FROM (SELECT DISTINCT U."Correo"
                          FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
                          JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
                          JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
                         WHERE UL."Eliminado" = 'N' AND UL."ID_Catalogo_Sede" = lv_sede
                           AND UL."ID_Catalogo_Licencia" IN (
                                 SELECT S."ID_Catalogo_Licencia" FROM "Tipo_Acceso_Paso_Aprobacion" S
                                  WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y'
                                    AND S."Obligatorio" = 'Y' AND S."ID_Catalogo_Licencia" IS NOT NULL
                                    AND ("HV_Modo" = 'APROBADORES' OR S."Orden" = lv_orden)
                                    -- Para una persona concreta, solo los pasos que AÚN le faltan:
                                    -- el área que ya aprobó su parte no necesita otro aviso
                                    AND ("HV_Modo" <> 'PASO_PENDIENTE'
                                         OR NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                                                         WHERE D."ID_Solicitud_Persona" = "HV_Referencia"
                                                           AND D."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                                                           AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'APROBADA')))) X;
            END IF;
        END IF;

        "HV_Destinatarios" := LEFT(lv_dest, 2000);
        "HV_Codigo_Resp"   := 100;
        "HV_Mensaje"       := 'Destinatarios calculados.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DESTINATARIOS';
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_EDITAR_DATOS(bigint, timestamp without time zone, character varying, bigint, bigint, character varying, character varying, character varying, character varying, bigint, character, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_EDITAR_DATOS"(IN "HV_ID_Solicitud" bigint, IN "HV_Fecha_Hora_Prevista" timestamp without time zone, IN "HV_Empresa_Visitante" character varying, IN "HV_ID_Personal_Responsable" bigint, IN "HV_ID_Catalogo_Motivo_Visita" bigint, IN "HV_Motivo_Detalle" character varying, IN "HV_Observaciones" character varying, IN "HV_IDs_Zona" character varying, IN "HV_Copias" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Reabierta_Result" character DEFAULT NULL::bpchar, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n        INT := 0;
    lv_n2       INT := 0;
    lv_sede     BIGINT;
    lv_tipo     BIGINT;
    lv_owner    BIGINT;
    lv_estado   VARCHAR(20);
    lv_fecha    TIMESTAMP;
    lv_emp      VARCHAR(500);
    lv_mot      BIGINT;
    lv_det_old  VARCHAR(500);
    lv_resp_old BIGINT;
    lv_codsol   VARCHAR(20);
    lv_otro     CHAR(1);
    lv_detalle  VARCHAR(500);
    lv_z        VARCHAR(2100);
    lv_listaZ   VARCHAR(2100);
    lv_cntZ     INT := 0;
    lv_cambia   CHAR(1) := 'N';
    lv_sctr     CHAR(1);
    lv_epp      CHAR(1);
    lv_c        INT;
    lv_m        VARCHAR(250);
    lv_est2     VARCHAR(20);
    lv_dest     VARCHAR(2000);
    lv_copia    VARCHAR(2000);
    lv_desc     VARCHAR(2000) := '';
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_EDITAR_DATOS';
    "HV_Reabierta_Result" := 'N';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("ID_Usuario_Solicitante"), MAX("Estado"),
               MAX("Fecha_Hora_Prevista"), MAX("Empresa_Visitante"), MAX("ID_Catalogo_Motivo_Visita"), MAX("Motivo_Detalle"),
               MAX("ID_Personal_Responsable"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_tipo, lv_owner, lv_estado, lv_fecha, lv_emp, lv_mot, lv_det_old, lv_resp_old, lv_codsol
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para modificarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF lv_estado = 'RECHAZADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Todas las personas fueron rechazadas. Use «Reutilizar» para crear una solicitud nueva.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó. Use «Reutilizar».'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Estado" <> 'ESPERADA';
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'Ya ingresó una persona: los datos de la visita no se cambian. Puede modificar el personal.'; RETURN;
        END IF;

        -- Validación de los valores nuevos (mismas reglas que al crear)
        IF "HV_Fecha_Hora_Prevista" IS NULL OR CAST("HV_Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique una fecha y hora de visita que no sea anterior a hoy.'; RETURN;
        END IF;
        IF "HV_Empresa_Visitante" IS NULL OR LENGTH(TRIM("HV_Empresa_Visitante")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La empresa o procedencia es obligatoria.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Personal"
         WHERE "ID_Personal" = "HV_ID_Personal_Responsable" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El responsable de atención no existe o está inactivo.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Es_Otro") INTO lv_n, lv_otro FROM "Catalogo_Motivo_Visita"
         WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita" AND "Eliminado" = 'N' AND ("Activo" = 'Y' OR "ID_Catalogo_Motivo_Visita" = lv_mot);
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El motivo no existe.'; RETURN;
        END IF;
        IF lv_otro = 'Y' AND ("HV_Motivo_Detalle" IS NULL OR LENGTH(TRIM("HV_Motivo_Detalle")) = 0) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Describa el motivo de la visita.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Copias") <> 'Y' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de correos en copia no es válida.'; RETURN;
        END IF;

        lv_z := REPLACE(REPLACE(COALESCE("HV_IDs_Zona", ''), ' ', ''), ';', ',');
        lv_cntZ := CASE WHEN LENGTH(lv_z) = 0 THEN 0 ELSE LENGTH(lv_z) - LENGTH(REPLACE(lv_z, ',', '')) + 1 END;
        lv_listaZ := ',' || lv_z || ',';
        IF lv_cntZ = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Marque al menos una zona.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Zona_Acceso" Z
         WHERE Z."Eliminado" = 'N' AND Z."ID_Catalogo_Sede" = lv_sede
           AND lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%'
           AND (Z."Activo" = 'Y' OR EXISTS (SELECT 1 FROM "CAF_Solicitud_Zona" W
                                             WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."Eliminado" = 'N'
                                               AND W."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso"));
        IF lv_n <> lv_cntZ THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Alguna zona no existe, está inactiva, está repetida o es de otra sede.'; RETURN;
        END IF;

        -- ¿Cambió algo que obligue a volver a aprobar?
        lv_detalle := CASE WHEN lv_otro = 'Y' THEN TRIM("HV_Motivo_Detalle") ELSE NULL END;
        IF "HV_Fecha_Hora_Prevista" <> lv_fecha THEN
            lv_cambia := 'Y';
            lv_desc := lv_desc || 'Visita ' || TO_CHAR(lv_fecha, 'DD/MM/YYYY HH24:MI') || ' → ' || TO_CHAR("HV_Fecha_Hora_Prevista", 'DD/MM/YYYY HH24:MI') || '. ';
        END IF;
        IF TRIM("HV_Empresa_Visitante") <> lv_emp THEN
            lv_cambia := 'Y'; lv_desc := lv_desc || 'Empresa: ' || lv_emp || ' → ' || TRIM("HV_Empresa_Visitante") || '. ';
        END IF;
        IF "HV_ID_Catalogo_Motivo_Visita" <> lv_mot OR COALESCE(lv_detalle, '') <> COALESCE(lv_det_old, '') THEN
            lv_cambia := 'Y'; lv_desc := lv_desc || 'Motivo modificado. ';
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Zona" W
         WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."Eliminado" = 'N'
           AND lv_listaZ NOT LIKE '%,' || CAST(W."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        SELECT COUNT(*) INTO lv_n2 FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%'
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Zona" W
                            WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."Eliminado" = 'N'
                              AND W."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso");
        IF lv_n > 0 OR lv_n2 > 0 THEN
            lv_cambia := 'Y'; lv_desc := lv_desc || 'Zonas modificadas. ';
        END IF;
        IF "HV_ID_Personal_Responsable" <> lv_resp_old THEN
            lv_desc := lv_desc || 'Responsable de atención cambiado. ';
        END IF;
        IF lv_desc = '' THEN lv_desc := 'Observaciones o copias de correo.'; END IF;

        -- Zonas: retirar las que ya no vienen, reactivar las quitadas, agregar las nuevas
        UPDATE "CAF_Solicitud_Zona"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N'
           AND lv_listaZ NOT LIKE '%,' || CAST("ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        UPDATE "CAF_Solicitud_Zona"
           SET "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'Y'
           AND lv_listaZ LIKE '%,' || CAST("ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        INSERT INTO "CAF_Solicitud_Zona" ("ID_Solicitud","ID_Catalogo_Zona_Acceso","UsuarioID_Create")
        SELECT "HV_ID_Solicitud", Z."ID_Catalogo_Zona_Acceso", "HV_UsuarioID" FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%'
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Zona" W
                            WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso");

        SELECT CASE WHEN SUM(CASE WHEN Z."Exige_SCTR" = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END,
               CASE WHEN SUM(CASE WHEN Z."Exige_EPP"  = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END
          INTO lv_sctr, lv_epp
          FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';

        UPDATE "CAF_Solicitud"
           SET "Fecha_Hora_Prevista" = "HV_Fecha_Hora_Prevista", "Empresa_Visitante" = TRIM("HV_Empresa_Visitante"),
               "ID_Personal_Responsable" = "HV_ID_Personal_Responsable", "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita",
               "Motivo_Detalle" = lv_detalle, "Observaciones" = NULLIF(TRIM("HV_Observaciones"), ''),
               "Exige_SCTR" = lv_sctr, "Exige_EPP" = lv_epp,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";

        CALL "ERP_CAF_SOLICITUD_COPIAS_GUARDAR"("HV_ID_Solicitud", "HV_Copias", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'copias: %', lv_m; END IF;

        -- Reabrir la aprobación si cambió lo que se había autorizado
        IF lv_cambia = 'Y' THEN
            UPDATE "CAF_Solicitud_Persona"
               SET "Origen" = 'REABIERTA', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N'
               AND "Aprobacion" IN ('APROBADA','PENDIENTE') AND "Estado" = 'ESPERADA';

            UPDATE "CAF_Solicitud_Decision" D
               SET "Vigente" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE D."Vigente" = 'Y' AND D."Eliminado" = 'N'
               AND D."ID_Solicitud_Persona" IN (SELECT P."ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" P
                                                 WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Estado" = 'ESPERADA')
               AND (D."ID_Tipo_Acceso_Paso_Aprobacion" IN (SELECT S."ID_Tipo_Acceso_Paso_Aprobacion" FROM "Tipo_Acceso_Paso_Aprobacion" S
                                                            WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Alcance" = 'SOLICITUD')
                    OR D."ID_Solicitud_Persona" IN (SELECT P2."ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" P2
                                                     WHERE P2."ID_Solicitud" = "HV_ID_Solicitud" AND P2."Aprobacion" IN ('APROBADA','PENDIENTE')));

            UPDATE "CAF_Solicitud" SET "Version" = "Version" + 1 WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        END IF;

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'EDITAR', TRIM(lv_desc), "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        IF lv_cambia = 'Y' AND lv_est2 IN ('PENDIENTE','APROBADA_PARCIAL') THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PRIMER_PASO', NULL, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'COPIAS', NULL, lv_copia, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_EDITADA', "HV_ID_Solicitud", lv_dest, lv_copia,
                 'Solicitud ' || lv_codsol || ' modificada: hay personas por aprobar',
                 '<p>Se modificaron los datos de la solicitud ' || lv_codsol || '. ' || TRIM(lv_desc) || '</p>',
                 "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_Reabierta_Result" := lv_cambia;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN lv_cambia = 'Y' THEN 'Solicitud actualizada. Vuelve a aprobación.' ELSE 'Solicitud actualizada.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_EDITAR_DATOS';
        "HV_Reabierta_Result" := 'N';
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_HEREDAR_PASOS(bigint, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_HEREDAR_PASOS"(IN "HV_ID_Solicitud" bigint, IN "HV_ID_Solicitud_Persona" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_HEREDAR_PASOS';
    BEGIN
        INSERT INTO "CAF_Solicitud_Decision"
               ("ID_Solicitud_Persona","ID_Tipo_Acceso_Paso_Aprobacion","Decision","Mensaje","ID_Usuario","Fecha_Decision","UsuarioID_Create")
        SELECT "HV_ID_Solicitud_Persona", S."ID_Tipo_Acceso_Paso_Aprobacion", 'APROBADA', 'Heredada de la solicitud',
               (SELECT D2."ID_Usuario" FROM "CAF_Solicitud_Decision" D2
                  JOIN "CAF_Solicitud_Persona" P2 ON P2."ID_Solicitud_Persona" = D2."ID_Solicitud_Persona"
                 WHERE P2."ID_Solicitud" = "HV_ID_Solicitud" AND P2."Eliminado" = 'N'
                   AND D2."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                   AND D2."Vigente" = 'Y' AND D2."Eliminado" = 'N' AND D2."Decision" = 'APROBADA'
                 ORDER BY D2."Fecha_Decision" DESC, D2."ID_Solicitud_Decision" DESC LIMIT 1),
               CURRENT_TIMESTAMP, "HV_UsuarioID"
          FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = (SELECT "ID_Catalogo_Tipo_Acceso" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud")
           AND S."Alcance" = 'SOLICITUD' AND S."Eliminado" = 'N' AND S."Activo" = 'Y'
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                            WHERE D."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona"
                              AND D."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                              AND D."Vigente" = 'Y' AND D."Eliminado" = 'N')
           AND EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D3
                         JOIN "CAF_Solicitud_Persona" P3 ON P3."ID_Solicitud_Persona" = D3."ID_Solicitud_Persona"
                        WHERE P3."ID_Solicitud" = "HV_ID_Solicitud" AND P3."Eliminado" = 'N'
                          AND D3."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                          AND D3."Vigente" = 'Y' AND D3."Eliminado" = 'N' AND D3."Decision" = 'APROBADA');

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Pasos heredados.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_HEREDAR_PASOS';
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_PERSONA_AGREGAR(bigint, bigint, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(IN "HV_ID_Solicitud" bigint, IN "HV_ID_Persona_Externa" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_ID_Solicitud_Persona_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n      INT := 0;
    lv_sede   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_sp     BIGINT;
    lv_apr    VARCHAR(20);
    lv_apr2   VARCHAR(20);
    lv_nom    VARCHAR(400);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
    lv_dest   VARCHAR(2000);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR';
    "HV_ID_Solicitud_Persona_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_owner, lv_estado, lv_fecha, lv_codsol
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para modificarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres")
          INTO lv_n, lv_nom FROM "CAF_Persona_Externa"
         WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La persona no está registrada.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("ID_Solicitud_Persona"), MAX("Aprobacion") INTO lv_n, lv_sp, lv_apr
          FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';

        IF lv_n > 0 AND lv_apr <> 'RETIRADA' THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := CASE WHEN lv_apr = 'RECHAZADA' THEN 'Esa persona figura en la solicitud como rechazada.'
                                 ELSE 'Esa persona ya está en la solicitud.' END;
            RETURN;
        END IF;

        IF lv_n > 0 THEN
            -- Vuelve a agregarse a quien se había retirado: se reactiva la misma fila
            UPDATE "CAF_Solicitud_Persona"
               SET "Aprobacion" = 'PENDIENTE', "Aprobacion_Mensaje" = NULL, "ID_Usuario_Aprobacion" = NULL, "Fecha_Aprobacion" = NULL,
                   "Origen" = 'AGREGADA', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = lv_sp;
        ELSE
            INSERT INTO "CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","Origen","UsuarioID_Create")
            VALUES ("HV_ID_Solicitud", "HV_ID_Persona_Externa", 'PENDIENTE', 'AGREGADA', "HV_UsuarioID")
            RETURNING "ID_Solicitud_Persona" INTO lv_sp;
        END IF;

        CALL "ERP_CAF_SOLICITUD_HEREDAR_PASOS"("HV_ID_Solicitud", lv_sp, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'heredar: %', lv_m; END IF;
        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', lv_sp, "HV_ID_Solicitud", 'AGREGAR',
             lv_nom || CASE WHEN lv_n > 0 THEN ' (volvió a agregarse)' ELSE '' END, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        SELECT "Aprobacion" INTO lv_apr2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = lv_sp;
        IF lv_apr2 = 'PENDIENTE' THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PASO_PENDIENTE', lv_sp, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', "HV_ID_Solicitud", lv_dest, NULL,
                 'Persona por aprobar en ' || lv_codsol,
                 '<p>Se agregó a ' || lv_nom || ' a la solicitud ' || lv_codsol || ' y espera su decisión.</p>', "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_ID_Solicitud_Persona_Result" := lv_sp;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Persona agregada a la solicitud.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR';
        "HV_ID_Solicitud_Persona_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA(bigint, bigint, bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA"(IN "HV_ID_Solicitud" bigint, IN "HV_ID_Persona_Externa" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_ID_Solicitud_Persona_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n      INT := 0;
    lv_sede   BIGINT;
    lv_tipo   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_sp     BIGINT;
    lv_apr    VARCHAR(20);
    lv_apr2   VARCHAR(20);
    lv_nom    VARCHAR(400);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
    lv_dest   VARCHAR(2000);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA';
    "HV_ID_Solicitud_Persona_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_tipo, lv_owner, lv_estado, lv_fecha, lv_codsol
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_APROBAR', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para aprobar en esta sede.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
           AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", S."ID_Catalogo_Licencia", lv_sede) = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Su rol no decide ningún paso de este tipo de acceso.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres")
          INTO lv_n, lv_nom FROM "CAF_Persona_Externa"
         WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La persona no está registrada.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("ID_Solicitud_Persona"), MAX("Aprobacion") INTO lv_n, lv_sp, lv_apr
          FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';
        IF lv_n > 0 AND lv_apr <> 'RETIRADA' THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := CASE WHEN lv_apr = 'RECHAZADA' THEN 'Esa persona figura en la solicitud como rechazada.'
                                 ELSE 'Esa persona ya está en la solicitud.' END;
            RETURN;
        END IF;

        IF lv_n > 0 THEN
            UPDATE "CAF_Solicitud_Persona"
               SET "Aprobacion" = 'PENDIENTE', "Aprobacion_Mensaje" = NULL, "ID_Usuario_Aprobacion" = NULL, "Fecha_Aprobacion" = NULL,
                   "Origen" = 'AGREGADA_COORDINADOR', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = lv_sp;
        ELSE
            INSERT INTO "CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","Origen","UsuarioID_Create")
            VALUES ("HV_ID_Solicitud", "HV_ID_Persona_Externa", 'PENDIENTE', 'AGREGADA_COORDINADOR', "HV_UsuarioID")
            RETURNING "ID_Solicitud_Persona" INTO lv_sp;
        END IF;

        CALL "ERP_CAF_SOLICITUD_HEREDAR_PASOS"("HV_ID_Solicitud", lv_sp, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'heredar: %', lv_m; END IF;

        -- Aprueba los pasos por persona que le corresponden por rol, sin saltarse el orden
        INSERT INTO "CAF_Solicitud_Decision"
               ("ID_Solicitud_Persona","ID_Tipo_Acceso_Paso_Aprobacion","Decision","Mensaje","ID_Usuario","Fecha_Decision","UsuarioID_Create")
        SELECT lv_sp, S."ID_Tipo_Acceso_Paso_Aprobacion", 'APROBADA', 'Agregada y aprobada por quien decide el paso',
               "HV_UsuarioID", CURRENT_TIMESTAMP, "HV_UsuarioID"
          FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Alcance" = 'PERSONA'
           AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", S."ID_Catalogo_Licencia", lv_sede) = 'Y'
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                            WHERE D."ID_Solicitud_Persona" = lv_sp AND D."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                              AND D."Vigente" = 'Y' AND D."Eliminado" = 'N')
           AND NOT EXISTS (SELECT 1 FROM "Tipo_Acceso_Paso_Aprobacion" L
                            WHERE L."ID_Catalogo_Tipo_Acceso" = lv_tipo AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
                              AND L."Obligatorio" = 'Y' AND L."Orden" < S."Orden"
                              AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D2
                                               WHERE D2."ID_Solicitud_Persona" = lv_sp AND D2."ID_Tipo_Acceso_Paso_Aprobacion" = L."ID_Tipo_Acceso_Paso_Aprobacion"
                                                 AND D2."Vigente" = 'Y' AND D2."Eliminado" = 'N' AND D2."Decision" = 'APROBADA')
                              AND NOT (L."Alcance" = 'PERSONA'
                                       AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", L."ID_Catalogo_Licencia", lv_sede) = 'Y'));

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', lv_sp, "HV_ID_Solicitud", 'AGREGAR_APROBADA', lv_nom, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        -- Se avisa al solicitante; y a los demás aprobadores si todavía faltan pasos
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'SOLICITANTE', NULL, lv_dest, lv_c, lv_m);
        CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_DECISION', "HV_ID_Solicitud", lv_dest, NULL,
             'Se agregó a una persona en ' || lv_codsol,
             '<p>Se agregó a ' || lv_nom || ' a la solicitud ' || lv_codsol || ' porque llegó a portería.</p>', "HV_UsuarioID", lv_c, lv_m);
        SELECT "Aprobacion" INTO lv_apr2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = lv_sp;
        IF lv_apr2 = 'PENDIENTE' THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PASO_PENDIENTE', lv_sp, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', "HV_ID_Solicitud", lv_dest, NULL,
                 'Persona por aprobar en ' || lv_codsol,
                 '<p>' || lv_nom || ' llegó sin estar en la solicitud ' || lv_codsol || ' y espera su decisión.</p>', "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_ID_Solicitud_Persona_Result" := lv_sp;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN lv_apr2 = 'APROBADA' THEN 'Persona agregada y aprobada.'
                                 ELSE 'Persona agregada; faltan pasos de otros aprobadores.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA';
        "HV_ID_Solicitud_Persona_Result" := 0;
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_PERSONA_CORREGIR(bigint, bigint, bigint, character, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(IN "HV_ID_Solicitud_Persona" bigint, IN "HV_ID_Persona_Externa_Nueva" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_Reenviada_Result" character DEFAULT NULL::bpchar, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n      INT := 0;
    lv_sol    BIGINT;
    lv_apr    VARCHAR(20);
    lv_ing    VARCHAR(20);
    lv_ext    BIGINT;
    lv_tipo   BIGINT;
    lv_sede   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_nom    VARCHAR(400);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
    lv_dest   VARCHAR(2000);
    lv_cambia CHAR(1) := 'N';
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_CORREGIR';
    "HV_Reenviada_Result" := 'N';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud (se toma desde la persona): la segunda operación espera y ve lo ya registrado
        SELECT MAX("ID_Solicitud") INTO lv_sol FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = lv_sol;
        SELECT COUNT(*), MAX("ID_Solicitud"), MAX("Aprobacion"), MAX("Estado"), MAX("ID_Persona_Externa")
          INTO lv_n, lv_sol, lv_apr, lv_ing, lv_ext
          FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no está en la solicitud.'; RETURN;
        END IF;
        SELECT MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_sede, lv_tipo, lv_owner, lv_estado, lv_fecha, lv_codsol FROM "CAF_Solicitud" WHERE "ID_Solicitud" = lv_sol;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para modificarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;
        IF lv_apr = 'APROBADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Una persona autorizada no se edita: retírela y agregue otra persona.'; RETURN;
        END IF;
        IF lv_apr = 'RECHAZADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona fue rechazada: está cerrada y no se modifica.'; RETURN;
        END IF;
        IF lv_apr = 'RETIRADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona está retirada. Vuelva a agregarla primero.'; RETURN;
        END IF;
        IF lv_ing <> 'ESPERADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona ya tiene movimientos en portería: no se modifica.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres")
          INTO lv_n, lv_nom FROM "CAF_Persona_Externa"
         WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa_Nueva" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La persona indicada no está registrada.'; RETURN;
        END IF;

        IF "HV_ID_Persona_Externa_Nueva" <> lv_ext THEN
            SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
             WHERE "ID_Solicitud" = lv_sol AND "ID_Persona_Externa" = "HV_ID_Persona_Externa_Nueva" AND "Eliminado" = 'N';
            IF lv_n > 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Esa persona ya figura en la solicitud.'; RETURN;
            END IF;
            lv_cambia := 'Y';
            UPDATE "CAF_Solicitud_Persona"
               SET "ID_Persona_Externa" = "HV_ID_Persona_Externa_Nueva", "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
        END IF;

        IF lv_apr = 'OBSERVADA' OR lv_cambia = 'Y' THEN
            -- Se reabren solo los pasos por persona; los de la solicitud se conservan
            UPDATE "CAF_Solicitud_Decision"
               SET "Vigente" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Vigente" = 'Y' AND "Eliminado" = 'N'
               AND "ID_Tipo_Acceso_Paso_Aprobacion" IN (SELECT S."ID_Tipo_Acceso_Paso_Aprobacion" FROM "Tipo_Acceso_Paso_Aprobacion" S
                                                         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Alcance" = 'PERSONA');
            IF lv_apr = 'OBSERVADA' THEN
                UPDATE "CAF_Solicitud_Persona"
                   SET "Origen" = 'REENVIADA', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
                "HV_Reenviada_Result" := 'Y';
            END IF;

            CALL "ERP_CAF_SOLICITUD_RECALCULAR"(lv_sol, "HV_UsuarioID", lv_est2, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
            CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', "HV_ID_Solicitud_Persona", lv_sol,
                 CASE WHEN lv_apr = 'OBSERVADA' THEN 'REENVIAR' ELSE 'CORREGIR' END, lv_nom, "HV_UsuarioID", lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

            IF lv_apr = 'OBSERVADA' THEN
                CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_sol, 'PASO_PENDIENTE', "HV_ID_Solicitud_Persona", lv_dest, lv_c, lv_m);
                CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', lv_sol, lv_dest, NULL,
                     'Persona corregida en ' || lv_codsol,
                     '<p>' || lv_nom || ' fue corregida y reenviada en la solicitud ' || lv_codsol || '.</p>', "HV_UsuarioID", lv_c, lv_m);
            END IF;
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN lv_apr = 'OBSERVADA' THEN 'Persona corregida y reenviada a aprobación.'
                                 WHEN lv_cambia = 'Y' THEN 'Persona corregida.'
                                 ELSE 'Sin cambios.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_CORREGIR';
        "HV_Reenviada_Result" := 'N';
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_PERSONA_RETIRAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(IN "HV_ID_Solicitud_Persona" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n      INT := 0;
    lv_sol    BIGINT;
    lv_apr    VARCHAR(20);
    lv_ing    VARCHAR(20);
    lv_ext    BIGINT;
    lv_sede   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_nom    VARCHAR(400);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_RETIRAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud (se toma desde la persona): la segunda operación espera y ve lo ya registrado
        SELECT MAX("ID_Solicitud") INTO lv_sol FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = lv_sol;
        SELECT COUNT(*), MAX("ID_Solicitud"), MAX("Aprobacion"), MAX("Estado"), MAX("ID_Persona_Externa")
          INTO lv_n, lv_sol, lv_apr, lv_ing, lv_ext
          FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no está en la solicitud.'; RETURN;
        END IF;
        SELECT MAX("ID_Catalogo_Sede"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista")
          INTO lv_sede, lv_owner, lv_estado, lv_fecha FROM "CAF_Solicitud" WHERE "ID_Solicitud" = lv_sol;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para modificarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;
        IF lv_apr = 'RETIRADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona ya está retirada.'; RETURN;
        END IF;
        IF lv_apr = 'RECHAZADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona fue rechazada: está cerrada y no se modifica.'; RETURN;
        END IF;
        IF lv_ing <> 'ESPERADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona ya tiene movimientos en portería: no se retira.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = lv_sol AND "Eliminado" = 'N' AND "Aprobacion" <> 'RETIRADA'
           AND "ID_Solicitud_Persona" <> "HV_ID_Solicitud_Persona";
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Es la última persona de la solicitud. Cancele la solicitud en su lugar.'; RETURN;
        END IF;

        SELECT "Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres" INTO lv_nom
          FROM "CAF_Persona_Externa" WHERE "ID_Persona_Externa" = lv_ext;

        UPDATE "CAF_Solicitud_Decision"
           SET "Vigente" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Vigente" = 'Y' AND "Eliminado" = 'N';
        UPDATE "CAF_Solicitud_Persona"
           SET "Aprobacion" = 'RETIRADA', "Aprobacion_Mensaje" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"(lv_sol, "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', "HV_ID_Solicitud_Persona", lv_sol, 'RETIRAR', lv_nom, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Persona retirada. No necesitó aprobación.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_RETIRAR';
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_RECALCULAR(bigint, bigint, character varying, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_RECALCULAR"(IN "HV_ID_Solicitud" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_Estado_Result" character varying DEFAULT NULL::character varying, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_existe   INT := 0;
    lv_tipo     BIGINT;
    lv_estado   VARCHAR(20);
    lv_requiere CHAR(1);
    lv_nreq     INT := 0;
    lv_apr      INT := 0;
    lv_pen      INT := 0;
    lv_obs      INT := 0;
    lv_rec      INT := 0;
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_RECALCULAR';
    BEGIN
        SELECT COUNT(*), MAX("ID_Catalogo_Tipo_Acceso"), MAX("Estado") INTO lv_existe, lv_tipo, lv_estado
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;

        SELECT "Requiere_Aprobacion" INTO lv_requiere FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo;
        SELECT COUNT(*) INTO lv_nreq FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y'
           AND S."Obligatorio" = 'Y' AND S."Condicion" = 'SIEMPRE';

        -- 1. Todas las personas vigentes y sin movimientos parten de PENDIENTE
        UPDATE "CAF_Solicitud_Persona"
           SET "Aprobacion" = 'PENDIENTE', "Aprobacion_Mensaje" = NULL, "ID_Usuario_Aprobacion" = NULL, "Fecha_Aprobacion" = NULL
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N'
           AND "Aprobacion" <> 'RETIRADA' AND "Estado" = 'ESPERADA';

        -- 2. APROBADA: todos los pasos obligatorios aprobados (o el flujo no requiere aprobación)
        UPDATE "CAF_Solicitud_Persona" SP
           SET "Aprobacion" = 'APROBADA'
         WHERE SP."ID_Solicitud" = "HV_ID_Solicitud" AND SP."Eliminado" = 'N'
           AND SP."Aprobacion" = 'PENDIENTE' AND SP."Estado" = 'ESPERADA'
           AND (lv_requiere = 'N'
                OR (lv_nreq > 0 AND (SELECT COUNT(DISTINCT S."ID_Tipo_Acceso_Paso_Aprobacion")
                                       FROM "CAF_Solicitud_Decision" D
                                       JOIN "Tipo_Acceso_Paso_Aprobacion" S ON S."ID_Tipo_Acceso_Paso_Aprobacion" = D."ID_Tipo_Acceso_Paso_Aprobacion"
                                      WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona"
                                        AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'APROBADA'
                                        AND S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y'
                                        AND S."Obligatorio" = 'Y' AND S."Condicion" = 'SIEMPRE') >= lv_nreq));

        -- 3. OBSERVADA (pisa a PENDIENTE y APROBADA); el mensaje sale de la decisión más reciente
        UPDATE "CAF_Solicitud_Persona" SP
           SET "Aprobacion" = 'OBSERVADA',
               "Aprobacion_Mensaje" = (SELECT D."Mensaje" FROM "CAF_Solicitud_Decision" D
                                         JOIN "Tipo_Acceso_Paso_Aprobacion" S ON S."ID_Tipo_Acceso_Paso_Aprobacion" = D."ID_Tipo_Acceso_Paso_Aprobacion"
                                        WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona"
                                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'OBSERVADA'
                                          AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
                                        ORDER BY D."Fecha_Decision" DESC, D."ID_Solicitud_Decision" DESC LIMIT 1)
         WHERE SP."ID_Solicitud" = "HV_ID_Solicitud" AND SP."Eliminado" = 'N'
           AND SP."Aprobacion" IN ('PENDIENTE','APROBADA') AND SP."Estado" = 'ESPERADA'
           AND EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                         JOIN "Tipo_Acceso_Paso_Aprobacion" S ON S."ID_Tipo_Acceso_Paso_Aprobacion" = D."ID_Tipo_Acceso_Paso_Aprobacion"
                        WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona"
                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'OBSERVADA'
                          AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y');

        -- 4. RECHAZADA (pisa a todas; es la decisión más fuerte)
        UPDATE "CAF_Solicitud_Persona" SP
           SET "Aprobacion" = 'RECHAZADA',
               "Aprobacion_Mensaje" = (SELECT D."Mensaje" FROM "CAF_Solicitud_Decision" D
                                         JOIN "Tipo_Acceso_Paso_Aprobacion" S ON S."ID_Tipo_Acceso_Paso_Aprobacion" = D."ID_Tipo_Acceso_Paso_Aprobacion"
                                        WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona"
                                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'RECHAZADA'
                                          AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
                                        ORDER BY D."Fecha_Decision" DESC, D."ID_Solicitud_Decision" DESC LIMIT 1)
         WHERE SP."ID_Solicitud" = "HV_ID_Solicitud" AND SP."Eliminado" = 'N'
           AND SP."Aprobacion" IN ('PENDIENTE','APROBADA','OBSERVADA') AND SP."Estado" = 'ESPERADA'
           AND EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                         JOIN "Tipo_Acceso_Paso_Aprobacion" S ON S."ID_Tipo_Acceso_Paso_Aprobacion" = D."ID_Tipo_Acceso_Paso_Aprobacion"
                        WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona"
                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'RECHAZADA'
                          AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y');

        -- 5. Quién y cuándo decidió por última vez, para quien ya tiene una decisión final
        UPDATE "CAF_Solicitud_Persona" SP
           SET "ID_Usuario_Aprobacion" = (SELECT D."ID_Usuario" FROM "CAF_Solicitud_Decision" D
                                           WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona" AND D."Vigente" = 'Y' AND D."Eliminado" = 'N'
                                           ORDER BY D."Fecha_Decision" DESC, D."ID_Solicitud_Decision" DESC LIMIT 1),
               "Fecha_Aprobacion"      = (SELECT D."Fecha_Decision" FROM "CAF_Solicitud_Decision" D
                                           WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona" AND D."Vigente" = 'Y' AND D."Eliminado" = 'N'
                                           ORDER BY D."Fecha_Decision" DESC, D."ID_Solicitud_Decision" DESC LIMIT 1)
         WHERE SP."ID_Solicitud" = "HV_ID_Solicitud" AND SP."Eliminado" = 'N'
           AND SP."Aprobacion" IN ('APROBADA','OBSERVADA','RECHAZADA') AND SP."Estado" = 'ESPERADA';

        -- 6. Estado de la solicitud
        SELECT COALESCE(SUM(CASE WHEN "Aprobacion" = 'APROBADA'  THEN 1 ELSE 0 END), 0),
               COALESCE(SUM(CASE WHEN "Aprobacion" = 'PENDIENTE' THEN 1 ELSE 0 END), 0),
               COALESCE(SUM(CASE WHEN "Aprobacion" = 'OBSERVADA' THEN 1 ELSE 0 END), 0),
               COALESCE(SUM(CASE WHEN "Aprobacion" = 'RECHAZADA' THEN 1 ELSE 0 END), 0)
          INTO lv_apr, lv_pen, lv_obs, lv_rec
          FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" <> 'RETIRADA';

        IF lv_estado <> 'CANCELADA' AND (lv_apr + lv_pen + lv_obs + lv_rec) > 0 THEN
            IF lv_apr > 0 THEN
                IF lv_pen + lv_obs > 0 THEN lv_estado := 'APROBADA_PARCIAL'; ELSE lv_estado := 'APROBADA'; END IF;
            ELSIF lv_pen > 0 THEN lv_estado := 'PENDIENTE';
            ELSIF lv_obs > 0 THEN lv_estado := 'OBSERVADA';
            ELSE lv_estado := 'RECHAZADA';
            END IF;
            UPDATE "CAF_Solicitud"
               SET "Estado" = lv_estado, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Estado" <> lv_estado;
        END IF;

        "HV_Estado_Result" := lv_estado;
        "HV_Codigo_Resp"   := 100;
        "HV_Mensaje"       := 'Aprobación recalculada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_RECALCULAR';
    END;
END;
$$;

-- Name: ERP_CAF_SOLICITUD_VERSION_GUARDAR(bigint, bigint, integer, character varying); Type: PROCEDURE; Schema: TRIANONSATELITAL_CAF_PRODD; Owner: -

CREATE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_VERSION_GUARDAR"(IN "HV_ID_Solicitud" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
    LANGUAGE plpgsql
    SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
    AS $$
DECLARE
    lv_n    INT := 0;
    lv_ver  BIGINT;
    lv_json TEXT;
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_VERSION_GUARDAR';
    BEGIN
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'APROBADA';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Sin personas aprobadas: no se guarda versión.'; RETURN;
        END IF;

        SELECT SO."Version",
               '{"codigo":"' || COALESCE(SO."Codigo",'') || '","version":' || SO."Version"
               || ',"fecha_hora":"' || TO_CHAR(SO."Fecha_Hora_Prevista", 'YYYY-MM-DD HH24:MI')
               || '","empresa":"' || REPLACE(REPLACE(SO."Empresa_Visitante", '\', '\\'), '"', '\"')
               || '","zonas":[' || COALESCE((SELECT STRING_AGG('"' || REPLACE(REPLACE(Z."Descripcion", '\', '\\'), '"', '\"') || '"', ',' ORDER BY Z."ID_Catalogo_Zona_Acceso")
                                               FROM "CAF_Solicitud_Zona" SZ
                                               JOIN "Catalogo_Zona_Acceso" Z ON Z."ID_Catalogo_Zona_Acceso" = SZ."ID_Catalogo_Zona_Acceso"
                                              WHERE SZ."ID_Solicitud" = SO."ID_Solicitud" AND SZ."Eliminado" = 'N'), '')
               || '],"personas":[' || COALESCE((SELECT STRING_AGG('{"documento":"' || PE."Numero_Documento"
                                                               || '","nombre":"' || REPLACE(REPLACE(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno",'') || ', ' || PE."Nombres", '\', '\\'), '"', '\"')
                                                               || '","aprobacion":"' || SP."Aprobacion" || '"}', ',' ORDER BY SP."ID_Solicitud_Persona")
                                                  FROM "CAF_Solicitud_Persona" SP
                                                  JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = SP."ID_Persona_Externa"
                                                 WHERE SP."ID_Solicitud" = SO."ID_Solicitud" AND SP."Eliminado" = 'N' AND SP."Aprobacion" <> 'RETIRADA'), '')
               || ']}'
          INTO lv_ver, lv_json
          FROM "CAF_Solicitud" SO WHERE SO."ID_Solicitud" = "HV_ID_Solicitud";

        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Version" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Version" = lv_ver;
        IF lv_n > 0 THEN
            UPDATE "CAF_Solicitud_Version"
               SET "Contenido_JSON" = lv_json, "ID_Usuario_Aprobador" = "HV_UsuarioID", "Fecha_Aprobacion" = CURRENT_TIMESTAMP,
                   "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Version" = lv_ver;
        ELSE
            INSERT INTO "CAF_Solicitud_Version" ("ID_Solicitud","Version","Contenido_JSON","ID_Usuario_Aprobador","Fecha_Aprobacion","UsuarioID_Create")
            VALUES ("HV_ID_Solicitud", lv_ver, lv_json, "HV_UsuarioID", CURRENT_TIMESTAMP, "HV_UsuarioID");
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Versión ' || lv_ver || ' guardada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_VERSION_GUARDAR';
    END;
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
    CONSTRAINT "CK_CAF_Correo_Pendiente_Tipo" CHECK ((("Tipo")::text = ANY ((ARRAY['SOLICITUD_NUEVA'::character varying, 'SOLICITUD_EDITADA'::character varying, 'SOLICITUD_OBSERVADA'::character varying, 'SOLICITUD_APROBADA'::character varying, 'SOLICITUD_CANCELADA'::character varying, 'USUARIO_DEFINIR_PASSWORD'::character varying, 'SOLICITUD_DECISION'::character varying, 'PERSONA_POR_APROBAR'::character varying])::text[])))
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

