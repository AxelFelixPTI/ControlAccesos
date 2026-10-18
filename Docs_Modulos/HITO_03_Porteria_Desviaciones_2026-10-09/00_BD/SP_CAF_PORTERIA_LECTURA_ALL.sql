-- =============================================================================
-- Archivo : SP_CAF_PORTERIA_LECTURA_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 3 - Portería y desviaciones | Fase 1 - Procedimientos (lectura)
-- Versión : V1.0 2026-10-17
-- Requiere: SP_CAF_PORTERIA_ALL.sql, SP_CAF_DESVIACION_ALL.sql, SP_CAF_RESPALDO_ALL.sql
-- =============================================================================
-- PARA LA APLICACIÓN (lecturas: devuelven filas; sin permiso devuelven CERO FILAS, D-57):
--  1 ERP_CAF_PORTERIA_CHECKLIST_OBTENER       ítems que Vigilancia debe marcar en este movimiento
--  2 ERP_CAF_PORTERIA_FICHA                   la persona, qué puede hacer Vigilancia y por qué no
--  3 ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR      bitácora de ingresos y salidas (formato G-FSCA-008)
--  4 ERP_CAF_PORTERIA_REGISTRO_DETALLE        un movimiento
--  5 ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR   los ítems marcados en ese movimiento
--  6 ERP_CAF_RESPALDO_LISTAR_POR_PERSONA      respaldos que cubren a la persona
--  7 ERP_CAF_DESVIACION_LISTAR                desviaciones por revisar / revisadas
--  8 ERP_CAF_DESVIACION_DETALLE               una desviación
--  9 ERP_CAF_DESVIACION_CONTADORES            números para las insignias
-- 10 ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN  a quién se puede consultar en la sede
-- 11 ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN   tratamientos válidos según la etapa
--
-- REGLAS
--  * Los botones «Puede_Registrar_...» repiten la misma regla de los procedimientos de
--    escritura llamando a la misma función (ERP_CAF_PORTERIA_REGLA_MOVIMIENTO): D-56.
--  * Permisos: ver ficha, checklist y respaldos = PER_CAF_PORTERIA_REGISTRAR o PER_CAF_PORTERIA_VER;
--    bitácora y detalle de movimientos = PORTERIA_VER, PORTERIA_REGISTRAR o REPORTE_VER;
--    desviaciones = DESVIACION_CONFORMIDAD, DESVIACION_REGISTRAR, PORTERIA_VER o REPORTE_VER.
--  * Sin paginación en el servidor (D-58). Búsqueda sin tildes (D-59).
-- HANA: cada función RETURNS TABLE pasa a procedimiento con parámetro de salida tipo tabla.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_PORTERIA_CHECKLIST_OBTENER
--    HV_Trae_Equipos / HV_Trae_Herramientas: lo que Vigilancia respondió (solo INGRESO).
--    En SALIDA se usa lo que la persona declaró al ingresar.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(
    "HV_UsuarioID"            BIGINT,
    "HV_ID_Solicitud_Persona" BIGINT,
    "HV_Etapa"                VARCHAR,
    "HV_Trae_Equipos"         CHAR DEFAULT 'N',
    "HV_Trae_Herramientas"    CHAR DEFAULT 'N'
)
RETURNS TABLE ("ID_Catalogo_Item_Checklist" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Ayuda" VARCHAR,
               "Es_Critico" CHAR(1), "Orden" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_sede BIGINT; lv_eq CHAR(1); lv_he CHAR(1);
    lv_etapa VARCHAR(10) := UPPER(TRIM(COALESCE("HV_Etapa", '')));
BEGIN
    -- V1.0 2026-10-17
    SELECT S."ID_Catalogo_Sede", P."Trae_Equipos", P."Trae_Herramientas" INTO lv_sede, lv_eq, lv_he
      FROM "CAF_Solicitud_Persona" P JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
     WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND P."Eliminado" = 'N' AND S."Eliminado" = 'N';
    IF lv_sede IS NULL OR lv_etapa NOT IN ('INGRESO','SALIDA')
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', lv_sede) <> 'Y' THEN
        RETURN;
    END IF;
    IF lv_etapa = 'INGRESO' THEN lv_eq := COALESCE("HV_Trae_Equipos", 'N'); lv_he := COALESCE("HV_Trae_Herramientas", 'N'); END IF;
    RETURN QUERY SELECT * FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"("HV_ID_Solicitud_Persona", lv_etapa, lv_eq, lv_he);
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_PORTERIA_FICHA
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PORTERIA_FICHA"(
    "HV_UsuarioID"            BIGINT,
    "HV_ID_Solicitud_Persona" BIGINT
)
RETURNS TABLE ("ID_Solicitud_Persona" BIGINT, "ID_Solicitud" BIGINT, "Codigo" VARCHAR, "ID_Catalogo_Sede" BIGINT,
               "Fecha_Hora_Prevista" TIMESTAMP, "Empresa_Visitante" VARCHAR, "Responsable_Nombre" VARCHAR,
               "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR, "Persona_Nombre" VARCHAR,
               "Estado" VARCHAR, "Fecha_Hora_Ingreso" TIMESTAMP, "Fecha_Hora_Salida" TIMESTAMP,
               "Acceso_Restringido" CHAR(1), "Trae_Equipos" CHAR(1), "Trae_Herramientas" CHAR(1),
               "Exige_SCTR" CHAR(1), "Exige_EPP" CHAR(1), "Zonas_Nombres" VARCHAR,
               "Tiene_Respaldo_Equipos" CHAR(1), "Tiene_Respaldo_Herramientas" CHAR(1),
               "Puede_Registrar_Ingreso" CHAR(1), "Motivo_No_Ingreso" VARCHAR,
               "Puede_Registrar_Ingreso_Tardio" CHAR(1),
               "Puede_Registrar_Salida" CHAR(1), "Motivo_No_Salida" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_sede BIGINT; lv_puede CHAR(1);
BEGIN
    -- V1.0 2026-10-17
    SELECT S."ID_Catalogo_Sede" INTO lv_sede
      FROM "CAF_Solicitud_Persona" P JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
     WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND P."Eliminado" = 'N' AND S."Eliminado" = 'N';
    IF lv_sede IS NULL THEN RETURN; END IF;
    IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', lv_sede) = 'Y' THEN
        lv_puede := 'Y';
    ELSIF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', lv_sede) = 'Y' THEN
        lv_puede := 'N';
    ELSE
        RETURN;
    END IF;

    RETURN QUERY
    SELECT P."ID_Solicitud_Persona", S."ID_Solicitud", S."Codigo", S."ID_Catalogo_Sede",
           S."Fecha_Hora_Prevista", S."Empresa_Visitante",
           CAST(R."Apellido_Paterno" || COALESCE(' ' || R."Apellido_Materno", '') || ', ' || R."Nombres" AS VARCHAR),
           TD."Codigo", PE."Numero_Documento",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           P."Estado", P."Fecha_Hora_Ingreso", P."Fecha_Hora_Salida",
           P."Acceso_Restringido", P."Trae_Equipos", P."Trae_Herramientas",
           S."Exige_SCTR", S."Exige_EPP",
           CAST((SELECT STRING_AGG(ZA."Descripcion", ', ' ORDER BY ZA."Orden", ZA."ID_Catalogo_Zona_Acceso")
                   FROM "CAF_Solicitud_Zona" Z
                   JOIN "Catalogo_Zona_Acceso" ZA ON ZA."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso"
                  WHERE Z."ID_Solicitud" = S."ID_Solicitud" AND Z."Eliminado" = 'N') AS VARCHAR),
           CAST(CASE WHEN EXISTS (SELECT 1 FROM "CAF_Respaldo_Persona" RP JOIN "CAF_Respaldo" RS ON RS."ID_Respaldo" = RP."ID_Respaldo"
                                   WHERE RP."ID_Solicitud_Persona" = P."ID_Solicitud_Persona" AND RP."Eliminado" = 'N'
                                     AND RS."Eliminado" = 'N' AND RS."Categoria" = 'EQUIPOS') THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN EXISTS (SELECT 1 FROM "CAF_Respaldo_Persona" RP JOIN "CAF_Respaldo" RS ON RS."ID_Respaldo" = RP."ID_Respaldo"
                                   WHERE RP."ID_Solicitud_Persona" = P."ID_Solicitud_Persona" AND RP."Eliminado" = 'N'
                                     AND RS."Eliminado" = 'N' AND RS."Categoria" = 'HERRAMIENTAS_MATERIALES') THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN lv_puede = 'Y' THEN RI."Permitido" ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN lv_puede <> 'Y' THEN 'Solo tiene permiso de consulta.' WHEN RI."Permitido" = 'Y' THEN NULL ELSE RI."Mensaje" END AS VARCHAR),
           CAST(CASE WHEN lv_puede = 'Y' AND RT."Permitido" = 'Y' AND RI."Permitido" <> 'Y' THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN lv_puede = 'Y' THEN RS."Permitido" ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN lv_puede <> 'Y' THEN 'Solo tiene permiso de consulta.' WHEN RS."Permitido" = 'Y' THEN NULL ELSE RS."Mensaje" END AS VARCHAR)
      FROM "CAF_Solicitud_Persona" P
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = PE."ID_Catalogo_Tipo_Documento"
      LEFT JOIN "CAF_GOVERNANCE"."Personal" R ON R."ID_Personal" = S."ID_Personal_Responsable"
      CROSS JOIN LATERAL "ERP_CAF_PORTERIA_REGLA_MOVIMIENTO"(P."ID_Solicitud_Persona", 'INGRESO', 'N') RI
      CROSS JOIN LATERAL "ERP_CAF_PORTERIA_REGLA_MOVIMIENTO"(P."ID_Solicitud_Persona", 'INGRESO', 'Y') RT
      CROSS JOIN LATERAL "ERP_CAF_PORTERIA_REGLA_MOVIMIENTO"(P."ID_Solicitud_Persona", 'SALIDA', 'N') RS
     WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR
--    Fechas nulas = hoy. HV_Tipo: INGRESO, SALIDA o nulo (ambos).
--    HV_Texto: documento, nombre, empresa o código de solicitud.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT,
    "HV_Fecha_Desde"      DATE    DEFAULT NULL,
    "HV_Fecha_Hasta"      DATE    DEFAULT NULL,
    "HV_Tipo"             VARCHAR DEFAULT NULL,
    "HV_Texto"            VARCHAR DEFAULT NULL
)
RETURNS TABLE ("ID_Registro_Acceso" BIGINT, "ID_Solicitud_Persona" BIGINT, "ID_Solicitud" BIGINT, "Codigo_Solicitud" VARCHAR,
               "Fecha_Hora" TIMESTAMP, "Tipo_Movimiento" VARCHAR, "Resultado" VARCHAR, "Es_Registro_Tardio" CHAR(1),
               "Tipo_Documento" VARCHAR, "Numero_Documento" VARCHAR, "Persona_Nombre" VARCHAR, "Empresa_Visitante" VARCHAR,
               "Vigilante_Nombre" VARCHAR, "Observacion" VARCHAR, "Tiene_Desviacion" CHAR(1), "Codigo_Desviacion" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_d1  DATE := COALESCE("HV_Fecha_Desde", CURRENT_DATE);
    lv_d2  DATE := COALESCE("HV_Fecha_Hasta", COALESCE("HV_Fecha_Desde", CURRENT_DATE));
    lv_tip VARCHAR(10) := UPPER(TRIM(COALESCE("HV_Tipo", '')));
    lv_txt VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Texto", '')));
BEGIN
    -- V1.0 2026-10-17
    IF "HV_ID_Catalogo_Sede" IS NULL OR NOT (
          "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', "HV_ID_Catalogo_Sede") = 'Y') THEN
        RETURN;
    END IF;
    IF lv_d2 < lv_d1 THEN RETURN; END IF;
    RETURN QUERY
    SELECT A."ID_Registro_Acceso", A."ID_Solicitud_Persona", S."ID_Solicitud", S."Codigo", A."Fecha_Hora",
           A."Tipo_Movimiento", A."Resultado", A."Es_Registro_Tardio",
           TD."Codigo", PE."Numero_Documento",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           S."Empresa_Visitante",
           CAST(U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" AS VARCHAR),
           A."Observacion",
           CAST(CASE WHEN D."ID_Desviacion" IS NULL THEN 'N' ELSE 'Y' END AS CHAR(1)), D."Codigo"
      FROM "CAF_Registro_Acceso" A
      JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = A."ID_Solicitud_Persona"
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = PE."ID_Catalogo_Tipo_Documento"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = A."ID_Usuario_Vigilante"
      LEFT JOIN "CAF_Desviacion" D ON D."ID_Registro_Acceso" = A."ID_Registro_Acceso" AND D."Eliminado" = 'N'
     WHERE A."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND A."Eliminado" = 'N'
       AND CAST(A."Fecha_Hora" AS DATE) BETWEEN lv_d1 AND lv_d2
       AND (lv_tip = '' OR A."Tipo_Movimiento" = lv_tip)
       AND (lv_txt = '' OR "ERP_CAF_FN_NORMALIZAR"(PE."Numero_Documento" || ' ' || PE."Apellido_Paterno" || ' ' || COALESCE(PE."Apellido_Materno", '')
                                                    || ' ' || PE."Nombres" || ' ' || COALESCE(S."Empresa_Visitante", '') || ' ' || S."Codigo") LIKE '%' || lv_txt || '%')
     ORDER BY A."Fecha_Hora" DESC, A."ID_Registro_Acceso" DESC;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_PORTERIA_REGISTRO_DETALLE
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PORTERIA_REGISTRO_DETALLE"(
    "HV_UsuarioID"          BIGINT,
    "HV_ID_Registro_Acceso" BIGINT
)
RETURNS TABLE ("ID_Registro_Acceso" BIGINT, "ID_Solicitud_Persona" BIGINT, "ID_Solicitud" BIGINT, "Codigo_Solicitud" VARCHAR,
               "ID_Catalogo_Sede" BIGINT, "Fecha_Hora" TIMESTAMP, "Fecha_Hora_Sistema" TIMESTAMP,
               "Tipo_Movimiento" VARCHAR, "Resultado" VARCHAR, "Es_Registro_Tardio" CHAR(1),
               "Persona_Nombre" VARCHAR, "Numero_Documento" VARCHAR, "Empresa_Visitante" VARCHAR,
               "Vigilante_Nombre" VARCHAR, "Observacion" VARCHAR, "ID_Desviacion" BIGINT, "Codigo_Desviacion" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE lv_sede BIGINT;
BEGIN
    -- V1.0 2026-10-17
    SELECT A."ID_Catalogo_Sede" INTO lv_sede FROM "CAF_Registro_Acceso" A
     WHERE A."ID_Registro_Acceso" = "HV_ID_Registro_Acceso" AND A."Eliminado" = 'N';
    IF lv_sede IS NULL OR NOT (
          "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', lv_sede) = 'Y') THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT A."ID_Registro_Acceso", A."ID_Solicitud_Persona", S."ID_Solicitud", S."Codigo", A."ID_Catalogo_Sede",
           A."Fecha_Hora", A."Fecha_Hora_Sistema", A."Tipo_Movimiento", A."Resultado", A."Es_Registro_Tardio",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           PE."Numero_Documento", S."Empresa_Visitante",
           CAST(U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" AS VARCHAR),
           A."Observacion", D."ID_Desviacion", D."Codigo"
      FROM "CAF_Registro_Acceso" A
      JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = A."ID_Solicitud_Persona"
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = A."ID_Usuario_Vigilante"
      LEFT JOIN "CAF_Desviacion" D ON D."ID_Registro_Acceso" = A."ID_Registro_Acceso" AND D."Eliminado" = 'N'
     WHERE A."ID_Registro_Acceso" = "HV_ID_Registro_Acceso";
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR"(
    "HV_UsuarioID"          BIGINT,
    "HV_ID_Registro_Acceso" BIGINT
)
RETURNS TABLE ("ID_Catalogo_Item_Checklist" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Es_Critico" CHAR(1),
               "Cumple" CHAR(1), "Orden" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE lv_sede BIGINT;
BEGIN
    -- V1.0 2026-10-17
    SELECT A."ID_Catalogo_Sede" INTO lv_sede FROM "CAF_Registro_Acceso" A
     WHERE A."ID_Registro_Acceso" = "HV_ID_Registro_Acceso" AND A."Eliminado" = 'N';
    IF lv_sede IS NULL OR NOT (
          "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', lv_sede) = 'Y') THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT I."ID_Catalogo_Item_Checklist", I."Codigo", I."Descripcion", I."Es_Critico", C."Cumple", I."Orden"
      FROM "CAF_Registro_Checklist" C
      JOIN "Catalogo_Item_Checklist" I ON I."ID_Catalogo_Item_Checklist" = C."ID_Catalogo_Item_Checklist"
     WHERE C."ID_Registro_Acceso" = "HV_ID_Registro_Acceso" AND C."Eliminado" = 'N'
     ORDER BY I."Orden", I."ID_Catalogo_Item_Checklist";
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CAF_RESPALDO_LISTAR_POR_PERSONA
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_RESPALDO_LISTAR_POR_PERSONA"(
    "HV_UsuarioID"            BIGINT,
    "HV_ID_Solicitud_Persona" BIGINT
)
RETURNS TABLE ("ID_Respaldo" BIGINT, "Categoria" VARCHAR, "Tipo_Respaldo" VARCHAR, "Numero_Documento" VARCHAR,
               "Fecha_Hora" TIMESTAMP, "Vigilante_Nombre" VARCHAR, "Observacion" VARCHAR, "Cantidad_Personas" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE lv_sede BIGINT;
BEGIN
    -- V1.0 2026-10-17
    SELECT S."ID_Catalogo_Sede" INTO lv_sede
      FROM "CAF_Solicitud_Persona" P JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
     WHERE P."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND P."Eliminado" = 'N' AND S."Eliminado" = 'N';
    IF lv_sede IS NULL OR NOT (
          "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', lv_sede) = 'Y') THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT RS."ID_Respaldo", RS."Categoria", RS."Tipo_Respaldo", RS."Numero_Documento", RS."Fecha_Hora",
           CAST(U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" AS VARCHAR),
           RS."Observacion",
           (SELECT COUNT(*) FROM "CAF_Respaldo_Persona" X WHERE X."ID_Respaldo" = RS."ID_Respaldo" AND X."Eliminado" = 'N')
      FROM "CAF_Respaldo_Persona" RP
      JOIN "CAF_Respaldo" RS ON RS."ID_Respaldo" = RP."ID_Respaldo" AND RS."Eliminado" = 'N'
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = RS."ID_Usuario_Vigilante"
     WHERE RP."ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND RP."Eliminado" = 'N'
     ORDER BY RS."Fecha_Hora" DESC, RS."ID_Respaldo" DESC;
END;
$$;

-- -----------------------------------------------------------------------------
-- 7. ERP_CAF_DESVIACION_LISTAR
--    HV_Estado: POR_REVISAR, REVISADA o nulo (todas). Primero las POR_REVISAR, de la más
--    antigua a la más reciente; luego las revisadas, de la más reciente a la más antigua.
--    Fechas nulas = sin límite (se filtra por la fecha del movimiento).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_DESVIACION_LISTAR"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT,
    "HV_Estado"           VARCHAR DEFAULT NULL,
    "HV_Fecha_Desde"      DATE    DEFAULT NULL,
    "HV_Fecha_Hasta"      DATE    DEFAULT NULL,
    "HV_Texto"            VARCHAR DEFAULT NULL
)
RETURNS TABLE ("ID_Desviacion" BIGINT, "Codigo" VARCHAR, "ID_Registro_Acceso" BIGINT, "Tipo_Movimiento" VARCHAR,
               "Resultado" VARCHAR, "Fecha_Hora" TIMESTAMP, "Persona_Nombre" VARCHAR, "Numero_Documento" VARCHAR,
               "Empresa_Visitante" VARCHAR, "Codigo_Solicitud" VARCHAR, "Descripcion" VARCHAR,
               "Tratamiento" VARCHAR, "Coordinador_Nombre" VARCHAR, "Estado" VARCHAR, "Fecha_Conformidad" TIMESTAMP)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_est VARCHAR(20)  := UPPER(TRIM(COALESCE("HV_Estado", '')));
    lv_txt VARCHAR(300) := "ERP_CAF_FN_NORMALIZAR"(TRIM(COALESCE("HV_Texto", '')));
BEGIN
    -- V1.0 2026-10-17
    IF "HV_ID_Catalogo_Sede" IS NULL OR NOT (
          "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_DESVIACION_CONFORMIDAD', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_DESVIACION_REGISTRAR', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', "HV_ID_Catalogo_Sede") = 'Y') THEN
        RETURN;
    END IF;
    IF lv_est NOT IN ('', 'POR_REVISAR', 'REVISADA') THEN RETURN; END IF;
    RETURN QUERY
    SELECT D."ID_Desviacion", D."Codigo", A."ID_Registro_Acceso", A."Tipo_Movimiento", A."Resultado", A."Fecha_Hora",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           PE."Numero_Documento", S."Empresa_Visitante", S."Codigo", D."Descripcion",
           CAST(CASE WHEN T."Es_Otro" = 'Y' THEN T."Descripcion" || ': ' || COALESCE(D."Tratamiento_Detalle", '') ELSE T."Descripcion" END AS VARCHAR),
           CAST(C."Apellido_Paterno" || COALESCE(' ' || C."Apellido_Materno", '') || ', ' || C."Nombres" AS VARCHAR),
           D."Estado", D."Fecha_Conformidad"
      FROM "CAF_Desviacion" D
      JOIN "CAF_Registro_Acceso" A ON A."ID_Registro_Acceso" = D."ID_Registro_Acceso"
      JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = A."ID_Solicitud_Persona"
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      JOIN "Catalogo_Tratamiento_Desviacion" T ON T."ID_Catalogo_Tratamiento_Desviacion" = D."ID_Catalogo_Tratamiento_Desviacion"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" C ON C."ID_Usuario" = D."ID_Usuario_Coordinador_Consultado"
     WHERE D."Eliminado" = 'N' AND A."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
       AND (lv_est = '' OR D."Estado" = lv_est)
       AND ("HV_Fecha_Desde" IS NULL OR CAST(A."Fecha_Hora" AS DATE) >= "HV_Fecha_Desde")
       AND ("HV_Fecha_Hasta" IS NULL OR CAST(A."Fecha_Hora" AS DATE) <= "HV_Fecha_Hasta")
       AND (lv_txt = '' OR "ERP_CAF_FN_NORMALIZAR"(D."Codigo" || ' ' || PE."Numero_Documento" || ' ' || PE."Apellido_Paterno" || ' '
                                                    || COALESCE(PE."Apellido_Materno", '') || ' ' || PE."Nombres" || ' '
                                                    || COALESCE(S."Empresa_Visitante", '') || ' ' || S."Codigo") LIKE '%' || lv_txt || '%')
     ORDER BY CASE D."Estado" WHEN 'POR_REVISAR' THEN 0 ELSE 1 END,
              CASE D."Estado" WHEN 'POR_REVISAR' THEN EXTRACT(EPOCH FROM A."Fecha_Hora") ELSE -EXTRACT(EPOCH FROM A."Fecha_Hora") END,
              D."ID_Desviacion";
END;
$$;

-- -----------------------------------------------------------------------------
-- 8. ERP_CAF_DESVIACION_DETALLE
--    Puede_Dar_Conformidad repite la regla de ERP_CAF_DESVIACION_CONFORMIDAD_DAR (D-56).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_DESVIACION_DETALLE"(
    "HV_UsuarioID"     BIGINT,
    "HV_ID_Desviacion" BIGINT
)
RETURNS TABLE ("ID_Desviacion" BIGINT, "Codigo" VARCHAR, "ID_Registro_Acceso" BIGINT, "ID_Solicitud" BIGINT,
               "Codigo_Solicitud" VARCHAR, "Tipo_Movimiento" VARCHAR, "Resultado" VARCHAR, "Fecha_Hora" TIMESTAMP,
               "Persona_Nombre" VARCHAR, "Numero_Documento" VARCHAR, "Empresa_Visitante" VARCHAR,
               "Descripcion" VARCHAR, "ID_Catalogo_Tratamiento_Desviacion" BIGINT, "Tratamiento" VARCHAR,
               "Tratamiento_Detalle" VARCHAR, "ID_Usuario_Coordinador_Consultado" BIGINT, "Coordinador_Nombre" VARCHAR,
               "Registrado_Por_Nombre" VARCHAR, "Estado" VARCHAR, "Conformidad_Nombre" VARCHAR,
               "Fecha_Conformidad" TIMESTAMP, "Comentario_Conformidad" VARCHAR, "ID_Incidencia" BIGINT,
               "Puede_Dar_Conformidad" CHAR(1), "Motivo_No_Conformidad" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE lv_sede BIGINT; lv_conf CHAR(1);
BEGIN
    -- V1.0 2026-10-17
    SELECT A."ID_Catalogo_Sede" INTO lv_sede
      FROM "CAF_Desviacion" D JOIN "CAF_Registro_Acceso" A ON A."ID_Registro_Acceso" = D."ID_Registro_Acceso"
     WHERE D."ID_Desviacion" = "HV_ID_Desviacion" AND D."Eliminado" = 'N';
    IF lv_sede IS NULL THEN RETURN; END IF;
    lv_conf := "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_DESVIACION_CONFORMIDAD', lv_sede);
    IF NOT (lv_conf = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_DESVIACION_REGISTRAR', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', lv_sede) = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', lv_sede) = 'Y') THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT D."ID_Desviacion", D."Codigo", A."ID_Registro_Acceso", S."ID_Solicitud", S."Codigo", A."Tipo_Movimiento",
           A."Resultado", A."Fecha_Hora",
           CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR),
           PE."Numero_Documento", S."Empresa_Visitante", D."Descripcion",
           T."ID_Catalogo_Tratamiento_Desviacion", T."Descripcion", D."Tratamiento_Detalle",
           D."ID_Usuario_Coordinador_Consultado",
           CAST(C."Apellido_Paterno" || COALESCE(' ' || C."Apellido_Materno", '') || ', ' || C."Nombres" AS VARCHAR),
           CAST(V."Apellido_Paterno" || COALESCE(' ' || V."Apellido_Materno", '') || ', ' || V."Nombres" AS VARCHAR),
           D."Estado",
           CAST(K."Apellido_Paterno" || COALESCE(' ' || K."Apellido_Materno", '') || ', ' || K."Nombres" AS VARCHAR),
           D."Fecha_Conformidad", D."Comentario_Conformidad", D."ID_Incidencia",
           CAST(CASE WHEN lv_conf = 'Y' AND D."Estado" = 'POR_REVISAR' THEN 'Y' ELSE 'N' END AS CHAR(1)),
           CAST(CASE WHEN lv_conf <> 'Y' THEN 'No tiene permiso para dar conformidad.'
                     WHEN D."Estado" = 'REVISADA' THEN 'La desviación ya fue revisada.'
                     ELSE NULL END AS VARCHAR)
      FROM "CAF_Desviacion" D
      JOIN "CAF_Registro_Acceso" A ON A."ID_Registro_Acceso" = D."ID_Registro_Acceso"
      JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = A."ID_Solicitud_Persona"
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = P."ID_Solicitud"
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
      JOIN "Catalogo_Tratamiento_Desviacion" T ON T."ID_Catalogo_Tratamiento_Desviacion" = D."ID_Catalogo_Tratamiento_Desviacion"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" C ON C."ID_Usuario" = D."ID_Usuario_Coordinador_Consultado"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" V ON V."ID_Usuario" = A."ID_Usuario_Vigilante"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" K ON K."ID_Usuario" = D."ID_Usuario_Conformidad"
     WHERE D."ID_Desviacion" = "HV_ID_Desviacion";
END;
$$;

-- -----------------------------------------------------------------------------
-- 9. ERP_CAF_DESVIACION_CONTADORES
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_DESVIACION_CONTADORES"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT
)
RETURNS TABLE ("Por_Revisar" BIGINT, "Revisadas" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-17
    IF "HV_ID_Catalogo_Sede" IS NULL OR NOT (
          "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_DESVIACION_CONFORMIDAD', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_DESVIACION_REGISTRAR', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_VER', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_REPORTE_VER', "HV_ID_Catalogo_Sede") = 'Y') THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT CAST(COALESCE(SUM(CASE WHEN D."Estado" = 'POR_REVISAR' THEN 1 ELSE 0 END), 0) AS BIGINT),
           CAST(COALESCE(SUM(CASE WHEN D."Estado" = 'REVISADA' THEN 1 ELSE 0 END), 0) AS BIGINT)
      FROM "CAF_Desviacion" D JOIN "CAF_Registro_Acceso" A ON A."ID_Registro_Acceso" = D."ID_Registro_Acceso"
     WHERE D."Eliminado" = 'N' AND A."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede";
END;
$$;

-- -----------------------------------------------------------------------------
-- 10. ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN
--     Usuarios activos con PER_CAF_DESVIACION_CONFORMIDAD en la sede (a quienes Vigilancia puede consultar).
--     Lo piden quienes registran en portería o desviaciones.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN"(
    "HV_UsuarioID"        BIGINT,
    "HV_ID_Catalogo_Sede" BIGINT
)
RETURNS TABLE ("ID_Usuario" BIGINT, "Nombre" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-17
    IF "HV_ID_Catalogo_Sede" IS NULL OR NOT (
          "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PORTERIA_REGISTRAR', "HV_ID_Catalogo_Sede") = 'Y'
       OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_DESVIACION_REGISTRAR', "HV_ID_Catalogo_Sede") = 'Y') THEN
        RETURN;
    END IF;
    RETURN QUERY
    SELECT U."ID_Usuario",
           CAST(U."Apellido_Paterno" || COALESCE(' ' || U."Apellido_Materno", '') || ', ' || U."Nombres" AS VARCHAR)
      FROM "CAF_GOVERNANCE"."Usuario" U
     WHERE U."Eliminado" = 'N' AND U."Activo" = 'Y'
       AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"(U."ID_Usuario", 'PER_CAF_DESVIACION_CONFORMIDAD', "HV_ID_Catalogo_Sede") = 'Y'
     ORDER BY U."Apellido_Paterno", U."Nombres", U."ID_Usuario";
END;
$$;

-- -----------------------------------------------------------------------------
-- 11. ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN
--     HV_Etapa: INGRESO o SALIDA. Incluye el efecto que produce cada tratamiento
--     (para «Otro» es NULL: lo elige Vigilancia).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN"(
    "HV_Etapa" VARCHAR
)
RETURNS TABLE ("ID_Catalogo_Tratamiento_Desviacion" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR,
               "Es_Otro" CHAR(1), "Resultado" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE lv_etapa VARCHAR(10) := UPPER(TRIM(COALESCE("HV_Etapa", '')));
BEGIN
    -- V1.0 2026-10-17
    IF lv_etapa NOT IN ('INGRESO','SALIDA') THEN RETURN; END IF;
    RETURN QUERY
    SELECT T."ID_Catalogo_Tratamiento_Desviacion", T."Codigo", T."Descripcion", T."Es_Otro",
           CAST(CASE lv_etapa WHEN 'INGRESO' THEN T."Resultado_Ingreso" ELSE T."Resultado_Salida" END AS VARCHAR)
      FROM "Catalogo_Tratamiento_Desviacion" T
     WHERE T."Eliminado" = 'N' AND T."Activo" = 'Y'
       AND ((lv_etapa = 'INGRESO' AND T."Aplica_Ingreso" = 'Y') OR (lv_etapa = 'SALIDA' AND T."Aplica_Salida" = 'Y'))
     ORDER BY T."Orden", T."ID_Catalogo_Tratamiento_Desviacion";
END;
$$;
