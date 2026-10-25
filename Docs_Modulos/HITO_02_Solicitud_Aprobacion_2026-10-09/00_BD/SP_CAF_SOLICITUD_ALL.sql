-- =============================================================================
-- Archivo : SP_CAF_SOLICITUD_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobación | Fase 1 - Procedimientos (escritura)
-- Entidad : CAF_Solicitud
-- Versión : V1.0 2026-10-16
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO2_ESCRITURA.sql)
-- Requiere: scripts 01 a 10 y SP_CAF_SOLICITUD_BASE_ALL.sql cargado antes.
-- =============================================================================
-- 1 ERP_CAF_SOLICITUD_CREAR        crea y envía a aprobación (también «Reutilizar»)
-- 2 ERP_CAF_SOLICITUD_EDITAR_DATOS cambia los datos de la visita
-- 3 ERP_CAF_SOLICITUD_CANCELAR     cancela (no se borra nunca)
--
-- Las LISTAS (zonas, personas, correos en copia) llegan como texto separado por
-- comas, porque HANA no recibe arreglos como parámetro. Los identificadores se
-- validan contra el catálogo: si uno no existe, se rechaza todo.
-- Las personas externas ya deben estar en el registro (ERP_CAF_PERSONA_EXTERNA_*):
-- la aplicación las crea o corrige antes y pasa sus identificadores.
-- Cada procedimiento es ATÓMICO: si algo falla a medias, no queda nada escrito.
--
-- Reglas de quién puede qué:
--   * Solo el solicitante dueño de la solicitud la edita o la cancela, y debe
--     tener el permiso PER_CAF_SOLICITUD_PROPIA en esa sede (RNF-05).
-- CONCURRENCIA: cada operación toma primero un bloqueo sobre la fila de la
-- solicitud (un UPDATE que no cambia nada). Si dos personas deciden a la vez, la
-- segunda espera a que termine la primera y entonces ve el resultado ya registrado
-- (por ejemplo «ya tiene decisión en este paso»). No existe un índice único para
-- «una sola decisión vigente por persona y paso» porque HANA no admite índices parciales.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_SOLICITUD_CREAR
--    HV_ID_Solicitud_Origen: solo si nace de «Reutilizar» otra solicitud suya.
--    Es trazabilidad («Basada en SOL-xxx»): NO agrupa visitas ni cuenta aparte.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_CREAR"(
    IN    "HV_ID_Catalogo_Sede"         BIGINT,
    IN    "HV_ID_Catalogo_Tipo_Acceso"  BIGINT,
    IN    "HV_ID_Personal_Responsable"  BIGINT,
    IN    "HV_Fecha_Hora_Prevista"      TIMESTAMP,
    IN    "HV_Empresa_Visitante"        VARCHAR(500),
    IN    "HV_ID_Catalogo_Motivo_Visita" BIGINT,
    IN    "HV_Motivo_Detalle"           VARCHAR(500),
    IN    "HV_Observaciones"            VARCHAR(2000),
    IN    "HV_IDs_Zona"                 VARCHAR(2000),
    IN    "HV_IDs_Persona_Externa"      VARCHAR(2000),
    IN    "HV_Copias"                   VARCHAR(2000),
    IN    "HV_ID_Solicitud_Origen"      BIGINT,
    IN    "HV_UsuarioID"                BIGINT,
    INOUT "HV_ID_Solicitud_Result"      BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Solicitud_Result"  VARCHAR(20) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"              INT DEFAULT NULL,
    INOUT "HV_Mensaje"                  VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n       INT := 0;
    lv_otro    CHAR(1);
    lv_disp    CHAR(1);
    lv_req     CHAR(1);
    lv_z       VARCHAR(2100);
    lv_p       VARCHAR(2100);
    lv_listaZ  VARCHAR(2100);
    lv_listaP  VARCHAR(2100);
    lv_cntZ    INT := 0;
    lv_cntP    INT := 0;
    lv_sctr    CHAR(1);
    lv_epp     CHAR(1);
    lv_id      BIGINT;
    lv_codsol  VARCHAR(20);
    lv_c       INT;
    lv_m       VARCHAR(250);
    lv_estado  VARCHAR(20);
    lv_dest    VARCHAR(2000);
    lv_copia   VARCHAR(2000);
    lv_detalle VARCHAR(500);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR';
    "HV_ID_Solicitud_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', "HV_ID_Catalogo_Sede") <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para crear solicitudes en esta sede.'; RETURN;
        END IF;

        -- Tipo de acceso: debe estar habilitado y tener pasos de aprobación
        SELECT COUNT(*), MAX("Disponible"), MAX("Requiere_Aprobacion") INTO lv_n, lv_disp, lv_req
          FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de acceso no existe o está inactivo.'; RETURN;
        END IF;
        IF lv_disp <> 'Y' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Ese tipo de acceso todavía no está disponible.'; RETURN;
        END IF;
        IF lv_req = 'Y' THEN
            SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion"
             WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N' AND "Activo" = 'Y' AND "Obligatorio" = 'Y';
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'El tipo de acceso no tiene pasos de aprobación configurados.'; RETURN;
            END IF;
        END IF;

        -- Datos de la visita
        IF "HV_Fecha_Hora_Prevista" IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique la fecha y la hora de la visita.'; RETURN;
        END IF;
        IF CAST("HV_Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La fecha de la visita no puede ser anterior a hoy.'; RETURN;
        END IF;
        IF "HV_Empresa_Visitante" IS NULL OR LENGTH(TRIM("HV_Empresa_Visitante")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La empresa o procedencia es obligatoria.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Personal"
         WHERE "ID_Personal" = "HV_ID_Personal_Responsable" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El responsable de atención no existe o está inactivo.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Es_Otro") INTO lv_n, lv_otro FROM "Catalogo_Motivo_Visita"
         WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El motivo no existe o está inactivo.'; RETURN;
        END IF;
        IF lv_otro = 'Y' AND ("HV_Motivo_Detalle" IS NULL OR LENGTH(TRIM("HV_Motivo_Detalle")) = 0) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Describa el motivo de la visita.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Copias") <> 'Y' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de correos en copia no es válida.'; RETURN;
        END IF;

        -- Zonas: al menos una, todas activas y de esa sede
        lv_z := REPLACE(REPLACE(COALESCE("HV_IDs_Zona", ''), ' ', ''), ';', ',');
        lv_cntZ := CASE WHEN LENGTH(lv_z) = 0 THEN 0 ELSE LENGTH(lv_z) - LENGTH(REPLACE(lv_z, ',', '')) + 1 END;
        lv_listaZ := ',' || lv_z || ',';
        IF lv_cntZ = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Marque al menos una zona.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Zona_Acceso" Z
         WHERE Z."Eliminado" = 'N' AND Z."Activo" = 'Y' AND Z."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
           AND lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        IF lv_n <> lv_cntZ THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Alguna zona no existe, está inactiva, está repetida o es de otra sede.'; RETURN;
        END IF;

        -- Personas: al menos una, todas en el registro de personas externas
        lv_p := REPLACE(REPLACE(COALESCE("HV_IDs_Persona_Externa", ''), ' ', ''), ';', ',');
        lv_cntP := CASE WHEN LENGTH(lv_p) = 0 THEN 0 ELSE LENGTH(lv_p) - LENGTH(REPLACE(lv_p, ',', '')) + 1 END;
        lv_listaP := ',' || lv_p || ',';
        IF lv_cntP = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Agregue al menos una persona.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Persona_Externa" PE
         WHERE PE."Eliminado" = 'N' AND lv_listaP LIKE '%,' || CAST(PE."ID_Persona_Externa" AS VARCHAR) || ',%';
        IF lv_n <> lv_cntP THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Alguna persona no está registrada o está repetida.'; RETURN;
        END IF;

        -- Origen («Reutilizar»): debe ser una solicitud del mismo usuario
        IF "HV_ID_Solicitud_Origen" IS NOT NULL THEN
            SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud"
             WHERE "ID_Solicitud" = "HV_ID_Solicitud_Origen" AND "Eliminado" = 'N' AND "ID_Usuario_Solicitante" = "HV_UsuarioID";
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud de origen no existe o no es suya.'; RETURN;
            END IF;
        END IF;

        -- Qué exigen las zonas elegidas (se copia: un cambio posterior en el catálogo no altera lo ya enviado, D-18)
        SELECT CASE WHEN SUM(CASE WHEN Z."Exige_SCTR" = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END,
               CASE WHEN SUM(CASE WHEN Z."Exige_EPP"  = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END
          INTO lv_sctr, lv_epp
          FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';

        lv_detalle := CASE WHEN lv_otro = 'Y' THEN TRIM("HV_Motivo_Detalle") ELSE NULL END;

        INSERT INTO "CAF_Solicitud" ("ID_Catalogo_Sede","ID_Catalogo_Tipo_Acceso","ID_Usuario_Solicitante","ID_Personal_Responsable",
                                     "Fecha_Hora_Prevista","Empresa_Visitante","ID_Catalogo_Motivo_Visita","Motivo_Detalle","Observaciones",
                                     "Exige_SCTR","Exige_EPP","Estado","Version","Fecha_Envio","ID_Solicitud_Origen","UsuarioID_Create")
        VALUES ("HV_ID_Catalogo_Sede", "HV_ID_Catalogo_Tipo_Acceso", "HV_UsuarioID", "HV_ID_Personal_Responsable",
                "HV_Fecha_Hora_Prevista", TRIM("HV_Empresa_Visitante"), "HV_ID_Catalogo_Motivo_Visita", lv_detalle, NULLIF(TRIM("HV_Observaciones"), ''),
                lv_sctr, lv_epp, 'PENDIENTE', 1, CURRENT_TIMESTAMP, "HV_ID_Solicitud_Origen", "HV_UsuarioID")
        RETURNING "ID_Solicitud" INTO lv_id;

        -- El código visible se deriva del identificador (D-15)
        lv_codsol := 'SOL-' || LPAD(CAST(lv_id AS VARCHAR), 5, '0');
        UPDATE "CAF_Solicitud" SET "Codigo" = lv_codsol WHERE "ID_Solicitud" = lv_id;

        INSERT INTO "CAF_Solicitud_Zona" ("ID_Solicitud","ID_Catalogo_Zona_Acceso","UsuarioID_Create")
        SELECT lv_id, Z."ID_Catalogo_Zona_Acceso", "HV_UsuarioID" FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';

        INSERT INTO "CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","Origen","UsuarioID_Create")
        SELECT lv_id, PE."ID_Persona_Externa", 'PENDIENTE', 'SOLICITUD', "HV_UsuarioID" FROM "CAF_Persona_Externa" PE
         WHERE lv_listaP LIKE '%,' || CAST(PE."ID_Persona_Externa" AS VARCHAR) || ',%';

        CALL "ERP_CAF_SOLICITUD_COPIAS_GUARDAR"(lv_id, "HV_Copias", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'copias: %', lv_m; END IF;

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"(lv_id, "HV_UsuarioID", lv_estado, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', lv_id, lv_id, 'CREAR',
             'Creó y envió la solicitud' || CASE WHEN "HV_ID_Solicitud_Origen" IS NULL THEN '' ELSE ' a partir de la solicitud ' || "HV_ID_Solicitud_Origen" END,
             "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        -- Aviso a quienes deciden el primer paso (si el flujo no requería aprobación ya quedó aprobada)
        IF lv_estado = 'PENDIENTE' THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_id, 'PRIMER_PASO', NULL, lv_dest, lv_c, lv_m);
            -- Para: quien decide el primer paso. Copia: el solicitante y los correos adicionales del asistente
            CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_NUEVA', lv_id, lv_dest,
                 "ERP_CAF_FN_COPIA_CORREO"(lv_id, 'Y', 'N', 'N', 'Y'),
                 'Nueva solicitud ' || lv_codsol || ' por aprobar',
                 'Se registró una nueva solicitud de acceso y está por aprobar: ' || lv_cntP || ' persona(s) de '
                 || TRIM("HV_Empresa_Visitante") || ', visita prevista el ' || TO_CHAR("HV_Fecha_Hora_Prevista", 'DD/MM/YYYY HH24:MI') || '.',
                 "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_ID_Solicitud_Result"     := lv_id;
        "HV_Codigo_Solicitud_Result" := lv_codsol;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Solicitud ' || lv_codsol || ' registrada y enviada a aprobación.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR';
        "HV_ID_Solicitud_Result" := 0;
        "HV_Codigo_Solicitud_Result" := NULL;
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_SOLICITUD_EDITAR_DATOS
--    Cambia los datos de la visita. Reglas (RN-06 y RN-07 afinadas):
--      * Solo si nadie ingresó, la fecha no pasó y no está cancelada ni rechazada.
--      * Si cambian fecha, hora, empresa, motivo o zonas, se REABRE la aprobación:
--        la versión sube, y las personas aprobadas o pendientes vuelven a
--        PENDIENTE (origen REABIERTA). Las observadas conservan su observación;
--        las rechazadas y retiradas no se reabren.
--      * Si solo cambian el responsable de atención, las observaciones o las
--        copias de correo, lo aprobado NO se toca (no cambia lo que se autorizó).
--    El personal se modifica con los procedimientos de persona, no aquí.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_EDITAR_DATOS"(
    IN    "HV_ID_Solicitud"             BIGINT,
    IN    "HV_Fecha_Hora_Prevista"      TIMESTAMP,
    IN    "HV_Empresa_Visitante"        VARCHAR(500),
    IN    "HV_ID_Personal_Responsable"  BIGINT,
    IN    "HV_ID_Catalogo_Motivo_Visita" BIGINT,
    IN    "HV_Motivo_Detalle"           VARCHAR(500),
    IN    "HV_Observaciones"            VARCHAR(2000),
    IN    "HV_IDs_Zona"                 VARCHAR(2000),
    IN    "HV_Copias"                   VARCHAR(2000),
    IN    "HV_UsuarioID"                BIGINT,
    INOUT "HV_Reabierta_Result"         CHAR(1) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"              INT DEFAULT NULL,
    INOUT "HV_Mensaje"                  VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n        INT := 0;
    lv_n2       INT := 0;
    lv_sede     BIGINT;
    lv_tipo     BIGINT;
    lv_owner    BIGINT;
    lv_estado   VARCHAR(20);
    lv_fecha    TIMESTAMP;
    lv_emp      VARCHAR(500);
    lv_mot      BIGINT;
    lv_det_old  VARCHAR(500);
    lv_resp_old BIGINT;
    lv_codsol   VARCHAR(20);
    lv_otro     CHAR(1);
    lv_detalle  VARCHAR(500);
    lv_z        VARCHAR(2100);
    lv_listaZ   VARCHAR(2100);
    lv_cntZ     INT := 0;
    lv_cambia   CHAR(1) := 'N';
    lv_sctr     CHAR(1);
    lv_epp      CHAR(1);
    lv_c        INT;
    lv_m        VARCHAR(250);
    lv_est2     VARCHAR(20);
    lv_dest     VARCHAR(2000);
    lv_copia    VARCHAR(2000);
    lv_desc     VARCHAR(2000) := '';
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_EDITAR_DATOS';
    "HV_Reabierta_Result" := 'N';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("ID_Usuario_Solicitante"), MAX("Estado"),
               MAX("Fecha_Hora_Prevista"), MAX("Empresa_Visitante"), MAX("ID_Catalogo_Motivo_Visita"), MAX("Motivo_Detalle"),
               MAX("ID_Personal_Responsable"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_tipo, lv_owner, lv_estado, lv_fecha, lv_emp, lv_mot, lv_det_old, lv_resp_old, lv_codsol
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
        IF lv_estado = 'RECHAZADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Todas las personas fueron rechazadas. Use «Reutilizar» para crear una solicitud nueva.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó. Use «Reutilizar».'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Estado" <> 'ESPERADA';
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'Ya ingresó una persona: los datos de la visita no se cambian. Puede modificar el personal.'; RETURN;
        END IF;

        -- Validación de los valores nuevos (mismas reglas que al crear)
        IF "HV_Fecha_Hora_Prevista" IS NULL OR CAST("HV_Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique una fecha y hora de visita que no sea anterior a hoy.'; RETURN;
        END IF;
        IF "HV_Empresa_Visitante" IS NULL OR LENGTH(TRIM("HV_Empresa_Visitante")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La empresa o procedencia es obligatoria.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Personal"
         WHERE "ID_Personal" = "HV_ID_Personal_Responsable" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El responsable de atención no existe o está inactivo.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Es_Otro") INTO lv_n, lv_otro FROM "Catalogo_Motivo_Visita"
         WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita" AND "Eliminado" = 'N' AND ("Activo" = 'Y' OR "ID_Catalogo_Motivo_Visita" = lv_mot);
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El motivo no existe.'; RETURN;
        END IF;
        IF lv_otro = 'Y' AND ("HV_Motivo_Detalle" IS NULL OR LENGTH(TRIM("HV_Motivo_Detalle")) = 0) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Describa el motivo de la visita.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Copias") <> 'Y' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de correos en copia no es válida.'; RETURN;
        END IF;

        lv_z := REPLACE(REPLACE(COALESCE("HV_IDs_Zona", ''), ' ', ''), ';', ',');
        lv_cntZ := CASE WHEN LENGTH(lv_z) = 0 THEN 0 ELSE LENGTH(lv_z) - LENGTH(REPLACE(lv_z, ',', '')) + 1 END;
        lv_listaZ := ',' || lv_z || ',';
        IF lv_cntZ = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Marque al menos una zona.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Zona_Acceso" Z
         WHERE Z."Eliminado" = 'N' AND Z."ID_Catalogo_Sede" = lv_sede
           AND lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%'
           AND (Z."Activo" = 'Y' OR EXISTS (SELECT 1 FROM "CAF_Solicitud_Zona" W
                                             WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."Eliminado" = 'N'
                                               AND W."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso"));
        IF lv_n <> lv_cntZ THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Alguna zona no existe, está inactiva, está repetida o es de otra sede.'; RETURN;
        END IF;

        -- ¿Cambió algo que obligue a volver a aprobar?
        lv_detalle := CASE WHEN lv_otro = 'Y' THEN TRIM("HV_Motivo_Detalle") ELSE NULL END;
        IF "HV_Fecha_Hora_Prevista" <> lv_fecha THEN
            lv_cambia := 'Y';
            lv_desc := lv_desc || 'Visita ' || TO_CHAR(lv_fecha, 'DD/MM/YYYY HH24:MI') || ' → ' || TO_CHAR("HV_Fecha_Hora_Prevista", 'DD/MM/YYYY HH24:MI') || '. ';
        END IF;
        IF TRIM("HV_Empresa_Visitante") <> lv_emp THEN
            lv_cambia := 'Y'; lv_desc := lv_desc || 'Empresa: ' || lv_emp || ' → ' || TRIM("HV_Empresa_Visitante") || '. ';
        END IF;
        IF "HV_ID_Catalogo_Motivo_Visita" <> lv_mot OR COALESCE(lv_detalle, '') <> COALESCE(lv_det_old, '') THEN
            lv_cambia := 'Y'; lv_desc := lv_desc || 'Motivo modificado. ';
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Zona" W
         WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."Eliminado" = 'N'
           AND lv_listaZ NOT LIKE '%,' || CAST(W."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        SELECT COUNT(*) INTO lv_n2 FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%'
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Zona" W
                            WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."Eliminado" = 'N'
                              AND W."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso");
        IF lv_n > 0 OR lv_n2 > 0 THEN
            lv_cambia := 'Y'; lv_desc := lv_desc || 'Zonas modificadas. ';
        END IF;
        IF "HV_ID_Personal_Responsable" <> lv_resp_old THEN
            lv_desc := lv_desc || 'Responsable de atención cambiado. ';
        END IF;
        IF lv_desc = '' THEN lv_desc := 'Observaciones o copias de correo.'; END IF;

        -- Zonas: retirar las que ya no vienen, reactivar las quitadas, agregar las nuevas
        UPDATE "CAF_Solicitud_Zona"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N'
           AND lv_listaZ NOT LIKE '%,' || CAST("ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        UPDATE "CAF_Solicitud_Zona"
           SET "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'Y'
           AND lv_listaZ LIKE '%,' || CAST("ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        INSERT INTO "CAF_Solicitud_Zona" ("ID_Solicitud","ID_Catalogo_Zona_Acceso","UsuarioID_Create")
        SELECT "HV_ID_Solicitud", Z."ID_Catalogo_Zona_Acceso", "HV_UsuarioID" FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%'
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Zona" W
                            WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso");

        SELECT CASE WHEN SUM(CASE WHEN Z."Exige_SCTR" = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END,
               CASE WHEN SUM(CASE WHEN Z."Exige_EPP"  = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END
          INTO lv_sctr, lv_epp
          FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';

        UPDATE "CAF_Solicitud"
           SET "Fecha_Hora_Prevista" = "HV_Fecha_Hora_Prevista", "Empresa_Visitante" = TRIM("HV_Empresa_Visitante"),
               "ID_Personal_Responsable" = "HV_ID_Personal_Responsable", "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita",
               "Motivo_Detalle" = lv_detalle, "Observaciones" = NULLIF(TRIM("HV_Observaciones"), ''),
               "Exige_SCTR" = lv_sctr, "Exige_EPP" = lv_epp,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";

        CALL "ERP_CAF_SOLICITUD_COPIAS_GUARDAR"("HV_ID_Solicitud", "HV_Copias", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'copias: %', lv_m; END IF;

        -- Reabrir la aprobación si cambió lo que se había autorizado
        IF lv_cambia = 'Y' THEN
            UPDATE "CAF_Solicitud_Persona"
               SET "Origen" = 'REABIERTA', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N'
               AND "Aprobacion" IN ('APROBADA','PENDIENTE') AND "Estado" = 'ESPERADA';

            UPDATE "CAF_Solicitud_Decision" D
               SET "Vigente" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE D."Vigente" = 'Y' AND D."Eliminado" = 'N'
               AND D."ID_Solicitud_Persona" IN (SELECT P."ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" P
                                                 WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Estado" = 'ESPERADA')
               AND (D."ID_Tipo_Acceso_Paso_Aprobacion" IN (SELECT S."ID_Tipo_Acceso_Paso_Aprobacion" FROM "Tipo_Acceso_Paso_Aprobacion" S
                                                            WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Alcance" = 'SOLICITUD')
                    OR D."ID_Solicitud_Persona" IN (SELECT P2."ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" P2
                                                     WHERE P2."ID_Solicitud" = "HV_ID_Solicitud" AND P2."Aprobacion" IN ('APROBADA','PENDIENTE')));

            UPDATE "CAF_Solicitud" SET "Version" = "Version" + 1 WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        END IF;

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'EDITAR', TRIM(lv_desc), "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        IF lv_cambia = 'Y' AND lv_est2 IN ('PENDIENTE','APROBADA_PARCIAL') THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PRIMER_PASO', NULL, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_EDITADA', "HV_ID_Solicitud", lv_dest,
                 "ERP_CAF_FN_COPIA_CORREO"("HV_ID_Solicitud", 'Y', 'N', 'N', 'Y'),
                 'Solicitud ' || lv_codsol || ' modificada: hay personas por aprobar',
                 'Se modificaron los datos de la solicitud y hay personas por aprobar. ' || TRIM(lv_desc),
                 "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_Reabierta_Result" := lv_cambia;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN lv_cambia = 'Y' THEN 'Solicitud actualizada. Vuelve a aprobación.' ELSE 'Solicitud actualizada.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_EDITAR_DATOS';
        "HV_Reabierta_Result" := 'N';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_SOLICITUD_CANCELAR
--    No se borra: el estado pasa a CANCELADA (RN-08). No se cancela si alguien
--    ya ingresó (RN-07): en ese caso se retira a quienes faltan.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_CANCELAR"(
    IN    "HV_ID_Solicitud"        BIGINT,
    IN    "HV_Motivo_Cancelacion"  VARCHAR(500),
    IN    "HV_UsuarioID"           BIGINT,
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
    lv_aut    INT := 0;
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_dest   VARCHAR(2000);
    lv_port   VARCHAR(2000);
    lv_copia  VARCHAR(2000);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CANCELAR';
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
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para cancelarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud ya está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Estado" <> 'ESPERADA';
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Ya ingresó una persona: no se puede cancelar. Retire a quienes faltan.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_aut FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'APROBADA';

        UPDATE "CAF_Solicitud"
           SET "Estado" = 'CANCELADA', "Motivo_Cancelacion" = NULLIF(TRIM("HV_Motivo_Cancelacion"), ''),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'CANCELAR',
             COALESCE(NULLIF(TRIM("HV_Motivo_Cancelacion"), ''), 'Sin motivo indicado'), "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        -- Si ya había personas autorizadas, Vigilancia y los aprobadores deben enterarse
        IF lv_aut > 0 THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'APROBADORES', NULL, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PORTERIA', NULL, lv_port, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_CANCELADA', "HV_ID_Solicitud",
                 CASE WHEN lv_dest IS NULL THEN lv_port WHEN lv_port IS NULL THEN lv_dest ELSE lv_dest || '; ' || lv_port END,
                 "ERP_CAF_FN_COPIA_CORREO"("HV_ID_Solicitud", 'Y', 'N', 'N', 'Y'),
                 'Solicitud ' || lv_codsol || ' cancelada',
                 'La solicitud fue cancelada. ' || COALESCE(NULLIF(TRIM("HV_Motivo_Cancelacion"), ''), ''),
                 "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Solicitud cancelada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CANCELAR';
    END;
END;
$$;
