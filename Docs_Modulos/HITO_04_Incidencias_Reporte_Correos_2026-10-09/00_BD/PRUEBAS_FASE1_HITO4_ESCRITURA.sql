-- =============================================================================
-- Archivo : PRUEBAS_FASE1_HITO4_ESCRITURA.sql
-- Proyecto: Control de Accesos · V1.0 2026-10-18
-- Propósito: pruebas automáticas de los procedimientos de ESCRITURA del Hito 4:
--   registrar y decidir incidencias, y la bandeja de correos (cola, envío, errores y reencolado).
--   Termina en ROLLBACK: la base queda exactamente como estaba.
-- Requiere: scripts 01 a 10, los SP de los Hitos 0 a 3 y los 3 archivos del Hito 4
--   (SP_CAF_INCIDENCIA_ALL, SP_CAF_CORREO_ALL, SP_CAF_REPORTE_ALL).
-- Ejecutar con psql, o en pgAdmin el archivo completo de una vez.
-- NOTA: usa funciones temporales de PostgreSQL solo para escribir las pruebas
--   con menos repetición. No se despliegan ni se traducen a HANA.
-- =============================================================================

BEGIN;
SET search_path TO "TRIANONSATELITAL_CAF_PRODD", "CAF_GOVERNANCE";

CREATE TEMP TABLE pruebas (n SERIAL, prueba TEXT, esperado TEXT, obtenido TEXT, detalle TEXT) ON COMMIT DROP;
CREATE FUNCTION pg_temp.chk(p TEXT, e TEXT, o TEXT, d TEXT) RETURNS void LANGUAGE sql
AS $f$ INSERT INTO pruebas (prueba, esperado, obtenido, detalle) VALUES (p, e, o, COALESCE(d, '')) $f$;
CREATE FUNCTION pg_temp.q(s TEXT) RETURNS TEXT LANGUAGE plpgsql
AS $f$ DECLARE r TEXT; BEGIN EXECUTE s INTO r; RETURN COALESCE(r, '(nulo)'); END $f$;
CREATE FUNCTION pg_temp.sp(sol BIGINT, ext BIGINT) RETURNS BIGINT LANGUAGE sql
AS $f$ SELECT "ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = sol AND "ID_Persona_Externa" = ext $f$;
-- «id:Y,id:N,...» con todos los ítems de la etapa; los códigos de HV_Fallan salen en N
CREATE FUNCTION pg_temp.items(p BIGINT, etapa TEXT, eq TEXT, he TEXT, fallan TEXT) RETURNS TEXT LANGUAGE sql
AS $f$ SELECT STRING_AGG(A."ID_Catalogo_Item_Checklist" || ':' || CASE WHEN A."Codigo" = ANY(STRING_TO_ARRAY(fallan, ',')) THEN 'N' ELSE 'Y' END, ',' ORDER BY A."Orden")
         FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(p, etapa, eq, he) A $f$;
CREATE FUNCTION pg_temp.ti(c TEXT) RETURNS BIGINT LANGUAGE sql
AS $f$ SELECT "ID_Catalogo_Tipo_Incidencia" FROM "Catalogo_Tipo_Incidencia" WHERE "Codigo" = c $f$;
CREATE FUNCTION pg_temp.cid(a TEXT) RETURNS BIGINT LANGUAGE sql
AS $f$ SELECT "ID_Correo_Pendiente" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = a $f$;
CREATE FUNCTION pg_temp.ev(ent TEXT, id BIGINT, acc TEXT) RETURNS TEXT LANGUAGE sql
AS $f$ SELECT COUNT(*)::TEXT FROM "CAF_Evento" WHERE "Entidad" = ent AND "ID_Entidad" = id AND "Accion" = acc $f$;

DO $$
DECLARE
    v_cod INT; v_msg VARCHAR(250); v_cant BIGINT; v_cs VARCHAR(20); v_reg BIGINT; v_des BIGINT; v_res VARCHAR(30); v_resp BIGINT;
    v_ves BIGINT; v_dni BIGINT; v_area BIGINT; v_emp BIGINT; v_per BIGINT;
    v_lic_sol BIGINT; v_lic_coo BIGINT; v_lic_vig BIGINT; v_lic_min BIGINT;
    v_u_sol BIGINT; v_u_coo BIGINT; v_u_vig BIGINT; v_u_min BIGINT; v_u_nada BIGINT; v_ul BIGINT;
    v_e BIGINT[]; v_z_adm BIGINT; v_z_pt BIGINT; v_mot BIGINT; v_ext BIGINT; v_paso_ext BIGINT;
    v_s1 BIGINT; v_s2 BIGINT; v_s3 BIGINT; v_s5 BIGINT;
    v_p1 BIGINT; v_p2 BIGINT; v_p3 BIGINT; v_p4 BIGINT; v_p5 BIGINT; v_p6 BIGINT; v_p11 BIGINT; v_p12 BIGINT;
    v_p7 BIGINT; v_p8 BIGINT; v_p9 BIGINT; v_p10 BIGINT;
    v_t_lib BIGINT; v_t_reg BIGINT; v_t_rest BIGINT; v_t_den BIGINT; v_t_ret BIGINT; v_t_otro BIGINT;
    v_fut TIMESTAMP; v_hoy TIMESTAMP; v_pas TIMESTAMP; v_hecho TIMESTAMP; v_cs1 VARCHAR(20);
    v_reg2 BIGINT; v_i1 BIGINT; v_i2 BIGINT; v_i3 BIGINT; v_i4 BIGINT; v_u_adm BIGINT; v_c1 BIGINT; v_c2 BIGINT; v_c3 BIGINT; v_est VARCHAR(20); v_des2 BIGINT; v_n INT; v_txt TEXT;
BEGIN
    -- ===================================================== PREPARACIÓN
    SELECT "ID_Catalogo_Sede" INTO v_ves FROM "Catalogo_Sede" WHERE "Codigo" = 'VES';
    SELECT "ID_Catalogo_Tipo_Documento" INTO v_dni FROM "Catalogo_Tipo_Documento" WHERE "Codigo" = 'DNI';
    SELECT MIN("ID_Catalogo_Area") INTO v_area FROM "Catalogo_Area";
    SELECT MIN("ID_Catalogo_Empresa_Grupo") INTO v_emp FROM "Catalogo_Empresa_Grupo";
    SELECT "ID_Catalogo_Licencia" INTO v_lic_sol FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_SOLICITANTE';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_coo FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_COORDINADOR';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_vig FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_VIGILANCIA';
    SELECT "ID_Catalogo_Zona_Acceso" INTO v_z_adm FROM "Catalogo_Zona_Acceso" WHERE "Codigo" = 'OFICINAS_ADM' AND "ID_Catalogo_Sede" = v_ves;
    SELECT "ID_Catalogo_Zona_Acceso" INTO v_z_pt  FROM "Catalogo_Zona_Acceso" WHERE "Codigo" = 'PRODUCTO_TERMINADO' AND "ID_Catalogo_Sede" = v_ves;
    SELECT "ID_Catalogo_Motivo_Visita" INTO v_mot FROM "Catalogo_Motivo_Visita" WHERE "Codigo" = 'REUNION_COORDINACION';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_ext FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'VISITA_EXTERNA';
    SELECT "ID_Tipo_Acceso_Paso_Aprobacion" INTO v_paso_ext FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "ID_Catalogo_Tipo_Acceso" = v_ext LIMIT 1;
    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_lib  FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'LIBERACION';
    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_reg  FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'REGULARIZACION';
    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_rest FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'RESTRICCION_ZONA_ADM';
    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_den  FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'DENEGATORIA';
    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_ret  FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'RETENCION_ELEMENTO';
    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_otro FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'OTRO';

    v_fut := CURRENT_TIMESTAMP + INTERVAL '2 days';
    v_hoy := CAST(CURRENT_DATE AS TIMESTAMP) + INTERVAL '23 hours';

    INSERT INTO "Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","UsuarioID_Create")
    VALUES (v_dni,'10101010','Resp','Atención',v_area,v_emp,v_ves,'resp@ejemplo.pe',0) RETURNING "ID_Personal" INTO v_per;

    -- Rol mínimo: solo registra ingresos (sin permiso de desviaciones)
    INSERT INTO "Catalogo_Licencia" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create") VALUES ('LIC_CAF_SOLO_PORTERIA','Solo portería','ACCESOS',9,0) RETURNING "ID_Catalogo_Licencia" INTO v_lic_min;
    CALL "ERP_LICENCIA_PERMISO_ASIGNAR"(v_lic_min, 'PER_CAF_PORTERIA_REGISTRAR', 0, v_cod, v_msg);

    CALL "ERP_USUARIO_CREAR"('carlos@ejemplo.pe',  v_dni,'20000001','Solicitante','Uno','Carlos',NULL,'Ejemplo','Y',0, v_u_sol,  v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('roberto@ejemplo.pe', v_dni,'20000003','Coordinador','Uno','Roberto',NULL,'Ejemplo','Y',0, v_u_coo,  v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('maria@ejemplo.pe',   v_dni,'20000004','Vigilante','Uno','María',   NULL,'Ejemplo','Y',0, v_u_vig,  v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('mario@ejemplo.pe',   v_dni,'20000007','Minimo','Uno','Mario',      NULL,'Ejemplo','Y',0, v_u_min,  v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('nadie@ejemplo.pe',   v_dni,'20000006','Sin','Rol','Nadie',         NULL,'Ejemplo','Y',0, v_u_nada, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_sol,  v_lic_sol, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_coo,  v_lic_coo, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_vig,  v_lic_vig, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_min,  v_lic_min, v_ves, 0, v_ul, v_cod, v_msg);

    v_e := ARRAY[]::BIGINT[];
    FOR i IN 1..12 LOOP
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni, '7100' || LPAD(i::TEXT, 4, '0'), 'Apellido' || i, 'Materno' || i, 'Nombre' || i, 0, v_resp, v_cod, v_msg);
        v_e := v_e || v_resp;
    END LOOP;

    -- S1: HOY, personas 1 a 6, todas aprobadas
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_hoy, 'Energía Verde S.A.C.', v_mot, NULL, NULL,
                                   v_z_adm || ',' || v_z_pt, v_e[1] || ',' || v_e[2] || ',' || v_e[3] || ',' || v_e[4] || ',' || v_e[5] || ',' || v_e[6],
                                   NULL, NULL, v_u_sol, v_s1, v_cs1, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S1 creada', '100', v_cod::TEXT, v_msg);
    v_p1 := pg_temp.sp(v_s1, v_e[1]); v_p2 := pg_temp.sp(v_s1, v_e[2]); v_p3 := pg_temp.sp(v_s1, v_e[3]);
    v_p4 := pg_temp.sp(v_s1, v_e[4]); v_p5 := pg_temp.sp(v_s1, v_e[5]); v_p6 := pg_temp.sp(v_s1, v_e[6]);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, v_p1||','||v_p2||','||v_p3||','||v_p4||','||v_p5||','||v_p6, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S1 aprobada', '100', v_cod::TEXT, v_msg);
    -- S2: HOY, personas 11 y 12 aprobadas (la 11 no se usa: queda ESPERADA todo el tiempo)
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_hoy, 'Otra Visita S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e[11] || ',' || v_e[12], NULL, NULL, v_u_sol, v_s2, v_cs, v_cod, v_msg);
    v_p11 := pg_temp.sp(v_s2, v_e[11]); v_p12 := pg_temp.sp(v_s2, v_e[12]);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_ext, 'APROBADA', NULL, v_p11 || ',' || v_p12, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S2 con dos personas aprobadas', '100', v_cod::TEXT, v_msg);
    -- S5: visita PASADA (hace 3 días), personas 7 y 8 aprobadas, 9 pendiente
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Pasada S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e[7] || ',' || v_e[8] || ',' || v_e[9], NULL, NULL, v_u_sol, v_s5, v_cs, v_cod, v_msg);
    v_p7 := pg_temp.sp(v_s5, v_e[7]); v_p8 := pg_temp.sp(v_s5, v_e[8]); v_p9 := pg_temp.sp(v_s5, v_e[9]);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s5, v_paso_ext, 'APROBADA', NULL, v_p7||','||v_p8, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S5 aprobada', '100', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = CURRENT_TIMESTAMP - INTERVAL '3 days' WHERE "ID_Solicitud" = v_s5;
    v_pas := CURRENT_TIMESTAMP - INTERVAL '3 days';
    -- S3: aprobada y luego cancelada, también de fecha pasada (persona 10)
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Cancelada S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e[10]::TEXT, NULL, NULL, v_u_sol, v_s3, v_cs, v_cod, v_msg);
    v_p10 := pg_temp.sp(v_s3, v_e[10]);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s3, v_paso_ext, 'APROBADA', NULL, v_p10::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_s3, 'Reprogramada', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S3 cancelada', '100', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = CURRENT_TIMESTAMP - INTERVAL '3 days' WHERE "ID_Solicitud" = v_s3;

    -- ===================================================== A. INCIDENCIA_REGISTRAR: validaciones
    v_hecho := CAST(CURRENT_DATE AS TIMESTAMP);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', NULL, v_u_nada, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: sin permiso', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', NULL, v_u_sol, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: el solicitante no registra incidencias', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', NULL, v_u_min, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: el rol solo-portería no registra incidencias', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', NULL, NULL, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: usuario nulo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', NULL, -1, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: usuario negativo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(NULL, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: sede nula', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, NULL, NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: sin tipo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, 999999, NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: tipo inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, NULL, NULL, 'Almacén', 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: sin fecha del hecho', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, LOCALTIMESTAMP + INTERVAL '1 hour', NULL, 'Almacén', 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: hecho en el futuro', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', NULL, NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: sin descripción', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', '   ', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: descripción en blanco', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', REPEAT('x', 2001), NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: descripción demasiado larga', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, REPEAT('x', 201), 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: lugar demasiado largo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, NULL, 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: sin zona ni lugar', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, '   ', 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: lugar en blanco cuenta como vacío', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, 999999, NULL, 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: zona inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('OTRO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: «Otro» sin detalle', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('OTRO'), REPEAT('x', 501), v_hecho, NULL, 'Almacén', 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: detalle del tipo demasiado largo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', 'a,b', v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: lista de personas mal escrita', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', v_p1::TEXT || ',' || v_p1::TEXT, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: persona repetida', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', v_p1::TEXT || ',999999', v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: persona inexistente', '404', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Registrar: nada de lo anterior dejó incidencias', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Incidencia"'), '');
    PERFORM pg_temp.chk('Registrar: ni personas', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Incidencia_Persona"'), '');
    -- ===================================================== B. INCIDENCIA_REGISTRAR: caminos felices
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, v_z_pt, NULL, '  Faltan dos cajas.  ', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: Vigilancia, con zona y sin personas', '100', v_cod::TEXT, v_msg);
    v_i1 := v_reg2;
    PERFORM pg_temp.chk('Registrar: devuelve un identificador', 'si', CASE WHEN v_i1 > 0 THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Registrar: el código es INC- y 5 dígitos', 'si', CASE WHEN v_cs = 'INC-' || LPAD(v_i1::TEXT, 5, '0') THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Registrar: nace REGISTRADA', 'REGISTRADA', pg_temp.q('SELECT "Estado" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Registrar: Vigilancia deja origen VIGILANCIA', 'VIGILANCIA', pg_temp.q('SELECT "Origen" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Registrar: guarda quién la registró', 'si', CASE WHEN pg_temp.q('SELECT "ID_Usuario_Registro" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')) = v_u_vig::TEXT THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Registrar: recorta espacios de la descripción', 'Faltan dos cajas.', pg_temp.q('SELECT "Descripcion" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Registrar: sin decisión todavía', '(nulo)', pg_temp.q('SELECT "ID_Usuario_Decision" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Registrar: sin personas', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Incidencia_Persona" WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Registrar: deja el evento REGISTRAR', '1', pg_temp.ev('INCIDENCIA', v_i1, 'REGISTRAR'), '');
    PERFORM pg_temp.chk('Registrar: evento sin solicitud si no hay personas', '(nulo)', pg_temp.q('SELECT "ID_Solicitud" FROM "CAF_Evento" WHERE "Entidad" = ''INCIDENCIA'' AND "ID_Entidad" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), 'No debería guardarse', v_hecho, NULL, 'Almacén', 'Descripción de prueba.', v_p2::TEXT || ',' || v_p3::TEXT, v_u_coo, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: Coordinador, con lugar y dos personas de la misma visita', '100', v_cod::TEXT, v_msg);
    v_i2 := v_reg2;
    PERFORM pg_temp.chk('Registrar: el Coordinador deja origen COORDINADOR', 'COORDINADOR', pg_temp.q('SELECT "Origen" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i2::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Registrar: guarda las dos personas', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Incidencia_Persona" WHERE "ID_Incidencia" = ' || COALESCE(v_i2::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Registrar: el detalle se descarta si el tipo no es «Otro»', '(nulo)', pg_temp.q('SELECT "Tipo_Detalle" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i2::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Registrar: el evento apunta a la solicitud común', 'si', CASE WHEN pg_temp.q('SELECT "ID_Solicitud" FROM "CAF_Evento" WHERE "Entidad" = ''INCIDENCIA'' AND "ID_Entidad" = ' || COALESCE(v_i2::TEXT, 'NULL')) = v_s1::TEXT THEN 'si' ELSE 'no' END, '');
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('OTRO'), 'Falla de cerca', v_hecho, v_z_adm, NULL, 'Descripción de prueba.', v_p1::TEXT || ',' || v_p12::TEXT, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: «Otro» con detalle y personas de dos visitas', '100', v_cod::TEXT, v_msg);
    v_i3 := v_reg2;
    PERFORM pg_temp.chk('Registrar: guarda el detalle de «Otro»', 'Falla de cerca', pg_temp.q('SELECT "Tipo_Detalle" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i3::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Registrar: evento sin solicitud si las personas son de varias visitas', '(nulo)', pg_temp.q('SELECT "ID_Solicitud" FROM "CAF_Evento" WHERE "Entidad" = ''INCIDENCIA'' AND "ID_Entidad" = ' || COALESCE(v_i3::TEXT, 'NULL')), '');
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('ROBO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', v_p10::TEXT || ',' || v_p9::TEXT || ', ' || v_p7::TEXT, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: acepta personas de visita cancelada o sin aprobar, y espacios en la lista', '100', v_cod::TEXT, v_msg);
    v_i4 := v_reg2;
    PERFORM pg_temp.chk('Registrar: tres personas guardadas', '3', pg_temp.q('SELECT COUNT(*) FROM "CAF_Incidencia_Persona" WHERE "ID_Incidencia" = ' || COALESCE(v_i4::TEXT, 'NULL')), '');
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, LOCALTIMESTAMP - INTERVAL '5 days', NULL, 'Almacén', 'Descripción de prueba.', NULL, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Registrar: acepta un hecho de hace días', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Registrar: los códigos no se repiten', '5', pg_temp.q('SELECT COUNT(DISTINCT "Codigo") FROM "CAF_Incidencia"'), '');
    -- ===================================================== C. INCIDENCIA_DECIDIR
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'CONFIRMAR', 'Sustento de prueba.', v_u_vig, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: Vigilancia no decide', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'CONFIRMAR', 'Sustento de prueba.', v_u_nada, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: sin permiso', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'CONFIRMAR', 'Sustento de prueba.', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: el solicitante no decide', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'CONFIRMAR', 'Sustento de prueba.', NULL, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: usuario nulo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'CONFIRMAR', 'Sustento de prueba.', -1, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: usuario negativo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'APROBAR', 'Sustento de prueba.', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: decisión inválida', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, NULL, 'Sustento de prueba.', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: sin decisión', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'CONFIRMAR', NULL, v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: sin sustento', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'CONFIRMAR', '  ', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: sustento en blanco', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'CONFIRMAR', REPEAT('x', 2001), v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: sustento demasiado largo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(999999, 'CONFIRMAR', 'Sustento de prueba.', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: incidencia inexistente', '404', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Decidir: nada de lo anterior la decidió', 'REGISTRADA', pg_temp.q('SELECT "Estado" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'confirmar', '  Se verificó con el inventario.  ', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: confirmar (acepta minúsculas)', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Decidir: queda CONFIRMADA', 'CONFIRMADA', pg_temp.q('SELECT "Estado" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Decidir: guarda al decisor', 'si', CASE WHEN pg_temp.q('SELECT "ID_Usuario_Decision" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')) = v_u_coo::TEXT THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Decidir: guarda la fecha', 'si', CASE WHEN pg_temp.q('SELECT "Fecha_Decision" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')) <> '(nulo)' THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Decidir: guarda el sustento recortado', 'Se verificó con el inventario.', pg_temp.q('SELECT "Sustento_Decision" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Decidir: deja el evento CONFIRMAR', '1', pg_temp.ev('INCIDENCIA', v_i1, 'CONFIRMAR'), '');
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'CONFIRMAR', 'Sustento de prueba.', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: no se decide dos veces', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'DESESTIMAR', 'Sustento de prueba.', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: ni se cambia después de confirmar', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'DESESTIMAR', 'Sustento de prueba.', v_u_vig, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: sin permiso gana sobre «ya decidida»', '101', v_cod::TEXT, v_msg);
    -- D-165: lo que registra el Coordinador nace CONFIRMADA, con su propia decisión
    PERFORM pg_temp.chk('Coordinador: su incidencia nace CONFIRMADA', 'CONFIRMADA', pg_temp.q('SELECT "Estado" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i2::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Coordinador: queda como decisor', 'si', CASE WHEN pg_temp.q('SELECT "ID_Usuario_Decision" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i2::TEXT, 'NULL')) = v_u_coo::TEXT THEN 'si' ELSE 'no' END, '');
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i2, 'DESESTIMAR', 'No hubo tal hurto.', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Coordinador: su incidencia confirmada no se vuelve a decidir', '409', v_cod::TEXT, v_msg);
    -- para seguir probando «desestimar» se devuelve a REGISTRADA (como las anteriores a D-165)
    UPDATE "CAF_Incidencia" SET "Estado" = 'REGISTRADA', "ID_Usuario_Decision" = NULL, "Fecha_Decision" = NULL, "Sustento_Decision" = NULL WHERE "ID_Incidencia" = v_i2;
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i2, 'DESESTIMAR', 'No hubo tal hurto.', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: desestimar', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Decidir: queda DESESTIMADA', 'DESESTIMADA', pg_temp.q('SELECT "Estado" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = ' || COALESCE(v_i2::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Decidir: deja el evento DESESTIMAR', '1', pg_temp.ev('INCIDENCIA', v_i2, 'DESESTIMAR'), '');
    PERFORM pg_temp.chk('Decidir: el evento de decisión apunta a la solicitud común', 'si', CASE WHEN pg_temp.q('SELECT "ID_Solicitud" FROM "CAF_Evento" WHERE "Entidad" = ''INCIDENCIA'' AND "ID_Entidad" = ' || COALESCE(v_i2::TEXT, 'NULL') || ' AND "Accion" = ''DESESTIMAR''') = v_s1::TEXT THEN 'si' ELSE 'no' END, '');
    UPDATE "CAF_Incidencia" SET "Eliminado" = 'Y' WHERE "ID_Incidencia" = v_i3;
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i3, 'CONFIRMAR', 'Sustento de prueba.', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: una incidencia eliminada no existe', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i4, 'CONFIRMAR', 'Sustento de prueba.', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: otra incidencia sigue su curso', '100', v_cod::TEXT, v_msg);
    -- ===================================================== D. CORREOS: cola, envío y errores
    UPDATE "CAF_Correo_Pendiente" SET "Estado" = 'ENVIADO';
    CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_NUEVA', v_s1, 'a@ejemplo.pe', NULL, 'Prueba A', '<p>A</p>', v_u_coo, v_cod, v_msg);
    CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_NUEVA', v_s1, 'a@ejemplo.pe', NULL, 'Prueba B', '<p>B</p>', v_u_coo, v_cod, v_msg);
    CALL "ERP_CAF_CORREO_ENCOLAR"('SOLICITUD_NUEVA', v_s1, 'a@ejemplo.pe', NULL, 'Prueba C', '<p>C</p>', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Pendientes: el sistema ve los 3 encolados', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0)'), '');
    PERFORM pg_temp.chk('Pendientes: una persona no puede leerlos (Vigilancia)', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Pendientes: ni el Coordinador', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Pendientes: usuario nulo', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(NULL)'), '');
    PERFORM pg_temp.chk('Pendientes: máximo 2', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, 2)'), '');
    PERFORM pg_temp.chk('Pendientes: máximo 0 se corrige a 1', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, 0)'), '');
    PERFORM pg_temp.chk('Pendientes: máximo enorme se corrige a 100', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, 1000)'), '');
    PERFORM pg_temp.chk('Pendientes: máximo nulo usa el valor por defecto', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, NULL)'), '');
    PERFORM pg_temp.chk('Pendientes: el más antiguo primero', 'Prueba A', pg_temp.q('SELECT "Asunto" FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0) LIMIT 1'), '');
    PERFORM pg_temp.chk('Pendientes: trae el cuerpo', '<p>A</p>', pg_temp.q('SELECT "Cuerpo" FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0) LIMIT 1'), '');
    CALL "ERP_CAF_CORREO_MARCAR_ENVIADO"(pg_temp.cid('Prueba A'), v_u_vig, v_cod, v_msg);
    PERFORM pg_temp.chk('Enviado: una persona no marca correos', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_MARCAR_ENVIADO"(pg_temp.cid('Prueba A'), NULL, v_cod, v_msg);
    PERFORM pg_temp.chk('Enviado: usuario nulo', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_MARCAR_ENVIADO"(999999, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Enviado: correo inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_MARCAR_ENVIADO"(pg_temp.cid('Prueba A'), 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Enviado: ok', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Enviado: queda ENVIADO', 'ENVIADO', pg_temp.q('SELECT "Estado" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = ''Prueba A'''), '');
    PERFORM pg_temp.chk('Enviado: cuenta el intento', '1', pg_temp.q('SELECT "Intentos" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = ''Prueba A'''), '');
    PERFORM pg_temp.chk('Enviado: guarda la fecha de envío', 'si', CASE WHEN pg_temp.q('SELECT "Fecha_Envio" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = ''Prueba A''') <> '(nulo)' THEN 'si' ELSE 'no' END, '');
    CALL "ERP_CAF_CORREO_MARCAR_ENVIADO"(pg_temp.cid('Prueba A'), 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Enviado: no se marca dos veces', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Pendientes: ya quedan 2', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0)'), '');
    CALL "ERP_CAF_CORREO_MARCAR_ERROR"(pg_temp.cid('Prueba B'), 'SMTP caído', 3, v_u_vig, v_est, v_cod, v_msg);
    PERFORM pg_temp.chk('Error: una persona no marca correos', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_MARCAR_ERROR"(pg_temp.cid('Prueba B'), 'SMTP caído', 0, 0, v_est, v_cod, v_msg);
    PERFORM pg_temp.chk('Error: máximo de intentos 0', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_MARCAR_ERROR"(pg_temp.cid('Prueba B'), 'SMTP caído', 21, 0, v_est, v_cod, v_msg);
    PERFORM pg_temp.chk('Error: máximo de intentos 21', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_MARCAR_ERROR"(pg_temp.cid('Prueba B'), 'SMTP caído', NULL, 0, v_est, v_cod, v_msg);
    PERFORM pg_temp.chk('Error: máximo de intentos nulo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_MARCAR_ERROR"(999999, 'x', 3, 0, v_est, v_cod, v_msg);
    PERFORM pg_temp.chk('Error: correo inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_MARCAR_ERROR"(pg_temp.cid('Prueba B'), 'SMTP caído', 3, 0, v_est, v_cod, v_msg);
    PERFORM pg_temp.chk('Error: primer fallo', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Error: sigue PENDIENTE', 'PENDIENTE|1', v_est || '|' || pg_temp.q('SELECT "Intentos" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = ''Prueba B'''), '');
    PERFORM pg_temp.chk('Error: guarda el error', 'SMTP caído', pg_temp.q('SELECT "Ultimo_Error" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = ''Prueba B'''), '');
    PERFORM pg_temp.chk('Error: se reintentará (sigue en la lista)', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0)'), '');
    CALL "ERP_CAF_CORREO_MARCAR_ERROR"(pg_temp.cid('Prueba B'), 'SMTP caído', 3, 0, v_est, v_cod, v_msg);
    PERFORM pg_temp.chk('Error: segundo fallo, sigue PENDIENTE', 'PENDIENTE|2', v_est || '|' || pg_temp.q('SELECT "Intentos" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = ''Prueba B'''), '');
    CALL "ERP_CAF_CORREO_MARCAR_ERROR"(pg_temp.cid('Prueba B'), '   ', 3, 0, v_est, v_cod, v_msg);
    PERFORM pg_temp.chk('Error: tercer fallo agota los intentos', 'ERROR|3', v_est || '|' || pg_temp.q('SELECT "Intentos" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = ''Prueba B'''), '');
    PERFORM pg_temp.chk('Error: error vacío se guarda como «sin detalle»', 'Error sin detalle', pg_temp.q('SELECT "Ultimo_Error" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = ''Prueba B'''), '');
    CALL "ERP_CAF_CORREO_MARCAR_ERROR"(pg_temp.cid('Prueba B'), 'SMTP caído', 3, 0, v_est, v_cod, v_msg);
    PERFORM pg_temp.chk('Error: un correo en ERROR no se vuelve a marcar', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Pendientes: sale de la lista', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0)'), '');
    CALL "ERP_CAF_CORREO_MARCAR_ERROR"(pg_temp.cid('Prueba C'), NULL, 1, 0, v_est, v_cod, v_msg);
    PERFORM pg_temp.chk('Error: con máximo 1 pasa a ERROR de inmediato', 'ERROR', v_est, '');
    PERFORM pg_temp.chk('Error: error nulo se guarda como «sin detalle»', 'Error sin detalle', pg_temp.q('SELECT "Ultimo_Error" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = ''Prueba C'''), '');
    PERFORM pg_temp.chk('Pendientes: ya no queda ninguno', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0)'), '');
    -- ===================================================== E. CORREOS: administración
    SELECT "ID_Usuario" INTO v_u_adm FROM "Usuario" WHERE "Correo" = 'nadie@ejemplo.pe';
    SELECT "ID_Catalogo_Licencia" INTO v_c1 FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_ADMIN';
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_adm, v_c1, v_ves, 0, v_ul, v_cod, v_msg);
    PERFORM pg_temp.chk('Listar correos: el Administrador ve todos', (SELECT COUNT(*)::TEXT FROM "CAF_Correo_Pendiente" WHERE "Eliminado" = 'N'), pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_LISTAR"(' || COALESCE(v_u_adm::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Listar correos: filtra por ERROR', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_LISTAR"(' || COALESCE(v_u_adm::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ''ERROR'')'), '');
    PERFORM pg_temp.chk('Listar correos: filtra por PENDIENTE', (SELECT COUNT(*)::TEXT FROM "CAF_Correo_Pendiente" WHERE "Estado" = 'PENDIENTE'), pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_LISTAR"(' || COALESCE(v_u_adm::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ''pendiente'')'), '');
    PERFORM pg_temp.chk('Listar correos: estado inválido', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_LISTAR"(' || COALESCE(v_u_adm::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ''OTRO'')'), '');
    PERFORM pg_temp.chk('Listar correos: el Coordinador no administra la bandeja', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Listar correos: Vigilancia tampoco', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_LISTAR"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Listar correos: sin sede', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_LISTAR"(' || COALESCE(v_u_adm::TEXT, 'NULL') || ', NULL)'), '');
    PERFORM pg_temp.chk('Listar correos: no devuelve el cuerpo', '0', pg_temp.q('SELECT COUNT(*) FROM information_schema.parameters WHERE specific_schema = ''TRIANONSATELITAL_CAF_PRODD'' AND parameter_mode = ''OUT'' AND parameter_name = ''Cuerpo'' AND specific_name LIKE ''ERP_CAF_CORREO_LISTAR%'''), '');
    PERFORM pg_temp.chk('Listar correos: muestra el código de la solicitud', 'si', CASE WHEN pg_temp.q('SELECT "Codigo_Solicitud" FROM "ERP_CAF_CORREO_LISTAR"(' || COALESCE(v_u_adm::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ''ERROR'') LIMIT 1') <> '(nulo)' THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Listar correos: otra fecha', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_LISTAR"(' || COALESCE(v_u_adm::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, CURRENT_DATE - 9, CURRENT_DATE - 8)'), '');
    CALL "ERP_CAF_CORREO_REENCOLAR"(pg_temp.cid('Prueba B'), v_ves, v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Reencolar: el Coordinador no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_REENCOLAR"(pg_temp.cid('Prueba B'), v_ves, v_u_vig, v_cod, v_msg);
    PERFORM pg_temp.chk('Reencolar: Vigilancia no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_REENCOLAR"(pg_temp.cid('Prueba B'), NULL, v_u_adm, v_cod, v_msg);
    PERFORM pg_temp.chk('Reencolar: sin sede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_REENCOLAR"(pg_temp.cid('Prueba B'), v_ves, NULL, v_cod, v_msg);
    PERFORM pg_temp.chk('Reencolar: usuario nulo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_REENCOLAR"(999999, v_ves, v_u_adm, v_cod, v_msg);
    PERFORM pg_temp.chk('Reencolar: correo inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_REENCOLAR"(pg_temp.cid('Prueba A'), v_ves, v_u_adm, v_cod, v_msg);
    PERFORM pg_temp.chk('Reencolar: un correo ENVIADO no se reencola', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_CORREO_REENCOLAR"(pg_temp.cid('Prueba B'), v_ves, v_u_adm, v_cod, v_msg);
    PERFORM pg_temp.chk('Reencolar: correo en ERROR', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Reencolar: vuelve a PENDIENTE', 'PENDIENTE|0', pg_temp.q('SELECT "Estado" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = ''Prueba B''') || '|' || pg_temp.q('SELECT "Intentos" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = ''Prueba B'''), '');
    PERFORM pg_temp.chk('Reencolar: vuelve a la lista del sistema', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0)'), '');
    CALL "ERP_CAF_CORREO_REENCOLAR"(pg_temp.cid('Prueba B'), v_ves, v_u_adm, v_cod, v_msg);
    PERFORM pg_temp.chk('Reencolar: ya no está en ERROR', '409', v_cod::TEXT, v_msg);
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Nota"
  FROM pruebas WHERE esperado <> obtenido ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
