-- =============================================================================
-- SP_CAF_SOLICITUD_REABRIR_ALL.sql   (2026-11-27, D-259)  Entrega 2C-3i
--   1 ERP_CAF_SOLICITUD_VENCIMIENTO_SIMULAR : cuenta (sin cambiar nada) qué solicitudes pendientes u observadas pasarían a
--                                             VENCIDA si se guardan estas horas de anticipación / esta hora de corte.
--   2 ERP_CAF_SOLICITUD_REABRIR             : devuelve una VENCIDA al estado en que estaba (lo toma del evento VENCER).
--   Reglas de REABRIR: quien puede ver «Fuera de tiempo» (FN_SOLICITUD_FT_VISIBLE); motivo obligatorio; solo si todavía está
--   dentro de su último día de visita; y no si, con los parámetros de hoy, volvería a vencer enseguida.
--   HANA: sin sobrecargas; CAST(x AS INTERVAL) -> ADD_SECONDS; resta de fechas -> DAYS_BETWEEN (T-53).
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

DROP FUNCTION IF EXISTS "ERP_CAF_SOLICITUD_VENCIMIENTO_SIMULAR"(INT, VARCHAR);
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_VENCIMIENTO_SIMULAR"("HV_Horas" INT, "HV_Corte" VARCHAR DEFAULT NULL)
RETURNS TABLE ("ID_Solicitud" BIGINT, "Codigo" VARCHAR, "Fecha_Hora_Prevista" TIMESTAMP, "Estado" VARCHAR, "Empresa_Visitante" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_corte VARCHAR := COALESCE(NULLIF(TRIM("HV_Corte"), ''), COALESCE("ERP_CAF_PARAMETRO_VALOR"('SOLICITUD_HORA_CORTE_VENCIMIENTO'), '00:00'));
    lv_horas INT      := GREATEST(0, COALESCE("HV_Horas", 0));
    lv_dia   DATE;
BEGIN
    -- V1.0 2026-11-27 (D-259)
    IF lv_corte !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' THEN lv_corte := '00:00'; END IF;
    lv_dia := CAST(CAST(CURRENT_TIMESTAMP AS TIMESTAMP) - CAST(lv_corte AS INTERVAL) AS DATE);
    RETURN QUERY
    SELECT S."ID_Solicitud", S."Codigo", S."Fecha_Hora_Prevista", S."Estado", S."Empresa_Visitante"
      FROM "CAF_Solicitud" S
     WHERE S."Eliminado" = 'N' AND S."Estado" IN ('PENDIENTE','OBSERVADA') AND S."Fecha_Hora_Prevista" IS NOT NULL
       AND "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(S."ID_Solicitud") = 'N'                       -- hoy siguen en plazo...
       AND ( "ERP_CAF_FN_SOLICITUD_FIN_DIA"(S."ID_Solicitud") < lv_dia                          -- ...y con el valor nuevo dejarían de estarlo
             OR (lv_horas > 0 AND CAST(CURRENT_TIMESTAMP AS TIMESTAMP) > S."Fecha_Hora_Prevista" - CAST(lv_horas || ' hours' AS INTERVAL)) )
     ORDER BY S."Fecha_Hora_Prevista";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SOLICITUD_VENCIMIENTO_SIMULAR"(24, NULL);

CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_REABRIR"(
    IN    "HV_ID_Solicitud" BIGINT,
    IN    "HV_Motivo"       VARCHAR(250),
    IN    "HV_UsuarioID"    BIGINT,
    INOUT "HV_Estado"       VARCHAR(20) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"  INT DEFAULT NULL,
    INOUT "HV_Mensaje"      VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_est   VARCHAR(20);
    lv_ant   VARCHAR(20);
    lv_det   VARCHAR(2000);
    lv_mot   VARCHAR(250) := NULLIF(TRIM(COALESCE("HV_Motivo", '')), '');
BEGIN
    -- V1.0 2026-11-27 (D-259)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_REABRIR';
    "HV_Estado"      := NULL;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <= 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        IF lv_mot IS NULL THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Escriba el motivo para reabrir la solicitud.'; RETURN; END IF;
        SELECT S."Estado" INTO lv_est FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_est IS NULL THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN; END IF;
        IF "ERP_CAF_FN_SOLICITUD_FT_VISIBLE"("HV_UsuarioID", "HV_ID_Solicitud") <> 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'No tiene permiso para reabrir esta solicitud.'; RETURN;
        END IF;
        IF lv_est <> 'VENCIDA' THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Solo se reabren solicitudes vencidas (está ' || lv_est || ').'; RETURN; END IF;
        IF "ERP_CAF_FN_SOLICITUD_DIAS_ATRASO"("HV_ID_Solicitud") > 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Ya pasó su último día de visita. Use «Reutilizar» con una fecha nueva.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"("HV_ID_Solicitud") = 'Y' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'Con la configuración actual (horas de anticipación) volvería a vencer. Desactive primero la anticipación.'; RETURN;
        END IF;
        SELECT CASE WHEN E."Detalle" LIKE '%estaba OBSERVADA%' THEN 'OBSERVADA' ELSE 'PENDIENTE' END INTO lv_ant
          FROM "CAF_Evento" E WHERE E."ID_Solicitud" = "HV_ID_Solicitud" AND E."Accion" = 'VENCER'
         ORDER BY E."ID_Evento" DESC LIMIT 1;
        lv_ant := COALESCE(lv_ant, 'PENDIENTE');
        UPDATE "CAF_Solicitud" SET "Estado" = lv_ant, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        lv_det := 'Reabierta a ' || lv_ant || '. Motivo: ' || lv_mot;
        INSERT INTO "CAF_Evento" ("Entidad","ID_Entidad","ID_Solicitud","Accion","Detalle","ID_Usuario","UsuarioID_Create")
        VALUES ('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'REABRIR', lv_det, "HV_UsuarioID", "HV_UsuarioID");
        "HV_Estado" := lv_ant; "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Solicitud reabierta: vuelve a ' || lv_ant || '.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SOLICITUD_REABRIR';
    END;
END;
$$;
-- Prueba: CALL "ERP_CAF_SOLICITUD_REABRIR"(1, 'Visita confirmada por teléfono', 1, NULL, NULL, NULL);
