#!/usr/bin/env python3
# Genera PRUEBAS_FASE1_HITO3_ESCRITURA.sql y PRUEBAS_FASE1_HITO3_LECTURA.sql (misma preparación, distintas comprobaciones)
import sys
out = sys.argv[1]

HEAD = '''-- =============================================================================
-- Archivo : {nombre}
-- Proyecto: Control de Accesos · V1.0 2026-10-17
-- Propósito: {proposito}
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

'''

TAIL = '''END;
$$;

SELECT n AS "#", prueba AS "Prueba", esperado AS "Esperado", obtenido AS "Obtenido",
       CASE WHEN esperado = obtenido THEN 'OK' ELSE 'FALLA' END AS "Resultado", detalle AS "Nota"
  FROM pruebas WHERE esperado <> obtenido ORDER BY n;

SELECT 'RESULTADO: ' || SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) || ' de ' || COUNT(*) ||
       CASE WHEN COUNT(*) = SUM(CASE WHEN esperado = obtenido THEN 1 ELSE 0 END) THEN ' OK' ELSE ' (HAY FALLAS)' END
  FROM pruebas;

ROLLBACK;
'''

def ING(p, items, eq='N', he='N', obs='NULL', desc='NULL', coord='NULL', trat='NULL', det='NULL', res='NULL', hecho='NULL', user='v_u_vig'):
    return ('CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(%s, %s, \'%s\', \'%s\', %s, %s, %s, %s, %s, %s, %s, %s, v_reg, v_des, v_res, v_cod, v_msg);'
            % (p, items, eq, he, obs, desc, coord, trat, det, res, hecho, user))

def SAL(p, items, obs='NULL', desc='NULL', coord='NULL', trat='NULL', det='NULL', res='NULL', hecho='NULL', user='v_u_vig'):
    return ('CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, v_reg, v_des, v_res, v_cod, v_msg);'
            % (p, items, obs, desc, coord, trat, det, res, hecho, user))

def IT(p, etapa='INGRESO', eq='N', he='N', fallan=''):
    return "pg_temp.items(%s, '%s', '%s', '%s', '%s')" % (p, etapa, eq, he, fallan)

L = []
def chk(nombre, esperado, obtenido, detalle="''"):
    L.append("    PERFORM pg_temp.chk('%s', %s, %s, %s);" % (nombre.replace("'", "''"), esperado, obtenido, detalle))
def code(nombre, esperado):
    chk(nombre, "'%s'" % esperado, "v_cod::TEXT", "v_msg")
def q(sql):
    import re
    s = re.sub(r"' \|\| ([\w()]+) \|\| '", lambda m: "\x00" + m.group(1) + "\x01", sql)
    s = s.replace("'", "''")
    s = s.replace("\x00", "' || ").replace("\x01", " || '")
    return "pg_temp.q('" + s + "')"
def raw(s):
    L.append('    ' + s)

DESC = "'El visitante no trajo su DNI físico.'"

def escritura():
    L.append('    -- ===================================================== A. INGRESO: validaciones')
    raw(ING('v_p1', IT('v_p1'), user='v_u_nada')); code('Ingreso: sin permiso en la sede', 101)
    raw(ING('v_p1', IT('v_p1'), user='v_u_coo')); code('Ingreso: el Coordinador solo consulta, no registra', 101)
    raw(ING('v_p1', IT('v_p1'), user='v_u_sol')); code('Ingreso: el solicitante no registra', 101)
    raw(ING('999999', "'1:Y'")); code('Ingreso: persona inexistente', 404)
    raw(ING('v_p9', IT('v_p9'))); code('Ingreso: persona con aprobación pendiente', 409)
    raw('v_hecho := CAST(CAST(v_pas AS DATE) AS TIMESTAMP) + INTERVAL \'10 hours\';')
    raw(ING('v_p10', IT('v_p10'), hecho='v_hecho', obs="'Tardío'")); code('Ingreso: solicitud cancelada', 409)
    raw(ING('v_p1', 'NULL')); code('Ingreso: sin ítems', 400)
    raw(ING('v_p1', "'1:Y,2:Y'")); code('Ingreso: faltan ítems', 400)
    raw(ING('v_p1', IT('v_p1') + " || ',999:Y'")); code('Ingreso: ítem que no corresponde', 400)
    raw(ING('v_p1', IT('v_p1') + " || ',1:Y'")); code('Ingreso: ítem repetido', 400)
    raw(ING('v_p1', "REPLACE(" + IT('v_p1') + ", ':Y', ':X')")); code('Ingreso: valor distinto de Y o N', 400)
    raw(ING('v_p1', IT('v_p1'), eq='Z')); code('Ingreso: equipos con valor inválido', 400)
    raw(ING('v_p1', IT('v_p1'), obs="REPEAT('x', 1001)")); code('Ingreso: observación demasiado larga', 400)
    raw(ING('v_p1', IT('v_p1'), desc=DESC)); code('Ingreso: todo cumple pero envían desviación', 400)
    raw(ING('v_p1', IT('v_p1'), trat='v_t_lib')); code('Ingreso: todo cumple pero envían tratamiento', 400)
    raw(ING('v_p1', IT('v_p1', fallan='ING_PERTENENCIAS'))); code('Ingreso: ítem no cumple y no hay desviación', 400)
    raw(ING('v_p1', IT('v_p1', fallan='ING_PERTENENCIAS'), desc=DESC, trat='v_t_lib', coord='NULL')); code('Ingreso: desviación sin Coordinador', 400)
    raw(ING('v_p1', IT('v_p1', fallan='ING_PERTENENCIAS'), desc=DESC, trat='v_t_lib', coord='v_u_vig')); code('Ingreso: el consultado no es Coordinador', 101)
    raw(ING('v_p1', IT('v_p1', fallan='ING_PERTENENCIAS'), desc=DESC, trat='v_t_ret', coord='v_u_coo')); code('Ingreso: tratamiento que solo aplica a la salida', 101)
    raw(ING('v_p1', IT('v_p1', fallan='ING_PERTENENCIAS'), desc=DESC, trat='v_t_otro', coord='v_u_coo')); code('Ingreso: «Otro» sin detalle', 400)
    raw(ING('v_p1', IT('v_p1', fallan='ING_PERTENENCIAS'), desc=DESC, trat='v_t_otro', coord='v_u_coo', det="'Se acepta con autorización verbal.'")); code('Ingreso: «Otro» sin efecto elegido', 400)
    raw(ING('v_p1', IT('v_p1', fallan='ING_PERTENENCIAS'), desc=DESC, trat='v_t_otro', coord='v_u_coo', det="'x'", res="'SALE'")); code('Ingreso: «Otro» con efecto de otra etapa', 400)
    raw(ING('v_p1', IT('v_p1', fallan='ING_PERTENENCIAS'), desc=DESC, trat='v_t_lib', coord='v_u_coo', res="'NO_INGRESA'")); code('Ingreso: efecto elegido distinto del que fija el tratamiento', 400)
    raw(ING('v_p1', IT('v_p1', fallan='ING_PERTENENCIAS'), desc="REPEAT('x', 2001)", trat='v_t_lib', coord='v_u_coo')); code('Ingreso: descripción demasiado larga', 400)
    raw(ING('v_p1', IT('v_p1', fallan='ING_PERTENENCIAS'), desc=DESC, trat='v_t_lib', coord='v_u_coo', user='v_u_min')); code('Ingreso: sin permiso para registrar desviaciones', 101)
    raw(ING('v_p1', IT('v_p1', fallan='ING_IDENTIDAD'), desc=DESC, trat='v_t_lib', coord='v_u_coo')); code('Ingreso: ítem crítico no cumple y lo quieren liberar', 101)
    chk('Ingreso: nada de lo anterior dejó registros', "'0'", q('SELECT COUNT(*) FROM "CAF_Registro_Acceso"'))
    chk('Ingreso: ni desviaciones', "'0'", q('SELECT COUNT(*) FROM "CAF_Desviacion"'))
    chk('Ingreso: ni cambios de estado', "'ESPERADA'", q("SELECT \"Estado\" FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p1 || '"))

    L.append('    -- ===================================================== B. INGRESO: caminos felices')
    raw(ING('v_p1', IT('v_p1'), obs="'Llegó puntual'"))
    code('Ingreso: todo cumple, entra', 100)
    chk('Ingreso: resultado INGRESA', "'INGRESA'", "v_res")
    chk('Ingreso: sin desviación', "'0'", "v_des::TEXT")
    chk('Ingreso: la persona queda DENTRO con su hora', "'DENTRO|Y'", q("SELECT \"Estado\" || '|' || CASE WHEN \"Fecha_Hora_Ingreso\" IS NOT NULL THEN 'Y' ELSE 'N' END FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p1 || '"))
    chk('Ingreso: el registro guarda al vigilante, la observación y no es tardío', "'INGRESO|N|Llegó puntual'", q("SELECT \"Tipo_Movimiento\" || '|' || \"Es_Registro_Tardio\" || '|' || \"Observacion\" FROM \"CAF_Registro_Acceso\" WHERE \"ID_Registro_Acceso\" = ' || v_reg || '"))
    chk('Ingreso: guarda cada ítem del checklist (todos cumplen)', "'si'", q("SELECT CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_ITEMS_APLICABLES\"(' || v_p1 || ', 'INGRESO', 'N', 'N')) AND MIN(\"Cumple\") = 'Y' THEN 'si' ELSE 'no' END FROM \"CAF_Registro_Checklist\" WHERE \"ID_Registro_Acceso\" = ' || v_reg || '"))
    chk('Ingreso: deja el evento INGRESO en la bitácora', "'1'", "pg_temp.ev('REGISTRO_ACCESO', v_reg, 'INGRESO')")
    raw('v_reg2 := v_reg;')
    raw(ING('v_p1', IT('v_p1'))); code('Ingreso: repetirlo es conflicto (ya ingresó)', 409)

    # B: no crítico N con desviación (liberación)
    raw(ING('v_p2', IT('v_p2', fallan='ING_PERTENENCIAS'), desc=DESC, trat='v_t_lib', coord='v_u_coo'))
    code('Ingreso con desviación: se libera por Coordinador', 100)
    chk('Ingreso con desviación: resultado INGRESA', "'INGRESA'", "v_res")
    chk('Ingreso con desviación: crea la desviación', "'DES-' || LPAD(v_des::TEXT, 5, '0')", q("SELECT \"Codigo\" FROM \"CAF_Desviacion\" WHERE \"ID_Desviacion\" = ' || v_des || '"))
    chk('Ingreso con desviación: queda por revisar y ligada al registro', "'POR_REVISAR|Y'", q("SELECT \"Estado\" || '|' || CASE WHEN \"ID_Registro_Acceso\" = ' || v_reg || ' THEN 'Y' ELSE 'N' END FROM \"CAF_Desviacion\" WHERE \"ID_Desviacion\" = ' || v_des || '"))
    chk('Ingreso con desviación: el ítem fallado queda en N', "'1'", q("SELECT COUNT(*) FROM \"CAF_Registro_Checklist\" C JOIN \"Catalogo_Item_Checklist\" I USING (\"ID_Catalogo_Item_Checklist\") WHERE C.\"ID_Registro_Acceso\" = ' || v_reg || ' AND C.\"Cumple\" = 'N' AND I.\"Codigo\" = 'ING_PERTENENCIAS'"))
    chk('Ingreso con desviación: eventos de registro y de desviación', "'1/1'", "pg_temp.ev('REGISTRO_ACCESO', v_reg, 'INGRESO') || '/' || pg_temp.ev('DESVIACION', v_des, 'REGISTRAR')")
    raw('v_des2 := v_des;')

    # C: restringido
    raw(ING('v_p3', IT('v_p3', fallan='ING_SCTR,ING_EPP'), desc=DESC, trat='v_t_rest', coord='v_u_coo'))
    code('Ingreso restringido: se permite solo zona administrativa', 100)
    chk('Ingreso restringido: resultado', "'INGRESA_RESTRINGIDO'", "v_res")
    chk('Ingreso restringido: la persona queda DENTRO con acceso restringido', "'DENTRO|Y'", q("SELECT \"Estado\" || '|' || \"Acceso_Restringido\" FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p3 || '"))

    # D: denegado
    raw(ING('v_p4', IT('v_p4', fallan='ING_IDENTIDAD'), desc=DESC, trat='v_t_den', coord='v_u_coo'))
    code('Ingreso denegado: ítem crítico no cumple y se deniega', 100)
    chk('Ingreso denegado: resultado NO_INGRESA', "'NO_INGRESA'", "v_res")
    chk('Ingreso denegado: la persona queda DENEGADA, sin hora de ingreso', "'DENEGADA|N'", q("SELECT \"Estado\" || '|' || CASE WHEN \"Fecha_Hora_Ingreso\" IS NOT NULL THEN 'Y' ELSE 'N' END FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p4 || '"))
    chk('Ingreso denegado: evento DENEGAR en la bitácora', "'1/0'", "pg_temp.ev('REGISTRO_ACCESO', v_reg, 'DENEGAR') || '/' || pg_temp.ev('REGISTRO_ACCESO', v_reg, 'INGRESO')")
    raw(ING('v_p4', IT('v_p4'))); code('Ingreso: tras una denegación no se reintenta', 409)
    raw(SAL('v_p4', "'1:Y'")); code('Salida: a quien se le denegó el ingreso', 409)

    # tratamiento «Otro» con efecto elegido
    raw(ING('v_p12', IT('v_p12', fallan='ING_ARCO'), desc=DESC, trat='v_t_otro', coord='v_u_coo', det="'Firma la autorización en portería.'", res="'INGRESA'"))
    code('Ingreso con «Otro»: detalle y efecto elegido', 100)
    chk('Ingreso con «Otro»: queda el detalle', "'Firma la autorización en portería.'", q("SELECT \"Tratamiento_Detalle\" FROM \"CAF_Desviacion\" WHERE \"ID_Desviacion\" = ' || v_des || '"))

    L.append('    -- ===================================================== C. RESPALDO Y EQUIPOS')
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'EQUIPOS\', \'G_FSCA_009\', NULL, v_p5::TEXT, NULL, v_u_nada, v_resp, v_cod, v_msg);'); code('Respaldo: sin permiso', 101)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'OTRA\', \'G_FSCA_009\', NULL, v_p5::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: categoría inválida', 400)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'EQUIPOS\', \'GUIA_REMISION\', \'T001-1\', v_p5::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: tipo que no corresponde a la categoría', 400)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'HERRAMIENTAS_MATERIALES\', \'GUIA_REMISION\', NULL, v_p5::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: la guía de remisión exige número', 400)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'EQUIPOS\', \'G_FSCA_009\', \'T001-1\', v_p5::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: el G-FSCA-009 no lleva número', 400)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'EQUIPOS\', \'G_FSCA_009\', NULL, \'abc\', NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: lista de personas mal escrita', 400)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'EQUIPOS\', \'G_FSCA_009\', NULL, NULL, NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: sin personas', 400)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'EQUIPOS\', \'G_FSCA_009\', NULL, \'999999\', NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: persona inexistente', 404)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'EQUIPOS\', \'G_FSCA_009\', NULL, v_p9::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: persona sin aprobar', 409)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'EQUIPOS\', \'G_FSCA_009\', NULL, v_p4::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: persona denegada', 409)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'EQUIPOS\', \'G_FSCA_009\', NULL, v_p5 || \',\' || v_p5, NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: la misma persona dos veces en el mismo respaldo', 400)
    chk('Respaldo: lo rechazado no dejó nada', "'0'", q('SELECT COUNT(*) FROM "CAF_Respaldo"'))
    # sin respaldo no entra con equipos
    raw(ING('v_p5', IT('v_p5', eq='Y'), eq='Y')); code('Ingreso con equipos: sin respaldo no entra', 101)
    raw(ING('v_p5', IT('v_p5', he='Y'), he='Y')); code('Ingreso con herramientas: sin respaldo no entra', 101)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'EQUIPOS\', \'G_FSCA_009\', NULL, v_p5 || \',\' || v_p6, \'Laptop y proyector\', v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: G-FSCA-009 para dos personas', 100)
    chk('Respaldo: cubre a las dos personas', "'2'", q('SELECT COUNT(*) FROM "CAF_Respaldo_Persona" WHERE "ID_Respaldo" = ' + "' || v_resp || '"))
    raw(ING('v_p5', IT('v_p5', eq='Y'), eq='Y')); code('Ingreso con equipos: con su respaldo entra', 100)
    chk('Ingreso con equipos: se guarda lo que trae', "'Y|N'", q("SELECT \"Trae_Equipos\" || '|' || \"Trae_Herramientas\" FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p5 || '"))
    chk('Ingreso con equipos: el checklist incluye los ítems de equipos (más ítems que sin equipos)', "'si'", q("SELECT CASE WHEN (SELECT COUNT(*) FROM \"CAF_Registro_Checklist\" WHERE \"ID_Registro_Acceso\" = ' || v_reg || ') >= (SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_ITEMS_APLICABLES\"(' || v_p6 || ', 'INGRESO', 'N', 'N')) THEN 'si' ELSE 'no' END"))
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'HERRAMIENTAS_MATERIALES\', \'GUIA_REMISION\', \'T001-00045\', v_p6::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: guía de remisión con número', 100)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'HERRAMIENTAS_MATERIALES\', \'GUIA_MANUAL_G_FSCA_010\', NULL, v_p6::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);'); code('Respaldo: guía manual G-FSCA-010', 100)
    raw(ING('v_p6', IT('v_p6', eq='Y', he='Y'), eq='Y', he='Y')); code('Ingreso con equipos y herramientas: con ambos respaldos', 100)

    L.append('    -- ===================================================== D. INGRESO TARDÍO')
    raw(ING('v_p7', IT('v_p7'))); code('Ingreso: visita de fecha pasada sin marcar tardío', 409)
    raw('v_hecho := CAST(CAST(v_pas AS DATE) AS TIMESTAMP) + INTERVAL \'10 hours\';')
    raw(ING('v_p7', IT('v_p7'), hecho='v_hecho')); code('Ingreso tardío: exige observación', 400)
    raw(ING('v_p7', IT('v_p7'), hecho='LOCALTIMESTAMP + INTERVAL \'1 hour\'', obs="'Se olvidó registrar'")); code('Ingreso tardío: hora futura', 400)
    raw(ING('v_p7', IT('v_p7'), hecho='v_hecho + INTERVAL \'1 day\'', obs="'Se olvidó registrar'")); code('Ingreso tardío: fecha distinta a la de la visita', 400)
    raw(ING('v_p9', IT('v_p9'), hecho='v_hecho', obs="'x'")); code('Ingreso tardío: persona sin aprobar', 409)
    raw(ING('v_p7', IT('v_p7'), hecho='v_hecho', obs="'Se olvidó registrar'")); code('Ingreso tardío: se registra con la hora del hecho', 100)
    chk('Ingreso tardío: queda marcado y con la hora indicada', "'Y|Y'", q("SELECT \"Es_Registro_Tardio\" || '|' || CASE WHEN \"Fecha_Hora\" = ' || QUOTE_LITERAL(v_hecho) || '::timestamp AND \"Fecha_Hora_Sistema\" > \"Fecha_Hora\" THEN 'Y' ELSE 'N' END FROM \"CAF_Registro_Acceso\" WHERE \"ID_Registro_Acceso\" = ' || v_reg || '"))
    chk('Ingreso tardío: la persona figura con la hora del hecho', "'Y'", q("SELECT CASE WHEN \"Fecha_Hora_Ingreso\" = ' || QUOTE_LITERAL(v_hecho) || '::timestamp THEN 'Y' ELSE 'N' END FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p7 || '"))
    chk('Ingreso tardío: el evento lo dice', "'registro tardío'", q("SELECT CASE WHEN \"Detalle\" LIKE '%registro tardío%' THEN 'registro tardío' ELSE \"Detalle\" END FROM \"CAF_Evento\" WHERE \"Entidad\" = 'REGISTRO_ACCESO' AND \"ID_Entidad\" = ' || v_reg || '"))
    raw('v_reg2 := v_reg;')

    L.append('    -- ===================================================== E. SALIDA')
    raw(SAL('v_p8', IT('v_p8', 'SALIDA'))); code('Salida: la persona aún no ingresó', 409)
    raw(SAL('v_p1', IT('v_p1', 'SALIDA'), user='v_u_nada')); code('Salida: sin permiso', 101)
    raw(SAL('v_p1', "'1:Y'")); code('Salida: ítems incompletos', 400)
    raw(SAL('v_p1', IT('v_p1', 'SALIDA', fallan='SAL_FICHA_DEVUELTA'))); code('Salida: ítem no cumple y no hay desviación', 400)
    raw(SAL('v_p1', IT('v_p1', 'SALIDA', fallan='SAL_FICHA_DEVUELTA'), desc="'No devolvió la ficha.'", trat='v_t_den', coord='v_u_coo')); code('Salida: tratamiento que solo aplica al ingreso', 101)
    raw(SAL('v_p1', IT('v_p1', 'SALIDA'), desc="'x'", trat='v_t_lib')); code('Salida: todo cumple pero envían desviación', 400)
    raw(SAL('v_p1', IT('v_p1', 'SALIDA'), hecho='LOCALTIMESTAMP + INTERVAL \'1 hour\'', obs="'x'")); code('Salida tardía: hora futura', 400)
    raw(SAL('v_p1', IT('v_p1', 'SALIDA'), hecho='LOCALTIMESTAMP - INTERVAL \'1 day\'', obs="'x'")); code('Salida tardía: anterior al ingreso', 400)
    raw(SAL('v_p1', IT('v_p1', 'SALIDA'), obs="'Salió conforme'"))
    code('Salida: todo cumple', 100)
    chk('Salida: resultado SALE', "'SALE'", "v_res")
    chk('Salida: la persona queda SALIO con su hora', "'SALIO|Y'", q("SELECT \"Estado\" || '|' || CASE WHEN \"Fecha_Hora_Salida\" IS NOT NULL THEN 'Y' ELSE 'N' END FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p1 || '"))
    chk('Salida: evento SALIDA', "'1'", "pg_temp.ev('REGISTRO_ACCESO', v_reg, 'SALIDA')")
    chk('Salida: la persona tiene dos movimientos (ingreso y salida)', "'2'", q("SELECT COUNT(*) FROM \"CAF_Registro_Acceso\" WHERE \"ID_Solicitud_Persona\" = ' || v_p1 || '"))
    raw(SAL('v_p1', IT('v_p1', 'SALIDA'))); code('Salida: repetirla es conflicto', 409)
    raw(ING('v_p1', IT('v_p1'))); code('Ingreso: quien ya salió no vuelve a ingresar', 409)

    raw(SAL('v_p2', IT('v_p2', 'SALIDA', fallan='SAL_SIN_ELEMENTOS'), desc="'Lleva un equipo de la planta.'", trat='v_t_ret', coord='v_u_coo'))
    code('Salida con retención: se retiene el elemento', 100)
    chk('Salida con retención: resultado', "'SALE_RETIENE_ELEMENTO'", "v_res")
    chk('Salida con retención: la persona igual sale', "'SALIO'", q("SELECT \"Estado\" FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p2 || '"))
    chk('Salida con retención: crea otra desviación (una por movimiento)', "'2'", q("SELECT COUNT(*) FROM \"CAF_Desviacion\" D JOIN \"CAF_Registro_Acceso\" A USING (\"ID_Registro_Acceso\") WHERE A.\"ID_Solicitud_Persona\" = ' || v_p2 || '"))
    raw(SAL('v_p3', IT('v_p3', 'SALIDA', fallan='SAL_FICHA_DEVUELTA'), desc="'Perdió la ficha.'", trat='v_t_lib', coord='v_u_coo'))
    code('Salida con liberación', 100)
    chk('Salida con liberación: resultado SALE', "'SALE'", "v_res")
    chk('Salida: los ítems de equipos aparecen solo si la persona los trajo', "'si'", q("SELECT CASE WHEN (SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_ITEMS_APLICABLES\"(' || v_p5 || ', 'SALIDA', 'Y', 'N')) = (SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_ITEMS_APLICABLES\"(' || v_p5 || ', 'SALIDA', 'N', 'N')) + 1 THEN 'si' ELSE 'no' END"))
    raw(SAL('v_p5', IT('v_p5', 'SALIDA', eq='N'))); code('Salida: si falta el ítem de equipos que corresponde, se rechaza', 400)
    raw(SAL('v_p5', IT('v_p5', 'SALIDA', eq='Y'))); code('Salida: con equipos y todo cumple', 100)

    L.append('    -- ===================================================== F. SALIDA TARDÍA')
    raw('v_hecho := CAST(CAST(v_pas AS DATE) AS TIMESTAMP) + INTERVAL \'9 hours\';')
    raw(SAL('v_p7', IT('v_p7', 'SALIDA'), hecho='v_hecho', obs="'Tardía'")); code('Salida tardía: anterior al ingreso tardío', 400)
    raw('v_hecho := CAST(CAST(v_pas AS DATE) AS TIMESTAMP) + INTERVAL \'11 hours\';')
    raw(SAL('v_p7', IT('v_p7', 'SALIDA'), hecho='v_hecho')); code('Salida tardía: exige observación', 400)
    raw(SAL('v_p7', IT('v_p7', 'SALIDA'), hecho='v_hecho', obs="'Tardía'")); code('Salida tardía: se registra', 100)
    chk('Salida tardía: marcada como tardía', "'Y'", q("SELECT \"Es_Registro_Tardio\" FROM \"CAF_Registro_Acceso\" WHERE \"ID_Registro_Acceso\" = ' || v_reg || '"))

    L.append('    -- ===================================================== G. CONFORMIDAD DE DESVIACIONES')
    raw('CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des2, \'Conforme\', v_u_vig, v_cod, v_msg);'); code('Conformidad: Vigilancia no la da', 101)
    raw('CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(999999, \'x\', v_u_coo, v_cod, v_msg);'); code('Conformidad: desviación inexistente', 404)
    raw('CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des2, \'Conforme, se regularizó la documentación\', v_u_coo, v_cod, v_msg);'); code('Conformidad: el Coordinador la da', 100)
    chk('Conformidad: queda REVISADA con quien y cuándo', "'REVISADA|Y|Y'", q("SELECT \"Estado\" || '|' || CASE WHEN \"ID_Usuario_Conformidad\" = ' || v_u_coo || ' THEN 'Y' ELSE 'N' END || '|' || CASE WHEN \"Fecha_Conformidad\" IS NOT NULL THEN 'Y' ELSE 'N' END FROM \"CAF_Desviacion\" WHERE \"ID_Desviacion\" = ' || v_des2 || '"))
    chk('Conformidad: evento en la bitácora', "'1'", "pg_temp.ev('DESVIACION', v_des2, 'CONFORMIDAD')")
    raw('CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des2, \'otra vez\', v_u_coo, v_cod, v_msg);'); code('Conformidad: no se da dos veces', 409)

    L.append('    -- ===================================================== H. «NO SE PRESENTÓ»')
    raw('CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(NULL, v_u_vig, v_cant, v_cod, v_msg);'); code('No se presentó: solo el proceso automático (usuario 0)', 101)
    raw('CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(CURRENT_DATE + 1, 0, v_cant, v_cod, v_msg);'); code('No se presentó: fecha de corte futura', 400)
    # p8 de S5 (pasada, aprobada, nunca ingresó) -> se marca; p9 (pendiente) no; p10 (cancelada) no; las de hoy no
    raw('CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(NULL, 0, v_cant, v_cod, v_msg);'); code('No se presentó: cierre del día', 100)
    chk('No se presentó: marca solo a la persona aprobada que no vino', "'1'", "v_cant::TEXT")
    chk('No se presentó: la persona 8 queda NO_SE_PRESENTO', "'NO_SE_PRESENTO'", q("SELECT \"Estado\" FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p8 || '"))
    chk('No se presentó: la pendiente de aprobación no se toca', "'ESPERADA'", q("SELECT \"Estado\" FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p9 || '"))
    chk('No se presentó: la de solicitud cancelada no se toca', "'ESPERADA'", q("SELECT \"Estado\" FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p10 || '"))
    chk('No se presentó: las visitas de hoy no se tocan', "'ESPERADA'", q("SELECT \"Estado\" FROM \"CAF_Solicitud_Persona\" WHERE \"ID_Solicitud_Persona\" = ' || v_p11 || '"))
    chk('No se presentó: deja su evento', "'1'", "pg_temp.ev('SOLICITUD_PERSONA', v_p8, 'NO_SE_PRESENTO')")
    raw('CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(NULL, 0, v_cant, v_cod, v_msg);'); chk('No se presentó: repetirlo no hace nada', "'0/100'", "v_cant || '/' || v_cod")
    raw(ING('v_p8', IT('v_p8'), hecho='v_hecho', obs="'x'")); code('Ingreso: quien figura como «no se presentó» no ingresa sin corrección', 409)
    raw(SAL('v_p8', IT('v_p8', 'SALIDA'))); code('Salida: quien no se presentó', 409)
    # cierre con fecha de corte: hoy no se marca aunque pidan hoy
    raw('CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(CURRENT_DATE, 0, v_cant, v_cod, v_msg);'); chk('No se presentó: con corte de hoy, la visita de hoy sigue vigente', "'0'", "v_cant::TEXT")

    L.append('    -- ===================================================== I. LA ESCRITURA NO TOCÓ OTRAS COSAS')
    chk('Cada movimiento tiene su checklist completo', "'0'", q('SELECT COUNT(*) FROM "CAF_Registro_Acceso" A WHERE NOT EXISTS (SELECT 1 FROM "CAF_Registro_Checklist" C WHERE C."ID_Registro_Acceso" = A."ID_Registro_Acceso")'))
    chk('Ninguna desviación huérfana', "'0'", q('SELECT COUNT(*) FROM "CAF_Desviacion" D WHERE NOT EXISTS (SELECT 1 FROM "CAF_Registro_Acceso" A WHERE A."ID_Registro_Acceso" = D."ID_Registro_Acceso")'))
    chk('Códigos de desviación únicos y con formato', "'0'", q("SELECT COUNT(*) FROM \"CAF_Desviacion\" WHERE \"Codigo\" !~ '^DES-[0-9]{5}$'"))


def lectura():
    L.append('    -- ===================================================== MOVIMIENTOS PREVIOS (con los procedimientos de escritura)')
    raw(ING('v_p1', IT('v_p1'), obs="'Llegó puntual'"))
    code('Preparación: ingreso de la persona 1', 100)
    raw(ING('v_p2', IT('v_p2', fallan='ING_PERTENENCIAS'), desc=DESC, trat='v_t_lib', coord='v_u_coo'))
    code('Preparación: ingreso de la persona 2 con desviación', 100)
    raw('v_des2 := v_des;')
    raw(ING('v_p4', IT('v_p4', fallan='ING_IDENTIDAD'), desc="'Documento no coincide.'", trat='v_t_den', coord='v_u_coo'))
    code('Preparación: ingreso denegado de la persona 4', 100)
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'EQUIPOS\', \'G_FSCA_009\', NULL, v_p5::TEXT, \'Laptop\', v_u_vig, v_resp, v_cod, v_msg);')
    raw('CALL "ERP_CAF_RESPALDO_REGISTRAR"(\'HERRAMIENTAS_MATERIALES\', \'GUIA_REMISION\', \'T001-00045\', v_p5::TEXT, NULL, v_u_vig, v_resp, v_cod, v_msg);')
    raw(ING('v_p5', IT('v_p5', eq='Y', he='Y'), eq='Y', he='Y'))
    code('Preparación: ingreso de la persona 5 con equipos y herramientas', 100)
    raw(SAL('v_p1', IT('v_p1', 'SALIDA')))
    code('Preparación: salida de la persona 1', 100)
    raw('v_reg2 := v_reg;')
    raw(ING('v_p3', IT('v_p3', fallan='ING_SCTR,ING_EPP'), desc=DESC, trat='v_t_rest', coord='v_u_coo'))
    raw(SAL('v_p3', IT('v_p3', 'SALIDA', fallan='SAL_SIN_ELEMENTOS'), desc="'Lleva un equipo.'", trat='v_t_ret', coord='v_u_coo'))
    code('Preparación: salida de la persona 3 con retención', 100)
    raw('CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des2, \'Conforme\', v_u_coo, v_cod, v_msg);')
    code('Preparación: se da conformidad a una desviación', 100)

    L.append('    -- ===================================================== A. CHECKLIST_OBTENER')
    ci = lambda u, p, e, eq='N', he='N': 'SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_CHECKLIST_OBTENER"(%s, %s, \'%s\', \'%s\', \'%s\')' % (u, p, e, eq, he)
    chk('Checklist: ingreso, mismos ítems que usa el SP', "(SELECT COUNT(*)::TEXT FROM \"ERP_CAF_PORTERIA_ITEMS_APLICABLES\"(v_p12, 'INGRESO', 'N', 'N'))", "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_CHECKLIST_OBTENER\"(' || v_u_vig || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'')')")
    chk('Checklist: ingreso tiene al menos 5 ítems', "'si'", "CASE WHEN pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_CHECKLIST_OBTENER\"(' || v_u_vig || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'')')::INT >= 5 THEN 'si' ELSE 'no' END")
    chk('Checklist: el único crítico es la identidad', "'ING_IDENTIDAD'", "pg_temp.q('SELECT STRING_AGG(\"Codigo\", '','') FROM \"ERP_CAF_PORTERIA_CHECKLIST_OBTENER\"(' || v_u_vig || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'') WHERE \"Es_Critico\" = ''Y''')")
    chk('Checklist: ingreso con equipos agrega ítems', "'si'", "CASE WHEN pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_CHECKLIST_OBTENER\"(' || v_u_vig || ', ' || v_p12 || ', ''INGRESO'', ''Y'', ''Y'')')::INT >= pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_CHECKLIST_OBTENER\"(' || v_u_vig || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'')')::INT THEN 'si' ELSE 'no' END")
    chk('Checklist: salida usa lo que la persona trajo (con equipos y herramientas, más ítems)', "'2'",
        "(pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_CHECKLIST_OBTENER\"(' || v_u_vig || ', ' || v_p5 || ', ''SALIDA'', ''N'', ''N'')')::INT - pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_CHECKLIST_OBTENER\"(' || v_u_vig || ', ' || v_p2 || ', ''SALIDA'', ''N'', ''N'')')::INT)::TEXT")
    chk('Checklist: sin permiso, cero filas', "'0'", "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_CHECKLIST_OBTENER\"(' || v_u_nada || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'')')")
    chk('Checklist: el Coordinador (solo consulta) no lo obtiene', "'0'", "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_CHECKLIST_OBTENER\"(' || v_u_coo || ', ' || v_p12 || ', ''INGRESO'', ''N'', ''N'')')")
    chk('Checklist: persona inexistente', "'0'", "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_CHECKLIST_OBTENER\"(' || v_u_vig || ', 999999, ''INGRESO'', ''N'', ''N'')')")
    chk('Checklist: etapa inválida', "'0'", "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_CHECKLIST_OBTENER\"(' || v_u_vig || ', ' || v_p12 || ', ''OTRA'', ''N'', ''N'')')")

    L.append('    -- ===================================================== B. FICHA y botones (coinciden con los SP de escritura)')
    f = lambda u, p, col: "pg_temp.q('SELECT \"%s\" FROM \"ERP_CAF_PORTERIA_FICHA\"(' || %s || ', ' || %s || ')')" % (col, u, p)
    chk('Ficha: persona esperada puede ingresar', "'Y'", f('v_u_vig', 'v_p12', 'Puede_Registrar_Ingreso'))
    chk('Ficha: persona esperada no puede salir (con motivo)', "'N|La persona aún no ingresó.'", f('v_u_vig', 'v_p12', 'Puede_Registrar_Salida') + " || '|' || " + f('v_u_vig', 'v_p12', 'Motivo_No_Salida'))
    chk('Ficha: trae el nombre completo', "'Apellido12 Materno12, Nombre12'", f('v_u_vig', 'v_p12', 'Persona_Nombre'))
    chk('Ficha: persona dentro no puede ingresar (con motivo)', "'N|La persona ya ingresó.'", f('v_u_vig', 'v_p2', 'Puede_Registrar_Ingreso') + " || '|' || " + f('v_u_vig', 'v_p2', 'Motivo_No_Ingreso'))
    chk('Ficha: persona dentro puede salir', "'Y'", f('v_u_vig', 'v_p2', 'Puede_Registrar_Salida'))
    chk('Ficha: persona que ya salió', "'N|N'", f('v_u_vig', 'v_p1', 'Puede_Registrar_Ingreso') + " || '|' || " + f('v_u_vig', 'v_p1', 'Puede_Registrar_Salida'))
    chk('Ficha: persona denegada', "'DENEGADA|N|N'", f('v_u_vig', 'v_p4', 'Estado') + " || '|' || " + f('v_u_vig', 'v_p4', 'Puede_Registrar_Ingreso') + " || '|' || " + f('v_u_vig', 'v_p4', 'Puede_Registrar_Salida'))
    chk('Ficha: persona sin aprobar no puede ingresar', "'N|La persona no está autorizada para ingresar.'", f('v_u_vig', 'v_p9', 'Puede_Registrar_Ingreso') + " || '|' || " + f('v_u_vig', 'v_p9', 'Motivo_No_Ingreso'))
    chk('Ficha: visita pasada no ingresa normal pero sí tardío', "'N|Y'", f('v_u_vig', 'v_p7', 'Puede_Registrar_Ingreso') + " || '|' || " + f('v_u_vig', 'v_p7', 'Puede_Registrar_Ingreso_Tardio'))
    chk('Ficha: visita de hoy no necesita tardío', "'N'", f('v_u_vig', 'v_p12', 'Puede_Registrar_Ingreso_Tardio'))
    chk('Ficha: solicitud cancelada', "'N|La solicitud está cancelada.'", f('v_u_vig', 'v_p10', 'Puede_Registrar_Ingreso') + " || '|' || " + f('v_u_vig', 'v_p10', 'Motivo_No_Ingreso'))
    chk('Ficha: el Coordinador la ve pero sin botones', "'N|N|Solo tiene permiso de consulta.'", f('v_u_coo', 'v_p12', 'Puede_Registrar_Ingreso') + " || '|' || " + f('v_u_coo', 'v_p12', 'Puede_Registrar_Salida') + " || '|' || " + f('v_u_coo', 'v_p12', 'Motivo_No_Ingreso'))
    chk('Ficha: sin permiso, cero filas', "'(nulo)'", f('v_u_nada', 'v_p12', 'Estado'))
    chk('Ficha: el solicitante no la ve', "'(nulo)'", f('v_u_sol', 'v_p12', 'Estado'))
    chk('Ficha: inexistente', "'(nulo)'", f('v_u_vig', '999999', 'Estado'))
    chk('Ficha: respaldos de la persona 5', "'Y|Y'", f('v_u_vig', 'v_p5', 'Tiene_Respaldo_Equipos') + " || '|' || " + f('v_u_vig', 'v_p5', 'Tiene_Respaldo_Herramientas'))
    chk('Ficha: sin respaldos', "'N|N'", f('v_u_vig', 'v_p12', 'Tiene_Respaldo_Equipos') + " || '|' || " + f('v_u_vig', 'v_p12', 'Tiene_Respaldo_Herramientas'))
    # coincidencia botón <-> SP
    raw(ING('v_p2', IT('v_p2')))
    chk('Coincide: botón de ingreso apagado = el SP rechaza (409)', "'N|409'", f('v_u_vig', 'v_p2', 'Puede_Registrar_Ingreso') + " || '|' || v_cod")
    raw(SAL('v_p12', IT('v_p12', 'SALIDA')))
    chk('Coincide: botón de salida apagado = el SP rechaza (409)', "'N|409'", f('v_u_vig', 'v_p12', 'Puede_Registrar_Salida') + " || '|' || v_cod")
    raw(ING('v_p12', IT('v_p12')))
    chk('Coincide: botón de ingreso encendido = el SP acepta (100)', "'Y|100'", "'Y|' || v_cod")
    chk('Coincide: y ahora el botón se apaga', "'N|Y'", f('v_u_vig', 'v_p12', 'Puede_Registrar_Ingreso') + " || '|' || " + f('v_u_vig', 'v_p12', 'Puede_Registrar_Salida'))

    L.append('    -- ===================================================== C. MOVIMIENTOS_LISTAR (bitácora)')
    m = lambda u, extra='': "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR\"(' || %s || ', ' || v_ves || '%s)')" % (u, extra)
    chk('Movimientos de hoy', "'8'", m('v_u_vig'), "'6 ingresos (uno denegado) y 2 salidas'")
    chk('Movimientos: solo ingresos', "'6'", m('v_u_vig', ", NULL, NULL, ''INGRESO''"))
    chk('Movimientos: solo salidas', "'2'", m('v_u_vig', ", NULL, NULL, ''SALIDA''"))
    chk('Movimientos: búsqueda sin tildes por nombre', "'1'", "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR\"(' || v_u_vig || ', ' || v_ves || ', NULL, NULL, ''INGRESO'', ''nombre4'')')")
    chk('Movimientos: búsqueda por empresa (sin tildes ni mayúsculas)', "'7'", "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR\"(' || v_u_vig || ', ' || v_ves || ', NULL, NULL, NULL, ''Energia verde'')')")
    chk('Movimientos: otra fecha no tiene', "'0'", m('v_u_vig', ", CURRENT_DATE - 1, CURRENT_DATE - 1"))
    chk('Movimientos: rango invertido', "'0'", m('v_u_vig', ", CURRENT_DATE, CURRENT_DATE - 5"))
    chk('Movimientos: sin permiso', "'0'", m('v_u_nada'))
    chk('Movimientos: el solicitante no los ve', "'0'", m('v_u_sol'))
    chk('Movimientos: el Coordinador sí', "'8'", m('v_u_coo'))
    chk('Movimientos: sede nula', "'0'", "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR\"(' || v_u_vig || ', NULL)')")
    chk('Movimientos: orden, lo más reciente primero', "'si'", "CASE WHEN pg_temp.q('SELECT \"ID_Registro_Acceso\" FROM \"ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR\"(' || v_u_vig || ', ' || v_ves || ') LIMIT 1')::BIGINT = (SELECT MAX(\"ID_Registro_Acceso\") FROM \"CAF_Registro_Acceso\") THEN 'si' ELSE 'no' END")
    chk('Movimientos: indica la desviación', "'Y'", "pg_temp.q('SELECT \"Tiene_Desviacion\" FROM \"ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR\"(' || v_u_vig || ', ' || v_ves || ') WHERE \"ID_Solicitud_Persona\" = ' || v_p2 || ' AND \"Tipo_Movimiento\" = ''INGRESO''')")

    L.append('    -- ===================================================== D. DETALLE de movimiento y su checklist')
    raw('SELECT MIN("ID_Registro_Acceso") INTO v_reg FROM "CAF_Registro_Acceso" WHERE "ID_Solicitud_Persona" = v_p2 AND "Tipo_Movimiento" = \'INGRESO\';')
    d = lambda u, col: "pg_temp.q('SELECT \"%s\" FROM \"ERP_CAF_PORTERIA_REGISTRO_DETALLE\"(' || %s || ', ' || v_reg || ')')" % (col, u)
    chk('Detalle de registro: movimiento y resultado', "'INGRESO|INGRESA'", d('v_u_vig', 'Tipo_Movimiento') + " || '|' || " + d('v_u_vig', 'Resultado'))
    chk('Detalle de registro: nombre del vigilante', "'Vigilante Uno, María'", d('v_u_vig', 'Vigilante_Nombre'))
    chk('Detalle de registro: trae la desviación', "'Y'", "CASE WHEN " + d('v_u_vig', 'ID_Desviacion') + " <> '(nulo)' THEN 'Y' ELSE 'N' END")
    chk('Detalle de registro: sin permiso', "'(nulo)'", d('v_u_nada', 'Resultado'))
    chk('Detalle de registro: el solicitante no lo ve', "'(nulo)'", d('v_u_sol', 'Resultado'))
    chk('Detalle de registro: inexistente', "'(nulo)'", "pg_temp.q('SELECT \"Resultado\" FROM \"ERP_CAF_PORTERIA_REGISTRO_DETALLE\"(' || v_u_vig || ', 999999)')")
    cl = lambda u: "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR\"(' || %s || ', ' || v_reg || ')')" % u
    chk('Checklist del registro: trae todos los ítems', "(SELECT COUNT(*)::TEXT FROM \"CAF_Registro_Checklist\" WHERE \"ID_Registro_Acceso\" = v_reg)", cl('v_u_vig'))
    chk('Checklist del registro: un ítem no cumple', "'1'", "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR\"(' || v_u_vig || ', ' || v_reg || ') WHERE \"Cumple\" = ''N''')")
    chk('Checklist del registro: sin permiso', "'0'", cl('v_u_nada'))

    L.append('    -- ===================================================== E. RESPALDOS')
    rl = lambda u, p: "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_RESPALDO_LISTAR_POR_PERSONA\"(' || %s || ', ' || %s || ')')" % (u, p)
    chk('Respaldos de la persona 5', "'2'", rl('v_u_vig', 'v_p5'))
    chk('Respaldos: la guía de remisión muestra su número', "'T001-00045'", "pg_temp.q('SELECT \"Numero_Documento\" FROM \"ERP_CAF_RESPALDO_LISTAR_POR_PERSONA\"(' || v_u_vig || ', ' || v_p5 || ') WHERE \"Tipo_Respaldo\" = ''GUIA_REMISION''')")
    chk('Respaldos: persona sin respaldos', "'0'", rl('v_u_vig', 'v_p12'))
    chk('Respaldos: sin permiso', "'0'", rl('v_u_nada', 'v_p5'))
    chk('Respaldos: el Coordinador (consulta) los ve', "'2'", rl('v_u_coo', 'v_p5'))

    L.append('    -- ===================================================== F. DESVIACIONES')
    dl = lambda u, extra='': "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_DESVIACION_LISTAR\"(' || %s || ', ' || v_ves || '%s)')" % (u, extra)
    chk('Desviaciones: todas', "'4'", dl('v_u_coo'), "'ingreso p2 (revisada), ingreso p3, salida p3, ingreso p4 denegado'")
    chk('Desviaciones: por revisar', "'3'", dl('v_u_coo', ", ''POR_REVISAR''"))
    chk('Desviaciones: revisadas', "'1'", dl('v_u_coo', ", ''REVISADA''"))
    chk('Desviaciones: estado inválido', "'0'", dl('v_u_coo', ", ''OTRA''"))
    chk('Desviaciones: primero las por revisar', "'POR_REVISAR'", "pg_temp.q('SELECT \"Estado\" FROM \"ERP_CAF_DESVIACION_LISTAR\"(' || v_u_coo || ', ' || v_ves || ') LIMIT 1')")
    chk('Desviaciones: las por revisar, de la más antigua', "'si'", "CASE WHEN pg_temp.q('SELECT \"ID_Desviacion\" FROM \"ERP_CAF_DESVIACION_LISTAR\"(' || v_u_coo || ', ' || v_ves || ', ''POR_REVISAR'') LIMIT 1')::BIGINT = (SELECT MIN(\"ID_Desviacion\") FROM \"CAF_Desviacion\" WHERE \"Estado\" = 'POR_REVISAR') THEN 'si' ELSE 'no' END")
    chk('Desviaciones: búsqueda sin tildes por persona', "'1'", dl('v_u_coo', ", NULL, NULL, NULL, ''NOMBRE4''"))
    chk('Desviaciones: Vigilancia también las ve', "'4'", dl('v_u_vig'))
    chk('Desviaciones: sin permiso', "'0'", dl('v_u_nada'))
    chk('Desviaciones: el solicitante no las ve', "'0'", dl('v_u_sol'))
    chk('Desviaciones: otra fecha', "'0'", dl('v_u_coo', ", NULL, CURRENT_DATE - 10, CURRENT_DATE - 9"))
    ct = lambda u, col: "pg_temp.q('SELECT \"%s\" FROM \"ERP_CAF_DESVIACION_CONTADORES\"(' || %s || ', ' || v_ves || ')')" % (col, u)
    chk('Contadores: por revisar / revisadas', "'3/1'", ct('v_u_coo', 'Por_Revisar') + " || '/' || " + ct('v_u_coo', 'Revisadas'))
    chk('Contadores: sin permiso', "'(nulo)'", ct('v_u_nada', 'Por_Revisar'))
    raw('SELECT "ID_Desviacion" INTO v_des FROM "CAF_Desviacion" WHERE "Estado" = \'POR_REVISAR\' ORDER BY "ID_Desviacion" LIMIT 1;')
    dd = lambda u, col: "pg_temp.q('SELECT \"%s\" FROM \"ERP_CAF_DESVIACION_DETALLE\"(' || %s || ', ' || v_des || ')')" % (col, u)
    chk('Detalle: el Coordinador puede dar conformidad', "'Y'", dd('v_u_coo', 'Puede_Dar_Conformidad'))
    chk('Detalle: Vigilancia la ve pero no da conformidad (con motivo)', "'N|No tiene permiso para dar conformidad.'", dd('v_u_vig', 'Puede_Dar_Conformidad') + " || '|' || " + dd('v_u_vig', 'Motivo_No_Conformidad'))
    chk('Detalle: trae al Coordinador consultado y al vigilante', "'si'", "CASE WHEN " + dd('v_u_coo', 'Coordinador_Nombre') + " LIKE '%Roberto%' AND " + dd('v_u_coo', 'Registrado_Por_Nombre') + " LIKE '%María%' THEN 'si' ELSE 'no' END")
    chk('Detalle: sin permiso', "'(nulo)'", dd('v_u_nada', 'Codigo'))
    chk('Detalle: inexistente', "'(nulo)'", "pg_temp.q('SELECT \"Codigo\" FROM \"ERP_CAF_DESVIACION_DETALLE\"(' || v_u_coo || ', 999999)')")
    raw('CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des, \'ok\', v_u_vig, v_cod, v_msg);')
    chk('Coincide: botón apagado para Vigilancia = el SP rechaza (101)', "'N|101'", dd('v_u_vig', 'Puede_Dar_Conformidad') + " || '|' || v_cod")
    raw('CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_des, \'ok\', v_u_coo, v_cod, v_msg);')
    chk('Coincide: botón encendido para el Coordinador = el SP acepta (100)', "'100'", "v_cod::TEXT")
    chk('Detalle: después de revisarla, el botón se apaga con motivo', "'N|La desviación ya fue revisada.'", dd('v_u_coo', 'Puede_Dar_Conformidad') + " || '|' || " + dd('v_u_coo', 'Motivo_No_Conformidad'))
    chk('Contadores: se actualizan', "'2/2'", ct('v_u_coo', 'Por_Revisar') + " || '/' || " + ct('v_u_coo', 'Revisadas'))

    L.append('    -- ===================================================== G. DROPDOWNS')
    cd = lambda u: "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN\"(' || %s || ', ' || v_ves || ')')" % u
    chk('Coordinadores: Vigilancia ve al Coordinador', "'1'", cd('v_u_vig'))
    chk('Coordinadores: es Roberto', "'si'", "CASE WHEN pg_temp.q('SELECT \"Nombre\" FROM \"ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN\"(' || v_u_vig || ', ' || v_ves || ')') LIKE '%Roberto%' THEN 'si' ELSE 'no' END")
    chk('Coordinadores: el solicitante no los pide', "'0'", cd('v_u_sol'))
    chk('Coordinadores: sin permiso', "'0'", cd('v_u_nada'))
    td = lambda e: "pg_temp.q('SELECT COUNT(*) FROM \"ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN\"(''%s'')')" % e
    chk('Tratamientos de ingreso', "'5'", td('INGRESO'))
    chk('Tratamientos de salida', "'4'", td('SALIDA'))
    chk('Tratamientos: etapa inválida', "'0'", td('OTRA'))
    chk('Tratamientos: «Liberación» en ingreso da INGRESA', "'INGRESA'", "pg_temp.q('SELECT \"Resultado\" FROM \"ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN\"(''INGRESO'') WHERE \"Codigo\" = ''LIBERACION''')")
    chk('Tratamientos: «Retención» en salida da SALE_RETIENE_ELEMENTO', "'SALE_RETIENE_ELEMENTO'", "pg_temp.q('SELECT \"Resultado\" FROM \"ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN\"(''SALIDA'') WHERE \"Codigo\" = ''RETENCION_ELEMENTO''')")

mode = sys.argv[2]
if mode == 'escritura':
    escritura()
    name = 'PRUEBAS_FASE1_HITO3_ESCRITURA.sql'
    prop = ('pruebas automáticas de los procedimientos de ESCRITURA del Hito 3:\n--   ingresos, salidas, denegaciones, desviaciones, conformidad, respaldos,\n--   registros tardíos y cierre «no se presentó».')
else:
    lectura()
    name = 'PRUEBAS_FASE1_HITO3_LECTURA.sql'
    prop = ('pruebas automáticas de las LECTURAS del Hito 3: checklist, ficha de portería,\n--   bitácora, detalle, respaldos, desviaciones, contadores y listas desplegables.\n--   Comprueba que cada botón («Puede_...») coincide con lo que de verdad hace\n--   el procedimiento de escritura (la regla vive en un solo lugar).')
with open(out + '/' + name, 'w', encoding='utf-8') as fh:
    fh.write(HEAD.format(nombre=name, proposito=prop))
    fh.write('\n'.join(L) + '\n')
    fh.write(TAIL)
print(name, len(L), 'líneas')
