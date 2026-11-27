-- =============================================================================
-- RESTAURAR_VENCIDAS_POR_ANTICIPACION.sql   (2026-11-26)   *** SCRIPT DE RECUPERACIÓN, SE CORRE A MANO ***
-- Cuándo: se activó «Horas de anticipación para aprobar» (SOLICITUD_HORAS_ANTICIPACION_APROBAR > 0) y solicitudes que
--         estaban PENDIENTE u OBSERVADA pasaron a VENCIDA por eso, aunque su visita todavía no había terminado.
-- Qué hace: devuelve cada una al estado en que estaba (lo toma del evento VENCER: «estaba PENDIENTE|OBSERVADA») y deja
--           el evento REABRIR en su historial. NO toca las que vencieron de verdad (su último día de visita ya pasó).
-- ANTES: ponga el parámetro «Horas de anticipación para aprobar» en 0 (Catálogos → Parámetros). Si no, el servicio las
--        vuelve a vencer en el minuto siguiente. El script se detiene si el parámetro no está en 0.
-- Uso   : 1) corra primero la PARTE A (vista previa) y revise la lista.  2) corra la PARTE B para restaurar.
--         Cambie la fecha de «v_desde» si el momento en que se activó el parámetro no fue hoy.
-- Idempotente: una solicitud ya restaurada no vuelve a aparecer (ya no está VENCIDA).
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD", "CAF_GOVERNANCE";

-- ─────────────────────────── PARTE A · VISTA PREVIA (no cambia nada) ───────────────────────────
SELECT S."Codigo", S."Fecha_Hora_Prevista", S."Estado" AS estado_actual,
       CASE WHEN E."Detalle" LIKE '%estaba OBSERVADA%' THEN 'OBSERVADA' ELSE 'PENDIENTE' END AS volvera_a,
       E."CreateDate" AS vencio_el
  FROM "CAF_Solicitud" S
  JOIN "CAF_Evento" E ON E."ID_Solicitud" = S."ID_Solicitud" AND E."Accion" = 'VENCER'
 WHERE S."Estado" = 'VENCIDA' AND S."Eliminado" = 'N'
   AND E."CreateDate" >= CURRENT_DATE                                   -- ← «v_desde»: desde cuándo se activó
   AND "ERP_CAF_FN_SOLICITUD_FIN_DIA"(S."ID_Solicitud") >= CAST(CAST(CURRENT_TIMESTAMP AS TIMESTAMP)
         - CAST(COALESCE("ERP_CAF_PARAMETRO_VALOR"('SOLICITUD_HORA_CORTE_VENCIMIENTO'), '00:00') AS INTERVAL) AS DATE)
 ORDER BY S."Fecha_Hora_Prevista";

-- ─────────────────────────── PARTE B · RESTAURAR ───────────────────────────
DO $$
DECLARE
    v_desde TIMESTAMP := CURRENT_DATE;                                  -- ← cámbiela si hace falta
    v_n INT;
BEGIN
    IF COALESCE("ERP_CAF_PARAMETRO_VALOR"('SOLICITUD_HORAS_ANTICIPACION_APROBAR'), '0') <> '0' THEN
        RAISE EXCEPTION 'Ponga primero «Horas de anticipación para aprobar» en 0 (Catálogos → Parámetros) y vuelva a correr esto.';
    END IF;
    CREATE TEMP TABLE IF NOT EXISTS "tmp_reabrir" ("ID_Solicitud" BIGINT, "Anterior" VARCHAR(20)) ON COMMIT DROP;
    DELETE FROM "tmp_reabrir";
    INSERT INTO "tmp_reabrir"
    SELECT S."ID_Solicitud", CASE WHEN E."Detalle" LIKE '%estaba OBSERVADA%' THEN 'OBSERVADA' ELSE 'PENDIENTE' END
      FROM "CAF_Solicitud" S
      JOIN "CAF_Evento" E ON E."ID_Solicitud" = S."ID_Solicitud" AND E."Accion" = 'VENCER'
     WHERE S."Estado" = 'VENCIDA' AND S."Eliminado" = 'N' AND E."CreateDate" >= v_desde
       AND "ERP_CAF_FN_SOLICITUD_FIN_DIA"(S."ID_Solicitud") >= CAST(CAST(CURRENT_TIMESTAMP AS TIMESTAMP)
             - CAST(COALESCE("ERP_CAF_PARAMETRO_VALOR"('SOLICITUD_HORA_CORTE_VENCIMIENTO'), '00:00') AS INTERVAL) AS DATE);
    SELECT CAST(COUNT(*) AS INT) INTO v_n FROM "tmp_reabrir";

    UPDATE "CAF_Solicitud" S SET "Estado" = T."Anterior", "UsuarioID_Update" = 0, "UpdateDate" = CURRENT_TIMESTAMP
      FROM "tmp_reabrir" T WHERE S."ID_Solicitud" = T."ID_Solicitud";
    INSERT INTO "CAF_Evento" ("Entidad","ID_Entidad","ID_Solicitud","Accion","Detalle","ID_Usuario","UsuarioID_Create")
    SELECT 'SOLICITUD', T."ID_Solicitud", T."ID_Solicitud", 'REABRIR',
           'Restaurada a ' || T."Anterior" || ': había vencido por «Horas de anticipación para aprobar».', 0, 0
      FROM "tmp_reabrir" T;
    RAISE NOTICE 'Solicitudes restauradas: %', v_n;
END $$;
