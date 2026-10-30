-- =============================================================================
-- Archivo : PRUEBAS_FASE1_HITO2_LECTURA.sql
-- Proyecto: Control de Accesos · V1.0 2026-10-17
-- Propósito: pruebas automáticas de los procedimientos de LECTURA del Hito 2:
--   «Mis solicitudes», bandeja de quien aprueba, contadores, detalle, personas,
--   ruta de aprobación, historial, versiones y listados de Vigilancia.
--   Comprueba también que cada botón («Puede_...») coincide con lo que de
--   verdad hace el procedimiento de escritura (la regla vive en un solo lugar).
--   Termina en ROLLBACK: la base queda exactamente como estaba.
-- Requiere: scripts 01 a 10, los SP de los Hitos 0 y 1, SP_GOVERNANCE_PERMISO_ALL,
--   SP_CAF_TIPO_ACCESO_PASO_APROBACION_ALL y los 5 archivos SP_CAF_SOLICITUD_*
--   (incluido SP_CAF_SOLICITUD_LECTURA_ALL).
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

DO $$
DECLARE
    v_cod INT; v_msg VARCHAR(250); v_cant BIGINT; v_cs VARCHAR(20); v_reab CHAR(1); v_rr CHAR(1); v_spr BIGINT;
    v_ves BIGINT; v_dni BIGINT; v_area BIGINT; v_emp BIGINT; v_per BIGINT;
    v_lic_sol BIGINT; v_lic_coo BIGINT; v_lic_vig BIGINT; v_lic_alm BIGINT;
    v_u_sol BIGINT; v_u_sol2 BIGINT; v_u_coo BIGINT; v_u_vig BIGINT; v_u_alm BIGINT; v_u_nada BIGINT; v_ul BIGINT;
    v_e1 BIGINT; v_e2 BIGINT; v_e3 BIGINT; v_e4 BIGINT; v_e5 BIGINT; v_e6 BIGINT;
    v_z_adm BIGINT; v_z_pt BIGINT; v_mot BIGINT; v_ext BIGINT; v_con BIGINT; v_paso_ext BIGINT;
    v_s1 BIGINT; v_s2 BIGINT; v_s3 BIGINT; v_s4 BIGINT; v_s5 BIGINT;
    v_p1 BIGINT; v_p2 BIGINT; v_p3 BIGINT; v_q4 BIGINT; v_q5 BIGINT; v_q6 BIGINT;
    v_paso_doc BIGINT; v_paso_serv BIGINT; v_paso_cierre BIGINT;
    v_fut TIMESTAMP; v_hoy TIMESTAMP; v_cs1 VARCHAR(20);
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
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_con FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'PROVEEDOR';
    SELECT "ID_Tipo_Acceso_Paso_Aprobacion" INTO v_paso_ext FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "ID_Catalogo_Tipo_Acceso" = v_ext LIMIT 1;

    v_fut := CURRENT_TIMESTAMP + INTERVAL '2 days';
    v_hoy := CAST(CURRENT_DATE AS TIMESTAMP) + INTERVAL '23 hours';

    INSERT INTO "Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","UsuarioID_Create")
    VALUES (v_dni,'10101010','Resp','Atención',v_area,v_emp,v_ves,'resp@ejemplo.pe',0) RETURNING "ID_Personal" INTO v_per;

    -- Rol nuevo: aprobador de almacén (solo aprueba)
    INSERT INTO "Catalogo_Licencia" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create") VALUES ('LIC_CAF_APROB_ALMACEN','Aprobador de almacén','ACCESOS',9,0) RETURNING "ID_Catalogo_Licencia" INTO v_lic_alm;
    CALL "ERP_LICENCIA_PERMISO_ASIGNAR"(v_lic_alm, 'PER_CAF_SOLICITUD_APROBAR', 0, v_cod, v_msg);

    CALL "ERP_USUARIO_CREAR"('carlos@ejemplo.pe',  v_dni,'20000001','Solicitante','Uno','Carlos',NULL,'Ejemplo','Y',0, v_u_sol,  v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('ana@ejemplo.pe',     v_dni,'20000002','Solicitante','Dos','Ana',   NULL,'Ejemplo','Y',0, v_u_sol2, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('roberto@ejemplo.pe', v_dni,'20000003','Coordinador','Uno','Roberto',NULL,'Ejemplo','Y',0, v_u_coo,  v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('maria@ejemplo.pe',   v_dni,'20000004','Vigilante','Uno','María',   NULL,'Ejemplo','Y',0, v_u_vig,  v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('jorge@ejemplo.pe',   v_dni,'20000005','Almacen','Uno','Jorge',     NULL,'Ejemplo','Y',0, v_u_alm,  v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('nadie@ejemplo.pe',   v_dni,'20000006','Sin','Rol','Nadie',         NULL,'Ejemplo','Y',0, v_u_nada, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_sol,  v_lic_sol, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_sol2, v_lic_sol, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_coo,  v_lic_coo, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_vig,  v_lic_vig, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_alm,  v_lic_alm, v_ves, 0, v_ul, v_cod, v_msg);

    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000001','Torres','Quispe','Luis',0, v_e1, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000002','Vargas','Ríos','Ana',0,    v_e2, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000003','Soto','Medina','Enrique',0,v_e3, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000004','Lima','Paz','Marta',0,     v_e4, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000005','Rojas','Cárdenas','José',0,v_e5, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000006','Arias','Mejía','Daniel',0, v_e6, v_cod, v_msg);

    -- Flujo de 3 pasos para contratista (solo con datos)
    UPDATE "Catalogo_Tipo_Acceso" SET "Disponible" = 'Y' WHERE "ID_Catalogo_Tipo_Acceso" = v_con;
    CALL "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_con, 1, 'DOCUMENTOS', 'Revisión de documentos', 'PERSONA',   'ROL', v_lic_coo, 'SIEMPRE', 'Y', 0, v_paso_doc,    v_cod, v_msg);
    CALL "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_con, 1, 'SERVICIO',   'Aprobación del servicio', 'SOLICITUD', 'ROL', v_lic_alm, 'SIEMPRE', 'Y', 0, v_paso_serv,   v_cod, v_msg);
    CALL "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_con, 2, 'CIERRE',     'Visto bueno final',       'PERSONA',   'ROL', v_lic_coo, 'SIEMPRE', 'Y', 0, v_paso_cierre, v_cod, v_msg);

    -- S1: visita externa de Carlos, 3 personas, 2 zonas, 2 copias
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, 'Traerán un proyector.',
                                   v_z_adm || ',' || v_z_pt, v_e1 || ',' || v_e2 || ',' || v_e3, 'almacen@ejemplo.pe; gerencia@ejemplo.pe', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_s1, v_cs1, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S1 creada', '100', v_cod::TEXT, v_msg);
    -- S2: contratista de Carlos, 3 personas, flujo de 3 pasos
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_con, v_per, v_fut, 'Contratista S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1 || ',' || v_e2 || ',' || v_e3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_s2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S2 creada', '100', v_cod::TEXT, v_msg);
    -- S3: visita de HOY de Ana, 3 personas
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_hoy, 'Hoy Visitas S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e4 || ',' || v_e5 || ',' || v_e6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_s3, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S3 creada', '100', v_cod::TEXT, v_msg);
    -- S4: de HOY de Carlos, cancelada
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_hoy, 'Cancelada S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e6::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_s4, v_cs, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_s4, 'Reprogramada', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S4 cancelada', '100', v_cod::TEXT, v_msg);
    -- S5: de Carlos, de una fecha ya pasada (se retrasa a mano) y «basada en» S1
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Pasada S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_s5, v_cs, v_cod, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = CURRENT_TIMESTAMP - INTERVAL '3 days', "ID_Solicitud_Origen" = v_s1 WHERE "ID_Solicitud" = v_s5;

    v_p1 := pg_temp.sp(v_s1, v_e1); v_p2 := pg_temp.sp(v_s1, v_e2); v_p3 := pg_temp.sp(v_s1, v_e3);
    v_q4 := pg_temp.sp(v_s3, v_e4); v_q5 := pg_temp.sp(v_s3, v_e5); v_q6 := pg_temp.sp(v_s3, v_e6);

    -- ===================================================== A. PIEZAS INTERNAS
    PERFORM pg_temp.chk('Normalizar: sin tildes ni mayúsculas', 'jose ano', "ERP_CAF_FN_NORMALIZAR"('JOSÉ Año'), '');
    PERFORM pg_temp.chk('Normalizar: nulo', '', "ERP_CAF_FN_NORMALIZAR"(NULL), '');
    PERFORM pg_temp.chk('Visible: el dueño ve su solicitud', 'Y', "ERP_CAF_FN_SOLICITUD_VISIBLE"(v_u_sol, v_s1), '');
    PERFORM pg_temp.chk('Visible: otro solicitante no ve la ajena', 'N', "ERP_CAF_FN_SOLICITUD_VISIBLE"(v_u_sol2, v_s1), '');
    PERFORM pg_temp.chk('Visible: el Coordinador ve todas', 'Y', "ERP_CAF_FN_SOLICITUD_VISIBLE"(v_u_coo, v_s1), '');
    PERFORM pg_temp.chk('Visible: almacén no ve una visita externa (no tiene paso)', 'N', "ERP_CAF_FN_SOLICITUD_VISIBLE"(v_u_alm, v_s1), 'su rol no decide ningún paso de ese flujo');
    PERFORM pg_temp.chk('Visible: almacén sí ve la del contratista (tiene el paso del servicio)', 'Y', "ERP_CAF_FN_SOLICITUD_VISIBLE"(v_u_alm, v_s2), '');
    PERFORM pg_temp.chk('Visible: Vigilancia no ve solicitudes', 'N', "ERP_CAF_FN_SOLICITUD_VISIBLE"(v_u_vig, v_s1), '');
    PERFORM pg_temp.chk('Visible: sin roles', 'N', "ERP_CAF_FN_SOLICITUD_VISIBLE"(v_u_nada, v_s1), '');
    PERFORM pg_temp.chk('Visible: solicitud inexistente', 'N', "ERP_CAF_FN_SOLICITUD_VISIBLE"(v_u_coo, 999999), '');
    PERFORM pg_temp.chk('Visible: usuario nulo', 'N', "ERP_CAF_FN_SOLICITUD_VISIBLE"(NULL, v_s1), '');

    -- Pasos que cada uno puede decidir ahora (S1: un paso; S2: tres pasos con orden)
    PERFORM pg_temp.chk('Decidibles S1: el Coordinador puede decidir a las 3 personas', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_coo || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Decidibles S1: almacén ninguna', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_alm || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Decidibles S1: el solicitante no aprueba', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Decidibles S2: Coordinador, solo «Documentos» (el cierre espera) para 3 personas', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_coo || ', ' || v_s2 || ') WHERE "Paso_Codigo" = ''DOCUMENTOS'''), '');
    PERFORM pg_temp.chk('Decidibles S2: el cierre todavía no', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_coo || ', ' || v_s2 || ') WHERE "Paso_Codigo" = ''CIERRE'''), 'faltan los pasos anteriores');
    PERFORM pg_temp.chk('Decidibles S2: almacén decide el servicio de las 3 personas', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_alm || ', ' || v_s2 || ') WHERE "Paso_Codigo" = ''SERVICIO'''), 'paso por solicitud');
    PERFORM pg_temp.chk('Decidibles: lo cancelado no se decide', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_coo || ', ' || v_s4 || ')'), '');
    PERFORM pg_temp.chk('Decidibles: lo de fecha pasada no se decide', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_coo || ', ' || v_s5 || ')'), '');

    -- Las decisiones (con los procedimientos de escritura)
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA',  NULL, v_p1::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S1 aprueba a la persona 1', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'OBSERVADA', 'Falta DNI legible', v_p2::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S1 observa a la persona 2', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_serv, 'APROBADA', NULL, NULL, v_u_alm, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S2 el servicio queda aprobado', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_doc, 'APROBADA', NULL, pg_temp.sp(v_s2, v_e1) || ',' || pg_temp.sp(v_s2, v_e2), v_u_coo, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_doc, 'OBSERVADA', 'SCTR vencido.', pg_temp.sp(v_s2, v_e3)::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidibles S2: tras aprobar documentos, el cierre le toca al Coordinador (2 personas)', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_coo || ', ' || v_s2 || ') WHERE "Paso_Codigo" = ''CIERRE'''), '');
    PERFORM pg_temp.chk('Decidibles S2: la observada ya no se decide', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_coo || ', ' || v_s2 || ') WHERE "ID_Solicitud_Persona" = ' || pg_temp.sp(v_s2, v_e3)), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_cierre, 'APROBADA', NULL, pg_temp.sp(v_s2, v_e1) || ',' || pg_temp.sp(v_s2, v_e2), v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S2 cierre aprobado', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Decidibles: el almacén ya no tiene nada pendiente', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_alm || ', NULL)'), '');
    -- S3: aprueba 2 y rechaza 1; después una persona ingresa
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s3, v_paso_ext, 'APROBADA',  NULL, v_q4 || ',' || v_q5, v_u_coo, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s3, v_paso_ext, 'RECHAZADA', 'No corresponde.', v_q6::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S3 decidida', '100', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'DENTRO', "Fecha_Hora_Ingreso" = CURRENT_TIMESTAMP WHERE "ID_Solicitud_Persona" = v_q4;

    -- ===================================================== B. INDICADORES (conteos, avance y botones por estado)
    PERFORM pg_temp.chk('Indicadores S1: 3 personas', '3', pg_temp.q('SELECT "Total_Personas" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S1: 1 autorizada, 1 observada, 1 pendiente', '1/1/1/0/0', pg_temp.q('SELECT "Autorizadas" || ''/'' || "Observadas" || ''/'' || "Pendientes" || ''/'' || "Rechazadas" || ''/'' || "Retiradas" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S1: avance «por iniciar»', 'POR_INICIAR', pg_temp.q('SELECT "Avance" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s1 || ')'), 'aprobada parcialmente y nadie ingresó');
    PERFORM pg_temp.chk('Indicadores S1: se puede editar, cancelar y modificar personal', 'Y/Y/Y', pg_temp.q('SELECT "Editar_Datos" || ''/'' || "Cancelar" || ''/'' || "Modificar_Personal" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S2: sin avance mientras no esté aprobada del todo (2 de 3, parcial)', 'POR_INICIAR', pg_temp.q('SELECT "Avance" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s2 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S3: avance «en curso»', 'EN_CURSO', pg_temp.q('SELECT "Avance" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s3 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S3: ya ingresó alguien, no edita ni cancela, sí modifica personal', 'N/N/Y', pg_temp.q('SELECT "Editar_Datos" || ''/'' || "Cancelar" || ''/'' || "Modificar_Personal" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s3 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S3: motivo de no poder editar', 'Ya ingresó una persona: los datos de la visita no se cambian. Puede modificar el personal.', pg_temp.q('SELECT "Motivo_Editar_Datos" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s3 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S3: motivo de no poder cancelar', 'Ya ingresó una persona: no se puede cancelar. Retire a quienes faltan.', pg_temp.q('SELECT "Motivo_Cancelar" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s3 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S4 (cancelada): nada se puede hacer', 'N/N/N', pg_temp.q('SELECT "Editar_Datos" || ''/'' || "Cancelar" || ''/'' || "Modificar_Personal" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s4 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S4: motivo', 'La solicitud está cancelada.', pg_temp.q('SELECT "Motivo_Editar_Datos" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s4 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S4: sin avance', '(nulo)', pg_temp.q('SELECT "Avance" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s4 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S5 (fecha pasada): nada se puede hacer', 'N/N/N', pg_temp.q('SELECT "Editar_Datos" || ''/'' || "Cancelar" || ''/'' || "Modificar_Personal" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s5 || ')'), '');
    PERFORM pg_temp.chk('Indicadores S5: motivo (invita a reutilizar)', 'La fecha de la visita ya pasó. Use «Reutilizar».', pg_temp.q('SELECT "Motivo_Editar_Datos" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s5 || ')'), '');
    PERFORM pg_temp.chk('Indicadores: sin parámetro devuelve todas las solicitudes', '5', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_INDICADORES"(NULL)'), '');
    PERFORM pg_temp.chk('Indicadores: solicitud inexistente', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_INDICADORES"(999999)'), '');
    -- Avance según cómo van las personas autorizadas de S3
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'SALIO', "Fecha_Hora_Salida" = CURRENT_TIMESTAMP WHERE "ID_Solicitud_Persona" = v_q4;
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'NO_SE_PRESENTO' WHERE "ID_Solicitud_Persona" = v_q5;
    PERFORM pg_temp.chk('Avance: todas las autorizadas salieron o no vinieron = finalizada', 'FINALIZADA', pg_temp.q('SELECT "Avance" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s3 || ')'), '');
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'NO_SE_PRESENTO', "Fecha_Hora_Salida" = NULL, "Fecha_Hora_Ingreso" = NULL WHERE "ID_Solicitud_Persona" = v_q4;
    PERFORM pg_temp.chk('Avance: nadie se presentó', 'NO_SE_PRESENTO', pg_temp.q('SELECT "Avance" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s3 || ')'), '');
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'DENTRO', "Fecha_Hora_Ingreso" = CURRENT_TIMESTAMP WHERE "ID_Solicitud_Persona" = v_q4;
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'ESPERADA' WHERE "ID_Solicitud_Persona" = v_q5;

    -- Los botones coinciden con lo que de verdad permite el procedimiento de escritura
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s3, v_fut, 'Hoy Visitas S.A.', v_per, v_mot, NULL, NULL, v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide S3: «no editar» = el SP rechaza (409)', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_s3, NULL, v_u_sol2, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide S3: «no cancelar» = el SP rechaza (409)', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s5, v_fut, 'Pasada S.A.', v_per, v_mot, NULL, NULL, v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide S5: «no editar» (fecha pasada) = el SP rechaza (409)', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_s5, NULL, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide S5: «no cancelar» = el SP rechaza (409)', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s5, v_e2, v_u_sol, v_spr, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide S5: «no modificar personal» = el SP rechaza (409)', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s4, v_fut, 'Cancelada S.A.', v_per, v_mot, NULL, NULL, v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide S4: «no editar» (cancelada) = el SP rechaza (409)', '409', v_cod::TEXT, v_msg);

    -- ===================================================== C. «MIS SOLICITUDES»
    PERFORM pg_temp.chk('Mis solicitudes: Carlos ve las 4 suyas (S1, S2, S4, S5)', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ')'), '');
    PERFORM pg_temp.chk('Mis solicitudes: Ana ve solo la suya', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol2 || ')'), '');
    PERFORM pg_temp.chk('Mis solicitudes: el Coordinador no tiene solicitudes propias', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_coo || ')'), '');
    PERFORM pg_temp.chk('Mis solicitudes: sin rol, nada', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_nada || ')'), '');
    PERFORM pg_temp.chk('Mis solicitudes: la más reciente primero', v_s5::TEXT, pg_temp.q('SELECT "ID_Solicitud" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') LIMIT 1'), '');
    PERFORM pg_temp.chk('Mis solicitudes: fila de S1 con sus conteos', '3/1/1/1', pg_temp.q('SELECT "Total_Personas" || ''/'' || "Autorizadas" || ''/'' || "Observadas" || ''/'' || "Pendientes" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Mis solicitudes: estado de S1 calculado', 'APROBADA_PARCIAL', pg_temp.q('SELECT "Estado" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Mis solicitudes: trae sede, tipo y responsable', 'Villa El Salvador|Resp, Atención', pg_temp.q('SELECT "Sede" || ''|'' || "Responsable_Nombre" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Mis solicitudes: S1 con todos los botones', 'Y/Y/Y/Y', pg_temp.q('SELECT "Puede_Editar_Datos" || ''/'' || "Puede_Modificar_Personal" || ''/'' || "Puede_Cancelar" || ''/'' || "Puede_Reutilizar" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Mis solicitudes: S5 pasada, solo reutilizar', 'N/N/N/Y', pg_temp.q('SELECT "Puede_Editar_Datos" || ''/'' || "Puede_Modificar_Personal" || ''/'' || "Puede_Cancelar" || ''/'' || "Puede_Reutilizar" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_s5), '');
    PERFORM pg_temp.chk('Mis solicitudes: S5 muestra «Basada en» S1', v_cs1, pg_temp.q('SELECT "Codigo_Origen" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_s5), '');
    PERFORM pg_temp.chk('Mis solicitudes: filtro por estado CANCELADA', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', NULL, NULL, ''cancelada'')'), 'acepta minúsculas');
    PERFORM pg_temp.chk('Mis solicitudes: buscar «energia» encuentra «Energía» (sin tildes)', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', NULL, ''energia'')'), '');
    PERFORM pg_temp.chk('Mis solicitudes: buscar por código', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', NULL, ''' || v_cs1 || ''')'), '');
    PERFORM pg_temp.chk('Mis solicitudes: buscar una persona por apellido', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', NULL, ''torres'')'), 'S1, S2 y S5 la incluyen');
    PERFORM pg_temp.chk('Mis solicitudes: buscar una persona por documento', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', NULL, ''71000001'')'), '');
    PERFORM pg_temp.chk('Mis solicitudes: una persona que solo está en solicitudes de otro', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', NULL, ''rojas'')'), '');
    PERFORM pg_temp.chk('Mis solicitudes: por sede', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', ' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Mis solicitudes: sede donde no tiene permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', 999999)'), '');
    PERFORM pg_temp.chk('Mis solicitudes: desde hoy (sin la pasada)', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', NULL, NULL, NULL, CURRENT_DATE)'), '');
    PERFORM pg_temp.chk('Mis solicitudes: hasta ayer (solo la pasada)', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', NULL, NULL, NULL, NULL, CURRENT_DATE - 1)'), '');
    PERFORM pg_temp.chk('Mis solicitudes: texto en blanco no filtra', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', NULL, ''   '')'), '');

    -- ===================================================== D. BANDEJA DE QUIEN APRUEBA
    PERFORM pg_temp.chk('Bandeja «Por decidir»: el Coordinador solo tiene S1 (e3 pendiente)', v_s1::TEXT, pg_temp.q('SELECT string_agg("ID_Solicitud"::TEXT, '','') FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''POR_DECIDIR'')'), 'S2 ya tiene todo decidido');
    PERFORM pg_temp.chk('Bandeja: personas por decidir en S1', '1', pg_temp.q('SELECT "Por_Decidir_Mis" FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''POR_DECIDIR'') WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Bandeja «Todas»: el Coordinador ve las 5', '5', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''TODAS'')'), '');
    PERFORM pg_temp.chk('Bandeja: sin pestaña = todas', '5', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ')'), '');
    PERFORM pg_temp.chk('Bandeja: pestaña desconocida', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''XX'')'), '');
    PERFORM pg_temp.chk('Bandeja: almacén no ve «Todas» (no tiene ese permiso)', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_alm || ', NULL, ''TODAS'')'), '');
    PERFORM pg_temp.chk('Bandeja: el solicitante no ve «Todas»', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_sol || ', NULL, ''TODAS'')'), '');
    PERFORM pg_temp.chk('Bandeja: el solicitante no decide nada', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_sol || ', NULL, ''POR_DECIDIR'')'), '');
    PERFORM pg_temp.chk('Bandeja: Vigilancia no ve solicitudes', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_vig || ', NULL, ''TODAS'')'), '');
    PERFORM pg_temp.chk('Bandeja: filtro por estado APROBADA', v_s3::TEXT, pg_temp.q('SELECT string_agg("ID_Solicitud"::TEXT, '','') FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''TODAS'', NULL, NULL, NULL, NULL, ''APROBADA'')'), '');
    PERFORM pg_temp.chk('Bandeja: filtro por fecha de hoy', v_s3 || ',' || v_s4, pg_temp.q('SELECT string_agg("ID_Solicitud"::TEXT, '','' ORDER BY "ID_Solicitud") FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''TODAS'', NULL, NULL, NULL, CURRENT_DATE)'), 'S3 y S4 son de hoy');
    PERFORM pg_temp.chk('Bandeja: «Es_Hoy» marca las de hoy', 'Y', pg_temp.q('SELECT "Es_Hoy" FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ') WHERE "ID_Solicitud" = ' || v_s3), '');
    PERFORM pg_temp.chk('Bandeja: filtro por empresa (sin tildes)', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''TODAS'', ''ENERGIA'')'), '');
    PERFORM pg_temp.chk('Bandeja: filtro por solicitante «carlos»', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''TODAS'', NULL, ''carlos'')'), '');
    PERFORM pg_temp.chk('Bandeja: filtro por solicitante «ana»', v_s3::TEXT, pg_temp.q('SELECT string_agg("ID_Solicitud"::TEXT, '','') FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''TODAS'', NULL, ''ana'')'), '');
    PERFORM pg_temp.chk('Bandeja: filtro por persona (apellido)', v_s3::TEXT, pg_temp.q('SELECT string_agg("ID_Solicitud"::TEXT, '','') FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''TODAS'', NULL, NULL, ''rojas'')'), '');
    PERFORM pg_temp.chk('Bandeja: filtro por persona (documento)', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''TODAS'', NULL, NULL, ''71000001'')'), 'S1, S2 y S5');
    PERFORM pg_temp.chk('Bandeja: por sede inexistente', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', 999999, ''TODAS'')'), '');
    PERFORM pg_temp.chk('Bandeja: nombres de las personas en la fila', 'Torres Quispe, Luis | Vargas Ríos, Ana | Soto Medina, Enrique', pg_temp.q('SELECT "Personas_Nombres" FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ') WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Bandeja: trae el solicitante', 'Solicitante Uno, Carlos', pg_temp.q('SELECT "Solicitante_Nombre" FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ') WHERE "ID_Solicitud" = ' || v_s1), '');
    -- Almacén: tras decidir el servicio, su bandeja queda vacía; antes tenía S2
    PERFORM pg_temp.chk('Bandeja: almacén sin pendientes', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_alm || ', NULL, ''POR_DECIDIR'')'), '');

    -- ===================================================== E. CONTADORES
    PERFORM pg_temp.chk('Contadores Carlos: 2 solicitudes con observadas (S1 y S2)', '2', pg_temp.q('SELECT "Mis_Con_Observadas" FROM "ERP_CAF_SOLICITUD_CONTADORES"(' || v_u_sol || ')'), 'la cancelada no cuenta');
    PERFORM pg_temp.chk('Contadores Carlos: no decide nada', '0/0', pg_temp.q('SELECT "Por_Decidir_Solicitudes" || ''/'' || "Por_Decidir_Personas" FROM "ERP_CAF_SOLICITUD_CONTADORES"(' || v_u_sol || ')'), '');
    PERFORM pg_temp.chk('Contadores Coordinador: 1 solicitud, 1 persona por decidir', '1/1', pg_temp.q('SELECT "Por_Decidir_Solicitudes" || ''/'' || "Por_Decidir_Personas" FROM "ERP_CAF_SOLICITUD_CONTADORES"(' || v_u_coo || ')'), '');
    PERFORM pg_temp.chk('Contadores Coordinador: no tiene solicitudes propias', '0', pg_temp.q('SELECT "Mis_Con_Observadas" FROM "ERP_CAF_SOLICITUD_CONTADORES"(' || v_u_coo || ')'), '');
    PERFORM pg_temp.chk('Contadores: sin rol, todo en cero', '0/0/0', pg_temp.q('SELECT "Mis_Con_Observadas" || ''/'' || "Por_Decidir_Solicitudes" || ''/'' || "Por_Decidir_Personas" FROM "ERP_CAF_SOLICITUD_CONTADORES"(' || v_u_nada || ')'), '');
    PERFORM pg_temp.chk('Contadores: siempre una fila', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_CONTADORES"(' || v_u_nada || ')'), '');

    -- ===================================================== F. DETALLE
    PERFORM pg_temp.chk('Detalle: el dueño ve su solicitud', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: otro solicitante no la ve (cero filas)', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol2 || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: el Coordinador la ve', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_coo || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: almacén no ve una visita externa', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_alm || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: almacén sí ve la del contratista', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_alm || ', ' || v_s2 || ')'), '');
    PERFORM pg_temp.chk('Detalle: Vigilancia no ve el detalle de una solicitud', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_vig || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: solicitud inexistente', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_coo || ', 999999)'), '');
    PERFORM pg_temp.chk('Detalle: código, sede y tipo', v_cs1 || '|Villa El Salvador|Visitante externo', pg_temp.q('SELECT "Codigo" || ''|'' || "Sede" || ''|'' || "Tipo_Acceso" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: responsable con su área', 'Resp, Atención', pg_temp.q('SELECT "Responsable_Nombre" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: el área del responsable', 'Y', pg_temp.q('SELECT CASE WHEN "Responsable_Area" IS NOT NULL THEN ''Y'' ELSE ''N'' END FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: solicitante', 'Solicitante Uno, Carlos|carlos@ejemplo.pe', pg_temp.q('SELECT "Solicitante_Nombre" || ''|'' || "Solicitante_Correo" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: dos zonas (identificadores en texto con comas)', '2', pg_temp.q('SELECT array_length(string_to_array("Zonas_IDs", '',''), 1) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: dos nombres de zona', '2', pg_temp.q('SELECT array_length(string_to_array("Zonas_Nombres", '', ''), 1) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: dos correos en copia', '2', pg_temp.q('SELECT array_length(string_to_array("Copias", ''; ''), 1) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: observaciones del solicitante', 'Traerán un proyector.', pg_temp.q('SELECT "Observaciones" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: estado, avance y conteos', 'APROBADA_PARCIAL|POR_INICIAR|3/1/1/1', pg_temp.q('SELECT "Estado" || ''|'' || "Avance" || ''|'' || "Total_Personas" || ''/'' || "Autorizadas" || ''/'' || "Observadas" || ''/'' || "Pendientes" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: última observación y quién decidió', 'Falta DNI legible|Coordinador Uno, Roberto', pg_temp.q('SELECT "Observacion_Coordinador" || ''|'' || "Usuario_Decision_Nombre" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), 'resumen de la última decisión (D-45)');
    PERFORM pg_temp.chk('Detalle: fecha de la decisión', 'Y', pg_temp.q('SELECT CASE WHEN "Fecha_Decision" IS NOT NULL THEN ''Y'' ELSE ''N'' END FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: el dueño tiene todos los botones', 'Y/Y/Y/Y/Y', pg_temp.q('SELECT "Es_Propia" || ''/'' || "Puede_Editar_Datos" || ''/'' || "Puede_Modificar_Personal" || ''/'' || "Puede_Cancelar" || ''/'' || "Puede_Reutilizar" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: el dueño no decide', 'N/0', pg_temp.q('SELECT "Puede_Decidir" || ''/'' || "Por_Decidir_Mis" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: el Coordinador no tiene botones del dueño', 'N/N/N/N/N', pg_temp.q('SELECT "Es_Propia" || ''/'' || "Puede_Editar_Datos" || ''/'' || "Puede_Modificar_Personal" || ''/'' || "Puede_Cancelar" || ''/'' || "Puede_Reutilizar" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_coo || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle: el Coordinador puede decidir 1 persona', 'Y/1', pg_temp.q('SELECT "Puede_Decidir" || ''/'' || "Por_Decidir_Mis" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_coo || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Detalle S2: almacén ya no tiene nada por decidir', 'N/0', pg_temp.q('SELECT "Puede_Decidir" || ''/'' || "Por_Decidir_Mis" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_alm || ', ' || v_s2 || ')'), '');
    PERFORM pg_temp.chk('Detalle S4: motivo de la cancelación', 'Reprogramada', pg_temp.q('SELECT "Motivo_Cancelacion" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s4 || ')'), '');
    PERFORM pg_temp.chk('Detalle S4: el dueño no puede hacer nada salvo reutilizar, con el motivo', 'N/N/N/Y/La solicitud está cancelada.', pg_temp.q('SELECT "Puede_Editar_Datos" || ''/'' || "Puede_Modificar_Personal" || ''/'' || "Puede_Cancelar" || ''/'' || "Puede_Reutilizar" || ''/'' || "Motivo_No_Editar_Datos" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s4 || ')'), '');
    PERFORM pg_temp.chk('Detalle S5: «Basada en» la solicitud origen', v_cs1, pg_temp.q('SELECT "Codigo_Origen" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_s5 || ')'), '');
    PERFORM pg_temp.chk('Detalle S3: el dueño (Ana) ve el avance', 'EN_CURSO', pg_temp.q('SELECT "Avance" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol2 || ', ' || v_s3 || ')'), '');

    -- ===================================================== G. PERSONAS DE LA SOLICITUD
    PERFORM pg_temp.chk('Personas S1: 3 filas para el dueño', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Personas: otro solicitante no ve nada', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol2 || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Personas: nombre y documento', 'Torres Quispe, Luis|DNI|71000001', pg_temp.q('SELECT "Nombre_Completo" || ''|'' || "Tipo_Documento" || ''|'' || "Numero_Documento" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p1), '');
    PERFORM pg_temp.chk('Personas: la aprobada muestra quién y cuándo', 'APROBADA|Coordinador Uno, Roberto', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Aprobado_Por_Nombre" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p1), '');
    PERFORM pg_temp.chk('Personas: la observada trae el mensaje', 'OBSERVADA|Falta DNI legible', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Aprobacion_Mensaje" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p2), '');
    PERFORM pg_temp.chk('Personas: la aprobada se retira pero no se corrige', 'Y/N/N', pg_temp.q('SELECT "Puede_Retirar" || ''/'' || "Puede_Corregir" || ''/'' || "Puede_Reactivar" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p1), '');
    PERFORM pg_temp.chk('Personas: la observada se retira y se corrige', 'Y/Y/N', pg_temp.q('SELECT "Puede_Retirar" || ''/'' || "Puede_Corregir" || ''/'' || "Puede_Reactivar" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p2), '');
    PERFORM pg_temp.chk('Personas: la pendiente se retira y se corrige', 'Y/Y/N', pg_temp.q('SELECT "Puede_Retirar" || ''/'' || "Puede_Corregir" || ''/'' || "Puede_Reactivar" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p3), '');
    PERFORM pg_temp.chk('Personas: el solicitante no decide', 'N', pg_temp.q('SELECT "Puede_Decidir" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p3), '');
    PERFORM pg_temp.chk('Personas: el Coordinador no tiene botones de edición', 'N/N/N', pg_temp.q('SELECT "Puede_Retirar" || ''/'' || "Puede_Corregir" || ''/'' || "Puede_Reactivar" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p3), '');
    PERFORM pg_temp.chk('Personas: el Coordinador puede decidir solo a la pendiente', v_p3::TEXT, pg_temp.q('SELECT string_agg("ID_Solicitud_Persona"::TEXT, '','') FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "Puede_Decidir" = ''Y'''), '');
    PERFORM pg_temp.chk('Personas: el paso que le toca decidir', v_paso_ext::TEXT, pg_temp.q('SELECT "Pasos_Mis_Decidir" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p3), '');
    PERFORM pg_temp.chk('Personas S3: la que ya ingresó no se retira ni se corrige', 'N/N', pg_temp.q('SELECT "Puede_Retirar" || ''/'' || "Puede_Corregir" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol2 || ', ' || v_s3 || ') WHERE "ID_Solicitud_Persona" = ' || v_q4), '');
    PERFORM pg_temp.chk('Personas S3: la rechazada está cerrada', 'N/N/N', pg_temp.q('SELECT "Puede_Retirar" || ''/'' || "Puede_Corregir" || ''/'' || "Puede_Reactivar" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol2 || ', ' || v_s3 || ') WHERE "ID_Solicitud_Persona" = ' || v_q6), '');
    PERFORM pg_temp.chk('Personas S3: la que falta llegar sí se puede retirar', 'Y', pg_temp.q('SELECT "Puede_Retirar" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol2 || ', ' || v_s3 || ') WHERE "ID_Solicitud_Persona" = ' || v_q5), '');
    PERFORM pg_temp.chk('Personas S4 (cancelada): ningún botón', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol || ', ' || v_s4 || ') WHERE "Puede_Retirar" = ''Y'' OR "Puede_Corregir" = ''Y'' OR "Puede_Reactivar" = ''Y'''), '');

    -- ===================================================== H. RUTA DE APROBACIÓN
    PERFORM pg_temp.chk('Ruta S1: 3 personas por 1 paso', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_coo || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Ruta S2: 3 personas por 3 pasos', '9', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_coo || ', ' || v_s2 || ')'), '');
    PERFORM pg_temp.chk('Ruta: nadie ajeno la ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_sol2 || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Ruta S1: la pendiente figura PENDIENTE', 'PENDIENTE', pg_temp.q('SELECT "Decision" FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p3), '');
    PERFORM pg_temp.chk('Ruta S1: la aprobada trae quién decidió', 'APROBADA|Coordinador Uno, Roberto', pg_temp.q('SELECT "Decision" || ''|'' || "Decidio_Nombre" FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p1), '');
    PERFORM pg_temp.chk('Ruta S1: la observada trae su mensaje', 'OBSERVADA|Falta DNI legible', pg_temp.q('SELECT "Decision" || ''|'' || "Mensaje" FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p2), '');
    PERFORM pg_temp.chk('Ruta S1: nombre del rol que aprueba', 'Y', pg_temp.q('SELECT CASE WHEN "Rol_Aprobador" LIKE ''Coordinador%'' THEN ''Y'' ELSE ''N'' END FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') LIMIT 1'), '');
    PERFORM pg_temp.chk('Ruta S1: «Es_Mi_Turno» solo para la pendiente del Coordinador', v_p3::TEXT, pg_temp.q('SELECT string_agg("ID_Solicitud_Persona"::TEXT, '','') FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "Es_Mi_Turno" = ''Y'''), '');
    PERFORM pg_temp.chk('Ruta S2: el paso por solicitud figura aprobado para las 3', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_coo || ', ' || v_s2 || ') WHERE "Paso_Codigo" = ''SERVICIO'' AND "Decision" = ''APROBADA'''), '');
    PERFORM pg_temp.chk('Ruta S2: el cierre aprobado para 2 y pendiente para la observada', '2/1', pg_temp.q('SELECT SUM(CASE WHEN "Decision" = ''APROBADA'' THEN 1 ELSE 0 END) || ''/'' || SUM(CASE WHEN "Decision" = ''PENDIENTE'' THEN 1 ELSE 0 END) FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_coo || ', ' || v_s2 || ') WHERE "Paso_Codigo" = ''CIERRE'''), '');
    PERFORM pg_temp.chk('Ruta S2: los pasos salen en orden', 'DOCUMENTOS,SERVICIO,CIERRE', pg_temp.q('SELECT string_agg("Paso_Codigo", '','' ORDER BY "Paso_Orden", "ID_Tipo_Acceso_Paso_Aprobacion") FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_coo || ', ' || v_s2 || ') WHERE "ID_Solicitud_Persona" = ' || pg_temp.sp(v_s2, v_e1)), '');

    -- ===================================================== I. HISTORIAL
    PERFORM pg_temp.chk('Historial: el dueño lo ve', 'Y', pg_temp.q('SELECT CASE WHEN COUNT(*) > 0 THEN ''Y'' ELSE ''N'' END FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Historial: otro solicitante no lo ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_sol2 || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Historial: Vigilancia no lo ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_vig || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Historial: aparece la creación con su autor', 'Creó y envió la solicitud|Solicitante Uno, Carlos', pg_temp.q('SELECT "Accion_Texto" || ''|'' || "Usuario_Nombre" FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "Accion" = ''CREAR'''), '');
    PERFORM pg_temp.chk('Historial: aparecen las decisiones con frase legible', 'Aprobó,Observó', pg_temp.q('SELECT string_agg(DISTINCT "Accion_Texto", '','' ORDER BY "Accion_Texto") FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "Entidad" = ''SOLICITUD_DECISION'''), '');
    PERFORM pg_temp.chk('Historial: lo más reciente primero', 'CREAR', pg_temp.q('SELECT "Accion" FROM (SELECT "Accion", "Fecha_Evento", "ID_Evento" FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ', ' || v_s1 || ')) X ORDER BY "ID_Evento" ASC LIMIT 1'), 'el primero escrito es la creación');
    PERFORM pg_temp.chk('Historial: la lista llega con el último evento arriba', pg_temp.q('SELECT MAX("ID_Evento") FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_s1), pg_temp.q('SELECT "ID_Evento" FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') LIMIT 1'), '');
    PERFORM pg_temp.chk('Historial S4: la cancelación y su motivo', 'Canceló la solicitud|Reprogramada', pg_temp.q('SELECT "Accion_Texto" || ''|'' || "Detalle" FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_sol || ', ' || v_s4 || ') WHERE "Accion" = ''CANCELAR'''), '');

    -- ===================================================== J. VERSIONES (RN-08)
    PERFORM pg_temp.chk('Versiones S1: hay una foto de lo aprobado', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VERSION_LISTAR"(' || v_u_coo || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Versiones: el contenido es JSON', '{', pg_temp.q('SELECT LEFT("Contenido_JSON", 1) FROM "ERP_CAF_SOLICITUD_VERSION_LISTAR"(' || v_u_coo || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Versiones: quién aprobó', 'Coordinador Uno, Roberto', pg_temp.q('SELECT "Aprobador_Nombre" FROM "ERP_CAF_SOLICITUD_VERSION_LISTAR"(' || v_u_sol || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Versiones: otro solicitante no las ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VERSION_LISTAR"(' || v_u_sol2 || ', ' || v_s1 || ')'), '');

    -- ===================================================== K. VIGILANCIA
    PERFORM pg_temp.chk('Vigilancia hoy: solo las 2 personas autorizadas de S3', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ')'), 'la rechazada y la cancelada no aparecen');
    PERFORM pg_temp.chk('Vigilancia: el estado y el grupo de cada una', 'DENTRO/POR_INGRESAR', pg_temp.q('SELECT string_agg("Grupo", ''/'' ORDER BY "ID_Solicitud_Persona") FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ')'), '');
    PERFORM pg_temp.chk('Vigilancia: filtro por grupo «Dentro»', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ', NULL, NULL, NULL, ''DENTRO'')'), '');
    PERFORM pg_temp.chk('Vigilancia: filtro por grupo «Por ingresar»', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ', NULL, NULL, NULL, ''por_ingresar'')'), '');
    PERFORM pg_temp.chk('Vigilancia: filtro por grupo «Salieron»', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ', NULL, NULL, NULL, ''SALIERON'')'), '');
    PERFORM pg_temp.chk('Vigilancia: buscar por apellido', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ', NULL, NULL, ''rojas'')'), '');
    PERFORM pg_temp.chk('Vigilancia: buscar por documento', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ', NULL, NULL, ''71000004'')'), '');
    PERFORM pg_temp.chk('Vigilancia: buscar por empresa', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ', NULL, NULL, ''hoy visitas'')'), '');
    PERFORM pg_temp.chk('Vigilancia: por sede inexistente', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ', 999999)'), '');
    PERFORM pg_temp.chk('Vigilancia: el Coordinador ve portería (tiene «Ver»)', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_coo || ')'), '');
    PERFORM pg_temp.chk('Vigilancia: el solicitante no', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_sol || ')'), '');
    PERFORM pg_temp.chk('Vigilancia: sin permisos de portería', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_nada || ')'), '');
    PERFORM pg_temp.chk('Vigilancia: otro día (la visita de pasado mañana), solo autorizadas', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ', NULL, CAST(''' || v_fut || ''' AS DATE))'), 'S1: 1 persona; S2: 2 personas');
    PERFORM pg_temp.chk('Vigilancia: trae zonas y exigencias', 'Y', pg_temp.q('SELECT CASE WHEN "Zonas_Nombres" IS NOT NULL AND "Exige_SCTR" IN (''Y'',''N'') AND "Exige_EPP" IN (''Y'',''N'') THEN ''Y'' ELSE ''N'' END FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ') LIMIT 1'), '');
    PERFORM pg_temp.chk('Vigilancia: la hora de ingreso de quien está dentro', 'Y', pg_temp.q('SELECT CASE WHEN "Fecha_Hora_Ingreso" IS NOT NULL THEN ''Y'' ELSE ''N'' END FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ') WHERE "Grupo" = ''DENTRO'''), '');
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'NO_SE_PRESENTO' WHERE "ID_Solicitud_Persona" = v_q5;
    PERFORM pg_temp.chk('Vigilancia: «no se presentó» cae en el último grupo', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ', NULL, NULL, NULL, ''DENEGADOS_NO_VINIERON'')'), '');
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'ESPERADA' WHERE "ID_Solicitud_Persona" = v_q5;

    -- «Aparece, pero no está autorizada»
    PERFORM pg_temp.chk('No autorizada: la rechazada y la de la solicitud cancelada', 'CANCELADA,RECHAZADA', pg_temp.q('SELECT string_agg("Motivo_Codigo", '','' ORDER BY "Motivo_Codigo") FROM "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR"(' || v_u_vig || ', ' || v_ves || ', CURRENT_DATE, ''arias'')'), 'Arias figura en S3 (rechazada) y en S4 (cancelada)');
    PERFORM pg_temp.chk('No autorizada: mínimo 3 letras', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR"(' || v_u_vig || ', ' || v_ves || ', CURRENT_DATE, ''ar'')'), '');
    PERFORM pg_temp.chk('No autorizada: una persona autorizada no aparece aquí', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR"(' || v_u_vig || ', ' || v_ves || ', CURRENT_DATE, ''rojas'')'), '');
    PERFORM pg_temp.chk('No autorizada: el texto explica el motivo', 'Su ingreso fue rechazado.', pg_temp.q('SELECT "Motivo_Texto" FROM "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR"(' || v_u_vig || ', ' || v_ves || ', CURRENT_DATE, ''71000006'') WHERE "Motivo_Codigo" = ''RECHAZADA'''), '');
    PERFORM pg_temp.chk('No autorizada: quien no es de portería no puede buscar', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR"(' || v_u_sol || ', ' || v_ves || ', CURRENT_DATE, ''arias'')'), '');
    PERFORM pg_temp.chk('No autorizada: otro día no trae nada', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR"(' || v_u_vig || ', ' || v_ves || ', CURRENT_DATE + 30, ''arias'')'), '');

    -- ===================================================== L. CAMBIOS: retirar y volver a agregar (los botones se actualizan)
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_p3, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Cambios: se retira a la pendiente', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Cambios: ahora puede volver a agregarse', 'RETIRADA|Y/N', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Puede_Reactivar" || ''/'' || "Puede_Retirar" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p3), '');
    PERFORM pg_temp.chk('Cambios: la retirada ya no cuenta en el total pero sí en el conteo de retiradas', '2/1', pg_temp.q('SELECT "Total_Personas" || ''/'' || "Retiradas" FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Cambios: el Coordinador ya no la tiene por decidir', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_coo || ', ' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Cambios: la retirada no aparece en la ruta de aprobación', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p3), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_p2, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Cambios: se retira a la observada; queda una sola persona', '2/Y', pg_temp.q('SELECT "Retiradas" || ''/'' || ''Y'' FROM "ERP_CAF_SOLICITUD_INDICADORES"(' || v_s1 || ')'), '');
    PERFORM pg_temp.chk('Cambios: la última persona ya no se puede retirar (botón)', 'N', pg_temp.q('SELECT "Puede_Retirar" FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_u_sol || ', ' || v_s1 || ') WHERE "ID_Solicitud_Persona" = ' || v_p1), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_p1, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide: ese botón apagado = el SP rechaza (101)', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s1, v_e3, v_u_sol, v_spr, v_cod, v_msg);
    PERFORM pg_temp.chk('Cambios: se vuelve a agregar a la retirada', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Cambios: vuelve como pendiente y el Coordinador la tiene por decidir', 'PENDIENTE|1', pg_temp.q('SELECT P."Aprobacion" || ''|'' || (SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_coo || ', ' || v_s1 || ')) FROM "CAF_Solicitud_Persona" P WHERE P."ID_Solicitud_Persona" = ' || v_p3), '');
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Nota"
  FROM pruebas WHERE esperado <> obtenido ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
