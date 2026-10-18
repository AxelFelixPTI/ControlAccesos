-- =============================================================================
-- Archivo : SP_CAF_REPORTE_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 4 - Incidencias, reporte y correos | Fase 1 - Procedimientos (reporte de accesos)
-- Entidad : (consultas sobre CAF_Registro_Acceso y relacionadas)
-- Versión : V1.0 2026-10-18
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO4_LECTURA.sql)
-- Requiere: scripts 01 a 10 y los SP de los Hitos 0 a 3.
-- =============================================================================
-- Todas exigen PER_CAF_REPORTE_VER en la sede. Rango máximo: 92 días (si no, no devuelven filas).
--   1 ERP_CAF_REPORTE_ACCESOS               una fila por movimiento (la base de la exportación a Excel)
--   2 ERP_CAF_REPORTE_RESUMEN_DIARIO        una fila por día con totales
--   3 ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA  quiénes estaban autorizados a una zona en una fecha
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_REPORTE_ACCESOS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_REPORTE_ACCESOS"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT,
    "HV_Fecha_Desde"      DATE,
    "HV_Fecha_Hasta"      DATE,
    "HV_Tipo"             VARCHAR DEFAULT NULL,
    "HV_Resultado"        VARCHAR DEFAULT NULL,
    "HV_Texto"            VARCHAR DEFAULT NULL
)
RETURNS TABLE ("ID_Registro_Acceso" BIGINT, "Fecha_Hora" TIMESTAMP, "Tipo_Movimiento" VARCHAR, "Resultado" VARCHAR,
               "Es_Registro_Tardio" CHAR(1), "Codigo_Solicitud" VARCHAR, "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR,
               "Persona_Nombre" VARCHAR, "Empresa_Visitante" VARCHAR, "Zonas" VARCHAR, "Vigilante_Nombre" VARCHAR,
               "Items_Incumplidos" BIGINT, "Codigo_Desviacion" VARCHAR, "Estado_Desviacion" VARCHAR, "Observacion" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_tip VARCHAR(10)  := UPPER(TRIM(COALESCE("HV_Tipo", '')));
    lv_res VARCHAR(30)  := UPPER(TRIM(COALESCE("HV_Resultado", '')));
    lv_txt VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Texto", '')));
BEGIN
    -- V1.0 2026-10-18
    IF "HV_ID_Catalogo_Sede" IS NULL OR "HV_Fecha_Desde" IS NULL OR "HV_Fecha_Hasta" IS NULL
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', "HV_ID_Catalogo_Sede") <> 'Y' THEN
        RETURN;
    END IF;
    IF "HV_Fecha_Hasta" < "HV_Fecha_Desde" OR "HV_Fecha_Hasta" - "HV_Fecha_Desde" > 92 THEN RETURN; END IF;
    IF lv_tip NOT IN ('', 'INGRESO', 'SALIDA') THEN RETURN; END IF;
    RETURN QUERY
    SELECT A."ID_Registro_Acceso", A."Fecha_Hora", A."Tipo_Movimiento", A."Resultado", A."Es_Registro_Tardio",
           S."Codigo", TD."Codigo", PE."Numero_Documento",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           S."Empresa_Visitante",
           CAST((SELECT STRING_AGG(Z."Descripcion", ', ' ORDER BY Z."Orden", Z."ID_Catalogo_Zona_Acceso")
                   FROM "CAF_Solicitud_Zona" SZ
                   JOIN "Catalogo_Zona_Acceso" Z ON Z."ID_Catalogo_Zona_Acceso" = SZ."ID_Catalogo_Zona_Acceso"
                  WHERE SZ."ID_Solicitud" = S."ID_Solicitud" AND SZ."Eliminado" = 'N') AS VARCHAR),
           CAST(U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" AS VARCHAR),
           (SELECT COUNT(*) FROM "CAF_Registro_Checklist" RC
             WHERE RC."ID_Registro_Acceso" = A."ID_Registro_Acceso" AND RC."Eliminado" = 'N' AND RC."Cumple" = 'N'),
           D."Codigo", D."Estado", A."Observacion"
      FROM "CAF_Registro_Acceso" A
      JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = A."ID_Solicitud_Persona"
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = PE."ID_Catalogo_Tipo_Documento"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = A."ID_Usuario_Vigilante"
      LEFT JOIN "CAF_Desviacion" D ON D."ID_Registro_Acceso" = A."ID_Registro_Acceso" AND D."Eliminado" = 'N'
     WHERE A."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND A."Eliminado" = 'N'
       AND CAST(A."Fecha_Hora" AS DATE) BETWEEN "HV_Fecha_Desde" AND "HV_Fecha_Hasta"
       AND (lv_tip = '' OR A."Tipo_Movimiento" = lv_tip)
       AND (lv_res = '' OR A."Resultado" = lv_res)
       AND (lv_txt = '' OR "ERP_CAF_FN_NORMALIZAR"(PE."Numero_Documento" || ' ' || PE."Apellido_Paterno" || ' ' || COALESCE(PE."Apellido_Materno", '')
                                                    || ' ' || PE."Nombres" || ' ' || COALESCE(S."Empresa_Visitante", '') || ' ' || S."Codigo") LIKE '%' || lv_txt || '%')
     ORDER BY A."Fecha_Hora", A."ID_Registro_Acceso";
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_REPORTE_RESUMEN_DIARIO
--    Una fila por cada día del rango que tenga movimientos, desviaciones o incidencias.
--    Las incidencias se cuentan por la fecha del hecho; las desviaciones por la del movimiento.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_REPORTE_RESUMEN_DIARIO"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT,
    "HV_Fecha_Desde"      DATE,
    "HV_Fecha_Hasta"      DATE
)
RETURNS TABLE ("Fecha" DATE, "Ingresos" BIGINT, "Ingresos_Restringidos" BIGINT, "Ingresos_Denegados" BIGINT,
               "Salidas" BIGINT, "Desviaciones" BIGINT, "Incidencias" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-18
    IF "HV_ID_Catalogo_Sede" IS NULL OR "HV_Fecha_Desde" IS NULL OR "HV_Fecha_Hasta" IS NULL
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', "HV_ID_Catalogo_Sede") <> 'Y' THEN
        RETURN;
    END IF;
    IF "HV_Fecha_Hasta" < "HV_Fecha_Desde" OR "HV_Fecha_Hasta" - "HV_Fecha_Desde" > 92 THEN RETURN; END IF;
    RETURN QUERY
    SELECT X."Dia",
           CAST(SUM(X."I") AS BIGINT), CAST(SUM(X."IR") AS BIGINT), CAST(SUM(X."ID") AS BIGINT),
           CAST(SUM(X."S") AS BIGINT), CAST(SUM(X."D") AS BIGINT), CAST(SUM(X."N") AS BIGINT)
      FROM (
            SELECT CAST(A."Fecha_Hora" AS DATE) AS "Dia",
                   CAST(CASE WHEN A."Resultado" IN ('INGRESA','INGRESA_RESTRINGIDO') THEN 1 ELSE 0 END AS BIGINT) AS "I",
                   CAST(CASE WHEN A."Resultado" = 'INGRESA_RESTRINGIDO' THEN 1 ELSE 0 END AS BIGINT) AS "IR",
                   CAST(CASE WHEN A."Resultado" = 'NO_INGRESA' THEN 1 ELSE 0 END AS BIGINT) AS "ID",
                   CAST(CASE WHEN A."Tipo_Movimiento" = 'SALIDA' THEN 1 ELSE 0 END AS BIGINT) AS "S",
                   CAST((SELECT COUNT(*) FROM "CAF_Desviacion" D WHERE D."ID_Registro_Acceso" = A."ID_Registro_Acceso" AND D."Eliminado" = 'N') AS BIGINT) AS "D",
                   CAST(0 AS BIGINT) AS "N"
              FROM "CAF_Registro_Acceso" A
             WHERE A."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND A."Eliminado" = 'N'
               AND CAST(A."Fecha_Hora" AS DATE) BETWEEN "HV_Fecha_Desde" AND "HV_Fecha_Hasta"
            UNION ALL
            SELECT CAST(I."Fecha_Hora_Hecho" AS DATE), 0, 0, 0, 0, 0, 1
              FROM "CAF_Incidencia" I
             WHERE I."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND I."Eliminado" = 'N' AND I."Estado" <> 'DESESTIMADA'
               AND CAST(I."Fecha_Hora_Hecho" AS DATE) BETWEEN "HV_Fecha_Desde" AND "HV_Fecha_Hasta"
           ) X
     GROUP BY X."Dia"
     ORDER BY X."Dia";
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA
--    «¿Quién estaba autorizado a entrar a esta zona ese día?» Personas APROBADAS de
--    solicitudes vigentes (no canceladas) de esa fecha que incluyen la zona.
--    Se indica si la persona llegó a entrar (Estado_Persona).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(
    "HV_UsuarioID"             BIGINT,
    "HV_ID_Catalogo_Sede"      BIGINT,
    "HV_ID_Catalogo_Zona_Acceso" BIGINT,
    "HV_Fecha"                 DATE
)
RETURNS TABLE ("ID_Solicitud_Persona" BIGINT, "Codigo_Solicitud" VARCHAR, "Fecha_Hora_Prevista" TIMESTAMP,
               "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR, "Persona_Nombre" VARCHAR,
               "Empresa_Visitante" VARCHAR, "Estado_Persona" VARCHAR, "Acceso_Restringido" CHAR(1),
               "Fecha_Hora_Ingreso" TIMESTAMP, "Fecha_Hora_Salida" TIMESTAMP)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-18
    IF "HV_ID_Catalogo_Sede" IS NULL OR "HV_ID_Catalogo_Zona_Acceso" IS NULL OR "HV_Fecha" IS NULL
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', "HV_ID_Catalogo_Sede") <> 'Y' THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT P."ID_Solicitud_Persona", S."Codigo", S."Fecha_Hora_Prevista", TD."Codigo", PE."Numero_Documento",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           S."Empresa_Visitante", P."Estado", P."Acceso_Restringido", P."Fecha_Hora_Ingreso", P."Fecha_Hora_Salida"
      FROM "CAF_Solicitud_Zona" SZ
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = SZ."ID_Solicitud" AND S."Eliminado" = 'N' AND S."Estado" <> 'CANCELADA'
                            AND S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
      JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud" = S."ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'APROBADA'
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = PE."ID_Catalogo_Tipo_Documento"
     WHERE SZ."Eliminado" = 'N' AND SZ."ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso"
       AND CAST(S."Fecha_Hora_Prevista" AS DATE) = "HV_Fecha"
     ORDER BY S."Fecha_Hora_Prevista", PE."Apellido_Paterno", PE."Nombres", P."ID_Solicitud_Persona";
END;
$$;
