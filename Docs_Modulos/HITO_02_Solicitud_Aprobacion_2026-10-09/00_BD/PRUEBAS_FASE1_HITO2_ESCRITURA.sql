-- =============================================================================
-- Archivo : PRUEBAS_FASE1_HITO2_ESCRITURA.sql
-- Proyecto: Control de Accesos · V1.0 2026-10-16
-- Propósito: pruebas automáticas de los procedimientos de escritura del Hito 2:
--   crear, editar, cancelar, personas de la solicitud y decisiones por paso.
--   Cada prueba llama un procedimiento y compara el resultado con lo esperado.
--   Termina en ROLLBACK: la base queda exactamente como estaba.
-- Requiere: scripts 01 a 10, los SP de los Hitos 0 y 1, SP_GOVERNANCE_PERMISO_ALL,
--   SP_CAF_TIPO_ACCESO_PASO_APROBACION_ALL y los 4 archivos SP_CAF_SOLICITUD_*.
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
    v_id BIGINT; v_cs VARCHAR(20); v_cod INT; v_msg VARCHAR(250); v_cant BIGINT; v_reab CHAR(1); v_sp BIGINT; v_est VARCHAR(20);
    v_ves BIGINT; v_dni BIGINT; v_area BIGINT; v_emp BIGINT; v_per BIGINT;
    v_lic_sol BIGINT; v_lic_coo BIGINT; v_lic_vig BIGINT; v_lic_alm BIGINT;
    v_u_sol BIGINT; v_u_sol2 BIGINT; v_u_coo BIGINT; v_u_vig BIGINT; v_u_alm BIGINT; v_u_nada BIGINT; v_ul BIGINT;
    v_e1 BIGINT; v_e2 BIGINT; v_e3 BIGINT; v_e4 BIGINT; v_e5 BIGINT; v_e6 BIGINT;
    v_z_adm BIGINT; v_z_pt BIGINT; v_z_1p BIGINT; v_mot BIGINT; v_mot_otro BIGINT;
    v_ext BIGINT; v_con BIGINT; v_int BIGINT; v_paso_ext BIGINT; v_s1 BIGINT; v_s2 BIGINT; v_s3 BIGINT;
    v_fut TIMESTAMP; v_pas TIMESTAMP; v_hoy TIMESTAMP;
    v_a BIGINT; v_b BIGINT; v_c BIGINT; v_d BIGINT;
    v_p1 BIGINT; v_p2 BIGINT; v_p3 BIGINT; v_p4 BIGINT; v_p5 BIGINT;
    v_paso_doc BIGINT; v_paso_serv BIGINT; v_paso_cierre BIGINT; v_dummy BIGINT;
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
    SELECT "ID_Catalogo_Zona_Acceso" INTO v_z_1p  FROM "Catalogo_Zona_Acceso" WHERE "Codigo" = 'OFICINA_1P' AND "ID_Catalogo_Sede" = v_ves;
    SELECT "ID_Catalogo_Motivo_Visita" INTO v_mot FROM "Catalogo_Motivo_Visita" WHERE "Codigo" = 'REUNION_COORDINACION';
    SELECT "ID_Catalogo_Motivo_Visita" INTO v_mot_otro FROM "Catalogo_Motivo_Visita" WHERE "Codigo" = 'OTRO';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_ext FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'VISITA_EXTERNA';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_con FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'CONTRATISTA';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_int FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'INTERNO_VISITANTE';
    SELECT "ID_Tipo_Acceso_Paso_Aprobacion" INTO v_paso_ext FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "ID_Catalogo_Tipo_Acceso" = v_ext LIMIT 1;

    v_fut := CURRENT_TIMESTAMP + INTERVAL '2 days';
    v_pas := CURRENT_TIMESTAMP - INTERVAL '2 days';
    v_hoy := CAST(CURRENT_DATE AS TIMESTAMP) + INTERVAL '23 hours';

    INSERT INTO "Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","UsuarioID_Create")
    VALUES (v_dni,'10101010','Resp','Atención',v_area,v_emp,v_ves,'resp@ejemplo.pe',0) RETURNING "ID_Personal" INTO v_per;

    -- Rol nuevo: aprobador de almacén (solo aprueba; no hereda nada del Coordinador)
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

    -- ===================================================== A. BITÁCORA (único escritor)
    CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', 1, NULL, 'CREAR', 'prueba', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Bitácora: pareja válida', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_EVENTO_REGISTRAR"('PERSONA_EXTERNA', 1, NULL, 'SALIDA', 'prueba', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Bitácora: PERSONA_EXTERNA + SALIDA no tiene sentido', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_EVENTO_REGISTRAR"('solicitud', 1, NULL, 'crear', 'prueba', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Bitácora: acepta minúsculas', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_EVENTO_REGISTRAR"('INCIDENCIA', 1, NULL, 'APROBAR', 'prueba', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Bitácora: INCIDENCIA + APROBAR no tiene sentido', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', NULL, NULL, 'CREAR', 'prueba', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Bitácora: sin identificador', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_EVENTO_REGISTRAR"('SOLICITUD', 1, NULL, 'CREAR', 'prueba', -1, v_cod, v_msg);
    PERFORM pg_temp.chk('Bitácora: usuario no válido', '400', v_cod::TEXT, v_msg);

    -- ===================================================== B. CREAR
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, v_u_nada, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: sin permiso', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, v_u_vig, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: Vigilancia no crea solicitudes', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_con, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: tipo de acceso no disponible', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_pas, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: fecha anterior a hoy', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, NULL, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: sin fecha', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, '   ', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: empresa vacía', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, 999999, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: responsable inexistente', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot_otro, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: motivo «Otro» exige describirlo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, NULL, v_e1::TEXT, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: sin zonas', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, '999999', v_e1::TEXT, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: zona inexistente', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm || ',' || v_z_adm, v_e1::TEXT, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: zona repetida', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: sin personas', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, '888888', NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: persona no registrada', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, 'sin-arroba', NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: correo en copia inválido', '400', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Crear: lo rechazado no dejó nada escrito', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud"'), 'ninguna solicitud');

    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, 'Traerán un proyector.',
                                   v_z_adm || ',' || v_z_pt, v_e1 || ',' || v_e2 || ',' || v_e3, 'Almacen@Ejemplo.pe; gerencia@ejemplo.pe', NULL, v_u_sol, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: correcta', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Crear: código SOL-nnnnn derivado del identificador', 'SOL-' || LPAD(v_s1::TEXT, 5, '0'), v_cs, '');
    PERFORM pg_temp.chk('Crear: estado PENDIENTE', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Crear: versión 1', '1', pg_temp.q('SELECT "Version" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Crear: 3 personas pendientes', '3', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Aprobacion" = ''PENDIENTE'' AND "Origen" = ''SOLICITUD'''), '');
    PERFORM pg_temp.chk('Crear: 2 zonas', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Zona" WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Crear: 2 copias, en minúsculas', 'almacen@ejemplo.pe,gerencia@ejemplo.pe', pg_temp.q('SELECT STRING_AGG("Correo", '','' ORDER BY "Correo") FROM "CAF_Solicitud_Copia_Correo" WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Crear: Producto terminado exige SCTR y EPP', 'YY', pg_temp.q('SELECT "Exige_SCTR" || "Exige_EPP" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1), 'copiado de la zona');
    PERFORM pg_temp.chk('Crear: tiene fecha de envío', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Fecha_Envio" IS NOT NULL'), '');
    PERFORM pg_temp.chk('Crear: deja un evento CREAR en la bitácora', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Accion" = ''CREAR'''), '');
    PERFORM pg_temp.chk('Crear: avisa al Coordinador', 'roberto@ejemplo.pe', pg_temp.q('SELECT "Destinatarios" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_NUEVA'''), 'solo el rol del primer paso');
    PERFORM pg_temp.chk('Crear: las copias van en la columna Copia', 'almacen@ejemplo.pe; gerencia@ejemplo.pe', pg_temp.q('SELECT "Copia" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_NUEVA'''), '');

    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Otra S.A.C.', v_mot_otro, 'Entrega de planos', NULL, v_z_adm::TEXT, v_e4::TEXT, NULL, NULL, v_u_sol, v_a, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: con motivo «Otro» y su detalle', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Crear: guarda el detalle del motivo', 'Entrega de planos', pg_temp.q('SELECT "Motivo_Detalle" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_a), '');
    PERFORM pg_temp.chk('Crear: zona administrativa no exige SCTR', 'NN', pg_temp.q('SELECT "Exige_SCTR" || "Exige_EPP" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_a), '');

    v_p1 := pg_temp.sp(v_s1, v_e1); v_p2 := pg_temp.sp(v_s1, v_e2); v_p3 := pg_temp.sp(v_s1, v_e3);

    -- ===================================================== C. DECIDIR (visitante externo: un solo paso)
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, v_p1::TEXT, v_u_sol, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: el solicitante no aprueba', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, v_p1::TEXT, v_u_vig, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: Vigilancia no aprueba', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, v_p1::TEXT, v_u_alm, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: tiene el permiso de aprobar pero no el rol de este paso', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'TAL VEZ', NULL, v_p1::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: valor de decisión no válido', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'OBSERVADA', '  ', v_p2::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: observar exige texto', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'RECHAZADA', NULL, v_p3::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: rechazar exige motivo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, 999999, 'APROBADA', NULL, v_p1::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: paso inexistente', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, NULL, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: sin elegir personas', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(999999, v_paso_ext, 'APROBADA', NULL, v_p1::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: solicitud inexistente', '404', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Decidir: lo rechazado no escribió decisiones', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Decision"'), '');

    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, v_p1::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: el Coordinador aprueba a 1 de 3', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Decidir: devuelve la cantidad decidida', '1', v_cant::TEXT, '');
    PERFORM pg_temp.chk('Decidir: la persona queda APROBADA', 'APROBADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p1), '');
    PERFORM pg_temp.chk('Decidir: guarda quién aprobó', v_u_coo::TEXT, pg_temp.q('SELECT "ID_Usuario_Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p1), '');
    PERFORM pg_temp.chk('Decidir: la solicitud queda APROBADA_PARCIAL', 'APROBADA_PARCIAL', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1), '2 siguen pendientes');
    PERFORM pg_temp.chk('Decidir: guarda la foto de lo aprobado', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Version" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Version" = 1 AND "Contenido_JSON" LIKE ''%"aprobacion":"APROBADA"%'''), 'RN-08');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, v_p1::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: no se decide dos veces sobre la misma persona', '409', v_cod::TEXT, v_msg);

    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'OBSERVADA', 'El DNI no coincide con el nombre.', v_p2::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: observa a otra', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Decidir: queda OBSERVADA con su mensaje', 'OBSERVADA|El DNI no coincide con el nombre.', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Aprobacion_Mensaje" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p2), 'lo ve el solicitante');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'RECHAZADA', 'No autorizado por seguridad.', v_p3::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: rechaza a la tercera', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Decidir: queda RECHAZADA con su motivo', 'RECHAZADA|No autorizado por seguridad.', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Aprobacion_Mensaje" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p3), '');
    PERFORM pg_temp.chk('Decidir: con una observada sigue APROBADA_PARCIAL', 'APROBADA_PARCIAL', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, v_p2::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: una persona observada no se decide hasta que se reenvíe', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, pg_temp.sp(v_a, v_e4)::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: no se decide sobre personas de otra solicitud', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Decidir: 3 eventos en la bitácora (aprobar, observar, rechazar)', 'APROBAR,OBSERVAR,RECHAZAR', pg_temp.q('SELECT STRING_AGG("Accion", '','' ORDER BY "ID_Evento") FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Entidad" = ''SOLICITUD_DECISION'''), '');
    PERFORM pg_temp.chk('Decidir: avisa al solicitante de cada decisión', '3', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_DECISION'' AND "Destinatarios" = ''carlos@ejemplo.pe'''), '');
    PERFORM pg_temp.chk('Decidir: resume la última decisión en la cabecera', 'No autorizado por seguridad.', pg_temp.q('SELECT "Observacion_Coordinador" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1), '');
    CALL "ERP_CAF_SOLICITUD_RECALCULAR"(v_s1, 0, v_est, v_cod, v_msg);
    PERFORM pg_temp.chk('Recalcular: llamarlo otra vez da lo mismo', 'APROBADA_PARCIAL', v_est::TEXT, 'idempotente');

    -- ===================================================== D. CORREGIR una persona observada
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(v_p2, v_e4, v_u_sol2, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Corregir: otro solicitante no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(v_p1, v_e4, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Corregir: una persona aprobada no se edita', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(v_p3, v_e4, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Corregir: una persona rechazada está cerrada', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(v_p2, v_e1, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Corregir: no puede apuntar a una persona que ya está en la solicitud', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(v_p2, 888888, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Corregir: persona nueva no registrada', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(v_p2, v_e5, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Corregir y reenviar a la observada', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Corregir: informa que se reenvió', 'Y', v_reab::TEXT, '');
    PERFORM pg_temp.chk('Corregir: vuelve a PENDIENTE con origen REENVIADA', 'PENDIENTE|REENVIADA', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Origen" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p2), '');
    PERFORM pg_temp.chk('Corregir: ya no tiene el mensaje de la observación', '(nulo)', pg_temp.q('SELECT "Aprobacion_Mensaje" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p2), '');
    PERFORM pg_temp.chk('Corregir: apunta a la persona corregida', v_e5::TEXT, pg_temp.q('SELECT "ID_Persona_Externa" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p2), '');
    PERFORM pg_temp.chk('Corregir: la decisión anterior queda en el historial, no vigente', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Decision" WHERE "ID_Solicitud_Persona" = ' || v_p2 || ' AND "Vigente" = ''N'' AND "Decision" = ''OBSERVADA'''), 'nada se borra');
    PERFORM pg_temp.chk('Corregir: avisa a quien decide', 'roberto@ejemplo.pe', pg_temp.q('SELECT "Destinatarios" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''PERSONA_POR_APROBAR'''), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(v_p2, v_e5, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Corregir: sin cambios en una pendiente', 'Sin cambios.', v_msg, 'no reenvía');
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(v_p2, v_e6, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Corregir: una pendiente se puede cambiar de persona', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Corregir: sin reenvío si no estaba observada', 'N', v_reab::TEXT, '');

    -- ===================================================== E. AGREGAR y RETIRAR personas
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s1, v_e4, v_u_sol2, v_p4, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar: otro solicitante no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s1, 888888, v_u_sol, v_p4, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar: persona no registrada', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s1, v_e4, v_u_sol, v_p4, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar: persona nueva a una solicitud en curso', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Agregar: nace PENDIENTE con origen AGREGADA', 'PENDIENTE|AGREGADA', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Origen" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p4), '');
    PERFORM pg_temp.chk('Agregar: lo aprobado no se toca', 'APROBADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p1), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s1, v_e4, v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar: la misma persona dos veces', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s1, v_e3, v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar: una persona rechazada no vuelve a entrar', '101', v_cod::TEXT, v_msg);

    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_p1, v_u_sol2, v_cod, v_msg);
    PERFORM pg_temp.chk('Retirar: otro solicitante no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_p3, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Retirar: una persona rechazada está cerrada', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(999999, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Retirar: persona inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_p1, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Retirar: una persona aprobada (aún no ingresó)', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Retirar: queda RETIRADA, no se borra', 'RETIRADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p1), '');
    PERFORM pg_temp.chk('Retirar: sus decisiones dejan de ser vigentes', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Decision" WHERE "ID_Solicitud_Persona" = ' || v_p1 || ' AND "Vigente" = ''Y'''), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_p1, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Retirar: dos veces', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s1, v_e1, v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Volver a agregar a quien se retiró', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Volver a agregar: se reactiva la MISMA fila', v_p1::TEXT, v_dummy::TEXT, 'no se duplica');
    PERFORM pg_temp.chk('Volver a agregar: parte de cero, PENDIENTE', 'PENDIENTE|AGREGADA', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Origen" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p1), 'no hereda la aprobación anterior');

    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(pg_temp.sp(v_a, v_e4), v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Retirar: no se retira a la última persona', '101', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Persona" SET "Aprobacion" = 'APROBADA', "Estado" = 'DENTRO' WHERE "ID_Solicitud_Persona" = v_p4;
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_p4, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Retirar: quien ya ingresó no se retira', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Persona" SET "Aprobacion" = 'PENDIENTE', "Estado" = 'ESPERADA' WHERE "ID_Solicitud_Persona" = v_p4;

    -- ===================================================== F. AGREGAR_APROBADA (quien aprueba agrega a quien llegó sin estar)
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA"(v_s1, v_e6, v_u_sol, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar aprobada: el solicitante no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA"(v_s1, v_e6, v_u_alm, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar aprobada: el aprobador de almacén no decide pasos de este flujo', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA"(v_s1, v_e1, v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar aprobada: quien ya está en la solicitud', '101', v_cod::TEXT, v_msg);
    SELECT "ID_Solicitud_Persona" INTO v_dummy FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_s1 AND "ID_Persona_Externa" = v_e6;
    UPDATE "CAF_Solicitud_Persona" SET "Aprobacion" = 'RETIRADA' WHERE "ID_Solicitud_Persona" = v_dummy;
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_dummy, v_u_sol, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000007','Nueva','Persona','Julia',0, v_d, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA"(v_s1, v_d, v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar aprobada: el Coordinador agrega a quien llegó', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Agregar aprobada: queda APROBADA al instante', 'APROBADA|AGREGADA_COORDINADOR', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Origen" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p5), 'resuelve el caso del teléfono');
    PERFORM pg_temp.chk('Agregar aprobada: deja el evento', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Accion" = ''AGREGAR_APROBADA'''), '');
    PERFORM pg_temp.chk('Agregar aprobada: avisa al solicitante', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Asunto" LIKE ''Se agregó a una persona%'''), '');

    -- ===================================================== G. EDITAR los datos de la visita
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Editable S.A.C.', v_mot, NULL, 'Primera versión', v_z_adm::TEXT, v_e1 || ',' || v_e2, 'a@ejemplo.pe', NULL, v_u_sol, v_s2, v_cs, v_cod, v_msg);
    v_a := pg_temp.sp(v_s2, v_e1); v_b := pg_temp.sp(v_s2, v_e2);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_ext, 'APROBADA', NULL, v_a || ',' || v_b, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: preparación, solicitud aprobada', 'APROBADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), 'las 2 personas aprobadas');

    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm::TEXT, NULL, v_u_sol2, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: otro solicitante no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_pas, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm::TEXT, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: la nueva fecha no puede ser anterior a hoy', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot_otro, NULL, 'x', v_z_adm::TEXT, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: motivo «Otro» sin describir', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: sin zonas', '400', v_cod::TEXT, v_msg);

    SELECT "Fecha_Hora_Prevista" INTO v_fut FROM "CAF_Solicitud" WHERE "ID_Solicitud" = v_s2;
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'Segunda versión de las observaciones', v_z_adm::TEXT, 'a@ejemplo.pe, b@ejemplo.pe', v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: solo observaciones y copias', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Editar: eso NO reabre la aprobación', 'N', v_reab::TEXT, 'no cambia lo autorizado');
    PERFORM pg_temp.chk('Editar: las personas siguen APROBADAS', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Aprobacion" = ''APROBADA'''), '');
    PERFORM pg_temp.chk('Editar: la versión no sube', '1', pg_temp.q('SELECT "Version" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), '');
    PERFORM pg_temp.chk('Editar: las copias quedan como se indicó', 'a@ejemplo.pe,b@ejemplo.pe', pg_temp.q('SELECT STRING_AGG("Correo", '','' ORDER BY "Correo") FROM "CAF_Solicitud_Copia_Correo" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Eliminado" = ''N'''), '');

    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut + INTERVAL '90 minutes', 'Editable S.A.C.', v_per, v_mot, NULL, 'Segunda versión de las observaciones', v_z_adm::TEXT, 'a@ejemplo.pe', v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: cambiar la hora', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Editar: cambiar la hora SÍ reabre la aprobación', 'Y', v_reab::TEXT, '');
    PERFORM pg_temp.chk('Editar: la versión sube a 2', '2', pg_temp.q('SELECT "Version" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), '');
    PERFORM pg_temp.chk('Editar: las personas vuelven a PENDIENTE con origen REABIERTA', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Aprobacion" = ''PENDIENTE'' AND "Origen" = ''REABIERTA'''), '');
    PERFORM pg_temp.chk('Editar: la solicitud vuelve a PENDIENTE', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), 'Vigilancia deja de verlas hasta que se apruebe');
    PERFORM pg_temp.chk('Editar: las aprobaciones anteriores quedan en el historial', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Decision" WHERE "ID_Solicitud_Persona" IN (' || v_a || ',' || v_b || ') AND "Vigente" = ''N'' AND "Decision" = ''APROBADA'''), 'nada se borra');
    PERFORM pg_temp.chk('Editar: el evento describe el cambio', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Accion" = ''EDITAR'' AND "Detalle" LIKE ''%Visita%→%'''), '');
    PERFORM pg_temp.chk('Editar: avisa que hay personas por aprobar', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Tipo" = ''SOLICITUD_EDITADA'''), '');
    PERFORM pg_temp.chk('Editar: la foto de lo aprobado de la versión 1 se conserva', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Version" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Version" = 1'), 'RN-08');

    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_ext, 'APROBADA', NULL, v_a::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_ext, 'OBSERVADA', 'Falta el nombre completo.', v_b::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    SELECT "Fecha_Hora_Prevista" INTO v_fut FROM "CAF_Solicitud" WHERE "ID_Solicitud" = v_s2;
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm || ',' || v_z_pt, 'a@ejemplo.pe', v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: agregar una zona reabre', 'Y', v_reab::TEXT, '');
    PERFORM pg_temp.chk('Editar: la aprobada vuelve a PENDIENTE', 'PENDIENTE', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_a), '');
    PERFORM pg_temp.chk('Editar: la observada CONSERVA su observación', 'OBSERVADA|Falta el nombre completo.', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Aprobacion_Mensaje" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_b), 'depende del solicitante, no se reabre');
    PERFORM pg_temp.chk('Editar: ahora la solicitud exige SCTR', 'Y', pg_temp.q('SELECT "Exige_SCTR" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), 'se recalcula desde las zonas');
    PERFORM pg_temp.chk('Editar: la zona nueva quedó asociada', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Zona" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Eliminado" = ''N'''), '');
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_1p::TEXT, 'a@ejemplo.pe', v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: cambiar de zona (se retira una y entra otra)', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Editar: queda una sola zona vigente', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Zona" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Eliminado" = ''N'''), '');
    PERFORM pg_temp.chk('Editar: la zona retirada se conserva marcada, no se borra', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Zona" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Eliminado" = ''Y'''), '');
    PERFORM pg_temp.chk('Editar: sin zonas operativas ya no exige SCTR', 'N', pg_temp.q('SELECT "Exige_SCTR" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), '');
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm || ',' || v_z_1p, 'a@ejemplo.pe', v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: volver a una zona retirada la reactiva', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Zona" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Eliminado" = ''N'''), 'misma fila, sin duplicar');

    -- Con alguien dentro, los datos de la visita no se cambian
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_hoy, 'Hoy S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1 || ',' || v_e2, NULL, NULL, v_u_sol, v_s3, v_cs, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s3, v_paso_ext, 'APROBADA', NULL, pg_temp.sp(v_s3, v_e1) || ',' || pg_temp.sp(v_s3, v_e2), v_u_coo, v_cant, v_cod, v_msg);
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'DENTRO', "Fecha_Hora_Ingreso" = CURRENT_TIMESTAMP WHERE "ID_Solicitud_Persona" = pg_temp.sp(v_s3, v_e1);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s3, v_hoy, 'Hoy S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm::TEXT, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: con alguien dentro no se editan los datos', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_s3, 'x', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar: con alguien dentro no se cancela', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s3, v_e4, v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar: con alguien dentro SÍ se puede agregar personal', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(pg_temp.sp(v_s3, v_e2), v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Retirar: con alguien dentro SÍ se retira a quien falta', '100', v_cod::TEXT, v_msg);

    -- Fecha pasada: nada se modifica
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_pas WHERE "ID_Solicitud" = v_s2;
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm::TEXT, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: la fecha de la visita ya pasó', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s2, v_e5, v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar: la fecha de la visita ya pasó', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_s2, 'x', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar: la fecha de la visita ya pasó', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_ext, 'APROBADA', NULL, v_a::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: la fecha de la visita ya pasó', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_fut WHERE "ID_Solicitud" = v_s2;

    -- ===================================================== H. CANCELAR
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_s2, 'La empresa reprogramó.', v_u_sol2, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar: otro solicitante no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(999999, 'x', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar: solicitud inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_ext, 'APROBADA', NULL, v_a::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_s2, 'La empresa reprogramó.', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar: correcta', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Cancelar: estado CANCELADA con su motivo', 'CANCELADA|La empresa reprogramó.', pg_temp.q('SELECT "Estado" || ''|'' || "Motivo_Cancelacion" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), 'no se borra');
    PERFORM pg_temp.chk('Cancelar: deja el evento', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Accion" = ''CANCELAR'''), '');
    PERFORM pg_temp.chk('Cancelar: con una persona autorizada avisa a aprobadores y Vigilancia', 'roberto@ejemplo.pe; maria@ejemplo.pe', pg_temp.q('SELECT "Destinatarios" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Tipo" = ''SOLICITUD_CANCELADA'''), 'primero los aprobadores, luego portería');
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_s2, 'x', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar: dos veces', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm::TEXT, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelada: no se edita', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s2, v_e5, v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelada: no se agregan personas', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_b, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelada: no se retiran personas', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_ext, 'APROBADA', NULL, v_b::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelada: no se decide', '409', v_cod::TEXT, v_msg);

    -- ===================================================== I. FLUJO DE VARIOS PASOS (contratista, solo con datos)
    UPDATE "Catalogo_Tipo_Acceso" SET "Disponible" = 'Y' WHERE "ID_Catalogo_Tipo_Acceso" = v_con;
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_con, v_per, v_fut, 'Contratista S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: un tipo sin pasos configurados no admite solicitudes', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_con, 1, 'DOCUMENTOS', 'Revisión de documentos', 'PERSONA',   'ROL', v_lic_coo, 'SIEMPRE', 'Y', 0, v_paso_doc,    v_cod, v_msg);
    CALL "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_con, 1, 'SERVICIO',   'Aprobación del servicio', 'SOLICITUD', 'ROL', v_lic_alm, 'SIEMPRE', 'Y', 0, v_paso_serv,   v_cod, v_msg);
    CALL "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_con, 2, 'CIERRE',     'Visto bueno final',       'PERSONA',   'ROL', v_lic_coo, 'SIEMPRE', 'Y', 0, v_paso_cierre, v_cod, v_msg);

    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_con, v_per, v_fut, 'Contratista S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1 || ',' || v_e2 || ',' || v_e3, NULL, NULL, v_u_sol, v_c, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: se crea el flujo de 3 pasos', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Varios pasos: avisa a los DOS roles del primer orden (en paralelo)', 'jorge@ejemplo.pe; roberto@ejemplo.pe', pg_temp.q('SELECT "Destinatarios" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_c || ' AND "Tipo" = ''SOLICITUD_NUEVA'''), '');
    v_p1 := pg_temp.sp(v_c, v_e1); v_p2 := pg_temp.sp(v_c, v_e2); v_p3 := pg_temp.sp(v_c, v_e3);

    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_c, v_paso_cierre, 'APROBADA', NULL, v_p1::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: no se salta el orden (el paso 2 antes que el 1)', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_c, v_paso_doc, 'APROBADA', NULL, v_p1 || ',' || v_p2, v_u_alm, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: cada rol decide solo SU paso', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_c, v_paso_ext, 'APROBADA', NULL, v_p1::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: un paso de otro tipo de acceso se rechaza', '400', v_cod::TEXT, v_msg);

    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_c, v_paso_doc, 'APROBADA', NULL, v_p1 || ',' || v_p2, v_u_coo, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_c, v_paso_doc, 'OBSERVADA', 'SCTR vencido.', v_p3::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: tras el paso 1 nadie está aprobado todavía', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_c), 'faltan los otros pasos');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_c, v_paso_serv, 'APROBADA', NULL, NULL, v_u_alm, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: el paso por solicitud vale para las que están pendientes', '2', v_cant::TEXT, 'la observada queda fuera hasta que se reenvíe');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_c, v_paso_serv, 'APROBADA', NULL, NULL, v_u_alm, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: ya no quedan pendientes en ese paso', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Varios pasos: con los pasos 1 y 2 todavía falta el 3', 'PENDIENTE', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p1), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_c, v_paso_cierre, 'APROBADA', NULL, v_p1 || ',' || v_p2, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: con los 3 pasos queda APROBADA', 'APROBADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p1), '');
    PERFORM pg_temp.chk('Varios pasos: la solicitud queda APROBADA_PARCIAL (la tercera sigue observada)', 'APROBADA_PARCIAL', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_c), '');

    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR"(v_p3, v_e3, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: reenviar a la observada', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Varios pasos: reabre solo su paso por persona; conserva lo de la solicitud', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Decision" WHERE "ID_Solicitud_Persona" = ' || v_p3 || ' AND "Vigente" = ''Y'''), 'nunca tuvo la del servicio: estaba observada');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_c, v_paso_doc, 'APROBADA', NULL, v_p3::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_c, v_paso_serv, 'APROBADA', NULL, NULL, v_u_alm, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: el servicio se decide también para la reenviada', '1', v_cant::TEXT, '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_c, v_paso_cierre, 'APROBADA', NULL, v_p3::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: todas decididas, la solicitud queda APROBADA', 'APROBADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_c), '');

    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_c, v_e4, v_u_sol, v_p4, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: quien llega después HEREDA el paso por solicitud', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Decision" WHERE "ID_Solicitud_Persona" = ' || v_p4 || ' AND "ID_Tipo_Acceso_Paso_Aprobacion" = ' || v_paso_serv || ' AND "Vigente" = ''Y'''), 'no vuelve a pasar por el área');
    PERFORM pg_temp.chk('Varios pasos: solo le faltan los pasos que dependen de ella', 'PENDIENTE', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p4), '');
    PERFORM pg_temp.chk('Varios pasos: avisa solo a quien decide su paso pendiente', 'roberto@ejemplo.pe', pg_temp.q('SELECT "Destinatarios" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_c || ' AND "Tipo" = ''PERSONA_POR_APROBAR'' ORDER BY "ID_Correo_Pendiente" DESC LIMIT 1'), 'no al área, que ya aprobó');
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA"(v_c, v_e5, v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: quien decide 2 pasos aprueba a quien llegó en ambos, en orden', 'APROBADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p5), 'hereda el servicio');
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000008','Otra','Visita','Pilar',0, v_dummy, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA"(v_c, v_dummy, v_u_alm, v_d, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: el área agrega a alguien; solo hereda el suyo', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Varios pasos: y le faltan los pasos de otros roles', 'PENDIENTE', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_d), '');

    SELECT "Fecha_Hora_Prevista" INTO v_fut FROM "CAF_Solicitud" WHERE "ID_Solicitud" = v_c;
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_c, v_fut + INTERVAL '1 hour', 'Contratista S.A.C.', v_per, v_mot, NULL, NULL, v_z_adm::TEXT, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: cambiar la hora reabre TAMBIÉN los pasos por solicitud', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Decision" WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = ' || v_paso_serv || ' AND "Vigente" = ''Y'' AND "ID_Solicitud_Persona" IN (SELECT "ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_c || ')'), 'el área vuelve a aprobar el servicio');
    PERFORM pg_temp.chk('Varios pasos: todas las personas vuelven a PENDIENTE', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_c || ' AND "Aprobacion" = ''APROBADA'''), '');

    -- ===================================================== J. REUTILIZAR («Basada en SOL-xxx»)
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Reutilizada S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, v_s1, v_u_sol, v_a, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Reutilizar: nace como solicitud nueva, pendiente', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Reutilizar: guarda de cuál se tomó', v_s1::TEXT, pg_temp.q('SELECT "ID_Solicitud_Origen" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_a), 'solo trazabilidad');
    PERFORM pg_temp.chk('Reutilizar: tiene su propio código y su propia aprobación', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_a), '');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Reutilizada S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, v_s1, v_u_sol2, v_b, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Reutilizar: no se puede tomar la solicitud de otro usuario', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Reutilizada S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, 999999, v_u_sol, v_b, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Reutilizar: origen inexistente', '101', v_cod::TEXT, v_msg);

    -- ===================================================== K. FLUJO QUE NO REQUIERE APROBACIÓN
    UPDATE "Catalogo_Tipo_Acceso" SET "Disponible" = 'Y', "Requiere_Aprobacion" = 'N' WHERE "ID_Catalogo_Tipo_Acceso" = v_int;
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_int, v_per, v_fut, 'Interno', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, v_u_sol, v_d, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Sin aprobación: se crea', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Sin aprobación: las personas nacen APROBADAS', 'APROBADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_d), 'no hay a quién esperar');
    PERFORM pg_temp.chk('Sin aprobación: la solicitud queda APROBADA', 'APROBADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_d), '');
    PERFORM pg_temp.chk('Sin aprobación: no se pide aprobación a nadie por correo', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_d), '');
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Nota"
  FROM pruebas WHERE esperado <> obtenido ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
