-- =============================================================================
-- Script  : 38_ALTER_PARAMETRO_INCIDENCIA_POST_SALIDA.sql   (2026-11-19, D-257)
-- Propósito: parámetro INCIDENCIA_POST_SALIDA (Y/N): ¿Vigilancia puede registrar incidencias a personas que ya salieron?
--            Por defecto N (no). El Coordinador no se ve afectado. Idempotente.
-- Nota HANA: INSERT ... SELECT ... WHERE NOT EXISTS es válido tal cual (T-53/T-54 no aplican).
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD", "CAF_GOVERNANCE";

INSERT INTO "CAF_Parametro" ("Clave","Valor","Descripcion","UsuarioID_Create")
SELECT 'INCIDENCIA_POST_SALIDA', 'N', 'Permitir que Vigilancia registre incidencias a personas que ya salieron del establecimiento (Y/N). Por defecto N.', 0
 WHERE NOT EXISTS (SELECT 1 FROM "CAF_Parametro" WHERE "Clave" = 'INCIDENCIA_POST_SALIDA');
