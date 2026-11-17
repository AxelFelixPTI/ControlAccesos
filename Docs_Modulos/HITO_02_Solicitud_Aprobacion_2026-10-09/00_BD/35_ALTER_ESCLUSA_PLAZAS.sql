-- =============================================================================
-- 35_ALTER_ESCLUSA_PLAZAS.sql   (2026-11-17, D-247)
-- Entrega 2C-2i: la esclusa admite varias entregas con ingreso vehicular a la vez, hasta la «Capacidad de la esclusa».
--   Antes: CAF_Exclusa tenía UNA fila por sede (un solo titular). Ahora cada fila es una PLAZA: ID_Solicitud_Actual = NULL (libre)
--   o la entrega que la tiene reservada. La fila ya existente sigue siendo la primera plaza; las demás se crean solas al reservar.
--   Solo se quita la restricción de unicidad por sede. Se puede ejecutar más de una vez. Schema: TRIANONSATELITAL_CAF_PRODD.
-- HANA: ALTER TABLE "CAF_Exclusa" DROP CONSTRAINT "UQ_CAF_Exclusa_Sede"; (T-50)
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

ALTER TABLE "CAF_Exclusa" DROP CONSTRAINT IF EXISTS "UQ_CAF_Exclusa_Sede";
CREATE INDEX IF NOT EXISTS "IX_CAF_Exclusa_Sede" ON "CAF_Exclusa" ("ID_Catalogo_Sede", "ID_Solicitud_Actual");
