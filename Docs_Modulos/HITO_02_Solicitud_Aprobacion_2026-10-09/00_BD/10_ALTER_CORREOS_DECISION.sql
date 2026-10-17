-- =============================================================================
-- Archivo : 10_ALTER_CORREOS_DECISION.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Hito    : 2 - Solicitud y aprobación | Fase 0 - DDL (ampliación)
-- Versión : V1.0 2026-10-16
-- Estado  : CANDIDATO - probado en PostgreSQL 16 sobre la base con 01 a 09
-- Requiere: scripts 01 a 09 ejecutados.
-- =============================================================================
-- POR QUÉ
-- Con la aprobación por persona, el correo al solicitante resume UNA decisión
-- que puede mezclar aprobadas, observadas y rechazadas. Los tipos que existían
-- (SOLICITUD_APROBADA, SOLICITUD_OBSERVADA) hablaban de toda la solicitud y no
-- había uno para el rechazo. Se agregan dos tipos y se conservan los anteriores:
--   SOLICITUD_DECISION   resumen de una decisión del aprobador (aprobó, observó, rechazó)
--   PERSONA_POR_APROBAR  aviso al siguiente aprobador de que hay personas esperando
-- ADITIVO: no se quita ningún valor ni se toca ningún dato.
-- HANA: ampliar un CHECK es borrar y volver a crear la restricción (igual que aquí).
-- Va en una transacción y verifica sus requisitos: todo o nada. Se ejecuta UNA vez.
-- =============================================================================

BEGIN;

DO $$
BEGIN
    IF to_regclass('"TRIANONSATELITAL_CAF_PRODD"."CAF_Correo_Pendiente"') IS NULL THEN
        RAISE EXCEPTION 'Faltan los scripts 06 a 08: no existe CAF_Correo_Pendiente.';
    END IF;
    IF to_regclass('"CAF_GOVERNANCE"."Catalogo_Permiso"') IS NULL THEN
        RAISE EXCEPTION 'Falta el script 09: ejecútelo antes del 10.';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint
                WHERE conname = 'CK_CAF_Correo_Pendiente_Tipo'
                  AND pg_get_constraintdef(oid) LIKE '%SOLICITUD_DECISION%') THEN
        RAISE EXCEPTION 'El script 10 ya se ejecutó. No se repite.';
    END IF;
END $$;

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

ALTER TABLE "CAF_Correo_Pendiente" DROP CONSTRAINT "CK_CAF_Correo_Pendiente_Tipo";
ALTER TABLE "CAF_Correo_Pendiente" ADD CONSTRAINT "CK_CAF_Correo_Pendiente_Tipo"
  CHECK ("Tipo" IN ('SOLICITUD_NUEVA','SOLICITUD_EDITADA','SOLICITUD_OBSERVADA','SOLICITUD_APROBADA',
                    'SOLICITUD_CANCELADA','USUARIO_DEFINIR_PASSWORD','SOLICITUD_DECISION','PERSONA_POR_APROBAR'));

COMMIT;
