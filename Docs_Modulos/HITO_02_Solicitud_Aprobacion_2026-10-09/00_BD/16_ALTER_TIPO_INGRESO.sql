-- =============================================================================
-- Archivo : 16_ALTER_TIPO_INGRESO.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Hito    : 2 - Solicitud y aprobación | Fase 0 - DDL y datos (Entrega H: tipo de ingreso)   (D-187 a D-192)
-- Versión : V1.0 2026-10-29
-- Estado  : CANDIDATO - probado en PostgreSQL 16 sobre la base con 01 a 15
-- Requiere: scripts 01 a 15 ejecutados.
-- =============================================================================
-- Qué hace (aditivo; no cambia ni borra datos de solicitudes ya creadas):
--   1. CAF_Solicitud: columnas para estacionamiento (Requiere_Cochera, Placa_Vehiculo), detalle del
--      área de trabajo y contacto de la empresa contratista (nombre, teléfonos y correos).
--      El resto del contratista reutiliza columnas existentes: Empresa_Visitante = empresa
--      contratista, Motivo_Detalle = actividades, Fecha_Hora_Prevista = fecha y hora del servicio,
--      y las zonas = área donde se ejecuta el trabajo.
--   2. Catalogo_Sede.Aplica_Cochera: indica en qué sedes se pregunta por la cochera (MAG = 'Y').
--   3. Motivo «Servicio de contratista» (fijo para ese tipo; no se ofrece a los visitantes).
--   4. Zona de las oficinas de Magdalena (hasta hoy solo existían zonas de VES).
--   5. Contratista pasa a «Disponible» con el mismo paso de aprobación que el visitante externo.
--      Proveedor sigue NO disponible (se ve, no se puede usar). «Personal interno visitante» se
--      oculta (Activo = 'N') porque por ahora solo se contemplan tres tipos; el administrador
--      puede reactivarlo desde Catálogos.
-- HANA: ALTER TABLE ... ADD ("col" tipo ...); las restricciones CHECK se agregan con ALTER TABLE ... ADD CONSTRAINT.
-- Va en una transacción y se ejecuta UNA vez.
-- =============================================================================

BEGIN;

DO $$
BEGIN
    IF to_regclass('"TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Adjunto"') IS NULL THEN
        RAISE EXCEPTION 'Faltan los scripts 01 a 15.';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'TRIANONSATELITAL_CAF_PRODD' AND table_name = 'CAF_Solicitud' AND column_name = 'Requiere_Cochera') THEN
        RAISE EXCEPTION 'El script 16 ya se ejecutó. No se repite.';
    END IF;
END $$;

-- 1. Sede: dónde aplica la cochera ---------------------------------------------------------
SET search_path TO "CAF_GOVERNANCE";
ALTER TABLE "Catalogo_Sede" ADD COLUMN "Aplica_Cochera" CHAR(1) DEFAULT 'N' NOT NULL;
ALTER TABLE "Catalogo_Sede" ADD CONSTRAINT "CK_Catalogo_Sede_Cochera" CHECK ("Aplica_Cochera" IN ('Y','N'));
UPDATE "Catalogo_Sede" SET "Aplica_Cochera" = 'Y' WHERE "Codigo" = 'MAG';

-- 2. Solicitud: estacionamiento y datos del servicio ------------------------------------------
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";
ALTER TABLE "CAF_Solicitud" ADD COLUMN "Requiere_Cochera"   CHAR(1) DEFAULT 'N' NOT NULL;
ALTER TABLE "CAF_Solicitud" ADD COLUMN "Placa_Vehiculo"     VARCHAR(15);
ALTER TABLE "CAF_Solicitud" ADD COLUMN "Area_Detalle"       VARCHAR(300);
ALTER TABLE "CAF_Solicitud" ADD COLUMN "Contacto_Nombre"    VARCHAR(200);
ALTER TABLE "CAF_Solicitud" ADD COLUMN "Contacto_Telefonos" VARCHAR(100);
ALTER TABLE "CAF_Solicitud" ADD COLUMN "Contacto_Correos"   VARCHAR(500);
ALTER TABLE "CAF_Solicitud" ADD CONSTRAINT "CK_CAF_Solicitud_Cochera"
    CHECK ("Requiere_Cochera" IN ('Y','N') AND ("Requiere_Cochera" = 'Y' OR "Placa_Vehiculo" IS NULL));

-- 3. Motivo fijo del contratista ----------------------------------------------------------------
INSERT INTO "Catalogo_Motivo_Visita" ("Codigo","Descripcion","Es_Otro","Orden","UsuarioID_Create")
VALUES ('SERVICIO_CONTRATISTA','Servicio o trabajo de contratista','N',90,0);

-- 4. Zona de las oficinas de Magdalena ---------------------------------------------------------
INSERT INTO "Catalogo_Zona_Acceso" ("ID_Catalogo_Sede","Codigo","Descripcion","Tipo_Zona","Exige_SCTR","Exige_EPP","Orden","UsuarioID_Create")
SELECT s."ID_Catalogo_Sede", 'OFICINAS_ADM', 'Oficinas administrativas', 'ADMINISTRATIVA', 'N', 'N', 1, 0
  FROM "CAF_GOVERNANCE"."Catalogo_Sede" s WHERE s."Codigo" = 'MAG';

-- 5. Tipos de ingreso ----------------------------------------------------------------------------
UPDATE "Catalogo_Tipo_Acceso" SET "Disponible" = 'Y', "UpdateDate" = CURRENT_TIMESTAMP, "UsuarioID_Update" = 0 WHERE "Codigo" = 'CONTRATISTA';
UPDATE "Catalogo_Tipo_Acceso" SET "Activo" = 'N', "UpdateDate" = CURRENT_TIMESTAMP, "UsuarioID_Update" = 0 WHERE "Codigo" = 'INTERNO_VISITANTE';

INSERT INTO "Tipo_Acceso_Paso_Aprobacion"
  ("ID_Catalogo_Tipo_Acceso","Orden","Codigo","Descripcion","Alcance","Tipo_Aprobador","ID_Catalogo_Licencia","Condicion","Obligatorio","UsuarioID_Create")
SELECT t."ID_Catalogo_Tipo_Acceso", 1, 'AUTORIZACION', 'Autorización del Coordinador de Control de Activos y SST',
       'PERSONA', 'ROL', l."ID_Catalogo_Licencia", 'SIEMPRE', 'Y', 0
  FROM "Catalogo_Tipo_Acceso" t, "CAF_GOVERNANCE"."Catalogo_Licencia" l
 WHERE t."Codigo" = 'CONTRATISTA' AND l."Codigo" = 'LIC_CAF_COORDINADOR';

COMMIT;
