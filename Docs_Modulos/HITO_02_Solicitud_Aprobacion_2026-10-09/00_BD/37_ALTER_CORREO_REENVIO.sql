-- =============================================================================
-- 37_ALTER_CORREO_REENVIO.sql   (2026-11-19, D-252)
-- Entrega 2C-3b: reenvío manual del correo de una solicitud.
--   CK_CAF_Correo_Pendiente_Tipo admite 'SOLICITUD_REENVIO' (aviso con el estado ACTUAL de la solicitud).
-- Se puede ejecutar más de una vez. Schema: TRIANONSATELITAL_CAF_PRODD.
-- HANA: ALTER TABLE ... DROP CONSTRAINT / ADD CONSTRAINT (T-54)
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

ALTER TABLE "CAF_Correo_Pendiente" DROP CONSTRAINT IF EXISTS "CK_CAF_Correo_Pendiente_Tipo";
ALTER TABLE "CAF_Correo_Pendiente" ADD CONSTRAINT "CK_CAF_Correo_Pendiente_Tipo"
  CHECK ("Tipo" IN ('SOLICITUD_NUEVA','SOLICITUD_EDITADA','SOLICITUD_OBSERVADA','SOLICITUD_APROBADA',
                    'SOLICITUD_CANCELADA','USUARIO_DEFINIR_PASSWORD','SOLICITUD_DECISION','PERSONA_POR_APROBAR',
                    'SOLICITUD_CORRECCION','SOLICITUD_VIGILANCIA','PROVEEDOR_AVISO','SOLICITUD_REENVIO'));
