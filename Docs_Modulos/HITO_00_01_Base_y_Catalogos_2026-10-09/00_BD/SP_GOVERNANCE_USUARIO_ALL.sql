-- =============================================================================
-- Archivo : SP_GOVERNANCE_USUARIO_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : CAF_GOVERNANCE
-- Hito    : 0 - Base | Fase 1 - Procedimientos
-- Entidad : Usuario (cuentas personales para entrar al sistema)
-- Versión : V1.0 2026-10-11
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO0.sql)
-- =============================================================================
-- 1 LISTAR · 2 CREAR · 3 DETALLE · 4 ACTUALIZAR · 5 ELIMINAR
-- Especiales (D-26):
--   6 AUTENTICACION_POR_CORREO     } ÚNICOS que devuelven Password_Hash.
--   7 AUTENTICACION_POR_DOCUMENTO  } Solo los usa el login.
--   8 LOGIN_REGISTRAR      intento exitoso o fallido; bloqueo temporal
--   9 PASSWORD_ACTUALIZAR  guarda el hash nuevo (la app hashea; nunca texto plano)
--  10 TOKEN_REGISTRAR      token de un solo uso para definir/restablecer contraseña
--  11 AUTENTICACION_POR_TOKEN  valida el token vigente
-- Reglas de seguridad:
--   * LISTAR y DETALLE NUNCA devuelven Password_Hash ni el token.
--   * Nadie puede desactivar ni eliminar su propia cuenta.
--   * No se puede desactivar/eliminar al último administrador activo (LIC_CAF_ADMIN).
--   * Registrar un login NO toca UsuarioID_Update/UpdateDate (no es una edición).
-- =============================================================================

SET search_path TO "CAF_GOVERNANCE";

-- -----------------------------------------------------------------------------
-- 1. ERP_USUARIO_LISTAR
--    Filtro de texto: nombre o correo (candidatos). Filtro opcional por licencia.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_USUARIO_LISTAR"(
    "HV_Filtro_Texto"       VARCHAR DEFAULT NULL,
    "HV_Codigo_Licencia"    VARCHAR DEFAULT NULL,
    "HV_Incluir_Eliminados" CHAR(1) DEFAULT 'N'
)
RETURNS TABLE ("ID_Usuario" BIGINT, "Correo" VARCHAR, "ID_Catalogo_Tipo_Documento" BIGINT, "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR,
               "Apellido_Paterno" VARCHAR, "Apellido_Materno" VARCHAR, "Nombres" VARCHAR, "Nombre_Completo" VARCHAR,
               "ID_Personal" BIGINT, "Area" VARCHAR, "Empresa_Externa" VARCHAR, "Licencias" VARCHAR,
               "Tiene_Password" CHAR(1), "Password_Requiere_Cambio" CHAR(1), "Bloqueado" CHAR(1), "Ultimo_Acceso" TIMESTAMP,
               "Activo" CHAR(1), "Eliminado" CHAR(1), "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR,
               "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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
-- Prueba: SELECT * FROM "ERP_USUARIO_LISTAR"(NULL, 'LIC_CAF_VIGILANCIA');

-- -----------------------------------------------------------------------------
-- 2. ERP_USUARIO_CREAR  (sin contraseña: se define con el token, D-26)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_USUARIO_CREAR"(
    IN    "HV_Correo"                     VARCHAR(200),
    IN    "HV_ID_Catalogo_Tipo_Documento" BIGINT,
    IN    "HV_Numero_Documento"           VARCHAR(20),
    IN    "HV_Apellido_Paterno"           VARCHAR(100),
    IN    "HV_Apellido_Materno"           VARCHAR(100),
    IN    "HV_Nombres"                    VARCHAR(200),
    IN    "HV_ID_Personal"                BIGINT,
    IN    "HV_Empresa_Externa"            VARCHAR(500),
    IN    "HV_Activo"                     CHAR(1),
    IN    "HV_UsuarioID_Create"           BIGINT,
    INOUT "HV_ID_Usuario_Result"          BIGINT DEFAULT NULL,
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
-- Prueba: CALL "ERP_USUARIO_CREAR"('ana@ejemplo.pe',1,'12345678','Prueba',NULL,'Ana',NULL,'Seguridad S.A.C.','Y',0);

-- -----------------------------------------------------------------------------
-- 3. ERP_USUARIO_DETALLE  (no filtra Eliminado; sin hash ni token)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_USUARIO_DETALLE"("HV_ID_Usuario" BIGINT)
RETURNS TABLE ("ID_Usuario" BIGINT, "Correo" VARCHAR, "ID_Catalogo_Tipo_Documento" BIGINT, "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR,
               "Apellido_Paterno" VARCHAR, "Apellido_Materno" VARCHAR, "Nombres" VARCHAR, "Nombre_Completo" VARCHAR,
               "ID_Personal" BIGINT, "Area" VARCHAR, "Empresa_Externa" VARCHAR, "Licencias" VARCHAR,
               "Tiene_Password" CHAR(1), "Password_Requiere_Cambio" CHAR(1), "Bloqueado" CHAR(1), "Ultimo_Acceso" TIMESTAMP,
               "Activo" CHAR(1), "Eliminado" CHAR(1), "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR,
               "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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
-- Prueba: SELECT * FROM "ERP_USUARIO_DETALLE"(1);

-- -----------------------------------------------------------------------------
-- 4. ERP_USUARIO_ACTUALIZAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_USUARIO_ACTUALIZAR"(
    IN    "HV_ID_Usuario"                 BIGINT,
    IN    "HV_Correo"                     VARCHAR(200),
    IN    "HV_ID_Catalogo_Tipo_Documento" BIGINT,
    IN    "HV_Numero_Documento"           VARCHAR(20),
    IN    "HV_Apellido_Paterno"           VARCHAR(100),
    IN    "HV_Apellido_Materno"           VARCHAR(100),
    IN    "HV_Nombres"                    VARCHAR(200),
    IN    "HV_ID_Personal"                BIGINT,
    IN    "HV_Empresa_Externa"            VARCHAR(500),
    IN    "HV_Activo"                     CHAR(1),
    IN    "HV_UsuarioID"                  BIGINT,
    INOUT "HV_Codigo_Resp"                INT DEFAULT NULL,
    INOUT "HV_Mensaje"                    VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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

-- -----------------------------------------------------------------------------
-- 5. ERP_USUARIO_ELIMINAR  (borrado lógico; también retira sus licencias)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_USUARIO_ELIMINAR"(
    IN    "HV_ID_Usuario"       BIGINT,
    IN    "HV_UsuarioID_Update" BIGINT,
    INOUT "HV_Codigo_Resp"      INT DEFAULT NULL,
    INOUT "HV_Mensaje"          VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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

-- -----------------------------------------------------------------------------
-- 6. ERP_USUARIO_AUTENTICACION_POR_CORREO  (solo login; devuelve el hash)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_USUARIO_AUTENTICACION_POR_CORREO"("HV_Correo" VARCHAR)
RETURNS TABLE ("ID_Usuario" BIGINT, "Correo" VARCHAR, "Nombre_Completo" VARCHAR, "Password_Hash" VARCHAR,
               "Password_Requiere_Cambio" CHAR(1), "Intentos_Fallidos" BIGINT, "Bloqueado_Hasta" TIMESTAMP, "Activo" CHAR(1))
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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

-- -----------------------------------------------------------------------------
-- 7. ERP_USUARIO_AUTENTICACION_POR_DOCUMENTO  (solo login; devuelve el hash)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_USUARIO_AUTENTICACION_POR_DOCUMENTO"("HV_ID_Catalogo_Tipo_Documento" BIGINT, "HV_Numero_Documento" VARCHAR)
RETURNS TABLE ("ID_Usuario" BIGINT, "Correo" VARCHAR, "Nombre_Completo" VARCHAR, "Password_Hash" VARCHAR,
               "Password_Requiere_Cambio" CHAR(1), "Intentos_Fallidos" BIGINT, "Bloqueado_Hasta" TIMESTAMP, "Activo" CHAR(1))
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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

-- -----------------------------------------------------------------------------
-- 8. ERP_USUARIO_LOGIN_REGISTRAR
--    Exitoso: limpia intentos y bloqueo, anota Ultimo_Acceso.
--    Fallido: suma un intento; al llegar a HV_Max_Intentos bloquea
--    HV_Minutos_Bloqueo minutos y reinicia el contador.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_USUARIO_LOGIN_REGISTRAR"(
    IN    "HV_ID_Usuario"        BIGINT,
    IN    "HV_Exitoso"           CHAR(1),
    IN    "HV_Max_Intentos"      BIGINT,
    IN    "HV_Minutos_Bloqueo"   BIGINT,
    INOUT "HV_Intentos_Fallidos" BIGINT DEFAULT NULL,
    INOUT "HV_Bloqueado_Hasta"   TIMESTAMP DEFAULT NULL,
    INOUT "HV_Codigo_Resp"       INT DEFAULT NULL,
    INOUT "HV_Mensaje"           VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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

-- -----------------------------------------------------------------------------
-- 9. ERP_USUARIO_PASSWORD_ACTUALIZAR  (recibe el HASH; consume el token)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_USUARIO_PASSWORD_ACTUALIZAR"(
    IN    "HV_ID_Usuario"    BIGINT,
    IN    "HV_Password_Hash" VARCHAR(500),
    IN    "HV_UsuarioID"     BIGINT,
    INOUT "HV_Codigo_Resp"   INT DEFAULT NULL,
    INOUT "HV_Mensaje"       VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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

-- -----------------------------------------------------------------------------
-- 10. ERP_USUARIO_TOKEN_REGISTRAR  (guarda el HASH del token y su vencimiento)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_USUARIO_TOKEN_REGISTRAR"(
    IN    "HV_ID_Usuario"       BIGINT,
    IN    "HV_Token_Hash"       VARCHAR(500),
    IN    "HV_Minutos_Vigencia" BIGINT,
    IN    "HV_UsuarioID"        BIGINT,
    INOUT "HV_Codigo_Resp"      INT DEFAULT NULL,
    INOUT "HV_Mensaje"          VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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

-- -----------------------------------------------------------------------------
-- 11. ERP_USUARIO_AUTENTICACION_POR_TOKEN  (token vigente de una cuenta activa)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_USUARIO_AUTENTICACION_POR_TOKEN"("HV_Token_Hash" VARCHAR)
RETURNS TABLE ("ID_Usuario" BIGINT, "Correo" VARCHAR, "Nombre_Completo" VARCHAR)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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
