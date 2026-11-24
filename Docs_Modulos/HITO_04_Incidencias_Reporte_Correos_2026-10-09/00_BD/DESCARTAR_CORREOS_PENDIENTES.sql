-- =============================================================================
-- D-271. Descarta los avisos automáticos que quedaron en la cola (por ejemplo, los que generaron los datos DEMO) para que no se envíen
-- cuando se active el envío automático. NO toca los reenvíos manuales ni lo ya enviado. No se borra nada: quedan en estado ERROR con el motivo.
-- Se puede ejecutar las veces que haga falta.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

UPDATE "CAF_Correo_Pendiente"
   SET "Estado" = 'ERROR', "Ultimo_Error" = 'Descartado a mano (D-271): no se envía.', "UpdateDate" = CURRENT_TIMESTAMP
 WHERE "Eliminado" = 'N' AND "Estado" = 'PENDIENTE' AND "Tipo" <> 'SOLICITUD_REENVIO';

SELECT "Estado", COUNT(*) AS "Correos" FROM "CAF_Correo_Pendiente" WHERE "Eliminado" = 'N' GROUP BY "Estado" ORDER BY 1;
