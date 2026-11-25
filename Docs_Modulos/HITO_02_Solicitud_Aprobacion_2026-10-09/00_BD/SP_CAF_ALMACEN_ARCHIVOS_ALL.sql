-- =============================================================================
-- Archivo : SP_CAF_ALMACEN_ARCHIVOS_ALL.sql   (2026-11-24, D-276)
-- Propósito: migrar a un almacén externo (carpeta de red o Drive) los archivos que hoy están en la base. Solo la usa la consola de operación (usuario sistema 0).
--   ERP_CAF_ARCHIVO_PENDIENTES_MIGRAR(usuario, tabla, maximo)  archivos con Almacen = 'BD' y contenido presente. tabla: 'ADJUNTO' | 'DOC_INGRESO'.
--   ERP_CAF_ARCHIVO_MIGRADO(tabla, id, almacen, ruta, vaciar, usuario)  anota dónde quedó el archivo; vaciar = 'Y' borra el contenido de la base
--        (solo si el archivo ya está en el almacén; si se conserva la copia, la fila queda con el almacén externo y el contenido).
--   ERP_CAF_ARCHIVO_ESTADISTICA(usuario)  por tabla y almacén: cantidad y bytes (con contenido en la base / sin él).
-- Nota HANA: BYTEA → BLOB; LENGTH(BLOB) → LENGTH; plpgsql → SQLScript.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

DROP FUNCTION IF EXISTS "ERP_CAF_ARCHIVO_PENDIENTES_MIGRAR"(BIGINT, VARCHAR, INT);
CREATE OR REPLACE FUNCTION "ERP_CAF_ARCHIVO_PENDIENTES_MIGRAR"("HV_UsuarioID" BIGINT, "HV_Tabla" VARCHAR, "HV_Maximo" INT)
RETURNS TABLE ("ID" BIGINT, "Nombre_Archivo" VARCHAR, "Extension" VARCHAR, "Hash_SHA256" VARCHAR, "Fecha" TIMESTAMP, "Contenido" BYTEA)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-24 (D-276)
    IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <> 0 THEN RETURN; END IF;
    IF "HV_Tabla" = 'ADJUNTO' THEN
        RETURN QUERY SELECT A."ID_Solicitud_Adjunto", CAST(A."Nombre_Archivo" AS VARCHAR), CAST(A."Extension" AS VARCHAR), CAST(A."Hash_SHA256" AS VARCHAR), A."CreateDate", A."Contenido"
                       FROM "CAF_Solicitud_Adjunto" A WHERE A."Almacen" = 'BD' AND A."Contenido" IS NOT NULL ORDER BY A."ID_Solicitud_Adjunto" LIMIT GREATEST(1, LEAST(COALESCE("HV_Maximo", 20), 200));
    ELSIF "HV_Tabla" = 'DOC_INGRESO' THEN
        RETURN QUERY SELECT D."ID_Documento_Ingreso", CAST(D."Nombre_Archivo" AS VARCHAR), CAST(D."Extension" AS VARCHAR), CAST(D."Hash_SHA256" AS VARCHAR), D."CreateDate", D."Contenido"
                       FROM "CAF_Documento_Ingreso" D WHERE D."Almacen" = 'BD' AND D."Contenido" IS NOT NULL ORDER BY D."ID_Documento_Ingreso" LIMIT GREATEST(1, LEAST(COALESCE("HV_Maximo", 20), 200));
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_ARCHIVO_MIGRADO"(
    IN    "HV_Tabla"        VARCHAR(20),
    IN    "HV_ID"           BIGINT,
    IN    "HV_Almacen"      VARCHAR(10),
    IN    "HV_Ruta_Externa" VARCHAR(500),
    IN    "HV_Vaciar"       CHAR(1),
    IN    "HV_UsuarioID"    BIGINT,
    INOUT "HV_Codigo_Resp"  INT DEFAULT NULL,
    INOUT "HV_Mensaje"      VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE lv_n INT := 0;
BEGIN
    -- V1.0 2026-11-24 (D-276)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_ARCHIVO_MIGRADO';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <> 0 THEN "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo el proceso de operación migra archivos.'; RETURN; END IF;
        IF COALESCE("HV_Almacen", '') NOT IN ('RED','DRIVE') OR COALESCE(TRIM("HV_Ruta_Externa"), '') = '' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Almacén o ubicación no válidos.'; RETURN; END IF;
        IF "HV_Tabla" = 'ADJUNTO' THEN
            UPDATE "CAF_Solicitud_Adjunto" SET "Almacen" = "HV_Almacen", "Ruta_Externa" = TRIM("HV_Ruta_Externa"),
                   "Contenido" = CASE WHEN COALESCE("HV_Vaciar", 'N') = 'Y' THEN NULL ELSE "Contenido" END, "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Adjunto" = "HV_ID" AND "Almacen" = 'BD';
            GET DIAGNOSTICS lv_n = ROW_COUNT;
        ELSIF "HV_Tabla" = 'DOC_INGRESO' THEN
            UPDATE "CAF_Documento_Ingreso" SET "Almacen" = "HV_Almacen", "Ruta_Externa" = TRIM("HV_Ruta_Externa"),
                   "Contenido" = CASE WHEN COALESCE("HV_Vaciar", 'N') = 'Y' THEN NULL ELSE "Contenido" END, "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Documento_Ingreso" = "HV_ID" AND "Almacen" = 'BD';
            GET DIAGNOSTICS lv_n = ROW_COUNT;
        ELSE
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Tabla no válida.'; RETURN;
        END IF;
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El archivo no existe o ya fue migrado.'; RETURN; END IF;
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Archivo migrado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_ARCHIVO_MIGRADO';
    END;
END;
$$;

DROP FUNCTION IF EXISTS "ERP_CAF_ARCHIVO_ESTADISTICA"(BIGINT);
CREATE OR REPLACE FUNCTION "ERP_CAF_ARCHIVO_ESTADISTICA"("HV_UsuarioID" BIGINT)
RETURNS TABLE ("Tabla" VARCHAR, "Almacen" VARCHAR, "Cantidad" BIGINT, "Bytes" BIGINT, "Con_Contenido_En_BD" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-24 (D-276)
    IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <> 0 THEN RETURN; END IF;
    RETURN QUERY
    SELECT CAST('ADJUNTO' AS VARCHAR), CAST(A."Almacen" AS VARCHAR), COUNT(*), COALESCE(SUM(A."Tamano_Bytes"), 0)::BIGINT, COUNT(A."Contenido")
      FROM "CAF_Solicitud_Adjunto" A GROUP BY A."Almacen"
    UNION ALL
    SELECT CAST('DOC_INGRESO' AS VARCHAR), CAST(D."Almacen" AS VARCHAR), COUNT(*), COALESCE(SUM(D."Tamano_Bytes"), 0)::BIGINT, COUNT(D."Contenido")
      FROM "CAF_Documento_Ingreso" D GROUP BY D."Almacen";
END;
$$;
