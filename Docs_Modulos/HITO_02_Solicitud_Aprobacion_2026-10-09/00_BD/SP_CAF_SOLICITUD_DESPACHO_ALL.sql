-- =============================================================================
-- SP_CAF_SOLICITUD_DESPACHO_ALL.sql   V1.0 2026-11-27 (D-276)
-- Solicitud de DESPACHO (salida de productos). Comparte con la entrega de proveedor la aprobación, la verificación de
-- Vigilancia, la atención de Almacén y la esclusa; cambian los datos del formulario y el transporte.
--   1 ERP_CAF_FN_NUMEROS_DOC_VALIDAR           N.° de OF / OV / orden: formato, cantidad y obligatoriedad ('' = correcto)
--   2 ERP_CAF_FN_DESPACHO_TRANSPORTES          tipos de transporte permitidos para un conjunto de empresas (intersección)
--   3 ERP_CAF_FN_DESPACHO_TRANSPORTE_RESOLVER  transporte que queda: el pedido si es permitido; si no, el predeterminado de la empresa principal
--   4 ERP_CAF_DESPACHO_CONFIG_LISTAR           configuración de transporte por empresa (formulario y pantalla del administrador)
--   5 ERP_CAF_DESPACHO_CONFIG_GUARDAR          el administrador cambia los transportes permitidos y el predeterminado de una empresa
--   6 ERP_CAF_FN_DESPACHO_DATOS_VALIDAR        OF/OV/orden + transporte + franja + correos (datos propios del despacho)
--   7 ERP_CAF_SOLICITUD_CREAR_DESPACHO         crea la solicitud y los conductores EN UNA SOLA OPERACIÓN (todo o nada)
--   8 ERP_CAF_SOLICITUD_DESPACHO_DATOS_GUARDAR edición de los datos propios del despacho (antes de que llegue)
-- Formato de HV_Transportistas igual que ERP_CAF_SOLICITUD_CREAR_PROVEEDOR (registros CHR(30), campos CHR(31):
--   ID_Persona_Externa, RUC, Nombre, Dirección, Placa, Marca, Licencia). En el despacho TODAS las personas son conductores.
-- Códigos: 100, 101, 400, 404, 409, 500. Schema: TRIANONSATELITAL_CAF_PRODD. Requiere el script 46.
-- HANA: STRING_TO_ARRAY / SPLIT_PART no existen (nota T-36); ARRAY(INTERSECT) se reemplaza por una tabla temporal o por TRIM de cadenas.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. Números de documento (OF / OV / orden)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_NUMEROS_DOC_VALIDAR"("HV_Texto" VARCHAR, "HV_Etiqueta" VARCHAR, "HV_Obligatorio" CHAR, "HV_Maximo" INT)
RETURNS VARCHAR(250)
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    lv_norm VARCHAR(200);
    lv_t    TEXT;
    lv_n    INT;
BEGIN
    -- V1.0 2026-11-27
    lv_norm := "ERP_CAF_FN_OC_NORMALIZAR"("HV_Texto");
    IF lv_norm IS NULL THEN
        IF "HV_Obligatorio" = 'Y' THEN RETURN 'Indique el número de ' || "HV_Etiqueta" || ' de este despacho (al menos uno).'; END IF;
        RETURN '';
    END IF;
    FOR lv_t IN SELECT REGEXP_SPLIT_TO_TABLE(lv_norm, ';') LOOP
        IF lv_t !~ '^[A-Z0-9][-A-Z0-9/.]{1,19}$' THEN
            RETURN 'El número de ' || "HV_Etiqueta" || ' «' || lv_t || '» no es válido: use de 2 a 20 letras, números, guion o barra.';
        END IF;
    END LOOP;
    lv_n := LENGTH(lv_norm) - LENGTH(REPLACE(lv_norm, ';', '')) + 1;
    IF lv_n > "HV_Maximo" THEN RETURN 'Indique como máximo ' || "HV_Maximo" || ' números de ' || "HV_Etiqueta" || ' por despacho.'; END IF;
    RETURN '';
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. Transportes permitidos para un conjunto de empresas: los que permiten TODAS (intersección). '' si no hay ninguno en común.
--    HV_IDs_Empresa: «1,3». Orden de salida: SERVICIO_APP, PROPIO_CLIENTE, CONTRATADO.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_DESPACHO_TRANSPORTES"("HV_IDs_Empresa" VARCHAR)
RETURNS VARCHAR(60)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_ids  BIGINT[];
    lv_n    INT;
    lv_t    VARCHAR;
    lv_r    VARCHAR(60) := '';
    lv_ok   INT;
BEGIN
    -- V1.0 2026-11-27
    IF COALESCE(TRIM("HV_IDs_Empresa"), '') = '' OR REPLACE("HV_IDs_Empresa", ' ', '') !~ '^[0-9]+(,[0-9]+)*$' THEN RETURN ''; END IF;
    SELECT ARRAY(SELECT DISTINCT CAST(X AS BIGINT) FROM UNNEST(STRING_TO_ARRAY(REPLACE("HV_IDs_Empresa", ' ', ''), ',')) AS X) INTO lv_ids;
    lv_n := COALESCE(CARDINALITY(lv_ids), 0);
    IF lv_n = 0 THEN RETURN ''; END IF;
    FOREACH lv_t IN ARRAY ARRAY['SERVICIO_APP','PROPIO_CLIENTE','CONTRATADO'] LOOP
        -- cuántas de las empresas indicadas permiten ese transporte (una empresa sin configuración permite los tres)
        SELECT COUNT(*) INTO lv_ok
          FROM UNNEST(lv_ids) AS E
         WHERE COALESCE((SELECT POSITION(';' || lv_t || ';' IN ';' || C."Transportes_Permitidos" || ';')
                           FROM "CAF_Despacho_Config_Empresa" C
                          WHERE C."ID_Catalogo_Empresa_Grupo" = E AND C."Eliminado" = 'N'), 1) > 0;
        IF lv_ok = lv_n THEN lv_r := lv_r || CASE WHEN lv_r = '' THEN '' ELSE ';' END || lv_t; END IF;
    END LOOP;
    RETURN lv_r;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. Transporte resuelto: el pedido (si es permitido); sin pedido, el predeterminado de la empresa PRINCIPAL (la primera) si es
--    permitido para todas; si no, el único permitido; NULL si no hay forma de resolverlo (varios y ninguno elegido).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_DESPACHO_TRANSPORTE_RESOLVER"("HV_IDs_Empresa" VARCHAR, "HV_Transporte" VARCHAR)
RETURNS VARCHAR(20)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_perm VARCHAR(60);
    lv_pred VARCHAR(20);
    lv_prim BIGINT;
BEGIN
    -- V1.0 2026-11-27
    lv_perm := "ERP_CAF_FN_DESPACHO_TRANSPORTES"("HV_IDs_Empresa");
    IF lv_perm = '' THEN RETURN NULL; END IF;
    IF NULLIF(TRIM(COALESCE("HV_Transporte", '')), '') IS NOT NULL THEN
        IF POSITION(';' || TRIM("HV_Transporte") || ';' IN ';' || lv_perm || ';') > 0 THEN RETURN TRIM("HV_Transporte"); END IF;
        RETURN NULL;
    END IF;
    IF POSITION(';' IN lv_perm) = 0 THEN RETURN lv_perm; END IF;   -- un solo transporte permitido: queda fijo
    lv_prim := CAST(SPLIT_PART(REPLACE("HV_IDs_Empresa", ' ', ''), ',', 1) AS BIGINT);
    SELECT C."Transporte_Predeterminado" INTO lv_pred FROM "CAF_Despacho_Config_Empresa" C
     WHERE C."ID_Catalogo_Empresa_Grupo" = lv_prim AND C."Eliminado" = 'N';
    IF lv_pred IS NOT NULL AND POSITION(';' || lv_pred || ';' IN ';' || lv_perm || ';') > 0 THEN RETURN lv_pred; END IF;
    RETURN NULL;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. Configuración por empresa (todas las empresas activas, tengan o no fila)
-- -----------------------------------------------------------------------------
DROP FUNCTION IF EXISTS "ERP_CAF_DESPACHO_CONFIG_LISTAR"();
CREATE OR REPLACE FUNCTION "ERP_CAF_DESPACHO_CONFIG_LISTAR"()
RETURNS TABLE ("ID_Catalogo_Empresa_Grupo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Transportes_Permitidos" VARCHAR,
               "Transporte_Predeterminado" VARCHAR, "Es_Fijo" CHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-27: sin fila = los tres transportes permitidos y predeterminado SERVICIO_APP
    RETURN QUERY
    SELECT EG."ID_Catalogo_Empresa_Grupo", CAST(EG."Codigo" AS VARCHAR), CAST(EG."Descripcion" AS VARCHAR),
           CAST(COALESCE(C."Transportes_Permitidos", 'SERVICIO_APP;PROPIO_CLIENTE;CONTRATADO') AS VARCHAR),
           CAST(COALESCE(C."Transporte_Predeterminado", 'SERVICIO_APP') AS VARCHAR),
           CAST(CASE WHEN POSITION(';' IN COALESCE(C."Transportes_Permitidos", 'SERVICIO_APP;PROPIO_CLIENTE;CONTRATADO')) = 0 THEN 'Y' ELSE 'N' END AS CHAR)
      FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG
      LEFT JOIN "CAF_Despacho_Config_Empresa" C ON C."ID_Catalogo_Empresa_Grupo" = EG."ID_Catalogo_Empresa_Grupo" AND C."Eliminado" = 'N'
     WHERE EG."Eliminado" = 'N' AND EG."Activo" = 'Y'
     ORDER BY EG."Orden", EG."ID_Catalogo_Empresa_Grupo";
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. Guardar la configuración de una empresa (el permiso lo exige el controlador: solo el Administrador)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_DESPACHO_CONFIG_GUARDAR"(
    IN    "HV_ID_Empresa"           BIGINT,
    IN    "HV_Transportes"          VARCHAR(60),
    IN    "HV_Predeterminado"       VARCHAR(20),
    IN    "HV_UsuarioID"            BIGINT,
    INOUT "HV_Codigo_Resp"          INT DEFAULT NULL,
    INOUT "HV_Mensaje"              VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_t    TEXT;
    lv_norm VARCHAR(60) := '';
    lv_n    INT;
BEGIN
    -- V1.0 2026-11-27
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_DESPACHO_CONFIG_GUARDAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG
         WHERE EG."ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa" AND EG."Eliminado" = 'N' AND EG."Activo" = 'Y';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La empresa no existe o no está activa.'; RETURN; END IF;
        -- normaliza en el orden fijo SERVICIO_APP, PROPIO_CLIENTE, CONTRATADO y rechaza códigos desconocidos
        FOR lv_t IN SELECT REGEXP_SPLIT_TO_TABLE(COALESCE("HV_Transportes", ''), '[;,]') LOOP
            IF TRIM(lv_t) <> '' AND TRIM(lv_t) NOT IN ('SERVICIO_APP','PROPIO_CLIENTE','CONTRATADO') THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Tipo de transporte desconocido: ' || TRIM(lv_t) || '.'; RETURN;
            END IF;
        END LOOP;
        FOREACH lv_t IN ARRAY ARRAY['SERVICIO_APP','PROPIO_CLIENTE','CONTRATADO'] LOOP
            IF POSITION(';' || lv_t || ';' IN ';' || REPLACE(COALESCE("HV_Transportes", ''), ',', ';') || ';') > 0 THEN
                lv_norm := lv_norm || CASE WHEN lv_norm = '' THEN '' ELSE ';' END || lv_t;
            END IF;
        END LOOP;
        IF lv_norm = '' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Marque al menos un tipo de transporte permitido.'; RETURN; END IF;
        IF POSITION(';' || COALESCE("HV_Predeterminado", '') || ';' IN ';' || lv_norm || ';') = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El transporte predeterminado debe estar entre los permitidos.'; RETURN;
        END IF;
        UPDATE "CAF_Despacho_Config_Empresa"
           SET "Transportes_Permitidos" = lv_norm, "Transporte_Predeterminado" = "HV_Predeterminado", "Eliminado" = 'N',
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa";
        IF NOT FOUND THEN
            INSERT INTO "CAF_Despacho_Config_Empresa" ("ID_Catalogo_Empresa_Grupo","Transportes_Permitidos","Transporte_Predeterminado","UsuarioID_Create")
            VALUES ("HV_ID_Empresa", lv_norm, "HV_Predeterminado", "HV_UsuarioID");
        END IF;
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Configuración de transporte guardada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_DESPACHO_CONFIG_GUARDAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. Datos propios del despacho ('' si está bien o el mensaje)
--    OF obligatoria (1 a 5); OV y orden opcionales (1 a 5); transporte resuelto y válido; con transporte del cliente o contratado por
--    la empresa se exige la empresa transportista y, en el conductor principal, el RUC (SERVICIO_APP solo pide nombre, DNI y placa).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_DESPACHO_DATOS_VALIDAR"(
    "HV_Numeros_OF"            VARCHAR,
    "HV_Numeros_OV"            VARCHAR,
    "HV_Numeros_Orden"         VARCHAR,
    "HV_IDs_Empresa"           VARCHAR,
    "HV_Transporte"            VARCHAR,      -- el pedido por el solicitante (puede ir vacío)
    "HV_Empresa_Transportista" VARCHAR,
    "HV_Ruc_Principal"         VARCHAR,
    "HV_Fecha_Hora_Prevista"   TIMESTAMP,
    "HV_Hora_Hasta"            VARCHAR,
    "HV_Contacto_Correos"      VARCHAR
)
RETURNS VARCHAR(250)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_err VARCHAR(250);
    lv_tr  VARCHAR(20);
    lv_h   VARCHAR(10);
BEGIN
    -- V1.0 2026-11-27
    lv_err := "ERP_CAF_FN_NUMEROS_DOC_VALIDAR"("HV_Numeros_OF", 'OF', 'Y', 5);
    IF lv_err <> '' THEN RETURN lv_err; END IF;
    lv_err := "ERP_CAF_FN_NUMEROS_DOC_VALIDAR"("HV_Numeros_OV", 'OV', 'N', 5);
    IF lv_err <> '' THEN RETURN lv_err; END IF;
    lv_err := "ERP_CAF_FN_NUMEROS_DOC_VALIDAR"("HV_Numeros_Orden", 'orden', 'N', 5);
    IF lv_err <> '' THEN RETURN lv_err; END IF;

    lv_tr := "ERP_CAF_FN_DESPACHO_TRANSPORTE_RESOLVER"("HV_IDs_Empresa", "HV_Transporte");
    IF lv_tr IS NULL THEN
        IF "ERP_CAF_FN_DESPACHO_TRANSPORTES"("HV_IDs_Empresa") = '' THEN
            RETURN 'Las empresas elegidas no tienen un tipo de transporte en común: haga una solicitud por empresa.';
        END IF;
        RETURN 'Elija un tipo de transporte válido para la(s) empresa(s) del despacho.';
    END IF;
    IF lv_tr IN ('PROPIO_CLIENTE','CONTRATADO') THEN
        IF NULLIF(TRIM(COALESCE("HV_Empresa_Transportista", '')), '') IS NULL THEN
            RETURN 'Indique la empresa de transporte (con transporte del cliente o contratado se exige).';
        END IF;
        IF NULLIF(TRIM(COALESCE("HV_Ruc_Principal", '')), '') IS NULL THEN
            RETURN 'Indique el RUC de la empresa de transporte del conductor principal.';
        END IF;
    END IF;
    IF LENGTH(TRIM(COALESCE("HV_Empresa_Transportista", ''))) > 200 THEN
        RETURN 'La empresa de transporte no puede superar 200 caracteres.';
    END IF;
    lv_h := NULLIF(TRIM(COALESCE("HV_Hora_Hasta", '')), '');
    IF lv_h IS NOT NULL THEN
        IF lv_h !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' THEN RETURN 'La hora final de la franja no es válida (use HH:MM).'; END IF;
        IF "HV_Fecha_Hora_Prevista" IS NOT NULL AND CAST(lv_h AS TIME) <= CAST("HV_Fecha_Hora_Prevista" AS TIME) THEN
            RETURN 'La hora final de la franja debe ser posterior a la hora estimada de llegada.';
        END IF;
    END IF;
    IF NULLIF(TRIM(COALESCE("HV_Contacto_Correos", '')), '') IS NOT NULL
       AND (LENGTH(TRIM("HV_Contacto_Correos")) > 500 OR "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Contacto_Correos") <> 'Y') THEN
        RETURN 'Los correos del responsable no son válidos (uno por etiqueta o separados por «;»).';
    END IF;
    RETURN '';
END;
$$;

-- -----------------------------------------------------------------------------
-- 7. ERP_CAF_SOLICITUD_CREAR_DESPACHO
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(
    IN    "HV_ID_Catalogo_Sede"         BIGINT,
    IN    "HV_Fecha_Hora_Prevista"      TIMESTAMP,
    IN    "HV_Empresa_Visitante"        VARCHAR(500),     -- cliente / destino del despacho
    IN    "HV_Observaciones"            VARCHAR(2000),
    IN    "HV_IDs_Persona_Externa"      VARCHAR(2000),
    IN    "HV_Copias"                   VARCHAR(2000),
    IN    "HV_ID_Solicitud_Origen"      BIGINT,
    IN    "HV_Contacto_Nombre"          VARCHAR(200),
    IN    "HV_Contacto_Telefonos"       VARCHAR(100),
    IN    "HV_IDs_Empresa"              VARCHAR(100),     -- empresas del grupo que despachan, «1,3» (la primera es la principal)
    IN    "HV_Transportistas"           VARCHAR(8000),
    IN    "HV_Numeros_OF"               VARCHAR(200),
    IN    "HV_Numeros_OV"               VARCHAR(200),
    IN    "HV_Numeros_Orden"            VARCHAR(200),
    IN    "HV_Transporte"               VARCHAR(20),      -- vacío = el que corresponda a la empresa
    IN    "HV_Empresa_Transportista"    VARCHAR(200),
    IN    "HV_Hora_Hasta"               VARCHAR(5),
    IN    "HV_Contacto_Correos"         VARCHAR(500),
    IN    "HV_UsuarioID"                BIGINT,
    INOUT "HV_ID_Solicitud_Result"      BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Solicitud_Result"  VARCHAR(20) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"              INT DEFAULT NULL,
    INOUT "HV_Mensaje"                  VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_tipo   BIGINT;
    lv_regs   TEXT[];
    lv_reg    TEXT;
    lv_i      INT;
    lv_n      INT;
    lv_nper   INT;
    lv_ids    VARCHAR(2000);
    lv_listaP VARCHAR(2100);
    lv_pid    BIGINT;
    lv_vistos VARCHAR(2100) := ',';
    lv_err    VARCHAR(250);
    lv_emp    VARCHAR(100);
    lv_tr     VARCHAR(20);
    lv_p_id   BIGINT; lv_p_ruc VARCHAR; lv_p_nom VARCHAR; lv_p_dir VARCHAR; lv_p_pla VARCHAR; lv_p_mar VARCHAR; lv_p_lic VARCHAR;
    lv_c      INT;
    lv_m      VARCHAR(250);
BEGIN
    -- V1.0 2026-11-27 (D-276)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR_DESPACHO';
    "HV_ID_Solicitud_Result" := 0;
    BEGIN
        SELECT MAX("ID_Catalogo_Tipo_Acceso") INTO lv_tipo FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'DESPACHO' AND "Eliminado" = 'N';
        IF lv_tipo IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de acceso de despachos no existe.'; RETURN;
        END IF;
        lv_emp := REPLACE(COALESCE("HV_IDs_Empresa", ''), ' ', '');
        IF lv_emp = '' OR lv_emp !~ '^[0-9]+(,[0-9]+)*$' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique la empresa del grupo que despacha.'; RETURN;
        END IF;

        -- Conductores: en el despacho TODAS las personas son conductores (no hay ayudante de descarga)
        lv_regs := STRING_TO_ARRAY(NULLIF(TRIM(COALESCE("HV_Transportistas", '')), ''), CHR(30));
        lv_n := COALESCE(ARRAY_LENGTH(lv_regs, 1), 0);
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Agregue al menos un conductor.'; RETURN;
        END IF;
        lv_ids := REPLACE(REPLACE(COALESCE("HV_IDs_Persona_Externa", ''), ' ', ''), ';', ',');
        lv_listaP := ',' || lv_ids || ',';
        lv_nper := CASE WHEN LENGTH(lv_ids) = 0 THEN 0 ELSE LENGTH(lv_ids) - LENGTH(REPLACE(lv_ids, ',', '')) + 1 END;
        IF lv_nper <> lv_n THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'En un despacho todas las personas son conductores: cada una debe llevar sus datos de transporte.'; RETURN;
        END IF;

        FOR lv_i IN 1..lv_n LOOP
            lv_reg := lv_regs[lv_i];
            lv_pid := CASE WHEN SPLIT_PART(lv_reg, CHR(31), 1) ~ '^[0-9]+$' THEN CAST(SPLIT_PART(lv_reg, CHR(31), 1) AS BIGINT) ELSE NULL END;
            IF lv_pid IS NULL OR lv_listaP NOT LIKE '%,' || CAST(lv_pid AS VARCHAR) || ',%' THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Cada conductor debe estar entre las personas de la solicitud.'; RETURN;
            END IF;
            IF lv_vistos LIKE '%,' || CAST(lv_pid AS VARCHAR) || ',%' THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Una persona está marcada dos veces como conductor.'; RETURN;
            END IF;
            lv_vistos := lv_vistos || CAST(lv_pid AS VARCHAR) || ',';
            lv_err := "ERP_CAF_FN_TRANSPORTISTA_VALIDAR"(SPLIT_PART(lv_reg, CHR(31), 2), SPLIT_PART(lv_reg, CHR(31), 3), SPLIT_PART(lv_reg, CHR(31), 4),
                                                         SPLIT_PART(lv_reg, CHR(31), 5), SPLIT_PART(lv_reg, CHR(31), 6), SPLIT_PART(lv_reg, CHR(31), 7));
            IF lv_err <> '' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := lv_err; RETURN; END IF;
        END LOOP;

        lv_reg   := lv_regs[1];
        lv_p_id  := CAST(SPLIT_PART(lv_reg, CHR(31), 1) AS BIGINT);
        lv_p_ruc := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 2)), '');
        lv_p_nom := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 3)), '');
        lv_p_dir := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 4)), '');
        lv_p_pla := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 5)), '');
        lv_p_mar := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 6)), '');
        lv_p_lic := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 7)), '');

        -- Datos propios del despacho y teléfonos (antes de crear nada)
        lv_err := "ERP_CAF_FN_DESPACHO_DATOS_VALIDAR"("HV_Numeros_OF", "HV_Numeros_OV", "HV_Numeros_Orden", lv_emp, "HV_Transporte",
                                                      "HV_Empresa_Transportista", lv_p_ruc, "HV_Fecha_Hora_Prevista", "HV_Hora_Hasta", "HV_Contacto_Correos");
        IF lv_err = '' THEN lv_err := "ERP_CAF_FN_TELEFONOS_VALIDAR"("HV_Contacto_Telefonos"); END IF;
        IF lv_err <> '' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := lv_err; RETURN; END IF;
        lv_tr := "ERP_CAF_FN_DESPACHO_TRANSPORTE_RESOLVER"(lv_emp, "HV_Transporte");

        -- Crea la solicitud con la misma rutina de proveedor: empresa principal = la primera (el trigger crea su fila)
        CALL "ERP_CAF_SOLICITUD_CREAR"("HV_ID_Catalogo_Sede", lv_tipo, NULL, "HV_Fecha_Hora_Prevista", "HV_Empresa_Visitante", NULL, NULL, "HV_Observaciones",
                                       NULL, "HV_IDs_Persona_Externa", "HV_Copias", "HV_ID_Solicitud_Origen", NULL, lv_p_pla, NULL,
                                       "HV_Contacto_Nombre", "ERP_CAF_FN_TELEFONOS_NORMALIZAR"("HV_Contacto_Telefonos"), NULL,
                                       CAST(SPLIT_PART(lv_emp, ',', 1) AS BIGINT), lv_p_ruc, lv_p_dir, lv_p_mar, lv_p_lic,
                                       lv_p_id, "HV_UsuarioID", "HV_ID_Solicitud_Result", "HV_Codigo_Solicitud_Result", lv_c, lv_m);
        IF lv_c <> 100 THEN
            "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; "HV_ID_Solicitud_Result" := 0; "HV_Codigo_Solicitud_Result" := NULL; RETURN;
        END IF;

        -- Varias empresas (PT y TA hacia la misma dirección): se registran todas
        IF POSITION(',' IN lv_emp) > 0 THEN
            CALL "ERP_CAF_SOLICITUD_EMPRESAS_ASIGNAR"("HV_ID_Solicitud_Result", lv_emp, "HV_UsuarioID", lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'empresas: %', lv_m; END IF;
        END IF;

        UPDATE "CAF_Solicitud"
           SET "Numeros_OF"            = "ERP_CAF_FN_OC_NORMALIZAR"("HV_Numeros_OF"),
               "Numeros_OV"            = "ERP_CAF_FN_OC_NORMALIZAR"("HV_Numeros_OV"),
               "Numeros_Orden"         = "ERP_CAF_FN_OC_NORMALIZAR"("HV_Numeros_Orden"),
               "Despacho_Transporte"   = lv_tr,
               "Empresa_Transportista" = NULLIF(TRIM("HV_Empresa_Transportista"), ''),
               "Hora_Hasta_Prevista"   = CASE WHEN NULLIF(TRIM(COALESCE("HV_Hora_Hasta", '')), '') IS NULL THEN NULL ELSE CAST(TRIM("HV_Hora_Hasta") AS TIME) END,
               "Contacto_Correos"      = NULLIF(TRIM("HV_Contacto_Correos"), '')
         WHERE "ID_Solicitud" = "HV_ID_Solicitud_Result";

        UPDATE "CAF_Solicitud_Transportista" T SET "Nombre" = lv_p_nom
         WHERE T."ID_Solicitud" = "HV_ID_Solicitud_Result"
           AND T."ID_Solicitud_Persona" IN (SELECT P."ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" P
                                             WHERE P."ID_Solicitud" = "HV_ID_Solicitud_Result" AND P."ID_Persona_Externa" = lv_p_id);

        FOR lv_i IN 2..lv_n LOOP
            lv_reg := lv_regs[lv_i];
            INSERT INTO "CAF_Solicitud_Transportista" ("ID_Solicitud","ID_Solicitud_Persona","Ruc","Nombre","Direccion","Placa","Marca","Licencia","UsuarioID_Create")
            SELECT "HV_ID_Solicitud_Result", P."ID_Solicitud_Persona",
                   NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 2)), ''), NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 3)), ''),
                   NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 4)), ''),
                   "ERP_CAF_FN_PLACA_NORMALIZAR"(SPLIT_PART(lv_reg, CHR(31), 5)),
                   NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 6)), ''), NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 7)), ''), "HV_UsuarioID"
              FROM "CAF_Solicitud_Persona" P
             WHERE P."ID_Solicitud" = "HV_ID_Solicitud_Result" AND P."ID_Persona_Externa" = CAST(SPLIT_PART(lv_reg, CHR(31), 1) AS BIGINT);
        END LOOP;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := lv_m;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR_DESPACHO';
        "HV_ID_Solicitud_Result" := 0;
        "HV_Codigo_Solicitud_Result" := NULL;
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 8. Edición de los datos propios del despacho (el dueño; antes de que llegue la primera persona)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_DESPACHO_DATOS_GUARDAR"(
    IN    "HV_ID_Solicitud"          BIGINT,
    IN    "HV_Numeros_OF"            VARCHAR(200),
    IN    "HV_Numeros_OV"            VARCHAR(200),
    IN    "HV_Numeros_Orden"         VARCHAR(200),
    IN    "HV_Transporte"            VARCHAR(20),
    IN    "HV_Empresa_Transportista" VARCHAR(200),
    IN    "HV_Hora_Hasta"            VARCHAR(5),
    IN    "HV_Contacto_Correos"      VARCHAR(500),
    IN    "HV_UsuarioID"             BIGINT,
    INOUT "HV_Codigo_Resp"           INT DEFAULT NULL,
    INOUT "HV_Mensaje"               VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_tipo   VARCHAR(50);
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_emp    VARCHAR(100);
    lv_ruc    VARCHAR(11);
    lv_tr     VARCHAR(20);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_err    VARCHAR(250);
BEGIN
    -- V1.0 2026-11-27
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DESPACHO_DATOS_GUARDAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";   -- serializa por solicitud
        SELECT COUNT(*), MAX(TA."Codigo"), MAX(S."ID_Usuario_Solicitante"), MAX(S."Estado"), MAX(S."Fecha_Hora_Prevista"), MAX(S."Proveedor_RUC")
          INTO lv_n, lv_tipo, lv_owner, lv_estado, lv_fecha, lv_ruc
          FROM "CAF_Solicitud" S JOIN "Catalogo_Tipo_Acceso" TA ON TA."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso"
         WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN; END IF;
        IF lv_tipo <> 'DESPACHO' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Estos datos corresponden solo a los despachos.'; RETURN; END IF;
        IF lv_owner <> "HV_UsuarioID" THEN "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya.'; RETURN; END IF;
        IF lv_estado IN ('CANCELADA','RECHAZADA','VENCIDA') THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud ya no admite cambios.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Estado" <> 'ESPERADA';
        IF lv_n > 0 THEN "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Ya ingresó una persona: estos datos no se cambian.'; RETURN; END IF;

        lv_emp := "ERP_CAF_FN_EMPRESAS_SOLICITUD"("HV_ID_Solicitud", 'I');
        lv_err := "ERP_CAF_FN_DESPACHO_DATOS_VALIDAR"("HV_Numeros_OF", "HV_Numeros_OV", "HV_Numeros_Orden", lv_emp, "HV_Transporte",
                                                      "HV_Empresa_Transportista", lv_ruc, lv_fecha, "HV_Hora_Hasta", "HV_Contacto_Correos");
        IF lv_err <> '' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := lv_err; RETURN; END IF;
        lv_tr := "ERP_CAF_FN_DESPACHO_TRANSPORTE_RESOLVER"(lv_emp, "HV_Transporte");

        UPDATE "CAF_Solicitud"
           SET "Numeros_OF"            = "ERP_CAF_FN_OC_NORMALIZAR"("HV_Numeros_OF"),
               "Numeros_OV"            = "ERP_CAF_FN_OC_NORMALIZAR"("HV_Numeros_OV"),
               "Numeros_Orden"         = "ERP_CAF_FN_OC_NORMALIZAR"("HV_Numeros_Orden"),
               "Despacho_Transporte"   = lv_tr,
               "Empresa_Transportista" = NULLIF(TRIM("HV_Empresa_Transportista"), ''),
               "Hora_Hasta_Prevista"   = CASE WHEN NULLIF(TRIM(COALESCE("HV_Hora_Hasta", '')), '') IS NULL THEN NULL ELSE CAST(TRIM("HV_Hora_Hasta") AS TIME) END,
               "Contacto_Correos"      = NULLIF(TRIM("HV_Contacto_Correos"), ''),
               "UsuarioID_Update"      = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'EDITAR',
             'Actualizó la OF, la OV, el número de orden, el transporte, la franja horaria o el correo del responsable del despacho', "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Datos del despacho actualizados.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DESPACHO_DATOS_GUARDAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 9. ERP_CAF_FN_DASHBOARD_ENTREGAS_MODO   qué tipos muestra el calendario de entregas en una sede
--    Parámetro DASHBOARD_ENTREGAS_MODO:<código de sede> si existe; si no, DASHBOARD_ENTREGAS_MODO; si no, AMBOS.
--    Valores: PROVEEDORES (solo proveedores, aislado) | DESPACHOS (solo despachos) | AMBOS (combinados).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_DASHBOARD_ENTREGAS_MODO"("HV_ID_Catalogo_Sede" BIGINT)
RETURNS VARCHAR(20)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_cod VARCHAR(50);
    lv_v   VARCHAR(200);
BEGIN
    -- V1.0 2026-11-27
    SELECT S."Codigo" INTO lv_cod FROM "CAF_GOVERNANCE"."Catalogo_Sede" S WHERE S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede";
    lv_v := "ERP_CAF_PARAMETRO_VALOR"('DASHBOARD_ENTREGAS_MODO:' || COALESCE(lv_cod, ''));
    IF lv_v IS NULL OR lv_v NOT IN ('PROVEEDORES','DESPACHOS','AMBOS') THEN
        lv_v := "ERP_CAF_PARAMETRO_VALOR"('DASHBOARD_ENTREGAS_MODO');
    END IF;
    IF lv_v IS NULL OR lv_v NOT IN ('PROVEEDORES','DESPACHOS','AMBOS') THEN lv_v := 'AMBOS'; END IF;
    RETURN lv_v;
END;
$$;
