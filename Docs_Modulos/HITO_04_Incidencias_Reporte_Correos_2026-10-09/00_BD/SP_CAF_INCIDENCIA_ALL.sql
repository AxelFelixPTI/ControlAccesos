-- =============================================================================
-- Archivo : SP_CAF_INCIDENCIA_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 4 - Incidencias, reporte y correos | Fase 1 - Procedimientos (incidencias)
-- Entidad : CAF_Incidencia, CAF_Incidencia_Persona
-- Versión : V1.0 2026-10-18
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO4_*.sql)
-- Requiere: scripts 01 a 10 y los SP de los Hitos 0 a 3.
-- =============================================================================
-- Escritura                                  Lectura
--  1 ERP_CAF_INCIDENCIA_REGISTRAR             3 ERP_CAF_INCIDENCIA_LISTAR
--  2 ERP_CAF_INCIDENCIA_DECIDIR               4 ERP_CAF_INCIDENCIA_DETALLE
--                                             5 ERP_CAF_INCIDENCIA_PERSONAS_LISTAR
--                                             6 ERP_CAF_INCIDENCIA_CONTADORES
--                                             7 ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR
--
-- Qué es una incidencia: un hecho ocurrido en la sede (hurto, uso no autorizado de un
-- área, daño...) que Vigilancia o un Coordinador deja registrado. Nace REGISTRADA y un
-- Coordinador la CONFIRMA o la DESESTIMA con su sustento. Puede involucrar a cero, una
-- o varias personas (en esa visita, D-22).
-- Origen: lo fija el SP según el permiso de quien registra (con PER_CAF_INCIDENCIA_DECIDIR
-- es COORDINADOR; si no, VIGILANCIA). La pantalla no lo envía.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_INCIDENCIA_REGISTRAR
--    HV_IDs_Solicitud_Persona: «12,15» o vacío. Zona o lugar: al menos uno.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_INCIDENCIA_REGISTRAR"(
    IN    "HV_ID_Catalogo_Sede"         BIGINT,
    IN    "HV_ID_Catalogo_Tipo_Incidencia" BIGINT,
    IN    "HV_Tipo_Detalle"             VARCHAR(500),
    IN    "HV_Fecha_Hora_Hecho"         TIMESTAMP,
    IN    "HV_ID_Catalogo_Zona_Acceso"  BIGINT,
    IN    "HV_Lugar_Detalle"            VARCHAR(200),
    IN    "HV_Descripcion"              VARCHAR(2000),
    IN    "HV_IDs_Solicitud_Persona"    VARCHAR(500),
    IN    "HV_UsuarioID"                BIGINT,
    INOUT "HV_ID_Incidencia_Result"     BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Result"            VARCHAR(20) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"              INT DEFAULT NULL,
    INOUT "HV_Mensaje"                  VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_lista  VARCHAR(600) := ',' || REPLACE(COALESCE("HV_IDs_Solicitud_Persona", ''), ' ', '') || ',';
    lv_hay    CHAR(1) := 'N';
    lv_tokens INT := 0;
    lv_dbl    VARCHAR(1200);
    lv_dup    INT := 0;
    lv_id     BIGINT := 0;
    lv_total  INT := 0;
    lv_validas INT := 0;
    lv_sol    BIGINT;
    lv_nsol   INT := 0;
    lv_n      INT := 0;
    lv_otro   CHAR(1);
    lv_detalle VARCHAR(4000) := NULLIF(TRIM(COALESCE("HV_Tipo_Detalle", '')), '');
    lv_lugar  VARCHAR(4000) := NULLIF(TRIM(COALESCE("HV_Lugar_Detalle", '')), '');
    lv_origen VARCHAR(20);
    lv_inc    BIGINT;
    lv_cod    VARCHAR(20);
    lv_c      INT;
    lv_m      VARCHAR(250);
BEGIN
    -- V1.0 2026-10-18
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_INCIDENCIA_REGISTRAR';
    "HV_ID_Incidencia_Result" := 0;
    "HV_Codigo_Result" := NULL;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "HV_ID_Catalogo_Sede" IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique la sede.'; RETURN;
        END IF;
        IF "HV_ID_Catalogo_Tipo_Incidencia" IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Elija el tipo de incidencia.'; RETURN;
        END IF;
        IF "HV_Fecha_Hora_Hecho" IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique cuándo ocurrió el hecho.'; RETURN;
        END IF;
        IF "HV_Fecha_Hora_Hecho" > LOCALTIMESTAMP + INTERVAL '5 minutes' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La fecha y hora del hecho no puede ser futura.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Describa lo ocurrido.'; RETURN;
        END IF;
        IF LENGTH(TRIM("HV_Descripcion")) > 2000 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción no puede superar 2000 caracteres.'; RETURN;
        END IF;
        IF lv_detalle IS NOT NULL AND LENGTH(lv_detalle) > 500 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El detalle del tipo no puede superar 500 caracteres.'; RETURN;
        END IF;
        IF lv_lugar IS NOT NULL AND LENGTH(lv_lugar) > 200 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El lugar no puede superar 200 caracteres.'; RETURN;
        END IF;
        IF "HV_ID_Catalogo_Zona_Acceso" IS NULL AND lv_lugar IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique la zona o describa el lugar.'; RETURN;
        END IF;

        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_REGISTRAR', "HV_ID_Catalogo_Sede") <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para registrar incidencias en esta sede.'; RETURN;
        END IF;

        -- Tipo
        SELECT COUNT(*), MAX("Es_Otro") INTO lv_n, lv_otro
          FROM "Catalogo_Tipo_Incidencia"
         WHERE "ID_Catalogo_Tipo_Incidencia" = "HV_ID_Catalogo_Tipo_Incidencia" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El tipo de incidencia no existe o está inactivo.'; RETURN;
        END IF;
        IF lv_otro = 'Y' AND lv_detalle IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Explique de qué tipo de incidencia se trata («Otro»).'; RETURN;
        END IF;
        IF lv_otro <> 'Y' THEN lv_detalle := NULL; END IF;

        -- Zona (de la misma sede)
        IF "HV_ID_Catalogo_Zona_Acceso" IS NOT NULL THEN
            SELECT COUNT(*) INTO lv_n FROM "Catalogo_Zona_Acceso"
             WHERE "ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso" AND "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
               AND "Eliminado" = 'N' AND "Activo" = 'Y';
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La zona no existe en esta sede o está inactiva.'; RETURN;
            END IF;
        END IF;

        -- Personas (opcionales)
        IF lv_lista <> ',,' THEN
            lv_hay := 'Y';
            IF lv_lista !~ '^,([0-9]+,)+$' THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique las personas como lista de números separados por coma.'; RETURN;
            END IF;
            lv_tokens := LENGTH(lv_lista) - LENGTH(REPLACE(lv_lista, ',', '')) - 1;
            lv_dbl := REPLACE(lv_lista, ',', ',,');
            LOOP
                SELECT MIN(P."ID_Solicitud_Persona") INTO lv_id
                  FROM "CAF_Solicitud_Persona" P
                 WHERE P."ID_Solicitud_Persona" > lv_id AND lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';
                EXIT WHEN lv_id IS NULL;
                lv_total := lv_total + 1;
                IF LENGTH(lv_dbl) - LENGTH(REPLACE(lv_dbl, ',' || CAST(lv_id AS VARCHAR) || ',', '')) > LENGTH(',' || CAST(lv_id AS VARCHAR) || ',') THEN
                    lv_dup := 1;
                END IF;
            END LOOP;
            IF lv_dup = 1 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Una persona está repetida en la lista.'; RETURN;
            END IF;
            IF lv_total <> lv_tokens THEN
                "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'Alguna persona indicada no existe.'; RETURN;
            END IF;
            SELECT COUNT(*), COUNT(DISTINCT S."ID_Solicitud"), MAX(S."ID_Solicitud")
              INTO lv_validas, lv_nsol, lv_sol
              FROM "CAF_Solicitud_Persona" P
              JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud" AND S."Eliminado" = 'N'
                                    AND S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
             WHERE P."Eliminado" = 'N' AND lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';
            IF lv_validas <> lv_total THEN
                "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Todas las personas deben ser de visitas de esta sede.'; RETURN;
            END IF;
            IF lv_nsol <> 1 THEN lv_sol := NULL; END IF;
        END IF;

        lv_origen := CASE WHEN "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_DECIDIR', "HV_ID_Catalogo_Sede") = 'Y'
                          THEN 'COORDINADOR' ELSE 'VIGILANCIA' END;

        INSERT INTO "CAF_Incidencia" ("ID_Catalogo_Sede","ID_Catalogo_Tipo_Incidencia","Tipo_Detalle","Fecha_Hora_Hecho",
                                      "ID_Catalogo_Zona_Acceso","Lugar_Detalle","Descripcion","Origen","ID_Usuario_Registro",
                                      "Estado","UsuarioID_Create")
        VALUES ("HV_ID_Catalogo_Sede","HV_ID_Catalogo_Tipo_Incidencia", lv_detalle, "HV_Fecha_Hora_Hecho",
                "HV_ID_Catalogo_Zona_Acceso", lv_lugar, TRIM("HV_Descripcion"), lv_origen, "HV_UsuarioID",
                'REGISTRADA', "HV_UsuarioID")
        RETURNING "ID_Incidencia" INTO lv_inc;

        lv_cod := 'INC-' || LPAD(CAST(lv_inc AS VARCHAR), 5, '0');
        UPDATE "CAF_Incidencia" SET "Codigo" = lv_cod WHERE "ID_Incidencia" = lv_inc;

        IF lv_hay = 'Y' THEN
            INSERT INTO "CAF_Incidencia_Persona" ("ID_Incidencia","ID_Solicitud_Persona","UsuarioID_Create")
            SELECT lv_inc, P."ID_Solicitud_Persona", "HV_UsuarioID"
              FROM "CAF_Solicitud_Persona" P
             WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';
        END IF;

        CALL "ERP_CAF_EVENTO_REGISTRAR"('INCIDENCIA', lv_inc, lv_sol, 'REGISTRAR',
             lv_cod || ' · ' || lv_origen || ' · ' || LEFT(TRIM("HV_Descripcion"), 200), "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_ID_Incidencia_Result" := lv_inc;
        "HV_Codigo_Result" := lv_cod;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Incidencia ' || lv_cod || ' registrada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_ID_Incidencia_Result" := 0;
        "HV_Codigo_Result" := NULL;
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_INCIDENCIA_REGISTRAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_INCIDENCIA_DECIDIR
--    HV_Decision: CONFIRMAR o DESESTIMAR. El sustento es obligatorio en ambos casos.
--    Solo se decide una incidencia REGISTRADA (409 si ya fue decidida).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_INCIDENCIA_DECIDIR"(
    IN    "HV_ID_Incidencia"  BIGINT,
    IN    "HV_Decision"       VARCHAR(20),
    IN    "HV_Sustento"       VARCHAR(2000),
    IN    "HV_UsuarioID"      BIGINT,
    INOUT "HV_Codigo_Resp"    INT DEFAULT NULL,
    INOUT "HV_Mensaje"        VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_dec    VARCHAR(20) := UPPER(TRIM(COALESCE("HV_Decision", '')));
    lv_n      INT := 0;
    lv_estado VARCHAR(20);
    lv_sede   BIGINT;
    lv_cod    VARCHAR(20);
    lv_nsol   INT := 0;
    lv_sol    BIGINT;
    lv_c      INT;
    lv_m      VARCHAR(250);
BEGIN
    -- V1.0 2026-10-18
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_INCIDENCIA_DECIDIR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF lv_dec NOT IN ('CONFIRMAR','DESESTIMAR') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La decisión debe ser CONFIRMAR o DESESTIMAR.'; RETURN;
        END IF;
        IF "HV_Sustento" IS NULL OR LENGTH(TRIM("HV_Sustento")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Escriba el sustento de la decisión.'; RETURN;
        END IF;
        IF LENGTH(TRIM("HV_Sustento")) > 2000 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El sustento no puede superar 2000 caracteres.'; RETURN;
        END IF;
        -- Serializa decisiones simultáneas
        UPDATE "CAF_Incidencia" SET "UpdateDate" = "UpdateDate" WHERE "ID_Incidencia" = "HV_ID_Incidencia";
        SELECT COUNT(*), MAX("Estado"), MAX("ID_Catalogo_Sede"), MAX("Codigo")
          INTO lv_n, lv_estado, lv_sede, lv_cod
          FROM "CAF_Incidencia" WHERE "ID_Incidencia" = "HV_ID_Incidencia" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La incidencia no existe.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_DECIDIR', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para decidir incidencias de esta sede.'; RETURN;
        END IF;
        IF lv_estado <> 'REGISTRADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La incidencia ya fue decidida.'; RETURN;
        END IF;

        UPDATE "CAF_Incidencia"
           SET "Estado" = CASE lv_dec WHEN 'CONFIRMAR' THEN 'CONFIRMADA' ELSE 'DESESTIMADA' END,
               "ID_Usuario_Decision" = "HV_UsuarioID", "Fecha_Decision" = CURRENT_TIMESTAMP,
               "Sustento_Decision" = TRIM("HV_Sustento"),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Incidencia" = "HV_ID_Incidencia";

        SELECT COUNT(DISTINCT P."ID_Solicitud"), MAX(P."ID_Solicitud") INTO lv_nsol, lv_sol
          FROM "CAF_Incidencia_Persona" IP
          JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = IP."ID_Solicitud_Persona"
         WHERE IP."ID_Incidencia" = "HV_ID_Incidencia" AND IP."Eliminado" = 'N';
        IF lv_nsol <> 1 THEN lv_sol := NULL; END IF;

        CALL "ERP_CAF_EVENTO_REGISTRAR"('INCIDENCIA', "HV_ID_Incidencia", lv_sol, lv_dec,
             lv_cod || ' · ' || LEFT(TRIM("HV_Sustento"), 200), "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE lv_dec WHEN 'CONFIRMAR' THEN 'Incidencia confirmada.' ELSE 'Incidencia desestimada.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_INCIDENCIA_DECIDIR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_INCIDENCIA_LISTAR
--    Ven la lista quienes registran, deciden incidencias, ven portería o el reporte.
--    Orden: REGISTRADA primero (las más antiguas arriba), luego las decididas (recientes arriba).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_INCIDENCIA_LISTAR"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT,
    "HV_Estado"           VARCHAR DEFAULT NULL,
    "HV_Fecha_Desde"      DATE    DEFAULT NULL,
    "HV_Fecha_Hasta"      DATE    DEFAULT NULL,
    "HV_Texto"            VARCHAR DEFAULT NULL
)
RETURNS TABLE ("ID_Incidencia" BIGINT, "Codigo" VARCHAR, "Fecha_Hora_Hecho" TIMESTAMP, "Tipo_Codigo" VARCHAR,
               "Tipo_Descripcion" VARCHAR, "Zona_Descripcion" VARCHAR, "Lugar_Detalle" VARCHAR, "Descripcion" VARCHAR,
               "Origen" VARCHAR, "Registrador_Nombre" VARCHAR, "Estado" VARCHAR, "Cantidad_Personas" BIGINT,
               "Fecha_Decision" TIMESTAMP)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_est VARCHAR(20)  := UPPER(TRIM(COALESCE("HV_Estado", '')));
    lv_txt VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Texto", '')));
BEGIN
    -- V1.0 2026-10-18
    IF "HV_ID_Catalogo_Sede" IS NULL OR NOT (
          "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_REGISTRAR', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_DECIDIR', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', "HV_ID_Catalogo_Sede") = 'Y') THEN
        RETURN;
    END IF;
    IF lv_est NOT IN ('', 'REGISTRADA', 'CONFIRMADA', 'DESESTIMADA') THEN RETURN; END IF;
    RETURN QUERY
    SELECT I."ID_Incidencia", I."Codigo", I."Fecha_Hora_Hecho", T."Codigo",
           CAST(CASE WHEN T."Es_Otro" = 'Y' THEN T."Descripcion" || ': ' || COALESCE(I."Tipo_Detalle", '') ELSE T."Descripcion" END AS VARCHAR),
           Z."Descripcion", I."Lugar_Detalle", I."Descripcion", I."Origen",
           CAST(U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" AS VARCHAR),
           I."Estado",
           (SELECT COUNT(*) FROM "CAF_Incidencia_Persona" IP WHERE IP."ID_Incidencia" = I."ID_Incidencia" AND IP."Eliminado" = 'N'),
           I."Fecha_Decision"
      FROM "CAF_Incidencia" I
      JOIN "Catalogo_Tipo_Incidencia" T ON T."ID_Catalogo_Tipo_Incidencia" = I."ID_Catalogo_Tipo_Incidencia"
      LEFT JOIN "Catalogo_Zona_Acceso" Z ON Z."ID_Catalogo_Zona_Acceso" = I."ID_Catalogo_Zona_Acceso"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = I."ID_Usuario_Registro"
     WHERE I."Eliminado" = 'N' AND I."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
       AND (lv_est = '' OR I."Estado" = lv_est)
       AND ("HV_Fecha_Desde" IS NULL OR CAST(I."Fecha_Hora_Hecho" AS DATE) >= "HV_Fecha_Desde")
       AND ("HV_Fecha_Hasta" IS NULL OR CAST(I."Fecha_Hora_Hecho" AS DATE) <= "HV_Fecha_Hasta")
       AND (lv_txt = '' OR "ERP_CAF_FN_NORMALIZAR"(I."Codigo" || ' ' || I."Descripcion" || ' ' || T."Descripcion" || ' '
                                                    || COALESCE(I."Lugar_Detalle", '') || ' ' || COALESCE(Z."Descripcion", '')) LIKE '%' || lv_txt || '%')
     ORDER BY CASE I."Estado" WHEN 'REGISTRADA' THEN 0 ELSE 1 END,
              CASE I."Estado" WHEN 'REGISTRADA' THEN EXTRACT(EPOCH FROM I."Fecha_Hora_Hecho") ELSE -EXTRACT(EPOCH FROM I."Fecha_Hora_Hecho") END,
              I."ID_Incidencia";
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_INCIDENCIA_DETALLE
--    Puede_Decidir repite la regla de ERP_CAF_INCIDENCIA_DECIDIR (D-56).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_INCIDENCIA_DETALLE"(
    "HV_UsuarioID"    BIGINT,
    "HV_ID_Incidencia" BIGINT
)
RETURNS TABLE ("ID_Incidencia" BIGINT, "Codigo" VARCHAR, "ID_Catalogo_Sede" BIGINT, "Fecha_Hora_Hecho" TIMESTAMP,
               "ID_Catalogo_Tipo_Incidencia" BIGINT, "Tipo_Descripcion" VARCHAR, "Tipo_Detalle" VARCHAR,
               "ID_Catalogo_Zona_Acceso" BIGINT, "Zona_Descripcion" VARCHAR, "Lugar_Detalle" VARCHAR,
               "Descripcion" VARCHAR, "Origen" VARCHAR, "Registrador_Nombre" VARCHAR, "Estado" VARCHAR,
               "Decisor_Nombre" VARCHAR, "Fecha_Decision" TIMESTAMP, "Sustento_Decision" VARCHAR,
               "Puede_Decidir" CHAR(1))
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_sede BIGINT;
BEGIN
    -- V1.0 2026-10-18
    SELECT MAX(I."ID_Catalogo_Sede") INTO lv_sede
      FROM "CAF_Incidencia" I WHERE I."ID_Incidencia" = "HV_ID_Incidencia" AND I."Eliminado" = 'N';
    IF lv_sede IS NULL OR NOT (
          "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_REGISTRAR', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_DECIDIR', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', lv_sede) = 'Y') THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT I."ID_Incidencia", I."Codigo", I."ID_Catalogo_Sede", I."Fecha_Hora_Hecho",
           I."ID_Catalogo_Tipo_Incidencia", T."Descripcion", I."Tipo_Detalle",
           I."ID_Catalogo_Zona_Acceso", Z."Descripcion", I."Lugar_Detalle",
           I."Descripcion", I."Origen",
           CAST(U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" AS VARCHAR),
           I."Estado",
           CAST(D."Apellido_Paterno" || COALESCE(' ' || D."Apellido_Materno", '') || ', ' || D."Nombres" AS VARCHAR),
           I."Fecha_Decision", I."Sustento_Decision",
           CAST(CASE WHEN I."Estado" = 'REGISTRADA'
                      AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_DECIDIR', I."ID_Catalogo_Sede") = 'Y'
                     THEN 'Y' ELSE 'N' END AS CHAR(1))
      FROM "CAF_Incidencia" I
      JOIN "Catalogo_Tipo_Incidencia" T ON T."ID_Catalogo_Tipo_Incidencia" = I."ID_Catalogo_Tipo_Incidencia"
      LEFT JOIN "Catalogo_Zona_Acceso" Z ON Z."ID_Catalogo_Zona_Acceso" = I."ID_Catalogo_Zona_Acceso"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = I."ID_Usuario_Registro"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" D ON D."ID_Usuario" = I."ID_Usuario_Decision"
     WHERE I."ID_Incidencia" = "HV_ID_Incidencia" AND I."Eliminado" = 'N';
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_INCIDENCIA_PERSONAS_LISTAR  (personas involucradas en una incidencia)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR"(
    "HV_UsuarioID"     BIGINT,
    "HV_ID_Incidencia" BIGINT
)
RETURNS TABLE ("ID_Solicitud_Persona" BIGINT, "ID_Solicitud" BIGINT, "Codigo_Solicitud" VARCHAR,
               "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR, "Persona_Nombre" VARCHAR,
               "Empresa_Visitante" VARCHAR, "Estado_Persona" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_sede BIGINT;
BEGIN
    -- V1.0 2026-10-18
    SELECT MAX(I."ID_Catalogo_Sede") INTO lv_sede
      FROM "CAF_Incidencia" I WHERE I."ID_Incidencia" = "HV_ID_Incidencia" AND I."Eliminado" = 'N';
    IF lv_sede IS NULL OR NOT (
          "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_REGISTRAR', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_DECIDIR', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', lv_sede) = 'Y') THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT P."ID_Solicitud_Persona", S."ID_Solicitud", S."Codigo", TD."Codigo", PE."Numero_Documento",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           S."Empresa_Visitante", P."Estado"
      FROM "CAF_Incidencia_Persona" IP
      JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = IP."ID_Solicitud_Persona"
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = PE."ID_Catalogo_Tipo_Documento"
     WHERE IP."ID_Incidencia" = "HV_ID_Incidencia" AND IP."Eliminado" = 'N'
     ORDER BY PE."Apellido_Paterno", PE."Nombres", P."ID_Solicitud_Persona";
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CAF_INCIDENCIA_CONTADORES  (cuántas hay por estado, para las pestañas)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_INCIDENCIA_CONTADORES"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT
)
RETURNS TABLE ("Registradas" BIGINT, "Confirmadas" BIGINT, "Desestimadas" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-18
    IF "HV_ID_Catalogo_Sede" IS NULL OR NOT (
          "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_REGISTRAR', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_DECIDIR', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', "HV_ID_Catalogo_Sede") = 'Y') THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT COUNT(CASE WHEN I."Estado" = 'REGISTRADA' THEN 1 END),
           COUNT(CASE WHEN I."Estado" = 'CONFIRMADA' THEN 1 END),
           COUNT(CASE WHEN I."Estado" = 'DESESTIMADA' THEN 1 END)
      FROM "CAF_Incidencia" I
     WHERE I."Eliminado" = 'N' AND I."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede";
END;
$$;

-- -----------------------------------------------------------------------------
-- 7. ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR
--    Para elegir a quién involucra la incidencia: personas de visitas de la sede
--    cuya fecha prevista cae en [Fecha_Desde, Fecha_Hasta] (por defecto hoy y ayer),
--    sin importar su estado (una persona puede haber salido ya). Texto opcional.
--    Quien registra incidencias necesita PER_CAF_INCIDENCIA_REGISTRAR.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT,
    "HV_Fecha_Desde"      DATE    DEFAULT NULL,
    "HV_Fecha_Hasta"      DATE    DEFAULT NULL,
    "HV_Texto"            VARCHAR DEFAULT NULL
)
RETURNS TABLE ("ID_Solicitud_Persona" BIGINT, "ID_Solicitud" BIGINT, "Codigo_Solicitud" VARCHAR,
               "Fecha_Hora_Prevista" TIMESTAMP, "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR,
               "Persona_Nombre" VARCHAR, "Empresa_Visitante" VARCHAR, "Estado_Persona" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_d1  DATE := COALESCE("HV_Fecha_Desde", CURRENT_DATE - 1);
    lv_d2  DATE := COALESCE("HV_Fecha_Hasta", COALESCE("HV_Fecha_Desde", CURRENT_DATE));
    lv_txt VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Texto", '')));
BEGIN
    -- V1.0 2026-10-18
    IF "HV_ID_Catalogo_Sede" IS NULL
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_INCIDENCIA_REGISTRAR', "HV_ID_Catalogo_Sede") <> 'Y' THEN
        RETURN;
    END IF;
    IF lv_d2 < lv_d1 THEN RETURN; END IF;
    RETURN QUERY
    SELECT P."ID_Solicitud_Persona", S."ID_Solicitud", S."Codigo", S."Fecha_Hora_Prevista", TD."Codigo", PE."Numero_Documento",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           S."Empresa_Visitante", P."Estado"
      FROM "CAF_Solicitud_Persona" P
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud" AND S."Eliminado" = 'N'
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = PE."ID_Catalogo_Tipo_Documento"
     WHERE P."Eliminado" = 'N' AND S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
       AND CAST(S."Fecha_Hora_Prevista" AS DATE) BETWEEN lv_d1 AND lv_d2
       AND (lv_txt = '' OR "ERP_CAF_FN_NORMALIZAR"(PE."Numero_Documento" || ' ' || PE."Apellido_Paterno" || ' ' || COALESCE(PE."Apellido_Materno", '')
                                                    || ' ' || PE."Nombres" || ' ' || COALESCE(S."Empresa_Visitante", '') || ' ' || S."Codigo") LIKE '%' || lv_txt || '%')
     ORDER BY S."Fecha_Hora_Prevista" DESC, PE."Apellido_Paterno", PE."Nombres", P."ID_Solicitud_Persona";
END;
$$;
