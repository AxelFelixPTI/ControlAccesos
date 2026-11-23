-- =============================================================================
-- SP_CAF_SOLICITUD_ATENCION_ALL.sql   V2.0 2026-11-15 (D-238 Entrega 2C-1; D-239 Entrega 2C-2: detener/reanudar y varias empresas a la vez)
-- Atención de Almacén por empresa receptora. Requiere los scripts 30 y 32.
--   ERP_CAF_FN_ATENCION_ESTADO(solicitud, empresa)          estado efectivo (fila o, si no existe, derivado del estado operativo)
--   ERP_CAF_FN_ATENCION_ACTIVAS(empresa)                    entregas que esa empresa está atendiendo ahora
--   ERP_CAF_FN_ATENCION_AUTORIZADO(usuario, empresa, sede)  'Y' si es de Almacén y atiende a esa empresa
--   ERP_CAF_FN_ATENCION_PUEDE_CERRAR_SIN(usuario, solicitud, empresa, sede)  D-259: quien la inició o con la licencia «Cerrar sin atención»
--   ERP_CAF_ATENCION_LISTAR(solicitud, usuario)             una fila por empresa con lo que el usuario puede hacer
--   ERP_CAF_MOTIVO_SIN_ATENCION_LISTAR()                    motivos de «Cerrar sin atención»
--   ERP_CAF_PROVEEDOR_ATENDER_EMPRESA / RECEPCION_EMPRESA / CERRAR_SIN_ATENCION / DETENER_EMPRESA / REANUDAR_EMPRESA (una empresa)
--   ERP_CAF_PROVEEDOR_ATENDER_EMPRESAS / DETENER_EMPRESAS / REANUDAR_EMPRESAS / RECEPCION_EMPRESAS (varias a la vez: lista de ids)
-- D-239: solo quien INICIÓ la atención de una empresa puede detenerla, reanudarla o terminarla. Detener libera el cupo de «atenciones
-- simultáneas» de esa empresa (la esclusa sigue reservada); reanudar exige que haya cupo. El estado DETENIDA no cuenta como terminada.
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

-- Quien inició la atención de la empresa (la fila; si no existe, el responsable efectivo de la entrega).
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ATENCION_INICIO"("HV_ID_Solicitud" BIGINT, "HV_ID_Empresa" BIGINT)
RETURNS BIGINT
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_u BIGINT;
BEGIN
    -- V1.0 2026-11-15
    SELECT A."ID_Usuario_Inicio" INTO lv_u FROM "CAF_Solicitud_Atencion" A
     WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND A."Eliminado" = 'N';
    IF lv_u IS NULL THEN
        SELECT O."ID_Usuario_Atencion" INTO lv_u FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
    END IF;
    RETURN lv_u;
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

-- D-259: ¿puede el usuario «Cerrar sin atención» esta empresa? Siempre debe ser un almacenero de esa empresa (Almacén por empresa) y:
--   · la empresa aún no se empezó a atender (PENDIENTE): cualquiera de sus almaceneros (nadie la inició), o
--   · la inició él, o
--   · tiene el permiso PER_CAF_PROVEEDOR_CERRAR_SIN_ATENCION (licencia aparte): puede cerrar aunque la haya iniciado otro.
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ATENCION_PUEDE_CERRAR_SIN"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT, "HV_ID_Empresa" BIGINT, "HV_ID_Sede" BIGINT)
RETURNS CHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-20
    IF "ERP_CAF_FN_ATENCION_AUTORIZADO"("HV_UsuarioID", "HV_ID_Empresa", "HV_ID_Sede") <> 'Y' THEN RETURN 'N'; END IF;
    IF "ERP_CAF_FN_ATENCION_ESTADO"("HV_ID_Solicitud", "HV_ID_Empresa") = 'PENDIENTE' THEN RETURN 'Y'; END IF;
    IF "ERP_CAF_FN_ATENCION_INICIO"("HV_ID_Solicitud", "HV_ID_Empresa") = "HV_UsuarioID" THEN RETURN 'Y'; END IF;
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_CERRAR_SIN_ATENCION', "HV_ID_Sede") = 'Y' THEN RETURN 'Y'; END IF;
    RETURN 'N';
END;
$$;

-- D-244: cupos configurables ---------------------------------------------------------------------------------------------
-- Texto de un parámetro de cupo -> número (SIN_LIMITE = sin tope; algo no válido o vacío = NULL).
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_CUPO_VALOR"("HV_Valor" VARCHAR)
RETURNS INT
LANGUAGE plpgsql IMMUTABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-16
    IF "HV_Valor" = 'SIN_LIMITE' THEN RETURN 2147483647; END IF;
    IF "HV_Valor" ~ '^[1-9][0-9]?$' THEN RETURN CAST("HV_Valor" AS INT); END IF;
    RETURN NULL;
END;
$$;

-- Cupo de la empresa: el suyo (CUPO_EMPRESA:<código>) o, si no tiene o dice GENERAL, ATENCIONES_SIMULTANEAS_EMPRESA (por defecto 1).
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_CUPO_EMPRESA"("HV_ID_Empresa" BIGINT)
RETURNS INT
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_cod VARCHAR;
    lv_n   INT;
BEGIN
    -- V1.0 2026-11-16 (D-244)
    SELECT E."Codigo" INTO lv_cod FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" E WHERE E."ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa";
    lv_n := "ERP_CAF_FN_CUPO_VALOR"("ERP_CAF_PARAMETRO_VALOR"('CUPO_EMPRESA:' || COALESCE(lv_cod, '')));
    IF lv_n IS NULL THEN lv_n := "ERP_CAF_FN_CUPO_VALOR"("ERP_CAF_PARAMETRO_VALOR"('ATENCIONES_SIMULTANEAS_EMPRESA')); END IF;
    RETURN COALESCE(lv_n, 1);
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_CUPO_ALMACENERO_LIMITE"()
RETURNS INT
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-16 (D-244)
    RETURN COALESCE("ERP_CAF_FN_CUPO_VALOR"("ERP_CAF_PARAMETRO_VALOR"('ATENCIONES_SIMULTANEAS_ALMACENERO')), 1);
END;
$$;

-- ¿Esta solicitud ocupa el cupo del almacenero? 'ATENCION' si tiene una empresa en atención iniciada por él; 'RESERVA' si confirmó la disponibilidad
-- de la entrega de hoy y la atención todavía no empezó; NULL si no. Una detenida o terminada ya no ocupa el cupo.
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_CUPO_OCUPA"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS VARCHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_eop VARCHAR(20);
    lv_act CHAR(1);
    lv_fd  TIMESTAMP;
    lv_ud  BIGINT;
    lv_fp  TIMESTAMP;
BEGIN
    -- V1.0 2026-11-16 (D-244)
    SELECT O."Estado_Operativo", O."Activa", O."Fecha_Disponibilidad", O."ID_Usuario_Disponibilidad", S."Fecha_Hora_Prevista"
      INTO lv_eop, lv_act, lv_fd, lv_ud, lv_fp
      FROM "CAF_Solicitud_Operacion" O JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = O."ID_Solicitud"
     WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
    IF lv_eop IS NULL OR lv_act <> 'Y' OR lv_eop NOT IN ('EN_ESPERA','INGRESO','EN_ATENCION') THEN RETURN NULL; END IF;
    IF EXISTS (SELECT 1 FROM "CAF_Solicitud_Atencion" A
                WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."Eliminado" = 'N' AND A."Estado" = 'EN_ATENCION'
                  AND "ERP_CAF_FN_ATENCION_INICIO"(A."ID_Solicitud", A."ID_Catalogo_Empresa_Grupo") = "HV_UsuarioID") THEN RETURN 'ATENCION'; END IF;
    IF lv_fd IS NOT NULL AND lv_ud = "HV_UsuarioID" AND CAST(lv_fp AS DATE) = CURRENT_DATE
       AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Atencion" A WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."Eliminado" = 'N' AND A."Estado" <> 'PENDIENTE') THEN
        RETURN 'RESERVA';
    END IF;
    RETURN NULL;
END;
$$;

-- Motivo por el que el almacenero NO puede tomar esta solicitud (confirmar, tomar, iniciar o reanudar): ya tiene otras en curso. NULL = puede.
-- Una solicitud que ya ocupa su cupo siempre le sirve para seguir atendiendo.
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_CUPO_ALMACENERO_MOTIVO"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS VARCHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_lim  INT := "ERP_CAF_FN_CUPO_ALMACENERO_LIMITE"();
    lv_n    INT;
    lv_cods VARCHAR;
BEGIN
    -- V1.0 2026-11-16 (D-244)
    IF "ERP_CAF_FN_CUPO_OCUPA"("HV_UsuarioID", "HV_ID_Solicitud") IS NOT NULL THEN RETURN NULL; END IF;
    SELECT CAST(COUNT(*) AS INT), STRING_AGG(S."Codigo", ', ' ORDER BY S."Codigo") INTO lv_n, lv_cods
      FROM "CAF_Solicitud_Operacion" O JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = O."ID_Solicitud"
     WHERE O."Eliminado" = 'N' AND O."Activa" = 'Y' AND O."Estado_Operativo" IN ('EN_ESPERA','INGRESO','EN_ATENCION')
       AND "ERP_CAF_FN_CUPO_OCUPA"("HV_UsuarioID", O."ID_Solicitud") IS NOT NULL;
    IF lv_n >= lv_lim THEN
        RETURN CAST('Usted ya tiene ' || CASE WHEN lv_lim = 1 THEN 'una solicitud en curso' ELSE lv_n || ' solicitudes en curso (límite ' || lv_lim || ')' END
                    || ' (' || COALESCE(lv_cods, '') || '): termine o detenga su atención antes de tomar otra.' AS VARCHAR);
    END IF;
    RETURN NULL;
END;
$$;

-- Motivo por el que la atención de la empresa no puede iniciarse o reanudarse ahora (reserva, cupo del almacenero, cupo de la empresa). NULL = puede.
CREATE OR REPLACE FUNCTION "ERP_CAF_ATENCION_CUPO_MOTIVO"("HV_ID_Solicitud" BIGINT, "HV_ID_Empresa" BIGINT, "HV_UsuarioID" BIGINT, "HV_Accion" VARCHAR)
RETURNS VARCHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_fd   TIMESTAMP;
    lv_ud   BIGINT;
    lv_ini  BOOLEAN;
    lv_nom  VARCHAR;
    lv_m    VARCHAR;
    lv_lim  INT;
BEGIN
    -- V1.0 2026-11-16 (D-244)
    SELECT O."Fecha_Disponibilidad", O."ID_Usuario_Disponibilidad" INTO lv_fd, lv_ud
      FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
    lv_ini := EXISTS (SELECT 1 FROM "CAF_Solicitud_Atencion" A WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."Eliminado" = 'N' AND A."Estado" <> 'PENDIENTE');
    IF "HV_Accion" = 'INICIAR' AND lv_fd IS NOT NULL THEN
        IF lv_ud IS NULL THEN
            RETURN 'La reserva fue cedida: use «Tomar» para quedarse con esta entrega.';
        END IF;
        IF lv_ud <> "HV_UsuarioID" AND NOT lv_ini THEN
            SELECT U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" INTO lv_nom
              FROM "CAF_GOVERNANCE"."Usuario" U WHERE U."ID_Usuario" = lv_ud;
            RETURN CAST('La disponibilidad la confirmó ' || COALESCE(lv_nom, 'otro almacenero') || ': solo esa persona inicia la atención (o debe ceder la reserva).' AS VARCHAR);
        END IF;
    END IF;
    lv_m := "ERP_CAF_FN_CUPO_ALMACENERO_MOTIVO"("HV_UsuarioID", "HV_ID_Solicitud");
    IF lv_m IS NOT NULL THEN RETURN lv_m; END IF;
    lv_lim := "ERP_CAF_FN_CUPO_EMPRESA"("HV_ID_Empresa");
    IF "ERP_CAF_FN_ATENCION_ACTIVAS"("HV_ID_Empresa") >= lv_lim THEN
        RETURN CAST('La empresa ya está atendiendo ' || lv_lim || ' entrega(s) a la vez (límite configurado). Termine o detenga una antes de '
                    || CASE WHEN "HV_Accion" = 'INICIAR' THEN 'iniciar otra.' ELSE 'reanudar.' END AS VARCHAR);
    END IF;
    RETURN NULL;
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
    -- V1.1 2026-11-16 (D-244): una fila CUPO_EMPRESA:<código> por empresa activa (GENERAL si no tiene cupo propio)
    SELECT X."Clave", X."Valor", X."Descripcion" FROM (
        SELECT CAST(P."Clave" AS VARCHAR) AS "Clave", CAST(P."Valor" AS VARCHAR) AS "Valor", CAST(COALESCE(P."Descripcion", '') AS VARCHAR) AS "Descripcion", 0 AS ord, CAST(P."Clave" AS VARCHAR) AS k2
          FROM "CAF_Parametro" P WHERE P."Eliminado" = 'N' AND P."Clave" NOT LIKE 'CUPO_EMPRESA:%'
        UNION ALL
        SELECT CAST('CUPO_EMPRESA:' || EG."Codigo" AS VARCHAR), CAST(COALESCE(PV."Valor", 'GENERAL') AS VARCHAR), CAST(EG."Descripcion" AS VARCHAR), 1, CAST(LPAD(CAST(EG."Orden" AS VARCHAR), 5, '0') || EG."Codigo" AS VARCHAR)
          FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG
          LEFT JOIN "CAF_Parametro" PV ON PV."Clave" = 'CUPO_EMPRESA:' || EG."Codigo" AND PV."Eliminado" = 'N'
         WHERE EG."Eliminado" = 'N' AND EG."Activo" = 'Y'
    ) X ORDER BY X.ord, X.k2;
END;
$$;

DROP FUNCTION IF EXISTS "ERP_CAF_ATENCION_LISTAR"(BIGINT, BIGINT);
CREATE OR REPLACE FUNCTION "ERP_CAF_ATENCION_LISTAR"("HV_ID_Solicitud" BIGINT, "HV_UsuarioID" BIGINT)
RETURNS TABLE ("ID_Empresa" BIGINT, "Codigo" VARCHAR, "Empresa" VARCHAR, "Estado" VARCHAR, "Resultado" VARCHAR, "Observacion" VARCHAR,
               "Motivo" VARCHAR, "Fecha_Inicio" TIMESTAMP, "Fecha_Fin" TIMESTAMP, "Atiende" VARCHAR,
               "Autorizado" CHAR, "Puede_Atender" CHAR, "Puede_Recepcionar" CHAR, "Puede_Cerrar_Sin" CHAR, "Motivo_No" VARCHAR,
               "Puede_Detener" CHAR, "Puede_Reanudar" CHAR, "Motivo_Detencion" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_sede  BIGINT;
    lv_fecha TIMESTAMP;
    lv_eop   VARCHAR(20);
    lv_act   CHAR(1);
    lv_res   BOOLEAN;
    lv_lim   INT;
    lv_sin   BOOLEAN;
BEGIN
    -- V2.3 2026-11-20 (D-259): Puede_Cerrar_Sin = quien inició la atención, o con la licencia «Cerrar sin atención» (solo sus empresas); una empresa PENDIENTE la puede cerrar cualquiera de sus almaceneros
    -- V2.2 2026-11-16 (D-244): reserva (solo quien confirmó inicia), cupo del almacenero y cupo por empresa configurables, todo vía ERP_CAF_ATENCION_CUPO_MOTIVO
    -- V2.1 2026-11-16 (D-243): SIN ingreso vehicular la atención puede iniciarse con la entrega EN_ESPERA (Almacén y Vigilancia son independientes)
    -- V2.0 2026-11-15 (D-239): DETENIDA, Puede_Detener/Puede_Reanudar, solo quien inició actúa sobre una empresa en atención; sin ingreso vehicular no usa la esclusa
    -- V1.0 2026-11-14
    SELECT S."ID_Catalogo_Sede", S."Fecha_Hora_Prevista" INTO lv_sede, lv_fecha FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
    SELECT O."Estado_Operativo", O."Activa" INTO lv_eop, lv_act FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
    lv_res := "ERP_CAF_FN_DISPONIBLE"("HV_ID_Solicitud") = 'Y';
    lv_sin := COALESCE((SELECT O."Con_Vehiculo" FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N'), 'Y') = 'N';
    lv_lim := COALESCE(NULLIF("ERP_CAF_PARAMETRO_VALOR"('ATENCIONES_SIMULTANEAS_EMPRESA'), '')::INT, 1);
    RETURN QUERY
    SELECT EG."ID_Catalogo_Empresa_Grupo", CAST(EG."Codigo" AS VARCHAR), CAST(EG."Descripcion" AS VARCHAR),
           CAST(ST.est AS VARCHAR), CAST(A."Resultado" AS VARCHAR), CAST(A."Observacion" AS VARCHAR), CAST(M."Descripcion" AS VARCHAR),
           A."Fecha_Inicio", A."Fecha_Fin",
           CAST(COALESCE(PF."Apellido_Paterno" || COALESCE(' ' || PF."Apellido_Materno", '') || ', ' || PF."Nombres", UF."Apellido_Paterno" || COALESCE(' ' || UF."Apellido_Materno", '') || ', ' || UF."Nombres") AS VARCHAR),
           AU.aut,
           CAST(CASE WHEN AU.aut = 'Y' AND ST.est = 'PENDIENTE' AND lv_act = 'Y' AND (lv_eop IN ('INGRESO','EN_ATENCION') OR (lv_sin AND lv_eop = 'EN_ESPERA')) AND lv_res
                          AND CAST(lv_fecha AS DATE) <= CURRENT_DATE AND MOT.m IS NULL THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN AU.aut = 'Y' AND ST.est = 'EN_ATENCION' AND lv_act = 'Y' AND lv_eop = 'EN_ATENCION' AND INI.u = "HV_UsuarioID" THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN AU.aut = 'Y' AND ST.est IN ('PENDIENTE','EN_ATENCION','DETENIDA')
                          AND "ERP_CAF_FN_ATENCION_PUEDE_CERRAR_SIN"("HV_UsuarioID", E."ID_Solicitud", E."ID_Catalogo_Empresa_Grupo", lv_sede) = 'Y' AND lv_act = 'Y' AND (lv_eop IN ('INGRESO','EN_ATENCION') OR (lv_sin AND lv_eop = 'EN_ESPERA')) THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN ST.est = 'PENDIENTE' THEN
                          CASE WHEN AU.aut <> 'Y' THEN 'Usted no atiende a esta empresa.'
                               WHEN lv_act IS DISTINCT FROM 'Y' OR NOT (lv_eop IN ('INGRESO','EN_ATENCION') OR (lv_sin AND lv_eop = 'EN_ESPERA')) THEN CASE WHEN lv_sin THEN 'Vigilancia aún no verificó los datos del proveedor.' ELSE 'La entrega aún no está lista para atenderse (el proveedor debe haber ingresado).' END
                               WHEN NOT lv_res THEN 'Almacén no confirmó su disponibilidad para esta entrega.'
                               WHEN CAST(lv_fecha AS DATE) > CURRENT_DATE THEN 'La atención solo puede iniciarse el día programado.'
                               WHEN MOT.m IS NOT NULL THEN MOT.m
                               ELSE NULL END
                     WHEN ST.est = 'EN_ATENCION' AND AU.aut = 'Y' AND INI.u IS DISTINCT FROM "HV_UsuarioID" THEN 'Solo quien inició la atención puede detenerla o terminarla.'
                     WHEN ST.est = 'DETENIDA' AND AU.aut <> 'Y' THEN 'Usted no atiende a esta empresa.'
                     WHEN ST.est = 'DETENIDA' AND INI.u IS DISTINCT FROM "HV_UsuarioID" THEN 'Solo quien inició la atención puede reanudarla.'
                     WHEN ST.est = 'DETENIDA' AND MOT.m IS NOT NULL THEN MOT.m
                     ELSE NULL END AS VARCHAR),
           CAST(CASE WHEN AU.aut = 'Y' AND ST.est = 'EN_ATENCION' AND lv_act = 'Y' AND lv_eop = 'EN_ATENCION' AND INI.u = "HV_UsuarioID" THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(CASE WHEN AU.aut = 'Y' AND ST.est = 'DETENIDA' AND lv_act = 'Y' AND lv_eop = 'EN_ATENCION' AND INI.u = "HV_UsuarioID"
                          AND MOT.m IS NULL THEN 'Y' ELSE 'N' END AS CHAR),
           CAST(A."Motivo_Detencion" AS VARCHAR)
      FROM "CAF_Solicitud_Empresa" E
      JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG ON EG."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo"
      LEFT JOIN "CAF_Solicitud_Atencion" A ON A."ID_Solicitud" = E."ID_Solicitud" AND A."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo" AND A."Eliminado" = 'N'
      LEFT JOIN "CAF_Motivo_Sin_Atencion" M ON M."ID_Motivo_Sin_Atencion" = A."ID_Motivo_Sin_Atencion"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" UF ON UF."ID_Usuario" = COALESCE(A."ID_Usuario_Fin", A."ID_Usuario_Inicio")
      LEFT JOIN "CAF_GOVERNANCE"."Personal" PF ON PF."ID_Personal" = UF."ID_Personal"
     CROSS JOIN LATERAL (SELECT "ERP_CAF_FN_ATENCION_ESTADO"(E."ID_Solicitud", E."ID_Catalogo_Empresa_Grupo") AS est) ST
     CROSS JOIN LATERAL (SELECT "ERP_CAF_FN_ATENCION_AUTORIZADO"("HV_UsuarioID", E."ID_Catalogo_Empresa_Grupo", lv_sede) AS aut) AU
     CROSS JOIN LATERAL (SELECT "ERP_CAF_FN_ATENCION_INICIO"(E."ID_Solicitud", E."ID_Catalogo_Empresa_Grupo") AS u) INI
     CROSS JOIN LATERAL (SELECT "ERP_CAF_ATENCION_CUPO_MOTIVO"(E."ID_Solicitud", E."ID_Catalogo_Empresa_Grupo", "HV_UsuarioID", CASE WHEN ST.est = 'DETENIDA' THEN 'REANUDAR' ELSE 'INICIAR' END) AS m) MOT
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
     WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."Eliminado" = 'N' AND A."Estado" IN ('PENDIENTE','EN_ATENCION','DETENIDA');
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
    IF lv_eop IN ('INGRESO','EN_ESPERA') THEN         -- ninguna empresa llegó a atenderse: se pasa por EN_ATENCION para dejar el historial coherente
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
    -- D-243: SIN ingreso vehicular, si nadie llegó a ingresar, la entrega termina aquí (quien no ingresó queda como «no se presentó»)
    IF (SELECT O."Con_Vehiculo" FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N') = 'N'
       AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Persona" P WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Estado" = 'DENTRO') THEN
        UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'NO_SE_PRESENTO', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'APROBADA' AND "Estado" = 'ESPERADA';
        CALL "ERP_CAF_PROVEEDOR_MOVER"("HV_ID_Solicitud", 'SALIO', "HV_UsuarioID", NULL, 'Atención terminada sin ingreso de personas', NULL, lv_c, lv_m);
        IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RAISE EXCEPTION 'mover: %', lv_m; END IF;
        "HV_Mensaje" := 'Atención registrada. Todas las empresas terminaron y nadie ingresó: la entrega quedó cerrada.';
    END IF;
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
    lv_con CHAR(1);
BEGIN
    -- V1.1 2026-11-16 (D-243): SIN ingreso vehicular admite la atención con la entrega EN_ESPERA
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
    SELECT COUNT(*), MAX("Activa"), MAX("Estado_Operativo"), MAX("Con_Vehiculo") INTO lv_n, lv_act, lv_eop, lv_con
      FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
    IF lv_n = 0 OR lv_act <> 'Y' THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La entrega no está programada (solicitud sin aprobar o cancelada).'; RETURN; END IF;
    IF NOT (lv_eop IN ('INGRESO','EN_ATENCION') OR (lv_con = 'N' AND lv_eop = 'EN_ESPERA')) THEN
        "HV_Codigo_Resp" := 409;
        "HV_Mensaje" := CASE WHEN lv_eop IN ('PROGRAMADO','EN_ESPERA') THEN 'Aún no ingresó ningún conductor.'
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
        IF "ERP_CAF_FN_DISPONIBLE"("HV_ID_Solicitud") <> 'Y' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Almacén no confirmó su disponibilidad para esta entrega.'; RETURN;
        END IF;
        lv_est := "ERP_CAF_FN_ATENCION_ESTADO"("HV_ID_Solicitud", "HV_ID_Empresa");
        IF lv_est <> 'PENDIENTE' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE WHEN lv_est = 'EN_ATENCION' THEN 'Esa empresa ya está en atención.'
                                 WHEN lv_est = 'DETENIDA' THEN 'Esa empresa está detenida: use «Reanudar atención».'
                                 ELSE 'Esa empresa ya terminó su atención.' END; RETURN;
        END IF;
        lv_m := "ERP_CAF_ATENCION_CUPO_MOTIVO"("HV_ID_Solicitud", "HV_ID_Empresa", "HV_UsuarioID", 'INICIAR');     -- D-244
        IF lv_m IS NOT NULL THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := LEFT(lv_m, 250); RETURN; END IF;
        CALL "ERP_CAF_ATENCION_ASEGURAR"("HV_ID_Solicitud", "HV_UsuarioID");
        UPDATE "CAF_Solicitud_Atencion"
           SET "Estado" = 'EN_ATENCION', "Fecha_Inicio" = CURRENT_TIMESTAMP, "ID_Usuario_Inicio" = "HV_UsuarioID", "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND "Eliminado" = 'N';
        SELECT "Estado_Operativo" INTO lv_eop FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        IF lv_eop IN ('INGRESO','EN_ESPERA') THEN
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
            "HV_Mensaje" := CASE WHEN lv_est = 'PENDIENTE' THEN 'La atención de esa empresa aún no se inició.'
                                 WHEN lv_est = 'DETENIDA' THEN 'Esa empresa está detenida: reanude la atención para terminarla.'
                                 ELSE 'Esa empresa ya terminó su atención.' END; RETURN;
        END IF;
        IF "ERP_CAF_FN_ATENCION_INICIO"("HV_ID_Solicitud", "HV_ID_Empresa") IS DISTINCT FROM "HV_UsuarioID" THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo quien inició la atención de esta empresa puede terminarla.'; RETURN;
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
        IF lv_est NOT IN ('PENDIENTE','EN_ATENCION','DETENIDA') THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Esa empresa ya terminó su atención.'; RETURN; END IF;
        -- V1.1 2026-11-20 (D-259): quien inició la atención, o un almacenero con la licencia «Cerrar sin atención» (solo de sus empresas)
        IF "ERP_CAF_FN_ATENCION_PUEDE_CERRAR_SIN"("HV_UsuarioID", "HV_ID_Solicitud", "HV_ID_Empresa", lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Solo quien inició la atención, o un almacenero con la licencia «Cerrar sin atención», puede cerrarla.';
            RETURN;
        END IF;
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

-- ----------------------------------------------------------------------------- D-239: detener y reanudar una empresa
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_DETENER_EMPRESA"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_ID_Empresa" BIGINT, IN "HV_Motivo" VARCHAR(300), IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede BIGINT; lv_fecha TIMESTAMP; lv_est VARCHAR(25); lv_c INT; lv_m VARCHAR(250); lv_cod VARCHAR; lv_ini BIGINT;
BEGIN
    -- V1.0 2026-11-15 (D-239): EN_ATENCION -> DETENIDA. El motivo es opcional. Libera el cupo de la empresa (no el de la esclusa). Solo quien la inició.
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_DETENER_EMPRESA';
    BEGIN
        IF LENGTH(COALESCE("HV_Motivo", '')) > 300 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El motivo no puede superar 300 caracteres.'; RETURN; END IF;
        CALL "ERP_CAF_ATENCION_VALIDAR"("HV_ID_Solicitud", "HV_ID_Empresa", "HV_UsuarioID", lv_c, lv_m, lv_sede, lv_fecha);
        IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RETURN; END IF;
        lv_est := "ERP_CAF_FN_ATENCION_ESTADO"("HV_ID_Solicitud", "HV_ID_Empresa");
        IF lv_est <> 'EN_ATENCION' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE WHEN lv_est = 'PENDIENTE' THEN 'La atención de esa empresa aún no se inició.'
                                 WHEN lv_est = 'DETENIDA' THEN 'Esa empresa ya está detenida.' ELSE 'Esa empresa ya terminó su atención.' END; RETURN;
        END IF;
        lv_ini := "ERP_CAF_FN_ATENCION_INICIO"("HV_ID_Solicitud", "HV_ID_Empresa");
        IF lv_ini IS DISTINCT FROM "HV_UsuarioID" THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo quien inició la atención de esta empresa puede detenerla.'; RETURN;
        END IF;
        CALL "ERP_CAF_ATENCION_ASEGURAR"("HV_ID_Solicitud", "HV_UsuarioID");
        UPDATE "CAF_Solicitud_Atencion"
           SET "Estado" = 'DETENIDA', "Fecha_Detencion" = CURRENT_TIMESTAMP, "Motivo_Detencion" = NULLIF(TRIM(COALESCE("HV_Motivo", '')), ''),
               "ID_Usuario_Inicio" = COALESCE("ID_Usuario_Inicio", lv_ini), "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND "Eliminado" = 'N';
        SELECT "Codigo" INTO lv_cod FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa";
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES ("HV_ID_Solicitud", 'EN_ATENCION', 'EN_ATENCION', "HV_UsuarioID", 'ATENCION_DETENIDA', 'Atención detenida: ' || lv_cod || COALESCE(' (' || NULLIF(TRIM("HV_Motivo"), '') || ')', ''));
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Atención detenida.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_DETENER_EMPRESA';
    END;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_REANUDAR_EMPRESA"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_ID_Empresa" BIGINT, IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede BIGINT; lv_fecha TIMESTAMP; lv_est VARCHAR(25); lv_c INT; lv_m VARCHAR(250); lv_cod VARCHAR; lv_lim INT;
BEGIN
    -- V1.0 2026-11-15 (D-239): DETENIDA -> EN_ATENCION. Solo quien la inició y solo si la empresa tiene cupo libre.
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_REANUDAR_EMPRESA';
    BEGIN
        CALL "ERP_CAF_ATENCION_VALIDAR"("HV_ID_Solicitud", "HV_ID_Empresa", "HV_UsuarioID", lv_c, lv_m, lv_sede, lv_fecha);
        IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RETURN; END IF;
        lv_est := "ERP_CAF_FN_ATENCION_ESTADO"("HV_ID_Solicitud", "HV_ID_Empresa");
        IF lv_est <> 'DETENIDA' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE WHEN lv_est = 'EN_ATENCION' THEN 'Esa empresa ya está en atención.'
                                 WHEN lv_est = 'PENDIENTE' THEN 'La atención de esa empresa aún no se inició.' ELSE 'Esa empresa ya terminó su atención.' END; RETURN;
        END IF;
        IF "ERP_CAF_FN_ATENCION_INICIO"("HV_ID_Solicitud", "HV_ID_Empresa") IS DISTINCT FROM "HV_UsuarioID" THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo quien inició la atención de esta empresa puede reanudarla.'; RETURN;
        END IF;
        lv_m := "ERP_CAF_ATENCION_CUPO_MOTIVO"("HV_ID_Solicitud", "HV_ID_Empresa", "HV_UsuarioID", 'REANUDAR');     -- D-244
        IF lv_m IS NOT NULL THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := LEFT(lv_m, 250); RETURN; END IF;
        UPDATE "CAF_Solicitud_Atencion"
           SET "Estado" = 'EN_ATENCION', "Motivo_Detencion" = NULL, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND "Eliminado" = 'N';
        SELECT "Codigo" INTO lv_cod FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa";
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES ("HV_ID_Solicitud", 'EN_ATENCION', 'EN_ATENCION', "HV_UsuarioID", 'ATENCION_REANUDADA', 'Atención reanudada: ' || lv_cod);
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Atención reanudada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_REANUDAR_EMPRESA';
    END;
END;
$$;

-- ----------------------------------------------------------------------------- D-239: varias empresas a la vez
-- Interna: aplica la acción a cada empresa de la lista (ids separados por coma) con las mismas reglas de la acción de una empresa.
-- Se hace lo que se puede: si al menos una empresa se procesó el código es 100 y el mensaje avisa cuáles no (p. ej. «sin cupo»);
-- si ninguna, se devuelve el código y el motivo de la primera.
CREATE OR REPLACE PROCEDURE "ERP_CAF_ATENCION_MULTI"(
    IN "HV_Accion" VARCHAR(12), IN "HV_ID_Solicitud" BIGINT, IN "HV_IDs_Empresa" VARCHAR(200), IN "HV_Texto1" VARCHAR(1000), IN "HV_Texto2" VARCHAR(1000), IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT, INOUT "HV_Mensaje" VARCHAR(250))
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_arr   BIGINT[];
    lv_e     BIGINT;
    lv_c     INT;
    lv_m     VARCHAR(250);
    lv_cod   VARCHAR;
    lv_ok    VARCHAR := '';
    lv_no    VARCHAR := '';
    lv_c1    INT;
    lv_m1    VARCHAR(250);
    lv_nok   INT := 0;
BEGIN
    -- V1.0 2026-11-15 (D-239)
    "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Seleccione al menos una empresa.';
    IF COALESCE(TRIM("HV_IDs_Empresa"), '') = '' OR REPLACE("HV_IDs_Empresa", ' ', '') !~ '^[0-9]+(,[0-9]+)*$' THEN RETURN; END IF;
    lv_arr := CAST(ARRAY(SELECT DISTINCT X FROM UNNEST(STRING_TO_ARRAY(REPLACE("HV_IDs_Empresa", ' ', ''), ',')::BIGINT[]) AS X) AS BIGINT[]);
    FOR lv_e IN SELECT X FROM UNNEST(lv_arr) AS X ORDER BY X LOOP
        lv_c := 500; lv_m := NULL;
        IF "HV_Accion" = 'ATENDER' THEN CALL "ERP_CAF_PROVEEDOR_ATENDER_EMPRESA"("HV_ID_Solicitud", lv_e, "HV_UsuarioID", lv_c, lv_m);
        ELSIF "HV_Accion" = 'DETENER' THEN CALL "ERP_CAF_PROVEEDOR_DETENER_EMPRESA"("HV_ID_Solicitud", lv_e, "HV_Texto1", "HV_UsuarioID", lv_c, lv_m);
        ELSIF "HV_Accion" = 'REANUDAR' THEN CALL "ERP_CAF_PROVEEDOR_REANUDAR_EMPRESA"("HV_ID_Solicitud", lv_e, "HV_UsuarioID", lv_c, lv_m);
        ELSIF "HV_Accion" = 'RECEPCION' THEN CALL "ERP_CAF_PROVEEDOR_RECEPCION_EMPRESA"("HV_ID_Solicitud", lv_e, "HV_Texto1", "HV_Texto2", "HV_UsuarioID", lv_c, lv_m);
        END IF;
        SELECT "Codigo" INTO lv_cod FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "ID_Catalogo_Empresa_Grupo" = lv_e;
        IF lv_c = 100 THEN
            lv_nok := lv_nok + 1; lv_ok := lv_ok || CASE WHEN lv_ok = '' THEN '' ELSE ', ' END || COALESCE(lv_cod, lv_e::VARCHAR);
        ELSE
            IF lv_c1 IS NULL THEN lv_c1 := lv_c; lv_m1 := lv_m; END IF;
            lv_no := lv_no || CASE WHEN lv_no = '' THEN '' ELSE ' ' END || COALESCE(lv_cod, lv_e::VARCHAR) || ': ' || COALESCE(lv_m, 'error');
        END IF;
    END LOOP;
    IF lv_nok = 0 THEN "HV_Codigo_Resp" := COALESCE(lv_c1, 400); "HV_Mensaje" := LEFT(COALESCE(lv_no, lv_m1), 250); RETURN; END IF;
    "HV_Codigo_Resp" := 100;
    "HV_Mensaje" := LEFT(CASE "HV_Accion" WHEN 'ATENDER' THEN 'Atención iniciada: ' WHEN 'DETENER' THEN 'Atención detenida: '
                                          WHEN 'REANUDAR' THEN 'Atención reanudada: ' ELSE 'Atención terminada: ' END || lv_ok || '.'
                         || CASE WHEN lv_no <> '' THEN ' No se pudo en: ' || lv_no ELSE '' END, 250);
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_ATENDER_EMPRESAS"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_IDs_Empresa" VARCHAR(200), IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-15 (D-239): inicia las empresas que tienen cupo y avisa cuáles quedaron fuera
    CALL "ERP_CAF_ATENCION_MULTI"('ATENDER', "HV_ID_Solicitud", "HV_IDs_Empresa", NULL, NULL, "HV_UsuarioID", "HV_Codigo_Resp", "HV_Mensaje");
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_DETENER_EMPRESAS"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_IDs_Empresa" VARCHAR(200), IN "HV_Motivo" VARCHAR(300), IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-15 (D-239)
    CALL "ERP_CAF_ATENCION_MULTI"('DETENER', "HV_ID_Solicitud", "HV_IDs_Empresa", "HV_Motivo", NULL, "HV_UsuarioID", "HV_Codigo_Resp", "HV_Mensaje");
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_REANUDAR_EMPRESAS"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_IDs_Empresa" VARCHAR(200), IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-15 (D-239): reanuda las que tienen cupo; las demás quedan bloqueadas con su aviso
    CALL "ERP_CAF_ATENCION_MULTI"('REANUDAR', "HV_ID_Solicitud", "HV_IDs_Empresa", NULL, NULL, "HV_UsuarioID", "HV_Codigo_Resp", "HV_Mensaje");
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_RECEPCION_EMPRESAS"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_IDs_Empresa" VARCHAR(200), IN "HV_Resultado" VARCHAR(20), IN "HV_Observacion" VARCHAR(1000), IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-11-15 (D-239): termina varias empresas con el mismo resultado/observación; la entrega se recepciona al terminar la última
    CALL "ERP_CAF_ATENCION_MULTI"('RECEPCION', "HV_ID_Solicitud", "HV_IDs_Empresa", "HV_Resultado", "HV_Observacion", "HV_UsuarioID", "HV_Codigo_Resp", "HV_Mensaje");
END;
$$;

-- -----------------------------------------------------------------------------
-- D-244: ERP_CAF_PROVEEDOR_RESERVA_CEDER / _TOMAR
--   La reserva (quién confirmó la disponibilidad) es de un almacenero; solo él inicia la atención. Antes de iniciarla puede CEDERLA: la entrega sigue
--   confirmada (modo y esclusa no cambian) pero sin dueño, y otro almacenero de sus empresas puede TOMARLA si tiene cupo.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_RESERVA_CEDER"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT; lv_sede BIGINT; lv_fd TIMESTAMP; lv_ud BIGINT; lv_eop VARCHAR(20); lv_act CHAR(1);
BEGIN
    -- V1.0 2026-11-16 (D-244)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_RESERVA_CEDER';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX(S."ID_Catalogo_Sede") INTO lv_n, lv_sede FROM "CAF_Solicitud" S
          JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
         WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud de proveedor no existe.'; RETURN; END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso de Almacén.'; RETURN;
        END IF;
        SELECT O."Fecha_Disponibilidad", O."ID_Usuario_Disponibilidad", O."Estado_Operativo", O."Activa" INTO lv_fd, lv_ud, lv_eop, lv_act
          FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
        IF lv_act IS DISTINCT FROM 'Y' OR lv_fd IS NULL THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La disponibilidad de esta entrega no está confirmada.'; RETURN; END IF;
        IF lv_ud IS NULL THEN "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'La reserva ya estaba cedida.'; RETURN; END IF;
        IF lv_ud <> "HV_UsuarioID" THEN "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo quien confirmó la disponibilidad puede ceder la reserva.'; RETURN; END IF;
        IF lv_eop NOT IN ('EN_ESPERA','INGRESO') OR EXISTS (SELECT 1 FROM "CAF_Solicitud_Atencion" A WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."Eliminado" = 'N' AND A."Estado" <> 'PENDIENTE') THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La atención ya empezó: detenga o termine la atención en vez de ceder la reserva.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud_Operacion" SET "ID_Usuario_Disponibilidad" = NULL, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES ("HV_ID_Solicitud", lv_eop, lv_eop, "HV_UsuarioID", 'RESERVA_CEDIDA', 'El almacenero cedió la reserva de la entrega: otro almacenero puede tomarla');
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Reserva cedida. Otro almacenero de esas empresas puede tomarla.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_RESERVA_CEDER';
    END;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_RESERVA_TOMAR"(
    IN "HV_ID_Solicitud" BIGINT, IN "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL, INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT; lv_sede BIGINT; lv_fd TIMESTAMP; lv_ud BIGINT; lv_eop VARCHAR(20); lv_act CHAR(1); lv_m VARCHAR;
BEGIN
    -- V1.0 2026-11-16 (D-244)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_RESERVA_TOMAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX(S."ID_Catalogo_Sede") INTO lv_n, lv_sede FROM "CAF_Solicitud" S
          JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
         WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud de proveedor no existe.'; RETURN; END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_ALMACEN', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso de Almacén.'; RETURN;
        END IF;
        SELECT O."Fecha_Disponibilidad", O."ID_Usuario_Disponibilidad", O."Estado_Operativo", O."Activa" INTO lv_fd, lv_ud, lv_eop, lv_act
          FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = "HV_ID_Solicitud" AND O."Eliminado" = 'N';
        IF lv_act IS DISTINCT FROM 'Y' OR lv_fd IS NULL OR lv_eop NOT IN ('EN_ESPERA','INGRESO') THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Esta entrega no tiene una reserva que tomar.'; RETURN;
        END IF;
        IF lv_ud IS NOT NULL THEN
            IF lv_ud = "HV_UsuarioID" THEN "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'La reserva ya es suya.'; RETURN; END IF;
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La reserva la tiene otro almacenero: solo puede tomarse si la cede.'; RETURN;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Empresa" E WHERE E."ID_Solicitud" = "HV_ID_Solicitud" AND E."Eliminado" = 'N'
                          AND "ERP_CAF_FN_ATENCION_AUTORIZADO"("HV_UsuarioID", E."ID_Catalogo_Empresa_Grupo", lv_sede) = 'Y') THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Usted no atiende a ninguna de las empresas de esta entrega.'; RETURN;
        END IF;
        lv_m := "ERP_CAF_FN_CUPO_ALMACENERO_MOTIVO"("HV_UsuarioID", "HV_ID_Solicitud");
        IF lv_m IS NOT NULL THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := LEFT(lv_m, 250); RETURN; END IF;
        UPDATE "CAF_Solicitud_Operacion" SET "ID_Usuario_Disponibilidad" = "HV_UsuarioID", "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Resultado","Observacion")
        VALUES ("HV_ID_Solicitud", lv_eop, lv_eop, "HV_UsuarioID", 'RESERVA_TOMADA', 'Un almacenero tomó la reserva cedida de la entrega');
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Reserva tomada: usted inicia la atención de esta entrega.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_RESERVA_TOMAR';
    END;
END;
$$;
