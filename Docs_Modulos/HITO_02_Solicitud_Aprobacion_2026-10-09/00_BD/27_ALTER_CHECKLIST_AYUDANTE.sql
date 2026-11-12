-- =============================================================================
-- 27_ALTER_CHECKLIST_AYUDANTE.sql   (2026-11-11, D-231)
-- Condición nueva de checklist SOLO_AYUDANTE: el ítem se pide únicamente a los ayudantes de descarga (lo contrario de SOLO_PRINCIPAL).
-- Amplía el CHECK de la condición y siembra UN ítem simple de salida para los ayudantes del proveedor.
-- Es solo un dato: se edita, desactiva o reasigna desde Catálogos › Checklist de portería. Se puede ejecutar más de una vez.
-- Después de este script hay que re-ejecutar SP_CAF_PORTERIA_ALL.sql y SP_CAF_CATALOGO_ITEM_CHECKLIST_ALL.sql.
-- Schema: TRIANONSATELITAL_CAF_PRODD (search_path de la sesión).
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

ALTER TABLE "Catalogo_Item_Checklist" DROP CONSTRAINT IF EXISTS "CK_Catalogo_Item_Checklist_Condicion";
ALTER TABLE "Catalogo_Item_Checklist" ADD CONSTRAINT "CK_Catalogo_Item_Checklist_Condicion"
    CHECK ("Condicion" IN ('SIEMPRE','ZONA_EXIGE_SCTR','ZONA_EXIGE_EPP','TRAE_EQUIPOS','TRAE_HERRAMIENTAS','SOLO_PRINCIPAL','SOLO_AYUDANTE'));

INSERT INTO "Catalogo_Item_Checklist" ("Codigo","Descripcion","Ayuda","Etapa","Condicion","Es_Critico","Orden","UsuarioID_Create")
SELECT 'SAL_AYUDANTE_VERIFICADO', 'Verificó la salida del ayudante de descarga', 'Sale sin llevar materiales ni equipos de la empresa.', 'SALIDA', 'SOLO_AYUDANTE', 'N', 20, 0
 WHERE NOT EXISTS (SELECT 1 FROM "Catalogo_Item_Checklist" WHERE "Codigo" = 'SAL_AYUDANTE_VERIFICADO');

INSERT INTO "Tipo_Acceso_Item_Checklist" ("ID_Catalogo_Tipo_Acceso","ID_Catalogo_Item_Checklist","UsuarioID_Create")
SELECT t."ID_Catalogo_Tipo_Acceso", i."ID_Catalogo_Item_Checklist", 0
  FROM "Catalogo_Tipo_Acceso" t
 CROSS JOIN "Catalogo_Item_Checklist" i
 WHERE t."Codigo" = 'PROVEEDOR' AND i."Codigo" = 'SAL_AYUDANTE_VERIFICADO'
   AND NOT EXISTS (SELECT 1 FROM "Tipo_Acceso_Item_Checklist" x
                    WHERE x."ID_Catalogo_Tipo_Acceso" = t."ID_Catalogo_Tipo_Acceso" AND x."ID_Catalogo_Item_Checklist" = i."ID_Catalogo_Item_Checklist");
