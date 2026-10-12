-- Docs_BD · TRIANONSATELITAL_CAF_PRODD · FUNCIONES Y PROCEDIMIENTOS · export 2026-10-12 11:36
-- ÍNDICE
--  1. ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR (procedimiento)
--  2. ERP_CAF_PERSONA_EXTERNA_CREAR (procedimiento)
--  3. ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO (función)
--  4. ERP_CAF_PERSONA_EXTERNA_LISTAR (función)
--  5. ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR (procedimiento)
--  6. ERP_CATALOGO_ITEM_CHECKLIST_CREAR (procedimiento)
--  7. ERP_CATALOGO_ITEM_CHECKLIST_DETALLE (función)
--  8. ERP_CATALOGO_ITEM_CHECKLIST_DROPDOWN (función)
--  9. ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR (procedimiento)
--  10. ERP_CATALOGO_ITEM_CHECKLIST_LISTAR (función)
--  11. ERP_CATALOGO_MOTIVO_VISITA_ACTUALIZAR (procedimiento)
--  12. ERP_CATALOGO_MOTIVO_VISITA_CREAR (procedimiento)
--  13. ERP_CATALOGO_MOTIVO_VISITA_DETALLE (función)
--  14. ERP_CATALOGO_MOTIVO_VISITA_DROPDOWN (función)
--  15. ERP_CATALOGO_MOTIVO_VISITA_ELIMINAR (procedimiento)
--  16. ERP_CATALOGO_MOTIVO_VISITA_LISTAR (función)
--  17. ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR (procedimiento)
--  18. ERP_CATALOGO_TIPO_ACCESO_CREAR (procedimiento)
--  19. ERP_CATALOGO_TIPO_ACCESO_DETALLE (función)
--  20. ERP_CATALOGO_TIPO_ACCESO_DROPDOWN (función)
--  21. ERP_CATALOGO_TIPO_ACCESO_ELIMINAR (procedimiento)
--  22. ERP_CATALOGO_TIPO_ACCESO_LISTAR (función)
--  23. ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR (procedimiento)
--  24. ERP_CATALOGO_TIPO_INCIDENCIA_CREAR (procedimiento)
--  25. ERP_CATALOGO_TIPO_INCIDENCIA_DETALLE (función)
--  26. ERP_CATALOGO_TIPO_INCIDENCIA_DROPDOWN (función)
--  27. ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR (procedimiento)
--  28. ERP_CATALOGO_TIPO_INCIDENCIA_LISTAR (función)
--  29. ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR (procedimiento)
--  30. ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR (procedimiento)
--  31. ERP_CATALOGO_TRATAMIENTO_DESVIACION_DETALLE (función)
--  32. ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN (función)
--  33. ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR (procedimiento)
--  34. ERP_CATALOGO_TRATAMIENTO_DESVIACION_LISTAR (función)
--  35. ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR (procedimiento)
--  36. ERP_CATALOGO_ZONA_ACCESO_CREAR (procedimiento)
--  37. ERP_CATALOGO_ZONA_ACCESO_DETALLE (función)
--  38. ERP_CATALOGO_ZONA_ACCESO_DROPDOWN (función)
--  39. ERP_CATALOGO_ZONA_ACCESO_ELIMINAR (procedimiento)
--  40. ERP_CATALOGO_ZONA_ACCESO_LISTAR (función)
--  41. ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR (procedimiento)
--  42. ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE (función)
--  43. ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR (procedimiento)

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR"(IN "HV_ID_Persona_Externa" bigint, IN "HV_ID_Catalogo_Tipo_Documento" bigint, IN "HV_Numero_Documento" character varying, IN "HV_Apellido_Paterno" character varying, IN "HV_Apellido_Materno" character varying, IN "HV_Nombres" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_min  BIGINT;
    lv_max  BIGINT;
    lv_solo CHAR(1);
    lv_n    INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR';
    BEGIN
        IF "HV_Apellido_Paterno" IS NULL OR LENGTH(TRIM("HV_Apellido_Paterno")) = 0
        OR "HV_Nombres" IS NULL OR LENGTH(TRIM("HV_Nombres")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Apellido paterno y nombres son obligatorios.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_Persona_Externa" WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no existe.'; RETURN;
        END IF;

        SELECT MAX("Longitud_Min"), MAX("Longitud_Max"), MAX("Solo_Numeros") INTO lv_min, lv_max, lv_solo
          FROM "CAF_GOVERNANCE"."Catalogo_Tipo_Documento"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_min IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de documento no existe o está inactivo.'; RETURN;
        END IF;
        IF "HV_Numero_Documento" IS NULL OR LENGTH(TRIM("HV_Numero_Documento")) NOT BETWEEN lv_min AND lv_max THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El documento debe tener entre ' || lv_min || ' y ' || lv_max || ' caracteres.'; RETURN;
        END IF;
        IF lv_solo = 'Y' AND LTRIM(TRIM("HV_Numero_Documento"), '0123456789') <> '' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El documento solo admite números.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_Persona_Externa"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Numero_Documento" = TRIM("HV_Numero_Documento")
           AND "ID_Persona_Externa" <> "HV_ID_Persona_Externa";
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otra persona con ese documento.'; RETURN;
        END IF;

        UPDATE "CAF_Persona_Externa"
           SET "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento", "Numero_Documento" = TRIM("HV_Numero_Documento"),
               "Apellido_Paterno" = TRIM("HV_Apellido_Paterno"), "Apellido_Materno" = NULLIF(TRIM("HV_Apellido_Materno"),''),
               "Nombres" = TRIM("HV_Nombres"), "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Persona actualizada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_PERSONA_EXTERNA_CREAR"(IN "HV_ID_Catalogo_Tipo_Documento" bigint, IN "HV_Numero_Documento" character varying, IN "HV_Apellido_Paterno" character varying, IN "HV_Apellido_Materno" character varying, IN "HV_Nombres" character varying, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Persona_Externa_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_min  BIGINT;
    lv_max  BIGINT;
    lv_solo CHAR(1);
    lv_n    INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_PERSONA_EXTERNA_CREAR';
    "HV_ID_Persona_Externa_Result" := 0;
    BEGIN
        -- Obligatorios
        IF "HV_Apellido_Paterno" IS NULL OR LENGTH(TRIM("HV_Apellido_Paterno")) = 0
        OR "HV_Nombres" IS NULL OR LENGTH(TRIM("HV_Nombres")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Apellido paterno y nombres son obligatorios.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        -- Documento según su tipo (schema transversal)
        SELECT MAX("Longitud_Min"), MAX("Longitud_Max"), MAX("Solo_Numeros") INTO lv_min, lv_max, lv_solo
          FROM "CAF_GOVERNANCE"."Catalogo_Tipo_Documento"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_min IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de documento no existe o está inactivo.'; RETURN;
        END IF;
        IF "HV_Numero_Documento" IS NULL OR LENGTH(TRIM("HV_Numero_Documento")) NOT BETWEEN lv_min AND lv_max THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El documento debe tener entre ' || lv_min || ' y ' || lv_max || ' caracteres.'; RETURN;
        END IF;
        IF lv_solo = 'Y' AND LTRIM(TRIM("HV_Numero_Documento"), '0123456789') <> '' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El documento solo admite números.'; RETURN;
        END IF;

        -- Duplicado (el UNIQUE es tipo + número)
        SELECT COUNT(*) INTO lv_n FROM "CAF_Persona_Externa"
         WHERE "ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento" AND "Numero_Documento" = TRIM("HV_Numero_Documento");
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe una persona con ese documento. Búsquela por documento y actualice sus datos.'; RETURN;
        END IF;

        INSERT INTO "CAF_Persona_Externa" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","UsuarioID_Create")
        VALUES ("HV_ID_Catalogo_Tipo_Documento", TRIM("HV_Numero_Documento"), TRIM("HV_Apellido_Paterno"),
                NULLIF(TRIM("HV_Apellido_Materno"),''), TRIM("HV_Nombres"), "HV_UsuarioID_Create")
        RETURNING "ID_Persona_Externa" INTO "HV_ID_Persona_Externa_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Persona registrada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_PERSONA_EXTERNA_CREAR';
        "HV_ID_Persona_Externa_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO"("HV_ID_Catalogo_Tipo_Documento" bigint, "HV_Numero_Documento" character varying)
 RETURNS TABLE("ID_Persona_Externa" bigint, "ID_Catalogo_Tipo_Documento" bigint, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Apellido_Paterno" character varying, "Apellido_Materno" character varying, "Nombres" character varying, "Nombre_Completo" character varying, "Fecha_Ultima_Visita" timestamp without time zone, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Persona_Externa", T0."ID_Catalogo_Tipo_Documento", TD."Codigo", T0."Numero_Documento",
           T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres",
           CAST(T0."Apellido_Paterno" || COALESCE(' ' || T0."Apellido_Materno", '') || ', ' || T0."Nombres" AS VARCHAR),
           T0."Fecha_Ultima_Visita", T0."Eliminado", T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "CAF_Persona_Externa" T0
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = T0."ID_Catalogo_Tipo_Documento"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1                 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Tipo_Documento" = "HV_ID_Catalogo_Tipo_Documento"
       AND T0."Numero_Documento" = TRIM("HV_Numero_Documento")
       AND T0."Eliminado" = 'N';
END;
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_PERSONA_EXTERNA_LISTAR"("HV_Filtro_Nombre" character varying DEFAULT NULL::character varying, "HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar)
 RETURNS TABLE("ID_Persona_Externa" bigint, "ID_Catalogo_Tipo_Documento" bigint, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Apellido_Paterno" character varying, "Apellido_Materno" character varying, "Nombres" character varying, "Nombre_Completo" character varying, "Fecha_Ultima_Visita" timestamp without time zone, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Persona_Externa", T0."ID_Catalogo_Tipo_Documento", TD."Codigo", T0."Numero_Documento",
           T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres",
           CAST(T0."Apellido_Paterno" || COALESCE(' ' || T0."Apellido_Materno", '') || ', ' || T0."Nombres" AS VARCHAR),
           T0."Fecha_Ultima_Visita", T0."Eliminado", T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "CAF_Persona_Externa" T0
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" TD ON TD."ID_Catalogo_Tipo_Documento" = T0."ID_Catalogo_Tipo_Documento"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1                 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
       AND ("HV_Filtro_Nombre" IS NULL OR UPPER(T0."Apellido_Paterno" || ' ' || COALESCE(T0."Apellido_Materno",'') || ' ' || T0."Nombres") LIKE '%' || UPPER(TRIM("HV_Filtro_Nombre")) || '%')
     ORDER BY T0."Apellido_Paterno", T0."Apellido_Materno", T0."Nombres";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR"(IN "HV_ID_Catalogo_Item_Checklist" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Ayuda" character varying, IN "HV_Etapa" character varying, IN "HV_Condicion" character varying, IN "HV_Es_Critico" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR';
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_Etapa" IS NULL OR UPPER(TRIM("HV_Etapa")) NOT IN ('INGRESO','SALIDA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La etapa debe ser INGRESO o SALIDA.'; RETURN;
        END IF;
        IF "HV_Condicion" IS NULL OR UPPER(TRIM("HV_Condicion")) NOT IN ('SIEMPRE','ZONA_EXIGE_SCTR','ZONA_EXIGE_EPP','TRAE_EQUIPOS','TRAE_HERRAMIENTAS') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La condición debe ser SIEMPRE, ZONA_EXIGE_SCTR, ZONA_EXIGE_EPP, TRAE_EQUIPOS o TRAE_HERRAMIENTAS.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Critico",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Critico debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Item_Checklist"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Item_Checklist" <> "HV_ID_Catalogo_Item_Checklist";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Item_Checklist"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Ayuda" = NULLIF(TRIM("HV_Ayuda"),''), "Etapa" = UPPER(TRIM("HV_Etapa")), "Condicion" = UPPER(TRIM("HV_Condicion")), "Es_Critico" = COALESCE("HV_Es_Critico",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ítem de checklist actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Ayuda" character varying, IN "HV_Etapa" character varying, IN "HV_Condicion" character varying, IN "HV_Es_Critico" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Item_Checklist_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_CREAR';
    "HV_ID_Catalogo_Item_Checklist_Result" := 0;
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_Etapa" IS NULL OR UPPER(TRIM("HV_Etapa")) NOT IN ('INGRESO','SALIDA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La etapa debe ser INGRESO o SALIDA.'; RETURN;
        END IF;
        IF "HV_Condicion" IS NULL OR UPPER(TRIM("HV_Condicion")) NOT IN ('SIEMPRE','ZONA_EXIGE_SCTR','ZONA_EXIGE_EPP','TRAE_EQUIPOS','TRAE_HERRAMIENTAS') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La condición debe ser SIEMPRE, ZONA_EXIGE_SCTR, ZONA_EXIGE_EPP, TRAE_EQUIPOS o TRAE_HERRAMIENTAS.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Critico",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Critico debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Item_Checklist"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Item_Checklist" ("Codigo","Descripcion","Ayuda","Etapa","Condicion","Es_Critico","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), NULLIF(TRIM("HV_Ayuda"),''), UPPER(TRIM("HV_Etapa")), UPPER(TRIM("HV_Condicion")), COALESCE("HV_Es_Critico",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Item_Checklist" INTO "HV_ID_Catalogo_Item_Checklist_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ítem de checklist registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_CREAR';
        "HV_ID_Catalogo_Item_Checklist_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_DETALLE"("HV_ID_Catalogo_Item_Checklist" bigint)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Ayuda" character varying, "Etapa" character varying, "Condicion" character varying, "Es_Critico" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Item_Checklist", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Ayuda", T0."Etapa", T0."Condicion", T0."Es_Critico", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Item_Checklist" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist";
END;
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_DROPDOWN"("HV_Etapa" character varying DEFAULT NULL::character varying)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Ayuda" character varying, "Etapa" character varying, "Condicion" character varying, "Es_Critico" character)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
DECLARE
    lv_etapa VARCHAR(10) := '%';
BEGIN
    -- V1.0 2026-10-11
    IF LENGTH(TRIM("HV_Etapa")) > 0 THEN
        lv_etapa := UPPER(TRIM("HV_Etapa"));
    END IF;
    RETURN QUERY
    SELECT T0."ID_Catalogo_Item_Checklist", T0."Codigo", T0."Descripcion", T0."Ayuda", T0."Etapa", T0."Condicion", T0."Es_Critico"
      FROM "Catalogo_Item_Checklist" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y' AND T0."Etapa" LIKE lv_etapa
     ORDER BY T0."Etapa", T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR"(IN "HV_ID_Catalogo_Item_Checklist" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_en_uso FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' tipo(s) de acceso. Desactívelo en vez de eliminarlo.'; RETURN;
        END IF;
        -- Uso por tablas de los Hitos 2 a 4 (CAF_Registro_Checklist): se agrega aquí cuando existan.

        UPDATE "Catalogo_Item_Checklist"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ítem de checklist eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ITEM_CHECKLIST_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Ayuda" character varying, "Etapa" character varying, "Condicion" character varying, "Es_Critico" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Item_Checklist", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Ayuda", T0."Etapa", T0."Condicion", T0."Es_Critico", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Item_Checklist" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Etapa", T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_ACTUALIZAR"(IN "HV_ID_Catalogo_Motivo_Visita" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_ACTUALIZAR';
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Motivo_Visita" WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Motivo_Visita"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Motivo_Visita" <> "HV_ID_Catalogo_Motivo_Visita";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Motivo_Visita"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Es_Otro" = COALESCE("HV_Es_Otro",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Motivo de visita actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_ACTUALIZAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Motivo_Visita_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_CREAR';
    "HV_ID_Catalogo_Motivo_Visita_Result" := 0;
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Motivo_Visita"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Motivo_Visita" ("Codigo","Descripcion","Es_Otro","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), COALESCE("HV_Es_Otro",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Motivo_Visita" INTO "HV_ID_Catalogo_Motivo_Visita_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Motivo de visita registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_CREAR';
        "HV_ID_Catalogo_Motivo_Visita_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_DETALLE"("HV_ID_Catalogo_Motivo_Visita" bigint)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Motivo_Visita", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Motivo_Visita" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita";
END;
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_DROPDOWN"()
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Es_Otro" character)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Motivo_Visita", T0."Codigo", T0."Descripcion", T0."Es_Otro"
      FROM "Catalogo_Motivo_Visita" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_ELIMINAR"(IN "HV_ID_Catalogo_Motivo_Visita" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Motivo_Visita" WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        -- Uso por tablas de los Hitos 2 a 4 (CAF_Solicitud): se agrega aquí cuando existan.

        UPDATE "Catalogo_Motivo_Visita"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Motivo de visita eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_MOTIVO_VISITA_ELIMINAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_MOTIVO_VISITA_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Motivo_Visita", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Motivo_Visita" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR"(IN "HV_ID_Catalogo_Tipo_Acceso" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Requiere_Aprobacion" character, IN "HV_Disponible" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR';
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Requiere_Aprobacion",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Requiere_Aprobacion debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Disponible",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Disponible debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tipo_Acceso"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Tipo_Acceso" <> "HV_ID_Catalogo_Tipo_Acceso";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Tipo_Acceso"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Requiere_Aprobacion" = COALESCE("HV_Requiere_Aprobacion",'Y'), "Disponible" = COALESCE("HV_Disponible",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de acceso actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Requiere_Aprobacion" character, IN "HV_Disponible" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Tipo_Acceso_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_CREAR';
    "HV_ID_Catalogo_Tipo_Acceso_Result" := 0;
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Requiere_Aprobacion",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Requiere_Aprobacion debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Disponible",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Disponible debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tipo_Acceso"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Tipo_Acceso" ("Codigo","Descripcion","Requiere_Aprobacion","Disponible","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), COALESCE("HV_Requiere_Aprobacion",'Y'), COALESCE("HV_Disponible",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Tipo_Acceso" INTO "HV_ID_Catalogo_Tipo_Acceso_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de acceso registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_CREAR';
        "HV_ID_Catalogo_Tipo_Acceso_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_DETALLE"("HV_ID_Catalogo_Tipo_Acceso" bigint)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Requiere_Aprobacion" character, "Disponible" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Acceso", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Requiere_Aprobacion", T0."Disponible", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tipo_Acceso" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso";
END;
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_DROPDOWN"()
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Requiere_Aprobacion" character, "Disponible" character)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Acceso", T0."Codigo", T0."Descripcion", T0."Requiere_Aprobacion", T0."Disponible"
      FROM "Catalogo_Tipo_Acceso" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_ELIMINAR"(IN "HV_ID_Catalogo_Tipo_Acceso" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_en_uso FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' ítem(s) de checklist asignado(s). Desactívelo en vez de eliminarlo.'; RETURN;
        END IF;
        -- Uso por tablas de los Hitos 2 a 4 (CAF_Solicitud): se agrega aquí cuando existan.

        UPDATE "Catalogo_Tipo_Acceso"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de acceso eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_ACCESO_ELIMINAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_ACCESO_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Requiere_Aprobacion" character, "Disponible" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Acceso", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Requiere_Aprobacion", T0."Disponible", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tipo_Acceso" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR"(IN "HV_ID_Catalogo_Tipo_Incidencia" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR';
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tipo_Incidencia" WHERE "ID_Catalogo_Tipo_Incidencia" = "HV_ID_Catalogo_Tipo_Incidencia" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tipo_Incidencia"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Tipo_Incidencia" <> "HV_ID_Catalogo_Tipo_Incidencia";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Tipo_Incidencia"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Es_Otro" = COALESCE("HV_Es_Otro",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tipo_Incidencia" = "HV_ID_Catalogo_Tipo_Incidencia";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de incidencia actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Tipo_Incidencia_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_CREAR';
    "HV_ID_Catalogo_Tipo_Incidencia_Result" := 0;
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tipo_Incidencia"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Tipo_Incidencia" ("Codigo","Descripcion","Es_Otro","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), COALESCE("HV_Es_Otro",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Tipo_Incidencia" INTO "HV_ID_Catalogo_Tipo_Incidencia_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de incidencia registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_CREAR';
        "HV_ID_Catalogo_Tipo_Incidencia_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_DETALLE"("HV_ID_Catalogo_Tipo_Incidencia" bigint)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Incidencia", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tipo_Incidencia" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Tipo_Incidencia" = "HV_ID_Catalogo_Tipo_Incidencia";
END;
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_DROPDOWN"()
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Es_Otro" character)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Incidencia", T0."Codigo", T0."Descripcion", T0."Es_Otro"
      FROM "Catalogo_Tipo_Incidencia" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR"(IN "HV_ID_Catalogo_Tipo_Incidencia" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tipo_Incidencia" WHERE "ID_Catalogo_Tipo_Incidencia" = "HV_ID_Catalogo_Tipo_Incidencia" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        -- Uso por tablas de los Hitos 2 a 4 (CAF_Incidencia): se agrega aquí cuando existan.

        UPDATE "Catalogo_Tipo_Incidencia"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tipo_Incidencia" = "HV_ID_Catalogo_Tipo_Incidencia";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tipo de incidencia eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TIPO_INCIDENCIA_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tipo_Incidencia", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tipo_Incidencia" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR"(IN "HV_ID_Catalogo_Tratamiento_Desviacion" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Aplica_Ingreso" character, IN "HV_Aplica_Salida" character, IN "HV_Resultado_Ingreso" character varying, IN "HV_Resultado_Salida" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR';
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Ingreso",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Aplica_Ingreso debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Salida",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Aplica_Salida debe ser Y o N.'; RETURN;
        END IF;
        IF NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL AND UPPER(TRIM("HV_Resultado_Ingreso")) NOT IN ('INGRESA','INGRESA_RESTRINGIDO','NO_INGRESA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El resultado de ingreso debe ser INGRESA, INGRESA_RESTRINGIDO o NO_INGRESA.'; RETURN;
        END IF;
        IF NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL AND UPPER(TRIM("HV_Resultado_Salida")) NOT IN ('SALE','SALE_RETIENE_ELEMENTO') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El resultado de salida debe ser SALE o SALE_RETIENE_ELEMENTO.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Ingreso",'N') = 'N' AND COALESCE("HV_Aplica_Salida",'N') = 'N' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tratamiento debe aplicar al ingreso, a la salida o a ambos.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Ingreso",'N') = 'N' AND NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Si no aplica al ingreso, no lleva resultado de ingreso.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Salida",'N') = 'N' AND NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Si no aplica a la salida, no lleva resultado de salida.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'Y'
           AND (NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL OR NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tratamiento "Otro" no lleva resultado fijo: Vigilancia lo elige al registrar.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'N' AND COALESCE("HV_Aplica_Ingreso",'N') = 'Y' AND NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el resultado al ingreso.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'N' AND COALESCE("HV_Aplica_Salida",'N') = 'Y' AND NULLIF(TRIM("HV_Resultado_Salida"),'') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el resultado a la salida.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tratamiento_Desviacion" WHERE "ID_Catalogo_Tratamiento_Desviacion" = "HV_ID_Catalogo_Tratamiento_Desviacion" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tratamiento_Desviacion"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Tratamiento_Desviacion" <> "HV_ID_Catalogo_Tratamiento_Desviacion";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
        END IF;

        UPDATE "Catalogo_Tratamiento_Desviacion"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "Aplica_Ingreso" = COALESCE("HV_Aplica_Ingreso",'N'), "Aplica_Salida" = COALESCE("HV_Aplica_Salida",'N'), "Resultado_Ingreso" = NULLIF(UPPER(TRIM("HV_Resultado_Ingreso")),''), "Resultado_Salida" = NULLIF(UPPER(TRIM("HV_Resultado_Salida")),''), "Es_Otro" = COALESCE("HV_Es_Otro",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tratamiento_Desviacion" = "HV_ID_Catalogo_Tratamiento_Desviacion";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tratamiento actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Aplica_Ingreso" character, IN "HV_Aplica_Salida" character, IN "HV_Resultado_Ingreso" character varying, IN "HV_Resultado_Salida" character varying, IN "HV_Es_Otro" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Tratamiento_Desviacion_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_duplicado INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR';
    "HV_ID_Catalogo_Tratamiento_Desviacion_Result" := 0;
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Ingreso",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Aplica_Ingreso debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Salida",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Aplica_Salida debe ser Y o N.'; RETURN;
        END IF;
        IF NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL AND UPPER(TRIM("HV_Resultado_Ingreso")) NOT IN ('INGRESA','INGRESA_RESTRINGIDO','NO_INGRESA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El resultado de ingreso debe ser INGRESA, INGRESA_RESTRINGIDO o NO_INGRESA.'; RETURN;
        END IF;
        IF NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL AND UPPER(TRIM("HV_Resultado_Salida")) NOT IN ('SALE','SALE_RETIENE_ELEMENTO') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El resultado de salida debe ser SALE o SALE_RETIENE_ELEMENTO.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Es_Otro debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Ingreso",'N') = 'N' AND COALESCE("HV_Aplica_Salida",'N') = 'N' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tratamiento debe aplicar al ingreso, a la salida o a ambos.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Ingreso",'N') = 'N' AND NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Si no aplica al ingreso, no lleva resultado de ingreso.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Salida",'N') = 'N' AND NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Si no aplica a la salida, no lleva resultado de salida.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'Y'
           AND (NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL OR NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tratamiento "Otro" no lleva resultado fijo: Vigilancia lo elige al registrar.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'N' AND COALESCE("HV_Aplica_Ingreso",'N') = 'Y' AND NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el resultado al ingreso.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'N' AND COALESCE("HV_Aplica_Salida",'N') = 'Y' AND NULLIF(TRIM("HV_Resultado_Salida"),'') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el resultado a la salida.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Tratamiento_Desviacion"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Tratamiento_Desviacion" ("Codigo","Descripcion","Aplica_Ingreso","Aplica_Salida","Resultado_Ingreso","Resultado_Salida","Es_Otro","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), COALESCE("HV_Aplica_Ingreso",'N'), COALESCE("HV_Aplica_Salida",'N'), NULLIF(UPPER(TRIM("HV_Resultado_Ingreso")),''), NULLIF(UPPER(TRIM("HV_Resultado_Salida")),''), COALESCE("HV_Es_Otro",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Tratamiento_Desviacion" INTO "HV_ID_Catalogo_Tratamiento_Desviacion_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tratamiento registrado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR';
        "HV_ID_Catalogo_Tratamiento_Desviacion_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_DETALLE"("HV_ID_Catalogo_Tratamiento_Desviacion" bigint)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Aplica_Ingreso" character, "Aplica_Salida" character, "Resultado_Ingreso" character varying, "Resultado_Salida" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tratamiento_Desviacion", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Aplica_Ingreso", T0."Aplica_Salida", T0."Resultado_Ingreso", T0."Resultado_Salida", T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tratamiento_Desviacion" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Tratamiento_Desviacion" = "HV_ID_Catalogo_Tratamiento_Desviacion";
END;
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN"("HV_Etapa" character varying DEFAULT NULL::character varying)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Aplica_Ingreso" character, "Aplica_Salida" character, "Resultado_Ingreso" character varying, "Resultado_Salida" character varying, "Es_Otro" character)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
DECLARE
    lv_ingreso VARCHAR(1) := '%';
    lv_salida  VARCHAR(1) := '%';
BEGIN
    -- V1.0 2026-10-11
    IF UPPER(TRIM("HV_Etapa")) = 'INGRESO' THEN
        lv_ingreso := 'Y';
    ELSIF UPPER(TRIM("HV_Etapa")) = 'SALIDA' THEN
        lv_salida := 'Y';
    ELSIF LENGTH(TRIM("HV_Etapa")) > 0 THEN
        lv_ingreso := '~';   -- etapa desconocida: ninguna fila
    END IF;
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tratamiento_Desviacion", T0."Codigo", T0."Descripcion", T0."Aplica_Ingreso", T0."Aplica_Salida", T0."Resultado_Ingreso", T0."Resultado_Salida", T0."Es_Otro"
      FROM "Catalogo_Tratamiento_Desviacion" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y' AND T0."Aplica_Ingreso" LIKE lv_ingreso AND T0."Aplica_Salida" LIKE lv_salida
     ORDER BY T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR"(IN "HV_ID_Catalogo_Tratamiento_Desviacion" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Tratamiento_Desviacion" WHERE "ID_Catalogo_Tratamiento_Desviacion" = "HV_ID_Catalogo_Tratamiento_Desviacion" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        -- Uso por tablas de los Hitos 2 a 4 (CAF_Desviacion): se agrega aquí cuando existan.

        UPDATE "Catalogo_Tratamiento_Desviacion"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Tratamiento_Desviacion" = "HV_ID_Catalogo_Tratamiento_Desviacion";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Tratamiento eliminado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_TRATAMIENTO_DESVIACION_LISTAR"("HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "Aplica_Ingreso" character, "Aplica_Salida" character, "Resultado_Ingreso" character varying, "Resultado_Salida" character varying, "Es_Otro" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Tratamiento_Desviacion", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."Aplica_Ingreso", T0."Aplica_Salida", T0."Resultado_Ingreso", T0."Resultado_Salida", T0."Es_Otro", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Tratamiento_Desviacion" T0
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR"(IN "HV_ID_Catalogo_Zona_Acceso" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_ID_Catalogo_Sede" bigint, IN "HV_Tipo_Zona" character varying, IN "HV_Exige_SCTR" character, IN "HV_Exige_EPP" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
    lv_n         INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR';
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_Tipo_Zona" IS NULL OR UPPER(TRIM("HV_Tipo_Zona")) NOT IN ('ADMINISTRATIVA','OPERATIVA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de zona debe ser ADMINISTRATIVA u OPERATIVA.'; RETURN;
        END IF;
        IF COALESCE("HV_Exige_SCTR",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Exige_SCTR debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Exige_EPP",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Exige_EPP debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Zona_Acceso" WHERE "ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Catalogo_Sede"
         WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La sede no existe.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Zona_Acceso"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "ID_Catalogo_Zona_Acceso" <> "HV_ID_Catalogo_Zona_Acceso";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otra zona con ese código en esa sede.'; RETURN;
        END IF;

        UPDATE "Catalogo_Zona_Acceso"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede", "Tipo_Zona" = UPPER(TRIM("HV_Tipo_Zona")), "Exige_SCTR" = COALESCE("HV_Exige_SCTR",'N'), "Exige_EPP" = COALESCE("HV_Exige_EPP",'N'), 
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Zona actualizada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_CREAR"(IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_ID_Catalogo_Sede" bigint, IN "HV_Tipo_Zona" character varying, IN "HV_Exige_SCTR" character, IN "HV_Exige_EPP" character, IN "HV_Orden" bigint, IN "HV_Activo" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Catalogo_Zona_Acceso_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_duplicado INT := 0;
    lv_n         INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_CREAR';
    "HV_ID_Catalogo_Zona_Acceso_Result" := 0;
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_Tipo_Zona" IS NULL OR UPPER(TRIM("HV_Tipo_Zona")) NOT IN ('ADMINISTRATIVA','OPERATIVA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de zona debe ser ADMINISTRATIVA u OPERATIVA.'; RETURN;
        END IF;
        IF COALESCE("HV_Exige_SCTR",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Exige_SCTR debe ser Y o N.'; RETURN;
        END IF;
        IF COALESCE("HV_Exige_EPP",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Exige_EPP debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Catalogo_Sede"
         WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La sede no existe o está inactiva.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "Catalogo_Zona_Acceso"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe una zona con ese código en esa sede (puede estar eliminada).'; RETURN;
        END IF;

        INSERT INTO "Catalogo_Zona_Acceso" ("Codigo","Descripcion","ID_Catalogo_Sede","Tipo_Zona","Exige_SCTR","Exige_EPP","Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), "HV_ID_Catalogo_Sede", UPPER(TRIM("HV_Tipo_Zona")), COALESCE("HV_Exige_SCTR",'N'), COALESCE("HV_Exige_EPP",'N'), COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Catalogo_Zona_Acceso" INTO "HV_ID_Catalogo_Zona_Acceso_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Zona registrada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_CREAR';
        "HV_ID_Catalogo_Zona_Acceso_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_DETALLE"("HV_ID_Catalogo_Zona_Acceso" bigint)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "ID_Catalogo_Sede" bigint, "Codigo_Sede" character varying, "Sede" character varying, "Tipo_Zona" character varying, "Exige_SCTR" character, "Exige_EPP" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Zona_Acceso", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."ID_Catalogo_Sede", S."Codigo", S."Descripcion", T0."Tipo_Zona", T0."Exige_SCTR", T0."Exige_EPP", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Zona_Acceso" T0
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Sede" S ON S."ID_Catalogo_Sede" = T0."ID_Catalogo_Sede"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE T0."ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso";
END;
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_DROPDOWN"("HV_ID_Catalogo_Sede" bigint)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Zona" character varying, "Exige_SCTR" character, "Exige_EPP" character)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Zona_Acceso", T0."Codigo", T0."Descripcion", T0."Tipo_Zona", T0."Exige_SCTR", T0."Exige_EPP"
      FROM "Catalogo_Zona_Acceso" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y' AND T0."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
     ORDER BY T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_ELIMINAR"(IN "HV_ID_Catalogo_Zona_Acceso" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "Catalogo_Zona_Acceso" WHERE "ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

        -- Uso por tablas de los Hitos 2 a 4 (CAF_Solicitud_Zona): se agrega aquí cuando existan.

        UPDATE "Catalogo_Zona_Acceso"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Catalogo_Zona_Acceso" = "HV_ID_Catalogo_Zona_Acceso";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Zona eliminada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_ZONA_ACCESO_ELIMINAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CATALOGO_ZONA_ACCESO_LISTAR"("HV_ID_Catalogo_Sede" bigint DEFAULT NULL::bigint, "HV_Incluir_Eliminados" character DEFAULT 'N'::bpchar)
 RETURNS TABLE("ID_Catalogo" bigint, "Codigo" character varying, "Descripcion" character varying, "Tipo_Entidad" character varying, "ID_Catalogo_Sede" bigint, "Codigo_Sede" character varying, "Sede" character varying, "Tipo_Zona" character varying, "Exige_SCTR" character, "Exige_EPP" character, "Orden" bigint, "Activo" character, "Eliminado" character, "UsuarioID_Create" bigint, "Nombre_Usuario" character varying, "UsuarioID_Update" bigint, "CreateDate" timestamp without time zone, "UpdateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Catalogo_Zona_Acceso", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), T0."ID_Catalogo_Sede", S."Codigo", S."Descripcion", T0."Tipo_Zona", T0."Exige_SCTR", T0."Exige_EPP", T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "Catalogo_Zona_Acceso" T0
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Sede" S ON S."ID_Catalogo_Sede" = T0."ID_Catalogo_Sede"
      LEFT JOIN "CAF_GOVERNANCE"."Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
       AND ("HV_ID_Catalogo_Sede" IS NULL OR T0."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede")
     ORDER BY S."Orden", S."Codigo", T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(IN "HV_ID_Catalogo_Tipo_Acceso" bigint, IN "HV_ID_Catalogo_Item_Checklist" bigint, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Tipo_Acceso_Item_Checklist_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n         INT := 0;
    lv_id        BIGINT;
    lv_eliminado CHAR(1);
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR';
    "HV_ID_Tipo_Acceso_Item_Checklist_Result" := 0;
    BEGIN
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- El tipo de acceso puede estar inactivo o no disponible: su checklist se prepara antes de habilitarlo
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El tipo de acceso no existe.'; RETURN; END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El ítem de checklist no existe o está inactivo.'; RETURN; END IF;

        SELECT MAX("ID_Tipo_Acceso_Item_Checklist"), MAX("Eliminado") INTO lv_id, lv_eliminado
          FROM "Tipo_Acceso_Item_Checklist"
         WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "ID_Catalogo_Item_Checklist" = "HV_ID_Catalogo_Item_Checklist";

        IF lv_id IS NOT NULL AND lv_eliminado = 'N' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'El ítem ya está asignado a ese tipo de acceso.'; RETURN;
        ELSIF lv_id IS NOT NULL THEN
            UPDATE "Tipo_Acceso_Item_Checklist"
               SET "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID_Create", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Tipo_Acceso_Item_Checklist" = lv_id;
            "HV_ID_Tipo_Acceso_Item_Checklist_Result" := lv_id;
        ELSE
            INSERT INTO "Tipo_Acceso_Item_Checklist" ("ID_Catalogo_Tipo_Acceso","ID_Catalogo_Item_Checklist","UsuarioID_Create")
            VALUES ("HV_ID_Catalogo_Tipo_Acceso", "HV_ID_Catalogo_Item_Checklist", "HV_UsuarioID_Create")
            RETURNING "ID_Tipo_Acceso_Item_Checklist" INTO "HV_ID_Tipo_Acceso_Item_Checklist_Result";
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ítem asignado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR';
        "HV_ID_Tipo_Acceso_Item_Checklist_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE"("HV_ID_Catalogo_Tipo_Acceso" bigint)
 RETURNS TABLE("ID_Tipo_Acceso_Item_Checklist" bigint, "ID_Catalogo_Tipo_Acceso" bigint, "ID_Catalogo_Item_Checklist" bigint, "Codigo_Item_Checklist" character varying, "Item_Checklist" character varying, "Ayuda" character varying, "Etapa" character varying, "Condicion" character varying, "Es_Critico" character, "Orden" bigint, "Activo" character, "CreateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-11
    RETURN QUERY
    SELECT T0."ID_Tipo_Acceso_Item_Checklist", T0."ID_Catalogo_Tipo_Acceso", T0."ID_Catalogo_Item_Checklist",
           I."Codigo", I."Descripcion", I."Ayuda", I."Etapa", I."Condicion", I."Es_Critico", I."Orden", I."Activo",
           T0."CreateDate"
      FROM "Tipo_Acceso_Item_Checklist" T0
      JOIN "Catalogo_Item_Checklist" I ON I."ID_Catalogo_Item_Checklist" = T0."ID_Catalogo_Item_Checklist"
     WHERE T0."ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND T0."Eliminado" = 'N'
     ORDER BY I."Etapa", I."Orden", I."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR"(IN "HV_ID_Tipo_Acceso_Item_Checklist" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-10-11
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Item_Checklist"
         WHERE "ID_Tipo_Acceso_Item_Checklist" = "HV_ID_Tipo_Acceso_Item_Checklist" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La asignación no existe o ya fue quitada.'; RETURN;
        END IF;

        UPDATE "Tipo_Acceso_Item_Checklist"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Tipo_Acceso_Item_Checklist" = "HV_ID_Tipo_Acceso_Item_Checklist";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Ítem retirado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR';
    END;
END;
$procedure$
;

