-- =============================================================================
-- 36_ALTER_VENCIDA.sql   (2026-11-19, D-251)
-- Entrega 2C-3a: estado VENCIDA para solicitudes que nadie decidió a tiempo, y sus dos parámetros.
--   1. CK_CAF_Solicitud_Estado admite 'VENCIDA'.
--   2. SOLICITUD_HORA_CORTE_VENCIMIENTO (HH:MM, 00:00): a esa hora se da por terminado el día; una solicitud PENDIENTE u OBSERVADA
--      cuyo último día de visita ya terminó pasa a VENCIDA. (Misma idea que PROVEEDOR_HORA_CORTE.)
--   3. SOLICITUD_HORAS_ANTICIPACION_APROBAR (0 = APAGADO): si es N > 0, la aprobación debe hacerse al menos N horas antes de la hora
--      prevista de la visita; pasado ese límite la solicitud también vence. Hoy no hay mínimo, por eso nace apagado.
-- Se puede ejecutar más de una vez. Schema: TRIANONSATELITAL_CAF_PRODD.
-- HANA: ALTER TABLE "CAF_Solicitud" DROP CONSTRAINT "CK_CAF_Solicitud_Estado"; ADD CONSTRAINT ... (T-53)
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

ALTER TABLE "CAF_Solicitud" DROP CONSTRAINT IF EXISTS "CK_CAF_Solicitud_Estado";
ALTER TABLE "CAF_Solicitud" ADD CONSTRAINT "CK_CAF_Solicitud_Estado"
    CHECK ("Estado" IN ('PENDIENTE','OBSERVADA','APROBADA','APROBADA_PARCIAL','RECHAZADA','CANCELADA','VENCIDA'));

INSERT INTO "CAF_Parametro" ("Clave","Valor","Descripcion","UsuarioID_Create")
SELECT 'SOLICITUD_HORA_CORTE_VENCIMIENTO','00:00','Hora (HH:MM) en que termina el día para las solicitudes: la que siga sin aprobar ni rechazar después del último día de la visita pasa a Vencida.',0
 WHERE NOT EXISTS (SELECT 1 FROM "CAF_Parametro" WHERE "Clave" = 'SOLICITUD_HORA_CORTE_VENCIMIENTO');
INSERT INTO "CAF_Parametro" ("Clave","Valor","Descripcion","UsuarioID_Create")
SELECT 'SOLICITUD_HORAS_ANTICIPACION_APROBAR','0','Horas mínimas de anticipación para aprobar una solicitud respecto de la hora de la visita. 0 = apagado (se puede aprobar hasta el final del día de la visita).',0
 WHERE NOT EXISTS (SELECT 1 FROM "CAF_Parametro" WHERE "Clave" = 'SOLICITUD_HORAS_ANTICIPACION_APROBAR');
