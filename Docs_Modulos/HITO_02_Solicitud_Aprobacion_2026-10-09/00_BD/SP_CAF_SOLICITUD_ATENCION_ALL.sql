-- =============================================================================
-- SP_CAF_SOLICITUD_ATENCION_ALL.sql   V1.0 2026-11-14 (D-238, Entrega 2C-1)
-- Atención de Almacén por empresa receptora. Requiere los scripts 30 y 32.
--   ERP_CAF_FN_ATENCION_ESTADO(solicitud, empresa)          estado efectivo (fila o, si no existe, derivado del estado operativo)
--   ERP_CAF_FN_ATENCION_ACTIVAS(empresa)                    entregas que esa empresa está atendiendo ahora
--   ERP_CAF_FN_ATENCION_AUTORIZADO(usuario, empresa, sede)  'Y' si es de Almacén y atiende a esa empresa
--   ERP_CAF_ATENCION_LISTAR(solicitud, usuario)             una fila por empresa con lo que el usuario puede hacer
--   ERP_CAF_MOTIVO_SIN_ATENCION_LISTAR()                    motivos de «Cerrar sin atención»
--   ERP_CAF_PROVEEDOR_ATENDER_EMPRESA / RECEPCION_EMPRESA / CERRAR_SIN_ATENCION
-- Regla del almacenero compartido: solo puede actuar sobre las empresas que él atiende Y que están en la solicitud
-- (p. ej. atiende PT y TA, el pedido es PT y TS → solo PT). La solicitud pasa a EN_ATENCION cuando la primera empresa inicia y a
-- RECEPCIONADO cuando todas terminaron (atendidas o cerradas sin atención); la salida del conductor sigue exigiendo RECEPCIONADO.
-- Schema: TRIANONSATELITAL_CAF_PRODD.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ATENCION_ESTADO"("HV_ID_Solicitud" BIGINT, "HV_ID_Empresa" BIGINT)
RETURNS VARCHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_e VARCHAR;
    lv_o VARCHAR;
BEGIN
    -- V1.0 2026-11-14
    SELECT A."Estado" INTO lv_e FROM "CAF_Solicitud_Atencion" A
     WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND A."Eliminado" = 'N';
    IF lv_e IS NOT NULL THEN RETURN lv_e; END IF;
    SELECT O."Estado_Operativo" INTO lv_o FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
    RETURN CASE WHEN lv_o = 'EN_ATENCION' THEN 'EN_ATENCION' WHEN lv_o IN ('RECEPCIONADO','SALIO') THEN 'ATENDIDA' ELSE 'PENDIENTE' END;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ATENCION_ACTIVAS"("HV_ID_Empresa" BIGINT)
RETURNS INT
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT;
BEGIN
    -- V1.0 2026-11-14: solo cuentan las entregas vigentes cuyo estado operativo sigue EN_ATENCION (una cerrada a la fuerza no bloquea)
    SELECT CAST(COUNT(*) AS INT) INTO lv_n
      FROM "CAF_Solicitud_Empresa" E
      JOIN "CAF_Solicitud_Operacion" O ON O."ID_Solicitud" = E."ID_Solicitud" AND O."Estado_Operativo" = 'EN_ATENCION' AND O."Activa" = 'Y' AND O."Eliminado" = 'N'
     WHERE E."ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND E."Eliminado" = 'N'
       AND "ERP_CAF_FN_ATENCION_ESTADO"(E."ID_Solicitud", E."ID_Catalogo_Empresa_Grupo") = 'EN_ATENCION';
    RETURN lv_n;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ATENCION_AUTORIZADO"("HV_UsuarioID" BIGINT, "HV_ID_Empresa" BIGINT, "HV_ID_Sede" BIGINT)
RETURNS CHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-14
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', "HV_ID_Sede") <> 'Y' THEN RETURN 'N'; END IF;
    IF EXISTS (SELECT 1 FROM "CAF_Usuario_Empresa_Almacen" X
                WHERE X."ID_Usuario" = "HV_UsuarioID" AND X."ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND X."Eliminado" = 'N') THEN RETURN 'Y'; END IF;
    RETURN 'N';
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_MOTIVO_SIN_ATENCION_LISTAR"()
RETURNS TABLE ("ID_Motivo_Sin_Atencion" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Es_Otro" CHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-14
    RETURN QUERY
    SELECT M."ID_Motivo_Sin_Atencion", CAST(M."Codigo" AS VARCHAR), CAST(M."Descripcion" AS VARCHAR), M."Es_Otro"
      FROM "CAF_Motivo_Sin_Atencion" M WHERE M."Eliminado" = 'N' AND M."Activo" = 'Y' ORDER BY M."Orden", M."ID_Motivo_Sin_Atencion";
END;
$$;

-- Parámetros del sistema para la pantalla «Parámetros» de Catálogos (D-238). El valor se edita con ERP_CAF_PARAMETRO_GUARDAR (que valida por clave).
CREATE OR REPLACE FUNCTION "ERP_CAF_PARAMETRO_LISTAR"()
RETURNS TABLE ("Clave" VARCHAR, "Valor" VARCHAR, "Descripcion" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-14
    RETURN QUERY
    SELECT CAST(P."Clave" AS VARCHAR), CAST(P."Valor" AS VARCHAR), CAST(COALESCE(P."Descripcion", '') AS VARCHAR)
      FROM "CAF_Parametro" P WHERE P."Eliminado" = 'N' ORDER BY P."Clave";
END;
$$;

DROP FUNCTION IF EXISTS "ERP_CAF_ATENCION_LISTAR"(BIGINT, BIGINT);
CREATE OR REPLACE FUNCTION "ERP_CAF_ATENCION_LISTAR"("HV_ID_Solicitud" BIGINT, "HV_UsuarioID" BIGINT)
RETURNS TABLE ("ID_Empresa" BIGINT, "Codigo" VARCHAR, "Empresa" VARCHAR, "Estado" VARCHAR, "Resultado" VARCHAR, "Observacion" VARCHAR,
               "Motivo" VARCHAR, "Fecha_Inicio" TIMESTAMP, "Fecha_Fin" TIMESTAMP, "Atiende" VARCHAR,
               "Autorizado" CHAR, "Puede_Atender" CHAR, "Puede_Recepcionar" CHAR, "Puede_Cerrar_Sin" CHAR, "Motivo_No" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_sede  BIGINT;
    lv_fecha TIMESTAMP;
    lv_eop   VARCHAR(20);
    lv_act   CHAR(1);
    lv_res   BOOLEAN;
    lv_lim   INT;
BEGIN
    -- V1.0 2026-11-14
    SELECT S."ID_Catalogo_Sede", S."Fecha_Hora_Prevista" INTO lv_sede, lv_fecha FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
    SELECT O."Estado_Operativo", O."Activa" INTO lv_eop, lv_act FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
    lv_res := EXISTS (SELECT 1 FROM "CAF_Exclusa" X WHERE X."ID_Catalogo_Sede" = lv_sede AND X."ID_Solicitud_Actual" = "HV_ID_Solicitud" AND X."Eliminado" = 'N');
    lv_lim := COALESCE(NULLIF("ERP_CAF_PARAMETRO_VALOR"('ATENCIONES_SIMULTANEAS_EMPRESA'), '')::INT, 1);
    RETURN QUERY
    SELECT EG."ID_Catalogo_Empresa_Grupo", CAST(EG."Codigo" AS VARCHAR), CAST(EG."Descripcion" AS VARCHAR),
           CAST(ST.est AS VARCHAR), CAST(A."Resultado" AS VARCHAR), CAST(A."Observacion" AS VARCHAR), CAST(M."Descripcion" AS VARCHAR),
           A."Fecha_Inicio", A."Fecha_Fin",
           CAST(COALESCE(PF."Apellido_Paterno" || COALESCE(' ' || PF."Apellido_Materno", '') || ', ' || PF."Nombres", UF."Apellido_Paterno" || COALESCE(' ' || UF."Apellido_Materno", '') || ', ' || UF."Nombres") AS VARCHAR),
           AU.aut,
           CAST(CASE WHEN AU.aut = 'Y' AND ST.est = 'PENDIENTE' AND lv_act = 'Y' AND lv_eop IN ('INGRESO','EN_ATENCION') AND lv_res
                          AND CAST(lv_fecha AS DATE) <= CURRENT_DATE AND "ERP_CAF_FN_ATENCION_ACTIVAS"(EG."ID_Catalogo_Empresa_Grupo") < lv_lim THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN AU.aut = 'Y' AND ST.est = 'EN_ATENCION' AND lv_act = 'Y' AND lv_eop = 'EN_ATENCION' THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN AU.aut = 'Y' AND ST.est IN ('PENDIENTE','EN_ATENCION') AND lv_act = 'Y' AND lv_eop IN ('INGRESO','EN_ATENCION') THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN ST.est <> 'PENDIENTE' THEN NULL
                     WHEN AU.aut <> 'Y' THEN 'Usted no atiende a esta empresa.'
                     WHEN lv_act IS DISTINCT FROM 'Y' OR lv_eop NOT IN ('INGRESO','EN_ATENCION') THEN 'La entrega aún no está lista para atenderse (el proveedor debe haber ingresado).'
                     WHEN NOT lv_res THEN 'Almacén no confirmó su disponibilidad (la exclusa no está reservada para esta entrega).'
                     WHEN CAST(lv_fecha AS DATE) > CURRENT_DATE THEN 'La atención solo puede iniciarse el día programado.'
                     WHEN "ERP_CAF_FN_ATENCION_ACTIVAS"(EG."ID_Catalogo_Empresa_Grupo") >= lv_lim
                          THEN 'La empresa ya está atendiendo ' || lv_lim || ' entrega(s) a la vez (límite configurado). Termine una antes de iniciar otra.'
                     ELSE NULL END AS VARCHAR)
      FROM "CAF_Solicitud_Empresa" E
      JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG ON EG."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo"
      LEFT JOIN "CAF_Solicitud_Atencion" A ON A."ID_Solicitud" = E."ID_Solicitud" AND A."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo" AND A."Eliminado" = 'N'
      LEFT JOIN "CAF_Motivo_Sin_Atencion" M ON M."ID_Motivo_Sin_Atencion" = A."ID_Motivo_Sin_Atencion"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" UF ON UF."ID_Usuario" = COALESCE(A."ID_Usuario_Fin", A."ID_Usuario_Inicio")
      LEFT JOIN "CAF_GOVERNANCE"."Personal" PF ON PF."ID_Personal" = UF."ID_Personal"
     CROSS JOIN LATERAL (SELECT "ERP_CAF_FN_ATENCION_ESTADO"(E."ID_Solicitud", E."ID_Catalogo_Empresa_Grupo") AS est) ST
     CROSS JOIN LATERAL (SELECT "ERP_CAF_FN_ATENCION_AUTORIZADO"("HV_UsuarioID", E."ID_Catalogo_Empresa_Grupo", lv_sede) AS aut) AU
     WHERE E."ID_Solicitud" = "HV_ID_Solicitud" AND E."Eliminado" = 'N'
     ORDER BY EG."Orden", EG."ID_Catalogo_Empresa_Grupo";
END;
$$;

-- Interna: deja una fila por empresa de la solicitud (estado inicial derivado del estado operativo). El llamador ya tiene el bloqueo de la solicitud.
CREATE OR REPLACE PROCEDURE "ERP_CAF_ATENCION_ASEGURAR"("HV_ID_Solicitud" BIGINT, "HV_UsuarioID" BIGINT)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-14
    INSERT INTO "CAF_Solicitud_Atencion" ("ID_Solicitud","ID_Catalogo_Empresa_Grupo","Estado","UsuarioID_Create")
    SELECT E."ID_Solicitud", E."ID_Catalogo_Empresa_Grupo", "ERP_CAF_FN_ATENCION_ESTADO"(E."ID_Solicitud", E."ID_Catalogo_Empresa_Grupo"), "HV_UsuarioID"
      FROM "CAF_Solicitud_Empresa" E
     WHERE E."ID_Solicitud" = "HV_ID_Solicitud" AND E."Eliminado" = 'N'
       AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Atencion" A WHERE A."ID_Solicitud" = E."ID_Solicitud" AND A."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo" AND A."Eliminado" = 'N');
END;
$$;

-- Interna: si ya no queda ninguna empresa por atender, recepciona la entrega completa (resultado y observación agregados).
CREATE OR REPLACE PROCEDURE "ERP_CAF_ATENCION_FINALIZAR"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_UsuarioID" BIGINT, INOUT "HV_Codigo_Resp" INT, INOUT "HV_Mensaje" VARCHAR(250))
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_pend INT;
    lv_obs  VARCHAR;
    lv_con  INT;
    lv_eop  VARCHAR(20);
    lv_per  BIGINT;
    lv_c    INT;
    lv_m    VARCHAR(250);
BEGIN
    -- V1.0 2026-11-14
    "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Atención registrada.';
    SELECT COUNT(*) INTO lv_pend FROM "CAF_Solicitud_Atencion" A
     WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."Eliminado" = 'N' AND A."Estado" IN ('PENDIENTE','EN_ATENCION');
    IF lv_pend > 0 THEN RETURN; END IF;
    SELECT CAST(STRING_AGG(EG."Codigo" || ': ' || CASE WHEN A."Estado" = 'CERRADA_SIN_ATENCION'
                                  THEN 'cerrada sin atención (' || COALESCE(M."Descripcion", '') || COALESCE(' - ' || A."Observacion", '') || ')'
                                  WHEN A."Resultado" = 'CON_OBSERVACION' THEN 'con observación (' || COALESCE(A."Observacion", '') || ')'
                                  ELSE 'conforme' END, '; ' ORDER BY EG."Orden") AS VARCHAR),
           CAST(COUNT(*) FILTER (WHERE A."Estado" = 'CERRADA_SIN_ATENCION' OR A."Resultado" = 'CON_OBSERVACION') AS INT)
      INTO lv_obs, lv_con
      FROM "CAF_Solicitud_Atencion" A
      JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG ON EG."ID_Catalogo_Empresa_Grupo" = A."ID_Catalogo_Empresa_Grupo"
      LEFT JOIN "CAF_Motivo_Sin_Atencion" M ON M."ID_Motivo_Sin_Atencion" = A."ID_Motivo_Sin_Atencion"
     WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."Eliminado" = 'N';
    SELECT O."Estado_Operativo" INTO lv_eop FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud";
    IF lv_eop = 'INGRESO' THEN         -- ninguna empresa llegó a atenderse: se pasa por EN_ATENCION para dejar el historial coherente
        SELECT MAX("ID_Personal") INTO lv_per FROM "CAF_GOVERNANCE"."Usuario" WHERE "ID_Usuario" = "HV_UsuarioID";
        CALL "ERP_CAF_PROVEEDOR_MOVER"("HV_ID_Solicitud", 'EN_ATENCION', "HV_UsuarioID", NULL, NULL, lv_per, lv_c, lv_m);
        IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RAISE EXCEPTION 'mover: %', lv_m; END IF;
    END IF;
    PERFORM set_config('caf.atencion_empresa', '1', true);       -- permite la recepción de una entrega con varias empresas
    CALL "ERP_CAF_PROVEEDOR_RECEPCION"("HV_ID_Solicitud", CASE WHEN lv_con > 0 THEN 'CON_OBSERVACION' ELSE 'CONFORME' END,
                                        CASE WHEN lv_con > 0 THEN LEFT(lv_obs, 1000) ELSE NULL END, "HV_UsuarioID", lv_c, lv_m);
    PERFORM set_config('caf.atencion_empresa', '', true);
    IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RAISE EXCEPTION 'recepcion: %', lv_m; END IF;
    "HV_Mensaje" := 'Atención registrada. Todas las empresas terminaron: la entrega quedó recepcionada.';
END;
$$;

-- Validaciones comunes de las tres acciones; devuelve el estado de la fila y la sede. Un RETURN con código <> 100 indica el motivo.
CREATE OR REPLACE PROCEDURE "ERP_CAF_ATENCION_VALIDAR"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_ID_Empresa" BIGINT, IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT, INOUT "HV_Mensaje" VARCHAR(250), INOUT "HV_Sede" BIGINT, INOUT "HV_Fecha" TIMESTAMP)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n   INT;
    lv_act CHAR(1);
    lv_eop VARCHAR(20);
BEGIN
    -- V1.0 2026-11-14
    "HV_Codigo_Resp" := 100;
    IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
    IF "HV_ID_Empresa" IS NULL OR "HV_ID_Empresa" <= 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique la empresa.'; RETURN; END IF;
    UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";          -- bloqueo de la solicitud
    SELECT COUNT(*), MAX(S."ID_Catalogo_Sede"), MAX(S."Fecha_Hora_Prevista") INTO lv_n, "HV_Sede", "HV_Fecha"
      FROM "CAF_Solicitud" S
      JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
     WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
    IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud de proveedor no existe.'; RETURN; END IF;
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', "HV_Sede") <> 'Y' THEN
        "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para atender proveedores.'; RETURN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Empresa" E WHERE E."ID_Solicitud" = "HV_ID_Solicitud" AND E."ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND E."Eliminado" = 'N') THEN
        "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'Esa empresa no forma parte de la entrega.'; RETURN;
    END IF;
    IF "ERP_CAF_FN_ATENCION_AUTORIZADO"("HV_UsuarioID", "HV_ID_Empresa", "HV_Sede") <> 'Y' THEN
        "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Usted no atiende a esta empresa.'; RETURN;
    END IF;
    SELECT COUNT(*), MAX("Activa"), MAX("Estado_Operativo") INTO lv_n, lv_act, lv_eop
      FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
    IF lv_n = 0 OR lv_act <> 'Y' THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La entrega no está programada (solicitud sin aprobar o cancelada).'; RETURN; END IF;
    IF lv_eop NOT IN ('INGRESO','EN_ATENCION') THEN
        "HV_Codigo_Resp" := 409;
        "HV_Mensaje" := CASE WHEN lv_eop IN ('PROGRAMADO','EN_ESPERA') THEN 'Aún no ingresó ningún transportista.'
                             WHEN lv_eop IN ('RECEPCIONADO','SALIO') THEN 'La entrega ya fue recepcionada.'
                             ELSE 'La entrega ya no admite atención.' END;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_ATENDER_EMPRESA"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_ID_Empresa" BIGINT, IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede BIGINT; lv_fecha TIMESTAMP; lv_est VARCHAR(25); lv_eop VARCHAR(20); lv_per BIGINT; lv_c INT; lv_m VARCHAR(250); lv_lim INT; lv_cod VARCHAR;
BEGIN
    -- V1.0 2026-11-14 (D-238)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_ATENDER_EMPRESA';
    BEGIN
        CALL "ERP_CAF_ATENCION_VALIDAR"("HV_ID_Solicitud", "HV_ID_Empresa", "HV_UsuarioID", lv_c, lv_m, lv_sede, lv_fecha);
        IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RETURN; END IF;
        IF CAST(lv_fecha AS DATE) > CURRENT_DATE THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La atención solo puede iniciarse el día programado de la entrega.'; RETURN; END IF;
        IF NOT EXISTS (SELECT 1 FROM "CAF_Exclusa" X WHERE X."ID_Catalogo_Sede" = lv_sede AND X."ID_Solicitud_Actual" = "HV_ID_Solicitud" AND X."Eliminado" = 'N') THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Almacén no confirmó su disponibilidad para esta entrega (la exclusa no está reservada para ella).'; RETURN;
        END IF;
        lv_est := "ERP_CAF_FN_ATENCION_ESTADO"("HV_ID_Solicitud", "HV_ID_Empresa");
        IF lv_est <> 'PENDIENTE' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE WHEN lv_est = 'EN_ATENCION' THEN 'Esa empresa ya está en atención.' ELSE 'Esa empresa ya terminó su atención.' END; RETURN;
        END IF;
        lv_lim := COALESCE(NULLIF("ERP_CAF_PARAMETRO_VALOR"('ATENCIONES_SIMULTANEAS_EMPRESA'), '')::INT, 1);
        IF "ERP_CAF_FN_ATENCION_ACTIVAS"("HV_ID_Empresa") >= lv_lim THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'La empresa ya está atendiendo ' || lv_lim || ' entrega(s) a la vez (límite configurado). Termine una antes de iniciar otra.'; RETURN;
        END IF;
        CALL "ERP_CAF_ATENCION_ASEGURAR"("HV_ID_Solicitud", "HV_UsuarioID");
        UPDATE "CAF_Solicitud_Atencion"
           SET "Estado" = 'EN_ATENCION', "Fecha_Inicio" = CURRENT_TIMESTAMP, "ID_Usuario_Inicio" = "HV_UsuarioID", "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND "Eliminado" = 'N';
        SELECT "Estado_Operativo" INTO lv_eop FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        IF lv_eop = 'INGRESO' THEN
            SELECT MAX("ID_Personal") INTO lv_per FROM "CAF_GOVERNANCE"."Usuario" WHERE "ID_Usuario" = "HV_UsuarioID";
            CALL "ERP_CAF_PROVEEDOR_MOVER"("HV_ID_Solicitud", 'EN_ATENCION', "HV_UsuarioID", NULL, NULL, lv_per, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'mover: %', lv_m; END IF;
        END IF;
        SELECT "Codigo" INTO lv_cod FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa";
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion")
        VALUES ("HV_ID_Solicitud", 'EN_ATENCION', 'EN_ATENCION', "HV_UsuarioID", 'Atención iniciada para ' || lv_cod);
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Atención iniciada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_ATENDER_EMPRESA';
    END;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_RECEPCION_EMPRESA"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_ID_Empresa" BIGINT, IN "HV_Resultado" VARCHAR(20), IN "HV_Observacion" VARCHAR(1000), IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede BIGINT; lv_fecha TIMESTAMP; lv_est VARCHAR(25); lv_c INT; lv_m VARCHAR(250); lv_cod VARCHAR;
    lv_res VARCHAR(20) := UPPER(TRIM(COALESCE("HV_Resultado", '')));
BEGIN
    -- V1.0 2026-11-14 (D-238)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_RECEPCION_EMPRESA';
    BEGIN
        IF lv_res NOT IN ('CONFORME','CON_OBSERVACION') THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El resultado debe ser CONFORME o CON_OBSERVACION.'; RETURN; END IF;
        IF lv_res = 'CON_OBSERVACION' AND NULLIF(TRIM(COALESCE("HV_Observacion", '')), '') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Describa la observación de la recepción.'; RETURN; END IF;
        IF LENGTH(COALESCE("HV_Observacion", '')) > 500 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La observación no puede superar 500 caracteres.'; RETURN; END IF;
        CALL "ERP_CAF_ATENCION_VALIDAR"("HV_ID_Solicitud", "HV_ID_Empresa", "HV_UsuarioID", lv_c, lv_m, lv_sede, lv_fecha);
        IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RETURN; END IF;
        lv_est := "ERP_CAF_FN_ATENCION_ESTADO"("HV_ID_Solicitud", "HV_ID_Empresa");
        IF lv_est <> 'EN_ATENCION' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE WHEN lv_est = 'PENDIENTE' THEN 'La atención de esa empresa aún no se inició.' ELSE 'Esa empresa ya terminó su atención.' END; RETURN;
        END IF;
        CALL "ERP_CAF_ATENCION_ASEGURAR"("HV_ID_Solicitud", "HV_UsuarioID");
        UPDATE "CAF_Solicitud_Atencion"
           SET "Estado" = 'ATENDIDA', "Fecha_Fin" = CURRENT_TIMESTAMP, "ID_Usuario_Fin" = "HV_UsuarioID", "Resultado" = lv_res,
               "Observacion" = NULLIF(TRIM(COALESCE("HV_Observacion", '')), ''), "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND "Eliminado" = 'N';
        SELECT "Codigo" INTO lv_cod FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa";
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES ("HV_ID_Solicitud", 'EN_ATENCION', 'EN_ATENCION', "HV_UsuarioID", lv_res, 'Recepción de ' || lv_cod || COALESCE(': ' || NULLIF(TRIM("HV_Observacion"), ''), ''));
        CALL "ERP_CAF_ATENCION_FINALIZAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'finalizar: %', lv_m; END IF;
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := lv_m;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_RECEPCION_EMPRESA';
    END;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_CERRAR_SIN_ATENCION"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_ID_Empresa" BIGINT, IN "HV_ID_Motivo" BIGINT, IN "HV_Detalle" VARCHAR(300), IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede BIGINT; lv_fecha TIMESTAMP; lv_est VARCHAR(25); lv_c INT; lv_m VARCHAR(250); lv_cod VARCHAR; lv_otro CHAR(1); lv_mot VARCHAR;
BEGIN
    -- V1.0 2026-11-14 (D-238)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_CERRAR_SIN_ATENCION';
    BEGIN
        SELECT M."Es_Otro", M."Descripcion" INTO lv_otro, lv_mot FROM "CAF_Motivo_Sin_Atencion" M
         WHERE M."ID_Motivo_Sin_Atencion" = "HV_ID_Motivo" AND M."Eliminado" = 'N' AND M."Activo" = 'Y';
        IF lv_otro IS NULL THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Elija el motivo por el que no se atiende a esta empresa.'; RETURN; END IF;
        IF lv_otro = 'Y' AND NULLIF(TRIM(COALESCE("HV_Detalle", '')), '') IS NULL THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Describa el motivo.'; RETURN; END IF;
        IF LENGTH(COALESCE("HV_Detalle", '')) > 300 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El detalle no puede superar 300 caracteres.'; RETURN; END IF;
        CALL "ERP_CAF_ATENCION_VALIDAR"("HV_ID_Solicitud", "HV_ID_Empresa", "HV_UsuarioID", lv_c, lv_m, lv_sede, lv_fecha);
        IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RETURN; END IF;
        lv_est := "ERP_CAF_FN_ATENCION_ESTADO"("HV_ID_Solicitud", "HV_ID_Empresa");
        IF lv_est NOT IN ('PENDIENTE','EN_ATENCION') THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Esa empresa ya terminó su atención.'; RETURN; END IF;
        CALL "ERP_CAF_ATENCION_ASEGURAR"("HV_ID_Solicitud", "HV_UsuarioID");
        UPDATE "CAF_Solicitud_Atencion"
           SET "Estado" = 'CERRADA_SIN_ATENCION', "Fecha_Fin" = CURRENT_TIMESTAMP, "ID_Usuario_Fin" = "HV_UsuarioID", "ID_Motivo_Sin_Atencion" = "HV_ID_Motivo",
               "Observacion" = NULLIF(TRIM(COALESCE("HV_Detalle", '')), ''), "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND "Eliminado" = 'N';
        SELECT "Codigo" INTO lv_cod FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa";
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion")
        VALUES ("HV_ID_Solicitud", 'EN_ATENCION', 'EN_ATENCION', "HV_UsuarioID", 'Cerrada sin atención: ' || lv_cod || ' (' || lv_mot || COALESCE(' - ' || NULLIF(TRIM("HV_Detalle"), ''), '') || ')');
        CALL "ERP_CAF_ATENCION_FINALIZAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'finalizar: %', lv_m; END IF;
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := CASE WHEN lv_m LIKE '%recepcionada%' THEN lv_m ELSE 'Empresa cerrada sin atención.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_CERRAR_SIN_ATENCION';
    END;
END;
$$;
