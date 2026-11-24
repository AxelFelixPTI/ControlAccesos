-- =============================================================================
-- Script  : 44_ALTER_PARAMETRO_CORREO_AUTOMATICO.sql   (2026-11-24, D-271)
-- Propósito: parámetro CORREO_ENVIO_AUTOMATICO (Y/N), editable en «Parámetros» por el administrador.
--            N (por defecto) = solo salen los reenvíos manuales; los avisos automáticos esperan en la cola.
--            Y = se envían también los avisos automáticos. Idempotente.
-- Nota HANA: INSERT ... SELECT ... WHERE NOT EXISTS es válido tal cual.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD", "CAF_GOVERNANCE";

INSERT INTO "CAF_Parametro" ("Clave","Valor","Descripcion","UsuarioID_Create")
SELECT 'CORREO_ENVIO_AUTOMATICO', 'N', 'Si la aplicación envía sola los avisos por correo (Y/N). Por defecto N: solo salen los reenvíos manuales.', 0
 WHERE NOT EXISTS (SELECT 1 FROM "CAF_Parametro" WHERE "Clave" = 'CORREO_ENVIO_AUTOMATICO');
