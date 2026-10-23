-- =============================================================================
-- Archivo : SP_CAF_SOLICITUD_VIGILANCIA_APROBADAS.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobación | Vigilancia: consulta de aprobadas (otras fechas)
-- Versión : V1.0 2026-10-21
-- Estado  : CANDIDATO
-- Requiere: SP_CAF_SOLICITUD_LECTURA_ALL.sql (ERP_CAF_FN_NORMALIZAR) y la función de permisos.
-- Objeto  : ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS (función, solo lectura)
--           Personas aprobadas de solicitudes no canceladas, de cualquier fecha (rango opcional).
--           Mismas columnas que ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR. Máximo 500 filas.
--           Sirve para consultar; el ingreso y la salida solo se registran el día de la visita.
-- =============================================================================
CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS"("HV_UsuarioID" bigint, "HV_ID_Catalogo_Sede" bigint DEFAULT NULL::bigint, "HV_Fecha_Desde" date DEFAULT NULL::date, "HV_Fecha_Hasta" date DEFAULT NULL::date, "HV_Texto" character varying DEFAULT NULL::character varying)
 RETURNS TABLE("ID_Solicitud_Persona" bigint, "ID_Solicitud" bigint, "Codigo" character varying, "ID_Catalogo_Sede" bigint, "Fecha_Hora_Prevista" timestamp without time zone, "Empresa_Visitante" character varying, "Responsable_Nombre" character varying, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Persona_Nombre" character varying, "Estado" character varying, "Grupo" character varying, "Fecha_Hora_Ingreso" timestamp without time zone, "Fecha_Hora_Salida" timestamp without time zone, "Acceso_Restringido" character, "Trae_Equipos" character, "Trae_Herramientas" character, "Exige_SCTR" character, "Exige_EPP" character, "Zonas_Nombres" character varying)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
DECLARE
    lv_txt VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Texto", '')));
BEGIN
    -- V1.0 2026-10-21
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
       AND ("HV_Fecha_Desde" IS NULL OR CAST(S."Fecha_Hora_Prevista" AS DATE) >= "HV_Fecha_Desde")
       AND ("HV_Fecha_Hasta" IS NULL OR CAST(S."Fecha_Hora_Prevista" AS DATE) <= "HV_Fecha_Hasta")
       AND ("HV_ID_Catalogo_Sede" IS NULL OR S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede")
       AND ("ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', S."ID_Catalogo_Sede") = 'Y'
            OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', S."ID_Catalogo_Sede") = 'Y')
       AND (LENGTH(lv_txt) = 0
            OR LOWER(PE."Numero_Documento") LIKE '%' || lv_txt || '%'
            OR "ERP_CAF_FN_NORMALIZAR"(PE."Apellido_Paterno" || ' ' || COALESCE(PE."Apellido_Materno", '') || ' ' || PE."Nombres") LIKE '%' || lv_txt || '%'
            OR "ERP_CAF_FN_NORMALIZAR"(S."Empresa_Visitante") LIKE '%' || lv_txt || '%')
     ORDER BY S."Fecha_Hora_Prevista", S."Empresa_Visitante", P."ID_Solicitud_Persona"
     LIMIT 500;
END;
$function$;
