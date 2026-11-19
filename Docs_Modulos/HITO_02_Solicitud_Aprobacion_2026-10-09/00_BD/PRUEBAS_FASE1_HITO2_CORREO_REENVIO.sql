-- =============================================================================
-- Archivo : PRUEBAS_FASE1_HITO2_CORREO_REENVIO.sql   (2026-11-19, D-252)
-- Propósito: pruebas de la entrega 2C-3b: lista de correos de la solicitud (con su resultado) y reenvío manual.
--   Termina en ROLLBACK: la base queda exactamente como estaba.
-- Requiere: scripts 01 a 37 y todos los SP (los mismos que PRUEBAS_FASE1_HITO2_LECTURA).
-- NOTA: usa funciones temporales de PostgreSQL solo para escribir las pruebas. No se despliegan ni se traducen a HANA.
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
    v_sa BIGINT; v_sb BIGINT; v_sc BIGINT; v_sh BIGINT; v_fc BIGINT; v_ft BIGINT; v_cx VARCHAR(20); v_n BIGINT; v_dias VARCHAR(400); v_paso_con BIGINT; v_pf BIGINT; v_cant_v INT;
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
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_con FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'INTERNO_VISITANTE';
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

    -- ===================================================== ESCENARIO
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'R S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_sa, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Prep: solicitud creada', '100', v_cod::TEXT, v_msg);
    INSERT INTO "CAF_Correo_Pendiente" ("Tipo","ID_Solicitud","Destinatarios","Copia","Asunto","Cuerpo","Estado","Intentos","Ultimo_Error","Fecha_Envio","UsuarioID_Create")
    VALUES ('SOLICITUD_NUEVA', v_sa, 'roberto@ejemplo.pe', 'copia@ejemplo.pe', 'a', 'b', 'ENVIADO', 1, NULL, CURRENT_TIMESTAMP, v_u_sol),
           ('SOLICITUD_DECISION', v_sa, 'carlos@ejemplo.pe', NULL, 'a', 'b', 'ERROR', 3, 'Falló el servidor SMTP: tiempo agotado', NULL, v_u_coo);

    -- ===================================================== 1. LISTA DE CORREOS
    PERFORM pg_temp.chk('Lista: el solicitante ve los correos', 'Y', CASE WHEN (SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_CORREOS_LISTAR"(v_u_sol, v_sa)) >= 2 THEN 'Y' ELSE 'N' END, '');
    PERFORM pg_temp.chk('Lista: el Coordinador también', 'Y', CASE WHEN (SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_CORREOS_LISTAR"(v_u_coo, v_sa)) >= 2 THEN 'Y' ELSE 'N' END, '');
    PERFORM pg_temp.chk('Lista: quien no tiene que ver no ve nada', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_CORREOS_LISTAR"(' || v_u_nada || ',' || v_sa || ')'), '');
    PERFORM pg_temp.chk('Lista: usuario 0 (sistema) no ve nada', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_CORREOS_LISTAR"(0,' || v_sa || ')'), '');
    PERFORM pg_temp.chk('Lista: el correo con error muestra el motivo', 'Falló el servidor SMTP: tiempo agotado',
        pg_temp.q('SELECT "Ultimo_Error" FROM "ERP_CAF_SOLICITUD_CORREOS_LISTAR"(' || v_u_sol || ',' || v_sa || ') WHERE "Estado" = ''ERROR'''), '');
    PERFORM pg_temp.chk('Lista: el correo enviado no trae error', '(nulo)',
        pg_temp.q('SELECT "Ultimo_Error" FROM "ERP_CAF_SOLICITUD_CORREOS_LISTAR"(' || v_u_sol || ',' || v_sa || ') WHERE "Tipo" = ''SOLICITUD_NUEVA'' AND "Estado" = ''ENVIADO'' LIMIT 1'), '');
    PERFORM pg_temp.chk('Lista: el intento cuenta se informa', '3', pg_temp.q('SELECT "Intentos" FROM "ERP_CAF_SOLICITUD_CORREOS_LISTAR"(' || v_u_sol || ',' || v_sa || ') WHERE "Estado" = ''ERROR'''), '');

    -- ===================================================== 2. REENVÍO A LOS MISMOS
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_sol, v_sa, 'Y', NULL, v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Reenvío (mismos): responde 100', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Reenvío (mismos): incluye al Coordinador, al solicitante y a la copia', 'Y',
        CASE WHEN v_dias LIKE '%roberto@ejemplo.pe%' AND v_dias LIKE '%carlos@ejemplo.pe%' AND v_dias LIKE '%copia@ejemplo.pe%' THEN 'Y' ELSE 'N' END, v_dias);
    PERFORM pg_temp.chk('Reenvío (mismos): queda un correo PENDIENTE de tipo SOLICITUD_REENVIO', '1',
        pg_temp.q('SELECT COUNT(*) FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_sa || ' AND "Tipo" = ''SOLICITUD_REENVIO'' AND "Estado" = ''PENDIENTE'''), '');
    PERFORM pg_temp.chk('Reenvío: lo hizo el solicitante', v_u_sol::TEXT,
        pg_temp.q('SELECT "UsuarioID_Create" FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_sa || ' AND "Tipo" = ''SOLICITUD_REENVIO'''), '');
    PERFORM pg_temp.chk('Lista: marca el reenvío y dice quién lo hizo', 'Y|Carlos Solicitante',
        pg_temp.q('SELECT "Es_Reenvio" || ''|'' || SPLIT_PART("Enviado_Por", '' '', 1) || '' '' || SPLIT_PART("Enviado_Por", '' '', 2) FROM "ERP_CAF_SOLICITUD_CORREOS_LISTAR"(' || v_u_sol || ',' || v_sa || ') WHERE "Es_Reenvio" = ''Y'''), '');
    PERFORM pg_temp.chk('Historial: queda registrado el reenvío', '1',
        pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ',' || v_sa || ') WHERE "Accion" = ''CORREO_REENVIAR'' AND "Accion_Texto" = ''Reenvió el correo de la solicitud'' AND "Detalle" LIKE ''%roberto@ejemplo.pe%'''), '');

    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_coo, v_sa, 'Y', NULL, v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Reenvío: con otro ya en cola responde 409', '409', v_cod::TEXT, v_msg);
    UPDATE "CAF_Correo_Pendiente" SET "Estado" = 'ENVIADO' WHERE "Tipo" = 'SOLICITUD_REENVIO';

    -- ===================================================== 3. SOLO A CORREOS NUEVOS
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_coo, v_sa, 'N', NULL, v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Solo nuevos sin correos: responde 400', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_coo, v_sa, 'N', 'esto-no-es-correo', v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Correo adicional inválido: responde 400', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_coo, v_sa, 'N', 'Extra@Otro.com; otro@x.pe, extra@otro.com', v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Solo nuevos: responde 100 (lo hace el Coordinador)', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Solo nuevos: van únicamente los indicados, sin repetir y en minúsculas', 'extra@otro.com; otro@x.pe', v_dias, '');
    PERFORM pg_temp.chk('Historial: aclara que fue solo a los indicados', '1',
        pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ',' || v_sa || ') WHERE "Accion" = ''CORREO_REENVIAR'' AND "Detalle" LIKE ''%solo a los correos indicados%'''), '');
    UPDATE "CAF_Correo_Pendiente" SET "Estado" = 'ENVIADO' WHERE "Tipo" = 'SOLICITUD_REENVIO';

    -- ===================================================== 4. MISMOS MÁS ADICIONALES
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_sol, v_sa, 'Y', 'nuevo@otra.com', v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Mismos + adicional: responde 100', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Mismos + adicional: están los de siempre y el nuevo', 'Y',
        CASE WHEN v_dias LIKE '%nuevo@otra.com%' AND v_dias LIKE '%roberto@ejemplo.pe%' THEN 'Y' ELSE 'N' END, v_dias);
    PERFORM pg_temp.chk('Mismos + adicional: no se incluyen los de reenvíos anteriores', 'N', CASE WHEN v_dias LIKE '%extra@otro.com%' THEN 'Y' ELSE 'N' END, v_dias);
    UPDATE "CAF_Correo_Pendiente" SET "Estado" = 'ENVIADO' WHERE "Tipo" = 'SOLICITUD_REENVIO';

    -- ===================================================== 5. PERMISOS Y VALIDACIONES
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_nada, v_sa, 'Y', NULL, v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Quien no tiene que ver la solicitud: 404', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(0, v_sa, 'Y', NULL, v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Usuario del sistema no reenvía: 400', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_sol, v_sa, 'X', NULL, v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Modo inválido: 400', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_sol, 99999999, 'Y', NULL, v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Solicitud inexistente: 404', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_sol2, v_sa, 'Y', NULL, v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Otro solicitante (no es suya): 404', '404', v_cod::TEXT, v_msg);

    UPDATE "CAF_Solicitud" SET "Estado" = 'CANCELADA' WHERE "ID_Solicitud" = v_sa;
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_sol, v_sa, 'Y', NULL, v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Una solicitud cancelada también se puede reenviar (con su estado actual)', '100', v_cod::TEXT, v_msg);
    -- ===================================================== 6. RESUMEN DEL ÚLTIMO ENVÍO (nota de Mis solicitudes, Bandeja y Detalle)
    UPDATE "CAF_Correo_Pendiente" SET "Eliminado" = 'Y' WHERE "ID_Solicitud" = v_sa;
    PERFORM pg_temp.chk('Resumen: sin correos no hay nota', '(nulo)', pg_temp.q('SELECT "ERP_CAF_FN_SOLICITUD_CORREO_ESTADO"(' || v_sa || ')'), '');
    INSERT INTO "CAF_Correo_Pendiente" ("Tipo","ID_Solicitud","Destinatarios","Asunto","Cuerpo","Estado","UsuarioID_Create","CreateDate")
    VALUES ('SOLICITUD_NUEVA', v_sa, 'a@x.pe', 'a', 'b', 'ENVIADO', v_u_sol, CURRENT_TIMESTAMP - INTERVAL '3 minutes');
    PERFORM pg_temp.chk('Resumen: enviado con éxito (automático)', 'ENVIADO:A', pg_temp.q('SELECT "ERP_CAF_FN_SOLICITUD_CORREO_ESTADO"(' || v_sa || ')'), '');
    INSERT INTO "CAF_Correo_Pendiente" ("Tipo","ID_Solicitud","Destinatarios","Asunto","Cuerpo","Estado","Ultimo_Error","UsuarioID_Create","CreateDate")
    VALUES ('SOLICITUD_DECISION', v_sa, 'a@x.pe', 'a', 'b', 'ERROR', 'SMTP caído', v_u_coo, CURRENT_TIMESTAMP - INTERVAL '2 minutes');
    PERFORM pg_temp.chk('Resumen: el último falló', 'ERROR:A', pg_temp.q('SELECT "ERP_CAF_FN_SOLICITUD_CORREO_ESTADO"(' || v_sa || ')'), '');
    PERFORM pg_temp.chk('Resumen: Mis solicitudes trae la nota', 'ERROR:A', pg_temp.q('SELECT "Correo_Estado" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Resumen: la Bandeja trae la nota', 'ERROR:A', pg_temp.q('SELECT "Correo_Estado" FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ',' || v_ves || ',''TODAS'') WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Resumen: el Detalle trae la nota', 'ERROR:A', pg_temp.q('SELECT "Correo_Estado" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ',' || v_sa || ')'), '');
    CALL "ERP_CAF_SOLICITUD_CORREO_REENVIAR"(v_u_sol, v_sa, 'Y', NULL, v_dias, v_cod, v_msg);
    PERFORM pg_temp.chk('Resumen: reenvío manual en cola', 'PENDIENTE:M', pg_temp.q('SELECT "ERP_CAF_FN_SOLICITUD_CORREO_ESTADO"(' || v_sa || ')'), v_msg);
    UPDATE "CAF_Correo_Pendiente" SET "Estado" = 'ENVIADO' WHERE "Tipo" = 'SOLICITUD_REENVIO' AND "ID_Solicitud" = v_sa;
    PERFORM pg_temp.chk('Resumen: tras el error, el reenvío sale bien → enviado (manual)', 'ENVIADO:M', pg_temp.q('SELECT "ERP_CAF_FN_SOLICITUD_CORREO_ESTADO"(' || v_sa || ')'), '');
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Nota"
  FROM pruebas WHERE esperado <> obtenido ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
