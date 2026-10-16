-- =============================================================================
-- Archivo : PRUEBAS_FASE1_PERMISOS.sql
-- Proyecto: Control de Accesos · V1.0 2026-10-16
-- Propósito: pruebas automáticas de los permisos, los roles y los pasos de
--   aprobación que agrega el script 09. Cada prueba llama una rutina y compara
--   el resultado con lo esperado. Termina en ROLLBACK: la base queda igual.
-- Requiere: scripts 01 a 09, los SP del Hito 0 y 1, SP_GOVERNANCE_PERMISO_ALL
--   y SP_CAF_TIPO_ACCESO_PASO_APROBACION_ALL.
-- Ejecutar con psql, o en pgAdmin el archivo completo de una vez.
-- =============================================================================

BEGIN;
CREATE TEMP TABLE pruebas (n SERIAL, prueba TEXT, esperado TEXT, obtenido TEXT, detalle TEXT) ON COMMIT DROP;

DO $$
DECLARE
    v_cod INT; v_msg VARCHAR(250); v_n INT; v_txt VARCHAR; v_id BIGINT;
    v_ves BIGINT; v_mag BIGINT; v_dni BIGINT; v_area BIGINT; v_emp BIGINT;
    v_lic_sol BIGINT; v_lic_coo BIGINT; v_lic_vig BIGINT; v_lic_adm BIGINT; v_lic_alm BIGINT;
    v_per BIGINT; v_u_adm BIGINT; v_u_alm BIGINT; v_ul BIGINT;
    v_tipo_ext BIGINT; v_tipo_con BIGINT; v_paso1 BIGINT; v_paso2 BIGINT; v_ext BIGINT;
BEGIN
    SELECT "ID_Catalogo_Sede" INTO v_ves FROM "CAF_GOVERNANCE"."Catalogo_Sede" WHERE "Codigo" = 'VES';
    SELECT "ID_Catalogo_Sede" INTO v_mag FROM "CAF_GOVERNANCE"."Catalogo_Sede" WHERE "Codigo" = 'MAG';
    SELECT "ID_Catalogo_Tipo_Documento" INTO v_dni FROM "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" WHERE "Codigo" = 'DNI';
    SELECT "ID_Catalogo_Area" INTO v_area FROM "CAF_GOVERNANCE"."Catalogo_Area" WHERE "Codigo" = 'ALMACEN';
    SELECT "ID_Catalogo_Empresa_Grupo" INTO v_emp FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" LIMIT 1;
    SELECT "ID_Catalogo_Licencia" INTO v_lic_sol FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_SOLICITANTE';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_coo FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_COORDINADOR';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_vig FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_VIGILANCIA';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_adm FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_ADMIN';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_tipo_ext FROM "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Acceso" WHERE "Codigo" = 'VISITA_EXTERNA';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_tipo_con FROM "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Tipo_Acceso" WHERE "Codigo" = 'CONTRATISTA';

    -- ===================================================== CARGA INICIAL
    SELECT COUNT(*) INTO v_n FROM "CAF_GOVERNANCE"."ERP_CATALOGO_PERMISO_LISTAR"();
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Carga: 13 permisos', '13', v_n::TEXT, '');
    SELECT COUNT(*) INTO v_n FROM "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_LISTAR_POR_PADRE"(v_lic_coo) WHERE "Asignado" = 'Y';
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Carga: Coordinador con 7 permisos', '7', v_n::TEXT, '');
    SELECT COUNT(*) INTO v_n FROM "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_LISTAR_POR_PADRE"(v_lic_coo);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Pantalla de roles: lista los 13 con su marca', '13', v_n::TEXT, 'asignados y no asignados');
    SELECT COUNT(*) INTO v_n FROM "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_LISTAR_POR_PADRE"(v_lic_vig) WHERE "Asignado" = 'Y';
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Carga: Vigilancia con 4 permisos', '4', v_n::TEXT, '');
    SELECT COUNT(*) INTO v_n FROM "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE"(v_tipo_ext);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Carga: visitante externo con 1 paso', '1', v_n::TEXT, 'el flujo actual no cambia');
    SELECT COUNT(*) INTO v_n FROM "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE"(v_tipo_con);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Carga: contratista todavía sin pasos', '0', v_n::TEXT, '');
    SELECT "Rol" INTO v_txt FROM "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE"(v_tipo_ext) LIMIT 1;
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('El paso trae el nombre del rol que aprueba', (SELECT "Descripcion" FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_COORDINADOR'), v_txt, 'cruza los dos schemas');

    -- ===================================================== UN ROL NUEVO SIN PROGRAMAR
    INSERT INTO "CAF_GOVERNANCE"."Catalogo_Licencia" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create")
    VALUES ('LIC_CAF_APROB_ALMACEN','Aprobador de almacén','ACCESOS',5,0) RETURNING "ID_Catalogo_Licencia" INTO v_lic_alm;
    CALL "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_ASIGNAR"(v_lic_alm, 'PER_CAF_SOLICITUD_APROBAR', 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Rol nuevo: asignar 1 permiso', '100', v_cod::TEXT, v_msg);
    SELECT COUNT(*) INTO v_n FROM "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_LISTAR_POR_PADRE"(v_lic_alm) WHERE "Asignado" = 'Y';
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Rol nuevo: queda con 1 permiso', '1', v_n::TEXT, 'sin tocar el programa');

    CALL "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_ASIGNAR"(v_lic_alm, 'PER_CAF_SOLICITUD_APROBAR, PER_CAF_INVENTADO', 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Permiso inexistente se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_ASIGNAR"(999999, 'PER_CAF_REPORTE_VER', 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Rol inexistente', '404', v_cod::TEXT, v_msg);

    -- Reemplazo completo: agrega, conserva y retira en una sola llamada
    CALL "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_ASIGNAR"(v_lic_alm, ' per_caf_solicitud_aprobar , PER_CAF_REPORTE_VER ', 0, v_cod, v_msg);
    SELECT COUNT(*) INTO v_n FROM "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_LISTAR_POR_PADRE"(v_lic_alm) WHERE "Asignado" = 'Y';
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Asignar acepta minúsculas y espacios', '2', v_n::TEXT, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_ASIGNAR"(v_lic_alm, 'PER_CAF_SOLICITUD_APROBAR', 0, v_cod, v_msg);
    SELECT COUNT(*) INTO v_n FROM "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_LISTAR_POR_PADRE"(v_lic_alm) WHERE "Asignado" = 'Y';
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Asignar retira los que ya no vienen', '1', v_n::TEXT, '');
    CALL "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_ASIGNAR"(v_lic_alm, 'PER_CAF_SOLICITUD_APROBAR, PER_CAF_REPORTE_VER', 0, v_cod, v_msg);
    SELECT COUNT(*) INTO v_n FROM "CAF_GOVERNANCE"."Licencia_Permiso" WHERE "ID_Catalogo_Licencia" = v_lic_alm;
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Reasignar reactiva la fila, no duplica', '2', v_n::TEXT, 'incluye las retiradas');

    -- ===================================================== PERMISOS DE UN USUARIO
    INSERT INTO "CAF_GOVERNANCE"."Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","UsuarioID_Create")
    VALUES (v_dni,'33221144','Prueba','Almacén','Jorge',v_area,v_emp,v_ves,0) RETURNING "ID_Personal" INTO v_per;
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_CREAR"('jorge.almacen@ejemplo.pe',v_dni,'33221144','Prueba','Almacén','Jorge',v_per,NULL,'Y',0, v_u_alm, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_u_alm, v_lic_alm, v_ves, 0, v_ul, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Usuario con el rol nuevo en VES', '100', v_cod::TEXT, v_msg);

    SELECT COUNT(*) INTO v_n FROM "CAF_GOVERNANCE"."ERP_USUARIO_PERMISO_LISTAR"(v_u_alm);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Permisos efectivos del aprobador de almacén', '2', v_n::TEXT, 'aprobar y ver reporte');
    SELECT "Tiene" INTO v_txt FROM "CAF_GOVERNANCE"."ERP_USUARIO_PERMISO_VERIFICAR"(v_u_alm, 'PER_CAF_SOLICITUD_APROBAR', v_ves);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Puede aprobar en VES', 'Y', v_txt, '');
    SELECT "Tiene" INTO v_txt FROM "CAF_GOVERNANCE"."ERP_USUARIO_PERMISO_VERIFICAR"(v_u_alm, 'PER_CAF_DESVIACION_CONFORMIDAD', v_ves);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('NO ve desviaciones (el caso que pediste)', 'N', v_txt, 'no hereda nada del Coordinador');
    SELECT "Tiene" INTO v_txt FROM "CAF_GOVERNANCE"."ERP_USUARIO_PERMISO_VERIFICAR"(v_u_alm, 'PER_CAF_INCIDENCIA_DECIDIR', v_ves);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('NO decide incidencias', 'N', v_txt, '');
    SELECT "Tiene" INTO v_txt FROM "CAF_GOVERNANCE"."ERP_USUARIO_PERMISO_VERIFICAR"(v_u_alm, 'PER_CAF_SOLICITUD_APROBAR', v_mag);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('El permiso es por sede: en Magdalena no', 'N', v_txt, '');
    SELECT "Tiene" INTO v_txt FROM "CAF_GOVERNANCE"."ERP_USUARIO_PERMISO_VERIFICAR"(v_u_alm, 'PER_CAF_INVENTADO', v_ves);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Permiso inexistente devuelve N, no error', 'N', v_txt, '');

    -- Un usuario desactivado pierde todos sus permisos
    UPDATE "CAF_GOVERNANCE"."Usuario" SET "Activo" = 'N' WHERE "ID_Usuario" = v_u_alm;
    SELECT "Tiene" INTO v_txt FROM "CAF_GOVERNANCE"."ERP_USUARIO_PERMISO_VERIFICAR"(v_u_alm, 'PER_CAF_SOLICITUD_APROBAR', v_ves);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Usuario inactivo no tiene permisos', 'N', v_txt, '');
    UPDATE "CAF_GOVERNANCE"."Usuario" SET "Activo" = 'Y' WHERE "ID_Usuario" = v_u_alm;

    -- Un rol desactivado deja sin permisos a sus usuarios
    UPDATE "CAF_GOVERNANCE"."Catalogo_Licencia" SET "Activo" = 'N' WHERE "ID_Catalogo_Licencia" = v_lic_alm;
    SELECT "Tiene" INTO v_txt FROM "CAF_GOVERNANCE"."ERP_USUARIO_PERMISO_VERIFICAR"(v_u_alm, 'PER_CAF_SOLICITUD_APROBAR', v_ves);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Rol inactivo deja sin permisos', 'N', v_txt, '');
    UPDATE "CAF_GOVERNANCE"."Catalogo_Licencia" SET "Activo" = 'Y' WHERE "ID_Catalogo_Licencia" = v_lic_alm;

    -- Nunca sin quien administre usuarios
    SELECT COUNT(DISTINCT UL."ID_Usuario") INTO v_n FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
      JOIN "CAF_GOVERNANCE"."Usuario" U ON U."ID_Usuario" = UL."ID_Usuario" AND U."Activo" = 'Y' AND U."Eliminado" = 'N'
     WHERE UL."ID_Catalogo_Licencia" = v_lic_adm AND UL."Eliminado" = 'N';
    IF v_n = 0 THEN
        CALL "CAF_GOVERNANCE"."ERP_USUARIO_CREAR"('admin.prueba@ejemplo.pe',v_dni,'99887766','Prueba','Admin','Sofía',NULL,'TI prueba','Y',0, v_u_adm, v_cod, v_msg);
        CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_u_adm, v_lic_adm, v_ves, 0, v_id, v_cod, v_msg);
    END IF;
    CALL "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_ASIGNAR"(v_lic_adm, 'PER_CAF_ADMIN_CATALOGOS', 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('No deja al sistema sin administrar usuarios', '101', v_cod::TEXT, v_msg);
    SELECT COUNT(*) INTO v_n FROM "CAF_GOVERNANCE"."ERP_LICENCIA_PERMISO_LISTAR_POR_PADRE"(v_lic_adm) WHERE "Asignado" = 'Y';
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Tras el rechazo, el rol Administrador no cambió', '3', v_n::TEXT, '');

    -- ===================================================== PASOS DE UN FLUJO NUEVO
    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_tipo_con, 1, 'DOCUMENTOS', 'Revisión de documentos de cada trabajador', 'PERSONA', 'ROL', v_lic_coo, 'SIEMPRE', 'Y', 0, v_paso1, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Contratista: paso 1 por persona', '100', v_cod::TEXT, v_msg);
    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_tipo_con, 1, 'SERVICIO', 'Aprobación del servicio por el área', 'SOLICITUD', 'ROL', v_lic_alm, 'SIEMPRE', 'Y', 0, v_paso2, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Contratista: paso 2 en paralelo, por solicitud', '100', v_cod::TEXT, v_msg);
    SELECT COUNT(*) INTO v_n FROM "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE"(v_tipo_con);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Flujo de 2 pasos creado solo con datos', '2', v_n::TEXT, 'sin tocar el programa');
    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_tipo_con, 2, 'DOCUMENTOS', 'Repetido', 'PERSONA', 'ROL', v_lic_coo, 'SIEMPRE', 'Y', 0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Código de paso repetido en el mismo flujo', '101', v_cod::TEXT, v_msg);
    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_tipo_con, 1, 'OTRO', 'x', 'EQUIPO', 'ROL', v_lic_coo, 'SIEMPRE', 'Y', 0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Alcance no admitido', '400', v_cod::TEXT, v_msg);
    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_tipo_con, 1, 'OTRO', 'x', 'PERSONA', 'JEFE_SOLICITANTE', NULL, 'SIEMPRE', 'Y', 0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Jefe del solicitante todavía no (P-16)', '400', v_cod::TEXT, v_msg);
    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_tipo_con, 1, 'OTRO', 'x', 'PERSONA', 'ROL', 999999, 'SIEMPRE', 'Y', 0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Rol que aprueba inexistente', '400', v_cod::TEXT, v_msg);
    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_tipo_con, 0, 'OTRO', 'x', 'PERSONA', 'ROL', v_lic_coo, 'SIEMPRE', 'Y', 0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Orden menor que 1', '400', v_cod::TEXT, v_msg);

    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR"(v_paso2, 2, 'Aprobación del servicio (ahora después)', 'SOLICITUD', v_lic_alm, 'Y', 'Y', 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Reordenar un paso a secuencia', '100', v_cod::TEXT, v_msg);
    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_QUITAR"(v_paso2, 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Quitar un paso sin decisiones', '100', v_cod::TEXT, v_msg);
    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_QUITAR"(v_paso2, 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Quitar dos veces', '404', v_cod::TEXT, v_msg);
    SELECT "ID_Tipo_Acceso_Paso_Aprobacion" INTO v_id FROM "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE"(v_tipo_ext) LIMIT 1;
    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_TIPO_ACCESO_PASO_QUITAR"(v_id, 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('No deja sin aprobación a un flujo disponible', '101', v_cod::TEXT, v_msg);

    -- ===================================================== REGLAS DE LAS TABLAS
    BEGIN
        INSERT INTO "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud" ("ID_Catalogo_Sede","ID_Catalogo_Tipo_Acceso","ID_Usuario_Solicitante","ID_Personal_Responsable","Fecha_Hora_Prevista","Empresa_Visitante","ID_Catalogo_Motivo_Visita","Estado","UsuarioID_Create")
        VALUES (v_ves, v_tipo_ext, 1, v_per, CURRENT_TIMESTAMP, 'Prueba S.A.C.', (SELECT MIN("ID_Catalogo_Motivo_Visita") FROM "TRIANONSATELITAL_CAF_PRODD"."Catalogo_Motivo_Visita"), 'APROBADA_PARCIAL', 0);
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Estado APROBADA_PARCIAL admitido', 'ok', 'ok', '');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Estado APROBADA_PARCIAL admitido', 'ok', 'error', SQLERRM);
    END;
    SELECT MAX("ID_Solicitud") INTO v_id FROM "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud";
    CALL "TRIANONSATELITAL_CAF_PRODD"."ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71717171','Visita','Prueba','Elena',0, v_ext, v_cod, v_msg);

    BEGIN
        INSERT INTO "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","UsuarioID_Create")
        VALUES (v_id, v_ext, 'OBSERVADA', 0);
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Observada sin motivo se rechaza', 'error', 'ok', 'la base lo permitió');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Observada sin motivo se rechaza', 'error', 'error', 'la base lo impidió');
    END;
    BEGIN
        INSERT INTO "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","Estado","UsuarioID_Create")
        VALUES (v_id, v_ext, 'PENDIENTE', 'DENTRO', 0);
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Nadie entra sin estar aprobado', 'error', 'ok', 'la base lo permitió');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Nadie entra sin estar aprobado', 'error', 'error', 'la base lo impidió');
    END;
    BEGIN
        INSERT INTO "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","Aprobacion","Aprobacion_Mensaje","UsuarioID_Create")
        VALUES (v_id, v_ext, 'RECHAZADA', 'No autorizado por seguridad.', 0);
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Rechazada con motivo se admite', 'ok', 'ok', '');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Rechazada con motivo se admite', 'ok', 'error', SQLERRM);
    END;
    BEGIN
        INSERT INTO "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Decision" ("ID_Solicitud_Persona","ID_Tipo_Acceso_Paso_Aprobacion","Decision","ID_Usuario","UsuarioID_Create")
        VALUES ((SELECT MAX("ID_Solicitud_Persona") FROM "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona"), v_paso1, 'OBSERVADA', 1, 0);
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Decisión observada sin mensaje se rechaza', 'error', 'ok', 'la base lo permitió');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Decisión observada sin mensaje se rechaza', 'error', 'error', 'la base lo impidió');
    END;
    BEGIN
        INSERT INTO "TRIANONSATELITAL_CAF_PRODD"."CAF_Evento" ("Entidad","ID_Entidad","Accion","ID_Usuario","UsuarioID_Create")
        VALUES ('SOLICITUD_DECISION', v_id, 'APROBAR', 1, 0);
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Bitácora acepta SOLICITUD_DECISION', 'ok', 'ok', '');
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Bitácora acepta SOLICITUD_DECISION', 'ok', 'error', SQLERRM);
    END;
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Mensaje"
  FROM pruebas ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
