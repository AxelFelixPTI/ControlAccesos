-- =============================================================================
-- Archivo : SP_CAF_SOLICITUD_LECTURA_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobación | Fase 1 - Procedimientos (lectura, parte 2)
-- Entidad : CAF_Solicitud y sus personas, pasos, historial y versiones
-- Versión : V1.0 2026-10-17
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO2_LECTURA.sql)
-- Requiere: scripts 01 a 10, los SP del Hito 0 y 1 y SP_CAF_SOLICITUD_BASE_ALL.sql.
-- =============================================================================
-- PIEZAS INTERNAS (las usan las de abajo; la aplicación no las llama):
--  1 ERP_CAF_FN_NORMALIZAR                    minúsculas y sin tildes, para buscar
--  2 ERP_CAF_FN_SOLICITUD_VISIBLE             ¿este usuario puede ver esta solicitud? (Y/N)
--  3 ERP_CAF_SOLICITUD_INDICADORES            conteos, avance y qué botones corresponden
--  4 ERP_CAF_SOLICITUD_PASOS_DECIDIBLES       qué personas y pasos puede decidir ahora este usuario
--
-- PARA LA APLICACIÓN:
--  5 ERP_CAF_SOLICITUD_MIS_LISTAR             «Mis solicitudes» del solicitante
--  6 ERP_CAF_SOLICITUD_BANDEJA_LISTAR         bandeja de quien aprueba: «Por decidir» o «Todas»
--  7 ERP_CAF_SOLICITUD_CONTADORES             los números de las insignias del menú
--  8 ERP_CAF_SOLICITUD_DETALLE                cabecera completa de una solicitud
--  9 ERP_CAF_SOLICITUD_PERSONAS_LISTAR        personas de la solicitud, con sus botones
-- 10 ERP_CAF_SOLICITUD_PASOS_LISTAR           ruta de aprobación: cada persona en cada paso
-- 11 ERP_CAF_SOLICITUD_HISTORIAL_LISTAR       bitácora de la solicitud
-- 12 ERP_CAF_SOLICITUD_VERSION_LISTAR         fotos de lo aprobado (RN-08)
-- 13 ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR      personas autorizadas de un día, para portería
-- 14 ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR  «aparece, pero no está autorizada»
--
-- REGLAS DE ESTE ARCHIVO
--  * Son LECTURAS: devuelven filas, no llevan HV_Codigo_Resp. Si el usuario no
--    tiene permiso sobre lo pedido, devuelven CERO FILAS (no revelan que existe).
--    La aplicación lo muestra como «no existe o no tiene acceso».
--  * Quién puede ver qué: el solicitante ve lo suyo (PER_CAF_SOLICITUD_PROPIA);
--    quien tiene PER_CAF_SOLICITUD_VER_TODAS ve todo en su sede; quien aprueba
--    (PER_CAF_SOLICITUD_APROBAR) ve las solicitudes cuyo flujo tiene un paso de su rol.
--    Portería ve solo a las personas AUTORIZADAS de un día, por sede (PER_CAF_PORTERIA_*).
--  * Los botones («Puede_...») salen de aquí y de ningún otro lugar: repiten, en
--    una sola consulta, las reglas que ya hacen cumplir los procedimientos de
--    escritura (D-56). Si una regla cambia, se cambia aquí y en el SP de escritura.
--    Cuando el botón no corresponde, trae el MOTIVO para mostrarlo al usuario.
--  * Las listas largas (zonas, copias) salen como texto separado por comas (D-47).
--  * Sin paginación en el servidor: la pantalla pagina y filtra con la tabla (HANA
--    no admite LIMIT/OFFSET con expresión). Si el volumen lo pide, se agrega después.
--  * El avance de una visita (POR_INICIAR, EN_CURSO, FINALIZADA, NO_SE_PRESENTO) se
--    CALCULA cada vez; no se guarda (D-44).
--
-- HANA: cada función RETURNS TABLE pasa a procedimiento con un parámetro de salida
-- de tipo tabla (ver EQUIVALENCIAS, sección 3-ter). ERP_CAF_FN_NORMALIZAR se
-- reescribe con REPLACE anidados (HANA no tiene TRANSLATE).
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_FN_NORMALIZAR
--    Para que buscar «jose» encuentre «José». Se aplica a ambos lados.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_NORMALIZAR"("HV_Texto" VARCHAR)
RETURNS VARCHAR
LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    -- V1.0 2026-10-17
    RETURN LOWER(TRANSLATE(COALESCE("HV_Texto", ''), 'ÁÉÍÓÚÜÑáéíóúüñ', 'AEIOUUNaeiouun'));
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_FN_SOLICITUD_VISIBLE
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_SOLICITUD_VISIBLE"("HV_ID_Usuario" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS CHAR(1)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n     INT := 0;
    lv_sede  BIGINT;
    lv_tipo  BIGINT;
    lv_owner BIGINT;
BEGIN
    -- V1.0 2026-10-17
    SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("ID_Usuario_Solicitante")
      INTO lv_n, lv_sede, lv_tipo, lv_owner
      FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
    IF lv_n = 0 OR "HV_ID_Usuario" IS NULL THEN RETURN 'N'; END IF;

    IF lv_owner = "HV_ID_Usuario"
       AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_ID_Usuario", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) = 'Y' THEN
        RETURN 'Y';
    END IF;
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_ID_Usuario", 'PER_CAF_SOLICITUD_VER_TODAS', lv_sede) = 'Y' THEN
        RETURN 'Y';
    END IF;
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_ID_Usuario", 'PER_CAF_SOLICITUD_APROBAR', lv_sede) = 'Y' THEN
        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y'
           AND S."ID_Catalogo_Licencia" IS NOT NULL
           AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_ID_Usuario", S."ID_Catalogo_Licencia", lv_sede) = 'Y';
        IF lv_n > 0 THEN RETURN 'Y'; END IF;
    END IF;
    RETURN 'N';
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_SOLICITUD_INDICADORES
--    HV_ID_Solicitud NULL = todas las solicitudes (lo usan los listados).
--    Es la ÚNICA consulta que sabe contar personas, calcular el avance y decidir
--    qué botones corresponden por el estado de la solicitud (D-56). No mira quién
--    pregunta: eso lo suma cada procedimiento que la usa (un botón solo se
--    ofrece al dueño de la solicitud).
--    Las reglas repiten las de ERP_CAF_SOLICITUD_EDITAR_DATOS, _CANCELAR y
--    ERP_CAF_SOLICITUD_PERSONA_*.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_INDICADORES"("HV_ID_Solicitud" BIGINT DEFAULT NULL)
RETURNS TABLE ("ID_Solicitud" BIGINT, "Total_Personas" INT, "Autorizadas" INT, "Observadas" INT,
               "Pendientes" INT, "Rechazadas" INT, "Retiradas" INT, "Con_Movimientos" INT,
               "Avance" VARCHAR, "Editar_Datos" CHAR(1), "Motivo_Editar_Datos" VARCHAR,
               "Modificar_Personal" CHAR(1), "Motivo_Modificar_Personal" VARCHAR,
               "Cancelar" CHAR(1), "Motivo_Cancelar" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-17
    RETURN QUERY
    WITH PC AS (
        SELECT P."ID_Solicitud" AS id_sol,
               CAST(SUM(CASE WHEN P."Aprobacion" <> 'RETIRADA' THEN 1 ELSE 0 END) AS INT) AS total,
               CAST(SUM(CASE WHEN P."Aprobacion" = 'APROBADA'  THEN 1 ELSE 0 END) AS INT) AS aut,
               CAST(SUM(CASE WHEN P."Aprobacion" = 'OBSERVADA' THEN 1 ELSE 0 END) AS INT) AS obs,
               CAST(SUM(CASE WHEN P."Aprobacion" = 'PENDIENTE' THEN 1 ELSE 0 END) AS INT) AS pen,
               CAST(SUM(CASE WHEN P."Aprobacion" = 'RECHAZADA' THEN 1 ELSE 0 END) AS INT) AS rec,
               CAST(SUM(CASE WHEN P."Aprobacion" = 'RETIRADA'  THEN 1 ELSE 0 END) AS INT) AS ret,
               CAST(SUM(CASE WHEN P."Estado" <> 'ESPERADA' THEN 1 ELSE 0 END) AS INT) AS mov,
               CAST(SUM(CASE WHEN P."Aprobacion" = 'APROBADA' AND P."Estado" = 'NO_SE_PRESENTO' THEN 1 ELSE 0 END) AS INT) AS nsp,
               CAST(SUM(CASE WHEN P."Aprobacion" = 'APROBADA' AND P."Estado" IN ('SALIO','DENEGADA','NO_SE_PRESENTO') THEN 1 ELSE 0 END) AS INT) AS fin,
               CAST(SUM(CASE WHEN P."Aprobacion" = 'APROBADA' AND P."Estado" <> 'ESPERADA' THEN 1 ELSE 0 END) AS INT) AS alguno
          FROM "CAF_Solicitud_Persona" P
         WHERE P."Eliminado" = 'N' AND ("HV_ID_Solicitud" IS NULL OR P."ID_Solicitud" = "HV_ID_Solicitud")
         GROUP BY P."ID_Solicitud"
    )
    SELECT S."ID_Solicitud",
           COALESCE(PC.total, 0), COALESCE(PC.aut, 0), COALESCE(PC.obs, 0),
           COALESCE(PC.pen, 0), COALESCE(PC.rec, 0), COALESCE(PC.ret, 0), COALESCE(PC.mov, 0),
           CAST(CASE WHEN S."Estado" IN ('APROBADA','APROBADA_PARCIAL') AND COALESCE(PC.aut, 0) > 0 THEN
                  CASE WHEN PC.nsp = PC.aut THEN 'NO_SE_PRESENTO'
                       WHEN PC.fin = PC.aut THEN 'FINALIZADA'
                       WHEN PC.alguno > 0   THEN 'EN_CURSO'
                       ELSE 'POR_INICIAR' END
                END AS VARCHAR),
           -- Editar los datos de la visita
           CAST(CASE WHEN S."Estado" IN ('CANCELADA','RECHAZADA') OR CAST(S."Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE
                          OR COALESCE(PC.mov, 0) > 0 THEN 'N' ELSE 'Y' END AS CHAR(1)),
           CAST(CASE WHEN S."Estado" = 'CANCELADA' THEN 'La solicitud está cancelada.'
                     WHEN S."Estado" = 'RECHAZADA' THEN 'Todas las personas fueron rechazadas. Use «Reutilizar» para crear una solicitud nueva.'
                     WHEN CAST(S."Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE THEN 'La fecha de la visita ya pasó. Use «Reutilizar».'
                     WHEN COALESCE(PC.mov, 0) > 0 THEN 'Ya ingresó una persona: los datos de la visita no se cambian. Puede modificar el personal.'
                END AS VARCHAR),
           -- Agregar, retirar o corregir personas
           CAST(CASE WHEN S."Estado" = 'CANCELADA' OR CAST(S."Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE THEN 'N' ELSE 'Y' END AS CHAR(1)),
           CAST(CASE WHEN S."Estado" = 'CANCELADA' THEN 'La solicitud está cancelada.'
                     WHEN CAST(S."Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE THEN 'La fecha de la visita ya pasó.'
                END AS VARCHAR),
           -- Cancelar la solicitud
           CAST(CASE WHEN S."Estado" = 'CANCELADA' OR CAST(S."Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE
                          OR COALESCE(PC.mov, 0) > 0 THEN 'N' ELSE 'Y' END AS CHAR(1)),
           CAST(CASE WHEN S."Estado" = 'CANCELADA' THEN 'La solicitud ya está cancelada.'
                     WHEN CAST(S."Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE THEN 'La fecha de la visita ya pasó.'
                     WHEN COALESCE(PC.mov, 0) > 0 THEN 'Ya ingresó una persona: no se puede cancelar. Retire a quienes faltan.'
                END AS VARCHAR)
      FROM "CAF_Solicitud" S
      LEFT JOIN PC ON PC.id_sol = S."ID_Solicitud"
     WHERE S."Eliminado" = 'N' AND ("HV_ID_Solicitud" IS NULL OR S."ID_Solicitud" = "HV_ID_Solicitud");
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_SOLICITUD_PASOS_DECIDIBLES
--    Todas las parejas (persona, paso) que este usuario puede decidir AHORA.
--    Repite las condiciones de ERP_CAF_SOLICITUD_DECIDIR:
--      * permiso de aprobar en la sede y el rol al que le toca el paso
--      * persona pendiente, sin ingreso; solicitud no cancelada y de hoy en adelante
--      * sin decisión vigente en ese paso
--      * todos los pasos obligatorios anteriores ya aprobados para esa persona
--    HV_ID_Solicitud NULL = de todas las solicitudes.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"("HV_ID_Usuario" BIGINT, "HV_ID_Solicitud" BIGINT DEFAULT NULL)
RETURNS TABLE ("ID_Solicitud" BIGINT, "ID_Solicitud_Persona" BIGINT, "ID_Tipo_Acceso_Paso_Aprobacion" BIGINT,
               "Paso_Codigo" VARCHAR, "Paso_Descripcion" VARCHAR, "Paso_Orden" BIGINT, "Paso_Alcance" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-17
    RETURN QUERY
    SELECT S."ID_Solicitud", P."ID_Solicitud_Persona", PA."ID_Tipo_Acceso_Paso_Aprobacion",
           PA."Codigo", PA."Descripcion", PA."Orden", PA."Alcance"
      FROM "CAF_Solicitud" S
      JOIN "CAF_Solicitud_Persona" P
        ON P."ID_Solicitud" = S."ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'PENDIENTE' AND P."Estado" = 'ESPERADA'
      JOIN "Tipo_Acceso_Paso_Aprobacion" PA
        ON PA."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND PA."Eliminado" = 'N' AND PA."Activo" = 'Y'
       AND PA."Obligatorio" = 'Y' AND PA."ID_Catalogo_Licencia" IS NOT NULL
     WHERE S."Eliminado" = 'N' AND S."Estado" <> 'CANCELADA' AND CAST(S."Fecha_Hora_Prevista" AS DATE) >= CURRENT_DATE
       AND ("HV_ID_Solicitud" IS NULL OR S."ID_Solicitud" = "HV_ID_Solicitud")
       AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_ID_Usuario", 'PER_CAF_SOLICITUD_APROBAR', S."ID_Catalogo_Sede") = 'Y'
       AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_ID_Usuario", PA."ID_Catalogo_Licencia", S."ID_Catalogo_Sede") = 'Y'
       AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                        WHERE D."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                          AND D."ID_Tipo_Acceso_Paso_Aprobacion" = PA."ID_Tipo_Acceso_Paso_Aprobacion"
                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N')
       AND NOT EXISTS (SELECT 1 FROM "Tipo_Acceso_Paso_Aprobacion" L
                        WHERE L."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
                          AND L."Obligatorio" = 'Y' AND L."Orden" < PA."Orden"
                          AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D2
                                           WHERE D2."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                                             AND D2."ID_Tipo_Acceso_Paso_Aprobacion" = L."ID_Tipo_Acceso_Paso_Aprobacion"
                                             AND D2."Vigente" = 'Y' AND D2."Eliminado" = 'N' AND D2."Decision" = 'APROBADA'));
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_SOLICITUD_MIS_LISTAR  («Mis solicitudes»)
--    Solo las del propio usuario, en las sedes donde tiene PER_CAF_SOLICITUD_PROPIA.
--    HV_Texto busca en código, empresa y en las personas (nombre o documento).
--    HV_Estado: PENDIENTE, OBSERVADA, APROBADA, APROBADA_PARCIAL, RECHAZADA o CANCELADA.
--    Fechas: sobre la fecha de la visita. Todos los filtros son opcionales (NULL).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_MIS_LISTAR"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT  DEFAULT NULL,
    "HV_Texto"            VARCHAR DEFAULT NULL,
    "HV_Estado"           VARCHAR DEFAULT NULL,
    "HV_Fecha_Desde"      DATE    DEFAULT NULL,
    "HV_Fecha_Hasta"      DATE    DEFAULT NULL
)
RETURNS TABLE ("ID_Solicitud" BIGINT, "Codigo" VARCHAR, "ID_Catalogo_Sede" BIGINT, "Sede" VARCHAR,
               "ID_Catalogo_Tipo_Acceso" BIGINT, "Tipo_Acceso" VARCHAR, "Fecha_Hora_Prevista" TIMESTAMP,
               "Empresa_Visitante" VARCHAR, "Estado" VARCHAR, "Avance" VARCHAR,
               "Total_Personas" INT, "Autorizadas" INT, "Observadas" INT, "Pendientes" INT, "Rechazadas" INT, "Retiradas" INT,
               "Responsable_Nombre" VARCHAR, "Codigo_Origen" VARCHAR, "Fecha_Envio" TIMESTAMP, "CreateDate" TIMESTAMP,
               "Puede_Editar_Datos" CHAR(1), "Motivo_No_Editar_Datos" VARCHAR,
               "Puede_Modificar_Personal" CHAR(1), "Motivo_No_Modificar_Personal" VARCHAR,
               "Puede_Cancelar" CHAR(1), "Motivo_No_Cancelar" VARCHAR, "Puede_Reutilizar" CHAR(1))
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_txt VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Texto", '')));
BEGIN
    -- V1.0 2026-10-17
    RETURN QUERY
    SELECT S."ID_Solicitud", S."Codigo", S."ID_Catalogo_Sede", SE."Descripcion",
           S."ID_Catalogo_Tipo_Acceso", TA."Descripcion", S."Fecha_Hora_Prevista",
           S."Empresa_Visitante", S."Estado", I."Avance",
           I."Total_Personas", I."Autorizadas", I."Observadas", I."Pendientes", I."Rechazadas", I."Retiradas",
           CAST(R."Apellido_Paterno" || COALESCE(' ' || R."Apellido_Materno", '') || ', ' || R."Nombres" AS VARCHAR),
           O."Codigo", S."Fecha_Envio", S."CreateDate",
           I."Editar_Datos", I."Motivo_Editar_Datos", I."Modificar_Personal", I."Motivo_Modificar_Personal",
           I."Cancelar", I."Motivo_Cancelar", CAST('Y' AS CHAR(1))
      FROM "CAF_Solicitud" S
      JOIN "ERP_CAF_SOLICITUD_INDICADORES"(NULL) I ON I."ID_Solicitud" = S."ID_Solicitud"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Sede" SE ON SE."ID_Catalogo_Sede" = S."ID_Catalogo_Sede"
      LEFT JOIN "Catalogo_Tipo_Acceso" TA ON TA."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso"
      LEFT JOIN "CAF_GOVERNANCE"."Personal" R ON R."ID_Personal" = S."ID_Personal_Responsable"
      LEFT JOIN "CAF_Solicitud" O ON O."ID_Solicitud" = S."ID_Solicitud_Origen"
     WHERE S."Eliminado" = 'N' AND S."ID_Usuario_Solicitante" = "HV_UsuarioID"
       AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', S."ID_Catalogo_Sede") = 'Y'
       AND ("HV_ID_Catalogo_Sede" IS NULL OR S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede")
       AND ("HV_Estado" IS NULL OR LENGTH(TRIM("HV_Estado")) = 0 OR S."Estado" = UPPER(TRIM("HV_Estado")))
       AND ("HV_Fecha_Desde" IS NULL OR CAST(S."Fecha_Hora_Prevista" AS DATE) >= "HV_Fecha_Desde")
       AND ("HV_Fecha_Hasta" IS NULL OR CAST(S."Fecha_Hora_Prevista" AS DATE) <= "HV_Fecha_Hasta")
       AND (LENGTH(lv_txt) = 0
            OR "ERP_CAF_FN_NORMALIZAR"(S."Codigo") LIKE '%' || lv_txt || '%'
            OR "ERP_CAF_FN_NORMALIZAR"(S."Empresa_Visitante") LIKE '%' || lv_txt || '%'
            OR EXISTS (SELECT 1 FROM "CAF_Solicitud_Persona" P
                         JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
                        WHERE P."ID_Solicitud" = S."ID_Solicitud" AND P."Eliminado" = 'N'
                          AND ("ERP_CAF_FN_NORMALIZAR"(PE."Apellido_Paterno" || ' ' || COALESCE(PE."Apellido_Materno", '') || ' ' || PE."Nombres") LIKE '%' || lv_txt || '%'
                               OR LOWER(PE."Numero_Documento") LIKE '%' || lv_txt || '%')))
     ORDER BY S."CreateDate" DESC, S."ID_Solicitud" DESC;
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(2);

-- -----------------------------------------------------------------------------
-- 6. ERP_CAF_SOLICITUD_BANDEJA_LISTAR  (quien aprueba)
--    HV_Pestana:
--      POR_DECIDIR  solicitudes con personas que ESTE usuario puede decidir ahora
--                   (necesita PER_CAF_SOLICITUD_APROBAR y el rol del paso); por fecha de visita
--      TODAS        todas las solicitudes de la sede (necesita PER_CAF_SOLICITUD_VER_TODAS);
--                   las más recientes primero. NULL equivale a TODAS.
--    Filtros opcionales: empresa, solicitante, persona (nombre o documento), fecha de
--    visita exacta y estado.
--    Por_Decidir_Mis = personas que este usuario puede decidir ahora en esa solicitud.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT  DEFAULT NULL,
    "HV_Pestana"          VARCHAR DEFAULT 'TODAS',
    "HV_Empresa"          VARCHAR DEFAULT NULL,
    "HV_Solicitante"      VARCHAR DEFAULT NULL,
    "HV_Persona"          VARCHAR DEFAULT NULL,
    "HV_Fecha"            DATE    DEFAULT NULL,
    "HV_Estado"           VARCHAR DEFAULT NULL
)
RETURNS TABLE ("ID_Solicitud" BIGINT, "Codigo" VARCHAR, "ID_Catalogo_Sede" BIGINT, "Sede" VARCHAR,
               "Tipo_Acceso" VARCHAR, "Fecha_Hora_Prevista" TIMESTAMP, "Es_Hoy" CHAR(1),
               "Empresa_Visitante" VARCHAR, "ID_Usuario_Solicitante" BIGINT, "Solicitante_Nombre" VARCHAR,
               "Estado" VARCHAR, "Avance" VARCHAR,
               "Total_Personas" INT, "Autorizadas" INT, "Observadas" INT, "Pendientes" INT, "Rechazadas" INT, "Retiradas" INT,
               "Por_Decidir_Mis" INT, "Personas_Nombres" VARCHAR, "Fecha_Envio" TIMESTAMP)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_pest VARCHAR(20)  := UPPER(TRIM(COALESCE("HV_Pestana", 'TODAS')));
    lv_emp  VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Empresa", '')));
    lv_sol  VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Solicitante", '')));
    lv_per  VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Persona", '')));
BEGIN
    -- V1.0 2026-10-17
    IF lv_pest NOT IN ('POR_DECIDIR', 'TODAS') THEN RETURN; END IF;
    RETURN QUERY
    SELECT S."ID_Solicitud", S."Codigo", S."ID_Catalogo_Sede", SE."Descripcion",
           TA."Descripcion", S."Fecha_Hora_Prevista",
           CAST(CASE WHEN CAST(S."Fecha_Hora_Prevista" AS DATE) = CURRENT_DATE THEN 'Y' ELSE 'N' END AS CHAR(1)),
           S."Empresa_Visitante", S."ID_Usuario_Solicitante",
           CAST(CASE WHEN U."ID_Usuario" IS NULL THEN NULL
                     ELSE U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" END AS VARCHAR),
           S."Estado", I."Avance",
           I."Total_Personas", I."Autorizadas", I."Observadas", I."Pendientes", I."Rechazadas", I."Retiradas",
           CAST(COALESCE(D.n, 0) AS INT),
           CAST(LEFT((SELECT STRING_AGG(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres",
                                        ' | ' ORDER BY P."ID_Solicitud_Persona")
                        FROM "CAF_Solicitud_Persona" P
                        JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
                       WHERE P."ID_Solicitud" = S."ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" <> 'RETIRADA'), 1000) AS VARCHAR),
           S."Fecha_Envio"
      FROM "CAF_Solicitud" S
      JOIN "ERP_CAF_SOLICITUD_INDICADORES"(NULL) I ON I."ID_Solicitud" = S."ID_Solicitud"
      LEFT JOIN (SELECT X."ID_Solicitud" AS id_sol, COUNT(DISTINCT X."ID_Solicitud_Persona") AS n
                   FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"("HV_UsuarioID", NULL) X
                  GROUP BY X."ID_Solicitud") D ON D.id_sol = S."ID_Solicitud"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Sede" SE ON SE."ID_Catalogo_Sede" = S."ID_Catalogo_Sede"
      LEFT JOIN "Catalogo_Tipo_Acceso" TA ON TA."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = S."ID_Usuario_Solicitante"
     WHERE S."Eliminado" = 'N'
       AND ("HV_ID_Catalogo_Sede" IS NULL OR S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede")
       AND ((lv_pest = 'POR_DECIDIR' AND D.n IS NOT NULL)
            OR (lv_pest = 'TODAS' AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_VER_TODAS', S."ID_Catalogo_Sede") = 'Y'))
       AND ("HV_Estado" IS NULL OR LENGTH(TRIM("HV_Estado")) = 0 OR S."Estado" = UPPER(TRIM("HV_Estado")))
       AND ("HV_Fecha" IS NULL OR CAST(S."Fecha_Hora_Prevista" AS DATE) = "HV_Fecha")
       AND (LENGTH(lv_emp) = 0 OR "ERP_CAF_FN_NORMALIZAR"(S."Empresa_Visitante") LIKE '%' || lv_emp || '%')
       AND (LENGTH(lv_sol) = 0 OR "ERP_CAF_FN_NORMALIZAR"(U."Apellido_Paterno" || ' ' || COALESCE(U."Apellido_Materno", '') || ' ' || U."Nombres") LIKE '%' || lv_sol || '%')
       AND (LENGTH(lv_per) = 0
            OR EXISTS (SELECT 1 FROM "CAF_Solicitud_Persona" P
                         JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
                        WHERE P."ID_Solicitud" = S."ID_Solicitud" AND P."Eliminado" = 'N'
                          AND ("ERP_CAF_FN_NORMALIZAR"(PE."Apellido_Paterno" || ' ' || COALESCE(PE."Apellido_Materno", '') || ' ' || PE."Nombres") LIKE '%' || lv_per || '%'
                               OR LOWER(PE."Numero_Documento") LIKE '%' || lv_per || '%')))
     ORDER BY CASE WHEN lv_pest = 'POR_DECIDIR' THEN S."Fecha_Hora_Prevista" END ASC,
              CASE WHEN lv_pest = 'POR_DECIDIR' THEN S."ID_Solicitud" END ASC,
              S."Fecha_Hora_Prevista" DESC, S."ID_Solicitud" DESC;
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(3, NULL, 'POR_DECIDIR');

-- -----------------------------------------------------------------------------
-- 7. ERP_CAF_SOLICITUD_CONTADORES  (insignias del menú; una sola fila)
--    Mis_Con_Observadas : solicitudes del usuario con alguna persona observada
--    Por_Decidir_Solicitudes / Por_Decidir_Personas : lo que puede decidir ahora
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_CONTADORES"("HV_UsuarioID" BIGINT, "HV_ID_Catalogo_Sede" BIGINT DEFAULT NULL)
RETURNS TABLE ("Mis_Con_Observadas" INT, "Por_Decidir_Solicitudes" INT, "Por_Decidir_Personas" INT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_obs INT := 0;
    lv_sol INT := 0;
    lv_per INT := 0;
BEGIN
    -- V1.0 2026-10-17
    SELECT CAST(COUNT(*) AS INT) INTO lv_obs
      FROM "CAF_Solicitud" S
     WHERE S."Eliminado" = 'N' AND S."ID_Usuario_Solicitante" = "HV_UsuarioID" AND S."Estado" <> 'CANCELADA'
       AND ("HV_ID_Catalogo_Sede" IS NULL OR S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede")
       AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', S."ID_Catalogo_Sede") = 'Y'
       AND EXISTS (SELECT 1 FROM "CAF_Solicitud_Persona" P
                    WHERE P."ID_Solicitud" = S."ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'OBSERVADA');

    SELECT CAST(COUNT(DISTINCT X."ID_Solicitud") AS INT), CAST(COUNT(DISTINCT X."ID_Solicitud_Persona") AS INT) INTO lv_sol, lv_per
      FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"("HV_UsuarioID", NULL) X
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = X."ID_Solicitud"
     WHERE ("HV_ID_Catalogo_Sede" IS NULL OR S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede");

    RETURN QUERY SELECT lv_obs, lv_sol, lv_per;
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SOLICITUD_CONTADORES"(3);

-- -----------------------------------------------------------------------------
-- 8. ERP_CAF_SOLICITUD_DETALLE
--    Una fila con todo lo de la cabecera. Vacío si no existe o no puede verla.
--    Es_Propia = 'Y' solo si es el solicitante dueño: los botones de editar, cancelar,
--    modificar personal y reutilizar se ofrecen únicamente a él.
--    Puede_Decidir / Por_Decidir_Mis: lo que este usuario puede decidir ahora.
-- -----------------------------------------------------------------------------
-- Entrega H: la consulta devuelve columnas nuevas, por eso se retira antes (HANA: DROP FUNCTION IF EXISTS).
DROP FUNCTION IF EXISTS "ERP_CAF_SOLICITUD_DETALLE"(BIGINT, BIGINT);
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_DETALLE"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Solicitud" BIGINT, "Codigo" VARCHAR, "ID_Catalogo_Sede" BIGINT, "Sede" VARCHAR,
               "ID_Catalogo_Tipo_Acceso" BIGINT, "Tipo_Acceso" VARCHAR, "Fecha_Hora_Prevista" TIMESTAMP,
               "Empresa_Visitante" VARCHAR,
               "ID_Personal_Responsable" BIGINT, "Responsable_Nombre" VARCHAR, "Responsable_Correo" VARCHAR, "Responsable_Area" VARCHAR,
               "ID_Catalogo_Motivo_Visita" BIGINT, "Motivo" VARCHAR, "Motivo_Detalle" VARCHAR, "Observaciones" VARCHAR,
               "Exige_SCTR" CHAR(1), "Exige_EPP" CHAR(1),
               "Estado" VARCHAR, "Avance" VARCHAR, "Version" BIGINT, "Fecha_Envio" TIMESTAMP,
               "ID_Usuario_Solicitante" BIGINT, "Solicitante_Nombre" VARCHAR, "Solicitante_Correo" VARCHAR,
               "Fecha_Decision" TIMESTAMP, "Usuario_Decision_Nombre" VARCHAR, "Observacion_Coordinador" VARCHAR,
               "Motivo_Cancelacion" VARCHAR, "ID_Solicitud_Origen" BIGINT, "Codigo_Origen" VARCHAR,
               "Zonas_IDs" VARCHAR, "Zonas_Nombres" VARCHAR, "Copias" VARCHAR, "CreateDate" TIMESTAMP,
               "Total_Personas" INT, "Autorizadas" INT, "Observadas" INT, "Pendientes" INT, "Rechazadas" INT, "Retiradas" INT,
               "Es_Propia" CHAR(1),
               "Puede_Editar_Datos" CHAR(1), "Motivo_No_Editar_Datos" VARCHAR,
               "Puede_Modificar_Personal" CHAR(1), "Motivo_No_Modificar_Personal" VARCHAR,
               "Puede_Cancelar" CHAR(1), "Motivo_No_Cancelar" VARCHAR, "Puede_Reutilizar" CHAR(1),
               "Puede_Decidir" CHAR(1), "Por_Decidir_Mis" INT,
               "Tipo_Acceso_Codigo" VARCHAR, "Requiere_Cochera" CHAR(1), "Placa_Vehiculo" VARCHAR, "Area_Detalle" VARCHAR,
               "Contacto_Nombre" VARCHAR, "Contacto_Telefonos" VARCHAR, "Contacto_Correos" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_dec INT := 0;
BEGIN
    -- V1.1 2026-10-29 (Entrega H: tipo de ingreso, cochera y datos del contratista)
    IF "ERP_CAF_FN_SOLICITUD_VISIBLE"("HV_UsuarioID", "HV_ID_Solicitud") <> 'Y' THEN RETURN; END IF;
    SELECT CAST(COUNT(DISTINCT X."ID_Solicitud_Persona") AS INT) INTO lv_dec
      FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"("HV_UsuarioID", "HV_ID_Solicitud") X;

    RETURN QUERY
    SELECT S."ID_Solicitud", S."Codigo", S."ID_Catalogo_Sede", SE."Descripcion",
           S."ID_Catalogo_Tipo_Acceso", TA."Descripcion", S."Fecha_Hora_Prevista",
           S."Empresa_Visitante",
           S."ID_Personal_Responsable",
           CAST(R."Apellido_Paterno" || COALESCE(' ' || R."Apellido_Materno", '') || ', ' || R."Nombres" AS VARCHAR),
           R."Correo", AR."Descripcion",
           S."ID_Catalogo_Motivo_Visita", MV."Descripcion", S."Motivo_Detalle", S."Observaciones",
           S."Exige_SCTR", S."Exige_EPP",
           S."Estado", I."Avance", S."Version", S."Fecha_Envio",
           S."ID_Usuario_Solicitante",
           CAST(US."Apellido_Paterno" || COALESCE(' ' || US."Apellido_Materno", '') || ', ' || US."Nombres" AS VARCHAR),
           US."Correo",
           S."Fecha_Decision",
           CAST(CASE WHEN S."ID_Usuario_Decision" IS NULL THEN NULL
                     WHEN S."ID_Usuario_Decision" = 0 THEN 'Sistema'
                     ELSE UD."Apellido_Paterno" || COALESCE(' ' || UD."Apellido_Materno", '') || ', ' || UD."Nombres" END AS VARCHAR),
           S."Observacion_Coordinador",
           S."Motivo_Cancelacion", S."ID_Solicitud_Origen", O."Codigo",
           CAST((SELECT STRING_AGG(CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR), ',' ORDER BY ZA."Orden", ZA."ID_Catalogo_Zona_Acceso")
                   FROM "CAF_Solicitud_Zona" Z
                   JOIN "Catalogo_Zona_Acceso" ZA ON ZA."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso"
                  WHERE Z."ID_Solicitud" = S."ID_Solicitud" AND Z."Eliminado" = 'N') AS VARCHAR),
           CAST((SELECT STRING_AGG(ZA."Descripcion", ', ' ORDER BY ZA."Orden", ZA."ID_Catalogo_Zona_Acceso")
                   FROM "CAF_Solicitud_Zona" Z
                   JOIN "Catalogo_Zona_Acceso" ZA ON ZA."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso"
                  WHERE Z."ID_Solicitud" = S."ID_Solicitud" AND Z."Eliminado" = 'N') AS VARCHAR),
           CAST((SELECT STRING_AGG(C."Correo", '; ' ORDER BY C."Correo")
                   FROM "CAF_Solicitud_Copia_Correo" C
                  WHERE C."ID_Solicitud" = S."ID_Solicitud" AND C."Eliminado" = 'N') AS VARCHAR),
           S."CreateDate",
           I."Total_Personas", I."Autorizadas", I."Observadas", I."Pendientes", I."Rechazadas", I."Retiradas",
           CAST(CASE WHEN S."ID_Usuario_Solicitante" = "HV_UsuarioID"
                      AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', S."ID_Catalogo_Sede") = 'Y'
                     THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN S."ID_Usuario_Solicitante" = "HV_UsuarioID"
                      AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', S."ID_Catalogo_Sede") = 'Y'
                     THEN I."Editar_Datos" ELSE 'N' END AS CHAR(1)),
           CASE WHEN S."ID_Usuario_Solicitante" = "HV_UsuarioID" THEN I."Motivo_Editar_Datos" END,
           CAST(CASE WHEN S."ID_Usuario_Solicitante" = "HV_UsuarioID"
                      AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', S."ID_Catalogo_Sede") = 'Y'
                     THEN I."Modificar_Personal" ELSE 'N' END AS CHAR(1)),
           CASE WHEN S."ID_Usuario_Solicitante" = "HV_UsuarioID" THEN I."Motivo_Modificar_Personal" END,
           CAST(CASE WHEN S."ID_Usuario_Solicitante" = "HV_UsuarioID"
                      AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', S."ID_Catalogo_Sede") = 'Y'
                     THEN I."Cancelar" ELSE 'N' END AS CHAR(1)),
           CASE WHEN S."ID_Usuario_Solicitante" = "HV_UsuarioID" THEN I."Motivo_Cancelar" END,
           CAST(CASE WHEN S."ID_Usuario_Solicitante" = "HV_UsuarioID"
                      AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', S."ID_Catalogo_Sede") = 'Y'
                     THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN lv_dec > 0 THEN 'Y' ELSE 'N' END AS CHAR(1)), lv_dec,
           TA."Codigo", S."Requiere_Cochera", S."Placa_Vehiculo", S."Area_Detalle",
           S."Contacto_Nombre", S."Contacto_Telefonos", S."Contacto_Correos"
      FROM "CAF_Solicitud" S
      JOIN "ERP_CAF_SOLICITUD_INDICADORES"("HV_ID_Solicitud") I ON I."ID_Solicitud" = S."ID_Solicitud"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Sede" SE ON SE."ID_Catalogo_Sede" = S."ID_Catalogo_Sede"
      LEFT JOIN "Catalogo_Tipo_Acceso" TA ON TA."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso"
      LEFT JOIN "CAF_GOVERNANCE"."Personal" R ON R."ID_Personal" = S."ID_Personal_Responsable"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Area" AR ON AR."ID_Catalogo_Area" = R."ID_Catalogo_Area"
      LEFT JOIN "Catalogo_Motivo_Visita" MV ON MV."ID_Catalogo_Motivo_Visita" = S."ID_Catalogo_Motivo_Visita"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" US ON US."ID_Usuario" = S."ID_Usuario_Solicitante"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" UD ON UD."ID_Usuario" = S."ID_Usuario_Decision"
      LEFT JOIN "CAF_Solicitud" O ON O."ID_Solicitud" = S."ID_Solicitud_Origen"
     WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SOLICITUD_DETALLE"(2, 1);

-- -----------------------------------------------------------------------------
-- 9. ERP_CAF_SOLICITUD_PERSONAS_LISTAR
--    Todas las personas de la solicitud, también las retiradas (se pueden volver
--    a agregar). Cada fila trae los botones que le corresponden al usuario:
--      Puede_Retirar    ... dueño, aún sin ingreso, no rechazada, y no es la última persona
--      Puede_Corregir   ... dueño, pendiente u observada (la aprobada no se edita)
--      Puede_Reactivar  ... dueño, persona retirada
--      Puede_Decidir    ... quien aprueba, si hay un paso que ahora le toca
--    Pasos_Mis_Decidir = identificadores de los pasos que puede decidir, en texto con comas.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Solicitud_Persona" BIGINT, "ID_Persona_Externa" BIGINT, "ID_Catalogo_Tipo_Documento" BIGINT,
               "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR,
               "Apellido_Paterno" VARCHAR, "Apellido_Materno" VARCHAR, "Nombres" VARCHAR, "Nombre_Completo" VARCHAR,
               "Aprobacion" VARCHAR, "Aprobacion_Mensaje" VARCHAR, "Aprobado_Por_Nombre" VARCHAR, "Fecha_Aprobacion" TIMESTAMP,
               "Origen" VARCHAR, "Estado" VARCHAR, "Acceso_Restringido" CHAR(1), "Trae_Equipos" CHAR(1), "Trae_Herramientas" CHAR(1),
               "Fecha_Hora_Ingreso" TIMESTAMP, "Fecha_Hora_Salida" TIMESTAMP,
               "Puede_Retirar" CHAR(1), "Puede_Corregir" CHAR(1), "Puede_Reactivar" CHAR(1),
               "Puede_Decidir" CHAR(1), "Pasos_Mis_Decidir" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_owner CHAR(1) := 'N';
BEGIN
    -- V1.0 2026-10-17
    IF "ERP_CAF_FN_SOLICITUD_VISIBLE"("HV_UsuarioID", "HV_ID_Solicitud") <> 'Y' THEN RETURN; END IF;
    SELECT CASE WHEN S."ID_Usuario_Solicitante" = "HV_UsuarioID"
                 AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', S."ID_Catalogo_Sede") = 'Y'
                THEN 'Y' ELSE 'N' END
      INTO lv_owner FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = "HV_ID_Solicitud";

    RETURN QUERY
    SELECT P."ID_Solicitud_Persona", P."ID_Persona_Externa", PE."ID_Catalogo_Tipo_Documento",
           TD."Codigo", PE."Numero_Documento",
           PE."Apellido_Paterno", PE."Apellido_Materno", PE."Nombres",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           P."Aprobacion", P."Aprobacion_Mensaje",
           CAST(CASE WHEN P."ID_Usuario_Aprobacion" IS NULL THEN NULL
                     WHEN P."ID_Usuario_Aprobacion" = 0 THEN 'Sistema'
                     ELSE UA."Apellido_Paterno" || COALESCE(' ' || UA."Apellido_Materno", '') || ', ' || UA."Nombres" END AS VARCHAR),
           P."Fecha_Aprobacion",
           P."Origen", P."Estado", P."Acceso_Restringido", P."Trae_Equipos", P."Trae_Herramientas",
           P."Fecha_Hora_Ingreso", P."Fecha_Hora_Salida",
           CAST(CASE WHEN lv_owner = 'Y' AND I."Modificar_Personal" = 'Y' AND P."Estado" = 'ESPERADA'
                          AND P."Aprobacion" NOT IN ('RETIRADA','RECHAZADA') AND I."Total_Personas" > 1
                     THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN lv_owner = 'Y' AND I."Modificar_Personal" = 'Y' AND P."Estado" = 'ESPERADA'
                          AND P."Aprobacion" IN ('PENDIENTE','OBSERVADA')
                     THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN lv_owner = 'Y' AND I."Modificar_Personal" = 'Y' AND P."Aprobacion" = 'RETIRADA'
                     THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN EXISTS (SELECT 1 FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"("HV_UsuarioID", "HV_ID_Solicitud") X
                                   WHERE X."ID_Solicitud_Persona" = P."ID_Solicitud_Persona")
                     THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST((SELECT STRING_AGG(CAST(X."ID_Tipo_Acceso_Paso_Aprobacion" AS VARCHAR), ',' ORDER BY X."Paso_Orden", X."ID_Tipo_Acceso_Paso_Aprobacion")
                   FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"("HV_UsuarioID", "HV_ID_Solicitud") X
                  WHERE X."ID_Solicitud_Persona" = P."ID_Solicitud_Persona") AS VARCHAR)
      FROM "CAF_Solicitud_Persona" P
      JOIN "ERP_CAF_SOLICITUD_INDICADORES"("HV_ID_Solicitud") I ON I."ID_Solicitud" = P."ID_Solicitud"
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = PE."ID_Catalogo_Tipo_Documento"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" UA ON UA."ID_Usuario" = P."ID_Usuario_Aprobacion"
     WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N'
     ORDER BY P."ID_Solicitud_Persona";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(2, 1);

-- -----------------------------------------------------------------------------
-- 10. ERP_CAF_SOLICITUD_PASOS_LISTAR  (ruta de aprobación)
--     Una fila por persona (no retirada) y paso activo del flujo. Decision vale
--     PENDIENTE mientras nadie decidió ese paso para esa persona. Es_Mi_Turno = 'Y'
--     cuando este usuario puede decidirlo ahora.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_PASOS_LISTAR"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Solicitud_Persona" BIGINT, "Persona_Nombre" VARCHAR,
               "ID_Tipo_Acceso_Paso_Aprobacion" BIGINT, "Paso_Orden" BIGINT, "Paso_Codigo" VARCHAR, "Paso_Descripcion" VARCHAR,
               "Paso_Alcance" VARCHAR, "Obligatorio" CHAR(1), "Rol_Aprobador" VARCHAR,
               "Decision" VARCHAR, "Mensaje" VARCHAR, "Decidio_Nombre" VARCHAR, "Fecha_Decision" TIMESTAMP,
               "Es_Mi_Turno" CHAR(1))
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-17
    IF "ERP_CAF_FN_SOLICITUD_VISIBLE"("HV_UsuarioID", "HV_ID_Solicitud") <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT P."ID_Solicitud_Persona",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           PA."ID_Tipo_Acceso_Paso_Aprobacion", PA."Orden", PA."Codigo", PA."Descripcion", PA."Alcance", PA."Obligatorio",
           L."Descripcion",
           CAST(COALESCE(D."Decision", 'PENDIENTE') AS VARCHAR), D."Mensaje",
           CAST(CASE WHEN D."ID_Solicitud_Decision" IS NULL THEN NULL
                     WHEN D."ID_Usuario" = 0 THEN 'Sistema'
                     ELSE UD."Apellido_Paterno" || COALESCE(' ' || UD."Apellido_Materno", '') || ', ' || UD."Nombres" END AS VARCHAR),
           D."Fecha_Decision",
           CAST(CASE WHEN EXISTS (SELECT 1 FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"("HV_UsuarioID", "HV_ID_Solicitud") X
                                   WHERE X."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                                     AND X."ID_Tipo_Acceso_Paso_Aprobacion" = PA."ID_Tipo_Acceso_Paso_Aprobacion")
                     THEN 'Y' ELSE 'N' END AS CHAR(1))
      FROM "CAF_Solicitud" S
      JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud" = S."ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" <> 'RETIRADA'
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      JOIN "Tipo_Acceso_Paso_Aprobacion" PA ON PA."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND PA."Eliminado" = 'N' AND PA."Activo" = 'Y'
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = PA."ID_Catalogo_Licencia"
      LEFT JOIN "CAF_Solicitud_Decision" D ON D."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                 AND D."ID_Tipo_Acceso_Paso_Aprobacion" = PA."ID_Tipo_Acceso_Paso_Aprobacion" AND D."Vigente" = 'Y' AND D."Eliminado" = 'N'
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" UD ON UD."ID_Usuario" = D."ID_Usuario"
     WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N'
     ORDER BY P."ID_Solicitud_Persona", PA."Orden", PA."ID_Tipo_Acceso_Paso_Aprobacion";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(3, 1);

-- -----------------------------------------------------------------------------
-- 11. ERP_CAF_SOLICITUD_HISTORIAL_LISTAR
--     Bitácora de la solicitud, lo más reciente primero. Accion_Texto es la frase
--     para mostrar; Entidad y Accion se devuelven por si la pantalla filtra.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Evento" BIGINT, "Fecha_Evento" TIMESTAMP, "Entidad" VARCHAR, "Accion" VARCHAR,
               "Accion_Texto" VARCHAR, "Detalle" VARCHAR, "ID_Usuario" BIGINT, "Usuario_Nombre" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-17
    IF "ERP_CAF_FN_SOLICITUD_VISIBLE"("HV_UsuarioID", "HV_ID_Solicitud") <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT E."ID_Evento", E."Fecha_Evento", E."Entidad", E."Accion",
           CAST(CASE E."Entidad" || ':' || E."Accion"
                WHEN 'SOLICITUD:CREAR'                      THEN 'Creó y envió la solicitud'
                WHEN 'SOLICITUD:EDITAR'                     THEN 'Editó los datos de la solicitud'
                WHEN 'SOLICITUD:CANCELAR'                   THEN 'Canceló la solicitud'
                WHEN 'SOLICITUD:ADJUNTO_AGREGAR'            THEN 'Adjuntó un documento'
                WHEN 'SOLICITUD:ADJUNTO_QUITAR'             THEN 'Retiró un documento'
                WHEN 'SOLICITUD_PERSONA:AGREGAR'            THEN 'Agregó a una persona'
                WHEN 'SOLICITUD_PERSONA:AGREGAR_APROBADA'   THEN 'Agregó a una persona ya aprobada'
                WHEN 'SOLICITUD_PERSONA:RETIRAR'            THEN 'Retiró a una persona'
                WHEN 'SOLICITUD_PERSONA:AGREGAR_EMERGENCIA' THEN 'Agregó a una persona (corrección de emergencia)'
                WHEN 'SOLICITUD_PERSONA:RETIRAR_EMERGENCIA' THEN 'Retiró a una persona (corrección de emergencia)'
                WHEN 'SOLICITUD_PERSONA:CORREGIR'           THEN 'Corrigió los datos de una persona'
                WHEN 'SOLICITUD_PERSONA:REENVIAR'           THEN 'Reenvió a una persona a aprobación'
                WHEN 'SOLICITUD_PERSONA:NO_SE_PRESENTO'     THEN 'Marcó que una persona no se presentó'
                WHEN 'SOLICITUD_DECISION:APROBAR'           THEN 'Aprobó'
                WHEN 'SOLICITUD_DECISION:OBSERVAR'          THEN 'Observó'
                WHEN 'SOLICITUD_DECISION:RECHAZAR'          THEN 'Rechazó'
                WHEN 'REGISTRO_ACCESO:INGRESO'              THEN 'Registró un ingreso'
                WHEN 'REGISTRO_ACCESO:SALIDA'               THEN 'Registró una salida'
                WHEN 'REGISTRO_ACCESO:DENEGAR'              THEN 'Denegó el ingreso'
                WHEN 'DESVIACION:REGISTRAR'                 THEN 'Registró una desviación'
                WHEN 'DESVIACION:CONFORMIDAD'               THEN 'Dio conformidad a una desviación'
                WHEN 'INCIDENCIA:REGISTRAR'                 THEN 'Registró una incidencia'
                WHEN 'INCIDENCIA:CONFIRMAR'                 THEN 'Confirmó una incidencia'
                WHEN 'INCIDENCIA:DESESTIMAR'                THEN 'Desestimó una incidencia'
                ELSE E."Accion" END AS VARCHAR),
           E."Detalle", E."ID_Usuario",
           CAST(CASE WHEN E."ID_Usuario" = 0 THEN 'Sistema'
                     ELSE U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" END AS VARCHAR)
      FROM "CAF_Evento" E
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = E."ID_Usuario"
     WHERE E."ID_Solicitud" = "HV_ID_Solicitud"
     ORDER BY E."Fecha_Evento" DESC, E."ID_Evento" DESC;
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(2, 1);

-- -----------------------------------------------------------------------------
-- 12. ERP_CAF_SOLICITUD_VERSION_LISTAR  (RN-08)
--     Las fotos de lo aprobado, una por versión. Contenido_JSON es la solicitud
--     completa tal como se aprobó. HANA: NCLOB.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_VERSION_LISTAR"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("Version" BIGINT, "Fecha_Aprobacion" TIMESTAMP, "ID_Usuario_Aprobador" BIGINT,
               "Aprobador_Nombre" VARCHAR, "Contenido_JSON" TEXT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-17
    IF "ERP_CAF_FN_SOLICITUD_VISIBLE"("HV_UsuarioID", "HV_ID_Solicitud") <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT V."Version", V."Fecha_Aprobacion", V."ID_Usuario_Aprobador",
           CAST(CASE WHEN V."ID_Usuario_Aprobador" IS NULL THEN NULL
                     WHEN V."ID_Usuario_Aprobador" = 0 THEN 'Sistema'
                     ELSE U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" END AS VARCHAR),
           V."Contenido_JSON"
      FROM "CAF_Solicitud_Version" V
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = V."ID_Usuario_Aprobador"
     WHERE V."ID_Solicitud" = "HV_ID_Solicitud" AND V."Eliminado" = 'N'
     ORDER BY V."Version" DESC;
END;
$$;
-- Prueba: SELECT "Version","Fecha_Aprobacion","Aprobador_Nombre" FROM "ERP_CAF_SOLICITUD_VERSION_LISTAR"(2, 1);

-- -----------------------------------------------------------------------------
-- 13. ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR
--     Portería ve SOLO a las personas AUTORIZADAS de un día, en las sedes donde
--     tiene PER_CAF_PORTERIA_REGISTRAR o PER_CAF_PORTERIA_VER. Una solicitud
--     cancelada desaparece. HV_Fecha NULL = hoy.
--     HV_Grupo: POR_INGRESAR, DENTRO, SALIERON, DENEGADOS_NO_VINIERON; NULL o TODOS = todos.
--     HV_Texto: documento, nombre de la persona o empresa.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT  DEFAULT NULL,
    "HV_Fecha"            DATE    DEFAULT NULL,
    "HV_Texto"            VARCHAR DEFAULT NULL,
    "HV_Grupo"            VARCHAR DEFAULT NULL
)
RETURNS TABLE ("ID_Solicitud_Persona" BIGINT, "ID_Solicitud" BIGINT, "Codigo" VARCHAR, "ID_Catalogo_Sede" BIGINT,
               "Fecha_Hora_Prevista" TIMESTAMP, "Empresa_Visitante" VARCHAR, "Responsable_Nombre" VARCHAR,
               "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR, "Persona_Nombre" VARCHAR,
               "Estado" VARCHAR, "Grupo" VARCHAR, "Fecha_Hora_Ingreso" TIMESTAMP, "Fecha_Hora_Salida" TIMESTAMP,
               "Acceso_Restringido" CHAR(1), "Trae_Equipos" CHAR(1), "Trae_Herramientas" CHAR(1),
               "Exige_SCTR" CHAR(1), "Exige_EPP" CHAR(1), "Zonas_Nombres" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_fecha DATE         := COALESCE("HV_Fecha", CURRENT_DATE);
    lv_txt   VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Texto", '')));
    lv_grupo VARCHAR(30)  := UPPER(TRIM(COALESCE("HV_Grupo", 'TODOS')));
BEGIN
    -- V1.0 2026-10-17
    IF LENGTH(lv_grupo) = 0 THEN lv_grupo := 'TODOS'; END IF;
    RETURN QUERY
    SELECT P."ID_Solicitud_Persona", S."ID_Solicitud", S."Codigo", S."ID_Catalogo_Sede",
           S."Fecha_Hora_Prevista", S."Empresa_Visitante",
           CAST(R."Apellido_Paterno" || COALESCE(' ' || R."Apellido_Materno", '') || ', ' || R."Nombres" AS VARCHAR),
           TD."Codigo", PE."Numero_Documento",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           P."Estado",
           CAST(CASE P."Estado" WHEN 'ESPERADA' THEN 'POR_INGRESAR' WHEN 'DENTRO' THEN 'DENTRO' WHEN 'SALIO' THEN 'SALIERON'
                                ELSE 'DENEGADOS_NO_VINIERON' END AS VARCHAR),
           P."Fecha_Hora_Ingreso", P."Fecha_Hora_Salida",
           P."Acceso_Restringido", P."Trae_Equipos", P."Trae_Herramientas",
           S."Exige_SCTR", S."Exige_EPP",
           CAST((SELECT STRING_AGG(ZA."Descripcion", ', ' ORDER BY ZA."Orden", ZA."ID_Catalogo_Zona_Acceso")
                   FROM "CAF_Solicitud_Zona" Z
                   JOIN "Catalogo_Zona_Acceso" ZA ON ZA."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso"
                  WHERE Z."ID_Solicitud" = S."ID_Solicitud" AND Z."Eliminado" = 'N') AS VARCHAR)
      FROM "CAF_Solicitud" S
      JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud" = S."ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'APROBADA'
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = PE."ID_Catalogo_Tipo_Documento"
      LEFT JOIN "CAF_GOVERNANCE"."Personal" R ON R."ID_Personal" = S."ID_Personal_Responsable"
     WHERE S."Eliminado" = 'N' AND S."Estado" <> 'CANCELADA'
       AND CAST(S."Fecha_Hora_Prevista" AS DATE) = lv_fecha
       AND ("HV_ID_Catalogo_Sede" IS NULL OR S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede")
       AND ("ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', S."ID_Catalogo_Sede") = 'Y'
            OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', S."ID_Catalogo_Sede") = 'Y')
       AND (lv_grupo = 'TODOS'
            OR (lv_grupo = 'POR_INGRESAR' AND P."Estado" = 'ESPERADA')
            OR (lv_grupo = 'DENTRO'       AND P."Estado" = 'DENTRO')
            OR (lv_grupo = 'SALIERON'     AND P."Estado" = 'SALIO')
            OR (lv_grupo = 'DENEGADOS_NO_VINIERON' AND P."Estado" IN ('DENEGADA','NO_SE_PRESENTO')))
       AND (LENGTH(lv_txt) = 0
            OR LOWER(PE."Numero_Documento") LIKE '%' || lv_txt || '%'
            OR "ERP_CAF_FN_NORMALIZAR"(PE."Apellido_Paterno" || ' ' || COALESCE(PE."Apellido_Materno", '') || ' ' || PE."Nombres") LIKE '%' || lv_txt || '%'
            OR "ERP_CAF_FN_NORMALIZAR"(S."Empresa_Visitante") LIKE '%' || lv_txt || '%')
     ORDER BY S."Fecha_Hora_Prevista", S."Empresa_Visitante", P."ID_Solicitud_Persona";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(4, NULL, CURRENT_DATE);

-- -----------------------------------------------------------------------------
-- 14. ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR
--     Cuando alguien llega y no figura entre los autorizados de hoy, Vigilancia
--     busca por documento o nombre (mínimo 3 letras) para saber POR QUÉ no está:
--     pendiente, observada, rechazada, retirada o la solicitud se canceló.
--     Solo devuelve lo mínimo para orientar a quien está en la puerta.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT,
    "HV_Fecha"            DATE,
    "HV_Texto"            VARCHAR
)
RETURNS TABLE ("Codigo" VARCHAR, "Persona_Nombre" VARCHAR, "Numero_Documento" VARCHAR, "Empresa_Visitante" VARCHAR,
               "Motivo_Codigo" VARCHAR, "Motivo_Texto" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_fecha DATE         := COALESCE("HV_Fecha", CURRENT_DATE);
    lv_txt   VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Texto", '')));
BEGIN
    -- V1.0 2026-10-17
    IF LENGTH(lv_txt) < 3 THEN RETURN; END IF;
    RETURN QUERY
    SELECT S."Codigo",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           PE."Numero_Documento", S."Empresa_Visitante",
           CAST(CASE WHEN S."Estado" = 'CANCELADA' THEN 'CANCELADA' ELSE P."Aprobacion" END AS VARCHAR),
           CAST(CASE WHEN S."Estado" = 'CANCELADA' THEN 'La solicitud fue cancelada.'
                     WHEN P."Aprobacion" = 'PENDIENTE' THEN 'Su solicitud está pendiente de aprobación.'
                     WHEN P."Aprobacion" = 'OBSERVADA' THEN 'Su solicitud fue observada y aún no se corrige.'
                     WHEN P."Aprobacion" = 'RECHAZADA' THEN 'Su ingreso fue rechazado.'
                     WHEN P."Aprobacion" = 'RETIRADA'  THEN 'Fue retirada de la solicitud.'
                END AS VARCHAR)
      FROM "CAF_Solicitud" S
      JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud" = S."ID_Solicitud" AND P."Eliminado" = 'N'
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
     WHERE S."Eliminado" = 'N' AND CAST(S."Fecha_Hora_Prevista" AS DATE) = lv_fecha
       AND S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
       AND (S."Estado" = 'CANCELADA' OR P."Aprobacion" <> 'APROBADA')
       AND ("ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', S."ID_Catalogo_Sede") = 'Y'
            OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', S."ID_Catalogo_Sede") = 'Y')
       AND (LOWER(PE."Numero_Documento") LIKE '%' || lv_txt || '%'
            OR "ERP_CAF_FN_NORMALIZAR"(PE."Apellido_Paterno" || ' ' || COALESCE(PE."Apellido_Materno", '') || ' ' || PE."Nombres") LIKE '%' || lv_txt || '%')
     ORDER BY S."Codigo", P."ID_Solicitud_Persona";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR"(4, 1, CURRENT_DATE, 'torres');

-- -----------------------------------------------------------------------------
-- 15. ERP_CAF_SOLICITUD_EMPRESAS_BUSCAR  (autocompletar «Empresa o procedencia»)
--     Empresas ya escritas en solicitudes (sin distinguir mayúsculas ni tildes), las más usadas primero.
--     Sin texto devuelve las más usadas. Máximo 10.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_EMPRESAS_BUSCAR"("HV_Texto" VARCHAR DEFAULT NULL)
RETURNS TABLE ("Empresa" VARCHAR, "Veces" INT)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_txt VARCHAR := LOWER(COALESCE(TRIM("HV_Texto"), ''));
BEGIN
    -- V1.0 2026-10-26
    RETURN QUERY
    SELECT X."Empresa", X."Veces"
      FROM (SELECT CAST(MIN(TRIM(S."Empresa_Visitante")) AS VARCHAR) AS "Empresa", CAST(COUNT(*) AS INT) AS "Veces",
                   LOWER(TRIM(S."Empresa_Visitante")) AS "Clave"
              FROM "CAF_Solicitud" S
             WHERE S."Eliminado" = 'N' AND TRIM(S."Empresa_Visitante") <> ''
             GROUP BY LOWER(TRIM(S."Empresa_Visitante"))) X
     WHERE lv_txt = '' OR "ERP_CAF_FN_NORMALIZAR"(X."Empresa") LIKE '%' || "ERP_CAF_FN_NORMALIZAR"(lv_txt) || '%'
     ORDER BY X."Veces" DESC, X."Empresa"
     LIMIT 10;
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SOLICITUD_EMPRESAS_BUSCAR"('tri');
