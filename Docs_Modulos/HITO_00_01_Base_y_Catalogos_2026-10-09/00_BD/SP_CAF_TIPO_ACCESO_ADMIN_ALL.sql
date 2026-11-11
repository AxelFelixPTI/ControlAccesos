-- =============================================================================
-- Archivo : SP_CAF_TIPO_ACCESO_ADMIN_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD
-- Versión : V1.0 2026-11-11 (D-232)
-- Qué hace: apoyo de la pantalla de administración «Tipos de ingreso» (Catálogos). Crear/editar/activar usa
--   ERP_CATALOGO_TIPO_ACCESO_CREAR / _ACTUALIZAR (ya existen). Este archivo agrega:
--   1 ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR  tipos con sus subtipos, pasos de aprobación, ítems de checklist y solicitudes
--   2 ERP_CAF_SUBTIPO_LISTAR            subtipos de persona por tipo (los define el desarrollo con el flujo)
--   3 ERP_CAF_TIPO_ACCESO_PREPARAR      deja listo un tipo NUEVO: copia del tipo «Visita externa» sus pasos de aprobación y su checklist
--                                       (si el tipo aún no tiene). Es el flujo estándar de visitante.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

CREATE OR REPLACE FUNCTION "ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR"()
RETURNS TABLE ("ID_Catalogo_Tipo_Acceso" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Requiere_Aprobacion" CHAR(1), "Disponible" CHAR(1),
               "Orden" BIGINT, "Activo" CHAR(1), "Subtipos" VARCHAR, "Pasos" BIGINT, "Items" BIGINT, "Solicitudes" BIGINT)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-11
    RETURN QUERY
    SELECT T."ID_Catalogo_Tipo_Acceso", T."Codigo", T."Descripcion", T."Requiere_Aprobacion", T."Disponible", T."Orden", T."Activo",
           CAST((SELECT STRING_AGG(X."Descripcion", ', ' ORDER BY X."Orden", X."ID_Tipo_Acceso_Subtipo") FROM "Tipo_Acceso_Subtipo" X
                  WHERE X."ID_Catalogo_Tipo_Acceso" = T."ID_Catalogo_Tipo_Acceso" AND X."Eliminado" = 'N') AS VARCHAR),
           CAST((SELECT COUNT(*) FROM "Tipo_Acceso_Paso_Aprobacion" P WHERE P."ID_Catalogo_Tipo_Acceso" = T."ID_Catalogo_Tipo_Acceso" AND P."Eliminado" = 'N') AS BIGINT),
           CAST((SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" I WHERE I."ID_Catalogo_Tipo_Acceso" = T."ID_Catalogo_Tipo_Acceso" AND I."Eliminado" = 'N') AS BIGINT),
           CAST((SELECT COUNT(*) FROM "CAF_Solicitud" S WHERE S."ID_Catalogo_Tipo_Acceso" = T."ID_Catalogo_Tipo_Acceso") AS BIGINT)
      FROM "Catalogo_Tipo_Acceso" T
     WHERE T."Eliminado" = 'N'
     ORDER BY T."Orden", T."ID_Catalogo_Tipo_Acceso";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR"();

CREATE OR REPLACE FUNCTION "ERP_CAF_SUBTIPO_LISTAR"()
RETURNS TABLE ("ID_Tipo_Acceso_Subtipo" BIGINT, "ID_Catalogo_Tipo_Acceso" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-11
    RETURN QUERY
    SELECT X."ID_Tipo_Acceso_Subtipo", X."ID_Catalogo_Tipo_Acceso", X."Codigo", X."Descripcion"
      FROM "Tipo_Acceso_Subtipo" X
     WHERE X."Eliminado" = 'N' AND X."Activo" = 'Y'
     ORDER BY X."ID_Catalogo_Tipo_Acceso", X."Orden", X."ID_Tipo_Acceso_Subtipo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CAF_SUBTIPO_LISTAR"();

CREATE OR REPLACE PROCEDURE "ERP_CAF_TIPO_ACCESO_PREPARAR"(
    IN    "HV_ID_Catalogo_Tipo_Acceso" BIGINT,
    IN    "HV_UsuarioID"               BIGINT,
    INOUT "HV_Codigo_Resp"             INT DEFAULT NULL,
    INOUT "HV_Mensaje"                 VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_n    INT := 0;
    lv_base BIGINT;
BEGIN
    -- V1.0 2026-11-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PREPARAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El tipo de ingreso no existe.'; RETURN; END IF;
        SELECT MAX("ID_Catalogo_Tipo_Acceso") INTO lv_base FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'VISITA_EXTERNA' AND "Eliminado" = 'N';
        IF lv_base IS NULL OR lv_base = "HV_ID_Catalogo_Tipo_Acceso" THEN
            "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Nada que preparar.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            INSERT INTO "Tipo_Acceso_Paso_Aprobacion" ("ID_Catalogo_Tipo_Acceso","Orden","Codigo","Descripcion","Alcance","Tipo_Aprobador","ID_Catalogo_Licencia","Condicion","Obligatorio","Activo","UsuarioID_Create")
            SELECT "HV_ID_Catalogo_Tipo_Acceso", P."Orden", P."Codigo", P."Descripcion", P."Alcance", P."Tipo_Aprobador", P."ID_Catalogo_Licencia", P."Condicion", P."Obligatorio", P."Activo", "HV_UsuarioID"
              FROM "Tipo_Acceso_Paso_Aprobacion" P
             WHERE P."ID_Catalogo_Tipo_Acceso" = lv_base AND P."Eliminado" = 'N'
               AND NOT EXISTS (SELECT 1 FROM "Tipo_Acceso_Paso_Aprobacion" Q WHERE Q."ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND Q."Codigo" = P."Codigo");
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            INSERT INTO "Tipo_Acceso_Item_Checklist" ("ID_Catalogo_Tipo_Acceso","ID_Catalogo_Item_Checklist","UsuarioID_Create")
            SELECT "HV_ID_Catalogo_Tipo_Acceso", I."ID_Catalogo_Item_Checklist", "HV_UsuarioID"
              FROM "Tipo_Acceso_Item_Checklist" I
             WHERE I."ID_Catalogo_Tipo_Acceso" = lv_base AND I."Eliminado" = 'N' AND I."ID_Tipo_Acceso_Subtipo" IS NULL
               AND NOT EXISTS (SELECT 1 FROM "Tipo_Acceso_Item_Checklist" Q WHERE Q."ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND Q."ID_Catalogo_Item_Checklist" = I."ID_Catalogo_Item_Checklist");
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de ingreso preparado con los pasos y el checklist de Visita externa.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PREPARAR';
    END;
END;
$$;
-- Prueba: CALL "ERP_CAF_TIPO_ACCESO_PREPARAR"(5, 0);
