-- =============================================================================
-- Archivo : SP_CAF_PROVEEDOR_GRUPO_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobación | Fase 1 - Procedimientos (D-225: varios transportistas y ayudantes por entrega)
-- Versión : V1.0 2026-11-09
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO2_ESCRITURA.sql, sección «D-225»)
-- Requiere: scripts 01 a 24 y SP_CAF_PROVEEDOR_ALL.sql / SP_CAF_PORTERIA_ALL.sql (se invocan en tiempo de ejecución).
-- =============================================================================
-- Acciones de Vigilancia sobre una SELECCIÓN de personas de una entrega de proveedor (transportistas y ayudantes de descarga).
-- La lista de personas es un texto «id,id,id» (ID_Solicitud_Persona). Cada acción es TODO O NADA.
--  1 ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO   un solo checklist de ingreso para varias personas (cada una queda con su registro)
--  2 ERP_CAF_PROVEEDOR_INGRESO_FISICO    «Registrar ingreso»: las personas verificadas entran (capacidad de la exclusa)
--  3 ERP_CAF_PROVEEDOR_SALIDA_GRUPO      un solo checklist de salida para varias personas
--  4 ERP_CAF_PROVEEDOR_RETIRO_PERSONAS   «Retiró sin ingresar» para varias personas
-- Si un ítem no cumple, nace UNA desviación por persona con la misma decisión del Coordinador consultado en el acto.
-- HANA: STRING_TO_ARRAY / ANY / CARDINALITY y el FOR sobre un SELECT se reescriben (SERIES_GENERATE + SUBSTR_REGEXPR, sin cursores).
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_PROVEEDOR_INGRESO_FISICO
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_INGRESO_FISICO"(
    IN    "HV_ID_Solicitud"  BIGINT,
    IN    "HV_IDs_Persona"   VARCHAR(2000),
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
    lv_arr   BIGINT[];
    lv_cap   INT := 1;
    lv_val   VARCHAR(200);
    lv_dentro INT := 0;
    lv_nuevos INT := 0;
    lv_mal   VARCHAR(2000);
    lv_c     INT;
    lv_m     VARCHAR(250);
BEGIN
    -- V1.0 2026-11-09
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_INGRESO_FISICO';
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
        IF lv_eop NOT IN ('EN_ESPERA','INGRESO','EN_ATENCION') THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE lv_eop WHEN 'PROGRAMADO' THEN 'Primero debe verificar los datos de los transportistas.'
                                        WHEN 'INGRESO_DENEGADO' THEN 'El ingreso de este proveedor fue denegado.'
                                        WHEN 'RETIRO_SIN_INGRESO' THEN 'El proveedor se retiró sin ingresar.'
                                        WHEN 'NO_SE_PRESENTO' THEN 'La entrega figura como «no se presentó».'
                                        ELSE 'La recepción de la entrega ya culminó: no se registran más ingresos.' END; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Exclusa"
         WHERE "ID_Catalogo_Sede" = lv_sede AND "ID_Solicitud_Actual" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Almacén aún no confirmó su disponibilidad para recibir a este proveedor.'; RETURN;
        END IF;
        IF COALESCE(TRIM("HV_IDs_Persona"), '') = '' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Seleccione al menos una persona.'; RETURN;
        END IF;
        IF REPLACE("HV_IDs_Persona", ' ', '') !~ '^[0-9]+(,[0-9]+)*$' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de personas no es válida.'; RETURN;
        END IF;
        lv_arr := CAST(STRING_TO_ARRAY(REPLACE("HV_IDs_Persona", ' ', ''), ',') AS BIGINT[]);
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud_Persona" = ANY(lv_arr) AND "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n <> CARDINALITY(ARRAY(SELECT DISTINCT X FROM UNNEST(lv_arr) AS X)) THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'Alguna de las personas no pertenece a esta entrega.'; RETURN;
        END IF;
        SELECT STRING_AGG(PE."Apellido_Paterno" || ' ' || PE."Nombres", '; ') INTO lv_mal
          FROM "CAF_Solicitud_Persona" P JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
         WHERE P."ID_Solicitud_Persona" = ANY(lv_arr)
           AND (P."Aprobacion" <> 'APROBADA' OR P."Estado" <> 'ESPERADA' OR P."Fecha_Verificacion" IS NULL);
        IF lv_mal IS NOT NULL THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'No pueden ingresar (deben estar verificados y por ingresar): ' || LEFT(lv_mal, 150); RETURN;
        END IF;
        -- Capacidad de la exclusa: vehículos (transportistas) dentro a la vez. Los ayudantes no cuentan.
        lv_val := "ERP_CAF_PARAMETRO_VALOR"('EXCLUSA_CAPACIDAD');
        IF lv_val IS NOT NULL AND lv_val ~ '^[1-9][0-9]*$' THEN lv_cap := CAST(lv_val AS INT); END IF;
        SELECT COUNT(*) INTO lv_dentro FROM "CAF_Solicitud_Persona" P
         WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Estado" = 'DENTRO'
           AND "ERP_CAF_FN_ES_TRANSPORTISTA"(P."ID_Solicitud_Persona") = 'Y';
        SELECT COUNT(*) INTO lv_nuevos FROM "CAF_Solicitud_Persona" P
         WHERE P."ID_Solicitud_Persona" = ANY(lv_arr) AND "ERP_CAF_FN_ES_TRANSPORTISTA"(P."ID_Solicitud_Persona") = 'Y';
        IF lv_dentro + lv_nuevos > lv_cap THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'La exclusa admite ' || lv_cap || ' vehículo(s) a la vez y ya hay ' || lv_dentro || ' dentro: registre primero su salida.'; RETURN;
        END IF;
        IF lv_dentro + lv_nuevos = 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Los ayudantes ingresan con su transportista: registre primero el ingreso de un transportista.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud_Persona"
           SET "Estado" = 'DENTRO', "Fecha_Hora_Ingreso" = CURRENT_TIMESTAMP, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = ANY(lv_arr);
        IF lv_eop = 'EN_ESPERA' THEN
            CALL "ERP_CAF_PROVEEDOR_MOVER"("HV_ID_Solicitud", 'INGRESO', "HV_UsuarioID", NULL, 'Ingreso físico registrado', NULL, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'mover: %', lv_m; END IF;
        END IF;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ingreso registrado (' || CARDINALITY(lv_arr) || ' persona(s)).';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_INGRESO_FISICO';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_PROVEEDOR_RETIRO_PERSONAS
--    HV_Exigir_En_Espera = 'Y' (atajo de toda la entrega): solo con la entrega EN_ESPERA, como antes.
--    'N' (pantalla): mientras la entrega no haya sido recepcionada. Quien se retira queda NO_SE_PRESENTO.
--    Si ya no queda ningún transportista por ingresar, la entrega termina sin ingreso y se libera la exclusa.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_RETIRO_PERSONAS"(
    IN    "HV_ID_Solicitud"      BIGINT,
    IN    "HV_IDs_Persona"       VARCHAR(2000),
    IN    "HV_Motivo"            VARCHAR(500),
    IN    "HV_Exigir_En_Espera"  CHAR(1),
    IN    "HV_UsuarioID"         BIGINT,
    INOUT "HV_Codigo_Resp"       INT DEFAULT NULL,
    INOUT "HV_Mensaje"           VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n     INT := 0;
    lv_sede  BIGINT;
    lv_act   CHAR(1);
    lv_eop   VARCHAR(20);
    lv_mot   VARCHAR(500);
    lv_arr   BIGINT[];
    lv_mal   VARCHAR(2000);
    lv_c     INT;
    lv_m     VARCHAR(250);
BEGIN
    -- V1.0 2026-11-09
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_RETIRO_PERSONAS';
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
        IF COALESCE("HV_Exigir_En_Espera", 'N') = 'Y' AND lv_eop <> 'EN_ESPERA' THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := CASE lv_eop WHEN 'PROGRAMADO' THEN 'Solo se registra el retiro de un proveedor ya verificado.'
                                        WHEN 'RETIRO_SIN_INGRESO' THEN 'El proveedor ya figura como retirado sin ingresar.'
                                        WHEN 'INGRESO_DENEGADO' THEN 'El ingreso de este proveedor fue denegado.'
                                        WHEN 'NO_SE_PRESENTO' THEN 'La entrega figura como «no se presentó».'
                                        ELSE 'El proveedor ya ingresó: no se registra como retirado sin ingresar.' END; RETURN;
        END IF;
        IF lv_eop NOT IN ('PROGRAMADO','EN_ESPERA','INGRESO','EN_ATENCION') THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La entrega ya terminó o fue cerrada: no se registran retiros.'; RETURN;
        END IF;
        IF COALESCE(TRIM("HV_IDs_Persona"), '') = '' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Seleccione al menos una persona.'; RETURN;
        END IF;
        IF REPLACE("HV_IDs_Persona", ' ', '') !~ '^[0-9]+(,[0-9]+)*$' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de personas no es válida.'; RETURN;
        END IF;
        lv_arr := CAST(STRING_TO_ARRAY(REPLACE("HV_IDs_Persona", ' ', ''), ',') AS BIGINT[]);
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud_Persona" = ANY(lv_arr) AND "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n <> CARDINALITY(ARRAY(SELECT DISTINCT X FROM UNNEST(lv_arr) AS X)) THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'Alguna de las personas no pertenece a esta entrega.'; RETURN;
        END IF;
        SELECT STRING_AGG(PE."Apellido_Paterno" || ' ' || PE."Nombres", '; ') INTO lv_mal
          FROM "CAF_Solicitud_Persona" P JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
         WHERE P."ID_Solicitud_Persona" = ANY(lv_arr) AND (P."Estado" <> 'ESPERADA' OR P."Aprobacion" <> 'APROBADA');
        IF lv_mal IS NOT NULL THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'Solo se retira a quien aún no ingresó: ' || LEFT(lv_mal, 150); RETURN;
        END IF;
        UPDATE "CAF_Solicitud_Persona"
           SET "Estado" = 'NO_SE_PRESENTO', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = ANY(lv_arr);
        INSERT INTO "CAF_Solicitud_Operacion_Evento" ("ID_Solicitud","Estado_Anterior","Estado_Nuevo","ID_Usuario","Observacion")
        VALUES ("HV_ID_Solicitud", lv_eop, lv_eop, "HV_UsuarioID", 'Retiró sin ingresar (' || CARDINALITY(lv_arr) || ' persona(s)): ' || lv_mot);
        CALL "ERP_CAF_PROVEEDOR_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", 'Retiro sin ingresar: ' || lv_mot, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Retiro registrado (' || CARDINALITY(lv_arr) || ' persona(s)).';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_RETIRO_PERSONAS';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 1 y 3. ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO / ERP_CAF_PROVEEDOR_SALIDA_GRUPO
--    HV_Items: «id:Y,id:N,...» con TODOS los ítems del checklist mostrado (la unión de los de la selección). A cada persona se le
--    aplican solo los que le corresponden (p. ej. la placa solo a los transportistas). Cada persona queda con su propio registro de
--    portería (misma hora, mismo vigilante) y, si algún ítem no cumple, con su propia desviación (misma decisión).
--    Las reglas de cada persona (ingreso, salida, ítem crítico, permisos) las aplica ERP_CAF_PORTERIA_*_REGISTRAR; si una falla, nada se guarda.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(
    IN    "HV_ID_Solicitud"        BIGINT,
    IN    "HV_IDs_Persona"         VARCHAR(2000),
    IN    "HV_Items"               VARCHAR(2000),
    IN    "HV_Observacion"         VARCHAR(1000),
    IN    "HV_Desv_Descripcion"    VARCHAR(2000),
    IN    "HV_ID_Coordinador"      BIGINT,
    IN    "HV_ID_Tratamiento"      BIGINT,
    IN    "HV_Tratamiento_Detalle" VARCHAR(500),
    IN    "HV_Resultado_Elegido"   VARCHAR(30),
    IN    "HV_UsuarioID"           BIGINT,
    INOUT "HV_Codigo_Resp"         INT DEFAULT NULL,
    INOUT "HV_Mensaje"             VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_arr    BIGINT[];
    lv_id     BIGINT;
    lv_n      INT := 0;
    lv_lista  VARCHAR(2100);
    lv_items  VARCHAR(2000);
    lv_falta  INT;
    lv_reg    BIGINT;
    lv_des    BIGINT;
    lv_res    VARCHAR(30);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_nom    VARCHAR(200);
    lv_den    INT := 0;
    lv_cod_f  INT := NULL;
    lv_msg_f  VARCHAR(250) := NULL;
BEGIN
    -- V1.0 2026-11-09
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO';
    BEGIN
        IF COALESCE(TRIM("HV_IDs_Persona"), '') = '' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Seleccione al menos una persona.'; RETURN;
        END IF;
        IF REPLACE("HV_IDs_Persona", ' ', '') !~ '^[0-9]+(,[0-9]+)*$' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de personas no es válida.'; RETURN;
        END IF;
        lv_arr := CAST(STRING_TO_ARRAY(REPLACE("HV_IDs_Persona", ' ', ''), ',') AS BIGINT[]);
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud_Persona" = ANY(lv_arr) AND "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n <> CARDINALITY(ARRAY(SELECT DISTINCT X FROM UNNEST(lv_arr) AS X)) THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'Alguna de las personas no pertenece a esta entrega.'; RETURN;
        END IF;
        lv_lista := ',' || REPLACE(UPPER(COALESCE("HV_Items", '')), ' ', '') || ',';
        FOR lv_id IN SELECT DISTINCT X FROM UNNEST(lv_arr) AS X ORDER BY X LOOP
            SELECT PE."Apellido_Paterno" || ' ' || PE."Nombres" INTO lv_nom
              FROM "CAF_Solicitud_Persona" P JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
             WHERE P."ID_Solicitud_Persona" = lv_id;
            SELECT STRING_AGG(CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':' ||
                              CASE WHEN lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':Y,%' THEN 'Y' ELSE 'N' END, ','),
                   SUM(CASE WHEN lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':Y,%'
                              OR lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':N,%' THEN 0 ELSE 1 END)
              INTO lv_items, lv_falta
              FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(lv_id, 'INGRESO', 'N', 'N') A;
            IF lv_items IS NULL OR COALESCE(lv_falta, 0) > 0 THEN
                lv_cod_f := 400; lv_msg_f := 'Responda todos los ítems del checklist.'; RAISE EXCEPTION 'grupo';
            END IF;
            lv_reg := 0; lv_des := 0; lv_res := NULL;
            CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(lv_id, lv_items, 'N', 'N', "HV_Observacion", "HV_Desv_Descripcion", "HV_ID_Coordinador",
                 "HV_ID_Tratamiento", "HV_Tratamiento_Detalle", "HV_Resultado_Elegido", NULL, "HV_UsuarioID", lv_reg, lv_des, lv_res, lv_c, lv_m);
            IF lv_c <> 100 THEN
                lv_cod_f := lv_c; lv_msg_f := LEFT(lv_nom || ': ' || lv_m, 250); RAISE EXCEPTION 'grupo';
            END IF;
            IF lv_res = 'NO_INGRESA' THEN lv_den := lv_den + 1; END IF;
        END LOOP;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Verificación registrada (' || CARDINALITY(ARRAY(SELECT DISTINCT X FROM UNNEST(lv_arr) AS X)) || ' persona(s)' ||
                            CASE WHEN lv_den > 0 THEN ', ' || lv_den || ' con ingreso denegado' ELSE '' END || ').';
    EXCEPTION WHEN OTHERS THEN
        IF lv_cod_f IS NOT NULL THEN
            "HV_Codigo_Resp" := lv_cod_f; "HV_Mensaje" := lv_msg_f;
        ELSE
            "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO';
        END IF;
    END;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_PROVEEDOR_SALIDA_GRUPO"(
    IN    "HV_ID_Solicitud"        BIGINT,
    IN    "HV_IDs_Persona"         VARCHAR(2000),
    IN    "HV_Items"               VARCHAR(2000),
    IN    "HV_Observacion"         VARCHAR(1000),
    IN    "HV_Desv_Descripcion"    VARCHAR(2000),
    IN    "HV_ID_Coordinador"      BIGINT,
    IN    "HV_ID_Tratamiento"      BIGINT,
    IN    "HV_Tratamiento_Detalle" VARCHAR(500),
    IN    "HV_Resultado_Elegido"   VARCHAR(30),
    IN    "HV_UsuarioID"           BIGINT,
    INOUT "HV_Codigo_Resp"         INT DEFAULT NULL,
    INOUT "HV_Mensaje"             VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_arr    BIGINT[];
    lv_id     BIGINT;
    lv_n      INT := 0;
    lv_lista  VARCHAR(2100);
    lv_items  VARCHAR(2000);
    lv_falta  INT;
    lv_reg    BIGINT;
    lv_des    BIGINT;
    lv_res    VARCHAR(30);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_nom    VARCHAR(200);
    lv_te     CHAR(1);
    lv_th     CHAR(1);
    lv_cod_f  INT := NULL;
    lv_msg_f  VARCHAR(250) := NULL;
BEGIN
    -- V1.0 2026-11-09
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PROVEEDOR_SALIDA_GRUPO';
    BEGIN
        IF COALESCE(TRIM("HV_IDs_Persona"), '') = '' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Seleccione al menos una persona.'; RETURN;
        END IF;
        IF REPLACE("HV_IDs_Persona", ' ', '') !~ '^[0-9]+(,[0-9]+)*$' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de personas no es válida.'; RETURN;
        END IF;
        lv_arr := CAST(STRING_TO_ARRAY(REPLACE("HV_IDs_Persona", ' ', ''), ',') AS BIGINT[]);
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud_Persona" = ANY(lv_arr) AND "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n <> CARDINALITY(ARRAY(SELECT DISTINCT X FROM UNNEST(lv_arr) AS X)) THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'Alguna de las personas no pertenece a esta entrega.'; RETURN;
        END IF;
        lv_lista := ',' || REPLACE(UPPER(COALESCE("HV_Items", '')), ' ', '') || ',';
        FOR lv_id IN SELECT DISTINCT X FROM UNNEST(lv_arr) AS X ORDER BY X LOOP
            SELECT PE."Apellido_Paterno" || ' ' || PE."Nombres", P."Trae_Equipos", P."Trae_Herramientas" INTO lv_nom, lv_te, lv_th
              FROM "CAF_Solicitud_Persona" P JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
             WHERE P."ID_Solicitud_Persona" = lv_id;
            SELECT STRING_AGG(CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':' ||
                              CASE WHEN lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':Y,%' THEN 'Y' ELSE 'N' END, ','),
                   SUM(CASE WHEN lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':Y,%'
                              OR lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':N,%' THEN 0 ELSE 1 END)
              INTO lv_items, lv_falta
              FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(lv_id, 'SALIDA', lv_te, lv_th) A;
            lv_items := COALESCE(lv_items, '');   -- la salida del proveedor puede no tener ítems configurados
            IF COALESCE(lv_falta, 0) > 0 THEN
                lv_cod_f := 400; lv_msg_f := 'Responda todos los ítems del checklist.'; RAISE EXCEPTION 'grupo';
            END IF;
            lv_reg := 0; lv_des := 0; lv_res := NULL;
            CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(lv_id, lv_items, "HV_Observacion", "HV_Desv_Descripcion", "HV_ID_Coordinador",
                 "HV_ID_Tratamiento", "HV_Tratamiento_Detalle", "HV_Resultado_Elegido", NULL, "HV_UsuarioID", lv_reg, lv_des, lv_res, lv_c, lv_m);
            IF lv_c <> 100 THEN
                lv_cod_f := lv_c; lv_msg_f := LEFT(lv_nom || ': ' || lv_m, 250); RAISE EXCEPTION 'grupo';
            END IF;
        END LOOP;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Salida registrada (' || CARDINALITY(ARRAY(SELECT DISTINCT X FROM UNNEST(lv_arr) AS X)) || ' persona(s)).';
    EXCEPTION WHEN OTHERS THEN
        IF lv_cod_f IS NOT NULL THEN
            "HV_Codigo_Resp" := lv_cod_f; "HV_Mensaje" := lv_msg_f;
        ELSE
            "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_PROVEEDOR_SALIDA_GRUPO';
        END IF;
    END;
END;
$$;
