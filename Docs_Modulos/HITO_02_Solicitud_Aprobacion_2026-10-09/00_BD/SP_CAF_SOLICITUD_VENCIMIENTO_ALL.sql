-- =============================================================================
-- SP_CAF_SOLICITUD_VENCIMIENTO_ALL.sql   (2026-11-19, D-251)  Entrega 2C-3a: solicitudes VENCIDAS
--   Una solicitud que nadie aprobó ni rechazó (PENDIENTE u OBSERVADA) vence cuando termina el plazo:
--     * Plazo normal : el último día de la visita ya terminó (día operativo = fecha de «ahora − hora de corte»).
--                      Visita de un día = su fecha; visita por franja (varios días) = el ÚLTIMO día de la franja.
--     * Anticipación : si SOLICITUD_HORAS_ANTICIPACION_APROBAR = N > 0, también vence cuando faltan menos de N horas para la hora prevista.
--   Contenido: 1 FN_SOLICITUD_FIN_DIA   2 FN_SOLICITUD_FUERA_DE_PLAZO   3 FN_SOLICITUD_DIAS_ATRASO   4 FN_SOLICITUD_FRANJA_SIN_APROBAR
--              4-bis FN_SOLICITUD_FT_VISIBLE   5 ERP_CAF_SOLICITUD_VENCER (la llama el servicio en segundo plano y, de red de seguridad, los listados)
--   HANA: sin sobrecargas; CAST(x AS INTERVAL) -> ADD_SECONDS; resta de fechas -> DAYS_BETWEEN (T-53).
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- 1. Último día de la visita: último día de la franja o, si no es de franja, su fecha única.
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_SOLICITUD_FIN_DIA"("HV_ID_Solicitud" BIGINT)
RETURNS DATE
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_f DATE;
BEGIN
    -- V1.0 2026-11-19 (D-251)
    SELECT COALESCE((SELECT MAX(D."Fecha") FROM "CAF_Solicitud_Dia" D WHERE D."ID_Solicitud" = S."ID_Solicitud" AND D."Eliminado" = 'N'),
                    CAST(S."Fecha_Hora_Prevista" AS DATE))
      INTO lv_f FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud";
    RETURN lv_f;
END;
$$;

-- 2. 'Y' si ya se acabó el plazo para decidir la solicitud (por fin de día o por anticipación mínima).
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"("HV_ID_Solicitud" BIGINT)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_corte VARCHAR := COALESCE("ERP_CAF_PARAMETRO_VALOR"('SOLICITUD_HORA_CORTE_VENCIMIENTO'), '00:00');
    lv_horas INT      := CASE WHEN COALESCE("ERP_CAF_PARAMETRO_VALOR"('SOLICITUD_HORAS_ANTICIPACION_APROBAR'), '0') ~ '^[0-9]{1,3}$'
                               THEN CAST("ERP_CAF_PARAMETRO_VALOR"('SOLICITUD_HORAS_ANTICIPACION_APROBAR') AS INT) ELSE 0 END;
    lv_dia   DATE     := CAST(CAST(CURRENT_TIMESTAMP AS TIMESTAMP) - CAST(lv_corte AS INTERVAL) AS DATE);
    lv_fin   DATE;
    lv_ini   TIMESTAMP;
BEGIN
    -- V1.0 2026-11-19 (D-251)
    SELECT S."Fecha_Hora_Prevista" INTO lv_ini FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud";
    IF lv_ini IS NULL THEN RETURN 'N'; END IF;
    lv_fin := "ERP_CAF_FN_SOLICITUD_FIN_DIA"("HV_ID_Solicitud");
    IF lv_fin < lv_dia THEN RETURN 'Y'; END IF;
    IF lv_horas > 0 AND CAST(CURRENT_TIMESTAMP AS TIMESTAMP) > lv_ini - CAST(lv_horas || ' hours' AS INTERVAL) THEN RETURN 'Y'; END IF;
    RETURN 'N';
END;
$$;

-- 3. Días de atraso: cuántos días pasaron desde el último día de la visita (0 si aún está dentro de plazo o venció por anticipación).
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_SOLICITUD_DIAS_ATRASO"("HV_ID_Solicitud" BIGINT)
RETURNS INT
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_corte VARCHAR := COALESCE("ERP_CAF_PARAMETRO_VALOR"('SOLICITUD_HORA_CORTE_VENCIMIENTO'), '00:00');
    lv_dia   DATE     := CAST(CAST(CURRENT_TIMESTAMP AS TIMESTAMP) - CAST(lv_corte AS INTERVAL) AS DATE);
    lv_fin   DATE;
BEGIN
    -- V1.0 2026-11-19 (D-251)
    lv_fin := "ERP_CAF_FN_SOLICITUD_FIN_DIA"("HV_ID_Solicitud");
    IF lv_fin IS NULL THEN RETURN 0; END IF;
    RETURN GREATEST(0, CAST(lv_dia - lv_fin AS INT));
END;
$$;

-- 4. Franja en curso sin aprobar: solicitud de varios días que sigue PENDIENTE u OBSERVADA con la franja ya iniciada y dentro de plazo.
--    Devuelve los días transcurridos desde su primer día (0 = no aplica).
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_SOLICITUD_FRANJA_SIN_APROBAR"("HV_ID_Solicitud" BIGINT)
RETURNS INT
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_est VARCHAR(20);
    lv_ini DATE;
    lv_n   INT := 0;
BEGIN
    -- V1.0 2026-11-19 (D-251)
    SELECT S."Estado" INTO lv_est FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
    IF lv_est IS NULL OR lv_est NOT IN ('PENDIENTE','OBSERVADA') THEN RETURN 0; END IF;
    SELECT MIN(D."Fecha"), COUNT(*) INTO lv_ini, lv_n FROM "CAF_Solicitud_Dia" D WHERE D."ID_Solicitud" = "HV_ID_Solicitud" AND D."Eliminado" = 'N';
    IF lv_n < 2 OR lv_ini IS NULL OR lv_ini >= CURRENT_DATE THEN RETURN 0; END IF;
    IF "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"("HV_ID_Solicitud") = 'Y' THEN RETURN 0; END IF;
    RETURN CAST(CURRENT_DATE - lv_ini AS INT);
END;
$$;

-- 4-bis. «Fuera de tiempo» visible: 'Y' si el usuario puede ver todas las solicitudes de la sede, o si puede aprobar en ella y su rol
--        decide algún paso activo del tipo de la solicitud (es decir, era a él a quien le tocaba decidirla).
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_SOLICITUD_FT_VISIBLE"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede BIGINT;
    lv_tipo BIGINT;
    lv_n    INT := 0;
BEGIN
    -- V1.0 2026-11-19 (D-251)
    SELECT S."ID_Catalogo_Sede", S."ID_Catalogo_Tipo_Acceso" INTO lv_sede, lv_tipo
      FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
    IF lv_sede IS NULL THEN RETURN 'N'; END IF;
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_VER_TODAS', lv_sede) = 'Y' THEN RETURN 'Y'; END IF;
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_APROBAR', lv_sede) <> 'Y' THEN RETURN 'N'; END IF;
    SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion" PA
     WHERE PA."ID_Catalogo_Tipo_Acceso" = lv_tipo AND PA."Eliminado" = 'N' AND PA."Activo" = 'Y' AND PA."ID_Catalogo_Licencia" IS NOT NULL
       AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", PA."ID_Catalogo_Licencia", lv_sede) = 'Y';
    RETURN CASE WHEN lv_n > 0 THEN 'Y' ELSE 'N' END;
END;
$$;

-- 5. ERP_CAF_SOLICITUD_VENCER
--    Pasa a VENCIDA toda solicitud PENDIENTE u OBSERVADA fuera de plazo y deja constancia en el historial (usuario 0 = sistema).
--    Idempotente y barato; no toca las solicitudes con alguna persona aprobada (APROBADA_PARCIAL sigue como está).
--    La llama el servicio en segundo plano cada minuto y, de red de seguridad, Mis solicitudes, la bandeja y los contadores.
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_VENCER"(
    IN    "HV_UsuarioID"   BIGINT,
    INOUT "HV_Vencidas"    INT DEFAULT NULL,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje"     VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-19 (D-251)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_VENCER';
    "HV_Vencidas"    := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        CREATE TEMP TABLE IF NOT EXISTS "tmp_vencer" ("ID_Solicitud" BIGINT, "Anterior" VARCHAR(20)) ON COMMIT DROP;
        DELETE FROM "tmp_vencer";
        INSERT INTO "tmp_vencer" ("ID_Solicitud", "Anterior")
        SELECT S."ID_Solicitud", S."Estado"
          FROM "CAF_Solicitud" S
         WHERE S."Eliminado" = 'N' AND S."Estado" IN ('PENDIENTE','OBSERVADA')
           AND "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(S."ID_Solicitud") = 'Y';
        SELECT CAST(COUNT(*) AS INT) INTO "HV_Vencidas" FROM "tmp_vencer";
        IF "HV_Vencidas" > 0 THEN
            UPDATE "CAF_Solicitud" S SET "Estado" = 'VENCIDA', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE S."ID_Solicitud" IN (SELECT T."ID_Solicitud" FROM "tmp_vencer" T);
            INSERT INTO "CAF_Evento" ("Entidad","ID_Entidad","ID_Solicitud","Accion","Detalle","ID_Usuario","UsuarioID_Create")
            SELECT 'SOLICITUD', T."ID_Solicitud", T."ID_Solicitud", 'VENCER',
                   'Venció sin decisión (estaba ' || T."Anterior" || ').', "HV_UsuarioID", "HV_UsuarioID"
              FROM "tmp_vencer" T;
        END IF;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Solicitudes vencidas: ' || "HV_Vencidas" || '.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_VENCER';
    END;
END;
$$;
-- Prueba: CALL "ERP_CAF_SOLICITUD_VENCER"(0, NULL, NULL, NULL);
