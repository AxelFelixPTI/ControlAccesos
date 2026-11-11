-- =============================================================================
-- Archivo : SP_CAF_ITEM_CHECKLIST_ADMIN_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Versión : V1.1 2026-11-11 (subtipo por asignación: «tipo:subtipo») · V1.0 2026-11-10
-- Qué hace: apoyo de la pantalla de administración «Checklist de portería» (Catálogos).
--   1 ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR  ítems (activos e inactivos, sin eliminados) con los tipos de acceso a los que aplican
--                                           y cuántas veces se usaron (si se usaron no se les cambia la etapa)
--   2 ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS reemplaza de una sola vez los tipos de acceso de un ítem (atómico: o queda todo o nada)
-- Sin cursores ni arreglos: recorre los tipos con MIN(id) y compara con la lista usando POSITION (en HANA: LOCATE).
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR"()
RETURNS TABLE ("ID_Catalogo_Item_Checklist" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Ayuda" VARCHAR, "Etapa" VARCHAR,
               "Condicion" VARCHAR, "Es_Critico" CHAR(1), "Orden" BIGINT, "Activo" CHAR(1), "Tipos_IDs" VARCHAR, "Usos" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.1 2026-11-11 (Tipos_IDs = «tipo» o «tipo:subtipo») · V1.0 2026-11-10
    RETURN QUERY
    SELECT I."ID_Catalogo_Item_Checklist", I."Codigo", I."Descripcion", I."Ayuda", I."Etapa", I."Condicion", I."Es_Critico", I."Orden", I."Activo",
           CAST((SELECT STRING_AGG(CAST(T."ID_Catalogo_Tipo_Acceso" AS VARCHAR) || CASE WHEN T."ID_Tipo_Acceso_Subtipo" IS NULL THEN '' ELSE ':' || CAST(T."ID_Tipo_Acceso_Subtipo" AS VARCHAR) END,
                                    ',' ORDER BY T."ID_Catalogo_Tipo_Acceso")
                   FROM "Tipo_Acceso_Item_Checklist" T
                  WHERE T."ID_Catalogo_Item_Checklist" = I."ID_Catalogo_Item_Checklist" AND T."Eliminado" = 'N') AS VARCHAR),
           CAST((SELECT COUNT(*) FROM "CAF_Registro_Checklist" R WHERE R."ID_Catalogo_Item_Checklist" = I."ID_Catalogo_Item_Checklist") AS BIGINT)
      FROM "Catalogo_Item_Checklist" I
     WHERE I."Eliminado" = 'N'
     ORDER BY I."Etapa", I."Orden", I."ID_Catalogo_Item_Checklist";   -- INGRESO antes que SALIDA
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR"();

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS
--    HV_IDs_Tipo: tipos de acceso separados por coma ('' = ninguno); cada uno es «idTipo» (aplica a todas las personas del tipo)
--    o «idTipo:idSubtipo» (solo a las personas de ese subtipo, ej. '3:7'). Los tipos que no están en la lista se quitan (borrado lógico)
--    y los que están se asignan o reactivan con su subtipo. Un subtipo que no pertenece al tipo -> 400 sin cambiar nada.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(
    IN    "HV_ID_Catalogo_Item_Checklist" BIGINT,
    IN    "HV_IDs_Tipo"                   VARCHAR(500),
    IN    "HV_UsuarioID"                  BIGINT,
    INOUT "HV_Codigo_Resp"                INT DEFAULT NULL,
    INOUT "HV_Mensaje"                    VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_lista  VARCHAR(520);
    lv_tipo   BIGINT;
    lv_quiere CHAR(1);
    lv_sub    BIGINT;
    lv_pos    INT;
    lv_resto  VARCHAR(520);
    lv_fila   BIGINT;
    lv_elim   CHAR(1);
    lv_pase   INT;
BEGIN
    -- V1.1 2026-11-11 (subtipo) · V1.0 2026-11-10
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El ítem no existe.'; RETURN; END IF;

        -- La lista solo admite dígitos, «:» y comas
        lv_lista := ',' || REPLACE(COALESCE(TRIM("HV_IDs_Tipo"), ''), ' ', '') || ',';
        IF COALESCE(TRIM("HV_IDs_Tipo"), '') <> '' AND REPLACE(TRIM("HV_IDs_Tipo"), ' ', '') !~ '^[0-9]+(:[0-9]+)?(,[0-9]+(:[0-9]+)?)*$' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de tipos de ingreso no es válida.'; RETURN;
        END IF;

        -- Pase 1: validar (no cambia nada). Pase 2: aplicar.
        FOR lv_pase IN 1..2 LOOP
            lv_tipo := 0;
            LOOP
                SELECT MIN("ID_Catalogo_Tipo_Acceso") INTO lv_tipo FROM "Catalogo_Tipo_Acceso" WHERE "Eliminado" = 'N' AND "ID_Catalogo_Tipo_Acceso" > lv_tipo;
                EXIT WHEN lv_tipo IS NULL;
                lv_sub := NULL;
                IF POSITION(',' || lv_tipo || ',' IN lv_lista) > 0 THEN
                    lv_quiere := 'Y';
                ELSIF POSITION(',' || lv_tipo || ':' IN lv_lista) > 0 THEN
                    lv_quiere := 'Y';
                    lv_pos   := POSITION(',' || lv_tipo || ':' IN lv_lista);
                    lv_resto := SUBSTRING(lv_lista FROM lv_pos + LENGTH(',' || lv_tipo || ':'));
                    lv_sub   := CAST(SUBSTRING(lv_resto FROM 1 FOR POSITION(',' IN lv_resto) - 1) AS BIGINT);
                    SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Subtipo"
                     WHERE "ID_Tipo_Acceso_Subtipo" = lv_sub AND "ID_Catalogo_Tipo_Acceso" = lv_tipo AND "Eliminado" = 'N';
                    IF lv_n = 0 THEN
                        "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El subtipo elegido no pertenece a ese tipo de ingreso.'; RETURN;
                    END IF;
                ELSE
                    lv_quiere := 'N';
                END IF;
                CONTINUE WHEN lv_pase = 1;

                SELECT MAX("ID_Tipo_Acceso_Item_Checklist"), MAX("Eliminado") INTO lv_fila, lv_elim
                  FROM "Tipo_Acceso_Item_Checklist"
                 WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo AND "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist";
                IF lv_quiere = 'Y' THEN
                    IF lv_fila IS NULL THEN
                        INSERT INTO "Tipo_Acceso_Item_Checklist" ("ID_Catalogo_Tipo_Acceso","ID_Catalogo_Item_Checklist","ID_Tipo_Acceso_Subtipo","UsuarioID_Create")
                        VALUES (lv_tipo, "HV_ID_Catalogo_Item_Checklist", lv_sub, "HV_UsuarioID");
                    ELSE
                        UPDATE "Tipo_Acceso_Item_Checklist" SET "Eliminado" = 'N', "ID_Tipo_Acceso_Subtipo" = lv_sub,
                               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                         WHERE "ID_Tipo_Acceso_Item_Checklist" = lv_fila
                           AND ("Eliminado" = 'Y' OR "ID_Tipo_Acceso_Subtipo" IS DISTINCT FROM lv_sub);
                    END IF;
                ELSIF lv_fila IS NOT NULL AND lv_elim = 'N' THEN
                    UPDATE "Tipo_Acceso_Item_Checklist" SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                     WHERE "ID_Tipo_Acceso_Item_Checklist" = lv_fila;
                END IF;
            END LOOP;
        END LOOP;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipos de ingreso del ítem actualizados.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS';
    END;
END;
$$;
-- Prueba: CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(1, '1,3:7', 0);
