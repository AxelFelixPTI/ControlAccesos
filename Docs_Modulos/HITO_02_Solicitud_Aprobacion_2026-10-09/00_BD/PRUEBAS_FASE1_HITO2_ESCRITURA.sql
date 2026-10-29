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

-- Aísla la prueba de los usuarios de demostración de 11_SEED_DEMO_USUARIOS.sql (todo se deshace con el ROLLBACK final):
-- las pruebas cuentan quién recibe los avisos y quién es Coordinador, y esperan una base sin esos usuarios.
DELETE FROM "CAF_GOVERNANCE"."Usuario_Licencia" WHERE "ID_Usuario" IN (SELECT "ID_Usuario" FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" LIKE '%@trianon.test');
DELETE FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" LIKE '%@trianon.test';

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
    v_ad BIGINT; v_ad1 BIGINT; v_ad2 BIGINT; v_ad3 BIGINT; v_adsp BIGINT;
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
    PERFORM pg_temp.chk('Crear: en Copia van el solicitante y los correos del asistente', 'carlos@ejemplo.pe; almacen@ejemplo.pe; gerencia@ejemplo.pe', pg_temp.q('SELECT "Copia" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_NUEVA'''), '');

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
    PERFORM pg_temp.chk('Vigilancia: observar o rechazar NO genera aviso de ingreso (sin aprobadas no hay aviso vacío)', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_VIGILANCIA'' AND ("IDs_Personas" LIKE ''%'' || ' || v_p2 || ' || ''%'' OR "IDs_Personas" LIKE ''%'' || ' || v_p3 || ' || ''%'')'), 'las personas no aprobadas no aparecen');
    PERFORM pg_temp.chk('Vigilancia: aviso solo con las aprobadas (no más avisos que decisiones aprobadas)', 'true', pg_temp.q('SELECT ((SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_VIGILANCIA'') <= (SELECT COUNT(DISTINCT D."ID_Solicitud_Persona") FROM "CAF_Solicitud_Decision" D JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = D."ID_Solicitud_Persona" WHERE P."ID_Solicitud" = ' || v_s1 || ' AND D."Decision" = ''APROBADA''))::TEXT'), '');
    PERFORM pg_temp.chk('Decidir: rechaza a la tercera', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Decidir: queda RECHAZADA con su motivo', 'RECHAZADA|No autorizado por seguridad.', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Aprobacion_Mensaje" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p3), '');
    PERFORM pg_temp.chk('Decidir: con una observada sigue APROBADA_PARCIAL', 'APROBADA_PARCIAL', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, v_p2::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: una persona observada no se decide hasta que se reenvíe', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, pg_temp.sp(v_a, v_e4)::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Decidir: no se decide sobre personas de otra solicitud', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Decidir: 3 eventos en la bitácora (aprobar, observar, rechazar)', 'APROBAR,OBSERVAR,RECHAZAR', pg_temp.q('SELECT STRING_AGG("Accion", '','' ORDER BY "ID_Evento") FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Entidad" = ''SOLICITUD_DECISION'''), '');
    PERFORM pg_temp.chk('Decidir: las decisiones de una misma revisión se avisan en UN solo correo al solicitante (D-182)', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_DECISION'' AND "Destinatarios" = ''carlos@ejemplo.pe'''), '');
    PERFORM pg_temp.chk('Decidir: el aviso al solicitante copia a los aprobadores y a los correos del asistente', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_DECISION'' AND "Copia" LIKE ''roberto@ejemplo.pe; almacen@ejemplo.pe; gerencia@ejemplo.pe%'''), 'Vigilancia ya no va en esta copia (D-181)');
    PERFORM pg_temp.chk('Correo: datos de la plantilla solo para el sistema', '0|1', pg_temp.q('SELECT (SELECT COUNT(*) FROM "ERP_CAF_CORREO_SOLICITUD_DATOS"(2, ' || v_s1 || ')) || ''|'' || (SELECT COUNT(*) FROM "ERP_CAF_CORREO_SOLICITUD_DATOS"(0, ' || v_s1 || '))'), '');
    PERFORM pg_temp.chk('Correo: personas de la plantilla', '1', pg_temp.q('SELECT CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END FROM "ERP_CAF_CORREO_SOLICITUD_PERSONAS"(0, ' || v_s1 || ')'), '');
    -- D-179 / D-180: asunto estable del hilo y a quién llega «Responder»
    PERFORM pg_temp.chk('Hilo: el aviso de solicitud nueva guarda el asunto «Solicitud código · empresa»', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" C JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = C."ID_Solicitud" WHERE C."ID_Solicitud" = ' || v_s1 || ' AND C."Tipo" = ''SOLICITUD_NUEVA'' AND C."Asunto" = ''Solicitud '' || S."Codigo" || '' · '' || S."Empresa_Visitante"'), '');
    PERFORM pg_temp.chk('Hilo: la plantilla recibe ese asunto', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_SOLICITUD_DATOS"(0, ' || v_s1 || ') D WHERE D."Asunto_Hilo" = ''Solicitud '' || D."Codigo" || '' · '' || D."Empresa_Visitante"'), '');
    UPDATE "CAF_Solicitud" SET "Empresa_Visitante" = 'Empresa Renombrada S.A.C.' WHERE "ID_Solicitud" = v_s1;
    PERFORM pg_temp.chk('Hilo: si luego cambia la empresa, el asunto del hilo NO cambia', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_SOLICITUD_DATOS"(0, ' || v_s1 || ') D WHERE D."Asunto_Hilo" = ''Solicitud '' || D."Codigo" || '' · Energía Verde S.A.C.'' AND D."Empresa_Visitante" = ''Empresa Renombrada S.A.C.'''), '');
    UPDATE "CAF_Solicitud" SET "Empresa_Visitante" = 'Energía Verde S.A.C.' WHERE "ID_Solicitud" = v_s1;
    PERFORM pg_temp.chk('Hilo: el aviso nuevo se responde a quien creó la solicitud (solicitante)', 'carlos@ejemplo.pe', pg_temp.q('SELECT "Responder_A" FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, 100) WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_NUEVA'''), '');
    PERFORM pg_temp.chk('Hilo: el aviso de una decisión se responde al Coordinador que decidió', 'roberto@ejemplo.pe', pg_temp.q('SELECT DISTINCT "Responder_A" FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, 100) WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_DECISION'''), '');
    PERFORM pg_temp.chk('Hilo: el nombre visible es nombre y apellido paterno', 'Roberto Coordinador', pg_temp.q('SELECT DISTINCT "Responder_A_Nombre" FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, 100) WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_DECISION'''), '');
    PERFORM pg_temp.chk('Hilo: los correos sin solicitud no llevan «responder a»', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, 100) WHERE "ID_Solicitud" IS NULL AND "Responder_A" IS NOT NULL'), '');
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

    -- ===================================================== F. CORRECCIÓN DE EMERGENCIA: agregar (D-169, P-98)
    -- Solo vale sobre una solicitud ya aprobada, con sustento y hasta el día de la visita.
    PERFORM pg_temp.chk('Emergencia: el procedimiento anterior (agregar aprobada) ya no existe', '0', pg_temp.q('SELECT COUNT(*) FROM pg_proc WHERE proname = ''ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA'''), 'no puede convivir con la aprobación normal');
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e6, 'Llegó sin avisar', v_u_sol, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: el solicitante no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e6, 'Llegó sin avisar', v_u_alm, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: el aprobador de almacén no decide pasos de este flujo', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_a, v_e6, 'Llegó sin avisar', v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: con la solicitud por decidir no vale', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: la solicitud por decidir sigue PENDIENTE', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_a), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, v_p1::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: preparación, el Coordinador aprueba a una persona', 'APROBADA_PARCIAL', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1), 'ya hay algo aprobado');
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e6, NULL, v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: sin sustento', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e6, '    ', v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: sustento en blanco', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e6, REPEAT('x', 301), v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: sustento de más de 300 caracteres', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e1, 'Llegó sin avisar', v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: quien ya está en la solicitud', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, 888888, 'Llegó sin avisar', v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: persona no registrada', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(999999, v_e6, 'Llegó sin avisar', v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: solicitud inexistente', '404', v_cod::TEXT, v_msg);
    SELECT "ID_Solicitud_Persona" INTO v_dummy FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_s1 AND "ID_Persona_Externa" = v_e6;
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_dummy, v_u_sol, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000007','Nueva','Persona','Julia',0, v_d, v_cod, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_pas WHERE "ID_Solicitud" = v_s1;
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_d, 'Llegó sin avisar', v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: una visita de fecha pasada no se corrige', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_fut WHERE "ID_Solicitud" = v_s1;
    UPDATE "CAF_Solicitud" SET "Estado" = 'CANCELADA' WHERE "ID_Solicitud" = v_s1;
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_d, 'Llegó sin avisar', v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: una solicitud cancelada no se corrige', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Estado" = 'APROBADA_PARCIAL' WHERE "ID_Solicitud" = v_s1;
    PERFORM pg_temp.chk('Emergencia agregar: lo rechazado no dejó nada escrito', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "ID_Persona_Externa" = ' || v_d), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_d, 'Llegó sin avisar', v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: el Coordinador agrega a quien llegó', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: queda APROBADA al instante', 'APROBADA|AGREGADA_COORDINADOR', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Origen" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p5), 'resuelve el caso del teléfono');
    PERFORM pg_temp.chk('Emergencia agregar: la bitácora guarda el sustento', 'Nueva Persona, Julia · Emergencia: Llegó sin avisar', pg_temp.q('SELECT "Detalle" FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Accion" = ''AGREGAR_EMERGENCIA'''), '');
    PERFORM pg_temp.chk('Emergencia agregar: avisa al solicitante y a Vigilancia', 'carlos@ejemplo.pe; maria@ejemplo.pe', pg_temp.q('SELECT "Destinatarios" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_CORRECCION'''), 'Para: solicitante + portería');
    PERFORM pg_temp.chk('Emergencia agregar: en copia el Coordinador y los correos del asistente', 'roberto@ejemplo.pe; almacen@ejemplo.pe; gerencia@ejemplo.pe', pg_temp.q('SELECT "Copia" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_CORRECCION'''), '');
    PERFORM pg_temp.chk('Emergencia agregar: el correo lleva el sustento', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_CORRECCION'' AND "Cuerpo" LIKE ''%Sustento: Llegó sin avisar%'''), '');
    PERFORM pg_temp.chk('Emergencia agregar: Vigilancia ve a la persona al instante', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS"(' || v_u_vig || ', ' || v_ves || ', NULL, NULL, ''julia'')'), 'su lista sale de las personas aprobadas');
    PERFORM pg_temp.chk('Emergencia agregar: el historial lo muestra', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "Accion_Texto" = ''Agregó a una persona (corrección de emergencia)'''), '');

    -- ===================================================== F2. CORRECCIÓN DE EMERGENCIA: quitar
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: el solicitante no puede por esta vía', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', v_u_alm, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: el aprobador de almacén no decide pasos de este flujo', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, NULL, v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: sin sustento', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(999999, 'Ya no viene', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: persona inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p4, 'Ya no viene', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: una persona pendiente se resuelve con la decisión normal', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'DENTRO' WHERE "ID_Solicitud_Persona" = v_p5;
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: quien ya ingresó no se quita', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: el mensaje indica registrar la salida con observación', '1', pg_temp.q('SELECT CASE WHEN ''' || v_msg || ''' LIKE ''%salida%observación%'' THEN 1 ELSE 0 END'), '');
    PERFORM pg_temp.chk('Emergencia quitar: la persona que ingresó sigue autorizada', 'APROBADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p5), '');
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'ESPERADA' WHERE "ID_Solicitud_Persona" = v_p5;
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_pas WHERE "ID_Solicitud" = v_s1;
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: una visita de fecha pasada no se corrige', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_fut WHERE "ID_Solicitud" = v_s1;
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: el Coordinador quita a una autorizada que no ingresó', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: queda RETIRADA, no se borra', 'RETIRADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p5), '');
    PERFORM pg_temp.chk('Emergencia quitar: sus decisiones dejan de ser vigentes', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Decision" WHERE "ID_Solicitud_Persona" = ' || v_p5 || ' AND "Vigente" = ''Y'''), '');
    PERFORM pg_temp.chk('Emergencia quitar: la bitácora guarda el sustento', 'Nueva Persona, Julia · Emergencia: Ya no viene', pg_temp.q('SELECT "Detalle" FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Accion" = ''RETIRAR_EMERGENCIA'''), '');
    PERFORM pg_temp.chk('Emergencia quitar: avisa al solicitante y a Vigilancia', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_CORRECCION'' AND "Destinatarios" = ''carlos@ejemplo.pe; maria@ejemplo.pe'''), 'uno al agregar y otro al quitar');
    PERFORM pg_temp.chk('Emergencia quitar: Vigilancia ya no la ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS"(' || v_u_vig || ', ' || v_ves || ', NULL, NULL, ''julia'')'), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: dos veces', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_a, v_paso_ext, 'APROBADA', NULL, pg_temp.sp(v_a, v_e4)::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), 'Ya no viene', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: no se quita a la única persona de la solicitud', '101', v_cod::TEXT, v_msg);

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
    -- ---- Entrega F (D-181, D-182): aviso a Vigilancia en aprobación parcial y un solo aviso de decisión
    PERFORM pg_temp.chk('Vigilancia: la aprobación parcial genera 1 aviso a Vigilancia', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Tipo" = ''SOLICITUD_VIGILANCIA'''), 'antes solo si la solicitud completa quedaba APROBADA');
    PERFORM pg_temp.chk('Vigilancia: de las personas del aviso solo sigue aprobada la que corresponde (el envío filtra por esto)', v_a::TEXT, pg_temp.q('SELECT STRING_AGG(CAST(P."ID_Solicitud_Persona" AS VARCHAR), '','') FROM "CAF_Solicitud_Persona" P JOIN "CAF_Correo_Pendiente" C ON C."ID_Solicitud" = P."ID_Solicitud" AND C."Tipo" = ''SOLICITUD_VIGILANCIA'' WHERE P."Aprobacion" = ''APROBADA'' AND P."Eliminado" = ''N'' AND CAST(P."ID_Solicitud_Persona" AS VARCHAR) = ANY (string_to_array(C."IDs_Personas", '','')) AND P."ID_Solicitud" = ' || v_s2), 'la observada ya no cuenta aunque la aprobaron antes de la edición');
    PERFORM pg_temp.chk('Vigilancia: el aviso va a quienes registran en portería', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Tipo" = ''SOLICITUD_VIGILANCIA'' AND "Destinatarios" IS NOT NULL AND LENGTH("Destinatarios") > 3'), '');
    PERFORM pg_temp.chk('Vigilancia: queda en la cola con estado PENDIENTE (evidencia)', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Tipo" = ''SOLICITUD_VIGILANCIA'''), '');
    PERFORM pg_temp.chk('Vigilancia: el aviso de decisión ya no copia a Vigilancia', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" C WHERE C."ID_Solicitud" = ' || v_s2 || ' AND C."Tipo" = ''SOLICITUD_DECISION'' AND C."Copia" LIKE ''%'' || (SELECT MAX(D."Destinatarios") FROM "CAF_Correo_Pendiente" D WHERE D."ID_Solicitud" = ' || v_s2 || ' AND D."Tipo" = ''SOLICITUD_VIGILANCIA'') || ''%'''), '');
    PERFORM pg_temp.chk('Unificar: aprobar y observar en la misma revisión deja UN aviso de decisión', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Tipo" = ''SOLICITUD_DECISION'' AND "Cuerpo" LIKE ''%aprobada(s)%'' AND "Cuerpo" LIKE ''%Además: 1 persona observada(s).%'''), 'la misma cabecera una sola vez');
    PERFORM pg_temp.chk('Unificar: el aviso consolidado lleva el motivo de la observación', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Tipo" = ''SOLICITUD_DECISION'' AND "Cuerpo" LIKE ''%Falta el nombre completo.%'''), '');
    PERFORM pg_temp.chk('Observaciones: cada persona conserva su propia observación', 'OBSERVADA|Falta el nombre completo.', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Aprobacion_Mensaje" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_b), '');
    PERFORM pg_temp.chk('Observaciones: la persona aprobada no hereda la observación', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_a || ' AND "Aprobacion" = ''APROBADA'' AND "Aprobacion_Mensaje" IS NULL'), '');
    UPDATE "CAF_Correo_Pendiente" SET "Estado" = 'ENVIADO', "Fecha_Envio" = CURRENT_TIMESTAMP WHERE "ID_Solicitud" = v_s2 AND "Tipo" IN ('SOLICITUD_DECISION','SOLICITUD_VIGILANCIA');
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
    PERFORM pg_temp.chk('Decidir: Vigilancia recibe su aviso propio (portería) al aprobarse personas', '1', pg_temp.q('SELECT CASE WHEN COUNT(*) >= 1 THEN 1 ELSE 0 END FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Tipo" = ''SOLICITUD_VIGILANCIA'' AND "Destinatarios" LIKE ''%maria@ejemplo.pe%'''), 'Vigilancia = portería');
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
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_c, v_e5, 'Prueba de varios pasos', v_u_coo, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: quien decide 2 pasos aprueba a quien llegó en ambos, en orden', 'APROBADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p5), 'hereda el servicio');
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000008','Otra','Visita','Pilar',0, v_dummy, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_c, v_dummy, 'Prueba de varios pasos', v_u_alm, v_d, v_cod, v_msg);
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

    -- ===================================================== L. AUTOCOMPLETAR EMPRESA
    PERFORM pg_temp.chk('Empresas: encuentra "Reutilizada" sin distinguir mayúsculas', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_EMPRESAS_BUSCAR"(''reutiliz'')'), '');
    PERFORM pg_temp.chk('Empresas: texto sin coincidencias devuelve vacío', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_EMPRESAS_BUSCAR"(''zzzzqq'')'), '');
    PERFORM pg_temp.chk('Empresas: máximo 10 resultados', 'true', pg_temp.q('SELECT (COUNT(*) <= 10)::TEXT FROM "ERP_CAF_SOLICITUD_EMPRESAS_BUSCAR"(NULL)'), '');
    PERFORM pg_temp.chk('Empresas: sin repetidos aunque cambie la mayúscula', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_EMPRESAS_BUSCAR"(''interno'')'), '');

    -- ===================================================== M. DOCUMENTOS ADJUNTOS (Entrega J, D-183 y D-184)
    UPDATE "Catalogo_Tipo_Acceso" SET "Disponible" = 'Y', "Requiere_Aprobacion" = 'Y' WHERE "ID_Catalogo_Tipo_Acceso" = v_ext;
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Con documentos S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT || ',' || v_e2::TEXT, NULL, NULL, v_u_sol, v_ad, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: se prepara una solicitud nueva', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'C:\Users\ana\SCTR vigente.PDF', 'application/pdf', convert_to('%PDF-1.4 sctr', 'UTF8'), v_u_sol, v_ad1, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: el solicitante adjunta un PDF', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Adjuntos: se guarda solo el nombre del archivo, sin carpetas, y la extensión en minúsculas', 'SCTR vigente.PDF|pdf', pg_temp.q('SELECT "Nombre_Archivo" || ''|'' || "Extension" FROM "CAF_Solicitud_Adjunto" WHERE "ID_Solicitud_Adjunto" = ' || v_ad1), '');
    PERFORM pg_temp.chk('Adjuntos: se guarda el tamaño y la huella SHA-256', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Adjunto" WHERE "ID_Solicitud_Adjunto" = ' || v_ad1 || ' AND "Tamano_Bytes" = 13 AND LENGTH("Hash_SHA256") = 64'), '');
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'otro.pdf', 'application/pdf', convert_to('%PDF-1.4 sctr', 'UTF8'), v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: no se adjunta dos veces el mismo contenido', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'virus.exe', 'application/octet-stream', convert_to('MZ binario', 'UTF8'), v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: una extensión no permitida se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'sin_extension', 'application/pdf', convert_to('%PDF', 'UTF8'), v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: un archivo sin extensión se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'vacio.pdf', 'application/pdf', ''::bytea, v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: un archivo vacío se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'grande.pdf', 'application/pdf', convert_to(REPEAT('a', 5242881), 'UTF8'), v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: más de 5 MB se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'otro_usuario.pdf', 'application/pdf', convert_to('%PDF otro', 'UTF8'), v_u_sol2, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: otro solicitante no puede adjuntar a una solicitud ajena', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(999999, 'x.pdf', 'application/pdf', convert_to('%PDF x', 'UTF8'), v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: solicitud inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'planilla.xlsx', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', convert_to('PK planilla', 'UTF8'), v_u_sol, v_ad2, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: el segundo documento se acepta', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'tercero.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', convert_to('PK tercero', 'UTF8'), v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: el tercero se rechaza (máximo 2 por solicitud)', '409', v_cod::TEXT, v_msg);

    PERFORM pg_temp.chk('Adjuntos: el solicitante ve sus 2 documentos', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_sol || ', ' || v_ad || ')'), '');
    PERFORM pg_temp.chk('Adjuntos: el solicitante puede retirarlos mientras edita', 'Y', pg_temp.q('SELECT DISTINCT "Puede_Quitar" FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_sol || ', ' || v_ad || ')'), '');
    PERFORM pg_temp.chk('Adjuntos: Coordinación ve los documentos para revisar', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_coo || ', ' || v_ad || ')'), '');
    PERFORM pg_temp.chk('Adjuntos: Coordinación no puede retirarlos', 'N', pg_temp.q('SELECT DISTINCT "Puede_Quitar" FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_coo || ', ' || v_ad || ')'), '');
    PERFORM pg_temp.chk('Adjuntos: otro solicitante no ve documentos ajenos', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_sol2 || ', ' || v_ad || ')'), '');
    PERFORM pg_temp.chk('Adjuntos: un usuario sin permisos no los ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_nada || ', ' || v_ad || ')'), '');
    PERFORM pg_temp.chk('Adjuntos: no se pueden obtener sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_OBTENER"(' || v_u_sol2 || ', ' || v_ad1 || ')'), '');
    PERFORM pg_temp.chk('Adjuntos: el solicitante obtiene el contenido', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_OBTENER"(' || v_u_sol || ', ' || v_ad1 || ') WHERE LENGTH("Contenido") = 13'), '');

    PERFORM pg_temp.chk('Adjuntos: Vigilancia NO ve documentos si aún no hay personas aprobadas', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_vig || ', ' || v_ad || ')'), '');
    v_adsp := pg_temp.sp(v_ad, v_e1);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_ad, v_paso_ext, 'APROBADA', NULL, v_adsp::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: se aprueba una de las dos personas (aprobación parcial)', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Adjuntos: la otra persona sigue pendiente', 'PENDIENTE', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || pg_temp.sp(v_ad, v_e2)), '');
    PERFORM pg_temp.chk('Adjuntos: Vigilancia ve los 2 documentos desde la primera aprobación parcial', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_vig || ', ' || v_ad || ')'), 'no espera a que toda la solicitud esté aprobada');
    PERFORM pg_temp.chk('Adjuntos: Vigilancia puede obtener el contenido', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_OBTENER"(' || v_u_vig || ', ' || v_ad2 || ')'), '');
    PERFORM pg_temp.chk('Adjuntos: Vigilancia no puede retirarlos', 'N', pg_temp.q('SELECT DISTINCT "Puede_Quitar" FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_vig || ', ' || v_ad || ')'), '');
    PERFORM pg_temp.chk('Adjuntos: la rutina del correo entrega los 2 documentos con contenido', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_CORREO"(0, ' || v_ad || ') WHERE LENGTH("Contenido") > 0'), '');
    PERFORM pg_temp.chk('Adjuntos: la rutina del correo solo la usa el sistema', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_CORREO"(' || v_u_coo || ', ' || v_ad || ')'), '');
    PERFORM pg_temp.chk('Adjuntos: el aviso a Vigilancia queda en la cola para esa solicitud', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_ad || ' AND "Tipo" = ''SOLICITUD_VIGILANCIA'''), 'el envío adjunta los documentos');

    CALL "ERP_CAF_SOLICITUD_ADJUNTO_QUITAR"(v_ad2, v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: Coordinación no puede retirar un documento', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_QUITAR"(v_ad2, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: el solicitante retira un documento', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Adjuntos: el retiro es lógico: el contenido se conserva como evidencia', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Adjunto" WHERE "ID_Solicitud_Adjunto" = ' || v_ad2 || ' AND "Eliminado" = ''Y'' AND LENGTH("Contenido") > 0'), '');
    PERFORM pg_temp.chk('Adjuntos: lo retirado ya no se lista', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_sol || ', ' || v_ad || ')'), '');
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_QUITAR"(v_ad2, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: retirar dos veces el mismo documento da 404', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'tercero.docx', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', convert_to('PK tercero', 'UTF8'), v_u_sol, v_ad3, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: al retirar uno se puede adjuntar otro', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Adjuntos: la bitácora registra los documentos agregados y retirados', '4', pg_temp.q('SELECT COUNT(*) FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_ad || ' AND "Accion" IN (''ADJUNTO_AGREGAR'',''ADJUNTO_QUITAR'')'), '3 agregados y 1 retirado');
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_ad, 'prueba', v_u_sol, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'tarde.pdf', 'application/pdf', convert_to('%PDF tarde', 'UTF8'), v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: en una solicitud cancelada ya no se agregan documentos', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Adjuntos: Vigilancia no ve documentos de una solicitud cancelada', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_vig || ', ' || v_ad || ')'), '');
    -- Correos: retención para dar tiempo a cargar los documentos (D-185)
    PERFORM pg_temp.chk('Correos: con retención de 60 s no sale un aviso recién creado', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, 100, 60) WHERE "ID_Solicitud" = ' || v_ad), '');
    PERFORM pg_temp.chk('Correos: sin retención sí sale', 'true', pg_temp.q('SELECT (COUNT(*) > 0)::TEXT FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, 100) WHERE "ID_Solicitud" = ' || v_ad), '');
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Nota"
  FROM pruebas WHERE esperado <> obtenido ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
