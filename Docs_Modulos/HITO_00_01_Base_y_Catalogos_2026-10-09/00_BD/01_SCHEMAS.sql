-- =============================================================================
-- Archivo : 01_SCHEMAS.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Hito    : 0 - Base | Fase 0 - DDL
-- Versión : V1.0 2026-10-09
-- Estado  : CANDIDATO - probado en PostgreSQL 16; pendiente de traducción a HANA
-- Motor   : PostgreSQL >= 14
-- =============================================================================
-- Dos schemas, imitando la separación del ecosistema Trianon:
--   CAF_GOVERNANCE              -> lo TRANSVERSAL (usuarios, licencias, sedes,
--                                      áreas, cargos, tipos de documento, personal).
--                                      En una integración se reemplaza por
--                                      TRIANONSATELITAL_GOVERNANCE.
--   TRIANONSATELITAL_CAF_PRODD  -> lo PROPIO del módulo (catálogos y tablas CAF_*).
--                                      En una integración se muda tal cual.
--
-- HANA: CREATE SCHEMA "X"; (no admite IF NOT EXISTS: ejecutar una sola vez).
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS "CAF_GOVERNANCE";
CREATE SCHEMA IF NOT EXISTS "TRIANONSATELITAL_CAF_PRODD";

COMMENT ON SCHEMA "CAF_GOVERNANCE" IS
  'Transversal local del piloto: identidad, licencias y catálogos compartidos. Se reemplaza por TRIANONSATELITAL_GOVERNANCE al integrar.';
COMMENT ON SCHEMA "TRIANONSATELITAL_CAF_PRODD" IS
  'Módulo Control de Accesos: catálogos propios y tablas transaccionales CAF_*.';
