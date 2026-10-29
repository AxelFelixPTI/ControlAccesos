-- =============================================================================
-- Archivo : 14_ALTER_CORREOS_VIGILANCIA.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Hito    : 2 - Solicitud y aprobación | Fase 0 - DDL (ampliación)   (D-181, D-182)
-- Versión : V1.0 2026-10-29
-- Estado  : CANDIDATO - probado en PostgreSQL 16 sobre la base con 01 a 13
-- Requiere: scripts 01 a 13 ejecutados.
-- =============================================================================
-- POR QUÉ
-- Vigilancia recibe un correo propio cuando una decisión deja personas APROBADAS (aunque otras
-- sigan observadas o pendientes) y ese correo lista SOLO a esas personas:
--   SOLICITUD_VIGILANCIA   aviso de ingreso autorizado (tipo nuevo en el CHECK)
--   IDs_Personas           columna nueva: las personas (ID_Solicitud_Persona, separadas por coma)
--                          que ese correo autoriza. Nulo en los demás tipos.
-- ADITIVO: no se quita ningún valor ni se toca ningún dato.
-- HANA: ampliar un CHECK es borrar y volver a crear la restricción; ADD COLUMN es igual.
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
                      AND pg_get_constraintdef(oid) LIKE '%SOLICITUD_CORRECCION%') THEN
        RAISE EXCEPTION 'Falta el script 13: ejecútelo antes del 14.';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint
                WHERE conname = 'CK_CAF_Correo_Pendiente_Tipo'
                  AND pg_get_constraintdef(oid) LIKE '%SOLICITUD_VIGILANCIA%') THEN
        RAISE EXCEPTION 'El script 14 ya se ejecutó. No se repite.';
    END IF;
END $$;

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

ALTER TABLE "CAF_Correo_Pendiente" ADD COLUMN "IDs_Personas" VARCHAR(2000);

ALTER TABLE "CAF_Correo_Pendiente" DROP CONSTRAINT "CK_CAF_Correo_Pendiente_Tipo";
ALTER TABLE "CAF_Correo_Pendiente" ADD CONSTRAINT "CK_CAF_Correo_Pendiente_Tipo"
  CHECK ("Tipo" IN ('SOLICITUD_NUEVA','SOLICITUD_EDITADA','SOLICITUD_OBSERVADA','SOLICITUD_APROBADA',
                    'SOLICITUD_CANCELADA','USUARIO_DEFINIR_PASSWORD','SOLICITUD_DECISION','PERSONA_POR_APROBAR',
                    'SOLICITUD_CORRECCION','SOLICITUD_VIGILANCIA'));

COMMIT;
