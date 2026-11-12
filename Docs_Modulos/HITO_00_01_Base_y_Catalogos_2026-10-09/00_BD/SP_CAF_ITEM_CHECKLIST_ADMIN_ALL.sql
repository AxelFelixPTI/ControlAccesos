-- =============================================================================
-- Archivo : SP_CAF_ITEM_CHECKLIST_ADMIN_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Versión : V1.2 2026-11-12 (una fila por subtipo, D-234) · V1.1 2026-11-11 · V1.0 2026-11-10
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

-- Auxiliar: deja activa la fila (ítem, tipo, subtipo); la crea si no existe o la reactiva si estaba quitada.
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ITEM_ASIGNAR_FILA"("HV_Item" BIGINT, "HV_Tipo" BIGINT, "HV_Subtipo" BIGINT, "HV_UsuarioID" BIGINT)
RETURNS INT
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_fila BIGINT;
BEGIN
    SELECT MAX("ID_Tipo_Acceso_Item_Checklist") INTO lv_fila FROM "Tipo_Acceso_Item_Checklist"
     WHERE "ID_Catalogo_Tipo_Acceso" = "HV_Tipo" AND "ID_Catalogo_Item_Checklist" = "HV_Item" AND COALESCE("ID_Tipo_Acceso_Subtipo", 0) = COALESCE("HV_Subtipo", 0);
    IF lv_fila IS NULL THEN
        INSERT INTO "Tipo_Acceso_Item_Checklist" ("ID_Catalogo_Tipo_Acceso","ID_Catalogo_Item_Checklist","ID_Tipo_Acceso_Subtipo","UsuarioID_Create")
        VALUES ("HV_Tipo", "HV_Item", "HV_Subtipo", "HV_UsuarioID");
    ELSE
        UPDATE "Tipo_Acceso_Item_Checklist" SET "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Tipo_Acceso_Item_Checklist" = lv_fila AND "Eliminado" = 'Y';
    END IF;
    RETURN 1;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS   (V1.2 2026-11-12, D-234: una fila por subtipo)
--    HV_IDs_Tipo: lista separada por coma ('' = ninguno) con elementos «idTipo» o «idTipo:idSubtipo». Un tipo puede repetirse con varios
--    subtipos ('3:7,3:8'). REGLA: si el tipo tiene subtipos activos el ítem se define por subtipo; un «idTipo» solo (sin subtipo) se toma
--    como «todos los subtipos activos» de ese tipo. Un tipo sin subtipos se asigna con «idTipo». Lo que no está en la lista se quita
--    (borrado lógico). Un tipo o subtipo inválido -> 400 sin cambiar nada (atómico).
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
    lv_resto  VARCHAR(520);
    lv_item   VARCHAR(40);
    lv_tipo   BIGINT;
    lv_sub    BIGINT;
    lv_x      BIGINT;
    lv_pase   INT;
    lv_p      INT;
BEGIN
    -- V1.2 2026-11-12 (varios subtipos por tipo) · V1.1 2026-11-11 (subtipo) · V1.0 2026-11-10
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El ítem no existe.'; RETURN; END IF;

        IF COALESCE(TRIM("HV_IDs_Tipo"), '') <> '' AND REPLACE(TRIM("HV_IDs_Tipo"), ' ', '') !~ '^[0-9]+(:[0-9]+)?(,[0-9]+(:[0-9]+)?)*$' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de tipos de ingreso no es válida.'; RETURN;
        END IF;

        -- Pase 1: validar (no cambia nada). Pase 2: quitar todo lo del ítem y reasignar lo pedido (todo en una transacción).
        FOR lv_pase IN 1..2 LOOP
            IF lv_pase = 2 THEN
                UPDATE "Tipo_Acceso_Item_Checklist" SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist" AND "Eliminado" = 'N'
                   AND ("ID_Tipo_Acceso_Subtipo" IS NULL OR NOT (',' || REPLACE(TRIM(COALESCE("HV_IDs_Tipo", '')), ' ', '') || ',' LIKE
                        '%,' || "ID_Catalogo_Tipo_Acceso" || ':' || "ID_Tipo_Acceso_Subtipo" || ',%'));
                -- (lo que quedó activo es exactamente lo pedido con subtipo; el resto se reasigna abajo)
            END IF;
            lv_resto := REPLACE(TRIM(COALESCE("HV_IDs_Tipo", '')), ' ', '');
            WHILE lv_resto <> '' LOOP
                lv_p := POSITION(',' IN lv_resto);
                IF lv_p = 0 THEN lv_item := lv_resto; lv_resto := ''; ELSE lv_item := SUBSTRING(lv_resto FROM 1 FOR lv_p - 1); lv_resto := SUBSTRING(lv_resto FROM lv_p + 1); END IF;
                IF POSITION(':' IN lv_item) > 0 THEN
                    lv_tipo := CAST(SUBSTRING(lv_item FROM 1 FOR POSITION(':' IN lv_item) - 1) AS BIGINT);
                    lv_sub  := CAST(SUBSTRING(lv_item FROM POSITION(':' IN lv_item) + 1) AS BIGINT);
                ELSE
                    lv_tipo := CAST(lv_item AS BIGINT); lv_sub := NULL;
                END IF;
                SELECT COUNT(*) INTO lv_n FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo AND "Eliminado" = 'N';
                CONTINUE WHEN lv_n = 0;   -- un tipo que no existe se ignora (igual que antes)
                IF lv_sub IS NOT NULL THEN
                    SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Subtipo" WHERE "ID_Tipo_Acceso_Subtipo" = lv_sub AND "ID_Catalogo_Tipo_Acceso" = lv_tipo AND "Eliminado" = 'N';
                    IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El subtipo elegido no pertenece a ese tipo de ingreso.'; RETURN; END IF;
                END IF;
                CONTINUE WHEN lv_pase = 1;

                IF lv_sub IS NOT NULL THEN
                    PERFORM "ERP_CAF_FN_ITEM_ASIGNAR_FILA"("HV_ID_Catalogo_Item_Checklist", lv_tipo, lv_sub, "HV_UsuarioID");
                ELSE
                    SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Subtipo" WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo AND "Eliminado" = 'N' AND "Activo" = 'Y';
                    IF lv_n = 0 THEN
                        PERFORM "ERP_CAF_FN_ITEM_ASIGNAR_FILA"("HV_ID_Catalogo_Item_Checklist", lv_tipo, NULL, "HV_UsuarioID");
                    ELSE
                        lv_x := 0;
                        LOOP
                            SELECT MIN("ID_Tipo_Acceso_Subtipo") INTO lv_x FROM "Tipo_Acceso_Subtipo"
                             WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo AND "Eliminado" = 'N' AND "Activo" = 'Y' AND "ID_Tipo_Acceso_Subtipo" > lv_x;
                            EXIT WHEN lv_x IS NULL;
                            PERFORM "ERP_CAF_FN_ITEM_ASIGNAR_FILA"("HV_ID_Catalogo_Item_Checklist", lv_tipo, lv_x, "HV_UsuarioID");
                        END LOOP;
                    END IF;
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
-- Prueba: CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(1, '1,3:7,3:8', 0);
