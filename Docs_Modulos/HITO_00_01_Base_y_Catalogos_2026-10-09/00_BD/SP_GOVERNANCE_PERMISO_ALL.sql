-- =============================================================================
-- Archivo : SP_GOVERNANCE_PERMISO_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : CAF_GOVERNANCE
-- Hito    : 0 - Base | Fase 1 - Procedimientos (ampliación del script 09)
-- Entidad : Catalogo_Permiso (catálogo de SISTEMA) y Licencia_Permiso (pivot)
-- Versión : V1.0 2026-10-16
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_PERMISOS.sql)
-- Requiere: script 09 ejecutado.
-- =============================================================================
-- Catalogo_Permiso NO tiene CREAR, ACTUALIZAR ni ELIMINAR: cada permiso
-- corresponde a una acción del código, así que se carga por script (D-25).
-- Lo que sí se administra desde pantalla es qué permisos tiene cada ROL.
--
-- 1 ERP_CATALOGO_PERMISO_LISTAR          catálogo completo
-- 2 ERP_LICENCIA_PERMISO_LISTAR_POR_PADRE permisos de un rol, con marca de asignado
-- 3 ERP_LICENCIA_PERMISO_ASIGNAR          reemplaza TODOS los permisos de un rol
-- 4 ERP_USUARIO_PERMISO_LISTAR            permisos efectivos de un usuario (menú)
-- 5 ERP_USUARIO_PERMISO_VERIFICAR         "¿puede hacer esto aquí?" (RNF-05)
--
-- REGLA: el servidor pregunta por PERMISO, nunca por el nombre del rol.
-- =============================================================================

SET search_path TO "CAF_GOVERNANCE";

-- -----------------------------------------------------------------------------
-- 1. ERP_CATALOGO_PERMISO_LISTAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_PERMISO_LISTAR"("HV_Incluir_Eliminados" CHAR(1) DEFAULT 'N')
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Tipo_Entidad" VARCHAR,
               "Orden" BIGINT, "Activo" CHAR(1), "Eliminado" CHAR(1), "UsuarioID_Create" BIGINT,
               "Nombre_Usuario" VARCHAR, "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-16
    RETURN QUERY
    SELECT T0."ID_Catalogo_Permiso", T0."Codigo", T0."Descripcion", T0."Modulo",
           T0."Orden", T0."Activo", T0."Eliminado", T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Permiso" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_PERMISO_LISTAR"();

-- -----------------------------------------------------------------------------
-- 2. ERP_LICENCIA_PERMISO_LISTAR_POR_PADRE
--    Devuelve TODOS los permisos activos con Asignado = 'Y'/'N': así la pantalla
--    de roles dibuja las casillas en una sola lectura.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_LICENCIA_PERMISO_LISTAR_POR_PADRE"("HV_ID_Catalogo_Licencia" BIGINT)
RETURNS TABLE ("ID_Catalogo_Permiso" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Modulo" VARCHAR,
               "Orden" BIGINT, "Asignado" CHAR(1))
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-16
    RETURN QUERY
    SELECT T0."ID_Catalogo_Permiso", T0."Codigo", T0."Descripcion", T0."Modulo", T0."Orden",
           CAST(CASE WHEN LP."ID_Licencia_Permiso" IS NULL THEN 'N' ELSE 'Y' END AS CHAR(1))
      FROM "Catalogo_Permiso" T0
      LEFT JOIN "Licencia_Permiso" LP
             ON LP."ID_Catalogo_Permiso" = T0."ID_Catalogo_Permiso"
            AND LP."ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia"
            AND LP."Eliminado" = 'N'
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_LICENCIA_PERMISO_LISTAR_POR_PADRE"(1);

-- -----------------------------------------------------------------------------
-- 3. ERP_LICENCIA_PERMISO_ASIGNAR
--    Recibe los códigos separados por comas y deja el rol EXACTAMENTE con esos
--    permisos: agrega los que faltan, reactiva los que estaban quitados y retira
--    los que ya no vienen. Una sola llamada por "Guardar" de la pantalla.
--    Lista vacía = quitar todos (permitido salvo la regla del administrador).
--    HANA: la separación de una lista en filas se traduce aparte; el contrato
--    (un texto con códigos separados por comas) no cambia.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_LICENCIA_PERMISO_ASIGNAR"(
    IN    "HV_ID_Catalogo_Licencia" BIGINT,
    IN    "HV_Codigos_Permiso"      VARCHAR(2000),
    IN    "HV_UsuarioID"            BIGINT,
    INOUT "HV_Codigo_Resp"          INT DEFAULT NULL,
    INOUT "HV_Mensaje"              VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
DECLARE
    lv_n            INT := 0;
    lv_lista        VARCHAR(2100);
    lv_desconocidos VARCHAR(2000);
    lv_admins       INT := 0;
    lv_tiene_admin  INT := 0;
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_LICENCIA_PERMISO_ASIGNAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Licencia"
         WHERE "ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El rol no existe o ya fue eliminado.'; RETURN;
        END IF;

        -- Lista normalizada: ",COD1,COD2," para comparar con LIKE.
        -- Sin tablas temporales ni UNNEST: se traduce a HANA tal cual.
        lv_lista := ',' || UPPER(REPLACE(REPLACE(REPLACE(COALESCE("HV_Codigos_Permiso", ''), ' ', ''), CHR(9), ''), CHR(10), '')) || ',';

        SELECT STRING_AGG(x, ', ') INTO lv_desconocidos
          FROM (SELECT DISTINCT UPPER(TRIM(c)) AS x
                  FROM REGEXP_SPLIT_TO_TABLE(COALESCE("HV_Codigos_Permiso", ''), ',') AS c
                 WHERE LENGTH(TRIM(c)) > 0) AS pedidos
         WHERE NOT EXISTS (SELECT 1 FROM "Catalogo_Permiso" p
                            WHERE p."Codigo" = pedidos.x AND p."Eliminado" = 'N' AND p."Activo" = 'Y');
        IF lv_desconocidos IS NOT NULL THEN
            "HV_Codigo_Resp" := 400;
            "HV_Mensaje" := 'Permisos no reconocidos: ' || LEFT(lv_desconocidos, 180); RETURN;
        END IF;

        -- Nunca dejar el sistema sin quien administre usuarios (D-29)
        SELECT COUNT(*) INTO lv_tiene_admin FROM "Licencia_Permiso" LP
          JOIN "Catalogo_Permiso" P ON P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso"
         WHERE LP."ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia" AND LP."Eliminado" = 'N'
           AND P."Codigo" = 'PER_CAF_ADMIN_USUARIOS';
        IF lv_tiene_admin > 0 AND lv_lista NOT LIKE '%,PER_CAF_ADMIN_USUARIOS,%' THEN
            SELECT COUNT(DISTINCT UL."ID_Usuario") INTO lv_admins
              FROM "Usuario_Licencia" UL
              JOIN "Usuario" U ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
              JOIN "Licencia_Permiso" LP ON LP."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND LP."Eliminado" = 'N'
              JOIN "Catalogo_Permiso" P ON P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso" AND P."Codigo" = 'PER_CAF_ADMIN_USUARIOS'
             WHERE UL."Eliminado" = 'N' AND UL."ID_Catalogo_Licencia" <> "HV_ID_Catalogo_Licencia";
            IF lv_admins = 0 THEN
                "HV_Codigo_Resp" := 101;
                "HV_Mensaje" := 'Es el único rol que administra usuarios; no se puede quitar ese permiso.'; RETURN;
            END IF;
        END IF;

        -- Retirar los que ya no vienen
        UPDATE "Licencia_Permiso" LP
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
          FROM "Catalogo_Permiso" P
         WHERE P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso"
           AND LP."ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia" AND LP."Eliminado" = 'N'
           AND lv_lista NOT LIKE '%,' || P."Codigo" || ',%';

        -- Reactivar los que estaban quitados
        UPDATE "Licencia_Permiso" LP
           SET "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
          FROM "Catalogo_Permiso" P
         WHERE P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso"
           AND LP."ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia" AND LP."Eliminado" = 'Y'
           AND lv_lista LIKE '%,' || P."Codigo" || ',%';

        -- Agregar los nuevos
        INSERT INTO "Licencia_Permiso" ("ID_Catalogo_Licencia","ID_Catalogo_Permiso","UsuarioID_Create")
        SELECT "HV_ID_Catalogo_Licencia", P."ID_Catalogo_Permiso", "HV_UsuarioID"
          FROM "Catalogo_Permiso" P
         WHERE lv_lista LIKE '%,' || P."Codigo" || ',%'
           AND P."Eliminado" = 'N' AND P."Activo" = 'Y'
           AND NOT EXISTS (SELECT 1 FROM "Licencia_Permiso" LP
                            WHERE LP."ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia"
                              AND LP."ID_Catalogo_Permiso" = P."ID_Catalogo_Permiso");

        SELECT COUNT(*) INTO lv_n FROM "Licencia_Permiso"
         WHERE "ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia" AND "Eliminado" = 'N';
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'El rol quedó con ' || lv_n || ' permisos.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_LICENCIA_PERMISO_ASIGNAR';
    END;
END;
$$;
-- Prueba: CALL "ERP_LICENCIA_PERMISO_ASIGNAR"(1, 'PER_CAF_SOLICITUD_PROPIA', 0);

-- -----------------------------------------------------------------------------
-- 4. ERP_USUARIO_PERMISO_LISTAR
--    Permisos efectivos de un usuario, con las sedes donde los tiene.
--    La aplicación la llama UNA vez al iniciar sesión y arma el menú con esto.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_USUARIO_PERMISO_LISTAR"("HV_ID_Usuario" BIGINT)
RETURNS TABLE ("Codigo_Permiso" VARCHAR, "Descripcion" VARCHAR, "Modulo" VARCHAR, "Sedes" VARCHAR, "Roles" VARCHAR)
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-16
    RETURN QUERY
    SELECT P."Codigo", P."Descripcion", P."Modulo",
           CAST(STRING_AGG(DISTINCT S."Codigo", ', ') AS VARCHAR),
           CAST(STRING_AGG(DISTINCT L."Descripcion", ', ') AS VARCHAR)
      FROM "Usuario_Licencia" UL
      JOIN "Usuario" U            ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
      JOIN "Catalogo_Licencia" L  ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
      JOIN "Catalogo_Sede" S      ON S."ID_Catalogo_Sede" = UL."ID_Catalogo_Sede" AND S."Eliminado" = 'N'
      JOIN "Licencia_Permiso" LP  ON LP."ID_Catalogo_Licencia" = L."ID_Catalogo_Licencia" AND LP."Eliminado" = 'N'
      JOIN "Catalogo_Permiso" P   ON P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso" AND P."Eliminado" = 'N' AND P."Activo" = 'Y'
     WHERE UL."ID_Usuario" = "HV_ID_Usuario" AND UL."Eliminado" = 'N'
     GROUP BY P."Codigo", P."Descripcion", P."Modulo", P."Orden"
     ORDER BY P."Orden", P."Codigo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_USUARIO_PERMISO_LISTAR"(1);

-- -----------------------------------------------------------------------------
-- 5. ERP_USUARIO_PERMISO_VERIFICAR
--    La pregunta que hace el servidor en CADA acción protegida (RNF-05):
--    "¿este usuario puede hacer esto en esta sede?". Reemplaza a preguntar por
--    el nombre del rol. ERP_USUARIO_LICENCIA_VERIFICAR sigue existiendo para
--    saber a qué rol pertenece alguien (lo usan los pasos de aprobación).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_USUARIO_PERMISO_VERIFICAR"(
    "HV_ID_Usuario"       BIGINT,
    "HV_Codigo_Permiso"   VARCHAR,
    "HV_ID_Catalogo_Sede" BIGINT
)
RETURNS TABLE ("Tiene" CHAR(1))
LANGUAGE plpgsql SET search_path TO "CAF_GOVERNANCE" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-16
    RETURN QUERY
    SELECT CAST(CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END AS CHAR(1))
      FROM "Usuario_Licencia" UL
      JOIN "Usuario" U           ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
      JOIN "Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
      JOIN "Licencia_Permiso" LP ON LP."ID_Catalogo_Licencia" = L."ID_Catalogo_Licencia" AND LP."Eliminado" = 'N'
      JOIN "Catalogo_Permiso" P  ON P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso" AND P."Eliminado" = 'N' AND P."Activo" = 'Y'
     WHERE UL."ID_Usuario" = "HV_ID_Usuario"
       AND P."Codigo" = "HV_Codigo_Permiso"
       AND UL."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
       AND UL."Eliminado" = 'N';
END;
$$;
-- Prueba: SELECT * FROM "ERP_USUARIO_PERMISO_VERIFICAR"(1, 'PER_CAF_ADMIN_USUARIOS', 1);
