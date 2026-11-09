-- =============================================================================
-- Archivo : SP_CAF_PROVEEDOR_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobación | Fase 1 - Procedimientos (Entrega 1 de Proveedor de abastecimiento)
-- Entidad : CAF_Solicitud_Operacion / CAF_Solicitud_Operacion_Evento
-- Versión : V1.0 2026-11-02
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO2_ESCRITURA.sql, sección O)
-- Requiere: scripts 01 a 18. Los demás SP_CAF_* lo invocan en tiempo de ejecución (no al crearse).
-- =============================================================================
-- 1 ERP_CAF_FN_PERMISO_TIPO         permiso de solicitante según el tipo (proveedor o los demás)
-- 2 ERP_CAF_FN_ES_PROVEEDOR         'Y' si la persona pertenece a una solicitud de proveedor
-- 3 ERP_CAF_FN_PORTERIA_PERMISO     permiso de portería según el tipo de la solicitud
-- 4 ERP_CAF_FN_PROVEEDOR_VALIDAR    validación de los datos propios del proveedor
-- 5 ERP_CAF_PROVEEDOR_MOVER         (interna) cambia el estado operativo y deja el evento
-- 6 ERP_CAF_PROVEEDOR_SINCRONIZAR   crea / activa / desactiva la operación según la aprobación
-- 7 ERP_CAF_PROVEEDOR_REGLA         (interna) reglas operativas del ingreso y la salida
-- 8 ERP_CAF_PROVEEDOR_PORTERIA_POST (interna) avanza el estado tras un ingreso o una salida
-- 9 ERP_CAF_PROVEEDOR_INGRESO_VALIDAR  Vigilancia registra el ingreso físico (exige la disponibilidad de Almacén; V2.0 2026-11-03)
-- 10 ERP_CAF_PROVEEDOR_ATENDER      Almacén empieza a atender (la esclusa ya fue reservada al confirmar disponibilidad; V3.0 2026-11-03)
-- 11 ERP_CAF_PROVEEDOR_RECEPCION    Almacén registra la recepción; la exclusa se libera con la SALIDA de Vigilancia (V4.0 2026-11-05)
--
-- Estados operativos: PROGRAMADO -> EN_ESPERA -> INGRESO -> EN_ATENCION -> RECEPCIONADO -> SALIO
--                     (y NO_SE_PRESENTO, INGRESO_DENEGADO). Son independientes del estado de aprobación.
--   EN_ESPERA = Vigilancia verificó los datos (la verificación registra la llegada) y el proveedor espera;
--   NO es ingreso físico. INGRESO = Vigilancia validó el ingreso después de que Almacén confirmó su
--   disponibilidad (reserva de la esclusa, ver SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql).
-- Cada cambio toma un bloqueo sobre la solicitud: si dos personas actúan a la vez, la segunda recibe 409.
-- HANA: sin sobrecarga de procedimientos; los UPDATE con CASE y los INSERT ... SELECT se mantienen.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_FN_PERMISO_TIPO
-- -----------------------------------------------------------------------------
-- 0. ERP_CAF_FN_ES_SOLICITANTE: puede crear Y gestionar sus propias solicitudes (D-224)
--    Quien tiene PER_CAF_SOLICITUD_PROPIA o PER_CAF_PROVEEDOR_SOLICITAR. El permiso de proveedor
--    NO da acceso a los demás tipos de ingreso (eso lo decide ERP_CAF_FN_PERMISO_TIPO).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ES_SOLICITANTE"("HV_UsuarioID" BIGINT, "HV_ID_Catalogo_Sede" BIGINT)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-09
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_SOLICITAR', "HV_ID_Catalogo_Sede") = 'Y' THEN
        RETURN 'Y';
    END IF;
    RETURN 'N';
END;
$$;

-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_PERMISO_TIPO"("HV_UsuarioID" BIGINT, "HV_Tipo_Codigo" VARCHAR, "HV_ID_Catalogo_Sede" BIGINT)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-02
    IF "HV_Tipo_Codigo" = 'PROVEEDOR' THEN
        RETURN "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_SOLICITAR', "HV_ID_Catalogo_Sede");
    END IF;
    RETURN "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', "HV_ID_Catalogo_Sede");
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_FN_ES_PROVEEDOR  (por solicitud-persona)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ES_PROVEEDOR"("HV_ID_Solicitud_Persona" BIGINT)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-11-02
    SELECT COUNT(*) INTO lv_n
      FROM "CAF_Solicitud_Persona" P
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
      JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
     WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
    RETURN CASE WHEN lv_n > 0 THEN 'Y' ELSE 'N' END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2-bis. ERP_CAF_FN_ES_TRANSPORTISTA  (por solicitud-persona; D-225)
--        'Y' si la persona figura como transportista de su solicitud (CAF_Solicitud_Transportista). Las demás son ayudantes de descarga.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ES_TRANSPORTISTA"("HV_ID_Solicitud_Persona" BIGINT)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-11-09
    SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Transportista" T
     WHERE T."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND T."Eliminado" = 'N';
    RETURN CASE WHEN lv_n > 0 THEN 'Y' ELSE 'N' END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_FN_PORTERIA_PERMISO  (el proveedor lo registra la Vigilancia con licencia de proveedores)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_PORTERIA_PERMISO"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud_Persona" BIGINT, "HV_ID_Catalogo_Sede" BIGINT)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-02
    IF "ERP_CAF_FN_ES_PROVEEDOR"("HV_ID_Solicitud_Persona") = 'Y' THEN
        RETURN "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_VIGILANCIA', "HV_ID_Catalogo_Sede");
    END IF;
    RETURN "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', "HV_ID_Catalogo_Sede");
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_FN_PROVEEDOR_VALIDAR
--    '' si todo está bien o el mensaje para el solicitante.
--      * Tipo distinto de PROVEEDOR: no admite datos de proveedor.
--      * PROVEEDOR: sede con Aplica_Proveedor, teléfono (mínimo 6 dígitos) y empresa Trianon destinataria activa.
--        RUC, dirección, marca, placa y licencia son opcionales (V1.1, D-223); si se escriben se valida su formato.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_PROVEEDOR_VALIDAR"(
    "HV_Tipo_Codigo"      VARCHAR,
    "HV_ID_Catalogo_Sede" BIGINT,
    "HV_ID_Empresa_Destino" BIGINT,
    "HV_Proveedor_RUC"    VARCHAR,
    "HV_Proveedor_Direccion" VARCHAR,
    "HV_Vehiculo_Marca"   VARCHAR,
    "HV_Placa_Vehiculo"   VARCHAR,
    "HV_Licencia_Conducir" VARCHAR,
    "HV_Telefono"         VARCHAR
)
RETURNS VARCHAR(250)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n     INT := 0;
    lv_aplica CHAR(1);
    lv_placa VARCHAR(15);
BEGIN
    -- V1.0 2026-11-02
    IF "HV_Tipo_Codigo" <> 'PROVEEDOR' THEN
        IF "HV_ID_Empresa_Destino" IS NOT NULL
           OR NULLIF(TRIM(COALESCE("HV_Proveedor_RUC", '')), '') IS NOT NULL
           OR NULLIF(TRIM(COALESCE("HV_Proveedor_Direccion", '')), '') IS NOT NULL
           OR NULLIF(TRIM(COALESCE("HV_Vehiculo_Marca", '')), '') IS NOT NULL
           OR NULLIF(TRIM(COALESCE("HV_Licencia_Conducir", '')), '') IS NOT NULL THEN
            RETURN 'Esos datos corresponden solo al ingreso de proveedores.';
        END IF;
        RETURN '';
    END IF;

    SELECT COUNT(*), MAX("Aplica_Proveedor") INTO lv_n, lv_aplica
      FROM "CAF_GOVERNANCE"."Catalogo_Sede"
     WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N' AND "Activo" = 'Y';
    IF lv_n = 0 THEN RETURN 'La sede no existe o está inactiva.'; END IF;
    IF lv_aplica <> 'Y' THEN RETURN 'Esa sede no recibe proveedores de abastecimiento.'; END IF;

    -- V1.1 2026-11-06 (D-223): RUC, dirección, marca, placa y licencia son OPCIONALES (pueden ir en los adjuntos);
    -- si se escriben, se validan el RUC (11 dígitos) y la placa (5 a 8 letras o números).
    IF NULLIF(TRIM(COALESCE("HV_Proveedor_RUC", '')), '') IS NOT NULL AND TRIM("HV_Proveedor_RUC") !~ '^[0-9]{11}$' THEN RETURN 'El RUC debe tener 11 dígitos.'; END IF;
    lv_placa := "ERP_CAF_FN_PLACA_NORMALIZAR"("HV_Placa_Vehiculo");
    IF lv_placa IS NOT NULL AND lv_placa !~ '^[A-Z0-9]{5,8}$' THEN RETURN 'La placa del vehículo debe tener de 5 a 8 letras o números.'; END IF;
    IF LENGTH(REGEXP_REPLACE(COALESCE("HV_Telefono", ''), '[^0-9]', '', 'g')) < 6 THEN
        RETURN 'Indique el teléfono del transportista (mínimo 6 dígitos).';
    END IF;
    SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo"
     WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa_Destino" AND "Eliminado" = 'N' AND "Activo" = 'Y';
    IF lv_n = 0 THEN RETURN 'Indique la empresa del grupo que recibe la entrega.'; END IF;
    RETURN '';
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_PROVEEDOR_MOVER  (interna; quien llama ya validó la transición y tiene el bloqueo)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_MOVER"(
    IN    "HV_ID_Solicitud"  BIGINT,
    IN    "HV_Estado_Nuevo"  VARCHAR(20),
    IN    "HV_UsuarioID"     BIGINT,
    IN    "HV_Resultado"     VARCHAR(20),
    IN    "HV_Observacion"   VARCHAR(1000),
    IN    "HV_ID_Personal_Almacen" BIGINT,
    INOUT "HV_Codigo_Resp"   INT DEFAULT NULL,
    INOUT "HV_Mensaje"       VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_ant VARCHAR(20);
BEGIN
    -- V1.0 2026-11-02
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_MOVER';
    BEGIN
        SELECT "Estado_Operativo" INTO lv_ant FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        UPDATE "CAF_Solicitud_Operacion"
           SET "Estado_Operativo" = "HV_Estado_Nuevo",
               "Fecha_Llegada"         = CASE WHEN "HV_Estado_Nuevo" IN ('EN_ESPERA','INGRESO_DENEGADO') THEN CURRENT_TIMESTAMP ELSE "Fecha_Llegada" END,   -- = verificación de datos
               "ID_Usuario_Llegada"    = CASE WHEN "HV_Estado_Nuevo" IN ('EN_ESPERA','INGRESO_DENEGADO') THEN "HV_UsuarioID" ELSE "ID_Usuario_Llegada" END,
               "Fecha_Ingreso"         = CASE WHEN "HV_Estado_Nuevo" = 'INGRESO'      THEN CURRENT_TIMESTAMP ELSE "Fecha_Ingreso" END,
               "Fecha_Inicio_Atencion" = CASE WHEN "HV_Estado_Nuevo" = 'EN_ATENCION'  THEN CURRENT_TIMESTAMP ELSE "Fecha_Inicio_Atencion" END,
               "ID_Usuario_Atencion"   = CASE WHEN "HV_Estado_Nuevo" = 'EN_ATENCION'  THEN "HV_UsuarioID" ELSE "ID_Usuario_Atencion" END,
               "ID_Personal_Almacen"   = CASE WHEN "HV_Estado_Nuevo" = 'EN_ATENCION'  THEN "HV_ID_Personal_Almacen" ELSE "ID_Personal_Almacen" END,
               "Fecha_Recepcion"       = CASE WHEN "HV_Estado_Nuevo" = 'RECEPCIONADO' THEN CURRENT_TIMESTAMP ELSE "Fecha_Recepcion" END,
               "Resultado_Recepcion"   = CASE WHEN "HV_Estado_Nuevo" = 'RECEPCIONADO' THEN "HV_Resultado" ELSE "Resultado_Recepcion" END,
               "Observacion_Recepcion" = CASE WHEN "HV_Estado_Nuevo" = 'RECEPCIONADO' THEN NULLIF(TRIM("HV_Observacion"), '') ELSE "Observacion_Recepcion" END,
               "ID_Usuario_Recepcion"  = CASE WHEN "HV_Estado_Nuevo" = 'RECEPCIONADO' THEN "HV_UsuarioID" ELSE "ID_Usuario_Recepcion" END,
               "Fecha_Salida"          = CASE WHEN "HV_Estado_Nuevo" = 'SALIO'        THEN CURRENT_TIMESTAMP ELSE "Fecha_Salida" END,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES ("HV_ID_Solicitud", lv_ant, "HV_Estado_Nuevo", "HV_UsuarioID", "HV_Resultado", NULLIF(TRIM("HV_Observacion"), ''));
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Estado operativo actualizado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_MOVER';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CAF_PROVEEDOR_SINCRONIZAR
--    Se llama al final de ERP_CAF_SOLICITUD_RECALCULAR y tras cancelar. No hace nada si la solicitud
--    no es de proveedor. Regla: la operación existe y está ACTIVA solo si la solicitud no está cancelada
--    y el transportista principal está APROBADO. Si deja de cumplirse mientras sigue PROGRAMADO, se
--    desactiva (desaparece de Vigilancia); si ya hubo llegada, no se toca (decisión pendiente P-120).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_SINCRONIZAR"(
    IN    "HV_ID_Solicitud"  BIGINT,
    IN    "HV_UsuarioID"     BIGINT,
    INOUT "HV_Codigo_Resp"   INT DEFAULT NULL,
    INOUT "HV_Mensaje"       VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_estado VARCHAR(20);
    lv_apr    VARCHAR(20);
    lv_op     INT := 0;
    lv_act    CHAR(1);
    lv_eop    VARCHAR(20);
    lv_debe   CHAR(1);
BEGIN
    -- V1.1 2026-11-06: perder la aprobación también desactiva una entrega EN_ESPERA (vuelve a PROGRAMADO)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_SINCRONIZAR';
    BEGIN
        SELECT COUNT(*), MAX(S."Estado") INTO lv_n, lv_estado
          FROM "CAF_Solicitud" S
          JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
         WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'No aplica.'; RETURN;
        END IF;

        -- V1.2 2026-11-09 (D-225): la entrega está vigente si hay al menos un transportista aprobado
        SELECT CASE WHEN COUNT(*) > 0 THEN 'APROBADA' ELSE 'NO' END INTO lv_apr FROM "CAF_Solicitud_Persona" P
         WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'APROBADA'
           AND ("ERP_CAF_FN_ES_TRANSPORTISTA"(P."ID_Solicitud_Persona") = 'Y' OR P."Es_Principal" = 'Y');
        lv_debe := CASE WHEN lv_estado <> 'CANCELADA' AND lv_apr = 'APROBADA' THEN 'Y' ELSE 'N' END;

        SELECT COUNT(*), MAX("Activa"), MAX("Estado_Operativo") INTO lv_op, lv_act, lv_eop
          FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';

        IF lv_op = 0 THEN
            IF lv_debe = 'Y' THEN
                INSERT INTO "CAF_Solicitud_Operacion" ("ID_Solicitud","Estado_Operativo","Activa","UsuarioID_Create")
                VALUES ("HV_ID_Solicitud", 'PROGRAMADO', 'Y', "HV_UsuarioID");
                INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion")
                VALUES ("HV_ID_Solicitud", NULL, 'PROGRAMADO', "HV_UsuarioID", 'Transportista principal aprobado');
            END IF;
        ELSIF lv_debe = 'Y' AND lv_act = 'N' THEN
            UPDATE "CAF_Solicitud_Operacion" SET "Activa" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud";
            INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion")
            VALUES ("HV_ID_Solicitud", lv_eop, lv_eop, "HV_UsuarioID", 'Reactivada: transportista principal aprobado');
        ELSIF lv_debe = 'N' AND lv_act = 'Y' AND lv_eop IN ('PROGRAMADO','EN_ESPERA') THEN
            -- D-220: antes del ingreso físico, perder la aprobación saca la entrega del calendario y de Vigilancia hasta que se
            -- apruebe de nuevo. Si ya estaba verificada (EN_ESPERA) vuelve a PROGRAMADO: los datos pueden haber cambiado y deben verificarse otra vez.
            UPDATE "CAF_Solicitud_Operacion"
               SET "Activa" = 'N', "Estado_Operativo" = 'PROGRAMADO',
                   "Fecha_Llegada" = CASE WHEN lv_eop = 'EN_ESPERA' THEN NULL ELSE "Fecha_Llegada" END,
                   "Fecha_Disponibilidad" = NULL, "ID_Usuario_Disponibilidad" = NULL,
                   "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud";
            UPDATE "CAF_Solicitud_Persona" SET "Fecha_Verificacion" = NULL, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Estado" = 'ESPERADA';
            INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion")
            VALUES ("HV_ID_Solicitud", lv_eop, 'PROGRAMADO', "HV_UsuarioID",
                    CASE WHEN lv_estado = 'CANCELADA' THEN 'Desactivada: solicitud cancelada'
                         WHEN lv_eop = 'EN_ESPERA' THEN 'Desactivada: el transportista principal ya no está aprobado; deberá verificarse de nuevo'
                         ELSE 'Desactivada: el transportista principal ya no está aprobado' END);
        END IF;
        -- Si la entrega deja de estar aprobada o se cancela antes del ingreso, se libera su reserva de la esclusa
        IF lv_debe = 'N' AND COALESCE(lv_eop, 'PROGRAMADO') IN ('PROGRAMADO','EN_ESPERA') THEN
            UPDATE "CAF_Exclusa"
               SET "ID_Solicitud_Actual" = NULL, "Fecha_Ocupada" = NULL, "ID_Usuario_Ocupa" = NULL,
                   "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Actual" = "HV_ID_Solicitud";
        END IF;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Operación sincronizada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_SINCRONIZAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 7. ERP_CAF_PROVEEDOR_REGLA  (interna; la usa ERP_CAF_PORTERIA_REGLA_MOVIMIENTO)
--    Solo se evalúa si la persona es de una solicitud de proveedor y lo demás ya permite el movimiento.
--      INGRESO del principal : la llegada debe estar registrada (EN_ESPERA). Con registro tardío no se exige.
--      INGRESO del apoyo     : el principal ya debe haber ingresado.
--      SALIDA del principal  : la mercadería debe estar recepcionada.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_REGLA"(
    "HV_ID_Solicitud_Persona" BIGINT,
    "HV_Etapa"                VARCHAR,
    "HV_Tardio"               CHAR DEFAULT 'N'
)
RETURNS TABLE ("Codigo_Resp" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_n    INT := 0;
    lv_op   INT := 0;
    lv_act  CHAR(1);
    lv_eop  VARCHAR(20);
    lv_cod  INT := 100;
    lv_msg  VARCHAR(250) := NULL;
    lv_prev TIMESTAMP;
    lv_ver  TIMESTAMP;
    lv_sol  BIGINT;
    lv_pend INT := 0;
BEGIN
    -- V3.0 2026-11-09 (D-225): todas las personas pasan por verificación; ya no hay «principal primero»
    SELECT COUNT(*), MAX(S."Fecha_Hora_Prevista"), MAX(P."Fecha_Verificacion"), MAX(P."ID_Solicitud") INTO lv_n, lv_prev, lv_ver, lv_sol
      FROM "CAF_Solicitud_Persona" P
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
      JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
     WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
    IF lv_n > 0 THEN
        SELECT COUNT(*), MAX(O."Activa"), MAX(O."Estado_Operativo") INTO lv_op, lv_act, lv_eop
          FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = lv_sol AND O."Eliminado" = 'N';
        IF lv_op = 0 OR lv_act <> 'Y' THEN
            lv_cod := 409; lv_msg := 'La entrega del proveedor no está programada: debe haber un transportista aprobado.';
        ELSIF UPPER(COALESCE("HV_Etapa", '')) = 'INGRESO' THEN
            -- Este movimiento es la VERIFICACIÓN de datos de la persona; el ingreso físico se registra aparte.
            IF lv_eop NOT IN ('PROGRAMADO','EN_ESPERA','INGRESO','EN_ATENCION') THEN
                lv_cod := 409;
                lv_msg := CASE WHEN lv_eop = 'INGRESO_DENEGADO' THEN 'El ingreso de este proveedor fue denegado.'
                               WHEN lv_eop = 'RETIRO_SIN_INGRESO' THEN 'El proveedor se retiró sin ingresar.'
                               WHEN lv_eop IN ('CIERRE_FORZADO','NO_SE_PRESENTO') THEN 'La entrega fue cerrada al terminar su día.'
                               ELSE 'La recepción de la entrega ya culminó.' END;
            ELSIF lv_ver IS NOT NULL AND COALESCE("HV_Tardio", 'N') <> 'Y' THEN
                lv_cod := 409; lv_msg := 'Los datos de esta persona ya fueron verificados: falta registrar su ingreso.';
            ELSIF COALESCE("HV_Tardio", 'N') <> 'Y' AND CAST(lv_prev AS DATE) <> CURRENT_DATE THEN
                lv_cod := 409; lv_msg := 'La entrega es para otra fecha.';
            END IF;
        ELSIF UPPER(COALESCE("HV_Etapa", '')) = 'SALIDA' AND lv_eop NOT IN ('RECEPCIONADO','SALIO','CIERRE_FORZADO') THEN
            -- Con varios vehículos, cada uno sale al terminar su descarga para dar paso al siguiente (capacidad de la exclusa).
            SELECT COUNT(*) INTO lv_pend FROM "CAF_Solicitud_Persona" P2
             WHERE P2."ID_Solicitud" = lv_sol AND P2."Eliminado" = 'N' AND P2."Aprobacion" = 'APROBADA' AND P2."Estado" = 'ESPERADA'
               AND "ERP_CAF_FN_ES_TRANSPORTISTA"(P2."ID_Solicitud_Persona") = 'Y';
            IF NOT (lv_eop IN ('INGRESO','EN_ATENCION') AND lv_pend > 0) THEN
                lv_cod := 409; lv_msg := 'La salida se registra cuando Almacén recepciona la entrega (o para dar paso al siguiente vehículo).';
            END IF;
        END IF;
    END IF;
    RETURN QUERY SELECT lv_cod, CAST(COALESCE(lv_msg, 'Puede registrarse.') AS VARCHAR);
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_RECALCULAR"(
    IN    "HV_ID_Solicitud"  BIGINT,
    IN    "HV_UsuarioID"     BIGINT,
    IN    "HV_Observacion"   VARCHAR(500),
    INOUT "HV_Codigo_Resp"   INT DEFAULT NULL,
    INOUT "HV_Mensaje"       VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_eop  VARCHAR(20);
    lv_act  CHAR(1);
    lv_desv CHAR(1);
    lv_viv  INT := 0;
    lv_ver  INT := 0;
    lv_nega INT := 0;
    lv_nuevo VARCHAR(20);
    lv_c    INT;
    lv_m    VARCHAR(250);
BEGIN
    -- V1.0 2026-11-09 (D-225): el estado de la entrega sale del estado de sus transportistas.
    --   PROGRAMADO -> EN_ESPERA cuando TODOS los transportistas por ingresar están verificados.
    --   Sin transportistas por ingresar (denegados o retirados): la entrega termina sin ingreso y se libera la exclusa.
    "HV_Codigo_Resp" := 100;
    "HV_Mensaje"     := 'No aplica.';
    SELECT MAX("Estado_Operativo"), MAX("Activa"), MAX("Con_Desviacion") INTO lv_eop, lv_act, lv_desv
      FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
    IF lv_eop IS NULL OR lv_act <> 'Y' OR lv_eop NOT IN ('PROGRAMADO','EN_ESPERA') THEN RETURN; END IF;
    SELECT COUNT(*), COALESCE(SUM(CASE WHEN P."Fecha_Verificacion" IS NOT NULL THEN 1 ELSE 0 END), 0) INTO lv_viv, lv_ver
      FROM "CAF_Solicitud_Persona" P
     WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'APROBADA' AND P."Estado" = 'ESPERADA'
       AND "ERP_CAF_FN_ES_TRANSPORTISTA"(P."ID_Solicitud_Persona") = 'Y';
    IF lv_viv = 0 THEN
        SELECT COUNT(*) INTO lv_nega FROM "CAF_Solicitud_Persona" P
         WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Estado" = 'DENEGADA'
           AND "ERP_CAF_FN_ES_TRANSPORTISTA"(P."ID_Solicitud_Persona") = 'Y';
        lv_nuevo := CASE WHEN lv_nega > 0 THEN 'INGRESO_DENEGADO' ELSE 'RETIRO_SIN_INGRESO' END;
        CALL "ERP_CAF_PROVEEDOR_MOVER"("HV_ID_Solicitud", lv_nuevo, "HV_UsuarioID",
              CASE WHEN lv_nuevo = 'RETIRO_SIN_INGRESO' THEN 'RETIRO_SIN_INGRESO' ELSE NULL END,
              COALESCE(NULLIF(TRIM("HV_Observacion"), ''),
                       CASE WHEN lv_nega > 0 THEN 'Ingreso denegado en la verificación de datos' ELSE 'Ningún transportista quedó por ingresar' END), NULL, lv_c, lv_m);
        IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RETURN; END IF;
        UPDATE "CAF_Exclusa"
           SET "ID_Solicitud_Actual" = NULL, "Fecha_Ocupada" = NULL, "ID_Usuario_Ocupa" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Actual" = "HV_ID_Solicitud";
    ELSIF lv_eop = 'PROGRAMADO' AND lv_ver = lv_viv THEN
        CALL "ERP_CAF_PROVEEDOR_MOVER"("HV_ID_Solicitud", 'EN_ESPERA', "HV_UsuarioID", NULL,
              CASE WHEN lv_desv = 'Y' THEN 'Todos los transportistas verificados (con desviación autorizada)' ELSE 'Todos los transportistas verificados' END, NULL, lv_c, lv_m);
        IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RETURN; END IF;
    END IF;
    "HV_Mensaje" := 'Estado operativo revisado.';
END;
$$;

-- -----------------------------------------------------------------------------
-- 8. ERP_CAF_PROVEEDOR_PORTERIA_POST  (interna; la llaman ingreso y salida de portería ya registrados)
--    INGRESO (etapa de verificación): la persona verificada queda ESPERADA con Fecha_Verificacion (todavía NO está dentro)
--              y se recalcula la entrega. Una persona DENEGADA solo se recalcula (puede dejar la entrega sin transportistas).
--    SALIDA  : si ya nadie de la solicitud está DENTRO y estaba RECEPCIONADO -> SALIO y se libera la exclusa.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_PORTERIA_POST"(
    IN    "HV_ID_Solicitud_Persona" BIGINT,
    IN    "HV_Etapa"                VARCHAR(10),
    IN    "HV_UsuarioID"            BIGINT,
    INOUT "HV_Codigo_Resp"          INT DEFAULT NULL,
    INOUT "HV_Mensaje"              VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sol  BIGINT;
    lv_est  VARCHAR(20);
    lv_eop  VARCHAR(20);
    lv_act  CHAR(1);
    lv_den  INT := 0;
    lv_c    INT;
    lv_m    VARCHAR(250);
    lv_desv INT := 0;
    lv_cod  VARCHAR(20);
    lv_emp  VARCHAR(500);
    lv_fp   VARCHAR(20);
    lv_quien VARCHAR(400);
    lv_dest VARCHAR(2000);
BEGIN
    -- V3.0 2026-11-09 (D-225: verificación por persona)
    -- V2.1 2026-11-06 (D-218: salida tardía tras un cierre forzado)
    "HV_Codigo_Resp" := 100;
    "HV_Mensaje"     := 'No aplica.';
    IF "ERP_CAF_FN_ES_PROVEEDOR"("HV_ID_Solicitud_Persona") <> 'Y' THEN RETURN; END IF;
    SELECT P."ID_Solicitud", P."Estado" INTO lv_sol, lv_est
      FROM "CAF_Solicitud_Persona" P WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
    SELECT "Estado_Operativo", "Activa" INTO lv_eop, lv_act FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = lv_sol;
    IF lv_eop IS NULL OR lv_act <> 'Y' THEN RETURN; END IF;

    IF "HV_Etapa" = 'INGRESO' THEN
        IF lv_eop IN ('PROGRAMADO','EN_ESPERA','INGRESO','EN_ATENCION') THEN
            -- La decisión del coordinador ya viene registrada en la desviación (si la hubo): la entrega queda marcada «con desviación».
            SELECT COUNT(*) INTO lv_desv
              FROM "CAF_Desviacion" D JOIN "CAF_Registro_Acceso" R ON R."ID_Registro_Acceso" = D."ID_Registro_Acceso"
             WHERE R."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND R."Tipo_Movimiento" = 'INGRESO' AND D."Eliminado" = 'N';
            IF lv_desv > 0 THEN
                UPDATE "CAF_Solicitud_Operacion" SET "Con_Desviacion" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Solicitud" = lv_sol;
            END IF;
            IF lv_est = 'DENTRO' THEN
                -- Verificación conforme (o desviación autorizada): todavía NO está dentro. El ingreso físico se registra después.
                UPDATE "CAF_Solicitud_Persona"
                   SET "Estado" = 'ESPERADA', "Fecha_Hora_Ingreso" = NULL, "Fecha_Verificacion" = CURRENT_TIMESTAMP,
                       "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
            END IF;
            CALL "ERP_CAF_PROVEEDOR_RECALCULAR"(lv_sol, "HV_UsuarioID", NULL, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        END IF;
    ELSE
        SELECT COUNT(*) INTO lv_den FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = lv_sol AND "Eliminado" = 'N' AND "Estado" = 'DENTRO';
        IF lv_den = 0 AND lv_eop = 'RECEPCIONADO' THEN
            CALL "ERP_CAF_PROVEEDOR_MOVER"(lv_sol, 'SALIO', "HV_UsuarioID", NULL, NULL, NULL, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'mover: %', lv_m; END IF;
            -- Sale el camión: recién ahora queda libre la exclusa para el siguiente proveedor (D-214)
            UPDATE "CAF_Exclusa"
               SET "ID_Solicitud_Actual" = NULL, "Fecha_Ocupada" = NULL, "ID_Usuario_Ocupa" = NULL,
                   "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Actual" = lv_sol;
        ELSIF lv_den = 0 AND lv_eop = 'CIERRE_FORZADO' THEN
            -- D-218: salida registrada tarde, sobre una entrega que el sistema ya había cerrado. La exclusa ya está libre.
            -- Es un descuido de Vigilancia: se avisa al Coordinador para que tome las medidas que correspondan.
            CALL "ERP_CAF_PROVEEDOR_MOVER"(lv_sol, 'SALIO', "HV_UsuarioID", NULL, 'Salida registrada tarde: la entrega se había cerrado a la fuerza', NULL, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'mover: %', lv_m; END IF;
            SELECT S."Codigo", S."Empresa_Visitante", TO_CHAR(S."Fecha_Hora_Prevista", 'DD/MM/YYYY HH24:MI') INTO lv_cod, lv_emp, lv_fp
              FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = lv_sol;
            SELECT U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" INTO lv_quien
              FROM "CAF_GOVERNANCE"."Usuario" U WHERE U."ID_Usuario" = "HV_UsuarioID";
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_sol, 'APROBADORES', NULL, lv_dest, lv_c, lv_m);
            IF lv_dest IS NOT NULL AND LENGTH(lv_dest) > 0 THEN
                CALL "ERP_CAF_CORREO_ENCOLAR"('PROVEEDOR_AVISO', lv_sol, lv_dest, NULL,
                     'Salida tardía de proveedor en ' || lv_cod || ': Vigilancia no la registró a tiempo',
                     'SALIDA REGISTRADA FUERA DE TIEMPO' || CHR(10)
                     || 'La entrega ' || lv_cod || ' (' || COALESCE(lv_emp, '') || ', programada el ' || lv_fp || ') no tenía registrada su salida al terminar el día, por lo que el sistema la cerró y liberó la exclusa.' || CHR(10)
                     || 'Vigilancia registró la salida después: ' || COALESCE(lv_quien, 'un vigilante') || '.' || CHR(10)
                     || 'Se informa para que tome las medidas que correspondan.',
                     "HV_UsuarioID", lv_c, lv_m);
            END IF;
        END IF;
    END IF;
    "HV_Mensaje" := 'Estado operativo revisado.';
END;
$$;

-- -----------------------------------------------------------------------------
-- 9. ERP_CAF_PROVEEDOR_INGRESO_VALIDAR   (Vigilancia; EN_ESPERA -> INGRESO)               V2.0 2026-11-03
--    Registra el ingreso FÍSICO del transportista principal. Exige (1) datos verificados (EN_ESPERA: la
--    verificación ya incluyó la decisión del coordinador si hubo desviación) y (2) que Almacén haya
--    confirmado su disponibilidad, es decir, que la esclusa esté reservada para ESTA entrega. Sin la
--    reserva no hay ingreso. Reemplaza a ERP_CAF_PROVEEDOR_LLEGADA (la llegada ya no es una acción aparte).
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS "ERP_CAF_PROVEEDOR_LLEGADA"(BIGINT, BIGINT, INT, VARCHAR);
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(
    IN    "HV_ID_Solicitud"  BIGINT,
    IN    "HV_UsuarioID"     BIGINT,
    INOUT "HV_Codigo_Resp"   INT DEFAULT NULL,
    INOUT "HV_Mensaje"       VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_id BIGINT;
BEGIN
    -- V3.0 2026-11-09 (D-225): atajo de UNA persona (el transportista principal). La pantalla usa ERP_CAF_PROVEEDOR_INGRESO_FISICO,
    -- que registra el ingreso de varias personas a la vez (ver SP_CAF_PROVEEDOR_GRUPO_ALL.sql).
    SELECT MAX("ID_Solicitud_Persona") INTO lv_id FROM "CAF_Solicitud_Persona"
     WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Es_Principal" = 'Y' AND "Eliminado" = 'N';
    CALL "ERP_CAF_PROVEEDOR_INGRESO_FISICO"("HV_ID_Solicitud", COALESCE(CAST(lv_id AS VARCHAR), ''), "HV_UsuarioID", "HV_Codigo_Resp", "HV_Mensaje");
END;
$$;

-- -----------------------------------------------------------------------------
-- 9b. ERP_CAF_PROVEEDOR_RETIRO_SIN_INGRESO   (Vigilancia; EN_ESPERA -> RETIRO_SIN_INGRESO)   V1.0 2026-11-05
--    El proveedor ya fue verificado pero se va sin ingresar. Exige motivo. Libera la exclusa si Almacén ya
--    la había reservado para esta entrega y deja a la persona principal como NO_SE_PRESENTO (sale de «Por ingresar»).
--    Solo antes del ingreso físico (EN_ESPERA).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_RETIRO_SIN_INGRESO"(
    IN    "HV_ID_Solicitud"  BIGINT,
    IN    "HV_Motivo"        VARCHAR(500),
    IN    "HV_UsuarioID"     BIGINT,
    INOUT "HV_Codigo_Resp"   INT DEFAULT NULL,
    INOUT "HV_Mensaje"       VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_ids VARCHAR(2000);
BEGIN
    -- V2.0 2026-11-09 (D-225): atajo de toda la entrega verificada (EN_ESPERA): retira a TODAS sus personas por ingresar.
    -- La pantalla usa ERP_CAF_PROVEEDOR_RETIRO_PERSONAS (selección de personas).
    SELECT STRING_AGG(CAST("ID_Solicitud_Persona" AS VARCHAR), ',') INTO lv_ids FROM "CAF_Solicitud_Persona"
     WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'APROBADA' AND "Estado" = 'ESPERADA';
    CALL "ERP_CAF_PROVEEDOR_RETIRO_PERSONAS"("HV_ID_Solicitud", COALESCE(lv_ids, ''), "HV_Motivo", 'Y', "HV_UsuarioID", "HV_Codigo_Resp", "HV_Mensaje");
END;
$$;

-- -----------------------------------------------------------------------------
-- 10. ERP_CAF_PROVEEDOR_ATENDER   (Almacén; INGRESO -> EN_ATENCION)                      V3.0 2026-11-03
--     El responsable EFECTIVO es quien ejecuta la acción (ID_Usuario_Atencion y, si su usuario tiene
--     persona, ID_Personal_Almacen). El responsable PROGRAMADO no se toca ni condiciona quién atiende.
--     V3.0: ya no ocupa la esclusa; solo exige que esté reservada para esta entrega (la reserva se hace en
--     ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR) y que el proveedor ya haya ingresado.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS "ERP_CAF_PROVEEDOR_ATENDER"(BIGINT, BIGINT, BIGINT, INT, VARCHAR);
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_ATENDER"(
    IN    "HV_ID_Solicitud"        BIGINT,
    IN    "HV_UsuarioID"           BIGINT,
    INOUT "HV_Codigo_Resp"         INT DEFAULT NULL,
    INOUT "HV_Mensaje"             VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n     INT := 0;
    lv_sede  BIGINT;
    lv_fecha TIMESTAMP;
    lv_act   CHAR(1);
    lv_eop   VARCHAR(20);
    lv_per   BIGINT;
    lv_c     INT;
    lv_m     VARCHAR(250);
    lv_otro  VARCHAR(20);
BEGIN
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_ATENDER';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX(S."ID_Catalogo_Sede"), MAX(S."Fecha_Hora_Prevista") INTO lv_n, lv_sede, lv_fecha
          FROM "CAF_Solicitud" S
          JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
         WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud de proveedor no existe.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para atender proveedores.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Activa"), MAX("Estado_Operativo") INTO lv_n, lv_act, lv_eop
          FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 OR lv_act <> 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La entrega no está programada (solicitud sin aprobar o cancelada).'; RETURN;
        END IF;
        IF lv_eop <> 'INGRESO' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE WHEN lv_eop IN ('PROGRAMADO','EN_ESPERA') THEN 'Aún no ingresó ningún transportista.'
                                 WHEN lv_eop = 'INGRESO_DENEGADO' THEN 'El ingreso de este proveedor fue denegado.'
                                 WHEN lv_eop = 'RETIRO_SIN_INGRESO' THEN 'El proveedor se retiró sin ingresar.'
                                 ELSE 'La atención ya se inició o terminó.' END; RETURN;
        END IF;
        -- Solo desde el día programado (el ingreso ya prueba la presencia; pasada la medianoche sigue pudiendo atenderse)
        IF CAST(lv_fecha AS DATE) > CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La atención solo puede iniciarse el día programado de la entrega.'; RETURN;
        END IF;

        -- La esclusa ya se reservó al confirmar la disponibilidad: debe estar reservada para ESTA entrega.
        SELECT COUNT(*) INTO lv_n FROM "CAF_Exclusa"
         WHERE "ID_Catalogo_Sede" = lv_sede AND "ID_Solicitud_Actual" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            SELECT S."Codigo" INTO lv_otro FROM "CAF_Exclusa" X JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = X."ID_Solicitud_Actual"
             WHERE X."ID_Catalogo_Sede" = lv_sede;
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE WHEN lv_otro IS NOT NULL THEN 'La esclusa está reservada para otra entrega (' || lv_otro || ').'
                                 ELSE 'Almacén no confirmó su disponibilidad para esta entrega.' END; RETURN;
        END IF;

        SELECT MAX("ID_Personal") INTO lv_per FROM "CAF_GOVERNANCE"."Usuario" WHERE "ID_Usuario" = "HV_UsuarioID";
        CALL "ERP_CAF_PROVEEDOR_MOVER"("HV_ID_Solicitud", 'EN_ATENCION', "HV_UsuarioID", NULL, NULL, lv_per, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'mover: %', lv_m; END IF;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Atención iniciada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_ATENDER';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 11. ERP_CAF_PROVEEDOR_RECEPCION   (Almacén; EN_ATENCION -> RECEPCIONADO; con observación exige descripción)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_RECEPCION"(
    IN    "HV_ID_Solicitud"  BIGINT,
    IN    "HV_Resultado"     VARCHAR(20),
    IN    "HV_Observacion"   VARCHAR(1000),
    IN    "HV_UsuarioID"     BIGINT,
    INOUT "HV_Codigo_Resp"   INT DEFAULT NULL,
    INOUT "HV_Mensaje"       VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n    INT := 0;
    lv_sede BIGINT;
    lv_act  CHAR(1);
    lv_eop  VARCHAR(20);
    lv_res  VARCHAR(20) := UPPER(TRIM(COALESCE("HV_Resultado", '')));
    lv_c    INT;
    lv_m    VARCHAR(250);
BEGIN
    -- V1.0 2026-11-02
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_RECEPCION';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF lv_res NOT IN ('CONFORME','CON_OBSERVACION') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El resultado debe ser CONFORME o CON_OBSERVACION.'; RETURN;
        END IF;
        IF lv_res = 'CON_OBSERVACION' AND NULLIF(TRIM(COALESCE("HV_Observacion", '')), '') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Describa la observación de la recepción.'; RETURN;
        END IF;
        IF LENGTH(COALESCE("HV_Observacion", '')) > 1000 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La observación no puede superar 1000 caracteres.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX(S."ID_Catalogo_Sede") INTO lv_n, lv_sede
          FROM "CAF_Solicitud" S
          JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
         WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud de proveedor no existe.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para recepcionar proveedores.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Activa"), MAX("Estado_Operativo") INTO lv_n, lv_act, lv_eop
          FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 OR lv_act <> 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La entrega no está programada (solicitud sin aprobar o cancelada).'; RETURN;
        END IF;
        IF lv_eop <> 'EN_ATENCION' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE WHEN lv_eop = 'RECEPCIONADO' OR lv_eop = 'SALIO' THEN 'La entrega ya fue recepcionada.'
                                 ELSE 'La atención aún no se inició.' END; RETURN;
        END IF;
        CALL "ERP_CAF_PROVEEDOR_MOVER"("HV_ID_Solicitud", 'RECEPCIONADO', "HV_UsuarioID", lv_res, "HV_Observacion", NULL, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'mover: %', lv_m; END IF;
        -- V5.0 2026-11-09 (D-225): quien no llegó a ingresar queda como «no ingresó» (con constancia en el historial)
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'APROBADA' AND "Estado" = 'ESPERADA';
        IF lv_n > 0 THEN
            UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'NO_SE_PRESENTO', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'APROBADA' AND "Estado" = 'ESPERADA';
            INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion")
            VALUES ("HV_ID_Solicitud", 'RECEPCIONADO', 'RECEPCIONADO', "HV_UsuarioID", 'No ingresó: ' || lv_n || ' persona(s) quedaron sin ingresar al recepcionarse la entrega');
        END IF;
        -- Si ya no hay nadie dentro (los vehículos salieron uno a uno), la entrega termina aquí y se libera la exclusa
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Estado" = 'DENTRO';
        IF lv_n = 0 THEN
            CALL "ERP_CAF_PROVEEDOR_MOVER"("HV_ID_Solicitud", 'SALIO', "HV_UsuarioID", NULL, 'Todos salieron antes de la recepción', NULL, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'mover: %', lv_m; END IF;
            UPDATE "CAF_Exclusa"
               SET "ID_Solicitud_Actual" = NULL, "Fecha_Ocupada" = NULL, "ID_Usuario_Ocupa" = NULL,
                   "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Actual" = "HV_ID_Solicitud";
        END IF;
        -- V4.0: la exclusa NO se libera aquí: el camión sigue dentro y sale por la misma exclusa. La libera la salida (PORTERIA_POST).
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Recepción registrada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_RECEPCION';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 10. ERP_CAF_PARAMETRO_VALOR / ERP_CAF_PARAMETRO_GUARDAR   (D-218)
--     Parámetros del sistema (clave/valor). Hoy: PROVEEDOR_HORA_CORTE (HH:MM, por defecto 00:00).
--     GUARDAR solo la usa quien administra la base (no hay pantalla todavía): valida el formato de la hora.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PARAMETRO_VALOR"("HV_Clave" VARCHAR)
RETURNS VARCHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_v VARCHAR;
BEGIN
    -- V1.0 2026-11-06
    SELECT "Valor" INTO lv_v FROM "CAF_Parametro" WHERE "Clave" = "HV_Clave" AND "Eliminado" = 'N';
    RETURN lv_v;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PARAMETRO_GUARDAR"(
    IN    "HV_Clave"       VARCHAR(60),
    IN    "HV_Valor"       VARCHAR(200),
    IN    "HV_UsuarioID"   BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje"     VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-11-06
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PARAMETRO_GUARDAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Parametro" WHERE "Clave" = "HV_Clave" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El parámetro no existe.'; RETURN;
        END IF;
        IF "HV_Clave" = 'EXCLUSA_CAPACIDAD' AND COALESCE("HV_Valor", '') !~ '^[1-9][0-9]?$' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La capacidad debe ser un número entero de 1 a 99.'; RETURN;
        END IF;
        IF "HV_Clave" = 'PROVEEDOR_HORA_CORTE' AND COALESCE("HV_Valor", '') !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La hora de corte debe tener el formato HH:MM (de 00:00 a 23:59).'; RETURN;
        END IF;
        UPDATE "CAF_Parametro" SET "Valor" = "HV_Valor", "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "Clave" = "HV_Clave";
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Parámetro guardado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PARAMETRO_GUARDAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 11. ERP_CAF_PROVEEDOR_CIERRE_DIA   (D-218)
--     Cierre forzado del día. Idempotente y barato: la llaman el servicio en segundo plano cada minuto y,
--     como red de seguridad, el calendario, la lista de Vigilancia y «Confirmar disponibilidad».
--     Día operativo = fecha de (ahora − hora de corte). Toda entrega activa cuya fecha prevista sea ANTERIOR
--     al día operativo y siga abierta se cierra:
--       PROGRAMADO                                        -> NO_SE_PRESENTO
--       EN_ESPERA, INGRESO, EN_ATENCION, RECEPCIONADO     -> CIERRE_FORZADO
--     Se libera la exclusa si la tenía, y las personas que seguían ESPERADAS pasan a NO_SE_PRESENTO. Quien ya
--     estaba DENTRO sigue DENTRO: Vigilancia aún puede registrar su salida (queda como salida tardía y avisa al Coordinador).
--     Todo en sentencias de conjunto (sin ciclos), y queda en el historial operativo como acción del sistema.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_CIERRE_DIA"(
    IN    "HV_UsuarioID"   BIGINT,
    INOUT "HV_Cerradas"    INT DEFAULT NULL,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje"     VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_corte VARCHAR(10);
    lv_dia   DATE;
    lv_cc    INT;
    lv_c     INT;
    lv_m     VARCHAR(250);
BEGIN
    -- V1.1 2026-11-09 (D-227: también cierra a los contratistas que siguieron dentro)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_CIERRE_DIA';
    "HV_Cerradas"    := 0;
    BEGIN
        lv_corte := COALESCE("ERP_CAF_PARAMETRO_VALOR"('PROVEEDOR_HORA_CORTE'), '00:00');
        lv_dia   := CAST(CAST(CURRENT_TIMESTAMP AS TIMESTAMP) - CAST(lv_corte AS INTERVAL) AS DATE);

        CREATE TEMP TABLE IF NOT EXISTS "tmp_cierre_dia" ("ID_Solicitud" BIGINT, "Anterior" VARCHAR(20), "Nuevo" VARCHAR(20)) ON COMMIT DROP;
        DELETE FROM "tmp_cierre_dia";
        INSERT INTO "tmp_cierre_dia" ("ID_Solicitud", "Anterior", "Nuevo")
        SELECT O."ID_Solicitud", O."Estado_Operativo",
               CASE WHEN O."Estado_Operativo" = 'PROGRAMADO' THEN 'NO_SE_PRESENTO' ELSE 'CIERRE_FORZADO' END
          FROM "CAF_Solicitud_Operacion" O
          JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = O."ID_Solicitud"
         WHERE O."Activa" = 'Y' AND O."Eliminado" = 'N'
           AND O."Estado_Operativo" IN ('PROGRAMADO','EN_ESPERA','INGRESO','EN_ATENCION','RECEPCIONADO')
           AND CAST(S."Fecha_Hora_Prevista" AS DATE) < lv_dia;
        SELECT COUNT(*) INTO "HV_Cerradas" FROM "tmp_cierre_dia";

        IF "HV_Cerradas" > 0 THEN
            UPDATE "CAF_Exclusa"
               SET "ID_Solicitud_Actual" = NULL, "Fecha_Ocupada" = NULL, "ID_Usuario_Ocupa" = NULL,
                   "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Actual" IN (SELECT "ID_Solicitud" FROM "tmp_cierre_dia");
            UPDATE "CAF_Solicitud_Persona"
               SET "Estado" = 'NO_SE_PRESENTO', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" IN (SELECT "ID_Solicitud" FROM "tmp_cierre_dia") AND "Eliminado" = 'N' AND "Estado" = 'ESPERADA';
            INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion")
            SELECT T."ID_Solicitud", T."Anterior", T."Nuevo", "HV_UsuarioID",
                   'Cierre automático del día (hora de corte ' || lv_corte || ')' FROM "tmp_cierre_dia" T;
            UPDATE "CAF_Solicitud_Operacion" O
               SET "Estado_Operativo" = T."Nuevo", "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
              FROM "tmp_cierre_dia" T WHERE O."ID_Solicitud" = T."ID_Solicitud";
        END IF;
        -- D-227: el cierre forzado del día de los contratistas va con el mismo reloj (misma hora de corte)
        CALL "ERP_CAF_CONTRATISTA_CIERRE_DIA"(lv_dia, "HV_UsuarioID", lv_cc, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'contratista: %', lv_m; END IF;
        "HV_Cerradas" := "HV_Cerradas" + COALESCE(lv_cc, 0);
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Cierre del día revisado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_CIERRE_DIA';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 12. ERP_CAF_PROVEEDOR_AVISOS_SALIDA   (D-218)
--     Aviso por correo a Vigilancia (copia a Almacén) de cada entrega RECEPCIONADA (la exclusa sigue ocupada,
--     «por salir») cuya salida no se registró: el primero a la hora de recibida y luego uno por hora. Dice
--     cuándo se cerrará a la fuerza. La llama el servicio en segundo plano cada minuto; no repite antes de una hora.
--     OJO HANA (T-33): usa un ciclo FOR; en HANA se recorre desde la aplicación o con una tabla temporal.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_AVISOS_SALIDA"(
    IN    "HV_UsuarioID"   BIGINT,
    INOUT "HV_Avisados"    INT DEFAULT NULL,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje"     VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    r        RECORD;
    lv_corte VARCHAR(10);
    lv_dest  VARCHAR(2000);
    lv_copia VARCHAR(2000);
    lv_c     INT;
    lv_m     VARCHAR(250);
    lv_hrs   INT;
BEGIN
    -- V1.0 2026-11-06
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_AVISOS_SALIDA';
    "HV_Avisados"    := 0;
    BEGIN
        lv_corte := COALESCE("ERP_CAF_PARAMETRO_VALOR"('PROVEEDOR_HORA_CORTE'), '00:00');
        FOR r IN
            SELECT O."ID_Solicitud", S."Codigo", S."Empresa_Visitante", O."Fecha_Recepcion"
              FROM "CAF_Solicitud_Operacion" O
              JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = O."ID_Solicitud"
             WHERE O."Activa" = 'Y' AND O."Eliminado" = 'N' AND O."Estado_Operativo" = 'RECEPCIONADO'
               AND O."Fecha_Recepcion" <= CURRENT_TIMESTAMP - INTERVAL '1 hour'
               AND (O."Ultimo_Aviso_Salida" IS NULL OR O."Ultimo_Aviso_Salida" <= CURRENT_TIMESTAMP - INTERVAL '1 hour')
             ORDER BY O."ID_Solicitud"
        LOOP
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(r."ID_Solicitud", 'PORTERIA', NULL, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(r."ID_Solicitud", 'ALMACEN', NULL, lv_copia, lv_c, lv_m);
            lv_hrs := CAST(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - r."Fecha_Recepcion")) / 3600 AS INT);
            IF lv_dest IS NOT NULL AND LENGTH(lv_dest) > 0 THEN
                CALL "ERP_CAF_CORREO_ENCOLAR"('PROVEEDOR_AVISO', r."ID_Solicitud", lv_dest, lv_copia,
                     'Salida pendiente: ' || r."Codigo" || ' sigue con la exclusa ocupada',
                     'SALIDA PENDIENTE' || CHR(10)
                     || 'La entrega ' || r."Codigo" || ' (' || COALESCE(r."Empresa_Visitante", '') || ') fue recepcionada a las ' || TO_CHAR(r."Fecha_Recepcion", 'HH24:MI')
                     || ' (hace ' || lv_hrs || ' h) y su salida no está registrada: la exclusa sigue ocupada y no puede usarla otro proveedor.' || CHR(10)
                     || 'Registre la salida en Control de accesos. Si sigue abierta al llegar la hora de corte (' || lv_corte || '), el sistema cerrará la entrega a la fuerza y avisará al Coordinador.',
                     "HV_UsuarioID", lv_c, lv_m);
                IF lv_c <> 100 THEN RAISE EXCEPTION 'correo: %', lv_m; END IF;
                "HV_Avisados" := "HV_Avisados" + 1;
            END IF;
            UPDATE "CAF_Solicitud_Operacion" SET "Ultimo_Aviso_Salida" = CURRENT_TIMESTAMP WHERE "ID_Solicitud" = r."ID_Solicitud";
        END LOOP;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Avisos de salida revisados.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_AVISOS_SALIDA';
    END;
END;
$$;
