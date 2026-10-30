-- =============================================================================
-- Archivo : SP_CAF_SOLICITUD_TIPO_INGRESO_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Hito    : 2 - Solicitud y aprobación | Fase 1 - Procedimientos (Entrega H: tipo de ingreso)   (D-187 a D-192)
-- Versión : V1.0 2026-10-29
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO2_ESCRITURA.sql, sección N)
-- Requiere: script 16 y SP_CAF_SOLICITUD_BASE_ALL.sql.
-- =============================================================================
-- 1 ERP_CAF_FN_PLACA_NORMALIZAR           placa en mayúsculas, sin espacios ni guiones (NULL si queda vacía)
-- 2 ERP_CAF_FN_TIPO_INGRESO_VALIDAR       reglas de los datos propios de cada tipo de ingreso; '' = correcto
-- 3 ERP_CAF_SOLICITUD_TIPOS_OPCIONES      tipos de ingreso activos y si se pueden usar (Proveedor: visible y bloqueado)
-- 4 ERP_CAF_SOLICITUD_SEDES_OPCIONES      sedes donde el usuario puede crear solicitudes, con zonas y si ofrecen cochera
--
-- La validación de la función 2 la usan CREAR y EDITAR_DATOS, así no se escribe dos veces.
-- Para sumar un tipo nuevo basta una rama más en la función 2 (y su formulario en la web); no cambian
-- las tablas ni los procedimientos de crear y editar.
-- HANA: la expresión regular (~, !~) pasa a LIKE_REGEXPR / NOT LIKE_REGEXPR; REGEXP_REPLACE a REPLACE_REGEXPR.
-- =============================================================================

SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- -----------------------------------------------------------------------------
-- 1. ERP_CAF_FN_PLACA_NORMALIZAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_PLACA_NORMALIZAR"("HV_Placa" VARCHAR)
RETURNS VARCHAR(15)
LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    -- V1.0 2026-10-29
    RETURN NULLIF(UPPER(REPLACE(REPLACE(TRIM(COALESCE("HV_Placa", '')), ' ', ''), '-', '')), '');
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. ERP_CAF_FN_TIPO_INGRESO_VALIDAR
--    Devuelve '' si todo está bien, o el mensaje para el solicitante.
--      * Cochera: solo en sedes con Aplica_Cochera = 'Y'; si se pide, la placa es obligatoria (5 a 8 letras o números).
--      * CONTRATISTA: contacto (nombre, teléfono, correos válidos) obligatorio; área en detalle opcional.
--      * Los demás tipos NO admiten datos de contratista (no se traslada un formulario al otro).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_FN_TIPO_INGRESO_VALIDAR"(
    "HV_Tipo_Codigo"        VARCHAR,
    "HV_ID_Catalogo_Sede"   BIGINT,
    "HV_Requiere_Cochera"   CHAR,
    "HV_Placa_Vehiculo"     VARCHAR,
    "HV_Area_Detalle"       VARCHAR,
    "HV_Contacto_Nombre"    VARCHAR,
    "HV_Contacto_Telefonos" VARCHAR,
    "HV_Contacto_Correos"   VARCHAR
)
RETURNS VARCHAR(250)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n      INT := 0;
    lv_aplica CHAR(1);
    lv_coch   CHAR(1);
    lv_placa  VARCHAR(15);
BEGIN
    -- V1.0 2026-10-29
    SELECT COUNT(*), MAX("Aplica_Cochera") INTO lv_n, lv_aplica
      FROM "CAF_GOVERNANCE"."Catalogo_Sede"
     WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N' AND "Activo" = 'Y';
    IF lv_n = 0 THEN RETURN 'La sede no existe o está inactiva.'; END IF;

    lv_coch  := COALESCE(NULLIF(UPPER(TRIM("HV_Requiere_Cochera")), ''), 'N');
    lv_placa := "ERP_CAF_FN_PLACA_NORMALIZAR"("HV_Placa_Vehiculo");
    IF lv_coch NOT IN ('Y','N') THEN RETURN 'Indique si requiere cochera (Sí o No).'; END IF;
    IF lv_coch = 'Y' THEN
        IF lv_aplica <> 'Y' THEN RETURN 'Esa sede no ofrece cochera.'; END IF;
        IF lv_placa IS NULL OR lv_placa !~ '^[A-Z0-9]{5,8}$' THEN
            RETURN 'Indique la placa del vehículo (de 5 a 8 letras o números).';
        END IF;
    ELSIF lv_placa IS NOT NULL THEN
        RETURN 'La placa solo se indica si requiere cochera.';
    END IF;

    IF "HV_Tipo_Codigo" = 'CONTRATISTA' THEN
        IF NULLIF(TRIM(COALESCE("HV_Contacto_Nombre", '')), '') IS NULL THEN
            RETURN 'Indique el nombre del contacto de la empresa contratista.';
        END IF;
        IF LENGTH(REGEXP_REPLACE(COALESCE("HV_Contacto_Telefonos", ''), '[^0-9]', '', 'g')) < 6 THEN
            RETURN 'Indique al menos un teléfono de contacto (mínimo 6 dígitos).';
        END IF;
        IF NULLIF(TRIM(COALESCE("HV_Contacto_Correos", '')), '') IS NULL OR "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Contacto_Correos") <> 'Y' THEN
            RETURN 'Indique correos de contacto válidos, separados por «;».';
        END IF;
    ELSIF NULLIF(TRIM(COALESCE("HV_Area_Detalle", '')), '') IS NOT NULL
       OR NULLIF(TRIM(COALESCE("HV_Contacto_Nombre", '')), '') IS NOT NULL
       OR NULLIF(TRIM(COALESCE("HV_Contacto_Telefonos", '')), '') IS NOT NULL
       OR NULLIF(TRIM(COALESCE("HV_Contacto_Correos", '')), '') IS NOT NULL THEN
        RETURN 'Esos datos corresponden solo al ingreso de contratistas.';
    END IF;
    RETURN '';
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. ERP_CAF_SOLICITUD_TIPOS_OPCIONES
--    Los tipos activos, en orden. Usable = el tipo está Disponible. Proveedor se devuelve (se ve) con
--    Usable = 'N' y su leyenda; no se puede enviar (CREAR lo rechaza igualmente).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"()
RETURNS TABLE ("ID_Catalogo_Tipo_Acceso" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Usable" CHAR, "Leyenda" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-10-29
    RETURN QUERY
    SELECT T."ID_Catalogo_Tipo_Acceso", T."Codigo", T."Descripcion", T."Disponible",
           CAST(CASE WHEN T."Disponible" = 'Y' THEN NULL ELSE 'Próximamente: pendiente de definición' END AS VARCHAR)
      FROM "Catalogo_Tipo_Acceso" T
     WHERE T."Eliminado" = 'N' AND T."Activo" = 'Y'
     ORDER BY T."Orden", T."ID_Catalogo_Tipo_Acceso";
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. ERP_CAF_SOLICITUD_SEDES_OPCIONES
--    Sedes activas donde el usuario tiene permiso para crear solicitudes (PER_CAF_SOLICITUD_PROPIA),
--    con la marca de cochera. Las zonas de cada sede las trae el catálogo de zonas (ya existente).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CAF_SOLICITUD_SEDES_OPCIONES"("HV_UsuarioID" BIGINT)
RETURNS TABLE ("ID_Catalogo_Sede" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Aplica_Cochera" CHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    -- V1.0 2026-10-29
    RETURN QUERY
    SELECT S."ID_Catalogo_Sede", S."Codigo", S."Descripcion", S."Aplica_Cochera"
      FROM "CAF_GOVERNANCE"."Catalogo_Sede" S
     WHERE S."Eliminado" = 'N' AND S."Activo" = 'Y'
       AND "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', S."ID_Catalogo_Sede") = 'Y'
     ORDER BY S."Orden", S."ID_Catalogo_Sede";
END;
$$;
