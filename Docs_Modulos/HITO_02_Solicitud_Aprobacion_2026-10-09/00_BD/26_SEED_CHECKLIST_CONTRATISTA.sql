-- =============================================================================
-- 26_SEED_CHECKLIST_CONTRATISTA.sql   (2026-11-09, D-227)
-- Checklist de INGRESO y SALIDA del contratista (provisional, pendiente de validar con Sandra: P-159).
-- Hasta hoy el tipo CONTRATISTA no tenía ítems de checklist y Vigilancia no podía registrar sus ingresos ni salidas
-- («No hay ítems de checklist configurados para este tipo de acceso»).
-- Se usan los mismos ítems que el visitante externo, salvo los dos que dependen del responsable de atención
-- («Responsable de atención confirmó la llegada» y «Responsable de atención acompañó hasta la salida»), porque para el
-- contratista el responsable es opcional.
-- Es solo un dato: se puede cambiar desde el administrador de checklist. Se puede ejecutar más de una vez.
-- Schema: TRIANONSATELITAL_CAF_PRODD (search_path de la sesión).
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

INSERT INTO "Tipo_Acceso_Item_Checklist" ("ID_Catalogo_Tipo_Acceso","ID_Catalogo_Item_Checklist","UsuarioID_Create")
SELECT t."ID_Catalogo_Tipo_Acceso", i."ID_Catalogo_Item_Checklist", 0
  FROM "Catalogo_Tipo_Acceso" t
 CROSS JOIN "Catalogo_Item_Checklist" i
 WHERE t."Codigo" = 'CONTRATISTA'
   AND i."Codigo" IN ('ING_IDENTIDAD','ING_SCTR','ING_EPP','ING_PERTENENCIAS','ING_ARCO','ING_FICHA_ENTREGADA',
                      'SAL_FICHA_DEVUELTA','SAL_ARCO','SAL_SIN_ELEMENTOS','SAL_EQUIPOS','SAL_HERRAMIENTAS')
   AND NOT EXISTS (SELECT 1 FROM "Tipo_Acceso_Item_Checklist" x
                    WHERE x."ID_Catalogo_Tipo_Acceso" = t."ID_Catalogo_Tipo_Acceso" AND x."ID_Catalogo_Item_Checklist" = i."ID_Catalogo_Item_Checklist");
