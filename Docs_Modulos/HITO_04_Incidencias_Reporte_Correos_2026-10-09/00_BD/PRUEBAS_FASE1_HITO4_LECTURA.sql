-- =============================================================================
-- Archivo : PRUEBAS_FASE1_HITO4_LECTURA.sql
-- Proyecto: Control de Accesos · V1.0 2026-10-18
-- Propósito: pruebas automáticas de las LECTURAS del Hito 4: incidencias (lista, detalle, personas,
--   contadores, búsqueda de personas) y reporte de accesos (movimientos, resumen diario, autorizados por zona).
--   Comprueba que el botón «Puede_Decidir» coincide con lo que de verdad hace el procedimiento.
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

    -- ===================================================== PREPARACIÓN DE MOVIMIENTOS E INCIDENCIAS
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p2, pg_temp.items(v_p2, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_lib, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p3, pg_temp.items(v_p3, 'INGRESO', 'N', 'N', 'ING_SCTR,ING_EPP'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_rest, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p4, pg_temp.items(v_p4, 'INGRESO', 'N', 'N', 'ING_IDENTIDAD'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_den, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'SALIDA', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    v_hecho := CAST(CURRENT_DATE AS TIMESTAMP);
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('HURTO'), NULL, v_hecho, v_z_pt, NULL, 'Descripción de prueba.', v_p2::TEXT || ',' || v_p3::TEXT, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    v_i1 := v_reg2;
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('OTRO'), 'Falla de cerca', v_hecho, NULL, 'Perímetro norte', 'Descripción de prueba.', NULL, v_u_coo, v_reg2, v_cs, v_cod, v_msg);
    v_i2 := v_reg2;
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('ROBO'), NULL, v_hecho, NULL, 'Almacén', 'Descripción de prueba.', v_p4::TEXT, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    v_i3 := v_reg2;
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves, pg_temp.ti('USO_NO_AUTORIZADO_AREA'), NULL, CAST(CURRENT_DATE - 2 AS TIMESTAMP) + INTERVAL '10 hours', v_z_adm, NULL, 'Descripción de prueba.', v_p12::TEXT, v_u_vig, v_reg2, v_cs, v_cod, v_msg);
    v_i4 := v_reg2;
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i2, 'CONFIRMAR', 'Sustento de prueba.', v_u_coo, v_cod, v_msg);
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i3, 'DESESTIMAR', 'Fue un error de conteo.', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: movimientos (4 ingresos y 1 salida)', '5', pg_temp.q('SELECT COUNT(*) FROM "CAF_Registro_Acceso"'), '');
    PERFORM pg_temp.chk('Preparación: 4 incidencias', '4', pg_temp.q('SELECT COUNT(*) FROM "CAF_Incidencia"'), '');
    -- ===================================================== A. INCIDENCIA_LISTAR
    PERFORM pg_temp.chk('Listar: el Coordinador ve las 4', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Listar: Vigilancia también', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Listar: por estado REGISTRADA', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ''REGISTRADA'')'), '');
    PERFORM pg_temp.chk('Listar: por estado CONFIRMADA', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ''confirmada'')'), '');
    PERFORM pg_temp.chk('Listar: por estado DESESTIMADA', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ''DESESTIMADA'')'), '');
    PERFORM pg_temp.chk('Listar: estado inválido', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ''OTRA'')'), '');
    PERFORM pg_temp.chk('Listar: sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_nada::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Listar: el solicitante no las ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_sol::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Listar: el rol solo-portería no las ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_min::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Listar: sede nula', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', NULL)'), '');
    PERFORM pg_temp.chk('Listar: hechos de hoy', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, CURRENT_DATE, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Listar: hechos de hace dos días', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, CURRENT_DATE - 3, CURRENT_DATE - 1)'), '');
    PERFORM pg_temp.chk('Listar: solo desde una fecha', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Listar: búsqueda sin tildes ni mayúsculas', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, NULL, NULL, ''PERIMETRO'')'), '');
    PERFORM pg_temp.chk('Listar: búsqueda por código', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, NULL, NULL, ''inc-'')'), '');
    PERFORM pg_temp.chk('Listar: búsqueda por tipo', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, NULL, NULL, ''hurto'')'), '');
    PERFORM pg_temp.chk('Listar: búsqueda por zona', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, NULL, NULL, ''oficinas'')'), '');
    PERFORM pg_temp.chk('Listar: búsqueda sin resultados', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, NULL, NULL, ''zzzz'')'), '');
    PERFORM pg_temp.chk('Listar: primero la registrada más antigua', 'si', CASE WHEN pg_temp.q('SELECT "ID_Incidencia" FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ') LIMIT 1') = v_i4::TEXT THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Listar: las decididas al final', 'si', CASE WHEN pg_temp.q('SELECT "Estado" FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ') OFFSET 3 LIMIT 1') <> 'REGISTRADA' THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Listar: cuenta las personas', '2', pg_temp.q('SELECT "Cantidad_Personas" FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ') WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Listar: incidencia sin personas', '0', pg_temp.q('SELECT "Cantidad_Personas" FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ') WHERE "ID_Incidencia" = ' || COALESCE(v_i2::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Listar: origen de cada una', 'VIGILANCIA|COORDINADOR', pg_temp.q('SELECT "Origen" FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ') WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')) || '|' || pg_temp.q('SELECT "Origen" FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ') WHERE "ID_Incidencia" = ' || COALESCE(v_i2::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Listar: «Otro» muestra su detalle', 'Otro: Falla de cerca', pg_temp.q('SELECT "Tipo_Descripcion" FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ') WHERE "ID_Incidencia" = ' || COALESCE(v_i2::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Listar: zona y lugar', 'Producto terminado|(nulo)', COALESCE(NULLIF(pg_temp.q('SELECT "Zona_Descripcion" FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ') WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '(nulo)'), '?') || '|' || pg_temp.q('SELECT "Lugar_Detalle" FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ') WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Listar: nombre de quien registró', 'Vigilante Uno, María', pg_temp.q('SELECT "Registrador_Nombre" FROM "ERP_CAF_INCIDENCIA_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ') WHERE "ID_Incidencia" = ' || COALESCE(v_i1::TEXT, 'NULL')), '');
    -- ===================================================== B. INCIDENCIA_DETALLE y PERSONAS_LISTAR
    PERFORM pg_temp.chk('Detalle: el Coordinador puede decidir una registrada', 'Y', pg_temp.q('SELECT "Puede_Decidir" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Detalle: Vigilancia la ve pero no decide', 'N', pg_temp.q('SELECT "Puede_Decidir" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Detalle: una decidida no se decide otra vez', 'N', pg_temp.q('SELECT "Puede_Decidir" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i2::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Detalle: trae al decisor y el sustento', 'Roberto|Fue un error de conteo.', SUBSTRING(pg_temp.q('SELECT "Decisor_Nombre" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i3::TEXT, 'NULL') || ')') FROM 'Roberto') || '|' || pg_temp.q('SELECT "Sustento_Decision" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i3::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Detalle: estado y origen', 'REGISTRADA|VIGILANCIA', pg_temp.q('SELECT "Estado" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')') || '|' || pg_temp.q('SELECT "Origen" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Detalle: sin decisión no hay decisor', '(nulo)', pg_temp.q('SELECT "Decisor_Nombre" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Detalle: tipo «Otro» con su detalle', 'Falla de cerca', pg_temp.q('SELECT "Tipo_Detalle" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i2::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Detalle: sin permiso', '(nulo)', pg_temp.q('SELECT "Codigo" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_nada::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Detalle: el solicitante no lo ve', '(nulo)', pg_temp.q('SELECT "Codigo" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_sol::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Detalle: inexistente', '(nulo)', pg_temp.q('SELECT "Codigo" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', 999999)'), '');
    PERFORM pg_temp.chk('Personas: la incidencia 1 involucra a 2', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Personas: la incidencia sin personas', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i2::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Personas: Vigilancia las ve', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Personas: sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR"(' || COALESCE(v_u_nada::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Personas: inexistente', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', 999999)'), '');
    PERFORM pg_temp.chk('Personas: estado de la persona en la visita', 'DENTRO', pg_temp.q('SELECT "Estado_Persona" FROM "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ') WHERE "ID_Solicitud_Persona" = ' || COALESCE(v_p2::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Personas: la de la incidencia 4 es de otra visita', 'si', CASE WHEN pg_temp.q('SELECT "ID_Solicitud" FROM "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i4::TEXT, 'NULL') || ')') = v_s2::TEXT THEN 'si' ELSE 'no' END, '');
    -- ===================================================== C. INCIDENCIA_CONTADORES y PERSONAS_BUSCAR
    PERFORM pg_temp.chk('Contadores: registradas / confirmadas / desestimadas', '2/1/1', pg_temp.q('SELECT "Registradas" FROM "ERP_CAF_INCIDENCIA_CONTADORES"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')') || '/' || pg_temp.q('SELECT "Confirmadas" FROM "ERP_CAF_INCIDENCIA_CONTADORES"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')') || '/' || pg_temp.q('SELECT "Desestimadas" FROM "ERP_CAF_INCIDENCIA_CONTADORES"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Contadores: sin permiso', '(nulo)', pg_temp.q('SELECT "Registradas" FROM "ERP_CAF_INCIDENCIA_CONTADORES"(' || COALESCE(v_u_nada::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Contadores: sede nula', '(nulo)', pg_temp.q('SELECT "Registradas" FROM "ERP_CAF_INCIDENCIA_CONTADORES"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', NULL)'), '');
    PERFORM pg_temp.chk('Buscar personas: por defecto, visitas de ayer y hoy', '8', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), 'S1 con 6 personas y S2 con 2');
    PERFORM pg_temp.chk('Buscar personas: el Coordinador también', '8', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Buscar personas: visitas de hace tres días (incluye cancelada y sin aprobar)', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 4, CURRENT_DATE - 2)'), '');
    PERFORM pg_temp.chk('Buscar personas: por nombre', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, NULL, ''nombre4'')'), '');
    PERFORM pg_temp.chk('Buscar personas: por empresa', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, NULL, ''otra visita'')'), '');
    PERFORM pg_temp.chk('Buscar personas: sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(' || COALESCE(v_u_nada::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Buscar personas: el solicitante no', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(' || COALESCE(v_u_sol::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Buscar personas: el rol solo-portería no', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(' || COALESCE(v_u_min::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Buscar personas: rango invertido', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE - 3)'), '');
    PERFORM pg_temp.chk('Buscar personas: sede nula', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', NULL)'), '');
    PERFORM pg_temp.chk('Buscar personas: indica el estado actual', 'DENTRO', pg_temp.q('SELECT "Estado_Persona" FROM "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ') WHERE "ID_Solicitud_Persona" = ' || COALESCE(v_p2::TEXT, 'NULL')), '');
    -- ===================================================== D. REPORTE_ACCESOS
    PERFORM pg_temp.chk('Reporte: el Coordinador ve los 5 movimientos de hoy', '5', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Reporte: Vigilancia no tiene permiso de reporte', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Reporte: sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_nada::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Reporte: el solicitante no', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_sol::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Reporte: solo ingresos', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE, ''INGRESO'')'), '');
    PERFORM pg_temp.chk('Reporte: solo salidas', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE, ''salida'')'), '');
    PERFORM pg_temp.chk('Reporte: tipo inválido', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE, ''OTRO'')'), '');
    PERFORM pg_temp.chk('Reporte: resultado NO_INGRESA', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE, NULL, ''NO_INGRESA'')'), '');
    PERFORM pg_temp.chk('Reporte: resultado INGRESA_RESTRINGIDO', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE, NULL, ''INGRESA_RESTRINGIDO'')'), '');
    PERFORM pg_temp.chk('Reporte: resultado SALE', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE, NULL, ''SALE'')'), '');
    PERFORM pg_temp.chk('Reporte: búsqueda por persona', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE, NULL, NULL, ''nombre4'')'), '');
    PERFORM pg_temp.chk('Reporte: búsqueda por empresa', '5', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE, NULL, NULL, ''energia verde'')'), '');
    PERFORM pg_temp.chk('Reporte: otro día no tiene', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 1, CURRENT_DATE - 1)'), '');
    PERFORM pg_temp.chk('Reporte: rango de 92 días permitido', '5', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 92, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Reporte: rango de 93 días rechazado', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 93, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Reporte: rango invertido', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE - 1)'), '');
    PERFORM pg_temp.chk('Reporte: sin fechas', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, NULL)'), '');
    PERFORM pg_temp.chk('Reporte: sede nula', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', NULL, CURRENT_DATE, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Reporte: ítems incumplidos de cada ingreso (0/1/2/0)', '0/1/2/0', pg_temp.q('SELECT "Items_Incumplidos" FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE) WHERE "Tipo_Movimiento" = ''INGRESO'' AND "Persona_Nombre" LIKE ''Apellido1 %''') || '/' || pg_temp.q('SELECT "Items_Incumplidos" FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE) WHERE "Persona_Nombre" LIKE ''Apellido2 %''') || '/' || pg_temp.q('SELECT "Items_Incumplidos" FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE) WHERE "Persona_Nombre" LIKE ''Apellido3 %''') || '/' || pg_temp.q('SELECT "Items_Incumplidos" FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE) WHERE "Tipo_Movimiento" = ''SALIDA'''), '');
    PERFORM pg_temp.chk('Reporte: trae el código y estado de la desviación', 'si', CASE WHEN pg_temp.q('SELECT "Codigo_Desviacion" FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE) WHERE "Persona_Nombre" LIKE ''Apellido2 %''') LIKE 'DES-%' AND pg_temp.q('SELECT "Estado_Desviacion" FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE) WHERE "Persona_Nombre" LIKE ''Apellido2 %''') = 'POR_REVISAR' THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Reporte: movimiento sin desviación', '(nulo)', pg_temp.q('SELECT "Codigo_Desviacion" FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE) WHERE "Tipo_Movimiento" = ''SALIDA'''), '');
    PERFORM pg_temp.chk('Reporte: lista las zonas de la visita', 'si', CASE WHEN pg_temp.q('SELECT "Zonas" FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE) LIMIT 1') LIKE '%, %' THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Reporte: nombre del vigilante', 'Vigilante Uno, María', pg_temp.q('SELECT "Vigilante_Nombre" FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE) LIMIT 1'), '');
    PERFORM pg_temp.chk('Reporte: en orden cronológico', 'si', CASE WHEN pg_temp.q('SELECT "Tipo_Movimiento" FROM "ERP_CAF_REPORTE_ACCESOS"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE) LIMIT 1') = 'INGRESO' THEN 'si' ELSE 'no' END, '');
    -- ===================================================== E. REPORTE_RESUMEN_DIARIO
    PERFORM pg_temp.chk('Resumen: dos días con actividad', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 5, CURRENT_DATE)'), 'hoy y la incidencia de hace dos días');
    PERFORM pg_temp.chk('Resumen: sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_nada::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 5, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Resumen: Vigilancia no tiene permiso de reporte', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 5, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Resumen: rango demasiado largo', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 93, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Resumen: rango invertido', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE, CURRENT_DATE - 1)'), '');
    PERFORM pg_temp.chk('Resumen: sede nula', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', NULL, CURRENT_DATE, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Resumen de hoy: ingresos / restringidos / denegados / salidas', '3/1/1/1', pg_temp.q('SELECT "Ingresos" FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 5, CURRENT_DATE) WHERE "Fecha" = CURRENT_DATE') || '/' || pg_temp.q('SELECT "Ingresos_Restringidos" FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 5, CURRENT_DATE) WHERE "Fecha" = CURRENT_DATE') || '/' || pg_temp.q('SELECT "Ingresos_Denegados" FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 5, CURRENT_DATE) WHERE "Fecha" = CURRENT_DATE') || '/' || pg_temp.q('SELECT "Salidas" FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 5, CURRENT_DATE) WHERE "Fecha" = CURRENT_DATE'), '');
    PERFORM pg_temp.chk('Resumen de hoy: desviaciones / incidencias (la desestimada no cuenta)', '3/2', pg_temp.q('SELECT "Desviaciones" FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 5, CURRENT_DATE) WHERE "Fecha" = CURRENT_DATE') || '/' || pg_temp.q('SELECT "Incidencias" FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 5, CURRENT_DATE) WHERE "Fecha" = CURRENT_DATE'), '');
    PERFORM pg_temp.chk('Resumen de hace dos días: solo la incidencia', '0/1', pg_temp.q('SELECT "Ingresos" FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 5, CURRENT_DATE) WHERE "Fecha" = CURRENT_DATE - 2') || '/' || pg_temp.q('SELECT "Incidencias" FROM "ERP_CAF_REPORTE_RESUMEN_DIARIO"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', CURRENT_DATE - 5, CURRENT_DATE) WHERE "Fecha" = CURRENT_DATE - 2'), '');
    -- ===================================================== F. REPORTE_AUTORIZADOS_POR_ZONA
    PERFORM pg_temp.chk('Autorizados: Producto terminado hoy (solo la visita 1)', '6', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Autorizados: oficinas hoy (visitas 1 y 2)', '8', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_adm::TEXT, 'NULL') || ', CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Autorizados: oficinas hace tres días (aprobadas de la visita pasada; la cancelada no)', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_adm::TEXT, 'NULL') || ', CURRENT_DATE - 3)'), '');
    PERFORM pg_temp.chk('Autorizados: otro día', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE + 30)'), '');
    PERFORM pg_temp.chk('Autorizados: Vigilancia no tiene permiso de reporte', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Autorizados: sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_nada::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Autorizados: zona nula', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', NULL, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Autorizados: fecha nula', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', NULL)'), '');
    PERFORM pg_temp.chk('Autorizados: sede nula', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', NULL, ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Autorizados: estado de cada persona (salió, dentro, denegada, esperada)', 'SALIO/DENTRO/DENEGADA/ESPERADA', pg_temp.q('SELECT "Estado_Persona" FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE) WHERE "ID_Solicitud_Persona" = ' || COALESCE(v_p1::TEXT, 'NULL')) || '/' || pg_temp.q('SELECT "Estado_Persona" FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE) WHERE "ID_Solicitud_Persona" = ' || COALESCE(v_p2::TEXT, 'NULL')) || '/' || pg_temp.q('SELECT "Estado_Persona" FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE) WHERE "ID_Solicitud_Persona" = ' || COALESCE(v_p4::TEXT, 'NULL')) || '/' || pg_temp.q('SELECT "Estado_Persona" FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE) WHERE "ID_Solicitud_Persona" = ' || COALESCE(v_p5::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Autorizados: indica la restricción', 'Y/N', pg_temp.q('SELECT "Acceso_Restringido" FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE) WHERE "ID_Solicitud_Persona" = ' || COALESCE(v_p3::TEXT, 'NULL')) || '/' || pg_temp.q('SELECT "Acceso_Restringido" FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE) WHERE "ID_Solicitud_Persona" = ' || COALESCE(v_p2::TEXT, 'NULL')), '');
    PERFORM pg_temp.chk('Autorizados: trae hora de ingreso de quien entró', 'si/(nulo)', CASE WHEN pg_temp.q('SELECT "Fecha_Hora_Ingreso" FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE) WHERE "ID_Solicitud_Persona" = ' || COALESCE(v_p2::TEXT, 'NULL')) <> '(nulo)' THEN 'si' ELSE 'no' END || '/' || pg_temp.q('SELECT "Fecha_Hora_Ingreso" FROM "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ', ' || COALESCE(v_z_pt::TEXT, 'NULL') || ', CURRENT_DATE) WHERE "ID_Solicitud_Persona" = ' || COALESCE(v_p5::TEXT, 'NULL')), '');
    -- ===================================================== G. Coincidencia botón <-> procedimiento (incidencias)
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'CONFIRMAR', 'Sustento de prueba.', v_u_vig, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide: botón apagado para Vigilancia = el SP rechaza (101)', 'N|101', pg_temp.q('SELECT "Puede_Decidir" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_vig::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')') || '|' || v_cod, '');
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_i1, 'CONFIRMAR', 'Sustento de prueba.', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide: botón encendido para el Coordinador = el SP acepta (100)', '100', v_cod::TEXT, '');
    PERFORM pg_temp.chk('Coincide: después de decidirla el botón se apaga', 'N', pg_temp.q('SELECT "Puede_Decidir" FROM "ERP_CAF_INCIDENCIA_DETALLE"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_i1::TEXT, 'NULL') || ')'), '');
    PERFORM pg_temp.chk('Contadores: se actualizan', '1/2/1', pg_temp.q('SELECT "Registradas" FROM "ERP_CAF_INCIDENCIA_CONTADORES"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')') || '/' || pg_temp.q('SELECT "Confirmadas" FROM "ERP_CAF_INCIDENCIA_CONTADORES"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')') || '/' || pg_temp.q('SELECT "Desestimadas" FROM "ERP_CAF_INCIDENCIA_CONTADORES"(' || COALESCE(v_u_coo::TEXT, 'NULL') || ', ' || COALESCE(v_ves::TEXT, 'NULL') || ')'), '');
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Nota"
  FROM pruebas WHERE esperado <> obtenido ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
