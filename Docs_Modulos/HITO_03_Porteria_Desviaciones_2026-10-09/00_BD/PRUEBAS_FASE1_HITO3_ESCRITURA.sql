-- =============================================================================
-- Archivo : PRUEBAS_FASE1_HITO3_ESCRITURA.sql
-- Proyecto: Control de Accesos · V1.0 2026-10-17
-- Propósito: pruebas automáticas de los procedimientos de ESCRITURA del Hito 3:
--   ingresos, salidas, denegaciones, desviaciones, conformidad, respaldos,
--   registros tardíos y cierre «no se presentó».
--   Termina en ROLLBACK: la base queda exactamente como estaba.
-- Requiere: scripts 01 a 10, los SP de los Hitos 0, 1 y 2 y los 4 archivos del Hito 3
--   (SP_CAF_DESVIACION_ALL, SP_CAF_PORTERIA_ALL, SP_CAF_RESPALDO_ALL, SP_CAF_PORTERIA_LECTURA_ALL).
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

    -- ===================================================== A. INGRESO: validaciones
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_nada, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: sin permiso en la sede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_coo, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: el Coordinador solo consulta, no registra', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_sol, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: el solicitante no registra', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(999999, '1:Y', 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: persona inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p9, pg_temp.items(v_p9, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: persona con aprobación pendiente', '409', v_cod::TEXT, v_msg);
    v_hecho := CAST(CAST(v_pas AS DATE) AS TIMESTAMP) + INTERVAL '10 hours';
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p10, pg_temp.items(v_p10, 'INGRESO', 'N', 'N', ''), 'N', 'N', 'Tardío', NULL, NULL, NULL, NULL, NULL, v_hecho, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: solicitud cancelada', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, NULL, 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: sin ítems', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, '1:Y,2:Y', 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: faltan ítems', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', '') || ',999:Y', 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: ítem que no corresponde', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', '') || ',1:Y', 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: ítem repetido', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, REPLACE(pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), ':Y', ':X'), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: valor distinto de Y o N', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'Z', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: equipos con valor inválido', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'N', 'N', REPEAT('x', 1001), NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: observación demasiado larga', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: todo cumple pero envían desviación', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, v_t_lib, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: todo cumple pero envían tratamiento', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: ítem no cumple y no hay desviación', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', NULL, v_t_lib, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: desviación sin Coordinador', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_vig, v_t_lib, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: el consultado no es Coordinador', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_ret, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: tratamiento que solo aplica a la salida', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_otro, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: «Otro» sin detalle', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_otro, 'Se acepta con autorización verbal.', NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: «Otro» sin efecto elegido', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_otro, 'x', 'SALE', NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: «Otro» con efecto de otra etapa', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_lib, NULL, 'NO_INGRESA', NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: efecto elegido distinto del que fija el tratamiento', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, REPEAT('x', 2001), v_u_coo, v_t_lib, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: descripción demasiado larga', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_lib, NULL, NULL, NULL, v_u_min, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: sin permiso para registrar desviaciones', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', 'ING_IDENTIDAD'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_lib, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: ítem crítico no cumple y lo quieren liberar', '101', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Ingreso: nada de lo anterior dejó registros', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Registro_Acceso"'), '');
    PERFORM pg_temp.chk('Ingreso: ni desviaciones', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Desviacion"'), '');
    PERFORM pg_temp.chk('Ingreso: ni cambios de estado', 'ESPERADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p1 || ''), '');
    -- ===================================================== B. INGRESO: caminos felices
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'N', 'N', 'Llegó puntual', NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: todo cumple, entra', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Ingreso: resultado INGRESA', 'INGRESA', v_res, '');
    PERFORM pg_temp.chk('Ingreso: sin desviación', '0', v_des::TEXT, '');
    PERFORM pg_temp.chk('Ingreso: la persona queda DENTRO con su hora', 'DENTRO|Y', pg_temp.q('SELECT "Estado" || ''|'' || CASE WHEN "Fecha_Hora_Ingreso" IS NOT NULL THEN ''Y'' ELSE ''N'' END FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p1 || ''), '');
    PERFORM pg_temp.chk('Ingreso: el registro guarda al vigilante, la observación y no es tardío', 'INGRESO|N|Llegó puntual', pg_temp.q('SELECT "Tipo_Movimiento" || ''|'' || "Es_Registro_Tardio" || ''|'' || "Observacion" FROM "CAF_Registro_Acceso" WHERE "ID_Registro_Acceso" = ' || v_reg || ''), '');
    PERFORM pg_temp.chk('Ingreso: guarda cada ítem del checklist (todos cumplen)', 'si', pg_temp.q('SELECT CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_p1 || ', ''INGRESO'', ''N'', ''N'')) AND MIN("Cumple") = ''Y'' THEN ''si'' ELSE ''no'' END FROM "CAF_Registro_Checklist" WHERE "ID_Registro_Acceso" = ' || v_reg || ''), '');
    PERFORM pg_temp.chk('Ingreso: deja el evento INGRESO en la bitácora', '1', pg_temp.ev('REGISTRO_ACCESO', v_reg, 'INGRESO'), '');
    v_reg2 := v_reg;
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: repetirlo es conflicto (ya ingresó)', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p2, pg_temp.items(v_p2, 'INGRESO', 'N', 'N', 'ING_PERTENENCIAS'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_lib, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso con desviación: se libera por Coordinador', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Ingreso con desviación: resultado INGRESA', 'INGRESA', v_res, '');
    PERFORM pg_temp.chk('Ingreso con desviación: crea la desviación', 'DES-' || LPAD(v_des::TEXT, 5, '0'), pg_temp.q('SELECT "Codigo" FROM "CAF_Desviacion" WHERE "ID_Desviacion" = ' || v_des || ''), '');
    PERFORM pg_temp.chk('Ingreso con desviación: queda por revisar y ligada al registro', 'POR_REVISAR|Y', pg_temp.q('SELECT "Estado" || ''|'' || CASE WHEN "ID_Registro_Acceso" = ' || v_reg || ' THEN ''Y'' ELSE ''N'' END FROM "CAF_Desviacion" WHERE "ID_Desviacion" = ' || v_des || ''), '');
    PERFORM pg_temp.chk('Ingreso con desviación: el ítem fallado queda en N', '1', pg_temp.q('SELECT COUNT(*) FROM "CAF_Registro_Checklist" C JOIN "Catalogo_Item_Checklist" I USING ("ID_Catalogo_Item_Checklist") WHERE C."ID_Registro_Acceso" = ' || v_reg || ' AND C."Cumple" = ''N'' AND I."Codigo" = ''ING_PERTENENCIAS'''), '');
    PERFORM pg_temp.chk('Ingreso con desviación: eventos de registro y de desviación', '1/1', pg_temp.ev('REGISTRO_ACCESO', v_reg, 'INGRESO') || '/' || pg_temp.ev('DESVIACION', v_des, 'REGISTRAR'), '');
    v_des2 := v_des;
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p3, pg_temp.items(v_p3, 'INGRESO', 'N', 'N', 'ING_SCTR,ING_EPP'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_rest, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso restringido: se permite solo zona administrativa', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Ingreso restringido: resultado', 'INGRESA_RESTRINGIDO', v_res, '');
    PERFORM pg_temp.chk('Ingreso restringido: la persona queda DENTRO con acceso restringido', 'DENTRO|Y', pg_temp.q('SELECT "Estado" || ''|'' || "Acceso_Restringido" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p3 || ''), '');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p4, pg_temp.items(v_p4, 'INGRESO', 'N', 'N', 'ING_IDENTIDAD'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_den, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso denegado: ítem crítico no cumple y se deniega', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Ingreso denegado: resultado NO_INGRESA', 'NO_INGRESA', v_res, '');
    PERFORM pg_temp.chk('Ingreso denegado: la persona queda DENEGADA, sin hora de ingreso', 'DENEGADA|N', pg_temp.q('SELECT "Estado" || ''|'' || CASE WHEN "Fecha_Hora_Ingreso" IS NOT NULL THEN ''Y'' ELSE ''N'' END FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p4 || ''), '');
    PERFORM pg_temp.chk('Ingreso denegado: evento DENEGAR en la bitácora', '1/0', pg_temp.ev('REGISTRO_ACCESO', v_reg, 'DENEGAR') || '/' || pg_temp.ev('REGISTRO_ACCESO', v_reg, 'INGRESO'), '');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p4, pg_temp.items(v_p4, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: tras una denegación no se reintenta', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p4, '1:Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: a quien se le denegó el ingreso', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p12, pg_temp.items(v_p12, 'INGRESO', 'N', 'N', 'ING_ARCO'), 'N', 'N', NULL, 'El visitante no trajo su DNI físico.', v_u_coo, v_t_otro, 'Firma la autorización en portería.', 'INGRESA', NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso con «Otro»: detalle y efecto elegido', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Ingreso con «Otro»: queda el detalle', 'Firma la autorización en portería.', pg_temp.q('SELECT "Tratamiento_Detalle" FROM "CAF_Desviacion" WHERE "ID_Desviacion" = ' || v_des || ''), '');
    -- ===================================================== C. RESPALDO Y EQUIPOS
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('EQUIPOS', 'G_FSCA_009', NULL, v_p5::TEXT, NULL, v_u_nada, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: sin permiso', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('OTRA', 'G_FSCA_009', NULL, v_p5::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: categoría inválida', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('EQUIPOS', 'GUIA_REMISION', 'T001-1', v_p5::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: tipo que no corresponde a la categoría', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('HERRAMIENTAS_MATERIALES', 'GUIA_REMISION', NULL, v_p5::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: la guía de remisión exige número', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('EQUIPOS', 'G_FSCA_009', 'T001-1', v_p5::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: el G-FSCA-009 no lleva número', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('EQUIPOS', 'G_FSCA_009', NULL, 'abc', NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: lista de personas mal escrita', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('EQUIPOS', 'G_FSCA_009', NULL, NULL, NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: sin personas', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('EQUIPOS', 'G_FSCA_009', NULL, '999999', NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: persona inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('EQUIPOS', 'G_FSCA_009', NULL, v_p9::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: persona sin aprobar', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('EQUIPOS', 'G_FSCA_009', NULL, v_p4::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: persona denegada', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('EQUIPOS', 'G_FSCA_009', NULL, v_p5 || ',' || v_p5, NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: la misma persona dos veces en el mismo respaldo', '400', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Respaldo: lo rechazado no dejó nada', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Respaldo"'), '');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p5, pg_temp.items(v_p5, 'INGRESO', 'Y', 'N', ''), 'Y', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso con equipos: sin respaldo no entra', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p5, pg_temp.items(v_p5, 'INGRESO', 'N', 'Y', ''), 'N', 'Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso con herramientas: sin respaldo no entra', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('EQUIPOS', 'G_FSCA_009', NULL, v_p5 || ',' || v_p6, 'Laptop y proyector', v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: G-FSCA-009 para dos personas', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Respaldo: cubre a las dos personas', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Respaldo_Persona" WHERE "ID_Respaldo" = ' || v_resp || ''), '');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p5, pg_temp.items(v_p5, 'INGRESO', 'Y', 'N', ''), 'Y', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso con equipos: con su respaldo entra', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Ingreso con equipos: se guarda lo que trae', 'Y|N', pg_temp.q('SELECT "Trae_Equipos" || ''|'' || "Trae_Herramientas" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p5 || ''), '');
    PERFORM pg_temp.chk('Ingreso con equipos: el checklist incluye los ítems de equipos (más ítems que sin equipos)', 'si', pg_temp.q('SELECT CASE WHEN (SELECT COUNT(*) FROM "CAF_Registro_Checklist" WHERE "ID_Registro_Acceso" = ' || v_reg || ') >= (SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_p6 || ', ''INGRESO'', ''N'', ''N'')) THEN ''si'' ELSE ''no'' END'), '');
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('HERRAMIENTAS_MATERIALES', 'GUIA_REMISION', 'T001-00045', v_p6::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: guía de remisión con número', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_RESPALDO_REGISTRAR"('HERRAMIENTAS_MATERIALES', 'GUIA_MANUAL_G_FSCA_010', NULL, v_p6::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);
    PERFORM pg_temp.chk('Respaldo: guía manual G-FSCA-010', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p6, pg_temp.items(v_p6, 'INGRESO', 'Y', 'Y', ''), 'Y', 'Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso con equipos y herramientas: con ambos respaldos', '100', v_cod::TEXT, v_msg);
    -- ===================================================== D. INGRESO TARDÍO
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p7, pg_temp.items(v_p7, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: visita de fecha pasada sin marcar tardío', '409', v_cod::TEXT, v_msg);
    v_hecho := CAST(CAST(v_pas AS DATE) AS TIMESTAMP) + INTERVAL '10 hours';
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p7, pg_temp.items(v_p7, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, v_hecho, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso tardío: exige observación', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p7, pg_temp.items(v_p7, 'INGRESO', 'N', 'N', ''), 'N', 'N', 'Se olvidó registrar', NULL, NULL, NULL, NULL, NULL, LOCALTIMESTAMP + INTERVAL '1 hour', v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso tardío: hora futura', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p7, pg_temp.items(v_p7, 'INGRESO', 'N', 'N', ''), 'N', 'N', 'Se olvidó registrar', NULL, NULL, NULL, NULL, NULL, v_hecho + INTERVAL '1 day', v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso tardío: fecha distinta a la de la visita', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p9, pg_temp.items(v_p9, 'INGRESO', 'N', 'N', ''), 'N', 'N', 'x', NULL, NULL, NULL, NULL, NULL, v_hecho, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso tardío: persona sin aprobar', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p7, pg_temp.items(v_p7, 'INGRESO', 'N', 'N', ''), 'N', 'N', 'Se olvidó registrar', NULL, NULL, NULL, NULL, NULL, v_hecho, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso tardío: se registra con la hora del hecho', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Ingreso tardío: queda marcado y con la hora indicada', 'Y|Y', pg_temp.q('SELECT "Es_Registro_Tardio" || ''|'' || CASE WHEN "Fecha_Hora" = ' || QUOTE_LITERAL(v_hecho) || '::timestamp AND "Fecha_Hora_Sistema" > "Fecha_Hora" THEN ''Y'' ELSE ''N'' END FROM "CAF_Registro_Acceso" WHERE "ID_Registro_Acceso" = ' || v_reg || ''), '');
    PERFORM pg_temp.chk('Ingreso tardío: la persona figura con la hora del hecho', 'Y', pg_temp.q('SELECT CASE WHEN "Fecha_Hora_Ingreso" = ' || QUOTE_LITERAL(v_hecho) || '::timestamp THEN ''Y'' ELSE ''N'' END FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p7 || ''), '');
    PERFORM pg_temp.chk('Ingreso tardío: el evento lo dice', 'registro tardío', pg_temp.q('SELECT CASE WHEN "Detalle" LIKE ''%registro tardío%'' THEN ''registro tardío'' ELSE "Detalle" END FROM "CAF_Evento" WHERE "Entidad" = ''REGISTRO_ACCESO'' AND "ID_Entidad" = ' || v_reg || ''), '');
    v_reg2 := v_reg;
    -- ===================================================== E. SALIDA
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p8, pg_temp.items(v_p8, 'SALIDA', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: la persona aún no ingresó', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'SALIDA', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_nada, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: sin permiso', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p1, '1:Y', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: ítems incompletos', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'SALIDA', 'N', 'N', 'SAL_FICHA_DEVUELTA'), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: ítem no cumple y no hay desviación', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'SALIDA', 'N', 'N', 'SAL_FICHA_DEVUELTA'), NULL, 'No devolvió la ficha.', v_u_coo, v_t_den, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: tratamiento que solo aplica al ingreso', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'SALIDA', 'N', 'N', ''), NULL, 'x', NULL, v_t_lib, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: todo cumple pero envían desviación', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'SALIDA', 'N', 'N', ''), 'x', NULL, NULL, NULL, NULL, NULL, LOCALTIMESTAMP + INTERVAL '1 hour', v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida tardía: hora futura', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'SALIDA', 'N', 'N', ''), 'x', NULL, NULL, NULL, NULL, NULL, LOCALTIMESTAMP - INTERVAL '1 day', v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida tardía: anterior al ingreso', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'SALIDA', 'N', 'N', ''), 'Salió conforme', NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: todo cumple', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Salida: resultado SALE', 'SALE', v_res, '');
    PERFORM pg_temp.chk('Salida: la persona queda SALIO con su hora', 'SALIO|Y', pg_temp.q('SELECT "Estado" || ''|'' || CASE WHEN "Fecha_Hora_Salida" IS NOT NULL THEN ''Y'' ELSE ''N'' END FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p1 || ''), '');
    PERFORM pg_temp.chk('Salida: evento SALIDA', '1', pg_temp.ev('REGISTRO_ACCESO', v_reg, 'SALIDA'), '');
    PERFORM pg_temp.chk('Salida: la persona tiene dos movimientos (ingreso y salida)', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Registro_Acceso" WHERE "ID_Solicitud_Persona" = ' || v_p1 || ''), '');
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'SALIDA', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: repetirla es conflicto', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p1, pg_temp.items(v_p1, 'INGRESO', 'N', 'N', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: quien ya salió no vuelve a ingresar', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p2, pg_temp.items(v_p2, 'SALIDA', 'N', 'N', 'SAL_SIN_ELEMENTOS'), NULL, 'Lleva un equipo de la planta.', v_u_coo, v_t_ret, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida con retención: se retiene el elemento', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Salida con retención: resultado', 'SALE_RETIENE_ELEMENTO', v_res, '');
    PERFORM pg_temp.chk('Salida con retención: la persona igual sale', 'SALIO', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p2 || ''), '');
    PERFORM pg_temp.chk('Salida con retención: crea otra desviación (una por movimiento)', '2', pg_temp.q('SELECT COUNT(*) FROM "CAF_Desviacion" D JOIN "CAF_Registro_Acceso" A USING ("ID_Registro_Acceso") WHERE A."ID_Solicitud_Persona" = ' || v_p2 || ''), '');
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p3, pg_temp.items(v_p3, 'SALIDA', 'N', 'N', 'SAL_FICHA_DEVUELTA'), NULL, 'Perdió la ficha.', v_u_coo, v_t_lib, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida con liberación', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Salida con liberación: resultado SALE', 'SALE', v_res, '');
    PERFORM pg_temp.chk('Salida: los ítems de equipos aparecen solo si la persona los trajo', 'si', pg_temp.q('SELECT CASE WHEN (SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_p5 || ', ''SALIDA'', ''Y'', ''N'')) = (SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_p5 || ', ''SALIDA'', ''N'', ''N'')) + 1 THEN ''si'' ELSE ''no'' END'), '');
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p5, pg_temp.items(v_p5, 'SALIDA', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: si falta el ítem de equipos que corresponde, se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p5, pg_temp.items(v_p5, 'SALIDA', 'Y', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: con equipos y todo cumple', '100', v_cod::TEXT, v_msg);
    -- ===================================================== F. SALIDA TARDÍA
    v_hecho := CAST(CAST(v_pas AS DATE) AS TIMESTAMP) + INTERVAL '9 hours';
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p7, pg_temp.items(v_p7, 'SALIDA', 'N', 'N', ''), 'Tardía', NULL, NULL, NULL, NULL, NULL, v_hecho, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida tardía: anterior al ingreso tardío', '400', v_cod::TEXT, v_msg);
    v_hecho := CAST(CAST(v_pas AS DATE) AS TIMESTAMP) + INTERVAL '11 hours';
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p7, pg_temp.items(v_p7, 'SALIDA', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, v_hecho, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida tardía: exige observación', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p7, pg_temp.items(v_p7, 'SALIDA', 'N', 'N', ''), 'Tardía', NULL, NULL, NULL, NULL, NULL, v_hecho, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida tardía: se registra', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Salida tardía: marcada como tardía', 'Y', pg_temp.q('SELECT "Es_Registro_Tardio" FROM "CAF_Registro_Acceso" WHERE "ID_Registro_Acceso" = ' || v_reg || ''), '');
    -- ===================================================== G. CONFORMIDAD DE DESVIACIONES
    CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des2, 'Conforme', v_u_vig, v_cod, v_msg);
    PERFORM pg_temp.chk('Conformidad: Vigilancia no la da', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(999999, 'x', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Conformidad: desviación inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des2, 'Conforme, se regularizó la documentación', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Conformidad: el Coordinador la da', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Conformidad: queda REVISADA con quien y cuándo', 'REVISADA|Y|Y', pg_temp.q('SELECT "Estado" || ''|'' || CASE WHEN "ID_Usuario_Conformidad" = ' || v_u_coo || ' THEN ''Y'' ELSE ''N'' END || ''|'' || CASE WHEN "Fecha_Conformidad" IS NOT NULL THEN ''Y'' ELSE ''N'' END FROM "CAF_Desviacion" WHERE "ID_Desviacion" = ' || v_des2 || ''), '');
    PERFORM pg_temp.chk('Conformidad: evento en la bitácora', '1', pg_temp.ev('DESVIACION', v_des2, 'CONFORMIDAD'), '');
    CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des2, 'otra vez', v_u_coo, v_cod, v_msg);
    PERFORM pg_temp.chk('Conformidad: no se da dos veces', '409', v_cod::TEXT, v_msg);
    -- ===================================================== H. «NO SE PRESENTÓ»
    CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(NULL, v_u_vig, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('No se presentó: solo el proceso automático (usuario 0)', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(CURRENT_DATE + 1, 0, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('No se presentó: fecha de corte futura', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(NULL, 0, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('No se presentó: cierre del día', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('No se presentó: marca solo a la persona aprobada que no vino', '1', v_cant::TEXT, '');
    PERFORM pg_temp.chk('No se presentó: la persona 8 queda NO_SE_PRESENTO', 'NO_SE_PRESENTO', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p8 || ''), '');
    PERFORM pg_temp.chk('No se presentó: la pendiente de aprobación no se toca', 'ESPERADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p9 || ''), '');
    PERFORM pg_temp.chk('No se presentó: la de solicitud cancelada no se toca', 'ESPERADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p10 || ''), '');
    PERFORM pg_temp.chk('No se presentó: las visitas de hoy no se tocan', 'ESPERADA', pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_p11 || ''), '');
    PERFORM pg_temp.chk('No se presentó: deja su evento', '1', pg_temp.ev('SOLICITUD_PERSONA', v_p8, 'NO_SE_PRESENTO'), '');
    CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(NULL, 0, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('No se presentó: repetirlo no hace nada', '0/100', v_cant || '/' || v_cod, '');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_p8, pg_temp.items(v_p8, 'INGRESO', 'N', 'N', ''), 'N', 'N', 'x', NULL, NULL, NULL, NULL, NULL, v_hecho, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Ingreso: quien figura como «no se presentó» no ingresa sin corrección', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_p8, pg_temp.items(v_p8, 'SALIDA', 'N', 'N', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_u_vig, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Salida: quien no se presentó', '409', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(CURRENT_DATE, 0, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('No se presentó: con corte de hoy, la visita de hoy sigue vigente', '0', v_cant::TEXT, '');
    -- ===================================================== I. LA ESCRITURA NO TOCÓ OTRAS COSAS
    PERFORM pg_temp.chk('Cada movimiento tiene su checklist completo', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Registro_Acceso" A WHERE NOT EXISTS (SELECT 1 FROM "CAF_Registro_Checklist" C WHERE C."ID_Registro_Acceso" = A."ID_Registro_Acceso")'), '');
    PERFORM pg_temp.chk('Ninguna desviación huérfana', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Desviacion" D WHERE NOT EXISTS (SELECT 1 FROM "CAF_Registro_Acceso" A WHERE A."ID_Registro_Acceso" = D."ID_Registro_Acceso")'), '');
    PERFORM pg_temp.chk('Códigos de desviación únicos y con formato', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Desviacion" WHERE "Codigo" !~ ''^DES-[0-9]{5}$'''), '');
END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Nota"
  FROM pruebas WHERE esperado <> obtenido ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
