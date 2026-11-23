-- =============================================================================
-- SP_CAF_PROVEEDOR_INGRESO_VEHICULAR_ALL.sql   V1.0 2026-11-20 (D-260, Entrega 2 · 2C-2j)
-- Coordinación entre almaceneros al «Confirmar disponibilidad» CON ingreso vehicular. Requiere el script 41.
-- No se pausa nada: cada almacenero atiende lo suyo. Cuando la esclusa tiene cupo pero otra entrega aún tiene vehículos por ingresar,
-- el almacenero que quiere confirmar debe SOLICITAR el ingreso vehicular y esperar la conformidad del almacenero con la entrega en curso
-- (o, si este no responde, del Coordinador de Almacén). Con la esclusa completa no hay solicitud: la tarjeta CON queda bloqueada.
--   ERP_CAF_FN_USUARIO_NOMBRE(usuario)                          «Apellidos, Nombres»
--   ERP_CAF_FN_VEHICULOS_CONTAR(solicitud, estado)              conductores aprobados de la entrega en ESPERADA (por ingresar), DENTRO o SALIO
--   ERP_CAF_FN_INGRESO_VEH_RESPONSABLE(solicitud)               almacenero a cargo de la entrega: quien atiende o, si no, quien confirmó la disponibilidad
--   ERP_CAF_FN_INGRESO_VEH_FALTANTES(usuario, solicitud)        entregas con vehículos por ingresar que aún no dieron su conformidad (NULL = ninguna)
--   ERP_CAF_PROVEEDOR_INGRESO_VEH_ESTADO(usuario, solicitud)    lo que muestra el modal «Confirmar disponibilidad» al abrirse
--   ERP_CAF_PROVEEDOR_INGRESO_VEH_LISTAR(usuario, sede)         solicitudes vigentes (para el aviso Confirmar / Rechazar y la tarjeta «Esperando conformidad»)
--   ERP_CAF_PROVEEDOR_INGRESO_VEH_SOLICITAR / _RETIRAR / _RESPONDER
-- La regla la valida además ERP_CAF_PROVEEDOR_DISPONIBILIDAD_MODO (409 si falta la conformidad), así que no depende de la pantalla.
-- Regla de la plaza (sin cambios): la plaza sigue reservada para la entrega hasta que Almacén termina la atención y nadie queda dentro (o al
-- cancelar, retirar o cerrar); la salida del primer vehículo de una entrega con varios NO la libera. Si Almacén termina antes de que
-- ingresen todos, los pendientes quedan «no ingresó» (responsabilidad de Almacén).
-- V1.2 2026-11-22: con la conformidad ya recibida, Requiere_Conformidad pasa a N (la pantalla deja confirmar directo).
-- D-261 (V1.1 2026-11-22): plazas por entrega. El almacenero reserva 1 o varias plazas al confirmar; la plaza es un contador (una fila de CAF_Exclusa por plaza).
--   ERP_CAF_FN_PLAZAS_ENTREGA(solicitud)            plazas que la entrega tiene hoy
--   ERP_CAF_FN_PLAZAS_AJUSTAR(solicitud, usuario)   libera el sobrante: plazas necesarias = menor entre las que tiene y (vehículos dentro + por ingresar), mínimo 1
-- D-263 (V1.3 2026-11-22): liberación temprana de plazas por Almacén (solo entregas de más de 1 vehículo).
--   ERP_CAF_FN_VEHICULOS_DECLARADOS(solicitud)               conductores aprobados de la entrega (por ingresar, dentro, salieron, no ingresaron)
--   ERP_CAF_FN_PLAZA_LIBERAR_MOTIVO(usuario, solicitud)      NULL si puede liberar una plaza; si no, el motivo
--   ERP_CAF_PROVEEDOR_PLAZAS_LISTAR(usuario, sede)           por entrega con varias plazas: plazas, vehículos, si puede liberar
--   ERP_CAF_PROVEEDOR_VEHICULOS_LISTAR(usuario, solicitud)   conductores con su placa y su estado (lista informativa del modal)
--   ERP_CAF_PROVEEDOR_PLAZA_LIBERAR(solicitud, usuario)      libera UNA plaza (queda al menos 1; la última se libera al terminar la atención)
-- Schema: TRIANONSATELITAL_CAF_PRODD.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_USUARIO_NOMBRE"("HV_ID_Usuario" BIGINT)
RETURNS VARCHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE lv_n VARCHAR;
BEGIN
    -- V1.0 2026-11-20
    SELECT CAST(U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" AS VARCHAR) INTO lv_n
      FROM "CAF_GOVERNANCE"."Usuario" U WHERE U."ID_Usuario" = "HV_ID_Usuario";
    RETURN lv_n;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_PLAZAS_ENTREGA"("HV_ID_Solicitud" BIGINT)
RETURNS INT
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE lv_n INT;
BEGIN
    -- V1.0 2026-11-22 (D-261)
    SELECT CAST(COUNT(*) AS INT) INTO lv_n FROM "CAF_Exclusa" X WHERE X."ID_Solicitud_Actual" = "HV_ID_Solicitud" AND X."Eliminado" = 'N';
    RETURN lv_n;
END;
$$;

-- Devuelve cuántas plazas liberó. Con 1 sola plaza no hace nada: esa la libera la salida de Vigilancia al terminar la atención (regla de D-214/D-247).
-- Si la atención ya terminó (RECEPCIONADO) los vehículos que no ingresaron no cuentan.
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_PLAZAS_AJUSTAR"("HV_ID_Solicitud" BIGINT, "HV_UsuarioID" BIGINT)
RETURNS INT
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_tiene INT;
    lv_nec   INT;
    lv_eop   VARCHAR(20);
    lv_pend  INT;
    lv_lib   INT;
BEGIN
    -- V1.0 2026-11-22 (D-261)
    lv_tiene := "ERP_CAF_FN_PLAZAS_ENTREGA"("HV_ID_Solicitud");
    IF lv_tiene <= 1 THEN RETURN 0; END IF;
    SELECT O."Estado_Operativo" INTO lv_eop FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N' AND O."Activa" = 'Y';
    IF lv_eop IS NULL THEN RETURN 0; END IF;
    lv_pend := CASE WHEN lv_eop = 'RECEPCIONADO' THEN 0 ELSE "ERP_CAF_FN_VEHICULOS_CONTAR"("HV_ID_Solicitud", 'ESPERADA') END;
    lv_nec  := GREATEST(1, LEAST(lv_tiene, "ERP_CAF_FN_VEHICULOS_CONTAR"("HV_ID_Solicitud", 'DENTRO') + lv_pend));
    lv_lib  := lv_tiene - lv_nec;
    IF lv_lib <= 0 THEN RETURN 0; END IF;
    UPDATE "CAF_Exclusa"
       SET "ID_Solicitud_Actual" = NULL, "Fecha_Ocupada" = NULL, "ID_Usuario_Ocupa" = NULL,
           "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
     WHERE "ID_Exclusa" IN (SELECT X."ID_Exclusa" FROM "CAF_Exclusa" X WHERE X."ID_Solicitud_Actual" = "HV_ID_Solicitud" AND X."Eliminado" = 'N'
                             ORDER BY X."ID_Exclusa" DESC LIMIT lv_lib);
    INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
    VALUES ("HV_ID_Solicitud", lv_eop, lv_eop, "HV_UsuarioID", 'PLAZA_LIBERADA', 'Se liberaron ' || lv_lib || ' plaza(s) de la esclusa (quedan ' || lv_nec || ')');
    RETURN lv_lib;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_VEHICULOS_CONTAR"("HV_ID_Solicitud" BIGINT, "HV_Estado" VARCHAR)
RETURNS INT
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE lv_n INT;
BEGIN
    -- V1.0 2026-11-20: vehículo = conductor (transportista) aprobado; ESPERADA = por ingresar, DENTRO, SALIO
    SELECT CAST(COUNT(*) AS INT) INTO lv_n
      FROM "CAF_Solicitud_Persona" P
     WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'APROBADA' AND P."Estado" = "HV_Estado"
       AND "ERP_CAF_FN_ES_TRANSPORTISTA"(P."ID_Solicitud_Persona") = 'Y';
    RETURN lv_n;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"("HV_ID_Solicitud" BIGINT)
RETURNS BIGINT
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE lv_u BIGINT;
BEGIN
    -- V1.0 2026-11-20
    SELECT COALESCE(O."ID_Usuario_Atencion", O."ID_Usuario_Disponibilidad") INTO lv_u
      FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
    RETURN lv_u;
END;
$$;

-- Entregas que hoy tienen una plaza de la esclusa de la sede (mismos estados que ERP_CAF_FN_EXCLUSA_RESERVAS), salvo la indicada.
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_INGRESO_VEH_TITULARES"("HV_ID_Sede" BIGINT, "HV_ID_Excluye" BIGINT)
RETURNS TABLE ("ID_Solicitud" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-20
    RETURN QUERY
    SELECT DISTINCT O."ID_Solicitud"
      FROM "CAF_Exclusa" X
      JOIN "CAF_Solicitud_Operacion" O ON O."ID_Solicitud" = X."ID_Solicitud_Actual"
           AND O."Estado_Operativo" IN ('EN_ESPERA','INGRESO','EN_ATENCION','RECEPCIONADO') AND O."Activa" = 'Y' AND O."Eliminado" = 'N'
     WHERE X."ID_Catalogo_Sede" = "HV_ID_Sede" AND X."Eliminado" = 'N'
       AND (O."ID_Solicitud" IS DISTINCT FROM "HV_ID_Excluye");
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_INGRESO_VEH_FALTANTES"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS VARCHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede BIGINT;
    lv_txt  VARCHAR;
BEGIN
    -- V1.0 2026-11-20: SIN_LIMITE no pide nada; si el responsable de la otra entrega es el mismo usuario no hace falta pedirse permiso a sí mismo
    IF "ERP_CAF_FN_EXCLUSA_CAPACIDAD"() >= 2147483647 THEN RETURN NULL; END IF;
    SELECT S."ID_Catalogo_Sede" INTO lv_sede FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud";
    SELECT STRING_AGG(S2."Codigo" || COALESCE(' (' || "ERP_CAF_FN_USUARIO_NOMBRE"("ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"(T."ID_Solicitud")) || ')', ''), ', ' ORDER BY S2."Codigo")
      INTO lv_txt
      FROM "ERP_CAF_FN_INGRESO_VEH_TITULARES"(lv_sede, "HV_ID_Solicitud") T
      JOIN "CAF_Solicitud" S2 ON S2."ID_Solicitud" = T."ID_Solicitud"
     WHERE "ERP_CAF_FN_VEHICULOS_CONTAR"(T."ID_Solicitud", 'ESPERADA') > 0
       AND "ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"(T."ID_Solicitud") IS DISTINCT FROM "HV_UsuarioID"
       AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Ingreso_Vehicular" R
                        WHERE R."ID_Solicitud" = "HV_ID_Solicitud" AND R."ID_Solicitud_Otra" = T."ID_Solicitud"
                          AND R."Estado" = 'CONFIRMADA' AND R."Eliminado" = 'N');
    RETURN lv_txt;
END;
$$;

-- D-261: el estado suma Veh_Propios y Plazas_Libres; cambia el tipo de retorno, así que se elimina la versión anterior.
DROP FUNCTION IF EXISTS "ERP_CAF_PROVEEDOR_INGRESO_VEH_ESTADO"(BIGINT, BIGINT);
-- -----------------------------------------------------------------------------
-- ERP_CAF_PROVEEDOR_INGRESO_VEH_ESTADO: qué ve el almacenero al abrir «Confirmar disponibilidad» de la entrega HV_ID_Solicitud.
--   Caso: SIN_LIMITE (no hay avisos) | COMPLETA (esclusa completa: «Con ingreso vehicular» bloqueada) | ADVERTENCIA (hay cupo pero otra entrega
--         tiene vehículos por ingresar: pide conformidad) | LIBRE.
--   Una fila por entrega que hoy tiene plaza (para listar «SOL-a, SOL-b» o las que piden conformidad); si no hay ninguna, una fila con ID_Solicitud_Otra NULL.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_INGRESO_VEH_ESTADO"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("Caso" VARCHAR, "Capacidad" INT, "Reservas" INT, "ID_Solicitud_Otra" BIGINT, "Codigo_Otra" VARCHAR, "Empresas_Otra" VARCHAR,
               "Almacenero_Otra" VARCHAR, "Veh_Total" INT, "Veh_Por_Ingresar" INT, "Veh_Dentro" INT, "Veh_Salieron" INT,
               "Requiere_Conformidad" CHAR, "ID_Solicitud_Ingreso" BIGINT, "Solicitud_Estado" VARCHAR, "Motivo_Rechazo" VARCHAR,
               "Veh_Propios" INT, "Plazas_Libres" INT, "Plazas_Otra" INT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_sede BIGINT;
    lv_cap  INT;
    lv_res  INT;
    lv_caso VARCHAR;
    lv_vp   INT;
    lv_lib  INT;
BEGIN
    -- V1.0 2026-11-20
    SELECT S."ID_Catalogo_Sede" INTO lv_sede FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
    IF lv_sede IS NULL OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', lv_sede) <> 'Y' THEN RETURN; END IF;
    lv_cap := "ERP_CAF_FN_EXCLUSA_CAPACIDAD"();
    lv_res := "ERP_CAF_FN_EXCLUSA_RESERVAS"(lv_sede);
    lv_vp  := "ERP_CAF_FN_VEHICULOS_CONTAR"("HV_ID_Solicitud", 'ESPERADA') + "ERP_CAF_FN_VEHICULOS_CONTAR"("HV_ID_Solicitud", 'DENTRO') + "ERP_CAF_FN_VEHICULOS_CONTAR"("HV_ID_Solicitud", 'SALIO');
    lv_lib := GREATEST(0, lv_cap - lv_res);
    lv_caso := CASE WHEN lv_cap >= 2147483647 THEN 'SIN_LIMITE'
                    WHEN lv_res >= lv_cap THEN 'COMPLETA'
                    WHEN EXISTS (SELECT 1 FROM "ERP_CAF_FN_INGRESO_VEH_TITULARES"(lv_sede, "HV_ID_Solicitud") T
                                  WHERE "ERP_CAF_FN_VEHICULOS_CONTAR"(T."ID_Solicitud", 'ESPERADA') > 0
                                    AND "ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"(T."ID_Solicitud") IS DISTINCT FROM "HV_UsuarioID") THEN 'ADVERTENCIA'
                    ELSE 'LIBRE' END;
    RETURN QUERY
    SELECT CAST(lv_caso AS VARCHAR), lv_cap, lv_res, T."ID_Solicitud", CAST(S2."Codigo" AS VARCHAR), "ERP_CAF_FN_EMPRESAS_SOLICITUD"(T."ID_Solicitud", 'N'),
           "ERP_CAF_FN_USUARIO_NOMBRE"("ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"(T."ID_Solicitud")),
           "ERP_CAF_FN_VEHICULOS_CONTAR"(T."ID_Solicitud", 'ESPERADA') + "ERP_CAF_FN_VEHICULOS_CONTAR"(T."ID_Solicitud", 'DENTRO') + "ERP_CAF_FN_VEHICULOS_CONTAR"(T."ID_Solicitud", 'SALIO'),
           "ERP_CAF_FN_VEHICULOS_CONTAR"(T."ID_Solicitud", 'ESPERADA'), "ERP_CAF_FN_VEHICULOS_CONTAR"(T."ID_Solicitud", 'DENTRO'), "ERP_CAF_FN_VEHICULOS_CONTAR"(T."ID_Solicitud", 'SALIO'),
           CAST(CASE WHEN lv_caso = 'ADVERTENCIA' AND "ERP_CAF_FN_VEHICULOS_CONTAR"(T."ID_Solicitud", 'ESPERADA') > 0
                          AND "ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"(T."ID_Solicitud") IS DISTINCT FROM "HV_UsuarioID"
                          AND R."Estado" IS DISTINCT FROM 'CONFIRMADA' THEN 'Y' ELSE 'N' END AS CHAR),
           R."ID_Solicitud_Ingreso", CAST(R."Estado" AS VARCHAR), CAST(R."Motivo_Rechazo" AS VARCHAR),
           lv_vp, lv_lib, "ERP_CAF_FN_PLAZAS_ENTREGA"(T."ID_Solicitud")
      FROM "ERP_CAF_FN_INGRESO_VEH_TITULARES"(lv_sede, "HV_ID_Solicitud") T
      JOIN "CAF_Solicitud" S2 ON S2."ID_Solicitud" = T."ID_Solicitud"
      LEFT JOIN LATERAL (SELECT V."ID_Solicitud_Ingreso", V."Estado", V."Motivo_Rechazo" FROM "CAF_Solicitud_Ingreso_Vehicular" V
                          WHERE V."ID_Solicitud" = "HV_ID_Solicitud" AND V."ID_Solicitud_Otra" = T."ID_Solicitud" AND V."Eliminado" = 'N'
                          ORDER BY V."ID_Solicitud_Ingreso" DESC LIMIT 1) R ON TRUE
     ORDER BY S2."Codigo";
    IF NOT FOUND THEN
        RETURN QUERY SELECT CAST(lv_caso AS VARCHAR), lv_cap, lv_res, CAST(NULL AS BIGINT), CAST(NULL AS VARCHAR), CAST(NULL AS VARCHAR), CAST(NULL AS VARCHAR),
                            0, 0, 0, 0, CAST('N' AS CHAR), CAST(NULL AS BIGINT), CAST(NULL AS VARCHAR), CAST(NULL AS VARCHAR), lv_vp, lv_lib, 0;
    END IF;
END;
$$;

-- -----------------------------------------------------------------------------
-- ERP_CAF_PROVEEDOR_INGRESO_VEH_LISTAR: solicitudes vigentes de la sede. Pendientes (cualquier día) y las decididas hoy.
--   Es_Responsable: el usuario es el almacenero a cargo de la entrega en curso (a él le salta el aviso Confirmar / Rechazar).
--   Puede_Decidir : es el responsable o tiene la licencia de Coordinador de Almacén (decide por el almacenero que no responde).
--   Es_Solicitante: la solicitud es de este usuario (puede retirarla).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_INGRESO_VEH_LISTAR"("HV_UsuarioID" BIGINT, "HV_ID_Catalogo_Sede" BIGINT)
RETURNS TABLE ("ID_Solicitud_Ingreso" BIGINT, "ID_Solicitud" BIGINT, "Codigo" VARCHAR, "Empresas" VARCHAR, "Solicitante_Nombre" VARCHAR,
               "ID_Solicitud_Otra" BIGINT, "Codigo_Otra" VARCHAR, "Empresas_Otra" VARCHAR, "Responsable_Nombre" VARCHAR,
               "Veh_Total_Otra" INT, "Veh_Por_Ingresar_Otra" INT, "Estado" VARCHAR, "Motivo_Rechazo" VARCHAR,
               "Fecha_Solicitud" TIMESTAMP, "Fecha_Decision" TIMESTAMP, "Decide_Nombre" VARCHAR, "Decidida_Por_Coord" CHAR,
               "Es_Responsable" CHAR, "Puede_Decidir" CHAR, "Es_Solicitante" CHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_coord CHAR(1);
BEGIN
    -- V1.0 2026-11-20
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', "HV_ID_Catalogo_Sede") <> 'Y' THEN RETURN; END IF;
    lv_coord := "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_COORD_ALMACEN', "HV_ID_Catalogo_Sede");
    RETURN QUERY
    SELECT R."ID_Solicitud_Ingreso", R."ID_Solicitud", CAST(S."Codigo" AS VARCHAR), "ERP_CAF_FN_EMPRESAS_SOLICITUD"(R."ID_Solicitud", 'N'),
           "ERP_CAF_FN_USUARIO_NOMBRE"(R."ID_Usuario_Solicita"),
           R."ID_Solicitud_Otra", CAST(S2."Codigo" AS VARCHAR), "ERP_CAF_FN_EMPRESAS_SOLICITUD"(R."ID_Solicitud_Otra", 'N'),
           "ERP_CAF_FN_USUARIO_NOMBRE"(COALESCE("ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"(R."ID_Solicitud_Otra"), R."ID_Usuario_Responsable")),
           "ERP_CAF_FN_VEHICULOS_CONTAR"(R."ID_Solicitud_Otra", 'ESPERADA') + "ERP_CAF_FN_VEHICULOS_CONTAR"(R."ID_Solicitud_Otra", 'DENTRO') + "ERP_CAF_FN_VEHICULOS_CONTAR"(R."ID_Solicitud_Otra", 'SALIO'),
           "ERP_CAF_FN_VEHICULOS_CONTAR"(R."ID_Solicitud_Otra", 'ESPERADA'),
           CAST(R."Estado" AS VARCHAR), CAST(R."Motivo_Rechazo" AS VARCHAR), R."CreateDate", R."Fecha_Decision",
           "ERP_CAF_FN_USUARIO_NOMBRE"(R."ID_Usuario_Decide"), R."Decidida_Por_Coord",
           CAST(CASE WHEN COALESCE("ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"(R."ID_Solicitud_Otra"), R."ID_Usuario_Responsable") = "HV_UsuarioID" THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN R."Estado" = 'PENDIENTE'
                          AND (COALESCE("ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"(R."ID_Solicitud_Otra"), R."ID_Usuario_Responsable") = "HV_UsuarioID" OR lv_coord = 'Y')
                     THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN R."ID_Usuario_Solicita" = "HV_UsuarioID" THEN 'Y' ELSE 'N' END AS CHAR)
      FROM "CAF_Solicitud_Ingreso_Vehicular" R
      JOIN "CAF_Solicitud" S  ON S."ID_Solicitud"  = R."ID_Solicitud"      AND S."Eliminado" = 'N' AND S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
      JOIN "CAF_Solicitud" S2 ON S2."ID_Solicitud" = R."ID_Solicitud_Otra" AND S2."Eliminado" = 'N'
     WHERE R."Eliminado" = 'N'
       AND (R."Estado" = 'PENDIENTE' OR (R."Estado" IN ('CONFIRMADA','RECHAZADA') AND CAST(R."Fecha_Decision" AS DATE) = CURRENT_DATE))
     ORDER BY R."CreateDate", R."ID_Solicitud_Ingreso";
END;
$$;

-- -----------------------------------------------------------------------------
-- ERP_CAF_PROVEEDOR_INGRESO_VEH_SOLICITAR(entrega, usuario): pide conformidad a quien tiene en curso cada entrega con vehículos por ingresar.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_INGRESO_VEH_SOLICITAR"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n     INT;
    lv_sede  BIGINT;
    lv_fecha TIMESTAMP;
    lv_act   CHAR(1);
    lv_eop   VARCHAR(20);
    lv_f     TIMESTAMP;
    lv_modo  CHAR(1);
    lv_cupo  VARCHAR;
    lv_cap   INT;
    lv_resp  BIGINT;
    lv_cand  INT := 0;
    lv_nuevas INT := 0;
    lv_cod   VARCHAR;
    lv_quien VARCHAR := '';
    r        RECORD;
BEGIN
    -- V1.0 2026-11-20 (D-260)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_INGRESO_VEH_SOLICITAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX(S."ID_Catalogo_Sede"), MAX(S."Fecha_Hora_Prevista"), MAX(S."Codigo") INTO lv_n, lv_sede, lv_fecha, lv_cod
          FROM "CAF_Solicitud" S
          JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
         WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud de proveedor no existe.'; RETURN; END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para solicitar el ingreso vehicular.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Activa"), MAX("Estado_Operativo") INTO lv_n, lv_act, lv_eop
          FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 OR lv_act <> 'Y' THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La entrega no está programada (solicitud sin aprobar o cancelada).'; RETURN; END IF;
        IF lv_eop <> 'EN_ESPERA' THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Solo se solicita el ingreso vehicular con los datos verificados y antes de confirmar la disponibilidad.'; RETURN; END IF;
        IF CAST(lv_fecha AS DATE) <> CURRENT_DATE THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La disponibilidad solo puede confirmarse el día programado de la entrega.'; RETURN; END IF;
        SELECT O."Fecha_Disponibilidad", O."Con_Vehiculo" INTO lv_f, lv_modo FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
        IF lv_f IS NOT NULL THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La disponibilidad ya se confirmó y no se puede cambiar.'; RETURN; END IF;
        lv_cupo := "ERP_CAF_FN_CUPO_ALMACENERO_MOTIVO"("HV_UsuarioID", "HV_ID_Solicitud");
        IF lv_cupo IS NOT NULL THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := LEFT(lv_cupo, 250); RETURN; END IF;
        -- se bloquean las plazas de la sede: el estado de la esclusa no cambia mientras se decide
        PERFORM 1 FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = lv_sede AND "Eliminado" = 'N' FOR UPDATE;
        lv_cap := "ERP_CAF_FN_EXCLUSA_CAPACIDAD"();
        IF lv_cap >= 2147483647 THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La esclusa no tiene límite: confirme la disponibilidad directamente.'; RETURN; END IF;
        IF "ERP_CAF_FN_EXCLUSA_RESERVAS"(lv_sede) >= lv_cap THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La esclusa está completa: no se puede solicitar el ingreso vehicular. Espere a que una plaza se libere o elija «Sin ingreso vehicular».'; RETURN;
        END IF;
        FOR r IN
            SELECT T."ID_Solicitud" AS id_otra, "ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"(T."ID_Solicitud") AS resp
              FROM "ERP_CAF_FN_INGRESO_VEH_TITULARES"(lv_sede, "HV_ID_Solicitud") T
             WHERE "ERP_CAF_FN_VEHICULOS_CONTAR"(T."ID_Solicitud", 'ESPERADA') > 0
               AND "ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"(T."ID_Solicitud") IS DISTINCT FROM "HV_UsuarioID"
             ORDER BY T."ID_Solicitud"
        LOOP
            lv_cand := lv_cand + 1;
            IF NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Ingreso_Vehicular" V
                            WHERE V."ID_Solicitud" = "HV_ID_Solicitud" AND V."ID_Solicitud_Otra" = r.id_otra
                              AND V."Estado" IN ('PENDIENTE','CONFIRMADA') AND V."Eliminado" = 'N') THEN
                INSERT INTO "CAF_Solicitud_Ingreso_Vehicular" ("ID_Solicitud","ID_Solicitud_Otra","ID_Usuario_Solicita","ID_Usuario_Responsable","UsuarioID_Create")
                VALUES ("HV_ID_Solicitud", r.id_otra, "HV_UsuarioID", r.resp, "HV_UsuarioID");
                lv_nuevas := lv_nuevas + 1;
                lv_quien := lv_quien || CASE WHEN lv_quien = '' THEN '' ELSE ', ' END || COALESCE("ERP_CAF_FN_USUARIO_NOMBRE"(r.resp), 'el Coordinador de Almacén');
            END IF;
        END LOOP;
        IF lv_cand = 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Ninguna otra entrega tiene vehículos por ingresar: puede confirmar la disponibilidad directamente.'; RETURN;
        END IF;
        IF lv_nuevas = 0 THEN
            "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Su solicitud ya está registrada. Espere la conformidad o retírela.'; RETURN;
        END IF;
        SELECT O."Estado_Operativo" INTO lv_eop FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES ("HV_ID_Solicitud", lv_eop, lv_eop, "HV_UsuarioID", 'INGVEH_SOLICITADO', LEFT('Solicitó el ingreso vehicular y espera la conformidad de ' || lv_quien, 1000));
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := LEFT('Solicitud enviada. Esperará la conformidad de ' || lv_quien || '.', 250);
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_INGRESO_VEH_SOLICITAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- ERP_CAF_PROVEEDOR_INGRESO_VEH_RETIRAR(entrega, usuario): el solicitante (o el Coordinador de Almacén) retira lo pendiente y puede optar por «Sin ingreso vehicular».
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_INGRESO_VEH_RETIRAR"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede BIGINT;
    lv_n    INT;
    lv_eop  VARCHAR(20);
    lv_mio  INT;
BEGIN
    -- V1.0 2026-11-20 (D-260)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_INGRESO_VEH_RETIRAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT S."ID_Catalogo_Sede" INTO lv_sede FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_sede IS NULL THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN; END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso de Almacén.'; RETURN;
        END IF;
        SELECT COUNT(*), COALESCE(SUM(CASE WHEN V."ID_Usuario_Solicita" = "HV_UsuarioID" THEN 1 ELSE 0 END), 0) INTO lv_n, lv_mio
          FROM "CAF_Solicitud_Ingreso_Vehicular" V WHERE V."ID_Solicitud" = "HV_ID_Solicitud" AND V."Estado" = 'PENDIENTE' AND V."Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'No hay una solicitud de ingreso vehicular pendiente para retirar.'; RETURN; END IF;
        IF lv_mio = 0 AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_COORD_ALMACEN', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo quien hizo la solicitud o el Coordinador de Almacén puede retirarla.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud_Ingreso_Vehicular"
           SET "Estado" = 'RETIRADA', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Estado" = 'PENDIENTE' AND "Eliminado" = 'N';
        SELECT O."Estado_Operativo" INTO lv_eop FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES ("HV_ID_Solicitud", COALESCE(lv_eop, 'EN_ESPERA'), COALESCE(lv_eop, 'EN_ESPERA'), "HV_UsuarioID", 'INGVEH_RETIRADO', 'Retiró la solicitud de ingreso vehicular');
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Solicitud retirada. Puede elegir «Sin ingreso vehicular» o volver a solicitar.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_INGRESO_VEH_RETIRAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- ERP_CAF_PROVEEDOR_INGRESO_VEH_RESPONDER(id solicitud, usuario, acción, motivo): CONFIRMAR o RECHAZAR (motivo corto opcional).
--   Responde el almacenero a cargo de la entrega en curso o, por él, el Coordinador de Almacén (queda marcado).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_INGRESO_VEH_RESPONDER"(
    IN "HV_ID_Solicitud_Ingreso" BIGINT, IN "HV_UsuarioID" BIGINT, IN "HV_Accion" VARCHAR(10), IN "HV_Motivo" VARCHAR(200),
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_x      BIGINT;
    lv_y      BIGINT;
    lv_est    VARCHAR(12);
    lv_resp_g BIGINT;
    lv_sede   BIGINT;
    lv_resp   BIGINT;
    lv_es_resp BOOLEAN;
    lv_coord  BOOLEAN;
    lv_mot    VARCHAR(200);
    lv_codx   VARCHAR;
    lv_cody   VARCHAR;
    lv_eop    VARCHAR(20);
BEGIN
    -- V1.0 2026-11-20 (D-260)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_INGRESO_VEH_RESPONDER';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        IF UPPER(COALESCE("HV_Accion", '')) NOT IN ('CONFIRMAR','RECHAZAR') THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La acción debe ser CONFIRMAR o RECHAZAR.'; RETURN; END IF;
        lv_mot := NULLIF(TRIM(COALESCE("HV_Motivo", '')), '');
        IF LENGTH(COALESCE("HV_Motivo", '')) > 200 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El motivo no puede superar 200 caracteres.'; RETURN; END IF;
        SELECT V."ID_Solicitud", V."ID_Solicitud_Otra", V."Estado", V."ID_Usuario_Responsable" INTO lv_x, lv_y, lv_est, lv_resp_g
          FROM "CAF_Solicitud_Ingreso_Vehicular" V WHERE V."ID_Solicitud_Ingreso" = "HV_ID_Solicitud_Ingreso" AND V."Eliminado" = 'N' FOR UPDATE;
        IF lv_x IS NULL THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud de ingreso vehicular no existe.'; RETURN; END IF;
        IF lv_est <> 'PENDIENTE' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE lv_est WHEN 'RETIRADA' THEN 'El solicitante retiró esta solicitud.' ELSE 'Esta solicitud ya fue respondida.' END; RETURN;
        END IF;
        SELECT S."ID_Catalogo_Sede", S."Codigo" INTO lv_sede, lv_codx FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = lv_x;
        SELECT S."Codigo" INTO lv_cody FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = lv_y;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso de Almacén.'; RETURN;
        END IF;
        lv_resp := COALESCE("ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"(lv_y), lv_resp_g);
        lv_es_resp := (lv_resp = "HV_UsuarioID");
        lv_coord := ("ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_COORD_ALMACEN', lv_sede) = 'Y');
        IF NOT lv_es_resp AND NOT lv_coord THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo el almacenero a cargo de la entrega en curso, o el Coordinador de Almacén, puede responder.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud_Ingreso_Vehicular"
           SET "Estado" = CASE WHEN UPPER("HV_Accion") = 'CONFIRMAR' THEN 'CONFIRMADA' ELSE 'RECHAZADA' END,
               "Motivo_Rechazo" = CASE WHEN UPPER("HV_Accion") = 'RECHAZAR' THEN lv_mot ELSE NULL END,
               "Fecha_Decision" = CURRENT_TIMESTAMP, "ID_Usuario_Decide" = "HV_UsuarioID",
               "Decidida_Por_Coord" = CASE WHEN lv_es_resp THEN 'N' ELSE 'Y' END,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Ingreso" = "HV_ID_Solicitud_Ingreso";
        SELECT O."Estado_Operativo" INTO lv_eop FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = lv_x AND O."Eliminado" = 'N';
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES (lv_x, COALESCE(lv_eop, 'EN_ESPERA'), COALESCE(lv_eop, 'EN_ESPERA'), "HV_UsuarioID",
                CASE WHEN UPPER("HV_Accion") = 'CONFIRMAR' THEN 'INGVEH_CONFIRMADO' ELSE 'INGVEH_RECHAZADO' END,
                LEFT(CASE WHEN UPPER("HV_Accion") = 'CONFIRMAR' THEN 'Conformidad de ' ELSE 'Rechazo de ' END || lv_cody
                     || CASE WHEN lv_es_resp THEN '' ELSE ' (decidido por el Coordinador de Almacén)' END
                     || COALESCE(': ' || lv_mot, ''), 1000));
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje" := CASE WHEN UPPER("HV_Accion") = 'CONFIRMAR' THEN 'Conformidad registrada. ' || lv_codx || ' ya puede confirmar su disponibilidad con ingreso vehicular.'
                             ELSE 'Solicitud rechazada.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_INGRESO_VEH_RESPONDER';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- D-263. Liberación temprana de plazas
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_VEHICULOS_DECLARADOS"("HV_ID_Solicitud" BIGINT)
RETURNS INT
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-22 (D-263)
    RETURN "ERP_CAF_FN_VEHICULOS_CONTAR"("HV_ID_Solicitud", 'ESPERADA') + "ERP_CAF_FN_VEHICULOS_CONTAR"("HV_ID_Solicitud", 'DENTRO')
         + "ERP_CAF_FN_VEHICULOS_CONTAR"("HV_ID_Solicitud", 'SALIO') + "ERP_CAF_FN_VEHICULOS_CONTAR"("HV_ID_Solicitud", 'NO_SE_PRESENTO');
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_PLAZA_LIBERAR_MOTIVO"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS VARCHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede BIGINT;
    lv_eop  VARCHAR(20);
    lv_act  CHAR(1);
    lv_modo CHAR(1);
    lv_resp BIGINT;
BEGIN
    -- V1.0 2026-11-22 (D-263): NULL = puede liberar una plaza
    SELECT S."ID_Catalogo_Sede" INTO lv_sede FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
    IF lv_sede IS NULL THEN RETURN 'La solicitud no existe.'; END IF;
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', lv_sede) <> 'Y' THEN RETURN 'No tiene permiso de Almacén.'; END IF;
    SELECT O."Estado_Operativo", O."Activa", O."Con_Vehiculo" INTO lv_eop, lv_act, lv_modo FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
    IF lv_eop IS NULL OR lv_act <> 'Y' THEN RETURN 'La entrega no está programada.'; END IF;
    IF lv_modo IS DISTINCT FROM 'Y' THEN RETURN 'La entrega no usa la esclusa.'; END IF;
    IF lv_eop NOT IN ('INGRESO','EN_ATENCION') THEN RETURN 'Solo se libera una plaza con la entrega en ingreso o en atención.'; END IF;
    IF "ERP_CAF_FN_VEHICULOS_DECLARADOS"("HV_ID_Solicitud") <= 1 THEN RETURN 'Con un solo vehículo la plaza se libera con la salida.'; END IF;
    IF "ERP_CAF_FN_PLAZAS_ENTREGA"("HV_ID_Solicitud") <= 1 THEN RETURN 'Solo queda 1 plaza: se libera al terminar la atención.'; END IF;
    lv_resp := "ERP_CAF_FN_INGRESO_VEH_RESPONSABLE"("HV_ID_Solicitud");
    IF lv_resp IS DISTINCT FROM "HV_UsuarioID" AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_COORD_ALMACEN', lv_sede) <> 'Y' THEN
        RETURN 'Solo quien está a cargo de la entrega o el Coordinador de Almacén puede liberar plazas.';
    END IF;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_PLAZAS_LISTAR"("HV_UsuarioID" BIGINT, "HV_ID_Catalogo_Sede" BIGINT)
RETURNS TABLE ("ID_Solicitud" BIGINT, "Plazas" INT, "Veh_Declarados" INT, "Veh_Dentro" INT, "Puede_Liberar" CHAR, "Motivo" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-22 (D-263): entregas con ingreso vehicular y más de 1 vehículo que hoy tienen plaza(s)
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', "HV_ID_Catalogo_Sede") <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT T."ID_Solicitud", "ERP_CAF_FN_PLAZAS_ENTREGA"(T."ID_Solicitud"), "ERP_CAF_FN_VEHICULOS_DECLARADOS"(T."ID_Solicitud"),
           "ERP_CAF_FN_VEHICULOS_CONTAR"(T."ID_Solicitud", 'DENTRO'),
           CAST(CASE WHEN "ERP_CAF_FN_PLAZA_LIBERAR_MOTIVO"("HV_UsuarioID", T."ID_Solicitud") IS NULL THEN 'Y' ELSE 'N' END AS CHAR),
           CAST("ERP_CAF_FN_PLAZA_LIBERAR_MOTIVO"("HV_UsuarioID", T."ID_Solicitud") AS VARCHAR)
      FROM "ERP_CAF_FN_INGRESO_VEH_TITULARES"("HV_ID_Catalogo_Sede", NULL) T
     WHERE "ERP_CAF_FN_VEHICULOS_DECLARADOS"(T."ID_Solicitud") > 1;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_VEHICULOS_LISTAR"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Solicitud_Persona" BIGINT, "Nombre" VARCHAR, "Placa" VARCHAR, "Estado" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE lv_sede BIGINT;
BEGIN
    -- V1.0 2026-11-22 (D-263): conductores (un vehículo cada uno) con su placa y su estado; lista informativa
    SELECT S."ID_Catalogo_Sede" INTO lv_sede FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
    IF lv_sede IS NULL OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', lv_sede) <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT P."ID_Solicitud_Persona", CAST(PE."Apellido_Paterno" || ' ' || PE."Nombres" AS VARCHAR), CAST(T."Placa" AS VARCHAR), CAST(P."Estado" AS VARCHAR)
      FROM "CAF_Solicitud_Persona" P
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      JOIN "CAF_Solicitud_Transportista" T ON T."ID_Solicitud_Persona" = P."ID_Solicitud_Persona" AND T."Eliminado" = 'N'
     WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'APROBADA'
     ORDER BY P."ID_Solicitud_Persona";
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_PLAZA_LIBERAR"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_mot  VARCHAR;
    lv_n    INT;
    lv_eop  VARCHAR(20);
    lv_id   BIGINT;
BEGIN
    -- V1.0 2026-11-22 (D-263)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_PLAZA_LIBERAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        IF NOT EXISTS (SELECT 1 FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N') THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        SELECT O."Estado_Operativo" INTO lv_eop FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
        lv_n := "ERP_CAF_FN_PLAZAS_ENTREGA"("HV_ID_Solicitud");
        -- idempotente: si la entrega ya terminó o ya no tiene plazas, no hay nada que liberar
        IF lv_n = 0 AND lv_eop IN ('RECEPCIONADO','SALIO','CIERRE_FORZADO') THEN
            "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'La entrega ya no tiene plazas reservadas.'; RETURN;
        END IF;
        lv_mot := "ERP_CAF_FN_PLAZA_LIBERAR_MOTIVO"("HV_UsuarioID", "HV_ID_Solicitud");
        IF lv_mot IS NOT NULL THEN
            "HV_Codigo_Resp" := CASE WHEN lv_mot LIKE 'No tiene permiso%' OR lv_mot LIKE 'Solo quien%' THEN 101 ELSE 409 END;
            "HV_Mensaje" := LEFT(lv_mot, 250); RETURN;
        END IF;
        SELECT X."ID_Exclusa" INTO lv_id FROM "CAF_Exclusa" X WHERE X."ID_Solicitud_Actual" = "HV_ID_Solicitud" AND X."Eliminado" = 'N' ORDER BY X."ID_Exclusa" DESC LIMIT 1 FOR UPDATE;
        UPDATE "CAF_Exclusa"
           SET "ID_Solicitud_Actual" = NULL, "Fecha_Ocupada" = NULL, "ID_Usuario_Ocupa" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Exclusa" = lv_id;
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES ("HV_ID_Solicitud", lv_eop, lv_eop, "HV_UsuarioID", 'PLAZA_LIB_ALMACEN', 'Almacén liberó una plaza de la esclusa (quedan ' || (lv_n - 1) || ')');
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Plaza liberada. Quedan ' || (lv_n - 1) || ' para esta entrega; Vigilancia registra la salida real del vehículo.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_PLAZA_LIBERAR';
    END;
END;
$$;
