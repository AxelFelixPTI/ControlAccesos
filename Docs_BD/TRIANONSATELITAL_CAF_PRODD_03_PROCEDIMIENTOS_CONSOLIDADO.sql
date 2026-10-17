-- Docs_BD · TRIANONSATELITAL_CAF_PRODD · FUNCIONES Y PROCEDIMIENTOS · export 2026-10-17 17:58
-- ÍNDICE
--  1. ERP_CAF_CORREO_ENCOLAR (procedimiento)
--  2. ERP_CAF_EVENTO_REGISTRAR (procedimiento)
--  3. ERP_CAF_FN_COPIAS_VALIDAS (función)
--  4. ERP_CAF_FN_NORMALIZAR (función)
--  5. ERP_CAF_FN_SOLICITUD_VISIBLE (función)
--  6. ERP_CAF_FN_USUARIO_TIENE_PERMISO (función)
--  7. ERP_CAF_FN_USUARIO_TIENE_ROL (función)
--  8. ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR (procedimiento)
--  9. ERP_CAF_PERSONA_EXTERNA_CREAR (procedimiento)
--  10. ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO (función)
--  11. ERP_CAF_PERSONA_EXTERNA_LISTAR (función)
--  12. ERP_CAF_SOLICITUD_BANDEJA_LISTAR (función)
--  13. ERP_CAF_SOLICITUD_CANCELAR (procedimiento)
--  14. ERP_CAF_SOLICITUD_CONTADORES (función)
--  15. ERP_CAF_SOLICITUD_COPIAS_GUARDAR (procedimiento)
--  16. ERP_CAF_SOLICITUD_CREAR (procedimiento)
--  17. ERP_CAF_SOLICITUD_DECIDIR (procedimiento)
--  18. ERP_CAF_SOLICITUD_DESTINATARIOS (procedimiento)
--  19. ERP_CAF_SOLICITUD_DETALLE (función)
--  20. ERP_CAF_SOLICITUD_EDITAR_DATOS (procedimiento)
--  21. ERP_CAF_SOLICITUD_HEREDAR_PASOS (procedimiento)
--  22. ERP_CAF_SOLICITUD_HISTORIAL_LISTAR (función)
--  23. ERP_CAF_SOLICITUD_INDICADORES (función)
--  24. ERP_CAF_SOLICITUD_MIS_LISTAR (función)
--  25. ERP_CAF_SOLICITUD_PASOS_DECIDIBLES (función)
--  26. ERP_CAF_SOLICITUD_PASOS_LISTAR (función)
--  27. ERP_CAF_SOLICITUD_PERSONAS_LISTAR (función)
--  28. ERP_CAF_SOLICITUD_PERSONA_AGREGAR (procedimiento)
--  29. ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA (procedimiento)
--  30. ERP_CAF_SOLICITUD_PERSONA_CORREGIR (procedimiento)
--  31. ERP_CAF_SOLICITUD_PERSONA_RETIRAR (procedimiento)
--  32. ERP_CAF_SOLICITUD_RECALCULAR (procedimiento)
--  33. ERP_CAF_SOLICITUD_VERSION_GUARDAR (procedimiento)
--  34. ERP_CAF_SOLICITUD_VERSION_LISTAR (función)
--  35. ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR (función)
--  36. ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR (función)
--  37. ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR (procedimiento)
--  38. ERP_CAF_TIPO_ACCESO_PASO_AGREGAR (procedimiento)
--  39. ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE (función)
--  40. ERP_CAF_TIPO_ACCESO_PASO_QUITAR (procedimiento)
--  41. ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR (procedimiento)
--  42. ERP_CATALOGO_ITEM_CHECKLIST_CREAR (procedimiento)
--  43. ERP_CATALOGO_ITEM_CHECKLIST_DETALLE (función)
--  44. ERP_CATALOGO_ITEM_CHECKLIST_DROPDOWN (función)
--  45. ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR (procedimiento)
--  46. ERP_CATALOGO_ITEM_CHECKLIST_LISTAR (función)
--  47. ERP_CATALOGO_MOTIVO_VISITA_ACTUALIZAR (procedimiento)
--  48. ERP_CATALOGO_MOTIVO_VISITA_CREAR (procedimiento)
--  49. ERP_CATALOGO_MOTIVO_VISITA_DETALLE (función)
--  50. ERP_CATALOGO_MOTIVO_VISITA_DROPDOWN (función)
--  51. ERP_CATALOGO_MOTIVO_VISITA_ELIMINAR (procedimiento)
--  52. ERP_CATALOGO_MOTIVO_VISITA_LISTAR (función)
--  53. ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR (procedimiento)
--  54. ERP_CATALOGO_TIPO_ACCESO_CREAR (procedimiento)
--  55. ERP_CATALOGO_TIPO_ACCESO_DETALLE (función)
--  56. ERP_CATALOGO_TIPO_ACCESO_DROPDOWN (función)
--  57. ERP_CATALOGO_TIPO_ACCESO_ELIMINAR (procedimiento)
--  58. ERP_CATALOGO_TIPO_ACCESO_LISTAR (función)
--  59. ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR (procedimiento)
--  60. ERP_CATALOGO_TIPO_INCIDENCIA_CREAR (procedimiento)
--  61. ERP_CATALOGO_TIPO_INCIDENCIA_DETALLE (función)
--  62. ERP_CATALOGO_TIPO_INCIDENCIA_DROPDOWN (función)
--  63. ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR (procedimiento)
--  64. ERP_CATALOGO_TIPO_INCIDENCIA_LISTAR (función)
--  65. ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR (procedimiento)
--  66. ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR (procedimiento)
--  67. ERP_CATALOGO_TRATAMIENTO_DESVIACION_DETALLE (función)
--  68. ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN (función)
--  69. ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR (procedimiento)
--  70. ERP_CATALOGO_TRATAMIENTO_DESVIACION_LISTAR (función)
--  71. ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR (procedimiento)
--  72. ERP_CATALOGO_ZONA_ACCESO_CREAR (procedimiento)
--  73. ERP_CATALOGO_ZONA_ACCESO_DETALLE (función)
--  74. ERP_CATALOGO_ZONA_ACCESO_DROPDOWN (función)
--  75. ERP_CATALOGO_ZONA_ACCESO_ELIMINAR (procedimiento)
--  76. ERP_CATALOGO_ZONA_ACCESO_LISTAR (función)
--  77. ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR (procedimiento)
--  78. ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE (función)
--  79. ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR (procedimiento)

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_CORREO_ENCOLAR"(IN "HV_Tipo" character varying, IN "HV_ID_Solicitud" bigint, IN "HV_Destinatarios" character varying, IN "HV_Copia" character varying, IN "HV_Asunto" character varying, IN "HV_Cuerpo" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
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
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_EVENTO_REGISTRAR"(IN "HV_Entidad" character varying, IN "HV_ID_Entidad" bigint, IN "HV_ID_Solicitud" bigint, IN "HV_Accion" character varying, IN "HV_Detalle" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
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
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_FN_COPIAS_VALIDAS"("HV_Copias" character varying)
 RETURNS character
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_FN_NORMALIZAR"("HV_Texto" character varying)
 RETURNS character varying
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
    -- V1.0 2026-10-17
    RETURN LOWER(TRANSLATE(COALESCE("HV_Texto", ''), 'ÁÉÍÓÚÜÑáéíóúüñ', 'AEIOUUNaeiouun'));
END;
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_FN_SOLICITUD_VISIBLE"("HV_ID_Usuario" bigint, "HV_ID_Solicitud" bigint)
 RETURNS character
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_ID_Usuario" bigint, "HV_Codigo_Permiso" character varying, "HV_ID_Catalogo_Sede" bigint)
 RETURNS character
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_ID_Usuario" bigint, "HV_ID_Catalogo_Licencia" bigint, "HV_ID_Catalogo_Sede" bigint)
 RETURNS character
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

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

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_BANDEJA_LISTAR"("HV_UsuarioID" bigint, "HV_ID_Catalogo_Sede" bigint DEFAULT NULL::bigint, "HV_Pestana" character varying DEFAULT 'TODAS'::character varying, "HV_Empresa" character varying DEFAULT NULL::character varying, "HV_Solicitante" character varying DEFAULT NULL::character varying, "HV_Persona" character varying DEFAULT NULL::character varying, "HV_Fecha" date DEFAULT NULL::date, "HV_Estado" character varying DEFAULT NULL::character varying)
 RETURNS TABLE("ID_Solicitud" bigint, "Codigo" character varying, "ID_Catalogo_Sede" bigint, "Sede" character varying, "Tipo_Acceso" character varying, "Fecha_Hora_Prevista" timestamp without time zone, "Es_Hoy" character, "Empresa_Visitante" character varying, "ID_Usuario_Solicitante" bigint, "Solicitante_Nombre" character varying, "Estado" character varying, "Avance" character varying, "Total_Personas" integer, "Autorizadas" integer, "Observadas" integer, "Pendientes" integer, "Rechazadas" integer, "Retiradas" integer, "Por_Decidir_Mis" integer, "Personas_Nombres" character varying, "Fecha_Envio" timestamp without time zone)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_CANCELAR"(IN "HV_ID_Solicitud" bigint, IN "HV_Motivo_Cancelacion" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n      INT := 0;
    lv_sede   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_aut    INT := 0;
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_dest   VARCHAR(2000);
    lv_port   VARCHAR(2000);
    lv_copia  VARCHAR(2000);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CANCELAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_owner, lv_estado, lv_fecha, lv_codsol
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para cancelarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud ya está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Estado" <> 'ESPERADA';
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Ya ingresó una persona: no se puede cancelar. Retire a quienes faltan.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_aut FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'APROBADA';

        UPDATE "CAF_Solicitud"
           SET "Estado" = 'CANCELADA', "Motivo_Cancelacion" = NULLIF(TRIM("HV_Motivo_Cancelacion"), ''),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'CANCELAR',
             COALESCE(NULLIF(TRIM("HV_Motivo_Cancelacion"), ''), 'Sin motivo indicado'), "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        -- Si ya había personas autorizadas, Vigilancia y los aprobadores deben enterarse
        IF lv_aut > 0 THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'APROBADORES', NULL, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PORTERIA', NULL, lv_port, lv_c, lv_m);
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'COPIAS', NULL, lv_copia, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_CANCELADA', "HV_ID_Solicitud",
                 CASE WHEN lv_dest IS NULL THEN lv_port WHEN lv_port IS NULL THEN lv_dest ELSE lv_dest || '; ' || lv_port END,
                 lv_copia, 'Solicitud ' || lv_codsol || ' cancelada',
                 '<p>La solicitud ' || lv_codsol || ' fue cancelada. ' || COALESCE(NULLIF(TRIM("HV_Motivo_Cancelacion"), ''), '') || '</p>',
                 "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Solicitud cancelada correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CANCELAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_CONTADORES"("HV_UsuarioID" bigint, "HV_ID_Catalogo_Sede" bigint DEFAULT NULL::bigint)
 RETURNS TABLE("Mis_Con_Observadas" integer, "Por_Decidir_Solicitudes" integer, "Por_Decidir_Personas" integer)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_COPIAS_GUARDAR"(IN "HV_ID_Solicitud" bigint, IN "HV_Copias" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
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
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_CREAR"(IN "HV_ID_Catalogo_Sede" bigint, IN "HV_ID_Catalogo_Tipo_Acceso" bigint, IN "HV_ID_Personal_Responsable" bigint, IN "HV_Fecha_Hora_Prevista" timestamp without time zone, IN "HV_Empresa_Visitante" character varying, IN "HV_ID_Catalogo_Motivo_Visita" bigint, IN "HV_Motivo_Detalle" character varying, IN "HV_Observaciones" character varying, IN "HV_IDs_Zona" character varying, IN "HV_IDs_Persona_Externa" character varying, IN "HV_Copias" character varying, IN "HV_ID_Solicitud_Origen" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_ID_Solicitud_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Solicitud_Result" character varying DEFAULT NULL::character varying, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n       INT := 0;
    lv_otro    CHAR(1);
    lv_disp    CHAR(1);
    lv_req     CHAR(1);
    lv_z       VARCHAR(2100);
    lv_p       VARCHAR(2100);
    lv_listaZ  VARCHAR(2100);
    lv_listaP  VARCHAR(2100);
    lv_cntZ    INT := 0;
    lv_cntP    INT := 0;
    lv_sctr    CHAR(1);
    lv_epp     CHAR(1);
    lv_id      BIGINT;
    lv_codsol  VARCHAR(20);
    lv_c       INT;
    lv_m       VARCHAR(250);
    lv_estado  VARCHAR(20);
    lv_dest    VARCHAR(2000);
    lv_copia   VARCHAR(2000);
    lv_detalle VARCHAR(500);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR';
    "HV_ID_Solicitud_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', "HV_ID_Catalogo_Sede") <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para crear solicitudes en esta sede.'; RETURN;
        END IF;

        -- Tipo de acceso: debe estar habilitado y tener pasos de aprobación
        SELECT COUNT(*), MAX("Disponible"), MAX("Requiere_Aprobacion") INTO lv_n, lv_disp, lv_req
          FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de acceso no existe o está inactivo.'; RETURN;
        END IF;
        IF lv_disp <> 'Y' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Ese tipo de acceso todavía no está disponible.'; RETURN;
        END IF;
        IF lv_req = 'Y' THEN
            SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion"
             WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N' AND "Activo" = 'Y' AND "Obligatorio" = 'Y';
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'El tipo de acceso no tiene pasos de aprobación configurados.'; RETURN;
            END IF;
        END IF;

        -- Datos de la visita
        IF "HV_Fecha_Hora_Prevista" IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique la fecha y la hora de la visita.'; RETURN;
        END IF;
        IF CAST("HV_Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La fecha de la visita no puede ser anterior a hoy.'; RETURN;
        END IF;
        IF "HV_Empresa_Visitante" IS NULL OR LENGTH(TRIM("HV_Empresa_Visitante")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La empresa o procedencia es obligatoria.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Personal"
         WHERE "ID_Personal" = "HV_ID_Personal_Responsable" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El responsable de atención no existe o está inactivo.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Es_Otro") INTO lv_n, lv_otro FROM "Catalogo_Motivo_Visita"
         WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El motivo no existe o está inactivo.'; RETURN;
        END IF;
        IF lv_otro = 'Y' AND ("HV_Motivo_Detalle" IS NULL OR LENGTH(TRIM("HV_Motivo_Detalle")) = 0) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Describa el motivo de la visita.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Copias") <> 'Y' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de correos en copia no es válida.'; RETURN;
        END IF;

        -- Zonas: al menos una, todas activas y de esa sede
        lv_z := REPLACE(REPLACE(COALESCE("HV_IDs_Zona", ''), ' ', ''), ';', ',');
        lv_cntZ := CASE WHEN LENGTH(lv_z) = 0 THEN 0 ELSE LENGTH(lv_z) - LENGTH(REPLACE(lv_z, ',', '')) + 1 END;
        lv_listaZ := ',' || lv_z || ',';
        IF lv_cntZ = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Marque al menos una zona.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Zona_Acceso" Z
         WHERE Z."Eliminado" = 'N' AND Z."Activo" = 'Y' AND Z."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
           AND lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        IF lv_n <> lv_cntZ THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Alguna zona no existe, está inactiva, está repetida o es de otra sede.'; RETURN;
        END IF;

        -- Personas: al menos una, todas en el registro de personas externas
        lv_p := REPLACE(REPLACE(COALESCE("HV_IDs_Persona_Externa", ''), ' ', ''), ';', ',');
        lv_cntP := CASE WHEN LENGTH(lv_p) = 0 THEN 0 ELSE LENGTH(lv_p) - LENGTH(REPLACE(lv_p, ',', '')) + 1 END;
        lv_listaP := ',' || lv_p || ',';
        IF lv_cntP = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Agregue al menos una persona.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Persona_Externa" PE
         WHERE PE."Eliminado" = 'N' AND lv_listaP LIKE '%,' || CAST(PE."ID_Persona_Externa" AS VARCHAR) || ',%';
        IF lv_n <> lv_cntP THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Alguna persona no está registrada o está repetida.'; RETURN;
        END IF;

        -- Origen («Reutilizar»): debe ser una solicitud del mismo usuario
        IF "HV_ID_Solicitud_Origen" IS NOT NULL THEN
            SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud"
             WHERE "ID_Solicitud" = "HV_ID_Solicitud_Origen" AND "Eliminado" = 'N' AND "ID_Usuario_Solicitante" = "HV_UsuarioID";
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud de origen no existe o no es suya.'; RETURN;
            END IF;
        END IF;

        -- Qué exigen las zonas elegidas (se copia: un cambio posterior en el catálogo no altera lo ya enviado, D-18)
        SELECT CASE WHEN SUM(CASE WHEN Z."Exige_SCTR" = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END,
               CASE WHEN SUM(CASE WHEN Z."Exige_EPP"  = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END
          INTO lv_sctr, lv_epp
          FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';

        lv_detalle := CASE WHEN lv_otro = 'Y' THEN TRIM("HV_Motivo_Detalle") ELSE NULL END;

        INSERT INTO "CAF_Solicitud" ("ID_Catalogo_Sede","ID_Catalogo_Tipo_Acceso","ID_Usuario_Solicitante","ID_Personal_Responsable",
                                     "Fecha_Hora_Prevista","Empresa_Visitante","ID_Catalogo_Motivo_Visita","Motivo_Detalle","Observaciones",
                                     "Exige_SCTR","Exige_EPP","Estado","Version","Fecha_Envio","ID_Solicitud_Origen","UsuarioID_Create")
        VALUES ("HV_ID_Catalogo_Sede", "HV_ID_Catalogo_Tipo_Acceso", "HV_UsuarioID", "HV_ID_Personal_Responsable",
                "HV_Fecha_Hora_Prevista", TRIM("HV_Empresa_Visitante"), "HV_ID_Catalogo_Motivo_Visita", lv_detalle, NULLIF(TRIM("HV_Observaciones"), ''),
                lv_sctr, lv_epp, 'PENDIENTE', 1, CURRENT_TIMESTAMP, "HV_ID_Solicitud_Origen", "HV_UsuarioID")
        RETURNING "ID_Solicitud" INTO lv_id;

        -- El código visible se deriva del identificador (D-15)
        lv_codsol := 'SOL-' || LPAD(CAST(lv_id AS VARCHAR), 5, '0');
        UPDATE "CAF_Solicitud" SET "Codigo" = lv_codsol WHERE "ID_Solicitud" = lv_id;

        INSERT INTO "CAF_Solicitud_Zona" ("ID_Solicitud","ID_Catalogo_Zona_Acceso","UsuarioID_Create")
        SELECT lv_id, Z."ID_Catalogo_Zona_Acceso", "HV_UsuarioID" FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';

        INSERT INTO "CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","Origen","UsuarioID_Create")
        SELECT lv_id, PE."ID_Persona_Externa", 'PENDIENTE', 'SOLICITUD', "HV_UsuarioID" FROM "CAF_Persona_Externa" PE
         WHERE lv_listaP LIKE '%,' || CAST(PE."ID_Persona_Externa" AS VARCHAR) || ',%';

        CALL "ERP_CAF_SOLICITUD_COPIAS_GUARDAR"(lv_id, "HV_Copias", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'copias: %', lv_m; END IF;

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"(lv_id, "HV_UsuarioID", lv_estado, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', lv_id, lv_id, 'CREAR',
             'Creó y envió la solicitud' || CASE WHEN "HV_ID_Solicitud_Origen" IS NULL THEN '' ELSE ' a partir de la solicitud ' || "HV_ID_Solicitud_Origen" END,
             "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        -- Aviso a quienes deciden el primer paso (si el flujo no requería aprobación ya quedó aprobada)
        IF lv_estado = 'PENDIENTE' THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_id, 'PRIMER_PASO', NULL, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_id, 'COPIAS', NULL, lv_copia, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_NUEVA', lv_id, lv_dest, lv_copia,
                 'Nueva solicitud ' || lv_codsol || ' por aprobar',
                 '<p>La solicitud ' || lv_codsol || ' de ' || TRIM("HV_Empresa_Visitante") || ' (visita el '
                 || TO_CHAR("HV_Fecha_Hora_Prevista", 'DD/MM/YYYY HH24:MI') || ') tiene ' || lv_cntP || ' persona(s) por aprobar.</p>',
                 "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_ID_Solicitud_Result"     := lv_id;
        "HV_Codigo_Solicitud_Result" := lv_codsol;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Solicitud ' || lv_codsol || ' registrada y enviada a aprobación.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_CREAR';
        "HV_ID_Solicitud_Result" := 0;
        "HV_Codigo_Solicitud_Result" := NULL;
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_DECIDIR"(IN "HV_ID_Solicitud" bigint, IN "HV_ID_Tipo_Acceso_Paso_Aprobacion" bigint, IN "HV_Decision" character varying, IN "HV_Mensaje_Decision" character varying, IN "HV_IDs_Solicitud_Persona" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Cantidad_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n        INT := 0;
    lv_sede     BIGINT;
    lv_tipo     BIGINT;
    lv_estado   VARCHAR(20);
    lv_fecha    TIMESTAMP;
    lv_codsol   VARCHAR(20);
    lv_solic    BIGINT;
    lv_p_tipo   BIGINT;
    lv_alcance  VARCHAR(20);
    lv_orden    BIGINT;
    lv_lic      BIGINT;
    lv_codpaso  VARCHAR(50);
    lv_ids      VARCHAR(4000);
    lv_lista    VARCHAR(4100);
    lv_cnt      INT := 0;
    lv_tokens   INT := 0;
    lv_viol     INT := 0;
    lv_acc      VARCHAR(20);
    lv_c        INT;
    lv_m        VARCHAR(250);
    lv_est2     VARCHAR(20);
    lv_nombres  VARCHAR(2000);
    lv_dest     VARCHAR(2000);
    lv_pend     INT := 0;
    lv_texto    VARCHAR(500);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DECIDIR';
    "HV_Cantidad_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        IF "HV_Decision" IS NULL OR "HV_Decision" NOT IN ('APROBADA','OBSERVADA','RECHAZADA') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La decisión debe ser APROBADA, OBSERVADA o RECHAZADA.'; RETURN;
        END IF;
        IF "HV_Decision" <> 'APROBADA' AND ("HV_Mensaje_Decision" IS NULL OR LENGTH(TRIM("HV_Mensaje_Decision")) = 0) THEN
            "HV_Codigo_Resp" := 400;
            "HV_Mensaje" := CASE WHEN "HV_Decision" = 'OBSERVADA' THEN 'Escriba qué debe corregir el solicitante.' ELSE 'Escriba el motivo del rechazo.' END;
            RETURN;
        END IF;

        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo"), MAX("ID_Usuario_Solicitante")
          INTO lv_n, lv_sede, lv_tipo, lv_estado, lv_fecha, lv_codsol, lv_solic
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("ID_Catalogo_Tipo_Acceso"), MAX("Alcance"), MAX("Orden"), MAX("ID_Catalogo_Licencia"), MAX("Codigo")
          INTO lv_n, lv_p_tipo, lv_alcance, lv_orden, lv_lic, lv_codpaso
          FROM "Tipo_Acceso_Paso_Aprobacion"
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 OR lv_p_tipo <> lv_tipo THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El paso no existe, está inactivo o no corresponde al tipo de acceso de esta solicitud.'; RETURN;
        END IF;

        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_APROBAR', lv_sede) <> 'Y'
           OR "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", lv_lic, lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No le corresponde decidir este paso de la solicitud.'; RETURN;
        END IF;

        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;

        -- A quiénes se decide
        IF lv_alcance = 'PERSONA' THEN
            lv_ids := REPLACE(REPLACE(COALESCE("HV_IDs_Solicitud_Persona", ''), ' ', ''), ';', ',');
            lv_tokens := CASE WHEN LENGTH(lv_ids) = 0 THEN 0 ELSE LENGTH(lv_ids) - LENGTH(REPLACE(lv_ids, ',', '')) + 1 END;
            IF lv_tokens = 0 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Elija al menos una persona.'; RETURN;
            END IF;
            lv_lista := ',' || lv_ids || ',';
            SELECT COUNT(*) INTO lv_cnt FROM "CAF_Solicitud_Persona" P
             WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'PENDIENTE' AND P."Estado" = 'ESPERADA'
               AND lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';
            IF lv_cnt <> lv_tokens THEN
                "HV_Codigo_Resp" := 409;
                "HV_Mensaje" := 'Alguna persona no está en la solicitud, está repetida o ya no está pendiente.'; RETURN;
            END IF;
        ELSE
            -- Paso por solicitud: todas las pendientes que aún no tienen decisión en ese paso
            SELECT STRING_AGG(CAST(P."ID_Solicitud_Persona" AS VARCHAR), ',' ORDER BY P."ID_Solicitud_Persona"), COUNT(*)
              INTO lv_ids, lv_cnt
              FROM "CAF_Solicitud_Persona" P
             WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Aprobacion" = 'PENDIENTE' AND P."Estado" = 'ESPERADA'
               AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                                WHERE D."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                                  AND D."ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion"
                                  AND D."Vigente" = 'Y' AND D."Eliminado" = 'N');
            IF lv_cnt = 0 THEN
                "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'No hay personas pendientes en este paso.'; RETURN;
            END IF;
            lv_lista := ',' || lv_ids || ',';
        END IF;

        -- Ninguna debe tener ya decisión en este paso
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona" P
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%'
           AND EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                        WHERE D."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                          AND D."ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion"
                          AND D."Vigente" = 'Y' AND D."Eliminado" = 'N');
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Alguna persona ya tiene decisión en este paso.'; RETURN;
        END IF;

        -- Los pasos anteriores deben estar aprobados para cada persona
        SELECT COUNT(*) INTO lv_viol FROM "CAF_Solicitud_Persona" P
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%'
           AND EXISTS (SELECT 1 FROM "Tipo_Acceso_Paso_Aprobacion" L
                        WHERE L."ID_Catalogo_Tipo_Acceso" = lv_tipo AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
                          AND L."Obligatorio" = 'Y' AND L."Orden" < lv_orden
                          AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D2
                                           WHERE D2."ID_Solicitud_Persona" = P."ID_Solicitud_Persona"
                                             AND D2."ID_Tipo_Acceso_Paso_Aprobacion" = L."ID_Tipo_Acceso_Paso_Aprobacion"
                                             AND D2."Vigente" = 'Y' AND D2."Eliminado" = 'N' AND D2."Decision" = 'APROBADA'));
        IF lv_viol > 0 THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Falta aprobar un paso anterior para alguna de las personas.'; RETURN;
        END IF;

        -- Se registran las decisiones
        INSERT INTO "CAF_Solicitud_Decision"
               ("ID_Solicitud_Persona","ID_Tipo_Acceso_Paso_Aprobacion","Decision","Mensaje","ID_Usuario","Fecha_Decision","UsuarioID_Create")
        SELECT P."ID_Solicitud_Persona", "HV_ID_Tipo_Acceso_Paso_Aprobacion", "HV_Decision",
               CASE WHEN "HV_Decision" = 'APROBADA' THEN NULL ELSE TRIM("HV_Mensaje_Decision") END,
               "HV_UsuarioID", CURRENT_TIMESTAMP, "HV_UsuarioID"
          FROM "CAF_Solicitud_Persona" P
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';

        -- Resumen de la última decisión en la cabecera (D-45)
        UPDATE "CAF_Solicitud"
           SET "ID_Usuario_Decision" = "HV_UsuarioID", "Fecha_Decision" = CURRENT_TIMESTAMP,
               "Observacion_Coordinador" = CASE WHEN "HV_Decision" = 'APROBADA' THEN "Observacion_Coordinador" ELSE TRIM("HV_Mensaje_Decision") END,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_SOLICITUD_VERSION_GUARDAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'version: %', lv_m; END IF;

        -- Bitácora
        lv_acc := CASE "HV_Decision" WHEN 'APROBADA' THEN 'APROBAR' WHEN 'OBSERVADA' THEN 'OBSERVAR' ELSE 'RECHAZAR' END;
        SELECT STRING_AGG(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres", '; ' ORDER BY P."ID_Solicitud_Persona")
          INTO lv_nombres
          FROM "CAF_Solicitud_Persona" P JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = P."ID_Persona_Externa"
         WHERE lv_lista LIKE '%,' || CAST(P."ID_Solicitud_Persona" AS VARCHAR) || ',%';
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_DECISION', "HV_ID_Tipo_Acceso_Paso_Aprobacion", "HV_ID_Solicitud", lv_acc,
             'Paso ' || lv_codpaso || ': ' || LEFT(lv_nombres, 1400)
             || CASE WHEN "HV_Decision" = 'APROBADA' THEN '' ELSE ' · ' || TRIM("HV_Mensaje_Decision") END,
             "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        -- Aviso al solicitante con el resumen de lo decidido
        lv_texto := lv_cnt || CASE WHEN lv_cnt = 1 THEN ' persona ' ELSE ' personas ' END
                    || CASE "HV_Decision" WHEN 'APROBADA' THEN 'aprobada(s)' WHEN 'OBSERVADA' THEN 'observada(s)' ELSE 'rechazada(s)' END;
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'SOLICITANTE', NULL, lv_dest, lv_c, lv_m);
        CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_DECISION', "HV_ID_Solicitud", lv_dest, NULL,
             'Decisión sobre ' || lv_codsol || ': ' || lv_texto,
             '<p>Sobre la solicitud ' || lv_codsol || ': ' || lv_texto || '.</p>'
             || CASE WHEN "HV_Decision" = 'APROBADA' THEN '' ELSE '<p>' || TRIM("HV_Mensaje_Decision") || '</p>' END
             || '<p>Estado de la solicitud: ' || lv_est2 || '.</p>',
             "HV_UsuarioID", lv_c, lv_m);

        -- Si aprobó y todavía faltan pasos, se avisa a quienes deciden el siguiente
        IF "HV_Decision" = 'APROBADA' THEN
            SELECT COUNT(*) INTO lv_pend FROM "CAF_Solicitud_Persona"
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Aprobacion" = 'PENDIENTE';
            IF lv_pend > 0 THEN
                CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'SIGUIENTE_PASO', lv_orden, lv_dest, lv_c, lv_m);
                CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', "HV_ID_Solicitud", lv_dest, NULL,
                     'Personas por aprobar en ' || lv_codsol,
                     '<p>La solicitud ' || lv_codsol || ' tiene ' || lv_pend || ' persona(s) esperando el siguiente paso.</p>',
                     "HV_UsuarioID", lv_c, lv_m);
            END IF;
        END IF;

        "HV_Cantidad_Result" := lv_cnt;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Decisión registrada: ' || lv_texto || '. Estado de la solicitud: ' || lv_est2 || '.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_DECIDIR';
        "HV_Cantidad_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_DESTINATARIOS"(IN "HV_ID_Solicitud" bigint, IN "HV_Modo" character varying, IN "HV_Referencia" bigint, INOUT "HV_Destinatarios" character varying DEFAULT NULL::character varying, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
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
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_DETALLE"("HV_UsuarioID" bigint, "HV_ID_Solicitud" bigint)
 RETURNS TABLE("ID_Solicitud" bigint, "Codigo" character varying, "ID_Catalogo_Sede" bigint, "Sede" character varying, "ID_Catalogo_Tipo_Acceso" bigint, "Tipo_Acceso" character varying, "Fecha_Hora_Prevista" timestamp without time zone, "Empresa_Visitante" character varying, "ID_Personal_Responsable" bigint, "Responsable_Nombre" character varying, "Responsable_Correo" character varying, "Responsable_Area" character varying, "ID_Catalogo_Motivo_Visita" bigint, "Motivo" character varying, "Motivo_Detalle" character varying, "Observaciones" character varying, "Exige_SCTR" character, "Exige_EPP" character, "Estado" character varying, "Avance" character varying, "Version" bigint, "Fecha_Envio" timestamp without time zone, "ID_Usuario_Solicitante" bigint, "Solicitante_Nombre" character varying, "Solicitante_Correo" character varying, "Fecha_Decision" timestamp without time zone, "Usuario_Decision_Nombre" character varying, "Observacion_Coordinador" character varying, "Motivo_Cancelacion" character varying, "ID_Solicitud_Origen" bigint, "Codigo_Origen" character varying, "Zonas_IDs" character varying, "Zonas_Nombres" character varying, "Copias" character varying, "CreateDate" timestamp without time zone, "Total_Personas" integer, "Autorizadas" integer, "Observadas" integer, "Pendientes" integer, "Rechazadas" integer, "Retiradas" integer, "Es_Propia" character, "Puede_Editar_Datos" character, "Motivo_No_Editar_Datos" character varying, "Puede_Modificar_Personal" character, "Motivo_No_Modificar_Personal" character varying, "Puede_Cancelar" character, "Motivo_No_Cancelar" character varying, "Puede_Reutilizar" character, "Puede_Decidir" character, "Por_Decidir_Mis" integer)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
DECLARE
    lv_dec INT := 0;
BEGIN
    -- V1.0 2026-10-17
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
           CAST(CASE WHEN lv_dec > 0 THEN 'Y' ELSE 'N' END AS CHAR(1)), lv_dec
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
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_EDITAR_DATOS"(IN "HV_ID_Solicitud" bigint, IN "HV_Fecha_Hora_Prevista" timestamp without time zone, IN "HV_Empresa_Visitante" character varying, IN "HV_ID_Personal_Responsable" bigint, IN "HV_ID_Catalogo_Motivo_Visita" bigint, IN "HV_Motivo_Detalle" character varying, IN "HV_Observaciones" character varying, IN "HV_IDs_Zona" character varying, IN "HV_Copias" character varying, IN "HV_UsuarioID" bigint, INOUT "HV_Reabierta_Result" character DEFAULT NULL::bpchar, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n        INT := 0;
    lv_n2       INT := 0;
    lv_sede     BIGINT;
    lv_tipo     BIGINT;
    lv_owner    BIGINT;
    lv_estado   VARCHAR(20);
    lv_fecha    TIMESTAMP;
    lv_emp      VARCHAR(500);
    lv_mot      BIGINT;
    lv_det_old  VARCHAR(500);
    lv_resp_old BIGINT;
    lv_codsol   VARCHAR(20);
    lv_otro     CHAR(1);
    lv_detalle  VARCHAR(500);
    lv_z        VARCHAR(2100);
    lv_listaZ   VARCHAR(2100);
    lv_cntZ     INT := 0;
    lv_cambia   CHAR(1) := 'N';
    lv_sctr     CHAR(1);
    lv_epp      CHAR(1);
    lv_c        INT;
    lv_m        VARCHAR(250);
    lv_est2     VARCHAR(20);
    lv_dest     VARCHAR(2000);
    lv_copia    VARCHAR(2000);
    lv_desc     VARCHAR(2000) := '';
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_EDITAR_DATOS';
    "HV_Reabierta_Result" := 'N';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("ID_Usuario_Solicitante"), MAX("Estado"),
               MAX("Fecha_Hora_Prevista"), MAX("Empresa_Visitante"), MAX("ID_Catalogo_Motivo_Visita"), MAX("Motivo_Detalle"),
               MAX("ID_Personal_Responsable"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_tipo, lv_owner, lv_estado, lv_fecha, lv_emp, lv_mot, lv_det_old, lv_resp_old, lv_codsol
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para modificarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF lv_estado = 'RECHAZADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Todas las personas fueron rechazadas. Use «Reutilizar» para crear una solicitud nueva.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó. Use «Reutilizar».'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND "Estado" <> 'ESPERADA';
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 409;
            "HV_Mensaje" := 'Ya ingresó una persona: los datos de la visita no se cambian. Puede modificar el personal.'; RETURN;
        END IF;

        -- Validación de los valores nuevos (mismas reglas que al crear)
        IF "HV_Fecha_Hora_Prevista" IS NULL OR CAST("HV_Fecha_Hora_Prevista" AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique una fecha y hora de visita que no sea anterior a hoy.'; RETURN;
        END IF;
        IF "HV_Empresa_Visitante" IS NULL OR LENGTH(TRIM("HV_Empresa_Visitante")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La empresa o procedencia es obligatoria.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Personal"
         WHERE "ID_Personal" = "HV_ID_Personal_Responsable" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El responsable de atención no existe o está inactivo.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("Es_Otro") INTO lv_n, lv_otro FROM "Catalogo_Motivo_Visita"
         WHERE "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita" AND "Eliminado" = 'N' AND ("Activo" = 'Y' OR "ID_Catalogo_Motivo_Visita" = lv_mot);
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El motivo no existe.'; RETURN;
        END IF;
        IF lv_otro = 'Y' AND ("HV_Motivo_Detalle" IS NULL OR LENGTH(TRIM("HV_Motivo_Detalle")) = 0) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Describa el motivo de la visita.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_COPIAS_VALIDAS"("HV_Copias") <> 'Y' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de correos en copia no es válida.'; RETURN;
        END IF;

        lv_z := REPLACE(REPLACE(COALESCE("HV_IDs_Zona", ''), ' ', ''), ';', ',');
        lv_cntZ := CASE WHEN LENGTH(lv_z) = 0 THEN 0 ELSE LENGTH(lv_z) - LENGTH(REPLACE(lv_z, ',', '')) + 1 END;
        lv_listaZ := ',' || lv_z || ',';
        IF lv_cntZ = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Marque al menos una zona.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Zona_Acceso" Z
         WHERE Z."Eliminado" = 'N' AND Z."ID_Catalogo_Sede" = lv_sede
           AND lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%'
           AND (Z."Activo" = 'Y' OR EXISTS (SELECT 1 FROM "CAF_Solicitud_Zona" W
                                             WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."Eliminado" = 'N'
                                               AND W."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso"));
        IF lv_n <> lv_cntZ THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Alguna zona no existe, está inactiva, está repetida o es de otra sede.'; RETURN;
        END IF;

        -- ¿Cambió algo que obligue a volver a aprobar?
        lv_detalle := CASE WHEN lv_otro = 'Y' THEN TRIM("HV_Motivo_Detalle") ELSE NULL END;
        IF "HV_Fecha_Hora_Prevista" <> lv_fecha THEN
            lv_cambia := 'Y';
            lv_desc := lv_desc || 'Visita ' || TO_CHAR(lv_fecha, 'DD/MM/YYYY HH24:MI') || ' → ' || TO_CHAR("HV_Fecha_Hora_Prevista", 'DD/MM/YYYY HH24:MI') || '. ';
        END IF;
        IF TRIM("HV_Empresa_Visitante") <> lv_emp THEN
            lv_cambia := 'Y'; lv_desc := lv_desc || 'Empresa: ' || lv_emp || ' → ' || TRIM("HV_Empresa_Visitante") || '. ';
        END IF;
        IF "HV_ID_Catalogo_Motivo_Visita" <> lv_mot OR COALESCE(lv_detalle, '') <> COALESCE(lv_det_old, '') THEN
            lv_cambia := 'Y'; lv_desc := lv_desc || 'Motivo modificado. ';
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Zona" W
         WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."Eliminado" = 'N'
           AND lv_listaZ NOT LIKE '%,' || CAST(W."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        SELECT COUNT(*) INTO lv_n2 FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%'
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Zona" W
                            WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."Eliminado" = 'N'
                              AND W."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso");
        IF lv_n > 0 OR lv_n2 > 0 THEN
            lv_cambia := 'Y'; lv_desc := lv_desc || 'Zonas modificadas. ';
        END IF;
        IF "HV_ID_Personal_Responsable" <> lv_resp_old THEN
            lv_desc := lv_desc || 'Responsable de atención cambiado. ';
        END IF;
        IF lv_desc = '' THEN lv_desc := 'Observaciones o copias de correo.'; END IF;

        -- Zonas: retirar las que ya no vienen, reactivar las quitadas, agregar las nuevas
        UPDATE "CAF_Solicitud_Zona"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N'
           AND lv_listaZ NOT LIKE '%,' || CAST("ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        UPDATE "CAF_Solicitud_Zona"
           SET "Eliminado" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'Y'
           AND lv_listaZ LIKE '%,' || CAST("ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';
        INSERT INTO "CAF_Solicitud_Zona" ("ID_Solicitud","ID_Catalogo_Zona_Acceso","UsuarioID_Create")
        SELECT "HV_ID_Solicitud", Z."ID_Catalogo_Zona_Acceso", "HV_UsuarioID" FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%'
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Zona" W
                            WHERE W."ID_Solicitud" = "HV_ID_Solicitud" AND W."ID_Catalogo_Zona_Acceso" = Z."ID_Catalogo_Zona_Acceso");

        SELECT CASE WHEN SUM(CASE WHEN Z."Exige_SCTR" = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END,
               CASE WHEN SUM(CASE WHEN Z."Exige_EPP"  = 'Y' THEN 1 ELSE 0 END) > 0 THEN 'Y' ELSE 'N' END
          INTO lv_sctr, lv_epp
          FROM "Catalogo_Zona_Acceso" Z
         WHERE lv_listaZ LIKE '%,' || CAST(Z."ID_Catalogo_Zona_Acceso" AS VARCHAR) || ',%';

        UPDATE "CAF_Solicitud"
           SET "Fecha_Hora_Prevista" = "HV_Fecha_Hora_Prevista", "Empresa_Visitante" = TRIM("HV_Empresa_Visitante"),
               "ID_Personal_Responsable" = "HV_ID_Personal_Responsable", "ID_Catalogo_Motivo_Visita" = "HV_ID_Catalogo_Motivo_Visita",
               "Motivo_Detalle" = lv_detalle, "Observaciones" = NULLIF(TRIM("HV_Observaciones"), ''),
               "Exige_SCTR" = lv_sctr, "Exige_EPP" = lv_epp,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud";

        CALL "ERP_CAF_SOLICITUD_COPIAS_GUARDAR"("HV_ID_Solicitud", "HV_Copias", "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'copias: %', lv_m; END IF;

        -- Reabrir la aprobación si cambió lo que se había autorizado
        IF lv_cambia = 'Y' THEN
            UPDATE "CAF_Solicitud_Persona"
               SET "Origen" = 'REABIERTA', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N'
               AND "Aprobacion" IN ('APROBADA','PENDIENTE') AND "Estado" = 'ESPERADA';

            UPDATE "CAF_Solicitud_Decision" D
               SET "Vigente" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE D."Vigente" = 'Y' AND D."Eliminado" = 'N'
               AND D."ID_Solicitud_Persona" IN (SELECT P."ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" P
                                                 WHERE P."ID_Solicitud" = "HV_ID_Solicitud" AND P."Eliminado" = 'N' AND P."Estado" = 'ESPERADA')
               AND (D."ID_Tipo_Acceso_Paso_Aprobacion" IN (SELECT S."ID_Tipo_Acceso_Paso_Aprobacion" FROM "Tipo_Acceso_Paso_Aprobacion" S
                                                            WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Alcance" = 'SOLICITUD')
                    OR D."ID_Solicitud_Persona" IN (SELECT P2."ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" P2
                                                     WHERE P2."ID_Solicitud" = "HV_ID_Solicitud" AND P2."Aprobacion" IN ('APROBADA','PENDIENTE')));

            UPDATE "CAF_Solicitud" SET "Version" = "Version" + 1 WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        END IF;

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;

        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', "HV_ID_Solicitud", "HV_ID_Solicitud", 'EDITAR', TRIM(lv_desc), "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        IF lv_cambia = 'Y' AND lv_est2 IN ('PENDIENTE','APROBADA_PARCIAL') THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PRIMER_PASO', NULL, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'COPIAS', NULL, lv_copia, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_EDITADA', "HV_ID_Solicitud", lv_dest, lv_copia,
                 'Solicitud ' || lv_codsol || ' modificada: hay personas por aprobar',
                 '<p>Se modificaron los datos de la solicitud ' || lv_codsol || '. ' || TRIM(lv_desc) || '</p>',
                 "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_Reabierta_Result" := lv_cambia;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN lv_cambia = 'Y' THEN 'Solicitud actualizada. Vuelve a aprobación.' ELSE 'Solicitud actualizada.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_EDITAR_DATOS';
        "HV_Reabierta_Result" := 'N';
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_HEREDAR_PASOS"(IN "HV_ID_Solicitud" bigint, IN "HV_ID_Solicitud_Persona" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
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
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"("HV_UsuarioID" bigint, "HV_ID_Solicitud" bigint)
 RETURNS TABLE("ID_Evento" bigint, "Fecha_Evento" timestamp without time zone, "Entidad" character varying, "Accion" character varying, "Accion_Texto" character varying, "Detalle" character varying, "ID_Usuario" bigint, "Usuario_Nombre" character varying)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
                WHEN 'SOLICITUD_PERSONA:AGREGAR'            THEN 'Agregó a una persona'
                WHEN 'SOLICITUD_PERSONA:AGREGAR_APROBADA'   THEN 'Agregó a una persona ya aprobada'
                WHEN 'SOLICITUD_PERSONA:RETIRAR'            THEN 'Retiró a una persona'
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
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_INDICADORES"("HV_ID_Solicitud" bigint DEFAULT NULL::bigint)
 RETURNS TABLE("ID_Solicitud" bigint, "Total_Personas" integer, "Autorizadas" integer, "Observadas" integer, "Pendientes" integer, "Rechazadas" integer, "Retiradas" integer, "Con_Movimientos" integer, "Avance" character varying, "Editar_Datos" character, "Motivo_Editar_Datos" character varying, "Modificar_Personal" character, "Motivo_Modificar_Personal" character varying, "Cancelar" character, "Motivo_Cancelar" character varying)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_MIS_LISTAR"("HV_UsuarioID" bigint, "HV_ID_Catalogo_Sede" bigint DEFAULT NULL::bigint, "HV_Texto" character varying DEFAULT NULL::character varying, "HV_Estado" character varying DEFAULT NULL::character varying, "HV_Fecha_Desde" date DEFAULT NULL::date, "HV_Fecha_Hasta" date DEFAULT NULL::date)
 RETURNS TABLE("ID_Solicitud" bigint, "Codigo" character varying, "ID_Catalogo_Sede" bigint, "Sede" character varying, "ID_Catalogo_Tipo_Acceso" bigint, "Tipo_Acceso" character varying, "Fecha_Hora_Prevista" timestamp without time zone, "Empresa_Visitante" character varying, "Estado" character varying, "Avance" character varying, "Total_Personas" integer, "Autorizadas" integer, "Observadas" integer, "Pendientes" integer, "Rechazadas" integer, "Retiradas" integer, "Responsable_Nombre" character varying, "Codigo_Origen" character varying, "Fecha_Envio" timestamp without time zone, "CreateDate" timestamp without time zone, "Puede_Editar_Datos" character, "Motivo_No_Editar_Datos" character varying, "Puede_Modificar_Personal" character, "Motivo_No_Modificar_Personal" character varying, "Puede_Cancelar" character, "Motivo_No_Cancelar" character varying, "Puede_Reutilizar" character)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"("HV_ID_Usuario" bigint, "HV_ID_Solicitud" bigint DEFAULT NULL::bigint)
 RETURNS TABLE("ID_Solicitud" bigint, "ID_Solicitud_Persona" bigint, "ID_Tipo_Acceso_Paso_Aprobacion" bigint, "Paso_Codigo" character varying, "Paso_Descripcion" character varying, "Paso_Orden" bigint, "Paso_Alcance" character varying)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_PASOS_LISTAR"("HV_UsuarioID" bigint, "HV_ID_Solicitud" bigint)
 RETURNS TABLE("ID_Solicitud_Persona" bigint, "Persona_Nombre" character varying, "ID_Tipo_Acceso_Paso_Aprobacion" bigint, "Paso_Orden" bigint, "Paso_Codigo" character varying, "Paso_Descripcion" character varying, "Paso_Alcance" character varying, "Obligatorio" character, "Rol_Aprobador" character varying, "Decision" character varying, "Mensaje" character varying, "Decidio_Nombre" character varying, "Fecha_Decision" timestamp without time zone, "Es_Mi_Turno" character)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_PERSONAS_LISTAR"("HV_UsuarioID" bigint, "HV_ID_Solicitud" bigint)
 RETURNS TABLE("ID_Solicitud_Persona" bigint, "ID_Persona_Externa" bigint, "ID_Catalogo_Tipo_Documento" bigint, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Apellido_Paterno" character varying, "Apellido_Materno" character varying, "Nombres" character varying, "Nombre_Completo" character varying, "Aprobacion" character varying, "Aprobacion_Mensaje" character varying, "Aprobado_Por_Nombre" character varying, "Fecha_Aprobacion" timestamp without time zone, "Origen" character varying, "Estado" character varying, "Acceso_Restringido" character, "Trae_Equipos" character, "Trae_Herramientas" character, "Fecha_Hora_Ingreso" timestamp without time zone, "Fecha_Hora_Salida" timestamp without time zone, "Puede_Retirar" character, "Puede_Corregir" character, "Puede_Reactivar" character, "Puede_Decidir" character, "Pasos_Mis_Decidir" character varying)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(IN "HV_ID_Solicitud" bigint, IN "HV_ID_Persona_Externa" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_ID_Solicitud_Persona_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n      INT := 0;
    lv_sede   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_sp     BIGINT;
    lv_apr    VARCHAR(20);
    lv_apr2   VARCHAR(20);
    lv_nom    VARCHAR(400);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
    lv_dest   VARCHAR(2000);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR';
    "HV_ID_Solicitud_Persona_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_owner, lv_estado, lv_fecha, lv_codsol
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para modificarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres")
          INTO lv_n, lv_nom FROM "CAF_Persona_Externa"
         WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La persona no está registrada.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("ID_Solicitud_Persona"), MAX("Aprobacion") INTO lv_n, lv_sp, lv_apr
          FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';

        IF lv_n > 0 AND lv_apr <> 'RETIRADA' THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := CASE WHEN lv_apr = 'RECHAZADA' THEN 'Esa persona figura en la solicitud como rechazada.'
                                 ELSE 'Esa persona ya está en la solicitud.' END;
            RETURN;
        END IF;

        IF lv_n > 0 THEN
            -- Vuelve a agregarse a quien se había retirado: se reactiva la misma fila
            UPDATE "CAF_Solicitud_Persona"
               SET "Aprobacion" = 'PENDIENTE', "Aprobacion_Mensaje" = NULL, "ID_Usuario_Aprobacion" = NULL, "Fecha_Aprobacion" = NULL,
                   "Origen" = 'AGREGADA', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = lv_sp;
        ELSE
            INSERT INTO "CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","Origen","UsuarioID_Create")
            VALUES ("HV_ID_Solicitud", "HV_ID_Persona_Externa", 'PENDIENTE', 'AGREGADA', "HV_UsuarioID")
            RETURNING "ID_Solicitud_Persona" INTO lv_sp;
        END IF;

        CALL "ERP_CAF_SOLICITUD_HEREDAR_PASOS"("HV_ID_Solicitud", lv_sp, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'heredar: %', lv_m; END IF;
        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', lv_sp, "HV_ID_Solicitud", 'AGREGAR',
             lv_nom || CASE WHEN lv_n > 0 THEN ' (volvió a agregarse)' ELSE '' END, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        SELECT "Aprobacion" INTO lv_apr2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = lv_sp;
        IF lv_apr2 = 'PENDIENTE' THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PASO_PENDIENTE', lv_sp, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', "HV_ID_Solicitud", lv_dest, NULL,
                 'Persona por aprobar en ' || lv_codsol,
                 '<p>Se agregó a ' || lv_nom || ' a la solicitud ' || lv_codsol || ' y espera su decisión.</p>', "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_ID_Solicitud_Persona_Result" := lv_sp;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Persona agregada a la solicitud.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR';
        "HV_ID_Solicitud_Persona_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA"(IN "HV_ID_Solicitud" bigint, IN "HV_ID_Persona_Externa" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_ID_Solicitud_Persona_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n      INT := 0;
    lv_sede   BIGINT;
    lv_tipo   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_sp     BIGINT;
    lv_apr    VARCHAR(20);
    lv_apr2   VARCHAR(20);
    lv_nom    VARCHAR(400);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
    lv_dest   VARCHAR(2000);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA';
    "HV_ID_Solicitud_Persona_Result" := 0;
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud: si dos personas deciden a la vez, la segunda espera y ve lo ya registrado
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        SELECT COUNT(*), MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_n, lv_sede, lv_tipo, lv_owner, lv_estado, lv_fecha, lv_codsol
          FROM "CAF_Solicitud" WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud no existe.'; RETURN;
        END IF;
        IF "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_APROBAR', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'No tiene permiso para aprobar en esta sede.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Obligatorio" = 'Y'
           AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", S."ID_Catalogo_Licencia", lv_sede) = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Su rol no decide ningún paso de este tipo de acceso.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres")
          INTO lv_n, lv_nom FROM "CAF_Persona_Externa"
         WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La persona no está registrada.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("ID_Solicitud_Persona"), MAX("Aprobacion") INTO lv_n, lv_sp, lv_apr
          FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "ID_Persona_Externa" = "HV_ID_Persona_Externa" AND "Eliminado" = 'N';
        IF lv_n > 0 AND lv_apr <> 'RETIRADA' THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := CASE WHEN lv_apr = 'RECHAZADA' THEN 'Esa persona figura en la solicitud como rechazada.'
                                 ELSE 'Esa persona ya está en la solicitud.' END;
            RETURN;
        END IF;

        IF lv_n > 0 THEN
            UPDATE "CAF_Solicitud_Persona"
               SET "Aprobacion" = 'PENDIENTE', "Aprobacion_Mensaje" = NULL, "ID_Usuario_Aprobacion" = NULL, "Fecha_Aprobacion" = NULL,
                   "Origen" = 'AGREGADA_COORDINADOR', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = lv_sp;
        ELSE
            INSERT INTO "CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","Origen","UsuarioID_Create")
            VALUES ("HV_ID_Solicitud", "HV_ID_Persona_Externa", 'PENDIENTE', 'AGREGADA_COORDINADOR', "HV_UsuarioID")
            RETURNING "ID_Solicitud_Persona" INTO lv_sp;
        END IF;

        CALL "ERP_CAF_SOLICITUD_HEREDAR_PASOS"("HV_ID_Solicitud", lv_sp, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'heredar: %', lv_m; END IF;

        -- Aprueba los pasos por persona que le corresponden por rol, sin saltarse el orden
        INSERT INTO "CAF_Solicitud_Decision"
               ("ID_Solicitud_Persona","ID_Tipo_Acceso_Paso_Aprobacion","Decision","Mensaje","ID_Usuario","Fecha_Decision","UsuarioID_Create")
        SELECT lv_sp, S."ID_Tipo_Acceso_Paso_Aprobacion", 'APROBADA', 'Agregada y aprobada por quien decide el paso',
               "HV_UsuarioID", CURRENT_TIMESTAMP, "HV_UsuarioID"
          FROM "Tipo_Acceso_Paso_Aprobacion" S
         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Eliminado" = 'N' AND S."Activo" = 'Y' AND S."Alcance" = 'PERSONA'
           AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", S."ID_Catalogo_Licencia", lv_sede) = 'Y'
           AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D
                            WHERE D."ID_Solicitud_Persona" = lv_sp AND D."ID_Tipo_Acceso_Paso_Aprobacion" = S."ID_Tipo_Acceso_Paso_Aprobacion"
                              AND D."Vigente" = 'Y' AND D."Eliminado" = 'N')
           AND NOT EXISTS (SELECT 1 FROM "Tipo_Acceso_Paso_Aprobacion" L
                            WHERE L."ID_Catalogo_Tipo_Acceso" = lv_tipo AND L."Eliminado" = 'N' AND L."Activo" = 'Y'
                              AND L."Obligatorio" = 'Y' AND L."Orden" < S."Orden"
                              AND NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Decision" D2
                                               WHERE D2."ID_Solicitud_Persona" = lv_sp AND D2."ID_Tipo_Acceso_Paso_Aprobacion" = L."ID_Tipo_Acceso_Paso_Aprobacion"
                                                 AND D2."Vigente" = 'Y' AND D2."Eliminado" = 'N' AND D2."Decision" = 'APROBADA')
                              AND NOT (L."Alcance" = 'PERSONA'
                                       AND "ERP_CAF_FN_USUARIO_TIENE_ROL"("HV_UsuarioID", L."ID_Catalogo_Licencia", lv_sede) = 'Y'));

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"("HV_ID_Solicitud", "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', lv_sp, "HV_ID_Solicitud", 'AGREGAR_APROBADA', lv_nom, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        -- Se avisa al solicitante; y a los demás aprobadores si todavía faltan pasos
        CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'SOLICITANTE', NULL, lv_dest, lv_c, lv_m);
        CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_DECISION', "HV_ID_Solicitud", lv_dest, NULL,
             'Se agregó a una persona en ' || lv_codsol,
             '<p>Se agregó a ' || lv_nom || ' a la solicitud ' || lv_codsol || ' porque llegó a portería.</p>', "HV_UsuarioID", lv_c, lv_m);
        SELECT "Aprobacion" INTO lv_apr2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = lv_sp;
        IF lv_apr2 = 'PENDIENTE' THEN
            CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"("HV_ID_Solicitud", 'PASO_PENDIENTE', lv_sp, lv_dest, lv_c, lv_m);
            CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', "HV_ID_Solicitud", lv_dest, NULL,
                 'Persona por aprobar en ' || lv_codsol,
                 '<p>' || lv_nom || ' llegó sin estar en la solicitud ' || lv_codsol || ' y espera su decisión.</p>', "HV_UsuarioID", lv_c, lv_m);
        END IF;

        "HV_ID_Solicitud_Persona_Result" := lv_sp;
        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN lv_apr2 = 'APROBADA' THEN 'Persona agregada y aprobada.'
                                 ELSE 'Persona agregada; faltan pasos de otros aprobadores.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA';
        "HV_ID_Solicitud_Persona_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(IN "HV_ID_Solicitud_Persona" bigint, IN "HV_ID_Persona_Externa_Nueva" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_Reenviada_Result" character DEFAULT NULL::bpchar, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n      INT := 0;
    lv_sol    BIGINT;
    lv_apr    VARCHAR(20);
    lv_ing    VARCHAR(20);
    lv_ext    BIGINT;
    lv_tipo   BIGINT;
    lv_sede   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_codsol VARCHAR(20);
    lv_nom    VARCHAR(400);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
    lv_dest   VARCHAR(2000);
    lv_cambia CHAR(1) := 'N';
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_CORREGIR';
    "HV_Reenviada_Result" := 'N';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud (se toma desde la persona): la segunda operación espera y ve lo ya registrado
        SELECT MAX("ID_Solicitud") INTO lv_sol FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = lv_sol;
        SELECT COUNT(*), MAX("ID_Solicitud"), MAX("Aprobacion"), MAX("Estado"), MAX("ID_Persona_Externa")
          INTO lv_n, lv_sol, lv_apr, lv_ing, lv_ext
          FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no está en la solicitud.'; RETURN;
        END IF;
        SELECT MAX("ID_Catalogo_Sede"), MAX("ID_Catalogo_Tipo_Acceso"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista"), MAX("Codigo")
          INTO lv_sede, lv_tipo, lv_owner, lv_estado, lv_fecha, lv_codsol FROM "CAF_Solicitud" WHERE "ID_Solicitud" = lv_sol;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para modificarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;
        IF lv_apr = 'APROBADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'Una persona autorizada no se edita: retírela y agregue otra persona.'; RETURN;
        END IF;
        IF lv_apr = 'RECHAZADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona fue rechazada: está cerrada y no se modifica.'; RETURN;
        END IF;
        IF lv_apr = 'RETIRADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona está retirada. Vuelva a agregarla primero.'; RETURN;
        END IF;
        IF lv_ing <> 'ESPERADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona ya tiene movimientos en portería: no se modifica.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres")
          INTO lv_n, lv_nom FROM "CAF_Persona_Externa"
         WHERE "ID_Persona_Externa" = "HV_ID_Persona_Externa_Nueva" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La persona indicada no está registrada.'; RETURN;
        END IF;

        IF "HV_ID_Persona_Externa_Nueva" <> lv_ext THEN
            SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
             WHERE "ID_Solicitud" = lv_sol AND "ID_Persona_Externa" = "HV_ID_Persona_Externa_Nueva" AND "Eliminado" = 'N';
            IF lv_n > 0 THEN
                "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Esa persona ya figura en la solicitud.'; RETURN;
            END IF;
            lv_cambia := 'Y';
            UPDATE "CAF_Solicitud_Persona"
               SET "ID_Persona_Externa" = "HV_ID_Persona_Externa_Nueva", "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
        END IF;

        IF lv_apr = 'OBSERVADA' OR lv_cambia = 'Y' THEN
            -- Se reabren solo los pasos por persona; los de la solicitud se conservan
            UPDATE "CAF_Solicitud_Decision"
               SET "Vigente" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
             WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Vigente" = 'Y' AND "Eliminado" = 'N'
               AND "ID_Tipo_Acceso_Paso_Aprobacion" IN (SELECT S."ID_Tipo_Acceso_Paso_Aprobacion" FROM "Tipo_Acceso_Paso_Aprobacion" S
                                                         WHERE S."ID_Catalogo_Tipo_Acceso" = lv_tipo AND S."Alcance" = 'PERSONA');
            IF lv_apr = 'OBSERVADA' THEN
                UPDATE "CAF_Solicitud_Persona"
                   SET "Origen" = 'REENVIADA', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
                 WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";
                "HV_Reenviada_Result" := 'Y';
            END IF;

            CALL "ERP_CAF_SOLICITUD_RECALCULAR"(lv_sol, "HV_UsuarioID", lv_est2, lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
            CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', "HV_ID_Solicitud_Persona", lv_sol,
                 CASE WHEN lv_apr = 'OBSERVADA' THEN 'REENVIAR' ELSE 'CORREGIR' END, lv_nom, "HV_UsuarioID", lv_c, lv_m);
            IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

            IF lv_apr = 'OBSERVADA' THEN
                CALL "ERP_CAF_SOLICITUD_DESTINATARIOS"(lv_sol, 'PASO_PENDIENTE', "HV_ID_Solicitud_Persona", lv_dest, lv_c, lv_m);
                CALL "ERP_CAF_CORREO_ENCOLAR"('PERSONA_POR_APROBAR', lv_sol, lv_dest, NULL,
                     'Persona corregida en ' || lv_codsol,
                     '<p>' || lv_nom || ' fue corregida y reenviada en la solicitud ' || lv_codsol || '.</p>', "HV_UsuarioID", lv_c, lv_m);
            END IF;
        END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := CASE WHEN lv_apr = 'OBSERVADA' THEN 'Persona corregida y reenviada a aprobación.'
                                 WHEN lv_cambia = 'Y' THEN 'Persona corregida.'
                                 ELSE 'Sin cambios.' END;
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_CORREGIR';
        "HV_Reenviada_Result" := 'N';
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(IN "HV_ID_Solicitud_Persona" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n      INT := 0;
    lv_sol    BIGINT;
    lv_apr    VARCHAR(20);
    lv_ing    VARCHAR(20);
    lv_ext    BIGINT;
    lv_sede   BIGINT;
    lv_owner  BIGINT;
    lv_estado VARCHAR(20);
    lv_fecha  TIMESTAMP;
    lv_nom    VARCHAR(400);
    lv_c      INT;
    lv_m      VARCHAR(250);
    lv_est2   VARCHAR(20);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_RETIRAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        -- Serializa por solicitud (se toma desde la persona): la segunda operación espera y ve lo ya registrado
        SELECT MAX("ID_Solicitud") INTO lv_sol FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        UPDATE "CAF_Solicitud" SET "UpdateDate" = "UpdateDate" WHERE "ID_Solicitud" = lv_sol;
        SELECT COUNT(*), MAX("ID_Solicitud"), MAX("Aprobacion"), MAX("Estado"), MAX("ID_Persona_Externa")
          INTO lv_n, lv_sol, lv_apr, lv_ing, lv_ext
          FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La persona no está en la solicitud.'; RETURN;
        END IF;
        SELECT MAX("ID_Catalogo_Sede"), MAX("ID_Usuario_Solicitante"), MAX("Estado"), MAX("Fecha_Hora_Prevista")
          INTO lv_sede, lv_owner, lv_estado, lv_fecha FROM "CAF_Solicitud" WHERE "ID_Solicitud" = lv_sol;
        IF lv_owner <> "HV_UsuarioID" OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_SOLICITUD_PROPIA', lv_sede) <> 'Y' THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'La solicitud no es suya o no tiene permiso para modificarla.'; RETURN;
        END IF;
        IF lv_estado = 'CANCELADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La solicitud está cancelada.'; RETURN;
        END IF;
        IF CAST(lv_fecha AS DATE) < CURRENT_DATE THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La fecha de la visita ya pasó.'; RETURN;
        END IF;
        IF lv_apr = 'RETIRADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona ya está retirada.'; RETURN;
        END IF;
        IF lv_apr = 'RECHAZADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona fue rechazada: está cerrada y no se modifica.'; RETURN;
        END IF;
        IF lv_ing <> 'ESPERADA' THEN
            "HV_Codigo_Resp" := 409; "HV_Mensaje" := 'La persona ya tiene movimientos en portería: no se retira.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_Solicitud_Persona"
         WHERE "ID_Solicitud" = lv_sol AND "Eliminado" = 'N' AND "Aprobacion" <> 'RETIRADA'
           AND "ID_Solicitud_Persona" <> "HV_ID_Solicitud_Persona";
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Es la última persona de la solicitud. Cancele la solicitud en su lugar.'; RETURN;
        END IF;

        SELECT "Apellido_Paterno" || COALESCE(' ' || "Apellido_Materno", '') || ', ' || "Nombres" INTO lv_nom
          FROM "CAF_Persona_Externa" WHERE "ID_Persona_Externa" = lv_ext;

        UPDATE "CAF_Solicitud_Decision"
           SET "Vigente" = 'N', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona" AND "Vigente" = 'Y' AND "Eliminado" = 'N';
        UPDATE "CAF_Solicitud_Persona"
           SET "Aprobacion" = 'RETIRADA', "Aprobacion_Mensaje" = NULL,
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud_Persona" = "HV_ID_Solicitud_Persona";

        CALL "ERP_CAF_SOLICITUD_RECALCULAR"(lv_sol, "HV_UsuarioID", lv_est2, lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'recalcular: %', lv_m; END IF;
        CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD_PERSONA', "HV_ID_Solicitud_Persona", lv_sol, 'RETIRAR', lv_nom, "HV_UsuarioID", lv_c, lv_m);
        IF lv_c <> 100 THEN RAISE EXCEPTION 'evento: %', lv_m; END IF;

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Persona retirada. No necesitó aprobación.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_SOLICITUD_PERSONA_RETIRAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_RECALCULAR"(IN "HV_ID_Solicitud" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_Estado_Result" character varying DEFAULT NULL::character varying, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
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
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_VERSION_GUARDAR"(IN "HV_ID_Solicitud" bigint, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
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
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_VERSION_LISTAR"("HV_UsuarioID" bigint, "HV_ID_Solicitud" bigint)
 RETURNS TABLE("Version" bigint, "Fecha_Aprobacion" timestamp without time zone, "ID_Usuario_Aprobador" bigint, "Aprobador_Nombre" character varying, "Contenido_JSON" text)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"("HV_UsuarioID" bigint, "HV_ID_Catalogo_Sede" bigint DEFAULT NULL::bigint, "HV_Fecha" date DEFAULT NULL::date, "HV_Texto" character varying DEFAULT NULL::character varying, "HV_Grupo" character varying DEFAULT NULL::character varying)
 RETURNS TABLE("ID_Solicitud_Persona" bigint, "ID_Solicitud" bigint, "Codigo" character varying, "ID_Catalogo_Sede" bigint, "Fecha_Hora_Prevista" timestamp without time zone, "Empresa_Visitante" character varying, "Responsable_Nombre" character varying, "Tipo_Documento" character varying, "Numero_Documento" character varying, "Persona_Nombre" character varying, "Estado" character varying, "Grupo" character varying, "Fecha_Hora_Ingreso" timestamp without time zone, "Fecha_Hora_Salida" timestamp without time zone, "Acceso_Restringido" character, "Trae_Equipos" character, "Trae_Herramientas" character, "Exige_SCTR" character, "Exige_EPP" character, "Zonas_Nombres" character varying)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR"("HV_UsuarioID" bigint, "HV_ID_Catalogo_Sede" bigint, "HV_Fecha" date, "HV_Texto" character varying)
 RETURNS TABLE("Codigo" character varying, "Persona_Nombre" character varying, "Numero_Documento" character varying, "Empresa_Visitante" character varying, "Motivo_Codigo" character varying, "Motivo_Texto" character varying)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
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
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR"(IN "HV_ID_Tipo_Acceso_Paso_Aprobacion" bigint, IN "HV_Orden" bigint, IN "HV_Descripcion" character varying, IN "HV_Alcance" character varying, IN "HV_ID_Catalogo_Licencia" bigint, IN "HV_Obligatorio" character, IN "HV_Activo" character, IN "HV_UsuarioID" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n          INT := 0;
    lv_decisiones INT := 0;
    lv_alcance    VARCHAR(20);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR';
    BEGIN
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF "HV_Orden" IS NULL OR "HV_Orden" < 1 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El orden debe ser 1 o más.'; RETURN;
        END IF;
        IF COALESCE("HV_Alcance",'PERSONA') NOT IN ('PERSONA','SOLICITUD') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El alcance debe ser PERSONA o SOLICITUD.'; RETURN;
        END IF;
        IF COALESCE("HV_Obligatorio",'Y') NOT IN ('Y','N') OR COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Obligatorio y Activo deben ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*), MAX("Alcance") INTO lv_n, lv_alcance FROM "Tipo_Acceso_Paso_Aprobacion"
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El paso no existe o ya fue quitado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_decisiones FROM "CAF_Solicitud_Decision"
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion" AND "Eliminado" = 'N';
        IF lv_decisiones > 0 AND lv_alcance <> COALESCE("HV_Alcance", lv_alcance) THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Ya tiene ' || lv_decisiones || ' decisiones: no se puede cambiar su alcance.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Catalogo_Licencia"
         WHERE "ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El rol que aprueba no existe.'; RETURN;
        END IF;

        UPDATE "Tipo_Acceso_Paso_Aprobacion"
           SET "Orden" = "HV_Orden", "Descripcion" = TRIM("HV_Descripcion"),
               "Alcance" = COALESCE("HV_Alcance", "Alcance"), "ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia",
               "Obligatorio" = COALESCE("HV_Obligatorio",'Y'), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Paso de aprobación actualizado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR';
    END;
END;
$procedure$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(IN "HV_ID_Catalogo_Tipo_Acceso" bigint, IN "HV_Orden" bigint, IN "HV_Codigo" character varying, IN "HV_Descripcion" character varying, IN "HV_Alcance" character varying, IN "HV_Tipo_Aprobador" character varying, IN "HV_ID_Catalogo_Licencia" bigint, IN "HV_Condicion" character varying, IN "HV_Obligatorio" character, IN "HV_UsuarioID_Create" bigint, INOUT "HV_ID_Tipo_Acceso_Paso_Aprobacion_Result" bigint DEFAULT NULL::bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n INT := 0;
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_AGREGAR';
    "HV_ID_Tipo_Acceso_Paso_Aprobacion_Result" := 0;
    BEGIN
        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código del paso es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF "HV_Orden" IS NULL OR "HV_Orden" < 1 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El orden debe ser 1 o más.'; RETURN;
        END IF;
        IF COALESCE("HV_Alcance",'PERSONA') NOT IN ('PERSONA','SOLICITUD') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El alcance debe ser PERSONA o SOLICITUD.'; RETURN;
        END IF;
        IF COALESCE("HV_Tipo_Aprobador",'ROL') NOT IN ('ROL') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Tipo de aprobador no admitido todavía.'; RETURN;
        END IF;
        IF COALESCE("HV_Condicion",'SIEMPRE') NOT IN ('SIEMPRE') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Condición no admitida todavía.'; RETURN;
        END IF;
        IF COALESCE("HV_Obligatorio",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Obligatorio debe ser Y o N.'; RETURN;
        END IF;
        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Catalogo_Tipo_Acceso"
         WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tipo de acceso no existe.'; RETURN;
        END IF;

        IF COALESCE("HV_Tipo_Aprobador",'ROL') = 'ROL' THEN
            SELECT COUNT(*) INTO lv_n FROM "CAF_GOVERNANCE"."Catalogo_Licencia"
             WHERE "ID_Catalogo_Licencia" = "HV_ID_Catalogo_Licencia" AND "Eliminado" = 'N' AND "Activo" = 'Y';
            IF lv_n = 0 THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El rol que aprueba no existe o está inactivo.'; RETURN;
            END IF;
        END IF;

        SELECT COUNT(*) INTO lv_n FROM "Tipo_Acceso_Paso_Aprobacion"
         WHERE "ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso"
           AND UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_n > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ese tipo de acceso ya tiene un paso con ese código.'; RETURN;
        END IF;

        INSERT INTO "Tipo_Acceso_Paso_Aprobacion"
          ("ID_Catalogo_Tipo_Acceso","Orden","Codigo","Descripcion","Alcance","Tipo_Aprobador","ID_Catalogo_Licencia","Condicion","Obligatorio","UsuarioID_Create")
        VALUES ("HV_ID_Catalogo_Tipo_Acceso", "HV_Orden", UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"),
                COALESCE("HV_Alcance",'PERSONA'), COALESCE("HV_Tipo_Aprobador",'ROL'), "HV_ID_Catalogo_Licencia",
                COALESCE("HV_Condicion",'SIEMPRE'), COALESCE("HV_Obligatorio",'Y'), "HV_UsuarioID_Create")
        RETURNING "ID_Tipo_Acceso_Paso_Aprobacion" INTO "HV_ID_Tipo_Acceso_Paso_Aprobacion_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Paso de aprobación agregado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_AGREGAR';
        "HV_ID_Tipo_Acceso_Paso_Aprobacion_Result" := 0;
    END;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE"("HV_ID_Catalogo_Tipo_Acceso" bigint, "HV_Incluir_Inactivos" character DEFAULT 'N'::bpchar)
 RETURNS TABLE("ID_Tipo_Acceso_Paso_Aprobacion" bigint, "ID_Catalogo_Tipo_Acceso" bigint, "Orden" bigint, "Codigo" character varying, "Descripcion" character varying, "Alcance" character varying, "Tipo_Aprobador" character varying, "ID_Catalogo_Licencia" bigint, "Codigo_Licencia" character varying, "Rol" character varying, "Condicion" character varying, "Obligatorio" character, "Activo" character, "CreateDate" timestamp without time zone)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $function$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-10-16
    RETURN QUERY
    SELECT T0."ID_Tipo_Acceso_Paso_Aprobacion", T0."ID_Catalogo_Tipo_Acceso", T0."Orden",
           T0."Codigo", T0."Descripcion", T0."Alcance", T0."Tipo_Aprobador",
           T0."ID_Catalogo_Licencia", L."Codigo", L."Descripcion",
           T0."Condicion", T0."Obligatorio", T0."Activo", T0."CreateDate"
      FROM "Tipo_Acceso_Paso_Aprobacion" T0
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = T0."ID_Catalogo_Licencia"
     WHERE T0."ID_Catalogo_Tipo_Acceso" = "HV_ID_Catalogo_Tipo_Acceso"
       AND T0."Eliminado" = 'N'
       AND ("HV_Incluir_Inactivos" = 'Y' OR T0."Activo" = 'Y')
     ORDER BY T0."Orden", T0."Codigo";
END;
$function$
;

CREATE OR REPLACE PROCEDURE "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_QUITAR"(IN "HV_ID_Tipo_Acceso_Paso_Aprobacion" bigint, IN "HV_UsuarioID_Update" bigint, INOUT "HV_Codigo_Resp" integer DEFAULT NULL::integer, INOUT "HV_Mensaje" character varying DEFAULT NULL::character varying)
 LANGUAGE plpgsql
 SET search_path TO 'TRIANONSATELITAL_CAF_PRODD'
AS $procedure$
DECLARE
    lv_n          INT := 0;
    lv_tipo       BIGINT;
    lv_decisiones INT := 0;
    lv_quedan     INT := 0;
    lv_disponible CHAR(1);
BEGIN
    -- V1.0 2026-10-16
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_QUITAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;
        SELECT COUNT(*), MAX("ID_Catalogo_Tipo_Acceso") INTO lv_n, lv_tipo
          FROM "Tipo_Acceso_Paso_Aprobacion"
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El paso no existe o ya fue quitado.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_decisiones FROM "CAF_Solicitud_Decision"
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion" AND "Eliminado" = 'N';
        IF lv_decisiones > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Tiene ' || lv_decisiones || ' decisiones registradas. Desactívelo en vez de quitarlo.'; RETURN;
        END IF;

        SELECT MAX("Disponible") INTO lv_disponible FROM "Catalogo_Tipo_Acceso"
         WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo;
        SELECT COUNT(*) INTO lv_quedan FROM "Tipo_Acceso_Paso_Aprobacion"
         WHERE "ID_Catalogo_Tipo_Acceso" = lv_tipo AND "Eliminado" = 'N' AND "Activo" = 'Y' AND "Obligatorio" = 'Y'
           AND "ID_Tipo_Acceso_Paso_Aprobacion" <> "HV_ID_Tipo_Acceso_Paso_Aprobacion";
        IF lv_disponible = 'Y' AND lv_quedan = 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Es el único paso obligatorio de un tipo de acceso disponible; no se puede quitar.'; RETURN;
        END IF;

        UPDATE "Tipo_Acceso_Paso_Aprobacion"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = "HV_ID_Tipo_Acceso_Paso_Aprobacion";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := 'Paso de aprobación quitado correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CAF_TIPO_ACCESO_PASO_QUITAR';
    END;
END;
$procedure$
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

