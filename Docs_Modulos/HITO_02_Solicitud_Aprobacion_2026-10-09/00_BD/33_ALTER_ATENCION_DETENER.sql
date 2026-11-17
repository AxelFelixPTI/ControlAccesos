-- =============================================================================
-- 33_ALTER_ATENCION_DETENER.sql   (2026-11-15, D-239)
-- Entrega 2C-2: disponibilidad con o sin ingreso vehicular, detener/reanudar la atención por empresa y placa configurable.
--   1. CAF_Solicitud_Operacion.Con_Vehiculo ('Y' con ingreso vehicular, 'N' sin ingreso; NULL = Almacén aún no confirmó).
--      Lo elige el almacenero al confirmar la disponibilidad y no se puede deshacer. Las entregas ya confirmadas quedan en 'Y'.
--   2. CAF_Solicitud_Atencion: estado DETENIDA + motivo (opcional) y hora de la detención.
--   3. Parámetro PLACA_OBLIGATORIA ('Y'/'N', por defecto 'Y'): si es 'N' no se exige la placa del conductor.
--   4. Parámetro EXCLUSA_CAPACIDAD acepta además SIN_LIMITE (se valida en ERP_CAF_PARAMETRO_GUARDAR).
-- Se puede ejecutar más de una vez. Requiere los scripts 19 y 32. Schema: TRIANONSATELITAL_CAF_PRODD.
-- HANA (T-45): ADD COLUMN IF NOT EXISTS no existe (consultar SYS.TABLE_COLUMNS); el CHECK se reemplaza con DROP CONSTRAINT / ADD CONSTRAINT.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

ALTER TABLE "CAF_Solicitud_Operacion" ADD COLUMN IF NOT EXISTS "Con_Vehiculo" CHAR(1);
ALTER TABLE "CAF_Solicitud_Operacion" DROP CONSTRAINT IF EXISTS "CK_CAF_Solicitud_Operacion_ConVehiculo";
ALTER TABLE "CAF_Solicitud_Operacion" ADD CONSTRAINT "CK_CAF_Solicitud_Operacion_ConVehiculo" CHECK ("Con_Vehiculo" IS NULL OR "Con_Vehiculo" IN ('Y','N'));
UPDATE "CAF_Solicitud_Operacion" SET "Con_Vehiculo" = 'Y' WHERE "Con_Vehiculo" IS NULL AND "Fecha_Disponibilidad" IS NOT NULL;

ALTER TABLE "CAF_Solicitud_Atencion" ADD COLUMN IF NOT EXISTS "Motivo_Detencion" VARCHAR(300);
ALTER TABLE "CAF_Solicitud_Atencion" ADD COLUMN IF NOT EXISTS "Fecha_Detencion"  TIMESTAMP;
ALTER TABLE "CAF_Solicitud_Atencion" DROP CONSTRAINT IF EXISTS "CK_CAF_Solicitud_Atencion_Estado";
ALTER TABLE "CAF_Solicitud_Atencion" ADD CONSTRAINT "CK_CAF_Solicitud_Atencion_Estado"
    CHECK ("Estado" IN ('PENDIENTE','EN_ATENCION','DETENIDA','ATENDIDA','CERRADA_SIN_ATENCION'));

INSERT INTO "CAF_Parametro" ("Clave","Valor","Descripcion","UsuarioID_Create")
SELECT 'PLACA_OBLIGATORIA', 'Y', 'Si es Y, la placa del vehículo del conductor es obligatoria en la solicitud de proveedor. Con N ya no se exige.', 0
 WHERE NOT EXISTS (SELECT 1 FROM "CAF_Parametro" WHERE "Clave" = 'PLACA_OBLIGATORIA');
