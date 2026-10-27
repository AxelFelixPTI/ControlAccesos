-- =============================================================================
-- 12_ALTER_INCIDENCIA_COORD_CONFIRMADA.sql   (D-165, 2026-10-26)
-- Las incidencias que registra el Coordinador ahora nacen CONFIRMADAS. Este script
-- confirma las que quedaron «Registrada» antes del cambio. Se puede ejecutar varias veces.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

UPDATE "CAF_Incidencia"
   SET "Estado" = 'CONFIRMADA',
       "ID_Usuario_Decision" = "ID_Usuario_Registro",
       "Fecha_Decision" = COALESCE("Fecha_Decision", "CreateDate"),
       "Sustento_Decision" = 'Registrada por el Coordinador: confirmada directamente.',
       "UpdateDate" = CURRENT_TIMESTAMP
 WHERE "Origen" = 'COORDINADOR' AND "Estado" = 'REGISTRADA' AND "Eliminado" = 'N';
