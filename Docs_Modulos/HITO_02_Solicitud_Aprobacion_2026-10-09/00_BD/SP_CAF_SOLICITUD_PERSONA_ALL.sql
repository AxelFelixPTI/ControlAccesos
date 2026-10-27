-- =============================================================================
-- Archivo : SP_CAF_SOLICITUD_PERSONA_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobación | Fase 1 - Procedimientos (escritura)
-- Entidad : CAF_Solicitud_Persona (cada visitante dentro de una solicitud)
-- Versión : V1.1 2026-10-27 (D-169: correcciones de emergencia)
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO2_ESCRITURA.sql)
-- Requiere: scripts 01 a 10 y SP_CAF_SOLICITUD_BASE_ALL.sql cargado antes.
-- =============================================================================
-- Reglas por estado de la persona (las tres reglas acordadas):
--   Pendiente ... se edita sin trámite y se puede retirar
--   Observada ... se corrige y se reenvía (vuelve a Pendiente); se puede retirar
--   Aprobada .... NO se edita; se puede retirar si aún no ingresó
--   Rechazada ... cerrada: no hay nada que corregir
--   Retirada .... se puede volver a agregar: se reactiva la MISMA fila
--   Ingresó ..... solo lectura
-- Retirar reduce la autorización y NO necesita aprobación. Agregar siempre nace
-- Pendiente (el solicitante); la única excepción es la CORRECCIÓN DE EMERGENCIA del
-- Coordinador (D-169), que solo existe sobre una solicitud ya aprobada y exige sustento.
--
-- 1 ERP_CAF_SOLICITUD_PERSONA_AGREGAR            el solicitante agrega o reactiva
-- 2 ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA el Coordinador agrega a quien llegó (solicitud ya aprobada)
-- 3 ERP_CAF_SOLICITUD_PERSONA_RETIRAR            el solicitante retira
-- 4 ERP_CAF_SOLICITUD_PERSONA_CORREGIR           corrige y, si estaba observada, reenvía
-- 5 ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA el Coordinador quita a una autorizada que aún no ingresó
--
-- La persona externa ya debe existir en el registro (ERP_CAF_PERSONA_EXTERNA_*).
-- CONCURRENCIA: cada operación toma primero un bloqueo sobre la fila de la
-- solicitud (un UPDATE que no cambia nada). Si dos personas deciden a la vez, la
-- segunda espera a que termine la primera y entonces ve el resultado ya registrado
-- (por ejemplo «ya tiene decisión en este paso»). No existe un índice único para
-- «una sola decisión vigente por persona y paso» porque HANA no admite índices parciales.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_SOLICITUD_PERSONA_AGREGAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(
    IN    "HV_ID_Solicitud"        BIGINT,
    IN    "HV_ID_Persona_Externa"  BIGINT,
    IN    "HV_UsuarioID"           BIGINT,
    INOUT "HV_ID_Solicitud_Persona_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"         INT DEFAULT NULL,
    INOUT "HV_Mensaje"             VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_sede   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_sp     BIGINT;
    lv_apr    VARCHAR(20);
    lv_apr2   VARCHAR(20);
    lv_nom    VARCHAR(400);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
    lv_dest   VARCHAR(2000);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR';
    "HV_ID_Solicitud_Persona_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_owner, lv_estado, lv_fecha, lv_codsol
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para modificarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres")
          INTO lv_n, lv_nom FROM "CAF_Persona_Externa"
         WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La persona no está registrada.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("ID_Solicitud_Persona"), MAX("Aprobacion") INTO lv_n, lv_sp, lv_apr
          FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';

        IF lv_n > 0 AND lv_apr <> 'RETIRADA' THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := CASE WHEN lv_apr = 'RECHAZADA' THEN 'Esa persona figura en la solicitud como rechazada.'
                                 ELSE 'Esa persona ya está en la solicitud.' END;
            RETURN;
        END IF;

        IF lv_n > 0 THEN
            -- Vuelve a agregarse a quien se había retirado: se reactiva la misma fila
            UPDATE "CAF_Solicitud_Persona"
               SET "Aprobacion" = 'PENDIENTE', "Aprobacion_Mensaje" = NULL, "ID_Usuario_Aprobacion" = NULL, "Fecha_Aprobacion" = NULL,
                   "Origen" = 'AGREGADA', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = lv_sp;
        ELSE
            INSERT INTO "CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","Origen","UsuarioID_Create")
            VALUES ("HV_ID_Solicitud", "HV_ID_Persona_Externa", 'PENDIENTE', 'AGREGADA', "HV_UsuarioID")
            RETURNING "ID_Solicitud_Persona" INTO lv_sp;
        END IF;

        CALL "ERP_CAF_SOLICITUD_HEREDAR_PASOS"("HV_ID_Solicitud", lv_sp, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'heredar: %', lv_m; END IF;
        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', lv_sp, "HV_ID_Solicitud", 'AGREGAR',
             lv_nom || CASE WHEN lv_n > 0 THEN ' (volvió a agregarse)' ELSE '' END, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        SELECT "Aprobacion" INTO lv_apr2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = lv_sp;
        IF lv_apr2 = 'PENDIENTE' THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PASO_PENDIENTE', lv_sp, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', "HV_ID_Solicitud", lv_dest, NULL,
                 'Persona por aprobar en ' || lv_codsol,
                 'Se agregó a ' || lv_nom || ' a la solicitud y espera su decisión.', "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_ID_Solicitud_Persona_Result" := lv_sp;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Persona agregada a la solicitud.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR';
        "HV_ID_Solicitud_Persona_Result" := 0;
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA   (D-169, P-98)
--    Reemplaza a ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA. Es una CORRECCIÓN DE
--    EMERGENCIA del Coordinador: la solicitud YA está aprobada (APROBADA o
--    APROBADA_PARCIAL) y llega alguien que no estaba (la llamada por teléfono desde
--    portería, un cambio de último momento). Mientras la solicitud sigue por decidir
--    esta rutina NO vale: ahí se aprueba normalmente, o el solicitante modifica.
--    - Exige SUSTENTO (queda en la bitácora y en el correo).
--    - Solo hasta el día de la visita (no se corrige una visita que ya pasó).
--    - La persona queda aprobada en los pasos POR PERSONA que corresponden a los roles
--      de quien la agrega, respetando el orden de los pasos; los pasos por solicitud ya
--      aprobados se heredan. Si el flujo tiene más pasos de otros roles, queda
--      Pendiente solo en esos.
--    - Avisa por correo al solicitante y a Vigilancia (Para); copia a aprobadores y a
--      los correos adicionales de la solicitud. Vigilancia lo ve al instante porque su
--      lista sale de las personas con Aprobacion = APROBADA.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA"(BIGINT, BIGINT, BIGINT, BIGINT, INT, VARCHAR);

CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(
    IN    "HV_ID_Solicitud"        BIGINT,
    IN    "HV_ID_Persona_Externa"  BIGINT,
    IN    "HV_Sustento"            VARCHAR(2000),
    IN    "HV_UsuarioID"           BIGINT,
    INOUT "HV_ID_Solicitud_Persona_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"         INT DEFAULT NULL,
    INOUT "HV_Mensaje"             VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_sede   BIGINT;
    lv_tipo   BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_sp     BIGINT;
    lv_apr    VARCHAR(20);
    lv_apr2   VARCHAR(20);
    lv_nom    VARCHAR(400);
    lv_quien  VARCHAR(400);
    lv_sus    VARCHAR(2000);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
    lv_dest   VARCHAR(2000);
    lv_dest2  VARCHAR(2000);
BEGIN
    -- V1.1 2026-10-27 (D-169)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA';
    "HV_ID_Solicitud_Persona_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        lv_sus := TRIM(COALESCE("HV_Sustento", ''));
        IF LENGTH(lv_sus) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Escriba el sustento de la corrección de emergencia.'; RETURN;
        END IF;
        IF LENGTH(lv_sus) > 300 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El sustento no puede pasar de 300 caracteres.'; RETURN;
        END IF;
        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_tipo, lv_estado, lv_fecha, lv_codsol
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_APROBAR', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para aprobar en esta sede.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
           AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", S."ID_Catalogo_Licencia", lv_sede) = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Su rol no decide ningún paso de este tipo de acceso.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF lv_estado NOT IN ('APROBADA', 'APROBADA_PARCIAL') THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'La corrección de emergencia solo aplica a una solicitud ya aprobada. Mientras esté por decidir, apruebe u observe a las personas desde la revisión.';
            RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó: la solicitud no se modifica.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres")
          INTO lv_n, lv_nom FROM "CAF_Persona_Externa"
         WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La persona no está registrada.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("ID_Solicitud_Persona"), MAX("Aprobacion") INTO lv_n, lv_sp, lv_apr
          FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';
        IF lv_n > 0 AND lv_apr <> 'RETIRADA' THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := CASE WHEN lv_apr = 'RECHAZADA' THEN 'Esa persona figura en la solicitud como rechazada.'
                                 ELSE 'Esa persona ya está en la solicitud.' END;
            RETURN;
        END IF;

        IF lv_n > 0 THEN
            UPDATE "CAF_Solicitud_Persona"
               SET "Aprobacion" = 'PENDIENTE', "Aprobacion_Mensaje" = NULL, "ID_Usuario_Aprobacion" = NULL, "Fecha_Aprobacion" = NULL,
                   "Origen" = 'AGREGADA_COORDINADOR', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = lv_sp;
        ELSE
            INSERT INTO "CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","Origen","UsuarioID_Create")
            VALUES ("HV_ID_Solicitud", "HV_ID_Persona_Externa", 'PENDIENTE', 'AGREGADA_COORDINADOR', "HV_UsuarioID")
            RETURNING "ID_Solicitud_Persona" INTO lv_sp;
        END IF;

        CALL "ERP_CAF_SOLICITUD_HEREDAR_PASOS"("HV_ID_Solicitud", lv_sp, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'heredar: %', lv_m; END IF;

        -- Aprueba los pasos por persona que le corresponden por rol, sin saltarse el orden
        INSERT INTO "CAF_Solicitud_Decision"
               ("ID_Solicitud_Persona","ID_Tipo_Acceso_Paso_Aprobacion","Decision","Mensaje","ID_Usuario","Fecha_Decision","UsuarioID_Create")
        SELECT lv_sp, S."ID_Tipo_Acceso_Paso_Aprobacion", 'APROBADA', 'Agregada por corrección de emergencia',
               "HV_UsuarioID", CURRENT_TIMESTAMP, "HV_UsuarioID"
          FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Alcance" = 'PERSONA'
           AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", S."ID_Catalogo_Licencia", lv_sede) = 'Y'
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                            WHERE D."ID_Solicitud_Persona" = lv_sp AND D."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                              AND D."Vigente" = 'Y' AND D."Eliminado" = 'N')
           AND NOT EXISTS (SELECT 1 FROM "Tipo_Acceso_Paso_Aprobacion" L
                            WHERE L."ID_Catalogo_Tipo_Acceso" = lv_tipo AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
                              AND L."Obligatorio" = 'Y' AND L."Orden" < S."Orden"
                              AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D2
                                               WHERE D2."ID_Solicitud_Persona" = lv_sp AND D2."ID_Tipo_Acceso_Paso_Aprobacion" = L."ID_Tipo_Acceso_Paso_Aprobacion"
                                                 AND D2."Vigente" = 'Y' AND D2."Eliminado" = 'N' AND D2."Decision" = 'APROBADA')
                              AND NOT (L."Alcance" = 'PERSONA'
                                       AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", L."ID_Catalogo_Licencia", lv_sede) = 'Y'));

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_SOLICITUD_VERSION_GUARDAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'version: %', lv_m; END IF;
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', lv_sp, "HV_ID_Solicitud", 'AGREGAR_EMERGENCIA',
             lv_nom || ' · Emergencia: ' || lv_sus, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        SELECT "Aprobacion" INTO lv_apr2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = lv_sp;
        SELECT U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" INTO lv_quien
          FROM "CAF_GOVERNANCE"."Usuario" U WHERE U."ID_Usuario" = "HV_UsuarioID";

        -- Para: solicitante y Vigilancia. Copia: aprobadores y correos adicionales de la solicitud.
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'SOLICITANTE', NULL, lv_dest, lv_c, lv_m);
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PORTERIA', NULL, lv_dest2, lv_c, lv_m);
        lv_dest := CASE WHEN lv_dest IS NULL THEN lv_dest2 WHEN lv_dest2 IS NULL THEN lv_dest ELSE lv_dest || '; ' || lv_dest2 END;
        CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_CORRECCION', "HV_ID_Solicitud", lv_dest,
             "ERP_CAF_FN_COPIA_CORREO"("HV_ID_Solicitud", 'N', 'Y', 'N', 'Y'),
             'Corrección de emergencia en ' || lv_codsol || ': se agregó a una persona',
             'CORRECCIÓN DE EMERGENCIA' || CHR(10)
             || 'Se agregó a ' || lv_nom || ' a la solicitud ' || lv_codsol
             || CASE WHEN lv_apr2 = 'APROBADA' THEN ' y queda autorizada para ingresar.' ELSE ' y espera la aprobación de otros aprobadores.' END || CHR(10)
             || 'Sustento: ' || lv_sus || CHR(10)
             || 'Registrado por: ' || COALESCE(lv_quien, 'el Coordinador') || '.',
             "HV_UsuarioID", lv_c, lv_m);
        IF lv_apr2 = 'PENDIENTE' THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PASO_PENDIENTE', lv_sp, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', "HV_ID_Solicitud", lv_dest, NULL,
                 'Persona por aprobar en ' || lv_codsol,
                 lv_nom || ' llegó sin estar en la solicitud y espera su decisión.', "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_ID_Solicitud_Persona_Result" := lv_sp;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN lv_apr2 = 'APROBADA' THEN 'Persona agregada y aprobada (corrección de emergencia).'
                                 ELSE 'Persona agregada; faltan pasos de otros aprobadores.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA';
        "HV_ID_Solicitud_Persona_Result" := 0;
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_SOLICITUD_PERSONA_RETIRAR
--    No se borra nada: la persona pasa a RETIRADA y sus decisiones dejan de ser
--    vigentes (si vuelve a agregarse, parte de cero). No se retira a la última
--    persona de la solicitud: en ese caso se cancela la solicitud.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(
    IN    "HV_ID_Solicitud_Persona" BIGINT,
    IN    "HV_UsuarioID"            BIGINT,
    INOUT "HV_Codigo_Resp"          INT DEFAULT NULL,
    INOUT "HV_Mensaje"              VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_sol    BIGINT;
    lv_apr    VARCHAR(20);
    lv_ing    VARCHAR(20);
    lv_ext    BIGINT;
    lv_sede   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_nom    VARCHAR(400);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_RETIRAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud (se toma desde la persona): la segunda operación espera y ve lo ya registrado
        SELECT MAX("ID_Solicitud") INTO lv_sol FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = lv_sol;
        SELECT COUNT(*), MAX("ID_Solicitud"), MAX("Aprobacion"), MAX("Estado"), MAX("ID_Persona_Externa")
          INTO lv_n, lv_sol, lv_apr, lv_ing, lv_ext
          FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no está en la solicitud.'; RETURN;
        END IF;
        SELECT MAX("ID_Catalogo_Sede"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista")
          INTO lv_sede, lv_owner, lv_estado, lv_fecha FROM "CAF_Solicitud" WHERE "ID_Solicitud" = lv_sol;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para modificarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;
        IF lv_apr = 'RETIRADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona ya está retirada.'; RETURN;
        END IF;
        IF lv_apr = 'RECHAZADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona fue rechazada: está cerrada y no se modifica.'; RETURN;
        END IF;
        IF lv_ing <> 'ESPERADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona ya tiene movimientos en portería: no se retira.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = lv_sol AND "Eliminado" = 'N' AND "Aprobacion" <> 'RETIRADA'
           AND "ID_Solicitud_Persona" <> "HV_ID_Solicitud_Persona";
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Es la última persona de la solicitud. Cancele la solicitud en su lugar.'; RETURN;
        END IF;

        SELECT "Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres" INTO lv_nom
          FROM "CAF_Persona_Externa" WHERE "ID_Persona_Externa" = lv_ext;

        UPDATE "CAF_Solicitud_Decision"
           SET "Vigente" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Vigente" = 'Y' AND "Eliminado" = 'N';
        UPDATE "CAF_Solicitud_Persona"
           SET "Aprobacion" = 'RETIRADA', "Aprobacion_Mensaje" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"(lv_sol, "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', "HV_ID_Solicitud_Persona", lv_sol, 'RETIRAR', lv_nom, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Persona retirada. No necesitó aprobación.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_RETIRAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_SOLICITUD_PERSONA_CORREGIR
--    Cambia a QUÉ persona del registro apunta la fila de la solicitud (cuando se
--    corrigió el documento) y, si estaba OBSERVADA, la reenvía: vuelve a PENDIENTE
--    y se reabren solo sus pasos por persona; los pasos por solicitud ya
--    aprobados no se tocan. Si la corrección fue solo del nombre en el registro
--    (la aplicación ya llamó a ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR), se pasa el
--    mismo identificador y solo se reenvía.
--    Una persona aprobada no se corrige: se retira y se agrega otra.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(
    IN    "HV_ID_Solicitud_Persona"      BIGINT,
    IN    "HV_ID_Persona_Externa_Nueva"  BIGINT,
    IN    "HV_UsuarioID"                 BIGINT,
    INOUT "HV_Reenviada_Result"          CHAR(1) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"               INT DEFAULT NULL,
    INOUT "HV_Mensaje"                   VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_sol    BIGINT;
    lv_apr    VARCHAR(20);
    lv_ing    VARCHAR(20);
    lv_ext    BIGINT;
    lv_tipo   BIGINT;
    lv_sede   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_nom    VARCHAR(400);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
    lv_dest   VARCHAR(2000);
    lv_cambia CHAR(1) := 'N';
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_CORREGIR';
    "HV_Reenviada_Result" := 'N';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud (se toma desde la persona): la segunda operación espera y ve lo ya registrado
        SELECT MAX("ID_Solicitud") INTO lv_sol FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = lv_sol;
        SELECT COUNT(*), MAX("ID_Solicitud"), MAX("Aprobacion"), MAX("Estado"), MAX("ID_Persona_Externa")
          INTO lv_n, lv_sol, lv_apr, lv_ing, lv_ext
          FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no está en la solicitud.'; RETURN;
        END IF;
        SELECT MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_sede, lv_tipo, lv_owner, lv_estado, lv_fecha, lv_codsol FROM "CAF_Solicitud" WHERE "ID_Solicitud" = lv_sol;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para modificarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;
        IF lv_apr = 'APROBADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Una persona autorizada no se edita: retírela y agregue otra persona.'; RETURN;
        END IF;
        IF lv_apr = 'RECHAZADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona fue rechazada: está cerrada y no se modifica.'; RETURN;
        END IF;
        IF lv_apr = 'RETIRADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona está retirada. Vuelva a agregarla primero.'; RETURN;
        END IF;
        IF lv_ing <> 'ESPERADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona ya tiene movimientos en portería: no se modifica.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres")
          INTO lv_n, lv_nom FROM "CAF_Persona_Externa"
         WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa_Nueva" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La persona indicada no está registrada.'; RETURN;
        END IF;

        IF "HV_ID_Persona_Externa_Nueva" <> lv_ext THEN
            SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
             WHERE "ID_Solicitud" = lv_sol AND "ID_Persona_Externa" = "HV_ID_Persona_Externa_Nueva" AND "Eliminado" = 'N';
            IF lv_n > 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Esa persona ya figura en la solicitud.'; RETURN;
            END IF;
            lv_cambia := 'Y';
            UPDATE "CAF_Solicitud_Persona"
               SET "ID_Persona_Externa" = "HV_ID_Persona_Externa_Nueva", "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
        END IF;

        IF lv_apr = 'OBSERVADA' OR lv_cambia = 'Y' THEN
            -- Se reabren solo los pasos por persona; los de la solicitud se conservan
            UPDATE "CAF_Solicitud_Decision"
               SET "Vigente" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Vigente" = 'Y' AND "Eliminado" = 'N'
               AND "ID_Tipo_Acceso_Paso_Aprobacion" IN (SELECT S."ID_Tipo_Acceso_Paso_Aprobacion" FROM "Tipo_Acceso_Paso_Aprobacion" S
                                                         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Alcance" = 'PERSONA');
            IF lv_apr = 'OBSERVADA' THEN
                UPDATE "CAF_Solicitud_Persona"
                   SET "Origen" = 'REENVIADA', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
                "HV_Reenviada_Result" := 'Y';
            END IF;

            CALL "ERP_CAF_SOLICITUD_RECALCULAR"(lv_sol, "HV_UsuarioID", lv_est2, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
            CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', "HV_ID_Solicitud_Persona", lv_sol,
                 CASE WHEN lv_apr = 'OBSERVADA' THEN 'REENVIAR' ELSE 'CORREGIR' END, lv_nom, "HV_UsuarioID", lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

            IF lv_apr = 'OBSERVADA' THEN
                CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_sol, 'PASO_PENDIENTE', "HV_ID_Solicitud_Persona", lv_dest, lv_c, lv_m);
                CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', lv_sol, lv_dest, NULL,
                     'Persona corregida en ' || lv_codsol,
                     lv_nom || ' fue corregida y reenviada en la solicitud.', "HV_UsuarioID", lv_c, lv_m);
            END IF;
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN lv_apr = 'OBSERVADA' THEN 'Persona corregida y reenviada a aprobación.'
                                 WHEN lv_cambia = 'Y' THEN 'Persona corregida.'
                                 ELSE 'Sin cambios.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_CORREGIR';
        "HV_Reenviada_Result" := 'N';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA   (D-169, P-98)
--    CORRECCIÓN DE EMERGENCIA del Coordinador: quita a una persona AUTORIZADA de una
--    solicitud ya aprobada (APROBADA o APROBADA_PARCIAL).
--    - Exige SUSTENTO (bitácora y correo). Solo hasta el día de la visita.
--    - Solo si la persona aún NO ingresó (Estado ESPERADA). Quien ya tiene movimientos
--      en portería no se quita: si está dentro, Vigilancia registra su salida con una
--      observación.
--    - No se borra nada: la persona pasa a RETIRADA y sus decisiones dejan de ser
--      vigentes. No se quita a la última persona: solo el solicitante cancela la solicitud.
--    - Las personas pendientes u observadas no se tocan aquí: se resuelven con la
--      decisión normal (observar o rechazar) o las modifica el solicitante.
--    - Avisa por correo igual que ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(
    IN    "HV_ID_Solicitud_Persona" BIGINT,
    IN    "HV_Sustento"             VARCHAR(2000),
    IN    "HV_UsuarioID"            BIGINT,
    INOUT "HV_Codigo_Resp"          INT DEFAULT NULL,
    INOUT "HV_Mensaje"              VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_sol    BIGINT;
    lv_apr    VARCHAR(20);
    lv_ing    VARCHAR(20);
    lv_ext    BIGINT;
    lv_tipo   BIGINT;
    lv_sede   BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_nom    VARCHAR(400);
    lv_quien  VARCHAR(400);
    lv_sus    VARCHAR(2000);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
    lv_dest   VARCHAR(2000);
    lv_dest2  VARCHAR(2000);
BEGIN
    -- V1.0 2026-10-27 (D-169)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        lv_sus := TRIM(COALESCE("HV_Sustento", ''));
        IF LENGTH(lv_sus) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Escriba el sustento de la corrección de emergencia.'; RETURN;
        END IF;
        IF LENGTH(lv_sus) > 300 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El sustento no puede pasar de 300 caracteres.'; RETURN;
        END IF;
        -- Serializa por solicitud (se toma desde la persona): la segunda operación espera y ve lo ya registrado
        SELECT MAX("ID_Solicitud") INTO lv_sol FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = lv_sol;
        SELECT COUNT(*), MAX("ID_Solicitud"), MAX("Aprobacion"), MAX("Estado"), MAX("ID_Persona_Externa")
          INTO lv_n, lv_sol, lv_apr, lv_ing, lv_ext
          FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no está en la solicitud.'; RETURN;
        END IF;
        SELECT MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_sede, lv_tipo, lv_estado, lv_fecha, lv_codsol FROM "CAF_Solicitud" WHERE "ID_Solicitud" = lv_sol;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_APROBAR', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para aprobar en esta sede.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
           AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", S."ID_Catalogo_Licencia", lv_sede) = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Su rol no decide ningún paso de este tipo de acceso.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF lv_estado NOT IN ('APROBADA', 'APROBADA_PARCIAL') THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'La corrección de emergencia solo aplica a una solicitud ya aprobada. Mientras esté por decidir, observe o rechace desde la revisión.';
            RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó: la solicitud no se modifica.'; RETURN;
        END IF;
        IF lv_apr = 'RETIRADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona ya está retirada.'; RETURN;
        END IF;
        IF lv_apr <> 'APROBADA' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'Solo se retira por emergencia a una persona autorizada. Las pendientes, observadas o rechazadas se resuelven con la decisión normal.';
            RETURN;
        END IF;
        IF lv_ing <> 'ESPERADA' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE WHEN lv_ing = 'DENTRO'
                                 THEN 'La persona ya ingresó: no se retira. Vigilancia debe registrar su salida con una observación.'
                                 ELSE 'La persona ya tiene movimientos en portería: no se retira.' END;
            RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = lv_sol AND "Eliminado" = 'N' AND "Aprobacion" <> 'RETIRADA'
           AND "ID_Solicitud_Persona" <> "HV_ID_Solicitud_Persona";
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Es la única persona de la solicitud. Pida al solicitante que cancele la solicitud en su lugar.';
            RETURN;
        END IF;

        SELECT "Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres" INTO lv_nom
          FROM "CAF_Persona_Externa" WHERE "ID_Persona_Externa" = lv_ext;

        UPDATE "CAF_Solicitud_Decision"
           SET "Vigente" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Vigente" = 'Y' AND "Eliminado" = 'N';
        UPDATE "CAF_Solicitud_Persona"
           SET "Aprobacion" = 'RETIRADA', "Aprobacion_Mensaje" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"(lv_sol, "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_SOLICITUD_VERSION_GUARDAR"(lv_sol, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'version: %', lv_m; END IF;
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', "HV_ID_Solicitud_Persona", lv_sol, 'RETIRAR_EMERGENCIA',
             lv_nom || ' · Emergencia: ' || lv_sus, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        SELECT U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" INTO lv_quien
          FROM "CAF_GOVERNANCE"."Usuario" U WHERE U."ID_Usuario" = "HV_UsuarioID";

        -- Para: solicitante y Vigilancia. Copia: aprobadores y correos adicionales de la solicitud.
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_sol, 'SOLICITANTE', NULL, lv_dest, lv_c, lv_m);
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_sol, 'PORTERIA', NULL, lv_dest2, lv_c, lv_m);
        lv_dest := CASE WHEN lv_dest IS NULL THEN lv_dest2 WHEN lv_dest2 IS NULL THEN lv_dest ELSE lv_dest || '; ' || lv_dest2 END;
        CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_CORRECCION', lv_sol, lv_dest,
             "ERP_CAF_FN_COPIA_CORREO"(lv_sol, 'N', 'Y', 'N', 'Y'),
             'Corrección de emergencia en ' || lv_codsol || ': se retiró a una persona',
             'CORRECCIÓN DE EMERGENCIA' || CHR(10)
             || 'Se retiró a ' || lv_nom || ' de la solicitud ' || lv_codsol || ': ya no está autorizada para ingresar.' || CHR(10)
             || 'Sustento: ' || lv_sus || CHR(10)
             || 'Registrado por: ' || COALESCE(lv_quien, 'el Coordinador') || '.',
             "HV_UsuarioID", lv_c, lv_m);

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Persona retirada por corrección de emergencia.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA';
    END;
END;
$$;
