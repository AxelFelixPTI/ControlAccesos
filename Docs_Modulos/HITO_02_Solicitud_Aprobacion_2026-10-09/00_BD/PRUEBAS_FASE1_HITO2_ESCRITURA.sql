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
-- «id:Y,id:N,...» con todos los ítems de la etapa; los códigos de fallan salen en N
CREATE FUNCTION pg_temp.items(p BIGINT, etapa TEXT, eq TEXT, he TEXT, fallan TEXT) RETURNS TEXT LANGUAGE sql
AS $f$ SELECT STRING_AGG(A."ID_Catalogo_Item_Checklist" || ':' || CASE WHEN A."Codigo" = ANY(STRING_TO_ARRAY(fallan, ',')) THEN 'N' ELSE 'Y' END, ',' ORDER BY A."Orden")
         FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(p, etapa, eq, he) A $f$;
-- Verificación de datos conforme (todo en Y) del transportista principal: devuelve «código|resultado»
CREATE FUNCTION pg_temp.verif(p_sp BIGINT, p_u BIGINT) RETURNS TEXT LANGUAGE plpgsql
AS $f$ DECLARE v_r BIGINT; v_d BIGINT; v_x VARCHAR(30); v_c INT; v_m VARCHAR(250);
BEGIN
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(p_sp, pg_temp.items(p_sp, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, p_u, v_r, v_d, v_x, v_c, v_m);
    RETURN v_c::TEXT || '|' || COALESCE(v_x, '');
END $f$;
-- Lleva una entrega ya verificada (EN_ESPERA) a INGRESO: Almacén confirma y Vigilancia valida. Devuelve «c1|c2»
CREATE FUNCTION pg_temp.ingresar(p_sol BIGINT, p_ual BIGINT, p_uvp BIGINT) RETURNS TEXT LANGUAGE plpgsql
AS $f$ DECLARE v_c1 INT; v_c2 INT; v_m VARCHAR(250);
BEGIN
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(p_sol, p_ual, v_c1, v_m);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(p_sol, p_uvp, v_c2, v_m);
    RETURN v_c1::TEXT || '|' || v_c2::TEXT;
END $f$;

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
    v_tr_n BIGINT; v_tr1 TEXT; v_tr2 TEXT; v_ids BIGINT;
    v_mag BIGINT; v_zmag BIGINT; v_ctr BIGINT; v_sc BIGINT; v_sm BIGINT; v_sk BIGINT; v_mcon BIGINT; v_pctr BIGINT;
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
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_con FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'INTERNO_VISITANTE';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_int FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'INTERNO_VISITANTE';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_ctr FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'CONTRATISTA';
    SELECT "ID_Catalogo_Sede" INTO v_mag FROM "Catalogo_Sede" WHERE "Codigo" = 'MAG';
    SELECT "ID_Catalogo_Zona_Acceso" INTO v_zmag FROM "Catalogo_Zona_Acceso" WHERE "Codigo" = 'OFICINAS_ADM' AND "ID_Catalogo_Sede" = v_mag;
    -- Estado de fábrica de los tipos de ingreso (script 16), antes de que otras secciones los cambien
    PERFORM pg_temp.chk('Tipos: «Personal interno visitante» queda oculto (Activo = N)', 'N', pg_temp.q('SELECT "Activo" FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = ''INTERNO_VISITANTE'''), '');
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
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_nada, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: sin permiso', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: Vigilancia no crea solicitudes', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_con, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: tipo de acceso no disponible', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_pas, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: fecha anterior a hoy', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, NULL, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: sin fecha', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, '   ', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: empresa vacía', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, 999999, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: responsable inexistente', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot_otro, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: motivo «Otro» exige describirlo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, NULL, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: sin zonas', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, '999999', v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: zona inexistente', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm || ',' || v_z_adm, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: zona repetida', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: sin personas', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, '888888', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: persona no registrada', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, 'sin-arroba', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: correo en copia inválido', '400', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Crear: lo rechazado no dejó nada escrito', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud"'), 'ninguna solicitud');

    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, 'Traerán un proyector.',
                                   v_z_adm || ',' || v_z_pt, v_e1 || ',' || v_e2 || ',' || v_e3, 'Almacen@Ejemplo.pe; gerencia@ejemplo.pe', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_s1, v_cs, v_cod, v_msg);
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

    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Otra S.A.C.', v_mot_otro, 'Entrega de planos', NULL, v_z_adm::TEXT, v_e4::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_a, v_cs, v_cod, v_msg);
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
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e6, 'Llegó sin avisar', v_u_sol, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: el solicitante no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e6, 'Llegó sin avisar', v_u_alm, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: el aprobador de almacén no decide pasos de este flujo', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_a, v_e6, 'Llegó sin avisar', v_u_coo, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: con la solicitud por decidir no vale', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: la solicitud por decidir sigue PENDIENTE', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_a), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, v_p1::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: preparación, el Coordinador aprueba a una persona', 'APROBADA_PARCIAL', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1), 'ya hay algo aprobado');
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e6, NULL, v_u_coo, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: sin sustento', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e6, '    ', v_u_coo, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: sustento en blanco', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e6, REPEAT('x', 301), v_u_coo, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: sustento de más de 300 caracteres', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_e1, 'Llegó sin avisar', v_u_coo, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: quien ya está en la solicitud', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, 888888, 'Llegó sin avisar', v_u_coo, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: persona no registrada', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(999999, v_e6, 'Llegó sin avisar', v_u_coo, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: solicitud inexistente', '404', v_cod::TEXT, v_msg);
    SELECT "ID_Solicitud_Persona" INTO v_dummy FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_s1 AND "ID_Persona_Externa" = v_e6;
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_dummy, v_u_sol, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000007','Nueva','Persona','Julia',0, v_d, v_cod, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_pas WHERE "ID_Solicitud" = v_s1;
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_d, 'Llegó sin avisar', v_u_coo, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: una visita de fecha pasada no se corrige', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_fut WHERE "ID_Solicitud" = v_s1;
    UPDATE "CAF_Solicitud" SET "Estado" = 'CANCELADA' WHERE "ID_Solicitud" = v_s1;
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_d, 'Llegó sin avisar', v_u_coo, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: una solicitud cancelada no se corrige', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Estado" = 'APROBADA_PARCIAL' WHERE "ID_Solicitud" = v_s1;
    PERFORM pg_temp.chk('Emergencia agregar: lo rechazado no dejó nada escrito', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "ID_Persona_Externa" = ' || v_d), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_s1, v_d, 'Llegó sin avisar', v_u_coo, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: el Coordinador agrega a quien llegó', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Emergencia agregar: queda APROBADA al instante', 'APROBADA|AGREGADA_COORDINADOR', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Origen" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p5), 'resuelve el caso del teléfono');
    PERFORM pg_temp.chk('Emergencia agregar: la bitácora guarda el sustento', 'Nueva Persona, Julia · Emergencia: Llegó sin avisar', pg_temp.q('SELECT "Detalle" FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Accion" = ''AGREGAR_EMERGENCIA'''), '');
    PERFORM pg_temp.chk('Emergencia agregar: avisa al solicitante y a Vigilancia', 'carlos@ejemplo.pe; maria@ejemplo.pe', pg_temp.q('SELECT "Destinatarios" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_CORRECCION'''), 'Para: solicitante + portería');
    PERFORM pg_temp.chk('Emergencia agregar: en copia el Coordinador y los correos del asistente', 'roberto@ejemplo.pe; almacen@ejemplo.pe; gerencia@ejemplo.pe', pg_temp.q('SELECT "Copia" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_CORRECCION'''), '');
    PERFORM pg_temp.chk('Emergencia agregar: el correo lleva el sustento', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_CORRECCION'' AND "Cuerpo" LIKE ''%Sustento: Llegó sin avisar%'''), '');
    PERFORM pg_temp.chk('Emergencia agregar: Vigilancia ve a la persona al instante', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS"(' || v_u_vig || ', ' || v_ves || ', NULL, NULL, ''julia'')'), 'su lista sale de las personas aprobadas');
    PERFORM pg_temp.chk('Emergencia agregar: el historial lo muestra', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ', ' || v_s1 || ') WHERE "Accion_Texto" = ''Agregó a una persona (corrección de emergencia)'''), '');

    -- ===================================================== F2. CORRECCIÓN DE EMERGENCIA: quitar
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', 'N', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: el solicitante no puede por esta vía', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', 'N', v_u_alm, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: el aprobador de almacén no decide pasos de este flujo', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, NULL, 'N', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: sin sustento', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(999999, 'Ya no viene', 'N', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: persona inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p4, 'Ya no viene', 'N', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: una persona pendiente se resuelve con la decisión normal', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'DENTRO' WHERE "ID_Solicitud_Persona" = v_p5;
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', 'N', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: quien ya ingresó no se quita', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: el mensaje indica registrar la salida con observación', '1', pg_temp.q('SELECT CASE WHEN ''' || v_msg || ''' LIKE ''%salida%observación%'' THEN 1 ELSE 0 END'), '');
    PERFORM pg_temp.chk('Emergencia quitar: la persona que ingresó sigue autorizada', 'APROBADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p5), '');
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'ESPERADA' WHERE "ID_Solicitud_Persona" = v_p5;
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_pas WHERE "ID_Solicitud" = v_s1;
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', 'N', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: una visita de fecha pasada no se corrige', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_fut WHERE "ID_Solicitud" = v_s1;
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', 'N', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: el Coordinador quita a una autorizada que no ingresó', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: queda RETIRADA, no se borra', 'RETIRADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p5), '');
    PERFORM pg_temp.chk('Emergencia quitar: sus decisiones dejan de ser vigentes', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Decision" WHERE "ID_Solicitud_Persona" = ' || v_p5 || ' AND "Vigente" = ''Y'''), '');
    PERFORM pg_temp.chk('Emergencia quitar: la bitácora guarda el sustento', 'Nueva Persona, Julia · Emergencia: Ya no viene', pg_temp.q('SELECT "Detalle" FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Accion" = ''RETIRAR_EMERGENCIA'''), '');
    PERFORM pg_temp.chk('Emergencia quitar: avisa al solicitante y a Vigilancia', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_CORRECCION'' AND "Destinatarios" = ''carlos@ejemplo.pe; maria@ejemplo.pe'''), 'uno al agregar y otro al quitar');
    PERFORM pg_temp.chk('Emergencia quitar: Vigilancia ya no la ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS"(' || v_u_vig || ', ' || v_ves || ', NULL, NULL, ''julia'')'), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_p5, 'Ya no viene', 'N', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: dos veces', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_a, v_paso_ext, 'APROBADA', NULL, pg_temp.sp(v_a, v_e4)::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), 'Ya no viene', 'N', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: la única persona exige confirmar el rechazo', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: el aviso dice que la solicitud quedará RECHAZADA', '1', pg_temp.q('SELECT CASE WHEN ''' || v_msg || ''' LIKE ''%quedará RECHAZADA%'' THEN 1 ELSE 0 END'), '');
    PERFORM pg_temp.chk('Emergencia quitar: sin confirmar no se tocó nada', 'APROBADA|APROBADA', pg_temp.q('SELECT SO."Estado" || ''|'' || SP."Aprobacion" FROM "CAF_Solicitud" SO JOIN "CAF_Solicitud_Persona" SP ON SP."ID_Solicitud" = SO."ID_Solicitud" WHERE SP."ID_Solicitud_Persona" = ' || pg_temp.sp(v_a, v_e4)), '');

    -- ===================================================== F3. CORRECCIÓN DE EMERGENCIA: corregir datos (D-215)
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), v_dni, 'Lima', 'Paz', 'Marta Elena', 'Error de digitación', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia corregir: el solicitante no puede por esta vía', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), v_dni, 'Lima', 'Paz', 'Marta Elena', NULL, v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia corregir: sin sustento', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), v_dni, '', 'Paz', 'Marta Elena', 'Error de digitación', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia corregir: apellido paterno obligatorio', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA"(999999, v_dni, 'Lima', 'Paz', 'Marta Elena', 'Error de digitación', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia corregir: persona inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), 999999, 'Lima', 'Paz', 'Marta Elena', 'Error de digitación', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia corregir: tipo de documento inexistente', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), v_dni, 'Lima', 'Paz', 'Marta', 'Error de digitación', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia corregir: sin cambios', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'DENTRO' WHERE "ID_Solicitud_Persona" = pg_temp.sp(v_a, v_e4);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), v_dni, 'Lima', 'Paz', 'Marta Elena', 'Error de digitación', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia corregir: quien ya ingresó no se corrige', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'ESPERADA' WHERE "ID_Solicitud_Persona" = pg_temp.sp(v_a, v_e4);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_pas WHERE "ID_Solicitud" = v_a;
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), v_dni, 'Lima', 'Paz', 'Marta Elena', 'Error de digitación', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia corregir: una visita de fecha pasada no se corrige', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_fut WHERE "ID_Solicitud" = v_a;
    INSERT INTO "CAF_Solicitud_Operacion" ("ID_Solicitud","Estado_Operativo","Activa","UsuarioID_Create") VALUES (v_a, 'EN_ESPERA', 'Y', 0);
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), v_dni, 'Lima', 'Paz', 'Marta Elena', 'Error de digitación', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia corregir: una entrega ya en espera no se modifica', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), 'Ya no viene', 'Y', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia quitar: una entrega ya en espera tampoco se retira', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Operacion" SET "Estado_Operativo" = 'PROGRAMADO' WHERE "ID_Solicitud" = v_a;
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), v_dni, 'Lima', 'Paz', 'Marta Elena', 'Error de digitación', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia corregir: el Coordinador corrige un nombre mal escrito', '100', v_cod::TEXT, v_msg);
    DELETE FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = v_a;
    PERFORM pg_temp.chk('Emergencia corregir: el nombre queda corregido', 'Marta Elena', pg_temp.q('SELECT "Nombres" FROM "CAF_Persona_Externa" WHERE "ID_Persona_Externa" = ' || v_e4), '');
    PERFORM pg_temp.chk('Emergencia corregir: el número de documento no cambia', '71000004', pg_temp.q('SELECT "Numero_Documento" FROM "CAF_Persona_Externa" WHERE "ID_Persona_Externa" = ' || v_e4), '');
    PERFORM pg_temp.chk('Emergencia corregir: sigue APROBADA (la aprobación no se reabre)', 'APROBADA|APROBADA', pg_temp.q('SELECT SO."Estado" || ''|'' || SP."Aprobacion" FROM "CAF_Solicitud" SO JOIN "CAF_Solicitud_Persona" SP ON SP."ID_Solicitud" = SO."ID_Solicitud" WHERE SP."ID_Solicitud_Persona" = ' || pg_temp.sp(v_a, v_e4)), '');
    PERFORM pg_temp.chk('Emergencia corregir: la bitácora guarda el antes, el después y el sustento', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_a || ' AND "Accion" = ''CORREGIR_EMERGENCIA'' AND "Detalle" LIKE ''Antes: Lima Paz, Marta (%Ahora: Lima Paz, Marta Elena (%Emergencia: Error de digitación'''), '');
    PERFORM pg_temp.chk('Emergencia corregir: avisa por correo con el antes y el ahora', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_a || ' AND "Tipo" = ''SOLICITUD_CORRECCION'' AND "Cuerpo" LIKE ''%Antes: Lima Paz, Marta (%Ahora: Lima Paz, Marta Elena (%Sustento: Error de digitación%'''), '');
    PERFORM pg_temp.chk('Emergencia corregir: el historial lo muestra', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ', ' || v_a || ') WHERE "Accion_Texto" = ''Corrigió los datos de una persona (corrección de emergencia)'''), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), v_dni, 'Lima', 'Paz', 'Marta Elena', 'Otra vez', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia corregir: repetir lo mismo es «sin cambios»', '409', v_cod::TEXT, v_msg);

    -- ===================================================== F4. RETIRAR a la única persona = rechazar la solicitud (D-215)
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), 'Ya no viene', 'Y', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia rechazar: el solicitante no puede por esta vía', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), 'Ya no viene', 'Y', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia rechazar: confirmado, la solicitud se rechaza', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Emergencia rechazar: la solicitud queda RECHAZADA (no CANCELADA)', 'RECHAZADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_a), 'cancelar es solo del solicitante');
    PERFORM pg_temp.chk('Emergencia rechazar: la persona queda RETIRADA', 'RETIRADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || pg_temp.sp(v_a, v_e4)), '');
    PERFORM pg_temp.chk('Emergencia rechazar: la bitácora registra el rechazo con el sustento', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_a || ' AND "Entidad" = ''SOLICITUD'' AND "Accion" = ''RECHAZAR_EMERGENCIA'' AND "Detalle" LIKE ''%Emergencia: Ya no viene'''), '');
    PERFORM pg_temp.chk('Emergencia rechazar: el historial lo muestra', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ', ' || v_a || ') WHERE "Accion_Texto" = ''Rechazó la solicitud (se retiró a la única persona)'''), '');
    PERFORM pg_temp.chk('Emergencia rechazar: el correo avisa que la solicitud fue rechazada', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_a || ' AND "Tipo" = ''SOLICITUD_CORRECCION'' AND "Asunto" LIKE ''%la solicitud fue rechazada'' AND "Cuerpo" LIKE ''%quedó RECHAZADA%'''), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(pg_temp.sp(v_a, v_e4), 'Ya no viene', 'Y', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Emergencia rechazar: dos veces', '409', v_cod::TEXT, v_msg);

    -- ===================================================== G. EDITAR los datos de la visita
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Editable S.A.C.', v_mot, NULL, 'Primera versión', v_z_adm::TEXT, v_e1 || ',' || v_e2, 'a@ejemplo.pe', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_s2, v_cs, v_cod, v_msg);
    v_a := pg_temp.sp(v_s2, v_e1); v_b := pg_temp.sp(v_s2, v_e2);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_ext, 'APROBADA', NULL, v_a || ',' || v_b, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: preparación, solicitud aprobada', 'APROBADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), 'las 2 personas aprobadas');

    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: otro solicitante no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_pas, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: la nueva fecha no puede ser anterior a hoy', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot_otro, NULL, 'x', v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: motivo «Otro» sin describir', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: sin zonas', '400', v_cod::TEXT, v_msg);

    SELECT "Fecha_Hora_Prevista" INTO v_fut FROM "CAF_Solicitud" WHERE "ID_Solicitud" = v_s2;
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'Segunda versión de las observaciones', v_z_adm::TEXT, 'a@ejemplo.pe, b@ejemplo.pe', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: solo observaciones y copias', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Editar: eso NO reabre la aprobación', 'N', v_reab::TEXT, 'no cambia lo autorizado');
    PERFORM pg_temp.chk('Editar: las personas siguen APROBADAS', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Aprobacion" = ''APROBADA'''), '');
    PERFORM pg_temp.chk('Editar: la versión no sube', '1', pg_temp.q('SELECT "Version" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), '');
    PERFORM pg_temp.chk('Editar: las copias quedan como se indicó', 'a@ejemplo.pe,b@ejemplo.pe', pg_temp.q('SELECT STRING_AGG("Correo", '','' ORDER BY "Correo") FROM "CAF_Solicitud_Copia_Correo" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Eliminado" = ''N'''), '');

    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut + INTERVAL '90 minutes', 'Editable S.A.C.', v_per, v_mot, NULL, 'Segunda versión de las observaciones', v_z_adm::TEXT, 'a@ejemplo.pe', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
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
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm || ',' || v_z_pt, 'a@ejemplo.pe', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: agregar una zona reabre', 'Y', v_reab::TEXT, '');
    PERFORM pg_temp.chk('Editar: la aprobada vuelve a PENDIENTE', 'PENDIENTE', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_a), '');
    PERFORM pg_temp.chk('Editar: la observada CONSERVA su observación', 'OBSERVADA|Falta el nombre completo.', pg_temp.q('SELECT "Aprobacion" || ''|'' || "Aprobacion_Mensaje" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_b), 'depende del solicitante, no se reabre');
    PERFORM pg_temp.chk('Editar: ahora la solicitud exige SCTR', 'Y', pg_temp.q('SELECT "Exige_SCTR" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), 'se recalcula desde las zonas');
    PERFORM pg_temp.chk('Editar: la zona nueva quedó asociada', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Zona" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Eliminado" = ''N'''), '');
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_1p::TEXT, 'a@ejemplo.pe', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: cambiar de zona (se retira una y entra otra)', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Editar: queda una sola zona vigente', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Zona" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Eliminado" = ''N'''), '');
    PERFORM pg_temp.chk('Editar: la zona retirada se conserva marcada, no se borra', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Zona" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Eliminado" = ''Y'''), '');
    PERFORM pg_temp.chk('Editar: sin zonas operativas ya no exige SCTR', 'N', pg_temp.q('SELECT "Exige_SCTR" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), '');
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm || ',' || v_z_1p, 'a@ejemplo.pe', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: volver a una zona retirada la reactiva', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Zona" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Eliminado" = ''N'''), 'misma fila, sin duplicar');

    -- Con alguien dentro, los datos de la visita no se cambian
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_hoy, 'Hoy S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1 || ',' || v_e2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_s3, v_cs, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s3, v_paso_ext, 'APROBADA', NULL, pg_temp.sp(v_s3, v_e1) || ',' || pg_temp.sp(v_s3, v_e2), v_u_coo, v_cant, v_cod, v_msg);
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'DENTRO', "Fecha_Hora_Ingreso" = CURRENT_TIMESTAMP WHERE "ID_Solicitud_Persona" = pg_temp.sp(v_s3, v_e1);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s3, v_hoy, 'Hoy S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: con alguien dentro no se editan los datos', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_s3, 'x', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar: con alguien dentro no se cancela', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s3, v_e4, v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Agregar: con alguien dentro SÍ se puede agregar personal', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(pg_temp.sp(v_s3, v_e2), v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Retirar: con alguien dentro SÍ se retira a quien falta', '100', v_cod::TEXT, v_msg);

    -- Fecha pasada: nada se modifica
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_pas WHERE "ID_Solicitud" = v_s2;
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
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
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_s2, v_fut, 'Editable S.A.C.', v_per, v_mot, NULL, 'x', v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelada: no se edita', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_s2, v_e5, v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelada: no se agregan personas', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_b, v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelada: no se retiran personas', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_ext, 'APROBADA', NULL, v_b::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelada: no se decide', '409', v_cod::TEXT, v_msg);

    -- ===================================================== I. FLUJO DE VARIOS PASOS (contratista, solo con datos)
    UPDATE "Catalogo_Tipo_Acceso" SET "Disponible" = 'Y', "Activo" = 'Y' WHERE "ID_Catalogo_Tipo_Acceso" = v_con;
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_con, v_per, v_fut, 'Contratista S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: un tipo sin pasos configurados no admite solicitudes', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_con, 1, 'DOCUMENTOS', 'Revisión de documentos', 'PERSONA',   'ROL', v_lic_coo, 'SIEMPRE', 'Y', 0, v_paso_doc,    v_cod, v_msg);
    CALL "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_con, 1, 'SERVICIO',   'Aprobación del servicio', 'SOLICITUD', 'ROL', v_lic_alm, 'SIEMPRE', 'Y', 0, v_paso_serv,   v_cod, v_msg);
    CALL "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR"(v_con, 2, 'CIERRE',     'Visto bueno final',       'PERSONA',   'ROL', v_lic_coo, 'SIEMPRE', 'Y', 0, v_paso_cierre, v_cod, v_msg);

    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_con, v_per, v_fut, 'Contratista S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1 || ',' || v_e2 || ',' || v_e3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_c, v_cs, v_cod, v_msg);
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
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_c, v_e5, 'Prueba de varios pasos', v_u_coo, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_p5, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: quien decide 2 pasos aprueba a quien llegó en ambos, en orden', 'APROBADA', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p5), 'hereda el servicio');
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'71000008','Otra','Visita','Pilar',0, v_dummy, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_c, v_dummy, 'Prueba de varios pasos', v_u_alm, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_d, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: el área agrega a alguien; solo hereda el suyo', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Varios pasos: y le faltan los pasos de otros roles', 'PENDIENTE', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_d), '');

    SELECT "Fecha_Hora_Prevista" INTO v_fut FROM "CAF_Solicitud" WHERE "ID_Solicitud" = v_c;
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_c, v_fut + INTERVAL '1 hour', 'Contratista S.A.C.', v_per, v_mot, NULL, NULL, v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Varios pasos: cambiar la hora reabre TAMBIÉN los pasos por solicitud', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Decision" WHERE "ID_Tipo_Acceso_Paso_Aprobacion" = ' || v_paso_serv || ' AND "Vigente" = ''Y'' AND "ID_Solicitud_Persona" IN (SELECT "ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_c || ')'), 'el área vuelve a aprobar el servicio');
    PERFORM pg_temp.chk('Varios pasos: todas las personas vuelven a PENDIENTE', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_c || ' AND "Aprobacion" = ''APROBADA'''), '');

    -- ===================================================== J. REUTILIZAR («Basada en SOL-xxx»)
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Reutilizada S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, v_s1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_a, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Reutilizar: nace como solicitud nueva, pendiente', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Reutilizar: guarda de cuál se tomó', v_s1::TEXT, pg_temp.q('SELECT "ID_Solicitud_Origen" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_a), 'solo trazabilidad');
    PERFORM pg_temp.chk('Reutilizar: tiene su propio código y su propia aprobación', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_a), '');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Reutilizada S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, v_s1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_b, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Reutilizar: no se puede tomar la solicitud de otro usuario', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Reutilizada S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, 999999, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_b, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Reutilizar: origen inexistente', '101', v_cod::TEXT, v_msg);

    -- ===================================================== K. FLUJO QUE NO REQUIERE APROBACIÓN
    UPDATE "Catalogo_Tipo_Acceso" SET "Disponible" = 'Y', "Activo" = 'Y', "Requiere_Aprobacion" = 'N' WHERE "ID_Catalogo_Tipo_Acceso" = v_int;
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_int, v_per, v_fut, 'Interno', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_d, v_cs, v_cod, v_msg);
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
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Con documentos S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT || ',' || v_e2::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_ad, v_cs, v_cod, v_msg);
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
    -- Límite: hasta 10 documentos y 20 MB en total (D-222). Se llenan, se prueban los dos topes y se vuelve a 2 documentos.
    FOR i IN 3..10 LOOP
        CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'extra' || i || '.pdf', 'application/pdf', convert_to('%PDF extra ' || i, 'UTF8'), v_u_sol, v_dummy, v_cod, v_msg);
        PERFORM pg_temp.chk('Adjuntos: el documento ' || i || ' se acepta (hasta 10)', '100', v_cod::TEXT, v_msg);
    END LOOP;
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'once.pdf', 'application/pdf', convert_to('%PDF once', 'UTF8'), v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: el undécimo se rechaza (máximo 10 por solicitud)', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Adjunto" SET "Eliminado" = 'Y' WHERE "ID_Solicitud" = v_ad AND "Nombre_Archivo" LIKE 'extra%' AND "Nombre_Archivo" NOT IN ('extra3.pdf','extra4.pdf');
    UPDATE "CAF_Solicitud_Adjunto" SET "Tamano_Bytes" = 5242880 WHERE "ID_Solicitud" = v_ad AND "Eliminado" = 'N';
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'pesado.pdf', 'application/pdf', convert_to('%PDF pesado', 'UTF8'), v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: si los documentos ya suman 20 MB se rechaza otro (el correo no podría llevarlos)', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Adjunto" SET "Eliminado" = 'Y' WHERE "ID_Solicitud" = v_ad AND "Nombre_Archivo" IN ('extra3.pdf','extra4.pdf');
    UPDATE "CAF_Solicitud_Adjunto" SET "Tamano_Bytes" = LENGTH("Contenido") WHERE "ID_Solicitud" = v_ad;

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
    PERFORM pg_temp.chk('Adjuntos: la bitácora registra los documentos agregados y retirados', '12', pg_temp.q('SELECT COUNT(*) FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_ad || ' AND "Accion" IN (''ADJUNTO_AGREGAR'',''ADJUNTO_QUITAR'')'), '10 agregados (2 + 8 de la prueba del límite) y 1 retirado + 1 del flujo previo');
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_ad, 'prueba', v_u_sol, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_ad, 'tarde.pdf', 'application/pdf', convert_to('%PDF tarde', 'UTF8'), v_u_sol, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('Adjuntos: en una solicitud cancelada ya no se agregan documentos', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Adjuntos: Vigilancia no ve documentos de una solicitud cancelada', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR"(' || v_u_vig || ', ' || v_ad || ')'), '');
    -- Correos: retención para dar tiempo a cargar los documentos (D-185)
    PERFORM pg_temp.chk('Correos: con retención de 60 s no sale un aviso recién creado', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, 100, 60) WHERE "ID_Solicitud" = ' || v_ad), '');
    PERFORM pg_temp.chk('Correos: sin retención sí sale', 'true', pg_temp.q('SELECT (COUNT(*) > 0)::TEXT FROM "ERP_CAF_CORREO_PENDIENTES_LISTAR"(0, 100) WHERE "ID_Solicitud" = ' || v_ad), '');

    -- ===================================================== N. TIPO DE INGRESO, COCHERA Y CONTRATISTA (Entrega H, D-187 a D-192)
    PERFORM pg_temp.chk('Tipos: Visitante externo y Contratista se pueden usar', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_u_sol || ') WHERE "Codigo" IN (''VISITA_EXTERNA'',''CONTRATISTA'') AND "Usable" = ''Y'''), '');

    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_sol2, v_lic_sol, v_mag, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_coo, v_lic_coo, v_mag, 0, v_ul, v_cod, v_msg);
    PERFORM pg_temp.chk('Sedes: quien solo tiene VES ve una sola sede', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_SEDES_OPCIONES"(' || v_u_sol || ')'), '');
    PERFORM pg_temp.chk('Sedes: con licencia en Magdalena ve las dos', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_SEDES_OPCIONES"(' || v_u_sol2 || ')'), '');
    PERFORM pg_temp.chk('Sedes: solo Magdalena ofrece cochera', 'MAG', pg_temp.q('SELECT STRING_AGG("Codigo", '','') FROM "ERP_CAF_SOLICITUD_SEDES_OPCIONES"(' || v_u_sol2 || ') WHERE "Aplica_Cochera" = ''Y'''), '');
    PERFORM pg_temp.chk('Sedes: sin ningún permiso no ve sedes', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_SEDES_OPCIONES"(' || v_u_nada || ')'), '');

    -- Contratista (en VES)
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ctr, v_per, v_fut, 'Montajes Andinos S.A.C.', NULL, 'Cambio del tablero eléctrico', NULL, v_z_adm::TEXT, v_e1::TEXT || ',' || v_e2::TEXT, NULL, NULL, NULL, NULL, 'Sala de tableros', 'Juan Pérez', '999 888 777', 'juan@montajes.pe; ops@montajes.pe', NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_sc, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Contratista: se crea con sus actividades, área y contacto', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Contratista: queda el motivo fijo y las actividades en el detalle', 'SERVICIO_CONTRATISTA|Cambio del tablero eléctrico', pg_temp.q('SELECT M."Codigo" || ''|'' || S."Motivo_Detalle" FROM "CAF_Solicitud" S JOIN "Catalogo_Motivo_Visita" M ON M."ID_Catalogo_Motivo_Visita" = S."ID_Catalogo_Motivo_Visita" WHERE S."ID_Solicitud" = ' || v_sc), '');
    PERFORM pg_temp.chk('Contratista: el contacto y el detalle del área quedan en la solicitud', 'Juan Pérez|999 888 777|juan@montajes.pe; ops@montajes.pe|Sala de tableros', pg_temp.q('SELECT "Contacto_Nombre" || ''|'' || "Contacto_Telefonos" || ''|'' || "Contacto_Correos" || ''|'' || "Area_Detalle" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sc), '');
    PERFORM pg_temp.chk('Contratista: el área son las zonas elegidas', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Zona" WHERE "ID_Solicitud" = ' || v_sc || ' AND "Eliminado" = ''N'''), '');
    PERFORM pg_temp.chk('Contratista: sin cochera por defecto', 'N|', pg_temp.q('SELECT "Requiere_Cochera" || ''|'' || COALESCE("Placa_Vehiculo", '''') FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sc), '');
    PERFORM pg_temp.chk('Contratista: entra al flujo de aprobación (pendiente)', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sc), '');
    PERFORM pg_temp.chk('Contratista: el aviso a quien aprueba habla de contratista', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_sc || ' AND "Tipo" = ''SOLICITUD_NUEVA'' AND "Cuerpo" LIKE ''%ingreso de contratista%'''), '');
    PERFORM pg_temp.chk('Contratista: el detalle trae el código del tipo y el contacto', 'CONTRATISTA|Juan Pérez', pg_temp.q('SELECT "Tipo_Acceso_Codigo" || ''|'' || "Contacto_Nombre" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ', ' || v_sc || ')'), '');
    PERFORM pg_temp.chk('Contratista: los datos del correo traen el tipo y el contacto', 'CONTRATISTA|Juan Pérez', pg_temp.q('SELECT "Tipo_Acceso_Codigo" || ''|'' || "Contacto_Nombre" FROM "ERP_CAF_CORREO_SOLICITUD_DATOS"(0, ' || v_sc || ')'), '');
    PERFORM pg_temp.chk('Contratista: lo ve el Coordinador', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_coo || ', ' || v_sc || ')'), '');

    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ctr, v_per, v_fut, 'Montajes Andinos S.A.C.', NULL, '  ', NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, 'Juan Pérez', '999 888 777', 'juan@montajes.pe', NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Contratista: sin actividades se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ctr, v_per, v_fut, 'Montajes Andinos S.A.C.', NULL, 'Cambio del tablero', NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, '999 888 777', 'juan@montajes.pe', NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Contratista: sin nombre de contacto se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ctr, v_per, v_fut, 'Montajes Andinos S.A.C.', NULL, 'Cambio del tablero', NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, 'Juan', '12-3', 'juan@montajes.pe', NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Contratista: un teléfono de menos de 6 dígitos se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ctr, v_per, v_fut, 'Montajes Andinos S.A.C.', NULL, 'Cambio del tablero', NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, 'Juan', '999888777', 'esto-no-es-un-correo', NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Contratista: un correo de contacto inválido se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ctr, v_per, v_fut, 'Montajes Andinos S.A.C.', NULL, 'Cambio del tablero', NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, 'Juan', '999888777', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Contratista: sin correo de contacto se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ctr, v_per, v_fut, 'Montajes Andinos S.A.C.', NULL, 'Cambio del tablero', NULL, '', v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, 'Juan', '999888777', 'juan@montajes.pe', NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Contratista: sin área de trabajo se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ctr, v_per, v_fut, 'Montajes Andinos S.A.C.', NULL, 'Cambio del tablero', NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, 'Y', 'ABC123', NULL, 'Juan', '999888777', 'juan@montajes.pe', NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Cochera: en VES no se ofrece, se rechaza', '400', v_cod::TEXT, v_msg);

    -- Visitante externo: conserva su formulario y no admite datos de contratista
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Visitas S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, 'Juan', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Visitante: no admite contacto de contratista', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Visitas S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, 'Taller', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Visitante: no admite detalle de área de contratista', '400', v_cod::TEXT, v_msg);
    SELECT "ID_Catalogo_Motivo_Visita" INTO v_mcon FROM "Catalogo_Motivo_Visita" WHERE "Codigo" = 'SERVICIO_CONTRATISTA';
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Visitas S.A.', v_mcon, 'x', NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Visitante: no puede usar el motivo exclusivo del contratista', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Visitas S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, 'ABC123', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Placa: sin cochera no se admite una placa', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Visitas S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_sk, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Visitante: «No requiere cochera» crea normalmente', '100', v_cod::TEXT, v_msg);

    -- Magdalena: cochera y placa
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_mag, v_ext, v_per, v_fut, 'Visitas S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Magdalena: una zona de VES no vale para esa sede', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_mag, v_ext, v_per, v_fut, 'Visitas S.A.', v_mot, NULL, NULL, v_zmag::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Magdalena: sin licencia en esa sede no se puede crear', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_mag, v_ext, v_per, v_fut, 'Visitas S.A.', v_mot, NULL, NULL, v_zmag::TEXT, v_e1::TEXT, NULL, NULL, 'Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Magdalena: con cochera la placa es obligatoria', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_mag, v_ext, v_per, v_fut, 'Visitas S.A.', v_mot, NULL, NULL, v_zmag::TEXT, v_e1::TEXT, NULL, NULL, 'Y', 'A1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Magdalena: una placa demasiado corta se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_mag, v_ext, v_per, v_fut, 'Visitas S.A.', v_mot, NULL, NULL, v_zmag::TEXT, v_e1::TEXT, NULL, NULL, 'X', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Magdalena: un valor de cochera distinto de Sí/No se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_mag, v_ext, v_per, v_fut, 'Visitas S.A.', v_mot, NULL, NULL, v_zmag::TEXT, v_e1::TEXT, NULL, NULL, 'Y', ' abc-123 ', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_sm, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Magdalena: visitante con cochera y placa se crea', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Magdalena: la placa se guarda normalizada (mayúsculas, sin espacios ni guiones)', 'Y|ABC123', pg_temp.q('SELECT "Requiere_Cochera" || ''|'' || "Placa_Vehiculo" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sm), '');
    PERFORM pg_temp.chk('Magdalena: la solicitud queda en la sede Magdalena', v_mag::TEXT, pg_temp.q('SELECT "ID_Catalogo_Sede" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol2 || ', ' || v_sm || ')'), '');
    PERFORM pg_temp.chk('Magdalena: el aviso menciona la cochera y la placa', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_sm || ' AND "Tipo" = ''SOLICITUD_NUEVA'' AND "Cuerpo" LIKE ''%Requiere cochera (placa ABC123)%'''), '');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_mag, v_ctr, v_per, v_fut, 'Montajes Andinos S.A.C.', NULL, 'Mantenimiento de aire acondicionado', NULL, v_zmag::TEXT, v_e1::TEXT, NULL, NULL, 'Y', 'xyz789', NULL, 'Ana Ruiz', '987654321', 'ana@montajes.pe', NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_dummy, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Magdalena: el Coordinador con licencia en esa sede ve la solicitud', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_coo || ', ' || v_sm || ')'), '');
    PERFORM pg_temp.chk('Magdalena: el Coordinador de VES solo (sin licencia en Magdalena) no la vería', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_alm || ', ' || v_sm || ')'), '');
    PERFORM pg_temp.chk('Magdalena: un contratista también puede pedir cochera', '100', v_cod::TEXT, v_msg);

    -- Editar
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_sc, v_fut, 'Montajes Andinos S.A.C.', v_per, NULL, 'Cambio del tablero eléctrico', NULL, v_z_adm::TEXT, NULL, NULL, NULL, NULL, 'Juan Pérez', '999 111 222', 'juan@montajes.pe', NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar contratista: cambiar solo el teléfono no reabre la aprobación', 'N', v_reab::TEXT, v_msg);
    PERFORM pg_temp.chk('Editar contratista: el teléfono queda actualizado', '999 111 222', pg_temp.q('SELECT "Contacto_Telefonos" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sc), '');
    PERFORM pg_temp.chk('Editar contratista: el cambio de contacto queda en el historial', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_sc || ' AND "Accion" = ''EDITAR'' AND "Detalle" LIKE ''%contacto%'''), '');
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_sc, v_fut, 'Montajes Andinos S.A.C.', v_per, v_mot, 'Cambio del tablero y cableado', NULL, v_z_adm::TEXT, NULL, NULL, NULL, NULL, 'Juan Pérez', '999 111 222', 'juan@montajes.pe', NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar contratista: cambiar las actividades reabre la aprobación', 'Y', v_reab::TEXT, v_msg);
    PERFORM pg_temp.chk('Editar contratista: el motivo sigue siendo el fijo aunque se envíe otro', 'SERVICIO_CONTRATISTA', pg_temp.q('SELECT M."Codigo" FROM "CAF_Solicitud" S JOIN "Catalogo_Motivo_Visita" M ON M."ID_Catalogo_Motivo_Visita" = S."ID_Catalogo_Motivo_Visita" WHERE S."ID_Solicitud" = ' || v_sc), '');
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_sc, v_fut, 'Montajes Andinos S.A.C.', v_per, NULL, 'Cambio del tablero y cableado', NULL, v_z_adm::TEXT, NULL, NULL, NULL, NULL, NULL, '999 111 222', 'juan@montajes.pe', NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar contratista: no se puede dejar sin nombre de contacto', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_sk, v_fut, 'Visitas S.A.', v_per, v_mot, NULL, NULL, v_z_adm::TEXT, NULL, NULL, NULL, NULL, 'Juan', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar visitante: no admite datos de contratista', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_sm, v_fut, 'Visitas S.A.', v_per, v_mot, NULL, NULL, v_zmag::TEXT, NULL, 'Y', 'qwe-456', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar visitante en Magdalena: cambiar la placa no reabre la aprobación', 'N', v_reab::TEXT, v_msg);
    PERFORM pg_temp.chk('Editar visitante en Magdalena: la placa nueva queda normalizada', 'QWE456', pg_temp.q('SELECT "Placa_Vehiculo" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sm), '');
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_sm, v_fut, 'Visitas S.A.', v_per, v_mot, NULL, NULL, v_zmag::TEXT, NULL, 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol2, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar visitante en Magdalena: quitar la cochera borra la placa', 'N|', pg_temp.q('SELECT "Requiere_Cochera" || ''|'' || COALESCE("Placa_Vehiculo", '''') FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sm), '');

    -- Aprobar un contratista: la foto de lo aprobado incluye el tipo y sus datos
    SELECT MIN("ID_Solicitud_Persona") INTO v_b FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_sc AND "Eliminado" = 'N';
    SELECT MIN("ID_Tipo_Acceso_Paso_Aprobacion") INTO v_pctr FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "ID_Catalogo_Tipo_Acceso" = v_ctr AND "Eliminado" = 'N';
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sc, v_pctr, 'APROBADA', NULL, v_b::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Contratista: el Coordinador aprueba con el mismo paso que el visitante', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Contratista: la foto aprobada incluye tipo, actividades y contacto', 'true', pg_temp.q('SELECT (V."Contenido_JSON" LIKE ''%"tipo":"CONTRATISTA"%'' AND V."Contenido_JSON" LIKE ''%Cambio del tablero y cableado%'' AND V."Contenido_JSON" LIKE ''%Juan Pérez%'')::TEXT FROM "CAF_Solicitud_Version" V WHERE V."ID_Solicitud" = ' || v_sc || ' ORDER BY V."Version" DESC LIMIT 1'), '');

    -- ===================================================== O. PROVEEDOR DE ABASTECIMIENTO (Entrega 1)
    DECLARE
        v_prov BIGINT; v_paso_p BIGINT; v_z_esc BIGINT; v_lic_sp BIGINT; v_lic_cp BIGINT; v_lic_vp BIGINT; v_lic_al BIGINT;
        v_usp BIGINT; v_ucp BIGINT; v_uvp BIGINT; v_ual BIGINT; v_umag BIGINT;
        v_q1 BIGINT; v_q2 BIGINT; v_q3 BIGINT; v_sa BIGINT; v_sb BIGINT; v_sc2 BIGINT; v_sd BIGINT; v_se BIGINT;
        v_sp1 BIGINT; v_sp2 BIGINT; v_it TEXT; v_reg2 BIGINT; v_des2 BIGINT; v_res2 VARCHAR(30);
        v_fhoy TIMESTAMP; v_cs2 VARCHAR(20);
    BEGIN
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_prov FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'PROVEEDOR';
    SELECT "ID_Tipo_Acceso_Paso_Aprobacion" INTO v_paso_p FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "ID_Catalogo_Tipo_Acceso" = v_prov AND "Eliminado" = 'N' LIMIT 1;
    SELECT "ID_Catalogo_Zona_Acceso" INTO v_z_esc FROM "Catalogo_Zona_Acceso" WHERE "Codigo" = 'ESCLUSA_VEHICULAR' AND "ID_Catalogo_Sede" = v_ves;
    SELECT "ID_Catalogo_Licencia" INTO v_lic_sp FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_SOLICITANTE_PROVEEDOR';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_cp FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_COORD_PROVEEDOR';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_vp FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_VIGILANCIA_PROVEEDOR';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_al FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_ALMACEN';
    v_fhoy := CAST(CURRENT_DATE AS TIMESTAMP) + INTERVAL '23 hours';

    -- Datos de fábrica (script 17)
    PERFORM pg_temp.chk('Proveedor: el tipo queda disponible', 'Y', pg_temp.q('SELECT "Disponible" FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = ''PROVEEDOR'''), '');
    PERFORM pg_temp.chk('Proveedor: solo VES lo recibe', 'VES', pg_temp.q('SELECT STRING_AGG("Codigo", '','') FROM "CAF_GOVERNANCE"."Catalogo_Sede" WHERE "Aplica_Proveedor" = ''Y'''), '');
    PERFORM pg_temp.chk('Proveedor: la esclusa vehicular exige SCTR y EPP', 'Y|Y', pg_temp.q('SELECT "Exige_SCTR" || ''|'' || "Exige_EPP" FROM "Catalogo_Zona_Acceso" WHERE "ID_Catalogo_Zona_Acceso" = ' || v_z_esc), '');
    PERFORM pg_temp.chk('Proveedor: checklist = ingreso (identificación, SCTR, EPP, placa) y salida (documentación de la carga)', 'ING_EPP,ING_IDENTIDAD,ING_PLACA,ING_SCTR,SAL_PROVEEDOR_DOCUMENTOS',
        pg_temp.q('SELECT STRING_AGG(I."Codigo", '','' ORDER BY I."Codigo") FROM "Tipo_Acceso_Item_Checklist" T JOIN "Catalogo_Item_Checklist" I ON I."ID_Catalogo_Item_Checklist" = T."ID_Catalogo_Item_Checklist" WHERE T."ID_Catalogo_Tipo_Acceso" = ' || v_prov), '');
    PERFORM pg_temp.chk('Proveedor: un paso de aprobación con la licencia de Coordinador de proveedores', '1|LIC_CAF_COORD_PROVEEDOR',
        pg_temp.q('SELECT COUNT(*) || ''|'' || MAX(L."Codigo") FROM "Tipo_Acceso_Paso_Aprobacion" S JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = S."ID_Catalogo_Licencia" WHERE S."ID_Catalogo_Tipo_Acceso" = ' || v_prov), '');

    -- Usuarios y personas
    CALL "ERP_USUARIO_CREAR"('solprov@ejemplo.pe',  v_dni,'30000001','Solicitante','Prov','Pedro',NULL,'Ejemplo','Y',0, v_usp, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('coordprov@ejemplo.pe',v_dni,'30000002','Coordinador','Prov','Carla',NULL,'Ejemplo','Y',0, v_ucp, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('vigprov@ejemplo.pe',  v_dni,'30000003','Vigilante','Prov','Victor',NULL,'Ejemplo','Y',0, v_uvp, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('almacen.prov@ejemplo.pe', v_dni,'30000004','Almacen','Prov','Alma',NULL,'Ejemplo','Y',0, v_ual, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('solprov.mag@ejemplo.pe', v_dni,'30000005','Solicitante','Mag','Mario',NULL,'Ejemplo','Y',0, v_umag, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_usp, v_lic_sp, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_ucp, v_lic_cp, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_uvp, v_lic_vp, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_ual, v_lic_al, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_umag, v_lic_sp, v_mag, 0, v_ul, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000001','Chofer','Principal','Carlos',0, v_q1, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000002','Ayudante','Uno','Raúl',0,       v_q2, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000003','Ayudante','Dos','Saúl',0,       v_q3, v_cod, v_msg);

    -- Quién ve qué
    PERFORM pg_temp.chk('Proveedor: el solicitante de proveedores ve el tipo Proveedor', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_usp || ') WHERE "Codigo" = ''PROVEEDOR'' AND "Usable" = ''Y'''), '');
    PERFORM pg_temp.chk('Proveedor: un solicitante común no ve el tipo Proveedor', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_u_sol || ') WHERE "Codigo" = ''PROVEEDOR'''), '');
    PERFORM pg_temp.chk('Proveedor: la sede se ofrece con la marca de proveedor', 'VES|Y', pg_temp.q('SELECT STRING_AGG("Codigo" || ''|'' || "Aplica_Proveedor", '','') FROM "ERP_CAF_SOLICITUD_SEDES_OPCIONES"(' || v_usp || ')'), '');

    -- CREAR: permisos y validaciones
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, v_q1::TEXT, NULL, NULL, NULL, 'ABC-123', NULL, NULL, '999111222', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', 'Volvo', 'Q12345678', v_q1, v_u_sol, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: sin licencia de proveedores', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, v_q1::TEXT, NULL, NULL, NULL, 'ABC-123', NULL, NULL, '999111222', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', 'Volvo', 'Q12345678', v_q1, v_uvp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: Vigilancia de proveedores no solicita', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_mag, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, v_q1::TEXT, NULL, NULL, NULL, 'ABC-123', NULL, NULL, '999111222', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', 'Volvo', 'Q12345678', v_q1, v_umag, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: Magdalena no recibe proveedores', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, v_q1::TEXT, NULL, NULL, NULL, 'ABC-123', NULL, NULL, '999111222', NULL, v_emp, '2012345678', 'Av. Los Olivos 123', 'Volvo', 'Q12345678', v_q1, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: el RUC debe tener 11 dígitos', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, v_q1::TEXT, NULL, NULL, NULL, 'AB', NULL, NULL, '999111222', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', 'Volvo', 'Q12345678', v_q1, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: la placa, si se escribe, debe tener 5 a 8 caracteres', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, v_q1::TEXT, NULL, NULL, NULL, 'ABC-123', NULL, NULL, '999111222', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', NULL, 'Q12345678', v_q1, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: la marca es opcional (puede ir en los adjuntos)', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, v_q1::TEXT, NULL, NULL, NULL, 'ABC-123', NULL, NULL, '999111222', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', 'Volvo', NULL, v_q1, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: la licencia es opcional (puede ir en los adjuntos)', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, v_q1::TEXT, NULL, NULL, NULL, 'ABC-123', NULL, NULL, '123', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', 'Volvo', 'Q12345678', v_q1, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: el teléfono es obligatorio', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, v_q1::TEXT, NULL, NULL, NULL, 'ABC-123', NULL, NULL, '999111222', NULL, NULL, '20123456789', 'Av. Los Olivos 123', 'Volvo', 'Q12345678', v_q1, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: la empresa destinataria es obligatoria', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, v_q1::TEXT, NULL, NULL, NULL, 'ABC-123', NULL, NULL, '999111222', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', 'Volvo', 'Q12345678', NULL, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: sin transportista principal no procede', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, v_q1::TEXT, NULL, NULL, NULL, 'ABC-123', NULL, NULL, '999111222', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', 'Volvo', 'Q12345678', v_q2, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: el principal debe estar entre las personas', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '20123456789', NULL, NULL, NULL, NULL, v_u_sol, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: un visitante no admite datos de proveedor', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Energía Verde S.A.C.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_e1, v_u_sol, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: un visitante no admite transportista principal', '400', v_cod::TEXT, v_msg);

    -- CREAR correcto (el motivo y la zona los fija el sistema; no hay responsable de atención)
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Distribuidora Andina S.A.', v_mot, 'ignorado', 'Entrega de insumos', v_z_adm::TEXT, v_q1 || ',' || v_q2, NULL, NULL, NULL, 'abc-123', 'x', 'x', '999 111 222', 'x@x.pe', v_emp, '20123456789', 'Av. Los Olivos 123', 'Volvo', 'Q12345678', v_q1, v_usp, v_sa, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: correcto', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor crear: queda PENDIENTE y sin responsable de atención', 'PENDIENTE|(nulo)',
        pg_temp.q('SELECT "Estado" || ''|'' || COALESCE(CAST("ID_Personal_Responsable" AS VARCHAR), ''(nulo)'') FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Proveedor crear: zona fija = esclusa vehicular (la enviada se ignora)', 'ESCLUSA_VEHICULAR',
        pg_temp.q('SELECT STRING_AGG(Z."Codigo", '','') FROM "CAF_Solicitud_Zona" W JOIN "Catalogo_Zona_Acceso" Z ON Z."ID_Catalogo_Zona_Acceso" = W."ID_Catalogo_Zona_Acceso" WHERE W."ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Proveedor crear: exige SCTR y EPP por la zona', 'Y|Y', pg_temp.q('SELECT "Exige_SCTR" || ''|'' || "Exige_EPP" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Proveedor crear: motivo fijo', 'ENTREGA_PROVEEDOR', pg_temp.q('SELECT M."Codigo" FROM "CAF_Solicitud" S JOIN "Catalogo_Motivo_Visita" M ON M."ID_Catalogo_Motivo_Visita" = S."ID_Catalogo_Motivo_Visita" WHERE S."ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Proveedor crear: guarda placa normalizada, RUC, marca y licencia', 'ABC123|20123456789|Volvo|Q12345678',
        pg_temp.q('SELECT "Placa_Vehiculo" || ''|'' || "Proveedor_RUC" || ''|'' || "Vehiculo_Marca" || ''|'' || "Licencia_Conducir" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Proveedor crear: guarda el responsable de la entrega y no la cochera ni el área', 'N|x|(nulo)',
        pg_temp.q('SELECT "Requiere_Cochera" || ''|'' || COALESCE("Contacto_Nombre", ''(nulo)'') || ''|'' || COALESCE("Area_Detalle", ''(nulo)'') FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Proveedor crear: un solo transportista principal', '1|' || v_q1, pg_temp.q('SELECT COUNT(*) || ''|'' || MAX("ID_Persona_Externa") FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_sa || ' AND "Es_Principal" = ''Y'''), '');
    PERFORM pg_temp.chk('Proveedor crear: todavía no hay operación (nada aprobado)', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sa), '');

    -- ===== Varios transportistas, cada uno con sus datos opcionales (D-223) =====
    PERFORM pg_temp.chk('Transportistas: CREAR directo deja la fila del principal con sus datos', '1|20123456789|ABC123|Volvo|Q12345678',
        pg_temp.q('SELECT COUNT(*) || ''|'' || MAX("Ruc") || ''|'' || MAX("Placa") || ''|'' || MAX("Marca") || ''|'' || MAX("Licencia") FROM "CAF_Solicitud_Transportista" WHERE "ID_Solicitud" = ' || v_sa), '');
    v_tr_n := (SELECT COUNT(*) FROM "CAF_Solicitud");
    v_tr1 := v_q1::TEXT || CHR(31) || '20123456789' || CHR(31) || 'Transportes Rápido SAC' || CHR(31) || 'Av. Argentina 100' || CHR(31) || 'abc-123' || CHR(31) || 'Volvo' || CHR(31) || 'Q12345678';
    v_tr2 := v_q2::TEXT || CHR(31) || CHR(31) || 'Fletes Pedro' || CHR(31) || CHR(31) || 'xyz 987' || CHR(31) || CHR(31);
    CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fut, 'Distribuidora Andina S.A.', NULL, v_q1 || ',' || v_q2, NULL, NULL, 'Luis Jefe', '999111222', v_emp, NULL, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Transportistas: sin ninguno marcado no procede', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fut, 'Distribuidora Andina S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Luis Jefe', '999111222', v_emp, v_tr2, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Transportistas: el transportista debe estar entre las personas', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fut, 'Distribuidora Andina S.A.', NULL, v_q1 || ',' || v_q2, NULL, NULL, 'Luis Jefe', '999111222', v_emp, v_tr1 || CHR(30) || v_tr1, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Transportistas: una persona no puede marcarse dos veces', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fut, 'Distribuidora Andina S.A.', NULL, v_q1 || ',' || v_q2, NULL, NULL, 'Luis Jefe', '999111222', v_emp, v_tr1 || CHR(30) || v_q2::TEXT || CHR(31) || '123', v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Transportistas: el RUC del segundo debe tener 11 dígitos', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fut, 'Distribuidora Andina S.A.', NULL, v_q1 || ',' || v_q2, NULL, NULL, 'Luis Jefe', '999111222', v_emp, v_tr1, v_uvp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Transportistas: Vigilancia de proveedores no solicita', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fut, 'Distribuidora Andina S.A.', NULL, v_q1 || ',' || v_q2, NULL, NULL, 'Luis Jefe', '12', v_emp, v_tr1, v_usp, v_id, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Transportistas: el teléfono del responsable sigue siendo obligatorio', '400', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Transportistas: los intentos fallidos no dejan nada creado', '0', ((SELECT COUNT(*) FROM "CAF_Solicitud") - v_tr_n)::TEXT, '');
    CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fut, 'Distribuidora Andina S.A.', 'Dos camiones', v_q1 || ',' || v_q2, NULL, NULL, 'Luis Jefe', '999 111 222', v_emp, v_tr1 || CHR(30) || v_tr2, v_usp, v_ids, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Transportistas: dos transportistas, correcto', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Transportistas: el primero es el principal (uno solo)', '1|' || v_q1, pg_temp.q('SELECT COUNT(*) || ''|'' || MAX("ID_Persona_Externa") FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_ids || ' AND "Es_Principal" = ''Y'''), '');
    PERFORM pg_temp.chk('Transportistas: dos filas de datos', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Transportista" WHERE "ID_Solicitud" = ' || v_ids), '');
    PERFORM pg_temp.chk('Transportistas: los datos del principal también van a la solicitud (calendario)', 'ABC123|20123456789|Volvo|Q12345678|Luis Jefe',
        pg_temp.q('SELECT "Placa_Vehiculo" || ''|'' || "Proveedor_RUC" || ''|'' || "Vehiculo_Marca" || ''|'' || "Licencia_Conducir" || ''|'' || "Contacto_Nombre" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_ids), '');
    PERFORM pg_temp.chk('Transportistas: el segundo guarda solo lo que se escribió (placa normalizada, el resto vacío)', 'XYZ987|Fletes Pedro|(nulo)|(nulo)',
        pg_temp.q('SELECT T."Placa" || ''|'' || T."Nombre" || ''|'' || COALESCE(T."Ruc", ''(nulo)'') || ''|'' || COALESCE(T."Marca", ''(nulo)'') FROM "CAF_Solicitud_Transportista" T JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud_Persona" = T."ID_Solicitud_Persona" WHERE T."ID_Solicitud" = ' || v_ids || ' AND P."ID_Persona_Externa" = ' || v_q2), '');
    PERFORM pg_temp.chk('Transportistas: el solicitante ve a sus dos transportistas (principal primero; datos completos Y/N)', 'YY,NN',
        pg_temp.q('SELECT STRING_AGG(X."Es_Principal" || X."Datos_Completos", '','' ORDER BY X."Es_Principal" DESC) FROM "ERP_CAF_SOLICITUD_TRANSPORTISTAS"(' || v_usp || ',' || v_ids || ') X'), '');
    PERFORM pg_temp.chk('Transportistas: otro solicitante no ve los transportistas ajenos', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TRANSPORTISTAS"(' || v_u_sol2 || ',' || v_ids || ')'), '');
    PERFORM pg_temp.chk('Transportistas: Coordinación ve los transportistas para decidir', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TRANSPORTISTAS"(' || v_u_coo || ',' || v_ids || ')'), '');
    -- D-224: quien puede solicitar proveedores gestiona sus propias solicitudes (ver, editar, personas)
    PERFORM pg_temp.chk('D-224: el solicitante de proveedores ve su solicitud en «Mis solicitudes»', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_usp || ') X WHERE X."ID_Solicitud" = ' || v_ids), '');
    PERFORM pg_temp.chk('D-224: ve el detalle de su solicitud y puede editarla', '1|Y', pg_temp.q('SELECT COUNT(*) || ''|'' || MAX(X."Puede_Editar_Datos") FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_usp || ',' || v_ids || ') X'), '');
    PERFORM pg_temp.chk('D-224: ve las personas de su solicitud', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"(' || v_usp || ',' || v_ids || ')'), '');
    PERFORM pg_temp.chk('D-224: el permiso de proveedor no abre otros tipos de ingreso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_usp || ') WHERE "Codigo" <> ''PROVEEDOR'' AND "Usable" = ''Y'''), '');
    PERFORM pg_temp.chk('D-224: otro solicitante sigue sin ver la solicitud ajena', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol2 || ',' || v_ids || ')'), '');
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_ids, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, 'Cambia solo la observación', NULL, NULL, NULL, NULL, NULL, 'Luis Jefe', '999111222', NULL, v_emp, NULL, NULL, NULL, NULL, v_usp, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Transportistas: editar sin datos de transportista conserva los guardados', '100|ABC123|20123456789|1', v_cod::TEXT || '|' || pg_temp.q('SELECT "Placa_Vehiculo" || ''|'' || "Proveedor_RUC" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_ids) || '|' || pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Transportista" T WHERE T."ID_Solicitud" = ' || v_ids || ' AND T."Placa" = ''ABC123'' AND T."Ruc" = ''20123456789'''), v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fut, 'Distribuidora Andina S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Luis Jefe', '999111222', v_emp, v_q1::TEXT, v_usp, v_ids, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Transportistas: se puede enviar solo con los datos mínimos (irán en los adjuntos)', '100|(nulo)|(nulo)', v_cod::TEXT || '|' || pg_temp.q('SELECT COALESCE("Placa_Vehiculo", ''(nulo)'') FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_ids) || '|' || pg_temp.q('SELECT COALESCE("Proveedor_RUC", ''(nulo)'') FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_ids), v_msg);
    PERFORM pg_temp.chk('Proveedor crear: Almacén va en copia desde el registro', 'true', pg_temp.q('SELECT COALESCE("ERP_CAF_FN_COPIA_CORREO"(' || v_sa || ', ''N'', ''N'', ''N'', ''N'') LIKE ''%almacen.prov@ejemplo.pe%'', false)'), '');
    PERFORM pg_temp.chk('Proveedor crear: el aviso de aprobación va al Coordinador de proveedores', 'true',
        pg_temp.q('SELECT COALESCE(STRING_AGG("Destinatarios", '';''), '''') LIKE ''%coordprov@ejemplo.pe%'' FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_sa || ' AND "Tipo" = ''SOLICITUD_NUEVA'''), '');

    -- Aprobación: solo la licencia del paso decide; el apoyo solo no programa nada; el principal sí
    v_sp1 := pg_temp.sp(v_sa, v_q1); v_sp2 := pg_temp.sp(v_sa, v_q2);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sa, v_paso_p, 'APROBADA', NULL, v_sp2::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor aprobar: el Coordinador común no decide (falta la licencia del paso)', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sa, v_paso_p, 'APROBADA', NULL, v_sp2::TEXT, v_ucp, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor aprobar: el Coordinador de proveedores aprueba al apoyo', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor aprobar: sin el principal aprobado no hay entrega programada', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sa), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sa, v_paso_p, 'APROBADA', NULL, v_sp1::TEXT, v_ucp, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor aprobar: aprueba al principal', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor aprobar: con el principal aprobado queda PROGRAMADO y activa', 'PROGRAMADO|Y', pg_temp.q('SELECT "Estado_Operativo" || ''|'' || "Activa" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Proveedor aprobar: no aparece en la lista de Vigilancia convencional', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS"(' || v_u_vig || ', ' || v_ves || ') WHERE "ID_Solicitud" = ' || v_sa), '');

    -- Editar y reprogramar (solo mientras sigue PROGRAMADO)
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_sa, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, 'Entrega de insumos', NULL, NULL, NULL, 'xyz-789', NULL, NULL, '999111222', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', 'Scania', 'Q12345678', v_usp, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor editar: cambiar placa y marca no reabre la aprobación', '100|N', v_cod::TEXT || '|' || v_reab, v_msg);
    PERFORM pg_temp.chk('Proveedor editar: la placa queda normalizada y la entrega sigue activa', 'XYZ789|Scania|Y', pg_temp.q('SELECT S."Placa_Vehiculo" || ''|'' || S."Vehiculo_Marca" || ''|'' || O."Activa" FROM "CAF_Solicitud" S JOIN "CAF_Solicitud_Operacion" O ON O."ID_Solicitud" = S."ID_Solicitud" WHERE S."ID_Solicitud" = ' || v_sa), '');
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_sa, v_fut + INTERVAL '1 day', 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'XYZ789', NULL, NULL, '999111222', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', 'Scania', 'Q12345678', v_usp, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor editar: reprogramar la fecha reabre la aprobación', '100|Y', v_cod::TEXT || '|' || v_reab, v_msg);
    PERFORM pg_temp.chk('Proveedor editar: reabierta, la entrega deja de estar activa (sale de Vigilancia)', 'PROGRAMADO|N', pg_temp.q('SELECT "Estado_Operativo" || ''|'' || "Activa" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sa), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sa, v_paso_p, 'APROBADA', NULL, v_sp1::TEXT, v_ucp, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor editar: al aprobar de nuevo la entrega vuelve a estar activa (una sola fila)', 'PROGRAMADO|Y|1', pg_temp.q('SELECT MAX("Estado_Operativo") || ''|'' || MAX("Activa") || ''|'' || COUNT(*) FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sa), '');
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_sa, v_fut, 'Distribuidora Andina S.A.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'XYZ789', NULL, NULL, '999111222', NULL, v_emp, '20123456789', 'Av. Los Olivos 123', 'Scania', 'Q12345678', v_u_sol, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor editar: otro usuario no edita', '101', v_cod::TEXT, v_msg);

    -- Cancelar: lógica, deja de estar activa
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_sa, 'Ya no llega', v_usp, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor cancelar: correcto', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor cancelar: queda CANCELADA (no se borra) y la entrega inactiva', 'CANCELADA|N', pg_temp.q('SELECT S."Estado" || ''|'' || O."Activa" FROM "CAF_Solicitud" S JOIN "CAF_Solicitud_Operacion" O ON O."ID_Solicitud" = S."ID_Solicitud" WHERE S."ID_Solicitud" = ' || v_sa), '');

    -- Entrega del día: llegada, ingreso del principal, apoyo, atención, recepción y salida
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fhoy, 'Transportes Sur S.A.C.', NULL, NULL, NULL, NULL, v_q1 || ',' || v_q2, NULL, NULL, NULL, 'DEF456', NULL, NULL, '988777666', NULL, v_emp, '20987654321', 'Jr. Lima 45', 'Hino', 'Q87654321', v_q1, v_usp, v_sb, v_cs2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor día: solicitud creada (hoy)', '100', v_cod::TEXT, v_msg);
    v_sp1 := pg_temp.sp(v_sb, v_q1); v_sp2 := pg_temp.sp(v_sb, v_q2);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sb, v_paso_p, 'APROBADA', NULL, v_sp1 || ',' || v_sp2, v_ucp, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor día: aprobada', '100', v_cod::TEXT, v_msg);
    v_it := pg_temp.q('SELECT STRING_AGG("ID_Catalogo_Item_Checklist" || '':Y'', '','') FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_sp1 || ', ''INGRESO'', ''N'', ''N'')');
    PERFORM pg_temp.chk('Proveedor día: el principal tiene 4 ítems de ingreso (incluye la placa)', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_sp1 || ', ''INGRESO'', ''N'', ''N'')'), '');
    PERFORM pg_temp.chk('Proveedor día: el apoyo tiene 3 (sin la placa)', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_sp2 || ', ''INGRESO'', ''N'', ''N'')'), '');
    PERFORM pg_temp.chk('Proveedor día: la salida del principal pide un ítem (documentación de la carga)', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_sp1 || ', ''SALIDA'', ''N'', ''N'')'), '');

    -- Verificación de datos (registra la llegada; NO es el ingreso físico)
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_sb, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso físico: sin verificar los datos no se valida', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_sb, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor disponibilidad: Almacén no confirma antes de que Vigilancia verifique', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sp1, v_it, 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_ual, v_reg2, v_des2, v_res2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor verificación: Almacén no verifica datos', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sp1, v_it, 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg2, v_des2, v_res2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor verificación: la Vigilancia convencional no verifica proveedores', '101', v_cod::TEXT, v_msg);
    v_it := pg_temp.q('SELECT STRING_AGG("ID_Catalogo_Item_Checklist" || '':Y'', '','') FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_sp2 || ', ''INGRESO'', ''N'', ''N'')');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sp2, v_it, 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_reg2, v_des2, v_res2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor verificación: el ayudante puede verificarse por adelantado (D-225)', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor verificación: verificar al ayudante no mueve la entrega (solo los transportistas la mueven)', 'PROGRAMADO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sb), '');
    v_it := pg_temp.q('SELECT STRING_AGG("ID_Catalogo_Item_Checklist" || '':Y'', '','') FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_sp1 || ', ''INGRESO'', ''N'', ''N'')');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sp1, v_it, 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_reg2, v_des2, v_res2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor verificación: el principal queda verificado', '100|INGRESA', v_cod::TEXT || '|' || v_res2, v_msg);
    PERFORM pg_temp.chk('Proveedor verificación: la entrega pasa a EN_ESPERA (no a INGRESO)', 'EN_ESPERA|N', pg_temp.q('SELECT "Estado_Operativo" || ''|'' || "Con_Desviacion" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sb), '');
    PERFORM pg_temp.chk('Proveedor verificación: el principal todavía NO figura dentro y no tiene hora de ingreso', 'ESPERADA|true',
        pg_temp.q('SELECT "Estado" || ''|'' || ("Fecha_Hora_Ingreso" IS NULL)::TEXT FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_sp1), '');
    PERFORM pg_temp.chk('Proveedor verificación: queda la llegada (hora y usuario) y el checklist de 4 respuestas', 'true|4',
        pg_temp.q('SELECT ("Fecha_Llegada" IS NOT NULL AND "ID_Usuario_Llegada" IS NOT NULL)::TEXT || ''|'' || (SELECT COUNT(*) FROM "CAF_Registro_Checklist" WHERE "ID_Registro_Acceso" = ' || v_reg2 || ') FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sb), '');
    PERFORM pg_temp.chk('Proveedor verificación: repetida es 409 (no se duplica)', '409|', pg_temp.verif(v_sp1, v_uvp), '');
    CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_sb, v_fhoy, 'Transportes Sur S.A.C.', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'DEF456', NULL, NULL, '988777666', NULL, v_emp, '20987654321', 'Jr. Lima 45', 'Hino', 'Q87654321', v_usp, v_reab, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor editar: tras la verificación ya no se edita', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_sb, 'Tarde', v_usp, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor cancelar: tras la verificación ya no se cancela', '409', v_cod::TEXT, v_msg);
    v_it := pg_temp.q('SELECT STRING_AGG("ID_Catalogo_Item_Checklist" || '':Y'', '','') FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_sp2 || ', ''INGRESO'', ''N'', ''N'')');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sp2, v_it, 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_reg2, v_des2, v_res2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor verificación: el ayudante ya verificado no se verifica dos veces', '409', v_cod::TEXT, v_msg);

    -- Ingreso físico: exige la disponibilidad de Almacén
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_sb, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso físico: sin la disponibilidad de Almacén no ingresa', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso físico: el mensaje dice que falta Almacén', 'true', (POSITION('Almacén' IN v_msg) > 0)::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_sb, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor atender: no se atiende a quien aún no ingresó', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_sb, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor disponibilidad: Vigilancia no confirma por Almacén', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_sb, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor disponibilidad: Almacén confirma', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor disponibilidad: la esclusa queda reservada para la entrega y se registra quién y cuándo', 'true|' || v_ual,
        pg_temp.q('SELECT (X."ID_Solicitud_Actual" = ' || v_sb || ' AND O."Fecha_Disponibilidad" IS NOT NULL)::TEXT || ''|'' || O."ID_Usuario_Disponibilidad" FROM "CAF_Exclusa" X, "CAF_Solicitud_Operacion" O WHERE X."ID_Catalogo_Sede" = ' || v_ves || ' AND O."ID_Solicitud" = ' || v_sb), '');
    PERFORM pg_temp.chk('Proveedor disponibilidad: confirmar la reserva no cambia el estado', 'EN_ESPERA', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sb), '');
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_sb, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso físico: Almacén no registra ingresos', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_sb, v_u_vig, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso físico: la Vigilancia convencional no lo registra', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_sb, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso físico: con la disponibilidad confirmada ingresa', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso físico: la entrega pasa a INGRESO y el principal figura dentro con su hora', 'INGRESO|DENTRO|true',
        pg_temp.q('SELECT O."Estado_Operativo" || ''|'' || P."Estado" || ''|'' || (P."Fecha_Hora_Ingreso" IS NOT NULL AND O."Fecha_Ingreso" IS NOT NULL)::TEXT FROM "CAF_Solicitud_Operacion" O JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud" = O."ID_Solicitud" AND P."Es_Principal" = ''Y'' WHERE O."ID_Solicitud" = ' || v_sb), '');
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_sb, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso físico: repetido es 409', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_FISICO"(v_sb, v_sp2::TEXT, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso: el ayudante ya verificado ingresa (con el transportista dentro)', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso: el checklist del ayudante guardó 3 respuestas y queda dentro', '3|DENTRO',
        pg_temp.q('SELECT (SELECT COUNT(*) FROM "CAF_Registro_Checklist" C JOIN "CAF_Registro_Acceso" R ON R."ID_Registro_Acceso" = C."ID_Registro_Acceso" WHERE R."ID_Solicitud_Persona" = ' || v_sp2 || ' AND R."Tipo_Movimiento" = ''INGRESO'') || ''|'' || "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_sp2), '');

    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_sp1, COALESCE(pg_temp.items(v_sp1, 'SALIDA', 'N', 'N', ''), ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_reg2, v_des2, v_res2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor salida: el principal no sale antes de la recepción', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_sb, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor atender: Vigilancia no atiende por Almacén', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_sb, 'CONFORME', NULL, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor recepción: antes de atender es 409', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_sb, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor atender: Almacén inicia la atención', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor atender: pasa a EN_ATENCION', 'EN_ATENCION', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sb), '');
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_sb, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor atender: repetido es 409', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_sb, 'CON_OBSERVACION', NULL, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor recepción: con observación exige la descripción', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_sb, 'TAL_VEZ', NULL, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor recepción: resultado inválido', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_sb, 'CON_OBSERVACION', 'Faltaron 2 cajas', v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor recepción: con observación', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor recepción: al terminar la exclusa sigue ocupada (el camión sigue dentro)', v_sb::TEXT, pg_temp.q('SELECT COALESCE("ID_Solicitud_Actual"::TEXT, ''libre'') FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves), '');
    PERFORM pg_temp.chk('Proveedor recepción: queda RECEPCIONADO con su resultado y descripción', 'RECEPCIONADO|CON_OBSERVACION|Faltaron 2 cajas',
        pg_temp.q('SELECT "Estado_Operativo" || ''|'' || "Resultado_Recepcion" || ''|'' || "Observacion_Recepcion" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sb), '');
    CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_sb, 'CONFORME', NULL, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor recepción: repetida es 409', '409', v_cod::TEXT, v_msg);

    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_sp2, COALESCE(pg_temp.items(v_sp2, 'SALIDA', 'N', 'N', ''), ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_reg2, v_des2, v_res2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor salida: el apoyo sale sin checklist', '100|SALE', v_cod::TEXT || '|' || v_res2, v_msg);
    PERFORM pg_temp.chk('Proveedor salida: con el principal todavía dentro la entrega sigue RECEPCIONADO', 'RECEPCIONADO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sb), '');
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_sp1, COALESCE(pg_temp.items(v_sp1, 'SALIDA', 'N', 'N', ''), ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_reg2, v_des2, v_res2, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor salida: el principal sale tras la recepción', '100|SALE', v_cod::TEXT || '|' || v_res2, v_msg);
    PERFORM pg_temp.chk('Proveedor salida: al salir el principal queda libre la exclusa', 'true', pg_temp.q('SELECT ("ID_Solicitud_Actual" IS NULL)::TEXT FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves), '');
    PERFORM pg_temp.chk('Proveedor salida: sin nadie dentro la entrega pasa a SALIO', 'SALIO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sb), '');
    PERFORM pg_temp.chk('Proveedor: el historial operativo tiene los 6 pasos en orden', 'PROGRAMADO>EN_ESPERA>INGRESO>EN_ATENCION>RECEPCIONADO>SALIO',
        pg_temp.q('SELECT STRING_AGG("Estado_Nuevo", ''>'' ORDER BY "ID_Operacion_Evento") FROM "CAF_Solicitud_Operacion_Evento" WHERE "ID_Solicitud" = ' || v_sb || ' AND "Estado_Nuevo" <> COALESCE("Estado_Anterior", '''')'), '');
    PERFORM pg_temp.chk('Proveedor salida: tras la salida Almacén ya no va en copia', 'false', pg_temp.q('SELECT COALESCE("ERP_CAF_FN_COPIA_CORREO"(' || v_sb || ', ''N'', ''N'', ''N'', ''N'') LIKE ''%almacen.prov@ejemplo.pe%'', false)'), '');
    PERFORM pg_temp.chk('Proveedor: las fechas de cada etapa quedan registradas', 'true', pg_temp.q('SELECT (Fecha_Llegada IS NOT NULL AND Fecha_Ingreso IS NOT NULL AND Fecha_Inicio_Atencion IS NOT NULL AND Fecha_Recepcion IS NOT NULL AND Fecha_Salida IS NOT NULL)::TEXT FROM (SELECT "Fecha_Llegada" AS Fecha_Llegada, "Fecha_Ingreso" AS Fecha_Ingreso, "Fecha_Inicio_Atencion" AS Fecha_Inicio_Atencion, "Fecha_Recepcion" AS Fecha_Recepcion, "Fecha_Salida" AS Fecha_Salida FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sb || ') X'), '');

    -- La verificación (llegada) solo el día programado
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fut, 'Otra Carga S.A.', NULL, NULL, NULL, NULL, v_q3::TEXT, NULL, NULL, NULL, 'GHI789', NULL, NULL, '977666555', NULL, v_emp, '20111111111', 'Calle 1', 'Isuzu', 'Q11111111', v_q3, v_usp, v_sc2, v_cs2, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sc2, v_paso_p, 'APROBADA', NULL, pg_temp.sp(v_sc2, v_q3)::TEXT, v_ucp, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor verificación: una entrega de otra fecha no se verifica hoy', '409|', pg_temp.verif(pg_temp.sp(v_sc2, v_q3), v_uvp), '');
    PERFORM pg_temp.chk('Proveedor verificación: una solicitud cancelada no tiene entrega activa', '409|', pg_temp.verif(pg_temp.sp(v_sa, v_q1), v_uvp), '');
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_sc2, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso físico: una entrega sin verificar no se valida', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(999999, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor ingreso físico: solicitud inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(999999, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor disponibilidad: solicitud inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_sc2, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor disponibilidad: una entrega aún PROGRAMADA no la recibe', '409', v_cod::TEXT, v_msg);

    -- No se presentó: sigue PROGRAMADO durante su día; al cierre pasa a NO_SE_PRESENTO (usuario 0)
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fhoy, 'Se Fue S.A.', NULL, NULL, NULL, NULL, v_q3::TEXT, NULL, NULL, NULL, 'JKL012', NULL, NULL, '966555444', NULL, v_emp, '20222222222', 'Calle 2', 'Fuso', 'Q22222222', v_q3, v_usp, v_sd, v_cs2, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sd, v_paso_p, 'APROBADA', NULL, pg_temp.sp(v_sd, v_q3)::TEXT, v_ucp, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(CURRENT_DATE, 0, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor no se presentó: durante su día sigue PROGRAMADO', 'PROGRAMADO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sd), '');
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = "Fecha_Hora_Prevista" - INTERVAL '1 day' WHERE "ID_Solicitud" = v_sd;
    CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(CURRENT_DATE, 0, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Proveedor no se presentó: el cierre del día lo marca', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Proveedor no se presentó: pasa a NO_SE_PRESENTO con evento del sistema', 'NO_SE_PRESENTO|0',
        pg_temp.q('SELECT O."Estado_Operativo" || ''|'' || (SELECT E."ID_Usuario" FROM "CAF_Solicitud_Operacion_Evento" E WHERE E."ID_Solicitud" = O."ID_Solicitud" ORDER BY E."ID_Operacion_Evento" DESC LIMIT 1) FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = ' || v_sd), '');
    PERFORM pg_temp.chk('Proveedor no se presentó: ya no se verifica', '409|', pg_temp.verif(pg_temp.sp(v_sd, v_q3), v_uvp), '');
    PERFORM pg_temp.chk('Proveedor no se presentó: la entrega en curso (EN_ESPERA) no se marca por error', 'SALIO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sb), '');

    -- ===================================================== O2. CIERRE FORZADO DEL DÍA (D-218)
    DECLARE v_sx BIGINT; v_px BIGINT; v_n INT; v_cz INT; v_csx VARCHAR(20); v_reg2 BIGINT; v_des2 BIGINT; v_res2 VARCHAR(30);
    BEGIN
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fhoy, 'Cierre Forzado S.A.', NULL, NULL, NULL, NULL, v_q3::TEXT, NULL, NULL, NULL, 'MNO345', NULL, NULL, '955444333', NULL, v_emp, '20333333333', 'Calle 3', 'Hino', 'Q33333333', v_q3, v_usp, v_sx, v_csx, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sx, v_paso_p, 'APROBADA', NULL, pg_temp.sp(v_sx, v_q3)::TEXT, v_ucp, v_cant, v_cod, v_msg);
    v_px := pg_temp.sp(v_sx, v_q3);
    PERFORM pg_temp.chk('Cierre: la hora de corte por defecto es 00:00', '00:00', pg_temp.q('SELECT "ERP_CAF_PARAMETRO_VALOR"(''PROVEEDOR_HORA_CORTE'')'), '');
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('PROVEEDOR_HORA_CORTE', '25:61', v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Cierre: una hora de corte inválida se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('NO_EXISTE', '1', v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Cierre: un parámetro inexistente es 404', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('PROVEEDOR_HORA_CORTE', '03:30', v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Cierre: la hora de corte se puede cambiar', '100|03:30', v_cod::TEXT || '|' || pg_temp.q('SELECT "ERP_CAF_PARAMETRO_VALOR"(''PROVEEDOR_HORA_CORTE'')'), v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('PROVEEDOR_HORA_CORTE', '00:00', v_uvp, v_cod, v_msg);

    -- Entrega RECEPCIONADA (camión dentro, exclusa ocupada) y su persona principal DENTRO
    UPDATE "CAF_Solicitud_Operacion" SET "Estado_Operativo" = 'RECEPCIONADO', "Fecha_Recepcion" = CURRENT_TIMESTAMP - INTERVAL '2 hours' WHERE "ID_Solicitud" = v_sx;
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'DENTRO', "Fecha_Hora_Ingreso" = CURRENT_TIMESTAMP - INTERVAL '3 hours' WHERE "ID_Solicitud_Persona" = v_px;
    UPDATE "CAF_Exclusa" SET "ID_Solicitud_Actual" = v_sx WHERE "ID_Catalogo_Sede" = v_ves;

    CALL "ERP_CAF_PROVEEDOR_AVISOS_SALIDA"(v_uvp, v_n, v_cod, v_msg);
    PERFORM pg_temp.chk('Cierre aviso: la entrega recepcionada hace 2 h genera un aviso', '100|1', v_cod::TEXT || '|' || v_n, v_msg);
    PERFORM pg_temp.chk('Cierre aviso: queda encolado PROVEEDOR_AVISO para Vigilancia', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "Tipo" = ''PROVEEDOR_AVISO'' AND "ID_Solicitud" = ' || v_sx), '');
    CALL "ERP_CAF_PROVEEDOR_AVISOS_SALIDA"(v_uvp, v_n, v_cod, v_msg);
    PERFORM pg_temp.chk('Cierre aviso: no se repite antes de una hora', '0', v_n::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Operacion" SET "Ultimo_Aviso_Salida" = CURRENT_TIMESTAMP - INTERVAL '2 hours' WHERE "ID_Solicitud" = v_sx;
    CALL "ERP_CAF_PROVEEDOR_AVISOS_SALIDA"(v_uvp, v_n, v_cod, v_msg);
    PERFORM pg_temp.chk('Cierre aviso: pasada la hora se avisa otra vez', '1|2', v_n || '|' || pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "Tipo" = ''PROVEEDOR_AVISO'' AND "ID_Solicitud" = ' || v_sx), '');

    CALL "ERP_CAF_PROVEEDOR_CIERRE_DIA"(0, v_cz, v_cod, v_msg);
    PERFORM pg_temp.chk('Cierre: durante su día la entrega no se cierra', 'RECEPCIONADO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sx), v_msg);

    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = "Fecha_Hora_Prevista" - INTERVAL '1 day' WHERE "ID_Solicitud" = v_sx;
    CALL "ERP_CAF_PROVEEDOR_CIERRE_DIA"(0, v_cz, v_cod, v_msg);
    PERFORM pg_temp.chk('Cierre: al día siguiente la entrega abierta pasa a CIERRE_FORZADO', '100|CIERRE_FORZADO', v_cod::TEXT || '|' || pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sx), v_msg);
    PERFORM pg_temp.chk('Cierre: se libera la exclusa', 'libre', pg_temp.q('SELECT COALESCE("ID_Solicitud_Actual"::TEXT, ''libre'') FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves), '');
    PERFORM pg_temp.chk('Cierre: quien estaba DENTRO sigue DENTRO (puede registrarse su salida)', 'DENTRO', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_px), '');
    PERFORM pg_temp.chk('Cierre: queda en el historial como acción del sistema', 'CIERRE_FORZADO|0', pg_temp.q('SELECT "Estado_Nuevo" || ''|'' || "ID_Usuario" FROM "CAF_Solicitud_Operacion_Evento" WHERE "ID_Solicitud" = ' || v_sx || ' ORDER BY "ID_Operacion_Evento" DESC LIMIT 1'), '');
    CALL "ERP_CAF_PROVEEDOR_CIERRE_DIA"(0, v_cz, v_cod, v_msg);
    PERFORM pg_temp.chk('Cierre: es idempotente (la segunda vez no cierra nada)', '100|0', v_cod::TEXT || '|' || v_cz, v_msg);
    CALL "ERP_CAF_PROVEEDOR_AVISOS_SALIDA"(v_uvp, v_n, v_cod, v_msg);
    PERFORM pg_temp.chk('Cierre aviso: una entrega cerrada ya no genera avisos', '0', v_n::TEXT, v_msg);

    -- Hora de corte configurable: con corte 23:59 el "día operativo" aún es el de ayer, y una entrega de ayer no se cierra
    UPDATE "CAF_Solicitud_Operacion" SET "Estado_Operativo" = 'EN_ESPERA' WHERE "ID_Solicitud" = v_sx;
    UPDATE "CAF_Parametro" SET "Valor" = '23:59' WHERE "Clave" = 'PROVEEDOR_HORA_CORTE';
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = CURRENT_TIMESTAMP - INTERVAL '23 hours' WHERE "ID_Solicitud" = v_sx AND CURRENT_TIME > TIME '00:01';
    CALL "ERP_CAF_PROVEEDOR_CIERRE_DIA"(0, v_cz, v_cod, v_msg);
    UPDATE "CAF_Parametro" SET "Valor" = '00:00' WHERE "Clave" = 'PROVEEDOR_HORA_CORTE';
    UPDATE "CAF_Solicitud_Operacion" SET "Estado_Operativo" = 'CIERRE_FORZADO' WHERE "ID_Solicitud" = v_sx;
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = CURRENT_TIMESTAMP - INTERVAL '1 day' WHERE "ID_Solicitud" = v_sx;

    -- Salida tardía
    PERFORM pg_temp.chk('Cierre regla: ya no se pide verificar la entrega cerrada', '409', pg_temp.q('SELECT (SELECT "Codigo_Resp" FROM "ERP_CAF_PROVEEDOR_REGLA"(' || v_px || ', ''INGRESO''))'), '');
    PERFORM pg_temp.chk('Cierre salida tardía: Vigilancia aún lo ve en su lista de hoy', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_uvp || ', NULL, CURRENT_DATE) WHERE "ID_Solicitud_Persona" = ' || v_px), '');
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_px, COALESCE(pg_temp.items(v_px, 'SALIDA', 'N', 'N', ''), ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_reg2, v_des2, v_res2, v_cod, v_msg);
    PERFORM pg_temp.chk('Cierre salida tardía: Vigilancia registra la salida', '100|SALE', v_cod::TEXT || '|' || v_res2, v_msg);
    PERFORM pg_temp.chk('Cierre salida tardía: la entrega pasa a SALIO', 'SALIO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sx), v_msg);
    PERFORM pg_temp.chk('Cierre salida tardía: se avisa al Coordinador', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "Tipo" = ''PROVEEDOR_AVISO'' AND "ID_Solicitud" = ' || v_sx || ' AND "Asunto" LIKE ''Salida tardía%'''), '');
    PERFORM pg_temp.chk('Cierre salida tardía: no vuelve a ocupar la exclusa', 'libre', pg_temp.q('SELECT COALESCE("ID_Solicitud_Actual"::TEXT, ''libre'') FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves), '');
    END;

    -- ===================================================== P. CALENDARIO DE ENTREGAS DE ALMACÉN (Entrega 2)
    DECLARE
        v_lic_da BIGINT; v_ual2 BIGINT; v_ud BIGINT; v_pal1 BIGINT; v_pal2 BIGINT; v_palv BIGINT;
        v_qa BIGINT; v_qb BIGINT; v_qc BIGINT; v_qd BIGINT; v_s1 BIGINT; v_s2 BIGINT; v_s3 BIGINT; v_spend BIGINT;
        v_p1 BIGINT; v_p2 BIGINT; v_p3 BIGINT; v_cs3 VARCHAR(20); v_qe BIGINT; v_qf BIGINT; v_s4 BIGINT; v_s5 BIGINT; v_t_den BIGINT; v_t_rest BIGINT; v_it3 TEXT; v_r3 BIGINT; v_d3 BIGINT; v_x3 VARCHAR(30); v_n3 INT;
    BEGIN
    SELECT "ID_Catalogo_Licencia" INTO v_lic_da FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_PROVEEDOR_DASHBOARD';
    PERFORM pg_temp.chk('Dashboard: la licencia de solo lectura tiene un único permiso', 'PER_CAF_PROVEEDOR_DASHBOARD',
        pg_temp.q('SELECT STRING_AGG(P."Codigo", '','') FROM "CAF_GOVERNANCE"."Licencia_Permiso" LP JOIN "CAF_GOVERNANCE"."Catalogo_Permiso" P ON P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso" WHERE LP."ID_Catalogo_Licencia" = ' || v_lic_da), '');
    PERFORM pg_temp.chk('Dashboard: lo traen la licencia nueva y la de Almacén, ninguna otra', 'LIC_CAF_ALMACEN,LIC_CAF_PROVEEDOR_DASHBOARD',
        pg_temp.q('SELECT STRING_AGG(L."Codigo", '','' ORDER BY L."Codigo") FROM "CAF_GOVERNANCE"."Licencia_Permiso" LP JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = LP."ID_Catalogo_Licencia" JOIN "CAF_GOVERNANCE"."Catalogo_Permiso" P ON P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso" WHERE P."Codigo" = ''PER_CAF_PROVEEDOR_DASHBOARD'''), '');
    PERFORM pg_temp.chk('Dashboard: la esclusa de VES existe y está libre', 'true',
        pg_temp.q('SELECT (COUNT(*) = 1 AND MAX("ID_Solicitud_Actual") IS NULL)::TEXT FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves), '');

    CALL "ERP_USUARIO_CREAR"('almacen2.prov@ejemplo.pe', v_dni,'30000006','Almacen','Dos','Ana',NULL,'Ejemplo','Y',0, v_ual2, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('dash.prov@ejemplo.pe',    v_dni,'30000007','Lectura','Dash','Dora',NULL,'Ejemplo','Y',0, v_ud, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_ual2, v_lic_al, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_ud, v_lic_da, v_ves, 0, v_ul, v_cod, v_msg);
    -- Los usuarios de Almacén y de Vigilancia son personal de la empresa: se les crea su ficha y se vincula
    INSERT INTO "CAF_GOVERNANCE"."Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","UsuarioID_Create")
    VALUES (v_dni,'20000001','Almacen Uno','Alma',v_area,v_emp,v_ves,'almacen.prov@ejemplo.pe',0) RETURNING "ID_Personal" INTO v_pal1;
    INSERT INTO "CAF_GOVERNANCE"."Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","UsuarioID_Create")
    VALUES (v_dni,'20000002','Almacen Dos','Ana',v_area,v_emp,v_ves,'almacen2.prov@ejemplo.pe',0) RETURNING "ID_Personal" INTO v_pal2;
    INSERT INTO "CAF_GOVERNANCE"."Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","UsuarioID_Create")
    VALUES (v_dni,'20000003','Vigilancia Prov','Victor',v_area,v_emp,v_ves,'vigprov@ejemplo.pe',0) RETURNING "ID_Personal" INTO v_palv;
    UPDATE "CAF_GOVERNANCE"."Usuario" SET "ID_Personal" = v_pal1 WHERE "ID_Usuario" = v_ual;
    UPDATE "CAF_GOVERNANCE"."Usuario" SET "ID_Personal" = v_pal2 WHERE "ID_Usuario" = v_ual2;
    UPDATE "CAF_GOVERNANCE"."Usuario" SET "ID_Personal" = v_palv WHERE "ID_Usuario" = v_uvp;

    -- Responsables posibles
    PERFORM pg_temp.chk('Responsables: Almacén ve solo al personal con licencia de Almacén (2)', '2|true',
        pg_temp.q('SELECT COUNT(*) || ''|'' || BOOL_AND("ID_Personal" IN (' || v_pal1 || ',' || v_pal2 || ')) FROM "ERP_CAF_PROVEEDOR_RESPONSABLES"(' || v_ual || ',' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Responsables: quien solo lee el dashboard no recibe la lista', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_RESPONSABLES"(' || v_ud || ',' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Responsables: Vigilancia no recibe la lista', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_RESPONSABLES"(' || v_uvp || ',' || v_ves || ')'), '');

    -- Entregas del calendario: tres de hoy en INGRESO y una pendiente sin aprobar
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000011','Chofer','Uno','Ulises',0, v_qa, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000012','Chofer','Dos','Dario',0,  v_qb, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000013','Chofer','Tres','Tomas',0, v_qc, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000014','Chofer','Cuatro','Quino',0, v_qd, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fhoy, 'Pendiente S.A.', NULL, NULL, NULL, NULL, v_qd::TEXT, NULL, NULL, NULL, 'PEN111', NULL, NULL, '911222333', NULL, v_emp, '20333333333', 'Calle 3', 'Isuzu', 'Q33333333', v_qd, v_usp, v_spend, v_cs3, v_cod, v_msg);
    PERFORM pg_temp.chk('Calendario: solicitud pendiente creada', '100', v_cod::TEXT, v_msg);
    FOR v_n3 IN 1..3 LOOP
        CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fhoy, 'Proveedor ' || v_n3 || ' S.A.', NULL, NULL, NULL, NULL,
              (CASE v_n3 WHEN 1 THEN v_qa WHEN 2 THEN v_qb ELSE v_qc END)::TEXT, NULL, NULL, NULL, 'AAA10' || v_n3, NULL, NULL, '9112223' || v_n3 || '0', NULL, v_emp, '2044444444' || v_n3, 'Calle ' || v_n3, 'Volvo', 'Q4444444' || v_n3,
              (CASE v_n3 WHEN 1 THEN v_qa WHEN 2 THEN v_qb ELSE v_qc END), v_usp, v_r3, v_cs3, v_cod, v_msg);
        IF v_n3 = 1 THEN v_s1 := v_r3; ELSIF v_n3 = 2 THEN v_s2 := v_r3; ELSE v_s3 := v_r3; END IF;
        v_p1 := pg_temp.sp(v_r3, (CASE v_n3 WHEN 1 THEN v_qa WHEN 2 THEN v_qb ELSE v_qc END));
        CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_r3, v_paso_p, 'APROBADA', NULL, v_p1::TEXT, v_ucp, v_cant, v_cod, v_msg);
        v_it3 := pg_temp.q('SELECT STRING_AGG("ID_Catalogo_Item_Checklist" || '':Y'', '','') FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_p1 || ', ''INGRESO'', ''N'', ''N'')');
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, v_it3, 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_r3, v_d3, v_x3, v_cod, v_msg);
    END LOOP;
    PERFORM pg_temp.chk('Calendario: las tres entregas del día quedan verificadas, en EN_ESPERA (ninguna ingresó)', 'EN_ESPERA,EN_ESPERA,EN_ESPERA',
        pg_temp.q('SELECT STRING_AGG("Estado_Operativo", '','') FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" IN (' || v_s1 || ',' || v_s2 || ',' || v_s3 || ')'), '');

    -- Visibilidad
    PERFORM pg_temp.chk('Calendario: sin el permiso del dashboard no se ve nada (Vigilancia aún sin la licencia)', '0',
        pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_uvp || ',' || v_ves || ', NULL, NULL)'), '');
    PERFORM pg_temp.chk('Calendario: Abastecimiento sin la licencia nueva no lo ve', '0',
        pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_usp || ',' || v_ves || ', NULL, NULL)'), '');
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_uvp, v_lic_da, v_ves, 0, v_ul, v_cod, v_msg);
    PERFORM pg_temp.chk('Calendario: Vigilancia con la licencia de lectura lo ve', 'true',
        pg_temp.q('SELECT (COUNT(*) >= 3)::TEXT FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_uvp || ',' || v_ves || ', NULL, NULL)'), '');
    PERFORM pg_temp.chk('Calendario: la solicitud pendiente no aparece', '0',
        pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ud || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_spend), '');
    PERFORM pg_temp.chk('Calendario: la solicitud cancelada no aparece', '0',
        pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ud || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Calendario: la entrega aprobada sí aparece, con su empresa y transportista principal', 'Proveedor 1 S.A.|Chofer Uno Ulises',
        pg_temp.q('SELECT "Empresa_Proveedor" || ''|'' || SPLIT_PART("Transportista", '', '', 1) || '' '' || SPLIT_PART("Transportista", '', '', 2) FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ud || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Calendario: el filtro por fechas excluye otros días', '0',
        pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ud || ',' || v_ves || ', CURRENT_DATE + 30, CURRENT_DATE + 31)'), '');
    PERFORM pg_temp.chk('Calendario: solo lectura, el usuario del dashboard no tiene ningún botón', 'N|N|N|N|N',
        pg_temp.q('SELECT "Puede_Programar" || ''|'' || "Puede_Confirmar" || ''|'' || "Puede_Cancelar_Disp" || ''|'' || "Puede_Atender" || ''|'' || "Puede_Terminar" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ud || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Calendario: Almacén puede programar y confirmar disponibilidad de una entrega verificada', 'Y|Y|N|N|N',
        pg_temp.q('SELECT "Puede_Programar" || ''|'' || "Puede_Confirmar" || ''|'' || "Puede_Cancelar_Disp" || ''|'' || "Puede_Atender" || ''|'' || "Puede_Terminar" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s1), '');

    -- Responsable programado
    CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_sc2, v_pal1, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Programar: Vigilancia (aunque lea el dashboard) no asigna', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_sc2, v_pal1, v_ud, v_cod, v_msg);
    PERFORM pg_temp.chk('Programar: quien solo lee el dashboard no asigna', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_sc2, v_palv, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Programar: no se puede elegir a quien no es de Almacén', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(999999, v_pal1, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Programar: solicitud inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_sa, v_pal1, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Programar: una solicitud cancelada no tiene entrega activa', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_sc2, v_pal1, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Programar: Almacén asigna con anticipación (entrega de otra fecha)', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Programar: queda el programado, quién lo asignó y cuándo', 'true|' || v_ual,
        pg_temp.q('SELECT ("ID_Personal_Programado" = ' || v_pal1 || ' AND "Fecha_Programacion" IS NOT NULL)::TEXT || ''|'' || "ID_Usuario_Programacion" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sc2), '');
    PERFORM pg_temp.chk('Programar: el estado operativo no cambia', 'PROGRAMADO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sc2), '');
    CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_sc2, v_pal1, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Programar: repetir lo mismo no cambia nada', '100|Sin cambios.', v_cod::TEXT || '|' || v_msg, '');
    CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_sc2, v_pal2, v_ual2, v_cod, v_msg);
    PERFORM pg_temp.chk('Programar: otro trabajador de Almacén puede cambiarlo', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Programar: el historial conserva a ambos programados en orden', v_pal1 || '>' || v_pal2,
        pg_temp.q('SELECT STRING_AGG("ID_Personal_Programado"::TEXT, ''>'' ORDER BY "ID_Operacion_Evento") FROM "CAF_Solicitud_Operacion_Evento" WHERE "ID_Solicitud" = ' || v_sc2 || ' AND "ID_Personal_Programado" IS NOT NULL'), '');
    PERFORM pg_temp.chk('Programar: el calendario muestra al programado', 'true',
        pg_temp.q('SELECT (POSITION(''Almacen Dos'' IN "Programado_Nombre") > 0)::TEXT FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ud || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_sc2), '');
    CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_sc2, NULL, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Programar: se puede quitar', '100|true', v_cod::TEXT || '|' || pg_temp.q('SELECT ("ID_Personal_Programado" IS NULL)::TEXT FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_sc2), v_msg);
    PERFORM pg_temp.chk('Programar: quitarlo también queda en el historial', '3',
        pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Operacion_Evento" WHERE "ID_Solicitud" = ' || v_sc2 || ' AND "Observacion" ILIKE ''%responsable programado%'''), '');

    -- Atender: día programado
    UPDATE "CAF_Solicitud_Operacion" SET "Estado_Operativo" = 'INGRESO' WHERE "ID_Solicitud" = v_sc2;
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_sc2, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Atender: una entrega de otra fecha no se atiende hoy', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Operacion" SET "Estado_Operativo" = 'PROGRAMADO' WHERE "ID_Solicitud" = v_sc2;

    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_den  FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'DENEGATORIA';
    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_rest FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'RESTRICCION_ZONA_ADM';

    -- Disponibilidad de Almacén = reserva de la esclusa (una sola a la vez)
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s1, v_ud, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: quien solo lee el dashboard no confirma', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s1, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: Vigilancia no confirma por Almacén', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_sc2, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: una entrega de otra fecha no recibe la confirmación', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Operacion" SET "Estado_Operativo" = 'EN_ESPERA' WHERE "ID_Solicitud" = v_sc2;
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_sc2, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: solo se confirma el día programado aunque ya esté verificada', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Operacion" SET "Estado_Operativo" = 'PROGRAMADO' WHERE "ID_Solicitud" = v_sc2;

    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s1, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: Almacén confirma la primera y reserva la esclusa', '100|' || v_s1, v_cod::TEXT || '|' || pg_temp.q('SELECT "ID_Solicitud_Actual" FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves), v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s1, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: repetir sobre la misma no cambia nada', '100|La disponibilidad ya estaba confirmada.', v_cod::TEXT || '|' || v_msg, '');
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s2, v_ual2, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: con la esclusa reservada, la segunda es 409', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: el mensaje avisa de la otra reserva', 'true', (POSITION('reservada para otra entrega' IN v_msg) > 0)::TEXT, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: la segunda no queda marcada', 'true', pg_temp.q('SELECT ("Fecha_Disponibilidad" IS NULL)::TEXT FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s2), '');
    PERFORM pg_temp.chk('Calendario: la reservada muestra Almacén listo y solo ofrece cancelar', 'Y|N|Y|true',
        pg_temp.q('SELECT "Disponibilidad_Confirmada" || ''|'' || "Puede_Confirmar" || ''|'' || "Puede_Cancelar_Disp" || ''|'' || ("Fecha_Disponibilidad" IS NOT NULL)::TEXT FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Calendario: la otra no puede confirmar y dice que la esclusa está reservada', 'N|N|true',
        pg_temp.q('SELECT "Puede_Confirmar" || ''|'' || "Puede_Cancelar_Disp" || ''|'' || (POSITION(''reservada'' IN "Motivo_Bloqueo") > 0)::TEXT FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s2), '');
    PERFORM pg_temp.chk('Esclusa estado: RESERVADA para la primera', 'Y|RESERVADA|' || v_s1,
        pg_temp.q('SELECT "Ocupada" || ''|'' || "Estado" || ''|'' || "ID_Solicitud" FROM "ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO"(' || v_ud || ',' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Esclusa estado: sin el permiso del dashboard no se informa', '0',
        pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO"(' || v_usp || ',' || v_ves || ')'), '');
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_s2, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso físico: la entrega sin reserva no ingresa mientras otra tiene la esclusa', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_s1, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Atender: con solo la reserva (sin ingreso físico) no se atiende', '409', v_cod::TEXT, v_msg);

    -- Cancelar la disponibilidad (el proveedor no vino, otro espera)
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR"(v_s1, NULL, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar disponibilidad: el motivo es obligatorio', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR"(v_s1, 'No llegó a tiempo', v_ud, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar disponibilidad: quien solo lee el dashboard no cancela', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR"(v_s1, 'No llegó a tiempo', v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar disponibilidad: Vigilancia no cancela', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR"(v_s2, 'No tiene reserva', v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar disponibilidad: la entrega sin reserva no se cancela', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR"(v_s1, 'El proveedor no llegó a tiempo', v_ual2, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar disponibilidad: otro trabajador de Almacén la cancela con motivo', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Cancelar disponibilidad: la esclusa queda libre y la entrega sin marca', 'true|true',
        pg_temp.q('SELECT (X."ID_Solicitud_Actual" IS NULL)::TEXT || ''|'' || (O."Fecha_Disponibilidad" IS NULL)::TEXT FROM "CAF_Exclusa" X, "CAF_Solicitud_Operacion" O WHERE X."ID_Catalogo_Sede" = ' || v_ves || ' AND O."ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Cancelar disponibilidad: quedan quién, cuándo y por qué, y la entrega sigue EN_ESPERA', v_ual2 || '|El proveedor no llegó a tiempo|EN_ESPERA|true',
        pg_temp.q('SELECT "ID_Usuario_Cancelacion_Disp" || ''|'' || "Motivo_Cancelacion_Disp" || ''|'' || "Estado_Operativo" || ''|'' || ("Fecha_Cancelacion_Disp" IS NOT NULL)::TEXT FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Cancelar disponibilidad: el historial conserva la confirmación y la cancelación con su motivo', 'DISP_CONFIRMADA>DISP_CANCELADA|El proveedor no llegó a tiempo',
        pg_temp.q('SELECT STRING_AGG("Resultado", ''>'' ORDER BY "ID_Operacion_Evento") || ''|'' || MAX(CASE WHEN "Resultado" = ''DISP_CANCELADA'' THEN "Observacion" END) FROM "CAF_Solicitud_Operacion_Evento" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Resultado" IS NOT NULL'), '');
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR"(v_s1, 'Otra vez', v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar disponibilidad: ya cancelada es 409', '409', v_cod::TEXT, v_msg);

    -- Retiro sin ingresar (Vigilancia): verificado, con reserva, y se va sin ingresar
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s1, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Retiro sin ingresar: se prepara con la reserva puesta', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RETIRO_SIN_INGRESO"(v_s1, NULL, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Retiro sin ingresar: el motivo es obligatorio', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RETIRO_SIN_INGRESO"(v_s1, 'Se fue por la demora', v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Retiro sin ingresar: Almacén no lo registra (es de Vigilancia)', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RETIRO_SIN_INGRESO"(v_s1, 'Se fue por la demora', v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Retiro sin ingresar: Vigilancia lo registra', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Retiro sin ingresar: estado, persona y exclusa libre', 'RETIRO_SIN_INGRESO|NO_SE_PRESENTO|true',
        pg_temp.q('SELECT O."Estado_Operativo" || ''|'' || (SELECT P."Estado" FROM "CAF_Solicitud_Persona" P WHERE P."ID_Solicitud" = ' || v_s1 || ' AND P."Es_Principal" = ''Y'') || ''|'' || (SELECT ("ID_Solicitud_Actual" IS NULL)::TEXT FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves || ') FROM "CAF_Solicitud_Operacion" O WHERE O."ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Retiro sin ingresar: el historial guarda el motivo', 'Retiro sin ingresar: Se fue por la demora',
        pg_temp.q('SELECT "Observacion" FROM "CAF_Solicitud_Operacion_Evento" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Estado_Nuevo" = ''RETIRO_SIN_INGRESO'''), '');
    CALL "ERP_CAF_PROVEEDOR_RETIRO_SIN_INGRESO"(v_s1, 'Otra vez', v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Retiro sin ingresar: repetido es 409', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_s1, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Retiro sin ingresar: ya no se valida su ingreso', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Vigilancia lista: la retirada figura con su estado operativo', 'Y|RETIRO_SIN_INGRESO|N',
        pg_temp.q('SELECT "Es_Proveedor" || ''|'' || "Estado_Operativo" || ''|'' || "Disponibilidad_Confirmada" FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_uvp || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Es_Proveedor" = ''Y'''), '');

    -- La esclusa liberada pasa a quien sí llegó
    CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_s2, v_pal2, v_ual, v_cod, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s2, v_ual2, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: liberada la esclusa, la segunda la reserva', '100|' || v_s2, v_cod::TEXT || '|' || pg_temp.q('SELECT "ID_Solicitud_Actual" FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves), v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s1, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: la primera ya no puede reservar mientras la segunda la tiene', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Vigilancia lista: con la reserva puesta ve EN_ESPERA y Almacén listo', 'Y|EN_ESPERA|Y',
        pg_temp.q('SELECT "Es_Proveedor" || ''|'' || "Estado_Operativo" || ''|'' || "Disponibilidad_Confirmada" FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_uvp || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Es_Proveedor" = ''Y'''), '');
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_s2, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso físico: la segunda, con la reserva, ingresa', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RETIRO_SIN_INGRESO"(v_s2, 'Ya estaba dentro', v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Retiro sin ingresar: tras el ingreso físico no se puede', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR"(v_s2, 'Ya ingresó', v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar disponibilidad: tras el ingreso no se puede', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Esclusa estado: con el proveedor adentro figura DENTRO', 'Y|DENTRO|' || v_s2,
        pg_temp.q('SELECT "Ocupada" || ''|'' || "Estado" || ''|'' || "ID_Solicitud" FROM "ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO"(' || v_ud || ',' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Calendario: dentro y con la esclusa propia, Atender se habilita solo para Almacén', 'Y|N',
        pg_temp.q('SELECT (SELECT "Puede_Atender" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s2 || ') || ''|'' || (SELECT "Puede_Atender" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ud || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s2 || ')'), '');

    -- Atender: el efectivo es quien pulsa; el programado se conserva
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_s2, v_ud, v_cod, v_msg);
    PERFORM pg_temp.chk('Atender: quien solo lee el dashboard no atiende', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_s2, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Atender: Almacén inicia la atención de la entrega con la esclusa', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Atender: programado y efectivo son personas distintas y ambos quedan', v_pal2 || '|' || v_ual || '|' || v_pal1,
        pg_temp.q('SELECT "ID_Personal_Programado" || ''|'' || "ID_Usuario_Atencion" || ''|'' || "ID_Personal_Almacen" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s2), '');
    PERFORM pg_temp.chk('Atender: la esclusa sigue siendo de esta entrega', v_s2::TEXT, pg_temp.q('SELECT "ID_Solicitud_Actual" FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves), '');
    CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_s2, v_pal1, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Programar: ya iniciada la atención no se cambia el programado', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s3, v_ual2, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: con una atención en curso nadie más reserva', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Calendario: en atención ofrece Terminar solo a Almacén y no permite reprogramar', 'N|Y|N',
        pg_temp.q('SELECT (SELECT "Puede_Terminar" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ud || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s2 || ') || ''|'' || ' ||
                  '(SELECT "Puede_Terminar" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual2 || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s2 || ') || ''|'' || ' ||
                  '(SELECT "Puede_Programar" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual2 || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s2 || ')'), '');
    PERFORM pg_temp.chk('Calendario: la que espera dice que la esclusa está reservada', 'N|true',
        pg_temp.q('SELECT "Puede_Confirmar" || ''|'' || (POSITION(''reservada'' IN "Motivo_Bloqueo") > 0)::TEXT FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual2 || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s3), '');

    -- Terminar libera la esclusa; cualquiera de Almacén puede terminar
    CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_s2, 'CONFORME', NULL, v_ud, v_cod, v_msg);
    PERFORM pg_temp.chk('Terminar: quien solo lee el dashboard no termina', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_s2, 'CONFORME', NULL, v_ual2, v_cod, v_msg);
    PERFORM pg_temp.chk('Terminar: otro trabajador de Almacén culmina la atención', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Terminar: la exclusa sigue ocupada hasta la salida y figura POR_SALIR', v_s2 || '|POR_SALIR',
        pg_temp.q('SELECT "ID_Solicitud" || ''|'' || "Estado" FROM "ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO"(' || v_ud || ',' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Terminar: quién inició y quién terminó quedan por separado', v_ual || '|' || v_ual2,
        pg_temp.q('SELECT "ID_Usuario_Atencion" || ''|'' || "ID_Usuario_Recepcion" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s2), '');

    -- Reserva huérfana: la esclusa apunta a una entrega que ya no está vigente
    UPDATE "CAF_Exclusa" SET "ID_Solicitud_Actual" = v_sb WHERE "ID_Catalogo_Sede" = v_ves;
    PERFORM pg_temp.chk('Esclusa estado: una reserva huérfana se muestra como LIBRE', 'N|LIBRE',
        pg_temp.q('SELECT "Ocupada" || ''|'' || "Estado" FROM "ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO"(' || v_ud || ',' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Calendario: con una reserva huérfana se puede confirmar', 'Y',
        pg_temp.q('SELECT "Puede_Confirmar" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s3), '');
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s3, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: una reserva huérfana no bloquea', '100|' || v_s3, v_cod::TEXT || '|' || pg_temp.q('SELECT "ID_Solicitud_Actual" FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves), v_msg);

    -- Si la entrega pierde su aprobación antes del ingreso, la reserva se libera
    UPDATE "CAF_Solicitud_Persona" SET "Aprobacion" = 'PENDIENTE' WHERE "ID_Solicitud" = v_s3 AND "Es_Principal" = 'Y';
    CALL "ERP_CAF_PROVEEDOR_SINCRONIZAR"(v_s3, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Dashboard: la entrega que perdió la aprobación en EN_ESPERA vuelve a PROGRAMADO (se verifica de nuevo)', 'PROGRAMADO|N', pg_temp.q('SELECT "Estado_Operativo" || ''|'' || "Activa" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s3), '');
    PERFORM pg_temp.chk('Dashboard: la entrega que pierde la aprobación desaparece del calendario', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s3), '');
    PERFORM pg_temp.chk('Sincronizar: sin aprobación del principal la reserva se libera', 'true', pg_temp.q('SELECT ("ID_Solicitud_Actual" IS NULL)::TEXT FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves), '');
    UPDATE "CAF_Solicitud_Persona" SET "Aprobacion" = 'APROBADA' WHERE "ID_Solicitud" = v_s3 AND "Es_Principal" = 'Y';
    CALL "ERP_CAF_PROVEEDOR_SINCRONIZAR"(v_s3, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Dashboard: al reaprobarse la entrega vuelve al calendario', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s3), '');
    PERFORM pg_temp.chk('Dashboard: Es_Solicitante es N para quien no creó la solicitud', 'N', pg_temp.q('SELECT "Es_Solicitante" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s3), '');
    UPDATE "CAF_Solicitud" SET "ID_Usuario_Solicitante" = v_ual WHERE "ID_Solicitud" = v_s3;
    PERFORM pg_temp.chk('Dashboard: Es_Solicitante es Y para quien creó la solicitud (acceso a «Mis solicitudes»)', 'Y', pg_temp.q('SELECT "Es_Solicitante" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s3), '');
    PERFORM pg_temp.chk('Calendario: su dueño ve Cancelar habilitado mientras la entrega está PROGRAMADA', 'Y', pg_temp.q('SELECT COALESCE("Puede_Cancelar_Sol",''-'') FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s3), '');
    UPDATE "CAF_Solicitud" SET "ID_Usuario_Solicitante" = v_usp WHERE "ID_Solicitud" = v_s3;
    PERFORM pg_temp.chk('Calendario: quien no es el dueño nunca puede cancelar desde la tarjeta', 'N|-', pg_temp.q('SELECT COALESCE("Puede_Cancelar_Sol",''-'') FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s3) || '|' || pg_temp.q('SELECT COALESCE("Motivo_No_Cancelar_Sol",''-'') FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s3), '');
    UPDATE "CAF_Solicitud" SET "ID_Usuario_Solicitante" = v_ual WHERE "ID_Solicitud" = v_s3;
    UPDATE "CAF_Solicitud_Operacion" SET "Estado_Operativo" = 'EN_ATENCION' WHERE "ID_Solicitud" = v_s3;
    PERFORM pg_temp.chk('Calendario: ya en atención el dueño no puede cancelar (botón deshabilitado)', 'N', pg_temp.q('SELECT COALESCE("Puede_Cancelar_Sol",''-'') FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s3), '');
    PERFORM pg_temp.chk('Calendario: ya en atención explica por qué no se puede cancelar', 'La entrega ya está en curso o terminó: no se puede cancelar.', pg_temp.q('SELECT COALESCE("Motivo_No_Cancelar_Sol",''-'') FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s3), '');
    UPDATE "CAF_Solicitud_Operacion" SET "Estado_Operativo" = 'PROGRAMADO' WHERE "ID_Solicitud" = v_s3;
    UPDATE "CAF_Solicitud" SET "ID_Usuario_Solicitante" = v_usp WHERE "ID_Solicitud" = v_s3;
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s3, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: reaprobada, antes de confirmar debe verificarse de nuevo', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.verif((SELECT "ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_s3 AND "Es_Principal" = 'Y'), v_uvp);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s3, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: reaprobada y verificada, se puede confirmar de nuevo', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_s3, v_uvp, v_cod, v_msg);
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_s3, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Atender: la tercera se atiende con su reserva', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_s3, 'CONFORME', NULL, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Vigilancia: tras terminar, la salida del principal ya se permite (regla existente)', 'RECEPCIONADO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s3), '');
    PERFORM pg_temp.chk('Historial: la entrega recorre sus pasos sin saltos', 'PROGRAMADO>EN_ESPERA>INGRESO>EN_ATENCION>RECEPCIONADO',
        pg_temp.q('SELECT STRING_AGG("Estado_Nuevo", ''>'' ORDER BY "ID_Operacion_Evento") FROM "CAF_Solicitud_Operacion_Evento" WHERE "ID_Solicitud" = ' || v_s2 || ' AND "Estado_Nuevo" <> COALESCE("Estado_Anterior", '''')'), '');

    -- Verificación con desviación: la decisión del coordinador ya viene registrada; no hay estado intermedio
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000015','Chofer','Cinco','Quique',0, v_qe, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000016','Chofer','Seis','Sixto',0,  v_qf, v_cod, v_msg);
    FOR v_n3 IN 4..5 LOOP
        CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_fhoy, 'Desviado ' || v_n3 || ' S.A.', NULL, NULL, NULL, NULL,
              (CASE v_n3 WHEN 4 THEN v_qe ELSE v_qf END)::TEXT, NULL, NULL, NULL, 'BBB10' || v_n3, NULL, NULL, '9112223' || v_n3 || '0', NULL, v_emp, '2055555555' || v_n3, 'Calle ' || v_n3, 'Volvo', 'Q5555555' || v_n3,
              (CASE v_n3 WHEN 4 THEN v_qe ELSE v_qf END), v_usp, v_r3, v_cs3, v_cod, v_msg);
        IF v_n3 = 4 THEN v_s4 := v_r3; ELSE v_s5 := v_r3; END IF;
        v_p1 := pg_temp.sp(v_r3, (CASE v_n3 WHEN 4 THEN v_qe ELSE v_qf END));
        CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_r3, v_paso_p, 'APROBADA', NULL, v_p1::TEXT, v_ucp, v_cant, v_cod, v_msg);
    END LOOP;
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(pg_temp.sp(v_s5, v_qf), pg_temp.items(pg_temp.sp(v_s5, v_qf), 'INGRESO', 'N', 'N', 'ING_EPP'), 'N', 'N', NULL, 'No porta EPP completo; el coordinador autoriza restringido a zona administrativa.', v_u_coo, v_t_rest, NULL, NULL, NULL, v_uvp, v_r3, v_d3, v_x3, v_cod, v_msg);
    PERFORM pg_temp.chk('Verificación con desviación: la decisión del coordinador se registra en el acto', '100|INGRESA_RESTRINGIDO', v_cod::TEXT || '|' || COALESCE(v_x3, ''), v_msg);
    PERFORM pg_temp.chk('Verificación con desviación autorizada: la entrega pasa a EN_ESPERA marcada con desviación', 'EN_ESPERA|Y',
        pg_temp.q('SELECT "Estado_Operativo" || ''|'' || "Con_Desviacion" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s5), '');
    PERFORM pg_temp.chk('Verificación con desviación autorizada: el calendario la marca', 'Y',
        pg_temp.q('SELECT "Con_Desviacion" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ud || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s5), '');
    PERFORM pg_temp.chk('Verificación con desviación autorizada: la desviación queda por revisar para el coordinador', 'POR_REVISAR',
        pg_temp.q('SELECT D."Estado" FROM "CAF_Desviacion" D JOIN "CAF_Registro_Acceso" R ON R."ID_Registro_Acceso" = D."ID_Registro_Acceso" WHERE R."ID_Solicitud_Persona" = ' || pg_temp.sp(v_s5, v_qf)), '');

    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s4, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: una entrega aún PROGRAMADA (sin verificar) no la recibe', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(pg_temp.sp(v_s4, v_qe), pg_temp.items(pg_temp.sp(v_s4, v_qe), 'INGRESO', 'N', 'N', 'ING_PLACA'), 'N', 'N', NULL, 'La placa no coincide; el coordinador no autoriza.', v_u_coo, v_t_den, NULL, NULL, NULL, v_uvp, v_r3, v_d3, v_x3, v_cod, v_msg);
    PERFORM pg_temp.chk('Verificación con desviación denegada: resultado NO_INGRESA', '100|NO_INGRESA', v_cod::TEXT || '|' || COALESCE(v_x3, ''), v_msg);
    PERFORM pg_temp.chk('Verificación denegada: la entrega pasa a INGRESO_DENEGADO con su desviación', 'INGRESO_DENEGADO|Y',
        pg_temp.q('SELECT "Estado_Operativo" || ''|'' || "Con_Desviacion" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s4), '');
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s4, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Verificación denegada: Almacén ya no puede confirmarle disponibilidad', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_s4, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Verificación denegada: Vigilancia no puede validar su ingreso', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Verificación denegada: la persona queda DENEGADA', 'DENEGADA',
        pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || pg_temp.sp(v_s4, v_qe)), '');
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s5, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: con un camión recepcionado por salir nadie más reserva', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Calendario: la que espera dice que la exclusa sigue ocupada y no puede confirmar', 'N',
        pg_temp.q('SELECT "Puede_Confirmar" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s5), '');
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(pg_temp.q('SELECT "ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_s3 || ' AND "Es_Principal" = ''Y''')::BIGINT, COALESCE(pg_temp.items(pg_temp.q('SELECT "ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_s3 || ' AND "Es_Principal" = ''Y''')::BIGINT, 'SALIDA', 'N', 'N', ''), ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_reg2, v_des2, v_res2, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: Vigilancia registra la salida del camión recepcionado', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Salida: la exclusa queda libre y la entrega SALIO', 'true|SALIO',
        pg_temp.q('SELECT (X."ID_Solicitud_Actual" IS NULL)::TEXT || ''|'' || O."Estado_Operativo" FROM "CAF_Exclusa" X, "CAF_Solicitud_Operacion" O WHERE X."ID_Catalogo_Sede" = ' || v_ves || ' AND O."ID_Solicitud" = ' || v_s3), '');
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_s5, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Disponibilidad: la entrega con desviación autorizada sí puede recibirla', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR"(v_s5, 'Se cancela la prueba', v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Cancelar disponibilidad: deja la esclusa libre', 'true', pg_temp.q('SELECT ("ID_Solicitud_Actual" IS NULL)::TEXT FROM "CAF_Exclusa" WHERE "ID_Catalogo_Sede" = ' || v_ves), '');
    PERFORM pg_temp.chk('Calendario: la entrega denegada sigue visible con su estado', 'INGRESO_DENEGADO',
        pg_temp.q('SELECT "Estado_Operativo" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ud || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_s4), '');

    -- ===================================================== Q. VARIOS TRANSPORTISTAS Y AYUDANTES (D-225)
    DECLARE
        v_gT1 BIGINT; v_gT2 BIGINT; v_gA1 BIGINT; v_gA2 BIGINT; v_gs BIGINT; v_gcs VARCHAR(20); v_gtr TEXT;
        v_pT1 BIGINT; v_pT2 BIGINT; v_pA1 BIGINT; v_pA2 BIGINT; v_gs2 BIGINT; v_gs3 BIGINT; v_gU BIGINT; v_gV BIGINT;
        v_pU BIGINT; v_pV BIGINT; v_gu_r TEXT;
    BEGIN
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000031','Trans','Uno','Tito',0, v_gT1, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000032','Trans','Dos','Teo',0,  v_gT2, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000033','Ayu','Uno','Alba',0,   v_gA1, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000034','Ayu','Dos','Abel',0,   v_gA2, v_cod, v_msg);
    v_gtr := v_gT1::TEXT || CHR(31) || '20111111111' || CHR(31) || 'Fletes Uno' || CHR(31) || 'Calle 1' || CHR(31) || 'GGG-001' || CHR(31) || 'Volvo' || CHR(31) || 'Q1000001'
          || CHR(30) || v_gT2::TEXT || CHR(31) || '20222222222' || CHR(31) || 'Fletes Dos' || CHR(31) || 'Calle 2' || CHR(31) || 'GGG-002' || CHR(31) || 'Scania' || CHR(31) || 'Q1000002';
    CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fhoy, 'Grupo S.A.', NULL, v_gT1 || ',' || v_gT2 || ',' || v_gA1 || ',' || v_gA2, NULL, NULL, 'Luis Jefe', '999111222', v_emp, v_gtr, v_usp, v_gs, v_gcs, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225: solicitud con 2 transportistas y 2 ayudantes creada', '100', v_cod::TEXT, v_msg);
    v_pT1 := pg_temp.sp(v_gs, v_gT1); v_pT2 := pg_temp.sp(v_gs, v_gT2); v_pA1 := pg_temp.sp(v_gs, v_gA1); v_pA2 := pg_temp.sp(v_gs, v_gA2);
    PERFORM pg_temp.chk('D-225: dos transportistas y dos ayudantes', '2|2',
        pg_temp.q('SELECT SUM(CASE WHEN "ERP_CAF_FN_ES_TRANSPORTISTA"("ID_Solicitud_Persona") = ''Y'' THEN 1 ELSE 0 END) || ''|'' || SUM(CASE WHEN "ERP_CAF_FN_ES_TRANSPORTISTA"("ID_Solicitud_Persona") = ''Y'' THEN 0 ELSE 1 END) FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_gs), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_gs, v_paso_p, 'APROBADA', NULL, v_pT1 || ',' || v_pT2 || ',' || v_pA1 || ',' || v_pA2, v_ucp, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225: aprobada, la entrega queda PROGRAMADO', '100|PROGRAMADO', v_cod::TEXT || '|' || pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_gs), v_msg);

    -- Checklist por rol: el ítem de placa solo aplica a transportistas
    PERFORM pg_temp.chk('D-225: el ayudante tiene menos ítems de ingreso que el transportista', 'true',
        pg_temp.q('SELECT ((SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_pA1 || ', ''INGRESO'', ''N'', ''N'')) < (SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_pT1 || ', ''INGRESO'', ''N'', ''N'')))::TEXT'), '');
    PERFORM pg_temp.chk('D-225: la placa no figura para el ayudante', '0',
        pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_pA1 || ', ''INGRESO'', ''N'', ''N'') WHERE "Codigo" = ''ING_PLACA'''), '');

    -- Verificar en grupo
    CALL "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(v_gs, '', pg_temp.items(v_pT1, 'INGRESO', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: sin selección no procede', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(v_gs, 'a,b', pg_temp.items(v_pT1, 'INGRESO', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: lista mal formada', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(v_gs, v_pT1::TEXT, pg_temp.items(v_pT1, 'INGRESO', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, v_ud, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: sin permiso de Vigilancia no verifica', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(v_gs, v_pT1::TEXT, pg_temp.items(v_pA1, 'INGRESO', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: al transportista le faltan ítems de su checklist (placa)', '400', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: el rechazo no dejó nada guardado', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "Fecha_Verificacion" IS NOT NULL AND "ID_Solicitud" = ' || v_gs), '');

    CALL "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(v_gs, v_pA1::TEXT, pg_temp.items(v_pA1, 'INGRESO', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: un ayudante se verifica por adelantado', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: verificar al ayudante no mueve la entrega', 'PROGRAMADO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_gs), '');
    CALL "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(v_gs, v_pA1::TEXT, pg_temp.items(v_pA1, 'INGRESO', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: quien ya está verificado no se verifica dos veces', '409', v_cod::TEXT, v_msg);

    -- Selección mixta: un transportista y un ayudante con UN solo checklist (unión de ítems)
    CALL "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(v_gs, v_pT1 || ',' || v_pA2, pg_temp.items(v_pT1, 'INGRESO', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: selección mixta con un solo checklist', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: cada uno guardó solo las respuestas que le aplican', 
        (SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(v_pT1, 'INGRESO', 'N', 'N'))::TEXT || '|' || (SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(v_pA2, 'INGRESO', 'N', 'N'))::TEXT,
        pg_temp.q('SELECT (SELECT COUNT(*) FROM "CAF_Registro_Checklist" C JOIN "CAF_Registro_Acceso" R ON R."ID_Registro_Acceso" = C."ID_Registro_Acceso" WHERE R."ID_Solicitud_Persona" = ' || v_pT1 || ' AND R."Tipo_Movimiento" = ''INGRESO'') || ''|'' || (SELECT COUNT(*) FROM "CAF_Registro_Checklist" C JOIN "CAF_Registro_Acceso" R ON R."ID_Registro_Acceso" = C."ID_Registro_Acceso" WHERE R."ID_Solicitud_Persona" = ' || v_pA2 || ' AND R."Tipo_Movimiento" = ''INGRESO'')'), '');
    PERFORM pg_temp.chk('D-225: falta el transportista 2, la entrega sigue PROGRAMADO (los ayudantes no bloquean)', 'PROGRAMADO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_gs), '');
    PERFORM pg_temp.chk('D-225: calendario cuenta transportistas 2, verificados 1, ayudantes 2', '2|1|0|2',
        pg_temp.q('SELECT "Transportistas_Total" || ''|'' || "Transportistas_Verificados" || ''|'' || "Transportistas_Dentro" || ''|'' || "Ayudantes_Total" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) WHERE "ID_Solicitud" = ' || v_gs), '');
    PERFORM pg_temp.chk('D-225: Vigilancia ve a cada persona con su rol y verificación', 'Y|Y|N|Y|Y|N',
        pg_temp.q('SELECT (SELECT "Es_Transportista" || ''|'' || "Verificada" FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_uvp || ', NULL, NULL) WHERE "ID_Solicitud_Persona" = ' || v_pT1 || ') || ''|'' || (SELECT "Es_Transportista" || ''|'' || "Verificada" FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_uvp || ', NULL, NULL) WHERE "ID_Solicitud_Persona" = ' || v_pA2 || ') || ''|'' || (SELECT "Es_Transportista" || ''|'' || "Verificada" FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_uvp || ', NULL, NULL) WHERE "ID_Solicitud_Persona" = ' || v_pT2 || ')'), '');

    -- El transportista 2 no coincide en la placa: desviación; el coordinador autorizó restringido
    CALL "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(v_gs, v_pT2::TEXT, pg_temp.items(v_pT2, 'INGRESO', 'N', 'N', 'ING_EPP'), NULL, 'No porta EPP completo; el coordinador autoriza restringido.', v_u_coo, v_t_rest, NULL, NULL, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: verificación con desviación autorizada', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 grupo: la desviación quedó a nombre de esa persona', '1',
        pg_temp.q('SELECT COUNT(*) FROM "CAF_Desviacion" D JOIN "CAF_Registro_Acceso" R ON R."ID_Registro_Acceso" = D."ID_Registro_Acceso" WHERE R."ID_Solicitud_Persona" = ' || v_pT2), '');
    PERFORM pg_temp.chk('D-225: con todos los transportistas verificados la entrega pasa a EN_ESPERA', 'EN_ESPERA', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_gs), '');

    -- Ingreso físico: exige la reserva de Almacén, la verificación y respeta la capacidad
    CALL "ERP_CAF_PROVEEDOR_INGRESO_FISICO"(v_gs, v_pT1::TEXT, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 ingreso: sin la disponibilidad de Almacén no se ingresa', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_gs, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 ingreso: Almacén confirma una sola vez para toda la entrega', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_FISICO"(v_gs, v_pT1::TEXT, v_ud, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 ingreso: sin permiso de Vigilancia no ingresa', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_FISICO"(v_gs, v_pA1::TEXT, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 ingreso: un ayudante no entra sin su transportista', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_FISICO"(v_gs, v_pT1 || ',' || v_pT2, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 ingreso: capacidad 1, los dos camiones a la vez no caben', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 ingreso: el rechazo no movió a nadie', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "Estado" = ''DENTRO'' AND "ID_Solicitud" = ' || v_gs), '');
    CALL "ERP_CAF_PROVEEDOR_INGRESO_FISICO"(v_gs, v_pT1 || ',' || v_pA1 || ',' || v_pA2, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 ingreso: un camión con sus dos ayudantes entra junto', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 ingreso: la entrega pasa a INGRESO y hay 3 personas dentro', 'INGRESO|3',
        pg_temp.q('SELECT (SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_gs || ') || ''|'' || (SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "Estado" = ''DENTRO'' AND "ID_Solicitud" = ' || v_gs || ')'), '');
    CALL "ERP_CAF_PROVEEDOR_INGRESO_FISICO"(v_gs, v_pT2::TEXT, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 ingreso: el segundo camión espera su turno (capacidad 1)', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('EXCLUSA_CAPACIDAD', 'abc', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 capacidad: un valor no numérico se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('EXCLUSA_CAPACIDAD', '0', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 capacidad: cero se rechaza', '400', v_cod::TEXT, v_msg);

    -- Salida del primer camión mientras el segundo espera
    CALL "ERP_CAF_PROVEEDOR_SALIDA_GRUPO"(v_gs, v_pT1 || ',' || v_pA1, COALESCE(pg_temp.items(v_pT1, 'SALIDA', 'N', 'N', ''), '') || ',' || COALESCE(pg_temp.items(v_pA1, 'SALIDA', 'N', 'N', ''), ''), NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 salida: el camión 1 y un ayudante salen para dar paso al camión 2', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 salida: la entrega sigue en INGRESO y queda 1 ayudante dentro', 'INGRESO|1',
        pg_temp.q('SELECT (SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_gs || ') || ''|'' || (SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "Estado" = ''DENTRO'' AND "ID_Solicitud" = ' || v_gs || ')'), '');
    CALL "ERP_CAF_PROVEEDOR_INGRESO_FISICO"(v_gs, v_pT2::TEXT, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 ingreso: libre el cupo, entra el camión 2 (con su desviación autorizada)', '100', v_cod::TEXT, v_msg);

    -- Almacén atiende y termina una sola vez
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_gs, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 almacén: inicia la atención una sola vez', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_gs, 'CONFORME', NULL, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 almacén: una sola conformidad para la entrega', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 almacén: la entrega queda RECEPCIONADO (aún hay gente dentro)', 'RECEPCIONADO', pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_gs), '');
    CALL "ERP_CAF_PROVEEDOR_SALIDA_GRUPO"(v_gs, v_pT2 || ',' || v_pA2, COALESCE(pg_temp.items(v_pT2, 'SALIDA', 'N', 'N', ''), '') || ',' || COALESCE(pg_temp.items(v_pA2, 'SALIDA', 'N', 'N', ''), ''), NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 salida: sale el resto en grupo', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 salida: sale el último y la entrega pasa a SALIO con la esclusa libre', 'SALIO|true',
        pg_temp.q('SELECT O."Estado_Operativo" || ''|'' || (X."ID_Solicitud_Actual" IS NULL)::TEXT FROM "CAF_Solicitud_Operacion" O, "CAF_Exclusa" X WHERE X."ID_Catalogo_Sede" = ' || v_ves || ' AND O."ID_Solicitud" = ' || v_gs), '');

    -- Retiro sin ingresar de varias personas; sin transportistas pendientes la entrega termina
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000035','Trans','Tres','Tulio',0, v_gU, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000036','Ayu','Tres','Aida',0,   v_gV, v_cod, v_msg);
    v_gtr := v_gU::TEXT || CHR(31) || '20333333333' || CHR(31) || 'Fletes Tres' || CHR(31) || 'Calle 3' || CHR(31) || 'GGG-003' || CHR(31) || 'Volvo' || CHR(31) || 'Q1000003';
    CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fhoy, 'Retiro S.A.', NULL, v_gU || ',' || v_gV, NULL, NULL, 'Luis Jefe', '999111222', v_emp, v_gtr, v_usp, v_gs2, v_gcs, v_cod, v_msg);
    v_pU := pg_temp.sp(v_gs2, v_gU); v_pV := pg_temp.sp(v_gs2, v_gV);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_gs2, v_paso_p, 'APROBADA', NULL, v_pU || ',' || v_pV, v_ucp, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(v_gs2, v_pU || ',' || v_pV, pg_temp.items(v_pU, 'INGRESO', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 retiro: verificados los dos, la entrega está EN_ESPERA', '100|EN_ESPERA', v_cod::TEXT || '|' || pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_gs2), v_msg);
    CALL "ERP_CAF_PROVEEDOR_RETIRO_PERSONAS"(v_gs2, v_pV::TEXT, 'Se fue el ayudante', 'N', v_ud, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 retiro: sin permiso de Vigilancia no procede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RETIRO_PERSONAS"(v_gs2, v_pV::TEXT, '', 'N', v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 retiro: pide el motivo', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PROVEEDOR_RETIRO_PERSONAS"(v_gs2, v_pV::TEXT, 'Se fue el ayudante', 'N', v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 retiro: se retira un ayudante', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 retiro: el ayudante queda NO_SE_PRESENTO y la entrega sigue EN_ESPERA', 'NO_SE_PRESENTO|EN_ESPERA',
        pg_temp.q('SELECT (SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_pV || ') || ''|'' || (SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_gs2 || ')'), '');
    CALL "ERP_CAF_PROVEEDOR_RETIRO_PERSONAS"(v_gs2, v_pU::TEXT, 'No ingresó el camión', 'N', v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 retiro: se retira al único transportista', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 retiro: sin transportistas por ingresar la entrega termina como RETIRO_SIN_INGRESO', 'RETIRO_SIN_INGRESO',
        pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_gs2), '');

    -- Quitar al único transportista: avisa que la solicitud se rechaza
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000037','Trans','Cuatro','Tomas',0, v_gU, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000038','Ayu','Cuatro','Ana',0,     v_gV, v_cod, v_msg);
    v_gtr := v_gU::TEXT || CHR(31) || '20444444444' || CHR(31) || 'Fletes Cuatro' || CHR(31) || 'Calle 4' || CHR(31) || 'GGG-004' || CHR(31) || 'Volvo' || CHR(31) || 'Q1000004';
    CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fut, 'Unico S.A.', NULL, v_gU || ',' || v_gV, NULL, NULL, 'Luis Jefe', '999111222', v_emp, v_gtr, v_usp, v_gs3, v_gcs, v_cod, v_msg);
    v_pU := pg_temp.sp(v_gs3, v_gU); v_pV := pg_temp.sp(v_gs3, v_gV);
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR"(v_pU, v_usp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 único: el solicitante no puede quitar a su único transportista', '101', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 único: el aviso sugiere corregir o cancelar', 'true', (POSITION('Corregir persona' IN v_msg) > 0 AND POSITION('cancele' IN v_msg) > 0)::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_gs3, v_paso_p, 'APROBADA', NULL, v_pU || ',' || v_pV, v_ucp, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 único: aprobada con su ayudante', '100', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'ESPERADA' WHERE "ID_Solicitud_Persona" = v_pU;
    CALL "ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA"(v_pU, 'Error de nombre', 'N', v_ucp, v_cod, v_msg);
    PERFORM pg_temp.chk('D-225 único: el coordinador debe confirmar el rechazo (aunque queden ayudantes)', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-225 único: el aviso explica que la solicitud quedará RECHAZADA', 'true', (POSITION('RECHAZADA' IN v_msg) > 0)::TEXT, v_msg);

    -- D-226: emergencia en proveedor: se elige transportista o ayudante de descarga
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000039','Nuevo','Cinco','Nora',0, v_gU, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000040','Nuevo','Seis','Nico',0,  v_gV, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_gs3, v_gV, 'Llegó otro', v_ucp, 'X', NULL, NULL, NULL, NULL, NULL, NULL, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('D-226 emergencia: el rol debe ser Y o N', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(pg_temp.q('SELECT S."ID_Solicitud" FROM "CAF_Solicitud" S JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" WHERE T."Codigo" <> ''PROVEEDOR'' AND S."Estado" IN (''APROBADA'',''APROBADA_PARCIAL'') AND CAST(S."Fecha_Hora_Prevista" AS DATE) >= CURRENT_DATE ORDER BY 1 LIMIT 1')::BIGINT, v_gV, 'Llegó otro', v_u_coo, 'Y', NULL, NULL, NULL, NULL, NULL, NULL, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('D-226 emergencia: fuera de proveedor no hay transportistas', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_gs3, v_gV, 'Llegó otro', v_ucp, 'Y', '123', NULL, NULL, NULL, NULL, NULL, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('D-226 emergencia: RUC inválido se rechaza', '400', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-226 emergencia: el rechazo no dejó a la persona', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_gs3 || ' AND "ID_Persona_Externa" = ' || v_gV), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_gs3, v_gV, 'Llegó otro', v_ucp, 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('D-226 emergencia: se agrega un ayudante', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-226 emergencia: el ayudante no es transportista', 'N', "ERP_CAF_FN_ES_TRANSPORTISTA"(v_dummy)::TEXT, '');
    UPDATE "CAF_Solicitud_Operacion" SET "Estado_Operativo" = 'EN_ESPERA' WHERE "ID_Solicitud" = v_gs3;
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_gs3, v_gU, 'Llegó otro camión', v_ucp, 'Y', '20555555555', 'Fletes Cinco', NULL, 'hh-005', 'Volvo', NULL, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('D-226 emergencia: se agrega un transportista', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('D-226 emergencia: queda como transportista con la placa normalizada', 'Y|HH005|20555555555',
        "ERP_CAF_FN_ES_TRANSPORTISTA"(v_dummy)::TEXT || '|' || pg_temp.q('SELECT "Placa" || ''|'' || "Ruc" FROM "CAF_Solicitud_Transportista" WHERE "ID_Solicitud_Persona" = ' || v_dummy || ' AND "Eliminado" = ''N'''), '');
    PERFORM pg_temp.chk('D-226 emergencia: la entrega que esperaba vuelve a PROGRAMADO (falta verificarlo)', 'PROGRAMADO',
        pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_gs3), '');
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA"(v_gs2, v_gU, 'Llegó otro camión', v_ucp, 'Y', NULL, NULL, NULL, NULL, NULL, NULL, v_dummy, v_cod, v_msg);
    PERFORM pg_temp.chk('D-226 emergencia: con la entrega terminada no se agrega transportista', '409', v_cod::TEXT, v_msg);

    -- D-227: contratista con franja de días (ingresos múltiples, fuera de franja, extensión y cierre forzado)
    DECLARE
        v_cxa BIGINT; v_cxb BIGINT; v_cxc BIGINT; v_cxd BIGINT; v_cxcod VARCHAR(20); v_pa BIGINT; v_pb BIGINT; v_pc BIGINT; v_pd BIGINT;
        v_ra BIGINT; v_de BIGINT; v_rs VARCHAR(30); v_ttr BIGINT; v_paso_c BIGINT; v_agr INT; v_hoy_t VARCHAR(10); v_h1 VARCHAR(5); v_h2 VARCHAR(5);
        v_ppa BIGINT; v_ppb BIGINT; v_ppc BIGINT; v_ppd BIGINT; v_l93 VARCHAR(2000);
    BEGIN
        SELECT STRING_AGG(TO_CHAR(CURRENT_DATE + g, 'YYYY-MM-DD'), ',') INTO v_l93 FROM GENERATE_SERIES(0, 92) g;
        v_hoy_t := TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD');
        SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_ttr FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'LIBERACION';
        SELECT "ID_Tipo_Acceso_Paso_Aprobacion" INTO v_paso_c FROM "Tipo_Acceso_Paso_Aprobacion" P JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = P."ID_Catalogo_Tipo_Acceso" WHERE T."Codigo" = 'CONTRATISTA' LIMIT 1;
        -- un horario que NUNCA contiene la hora actual
        IF CURRENT_TIME < TIME '12:00' THEN v_h1 := '22:00'; v_h2 := '23:59'; ELSE v_h1 := '00:00'; v_h2 := '10:00'; END IF;
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000041','Contra','Uno','Carlos',0, v_gU, v_cod, v_msg);
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000042','Contra','Dos','Clara',0,  v_gV, v_cod, v_msg);
        v_pa := v_gU; v_pb := v_gV;

        -- Validaciones de la lista de días y del horario
        CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Montajes Franja S.A.C.', 'Cambio de tablero', NULL, v_z_adm::TEXT, v_pa::TEXT || ',' || v_pb::TEXT, NULL, NULL, NULL, NULL, 'Sala de tableros', 'Juan Pérez', '999 888 777', 'juan@montajes.pe', '', NULL, NULL, v_u_sol, v_cxa, v_cxcod, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 crear: sin días se rechaza', '400', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Montajes Franja S.A.C.', 'Cambio de tablero', NULL, v_z_adm::TEXT, v_pa::TEXT || ',' || v_pb::TEXT, NULL, NULL, NULL, NULL, 'Sala de tableros', 'Juan Pérez', '999 888 777', 'juan@montajes.pe', '10/11/2026', NULL, NULL, v_u_sol, v_cxa, v_cxcod, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 crear: formato de día inválido', '400', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Montajes Franja S.A.C.', 'Cambio de tablero', NULL, v_z_adm::TEXT, v_pa::TEXT || ',' || v_pb::TEXT, NULL, NULL, NULL, NULL, 'Sala de tableros', 'Juan Pérez', '999 888 777', 'juan@montajes.pe', '2026-02-30', NULL, NULL, v_u_sol, v_cxa, v_cxcod, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 crear: un día que no existe en el calendario', '400', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Montajes Franja S.A.C.', 'Cambio de tablero', NULL, v_z_adm::TEXT, v_pa::TEXT || ',' || v_pb::TEXT, NULL, NULL, NULL, NULL, 'Sala de tableros', 'Juan Pérez', '999 888 777', 'juan@montajes.pe', TO_CHAR(CURRENT_DATE - 1, 'YYYY-MM-DD'), NULL, NULL, v_u_sol, v_cxa, v_cxcod, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 crear: no admite días pasados', '400', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Montajes Franja S.A.C.', 'Cambio de tablero', NULL, v_z_adm::TEXT, v_pa::TEXT || ',' || v_pb::TEXT, NULL, NULL, NULL, NULL, 'Sala de tableros', 'Juan Pérez', '999 888 777', 'juan@montajes.pe', v_hoy_t || ',' || v_hoy_t, NULL, NULL, v_u_sol, v_cxa, v_cxcod, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 crear: un día repetido', '400', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Montajes Franja S.A.C.', 'Cambio de tablero', NULL, v_z_adm::TEXT, v_pa::TEXT || ',' || v_pb::TEXT, NULL, NULL, NULL, NULL, 'Sala de tableros', 'Juan Pérez', '999 888 777', 'juan@montajes.pe', v_hoy_t, '25:00', NULL, v_u_sol, v_cxa, v_cxcod, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 crear: el formato de hora', '400', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Montajes Franja S.A.C.', 'Cambio de tablero', NULL, v_z_adm::TEXT, v_pa::TEXT || ',' || v_pb::TEXT, NULL, NULL, NULL, NULL, 'Sala de tableros', 'Juan Pérez', '999 888 777', 'juan@montajes.pe', v_hoy_t, '17:00', '08:00', v_u_sol, v_cxa, v_cxcod, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 crear: la hora de salida debe ser posterior', '400', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Montajes Franja S.A.C.', 'Cambio de tablero', NULL, v_z_adm::TEXT, v_pa::TEXT || ',' || v_pb::TEXT, NULL, NULL, NULL, NULL, 'Sala de tableros', 'Juan Pérez', '999 888 777', 'juan@montajes.pe', v_l93, NULL, NULL, v_u_sol, v_cxa, v_cxcod, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 crear: más de 92 días se rechaza', '400', v_cod::TEXT, v_msg);
        PERFORM pg_temp.chk('D-227 crear: los rechazos no dejaron solicitudes de contratista', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud" WHERE "Empresa_Visitante" = ''Montajes Franja S.A.C.'''), '');

        -- Solicitud A: hoy, +2 y +5 (sueltos), todo el día, sin responsable
        CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Montajes Franja S.A.C.', 'Cambio de tablero', NULL, v_z_adm::TEXT, v_pa::TEXT || ',' || v_pb::TEXT, NULL, NULL, NULL, NULL, 'Sala de tableros', 'Juan Pérez', '999 888 777', 'juan@montajes.pe',
             v_hoy_t || ',' || TO_CHAR(CURRENT_DATE + 2, 'YYYY-MM-DD') || ',' || TO_CHAR(CURRENT_DATE + 5, 'YYYY-MM-DD'), '00:00', '23:59', v_u_sol, v_cxa, v_cxcod, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 crear: días sueltos sin responsable de atención', '100', v_cod::TEXT, v_msg);
        PERFORM pg_temp.chk('D-227 crear: guarda los 3 días y no tiene responsable', '3|true|Y',
            pg_temp.q('SELECT (SELECT COUNT(*) FROM "CAF_Solicitud_Dia" WHERE "ID_Solicitud" = ' || v_cxa || ')::TEXT || ''|'' || (SELECT "ID_Personal_Responsable" IS NULL FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_cxa || ')::TEXT || ''|'' || "ERP_CAF_FN_ES_FRANJA"(' || v_cxa || ')'), '');
        PERFORM pg_temp.chk('D-227 crear: la fecha de la solicitud es el primer día', 'true', pg_temp.q('SELECT (CAST("Fecha_Hora_Prevista" AS DATE) = CURRENT_DATE)::TEXT FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_cxa), '');
        PERFORM pg_temp.chk('D-227 crear: una solicitud sin días no es de franja', 'N', "ERP_CAF_FN_ES_FRANJA"(v_s1), '');
        v_ppa := pg_temp.sp(v_cxa, v_pa); v_ppb := pg_temp.sp(v_cxa, v_pb);
        CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_cxa, v_paso_c, 'APROBADA', NULL, v_ppa || ',' || v_ppb, v_u_coo, v_cant, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 aprobar: el Coordinador aprueba a las dos personas', '100', v_cod::TEXT, v_msg);

        -- Ingresos y salidas varias veces
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_ppa, pg_temp.items(v_ppa, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_ra, v_de, v_rs, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 ingreso: dentro de la franja ingresa sin desviación', '100|INGRESA|0', v_cod::TEXT || '|' || COALESCE(v_rs, '') || '|' || v_de, v_msg);
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_ppa, pg_temp.items(v_ppa, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_ra, v_de, v_rs, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 ingreso: no se ingresa dos veces sin salir', '409', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_ppa, pg_temp.items(v_ppa, 'SALIDA', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_ra, v_de, v_rs, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 salida: sale y queda ESPERADA porque le quedan días', '100|ESPERADA', v_cod::TEXT || '|' || pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_ppa), v_msg);
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_ppa, pg_temp.items(v_ppa, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_ra, v_de, v_rs, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 ingreso: vuelve a ingresar el mismo día', '100|INGRESA', v_cod::TEXT || '|' || COALESCE(v_rs, ''), v_msg);
        PERFORM pg_temp.chk('D-227 ingreso: quedan 2 ingresos y 1 salida registrados', '2|1',
            pg_temp.q('SELECT (SELECT COUNT(*) FROM "CAF_Registro_Acceso" WHERE "ID_Solicitud_Persona" = ' || v_ppa || ' AND "Tipo_Movimiento" = ''INGRESO'')::TEXT || ''|'' || (SELECT COUNT(*) FROM "CAF_Registro_Acceso" WHERE "ID_Solicitud_Persona" = ' || v_ppa || ' AND "Tipo_Movimiento" = ''SALIDA'')::TEXT'), '');

        -- Lectura de Vigilancia para la franja
        PERFORM pg_temp.chk('D-227 vigilancia: hoy (día autorizado) aparecen las 2 personas, franja DENTRO', '2|DENTRO',
            pg_temp.q('SELECT COUNT(*)::TEXT || ''|'' || MIN("Franja_Estado") FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ', NULL, CURRENT_DATE) WHERE "ID_Solicitud" = ' || v_cxa), '');
        PERFORM pg_temp.chk('D-227 vigilancia: un día no autorizado no la muestra', '0',
            pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR"(' || v_u_vig || ', NULL, CURRENT_DATE + 200) WHERE "ID_Solicitud" = ' || v_cxa), '');
        PERFORM pg_temp.chk('D-227 vigilancia: la consulta de aprobadas la encuentra por sus días', '2',
            pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS"(' || v_u_vig || ', NULL, CURRENT_DATE, CURRENT_DATE) WHERE "ID_Solicitud" = ' || v_cxa), '');

        -- Cierre forzado del día: sigue dentro desde ayer
        UPDATE "CAF_Solicitud_Persona" SET "Fecha_Hora_Ingreso" = (CURRENT_DATE - 1) + TIME '10:00' WHERE "ID_Solicitud_Persona" = v_ppa;
        CALL "ERP_CAF_CONTRATISTA_CIERRE_DIA"(CURRENT_DATE, 0, v_agr, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 cierre: cierra a quien siguió dentro de un día anterior', '100|1', v_cod::TEXT || '|' || v_agr, v_msg);
        PERFORM pg_temp.chk('D-227 cierre: queda ESPERADA (le quedan días) con salida a las 23:59 de ayer', 'ESPERADA|23:59',
            pg_temp.q('SELECT "Estado" || ''|'' || TO_CHAR("Fecha_Hora_Salida", ''HH24:MI'') FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_ppa), '');
        PERFORM pg_temp.chk('D-227 cierre: queda el registro de salida forzada y el aviso al Coordinador', '1|1',
            pg_temp.q('SELECT (SELECT COUNT(*) FROM "CAF_Registro_Acceso" WHERE "ID_Solicitud_Persona" = ' || v_ppa || ' AND "Observacion" LIKE ''Cierre forzado%'')::TEXT || ''|'' || (SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_cxa || ' AND "Asunto" LIKE ''Salida no registrada de contratista%'')::TEXT'), '');
        CALL "ERP_CAF_CONTRATISTA_CIERRE_DIA"(CURRENT_DATE, 0, v_agr, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 cierre: repetirlo no cierra nada más', '100|0', v_cod::TEXT || '|' || v_agr, v_msg);
        PERFORM pg_temp.chk('D-227 cierre: la solicitud sigue vigente', 'APROBADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_cxa), '');

        -- Fuera de franja: otro día
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000043','Contra','Tres','Cesar',0, v_gU, v_cod, v_msg);
        v_pc := v_gU;
        CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Montajes Otro Dia S.A.C.', 'Pintura', NULL, v_z_adm::TEXT, v_pc::TEXT, NULL, NULL, NULL, NULL, 'Patio', 'Juan Pérez', '999 888 777', 'juan@montajes.pe',
             TO_CHAR(CURRENT_DATE + 3, 'YYYY-MM-DD'), NULL, NULL, v_u_sol, v_cxb, v_cxcod, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 crear: un solo día futuro sin horario', '100', v_cod::TEXT, v_msg);
        v_ppc := pg_temp.sp(v_cxb, v_pc);
        CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_cxb, v_paso_c, 'APROBADA', NULL, v_ppc::TEXT, v_u_coo, v_cant, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 aprobar: solicitud de otro día', '100', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_ppc, pg_temp.items(v_ppc, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_ra, v_de, v_rs, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 fuera de franja: sin desviación no ingresa', '400', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_ppc, pg_temp.items(v_ppc, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, 'Llegó un día antes por urgencia del cliente.', v_u_coo, v_ttr, NULL, NULL, NULL, v_u_vig, v_ra, v_de, v_rs, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 fuera de franja: con desviación autorizada ingresa', '100|INGRESA', v_cod::TEXT || '|' || COALESCE(v_rs, ''), v_msg);
        PERFORM pg_temp.chk('D-227 fuera de franja: la desviación queda identificada', 'true',
            pg_temp.q('SELECT ("Descripcion" LIKE ''Ingreso fuera de la franja autorizada. Llegó un día antes%'')::TEXT FROM "CAF_Desviacion" WHERE "ID_Desviacion" = ' || v_de), '');
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_ppb, pg_temp.items(v_ppb, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, 'Sin permiso', v_u_coo, v_ttr, NULL, NULL, NULL, v_u_sol, v_ra, v_de, v_rs, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 fuera de franja: sin permiso de Vigilancia no registra', '101', v_cod::TEXT, v_msg);

        -- Fuera de franja: mismo día pero fuera del horario
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'72000044','Contra','Cuatro','Cecilia',0, v_gU, v_cod, v_msg);
        v_pd := v_gU;
        CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Montajes Horario S.A.C.', 'Soldadura', NULL, v_z_adm::TEXT, v_pd::TEXT, NULL, NULL, NULL, NULL, 'Taller', 'Juan Pérez', '999 888 777', 'juan@montajes.pe',
             TO_CHAR(CURRENT_DATE + 1, 'YYYY-MM-DD'), v_h1, v_h2, v_u_sol, v_cxc, v_cxcod, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 crear: día de mañana con horas aproximadas', '100', v_cod::TEXT, v_msg);
        v_ppd := pg_temp.sp(v_cxc, v_pd);
        CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_cxc, v_paso_c, 'APROBADA', NULL, v_ppd::TEXT, v_u_coo, v_cant, v_cod, v_msg);
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_ppd, pg_temp.items(v_ppd, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_ra, v_de, v_rs, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 fuera de franja: otro día pide desviación', '400', v_cod::TEXT, v_msg);
        PERFORM pg_temp.chk('D-227 franja: el estado según el momento', 'FUERA|DENTRO|NA',
            "ERP_CAF_FN_FRANJA_ESTADO"(v_cxc, CAST(CURRENT_TIMESTAMP AS TIMESTAMP)) || '|' || "ERP_CAF_FN_FRANJA_ESTADO"(v_cxa, CAST(CURRENT_TIMESTAMP AS TIMESTAMP)) || '|' || "ERP_CAF_FN_FRANJA_ESTADO"(v_s1, CAST(CURRENT_TIMESTAMP AS TIMESTAMP)), '');

        -- Extensión del Coordinador
        CALL "ERP_CAF_SOLICITUD_DIAS_EXTENDER"(v_cxa, TO_CHAR(CURRENT_DATE + 7, 'YYYY-MM-DD'), NULL, NULL, 'Se amplía el trabajo', v_u_sol, v_agr, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 extender: el solicitante no puede', '101', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_DIAS_EXTENDER"(v_cxa, TO_CHAR(CURRENT_DATE + 7, 'YYYY-MM-DD'), NULL, NULL, '  ', v_u_coo, v_agr, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 extender: exige sustento', '400', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_DIAS_EXTENDER"(v_cxa, TO_CHAR(CURRENT_DATE - 1, 'YYYY-MM-DD'), NULL, NULL, 'Se amplía el trabajo', v_u_coo, v_agr, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 extender: no admite días pasados', '400', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_DIAS_EXTENDER"(v_cxa, TO_CHAR(CURRENT_DATE + 2, 'YYYY-MM-DD'), NULL, NULL, 'Se amplía el trabajo', v_u_coo, v_agr, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 extender: un día ya autorizado', '409', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_DIAS_EXTENDER"(v_cxa, '2026-02-30', NULL, NULL, 'Se amplía el trabajo', v_u_coo, v_agr, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 extender: una fecha que no existe', '400', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_DIAS_EXTENDER"(v_s1, TO_CHAR(CURRENT_DATE + 7, 'YYYY-MM-DD'), NULL, NULL, 'Se amplía el trabajo', v_u_coo, v_agr, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 extender: solo contratistas con franja', '409', v_cod::TEXT, v_msg);
        CALL "ERP_CAF_SOLICITUD_DIAS_EXTENDER"(v_cxa, TO_CHAR(CURRENT_DATE + 7, 'YYYY-MM-DD') || ',' || TO_CHAR(CURRENT_DATE + 8, 'YYYY-MM-DD'), '07:00', '17:00', 'Se amplía el trabajo', v_u_coo, v_agr, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 extender: el Coordinador agrega 2 días', '100|2', v_cod::TEXT || '|' || v_agr, v_msg);
        PERFORM pg_temp.chk('D-227 extender: 5 días, 2 de extensión y la solicitud sigue aprobada', '5|2|APROBADA',
            pg_temp.q('SELECT (SELECT COUNT(*) FROM "CAF_Solicitud_Dia" WHERE "ID_Solicitud" = ' || v_cxa || ')::TEXT || ''|'' || (SELECT COUNT(*) FROM "CAF_Solicitud_Dia" WHERE "ID_Solicitud" = ' || v_cxa || ' AND "Origen" = ''EXTENSION'')::TEXT || ''|'' || (SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_cxa || ')'), '');
        PERFORM pg_temp.chk('D-227 extender: queda en la bitácora y se avisa por correo', '1|1',
            pg_temp.q('SELECT (SELECT COUNT(*) FROM "CAF_Evento" WHERE "ID_Solicitud" = ' || v_cxa || ' AND "Accion" = ''EXTENDER_DIAS'')::TEXT || ''|'' || (SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_cxa || ' AND "Asunto" LIKE ''Se amplió el plazo autorizado%'')::TEXT'), '');
        -- Franja terminada
        UPDATE "CAF_Solicitud_Dia" SET "Fecha" = "Fecha" - 30 WHERE "ID_Solicitud" = v_cxb;
        CALL "ERP_CAF_SOLICITUD_DIAS_EXTENDER"(v_cxb, TO_CHAR(CURRENT_DATE + 7, 'YYYY-MM-DD'), NULL, NULL, 'Se amplía el trabajo', v_u_coo, v_agr, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 extender: con la franja terminada hay que crear otra solicitud', '409', v_cod::TEXT, v_msg);

        -- Fin de franja: el último día pasó
        UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'ESPERADA' WHERE "ID_Solicitud_Persona" IN (v_ppc, v_ppd);
        UPDATE "CAF_Solicitud_Dia" SET "Fecha" = CURRENT_DATE - 1 WHERE "ID_Solicitud" = v_cxc;
        CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(CURRENT_DATE, 0, v_cant, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 fin de franja: quien nunca ingresó queda NO_SE_PRESENTO y quien ya ingresó SALIO', 'SALIO|NO_SE_PRESENTO',
            pg_temp.q('SELECT (SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_ppc || ') || ''|'' || (SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_ppd || ')'), v_msg);
        PERFORM pg_temp.chk('D-227 fin de franja: con días pendientes nadie se marca', 'ESPERADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_ppb), '');

        -- Un solo día que ya pasó: la persona que seguía dentro sale como SALIO
        UPDATE "CAF_Solicitud_Persona" SET "Estado" = 'DENTRO', "Fecha_Hora_Ingreso" = (CURRENT_DATE - 1) + TIME '09:00' WHERE "ID_Solicitud_Persona" = v_ppd;
        CALL "ERP_CAF_CONTRATISTA_CIERRE_DIA"(CURRENT_DATE, 0, v_agr, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 cierre: si era el último día queda SALIO', '1|SALIO', v_agr || '|' || pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_ppd), v_msg);

        -- Editar: una solicitud de franja aprobada no se modifica
        CALL "ERP_CAF_SOLICITUD_EDITAR_DATOS"(v_cxa, CAST(CURRENT_DATE + 20 AS TIMESTAMP), 'Montajes Franja S.A.C.', NULL, NULL, 'Cambio de tablero', NULL, v_z_adm::TEXT, NULL, 'N', NULL, 'Sala de tableros', 'Juan Pérez', '999 888 777', 'juan@montajes.pe', NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reab, v_cod, v_msg);
        PERFORM pg_temp.chk('D-227 editar: una solicitud de contratista aprobada no se modifica', '409', v_cod::TEXT, v_msg);
    END;
    END;
    END;
    END;
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Nota"
  FROM pruebas WHERE esperado <> obtenido ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
