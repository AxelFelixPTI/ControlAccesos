-- =============================================================================
-- Archivo : SP_CAF_SOLICITUD_BASE_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobación | Fase 1 - Procedimientos (piezas internas)
-- Versión : V1.0 2026-10-16
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO2_ESCRITURA.sql)
-- Requiere: scripts 01 a 10 y los SP del Hito 0 y 1.
-- =============================================================================
-- PIEZAS INTERNAS: las llaman los procedimientos de negocio; la aplicación no
-- las llama directo. Cargar ESTE archivo antes que los demás del Hito 2.
--
-- 1 ERP_CAF_FN_USUARIO_TIENE_PERMISO  ¿puede hacer esto en esta sede?   (Y/N)
-- 2 ERP_CAF_FN_USUARIO_TIENE_ROL      ¿tiene este rol en esta sede?     (Y/N)
-- 3 ERP_CAF_FN_COPIAS_VALIDAS         ¿la lista de correos es válida?   (Y/N)
-- 4 ERP_CAF_EVENTO_REGISTRAR          ÚNICO escritor de la bitácora (D-23)
-- 5 ERP_CAF_CORREO_ENCOLAR            deja un correo en la bandeja de salida (D-19)
-- 6 ERP_CAF_SOLICITUD_DESTINATARIOS   a quién avisar según el momento
-- 7 ERP_CAF_SOLICITUD_HEREDAR_PASOS   la persona nueva hereda pasos "por solicitud"
-- 8 ERP_CAF_SOLICITUD_RECALCULAR      aprobación de cada persona y estado de la solicitud
-- 9 ERP_CAF_SOLICITUD_VERSION_GUARDAR foto de lo aprobado (RN-08)
-- 10 ERP_CAF_SOLICITUD_COPIAS_GUARDAR   deja EXACTAMENTE esas copias de correo en la solicitud
--
-- REGLA CENTRAL (D-44): solo ERP_CAF_SOLICITUD_RECALCULAR escribe Aprobacion en
-- CAF_Solicitud_Persona y Estado en CAF_Solicitud. Dos lugares que calculan lo
-- mismo terminan contradiciéndose.
--
-- Las funciones escalares (1 a 3) existen para no repetir la misma consulta en
-- cada procedimiento. En HANA se escriben como funciones escalares SQLScript.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_FN_USUARIO_TIENE_PERMISO
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_USUARIO_TIENE_PERMISO"(
    "HV_ID_Usuario"       BIGINT,
    "HV_Codigo_Permiso"   VARCHAR,
    "HV_ID_Catalogo_Sede" BIGINT
)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-10-16
    SELECT COUNT(*) INTO lv_n
      FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
      JOIN "CAF_GOVERNANCE"."Usuario" U           ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
      JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
      JOIN "CAF_GOVERNANCE"."Licencia_Permiso" LP ON LP."ID_Catalogo_Licencia" = L."ID_Catalogo_Licencia" AND LP."Eliminado" = 'N'
      JOIN "CAF_GOVERNANCE"."Catalogo_Permiso" P  ON P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso" AND P."Eliminado" = 'N' AND P."Activo" = 'Y'
     WHERE UL."ID_Usuario" = "HV_ID_Usuario" AND UL."Eliminado" = 'N'
       AND UL."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND P."Codigo" = "HV_Codigo_Permiso";
    IF lv_n > 0 THEN RETURN 'Y'; END IF;
    RETURN 'N';
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_FN_USUARIO_TIENE_ROL  (para saber si le toca un paso de aprobación)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_USUARIO_TIENE_ROL"(
    "HV_ID_Usuario"          BIGINT,
    "HV_ID_Catalogo_Licencia" BIGINT,
    "HV_ID_Catalogo_Sede"    BIGINT
)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-10-16
    SELECT COUNT(*) INTO lv_n
      FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
      JOIN "CAF_GOVERNANCE"."Usuario" U           ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
      JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
     WHERE UL."ID_Usuario" = "HV_ID_Usuario" AND UL."Eliminado" = 'N'
       AND UL."ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia"
       AND UL."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede";
    IF lv_n > 0 THEN RETURN 'Y'; END IF;
    RETURN 'N';
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_FN_COPIAS_VALIDAS  (lista de correos separados por coma o punto y coma)
--    Vacío es válido: las copias son opcionales. HANA: LIKE_REGEXPR.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Copias" VARCHAR)
RETURNS CHAR(1)
LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE
    lv_x VARCHAR(2100);
BEGIN
    -- V1.0 2026-10-16
    lv_x := REPLACE(REPLACE(COALESCE("HV_Copias", ''), ' ', ''), ';', ',');
    IF LENGTH(lv_x) = 0 THEN RETURN 'Y'; END IF;
    IF LENGTH(lv_x) > 2000 THEN RETURN 'N'; END IF;
    IF lv_x ~ '^[^@,]+@[^@,.]+(\.[^@,.]+)+(,[^@,]+@[^@,.]+(\.[^@,.]+)+)*$' THEN RETURN 'Y'; END IF;
    RETURN 'N';
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_EVENTO_REGISTRAR  (D-23: ÚNICO escritor de la bitácora)
--    Valida la pareja Entidad + Acción contra una matriz. Para agregar una acción
--    en una etapa futura se modifica ESTA lista y nada más.
--    ID_Entidad: id de la fila afectada (la persona de la solicitud, el paso de
--    aprobación, el registro de acceso...). ID_Solicitud se repite siempre que
--    exista, para armar el historial de una solicitud sin cruces.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_EVENTO_REGISTRAR"(
    IN    "HV_Entidad"      VARCHAR(50),
    IN    "HV_ID_Entidad"   BIGINT,
    IN    "HV_ID_Solicitud" BIGINT,
    IN    "HV_Accion"       VARCHAR(50),
    IN    "HV_Detalle"      VARCHAR(2000),
    IN    "HV_UsuarioID"    BIGINT,
    INOUT "HV_Codigo_Resp"  INT DEFAULT NULL,
    INOUT "HV_Mensaje"      VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_matriz VARCHAR(2000) := '|SOLICITUD:CREAR|SOLICITUD:EDITAR|SOLICITUD:CANCELAR'
        || '|SOLICITUD_PERSONA:AGREGAR|SOLICITUD_PERSONA:AGREGAR_APROBADA|SOLICITUD_PERSONA:RETIRAR'
        || '|SOLICITUD_PERSONA:CORREGIR|SOLICITUD_PERSONA:REENVIAR|SOLICITUD_PERSONA:NO_SE_PRESENTO'
        || '|SOLICITUD_DECISION:APROBAR|SOLICITUD_DECISION:OBSERVAR|SOLICITUD_DECISION:RECHAZAR'
        || '|REGISTRO_ACCESO:INGRESO|REGISTRO_ACCESO:SALIDA|REGISTRO_ACCESO:DENEGAR'
        || '|DESVIACION:REGISTRAR|DESVIACION:CONFORMIDAD'
        || '|INCIDENCIA:REGISTRAR|INCIDENCIA:CONFIRMAR|INCIDENCIA:DESESTIMAR'
        || '|PERSONA_EXTERNA:CREAR|PERSONA_EXTERNA:CORREGIR_DATOS|';
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_EVENTO_REGISTRAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "HV_ID_Entidad" IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Falta el identificador de la entidad.'; RETURN;
        END IF;
        IF POSITION('|' || UPPER(TRIM(COALESCE("HV_Entidad",''))) || ':' || UPPER(TRIM(COALESCE("HV_Accion",''))) || '|' IN lv_matriz) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La combinación de entidad y acción no está permitida en la bitácora.'; RETURN;
        END IF;

        INSERT INTO "CAF_Evento" ("Entidad","ID_Entidad","ID_Solicitud","Accion","Detalle","ID_Usuario","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Entidad")), "HV_ID_Entidad", "HV_ID_Solicitud", UPPER(TRIM("HV_Accion")),
                LEFT("HV_Detalle", 2000), "HV_UsuarioID", "HV_UsuarioID");

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Evento registrado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_EVENTO_REGISTRAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_CORREO_ENCOLAR  (D-19: el SP de negocio solo INSERTA; otro proceso envía)
--    Sin destinatarios no es un error: simplemente no hay a quién avisar.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_CORREO_ENCOLAR"(
    IN    "HV_Tipo"          VARCHAR(50),
    IN    "HV_ID_Solicitud"  BIGINT,
    IN    "HV_Destinatarios" VARCHAR(2000),
    IN    "HV_Copia"         VARCHAR(2000),
    IN    "HV_Asunto"        VARCHAR(500),
    IN    "HV_Cuerpo"        VARCHAR(4000),
    IN    "HV_UsuarioID"     BIGINT,
    INOUT "HV_Codigo_Resp"   INT DEFAULT NULL,
    INOUT "HV_Mensaje"       VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_CORREO_ENCOLAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "HV_Destinatarios" IS NULL OR LENGTH(TRIM("HV_Destinatarios")) = 0 THEN
            "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Sin destinatarios: no se encoló ningún correo.'; RETURN;
        END IF;

        INSERT INTO "CAF_Correo_Pendiente" ("Tipo","ID_Solicitud","Destinatarios","Copia","Asunto","Cuerpo","UsuarioID_Create")
        VALUES ("HV_Tipo", "HV_ID_Solicitud", LEFT("HV_Destinatarios", 2000), NULLIF(LEFT("HV_Copia", 2000), ''),
                LEFT("HV_Asunto", 500), COALESCE("HV_Cuerpo", ''), "HV_UsuarioID");

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Correo encolado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_CORREO_ENCOLAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CAF_SOLICITUD_DESTINATARIOS
--    Modos (HV_Modo):
--      SOLICITANTE    el que creó la solicitud
--      COPIAS         los correos en copia de esa solicitud
--      PORTERIA       quienes registran ingresos y salidas en esa sede
--      APROBADORES    quienes deciden CUALQUIER paso del flujo
--      PRIMER_PASO    quienes deciden el primer paso del flujo
--      PASO_PENDIENTE quienes deciden el primer paso que aún le falta a la
--                     persona HV_Referencia (ID_Solicitud_Persona)
--      SIGUIENTE_PASO quienes deciden el paso que sigue después del orden HV_Referencia
--    Devuelve los correos separados por "; ".
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_DESTINATARIOS"(
    IN    "HV_ID_Solicitud"   BIGINT,
    IN    "HV_Modo"           VARCHAR(20),
    IN    "HV_Referencia"     BIGINT,
    INOUT "HV_Destinatarios"  VARCHAR(2000) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"    INT DEFAULT NULL,
    INOUT "HV_Mensaje"        VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_sede   BIGINT;
    lv_tipo   BIGINT;
    lv_solic  BIGINT;
    lv_orden  BIGINT;
    lv_n      INT := 0;
    lv_dest   VARCHAR(4000);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DESTINATARIOS';
    "HV_Destinatarios" := NULL;
    BEGIN
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("ID_Usuario_Solicitante")
          INTO lv_n, lv_sede, lv_tipo, lv_solic
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;

        IF "HV_Modo" = 'SOLICITANTE' THEN
            SELECT U."Correo" INTO lv_dest FROM "CAF_GOVERNANCE"."Usuario" U
             WHERE U."ID_Usuario" = lv_solic AND U."Eliminado" = 'N' AND U."Activo" = 'Y';

        ELSIF "HV_Modo" = 'COPIAS' THEN
            SELECT STRING_AGG(C."Correo", '; ' ORDER BY C."Correo") INTO lv_dest
              FROM "CAF_Solicitud_Copia_Correo" C
             WHERE C."ID_Solicitud" = "HV_ID_Solicitud" AND C."Eliminado" = 'N';

        ELSIF "HV_Modo" = 'PORTERIA' THEN
            SELECT STRING_AGG(X."Correo", '; ' ORDER BY X."Correo") INTO lv_dest
              FROM (SELECT DISTINCT U."Correo"
                      FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
                      JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
                      JOIN "CAF_GOVERNANCE"."Licencia_Permiso" LP ON LP."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND LP."Eliminado" = 'N'
                      JOIN "CAF_GOVERNANCE"."Catalogo_Permiso" P ON P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso" AND P."Codigo" = 'PER_CAF_PORTERIA_REGISTRAR'
                     WHERE UL."Eliminado" = 'N' AND UL."ID_Catalogo_Sede" = lv_sede) X;

        ELSE
            IF "HV_Modo" = 'PRIMER_PASO' THEN
                SELECT MIN(S."Orden") INTO lv_orden FROM "Tipo_Acceso_Paso_Aprobacion" S
                 WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y';
            ELSIF "HV_Modo" = 'PASO_PENDIENTE' THEN
                SELECT MIN(S."Orden") INTO lv_orden FROM "Tipo_Acceso_Paso_Aprobacion" S
                 WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
                   AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                                    WHERE D."ID_Solicitud_Persona" = "HV_Referencia"
                                      AND D."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                                      AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'APROBADA');
            ELSIF "HV_Modo" = 'SIGUIENTE_PASO' THEN
                SELECT MIN(S."Orden") INTO lv_orden FROM "Tipo_Acceso_Paso_Aprobacion" S
                 WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
                   AND S."Orden" > "HV_Referencia";
            ELSIF "HV_Modo" <> 'APROBADORES' THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Modo de destinatarios no reconocido.'; RETURN;
            END IF;

            IF "HV_Modo" = 'APROBADORES' OR lv_orden IS NOT NULL THEN
                SELECT STRING_AGG(X."Correo", '; ' ORDER BY X."Correo") INTO lv_dest
                  FROM (SELECT DISTINCT U."Correo"
                          FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
                          JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = UL."ID_Usuario" AND U."Eliminado" = 'N' AND U."Activo" = 'Y'
                          JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
                         WHERE UL."Eliminado" = 'N' AND UL."ID_Catalogo_Sede" = lv_sede
                           AND UL."ID_Catalogo_Licencia" IN (
                                 SELECT S."ID_Catalogo_Licencia" FROM "Tipo_Acceso_Paso_Aprobacion" S
                                  WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y'
                                    AND S."Obligatorio" = 'Y' AND S."ID_Catalogo_Licencia" IS NOT NULL
                                    AND ("HV_Modo" = 'APROBADORES' OR S."Orden" = lv_orden)
                                    -- Para una persona concreta, solo los pasos que AÚN le faltan:
                                    -- el área que ya aprobó su parte no necesita otro aviso
                                    AND ("HV_Modo" <> 'PASO_PENDIENTE'
                                         OR NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                                                         WHERE D."ID_Solicitud_Persona" = "HV_Referencia"
                                                           AND D."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                                                           AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'APROBADA')))) X;
            END IF;
        END IF;

        "HV_Destinatarios" := LEFT(lv_dest, 2000);
        "HV_Codigo_Resp"   := 100;
        "HV_Mensaje"       := 'Destinatarios calculados.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DESTINATARIOS';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 7. ERP_CAF_SOLICITUD_HEREDAR_PASOS
--    Los pasos de alcance SOLICITUD (por ejemplo "el área aprueba el servicio")
--    valen para toda la solicitud. Una persona que llega después los hereda y
--    solo le faltan los pasos que dependen de ella (prueba del segundo flujo).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_HEREDAR_PASOS"(
    IN    "HV_ID_Solicitud"         BIGINT,
    IN    "HV_ID_Solicitud_Persona" BIGINT,
    IN    "HV_UsuarioID"            BIGINT,
    INOUT "HV_Codigo_Resp"          INT DEFAULT NULL,
    INOUT "HV_Mensaje"              VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_HEREDAR_PASOS';
    BEGIN
        INSERT INTO "CAF_Solicitud_Decision"
               ("ID_Solicitud_Persona","ID_Tipo_Acceso_Paso_Aprobacion","Decision","Mensaje","ID_Usuario","Fecha_Decision","UsuarioID_Create")
        SELECT "HV_ID_Solicitud_Persona", S."ID_Tipo_Acceso_Paso_Aprobacion", 'APROBADA', 'Heredada de la solicitud',
               (SELECT D2."ID_Usuario" FROM "CAF_Solicitud_Decision" D2
                  JOIN "CAF_Solicitud_Persona" P2 ON P2."ID_Solicitud_Persona" = D2."ID_Solicitud_Persona"
                 WHERE P2."ID_Solicitud" = "HV_ID_Solicitud" AND P2."Eliminado" = 'N'
                   AND D2."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                   AND D2."Vigente" = 'Y' AND D2."Eliminado" = 'N' AND D2."Decision" = 'APROBADA'
                 ORDER BY D2."Fecha_Decision" DESC, D2."ID_Solicitud_Decision" DESC LIMIT 1),
               CURRENT_TIMESTAMP, "HV_UsuarioID"
          FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = (SELECT "ID_Catalogo_Tipo_Acceso" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud")
           AND S."Alcance" = 'SOLICITUD' AND S."Eliminado" = 'N' AND S."Activo" = 'Y'
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                            WHERE D."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona"
                              AND D."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                              AND D."Vigente" = 'Y' AND D."Eliminado" = 'N')
           AND EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D3
                         JOIN "CAF_Solicitud_Persona" P3 ON P3."ID_Solicitud_Persona" = D3."ID_Solicitud_Persona"
                        WHERE P3."ID_Solicitud" = "HV_ID_Solicitud" AND P3."Eliminado" = 'N'
                          AND D3."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                          AND D3."Vigente" = 'Y' AND D3."Eliminado" = 'N' AND D3."Decision" = 'APROBADA');

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Pasos heredados.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_HEREDAR_PASOS';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 8. ERP_CAF_SOLICITUD_RECALCULAR  (D-44: la ÚNICA que escribe estos resúmenes)
--
--    Aprobación de cada persona, con este orden de precedencia:
--      RECHAZADA  si algún paso obligatorio la rechazó
--      OBSERVADA  si algún paso obligatorio la observó
--      APROBADA   si TODOS los pasos obligatorios la aprobaron
--      PENDIENTE  en los demás casos
--    RETIRADA no se toca. Quien ya tiene movimientos en portería no se toca.
--    Si el tipo de acceso no requiere aprobación, todas quedan APROBADA.
--
--    Estado de la solicitud, calculado desde sus personas vigentes:
--      alguna aprobada y todas decididas ........ APROBADA
--      alguna aprobada y alguna por decidir ..... APROBADA_PARCIAL
--      ninguna aprobada y alguna pendiente ...... PENDIENTE
--      ninguna aprobada, alguna observada ....... OBSERVADA
--      todas rechazadas ......................... RECHAZADA
--    CANCELADA nunca se toca. Sin personas vigentes, el estado no cambia.
--
--    Se recalcula TODO desde las decisiones vigentes: es idempotente (llamarlo
--    dos veces da lo mismo) y no depende de en qué orden pasaron las cosas.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_RECALCULAR"(
    IN    "HV_ID_Solicitud"  BIGINT,
    IN    "HV_UsuarioID"     BIGINT,
    INOUT "HV_Estado_Result" VARCHAR(20) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"   INT DEFAULT NULL,
    INOUT "HV_Mensaje"       VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_existe   INT := 0;
    lv_tipo     BIGINT;
    lv_estado   VARCHAR(20);
    lv_requiere CHAR(1);
    lv_nreq     INT := 0;
    lv_apr      INT := 0;
    lv_pen      INT := 0;
    lv_obs      INT := 0;
    lv_rec      INT := 0;
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_RECALCULAR';
    BEGIN
        SELECT COUNT(*), MAX("ID_Catalogo_Tipo_Acceso"), MAX("Estado") INTO lv_existe, lv_tipo, lv_estado
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;

        SELECT "Requiere_Aprobacion" INTO lv_requiere FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo;
        SELECT COUNT(*) INTO lv_nreq FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y'
           AND S."Obligatorio" = 'Y' AND S."Condicion" = 'SIEMPRE';

        -- 1. Todas las personas vigentes y sin movimientos parten de PENDIENTE
        UPDATE "CAF_Solicitud_Persona"
           SET "Aprobacion" = 'PENDIENTE', "Aprobacion_Mensaje" = NULL, "ID_Usuario_Aprobacion" = NULL, "Fecha_Aprobacion" = NULL
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N'
           AND "Aprobacion" <> 'RETIRADA' AND "Estado" = 'ESPERADA';

        -- 2. APROBADA: todos los pasos obligatorios aprobados (o el flujo no requiere aprobación)
        UPDATE "CAF_Solicitud_Persona" SP
           SET "Aprobacion" = 'APROBADA'
         WHERE SP."ID_Solicitud" = "HV_ID_Solicitud" AND SP."Eliminado" = 'N'
           AND SP."Aprobacion" = 'PENDIENTE' AND SP."Estado" = 'ESPERADA'
           AND (lv_requiere = 'N'
                OR (lv_nreq > 0 AND (SELECT COUNT(DISTINCT S."ID_Tipo_Acceso_Paso_Aprobacion")
                                       FROM "CAF_Solicitud_Decision" D
                                       JOIN "Tipo_Acceso_Paso_Aprobacion" S ON S."ID_Tipo_Acceso_Paso_Aprobacion" = D."ID_Tipo_Acceso_Paso_Aprobacion"
                                      WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona"
                                        AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'APROBADA'
                                        AND S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y'
                                        AND S."Obligatorio" = 'Y' AND S."Condicion" = 'SIEMPRE') >= lv_nreq));

        -- 3. OBSERVADA (pisa a PENDIENTE y APROBADA); el mensaje sale de la decisión más reciente
        UPDATE "CAF_Solicitud_Persona" SP
           SET "Aprobacion" = 'OBSERVADA',
               "Aprobacion_Mensaje" = (SELECT D."Mensaje" FROM "CAF_Solicitud_Decision" D
                                         JOIN "Tipo_Acceso_Paso_Aprobacion" S ON S."ID_Tipo_Acceso_Paso_Aprobacion" = D."ID_Tipo_Acceso_Paso_Aprobacion"
                                        WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona"
                                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'OBSERVADA'
                                          AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
                                        ORDER BY D."Fecha_Decision" DESC, D."ID_Solicitud_Decision" DESC LIMIT 1)
         WHERE SP."ID_Solicitud" = "HV_ID_Solicitud" AND SP."Eliminado" = 'N'
           AND SP."Aprobacion" IN ('PENDIENTE','APROBADA') AND SP."Estado" = 'ESPERADA'
           AND EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                         JOIN "Tipo_Acceso_Paso_Aprobacion" S ON S."ID_Tipo_Acceso_Paso_Aprobacion" = D."ID_Tipo_Acceso_Paso_Aprobacion"
                        WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona"
                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'OBSERVADA'
                          AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y');

        -- 4. RECHAZADA (pisa a todas; es la decisión más fuerte)
        UPDATE "CAF_Solicitud_Persona" SP
           SET "Aprobacion" = 'RECHAZADA',
               "Aprobacion_Mensaje" = (SELECT D."Mensaje" FROM "CAF_Solicitud_Decision" D
                                         JOIN "Tipo_Acceso_Paso_Aprobacion" S ON S."ID_Tipo_Acceso_Paso_Aprobacion" = D."ID_Tipo_Acceso_Paso_Aprobacion"
                                        WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona"
                                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'RECHAZADA'
                                          AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
                                        ORDER BY D."Fecha_Decision" DESC, D."ID_Solicitud_Decision" DESC LIMIT 1)
         WHERE SP."ID_Solicitud" = "HV_ID_Solicitud" AND SP."Eliminado" = 'N'
           AND SP."Aprobacion" IN ('PENDIENTE','APROBADA','OBSERVADA') AND SP."Estado" = 'ESPERADA'
           AND EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                         JOIN "Tipo_Acceso_Paso_Aprobacion" S ON S."ID_Tipo_Acceso_Paso_Aprobacion" = D."ID_Tipo_Acceso_Paso_Aprobacion"
                        WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona"
                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N' AND D."Decision" = 'RECHAZADA'
                          AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y');

        -- 5. Quién y cuándo decidió por última vez, para quien ya tiene una decisión final
        UPDATE "CAF_Solicitud_Persona" SP
           SET "ID_Usuario_Aprobacion" = (SELECT D."ID_Usuario" FROM "CAF_Solicitud_Decision" D
                                           WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona" AND D."Vigente" = 'Y' AND D."Eliminado" = 'N'
                                           ORDER BY D."Fecha_Decision" DESC, D."ID_Solicitud_Decision" DESC LIMIT 1),
               "Fecha_Aprobacion"      = (SELECT D."Fecha_Decision" FROM "CAF_Solicitud_Decision" D
                                           WHERE D."ID_Solicitud_Persona" = SP."ID_Solicitud_Persona" AND D."Vigente" = 'Y' AND D."Eliminado" = 'N'
                                           ORDER BY D."Fecha_Decision" DESC, D."ID_Solicitud_Decision" DESC LIMIT 1)
         WHERE SP."ID_Solicitud" = "HV_ID_Solicitud" AND SP."Eliminado" = 'N'
           AND SP."Aprobacion" IN ('APROBADA','OBSERVADA','RECHAZADA') AND SP."Estado" = 'ESPERADA';

        -- 6. Estado de la solicitud
        SELECT COALESCE(SUM(CASE WHEN "Aprobacion" = 'APROBADA'  THEN 1 ELSE 0 END), 0),
               COALESCE(SUM(CASE WHEN "Aprobacion" = 'PENDIENTE' THEN 1 ELSE 0 END), 0),
               COALESCE(SUM(CASE WHEN "Aprobacion" = 'OBSERVADA' THEN 1 ELSE 0 END), 0),
               COALESCE(SUM(CASE WHEN "Aprobacion" = 'RECHAZADA' THEN 1 ELSE 0 END), 0)
          INTO lv_apr, lv_pen, lv_obs, lv_rec
          FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" <> 'RETIRADA';

        IF lv_estado <> 'CANCELADA' AND (lv_apr + lv_pen + lv_obs + lv_rec) > 0 THEN
            IF lv_apr > 0 THEN
                IF lv_pen + lv_obs > 0 THEN lv_estado := 'APROBADA_PARCIAL'; ELSE lv_estado := 'APROBADA'; END IF;
            ELSIF lv_pen > 0 THEN lv_estado := 'PENDIENTE';
            ELSIF lv_obs > 0 THEN lv_estado := 'OBSERVADA';
            ELSE lv_estado := 'RECHAZADA';
            END IF;
            UPDATE "CAF_Solicitud"
               SET "Estado" = lv_estado, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Estado" <> lv_estado;
        END IF;

        "HV_Estado_Result" := lv_estado;
        "HV_Codigo_Resp"   := 100;
        "HV_Mensaje"       := 'Aprobación recalculada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_RECALCULAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 9. ERP_CAF_SOLICITUD_VERSION_GUARDAR  (RN-08: saber QUÉ se aprobó y cuándo)
--    Deja una foto en JSON de la solicitud con sus personas y su aprobación.
--    Una fila por número de versión: dentro de la misma versión, cada nueva
--    decisión actualiza la foto. Sin personas aprobadas no guarda nada.
--    El JSON se arma como texto (HANA no tiene un constructor igual al de PostgreSQL).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_VERSION_GUARDAR"(
    IN    "HV_ID_Solicitud" BIGINT,
    IN    "HV_UsuarioID"    BIGINT,
    INOUT "HV_Codigo_Resp"  INT DEFAULT NULL,
    INOUT "HV_Mensaje"      VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n    INT := 0;
    lv_ver  BIGINT;
    lv_json TEXT;
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_VERSION_GUARDAR';
    BEGIN
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'APROBADA';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Sin personas aprobadas: no se guarda versión.'; RETURN;
        END IF;

        SELECT SO."Version",
               '{"codigo":"' || COALESCE(SO."Codigo",'') || '","version":' || SO."Version"
               || ',"fecha_hora":"' || TO_CHAR(SO."Fecha_Hora_Prevista", 'YYYY-MM-DD HH24:MI')
               || '","empresa":"' || REPLACE(REPLACE(SO."Empresa_Visitante", '\', '\\'), '"', '\"')
               || '","zonas":[' || COALESCE((SELECT STRING_AGG('"' || REPLACE(REPLACE(Z."Descripcion", '\', '\\'), '"', '\"') || '"', ',' ORDER BY Z."ID_Catalogo_Zona_Acceso")
                                               FROM "CAF_Solicitud_Zona" SZ
                                               JOIN "Catalogo_Zona_Acceso" Z ON Z."ID_Catalogo_Zona_Acceso" = SZ."ID_Catalogo_Zona_Acceso"
                                              WHERE SZ."ID_Solicitud" = SO."ID_Solicitud" AND SZ."Eliminado" = 'N'), '')
               || '],"personas":[' || COALESCE((SELECT STRING_AGG('{"documento":"' || PE."Numero_Documento"
                                                               || '","nombre":"' || REPLACE(REPLACE(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno",'') || ', ' || PE."Nombres", '\', '\\'), '"', '\"')
                                                               || '","aprobacion":"' || SP."Aprobacion" || '"}', ',' ORDER BY SP."ID_Solicitud_Persona")
                                                  FROM "CAF_Solicitud_Persona" SP
                                                  JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = SP."ID_Persona_Externa"
                                                 WHERE SP."ID_Solicitud" = SO."ID_Solicitud" AND SP."Eliminado" = 'N' AND SP."Aprobacion" <> 'RETIRADA'), '')
               || ']}'
          INTO lv_ver, lv_json
          FROM "CAF_Solicitud" SO WHERE SO."ID_Solicitud" = "HV_ID_Solicitud";

        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Version" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Version" = lv_ver;
        IF lv_n > 0 THEN
            UPDATE "CAF_Solicitud_Version"
               SET "Contenido_JSON" = lv_json, "ID_Usuario_Aprobador" = "HV_UsuarioID", "Fecha_Aprobacion" = CURRENT_TIMESTAMP,
                   "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Version" = lv_ver;
        ELSE
            INSERT INTO "CAF_Solicitud_Version" ("ID_Solicitud","Version","Contenido_JSON","ID_Usuario_Aprobador","Fecha_Aprobacion","UsuarioID_Create")
            VALUES ("HV_ID_Solicitud", lv_ver, lv_json, "HV_UsuarioID", CURRENT_TIMESTAMP, "HV_UsuarioID");
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Versión ' || lv_ver || ' guardada.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_VERSION_GUARDAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 10. ERP_CAF_SOLICITUD_COPIAS_GUARDAR
--     Deja la solicitud con EXACTAMENTE los correos en copia de la lista:
--     retira los que ya no vienen, reactiva los que estaban quitados y agrega
--     los nuevos. La lista se valida antes con ERP_CAF_FN_COPIAS_VALIDAS.
--     Un bucle simple recorre la lista: la lista tiene como máximo unos pocos
--     correos y HANA no admite cursores (ver equivalencias).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_COPIAS_GUARDAR"(
    IN    "HV_ID_Solicitud" BIGINT,
    IN    "HV_Copias"       VARCHAR(2000),
    IN    "HV_UsuarioID"    BIGINT,
    INOUT "HV_Codigo_Resp"  INT DEFAULT NULL,
    INOUT "HV_Mensaje"      VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_resto VARCHAR(2100);
    lv_item  VARCHAR(200);
    lv_pos   INT := 0;
    lv_n     INT := 0;
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_COPIAS_GUARDAR';
    BEGIN
        IF "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Copias") <> 'Y' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de correos en copia no es válida.'; RETURN;
        END IF;

        lv_resto := LOWER(REPLACE(REPLACE(COALESCE("HV_Copias", ''), ' ', ''), ';', ','));

        -- Se retiran todas; luego se reactivan o agregan las que vienen
        UPDATE "CAF_Solicitud_Copia_Correo"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';

        WHILE LENGTH(lv_resto) > 0 LOOP
            lv_pos := POSITION(',' IN lv_resto);
            IF lv_pos = 0 THEN
                lv_item  := lv_resto;
                lv_resto := '';
            ELSE
                lv_item  := SUBSTRING(lv_resto FROM 1 FOR lv_pos - 1);
                lv_resto := SUBSTRING(lv_resto FROM lv_pos + 1);
            END IF;

            SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Copia_Correo"
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND LOWER("Correo") = lv_item;
            IF lv_n > 0 THEN
                UPDATE "CAF_Solicitud_Copia_Correo"
                   SET "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND LOWER("Correo") = lv_item;
            ELSE
                INSERT INTO "CAF_Solicitud_Copia_Correo" ("ID_Solicitud","Correo","UsuarioID_Create")
                VALUES ("HV_ID_Solicitud", lv_item, "HV_UsuarioID");
            END IF;
        END LOOP;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Copias de correo guardadas.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_COPIAS_GUARDAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 7. ERP_CAF_FN_COPIA_CORREO  (V1.0 2026-10-24)
--    Arma la lista "Copia" de un aviso sumando los grupos pedidos ('Y'/'N'):
--    solicitante, aprobadores, portería y correos en copia de la solicitud.
--    Devuelve NULL si no hay nadie. Los repetidos se depuran al enviar (.NET).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_COPIA_CORREO"(
    "HV_ID_Solicitud" BIGINT,
    "HV_Solicitante"  CHAR(1),
    "HV_Aprobadores"  CHAR(1),
    "HV_Porteria"     CHAR(1),
    "HV_Copias"       CHAR(1)
) RETURNS VARCHAR(2000)
LANGUAGE plpgsql VOLATILE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_res VARCHAR(4000) := NULL;
    lv_x   VARCHAR(2000);
    lv_c   INT;
    lv_m   VARCHAR(250);
BEGIN
    IF "HV_Solicitante" = 'Y' THEN
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'SOLICITANTE', NULL, lv_x, lv_c, lv_m);
        IF lv_x IS NOT NULL THEN lv_res := CASE WHEN lv_res IS NULL THEN lv_x ELSE lv_res || '; ' || lv_x END; END IF;
    END IF;
    IF "HV_Aprobadores" = 'Y' THEN
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'APROBADORES', NULL, lv_x, lv_c, lv_m);
        IF lv_x IS NOT NULL THEN lv_res := CASE WHEN lv_res IS NULL THEN lv_x ELSE lv_res || '; ' || lv_x END; END IF;
    END IF;
    IF "HV_Porteria" = 'Y' THEN
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PORTERIA', NULL, lv_x, lv_c, lv_m);
        IF lv_x IS NOT NULL THEN lv_res := CASE WHEN lv_res IS NULL THEN lv_x ELSE lv_res || '; ' || lv_x END; END IF;
    END IF;
    IF "HV_Copias" = 'Y' THEN
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'COPIAS', NULL, lv_x, lv_c, lv_m);
        IF lv_x IS NOT NULL THEN lv_res := CASE WHEN lv_res IS NULL THEN lv_x ELSE lv_res || '; ' || lv_x END; END IF;
    END IF;
    RETURN NULLIF(LEFT(lv_res, 2000), '');
END;
$$;
