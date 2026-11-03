-- =============================================================================
-- Archivo : SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobacion | Fase 1 - Procedimientos (Entrega 2 de Proveedor de abastecimiento)
-- Entidad : CAF_Solicitud_Operacion / CAF_Exclusa (calendario de entregas de Almacen)
-- Version : V1.0 2026-11-03
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO2_ESCRITURA.sql, seccion P)
-- Requiere: scripts 01 a 18 y SP_CAF_PROVEEDOR_ALL.sql.
-- =============================================================================
-- 1 ERP_CAF_PROVEEDOR_RESPONSABLES   personal de Almacen que puede ser responsable programado
-- 2 ERP_CAF_PROVEEDOR_PROGRAMAR      asigna / cambia / quita el responsable programado (Almacen)
-- 3 ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO quien ocupa la esclusa ahora
-- 4 ERP_CAF_PROVEEDOR_CALENDARIO     entregas aprobadas de un rango de fechas, con lo que el usuario puede hacer
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
-- 3. ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO   (una fila; vacia sin permiso de lectura del dashboard)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT
)
RETURNS TABLE ("Ocupada" CHAR, "ID_Solicitud" BIGINT, "Codigo" VARCHAR, "Empresa" VARCHAR, "Desde" TIMESTAMP, "Atiende" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-03
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_DASHBOARD', "HV_ID_Catalogo_Sede") <> 'Y' THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT CAST(CASE WHEN O."ID_Solicitud" IS NULL THEN 'N' ELSE 'Y' END AS CHAR),
           O."ID_Solicitud", S."Codigo", S."Empresa_Visitante", O."Fecha_Inicio_Atencion",
           CAST(COALESCE(P."Apellido_Paterno" || COALESCE(' ' || P."Apellido_Materno", '') || ', ' || P."Nombres",
                         U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres") AS VARCHAR)
      FROM "CAF_Exclusa" X
      LEFT JOIN "CAF_Solicitud_Operacion" O ON O."ID_Solicitud" = X."ID_Solicitud_Actual" AND O."Estado_Operativo" = 'EN_ATENCION' AND O."Activa" = 'Y'
      LEFT JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = O."ID_Solicitud"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = O."ID_Usuario_Atencion"
      LEFT JOIN "CAF_GOVERNANCE"."Personal" P ON P."ID_Personal" = U."ID_Personal"
     WHERE X."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND X."Eliminado" = 'N';
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_PROVEEDOR_CALENDARIO
--    Solo entregas con operacion ACTIVA (transportista principal aprobado y solicitud no cancelada).
--    Si la solicitud pierde la aprobacion mientras sigue PROGRAMADO, SINCRONIZAR la desactiva y sale de aqui.
--    Puede_*: lo que ESTE usuario puede hacer ahora (permiso de Almacen + estado + esclusa); la pantalla solo
--    muestra el boton, el procedimiento de la accion vuelve a validar todo.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_CALENDARIO"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT,
    "HV_Fecha_Desde"      DATE,
    "HV_Fecha_Hasta"      DATE
)
RETURNS TABLE ("ID_Solicitud" BIGINT, "Codigo" VARCHAR, "Fecha_Hora_Prevista" TIMESTAMP,
               "Empresa_Proveedor" VARCHAR, "Proveedor_RUC" VARCHAR, "Empresa_Destino" VARCHAR,
               "Transportista" VARCHAR, "Telefono" VARCHAR, "Placa" VARCHAR, "Vehiculo_Marca" VARCHAR,
               "Observaciones" VARCHAR, "Cantidad_Apoyo" INT, "Estado_Operativo" VARCHAR,
               "Fecha_Llegada" TIMESTAMP, "Fecha_Ingreso" TIMESTAMP, "Fecha_Inicio_Atencion" TIMESTAMP,
               "Fecha_Recepcion" TIMESTAMP, "Fecha_Salida" TIMESTAMP, "Resultado_Recepcion" VARCHAR,
               "ID_Personal_Programado" BIGINT, "Programado_Nombre" VARCHAR, "Efectivo_Nombre" VARCHAR,
               "Puede_Programar" CHAR, "Puede_Atender" CHAR, "Puede_Terminar" CHAR, "Motivo_No_Atender" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_alm   CHAR(1);
    lv_ocup  CHAR(1) := 'N';
BEGIN
    -- V1.0 2026-11-03
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_DASHBOARD', "HV_ID_Catalogo_Sede") <> 'Y' THEN
        RETURN;
    END IF;
    lv_alm := "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', "HV_ID_Catalogo_Sede");
    SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END INTO lv_ocup
      FROM "CAF_Exclusa" X
      JOIN "CAF_Solicitud_Operacion" O ON O."ID_Solicitud" = X."ID_Solicitud_Actual" AND O."Estado_Operativo" = 'EN_ATENCION' AND O."Activa" = 'Y'
     WHERE X."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND X."Eliminado" = 'N';

    RETURN QUERY
    SELECT S."ID_Solicitud", S."Codigo", S."Fecha_Hora_Prevista",
           S."Empresa_Visitante", S."Proveedor_RUC", CAST(EG."Descripcion" AS VARCHAR),
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           S."Contacto_Telefonos", S."Placa_Vehiculo", S."Vehiculo_Marca",
           S."Observaciones",
           CAST((SELECT COUNT(*) FROM "CAF_Solicitud_Persona" A
                  WHERE A."ID_Solicitud" = S."ID_Solicitud" AND A."Eliminado" = 'N' AND A."Es_Principal" = 'N') AS INT),
           O."Estado_Operativo", O."Fecha_Llegada", O."Fecha_Ingreso", O."Fecha_Inicio_Atencion",
           O."Fecha_Recepcion", O."Fecha_Salida", O."Resultado_Recepcion",
           O."ID_Personal_Programado",
           CAST(PG."Apellido_Paterno" || COALESCE(' ' || PG."Apellido_Materno", '') || ', ' || PG."Nombres" AS VARCHAR),
           CAST(COALESCE(PF."Apellido_Paterno" || COALESCE(' ' || PF."Apellido_Materno", '') || ', ' || PF."Nombres",
                         UF."Apellido_Paterno" || COALESCE(' ' || UF."Apellido_Materno", '') || ', ' || UF."Nombres") AS VARCHAR),
           CAST(CASE WHEN lv_alm = 'Y' AND O."Estado_Operativo" IN ('PROGRAMADO','EN_ESPERA','INGRESO')
                          AND CAST(S."Fecha_Hora_Prevista" AS DATE) >= CURRENT_DATE THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN lv_alm = 'Y' AND O."Estado_Operativo" = 'INGRESO' AND lv_ocup = 'N'
                          AND CAST(S."Fecha_Hora_Prevista" AS DATE) <= CURRENT_DATE THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN lv_alm = 'Y' AND O."Estado_Operativo" = 'EN_ATENCION' THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN O."Estado_Operativo" <> 'INGRESO' THEN NULL
                     WHEN CAST(S."Fecha_Hora_Prevista" AS DATE) > CURRENT_DATE THEN 'Aún no es el día programado'
                     WHEN lv_ocup = 'Y' THEN 'Hay otra atención en curso'
                     ELSE NULL END AS VARCHAR)
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
