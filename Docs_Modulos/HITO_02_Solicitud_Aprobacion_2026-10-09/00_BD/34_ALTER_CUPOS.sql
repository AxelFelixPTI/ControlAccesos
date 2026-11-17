-- =============================================================================
-- 34_ALTER_CUPOS.sql   (2026-11-16, D-244)
-- Entrega 2C-2e: cupos de atención configurables.
--   1. Parámetro ATENCIONES_SIMULTANEAS_ALMACENERO (por defecto 1): cuántas solicitudes puede tener a la vez un almacenero
--      (reservadas al confirmar la disponibilidad o en atención). Número de 1 a 99 o SIN_LIMITE (desactivado).
--   2. ATENCIONES_SIMULTANEAS_EMPRESA acepta también SIN_LIMITE (se valida en ERP_CAF_PARAMETRO_GUARDAR).
--   3. Cupo individual por empresa: parámetros CUPO_EMPRESA:<código de la empresa> (número, SIN_LIMITE o GENERAL = usar el valor general).
--      No hace falta sembrarlos: ERP_CAF_PARAMETRO_LISTAR muestra una fila por empresa activa y ERP_CAF_PARAMETRO_GUARDAR la crea al guardar.
-- Sin tablas nuevas. Se puede ejecutar más de una vez. Schema: TRIANONSATELITAL_CAF_PRODD.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

INSERT INTO "CAF_Parametro" ("Clave","Valor","Descripcion","UsuarioID_Create")
SELECT 'ATENCIONES_SIMULTANEAS_ALMACENERO', '1', 'Solicitudes que un almacenero puede tener a la vez (desde que confirma la disponibilidad hasta que termina o detiene la atención). Número de 1 a 99 o SIN_LIMITE.', 0
 WHERE NOT EXISTS (SELECT 1 FROM "CAF_Parametro" WHERE "Clave" = 'ATENCIONES_SIMULTANEAS_ALMACENERO');
