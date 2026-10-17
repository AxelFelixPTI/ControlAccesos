-- =============================================================================
-- Archivo : SP_CAF_SOLICITUD_DECISION_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobación | Fase 1 - Procedimientos (escritura)
-- Entidad : CAF_Solicitud_Decision (el «sello» de un aprobador sobre una persona)
-- Versión : V1.0 2026-10-16
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO2_ESCRITURA.sql)
-- Requiere: scripts 01 a 10 y SP_CAF_SOLICITUD_BASE_ALL.sql cargado antes.
-- =============================================================================
-- 1 ERP_CAF_SOLICITUD_DECIDIR
--
-- Un aprobador decide UN paso del flujo sobre una o varias personas:
--   APROBADA  ... el paso queda cumplido para esas personas
--   OBSERVADA ... hay algo que el solicitante puede corregir (texto obligatorio)
--   RECHAZADA ... decisión cerrada, sin nada que corregir (motivo obligatorio)
--
-- REGLAS QUE VERIFICA (RNF-05, en el servidor y no solo en la pantalla):
--   * Quien decide debe tener el permiso PER_CAF_SOLICITUD_APROBAR en la sede Y
--     el rol al que le toca ese paso. «Aprobar» lo tienen varios roles; el paso
--     dice a CUÁL le toca.
--   * Solo se decide sobre personas PENDIENTES que aún no tienen decisión en ese paso.
--   * Un paso no se decide antes que los anteriores: si el flujo tiene el orden
--     1 y el 2, la persona debe tener aprobado el 1 para decidir el 2.
--   * Paso POR PERSONA: HV_IDs_Solicitud_Persona dice sobre quiénes.
--     Paso POR SOLICITUD: vale para todas las pendientes; la lista se ignora.
--   * No se decide sobre una solicitud cancelada ni de una fecha pasada.
--
-- Todo es atómico: o se registran las decisiones de TODAS las personas, o ninguna.
-- Después de decidir se recalcula la aprobación y el estado (D-44), se guarda la
-- foto de lo aprobado (RN-08), se escribe la bitácora y se avisa por correo.
-- CONCURRENCIA: cada operación toma primero un bloqueo sobre la fila de la
-- solicitud (un UPDATE que no cambia nada). Si dos personas deciden a la vez, la
-- segunda espera a que termine la primera y entonces ve el resultado ya registrado
-- (por ejemplo «ya tiene decisión en este paso»). No existe un índice único para
-- «una sola decisión vigente por persona y paso» porque HANA no admite índices parciales.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_DECIDIR"(
    IN    "HV_ID_Solicitud"                   BIGINT,
    IN    "HV_ID_Tipo_Acceso_Paso_Aprobacion" BIGINT,
    IN    "HV_Decision"                       VARCHAR(20),
    IN    "HV_Mensaje_Decision"               VARCHAR(2000),
    IN    "HV_IDs_Solicitud_Persona"          VARCHAR(2000),
    IN    "HV_UsuarioID"                      BIGINT,
    INOUT "HV_Cantidad_Result"                BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"                    INT DEFAULT NULL,
    INOUT "HV_Mensaje"                        VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n        INT := 0;
    lv_sede     BIGINT;
    lv_tipo     BIGINT;
    lv_estado   VARCHAR(20);
    lv_fecha    TIMESTAMP;
    lv_codsol   VARCHAR(20);
    lv_solic    BIGINT;
    lv_p_tipo   BIGINT;
    lv_alcance  VARCHAR(20);
    lv_orden    BIGINT;
    lv_lic      BIGINT;
    lv_codpaso  VARCHAR(50);
    lv_ids      VARCHAR(4000);
    lv_lista    VARCHAR(4100);
    lv_cnt      INT := 0;
    lv_tokens   INT := 0;
    lv_viol     INT := 0;
    lv_acc      VARCHAR(20);
    lv_c        INT;
    lv_m        VARCHAR(250);
    lv_est2     VARCHAR(20);
    lv_nombres  VARCHAR(2000);
    lv_dest     VARCHAR(2000);
    lv_pend     INT := 0;
    lv_texto    VARCHAR(500);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DECIDIR';
    "HV_Cantidad_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "HV_Decision" IS NULL OR "HV_Decision" NOT IN ('APROBADA','OBSERVADA','RECHAZADA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La decisión debe ser APROBADA, OBSERVADA o RECHAZADA.'; RETURN;
        END IF;
        IF "HV_Decision" <> 'APROBADA' AND ("HV_Mensaje_Decision" IS NULL OR LENGTH(TRIM("HV_Mensaje_Decision")) = 0) THEN
            "HV_Codigo_Resp" := 400;
            "HV_Mensaje" := CASE WHEN "HV_Decision" = 'OBSERVADA' THEN 'Escriba qué debe corregir el solicitante.' ELSE 'Escriba el motivo del rechazo.' END;
            RETURN;
        END IF;

        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo"), MAX("ID_Usuario_Solicitante")
          INTO lv_n, lv_sede, lv_tipo, lv_estado, lv_fecha, lv_codsol, lv_solic
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("ID_Catalogo_Tipo_Acceso"), MAX("Alcance"), MAX("Orden"), MAX("ID_Catalogo_Licencia"), MAX("Codigo")
          INTO lv_n, lv_p_tipo, lv_alcance, lv_orden, lv_lic, lv_codpaso
          FROM "Tipo_Acceso_Paso_Aprobacion"
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 OR lv_p_tipo <> lv_tipo THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El paso no existe, está inactivo o no corresponde al tipo de acceso de esta solicitud.'; RETURN;
        END IF;

        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_APROBAR', lv_sede) <> 'Y'
           OR "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", lv_lic, lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No le corresponde decidir este paso de la solicitud.'; RETURN;
        END IF;

        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;

        -- A quiénes se decide
        IF lv_alcance = 'PERSONA' THEN
            lv_ids := REPLACE(REPLACE(COALESCE("HV_IDs_Solicitud_Persona", ''), ' ', ''), ';', ',');
            lv_tokens := CASE WHEN LENGTH(lv_ids) = 0 THEN 0 ELSE LENGTH(lv_ids) - LENGTH(REPLACE(lv_ids, ',', '')) + 1 END;
            IF lv_tokens = 0 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Elija al menos una persona.'; RETURN;
            END IF;
            lv_lista := ',' || lv_ids || ',';
            SELECT COUNT(*) INTO lv_cnt FROM "CAF_Solicitud_Persona" P
             WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'PENDIENTE' AND P."Estado" = 'ESPERADA'
               AND lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';
            IF lv_cnt <> lv_tokens THEN
                "HV_Codigo_Resp" := 409;
                "HV_Mensaje" := 'Alguna persona no está en la solicitud, está repetida o ya no está pendiente.'; RETURN;
            END IF;
        ELSE
            -- Paso por solicitud: todas las pendientes que aún no tienen decisión en ese paso
            SELECT STRING_AGG(CAST(P."ID_Solicitud_Persona" AS VARCHAR), ',' ORDER BY P."ID_Solicitud_Persona"), COUNT(*)
              INTO lv_ids, lv_cnt
              FROM "CAF_Solicitud_Persona" P
             WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'PENDIENTE' AND P."Estado" = 'ESPERADA'
               AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                                WHERE D."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                                  AND D."ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion"
                                  AND D."Vigente" = 'Y' AND D."Eliminado" = 'N');
            IF lv_cnt = 0 THEN
                "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'No hay personas pendientes en este paso.'; RETURN;
            END IF;
            lv_lista := ',' || lv_ids || ',';
        END IF;

        -- Ninguna debe tener ya decisión en este paso
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona" P
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%'
           AND EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                        WHERE D."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                          AND D."ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion"
                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N');
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Alguna persona ya tiene decisión en este paso.'; RETURN;
        END IF;

        -- Los pasos anteriores deben estar aprobados para cada persona
        SELECT COUNT(*) INTO lv_viol FROM "CAF_Solicitud_Persona" P
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%'
           AND EXISTS (SELECT 1 FROM "Tipo_Acceso_Paso_Aprobacion" L
                        WHERE L."ID_Catalogo_Tipo_Acceso" = lv_tipo AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
                          AND L."Obligatorio" = 'Y' AND L."Orden" < lv_orden
                          AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D2
                                           WHERE D2."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                                             AND D2."ID_Tipo_Acceso_Paso_Aprobacion" = L."ID_Tipo_Acceso_Paso_Aprobacion"
                                             AND D2."Vigente" = 'Y' AND D2."Eliminado" = 'N' AND D2."Decision" = 'APROBADA'));
        IF lv_viol > 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Falta aprobar un paso anterior para alguna de las personas.'; RETURN;
        END IF;

        -- Se registran las decisiones
        INSERT INTO "CAF_Solicitud_Decision"
               ("ID_Solicitud_Persona","ID_Tipo_Acceso_Paso_Aprobacion","Decision","Mensaje","ID_Usuario","Fecha_Decision","UsuarioID_Create")
        SELECT P."ID_Solicitud_Persona", "HV_ID_Tipo_Acceso_Paso_Aprobacion", "HV_Decision",
               CASE WHEN "HV_Decision" = 'APROBADA' THEN NULL ELSE TRIM("HV_Mensaje_Decision") END,
               "HV_UsuarioID", CURRENT_TIMESTAMP, "HV_UsuarioID"
          FROM "CAF_Solicitud_Persona" P
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';

        -- Resumen de la última decisión en la cabecera (D-45)
        UPDATE "CAF_Solicitud"
           SET "ID_Usuario_Decision" = "HV_UsuarioID", "Fecha_Decision" = CURRENT_TIMESTAMP,
               "Observacion_Coordinador" = CASE WHEN "HV_Decision" = 'APROBADA' THEN "Observacion_Coordinador" ELSE TRIM("HV_Mensaje_Decision") END,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_SOLICITUD_VERSION_GUARDAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'version: %', lv_m; END IF;

        -- Bitácora
        lv_acc := CASE "HV_Decision" WHEN 'APROBADA' THEN 'APROBAR' WHEN 'OBSERVADA' THEN 'OBSERVAR' ELSE 'RECHAZAR' END;
        SELECT STRING_AGG(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres", '; ' ORDER BY P."ID_Solicitud_Persona")
          INTO lv_nombres
          FROM "CAF_Solicitud_Persona" P JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_DECISION', "HV_ID_Tipo_Acceso_Paso_Aprobacion", "HV_ID_Solicitud", lv_acc,
             'Paso ' || lv_codpaso || ': ' || LEFT(lv_nombres, 1400)
             || CASE WHEN "HV_Decision" = 'APROBADA' THEN '' ELSE ' · ' || TRIM("HV_Mensaje_Decision") END,
             "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        -- Aviso al solicitante con el resumen de lo decidido
        lv_texto := lv_cnt || CASE WHEN lv_cnt = 1 THEN ' persona ' ELSE ' personas ' END
                    || CASE "HV_Decision" WHEN 'APROBADA' THEN 'aprobada(s)' WHEN 'OBSERVADA' THEN 'observada(s)' ELSE 'rechazada(s)' END;
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'SOLICITANTE', NULL, lv_dest, lv_c, lv_m);
        CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_DECISION', "HV_ID_Solicitud", lv_dest, NULL,
             'Decisión sobre ' || lv_codsol || ': ' || lv_texto,
             '<p>Sobre la solicitud ' || lv_codsol || ': ' || lv_texto || '.</p>'
             || CASE WHEN "HV_Decision" = 'APROBADA' THEN '' ELSE '<p>' || TRIM("HV_Mensaje_Decision") || '</p>' END
             || '<p>Estado de la solicitud: ' || lv_est2 || '.</p>',
             "HV_UsuarioID", lv_c, lv_m);

        -- Si aprobó y todavía faltan pasos, se avisa a quienes deciden el siguiente
        IF "HV_Decision" = 'APROBADA' THEN
            SELECT COUNT(*) INTO lv_pend FROM "CAF_Solicitud_Persona"
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'PENDIENTE';
            IF lv_pend > 0 THEN
                CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'SIGUIENTE_PASO', lv_orden, lv_dest, lv_c, lv_m);
                CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', "HV_ID_Solicitud", lv_dest, NULL,
                     'Personas por aprobar en ' || lv_codsol,
                     '<p>La solicitud ' || lv_codsol || ' tiene ' || lv_pend || ' persona(s) esperando el siguiente paso.</p>',
                     "HV_UsuarioID", lv_c, lv_m);
            END IF;
        END IF;

        "HV_Cantidad_Result" := lv_cnt;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Decisión registrada: ' || lv_texto || '. Estado de la solicitud: ' || lv_est2 || '.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DECIDIR';
        "HV_Cantidad_Result" := 0;
    END;
END;
$$;
