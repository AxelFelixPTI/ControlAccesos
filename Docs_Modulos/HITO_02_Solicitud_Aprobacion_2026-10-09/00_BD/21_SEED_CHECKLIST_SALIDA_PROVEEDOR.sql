-- =============================================================================
-- 21_SEED_CHECKLIST_SALIDA_PROVEEDOR.sql   (2026-11-05)
-- Checklist de SALIDA del proveedor (provisional, a pedido del usuario): un ítem que solo se pide
-- al transportista principal. Sin ítems, Vigilancia no podía registrar la salida del camión.
-- Es solo un dato: se puede cambiar el texto o activar/desactivar desde el administrador de checklist.
-- Se puede ejecutar más de una vez.
-- Schema: TRIANONSATELITAL_CAF_PRODD (search_path de la sesión).
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

INSERT INTO "Catalogo_Item_Checklist" ("Codigo","Descripcion","Ayuda","Etapa","Condicion","Es_Critico","Orden","UsuarioID_Create")
SELECT 'SAL_PROVEEDOR_DOCUMENTOS',
       'Verifica que el vehículo se retire con la carga y documentación correspondiente, como guía de remisión, documento de despacho, acta de entrega u otro sustento aplicable.',
       'Solo se pide al transportista principal.', 'SALIDA', 'SOLO_PRINCIPAL', 'N', 10, 0
 WHERE NOT EXISTS (SELECT 1 FROM "Catalogo_Item_Checklist" WHERE "Codigo" = 'SAL_PROVEEDOR_DOCUMENTOS');

INSERT INTO "Tipo_Acceso_Item_Checklist" ("ID_Catalogo_Tipo_Acceso","ID_Catalogo_Item_Checklist","UsuarioID_Create")
SELECT t."ID_Catalogo_Tipo_Acceso", i."ID_Catalogo_Item_Checklist", 0
  FROM "Catalogo_Tipo_Acceso" t
  JOIN "Catalogo_Item_Checklist" i ON i."Codigo" = 'SAL_PROVEEDOR_DOCUMENTOS'
 WHERE t."Codigo" = 'PROVEEDOR'
   AND NOT EXISTS (SELECT 1 FROM "Tipo_Acceso_Item_Checklist" x
                    WHERE x."ID_Catalogo_Tipo_Acceso" = t."ID_Catalogo_Tipo_Acceso" AND x."ID_Catalogo_Item_Checklist" = i."ID_Catalogo_Item_Checklist");
