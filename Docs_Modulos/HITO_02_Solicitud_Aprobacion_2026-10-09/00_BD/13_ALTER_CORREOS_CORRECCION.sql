-- =============================================================================
-- Archivo : 13_ALTER_CORREOS_CORRECCION.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Hito    : 2 - Solicitud y aprobación | Fase 0 - DDL (ampliación)   (D-169, P-98)
-- Versión : V1.0 2026-10-27
-- Estado  : CANDIDATO - probado en PostgreSQL 16 sobre la base con 01 a 12
-- Requiere: scripts 01 a 12 ejecutados.
-- =============================================================================
-- POR QUÉ
-- La corrección de emergencia del Coordinador (agregar o quitar a una persona de una
-- solicitud ya aprobada) avisa al solicitante y a Vigilancia con un correo propio:
--   SOLICITUD_CORRECCION   aviso de una corrección de emergencia sobre una solicitud aprobada
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
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
                    WHERE conname = 'CK_CAF_Correo_Pendiente_Tipo'
                      AND pg_get_constraintdef(oid) LIKE '%SOLICITUD_DECISION%') THEN
        RAISE EXCEPTION 'Falta el script 10: ejecútelo antes del 13.';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint
                WHERE conname = 'CK_CAF_Correo_Pendiente_Tipo'
                  AND pg_get_constraintdef(oid) LIKE '%SOLICITUD_CORRECCION%') THEN
        RAISE EXCEPTION 'El script 13 ya se ejecutó. No se repite.';
    END IF;
END $$;

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

ALTER TABLE "CAF_Correo_Pendiente" DROP CONSTRAINT "CK_CAF_Correo_Pendiente_Tipo";
ALTER TABLE "CAF_Correo_Pendiente" ADD CONSTRAINT "CK_CAF_Correo_Pendiente_Tipo"
  CHECK ("Tipo" IN ('SOLICITUD_NUEVA','SOLICITUD_EDITADA','SOLICITUD_OBSERVADA','SOLICITUD_APROBADA',
                    'SOLICITUD_CANCELADA','USUARIO_DEFINIR_PASSWORD','SOLICITUD_DECISION','PERSONA_POR_APROBAR',
                    'SOLICITUD_CORRECCION'));

COMMIT;
