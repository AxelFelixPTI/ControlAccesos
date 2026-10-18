-- =============================================================================
-- Archivo : SP_CAF_PORTERIA_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 3 - Portería y desviaciones | Fase 1 - Procedimientos (portería, escritura)
-- Entidad : CAF_Registro_Acceso, CAF_Registro_Checklist (y, a través de ellos, CAF_Solicitud_Persona)
-- Versión : V1.0 2026-10-17
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO3_ESCRITURA.sql)
-- Requiere: scripts 01 a 10, los SP de los Hitos 0, 1 y 2 y SP_CAF_DESVIACION_ALL.sql.
-- =============================================================================
-- PIEZAS INTERNAS (la aplicación no las llama directo):
--  1 ERP_CAF_PORTERIA_ITEMS_APLICABLES   qué ítems del checklist se muestran en este movimiento
--  2 ERP_CAF_PORTERIA_REGLA_MOVIMIENTO   ¿esta persona puede ingresar / salir ahora? (D-56)
--
-- PARA LA APLICACIÓN:
--  3 ERP_CAF_PORTERIA_INGRESO_REGISTRAR  Vigilancia registra un ingreso (o lo deniega)
--  4 ERP_CAF_PORTERIA_SALIDA_REGISTRAR   Vigilancia registra una salida
--  5 ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR   cierre automático de «no se presentó»
--
-- REGLAS (D-62 a D-70; se detallan en DECISIONES_HITO3.md)
--  * Un movimiento = un CAF_Registro_Acceso con TODOS los ítems mostrados, cumplan o no (D-20).
--  * Si algún ítem no cumple, nace una desviación (una por movimiento). Si el ítem es
--    crítico (identidad) y no cumple, el ingreso solo puede denegarse.
--  * Una denegación también es un registro (NO_INGRESA) y la persona queda DENEGADA (D-21):
--    no se vuelve a intentar en la misma visita.
--  * Quien llega con equipos o herramientas necesita un respaldo (G-FSCA-009, guía) registrado
--    antes con ERP_CAF_RESPALDO_REGISTRAR (RN-14). La salida verifica ese contenido.
--  * Registro tardío (RN-18): si Vigilancia indica la hora del hecho, se guarda como tardío,
--    se exige la observación y la hora real de la carga queda en Fecha_Hora_Sistema.
--  * Una salida siempre deja salir a la persona; la desviación solo decide si se retiene un elemento.
--  * La persona figura como DENTRO / SALIO / DENEGADA / NO_SE_PRESENTO en CAF_Solicitud_Persona
--    (resumen de pantalla, D-18); la evidencia completa está en estas tablas.
--
-- ENTRADA DEL CHECKLIST: texto «id:Y,id:N,...» con TODOS los ítems aplicables (Y = cumple).
-- HANA: sin cursores ni tablas temporales; las listas se leen con LIKE sobre un texto
-- delimitado por comas, igual que en el Hito 2.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_PORTERIA_ITEMS_APLICABLES  (interna)
--    Ítems de la etapa que aplican al tipo de acceso de la solicitud y cuya
--    condición se cumple. TRAE_EQUIPOS / TRAE_HERRAMIENTAS dependen de lo que la
--    persona trae (al ingresar lo responde Vigilancia; en la salida es lo guardado).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(
    "HV_ID_Solicitud_Persona" BIGINT,
    "HV_Etapa"                VARCHAR,
    "HV_Trae_Equipos"         CHAR,
    "HV_Trae_Herramientas"    CHAR
)
RETURNS TABLE ("ID_Catalogo_Item_Checklist" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Ayuda" VARCHAR,
               "Es_Critico" CHAR(1), "Orden" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-17
    RETURN QUERY
    SELECT I."ID_Catalogo_Item_Checklist", I."Codigo", I."Descripcion", I."Ayuda", I."Es_Critico", I."Orden"
      FROM "CAF_Solicitud_Persona" P
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
      JOIN "Tipo_Acceso_Item_Checklist" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Eliminado" = 'N'
      JOIN "Catalogo_Item_Checklist" I ON I."ID_Catalogo_Item_Checklist" = T."ID_Catalogo_Item_Checklist"
                                      AND I."Eliminado" = 'N' AND I."Activo" = 'Y'
     WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona"
       AND I."Etapa" = UPPER(TRIM(COALESCE("HV_Etapa", '')))
       AND (I."Condicion" = 'SIEMPRE'
            OR (I."Condicion" = 'ZONA_EXIGE_SCTR'   AND S."Exige_SCTR" = 'Y')
            OR (I."Condicion" = 'ZONA_EXIGE_EPP'    AND S."Exige_EPP" = 'Y')
            OR (I."Condicion" = 'TRAE_EQUIPOS'      AND COALESCE("HV_Trae_Equipos", 'N') = 'Y')
            OR (I."Condicion" = 'TRAE_HERRAMIENTAS' AND COALESCE("HV_Trae_Herramientas", 'N') = 'Y'))
     ORDER BY I."Orden", I."ID_Catalogo_Item_Checklist";
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_PORTERIA_REGLA_MOVIMIENTO  (interna)
--    LA regla de «¿puede ingresar / salir?». La usan los dos procedimientos de
--    escritura (que la aplican) y la ficha de portería (que la muestra): un solo lugar (D-56).
--    HV_Etapa: INGRESO o SALIDA.  HV_Tardio: 'Y' si es un registro tardío.
--    No revisa permisos de usuario (eso lo hace quien llama).
--    Codigo_Resp: 100 si puede; 404 / 409 con el motivo si no.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PORTERIA_REGLA_MOVIMIENTO"(
    "HV_ID_Solicitud_Persona" BIGINT,
    "HV_Etapa"                VARCHAR,
    "HV_Tardio"               CHAR DEFAULT 'N'
)
RETURNS TABLE ("Permitido" CHAR(1), "Codigo_Resp" INT, "Mensaje" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_n      INT := 0;
    lv_est_p  VARCHAR(20);
    lv_apr    VARCHAR(20);
    lv_est_s  VARCHAR(20);
    lv_fecha  DATE;
    lv_etapa  VARCHAR(10) := UPPER(TRIM(COALESCE("HV_Etapa", '')));
    lv_msg    VARCHAR(250) := NULL;
    lv_cod    INT := 100;
BEGIN
    -- V1.0 2026-10-17
    SELECT COUNT(*), MAX(P."Estado"), MAX(P."Aprobacion"), MAX(S."Estado"), MAX(CAST(S."Fecha_Hora_Prevista" AS DATE))
      INTO lv_n, lv_est_p, lv_apr, lv_est_s, lv_fecha
      FROM "CAF_Solicitud_Persona" P
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud" AND S."Eliminado" = 'N'
     WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND P."Eliminado" = 'N';

    IF lv_n = 0 THEN
        lv_cod := 404; lv_msg := 'La persona no figura en ninguna solicitud.';
    ELSIF lv_etapa NOT IN ('INGRESO','SALIDA') THEN
        lv_cod := 400; lv_msg := 'La etapa debe ser INGRESO o SALIDA.';
    ELSIF lv_est_s = 'CANCELADA' THEN
        lv_cod := 409; lv_msg := 'La solicitud está cancelada.';
    ELSIF lv_etapa = 'INGRESO' THEN
        IF lv_apr <> 'APROBADA' THEN
            lv_cod := 409; lv_msg := 'La persona no está autorizada para ingresar.';
        ELSIF lv_est_p = 'DENTRO' THEN
            lv_cod := 409; lv_msg := 'La persona ya ingresó.';
        ELSIF lv_est_p = 'SALIO' THEN
            lv_cod := 409; lv_msg := 'La persona ya ingresó y salió.';
        ELSIF lv_est_p = 'DENEGADA' THEN
            lv_cod := 409; lv_msg := 'Ya se le denegó el ingreso en esta visita.';
        ELSIF lv_est_p = 'NO_SE_PRESENTO' THEN
            lv_cod := 409; lv_msg := 'La persona figura como «no se presentó».';
        ELSIF COALESCE("HV_Tardio", 'N') = 'Y' THEN
            IF lv_fecha > CURRENT_DATE THEN
                lv_cod := 409; lv_msg := 'La visita todavía no ocurre: no corresponde un registro tardío.';
            END IF;
        ELSIF lv_fecha < CURRENT_DATE THEN
            lv_cod := 409; lv_msg := 'La fecha de la visita ya pasó. Si el ingreso ocurrió y no se registró, use el registro tardío.';
        ELSIF lv_fecha > CURRENT_DATE THEN
            lv_cod := 409; lv_msg := 'La visita es para otra fecha.';
        END IF;
    ELSE
        IF lv_est_p = 'ESPERADA' THEN
            lv_cod := 409; lv_msg := 'La persona aún no ingresó.';
        ELSIF lv_est_p = 'SALIO' THEN
            lv_cod := 409; lv_msg := 'La persona ya salió.';
        ELSIF lv_est_p = 'DENEGADA' THEN
            lv_cod := 409; lv_msg := 'A la persona se le denegó el ingreso.';
        ELSIF lv_est_p = 'NO_SE_PRESENTO' THEN
            lv_cod := 409; lv_msg := 'La persona figura como «no se presentó».';
        END IF;
    END IF;

    RETURN QUERY
    SELECT CAST(CASE WHEN lv_cod = 100 THEN 'Y' ELSE 'N' END AS CHAR(1)), lv_cod,
           CAST(COALESCE(lv_msg, 'Puede registrarse.') AS VARCHAR);
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_PORTERIA_INGRESO_REGISTRAR
--    HV_Items: «id:Y,id:N,...» con todos los ítems de ERP_CAF_PORTERIA_CHECKLIST_OBTENER
--    (etapa INGRESO, con los mismos Trae_Equipos / Trae_Herramientas).
--    Con algún ítem en N hay que enviar los datos de la desviación (descripción,
--    Coordinador consultado, tratamiento; «Otro» exige detalle y efecto).
--    HV_Fecha_Hora_Hecho: nulo = ahora. Con valor = registro tardío.
--    Devuelve el registro, la desviación (si la hubo) y el resultado final.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(
    IN    "HV_ID_Solicitud_Persona"   BIGINT,
    IN    "HV_Items"                  VARCHAR(2000),
    IN    "HV_Trae_Equipos"           CHAR(1),
    IN    "HV_Trae_Herramientas"      CHAR(1),
    IN    "HV_Observacion"            VARCHAR(1000),
    IN    "HV_Desv_Descripcion"       VARCHAR(2000),
    IN    "HV_ID_Coordinador"         BIGINT,
    IN    "HV_ID_Tratamiento"         BIGINT,
    IN    "HV_Tratamiento_Detalle"    VARCHAR(500),
    IN    "HV_Resultado_Elegido"      VARCHAR(30),
    IN    "HV_Fecha_Hora_Hecho"       TIMESTAMP,
    IN    "HV_UsuarioID"              BIGINT,
    INOUT "HV_ID_Registro_Acceso_Result" BIGINT DEFAULT NULL,
    INOUT "HV_ID_Desviacion_Result"   BIGINT DEFAULT NULL,
    INOUT "HV_Resultado_Result"       VARCHAR(30) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"            INT DEFAULT NULL,
    INOUT "HV_Mensaje"                VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n        INT := 0;
    lv_sede     BIGINT;
    lv_sol      BIGINT;
    lv_codsol   VARCHAR(20);
    lv_prevista TIMESTAMP;
    lv_nombre   VARCHAR(400);
    lv_trae_eq  CHAR(1) := COALESCE("HV_Trae_Equipos", 'N');
    lv_trae_h   CHAR(1) := COALESCE("HV_Trae_Herramientas", 'N');
    lv_tardio   CHAR(1) := 'N';
    lv_hecho    TIMESTAMP;
    lv_lista    VARCHAR(2100);
    lv_tokens   INT;
    lv_aplic    INT;
    lv_cubre    INT;
    lv_incumple INT;
    lv_critico  INT;
    lv_res      VARCHAR(30);
    lv_reg      BIGINT;
    lv_des      BIGINT := 0;
    lv_perm     CHAR(1);
    lv_cod_r    INT;
    lv_msg_r    VARCHAR(250);
    lv_c        INT;
    lv_m        VARCHAR(250);
    lv_estado   VARCHAR(20);
BEGIN
    -- V1.0 2026-10-17
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PORTERIA_INGRESO_REGISTRAR';
    "HV_ID_Registro_Acceso_Result" := 0;
    "HV_ID_Desviacion_Result" := 0;
    "HV_Resultado_Result" := NULL;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF lv_trae_eq NOT IN ('Y','N') OR lv_trae_h NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Equipos y herramientas deben ser Y o N.'; RETURN;
        END IF;
        -- Serializa por persona: dos vigilantes sobre la misma persona no se pisan
        UPDATE "CAF_Solicitud_Persona" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
        SELECT COUNT(*), MAX(S."ID_Catalogo_Sede"), MAX(S."ID_Solicitud"), MAX(S."Codigo"), MAX(S."Fecha_Hora_Prevista"),
               MAX(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres")
          INTO lv_n, lv_sede, lv_sol, lv_codsol, lv_prevista, lv_nombre
          FROM "CAF_Solicitud_Persona" P
          JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud" AND S."Eliminado" = 'N'
          JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
         WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND P."Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no figura en ninguna solicitud.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para registrar ingresos en esta sede.'; RETURN;
        END IF;

        -- Registro tardío: la hora del hecho la indica Vigilancia (RN-18)
        IF "HV_Fecha_Hora_Hecho" IS NOT NULL THEN
            lv_tardio := 'Y';
            lv_hecho  := "HV_Fecha_Hora_Hecho";
            IF lv_hecho > CURRENT_TIMESTAMP THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La hora indicada es futura.'; RETURN;
            END IF;
            IF CAST(lv_hecho AS DATE) <> CAST(lv_prevista AS DATE) THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La fecha del registro tardío debe ser la de la visita.'; RETURN;
            END IF;
            IF "HV_Observacion" IS NULL OR LENGTH(TRIM("HV_Observacion")) = 0 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Explique por qué el registro es tardío.'; RETURN;
            END IF;
        ELSE
            lv_hecho := CURRENT_TIMESTAMP;
        END IF;
        IF "HV_Observacion" IS NOT NULL AND LENGTH(TRIM("HV_Observacion")) > 1000 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La observación no puede superar 1000 caracteres.'; RETURN;
        END IF;

        -- La regla única: ¿puede ingresar?
        SELECT R."Permitido", R."Codigo_Resp", R."Mensaje" INTO lv_perm, lv_cod_r, lv_msg_r
          FROM "ERP_CAF_PORTERIA_REGLA_MOVIMIENTO"("HV_ID_Solicitud_Persona", 'INGRESO', lv_tardio) R;
        IF lv_perm <> 'Y' THEN
            "HV_Codigo_Resp" := lv_cod_r; "HV_Mensaje" := lv_msg_r; RETURN;
        END IF;

        -- Checklist: todos los ítems aplicables, ni uno más ni uno menos
        lv_lista  := ',' || REPLACE(UPPER(COALESCE("HV_Items", '')), ' ', '') || ',';
        lv_tokens := CASE WHEN LENGTH(REPLACE(lv_lista, ',', '')) = 0 THEN 0
                          ELSE LENGTH(lv_lista) - LENGTH(REPLACE(lv_lista, ',', '')) - 1 END;
        SELECT COUNT(*),
               SUM(CASE WHEN lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':Y,%'
                          OR lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':N,%' THEN 1 ELSE 0 END),
               SUM(CASE WHEN lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':N,%' THEN 1 ELSE 0 END),
               SUM(CASE WHEN lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':N,%' AND A."Es_Critico" = 'Y' THEN 1 ELSE 0 END)
          INTO lv_aplic, lv_cubre, lv_incumple, lv_critico
          FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"("HV_ID_Solicitud_Persona", 'INGRESO', lv_trae_eq, lv_trae_h) A;
        lv_cubre := COALESCE(lv_cubre, 0); lv_incumple := COALESCE(lv_incumple, 0); lv_critico := COALESCE(lv_critico, 0);
        IF lv_aplic = 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No hay ítems de checklist configurados para este tipo de acceso.'; RETURN;
        END IF;
        IF lv_cubre <> lv_aplic OR lv_tokens <> lv_aplic THEN
            "HV_Codigo_Resp" := 400;
            "HV_Mensaje" := 'Responda todos los ítems del checklist, ni más ni menos, con el formato id:Y o id:N.'; RETURN;
        END IF;

        IF lv_incumple = 0 THEN
            IF ("HV_Desv_Descripcion" IS NOT NULL AND LENGTH(TRIM("HV_Desv_Descripcion")) > 0) OR "HV_ID_Tratamiento" IS NOT NULL THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Todos los ítems cumplen: no corresponde registrar una desviación.'; RETURN;
            END IF;
            lv_res := 'INGRESA';
        ELSE
            IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_DESVIACION_REGISTRAR', lv_sede) <> 'Y' THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para registrar desviaciones en esta sede.'; RETURN;
            END IF;
            CALL "ERP_CAF_DESVIACION_VALIDAR"('INGRESO', "HV_Desv_Descripcion", "HV_ID_Coordinador", "HV_ID_Tratamiento",
                 "HV_Tratamiento_Detalle", "HV_Resultado_Elegido", lv_sede, lv_res, lv_c, lv_m);
            IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RETURN; END IF;
            IF lv_critico > 0 AND lv_res <> 'NO_INGRESA' THEN
                "HV_Codigo_Resp" := 101;
                "HV_Mensaje" := 'Un ítem crítico no se cumple (identidad): el ingreso debe denegarse.'; RETURN;
            END IF;
        END IF;

        -- Quien trae equipos o herramientas y entra necesita su respaldo registrado (RN-14)
        IF lv_res IN ('INGRESA','INGRESA_RESTRINGIDO') THEN
            IF lv_trae_eq = 'Y' AND NOT EXISTS (
                   SELECT 1 FROM "CAF_Respaldo_Persona" RP JOIN "CAF_Respaldo" RS ON RS."ID_Respaldo" = RP."ID_Respaldo"
                    WHERE RP."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND RP."Eliminado" = 'N'
                      AND RS."Eliminado" = 'N' AND RS."Categoria" = 'EQUIPOS') THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Registre primero el respaldo de los equipos (formato G-FSCA-009).'; RETURN;
            END IF;
            IF lv_trae_h = 'Y' AND NOT EXISTS (
                   SELECT 1 FROM "CAF_Respaldo_Persona" RP JOIN "CAF_Respaldo" RS ON RS."ID_Respaldo" = RP."ID_Respaldo"
                    WHERE RP."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND RP."Eliminado" = 'N'
                      AND RS."Eliminado" = 'N' AND RS."Categoria" = 'HERRAMIENTAS_MATERIALES') THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Registre primero el respaldo de herramientas o materiales (guía de remisión o G-FSCA-010).'; RETURN;
            END IF;
        END IF;

        -- Se escribe el movimiento y su checklist
        INSERT INTO "CAF_Registro_Acceso" ("ID_Solicitud_Persona","ID_Catalogo_Sede","Tipo_Movimiento","Resultado","Fecha_Hora",
                                           "Es_Registro_Tardio","ID_Usuario_Vigilante","Observacion","UsuarioID_Create")
        VALUES ("HV_ID_Solicitud_Persona", lv_sede, 'INGRESO', lv_res, lv_hecho, lv_tardio, "HV_UsuarioID",
                NULLIF(TRIM(COALESCE("HV_Observacion", '')), ''), "HV_UsuarioID")
        RETURNING "ID_Registro_Acceso" INTO lv_reg;

        INSERT INTO "CAF_Registro_Checklist" ("ID_Registro_Acceso","ID_Catalogo_Item_Checklist","Cumple","UsuarioID_Create")
        SELECT lv_reg, A."ID_Catalogo_Item_Checklist",
               CASE WHEN lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':Y,%' THEN 'Y' ELSE 'N' END,
               "HV_UsuarioID"
          FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"("HV_ID_Solicitud_Persona", 'INGRESO', lv_trae_eq, lv_trae_h) A;

        IF lv_incumple > 0 THEN
            CALL "ERP_CAF_DESVIACION_CREAR"(lv_reg, lv_sol, "HV_Desv_Descripcion", "HV_ID_Coordinador", "HV_ID_Tratamiento",
                 "HV_Tratamiento_Detalle", lv_res, "HV_UsuarioID", lv_des, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'desviacion: %', lv_m; END IF;
        END IF;

        -- La persona: resumen para las pantallas (D-18)
        lv_estado := CASE WHEN lv_res = 'NO_INGRESA' THEN 'DENEGADA' ELSE 'DENTRO' END;
        UPDATE "CAF_Solicitud_Persona"
           SET "Estado" = lv_estado,
               "Acceso_Restringido" = CASE WHEN lv_res = 'INGRESA_RESTRINGIDO' THEN 'Y' ELSE 'N' END,
               "Trae_Equipos"      = CASE WHEN lv_res = 'NO_INGRESA' THEN 'N' ELSE lv_trae_eq END,
               "Trae_Herramientas" = CASE WHEN lv_res = 'NO_INGRESA' THEN 'N' ELSE lv_trae_h END,
               "Fecha_Hora_Ingreso" = CASE WHEN lv_res = 'NO_INGRESA' THEN NULL ELSE lv_hecho END,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";

        CALL "ERP_CAF_EVENTO_REGISTRAR"('REGISTRO_ACCESO', lv_reg, lv_sol,
             CASE WHEN lv_res = 'NO_INGRESA' THEN 'DENEGAR' ELSE 'INGRESO' END,
             lv_nombre || ' · ' || lv_res || CASE WHEN lv_tardio = 'Y' THEN ' · registro tardío' ELSE '' END,
             "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_ID_Registro_Acceso_Result" := lv_reg;
        "HV_ID_Desviacion_Result" := lv_des;
        "HV_Resultado_Result" := lv_res;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje" := CASE lv_res WHEN 'INGRESA' THEN 'Ingreso registrado.'
                                    WHEN 'INGRESA_RESTRINGIDO' THEN 'Ingreso registrado con restricción a la zona administrativa.'
                                    ELSE 'Ingreso denegado y registrado.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_ID_Registro_Acceso_Result" := 0; "HV_ID_Desviacion_Result" := 0; "HV_Resultado_Result" := NULL;
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PORTERIA_INGRESO_REGISTRAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_PORTERIA_SALIDA_REGISTRAR
--    Los ítems de salida dependen de lo que la persona declaró al ingresar
--    (TRAE_EQUIPOS / TRAE_HERRAMIENTAS guardados en su fila). La salida siempre
--    se registra; si algo no cumple se levanta una desviación cuyo efecto es
--    SALE o SALE_RETIENE_ELEMENTO.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(
    IN    "HV_ID_Solicitud_Persona"   BIGINT,
    IN    "HV_Items"                  VARCHAR(2000),
    IN    "HV_Observacion"            VARCHAR(1000),
    IN    "HV_Desv_Descripcion"       VARCHAR(2000),
    IN    "HV_ID_Coordinador"         BIGINT,
    IN    "HV_ID_Tratamiento"         BIGINT,
    IN    "HV_Tratamiento_Detalle"    VARCHAR(500),
    IN    "HV_Resultado_Elegido"      VARCHAR(30),
    IN    "HV_Fecha_Hora_Hecho"       TIMESTAMP,
    IN    "HV_UsuarioID"              BIGINT,
    INOUT "HV_ID_Registro_Acceso_Result" BIGINT DEFAULT NULL,
    INOUT "HV_ID_Desviacion_Result"   BIGINT DEFAULT NULL,
    INOUT "HV_Resultado_Result"       VARCHAR(30) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"            INT DEFAULT NULL,
    INOUT "HV_Mensaje"                VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n        INT := 0;
    lv_sede     BIGINT;
    lv_sol      BIGINT;
    lv_nombre   VARCHAR(400);
    lv_trae_eq  CHAR(1);
    lv_trae_h   CHAR(1);
    lv_ingreso  TIMESTAMP;
    lv_tardio   CHAR(1) := 'N';
    lv_hecho    TIMESTAMP;
    lv_lista    VARCHAR(2100);
    lv_tokens   INT;
    lv_aplic    INT;
    lv_cubre    INT;
    lv_incumple INT;
    lv_res      VARCHAR(30);
    lv_reg      BIGINT;
    lv_des      BIGINT := 0;
    lv_perm     CHAR(1);
    lv_cod_r    INT;
    lv_msg_r    VARCHAR(250);
    lv_c        INT;
    lv_m        VARCHAR(250);
BEGIN
    -- V1.0 2026-10-17
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PORTERIA_SALIDA_REGISTRAR';
    "HV_ID_Registro_Acceso_Result" := 0;
    "HV_ID_Desviacion_Result" := 0;
    "HV_Resultado_Result" := NULL;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud_Persona" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
        SELECT COUNT(*), MAX(S."ID_Catalogo_Sede"), MAX(S."ID_Solicitud"), MAX(P."Trae_Equipos"), MAX(P."Trae_Herramientas"),
               MAX(P."Fecha_Hora_Ingreso"),
               MAX(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres")
          INTO lv_n, lv_sede, lv_sol, lv_trae_eq, lv_trae_h, lv_ingreso, lv_nombre
          FROM "CAF_Solicitud_Persona" P
          JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud" AND S."Eliminado" = 'N'
          JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
         WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND P."Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no figura en ninguna solicitud.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para registrar salidas en esta sede.'; RETURN;
        END IF;

        IF "HV_Fecha_Hora_Hecho" IS NOT NULL THEN
            lv_tardio := 'Y';
            lv_hecho  := "HV_Fecha_Hora_Hecho";
            IF lv_hecho > CURRENT_TIMESTAMP THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La hora indicada es futura.'; RETURN;
            END IF;
            IF lv_ingreso IS NOT NULL AND lv_hecho < lv_ingreso THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La salida no puede ser anterior al ingreso.'; RETURN;
            END IF;
            IF "HV_Observacion" IS NULL OR LENGTH(TRIM("HV_Observacion")) = 0 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Explique por qué el registro es tardío.'; RETURN;
            END IF;
        ELSE
            lv_hecho := CURRENT_TIMESTAMP;
        END IF;
        IF "HV_Observacion" IS NOT NULL AND LENGTH(TRIM("HV_Observacion")) > 1000 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La observación no puede superar 1000 caracteres.'; RETURN;
        END IF;

        SELECT R."Permitido", R."Codigo_Resp", R."Mensaje" INTO lv_perm, lv_cod_r, lv_msg_r
          FROM "ERP_CAF_PORTERIA_REGLA_MOVIMIENTO"("HV_ID_Solicitud_Persona", 'SALIDA', lv_tardio) R;
        IF lv_perm <> 'Y' THEN
            "HV_Codigo_Resp" := lv_cod_r; "HV_Mensaje" := lv_msg_r; RETURN;
        END IF;

        lv_lista  := ',' || REPLACE(UPPER(COALESCE("HV_Items", '')), ' ', '') || ',';
        lv_tokens := CASE WHEN LENGTH(REPLACE(lv_lista, ',', '')) = 0 THEN 0
                          ELSE LENGTH(lv_lista) - LENGTH(REPLACE(lv_lista, ',', '')) - 1 END;
        SELECT COUNT(*),
               SUM(CASE WHEN lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':Y,%'
                          OR lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':N,%' THEN 1 ELSE 0 END),
               SUM(CASE WHEN lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':N,%' THEN 1 ELSE 0 END)
          INTO lv_aplic, lv_cubre, lv_incumple
          FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"("HV_ID_Solicitud_Persona", 'SALIDA', lv_trae_eq, lv_trae_h) A;
        lv_cubre := COALESCE(lv_cubre, 0); lv_incumple := COALESCE(lv_incumple, 0);
        IF lv_aplic = 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No hay ítems de checklist de salida configurados para este tipo de acceso.'; RETURN;
        END IF;
        IF lv_cubre <> lv_aplic OR lv_tokens <> lv_aplic THEN
            "HV_Codigo_Resp" := 400;
            "HV_Mensaje" := 'Responda todos los ítems del checklist, ni más ni menos, con el formato id:Y o id:N.'; RETURN;
        END IF;

        IF lv_incumple = 0 THEN
            IF ("HV_Desv_Descripcion" IS NOT NULL AND LENGTH(TRIM("HV_Desv_Descripcion")) > 0) OR "HV_ID_Tratamiento" IS NOT NULL THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Todos los ítems cumplen: no corresponde registrar una desviación.'; RETURN;
            END IF;
            lv_res := 'SALE';
        ELSE
            IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_DESVIACION_REGISTRAR', lv_sede) <> 'Y' THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para registrar desviaciones en esta sede.'; RETURN;
            END IF;
            CALL "ERP_CAF_DESVIACION_VALIDAR"('SALIDA', "HV_Desv_Descripcion", "HV_ID_Coordinador", "HV_ID_Tratamiento",
                 "HV_Tratamiento_Detalle", "HV_Resultado_Elegido", lv_sede, lv_res, lv_c, lv_m);
            IF lv_c <> 100 THEN "HV_Codigo_Resp" := lv_c; "HV_Mensaje" := lv_m; RETURN; END IF;
        END IF;

        INSERT INTO "CAF_Registro_Acceso" ("ID_Solicitud_Persona","ID_Catalogo_Sede","Tipo_Movimiento","Resultado","Fecha_Hora",
                                           "Es_Registro_Tardio","ID_Usuario_Vigilante","Observacion","UsuarioID_Create")
        VALUES ("HV_ID_Solicitud_Persona", lv_sede, 'SALIDA', lv_res, lv_hecho, lv_tardio, "HV_UsuarioID",
                NULLIF(TRIM(COALESCE("HV_Observacion", '')), ''), "HV_UsuarioID")
        RETURNING "ID_Registro_Acceso" INTO lv_reg;

        INSERT INTO "CAF_Registro_Checklist" ("ID_Registro_Acceso","ID_Catalogo_Item_Checklist","Cumple","UsuarioID_Create")
        SELECT lv_reg, A."ID_Catalogo_Item_Checklist",
               CASE WHEN lv_lista LIKE '%,' || CAST(A."ID_Catalogo_Item_Checklist" AS VARCHAR) || ':Y,%' THEN 'Y' ELSE 'N' END,
               "HV_UsuarioID"
          FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"("HV_ID_Solicitud_Persona", 'SALIDA', lv_trae_eq, lv_trae_h) A;

        IF lv_incumple > 0 THEN
            CALL "ERP_CAF_DESVIACION_CREAR"(lv_reg, lv_sol, "HV_Desv_Descripcion", "HV_ID_Coordinador", "HV_ID_Tratamiento",
                 "HV_Tratamiento_Detalle", lv_res, "HV_UsuarioID", lv_des, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'desviacion: %', lv_m; END IF;
        END IF;

        UPDATE "CAF_Solicitud_Persona"
           SET "Estado" = 'SALIO', "Fecha_Hora_Salida" = lv_hecho,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";

        CALL "ERP_CAF_EVENTO_REGISTRAR"('REGISTRO_ACCESO', lv_reg, lv_sol, 'SALIDA',
             lv_nombre || ' · ' || lv_res || CASE WHEN lv_tardio = 'Y' THEN ' · registro tardío' ELSE '' END,
             "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_ID_Registro_Acceso_Result" := lv_reg;
        "HV_ID_Desviacion_Result" := lv_des;
        "HV_Resultado_Result" := lv_res;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje" := CASE lv_res WHEN 'SALE' THEN 'Salida registrada.' ELSE 'Salida registrada; se retiene el elemento.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_ID_Registro_Acceso_Result" := 0; "HV_ID_Desviacion_Result" := 0; "HV_Resultado_Result" := NULL;
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PORTERIA_SALIDA_REGISTRAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR
--    Cierre del día: las personas AUTORIZADAS que seguían como ESPERADA en visitas
--    anteriores a HV_Fecha_Corte (nulo = hoy) pasan a NO_SE_PRESENTO. Lo ejecuta el
--    proceso automático de la aplicación, con HV_UsuarioID = 0 (el sistema).
--    No toca visitas canceladas ni personas no autorizadas. Se puede repetir sin riesgo.
--    Sin cursores (HANA): recorre por identificador creciente.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(
    IN    "HV_Fecha_Corte"  DATE,
    IN    "HV_UsuarioID"    BIGINT,
    INOUT "HV_Cantidad_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp"  INT DEFAULT NULL,
    INOUT "HV_Mensaje"      VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_corte DATE := COALESCE("HV_Fecha_Corte", CURRENT_DATE);
    lv_id    BIGINT := 0;
    lv_sol   BIGINT;
    lv_nom   VARCHAR(400);
    lv_cant  BIGINT := 0;
    lv_c     INT;
    lv_m     VARCHAR(250);
BEGIN
    -- V1.0 2026-10-17
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR';
    "HV_Cantidad_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <> 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo el proceso automático (usuario 0) puede cerrar el día.'; RETURN;
        END IF;
        IF lv_corte > CURRENT_DATE THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La fecha de corte no puede ser futura.'; RETURN;
        END IF;

        LOOP
            SELECT MIN(P."ID_Solicitud_Persona") INTO lv_id
              FROM "CAF_Solicitud_Persona" P
              JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud" AND S."Eliminado" = 'N' AND S."Estado" <> 'CANCELADA'
             WHERE P."ID_Solicitud_Persona" > lv_id AND P."Eliminado" = 'N' AND P."Estado" = 'ESPERADA' AND P."Aprobacion" = 'APROBADA'
               AND CAST(S."Fecha_Hora_Prevista" AS DATE) < lv_corte;
            EXIT WHEN lv_id IS NULL;

            UPDATE "CAF_Solicitud_Persona"
               SET "Estado" = 'NO_SE_PRESENTO', "UsuarioID_Update" = 0, "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = lv_id;
            SELECT MAX(P."ID_Solicitud"), MAX(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres")
              INTO lv_sol, lv_nom
              FROM "CAF_Solicitud_Persona" P JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
             WHERE P."ID_Solicitud_Persona" = lv_id;
            CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', lv_id, lv_sol, 'NO_SE_PRESENTO', lv_nom, 0, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;
            lv_cant := lv_cant + 1;
        END LOOP;

        "HV_Cantidad_Result" := lv_cant;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN lv_cant = 0 THEN 'No había personas por marcar.'
                                 ELSE 'Se marcaron ' || CAST(lv_cant AS VARCHAR) || ' persona(s) como «no se presentó».' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Cantidad_Result" := 0;
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR';
    END;
END;
$$;
