-- =============================================================================
-- SP_CAF_DOCUMENTO_INGRESO_ALL.sql   (2026-11-22, D-265)
-- Documentos de ingreso del día que sube Vigilancia (fuera del flujo de registrar entradas y salidas).
--   ERP_CAF_FN_DOC_INGRESO_PUEDE_SUBIR(usuario, sede)       Vigilancia que registra (PER_CAF_PORTERIA_REGISTRAR)
--   ERP_CAF_FN_DOC_INGRESO_PUEDE_VER(usuario, sede)         Vigilancia (registra), Almacén y quien tiene el historial de Almacén; no Coordinación
--   ERP_CAF_DOC_INGRESO_AGREGAR(...)                        sube el archivo y lo vincula a las personas (≥ 1)
--   ERP_CAF_DOC_INGRESO_PERSONAS_ASIGNAR(doc, ids, usuario) deja exactamente esas personas (añade y quita)
--   ERP_CAF_DOC_INGRESO_QUITAR(doc, usuario)                retira el documento y sus vínculos (borrado lógico)
--   ERP_CAF_DOC_INGRESO_LISTAR(usuario, sede, fecha)        documentos del día, sin contenido, con sus personas
--   ERP_CAF_DOC_INGRESO_OBTENER(usuario, doc)               un documento con su contenido
--   ERP_CAF_DOC_INGRESO_PERSONAS_DIA(...)                   personas que ingresaron ese día, con filtro y texto (autocompletar)
--   ERP_CAF_DOC_INGRESO_RESUMEN(usuario, sede, fecha)       contadores del día y parámetros
--   ERP_CAF_DOC_INGRESO_DE_SOLICITUD(usuario, solicitud)    documentos vinculados a personas de una solicitud (bloque del detalle)
-- El documento se guarda en la base (como los adjuntos de la solicitud). El vínculo es con la PERSONA de la solicitud: de ahí salen
-- la solicitud y la empresa. Una persona ingresó el día D si su Fecha_Hora_Ingreso cae en D en la sede del documento.
-- Schema: TRIANONSATELITAL_CAF_PRODD.  HANA (T-60): BYTEA → BLOB; STRING_AGG nativo; ENCODE(SHA256()) → HASH_SHA256 en hexadecimal.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD", "CAF_GOVERNANCE";

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_DOC_INGRESO_PUEDE_SUBIR"("HV_UsuarioID" BIGINT, "HV_ID_Catalogo_Sede" BIGINT)
RETURNS CHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-22 (D-265)
    IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <= 0 THEN RETURN 'N'; END IF;
    RETURN CASE WHEN "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', "HV_ID_Catalogo_Sede") = 'Y' THEN 'Y' ELSE 'N' END;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_DOC_INGRESO_PUEDE_VER"("HV_UsuarioID" BIGINT, "HV_ID_Catalogo_Sede" BIGINT)
RETURNS CHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-22 (D-265): Vigilancia sube; Almacén y quien tiene el historial de Almacén solo consultan. PORTERIA_VER no basta: lo tiene también Coordinación
    IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <= 0 THEN RETURN 'N'; END IF;
    RETURN CASE WHEN "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', "HV_ID_Catalogo_Sede") = 'Y'
                  OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', "HV_ID_Catalogo_Sede") = 'Y'
                  OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_HIST_ALMACEN', "HV_ID_Catalogo_Sede") = 'Y' THEN 'Y' ELSE 'N' END;
END;
$$;

-- Interna: valida y deja el vínculo con las personas indicadas (ids separados por coma). Devuelve NULL si todo bien; si no, el mensaje (409/400 en lv_cod).
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_DOC_INGRESO_PERSONAS_ERROR"("HV_ID_Catalogo_Sede" BIGINT, "HV_Fecha" DATE, "HV_IDs" VARCHAR)
RETURNS VARCHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT; lv_ok INT;
BEGIN
    -- V1.0 2026-11-22 (D-265)
    IF COALESCE("HV_IDs", '') !~ '^[0-9]+(,[0-9]+)*$' THEN RETURN 'Elija al menos una persona.'; END IF;
    SELECT COUNT(DISTINCT X.v::BIGINT) INTO lv_n FROM UNNEST(STRING_TO_ARRAY("HV_IDs", ',')) AS X(v);
    IF lv_n > 100 THEN RETURN 'Un documento admite como máximo 100 personas.'; END IF;
    SELECT COUNT(DISTINCT P."ID_Solicitud_Persona") INTO lv_ok
      FROM "CAF_Solicitud_Persona" P JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud" AND S."Eliminado" = 'N'
     WHERE P."ID_Solicitud_Persona" IN (SELECT X.v::BIGINT FROM UNNEST(STRING_TO_ARRAY("HV_IDs", ',')) AS X(v))
       AND P."Eliminado" = 'N' AND S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
       AND P."Fecha_Hora_Ingreso" IS NOT NULL AND CAST(P."Fecha_Hora_Ingreso" AS DATE) = "HV_Fecha";
    IF lv_ok <> lv_n THEN RETURN 'Alguna persona no ingresó ese día en esta sede.'; END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_DOC_INGRESO_AGREGAR"(
    IN    "HV_ID_Catalogo_Sede" BIGINT,
    IN    "HV_Fecha"            DATE,
    IN    "HV_Tipo"             VARCHAR(20),
    IN    "HV_Nombre_Archivo"   VARCHAR(500),
    IN    "HV_Tipo_Contenido"   VARCHAR(100),
    IN    "HV_Contenido"        BYTEA,
    IN    "HV_Personas"         VARCHAR(2000),
    IN    "HV_UsuarioID"        BIGINT,
    INOUT "HV_ID_Result"        BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"      INT DEFAULT NULL,
    INOUT "HV_Mensaje"          VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_nombre VARCHAR(500); lv_ext VARCHAR(10); lv_hash VARCHAR(64); lv_max INT; lv_err VARCHAR; lv_n INT;
    lv_c INT; lv_m VARCHAR(250); r RECORD;
BEGIN
    -- V1.0 2026-11-22 (D-265)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_DOC_INGRESO_AGREGAR'; "HV_ID_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <= 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        IF "ERP_CAF_FN_DOC_INGRESO_PUEDE_SUBIR"("HV_UsuarioID", "HV_ID_Catalogo_Sede") <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo Vigilancia puede subir documentos de ingreso.'; RETURN;
        END IF;
        IF "HV_Fecha" IS NULL OR "HV_Fecha" > CURRENT_DATE THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Elija un día que no sea futuro.'; RETURN; END IF;
        IF COALESCE("HV_Tipo", '') NOT IN ('EQUIPOS','HERRAMIENTAS','GUIA','OTRO') THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Tipo de documento no válido.'; RETURN; END IF;
        lv_nombre := TRIM(REGEXP_REPLACE(COALESCE("HV_Nombre_Archivo", ''), '^.*[\\/]', ''));
        lv_nombre := REGEXP_REPLACE(lv_nombre, '[[:cntrl:]]', '', 'g');
        IF LENGTH(lv_nombre) = 0 OR LENGTH(lv_nombre) > 200 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El nombre del archivo debe tener entre 1 y 200 caracteres.'; RETURN; END IF;
        lv_ext := LOWER(SUBSTRING(lv_nombre FROM '\.([^.]+)$'));
        IF lv_ext IS NULL OR lv_ext NOT IN ('pdf','jpg','jpeg','png') THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Solo se permiten archivos PDF, JPG y PNG.'; RETURN; END IF;
        IF "HV_Contenido" IS NULL OR LENGTH("HV_Contenido") = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El archivo está vacío.'; RETURN; END IF;
        lv_max := COALESCE(NULLIF("ERP_CAF_PARAMETRO_VALOR"('DOCUMENTO_INGRESO_MAX_MB'), '')::INT, 10);
        IF LENGTH("HV_Contenido") > lv_max::BIGINT * 1048576 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El archivo supera el máximo de ' || lv_max || ' MB.'; RETURN;
        END IF;
        lv_err := "ERP_CAF_FN_DOC_INGRESO_PERSONAS_ERROR"("HV_ID_Catalogo_Sede", "HV_Fecha", "HV_Personas");
        IF lv_err IS NOT NULL THEN "HV_Codigo_Resp" := CASE WHEN lv_err LIKE 'Elija%' OR lv_err LIKE 'Un documento%' THEN 400 ELSE 409 END; "HV_Mensaje" := lv_err; RETURN; END IF;
        lv_hash := ENCODE(SHA256("HV_Contenido"), 'hex');
        SELECT COUNT(*) INTO lv_n FROM "CAF_Documento_Ingreso" D
         WHERE D."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND D."Fecha_Registro" = "HV_Fecha" AND D."Eliminado" = 'N' AND D."Hash_SHA256" = lv_hash;
        IF lv_n > 0 THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Ese documento ya fue subido para ese día.'; RETURN; END IF;

        INSERT INTO "CAF_Documento_Ingreso" ("ID_Catalogo_Sede","Fecha_Registro","Tipo","Nombre_Archivo","Extension","Tipo_Contenido","Tamano_Bytes","Hash_SHA256","Contenido","UsuarioID_Create")
        VALUES ("HV_ID_Catalogo_Sede", "HV_Fecha", "HV_Tipo", lv_nombre, lv_ext,
                CASE lv_ext WHEN 'pdf' THEN 'application/pdf' WHEN 'png' THEN 'image/png' ELSE 'image/jpeg' END,
                LENGTH("HV_Contenido"), lv_hash, "HV_Contenido", "HV_UsuarioID")
        RETURNING "ID_Documento_Ingreso" INTO "HV_ID_Result";
        INSERT INTO "CAF_Documento_Ingreso_Persona" ("ID_Documento_Ingreso","ID_Solicitud_Persona","UsuarioID_Create")
        SELECT DISTINCT "HV_ID_Result", X.v::BIGINT, "HV_UsuarioID" FROM UNNEST(STRING_TO_ARRAY("HV_Personas", ',')) AS X(v);
        -- bitácora: una vez por solicitud tocada (reutiliza ADJUNTO_AGREGAR del historial; el detalle lo distingue)
        FOR r IN SELECT DISTINCT P."ID_Solicitud" AS s FROM "CAF_Solicitud_Persona" P
                  WHERE P."ID_Solicitud_Persona" IN (SELECT X.v::BIGINT FROM UNNEST(STRING_TO_ARRAY("HV_Personas", ',')) AS X(v)) LOOP
            CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', r.s, r.s, 'ADJUNTO_AGREGAR', 'Documento de ingreso (Vigilancia): ' || lv_nombre, "HV_UsuarioID", lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;
        END LOOP;
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Documento subido.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_DOC_INGRESO_AGREGAR';
    END;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_DOC_INGRESO_PERSONAS_ASIGNAR"(
    IN "HV_ID_Documento_Ingreso" BIGINT, IN "HV_Personas" VARCHAR(2000), IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede BIGINT; lv_fecha DATE; lv_err VARCHAR;
BEGIN
    -- V1.0 2026-11-22 (D-265): deja exactamente las personas indicadas (añade las nuevas y quita las que faltan); mínimo 1
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_DOC_INGRESO_PERSONAS_ASIGNAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <= 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        SELECT D."ID_Catalogo_Sede", D."Fecha_Registro" INTO lv_sede, lv_fecha FROM "CAF_Documento_Ingreso" D WHERE D."ID_Documento_Ingreso" = "HV_ID_Documento_Ingreso" AND D."Eliminado" = 'N';
        IF lv_sede IS NULL THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El documento no existe.'; RETURN; END IF;
        IF "ERP_CAF_FN_DOC_INGRESO_PUEDE_SUBIR"("HV_UsuarioID", lv_sede) <> 'Y' THEN "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo Vigilancia puede modificar documentos de ingreso.'; RETURN; END IF;
        lv_err := "ERP_CAF_FN_DOC_INGRESO_PERSONAS_ERROR"(lv_sede, lv_fecha, "HV_Personas");
        IF lv_err IS NOT NULL THEN "HV_Codigo_Resp" := CASE WHEN lv_err LIKE 'Elija%' OR lv_err LIKE 'Un documento%' THEN 400 ELSE 409 END; "HV_Mensaje" := lv_err; RETURN; END IF;
        UPDATE "CAF_Documento_Ingreso_Persona" SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Documento_Ingreso" = "HV_ID_Documento_Ingreso" AND "Eliminado" = 'N'
           AND "ID_Solicitud_Persona" NOT IN (SELECT X.v::BIGINT FROM UNNEST(STRING_TO_ARRAY("HV_Personas", ',')) AS X(v));
        INSERT INTO "CAF_Documento_Ingreso_Persona" ("ID_Documento_Ingreso","ID_Solicitud_Persona","UsuarioID_Create")
        SELECT DISTINCT "HV_ID_Documento_Ingreso", X.v::BIGINT, "HV_UsuarioID" FROM UNNEST(STRING_TO_ARRAY("HV_Personas", ',')) AS X(v)
         WHERE NOT EXISTS (SELECT 1 FROM "CAF_Documento_Ingreso_Persona" L WHERE L."ID_Documento_Ingreso" = "HV_ID_Documento_Ingreso" AND L."ID_Solicitud_Persona" = X.v::BIGINT AND L."Eliminado" = 'N');
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Personas del documento actualizadas.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_DOC_INGRESO_PERSONAS_ASIGNAR';
    END;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_DOC_INGRESO_QUITAR"(
    IN "HV_ID_Documento_Ingreso" BIGINT, IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede BIGINT; lv_nom VARCHAR; lv_c INT; lv_m VARCHAR(250); r RECORD;
BEGIN
    -- V1.0 2026-11-22 (D-265)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_DOC_INGRESO_QUITAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <= 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        SELECT D."ID_Catalogo_Sede", D."Nombre_Archivo" INTO lv_sede, lv_nom FROM "CAF_Documento_Ingreso" D WHERE D."ID_Documento_Ingreso" = "HV_ID_Documento_Ingreso" AND D."Eliminado" = 'N';
        IF lv_sede IS NULL THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El documento no existe.'; RETURN; END IF;
        IF "ERP_CAF_FN_DOC_INGRESO_PUEDE_SUBIR"("HV_UsuarioID", lv_sede) <> 'Y' THEN "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo Vigilancia puede retirar documentos de ingreso.'; RETURN; END IF;
        FOR r IN SELECT DISTINCT P."ID_Solicitud" AS s FROM "CAF_Documento_Ingreso_Persona" L JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = L."ID_Solicitud_Persona"
                  WHERE L."ID_Documento_Ingreso" = "HV_ID_Documento_Ingreso" AND L."Eliminado" = 'N' LOOP
            CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', r.s, r.s, 'ADJUNTO_QUITAR', 'Documento de ingreso (Vigilancia): ' || lv_nom, "HV_UsuarioID", lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;
        END LOOP;
        UPDATE "CAF_Documento_Ingreso_Persona" SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Documento_Ingreso" = "HV_ID_Documento_Ingreso" AND "Eliminado" = 'N';
        UPDATE "CAF_Documento_Ingreso" SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP WHERE "ID_Documento_Ingreso" = "HV_ID_Documento_Ingreso";
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Documento retirado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_DOC_INGRESO_QUITAR';
    END;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_DOC_INGRESO_LISTAR"("HV_UsuarioID" BIGINT, "HV_ID_Catalogo_Sede" BIGINT, "HV_Fecha" DATE)
RETURNS TABLE ("ID_Documento_Ingreso" BIGINT, "Tipo" VARCHAR, "Nombre_Archivo" VARCHAR, "Extension" VARCHAR, "Tamano_Bytes" BIGINT,
               "Fecha_Subida" TIMESTAMP, "Subido_Por" VARCHAR, "Personas" VARCHAR, "Puede_Modificar" CHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-22 (D-265): Personas = «idPersona~Apellidos, Nombres~Documento~SOL-xxxx~Empresa» separadas por «|»
    IF "ERP_CAF_FN_DOC_INGRESO_PUEDE_VER"("HV_UsuarioID", "HV_ID_Catalogo_Sede") <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT D."ID_Documento_Ingreso", CAST(D."Tipo" AS VARCHAR), CAST(D."Nombre_Archivo" AS VARCHAR), CAST(D."Extension" AS VARCHAR), D."Tamano_Bytes", D."CreateDate",
           "ERP_CAF_FN_USUARIO_NOMBRE"(D."UsuarioID_Create"),
           CAST((SELECT STRING_AGG(P."ID_Solicitud_Persona" || '~' || PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" || '~' || PE."Numero_Documento"
                                   || '~' || S."Codigo" || '~' || COALESCE(S."Empresa_Visitante", ''), '|' ORDER BY PE."Apellido_Paterno", PE."Nombres")
                   FROM "CAF_Documento_Ingreso_Persona" L
                   JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = L."ID_Solicitud_Persona"
                   JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
                   JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
                  WHERE L."ID_Documento_Ingreso" = D."ID_Documento_Ingreso" AND L."Eliminado" = 'N') AS VARCHAR),
           CAST("ERP_CAF_FN_DOC_INGRESO_PUEDE_SUBIR"("HV_UsuarioID", D."ID_Catalogo_Sede") AS CHAR)
      FROM "CAF_Documento_Ingreso" D
     WHERE D."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND D."Fecha_Registro" = "HV_Fecha" AND D."Eliminado" = 'N'
     ORDER BY D."CreateDate" DESC, D."ID_Documento_Ingreso" DESC;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_DOC_INGRESO_OBTENER"("HV_UsuarioID" BIGINT, "HV_ID_Documento_Ingreso" BIGINT)
RETURNS TABLE ("ID_Documento_Ingreso" BIGINT, "Nombre_Archivo" VARCHAR, "Extension" VARCHAR, "Tamano_Bytes" BIGINT, "Contenido" BYTEA)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-22 (D-265): sin permiso, no devuelve nada (la descarga responde 404 sin revelar si existe)
    RETURN QUERY
    SELECT D."ID_Documento_Ingreso", CAST(D."Nombre_Archivo" AS VARCHAR), CAST(D."Extension" AS VARCHAR), D."Tamano_Bytes", D."Contenido"
      FROM "CAF_Documento_Ingreso" D
     WHERE D."ID_Documento_Ingreso" = "HV_ID_Documento_Ingreso" AND D."Eliminado" = 'N'
       AND "ERP_CAF_FN_DOC_INGRESO_PUEDE_VER"("HV_UsuarioID", D."ID_Catalogo_Sede") = 'Y';
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_DOC_INGRESO_PERSONAS_DIA"("HV_UsuarioID" BIGINT, "HV_ID_Catalogo_Sede" BIGINT, "HV_Fecha" DATE, "HV_Texto" VARCHAR, "HV_Solo_Con_Equipos" CHAR)
RETURNS TABLE ("ID_Solicitud_Persona" BIGINT, "Nombre" VARCHAR, "Documento" VARCHAR, "Solicitud" VARCHAR, "Empresa" VARCHAR,
               "Trae_Equipos" CHAR, "Trae_Herramientas" CHAR, "Documentos" INT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE lv_t VARCHAR := LOWER(TRIM(COALESCE("HV_Texto", '')));
BEGIN
    -- V1.0 2026-11-22 (D-265): personas que ingresaron ese día; texto = parte del nombre, del documento o del código de solicitud (autocompletar); máx. 50
    IF "ERP_CAF_FN_DOC_INGRESO_PUEDE_VER"("HV_UsuarioID", "HV_ID_Catalogo_Sede") <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT P."ID_Solicitud_Persona",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR), CAST(PE."Numero_Documento" AS VARCHAR),
           CAST(S."Codigo" AS VARCHAR), CAST(S."Empresa_Visitante" AS VARCHAR), CAST(P."Trae_Equipos" AS CHAR), CAST(P."Trae_Herramientas" AS CHAR),
           CAST((SELECT COUNT(*) FROM "CAF_Documento_Ingreso_Persona" L JOIN "CAF_Documento_Ingreso" D ON D."ID_Documento_Ingreso" = L."ID_Documento_Ingreso" AND D."Eliminado" = 'N'
                  WHERE L."ID_Solicitud_Persona" = P."ID_Solicitud_Persona" AND L."Eliminado" = 'N') AS INT)
      FROM "CAF_Solicitud_Persona" P
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud" AND S."Eliminado" = 'N'
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
     WHERE P."Eliminado" = 'N' AND S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
       AND P."Fecha_Hora_Ingreso" IS NOT NULL AND CAST(P."Fecha_Hora_Ingreso" AS DATE) = "HV_Fecha"
       AND ("HV_Solo_Con_Equipos" IS DISTINCT FROM 'Y' OR P."Trae_Equipos" = 'Y' OR P."Trae_Herramientas" = 'Y')
       AND (lv_t = '' OR LOWER(PE."Apellido_Paterno" || ' ' || COALESCE(PE."Apellido_Materno", '') || ' ' || PE."Nombres") LIKE '%' || lv_t || '%'
            OR LOWER(PE."Numero_Documento") LIKE '%' || lv_t || '%' OR LOWER(S."Codigo") LIKE '%' || lv_t || '%')
     ORDER BY PE."Apellido_Paterno", PE."Nombres", P."ID_Solicitud_Persona"
     LIMIT 50;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_DOC_INGRESO_RESUMEN"("HV_UsuarioID" BIGINT, "HV_ID_Catalogo_Sede" BIGINT, "HV_Fecha" DATE)
RETURNS TABLE ("Ingresaron" INT, "Con_Equipos" INT, "Sin_Documento" INT, "Documentos" INT, "Obligatorio" CHAR, "Max_MB" INT, "Puede_Subir" CHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-22 (D-265): Sin_Documento = personas que traen equipos o herramientas y no tienen ningún documento ese día
    IF "ERP_CAF_FN_DOC_INGRESO_PUEDE_VER"("HV_UsuarioID", "HV_ID_Catalogo_Sede") <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT CAST(COUNT(*) AS INT),
           CAST(COUNT(*) FILTER (WHERE P."Trae_Equipos" = 'Y' OR P."Trae_Herramientas" = 'Y') AS INT),
           CAST(COUNT(*) FILTER (WHERE (P."Trae_Equipos" = 'Y' OR P."Trae_Herramientas" = 'Y')
                 AND NOT EXISTS (SELECT 1 FROM "CAF_Documento_Ingreso_Persona" L JOIN "CAF_Documento_Ingreso" D ON D."ID_Documento_Ingreso" = L."ID_Documento_Ingreso" AND D."Eliminado" = 'N'
                                  WHERE L."ID_Solicitud_Persona" = P."ID_Solicitud_Persona" AND L."Eliminado" = 'N')) AS INT),
           CAST((SELECT COUNT(*) FROM "CAF_Documento_Ingreso" D WHERE D."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND D."Fecha_Registro" = "HV_Fecha" AND D."Eliminado" = 'N') AS INT),
           CAST(CASE WHEN COALESCE("ERP_CAF_PARAMETRO_VALOR"('DOCUMENTO_INGRESO_OBLIGATORIO'), 'N') = 'Y' THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(COALESCE(NULLIF("ERP_CAF_PARAMETRO_VALOR"('DOCUMENTO_INGRESO_MAX_MB'), '')::INT, 10) AS INT),
           CAST("ERP_CAF_FN_DOC_INGRESO_PUEDE_SUBIR"("HV_UsuarioID", "HV_ID_Catalogo_Sede") AS CHAR)
      FROM "CAF_Solicitud_Persona" P
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud" AND S."Eliminado" = 'N'
     WHERE P."Eliminado" = 'N' AND S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
       AND P."Fecha_Hora_Ingreso" IS NOT NULL AND CAST(P."Fecha_Hora_Ingreso" AS DATE) = "HV_Fecha";
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_DOC_INGRESO_DE_SOLICITUD"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Documento_Ingreso" BIGINT, "Tipo" VARCHAR, "Nombre_Archivo" VARCHAR, "Extension" VARCHAR, "Tamano_Bytes" BIGINT,
               "Fecha_Registro" DATE, "Subido_Por" VARCHAR, "Personas" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE lv_sede BIGINT;
BEGIN
    -- V1.0 2026-11-22 (D-265): documentos vinculados a personas de ESTA solicitud (Personas = solo las de esta solicitud: «Apellidos, Nombres» separadas por «|»)
    SELECT S."ID_Catalogo_Sede" INTO lv_sede FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
    IF lv_sede IS NULL OR "ERP_CAF_FN_DOC_INGRESO_PUEDE_VER"("HV_UsuarioID", lv_sede) <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT D."ID_Documento_Ingreso", CAST(D."Tipo" AS VARCHAR), CAST(D."Nombre_Archivo" AS VARCHAR), CAST(D."Extension" AS VARCHAR), D."Tamano_Bytes", D."Fecha_Registro",
           "ERP_CAF_FN_USUARIO_NOMBRE"(D."UsuarioID_Create"),
           CAST((SELECT STRING_AGG(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres", '|' ORDER BY PE."Apellido_Paterno", PE."Nombres")
                   FROM "CAF_Documento_Ingreso_Persona" L
                   JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = L."ID_Solicitud_Persona" AND P."ID_Solicitud" = "HV_ID_Solicitud"
                   JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
                  WHERE L."ID_Documento_Ingreso" = D."ID_Documento_Ingreso" AND L."Eliminado" = 'N') AS VARCHAR)
      FROM "CAF_Documento_Ingreso" D
     WHERE D."Eliminado" = 'N'
       AND EXISTS (SELECT 1 FROM "CAF_Documento_Ingreso_Persona" L JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = L."ID_Solicitud_Persona"
                    WHERE L."ID_Documento_Ingreso" = D."ID_Documento_Ingreso" AND L."Eliminado" = 'N' AND P."ID_Solicitud" = "HV_ID_Solicitud")
     ORDER BY D."Fecha_Registro" DESC, D."ID_Documento_Ingreso" DESC;
END;
$$;

-- D-269: consulta de documentos por rango de días y por texto (persona: nombre o documento; solicitud; empresa; nombre del archivo). Máximo 200, el más reciente primero.
-- Sin fechas: últimos 30 días. El rango no puede pasar de 366 días. Misma regla de acceso que el listado del día (Vigilancia y Almacén).
CREATE OR REPLACE FUNCTION "ERP_CAF_DOC_INGRESO_BUSCAR"("HV_UsuarioID" BIGINT, "HV_ID_Catalogo_Sede" BIGINT, "HV_Desde" DATE, "HV_Hasta" DATE, "HV_Texto" VARCHAR)
RETURNS TABLE ("ID_Documento_Ingreso" BIGINT, "Fecha_Registro" DATE, "Tipo" VARCHAR, "Nombre_Archivo" VARCHAR, "Extension" VARCHAR, "Tamano_Bytes" BIGINT,
               "Fecha_Subida" TIMESTAMP, "Subido_Por" VARCHAR, "Personas" VARCHAR, "Puede_Modificar" CHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_h DATE := COALESCE("HV_Hasta", CURRENT_DATE);
    lv_d DATE := COALESCE("HV_Desde", COALESCE("HV_Hasta", CURRENT_DATE) - 30);
    lv_t VARCHAR := NULLIF(TRIM(COALESCE("HV_Texto", '')), '');
BEGIN
    -- V1.0 2026-11-23 (D-269). Personas = «idPersona~Apellidos, Nombres~Documento~SOL-xxxx~Empresa» separadas por «|»
    IF "ERP_CAF_FN_DOC_INGRESO_PUEDE_VER"("HV_UsuarioID", "HV_ID_Catalogo_Sede") <> 'Y' THEN RETURN; END IF;
    IF lv_d > lv_h THEN RETURN; END IF;
    IF lv_h - lv_d > 366 THEN lv_d := lv_h - 366; END IF;
    RETURN QUERY
    SELECT D."ID_Documento_Ingreso", D."Fecha_Registro", CAST(D."Tipo" AS VARCHAR), CAST(D."Nombre_Archivo" AS VARCHAR), CAST(D."Extension" AS VARCHAR), D."Tamano_Bytes", D."CreateDate",
           "ERP_CAF_FN_USUARIO_NOMBRE"(D."UsuarioID_Create"),
           CAST((SELECT STRING_AGG(P."ID_Solicitud_Persona" || '~' || PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" || '~' || PE."Numero_Documento"
                                   || '~' || S."Codigo" || '~' || COALESCE(S."Empresa_Visitante", ''), '|' ORDER BY PE."Apellido_Paterno", PE."Nombres")
                   FROM "CAF_Documento_Ingreso_Persona" L
                   JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = L."ID_Solicitud_Persona"
                   JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
                   JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
                  WHERE L."ID_Documento_Ingreso" = D."ID_Documento_Ingreso" AND L."Eliminado" = 'N') AS VARCHAR),
           CAST("ERP_CAF_FN_DOC_INGRESO_PUEDE_SUBIR"("HV_UsuarioID", D."ID_Catalogo_Sede") AS CHAR)
      FROM "CAF_Documento_Ingreso" D
     WHERE D."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND D."Eliminado" = 'N' AND D."Fecha_Registro" BETWEEN lv_d AND lv_h
       AND (lv_t IS NULL
            OR D."Nombre_Archivo" ILIKE '%' || lv_t || '%'
            OR EXISTS (SELECT 1 FROM "CAF_Documento_Ingreso_Persona" L
                         JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = L."ID_Solicitud_Persona"
                         JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
                         JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
                        WHERE L."ID_Documento_Ingreso" = D."ID_Documento_Ingreso" AND L."Eliminado" = 'N'
                          AND (PE."Apellido_Paterno" || ' ' || COALESCE(PE."Apellido_Materno", '') || ' ' || PE."Nombres" || ' ' || PE."Nombres" || ' ' || PE."Apellido_Paterno" ILIKE '%' || lv_t || '%'
                               OR PE."Numero_Documento" ILIKE '%' || lv_t || '%' OR S."Codigo" ILIKE '%' || lv_t || '%' OR COALESCE(S."Empresa_Visitante", '') ILIKE '%' || lv_t || '%')))
     ORDER BY D."Fecha_Registro" DESC, D."CreateDate" DESC, D."ID_Documento_Ingreso" DESC
     LIMIT 200;
END;
$$;
