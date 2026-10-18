-- =============================================================================
-- Archivo : SP_CAF_DESVIACION_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 3 - Portería y desviaciones | Fase 1 - Procedimientos (desviaciones, escritura)
-- Entidad : CAF_Desviacion
-- Versión : V1.0 2026-10-17
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO3_ESCRITURA.sql)
-- Requiere: scripts 01 a 10, los SP del Hito 0, 1 y 2 (SP_CAF_SOLICITUD_BASE_ALL en especial).
-- =============================================================================
-- 1 ERP_CAF_DESVIACION_VALIDAR     (interna) valida el tratamiento y devuelve el efecto (D-11)
-- 2 ERP_CAF_DESVIACION_CREAR       (interna) escribe la desviación y su evento
-- 3 ERP_CAF_DESVIACION_CONFORMIDAD_DAR   el Coordinador revisa y da su conformidad
--
-- Las dos primeras las llaman ERP_CAF_PORTERIA_INGRESO_REGISTRAR y _SALIDA_REGISTRAR;
-- la aplicación no las llama directo. Una desviación nace SOLO con un ingreso o una
-- salida (D-20): sus ítems incumplidos son las filas Cumple = 'N' de ese movimiento.
--
-- Qué es una desviación: algo del checklist no se cumplió (SCTR vencido, sin EPP...).
-- Vigilancia consulta a un Coordinador (que consta en la desviación), elige un
-- tratamiento del catálogo y ese tratamiento fija el efecto: INGRESA,
-- INGRESA_RESTRINGIDO, NO_INGRESA, SALE o SALE_RETIENE_ELEMENTO. Con «Otro»
-- Vigilancia elige el efecto y debe explicarlo (D-11).
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_DESVIACION_VALIDAR  (interna)
--    Comprueba los datos de la desviación y devuelve en HV_Resultado_Result el
--    efecto que tendrá el movimiento. No escribe nada.
--    HV_Etapa: INGRESO o SALIDA.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_DESVIACION_VALIDAR"(
    IN    "HV_Etapa"              VARCHAR(10),
    IN    "HV_Descripcion"        VARCHAR(2000),
    IN    "HV_ID_Coordinador"     BIGINT,
    IN    "HV_ID_Tratamiento"     BIGINT,
    IN    "HV_Tratamiento_Detalle" VARCHAR(500),
    IN    "HV_Resultado_Elegido"  VARCHAR(30),
    IN    "HV_ID_Catalogo_Sede"   BIGINT,
    INOUT "HV_Resultado_Result"   VARCHAR(30) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"        INT DEFAULT NULL,
    INOUT "HV_Mensaje"            VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n        INT := 0;
    lv_aplica   CHAR(1);
    lv_otro     CHAR(1);
    lv_res_cat  VARCHAR(30);
    lv_eleg     VARCHAR(30);
BEGIN
    -- V1.0 2026-10-17
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_DESVIACION_VALIDAR';
    "HV_Resultado_Result" := NULL;
    BEGIN
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Describa la desviación.'; RETURN;
        END IF;
        IF LENGTH(TRIM("HV_Descripcion")) > 2000 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción no puede superar 2000 caracteres.'; RETURN;
        END IF;
        IF "HV_ID_Coordinador" IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique al Coordinador consultado.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_ID_Coordinador", 'PER_CAF_DESVIACION_CONFORMIDAD', "HV_ID_Catalogo_Sede") <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La persona consultada no es Coordinador de esta sede.'; RETURN;
        END IF;
        IF "HV_ID_Tratamiento" IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Elija el tratamiento de la desviación.'; RETURN;
        END IF;

        SELECT COUNT(*),
               MAX(CASE "HV_Etapa" WHEN 'INGRESO' THEN "Aplica_Ingreso" ELSE "Aplica_Salida" END),
               MAX("Es_Otro"),
               MAX(CASE "HV_Etapa" WHEN 'INGRESO' THEN "Resultado_Ingreso" ELSE "Resultado_Salida" END)
          INTO lv_n, lv_aplica, lv_otro, lv_res_cat
          FROM "Catalogo_Tratamiento_Desviacion"
         WHERE "ID_Catalogo_Tratamiento_Desviacion" = "HV_ID_Tratamiento" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El tratamiento no existe o está inactivo.'; RETURN;
        END IF;
        IF lv_aplica <> 'Y' THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := CASE "HV_Etapa" WHEN 'INGRESO' THEN 'Ese tratamiento no se aplica a un ingreso.' ELSE 'Ese tratamiento no se aplica a una salida.' END;
            RETURN;
        END IF;

        lv_eleg := NULLIF(UPPER(TRIM(COALESCE("HV_Resultado_Elegido", ''))), '');
        IF lv_otro = 'Y' THEN
            IF "HV_Tratamiento_Detalle" IS NULL OR LENGTH(TRIM("HV_Tratamiento_Detalle")) = 0 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Explique en qué consiste el tratamiento «Otro».'; RETURN;
            END IF;
            IF lv_eleg IS NULL THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Elija el efecto del tratamiento «Otro».'; RETURN;
            END IF;
            IF "HV_Etapa" = 'INGRESO' AND lv_eleg NOT IN ('INGRESA','INGRESA_RESTRINGIDO','NO_INGRESA') THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El efecto de un ingreso debe ser INGRESA, INGRESA_RESTRINGIDO o NO_INGRESA.'; RETURN;
            END IF;
            IF "HV_Etapa" = 'SALIDA' AND lv_eleg NOT IN ('SALE','SALE_RETIENE_ELEMENTO') THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El efecto de una salida debe ser SALE o SALE_RETIENE_ELEMENTO.'; RETURN;
            END IF;
            "HV_Resultado_Result" := lv_eleg;
        ELSE
            IF lv_res_cat IS NULL THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'El tratamiento no define un efecto para esta etapa.'; RETURN;
            END IF;
            IF lv_eleg IS NOT NULL AND lv_eleg <> lv_res_cat THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El efecto no corresponde al tratamiento elegido.'; RETURN;
            END IF;
            "HV_Resultado_Result" := lv_res_cat;
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Desviación válida.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_DESVIACION_VALIDAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_DESVIACION_CREAR  (interna)
--    Escribe la desviación de un movimiento ya registrado (Codigo DES-00001, D-15)
--    y su evento. Los datos ya fueron validados con ERP_CAF_DESVIACION_VALIDAR.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_DESVIACION_CREAR"(
    IN    "HV_ID_Registro_Acceso"  BIGINT,
    IN    "HV_ID_Solicitud"        BIGINT,
    IN    "HV_Descripcion"         VARCHAR(2000),
    IN    "HV_ID_Coordinador"      BIGINT,
    IN    "HV_ID_Tratamiento"      BIGINT,
    IN    "HV_Tratamiento_Detalle" VARCHAR(500),
    IN    "HV_Resultado"           VARCHAR(30),
    IN    "HV_UsuarioID"           BIGINT,
    INOUT "HV_ID_Desviacion_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"         INT DEFAULT NULL,
    INOUT "HV_Mensaje"             VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_id BIGINT;
    lv_c  INT;
    lv_m  VARCHAR(250);
BEGIN
    -- V1.0 2026-10-17
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_DESVIACION_CREAR';
    "HV_ID_Desviacion_Result" := 0;
    BEGIN
        INSERT INTO "CAF_Desviacion" ("ID_Registro_Acceso","Descripcion","ID_Usuario_Coordinador_Consultado",
                                      "ID_Catalogo_Tratamiento_Desviacion","Tratamiento_Detalle","Resultado","Estado","UsuarioID_Create")
        VALUES ("HV_ID_Registro_Acceso", TRIM("HV_Descripcion"), "HV_ID_Coordinador", "HV_ID_Tratamiento",
                NULLIF(TRIM(COALESCE("HV_Tratamiento_Detalle", '')), ''), "HV_Resultado", 'POR_REVISAR', "HV_UsuarioID")
        RETURNING "ID_Desviacion" INTO lv_id;

        UPDATE "CAF_Desviacion" SET "Codigo" = 'DES-' || LPAD(CAST(lv_id AS VARCHAR), 5, '0') WHERE "ID_Desviacion" = lv_id;

        CALL "ERP_CAF_EVENTO_REGISTRAR"('DESVIACION', lv_id, "HV_ID_Solicitud", 'REGISTRAR',
             'DES-' || LPAD(CAST(lv_id AS VARCHAR), 5, '0') || ' · ' || "HV_Resultado" || ' · ' || LEFT(TRIM("HV_Descripcion"), 200),
             "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_ID_Desviacion_Result" := lv_id;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Desviación registrada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_DESVIACION_CREAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_DESVIACION_CONFORMIDAD_DAR
--    El Coordinador revisa la desviación y deja su conformidad (estado REVISADA).
--    Requiere PER_CAF_DESVIACION_CONFORMIDAD en la sede del movimiento.
--    El comentario es opcional.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(
    IN    "HV_ID_Desviacion"  BIGINT,
    IN    "HV_Comentario"     VARCHAR(1000),
    IN    "HV_UsuarioID"      BIGINT,
    INOUT "HV_Codigo_Resp"    INT DEFAULT NULL,
    INOUT "HV_Mensaje"        VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_estado VARCHAR(20);
    lv_sede   BIGINT;
    lv_sol    BIGINT;
    lv_cod    VARCHAR(20);
    lv_c      INT;
    lv_m      VARCHAR(250);
BEGIN
    -- V1.0 2026-10-17
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_DESVIACION_CONFORMIDAD_DAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "HV_Comentario" IS NOT NULL AND LENGTH(TRIM("HV_Comentario")) > 1000 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El comentario no puede superar 1000 caracteres.'; RETURN;
        END IF;
        -- Serializa: si dos Coordinadores dan conformidad a la vez, el segundo ve «ya revisada»
        UPDATE "CAF_Desviacion" SET "UpdateDate" = "UpdateDate" WHERE "ID_Desviacion" = "HV_ID_Desviacion";
        SELECT COUNT(*), MAX(D."Estado"), MAX(R."ID_Catalogo_Sede"), MAX(P."ID_Solicitud"), MAX(D."Codigo")
          INTO lv_n, lv_estado, lv_sede, lv_sol, lv_cod
          FROM "CAF_Desviacion" D
          JOIN "CAF_Registro_Acceso" R ON R."ID_Registro_Acceso" = D."ID_Registro_Acceso"
          JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = R."ID_Solicitud_Persona"
         WHERE D."ID_Desviacion" = "HV_ID_Desviacion" AND D."Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La desviación no existe.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_DESVIACION_CONFORMIDAD', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para dar conformidad a desviaciones de esta sede.'; RETURN;
        END IF;
        IF lv_estado <> 'POR_REVISAR' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La desviación ya fue revisada.'; RETURN;
        END IF;

        UPDATE "CAF_Desviacion"
           SET "Estado" = 'REVISADA', "ID_Usuario_Conformidad" = "HV_UsuarioID", "Fecha_Conformidad" = CURRENT_TIMESTAMP,
               "Comentario_Conformidad" = NULLIF(TRIM(COALESCE("HV_Comentario", '')), ''),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Desviacion" = "HV_ID_Desviacion";

        CALL "ERP_CAF_EVENTO_REGISTRAR"('DESVIACION', "HV_ID_Desviacion", lv_sol, 'CONFORMIDAD',
             lv_cod || COALESCE(' · ' || NULLIF(TRIM(COALESCE("HV_Comentario", '')), ''), ''), "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Conformidad registrada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_DESVIACION_CONFORMIDAD_DAR';
    END;
END;
$$;
