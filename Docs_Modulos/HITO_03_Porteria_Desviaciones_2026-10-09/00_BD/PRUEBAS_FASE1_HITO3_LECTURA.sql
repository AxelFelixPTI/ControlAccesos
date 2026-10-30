-- =============================================================================
-- Archivo : PRUEBAS_FASE1_HITO3_LECTURA.sql
-- Proyecto: Control de Accesos · V1.0 2026-10-17
-- Propósito: pruebas automáticas de las LECTURAS del Hito 3: checklist, ficha de portería,
--   bitácora, detalle, respaldos, desviaciones, contadores y listas desplegables.
--   Comprueba que cada botón («Puede_...») coincide con lo que de verdad hace
--   el procedimiento de escritura (la regla vive en un solo lugar).
--   Termina en ROLLBACK: la base queda exactamente como estaba.
-- Requiere: scripts 01 a 10, los SP de los Hitos 0, 1 y 2 y los 4 archivos del Hito 3
--   (SP_CAF_DESVIACION_ALL, SP_CAF_PORTERIA_ALL, SP_CAF_RESPALDO_ALL, SP_CAF_PORTERIA_LECTURA_ALL).
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
-- «id:Y,id:N,...» con todos los ítems de la etapa; los códigos de HV_Fallan salen en N
CREATE FUNCTION pg_temp.items(p BIGINT, etapa TEXT, eq TEXT, he TEXT, fallan TEXT) RETURNS TEXT LANGUAGE sql
AS $f$ SELECT STRING_AGG(A."ID_Catalogo_Item_Checklist" || ':' || CASE WHEN A."Codigo" = ANY(STRING_TO_ARRAY(fallan, ',')) THEN 'N' ELSE 'Y' END, ',' ORDER BY A."Orden")
         FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(p, etapa, eq, he) A $f$;
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
    v_reg2 BIGINT; v_des2 BIGINT; v_n INT; v_txt TEXT;
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
                                   NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_s1, v_cs1, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S1 creada', '100', v_cod::TEXT, v_msg);
    v_p1 := pg_temp.sp(v_s1, v_e[1]); v_p2 := pg_temp.sp(v_s1, v_e[2]); v_p3 := pg_temp.sp(v_s1, v_e[3]);
    v_p4 := pg_temp.sp(v_s1, v_e[4]); v_p5 := pg_temp.sp(v_s1, v_e[5]); v_p6 := pg_temp.sp(v_s1, v_e[6]);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso_ext, 'APROBADA', NULL, v_p1||','||v_p2||','||v_p3||','||v_p4||','||v_p5||','||v_p6, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S1 aprobada', '100', v_cod::TEXT, v_msg);
    -- S2: HOY, personas 11 y 12 aprobadas (la 11 no se usa: queda ESPERADA todo el tiempo)
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_hoy, 'Otra Visita S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e[11] || ',' || v_e[12], NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_s2, v_cs, v_cod, v_msg);
    v_p11 := pg_temp.sp(v_s2, v_e[11]); v_p12 := pg_temp.sp(v_s2, v_e[12]);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso_ext, 'APROBADA', NULL, v_p11 || ',' || v_p12, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S2 con dos personas aprobadas', '100', v_cod::TEXT, v_msg);
    -- S5: visita PASADA (hace 3 días), personas 7 y 8 aprobadas, 9 pendiente
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Pasada S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e[7] || ',' || v_e[8] || ',' || v_e[9], NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_s5, v_cs, v_cod, v_msg);
    v_p7 := pg_temp.sp(v_s5, v_e[7]); v_p8 := pg_temp.sp(v_s5, v_e[8]); v_p9 := pg_temp.sp(v_s5, v_e[9]);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s5, v_paso_ext, 'APROBADA', NULL, v_p7||','||v_p8, v_u_coo, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S5 aprobada', '100', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = CURRENT_TIMESTAMP - INTERVAL '3 days' WHERE "ID_Solicitud" = v_s5;
    v_pas := CURRENT_TIMESTAMP - INTERVAL '3 days';
    -- S3: aprobada y luego cancelada, también de fecha pasada (persona 10)
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_ext, v_per, v_fut, 'Cancelada S.A.', v_mot, NULL, NULL, v_z_adm::TEXT, v_e[10]::TEXT, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_s3, v_cs, v_cod, v_msg);
    v_p10 := pg_temp.sp(v_s3, v_e[10]);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s3, v_paso_ext, 'APROBADA', NULL, v_p10::TEXT, v_u_coo, v_cant, v_cod, v_msg);
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_s3, 'Reprogramada', v_u_sol, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: S3 cancelada', '100', v_cod::TEXT, v_msg);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = CURRENT_TIMESTAMP - INTERVAL '3 days' WHERE "ID_Solicitud" = v_s3;

    -- ===================================================== MOVIMIENTOS PREVIOS (con los procedimientos de escritura)
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'N', 'N', 'Llegó puntual', NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: ingreso de la persona 1', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p2, pg_temp.items(v_p2, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_lib, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: ingreso de la persona 2 con desviación', '100', v_cod::TEXT, v_msg);
    v_des2 := v_des;
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p4, pg_temp.items(v_p4, 'INGRESO', 'N', 'N', 'ING_IDENTIDAD'), 'N', 'N', NULL, 'Documento no coincide.', v_u_coo, v_t_den, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: ingreso denegado de la persona 4', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('EQUIPOS', 'G_FSCA_009', NULL, v_p5::TEXT, 'Laptop', v_u_vig, v_resp, v_cod, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('HERRAMIENTAS_MATERIALES', 'GUIA_REMISION', 'T001-00045', v_p5::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p5, pg_temp.items(v_p5, 'INGRESO', 'Y', 'Y', ''), 'Y', 'Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: ingreso de la persona 5 con equipos y herramientas', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'SALIDA', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: salida de la persona 1', '100', v_cod::TEXT, v_msg);
    v_reg2 := v_reg;
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p3, pg_temp.items(v_p3, 'INGRESO', 'N', 'N', 'ING_SCTR,ING_EPP'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_rest, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p3, pg_temp.items(v_p3, 'SALIDA', 'N', 'N', 'SAL_SIN_ELEMENTOS'), NULL, 'Lleva un equipo.', v_u_coo, v_t_ret, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: salida de la persona 3 con retención', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des2, 'Conforme', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparación: se da conformidad a una desviación', '100', v_cod::TEXT, v_msg);
    -- ===================================================== A. CHECKLIST_OBTENER
    PERFORM pg_temp.chk('Checklist: ingreso, mismos ítems que usa el SP', (SELECT COUNT(*)::TEXT FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(v_p12, 'INGRESO', 'N', 'N')), pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(' || v_u_vig || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'')'), '');
    PERFORM pg_temp.chk('Checklist: ingreso tiene al menos 5 ítems', 'si', CASE WHEN pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(' || v_u_vig || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'')')::INT >= 5 THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Checklist: el único crítico es la identidad', 'ING_IDENTIDAD', pg_temp.q('SELECT STRING_AGG("Codigo", '','') FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(' || v_u_vig || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'') WHERE "Es_Critico" = ''Y'''), '');
    PERFORM pg_temp.chk('Checklist: ingreso con equipos agrega ítems', 'si', CASE WHEN pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(' || v_u_vig || ', ' || v_p12 || ', ''INGRESO'', ''Y'', ''Y'')')::INT >= pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(' || v_u_vig || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'')')::INT THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Checklist: salida usa lo que la persona trajo (con equipos y herramientas, más ítems)', '2', (pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(' || v_u_vig || ', ' || v_p5 || ', ''SALIDA'', ''N'', ''N'')')::INT - pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(' || v_u_vig || ', ' || v_p2 || ', ''SALIDA'', ''N'', ''N'')')::INT)::TEXT, '');
    PERFORM pg_temp.chk('Checklist: sin permiso, cero filas', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(' || v_u_nada || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'')'), '');
    PERFORM pg_temp.chk('Checklist: el Coordinador (solo consulta) no lo obtiene', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(' || v_u_coo || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'')'), '');
    PERFORM pg_temp.chk('Checklist: persona inexistente', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(' || v_u_vig || ', 999999, ''INGRESO'', ''N'', ''N'')'), '');
    PERFORM pg_temp.chk('Checklist: etapa inválida', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(' || v_u_vig || ', ' || v_p12 || ', ''OTRA'', ''N'', ''N'')'), '');
    -- ===================================================== B. FICHA y botones (coinciden con los SP de escritura)
    PERFORM pg_temp.chk('Ficha: persona esperada puede ingresar', 'Y', pg_temp.q('SELECT "Puede_Registrar_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p12 || ')'), '');
    PERFORM pg_temp.chk('Ficha: persona esperada no puede salir (con motivo)', 'N|La persona aún no ingresó.', pg_temp.q('SELECT "Puede_Registrar_Salida" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p12 || ')') || '|' || pg_temp.q('SELECT "Motivo_No_Salida" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p12 || ')'), '');
    PERFORM pg_temp.chk('Ficha: trae el nombre completo', 'Apellido12 Materno12, Nombre12', pg_temp.q('SELECT "Persona_Nombre" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p12 || ')'), '');
    PERFORM pg_temp.chk('Ficha: persona dentro no puede ingresar (con motivo)', 'N|La persona ya ingresó.', pg_temp.q('SELECT "Puede_Registrar_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p2 || ')') || '|' || pg_temp.q('SELECT "Motivo_No_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p2 || ')'), '');
    PERFORM pg_temp.chk('Ficha: persona dentro puede salir', 'Y', pg_temp.q('SELECT "Puede_Registrar_Salida" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p2 || ')'), '');
    PERFORM pg_temp.chk('Ficha: persona que ya salió', 'N|N', pg_temp.q('SELECT "Puede_Registrar_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p1 || ')') || '|' || pg_temp.q('SELECT "Puede_Registrar_Salida" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p1 || ')'), '');
    PERFORM pg_temp.chk('Ficha: persona denegada', 'DENEGADA|N|N', pg_temp.q('SELECT "Estado" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p4 || ')') || '|' || pg_temp.q('SELECT "Puede_Registrar_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p4 || ')') || '|' || pg_temp.q('SELECT "Puede_Registrar_Salida" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p4 || ')'), '');
    PERFORM pg_temp.chk('Ficha: persona sin aprobar no puede ingresar', 'N|La persona no está autorizada para ingresar.', pg_temp.q('SELECT "Puede_Registrar_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p9 || ')') || '|' || pg_temp.q('SELECT "Motivo_No_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p9 || ')'), '');
    PERFORM pg_temp.chk('Ficha: visita pasada no ingresa normal pero sí tardío', 'N|Y', pg_temp.q('SELECT "Puede_Registrar_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p7 || ')') || '|' || pg_temp.q('SELECT "Puede_Registrar_Ingreso_Tardio" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p7 || ')'), '');
    PERFORM pg_temp.chk('Ficha: visita de hoy no necesita tardío', 'N', pg_temp.q('SELECT "Puede_Registrar_Ingreso_Tardio" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p12 || ')'), '');
    PERFORM pg_temp.chk('Ficha: solicitud cancelada', 'N|La solicitud está cancelada.', pg_temp.q('SELECT "Puede_Registrar_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p10 || ')') || '|' || pg_temp.q('SELECT "Motivo_No_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p10 || ')'), '');
    PERFORM pg_temp.chk('Ficha: el Coordinador la ve pero sin botones', 'N|N|Solo tiene permiso de consulta.', pg_temp.q('SELECT "Puede_Registrar_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_coo || ', ' || v_p12 || ')') || '|' || pg_temp.q('SELECT "Puede_Registrar_Salida" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_coo || ', ' || v_p12 || ')') || '|' || pg_temp.q('SELECT "Motivo_No_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_coo || ', ' || v_p12 || ')'), '');
    PERFORM pg_temp.chk('Ficha: sin permiso, cero filas', '(nulo)', pg_temp.q('SELECT "Estado" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_nada || ', ' || v_p12 || ')'), '');
    PERFORM pg_temp.chk('Ficha: el solicitante no la ve', '(nulo)', pg_temp.q('SELECT "Estado" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_sol || ', ' || v_p12 || ')'), '');
    PERFORM pg_temp.chk('Ficha: inexistente', '(nulo)', pg_temp.q('SELECT "Estado" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || 999999 || ')'), '');
    PERFORM pg_temp.chk('Ficha: respaldos de la persona 5', 'Y|Y', pg_temp.q('SELECT "Tiene_Respaldo_Equipos" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p5 || ')') || '|' || pg_temp.q('SELECT "Tiene_Respaldo_Herramientas" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p5 || ')'), '');
    PERFORM pg_temp.chk('Ficha: sin respaldos', 'N|N', pg_temp.q('SELECT "Tiene_Respaldo_Equipos" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p12 || ')') || '|' || pg_temp.q('SELECT "Tiene_Respaldo_Herramientas" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p12 || ')'), '');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p2, pg_temp.items(v_p2, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide: botón de ingreso apagado = el SP rechaza (409)', 'N|409', pg_temp.q('SELECT "Puede_Registrar_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p2 || ')') || '|' || v_cod, '');
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p12, pg_temp.items(v_p12, 'SALIDA', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide: botón de salida apagado = el SP rechaza (409)', 'N|409', pg_temp.q('SELECT "Puede_Registrar_Salida" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p12 || ')') || '|' || v_cod, '');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p12, pg_temp.items(v_p12, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide: botón de ingreso encendido = el SP acepta (100)', 'Y|100', 'Y|' || v_cod, '');
    PERFORM pg_temp.chk('Coincide: y ahora el botón se apaga', 'N|Y', pg_temp.q('SELECT "Puede_Registrar_Ingreso" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p12 || ')') || '|' || pg_temp.q('SELECT "Puede_Registrar_Salida" FROM "ERP_CAF_PORTERIA_FICHA"(' || v_u_vig || ', ' || v_p12 || ')'), '');
    -- ===================================================== C. MOVIMIENTOS_LISTAR (bitácora)
    PERFORM pg_temp.chk('Movimientos de hoy', '8', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_vig || ', ' || v_ves || ')'), '6 ingresos (uno denegado) y 2 salidas');
    PERFORM pg_temp.chk('Movimientos: solo ingresos', '6', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_vig || ', ' || v_ves || ', NULL, NULL, ''INGRESO'')'), '');
    PERFORM pg_temp.chk('Movimientos: solo salidas', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_vig || ', ' || v_ves || ', NULL, NULL, ''SALIDA'')'), '');
    PERFORM pg_temp.chk('Movimientos: búsqueda sin tildes por nombre', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_vig || ', ' || v_ves || ', NULL, NULL, ''INGRESO'', ''nombre4'')'), '');
    PERFORM pg_temp.chk('Movimientos: búsqueda por empresa (sin tildes ni mayúsculas)', '7', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_vig || ', ' || v_ves || ', NULL, NULL, NULL, ''Energia verde'')'), '');
    PERFORM pg_temp.chk('Movimientos: otra fecha no tiene', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_vig || ', ' || v_ves || ', CURRENT_DATE - 1, CURRENT_DATE - 1)'), '');
    PERFORM pg_temp.chk('Movimientos: rango invertido', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_vig || ', ' || v_ves || ', CURRENT_DATE, CURRENT_DATE - 5)'), '');
    PERFORM pg_temp.chk('Movimientos: sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_nada || ', ' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Movimientos: el solicitante no los ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_sol || ', ' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Movimientos: el Coordinador sí', '8', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_coo || ', ' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Movimientos: sede nula', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_vig || ', NULL)'), '');
    PERFORM pg_temp.chk('Movimientos: orden, lo más reciente primero', 'si', CASE WHEN pg_temp.q('SELECT "ID_Registro_Acceso" FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_vig || ', ' || v_ves || ') LIMIT 1')::BIGINT = (SELECT MAX("ID_Registro_Acceso") FROM "CAF_Registro_Acceso") THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Movimientos: indica la desviación', 'Y', pg_temp.q('SELECT "Tiene_Desviacion" FROM "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR"(' || v_u_vig || ', ' || v_ves || ') WHERE "ID_Solicitud_Persona" = ' || v_p2 || ' AND "Tipo_Movimiento" = ''INGRESO'''), '');
    -- ===================================================== D. DETALLE de movimiento y su checklist
    SELECT MIN("ID_Registro_Acceso") INTO v_reg FROM "CAF_Registro_Acceso" WHERE "ID_Solicitud_Persona" = v_p2 AND "Tipo_Movimiento" = 'INGRESO';
    PERFORM pg_temp.chk('Detalle de registro: movimiento y resultado', 'INGRESO|INGRESA', pg_temp.q('SELECT "Tipo_Movimiento" FROM "ERP_CAF_PORTERIA_REGISTRO_DETALLE"(' || v_u_vig || ', ' || v_reg || ')') || '|' || pg_temp.q('SELECT "Resultado" FROM "ERP_CAF_PORTERIA_REGISTRO_DETALLE"(' || v_u_vig || ', ' || v_reg || ')'), '');
    PERFORM pg_temp.chk('Detalle de registro: nombre del vigilante', 'Vigilante Uno, María', pg_temp.q('SELECT "Vigilante_Nombre" FROM "ERP_CAF_PORTERIA_REGISTRO_DETALLE"(' || v_u_vig || ', ' || v_reg || ')'), '');
    PERFORM pg_temp.chk('Detalle de registro: trae la desviación', 'Y', CASE WHEN pg_temp.q('SELECT "ID_Desviacion" FROM "ERP_CAF_PORTERIA_REGISTRO_DETALLE"(' || v_u_vig || ', ' || v_reg || ')') <> '(nulo)' THEN 'Y' ELSE 'N' END, '');
    PERFORM pg_temp.chk('Detalle de registro: sin permiso', '(nulo)', pg_temp.q('SELECT "Resultado" FROM "ERP_CAF_PORTERIA_REGISTRO_DETALLE"(' || v_u_nada || ', ' || v_reg || ')'), '');
    PERFORM pg_temp.chk('Detalle de registro: el solicitante no lo ve', '(nulo)', pg_temp.q('SELECT "Resultado" FROM "ERP_CAF_PORTERIA_REGISTRO_DETALLE"(' || v_u_sol || ', ' || v_reg || ')'), '');
    PERFORM pg_temp.chk('Detalle de registro: inexistente', '(nulo)', pg_temp.q('SELECT "Resultado" FROM "ERP_CAF_PORTERIA_REGISTRO_DETALLE"(' || v_u_vig || ', 999999)'), '');
    PERFORM pg_temp.chk('Checklist del registro: trae todos los ítems', (SELECT COUNT(*)::TEXT FROM "CAF_Registro_Checklist" WHERE "ID_Registro_Acceso" = v_reg), pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR"(' || v_u_vig || ', ' || v_reg || ')'), '');
    PERFORM pg_temp.chk('Checklist del registro: un ítem no cumple', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR"(' || v_u_vig || ', ' || v_reg || ') WHERE "Cumple" = ''N'''), '');
    PERFORM pg_temp.chk('Checklist del registro: sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR"(' || v_u_nada || ', ' || v_reg || ')'), '');
    -- ===================================================== E. RESPALDOS
    PERFORM pg_temp.chk('Respaldos de la persona 5', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_RESPALDO_LISTAR_POR_PERSONA"(' || v_u_vig || ', ' || v_p5 || ')'), '');
    PERFORM pg_temp.chk('Respaldos: la guía de remisión muestra su número', 'T001-00045', pg_temp.q('SELECT "Numero_Documento" FROM "ERP_CAF_RESPALDO_LISTAR_POR_PERSONA"(' || v_u_vig || ', ' || v_p5 || ') WHERE "Tipo_Respaldo" = ''GUIA_REMISION'''), '');
    PERFORM pg_temp.chk('Respaldos: persona sin respaldos', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_RESPALDO_LISTAR_POR_PERSONA"(' || v_u_vig || ', ' || v_p12 || ')'), '');
    PERFORM pg_temp.chk('Respaldos: sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_RESPALDO_LISTAR_POR_PERSONA"(' || v_u_nada || ', ' || v_p5 || ')'), '');
    PERFORM pg_temp.chk('Respaldos: el Coordinador (consulta) los ve', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_RESPALDO_LISTAR_POR_PERSONA"(' || v_u_coo || ', ' || v_p5 || ')'), '');
    -- ===================================================== F. DESVIACIONES
    PERFORM pg_temp.chk('Desviaciones: todas', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_LISTAR"(' || v_u_coo || ', ' || v_ves || ')'), 'ingreso p2 (revisada), ingreso p3, salida p3, ingreso p4 denegado');
    PERFORM pg_temp.chk('Desviaciones: por revisar', '3', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_LISTAR"(' || v_u_coo || ', ' || v_ves || ', ''POR_REVISAR'')'), '');
    PERFORM pg_temp.chk('Desviaciones: revisadas', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_LISTAR"(' || v_u_coo || ', ' || v_ves || ', ''REVISADA'')'), '');
    PERFORM pg_temp.chk('Desviaciones: estado inválido', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_LISTAR"(' || v_u_coo || ', ' || v_ves || ', ''OTRA'')'), '');
    PERFORM pg_temp.chk('Desviaciones: primero las por revisar', 'POR_REVISAR', pg_temp.q('SELECT "Estado" FROM "ERP_CAF_DESVIACION_LISTAR"(' || v_u_coo || ', ' || v_ves || ') LIMIT 1'), '');
    PERFORM pg_temp.chk('Desviaciones: las por revisar, de la más antigua', 'si', CASE WHEN pg_temp.q('SELECT "ID_Desviacion" FROM "ERP_CAF_DESVIACION_LISTAR"(' || v_u_coo || ', ' || v_ves || ', ''POR_REVISAR'') LIMIT 1')::BIGINT = (SELECT MIN("ID_Desviacion") FROM "CAF_Desviacion" WHERE "Estado" = 'POR_REVISAR') THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Desviaciones: búsqueda sin tildes por persona', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_LISTAR"(' || v_u_coo || ', ' || v_ves || ', NULL, NULL, NULL, ''NOMBRE4'')'), '');
    PERFORM pg_temp.chk('Desviaciones: Vigilancia también las ve', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_LISTAR"(' || v_u_vig || ', ' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Desviaciones: sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_LISTAR"(' || v_u_nada || ', ' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Desviaciones: el solicitante no las ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_LISTAR"(' || v_u_sol || ', ' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Desviaciones: otra fecha', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_LISTAR"(' || v_u_coo || ', ' || v_ves || ', NULL, CURRENT_DATE - 10, CURRENT_DATE - 9)'), '');
    PERFORM pg_temp.chk('Contadores: por revisar / revisadas', '3/1', pg_temp.q('SELECT "Por_Revisar" FROM "ERP_CAF_DESVIACION_CONTADORES"(' || v_u_coo || ', ' || v_ves || ')') || '/' || pg_temp.q('SELECT "Revisadas" FROM "ERP_CAF_DESVIACION_CONTADORES"(' || v_u_coo || ', ' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Contadores: sin permiso', '(nulo)', pg_temp.q('SELECT "Por_Revisar" FROM "ERP_CAF_DESVIACION_CONTADORES"(' || v_u_nada || ', ' || v_ves || ')'), '');
    SELECT "ID_Desviacion" INTO v_des FROM "CAF_Desviacion" WHERE "Estado" = 'POR_REVISAR' ORDER BY "ID_Desviacion" LIMIT 1;
    PERFORM pg_temp.chk('Detalle: el Coordinador puede dar conformidad', 'Y', pg_temp.q('SELECT "Puede_Dar_Conformidad" FROM "ERP_CAF_DESVIACION_DETALLE"(' || v_u_coo || ', ' || v_des || ')'), '');
    PERFORM pg_temp.chk('Detalle: Vigilancia la ve pero no da conformidad (con motivo)', 'N|No tiene permiso para dar conformidad.', pg_temp.q('SELECT "Puede_Dar_Conformidad" FROM "ERP_CAF_DESVIACION_DETALLE"(' || v_u_vig || ', ' || v_des || ')') || '|' || pg_temp.q('SELECT "Motivo_No_Conformidad" FROM "ERP_CAF_DESVIACION_DETALLE"(' || v_u_vig || ', ' || v_des || ')'), '');
    PERFORM pg_temp.chk('Detalle: trae al Coordinador consultado y al vigilante', 'si', CASE WHEN pg_temp.q('SELECT "Coordinador_Nombre" FROM "ERP_CAF_DESVIACION_DETALLE"(' || v_u_coo || ', ' || v_des || ')') LIKE '%Roberto%' AND pg_temp.q('SELECT "Registrado_Por_Nombre" FROM "ERP_CAF_DESVIACION_DETALLE"(' || v_u_coo || ', ' || v_des || ')') LIKE '%María%' THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Detalle: sin permiso', '(nulo)', pg_temp.q('SELECT "Codigo" FROM "ERP_CAF_DESVIACION_DETALLE"(' || v_u_nada || ', ' || v_des || ')'), '');
    PERFORM pg_temp.chk('Detalle: inexistente', '(nulo)', pg_temp.q('SELECT "Codigo" FROM "ERP_CAF_DESVIACION_DETALLE"(' || v_u_coo || ', 999999)'), '');
    CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des, 'ok', v_u_vig, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide: botón apagado para Vigilancia = el SP rechaza (101)', 'N|101', pg_temp.q('SELECT "Puede_Dar_Conformidad" FROM "ERP_CAF_DESVIACION_DETALLE"(' || v_u_vig || ', ' || v_des || ')') || '|' || v_cod, '');
    CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des, 'ok', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Coincide: botón encendido para el Coordinador = el SP acepta (100)', '100', v_cod::TEXT, '');
    PERFORM pg_temp.chk('Detalle: después de revisarla, el botón se apaga con motivo', 'N|La desviación ya fue revisada.', pg_temp.q('SELECT "Puede_Dar_Conformidad" FROM "ERP_CAF_DESVIACION_DETALLE"(' || v_u_coo || ', ' || v_des || ')') || '|' || pg_temp.q('SELECT "Motivo_No_Conformidad" FROM "ERP_CAF_DESVIACION_DETALLE"(' || v_u_coo || ', ' || v_des || ')'), '');
    PERFORM pg_temp.chk('Contadores: se actualizan', '2/2', pg_temp.q('SELECT "Por_Revisar" FROM "ERP_CAF_DESVIACION_CONTADORES"(' || v_u_coo || ', ' || v_ves || ')') || '/' || pg_temp.q('SELECT "Revisadas" FROM "ERP_CAF_DESVIACION_CONTADORES"(' || v_u_coo || ', ' || v_ves || ')'), '');
    -- ===================================================== G. DROPDOWNS
    PERFORM pg_temp.chk('Coordinadores: Vigilancia ve al Coordinador', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN"(' || v_u_vig || ', ' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Coordinadores: es Roberto', 'si', CASE WHEN pg_temp.q('SELECT "Nombre" FROM "ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN"(' || v_u_vig || ', ' || v_ves || ')') LIKE '%Roberto%' THEN 'si' ELSE 'no' END, '');
    PERFORM pg_temp.chk('Coordinadores: el solicitante no los pide', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN"(' || v_u_sol || ', ' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Coordinadores: sin permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN"(' || v_u_nada || ', ' || v_ves || ')'), '');
    PERFORM pg_temp.chk('Tratamientos de ingreso', '5', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN"(''INGRESO'')'), '');
    PERFORM pg_temp.chk('Tratamientos de salida', '4', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN"(''SALIDA'')'), '');
    PERFORM pg_temp.chk('Tratamientos: etapa inválida', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN"(''OTRA'')'), '');
    PERFORM pg_temp.chk('Tratamientos: «Liberación» en ingreso da INGRESA', 'INGRESA', pg_temp.q('SELECT "Resultado" FROM "ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN"(''INGRESO'') WHERE "Codigo" = ''LIBERACION'''), '');
    PERFORM pg_temp.chk('Tratamientos: «Retención» en salida da SALE_RETIENE_ELEMENTO', 'SALE_RETIENE_ELEMENTO', pg_temp.q('SELECT "Resultado" FROM "ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN"(''SALIDA'') WHERE "Codigo" = ''RETENCION_ELEMENTO'''), '');
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Nota"
  FROM pruebas WHERE esperado <> obtenido ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
