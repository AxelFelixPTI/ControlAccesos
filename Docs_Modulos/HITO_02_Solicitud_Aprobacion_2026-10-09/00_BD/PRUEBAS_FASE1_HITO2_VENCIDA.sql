-- =============================================================================
-- Archivo : PRUEBAS_FASE1_HITO2_VENCIDA.sql   (2026-11-19, D-251)
-- Propósito: pruebas de la entrega 2C-3a: estado VENCIDA, plazo de decisión, días de atraso, franja en curso sin aprobar,
--   pestaña «Fuera de tiempo» de la bandeja, contadores y los dos parámetros nuevos
--   (SOLICITUD_HORA_CORTE_VENCIMIENTO y SOLICITUD_HORAS_ANTICIPACION_APROBAR).
--   Termina en ROLLBACK: la base queda exactamente como estaba.
-- Requiere: scripts 01 a 36 y todos los SP (los mismos que PRUEBAS_FASE1_HITO2_LECTURA).
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
    -- A: visita externa de AYER sin decidir (vence)          B: visita de HOY sin decidir (dentro de plazo)
    -- C: visita en 2 días                                    H: visita de hace 2 días OBSERVADA (vence)
    -- FC: franja contratista EN CURSO (anteayer, ayer, hoy, mañana)   FT: franja contratista TERMINADA (último día = ayer)
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'A S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e1::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_sa, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Prep: A creada', '100', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = CAST(CURRENT_DATE - 1 AS TIMESTAMP) + INTERVAL '9 hours' WHERE "ID_Solicitud" = v_sa;
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_hoy, 'B S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e2::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_sb, v_cs, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'C S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e3::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_sc, v_cs, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'H S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e4::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_sh, v_cs, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sh, v_paso_ext, 'OBSERVADA', 'Falta el DNI', pg_temp.sp(v_sh, v_e4)::TEXT, v_u_coo, v_n, v_cod, v_msg);
    PERFORM pg_temp.chk('Prep: H observada por el Coordinador', 'OBSERVADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sh), v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = CAST(CURRENT_DATE - 2 AS TIMESTAMP) + INTERVAL '9 hours' WHERE "ID_Solicitud" = v_sh;

    SELECT P."ID_Tipo_Acceso_Paso_Aprobacion" INTO v_paso_con FROM "Tipo_Acceso_Paso_Aprobacion" P JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = P."ID_Catalogo_Tipo_Acceso" WHERE T."Codigo" = 'CONTRATISTA' ORDER BY P."Orden" LIMIT 1;
    v_dias := TO_CHAR(CURRENT_DATE + 1, 'YYYY-MM-DD') || ',' || TO_CHAR(CURRENT_DATE + 2, 'YYYY-MM-DD') || ',' || TO_CHAR(CURRENT_DATE + 3, 'YYYY-MM-DD') || ',' || TO_CHAR(CURRENT_DATE + 4, 'YYYY-MM-DD');
    CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Franja en curso S.A.C.', 'Cambio de tablero', NULL, v_z_adm::TEXT, v_e5::TEXT, NULL, NULL, NULL, NULL, 'Sala', 'Juan Pérez', '999 888 777', 'juan@franja.pe', v_dias, NULL, NULL, v_u_sol, v_fc, v_cx, v_cod, v_msg);
    PERFORM pg_temp.chk('Prep: franja en curso creada', '100', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Dia" SET "Fecha" = "Fecha" - 3 WHERE "ID_Solicitud" = v_fc;
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = "Fecha_Hora_Prevista" - INTERVAL '3 days' WHERE "ID_Solicitud" = v_fc;
    CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves, NULL, 'Franja terminada S.A.C.', 'Cambio de tablero', NULL, v_z_adm::TEXT, v_e6::TEXT, NULL, NULL, NULL, NULL, 'Sala', 'Juan Pérez', '999 888 777', 'juan@franja.pe', v_dias, NULL, NULL, v_u_sol, v_ft, v_cx, v_cod, v_msg);
    PERFORM pg_temp.chk('Prep: franja terminada creada', '100', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud_Dia" SET "Fecha" = "Fecha" - 5 WHERE "ID_Solicitud" = v_ft;
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = "Fecha_Hora_Prevista" - INTERVAL '5 days' WHERE "ID_Solicitud" = v_ft;

    -- ===================================================== 1. PIEZAS DE PLAZO
    PERFORM pg_temp.chk('Plazo: el último día de A es ayer', TO_CHAR(CURRENT_DATE - 1, 'YYYY-MM-DD'), "ERP_CAF_FN_SOLICITUD_FIN_DIA"(v_sa)::TEXT, '');
    PERFORM pg_temp.chk('Plazo: el último día de la franja en curso es mañana', TO_CHAR(CURRENT_DATE + 1, 'YYYY-MM-DD'), "ERP_CAF_FN_SOLICITUD_FIN_DIA"(v_fc)::TEXT, '');
    PERFORM pg_temp.chk('Plazo: A (ayer) está fuera de plazo', 'Y', "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(v_sa), '');
    PERFORM pg_temp.chk('Plazo: B (hoy) sigue dentro de plazo', 'N', "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(v_sb), 'el día de la visita el Coordinador aún puede decidir');
    PERFORM pg_temp.chk('Plazo: C (en 2 días) dentro de plazo', 'N', "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(v_sc), '');
    PERFORM pg_temp.chk('Plazo: la franja en curso sigue dentro de plazo', 'N', "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(v_fc), '');
    PERFORM pg_temp.chk('Plazo: la franja terminada está fuera de plazo', 'Y', "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(v_ft), '');
    PERFORM pg_temp.chk('Plazo: solicitud inexistente no está fuera de plazo', 'N', "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(999999), '');
    PERFORM pg_temp.chk('Atraso: A lleva 1 día', '1', "ERP_CAF_FN_SOLICITUD_DIAS_ATRASO"(v_sa)::TEXT, '');
    PERFORM pg_temp.chk('Atraso: H lleva 2 días', '2', "ERP_CAF_FN_SOLICITUD_DIAS_ATRASO"(v_sh)::TEXT, '');
    PERFORM pg_temp.chk('Atraso: la franja terminada lleva 1 día desde su último día', '1', "ERP_CAF_FN_SOLICITUD_DIAS_ATRASO"(v_ft)::TEXT, '');
    PERFORM pg_temp.chk('Atraso: B (hoy) no tiene atraso', '0', "ERP_CAF_FN_SOLICITUD_DIAS_ATRASO"(v_sb)::TEXT, '');
    PERFORM pg_temp.chk('Franja sin aprobar: la franja en curso lleva 2 días iniciada', '2', "ERP_CAF_FN_SOLICITUD_FRANJA_SIN_APROBAR"(v_fc)::TEXT, '');
    PERFORM pg_temp.chk('Franja sin aprobar: una visita de un solo día no aplica', '0', "ERP_CAF_FN_SOLICITUD_FRANJA_SIN_APROBAR"(v_sb)::TEXT, '');
    PERFORM pg_temp.chk('Franja sin aprobar: la franja terminada no aplica (ya venció)', '0', "ERP_CAF_FN_SOLICITUD_FRANJA_SIN_APROBAR"(v_ft)::TEXT, '');

    -- ===================================================== 2. PARÁMETROS
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('SOLICITUD_HORA_CORTE_VENCIMIENTO', '25:61', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Parámetro: hora de corte inválida se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('SOLICITUD_HORAS_ANTICIPACION_APROBAR', 'abc', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Parámetro: horas de anticipación no numéricas se rechazan', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('SOLICITUD_HORAS_ANTICIPACION_APROBAR', '1000', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Parámetro: más de 999 horas se rechaza', '400', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Parámetro: la anticipación nace apagada (0)', '0', "ERP_CAF_PARAMETRO_VALOR"('SOLICITUD_HORAS_ANTICIPACION_APROBAR'), '');
    PERFORM pg_temp.chk('Parámetro: la hora de corte nace en 00:00', '00:00', "ERP_CAF_PARAMETRO_VALOR"('SOLICITUD_HORA_CORTE_VENCIMIENTO'), '');
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('SOLICITUD_HORA_CORTE_VENCIMIENTO', '23:59', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Parámetro: hora de corte válida se guarda', '100', v_cod::TEXT, v_msg);
    IF CURRENT_TIME < TIME '23:58' THEN
        PERFORM pg_temp.chk('Corte 23:59: A (ayer) aún está dentro de plazo', 'N', "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(v_sa), 'el día sigue abierto hasta la hora de corte');
    END IF;
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('SOLICITUD_HORA_CORTE_VENCIMIENTO', '00:00', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Corte 00:00: A (ayer) vuelve a estar fuera de plazo', 'Y', "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(v_sa), '');
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('SOLICITUD_HORAS_ANTICIPACION_APROBAR', '72', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Anticipación 72 h: C (en 2 días) queda fuera de plazo', 'Y', "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(v_sc), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sc, v_paso_ext, 'APROBADA', NULL, pg_temp.sp(v_sc, v_e3)::TEXT, v_u_coo, v_n, v_cod, v_msg);
    PERFORM pg_temp.chk('Anticipación 72 h: no se puede aprobar C', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('SOLICITUD_HORAS_ANTICIPACION_APROBAR', '0', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Anticipación apagada: C vuelve a estar dentro de plazo', 'N', "ERP_CAF_FN_SOLICITUD_FUERA_DE_PLAZO"(v_sc), '');

    -- ===================================================== 3. ANTES DE VENCER
    PERFORM pg_temp.chk('Antes: A sigue PENDIENTE en la base', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sa), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sa, v_paso_ext, 'APROBADA', NULL, pg_temp.sp(v_sa, v_e1)::TEXT, v_u_coo, v_n, v_cod, v_msg);
    PERFORM pg_temp.chk('Antes: aunque el estado aún no cambie, no se aprueba una solicitud fuera de plazo', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Antes: PASOS_DECIDIBLES no ofrece A al Coordinador', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_coo || ',' || v_sa || ')'), '');
    PERFORM pg_temp.chk('Antes: PASOS_DECIDIBLES sí ofrece B (hoy)', 'true', pg_temp.q('SELECT (COUNT(*) > 0)::TEXT FROM "ERP_CAF_SOLICITUD_PASOS_DECIDIBLES"(' || v_u_coo || ',' || v_sb || ')'), '');

    -- ===================================================== 4. VENCER
    CALL "ERP_CAF_SOLICITUD_VENCER"(-1, v_cant_v, v_cod, v_msg);
    PERFORM pg_temp.chk('Vencer: usuario inválido', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_VENCER"(0, v_cant_v, v_cod, v_msg);
    PERFORM pg_temp.chk('Vencer: respuesta 100', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Vencer: vencen A, H (observada) y la franja terminada', '3', v_cant_v::TEXT, v_msg);
    PERFORM pg_temp.chk('Vencer: A queda VENCIDA', 'VENCIDA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Vencer: H (observada) queda VENCIDA', 'VENCIDA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sh), '');
    PERFORM pg_temp.chk('Vencer: la franja terminada queda VENCIDA', 'VENCIDA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_ft), '');
    PERFORM pg_temp.chk('Vencer: B (hoy) sigue PENDIENTE', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sb), '');
    PERFORM pg_temp.chk('Vencer: C (futura) sigue PENDIENTE', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sc), '');
    PERFORM pg_temp.chk('Vencer: la franja en curso sigue PENDIENTE', 'PENDIENTE', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_fc), '');
    CALL "ERP_CAF_SOLICITUD_VENCER"(0, v_cant_v, v_cod, v_msg);
    PERFORM pg_temp.chk('Vencer: es idempotente (la segunda vuelta no vence nada)', '0', v_cant_v::TEXT, v_msg);
    PERFORM pg_temp.chk('Vencer: queda constancia en el historial, hecha por el Sistema', 'Sistema', pg_temp.q('SELECT "Usuario_Nombre" FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ',' || v_sa || ') WHERE "Accion" = ''VENCER'''), '');
    PERFORM pg_temp.chk('Vencer: el historial lo explica con palabras', 'La solicitud venció: nadie la decidió a tiempo', pg_temp.q('SELECT "Accion_Texto" FROM "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"(' || v_u_coo || ',' || v_sa || ') WHERE "Accion" = ''VENCER'''), '');
    PERFORM pg_temp.chk('Vencer: la persona de A no queda aprobada', 'PENDIENTE', pg_temp.q('SELECT "Aprobacion" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = ' || v_sa), '');

    -- ===================================================== 5. ACCIONES SOBRE UNA VENCIDA
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_sa, v_paso_ext, 'APROBADA', NULL, pg_temp.sp(v_sa, v_e1)::TEXT, v_u_coo, v_n, v_cod, v_msg);
    PERFORM pg_temp.chk('Vencida: no se puede aprobar', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_sa, 'Ya no', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Vencida: no se puede cancelar', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Vencida: el mensaje manda a Reutilizar', 'true', (v_msg LIKE '%Reutilizar%')::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_PERSONA_AGREGAR"(v_sa, v_e2, v_u_sol, v_pf, v_cod, v_msg);
    PERFORM pg_temp.chk('Vencida: no se pueden agregar personas', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_RECALCULAR"(v_sa, 0, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Vencida: recalcular no la devuelve a PENDIENTE', 'VENCIDA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_sa), '');

    -- ===================================================== 6. LO QUE VE EL SOLICITANTE
    PERFORM pg_temp.chk('Mis: A figura como VENCIDA', 'VENCIDA', pg_temp.q('SELECT "Estado" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Mis: A trae 1 día de atraso', '1', pg_temp.q('SELECT "Dias_Atraso" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Mis: sin botones de editar, personal ni cancelar; sí Reutilizar', 'N|N|N|Y',
        pg_temp.q('SELECT "Puede_Editar_Datos" || ''|'' || "Puede_Modificar_Personal" || ''|'' || "Puede_Cancelar" || ''|'' || "Puede_Reutilizar" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Mis: el motivo del botón apagado habla de Reutilizar', 'true',
        pg_temp.q('SELECT ("Motivo_No_Cancelar" LIKE ''%Reutilizar%'')::TEXT FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_sa), '');
    PERFORM pg_temp.chk('Mis: el filtro por estado VENCIDA devuelve las 3', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ', NULL, NULL, ''VENCIDA'')'), '');
    PERFORM pg_temp.chk('Mis: la franja en curso muestra la advertencia (2 días sin aprobar)', '2', pg_temp.q('SELECT "Franja_Sin_Aprobar" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_fc), '');
    PERFORM pg_temp.chk('Mis: B no muestra advertencia de franja', '0', pg_temp.q('SELECT "Franja_Sin_Aprobar" FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_u_sol || ') WHERE "ID_Solicitud" = ' || v_sb), '');
    PERFORM pg_temp.chk('Detalle: A trae estado VENCIDA y su atraso', 'VENCIDA|1', pg_temp.q('SELECT "Estado" || ''|'' || "Dias_Atraso" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ',' || v_sa || ')'), '');
    PERFORM pg_temp.chk('Detalle: la franja en curso trae la advertencia', '2', pg_temp.q('SELECT "Franja_Sin_Aprobar" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_sol || ',' || v_fc || ')'), '');
    PERFORM pg_temp.chk('Detalle: el Coordinador no puede decidir una vencida', 'N', pg_temp.q('SELECT "Puede_Decidir" FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_u_coo || ',' || v_sa || ')'), '');
    PERFORM pg_temp.chk('Contadores: la observada vencida ya no cuenta como con observaciones', '0', pg_temp.q('SELECT "Mis_Con_Observadas" FROM "ERP_CAF_SOLICITUD_CONTADORES"(' || v_u_sol || ')'), '');

    -- ===================================================== 7. LO QUE VE EL COORDINADOR
    PERFORM pg_temp.chk('Bandeja FUERA_DE_TIEMPO: las 3 vencidas', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''FUERA_DE_TIEMPO'')'), '');
    PERFORM pg_temp.chk('Bandeja FUERA_DE_TIEMPO: no mezcla pendientes dentro de plazo', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''FUERA_DE_TIEMPO'') WHERE "Estado" <> ''VENCIDA'''), '');
    PERFORM pg_temp.chk('Bandeja FUERA_DE_TIEMPO: H trae 2 días de atraso', '2', pg_temp.q('SELECT "Dias_Atraso" FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''FUERA_DE_TIEMPO'') WHERE "ID_Solicitud" = ' || v_sh), '');
    PERFORM pg_temp.chk('Bandeja FUERA_DE_TIEMPO: quien no aprueba ni ve todas no ve nada', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_nada || ', NULL, ''FUERA_DE_TIEMPO'')'), '');
    PERFORM pg_temp.chk('Bandeja FUERA_DE_TIEMPO: el solicitante tampoco', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_sol || ', NULL, ''FUERA_DE_TIEMPO'')'), '');
    PERFORM pg_temp.chk('Bandeja POR_DECIDIR: ya no incluye las vencidas', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''POR_DECIDIR'') WHERE "Estado" = ''VENCIDA'''), '');
    PERFORM pg_temp.chk('Bandeja POR_DECIDIR: sí incluye B, C y la franja en curso', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''POR_DECIDIR'') WHERE "ID_Solicitud" IN (' || v_sb || ',' || v_sc || ',' || v_fc || ')'), 'la franja en curso se puede seguir decidiendo');
    PERFORM pg_temp.chk('Bandeja TODAS: muestra las vencidas con su estado', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''TODAS'') WHERE "Estado" = ''VENCIDA'''), '');
    PERFORM pg_temp.chk('Bandeja: una pestaña inventada no devuelve nada', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''XXX'')'), '');
    PERFORM pg_temp.chk('Bandeja: la franja en curso trae su advertencia', '2', pg_temp.q('SELECT "Franja_Sin_Aprobar" FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_u_coo || ', NULL, ''POR_DECIDIR'') WHERE "ID_Solicitud" = ' || v_fc), '');
    PERFORM pg_temp.chk('Contadores: Fuera de tiempo del Coordinador', '3', pg_temp.q('SELECT "Fuera_De_Tiempo" FROM "ERP_CAF_SOLICITUD_CONTADORES"(' || v_u_coo || ')'), '');
    PERFORM pg_temp.chk('Contadores: sin rol no hay Fuera de tiempo', '0', pg_temp.q('SELECT "Fuera_De_Tiempo" FROM "ERP_CAF_SOLICITUD_CONTADORES"(' || v_u_nada || ')'), '');
    PERFORM pg_temp.chk('Contadores: por decidir cuenta B, C y la franja (no las vencidas)', '3', pg_temp.q('SELECT "Por_Decidir_Solicitudes" FROM "ERP_CAF_SOLICITUD_CONTADORES"(' || v_u_coo || ')'), '');

    -- ===================================================== 8. LA FRANJA EN CURSO SE PUEDE APROBAR TARDE
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_fc, v_paso_con, 'APROBADA', NULL, pg_temp.sp(v_fc, v_e5)::TEXT, v_u_coo, v_n, v_cod, v_msg);
    PERFORM pg_temp.chk('Franja en curso: el Coordinador todavía puede aprobar (ya pasaron 2 días)', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Franja en curso: queda APROBADA', 'APROBADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_fc), '');
    PERFORM pg_temp.chk('Franja en curso: aprobada ya no muestra la advertencia', '0', "ERP_CAF_FN_SOLICITUD_FRANJA_SIN_APROBAR"(v_fc)::TEXT, '');
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Nota"
  FROM pruebas WHERE esperado <> obtenido ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
