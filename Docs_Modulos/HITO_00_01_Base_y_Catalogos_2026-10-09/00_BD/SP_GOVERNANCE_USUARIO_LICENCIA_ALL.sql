-- =============================================================================
-- Archivo : SP_GOVERNANCE_USUARIO_LICENCIA_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : CAF_GOVERNANCE
-- Hito    : 0 - Base | Fase 1 - Procedimientos
-- Entidad : Usuario_Licencia (PIVOT usuario-licencia-sede)
-- Versión : V1.0 2026-10-11
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO0.sql)
-- =============================================================================
-- PIVOT: no usa los 5 del CRUD. Se administra desde la pantalla del usuario.
-- 1 LISTAR_POR_PADRE · 2 AGREGAR · 3 QUITAR · 4 VERIFICAR (la usa cada acción)
-- AGREGAR reactiva una asignación quitada antes (el UNIQUE incluye eliminados).
-- QUITAR no deja el sistema sin administrador.
-- =============================================================================

SET search_path TO "CAF_GOVERNANCE";

-- -----------------------------------------------------------------------------
-- 1. ERP_USUARIO_LICENCIA_LISTAR_POR_PADRE  (también carga los permisos al login)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_USUARIO_LICENCIA_LISTAR_POR_PADRE"("HV_ID_Usuario" BIGINT)
RETURNS TABLE ("ID_Usuario_Licencia" BIGINT, "ID_Usuario" BIGINT, "ID_Catalogo_Licencia" BIGINT, "Codigo_Licencia" VARCHAR,
               "Licencia" VARCHAR, "ID_Catalogo_Sede" BIGINT, "Codigo_Sede" VARCHAR, "Sede" VARCHAR, "CreateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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
-- Prueba: SELECT * FROM "ERP_USUARIO_LICENCIA_LISTAR_POR_PADRE"(1);

-- -----------------------------------------------------------------------------
-- 2. ERP_USUARIO_LICENCIA_AGREGAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_USUARIO_LICENCIA_AGREGAR"(
    IN    "HV_ID_Usuario"               BIGINT,
    IN    "HV_ID_Catalogo_Licencia"     BIGINT,
    IN    "HV_ID_Catalogo_Sede"         BIGINT,
    IN    "HV_UsuarioID_Create"         BIGINT,
    INOUT "HV_ID_Usuario_Licencia_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"              INT DEFAULT NULL,
    INOUT "HV_Mensaje"                  VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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
-- Prueba: CALL "ERP_USUARIO_LICENCIA_AGREGAR"(1, 1, 1, 0);

-- -----------------------------------------------------------------------------
-- 3. ERP_USUARIO_LICENCIA_QUITAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_USUARIO_LICENCIA_QUITAR"(
    IN    "HV_ID_Usuario_Licencia" BIGINT,
    IN    "HV_UsuarioID_Update"    BIGINT,
    INOUT "HV_Codigo_Resp"         INT DEFAULT NULL,
    INOUT "HV_Mensaje"             VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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

-- -----------------------------------------------------------------------------
-- 4. ERP_USUARIO_LICENCIA_VERIFICAR  ("¿puede este usuario hacer esto en esta sede?")
--    Devuelve Tiene = 'Y' solo si usuario, licencia y asignación están vigentes.
--    La usa el servidor en CADA acción protegida (RNF-05).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_USUARIO_LICENCIA_VERIFICAR"(
    "HV_ID_Usuario"       BIGINT,
    "HV_Codigo_Licencia"  VARCHAR,
    "HV_ID_Catalogo_Sede" BIGINT
)
RETURNS TABLE ("Tiene" CHAR(1))
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
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
-- Prueba: SELECT * FROM "ERP_USUARIO_LICENCIA_VERIFICAR"(1, 'LIC_CAF_ADMIN', 1);
