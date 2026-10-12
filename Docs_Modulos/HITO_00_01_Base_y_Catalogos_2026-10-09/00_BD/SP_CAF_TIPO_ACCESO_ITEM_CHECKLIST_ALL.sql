-- =============================================================================
-- Archivo : SP_CAF_TIPO_ACCESO_ITEM_CHECKLIST_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 1 - Catálogos del módulo | Fase 1 - Procedimientos
-- Entidad : Tipo_Acceso_Item_Checklist (pivot N:N)
-- Versión : V1.0 2026-10-11
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO1.sql)
-- Patrón  : SP_GOVERNANCE_USUARIO_LICENCIA_ALL.sql (Hito 0)
-- =============================================================================
-- Orden: 1 LISTAR_POR_PADRE · 2 AGREGAR · 3 QUITAR
-- Qué ítems de checklist se verifican para cada tipo de acceso (D-08). Sin
-- pantalla propia: se administra desde el tipo de acceso (A-02).
-- QUITAR es borrado lógico; AGREGAR reactiva la fila quitada en vez de insertar
-- otra (el UNIQUE de la tabla incluye las filas quitadas).
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE"("HV_ID_Catalogo_Tipo_Acceso" BIGINT)
RETURNS TABLE ("ID_Tipo_Acceso_Item_Checklist" BIGINT, "ID_Catalogo_Tipo_Acceso" BIGINT, "ID_Catalogo_Item_Checklist" BIGINT,
               "Codigo_Item_Checklist" VARCHAR, "Item_Checklist" VARCHAR, "Ayuda" VARCHAR, "Etapa" VARCHAR,
               "Condicion" VARCHAR, "Es_Critico" CHAR(1), "Orden" BIGINT, "Activo" CHAR(1), "CreateDate" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
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
-- Prueba: SELECT * FROM "ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE"(1);

-- -----------------------------------------------------------------------------
-- 2. ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(
    IN    "HV_ID_Catalogo_Tipo_Acceso" BIGINT,
    IN    "HV_ID_Catalogo_Item_Checklist" BIGINT,
    IN    "HV_UsuarioID_Create" BIGINT,
    INOUT "HV_ID_Tipo_Acceso_Item_Checklist_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
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
-- Prueba: CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(1,1,0);

-- -----------------------------------------------------------------------------
-- 3. ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR  (borrado lógico)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR"(
    IN    "HV_ID_Tipo_Acceso_Item_Checklist" BIGINT,
    IN    "HV_UsuarioID_Update" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
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
-- Prueba: CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR"(1,0);
