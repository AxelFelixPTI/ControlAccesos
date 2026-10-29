-- =============================================================================
-- Archivo : SP_CAF_CORREO_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 4 - Incidencias, reporte y correos | Fase 1 - Procedimientos (bandeja de correos)
-- Entidad : CAF_Correo_Pendiente
-- Versión : V1.0 2026-10-18
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO4_*.sql)
-- Requiere: scripts 01 a 10 y los SP de los Hitos 0 a 3 (ERP_CAF_CORREO_ENCOLAR ya existe, Hito 2).
-- =============================================================================
-- Quién escribe la cola: los SP de negocio (ERP_CAF_CORREO_ENCOLAR). Quién la vacía: el proceso
-- en segundo plano de la aplicación, que se identifica como el usuario del sistema (UsuarioID 0, D-12):
--   1 ERP_CAF_CORREO_PENDIENTES_LISTAR   (solo sistema) los correos por enviar, con cuerpo
--   2 ERP_CAF_CORREO_MARCAR_ENVIADO      (solo sistema)
--   3 ERP_CAF_CORREO_MARCAR_ERROR        (solo sistema) suma un intento; al llegar al máximo queda en ERROR
-- Y para el Administrador (PER_CAF_ADMIN_USUARIOS en la sede):
--   4 ERP_CAF_CORREO_LISTAR              revisar la bandeja (sin el cuerpo)
--   5 ERP_CAF_CORREO_REENCOLAR           devolver un correo en ERROR a PENDIENTE
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_CORREO_PENDIENTES_LISTAR
--    Los más antiguos primero. HV_Maximo: entre 1 y 100 (por defecto 20).
-- -----------------------------------------------------------------------------
-- V1.2 2026-10-29 (D-181): agrega "IDs_Personas" (las personas que autoriza un aviso a Vigilancia).
-- V1.1 2026-10-29 (D-180): agrega "Responder_A" y "Responder_A_Nombre" (quien realizó la acción) y por eso
-- se borra la función anterior (cambia el tipo de retorno). Solo los correos de una solicitud los llevan.
DROP FUNCTION IF EXISTS "ERP_CAF_CORREO_PENDIENTES_LISTAR"(BIGINT, INT);
CREATE OR REPLACE FUNCTION "ERP_CAF_CORREO_PENDIENTES_LISTAR"(
    "HV_UsuarioID" BIGINT,
    "HV_Maximo"    INT DEFAULT 20
)
RETURNS TABLE ("ID_Correo_Pendiente" BIGINT, "Tipo" VARCHAR, "ID_Solicitud" BIGINT, "Destinatarios" VARCHAR,
               "Copia" VARCHAR, "Asunto" VARCHAR, "Cuerpo" TEXT, "Intentos" BIGINT,
               "Responder_A" VARCHAR, "Responder_A_Nombre" VARCHAR, "IDs_Personas" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_max INT := COALESCE("HV_Maximo", 20);
BEGIN
    -- V1.1 2026-10-29
    IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <> 0 THEN RETURN; END IF;
    IF lv_max < 1 THEN lv_max := 1; END IF;
    IF lv_max > 100 THEN lv_max := 100; END IF;
    RETURN QUERY
    SELECT C."ID_Correo_Pendiente", C."Tipo", C."ID_Solicitud", C."Destinatarios", C."Copia", C."Asunto", C."Cuerpo", C."Intentos",
           CAST(U."Correo" AS VARCHAR),
           CAST(U."Nombres" || ' ' || U."Apellido_Paterno" AS VARCHAR),
           CAST(C."IDs_Personas" AS VARCHAR)
      FROM "CAF_Correo_Pendiente" C
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U
             ON U."ID_Usuario" = C."UsuarioID_Create" AND C."ID_Solicitud" IS NOT NULL AND C."UsuarioID_Create" > 0
     WHERE C."Eliminado" = 'N' AND C."Estado" = 'PENDIENTE'
     ORDER BY C."CreateDate", C."ID_Correo_Pendiente"
     LIMIT lv_max;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_CORREO_MARCAR_ENVIADO
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_CORREO_MARCAR_ENVIADO"(
    IN    "HV_ID_Correo_Pendiente" BIGINT,
    IN    "HV_UsuarioID"           BIGINT,
    INOUT "HV_Codigo_Resp"         INT DEFAULT NULL,
    INOUT "HV_Mensaje"             VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_estado VARCHAR(20);
BEGIN
    -- V1.0 2026-10-18
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_CORREO_MARCAR_ENVIADO';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <> 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo el proceso de envío puede marcar correos.'; RETURN;
        END IF;
        UPDATE "CAF_Correo_Pendiente" SET "UpdateDate" = "UpdateDate" WHERE "ID_Correo_Pendiente" = "HV_ID_Correo_Pendiente";
        SELECT COUNT(*), MAX("Estado") INTO lv_n, lv_estado
          FROM "CAF_Correo_Pendiente" WHERE "ID_Correo_Pendiente" = "HV_ID_Correo_Pendiente" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El correo no existe.'; RETURN;
        END IF;
        IF lv_estado <> 'PENDIENTE' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'El correo ya no está pendiente.'; RETURN;
        END IF;
        UPDATE "CAF_Correo_Pendiente"
           SET "Estado" = 'ENVIADO', "Fecha_Envio" = CURRENT_TIMESTAMP, "Intentos" = "Intentos" + 1, "Ultimo_Error" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Correo_Pendiente" = "HV_ID_Correo_Pendiente";
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Correo marcado como enviado.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_CORREO_MARCAR_ENVIADO';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_CORREO_MARCAR_ERROR
--    Suma un intento y guarda el error. Si los intentos llegan a HV_Max_Intentos
--    (1 a 20) el correo pasa a ERROR y deja de reintentarse; si no, sigue PENDIENTE.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_CORREO_MARCAR_ERROR"(
    IN    "HV_ID_Correo_Pendiente" BIGINT,
    IN    "HV_Error"               VARCHAR(1000),
    IN    "HV_Max_Intentos"        INT,
    IN    "HV_UsuarioID"           BIGINT,
    INOUT "HV_Estado_Result"       VARCHAR(20) DEFAULT NULL,
    INOUT "HV_Codigo_Resp"         INT DEFAULT NULL,
    INOUT "HV_Mensaje"             VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_estado VARCHAR(20);
    lv_int    BIGINT;
BEGIN
    -- V1.0 2026-10-18
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_CORREO_MARCAR_ERROR';
    "HV_Estado_Result" := NULL;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <> 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Solo el proceso de envío puede marcar correos.'; RETURN;
        END IF;
        IF "HV_Max_Intentos" IS NULL OR "HV_Max_Intentos" < 1 OR "HV_Max_Intentos" > 20 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El máximo de intentos debe estar entre 1 y 20.'; RETURN;
        END IF;
        UPDATE "CAF_Correo_Pendiente" SET "UpdateDate" = "UpdateDate" WHERE "ID_Correo_Pendiente" = "HV_ID_Correo_Pendiente";
        SELECT COUNT(*), MAX("Estado"), MAX("Intentos") INTO lv_n, lv_estado, lv_int
          FROM "CAF_Correo_Pendiente" WHERE "ID_Correo_Pendiente" = "HV_ID_Correo_Pendiente" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El correo no existe.'; RETURN;
        END IF;
        IF lv_estado <> 'PENDIENTE' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'El correo ya no está pendiente.'; RETURN;
        END IF;
        lv_int := lv_int + 1;
        "HV_Estado_Result" := CASE WHEN lv_int >= "HV_Max_Intentos" THEN 'ERROR' ELSE 'PENDIENTE' END;
        UPDATE "CAF_Correo_Pendiente"
           SET "Intentos" = lv_int, "Estado" = "HV_Estado_Result",
               "Ultimo_Error" = LEFT(COALESCE(NULLIF(TRIM(COALESCE("HV_Error", '')), ''), 'Error sin detalle'), 1000),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Correo_Pendiente" = "HV_ID_Correo_Pendiente";
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN "HV_Estado_Result" = 'ERROR' THEN 'Correo en ERROR: se agotaron los intentos.' ELSE 'Error registrado; se reintentará.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Estado_Result" := NULL;
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_CORREO_MARCAR_ERROR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_CORREO_LISTAR  (Administrador; no devuelve el cuerpo)
--    Muestra los correos de solicitudes de la sede y los que no pertenecen a ninguna
--    solicitud (p. ej. definir contraseña). HV_Estado: PENDIENTE, ENVIADO o ERROR.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_CORREO_LISTAR"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT,
    "HV_Estado"           VARCHAR DEFAULT NULL,
    "HV_Fecha_Desde"      DATE    DEFAULT NULL,
    "HV_Fecha_Hasta"      DATE    DEFAULT NULL
)
RETURNS TABLE ("ID_Correo_Pendiente" BIGINT, "Tipo" VARCHAR, "ID_Solicitud" BIGINT, "Codigo_Solicitud" VARCHAR,
               "Destinatarios" VARCHAR, "Asunto" VARCHAR, "Estado" VARCHAR, "Intentos" BIGINT,
               "Ultimo_Error" VARCHAR, "CreateDate" TIMESTAMP, "Fecha_Envio" TIMESTAMP)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_est VARCHAR(20) := UPPER(TRIM(COALESCE("HV_Estado", '')));
BEGIN
    -- V1.0 2026-10-18
    IF "HV_ID_Catalogo_Sede" IS NULL
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_ADMIN_USUARIOS', "HV_ID_Catalogo_Sede") <> 'Y' THEN
        RETURN;
    END IF;
    IF lv_est NOT IN ('', 'PENDIENTE', 'ENVIADO', 'ERROR') THEN RETURN; END IF;
    RETURN QUERY
    SELECT C."ID_Correo_Pendiente", C."Tipo", C."ID_Solicitud", S."Codigo", C."Destinatarios", C."Asunto", C."Estado",
           C."Intentos", C."Ultimo_Error", C."CreateDate", C."Fecha_Envio"
      FROM "CAF_Correo_Pendiente" C
      LEFT JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = C."ID_Solicitud"
     WHERE C."Eliminado" = 'N'
       AND (C."ID_Solicitud" IS NULL OR S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede")
       AND (lv_est = '' OR C."Estado" = lv_est)
       AND ("HV_Fecha_Desde" IS NULL OR CAST(C."CreateDate" AS DATE) >= "HV_Fecha_Desde")
       AND ("HV_Fecha_Hasta" IS NULL OR CAST(C."CreateDate" AS DATE) <= "HV_Fecha_Hasta")
     ORDER BY C."CreateDate" DESC, C."ID_Correo_Pendiente" DESC;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_CORREO_REENCOLAR  (Administrador)
--    Un correo en ERROR vuelve a PENDIENTE con los intentos en cero.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CAF_CORREO_REENCOLAR"(
    IN    "HV_ID_Correo_Pendiente" BIGINT,
    IN    "HV_ID_Catalogo_Sede"    BIGINT,
    IN    "HV_UsuarioID"           BIGINT,
    INOUT "HV_Codigo_Resp"         INT DEFAULT NULL,
    INOUT "HV_Mensaje"             VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_estado VARCHAR(20);
    lv_sede   BIGINT;
    lv_sol    BIGINT;
BEGIN
    -- V1.0 2026-10-18
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_CORREO_REENCOLAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "HV_ID_Catalogo_Sede" IS NULL
           OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_ADMIN_USUARIOS', "HV_ID_Catalogo_Sede") <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para administrar la bandeja de correos de esta sede.'; RETURN;
        END IF;
        UPDATE "CAF_Correo_Pendiente" SET "UpdateDate" = "UpdateDate" WHERE "ID_Correo_Pendiente" = "HV_ID_Correo_Pendiente";
        SELECT COUNT(*), MAX(C."Estado"), MAX(S."ID_Catalogo_Sede"), MAX(C."ID_Solicitud")
          INTO lv_n, lv_estado, lv_sede, lv_sol
          FROM "CAF_Correo_Pendiente" C
          LEFT JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = C."ID_Solicitud"
         WHERE C."ID_Correo_Pendiente" = "HV_ID_Correo_Pendiente" AND C."Eliminado" = 'N';
        IF lv_n = 0 OR (lv_sol IS NOT NULL AND lv_sede <> "HV_ID_Catalogo_Sede") THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El correo no existe.'; RETURN;
        END IF;
        IF lv_estado <> 'ERROR' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Solo se reencola un correo en ERROR.'; RETURN;
        END IF;
        UPDATE "CAF_Correo_Pendiente"
           SET "Estado" = 'PENDIENTE', "Intentos" = 0, "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Correo_Pendiente" = "HV_ID_Correo_Pendiente";
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Correo devuelto a la cola.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_CORREO_REENCOLAR';
    END;
END;
$$;
