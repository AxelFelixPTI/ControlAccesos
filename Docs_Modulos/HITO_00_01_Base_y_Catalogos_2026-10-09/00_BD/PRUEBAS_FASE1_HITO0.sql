-- =============================================================================
-- Archivo : PRUEBAS_FASE1_HITO0.sql
-- Proyecto: Control de Accesos · Hito 0 · Fase 1 · V1.0 2026-10-11
-- Propósito: pruebas automáticas de los procedimientos de CAF_GOVERNANCE.
--   Cada prueba llama un SP y compara el resultado con el esperado.
--   Muestra una tabla con OK / FALLA por prueba y un resumen.
--   Termina en ROLLBACK: la base queda exactamente como estaba.
-- Requiere: scripts 01 a 05 y los SP_GOVERNANCE_*_ALL.sql cargados.
-- Ejecutar con psql (o en pgAdmin, todo el archivo de una vez).
-- =============================================================================

BEGIN;
SET search_path TO "CAF_GOVERNANCE";
CREATE TEMP TABLE pruebas (n SERIAL, prueba TEXT, esperado TEXT, obtenido TEXT, detalle TEXT) ON COMMIT DROP;

DO $$
DECLARE
    v_id BIGINT; v_cod INT; v_msg VARCHAR(250); v_n INT; v_txt VARCHAR; v_i BIGINT; v_b TIMESTAMP;
    v_ves BIGINT; v_lim BIGINT; v_dni BIGINT; v_ing BIGINT; v_emp BIGINT;
    v_lic_adm BIGINT; v_lic_vig BIGINT;
    v_per_rob BIGINT; v_per_gab BIGINT;
    v_u_a BIGINT; v_u_b BIGINT; v_u_c BIGINT; v_ul_a BIGINT; v_ul_a2 BIGINT; v_ul_b BIGINT;
BEGIN
    SELECT "ID_Catalogo_Sede" INTO v_ves FROM "Catalogo_Sede" WHERE "Codigo" = 'VES';
    SELECT "ID_Catalogo_Tipo_Documento" INTO v_dni FROM "Catalogo_Tipo_Documento" WHERE "Codigo" = 'DNI';
    SELECT "ID_Catalogo_Area" INTO v_ing FROM "Catalogo_Area" WHERE "Codigo" = 'INGENIERIA';
    SELECT "ID_Catalogo_Empresa_Grupo" INTO v_emp FROM "Catalogo_Empresa_Grupo" WHERE "Codigo" = 'TRIANON_ASCENSORES';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_adm FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_ADMIN';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_vig FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_VIGILANCIA';

    -- ======================================================== CATÁLOGOS (sede como ejemplo)
    CALL "ERP_CATALOGO_SEDE_CREAR"('lim','Lima centro','Av. Ejemplo 123',5,'Y',0, v_lim, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: crear', '100', v_cod::TEXT, v_msg);
    SELECT "Codigo" INTO v_txt FROM "Catalogo_Sede" WHERE "ID_Catalogo_Sede" = v_lim;
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: código guardado en mayúsculas', 'LIM', v_txt, '');
    CALL "ERP_CATALOGO_SEDE_CREAR"('LIM','Otra','',1,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: código duplicado', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_SEDE_CREAR"('  ','Sin código','',1,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: código vacío', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_SEDE_ACTUALIZAR"(v_lim,'LIM','Lima centro (editada)','',5,'Y',0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: actualizar sin cambiar su propio código', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_SEDE_ACTUALIZAR"(v_lim,'VES','x','',5,'Y',0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: actualizar al código de otra', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_SEDE_ACTUALIZAR"(999999,'XXX','x','',5,'Y',0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: actualizar inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_SEDE_ELIMINAR"(v_lim, 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: eliminar', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_SEDE_ELIMINAR"(v_lim, 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: eliminar dos veces', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_SEDE_CREAR"('LIM','Reusar código','',1,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: reutilizar código eliminado', '101', v_cod::TEXT, v_msg);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_SEDE_DETALLE"(v_lim) WHERE "Eliminado" = 'Y';
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: DETALLE muestra la eliminada', '1', v_n::TEXT, 'no filtra Eliminado');
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_SEDE_LISTAR"() WHERE "ID_Catalogo" = v_lim;
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: LISTAR oculta eliminadas', '0', v_n::TEXT, '');
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_SEDE_LISTAR"('Y') WHERE "ID_Catalogo" = v_lim;
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: LISTAR con eliminadas', '1', v_n::TEXT, '');
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_SEDE_DROPDOWN"();
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: DROPDOWN solo activas', '2', v_n::TEXT, 'VES y MAG');
    CALL "ERP_CATALOGO_TIPO_DOCUMENTO_CREAR"('X','Inválido',8,5,'Y',1,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Tipo doc: máximo menor que mínimo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_EMPRESA_GRUPO_CREAR"('E1','Empresa','2012345',1,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Empresa: RUC de 7 dígitos', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_EMPRESA_GRUPO_CREAR"('E1','Empresa','20123456789',1,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Empresa: RUC válido', '100', v_cod::TEXT, v_msg);

    -- ======================================================== PERSONAL
    CALL "ERP_PERSONAL_CREAR"(v_dni,'25847561','Paredes','Huanca','Roberto José',v_ing,NULL,v_emp,v_ves,'Roberto.Paredes@Ejemplo.pe','101','Y',0, v_per_rob, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: crear', '100', v_cod::TEXT, v_msg);
    CALL "ERP_PERSONAL_CREAR"(v_dni,'45120933','Núñez','Paredes','Gabriela',v_ing,NULL,v_emp,v_ves,NULL,'214','Y',0, v_per_gab, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: crear segundo', '100', v_cod::TEXT, v_msg);
    CALL "ERP_PERSONAL_CREAR"(v_dni,'4512093','A','B','C',v_ing,NULL,v_emp,v_ves,NULL,NULL,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: DNI de 7 dígitos', '400', v_cod::TEXT, v_msg);
    CALL "ERP_PERSONAL_CREAR"(v_dni,'4512093A','A','B','C',v_ing,NULL,v_emp,v_ves,NULL,NULL,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: DNI con letras', '400', v_cod::TEXT, v_msg);
    CALL "ERP_PERSONAL_CREAR"(v_dni,'45120933','Otra','Persona','X',v_ing,NULL,v_emp,v_ves,NULL,NULL,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: documento duplicado', '101', v_cod::TEXT, v_msg);
    CALL "ERP_PERSONAL_CREAR"(v_dni,'11112222','A','B','C',999999,NULL,v_emp,v_ves,NULL,NULL,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: área inexistente', '400', v_cod::TEXT, v_msg);
    SELECT "Correo" INTO v_txt FROM "Personal" WHERE "ID_Personal" = v_per_rob;
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: correo guardado en minúsculas', 'roberto.paredes@ejemplo.pe', v_txt, '');
    SELECT COUNT(*) INTO v_n FROM "ERP_PERSONAL_DETALLE_POR_DOCUMENTO"(v_dni,'45120933');
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: detalle por documento', '1', v_n::TEXT, '');
    SELECT COUNT(*) INTO v_n FROM "ERP_PERSONAL_LISTAR"('núñez');
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: LISTAR por nombre', '1', v_n::TEXT, '');
    SELECT COUNT(*) INTO v_n FROM "ERP_PERSONAL_LISTAR"('45120933');
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: LISTAR no busca por documento', '0', v_n::TEXT, 'regla §3.1: identidad por DETALLE_POR_DOCUMENTO');
    SELECT COUNT(*) INTO v_n FROM "ERP_PERSONAL_BUSCAR"('n');
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: BUSCAR con 1 letra no devuelve nada', '0', v_n::TEXT, '');
    SELECT COUNT(*) INTO v_n FROM "ERP_PERSONAL_BUSCAR"('inge');
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: BUSCAR por área', '2', v_n::TEXT, '');
    CALL "ERP_PERSONAL_ACTUALIZAR"(v_per_gab,v_dni,'45120933','Núñez','Paredes','Gabriela',v_ing,NULL,v_emp,v_ves,'gabriela@ejemplo.pe','215','Y',0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: actualizar', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_SEDE_ELIMINAR"(v_ves, 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Sede: no eliminar VES (en uso)', '101', v_cod::TEXT, v_msg);

    -- ======================================================== USUARIOS
    CALL "ERP_USUARIO_CREAR"('Roberto.Paredes@Ejemplo.pe',v_dni,'25847561','Paredes','Huanca','Roberto José',v_per_rob,NULL,'Y',0, v_u_a, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Usuario A: crear vinculado a Personal', '100', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_CREAR"('sin-arroba.pe',v_dni,'12345678','X',NULL,'Y',NULL,NULL,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Usuario: correo inválido', '400', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_CREAR"('otro@ejemplo.pe',v_dni,'87654321','X',NULL,'Y',v_per_rob,NULL,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Usuario: trabajador que ya tiene cuenta', '101', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_CREAR"('ROBERTO.PAREDES@ejemplo.pe',v_dni,'87654321','X',NULL,'Y',NULL,NULL,'Y',0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Usuario: correo repetido (otras mayúsculas)', '101', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_CREAR"('gabriela@ejemplo.pe',v_dni,'45120933','Núñez','Paredes','Gabriela',v_per_gab,NULL,'Y',0, v_u_b, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Usuario B: crear', '100', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_CREAR"('maria.quispe@ejemplo.pe',v_dni,'41239987','Quispe','Torres','María',NULL,'Seguridad Ejemplo S.A.C.','Y',0, v_u_c, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Usuario C: vigilante contratista sin Personal', '100', v_cod::TEXT, v_msg);
    SELECT "Tiene_Password" INTO v_txt FROM "ERP_USUARIO_DETALLE"(v_u_a);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Usuario: nace sin contraseña', 'N', v_txt, 'se define con el token');
    SELECT COUNT(*) INTO v_n FROM information_schema.routines r
      JOIN information_schema.parameters p ON p.specific_name = r.specific_name
     WHERE r.routine_schema = 'CAF_GOVERNANCE' AND r.routine_name IN ('ERP_USUARIO_LISTAR','ERP_USUARIO_DETALLE')
       AND p.parameter_name ILIKE '%Password_Hash%';
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Usuario: LISTAR/DETALLE no exponen el hash', '0', v_n::TEXT, '');

    -- ======================================================== LICENCIAS
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_a, v_lic_adm, v_ves, 0, v_ul_a, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Licencia: A administrador en VES', '100', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_a, v_lic_adm, v_ves, 0, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Licencia: asignar dos veces', '101', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_c, v_lic_vig, v_ves, v_u_a, v_id, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Licencia: C vigilancia en VES', '100', v_cod::TEXT, v_msg);
    SELECT "Tiene" INTO v_txt FROM "ERP_USUARIO_LICENCIA_VERIFICAR"(v_u_a, 'LIC_CAF_ADMIN', v_ves);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Verificar: A es admin en VES', 'Y', v_txt, '');
    SELECT "Tiene" INTO v_txt FROM "ERP_USUARIO_LICENCIA_VERIFICAR"(v_u_a, 'LIC_CAF_VIGILANCIA', v_ves);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Verificar: A no es vigilancia', 'N', v_txt, '');
    CALL "ERP_USUARIO_LICENCIA_QUITAR"(v_ul_a, 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Licencia: no quitar el último admin', '101', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_b, v_lic_adm, v_ves, v_u_a, v_ul_b, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_QUITAR"(v_ul_a, v_u_b, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Licencia: quitar admin a A si B también lo es', '100', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_a, v_lic_adm, v_ves, v_u_b, v_ul_a2, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Licencia: reasignar reactiva la misma fila', v_ul_a::TEXT, v_ul_a2::TEXT, v_msg);

    -- ======================================================== REGLAS DE CUENTA
    CALL "ERP_USUARIO_ACTUALIZAR"(v_u_a,'roberto.paredes@ejemplo.pe',v_dni,'25847561','Paredes','Huanca','Roberto José',v_per_rob,NULL,'N',v_u_a, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Cuenta: no desactivarse a sí mismo', '101', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_ELIMINAR"(v_u_a, v_u_a, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Cuenta: no eliminarse a sí mismo', '101', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_ELIMINAR"(v_u_b, v_u_a, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Cuenta: A elimina a B (A sigue admin)', '100', v_cod::TEXT, v_msg);
    SELECT COUNT(*) INTO v_n FROM "Usuario_Licencia" WHERE "ID_Usuario" = v_u_b AND "Eliminado" = 'N';
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Cuenta: eliminar retira sus licencias', '0', v_n::TEXT, '');
    CALL "ERP_USUARIO_ELIMINAR"(v_u_a, v_u_c, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Cuenta: no eliminar al último admin', '101', v_cod::TEXT, v_msg);
    CALL "ERP_PERSONAL_ELIMINAR"(v_per_rob, 0, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Personal: no eliminar si tiene cuenta', '101', v_cod::TEXT, v_msg);

    -- ======================================================== LOGIN Y CONTRASEÑA
    SELECT COUNT(*) INTO v_n FROM "ERP_USUARIO_AUTENTICACION_POR_CORREO"('  MARIA.QUISPE@EJEMPLO.PE ');
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Login: buscar por correo (mayúsculas y espacios)', '1', v_n::TEXT, '');
    SELECT COUNT(*) INTO v_n FROM "ERP_USUARIO_AUTENTICACION_POR_DOCUMENTO"(v_dni, '41239987');
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Login: buscar por DNI', '1', v_n::TEXT, '');
    CALL "ERP_USUARIO_LOGIN_REGISTRAR"(v_u_c,'N',3,15, v_i, v_b, v_cod, v_msg);
    CALL "ERP_USUARIO_LOGIN_REGISTRAR"(v_u_c,'N',3,15, v_i, v_b, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Login: 2 intentos fallidos', '2', v_i::TEXT, v_msg);
    CALL "ERP_USUARIO_LOGIN_REGISTRAR"(v_u_c,'N',3,15, v_i, v_b, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Login: 3er fallo bloquea', 'bloqueado', CASE WHEN v_b IS NOT NULL THEN 'bloqueado' ELSE 'sin bloqueo' END, v_msg);
    SELECT "Bloqueado" INTO v_txt FROM "ERP_USUARIO_DETALLE"(v_u_c);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Login: DETALLE muestra bloqueado', 'Y', v_txt, '');
    CALL "ERP_USUARIO_LOGIN_REGISTRAR"(v_u_c,'Y',3,15, v_i, v_b, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Login: acceso exitoso limpia el bloqueo', '0', v_i::TEXT || CASE WHEN v_b IS NULL THEN '' ELSE ' (sigue bloqueado)' END, v_msg);
    CALL "ERP_USUARIO_TOKEN_REGISTRAR"(v_u_c, REPEAT('a',64), 60, v_u_a, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Token: registrar', '100', v_cod::TEXT, v_msg);
    SELECT COUNT(*) INTO v_n FROM "ERP_USUARIO_AUTENTICACION_POR_TOKEN"(REPEAT('a',64));
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Token: vigente', '1', v_n::TEXT, '');
    CALL "ERP_USUARIO_PASSWORD_ACTUALIZAR"(v_u_c, 'corta', v_u_c, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Contraseña: hash demasiado corto', '400', v_cod::TEXT, v_msg);
    CALL "ERP_USUARIO_PASSWORD_ACTUALIZAR"(v_u_c, 'AQAAAAIAAYagAAAAEJ' || REPEAT('x',40), v_u_c, v_cod, v_msg);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Contraseña: definir', '100', v_cod::TEXT, v_msg);
    SELECT COUNT(*) INTO v_n FROM "ERP_USUARIO_AUTENTICACION_POR_TOKEN"(REPEAT('a',64));
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Token: queda consumido', '0', v_n::TEXT, '');
    SELECT "Tiene_Password" || "Password_Requiere_Cambio" INTO v_txt FROM "ERP_USUARIO_DETALLE"(v_u_c);
    INSERT INTO pruebas (prueba,esperado,obtenido,detalle) VALUES ('Contraseña: tiene y ya no requiere cambio', 'YN', v_txt, '');
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Mensaje del SP"
  FROM pruebas ORDER BY n;

SELECT COUNT(*) AS "Pruebas", SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) AS "OK",
       SUM(CASE WHEN esperado = obtenido THEN 0 ELSE 1 END) AS "Fallas"
  FROM pruebas;

ROLLBACK;
