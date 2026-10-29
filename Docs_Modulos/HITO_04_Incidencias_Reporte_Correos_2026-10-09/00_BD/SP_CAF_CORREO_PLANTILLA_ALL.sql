-- =============================================================================
-- Archivo : SP_CAF_CORREO_PLANTILLA_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 4 - Correos | datos para armar la plantilla del correo
-- Versión : V1.1 2026-10-29 (D-179: Asunto_Hilo)
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO4_CORREO_PLANTILLA.sql)
-- Requiere: SP_CAF_SOLICITUD_LECTURA_ALL.sql (usa ERP_CAF_SOLICITUD_INDICADORES)
-- =============================================================================
-- Solo las llama el proceso de envío (UsuarioID 0, D-12): no validan visibilidad
-- porque el correo se arma con la solicitud tal como está al momento de enviar.
--   1 ERP_CAF_CORREO_SOLICITUD_DATOS     una fila con la cabecera de la solicitud
--   2 ERP_CAF_CORREO_SOLICITUD_PERSONAS  las personas de la solicitud (sin retiradas)
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- V1.1: se agrega la columna "Asunto_Hilo" y por eso se borra la función anterior (cambia el tipo de retorno)
DROP FUNCTION IF EXISTS "ERP_CAF_CORREO_SOLICITUD_DATOS"(BIGINT, BIGINT);
CREATE OR REPLACE FUNCTION "ERP_CAF_CORREO_SOLICITUD_DATOS"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Solicitud" BIGINT, "Codigo" VARCHAR, "Estado" VARCHAR, "Fecha_Hora_Prevista" TIMESTAMP,
               "Sede" VARCHAR, "Tipo_Acceso" VARCHAR, "Empresa_Visitante" VARCHAR,
               "Responsable_Nombre" VARCHAR, "Responsable_Correo" VARCHAR, "Responsable_Area" VARCHAR,
               "Motivo" VARCHAR, "Motivo_Detalle" VARCHAR, "Observaciones" VARCHAR, "Zonas_Nombres" VARCHAR,
               "Solicitante_Nombre" VARCHAR, "Solicitante_Correo" VARCHAR,
               "Exige_SCTR" CHAR(1), "Exige_EPP" CHAR(1),
               "Total_Personas" INT, "Autorizadas" INT, "Observadas" INT, "Pendientes" INT, "Rechazadas" INT, "Retiradas" INT,
               "Observacion_Coordinador" VARCHAR, "Motivo_Cancelacion" VARCHAR, "Version" BIGINT, "Fecha_Envio" TIMESTAMP,
               "Asunto_Hilo" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.1 2026-10-29
    IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <> 0 THEN RETURN; END IF;
    RETURN QUERY
    SELECT S."ID_Solicitud", S."Codigo", S."Estado", S."Fecha_Hora_Prevista",
           SE."Descripcion", TA."Descripcion", S."Empresa_Visitante",
           CAST(R."Apellido_Paterno" || COALESCE(' ' || R."Apellido_Materno", '') || ', ' || R."Nombres" AS VARCHAR),
           R."Correo", AR."Descripcion",
           MV."Descripcion", S."Motivo_Detalle", S."Observaciones",
           CAST((SELECT STRING_AGG(ZA."Descripcion", ', ' ORDER BY ZA."Orden", ZA."ID_Catalogo_Zona_Acceso")
                   FROM "CAF_Solicitud_Zona" Z
                   JOIN "Catalogo_Zona_Acceso" ZA ON ZA."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso"
                  WHERE Z."ID_Solicitud" = S."ID_Solicitud" AND Z."Eliminado" = 'N') AS VARCHAR),
           CAST(US."Apellido_Paterno" || COALESCE(' ' || US."Apellido_Materno", '') || ', ' || US."Nombres" AS VARCHAR),
           US."Correo",
           S."Exige_SCTR", S."Exige_EPP",
           I."Total_Personas", I."Autorizadas", I."Observadas", I."Pendientes", I."Rechazadas", I."Retiradas",
           S."Observacion_Coordinador", S."Motivo_Cancelacion", S."Version", S."Fecha_Envio",
           -- Asunto con el que salió el aviso de solicitud nueva (código + empresa de la creación). Vacío en solicitudes anteriores a D-179.
           CAST((SELECT C."Asunto" FROM "CAF_Correo_Pendiente" C
                  WHERE C."ID_Solicitud" = S."ID_Solicitud" AND C."Tipo" = 'SOLICITUD_NUEVA' AND C."Eliminado" = 'N'
                    AND C."Asunto" LIKE 'Solicitud ' || S."Codigo" || ' · %'
                  ORDER BY C."ID_Correo_Pendiente" LIMIT 1) AS VARCHAR)
      FROM "CAF_Solicitud" S
      JOIN "ERP_CAF_SOLICITUD_INDICADORES"("HV_ID_Solicitud") I ON I."ID_Solicitud" = S."ID_Solicitud"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Sede" SE ON SE."ID_Catalogo_Sede" = S."ID_Catalogo_Sede"
      LEFT JOIN "Catalogo_Tipo_Acceso" TA ON TA."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso"
      LEFT JOIN "CAF_GOVERNANCE"."Personal" R ON R."ID_Personal" = S."ID_Personal_Responsable"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Area" AR ON AR."ID_Catalogo_Area" = R."ID_Catalogo_Area"
      LEFT JOIN "Catalogo_Motivo_Visita" MV ON MV."ID_Catalogo_Motivo_Visita" = S."ID_Catalogo_Motivo_Visita"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" US ON US."ID_Usuario" = S."ID_Usuario_Solicitante"
     WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_CORREO_SOLICITUD_DATOS"(0, 1);

CREATE OR REPLACE FUNCTION "ERP_CAF_CORREO_SOLICITUD_PERSONAS"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Solicitud_Persona" BIGINT, "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR, "Nombre_Completo" VARCHAR,
               "Aprobacion" VARCHAR, "Aprobacion_Mensaje" VARCHAR, "Trae_Equipos" CHAR(1), "Trae_Herramientas" CHAR(1))
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-24
    IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" <> 0 THEN RETURN; END IF;
    RETURN QUERY
    SELECT P."ID_Solicitud_Persona", TD."Codigo", PE."Numero_Documento",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           P."Aprobacion", P."Aprobacion_Mensaje", P."Trae_Equipos", P."Trae_Herramientas"
      FROM "CAF_Solicitud_Persona" P
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = PE."ID_Catalogo_Tipo_Documento"
     WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" <> 'RETIRADA'
     ORDER BY P."ID_Solicitud_Persona";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_CORREO_SOLICITUD_PERSONAS"(0, 1);
