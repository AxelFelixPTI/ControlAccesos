-- =============================================================================
-- 31_ALTER_PROVEEDOR_FORMULARIO.sql   (2026-11-13, D-237)
-- Formulario de entrega de proveedor reestructurado (Entrega 2C-0):
--   1. CAF_Solicitud.Numeros_OC            las OC de la entrega, separadas por «;» (al menos una; lo exige el SP).
--   2. CAF_Solicitud.Empresa_Transportista opcional; vacío = el mismo proveedor hace el transporte.
--   3. CAF_Solicitud.Hora_Hasta_Prevista   fin de la franja horaria estimada (opcional, SOLO informativa: no restringe nada).
--      La hora de inicio sigue siendo Fecha_Hora_Prevista.
--   4. El subtipo de persona TRANSPORTISTA del Proveedor pasa a llamarse «Conductor» (solo el texto; el código no cambia).
-- Contacto_Correos (correo del responsable de la entrega) ya existe desde el script 16.
-- Las solicitudes anteriores quedan con estos campos vacíos; las reglas nuevas se exigen cuando se vuelven a guardar.
-- Se puede ejecutar más de una vez. Schema: TRIANONSATELITAL_CAF_PRODD.
-- HANA (T-43): sin ADD COLUMN IF NOT EXISTS (se pregunta antes por SYS.TABLE_COLUMNS); TIME existe; el resto de rutinas de
--              esta entrega usa REGEXP_SPLIT_TO_TABLE, que se reescribe como en los demás SP.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

ALTER TABLE "CAF_Solicitud" ADD COLUMN IF NOT EXISTS "Numeros_OC"            VARCHAR(200);
ALTER TABLE "CAF_Solicitud" ADD COLUMN IF NOT EXISTS "Empresa_Transportista" VARCHAR(200);
ALTER TABLE "CAF_Solicitud" ADD COLUMN IF NOT EXISTS "Hora_Hasta_Prevista"   TIME;

UPDATE "Tipo_Acceso_Subtipo" S
   SET "Descripcion" = 'Conductor', "UsuarioID_Update" = 0, "UpdateDate" = CURRENT_TIMESTAMP
  FROM "Catalogo_Tipo_Acceso" T
 WHERE T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
   AND S."Codigo" = 'TRANSPORTISTA' AND S."Descripcion" = 'Transportista';
