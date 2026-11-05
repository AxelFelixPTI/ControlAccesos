-- ============================================================================================================
-- Archivo : 20_ALTER_PROVEEDOR_RETIRO.sql        Version: V1.0  2026-11-05
-- Requiere: script 19.
-- Cambio  : nuevo estado operativo RETIRO_SIN_INGRESO (el proveedor ya fue verificado y se va sin ingresar;
--           lo registra Vigilancia con motivo). Despues re-ejecute SP_CAF_PROVEEDOR_ALL.sql y
--           SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql.
-- HANA    : ALTER TABLE ... DROP CONSTRAINT / ADD CONSTRAINT equivalente (T-31).
-- ============================================================================================================
BEGIN;
SET LOCAL search_path TO "TRIANONSATELITAL_CAF_PRODD";
ALTER TABLE "CAF_Solicitud_Operacion" DROP CONSTRAINT "CK_CAF_Solicitud_Operacion_Estado";
ALTER TABLE "CAF_Solicitud_Operacion" ADD CONSTRAINT "CK_CAF_Solicitud_Operacion_Estado"
    CHECK ("Estado_Operativo" IN ('PROGRAMADO','EN_ESPERA','INGRESO','EN_ATENCION','RECEPCIONADO','SALIO','NO_SE_PRESENTO','INGRESO_DENEGADO','RETIRO_SIN_INGRESO'));
COMMIT;
