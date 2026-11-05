-- =============================================================================
-- Archivo : 19_ALTER_PROVEEDOR_ESTADOS.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Hito    : 2 - Solicitud y aprobacion | Fase 0 - DDL y datos (Entrega 2b de Proveedor de abastecimiento)
-- Version : V1.0 2026-11-03
-- Estado  : CANDIDATO - probado en PostgreSQL 16 sobre la base con 01 a 18
-- Requiere: scripts 01 a 18 ejecutados.
-- =============================================================================
-- Que hace (corrige el flujo operativo de proveedores):
--   1. Estado operativo nuevo INGRESO_DENEGADO (el coordinador decidio que no ingresa, en la verificacion).
--   2. CAF_Solicitud_Operacion: Con_Desviacion (la verificacion tuvo desviacion), disponibilidad de Almacen
--      (quien y cuando la confirmo) y la ultima cancelacion de disponibilidad (quien, cuando, por que).
--      La RESERVA de la esclusa sigue siendo CAF_Exclusa.ID_Solicitud_Actual (una por sede).
--   3. Licencias de proveedores: la verificacion de datos puede traer desviaciones, asi que la licencia de
--      Vigilancia de proveedores recibe PER_CAF_DESVIACION_REGISTRAR y la del Coordinador de proveedores
--      PER_CAF_DESVIACION_CONFORMIDAD (ser consultado y dar conformidad). Hasta hoy no los tenian.
--   4. Migra datos con el significado anterior:
--        a) EN_ESPERA (antes = "llego") -> PROGRAMADO: ahora EN_ESPERA = datos verificados.
--        b) INGRESO sin reserva de esclusa: el primero de la sede conserva la esclusa si esta libre; los demas
--           vuelven a EN_ESPERA (no puede haber dos ingresos a la vez). Deja un evento por cada fila corregida.
--   El flujo nuevo: PROGRAMADO -> (Vigilancia verifica los datos) EN_ESPERA -> (Almacen confirma disponibilidad
--   y reserva la esclusa; Vigilancia valida el ingreso) INGRESO -> EN_ATENCION -> RECEPCIONADO -> SALIO.
-- HANA: ALTER TABLE ... ADD ("col" tipo); la migracion 3b usa una tabla temporal y UPDATE ... FROM (PostgreSQL):
--       en HANA se reescribe con subconsultas (ver T-31).
-- Va en una transaccion y se ejecuta UNA vez.
-- =============================================================================

BEGIN;

DO $$
BEGIN
    IF to_regclass('"TRIANONSATELITAL_CAF_PRODD"."CAF_Exclusa"') IS NULL THEN
        RAISE EXCEPTION 'Falta el script 18.';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'TRIANONSATELITAL_CAF_PRODD' AND table_name = 'CAF_Solicitud_Operacion' AND column_name = 'Con_Desviacion') THEN
        RAISE EXCEPTION 'El script 19 ya se ejecuto. No se repite.';
    END IF;
END $$;

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- 1. Estado nuevo ----------------------------------------------------------------------------------
ALTER TABLE "CAF_Solicitud_Operacion" DROP CONSTRAINT "CK_CAF_Solicitud_Operacion_Estado";
ALTER TABLE "CAF_Solicitud_Operacion" ADD CONSTRAINT "CK_CAF_Solicitud_Operacion_Estado"
    CHECK ("Estado_Operativo" IN ('PROGRAMADO','EN_ESPERA','INGRESO','EN_ATENCION','RECEPCIONADO','SALIO','NO_SE_PRESENTO','INGRESO_DENEGADO'));

-- 2. Columnas --------------------------------------------------------------------------------------
ALTER TABLE "CAF_Solicitud_Operacion" ADD COLUMN "Con_Desviacion"              CHAR(1) DEFAULT 'N' NOT NULL;
ALTER TABLE "CAF_Solicitud_Operacion" ADD CONSTRAINT "CK_CAF_Solicitud_Operacion_Desv" CHECK ("Con_Desviacion" IN ('Y','N'));
ALTER TABLE "CAF_Solicitud_Operacion" ADD COLUMN "Fecha_Disponibilidad"        TIMESTAMP;     -- Almacen confirmo que puede recibir (reserva vigente)
ALTER TABLE "CAF_Solicitud_Operacion" ADD COLUMN "ID_Usuario_Disponibilidad"   BIGINT;
ALTER TABLE "CAF_Solicitud_Operacion" ADD COLUMN "Fecha_Cancelacion_Disp"      TIMESTAMP;     -- ultima cancelacion de la disponibilidad
ALTER TABLE "CAF_Solicitud_Operacion" ADD COLUMN "ID_Usuario_Cancelacion_Disp" BIGINT;
ALTER TABLE "CAF_Solicitud_Operacion" ADD COLUMN "Motivo_Cancelacion_Disp"     VARCHAR(500);

-- 3. Permisos de desviaciones para las licencias de proveedores -----------------------------------
SET search_path TO "CAF_GOVERNANCE";
INSERT INTO "Licencia_Permiso" ("ID_Catalogo_Licencia","ID_Catalogo_Permiso","UsuarioID_Create")
SELECT l."ID_Catalogo_Licencia", p."ID_Catalogo_Permiso", 0
  FROM (VALUES
    ('LIC_CAF_VIGILANCIA_PROVEEDOR','PER_CAF_DESVIACION_REGISTRAR'),
    ('LIC_CAF_COORD_PROVEEDOR',     'PER_CAF_DESVIACION_CONFORMIDAD')
  ) AS v(lic, per)
  JOIN "Catalogo_Licencia" l ON l."Codigo" = v.lic
  JOIN "Catalogo_Permiso"  p ON p."Codigo" = v.per
 WHERE NOT EXISTS (SELECT 1 FROM "Licencia_Permiso" X WHERE X."ID_Catalogo_Licencia" = l."ID_Catalogo_Licencia" AND X."ID_Catalogo_Permiso" = p."ID_Catalogo_Permiso");
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- 3a. EN_ESPERA antiguo ("llego") -> PROGRAMADO ----------------------------------------------------
INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion")
SELECT O."ID_Solicitud", 'EN_ESPERA', 'PROGRAMADO', 0, 'Migracion 19: la llegada ya no es un estado; la verificacion de datos pasa a EN_ESPERA'
  FROM "CAF_Solicitud_Operacion" O WHERE O."Estado_Operativo" = 'EN_ESPERA';
UPDATE "CAF_Solicitud_Operacion"
   SET "Estado_Operativo" = 'PROGRAMADO', "Fecha_Llegada" = NULL, "ID_Usuario_Llegada" = NULL, "UsuarioID_Update" = 0, "UpdateDate" = CURRENT_TIMESTAMP
 WHERE "Estado_Operativo" = 'EN_ESPERA';

-- 3b. INGRESO sin reserva de esclusa ---------------------------------------------------------------
CREATE TEMPORARY TABLE "tmp_mig19_ingreso" ON COMMIT DROP AS
SELECT O."ID_Solicitud", S."ID_Catalogo_Sede", O."Fecha_Ingreso",
       ROW_NUMBER() OVER (PARTITION BY S."ID_Catalogo_Sede" ORDER BY O."Fecha_Ingreso", O."ID_Solicitud") AS rn
  FROM "CAF_Solicitud_Operacion" O
  JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = O."ID_Solicitud"
 WHERE O."Estado_Operativo" = 'INGRESO' AND O."Eliminado" = 'N';

-- el primero de cada sede conserva la esclusa si esta libre
UPDATE "CAF_Exclusa" X
   SET "ID_Solicitud_Actual" = T."ID_Solicitud", "Fecha_Ocupada" = COALESCE(T."Fecha_Ingreso", CURRENT_TIMESTAMP),
       "ID_Usuario_Ocupa" = 0, "UsuarioID_Update" = 0, "UpdateDate" = CURRENT_TIMESTAMP
  FROM "tmp_mig19_ingreso" T
 WHERE T.rn = 1 AND X."ID_Catalogo_Sede" = T."ID_Catalogo_Sede" AND X."ID_Solicitud_Actual" IS NULL;

-- los demas (sin la esclusa) vuelven a EN_ESPERA
INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion")
SELECT T."ID_Solicitud", 'INGRESO', 'EN_ESPERA', 0, 'Migracion 19: no puede haber dos ingresos a la vez; vuelve a esperar la disponibilidad de Almacen'
  FROM "tmp_mig19_ingreso" T
 WHERE NOT EXISTS (SELECT 1 FROM "CAF_Exclusa" X WHERE X."ID_Solicitud_Actual" = T."ID_Solicitud");

UPDATE "CAF_Solicitud_Persona" P
   SET "Estado" = 'ESPERADA', "Fecha_Hora_Ingreso" = NULL, "UsuarioID_Update" = 0, "UpdateDate" = CURRENT_TIMESTAMP
 WHERE P."Es_Principal" = 'Y' AND P."Estado" = 'DENTRO'
   AND P."ID_Solicitud" IN (SELECT T."ID_Solicitud" FROM "tmp_mig19_ingreso" T
                             WHERE NOT EXISTS (SELECT 1 FROM "CAF_Exclusa" X WHERE X."ID_Solicitud_Actual" = T."ID_Solicitud"));

UPDATE "CAF_Solicitud_Operacion" O
   SET "Estado_Operativo" = 'EN_ESPERA', "Fecha_Ingreso" = NULL, "UsuarioID_Update" = 0, "UpdateDate" = CURRENT_TIMESTAMP
 WHERE O."ID_Solicitud" IN (SELECT T."ID_Solicitud" FROM "tmp_mig19_ingreso" T
                             WHERE NOT EXISTS (SELECT 1 FROM "CAF_Exclusa" X WHERE X."ID_Solicitud_Actual" = T."ID_Solicitud"));

-- quien conserva la esclusa queda con su disponibilidad registrada
UPDATE "CAF_Solicitud_Operacion" O
   SET "Fecha_Disponibilidad" = X."Fecha_Ocupada", "ID_Usuario_Disponibilidad" = 0
  FROM "CAF_Exclusa" X
 WHERE X."ID_Solicitud_Actual" = O."ID_Solicitud" AND O."Fecha_Disponibilidad" IS NULL;

COMMIT;
