-- =============================================================================
-- Archivo : SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobacion | Fase 1 - Procedimientos (Entrega 2 de Proveedor de abastecimiento)
-- Entidad : CAF_Solicitud_Operacion / CAF_Exclusa (calendario de entregas de Almacen)
-- Version : V2.0 2026-11-03 (flujo corregido: disponibilidad de Almacen reserva la esclusa)
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO2_ESCRITURA.sql, seccion P)
-- Requiere: scripts 01 a 19 y SP_CAF_PROVEEDOR_ALL.sql.
-- =============================================================================
-- 1 ERP_CAF_PROVEEDOR_RESPONSABLES   personal de Almacen que puede ser responsable programado
-- 2 ERP_CAF_PROVEEDOR_PROGRAMAR      asigna / cambia / quita el responsable programado (Almacen)
-- 3 ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO para quien esta reservada u ocupada la esclusa ahora
-- 4 ERP_CAF_PROVEEDOR_CALENDARIO     entregas aprobadas de un rango de fechas, con lo que el usuario puede hacer
-- 5 ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR  Almacen declara que puede recibir: RESERVA la esclusa (atomico, una por sede)
-- 6 ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR   Almacen retira la disponibilidad (con motivo) y libera la esclusa
-- Lectura: exige PER_CAF_PROVEEDOR_DASHBOARD. Acciones: exigen PER_CAF_PROVEEDOR_ALMACEN.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_PROVEEDOR_RESPONSABLES
--    Personal activo cuyo usuario activo tiene la licencia LIC_CAF_ALMACEN en la sede.
--    Quien no tiene el permiso de Almacen recibe la lista vacia.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_RESPONSABLES"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT
)
RETURNS TABLE ("ID_Personal" BIGINT, "Nombre" VARCHAR, "Cargo" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-03
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', "HV_ID_Catalogo_Sede") <> 'Y' THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT DISTINCT P."ID_Personal",
           CAST(P."Apellido_Paterno" || COALESCE(' ' || P."Apellido_Materno", '') || ', ' || P."Nombres" AS VARCHAR) AS "Nombre",
           CAST(C."Descripcion" AS VARCHAR) AS "Cargo"
      FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
      JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia"
                                                  AND L."Codigo" = 'LIC_CAF_ALMACEN' AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
      JOIN "CAF_GOVERNANCE"."Usuario" U  ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
      JOIN "CAF_GOVERNANCE"."Personal" P ON P."ID_Personal" = U."ID_Personal" AND P."Eliminado" = 'N' AND P."Activo" = 'Y'
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Cargo" C ON C."ID_Catalogo_Cargo" = P."ID_Catalogo_Cargo"
     WHERE UL."Eliminado" = 'N' AND UL."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
     ORDER BY 2;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_PROVEEDOR_PROGRAMAR
--    Responsable PROGRAMADO: informativo, opcional, no obliga ni impide que otro atienda. NULL lo quita.
--    Disponible desde la aprobacion hasta el dia programado, mientras no se inicie la atencion.
--    Cada cambio deja un evento (el programado anterior no se pierde).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_PROGRAMAR"(
    IN    "HV_ID_Solicitud" BIGINT,
    IN    "HV_ID_Personal"  BIGINT,
    IN    "HV_UsuarioID"    BIGINT,
    INOUT "HV_Codigo_Resp"  INT DEFAULT NULL,
    INOUT "HV_Mensaje"      VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n     INT := 0;
    lv_sede  BIGINT;
    lv_fecha TIMESTAMP;
    lv_act   CHAR(1);
    lv_eop   VARCHAR(20);
    lv_ant   BIGINT;
    lv_nom   VARCHAR(400);
BEGIN
    -- V1.0 2026-11-03
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_PROGRAMAR';
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
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para asignar responsables de atención.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Activa"), MAX("Estado_Operativo"), MAX("ID_Personal_Programado") INTO lv_n, lv_act, lv_eop, lv_ant
          FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 OR lv_act <> 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La entrega no está programada (solicitud sin aprobar o cancelada).'; RETURN;
        END IF;
        IF lv_eop NOT IN ('PROGRAMADO','EN_ESPERA','INGRESO') THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE WHEN lv_eop = 'NO_SE_PRESENTO' THEN 'La entrega figura como «no se presentó».'
                                 WHEN lv_eop = 'CIERRE_FORZADO' THEN 'La entrega fue cerrada al terminar su día.'
                                 ELSE 'La atención ya se inició: el responsable programado no se cambia.' END; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la entrega ya pasó.'; RETURN;
        END IF;
        IF "HV_ID_Personal" IS NOT NULL THEN
            SELECT COUNT(*) INTO lv_n FROM "ERP_CAF_PROVEEDOR_RESPONSABLES"("HV_UsuarioID", lv_sede) R WHERE R."ID_Personal" = "HV_ID_Personal";
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La persona elegida no es personal de Almacén autorizado en esta sede.'; RETURN;
            END IF;
        END IF;
        IF lv_ant IS NOT DISTINCT FROM "HV_ID_Personal" THEN
            "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Sin cambios.'; RETURN;
        END IF;

        UPDATE "CAF_Solicitud_Operacion"
           SET "ID_Personal_Programado" = "HV_ID_Personal",
               "ID_Usuario_Programacion" = "HV_UsuarioID",
               "Fecha_Programacion" = CURRENT_TIMESTAMP,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT MAX(P."Apellido_Paterno" || COALESCE(' ' || P."Apellido_Materno", '') || ', ' || P."Nombres") INTO lv_nom
          FROM "CAF_GOVERNANCE"."Personal" P WHERE P."ID_Personal" = "HV_ID_Personal";
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion","ID_Personal_Programado")
        VALUES ("HV_ID_Solicitud", lv_eop, lv_eop, "HV_UsuarioID",
                CASE WHEN "HV_ID_Personal" IS NULL THEN 'Se quitó el responsable programado'
                     WHEN lv_ant IS NULL THEN 'Responsable programado: ' || lv_nom
                     ELSE 'Cambio de responsable programado: ' || lv_nom END,
                "HV_ID_Personal");
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN "HV_ID_Personal" IS NULL THEN 'Responsable programado retirado.' ELSE 'Responsable programado asignado.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_PROGRAMAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO
--    Estado: LIBRE | RESERVADA (disponibilidad confirmada, aun no ingresa) | DENTRO (ingreso validado, aun
--    sin atencion) | EN_ATENCION. Una reserva sin operacion vigente (huerfana) se muestra como LIBRE.
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS "ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO"(BIGINT, BIGINT);
CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT
)
RETURNS TABLE ("Ocupada" CHAR, "Estado" VARCHAR, "ID_Solicitud" BIGINT, "Codigo" VARCHAR, "Empresa" VARCHAR,
               "Desde" TIMESTAMP, "Atiende" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V2.2 2026-11-06: + Puede_Cancelar_Sol / Motivo_No_Cancelar_Sol (botones propios de la solicitud en la tarjeta)
    -- V2.1 2026-11-06: + Es_Solicitante (la solicitud es del usuario que consulta; habilita el acceso directo a «Mis solicitudes»)
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_DASHBOARD', "HV_ID_Catalogo_Sede") <> 'Y' THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT CAST(CASE WHEN O."ID_Solicitud" IS NULL THEN 'N' ELSE 'Y' END AS CHAR),
           CAST(CASE O."Estado_Operativo" WHEN 'EN_ESPERA' THEN 'RESERVADA' WHEN 'INGRESO' THEN 'DENTRO'
                                          WHEN 'EN_ATENCION' THEN 'EN_ATENCION' WHEN 'RECEPCIONADO' THEN 'POR_SALIR' ELSE 'LIBRE' END AS VARCHAR),
           O."ID_Solicitud", S."Codigo", S."Empresa_Visitante", X."Fecha_Ocupada",
           CAST(COALESCE(P."Apellido_Paterno" || COALESCE(' ' || P."Apellido_Materno", '') || ', ' || P."Nombres",
                         U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres") AS VARCHAR)
      FROM "CAF_Exclusa" X
      LEFT JOIN "CAF_Solicitud_Operacion" O ON O."ID_Solicitud" = X."ID_Solicitud_Actual"
                                           AND O."Estado_Operativo" IN ('EN_ESPERA','INGRESO','EN_ATENCION','RECEPCIONADO') AND O."Activa" = 'Y'
      LEFT JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = O."ID_Solicitud"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = O."ID_Usuario_Atencion"
      LEFT JOIN "CAF_GOVERNANCE"."Personal" P ON P."ID_Personal" = U."ID_Personal"
     WHERE X."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND X."Eliminado" = 'N';
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_PROVEEDOR_CALENDARIO
--    Solo entregas con operacion ACTIVA (transportista principal aprobado y solicitud no cancelada).
--    Puede_*: lo que ESTE usuario puede hacer ahora (permiso de Almacen + estado + esclusa); la pantalla solo
--    muestra el boton, el procedimiento de la accion vuelve a validar todo.
--      Puede_Confirmar     : EN_ESPERA, es el dia programado y la esclusa no esta reservada para otra entrega
--      Puede_Cancelar_Disp : EN_ESPERA con la esclusa reservada para ESTA entrega (aun no ingreso)
--      Puede_Atender       : INGRESO con la esclusa reservada para esta entrega
--      Puede_Terminar      : EN_ATENCION
--    Motivo_Bloqueo: por que una entrega EN_ESPERA no puede recibir la confirmacion todavia.
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS "ERP_CAF_PROVEEDOR_CALENDARIO"(BIGINT, BIGINT, DATE, DATE);
CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_CALENDARIO"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT,
    "HV_Fecha_Desde"      DATE,
    "HV_Fecha_Hasta"      DATE
)
RETURNS TABLE ("ID_Solicitud" BIGINT, "Codigo" VARCHAR, "Fecha_Hora_Prevista" TIMESTAMP,
               "Empresa_Proveedor" VARCHAR, "Proveedor_RUC" VARCHAR, "Empresa_Destino" VARCHAR,
               "Empresa_Destino_Codigo" VARCHAR,
               "Transportista" VARCHAR, "Telefono" VARCHAR, "Placa" VARCHAR, "Vehiculo_Marca" VARCHAR,
               "Observaciones" VARCHAR, "Cantidad_Apoyo" INT, "Estado_Operativo" VARCHAR,
               "Con_Desviacion" CHAR, "Disponibilidad_Confirmada" CHAR, "Fecha_Disponibilidad" TIMESTAMP,
               "Fecha_Llegada" TIMESTAMP, "Fecha_Ingreso" TIMESTAMP, "Fecha_Inicio_Atencion" TIMESTAMP,
               "Fecha_Recepcion" TIMESTAMP, "Fecha_Salida" TIMESTAMP, "Resultado_Recepcion" VARCHAR,
               "ID_Personal_Programado" BIGINT, "Programado_Nombre" VARCHAR, "Efectivo_Nombre" VARCHAR,
               "Puede_Programar" CHAR, "Puede_Confirmar" CHAR, "Puede_Cancelar_Disp" CHAR,
               "Puede_Atender" CHAR, "Puede_Terminar" CHAR, "Motivo_Bloqueo" VARCHAR,
               "Es_Solicitante" CHAR, "Puede_Cancelar_Sol" CHAR, "Motivo_No_Cancelar_Sol" VARCHAR,
               "Transportistas_Total" INT, "Transportistas_Verificados" INT, "Transportistas_Dentro" INT, "Transportistas_Salieron" INT,
               "Ayudantes_Total" INT,
               "Numeros_OC" VARCHAR, "Empresa_Transportista" VARCHAR, "Hora_Hasta" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_alm    CHAR(1);
    lv_titular BIGINT;
    lv_tcod   VARCHAR(20);
BEGIN
    -- V2.4 2026-11-13 (D-237): + OC, empresa transportista y franja «Hasta»
    -- V2.3 2026-11-09 (D-225): + contadores de transportistas y ayudantes
    -- V2.0 2026-11-03
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_DASHBOARD', "HV_ID_Catalogo_Sede") <> 'Y' THEN
        RETURN;
    END IF;
    lv_alm := "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', "HV_ID_Catalogo_Sede");
    -- Entrega a la que esta reservada u ocupada la esclusa ahora (una reserva huerfana no cuenta)
    SELECT MAX(O."ID_Solicitud"), MAX(S."Codigo") INTO lv_titular, lv_tcod
      FROM "CAF_Exclusa" X
      JOIN "CAF_Solicitud_Operacion" O ON O."ID_Solicitud" = X."ID_Solicitud_Actual"
           AND O."Estado_Operativo" IN ('EN_ESPERA','INGRESO','EN_ATENCION','RECEPCIONADO') AND O."Activa" = 'Y'
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = O."ID_Solicitud"
     WHERE X."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND X."Eliminado" = 'N';

    RETURN QUERY
    SELECT S."ID_Solicitud", S."Codigo", S."Fecha_Hora_Prevista",
           S."Empresa_Visitante", S."Proveedor_RUC", "ERP_CAF_FN_EMPRESAS_SOLICITUD"(S."ID_Solicitud", 'N'), "ERP_CAF_FN_EMPRESAS_SOLICITUD"(S."ID_Solicitud", 'C'),
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           S."Contacto_Telefonos", S."Placa_Vehiculo", S."Vehiculo_Marca",
           S."Observaciones",
           CAST((SELECT COUNT(*) FROM "CAF_Solicitud_Persona" A
                  WHERE A."ID_Solicitud" = S."ID_Solicitud" AND A."Eliminado" = 'N' AND A."Es_Principal" = 'N') AS INT),
           O."Estado_Operativo",
           O."Con_Desviacion",
           CAST(CASE WHEN lv_titular = S."ID_Solicitud" THEN 'Y' ELSE 'N' END AS CHAR),
           CASE WHEN lv_titular = S."ID_Solicitud" THEN O."Fecha_Disponibilidad" ELSE NULL END,
           O."Fecha_Llegada", O."Fecha_Ingreso", O."Fecha_Inicio_Atencion",
           O."Fecha_Recepcion", O."Fecha_Salida", O."Resultado_Recepcion",
           O."ID_Personal_Programado",
           CAST(PG."Apellido_Paterno" || COALESCE(' ' || PG."Apellido_Materno", '') || ', ' || PG."Nombres" AS VARCHAR),
           CAST(COALESCE(PF."Apellido_Paterno" || COALESCE(' ' || PF."Apellido_Materno", '') || ', ' || PF."Nombres",
                         UF."Apellido_Paterno" || COALESCE(' ' || UF."Apellido_Materno", '') || ', ' || UF."Nombres") AS VARCHAR),
           CAST(CASE WHEN lv_alm = 'Y' AND O."Estado_Operativo" IN ('PROGRAMADO','EN_ESPERA','INGRESO')
                          AND CAST(S."Fecha_Hora_Prevista" AS DATE) >= CURRENT_DATE THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN lv_alm = 'Y' AND O."Estado_Operativo" = 'EN_ESPERA' AND lv_titular IS NULL
                          AND CAST(S."Fecha_Hora_Prevista" AS DATE) = CURRENT_DATE THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN lv_alm = 'Y' AND O."Estado_Operativo" = 'EN_ESPERA' AND lv_titular = S."ID_Solicitud" THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN lv_alm = 'Y' AND O."Estado_Operativo" = 'INGRESO' AND lv_titular = S."ID_Solicitud"
                          AND CAST(S."Fecha_Hora_Prevista" AS DATE) <= CURRENT_DATE THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN lv_alm = 'Y' AND O."Estado_Operativo" = 'EN_ATENCION' THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN O."Estado_Operativo" <> 'EN_ESPERA' OR lv_titular = S."ID_Solicitud" THEN NULL
                     WHEN CAST(S."Fecha_Hora_Prevista" AS DATE) <> CURRENT_DATE THEN 'Solo se confirma el día programado'
                     WHEN lv_titular IS NOT NULL THEN 'La exclusa está reservada para ' || COALESCE(lv_tcod, 'otra entrega')
                     ELSE NULL END AS VARCHAR),
           CAST(CASE WHEN S."ID_Usuario_Solicitante" = "HV_UsuarioID" THEN 'Y' ELSE 'N' END AS CHAR),
           -- Cancelar la solicitud (solo su dueño): la regla es la de ERP_CAF_SOLICITUD_CANCELAR (sin ingresos y, en proveedor, solo PROGRAMADA)
           CAST(CASE WHEN S."ID_Usuario_Solicitante" = "HV_UsuarioID" AND O."Estado_Operativo" = 'PROGRAMADO'
                          AND (SELECT IX."Cancelar" FROM "ERP_CAF_SOLICITUD_INDICADORES"(S."ID_Solicitud") IX) = 'Y' THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN S."ID_Usuario_Solicitante" <> "HV_UsuarioID" THEN NULL
                     WHEN O."Estado_Operativo" <> 'PROGRAMADO' THEN 'La entrega ya está en curso o terminó: no se puede cancelar.'
                     ELSE (SELECT IX."Motivo_Cancelar" FROM "ERP_CAF_SOLICITUD_INDICADORES"(S."ID_Solicitud") IX) END AS VARCHAR),
           CAST((SELECT COUNT(*) FROM "CAF_Solicitud_Persona" X WHERE X."ID_Solicitud" = S."ID_Solicitud" AND X."Eliminado" = 'N' AND X."Aprobacion" = 'APROBADA'
                  AND "ERP_CAF_FN_ES_TRANSPORTISTA"(X."ID_Solicitud_Persona") = 'Y') AS INT),
           CAST((SELECT COUNT(*) FROM "CAF_Solicitud_Persona" X WHERE X."ID_Solicitud" = S."ID_Solicitud" AND X."Eliminado" = 'N' AND X."Aprobacion" = 'APROBADA'
                  AND "ERP_CAF_FN_ES_TRANSPORTISTA"(X."ID_Solicitud_Persona") = 'Y' AND X."Fecha_Verificacion" IS NOT NULL) AS INT),
           CAST((SELECT COUNT(*) FROM "CAF_Solicitud_Persona" X WHERE X."ID_Solicitud" = S."ID_Solicitud" AND X."Eliminado" = 'N' AND X."Aprobacion" = 'APROBADA'
                  AND "ERP_CAF_FN_ES_TRANSPORTISTA"(X."ID_Solicitud_Persona") = 'Y' AND X."Estado" = 'DENTRO') AS INT),
           CAST((SELECT COUNT(*) FROM "CAF_Solicitud_Persona" X WHERE X."ID_Solicitud" = S."ID_Solicitud" AND X."Eliminado" = 'N' AND X."Aprobacion" = 'APROBADA'
                  AND "ERP_CAF_FN_ES_TRANSPORTISTA"(X."ID_Solicitud_Persona") = 'Y' AND X."Estado" = 'SALIO') AS INT),
           CAST((SELECT COUNT(*) FROM "CAF_Solicitud_Persona" X WHERE X."ID_Solicitud" = S."ID_Solicitud" AND X."Eliminado" = 'N' AND X."Aprobacion" = 'APROBADA'
                  AND "ERP_CAF_FN_ES_TRANSPORTISTA"(X."ID_Solicitud_Persona") = 'N') AS INT),
           S."Numeros_OC", S."Empresa_Transportista", CAST(TO_CHAR(S."Hora_Hasta_Prevista", 'HH24:MI') AS VARCHAR)
      FROM "CAF_Solicitud_Operacion" O
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = O."ID_Solicitud" AND S."Eliminado" = 'N' AND S."Estado" <> 'CANCELADA'
      JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
      JOIN "CAF_Solicitud_Persona" PR ON PR."ID_Solicitud" = S."ID_Solicitud" AND PR."Eliminado" = 'N' AND PR."Es_Principal" = 'Y'
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = PR."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG ON EG."ID_Catalogo_Empresa_Grupo" = S."ID_Catalogo_Empresa_Grupo_Destino"
      LEFT JOIN "CAF_GOVERNANCE"."Personal" PG ON PG."ID_Personal" = O."ID_Personal_Programado"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" UF ON UF."ID_Usuario" = O."ID_Usuario_Atencion"
      LEFT JOIN "CAF_GOVERNANCE"."Personal" PF ON PF."ID_Personal" = UF."ID_Personal"
     WHERE O."Eliminado" = 'N' AND O."Activa" = 'Y'
       AND S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
       AND ("HV_Fecha_Desde" IS NULL OR CAST(S."Fecha_Hora_Prevista" AS DATE) >= "HV_Fecha_Desde")
       AND ("HV_Fecha_Hasta" IS NULL OR CAST(S."Fecha_Hora_Prevista" AS DATE) <= "HV_Fecha_Hasta")
     ORDER BY S."Fecha_Hora_Prevista", S."ID_Solicitud";
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR   (Almacen; reserva la esclusa)
--    Solo con datos verificados (EN_ESPERA) y el dia programado. La reserva es un UPDATE condicionado sobre
--    CAF_Exclusa (una fila por sede): si dos usuarios confirman a la vez para entregas distintas, solo uno
--    obtiene la fila; el otro recibe 409. Antes se libera una reserva huerfana (la entrega ya no esta vigente).
--    No cambia el estado: habilita a Vigilancia para validar el ingreso fisico.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(
    IN    "HV_ID_Solicitud"  BIGINT,
    IN    "HV_UsuarioID"     BIGINT,
    INOUT "HV_Codigo_Resp"   INT DEFAULT NULL,
    INOUT "HV_Mensaje"       VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n     INT := 0;
    lv_sede  BIGINT;
    lv_fecha TIMESTAMP;
    lv_act   CHAR(1);
    lv_eop   VARCHAR(20);
    lv_otro  VARCHAR(20);
BEGIN
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR';
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
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para confirmar la disponibilidad de Almacén.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Activa"), MAX("Estado_Operativo") INTO lv_n, lv_act, lv_eop
          FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 OR lv_act <> 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La entrega no está programada (solicitud sin aprobar o cancelada).'; RETURN;
        END IF;
        IF lv_eop <> 'EN_ESPERA' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE lv_eop WHEN 'PROGRAMADO' THEN 'Vigilancia aún no verificó los datos del proveedor.'
                                        WHEN 'INGRESO_DENEGADO' THEN 'El ingreso de este proveedor fue denegado.'
                                        WHEN 'RETIRO_SIN_INGRESO' THEN 'El proveedor se retiró sin ingresar.'
                                        WHEN 'NO_SE_PRESENTO' THEN 'La entrega figura como «no se presentó».'
                                        WHEN 'CIERRE_FORZADO' THEN 'La entrega fue cerrada al terminar su día.'
                                        ELSE 'El proveedor ya ingresó.' END; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) <> CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La disponibilidad solo puede confirmarse el día programado de la entrega.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = lv_sede AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La esclusa de la sede no está configurada.'; RETURN;
        END IF;
        -- Ya estaba confirmada para esta entrega
        SELECT COUNT(*) INTO lv_n FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = lv_sede AND "ID_Solicitud_Actual" = "HV_ID_Solicitud";
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'La disponibilidad ya estaba confirmada.'; RETURN;
        END IF;
        -- Reserva huérfana: la entrega que figura ya no está vigente
        UPDATE "CAF_Exclusa"
           SET "ID_Solicitud_Actual" = NULL, "Fecha_Ocupada" = NULL, "ID_Usuario_Ocupa" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Sede" = lv_sede AND "ID_Solicitud_Actual" IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Operacion" O
                            WHERE O."ID_Solicitud" = "CAF_Exclusa"."ID_Solicitud_Actual" AND O."Activa" = 'Y'
                              AND O."Estado_Operativo" IN ('EN_ESPERA','INGRESO','EN_ATENCION','RECEPCIONADO'));
        -- Reservar: UPDATE condicionado (atómico). Solo uno gana.
        UPDATE "CAF_Exclusa"
           SET "ID_Solicitud_Actual" = "HV_ID_Solicitud", "Fecha_Ocupada" = CURRENT_TIMESTAMP, "ID_Usuario_Ocupa" = "HV_UsuarioID",
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Sede" = lv_sede AND "Eliminado" = 'N' AND "ID_Solicitud_Actual" IS NULL;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = lv_sede AND "ID_Solicitud_Actual" = "HV_ID_Solicitud";
        IF lv_n = 0 THEN
            SELECT S."Codigo" INTO lv_otro FROM "CAF_Exclusa" X JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = X."ID_Solicitud_Actual"
             WHERE X."ID_Catalogo_Sede" = lv_sede;
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'La exclusa ya está reservada para otra entrega' || COALESCE(' (' || lv_otro || ')', '')
                            || '. Debe cancelarse su disponibilidad o terminar su atención.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud_Operacion"
           SET "Fecha_Disponibilidad" = CURRENT_TIMESTAMP, "ID_Usuario_Disponibilidad" = "HV_UsuarioID",
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES ("HV_ID_Solicitud", lv_eop, lv_eop, "HV_UsuarioID", 'DISP_CONFIRMADA', 'Almacén confirmó su disponibilidad y reservó la esclusa');
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Disponibilidad confirmada. La esclusa quedó reservada para esta entrega.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR   (Almacen; libera la reserva)
--    Solo mientras el proveedor no haya ingresado (EN_ESPERA con la esclusa reservada para esta entrega).
--    El motivo es obligatorio. No genera ingreso ni atencion; deja quien, cuando y por que.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR"(
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
BEGIN
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        lv_mot := NULLIF(TRIM(COALESCE("HV_Motivo", '')), '');
        IF lv_mot IS NULL OR LENGTH(lv_mot) < 3 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el motivo de la cancelación.'; RETURN;
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
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para cancelar la disponibilidad de Almacén.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Activa"), MAX("Estado_Operativo") INTO lv_n, lv_act, lv_eop
          FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 OR lv_act <> 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La entrega no está programada (solicitud sin aprobar o cancelada).'; RETURN;
        END IF;
        IF lv_eop IN ('INGRESO','EN_ATENCION','RECEPCIONADO') THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'El proveedor ya ingresó: no se puede cancelar la disponibilidad.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Exclusa"
         WHERE "ID_Catalogo_Sede" = lv_sede AND "ID_Solicitud_Actual" = "HV_ID_Solicitud";
        IF lv_n = 0 OR lv_eop <> 'EN_ESPERA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Esta entrega no tiene la disponibilidad confirmada.'; RETURN;
        END IF;
        UPDATE "CAF_Exclusa"
           SET "ID_Solicitud_Actual" = NULL, "Fecha_Ocupada" = NULL, "ID_Usuario_Ocupa" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Sede" = lv_sede AND "ID_Solicitud_Actual" = "HV_ID_Solicitud";
        UPDATE "CAF_Solicitud_Operacion"
           SET "Fecha_Disponibilidad" = NULL, "ID_Usuario_Disponibilidad" = NULL,
               "Fecha_Cancelacion_Disp" = CURRENT_TIMESTAMP, "ID_Usuario_Cancelacion_Disp" = "HV_UsuarioID",
               "Motivo_Cancelacion_Disp" = lv_mot,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES ("HV_ID_Solicitud", lv_eop, lv_eop, "HV_UsuarioID", 'DISP_CANCELADA', lv_mot);
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Disponibilidad cancelada. La esclusa quedó libre.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR';
    END;
END;
$$;
