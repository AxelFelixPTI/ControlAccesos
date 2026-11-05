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
--      * PROVEEDOR: sede con Aplica_Proveedor, RUC de 11 dígitos, dirección, marca, placa (5 a 8 letras o
--        números), licencia de conducir, teléfono (mínimo 6 dígitos) y empresa Trianon destinataria activa.
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

    IF COALESCE(TRIM("HV_Proveedor_RUC"), '') !~ '^[0-9]{11}$' THEN RETURN 'Indique el RUC del proveedor (11 dígitos).'; END IF;
    IF NULLIF(TRIM(COALESCE("HV_Proveedor_Direccion", '')), '') IS NULL THEN RETURN 'Indique la dirección del proveedor.'; END IF;
    IF NULLIF(TRIM(COALESCE("HV_Vehiculo_Marca", '')), '') IS NULL THEN RETURN 'Indique la marca del vehículo.'; END IF;
    lv_placa := "ERP_CAF_FN_PLACA_NORMALIZAR"("HV_Placa_Vehiculo");
    IF lv_placa IS NULL OR lv_placa !~ '^[A-Z0-9]{5,8}$' THEN RETURN 'Indique la placa del vehículo (de 5 a 8 letras o números).'; END IF;
    IF NULLIF(TRIM(COALESCE("HV_Licencia_Conducir", '')), '') IS NULL THEN RETURN 'Indique la licencia de conducir del transportista.'; END IF;
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
    -- V1.0 2026-11-02
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

        SELECT MAX("Aprobacion") INTO lv_apr FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Es_Principal" = 'Y';
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
        ELSIF lv_debe = 'N' AND lv_act = 'Y' AND lv_eop = 'PROGRAMADO' THEN
            UPDATE "CAF_Solicitud_Operacion" SET "Activa" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud";
            INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion")
            VALUES ("HV_ID_Solicitud", lv_eop, lv_eop, "HV_UsuarioID",
                    CASE WHEN lv_estado = 'CANCELADA' THEN 'Desactivada: solicitud cancelada' ELSE 'Desactivada: el transportista principal ya no está aprobado' END);
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
    lv_prin CHAR(1);
    lv_op   INT := 0;
    lv_act  CHAR(1);
    lv_eop  VARCHAR(20);
    lv_cod  INT := 100;
    lv_msg  VARCHAR(250) := NULL;
    lv_prev TIMESTAMP;
BEGIN
    -- V2.0 2026-11-03
    SELECT COUNT(*), MAX(P."Es_Principal"), MAX(S."Fecha_Hora_Prevista") INTO lv_n, lv_prin, lv_prev
      FROM "CAF_Solicitud_Persona" P
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
      JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
     WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
    IF lv_n > 0 THEN
        SELECT COUNT(*), MAX(O."Activa"), MAX(O."Estado_Operativo") INTO lv_op, lv_act, lv_eop
          FROM "CAF_Solicitud_Operacion" O
          JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud" = O."ID_Solicitud"
         WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND O."Eliminado" = 'N';
        IF lv_op = 0 OR lv_act <> 'Y' THEN
            lv_cod := 409; lv_msg := 'La entrega del proveedor no está programada: el transportista principal debe estar aprobado.';
        ELSIF UPPER(COALESCE("HV_Etapa", '')) = 'INGRESO' THEN
            IF lv_prin = 'Y' THEN
                -- Este movimiento es la VERIFICACIÓN de datos (registra la llegada); el ingreso físico se valida aparte.
                IF COALESCE("HV_Tardio", 'N') <> 'Y' THEN
                    IF lv_eop <> 'PROGRAMADO' THEN
                        lv_cod := 409;
                        lv_msg := CASE WHEN lv_eop = 'EN_ESPERA' THEN 'Los datos del proveedor ya fueron verificados: espere la disponibilidad de Almacén y valide el ingreso.'
                                       WHEN lv_eop = 'INGRESO_DENEGADO' THEN 'El ingreso de este proveedor fue denegado.'
                                       WHEN lv_eop = 'RETIRO_SIN_INGRESO' THEN 'El proveedor se retiró sin ingresar.'
                                       ELSE 'El transportista principal ya ingresó.' END;
                    ELSIF CAST(lv_prev AS DATE) <> CURRENT_DATE THEN
                        lv_cod := 409; lv_msg := 'La entrega es para otra fecha.';
                    END IF;
                ELSIF lv_eop NOT IN ('PROGRAMADO','EN_ESPERA') THEN
                    lv_cod := 409; lv_msg := 'El transportista principal ya ingresó o su ingreso fue denegado.';
                END IF;
            ELSIF lv_eop NOT IN ('INGRESO','EN_ATENCION','RECEPCIONADO') THEN
                lv_cod := 409; lv_msg := 'Primero debe ingresar el transportista principal.';
            END IF;
        ELSIF UPPER(COALESCE("HV_Etapa", '')) = 'SALIDA' AND lv_prin = 'Y' AND lv_eop NOT IN ('RECEPCIONADO','SALIO') THEN
            lv_cod := 409; lv_msg := 'El transportista principal sale cuando Almacén recepciona la entrega.';
        END IF;
    END IF;
    RETURN QUERY SELECT lv_cod, CAST(COALESCE(lv_msg, 'Puede registrarse.') AS VARCHAR);
END;
$$;

-- -----------------------------------------------------------------------------
-- 8. ERP_CAF_PROVEEDOR_PORTERIA_POST  (interna; la llaman ingreso y salida de portería ya registrados)
--    INGRESO del principal (quedó DENTRO)  : PROGRAMADO o EN_ESPERA -> INGRESO.
--    SALIDA: si ya nadie de la solicitud está DENTRO y estaba RECEPCIONADO -> SALIO.
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
    lv_prin CHAR(1);
    lv_est  VARCHAR(20);
    lv_eop  VARCHAR(20);
    lv_act  CHAR(1);
    lv_den  INT := 0;
    lv_c    INT;
    lv_m    VARCHAR(250);
    lv_desv CHAR(1) := 'N';
BEGIN
    -- V2.0 2026-11-03
    "HV_Codigo_Resp" := 100;
    "HV_Mensaje"     := 'No aplica.';
    IF "ERP_CAF_FN_ES_PROVEEDOR"("HV_ID_Solicitud_Persona") <> 'Y' THEN RETURN; END IF;
    SELECT P."ID_Solicitud", P."Es_Principal", P."Estado" INTO lv_sol, lv_prin, lv_est
      FROM "CAF_Solicitud_Persona" P WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
    SELECT "Estado_Operativo", "Activa" INTO lv_eop, lv_act FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = lv_sol;
    IF lv_eop IS NULL OR lv_act <> 'Y' THEN RETURN; END IF;

    IF "HV_Etapa" = 'INGRESO' THEN
        IF lv_prin = 'Y' AND lv_eop IN ('PROGRAMADO','EN_ESPERA') THEN
            -- El movimiento de portería del principal es la VERIFICACIÓN: la decisión del coordinador ya viene
            -- registrada en la desviación (si la hubo). No es el ingreso físico.
            SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END INTO lv_desv
              FROM "CAF_Desviacion" D JOIN "CAF_Registro_Acceso" R ON R."ID_Registro_Acceso" = D."ID_Registro_Acceso"
             WHERE R."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND R."Tipo_Movimiento" = 'INGRESO' AND D."Eliminado" = 'N';
            UPDATE "CAF_Solicitud_Operacion" SET "Con_Desviacion" = lv_desv, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = lv_sol;
            IF lv_est = 'DENEGADA' THEN
                CALL "ERP_CAF_PROVEEDOR_MOVER"(lv_sol, 'INGRESO_DENEGADO', "HV_UsuarioID", NULL, 'Ingreso denegado en la verificación de datos', NULL, lv_c, lv_m);
                IF lv_c <> 100 THEN RAISE EXCEPTION 'mover: %', lv_m; END IF;
                UPDATE "CAF_Exclusa"
                   SET "ID_Solicitud_Actual" = NULL, "Fecha_Ocupada" = NULL, "ID_Usuario_Ocupa" = NULL,
                       "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Solicitud_Actual" = lv_sol;
            ELSIF lv_est = 'DENTRO' THEN
                -- Verificación conforme (o desviación autorizada): todavía NO está dentro. El ingreso físico lo valida Vigilancia después.
                UPDATE "CAF_Solicitud_Persona"
                   SET "Estado" = 'ESPERADA', "Fecha_Hora_Ingreso" = NULL, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
                IF lv_eop = 'PROGRAMADO' THEN
                    CALL "ERP_CAF_PROVEEDOR_MOVER"(lv_sol, 'EN_ESPERA', "HV_UsuarioID", NULL,
                          CASE WHEN lv_desv = 'Y' THEN 'Verificación de datos con desviación autorizada' ELSE 'Verificación de datos conforme' END, NULL, lv_c, lv_m);
                    IF lv_c <> 100 THEN RAISE EXCEPTION 'mover: %', lv_m; END IF;
                END IF;
            END IF;
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
    lv_n     INT := 0;
    lv_sede  BIGINT;
    lv_act   CHAR(1);
    lv_eop   VARCHAR(20);
    lv_pest  VARCHAR(20);
    lv_c     INT;
    lv_m     VARCHAR(250);
BEGIN
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_INGRESO_VALIDAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX(S."ID_Catalogo_Sede") INTO lv_n, lv_sede
          FROM "CAF_Solicitud" S
          JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
         WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud de proveedor no existe.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_VIGILANCIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para registrar el ingreso de proveedores.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Activa"), MAX("Estado_Operativo") INTO lv_n, lv_act, lv_eop
          FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 OR lv_act <> 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La entrega no está programada (solicitud sin aprobar o cancelada).'; RETURN;
        END IF;
        IF lv_eop <> 'EN_ESPERA' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE lv_eop WHEN 'PROGRAMADO' THEN 'Primero debe verificar los datos del proveedor.'
                                        WHEN 'INGRESO_DENEGADO' THEN 'El ingreso de este proveedor fue denegado.'
                                        WHEN 'RETIRO_SIN_INGRESO' THEN 'El proveedor se retiró sin ingresar.'
                                        WHEN 'NO_SE_PRESENTO' THEN 'La entrega figura como «no se presentó».'
                                        WHEN 'RETIRO_SIN_INGRESO' THEN 'El proveedor se retiró sin ingresar.'
                                        ELSE 'El proveedor ya ingresó.' END; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Exclusa"
         WHERE "ID_Catalogo_Sede" = lv_sede AND "ID_Solicitud_Actual" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Almacén aún no confirmó su disponibilidad para recibir a este proveedor.'; RETURN;
        END IF;
        SELECT MAX("Estado") INTO lv_pest FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Es_Principal" = 'Y' AND "Eliminado" = 'N';
        IF lv_pest IS NULL OR lv_pest <> 'ESPERADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'El transportista principal no está pendiente de ingreso.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud_Persona"
           SET "Estado" = 'DENTRO', "Fecha_Hora_Ingreso" = CURRENT_TIMESTAMP, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Es_Principal" = 'Y' AND "Eliminado" = 'N';
        CALL "ERP_CAF_PROVEEDOR_MOVER"("HV_ID_Solicitud", 'INGRESO', "HV_UsuarioID", NULL, 'Ingreso físico validado', NULL, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'mover: %', lv_m; END IF;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ingreso registrado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_INGRESO_VALIDAR';
    END;
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
    lv_n     INT := 0;
    lv_sede  BIGINT;
    lv_act   CHAR(1);
    lv_eop   VARCHAR(20);
    lv_mot   VARCHAR(500);
    lv_c     INT;
    lv_m     VARCHAR(250);
BEGIN
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_RETIRO_SIN_INGRESO';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        lv_mot := TRIM(COALESCE("HV_Motivo", ''));
        IF LENGTH(lv_mot) < 3 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el motivo del retiro.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX(S."ID_Catalogo_Sede") INTO lv_n, lv_sede
          FROM "CAF_Solicitud" S
          JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
         WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud de proveedor no existe.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_VIGILANCIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para registrar el retiro de proveedores.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Activa"), MAX("Estado_Operativo") INTO lv_n, lv_act, lv_eop
          FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 OR lv_act <> 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La entrega no está programada (solicitud sin aprobar o cancelada).'; RETURN;
        END IF;
        IF lv_eop <> 'EN_ESPERA' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE lv_eop WHEN 'PROGRAMADO' THEN 'Solo se registra el retiro de un proveedor ya verificado.'
                                        WHEN 'RETIRO_SIN_INGRESO' THEN 'El proveedor ya figura como retirado sin ingresar.'
                                        WHEN 'INGRESO_DENEGADO' THEN 'El ingreso de este proveedor fue denegado.'
                                        WHEN 'NO_SE_PRESENTO' THEN 'La entrega figura como «no se presentó».'
                                        ELSE 'El proveedor ya ingresó: no se registra como retirado sin ingresar.' END; RETURN;
        END IF;
        UPDATE "CAF_Exclusa"
           SET "ID_Solicitud_Actual" = NULL, "Fecha_Ocupada" = NULL, "ID_Usuario_Ocupa" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Sede" = lv_sede AND "ID_Solicitud_Actual" = "HV_ID_Solicitud";
        UPDATE "CAF_Solicitud_Persona"
           SET "Estado" = 'NO_SE_PRESENTO', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Es_Principal" = 'Y' AND "Eliminado" = 'N' AND "Estado" = 'ESPERADA';
        CALL "ERP_CAF_PROVEEDOR_MOVER"("HV_ID_Solicitud", 'RETIRO_SIN_INGRESO', "HV_UsuarioID", 'RETIRO_SIN_INGRESO', 'Retiro sin ingresar: ' || lv_mot, NULL, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'mover: %', lv_m; END IF;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Retiro registrado. La esclusa quedó libre.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_RETIRO_SIN_INGRESO';
    END;
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
            "HV_Mensaje" := CASE WHEN lv_eop IN ('PROGRAMADO','EN_ESPERA') THEN 'El transportista principal aún no ingresó.'
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
        -- V4.0: la exclusa NO se libera aquí: el camión sigue dentro y sale por la misma exclusa. La libera la salida (PORTERIA_POST).
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Recepción registrada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_RECEPCION';
    END;
END;
$$;
