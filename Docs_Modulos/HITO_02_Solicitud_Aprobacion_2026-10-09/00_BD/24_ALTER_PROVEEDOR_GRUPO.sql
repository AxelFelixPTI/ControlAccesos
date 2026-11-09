-- =============================================================================
-- Archivo : 24_ALTER_PROVEEDOR_GRUPO.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Hito    : 2 - Solicitud y aprobación | Fase 0 - DDL (D-225: varios transportistas y ayudantes por entrega)
-- Versión : V1.0 2026-11-09
-- Estado  : CANDIDATO - probado en PostgreSQL 16 sobre la base con 01 a 23
-- Requiere: scripts 01 a 23 ejecutados. Se ejecuta UNA vez. Luego re-ejecutar los SP_CAF_* (restaurar_bd.ps1 lo hace solo).
-- =============================================================================
-- 1. CAF_Solicitud_Persona.Fecha_Verificacion: cuándo Vigilancia verificó los datos de ESA persona (checklist de
--    ingreso conforme o con desviación autorizada). NULL = sin verificar. La entrega pasa a EN_ESPERA cuando todos
--    sus transportistas están verificados; el ingreso físico solo se registra a personas verificadas.
-- 2. Parámetro EXCLUSA_CAPACIDAD: vehículos (transportistas) que pueden estar DENTRO a la vez (por defecto 1).
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";
BEGIN;

ALTER TABLE "CAF_Solicitud_Persona" ADD COLUMN "Fecha_Verificacion" TIMESTAMP;

-- Entregas ya verificadas (el principal tiene la llegada registrada): se conserva su verificación
UPDATE "CAF_Solicitud_Persona" P
   SET "Fecha_Verificacion" = COALESCE(O."Fecha_Llegada", CURRENT_TIMESTAMP)
  FROM "CAF_Solicitud_Operacion" O
 WHERE O."ID_Solicitud" = P."ID_Solicitud" AND O."Eliminado" = 'N'
   AND P."Es_Principal" = 'Y' AND P."Eliminado" = 'N'
   AND O."Estado_Operativo" IN ('EN_ESPERA','INGRESO','EN_ATENCION','RECEPCIONADO','SALIO','CIERRE_FORZADO');

INSERT INTO "CAF_Parametro" ("Clave","Valor","Descripcion","UsuarioID_Create")
VALUES ('EXCLUSA_CAPACIDAD','1','Vehículos (transportistas) que pueden estar dentro de la exclusa a la vez durante una entrega de proveedor. Los ayudantes no cuentan.',0);

COMMIT;
