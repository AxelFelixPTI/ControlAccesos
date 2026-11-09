-- =============================================================================
-- Archivo : SP_CAF_SOLICITUD_TRANSPORTISTA_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Hito    : 2 - Solicitud y aprobación | Fase 1 - Rutinas   (D-223)
-- Versión : V1.0 2026-11-06
-- Estado  : CANDIDATO - probado en PostgreSQL 16 sobre la base con 01 a 23
-- Requiere: script 23 y SP_CAF_SOLICITUD_BASE_ALL, SP_CAF_SOLICITUD_ALL, SP_CAF_PROVEEDOR_ALL, SP_CAF_SOLICITUD_ADJUNTO_ALL.
-- =============================================================================
-- Solicitud de proveedor con VARIOS transportistas, cada uno con sus datos opcionales.
--   1 ERP_CAF_FN_TRANSPORTISTA_VALIDAR       formato de los datos de un transportista ('' = correcto)
--   2 ERP_CAF_SOLICITUD_CREAR_PROVEEDOR      crea la solicitud de proveedor y los datos de cada transportista EN UNA SOLA OPERACIÓN
--   3 ERP_CAF_SOLICITUD_TRANSPORTISTAS       lista los transportistas de una solicitud (quien puede ver la solicitud)
-- Formato de HV_Transportistas: un transportista por registro, registros separados por CHR(30) y campos por CHR(31):
--   ID_Persona_Externa, RUC, Nombre, Dirección, Placa, Marca, Licencia.
-- El PRIMERO es el transportista principal (sus datos se copian a CAF_Solicitud, para el calendario y Vigilancia).
-- DNI y nombres son los de la persona (siempre obligatorios); aquí solo van los datos opcionales del transportista.
-- HANA: STRING_TO_ARRAY / SPLIT_PART no existen; se reemplazan por SERIES_GENERATE_INTEGER + SUBSTR_REGEXPR (nota T-36).
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_FN_TRANSPORTISTA_VALIDAR   ('' si está bien, o el mensaje)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_TRANSPORTISTA_VALIDAR"(
    "HV_Ruc" VARCHAR, "HV_Nombre" VARCHAR, "HV_Direccion" VARCHAR, "HV_Placa" VARCHAR, "HV_Marca" VARCHAR, "HV_Licencia" VARCHAR
)
RETURNS VARCHAR(250)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_placa VARCHAR(15);
BEGIN
    -- V1.0 2026-11-06
    IF NULLIF(TRIM(COALESCE("HV_Ruc", '')), '') IS NOT NULL AND TRIM("HV_Ruc") !~ '^[0-9]{11}$' THEN RETURN 'El RUC del transportista debe tener 11 dígitos.'; END IF;
    IF LENGTH(TRIM(COALESCE("HV_Nombre", ''))) > 200 THEN RETURN 'El nombre del transportista no puede superar 200 caracteres.'; END IF;
    IF LENGTH(TRIM(COALESCE("HV_Direccion", ''))) > 300 THEN RETURN 'La dirección del transportista no puede superar 300 caracteres.'; END IF;
    lv_placa := "ERP_CAF_FN_PLACA_NORMALIZAR"("HV_Placa");
    IF lv_placa IS NOT NULL AND lv_placa !~ '^[A-Z0-9]{5,8}$' THEN RETURN 'La placa del vehículo debe tener de 5 a 8 letras o números.'; END IF;
    IF LENGTH(TRIM(COALESCE("HV_Marca", ''))) > 50 THEN RETURN 'La marca del vehículo no puede superar 50 caracteres.'; END IF;
    IF LENGTH(TRIM(COALESCE("HV_Licencia", ''))) > 20 THEN RETURN 'La licencia de conducir no puede superar 20 caracteres.'; END IF;
    RETURN '';
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_SOLICITUD_CREAR_PROVEEDOR
--    400 validación | 101 sin permiso (lo decide ERP_CAF_SOLICITUD_CREAR) | 500 error. Todo o nada.
--    Pide al menos un transportista (el primero es el principal) y que cada uno esté entre las personas.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(
    IN    "HV_ID_Catalogo_Sede"         BIGINT,
    IN    "HV_Fecha_Hora_Prevista"      TIMESTAMP,
    IN    "HV_Empresa_Visitante"        VARCHAR(500),
    IN    "HV_Observaciones"            VARCHAR(2000),
    IN    "HV_IDs_Persona_Externa"      VARCHAR(2000),
    IN    "HV_Copias"                   VARCHAR(2000),
    IN    "HV_ID_Solicitud_Origen"      BIGINT,
    IN    "HV_Contacto_Nombre"          VARCHAR(200),
    IN    "HV_Contacto_Telefonos"       VARCHAR(100),
    IN    "HV_ID_Empresa_Destino"       BIGINT,
    IN    "HV_Transportistas"           VARCHAR(8000),
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
    lv_ids    VARCHAR(2000);
    lv_listaP VARCHAR(2100);
    lv_pid    BIGINT;
    lv_vistos VARCHAR(2100) := ',';
    lv_err    VARCHAR(250);
    lv_p_id   BIGINT; lv_p_ruc VARCHAR; lv_p_nom VARCHAR; lv_p_dir VARCHAR; lv_p_pla VARCHAR; lv_p_mar VARCHAR; lv_p_lic VARCHAR;
    lv_c      INT;
    lv_m      VARCHAR(250);
BEGIN
    -- V1.0 2026-11-06 (D-223)
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR_PROVEEDOR';
    "HV_ID_Solicitud_Result" := 0;
    BEGIN
        SELECT MAX("ID_Catalogo_Tipo_Acceso") INTO lv_tipo FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'PROVEEDOR' AND "Eliminado" = 'N';
        IF lv_tipo IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de acceso de proveedores no existe.'; RETURN;
        END IF;

        lv_regs := STRING_TO_ARRAY(NULLIF(TRIM(COALESCE("HV_Transportistas", '')), ''), CHR(30));
        lv_n := COALESCE(ARRAY_LENGTH(lv_regs, 1), 0);
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Marque al menos un transportista entre las personas de la solicitud.'; RETURN;
        END IF;
        lv_ids := REPLACE(REPLACE(COALESCE("HV_IDs_Persona_Externa", ''), ' ', ''), ';', ',');
        lv_listaP := ',' || lv_ids || ',';

        -- Cada transportista: persona de la solicitud, sin repetir, con datos de formato válido
        FOR lv_i IN 1..lv_n LOOP
            lv_reg := lv_regs[lv_i];
            lv_pid := CASE WHEN SPLIT_PART(lv_reg, CHR(31), 1) ~ '^[0-9]+$' THEN CAST(SPLIT_PART(lv_reg, CHR(31), 1) AS BIGINT) ELSE NULL END;
            IF lv_pid IS NULL OR lv_listaP NOT LIKE '%,' || CAST(lv_pid AS VARCHAR) || ',%' THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Cada transportista debe estar entre las personas de la solicitud.'; RETURN;
            END IF;
            IF lv_vistos LIKE '%,' || CAST(lv_pid AS VARCHAR) || ',%' THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Una persona está marcada dos veces como transportista.'; RETURN;
            END IF;
            lv_vistos := lv_vistos || CAST(lv_pid AS VARCHAR) || ',';
            lv_err := "ERP_CAF_FN_TRANSPORTISTA_VALIDAR"(SPLIT_PART(lv_reg, CHR(31), 2), SPLIT_PART(lv_reg, CHR(31), 3), SPLIT_PART(lv_reg, CHR(31), 4),
                                                         SPLIT_PART(lv_reg, CHR(31), 5), SPLIT_PART(lv_reg, CHR(31), 6), SPLIT_PART(lv_reg, CHR(31), 7));
            IF lv_err <> '' THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := lv_err; RETURN;
            END IF;
        END LOOP;

        -- El primero es el principal: sus datos van también a la solicitud (calendario, Vigilancia)
        lv_reg   := lv_regs[1];
        lv_p_id  := CAST(SPLIT_PART(lv_reg, CHR(31), 1) AS BIGINT);
        lv_p_ruc := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 2)), '');
        lv_p_nom := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 3)), '');
        lv_p_dir := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 4)), '');
        lv_p_pla := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 5)), '');
        lv_p_mar := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 6)), '');
        lv_p_lic := NULLIF(TRIM(SPLIT_PART(lv_reg, CHR(31), 7)), '');

        CALL "ERP_CAF_SOLICITUD_CREAR"("HV_ID_Catalogo_Sede", lv_tipo, NULL, "HV_Fecha_Hora_Prevista", "HV_Empresa_Visitante", NULL, NULL, "HV_Observaciones",
                                       NULL, "HV_IDs_Persona_Externa", "HV_Copias", "HV_ID_Solicitud_Origen", NULL, lv_p_pla, NULL,
                                       "HV_Contacto_Nombre", "HV_Contacto_Telefonos", NULL, "HV_ID_Empresa_Destino", lv_p_ruc, lv_p_dir, lv_p_mar, lv_p_lic,
                                       lv_p_id, "HV_UsuarioID", "HV_ID_Solicitud_Result", "HV_Codigo_Solicitud_Result", lv_c, lv_m);
        IF lv_c <> 100 THEN
            "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; "HV_ID_Solicitud_Result" := 0; "HV_Codigo_Solicitud_Result" := NULL; RETURN;
        END IF;

        -- Nombre del transportista principal (CREAR ya guardó RUC, dirección, placa, marca y licencia)
        UPDATE "CAF_Solicitud_Transportista" T SET "Nombre" = lv_p_nom
         WHERE T."ID_Solicitud" = "HV_ID_Solicitud_Result"
           AND T."ID_Solicitud_Persona" IN (SELECT P."ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" P
                                             WHERE P."ID_Solicitud" = "HV_ID_Solicitud_Result" AND P."ID_Persona_Externa" = lv_p_id);

        -- Los demás transportistas
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
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR_PROVEEDOR';
        "HV_ID_Solicitud_Result" := 0;
        "HV_Codigo_Solicitud_Result" := NULL;
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_SOLICITUD_TRANSPORTISTAS   (vacío si el usuario no puede ver la solicitud)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_TRANSPORTISTAS"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Solicitud_Persona" BIGINT, "ID_Persona_Externa" BIGINT, "Es_Principal" CHAR(1),
               "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR, "Nombre_Completo" VARCHAR,
               "Ruc" VARCHAR, "Nombre" VARCHAR, "Direccion" VARCHAR, "Placa" VARCHAR, "Marca" VARCHAR, "Licencia" VARCHAR,
               "Datos_Completos" CHAR(1))
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-06
    -- Quien puede ver la solicitud (dueño con licencia de solicitante, aprobadores, Vigilancia) o el dueño con la licencia de proveedores
    IF "ERP_CAF_FN_ADJUNTO_VISIBLE"("HV_UsuarioID", "HV_ID_Solicitud") <> 'Y' THEN
        IF NOT EXISTS (SELECT 1 FROM "CAF_Solicitud" S
                        WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N' AND S."ID_Usuario_Solicitante" = "HV_UsuarioID"
                          AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_SOLICITAR', S."ID_Catalogo_Sede") = 'Y') THEN
            RETURN;
        END IF;
    END IF;
    RETURN QUERY
    SELECT P."ID_Solicitud_Persona", P."ID_Persona_Externa", P."Es_Principal", TD."Codigo", PE."Numero_Documento",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           T."Ruc", T."Nombre", T."Direccion", T."Placa", T."Marca", T."Licencia",
           CAST(CASE WHEN T."Ruc" IS NOT NULL AND T."Nombre" IS NOT NULL AND T."Direccion" IS NOT NULL AND T."Placa" IS NOT NULL
                          AND T."Marca" IS NOT NULL AND T."Licencia" IS NOT NULL THEN 'Y' ELSE 'N' END AS CHAR(1))
      FROM "CAF_Solicitud_Transportista" T
      JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = T."ID_Solicitud_Persona"
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = PE."ID_Catalogo_Tipo_Documento"
     WHERE T."ID_Solicitud" = "HV_ID_Solicitud" AND T."Eliminado" = 'N' AND P."Eliminado" = 'N'
     ORDER BY CASE WHEN P."Es_Principal" = 'Y' THEN 0 ELSE 1 END, T."ID_Solicitud_Transportista";
END;
$$;

-- -----------------------------------------------------------------------------
-- ERP_CAF_SOLICITUD_TRANSPORTISTA_QUITAR  (interna; D-225)
--    La persona deja de ser transportista porque se retira de la solicitud. Si era el transportista principal y queda otro,
--    el principal pasa al siguiente (el de menor orden) y sus datos de transporte se copian a CAF_Solicitud.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_TRANSPORTISTA_QUITAR"(
    IN    "HV_ID_Solicitud_Persona" BIGINT,
    IN    "HV_UsuarioID"            BIGINT,
    INOUT "HV_Codigo_Resp"          INT DEFAULT NULL,
    INOUT "HV_Mensaje"              VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sol  BIGINT;
    lv_prin CHAR(1);
    lv_np   BIGINT;
BEGIN
    -- V1.0 2026-11-09
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_TRANSPORTISTA_QUITAR';
    BEGIN
        SELECT P."ID_Solicitud", P."Es_Principal" INTO lv_sol, lv_prin FROM "CAF_Solicitud_Persona" P
         WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
        UPDATE "CAF_Solicitud_Transportista" SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        IF lv_prin = 'Y' THEN
            SELECT MIN(T."ID_Solicitud_Persona") INTO lv_np
              FROM "CAF_Solicitud_Transportista" T
              JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = T."ID_Solicitud_Persona"
             WHERE T."Eliminado" = 'N' AND P."ID_Solicitud" = lv_sol AND P."Eliminado" = 'N' AND P."Aprobacion" <> 'RETIRADA'
               AND T."ID_Solicitud_Transportista" = (SELECT MIN(T2."ID_Solicitud_Transportista") FROM "CAF_Solicitud_Transportista" T2
                      JOIN "CAF_Solicitud_Persona" P2 ON P2."ID_Solicitud_Persona" = T2."ID_Solicitud_Persona"
                     WHERE T2."Eliminado" = 'N' AND P2."ID_Solicitud" = lv_sol AND P2."Eliminado" = 'N' AND P2."Aprobacion" <> 'RETIRADA');
            IF lv_np IS NOT NULL THEN
                UPDATE "CAF_Solicitud_Persona" SET "Es_Principal" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
                UPDATE "CAF_Solicitud_Persona" SET "Es_Principal" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Solicitud_Persona" = lv_np;
                UPDATE "CAF_Solicitud" S
                   SET "Placa_Vehiculo" = T."Placa", "Proveedor_RUC" = T."Ruc", "Proveedor_Direccion" = T."Direccion",
                       "Vehiculo_Marca" = T."Marca", "Licencia_Conducir" = T."Licencia",
                       "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                  FROM "CAF_Solicitud_Transportista" T
                 WHERE T."ID_Solicitud_Persona" = lv_np AND T."Eliminado" = 'N' AND S."ID_Solicitud" = lv_sol;
            END IF;
        END IF;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Transportista retirado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_TRANSPORTISTA_QUITAR';
    END;
END;
$$;
