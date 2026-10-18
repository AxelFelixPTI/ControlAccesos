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

# ------------------------------- Hito 4 -------------------------------
import re
HEAD = HEAD.replace('v_reg2 BIGINT;', 'v_reg2 BIGINT; v_i1 BIGINT; v_i2 BIGINT; v_i3 BIGINT; v_i4 BIGINT; v_u_adm BIGINT; v_c1 BIGINT; v_c2 BIGINT; v_c3 BIGINT; v_est VARCHAR(20);')
HEAD = HEAD.replace("-- Requiere: scripts 01 a 10, los SP de los Hitos 0, 1 y 2 y los 4 archivos del Hito 3\n--   (SP_CAF_DESVIACION_ALL, SP_CAF_PORTERIA_ALL, SP_CAF_RESPALDO_ALL, SP_CAF_PORTERIA_LECTURA_ALL).",
                    "-- Requiere: scripts 01 a 10, los SP de los Hitos 0 a 3 y los 3 archivos del Hito 4\n--   (SP_CAF_INCIDENCIA_ALL, SP_CAF_CORREO_ALL, SP_CAF_REPORTE_ALL).")
HEAD = HEAD.replace('V1.0 2026-10-17', 'V1.0 2026-10-18')
HEAD = HEAD.replace("CREATE FUNCTION pg_temp.ev(", """CREATE FUNCTION pg_temp.ti(c TEXT) RETURNS BIGINT LANGUAGE sql
AS $f$ SELECT "ID_Catalogo_Tipo_Incidencia" FROM "Catalogo_Tipo_Incidencia" WHERE "Codigo" = c $f$;
CREATE FUNCTION pg_temp.cid(a TEXT) RETURNS BIGINT LANGUAGE sql
AS $f$ SELECT "ID_Correo_Pendiente" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = a $f$;
CREATE FUNCTION pg_temp.ev(""")

def E(t):
    """plantilla con {v_x} -> expresión SQL que arma el texto en tiempo de ejecución"""
    parts = re.split(r'\{(v_\w+)\}', t)
    out = []
    for i, p in enumerate(parts):
        if i % 2 == 0:
            if p: out.append("'" + p.replace("'", "''") + "'")
        else:
            out.append("COALESCE(%s::TEXT, ''NULL'')" % p if False else "COALESCE(%s::TEXT, 'NULL')" % p)
    return 'pg_temp.q(' + ' || '.join(out) + ')'

def F(fn, args, col='COUNT(*)', where=''):
    return E('SELECT %s FROM "%s"(%s)%s' % (col, fn, ', '.join(args), (' ' + where) if where else ''))

def T(c): return "pg_temp.ti('%s')" % c

def INC(tipo, hecho='v_hecho', det='NULL', zona='NULL', lugar='NULL', desc="'Descripción de prueba.'", pers='NULL', user='v_u_vig', sede='v_ves', into='v_reg2'):
    return ('CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, v_cs, v_cod, v_msg);'
            % (sede, tipo, det, hecho, zona, lugar, desc, pers, user, into))

def DEC(i, dec, sus="'Sustento de prueba.'", user='v_u_coo'):
    return 'CALL "ERP_CAF_INCIDENCIA_DECIDIR"(%s, %s, %s, %s, v_cod, v_msg);' % (i, dec, sus, user)

P2 = "v_p2::TEXT || ',' || v_p3::TEXT"

def mov_setup():
    raw(ING('v_p1', IT('v_p1')))
    raw(ING('v_p2', IT('v_p2', fallan='ING_PERTENENCIAS'), desc=DESC, trat='v_t_lib', coord='v_u_coo'))
    raw(ING('v_p3', IT('v_p3', fallan='ING_SCTR,ING_EPP'), desc=DESC, trat='v_t_rest', coord='v_u_coo'))
    raw(ING('v_p4', IT('v_p4', fallan='ING_IDENTIDAD'), desc=DESC, trat='v_t_den', coord='v_u_coo'))
    raw(SAL('v_p1', IT('v_p1', 'SALIDA')))

def inc_setup():
    raw("v_hecho := CAST(CURRENT_DATE AS TIMESTAMP);")
    raw(INC(T('HURTO'), zona='v_z_pt', pers="v_p2::TEXT || ',' || v_p3::TEXT")); raw('v_i1 := v_reg2;')
    raw(INC(T('OTRO'), det="'Falla de cerca'", lugar="'Perímetro norte'", user='v_u_coo')); raw('v_i2 := v_reg2;')
    raw(INC(T('ROBO'), lugar="'Almacén'", pers='v_p4::TEXT')); raw('v_i3 := v_reg2;')
    raw(INC(T('USO_NO_AUTORIZADO_AREA'), hecho="CAST(CURRENT_DATE - 2 AS TIMESTAMP) + INTERVAL '10 hours'", zona='v_z_adm', pers='v_p12::TEXT')); raw('v_i4 := v_reg2;')
    raw(DEC('v_i2', "'CONFIRMAR'"))
    raw(DEC('v_i3', "'DESESTIMAR'", sus="'Fue un error de conteo.'"))

def escritura():
    L.append('    -- ===================================================== A. INCIDENCIA_REGISTRAR: validaciones')
    raw("v_hecho := CAST(CURRENT_DATE AS TIMESTAMP);")
    raw(INC(T('HURTO'), lugar="'Almacén'", user='v_u_nada')); code('Registrar: sin permiso', 101)
    raw(INC(T('HURTO'), lugar="'Almacén'", user='v_u_sol')); code('Registrar: el solicitante no registra incidencias', 101)
    raw(INC(T('HURTO'), lugar="'Almacén'", user='v_u_min')); code('Registrar: el rol solo-portería no registra incidencias', 101)
    raw(INC(T('HURTO'), lugar="'Almacén'", user='NULL')); code('Registrar: usuario nulo', 400)
    raw(INC(T('HURTO'), lugar="'Almacén'", user='-1')); code('Registrar: usuario negativo', 400)
    raw(INC(T('HURTO'), lugar="'Almacén'", sede='NULL')); code('Registrar: sede nula', 400)
    raw(INC('NULL', lugar="'Almacén'")); code('Registrar: sin tipo', 400)
    raw(INC('999999', lugar="'Almacén'")); code('Registrar: tipo inexistente', 404)
    raw(INC(T('HURTO'), hecho='NULL', lugar="'Almacén'")); code('Registrar: sin fecha del hecho', 400)
    raw(INC(T('HURTO'), hecho="LOCALTIMESTAMP + INTERVAL '1 hour'", lugar="'Almacén'")); code('Registrar: hecho en el futuro', 400)
    raw(INC(T('HURTO'), lugar="'Almacén'", desc='NULL')); code('Registrar: sin descripción', 400)
    raw(INC(T('HURTO'), lugar="'Almacén'", desc="'   '")); code('Registrar: descripción en blanco', 400)
    raw(INC(T('HURTO'), lugar="'Almacén'", desc="REPEAT('x', 2001)")); code('Registrar: descripción demasiado larga', 400)
    raw(INC(T('HURTO'), lugar="REPEAT('x', 201)")); code('Registrar: lugar demasiado largo', 400)
    raw(INC(T('HURTO'))); code('Registrar: sin zona ni lugar', 400)
    raw(INC(T('HURTO'), lugar="'   '")); code('Registrar: lugar en blanco cuenta como vacío', 400)
    raw(INC(T('HURTO'), zona='999999')); code('Registrar: zona inexistente', 404)
    raw(INC(T('OTRO'), lugar="'Almacén'")); code('Registrar: «Otro» sin detalle', 400)
    raw(INC(T('OTRO'), det="REPEAT('x', 501)", lugar="'Almacén'")); code('Registrar: detalle del tipo demasiado largo', 400)
    raw(INC(T('HURTO'), lugar="'Almacén'", pers="'a,b'")); code('Registrar: lista de personas mal escrita', 400)
    raw(INC(T('HURTO'), lugar="'Almacén'", pers="v_p1::TEXT || ',' || v_p1::TEXT")); code('Registrar: persona repetida', 400)
    raw(INC(T('HURTO'), lugar="'Almacén'", pers="v_p1::TEXT || ',999999'")); code('Registrar: persona inexistente', 404)
    chk('Registrar: nada de lo anterior dejó incidencias', "'0'", q('SELECT COUNT(*) FROM "CAF_Incidencia"'))
    chk('Registrar: ni personas', "'0'", q('SELECT COUNT(*) FROM "CAF_Incidencia_Persona"'))

    L.append('    -- ===================================================== B. INCIDENCIA_REGISTRAR: caminos felices')
    raw(INC(T('HURTO'), zona='v_z_pt', desc="'  Faltan dos cajas.  '", user='v_u_vig')); code('Registrar: Vigilancia, con zona y sin personas', 100)
    raw('v_i1 := v_reg2;')
    chk('Registrar: devuelve un identificador', "'si'", "CASE WHEN v_i1 > 0 THEN 'si' ELSE 'no' END")
    chk('Registrar: el código es INC- y 5 dígitos', "'si'", "CASE WHEN v_cs = 'INC-' || LPAD(v_i1::TEXT, 5, '0') THEN 'si' ELSE 'no' END")
    chk('Registrar: nace REGISTRADA', "'REGISTRADA'", E('SELECT "Estado" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i1}'))
    chk('Registrar: Vigilancia deja origen VIGILANCIA', "'VIGILANCIA'", E('SELECT "Origen" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i1}'))
    chk('Registrar: guarda quién la registró', "'si'", "CASE WHEN " + E('SELECT "ID_Usuario_Registro" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i1}') + " = v_u_vig::TEXT THEN 'si' ELSE 'no' END")
    chk('Registrar: recorta espacios de la descripción', "'Faltan dos cajas.'", E('SELECT "Descripcion" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i1}'))
    chk('Registrar: sin decisión todavía', "'(nulo)'", E('SELECT "ID_Usuario_Decision" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i1}'))
    chk('Registrar: sin personas', "'0'", E('SELECT COUNT(*) FROM "CAF_Incidencia_Persona" WHERE "ID_Incidencia" = {v_i1}'))
    chk('Registrar: deja el evento REGISTRAR', "'1'", "pg_temp.ev('INCIDENCIA', v_i1, 'REGISTRAR')")
    chk('Registrar: evento sin solicitud si no hay personas', "'(nulo)'", E('SELECT "ID_Solicitud" FROM "CAF_Evento" WHERE "Entidad" = \'INCIDENCIA\' AND "ID_Entidad" = {v_i1}'))
    raw(INC(T('HURTO'), det="'No debería guardarse'", lugar="'Almacén'", pers="v_p2::TEXT || ',' || v_p3::TEXT", user='v_u_coo')); code('Registrar: Coordinador, con lugar y dos personas de la misma visita', 100)
    raw('v_i2 := v_reg2;')
    chk('Registrar: el Coordinador deja origen COORDINADOR', "'COORDINADOR'", E('SELECT "Origen" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i2}'))
    chk('Registrar: guarda las dos personas', "'2'", E('SELECT COUNT(*) FROM "CAF_Incidencia_Persona" WHERE "ID_Incidencia" = {v_i2}'))
    chk('Registrar: el detalle se descarta si el tipo no es «Otro»', "'(nulo)'", E('SELECT "Tipo_Detalle" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i2}'))
    chk('Registrar: el evento apunta a la solicitud común', "'si'", "CASE WHEN " + E('SELECT "ID_Solicitud" FROM "CAF_Evento" WHERE "Entidad" = \'INCIDENCIA\' AND "ID_Entidad" = {v_i2}') + " = v_s1::TEXT THEN 'si' ELSE 'no' END")
    raw(INC(T('OTRO'), det="'Falla de cerca'", zona='v_z_adm', pers="v_p1::TEXT || ',' || v_p12::TEXT")); code('Registrar: «Otro» con detalle y personas de dos visitas', 100)
    raw('v_i3 := v_reg2;')
    chk('Registrar: guarda el detalle de «Otro»', "'Falla de cerca'", E('SELECT "Tipo_Detalle" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i3}'))
    chk('Registrar: evento sin solicitud si las personas son de varias visitas', "'(nulo)'", E('SELECT "ID_Solicitud" FROM "CAF_Evento" WHERE "Entidad" = \'INCIDENCIA\' AND "ID_Entidad" = {v_i3}'))
    raw(INC(T('ROBO'), lugar="'Almacén'", pers="v_p10::TEXT || ',' || v_p9::TEXT || ', ' || v_p7::TEXT")); code('Registrar: acepta personas de visita cancelada o sin aprobar, y espacios en la lista', 100)
    raw('v_i4 := v_reg2;')
    chk('Registrar: tres personas guardadas', "'3'", E('SELECT COUNT(*) FROM "CAF_Incidencia_Persona" WHERE "ID_Incidencia" = {v_i4}'))
    raw(INC(T('HURTO'), hecho="LOCALTIMESTAMP - INTERVAL '5 days'", lugar="'Almacén'")); code('Registrar: acepta un hecho de hace días', 100)
    chk('Registrar: los códigos no se repiten', "'5'", q('SELECT COUNT(DISTINCT "Codigo") FROM "CAF_Incidencia"'))

    L.append('    -- ===================================================== C. INCIDENCIA_DECIDIR')
    raw(DEC('v_i1', "'CONFIRMAR'", user='v_u_vig')); code('Decidir: Vigilancia no decide', 101)
    raw(DEC('v_i1', "'CONFIRMAR'", user='v_u_nada')); code('Decidir: sin permiso', 101)
    raw(DEC('v_i1', "'CONFIRMAR'", user='v_u_sol')); code('Decidir: el solicitante no decide', 101)
    raw(DEC('v_i1', "'CONFIRMAR'", user='NULL')); code('Decidir: usuario nulo', 400)
    raw(DEC('v_i1', "'CONFIRMAR'", user='-1')); code('Decidir: usuario negativo', 400)
    raw(DEC('v_i1', "'APROBAR'")); code('Decidir: decisión inválida', 400)
    raw(DEC('v_i1', 'NULL')); code('Decidir: sin decisión', 400)
    raw(DEC('v_i1', "'CONFIRMAR'", sus='NULL')); code('Decidir: sin sustento', 400)
    raw(DEC('v_i1', "'CONFIRMAR'", sus="'  '")); code('Decidir: sustento en blanco', 400)
    raw(DEC('v_i1', "'CONFIRMAR'", sus="REPEAT('x', 2001)")); code('Decidir: sustento demasiado largo', 400)
    raw(DEC('999999', "'CONFIRMAR'")); code('Decidir: incidencia inexistente', 404)
    chk('Decidir: nada de lo anterior la decidió', "'REGISTRADA'", E('SELECT "Estado" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i1}'))
    raw(DEC('v_i1', "'confirmar'", sus="'  Se verificó con el inventario.  '")); code('Decidir: confirmar (acepta minúsculas)', 100)
    chk('Decidir: queda CONFIRMADA', "'CONFIRMADA'", E('SELECT "Estado" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i1}'))
    chk('Decidir: guarda al decisor', "'si'", "CASE WHEN " + E('SELECT "ID_Usuario_Decision" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i1}') + " = v_u_coo::TEXT THEN 'si' ELSE 'no' END")
    chk('Decidir: guarda la fecha', "'si'", "CASE WHEN " + E('SELECT "Fecha_Decision" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i1}') + " <> '(nulo)' THEN 'si' ELSE 'no' END")
    chk('Decidir: guarda el sustento recortado', "'Se verificó con el inventario.'", E('SELECT "Sustento_Decision" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i1}'))
    chk('Decidir: deja el evento CONFIRMAR', "'1'", "pg_temp.ev('INCIDENCIA', v_i1, 'CONFIRMAR')")
    raw(DEC('v_i1', "'CONFIRMAR'")); code('Decidir: no se decide dos veces', 409)
    raw(DEC('v_i1', "'DESESTIMAR'")); code('Decidir: ni se cambia después de confirmar', 409)
    raw(DEC('v_i1', "'DESESTIMAR'", user='v_u_vig')); code('Decidir: sin permiso gana sobre «ya decidida»', 101)
    raw(DEC('v_i2', "'DESESTIMAR'", sus="'No hubo tal hurto.'")); code('Decidir: desestimar', 100)
    chk('Decidir: queda DESESTIMADA', "'DESESTIMADA'", E('SELECT "Estado" FROM "CAF_Incidencia" WHERE "ID_Incidencia" = {v_i2}'))
    chk('Decidir: deja el evento DESESTIMAR', "'1'", "pg_temp.ev('INCIDENCIA', v_i2, 'DESESTIMAR')")
    chk('Decidir: el evento de decisión apunta a la solicitud común', "'si'", "CASE WHEN " + E('SELECT "ID_Solicitud" FROM "CAF_Evento" WHERE "Entidad" = \'INCIDENCIA\' AND "ID_Entidad" = {v_i2} AND "Accion" = \'DESESTIMAR\'') + " = v_s1::TEXT THEN 'si' ELSE 'no' END")
    raw('UPDATE "CAF_Incidencia" SET "Eliminado" = \'Y\' WHERE "ID_Incidencia" = v_i3;')
    raw(DEC('v_i3', "'CONFIRMAR'")); code('Decidir: una incidencia eliminada no existe', 404)
    raw(DEC('v_i4', "'CONFIRMAR'")); code('Decidir: otra incidencia sigue su curso', 100)

    L.append('    -- ===================================================== D. CORREOS: cola, envío y errores')
    raw('UPDATE "CAF_Correo_Pendiente" SET "Estado" = \'ENVIADO\';')
    for a in 'ABC':
        raw('CALL "ERP_CAF_CORREO_ENCOLAR"(\'SOLICITUD_NUEVA\', v_s1, \'a@ejemplo.pe\', NULL, \'Prueba %s\', \'<p>%s</p>\', v_u_coo, v_cod, v_msg);' % (a, a))
    pl = lambda u, mx=None: F('ERP_CAF_CORREO_PENDIENTES_LISTAR', [u] + ([mx] if mx else []))
    chk('Pendientes: el sistema ve los 3 encolados', "'3'", pl('{v_u_vig}'.replace('{v_u_vig}', '0')))
    chk('Pendientes: una persona no puede leerlos (Vigilancia)', "'0'", pl('{v_u_vig}'))
    chk('Pendientes: ni el Coordinador', "'0'", pl('{v_u_coo}'))
    chk('Pendientes: usuario nulo', "'0'", pl('NULL'))
    chk('Pendientes: máximo 2', "'2'", pl('0', '2'))
    chk('Pendientes: máximo 0 se corrige a 1', "'1'", pl('0', '0'))
    chk('Pendientes: máximo enorme se corrige a 100', "'3'", pl('0', '1000'))
    chk('Pendientes: máximo nulo usa el valor por defecto', "'3'", pl('0', 'NULL'))
    chk('Pendientes: el más antiguo primero', "'Prueba A'", F('ERP_CAF_CORREO_PENDIENTES_LISTAR', ['0'], '"Asunto"', 'LIMIT 1'))
    chk('Pendientes: trae el cuerpo', "'<p>A</p>'", F('ERP_CAF_CORREO_PENDIENTES_LISTAR', ['0'], '"Cuerpo"', 'LIMIT 1'))
    mk = lambda a, u='0': 'CALL "ERP_CAF_CORREO_MARCAR_ENVIADO"(pg_temp.cid(\'Prueba %s\'), %s, v_cod, v_msg);' % (a, u)
    raw(mk('A', 'v_u_vig')); code('Enviado: una persona no marca correos', 101)
    raw(mk('A', 'NULL')); code('Enviado: usuario nulo', 101)
    raw('CALL "ERP_CAF_CORREO_MARCAR_ENVIADO"(999999, 0, v_cod, v_msg);'); code('Enviado: correo inexistente', 404)
    raw(mk('A')); code('Enviado: ok', 100)
    cc = lambda a, col: E('SELECT "%s" FROM "CAF_Correo_Pendiente" WHERE "Asunto" = \'Prueba %s\'' % (col, a))
    chk('Enviado: queda ENVIADO', "'ENVIADO'", cc('A', 'Estado'))
    chk('Enviado: cuenta el intento', "'1'", cc('A', 'Intentos'))
    chk('Enviado: guarda la fecha de envío', "'si'", "CASE WHEN " + cc('A', 'Fecha_Envio') + " <> '(nulo)' THEN 'si' ELSE 'no' END")
    raw(mk('A')); code('Enviado: no se marca dos veces', 409)
    chk('Pendientes: ya quedan 2', "'2'", pl('0'))
    me = lambda a, mx='3', err="'SMTP caído'", u='0': 'CALL "ERP_CAF_CORREO_MARCAR_ERROR"(pg_temp.cid(\'Prueba %s\'), %s, %s, %s, v_est, v_cod, v_msg);' % (a, err, mx, u)
    raw(me('B', u='v_u_vig')); code('Error: una persona no marca correos', 101)
    raw(me('B', mx='0')); code('Error: máximo de intentos 0', 400)
    raw(me('B', mx='21')); code('Error: máximo de intentos 21', 400)
    raw(me('B', mx='NULL')); code('Error: máximo de intentos nulo', 400)
    raw('CALL "ERP_CAF_CORREO_MARCAR_ERROR"(999999, \'x\', 3, 0, v_est, v_cod, v_msg);'); code('Error: correo inexistente', 404)
    raw(me('B')); code('Error: primer fallo', 100)
    chk('Error: sigue PENDIENTE', "'PENDIENTE|1'", "v_est || '|' || " + cc('B', 'Intentos'))
    chk('Error: guarda el error', "'SMTP caído'", cc('B', 'Ultimo_Error'))
    chk('Error: se reintentará (sigue en la lista)', "'2'", pl('0'))
    raw(me('B')); chk('Error: segundo fallo, sigue PENDIENTE', "'PENDIENTE|2'", "v_est || '|' || " + cc('B', 'Intentos'))
    raw(me('B', err="'   '")); chk('Error: tercer fallo agota los intentos', "'ERROR|3'", "v_est || '|' || " + cc('B', 'Intentos'))
    chk('Error: error vacío se guarda como «sin detalle»', "'Error sin detalle'", cc('B', 'Ultimo_Error'))
    raw(me('B')); code('Error: un correo en ERROR no se vuelve a marcar', 409)
    chk('Pendientes: sale de la lista', "'1'", pl('0'))
    raw(me('C', mx='1', err='NULL')); chk('Error: con máximo 1 pasa a ERROR de inmediato', "'ERROR'", "v_est")
    chk('Error: error nulo se guarda como «sin detalle»', "'Error sin detalle'", cc('C', 'Ultimo_Error'))
    chk('Pendientes: ya no queda ninguno', "'0'", pl('0'))

    L.append('    -- ===================================================== E. CORREOS: administración')
    raw('SELECT "ID_Usuario" INTO v_u_adm FROM "Usuario" WHERE "Correo" = \'nadie@ejemplo.pe\';')
    raw('SELECT "ID_Catalogo_Licencia" INTO v_c1 FROM "Catalogo_Licencia" WHERE "Codigo" = \'LIC_CAF_ADMIN\';')
    raw('CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_u_adm, v_c1, v_ves, 0, v_ul, v_cod, v_msg);')
    cl = lambda u, extra='': F('ERP_CAF_CORREO_LISTAR', [u, '{v_ves}'] + ([extra] if extra else []))
    chk('Listar correos: el Administrador ve todos', "(SELECT COUNT(*)::TEXT FROM \"CAF_Correo_Pendiente\" WHERE \"Eliminado\" = 'N')", cl('{v_u_adm}'))
    chk('Listar correos: filtra por ERROR', "'2'", cl('{v_u_adm}', "'ERROR'"))
    chk('Listar correos: filtra por PENDIENTE', "(SELECT COUNT(*)::TEXT FROM \"CAF_Correo_Pendiente\" WHERE \"Estado\" = 'PENDIENTE')", cl('{v_u_adm}', "'pendiente'"))
    chk('Listar correos: estado inválido', "'0'", cl('{v_u_adm}', "'OTRO'"))
    chk('Listar correos: el Coordinador no administra la bandeja', "'0'", cl('{v_u_coo}'))
    chk('Listar correos: Vigilancia tampoco', "'0'", cl('{v_u_vig}'))
    chk('Listar correos: sin sede', "'0'", F('ERP_CAF_CORREO_LISTAR', ['{v_u_adm}', 'NULL']))
    chk('Listar correos: no devuelve el cuerpo', "'0'", q("SELECT COUNT(*) FROM information_schema.parameters WHERE specific_schema = 'TRIANONSATELITAL_CAF_PRODD' AND parameter_mode = 'OUT' AND parameter_name = 'Cuerpo' AND specific_name LIKE 'ERP_CAF_CORREO_LISTAR%'"))
    chk('Listar correos: muestra el código de la solicitud', "'si'", "CASE WHEN " + F('ERP_CAF_CORREO_LISTAR', ['{v_u_adm}', '{v_ves}', "'ERROR'"], '"Codigo_Solicitud"', 'LIMIT 1') + " <> '(nulo)' THEN 'si' ELSE 'no' END")
    chk('Listar correos: otra fecha', "'0'", cl('{v_u_adm}', "NULL, CURRENT_DATE - 9, CURRENT_DATE - 8"))
    re_ = lambda a, u='v_u_adm', s='v_ves': 'CALL "ERP_CAF_CORREO_REENCOLAR"(pg_temp.cid(\'Prueba %s\'), %s, %s, v_cod, v_msg);' % (a, s, u)
    raw(re_('B', 'v_u_coo')); code('Reencolar: el Coordinador no puede', 101)
    raw(re_('B', 'v_u_vig')); code('Reencolar: Vigilancia no puede', 101)
    raw(re_('B', s='NULL')); code('Reencolar: sin sede', 101)
    raw(re_('B', 'NULL')); code('Reencolar: usuario nulo', 400)
    raw('CALL "ERP_CAF_CORREO_REENCOLAR"(999999, v_ves, v_u_adm, v_cod, v_msg);'); code('Reencolar: correo inexistente', 404)
    raw(re_('A')); code('Reencolar: un correo ENVIADO no se reencola', 409)
    raw(re_('B')); code('Reencolar: correo en ERROR', 100)
    chk('Reencolar: vuelve a PENDIENTE', "'PENDIENTE|0'", cc('B', 'Estado') + " || '|' || " + cc('B', 'Intentos'))
    chk('Reencolar: vuelve a la lista del sistema', "'1'", pl('0'))
    raw(re_('B')); code('Reencolar: ya no está en ERROR', 409)

def lectura():
    L.append('    -- ===================================================== PREPARACIÓN DE MOVIMIENTOS E INCIDENCIAS')
    mov_setup()
    inc_setup()
    chk('Preparación: movimientos (4 ingresos y 1 salida)', "'5'", q('SELECT COUNT(*) FROM "CAF_Registro_Acceso"'))
    chk('Preparación: 4 incidencias', "'4'", q('SELECT COUNT(*) FROM "CAF_Incidencia"'))

    L.append('    -- ===================================================== A. INCIDENCIA_LISTAR')
    il = lambda u, extra='': F('ERP_CAF_INCIDENCIA_LISTAR', [u, '{v_ves}'] + ([extra] if extra else []))
    chk('Listar: el Coordinador ve las 4', "'4'", il('{v_u_coo}'))
    chk('Listar: Vigilancia también', "'4'", il('{v_u_vig}'))
    chk('Listar: por estado REGISTRADA', "'2'", il('{v_u_coo}', "'REGISTRADA'"))
    chk('Listar: por estado CONFIRMADA', "'1'", il('{v_u_coo}', "'confirmada'"))
    chk('Listar: por estado DESESTIMADA', "'1'", il('{v_u_coo}', "'DESESTIMADA'"))
    chk('Listar: estado inválido', "'0'", il('{v_u_coo}', "'OTRA'"))
    chk('Listar: sin permiso', "'0'", il('{v_u_nada}'))
    chk('Listar: el solicitante no las ve', "'0'", il('{v_u_sol}'))
    chk('Listar: el rol solo-portería no las ve', "'0'", il('{v_u_min}'))
    chk('Listar: sede nula', "'0'", F('ERP_CAF_INCIDENCIA_LISTAR', ['{v_u_coo}', 'NULL']))
    chk('Listar: hechos de hoy', "'3'", il('{v_u_coo}', 'NULL, CURRENT_DATE, CURRENT_DATE'))
    chk('Listar: hechos de hace dos días', "'1'", il('{v_u_coo}', 'NULL, CURRENT_DATE - 3, CURRENT_DATE - 1'))
    chk('Listar: solo desde una fecha', "'3'", il('{v_u_coo}', 'NULL, CURRENT_DATE'))
    chk('Listar: búsqueda sin tildes ni mayúsculas', "'1'", il('{v_u_coo}', "NULL, NULL, NULL, 'PERIMETRO'"))
    chk('Listar: búsqueda por código', "'4'", il('{v_u_coo}', "NULL, NULL, NULL, 'inc-'"))
    chk('Listar: búsqueda por tipo', "'1'", il('{v_u_coo}', "NULL, NULL, NULL, 'hurto'"))
    chk('Listar: búsqueda por zona', "'1'", il('{v_u_coo}', "NULL, NULL, NULL, 'oficinas'"))
    chk('Listar: búsqueda sin resultados', "'0'", il('{v_u_coo}', "NULL, NULL, NULL, 'zzzz'"))
    chk('Listar: primero la registrada más antigua', "'si'", "CASE WHEN " + F('ERP_CAF_INCIDENCIA_LISTAR', ['{v_u_coo}', '{v_ves}'], '"ID_Incidencia"', 'LIMIT 1') + " = v_i4::TEXT THEN 'si' ELSE 'no' END")
    chk('Listar: las decididas al final', "'si'", "CASE WHEN " + F('ERP_CAF_INCIDENCIA_LISTAR', ['{v_u_coo}', '{v_ves}'], '"Estado"', 'OFFSET 3 LIMIT 1') + " <> 'REGISTRADA' THEN 'si' ELSE 'no' END")
    chk('Listar: cuenta las personas', "'2'", F('ERP_CAF_INCIDENCIA_LISTAR', ['{v_u_coo}', '{v_ves}'], '"Cantidad_Personas"', 'WHERE "ID_Incidencia" = {v_i1}'))
    chk('Listar: incidencia sin personas', "'0'", F('ERP_CAF_INCIDENCIA_LISTAR', ['{v_u_coo}', '{v_ves}'], '"Cantidad_Personas"', 'WHERE "ID_Incidencia" = {v_i2}'))
    chk('Listar: origen de cada una', "'VIGILANCIA|COORDINADOR'", F('ERP_CAF_INCIDENCIA_LISTAR', ['{v_u_coo}', '{v_ves}'], '"Origen"', 'WHERE "ID_Incidencia" = {v_i1}') + " || '|' || " + F('ERP_CAF_INCIDENCIA_LISTAR', ['{v_u_coo}', '{v_ves}'], '"Origen"', 'WHERE "ID_Incidencia" = {v_i2}'))
    chk('Listar: «Otro» muestra su detalle', "'Otro: Falla de cerca'", F('ERP_CAF_INCIDENCIA_LISTAR', ['{v_u_coo}', '{v_ves}'], '"Tipo_Descripcion"', 'WHERE "ID_Incidencia" = {v_i2}'))
    chk('Listar: zona y lugar', "'Producto terminado|(nulo)'", "COALESCE(NULLIF(" + F('ERP_CAF_INCIDENCIA_LISTAR', ['{v_u_coo}', '{v_ves}'], '"Zona_Descripcion"', 'WHERE "ID_Incidencia" = {v_i1}') + ", '(nulo)'), '?') || '|' || " + F('ERP_CAF_INCIDENCIA_LISTAR', ['{v_u_coo}', '{v_ves}'], '"Lugar_Detalle"', 'WHERE "ID_Incidencia" = {v_i1}'))
    chk('Listar: nombre de quien registró', "'Vigilante Uno, María'", F('ERP_CAF_INCIDENCIA_LISTAR', ['{v_u_coo}', '{v_ves}'], '"Registrador_Nombre"', 'WHERE "ID_Incidencia" = {v_i1}'))

    L.append('    -- ===================================================== B. INCIDENCIA_DETALLE y PERSONAS_LISTAR')
    idt = lambda u, i, col: F('ERP_CAF_INCIDENCIA_DETALLE', [u, i], '"%s"' % col)
    chk('Detalle: el Coordinador puede decidir una registrada', "'Y'", idt('{v_u_coo}', '{v_i1}', 'Puede_Decidir'))
    chk('Detalle: Vigilancia la ve pero no decide', "'N'", idt('{v_u_vig}', '{v_i1}', 'Puede_Decidir'))
    chk('Detalle: una decidida no se decide otra vez', "'N'", idt('{v_u_coo}', '{v_i2}', 'Puede_Decidir'))
    chk('Detalle: trae al decisor y el sustento', "'Roberto|Fue un error de conteo.'", "SUBSTRING(" + idt('{v_u_coo}', '{v_i3}', 'Decisor_Nombre') + " FROM 'Roberto') || '|' || " + idt('{v_u_coo}', '{v_i3}', 'Sustento_Decision'))
    chk('Detalle: estado y origen', "'REGISTRADA|VIGILANCIA'", idt('{v_u_coo}', '{v_i1}', 'Estado') + " || '|' || " + idt('{v_u_coo}', '{v_i1}', 'Origen'))
    chk('Detalle: sin decisión no hay decisor', "'(nulo)'", idt('{v_u_coo}', '{v_i1}', 'Decisor_Nombre'))
    chk('Detalle: tipo «Otro» con su detalle', "'Falla de cerca'", idt('{v_u_coo}', '{v_i2}', 'Tipo_Detalle'))
    chk('Detalle: sin permiso', "'(nulo)'", idt('{v_u_nada}', '{v_i1}', 'Codigo'))
    chk('Detalle: el solicitante no lo ve', "'(nulo)'", idt('{v_u_sol}', '{v_i1}', 'Codigo'))
    chk('Detalle: inexistente', "'(nulo)'", F('ERP_CAF_INCIDENCIA_DETALLE', ['{v_u_coo}', '999999'], '"Codigo"'))
    ipl = lambda u, i: F('ERP_CAF_INCIDENCIA_PERSONAS_LISTAR', [u, i])
    chk('Personas: la incidencia 1 involucra a 2', "'2'", ipl('{v_u_coo}', '{v_i1}'))
    chk('Personas: la incidencia sin personas', "'0'", ipl('{v_u_coo}', '{v_i2}'))
    chk('Personas: Vigilancia las ve', "'2'", ipl('{v_u_vig}', '{v_i1}'))
    chk('Personas: sin permiso', "'0'", ipl('{v_u_nada}', '{v_i1}'))
    chk('Personas: inexistente', "'0'", ipl('{v_u_coo}', '999999'))
    chk('Personas: estado de la persona en la visita', "'DENTRO'", F('ERP_CAF_INCIDENCIA_PERSONAS_LISTAR', ['{v_u_coo}', '{v_i1}'], '"Estado_Persona"', 'WHERE "ID_Solicitud_Persona" = {v_p2}'))
    chk('Personas: la de la incidencia 4 es de otra visita', "'si'", "CASE WHEN " + F('ERP_CAF_INCIDENCIA_PERSONAS_LISTAR', ['{v_u_coo}', '{v_i4}'], '"ID_Solicitud"') + " = v_s2::TEXT THEN 'si' ELSE 'no' END")

    L.append('    -- ===================================================== C. INCIDENCIA_CONTADORES y PERSONAS_BUSCAR')
    ic = lambda u, col: F('ERP_CAF_INCIDENCIA_CONTADORES', [u, '{v_ves}'], '"%s"' % col)
    chk('Contadores: registradas / confirmadas / desestimadas', "'2/1/1'", ic('{v_u_coo}', 'Registradas') + " || '/' || " + ic('{v_u_coo}', 'Confirmadas') + " || '/' || " + ic('{v_u_coo}', 'Desestimadas'))
    chk('Contadores: sin permiso', "'(nulo)'", ic('{v_u_nada}', 'Registradas'))
    chk('Contadores: sede nula', "'(nulo)'", F('ERP_CAF_INCIDENCIA_CONTADORES', ['{v_u_coo}', 'NULL'], '"Registradas"'))
    pb = lambda u, extra='': F('ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR', [u, '{v_ves}'] + ([extra] if extra else []))
    chk('Buscar personas: por defecto, visitas de ayer y hoy', "'8'", pb('{v_u_vig}'), "'S1 con 6 personas y S2 con 2'")
    chk('Buscar personas: el Coordinador también', "'8'", pb('{v_u_coo}'))
    chk('Buscar personas: visitas de hace tres días (incluye cancelada y sin aprobar)', "'4'", pb('{v_u_vig}', 'CURRENT_DATE - 4, CURRENT_DATE - 2'))
    chk('Buscar personas: por nombre', "'1'", pb('{v_u_vig}', "NULL, NULL, 'nombre4'"))
    chk('Buscar personas: por empresa', "'2'", pb('{v_u_vig}', "NULL, NULL, 'otra visita'"))
    chk('Buscar personas: sin permiso', "'0'", pb('{v_u_nada}'))
    chk('Buscar personas: el solicitante no', "'0'", pb('{v_u_sol}'))
    chk('Buscar personas: el rol solo-portería no', "'0'", pb('{v_u_min}'))
    chk('Buscar personas: rango invertido', "'0'", pb('{v_u_vig}', 'CURRENT_DATE, CURRENT_DATE - 3'))
    chk('Buscar personas: sede nula', "'0'", F('ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR', ['{v_u_vig}', 'NULL']))
    chk('Buscar personas: indica el estado actual', "'DENTRO'", F('ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR', ['{v_u_vig}', '{v_ves}'], '"Estado_Persona"', 'WHERE "ID_Solicitud_Persona" = {v_p2}'))

    L.append('    -- ===================================================== D. REPORTE_ACCESOS')
    ra = lambda u, extra='': F('ERP_CAF_REPORTE_ACCESOS', [u, '{v_ves}', 'CURRENT_DATE', 'CURRENT_DATE'] + ([extra] if extra else []))
    chk('Reporte: el Coordinador ve los 5 movimientos de hoy', "'5'", ra('{v_u_coo}'))
    chk('Reporte: Vigilancia no tiene permiso de reporte', "'0'", ra('{v_u_vig}'))
    chk('Reporte: sin permiso', "'0'", ra('{v_u_nada}'))
    chk('Reporte: el solicitante no', "'0'", ra('{v_u_sol}'))
    chk('Reporte: solo ingresos', "'4'", ra('{v_u_coo}', "'INGRESO'"))
    chk('Reporte: solo salidas', "'1'", ra('{v_u_coo}', "'salida'"))
    chk('Reporte: tipo inválido', "'0'", ra('{v_u_coo}', "'OTRO'"))
    chk('Reporte: resultado NO_INGRESA', "'1'", ra('{v_u_coo}', "NULL, 'NO_INGRESA'"))
    chk('Reporte: resultado INGRESA_RESTRINGIDO', "'1'", ra('{v_u_coo}', "NULL, 'INGRESA_RESTRINGIDO'"))
    chk('Reporte: resultado SALE', "'1'", ra('{v_u_coo}', "NULL, 'SALE'"))
    chk('Reporte: búsqueda por persona', "'1'", ra('{v_u_coo}', "NULL, NULL, 'nombre4'"))
    chk('Reporte: búsqueda por empresa', "'5'", ra('{v_u_coo}', "NULL, NULL, 'energia verde'"))
    chk('Reporte: otro día no tiene', "'0'", F('ERP_CAF_REPORTE_ACCESOS', ['{v_u_coo}', '{v_ves}', 'CURRENT_DATE - 1', 'CURRENT_DATE - 1']))
    chk('Reporte: rango de 92 días permitido', "'5'", F('ERP_CAF_REPORTE_ACCESOS', ['{v_u_coo}', '{v_ves}', 'CURRENT_DATE - 92', 'CURRENT_DATE']))
    chk('Reporte: rango de 93 días rechazado', "'0'", F('ERP_CAF_REPORTE_ACCESOS', ['{v_u_coo}', '{v_ves}', 'CURRENT_DATE - 93', 'CURRENT_DATE']))
    chk('Reporte: rango invertido', "'0'", F('ERP_CAF_REPORTE_ACCESOS', ['{v_u_coo}', '{v_ves}', 'CURRENT_DATE', 'CURRENT_DATE - 1']))
    chk('Reporte: sin fechas', "'0'", F('ERP_CAF_REPORTE_ACCESOS', ['{v_u_coo}', '{v_ves}', 'NULL', 'NULL']))
    chk('Reporte: sede nula', "'0'", F('ERP_CAF_REPORTE_ACCESOS', ['{v_u_coo}', 'NULL', 'CURRENT_DATE', 'CURRENT_DATE']))
    col = lambda c, w: F('ERP_CAF_REPORTE_ACCESOS', ['{v_u_coo}', '{v_ves}', 'CURRENT_DATE', 'CURRENT_DATE'], '"%s"' % c, w)
    chk('Reporte: ítems incumplidos de cada ingreso (0/1/2/0)', "'0/1/2/0'",
        col('Items_Incumplidos', 'WHERE "Tipo_Movimiento" = \'INGRESO\' AND "Persona_Nombre" LIKE \'Apellido1 %\'') + " || '/' || " +
        col('Items_Incumplidos', 'WHERE "Persona_Nombre" LIKE \'Apellido2 %\'') + " || '/' || " +
        col('Items_Incumplidos', 'WHERE "Persona_Nombre" LIKE \'Apellido3 %\'') + " || '/' || " +
        col('Items_Incumplidos', 'WHERE "Tipo_Movimiento" = \'SALIDA\''))
    chk('Reporte: trae el código y estado de la desviación', "'si'", "CASE WHEN " + col('Codigo_Desviacion', 'WHERE "Persona_Nombre" LIKE \'Apellido2 %\'') + " LIKE 'DES-%' AND " + col('Estado_Desviacion', 'WHERE "Persona_Nombre" LIKE \'Apellido2 %\'') + " = 'POR_REVISAR' THEN 'si' ELSE 'no' END")
    chk('Reporte: movimiento sin desviación', "'(nulo)'", col('Codigo_Desviacion', 'WHERE "Tipo_Movimiento" = \'SALIDA\''))
    chk('Reporte: lista las zonas de la visita', "'si'", "CASE WHEN " + col('Zonas', 'LIMIT 1') + " LIKE '%, %' THEN 'si' ELSE 'no' END")
    chk('Reporte: nombre del vigilante', "'Vigilante Uno, María'", col('Vigilante_Nombre', 'LIMIT 1'))
    chk('Reporte: en orden cronológico', "'si'", "CASE WHEN " + col('Tipo_Movimiento', 'LIMIT 1') + " = 'INGRESO' THEN 'si' ELSE 'no' END")

    L.append('    -- ===================================================== E. REPORTE_RESUMEN_DIARIO')
    rr = lambda u, d1='CURRENT_DATE - 5', d2='CURRENT_DATE': F('ERP_CAF_REPORTE_RESUMEN_DIARIO', [u, '{v_ves}', d1, d2])
    chk('Resumen: dos días con actividad', "'2'", rr('{v_u_coo}'), "'hoy y la incidencia de hace dos días'")
    chk('Resumen: sin permiso', "'0'", rr('{v_u_nada}'))
    chk('Resumen: Vigilancia no tiene permiso de reporte', "'0'", rr('{v_u_vig}'))
    chk('Resumen: rango demasiado largo', "'0'", rr('{v_u_coo}', 'CURRENT_DATE - 93'))
    chk('Resumen: rango invertido', "'0'", rr('{v_u_coo}', 'CURRENT_DATE', 'CURRENT_DATE - 1'))
    chk('Resumen: sede nula', "'0'", F('ERP_CAF_REPORTE_RESUMEN_DIARIO', ['{v_u_coo}', 'NULL', 'CURRENT_DATE', 'CURRENT_DATE']))
    rc = lambda c, d: F('ERP_CAF_REPORTE_RESUMEN_DIARIO', ['{v_u_coo}', '{v_ves}', 'CURRENT_DATE - 5', 'CURRENT_DATE'], '"%s"' % c, 'WHERE "Fecha" = %s' % d)
    chk('Resumen de hoy: ingresos / restringidos / denegados / salidas', "'3/1/1/1'", "/".join(['%s'] * 1) and (rc('Ingresos', 'CURRENT_DATE') + " || '/' || " + rc('Ingresos_Restringidos', 'CURRENT_DATE') + " || '/' || " + rc('Ingresos_Denegados', 'CURRENT_DATE') + " || '/' || " + rc('Salidas', 'CURRENT_DATE')))
    chk('Resumen de hoy: desviaciones / incidencias (la desestimada no cuenta)', "'3/2'", rc('Desviaciones', 'CURRENT_DATE') + " || '/' || " + rc('Incidencias', 'CURRENT_DATE'))
    chk('Resumen de hace dos días: solo la incidencia', "'0/1'", rc('Ingresos', 'CURRENT_DATE - 2') + " || '/' || " + rc('Incidencias', 'CURRENT_DATE - 2'))

    L.append('    -- ===================================================== F. REPORTE_AUTORIZADOS_POR_ZONA')
    az = lambda u, z, d, extra='': F('ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA', [u, '{v_ves}', z, d], extra or 'COUNT(*)') if not extra else F('ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA', [u, '{v_ves}', z, d])
    azc = lambda u, z, d: F('ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA', [u, '{v_ves}', z, d])
    chk('Autorizados: Producto terminado hoy (solo la visita 1)', "'6'", azc('{v_u_coo}', '{v_z_pt}', 'CURRENT_DATE'))
    chk('Autorizados: oficinas hoy (visitas 1 y 2)', "'8'", azc('{v_u_coo}', '{v_z_adm}', 'CURRENT_DATE'))
    chk('Autorizados: oficinas hace tres días (aprobadas de la visita pasada; la cancelada no)', "'2'", azc('{v_u_coo}', '{v_z_adm}', 'CURRENT_DATE - 3'))
    chk('Autorizados: otro día', "'0'", azc('{v_u_coo}', '{v_z_pt}', 'CURRENT_DATE + 30'))
    chk('Autorizados: Vigilancia no tiene permiso de reporte', "'0'", azc('{v_u_vig}', '{v_z_pt}', 'CURRENT_DATE'))
    chk('Autorizados: sin permiso', "'0'", azc('{v_u_nada}', '{v_z_pt}', 'CURRENT_DATE'))
    chk('Autorizados: zona nula', "'0'", azc('{v_u_coo}', 'NULL', 'CURRENT_DATE'))
    chk('Autorizados: fecha nula', "'0'", azc('{v_u_coo}', '{v_z_pt}', 'NULL'))
    chk('Autorizados: sede nula', "'0'", F('ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA', ['{v_u_coo}', 'NULL', '{v_z_pt}', 'CURRENT_DATE']))
    ae = lambda p, c: F('ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA', ['{v_u_coo}', '{v_ves}', '{v_z_pt}', 'CURRENT_DATE'], '"%s"' % c, 'WHERE "ID_Solicitud_Persona" = {%s}' % p)
    chk('Autorizados: estado de cada persona (salió, dentro, denegada, esperada)', "'SALIO/DENTRO/DENEGADA/ESPERADA'", ae('v_p1', 'Estado_Persona') + " || '/' || " + ae('v_p2', 'Estado_Persona') + " || '/' || " + ae('v_p4', 'Estado_Persona') + " || '/' || " + ae('v_p5', 'Estado_Persona'))
    chk('Autorizados: indica la restricción', "'Y/N'", ae('v_p3', 'Acceso_Restringido') + " || '/' || " + ae('v_p2', 'Acceso_Restringido'))
    chk('Autorizados: trae hora de ingreso de quien entró', "'si/(nulo)'", "CASE WHEN " + ae('v_p2', 'Fecha_Hora_Ingreso') + " <> '(nulo)' THEN 'si' ELSE 'no' END || '/' || " + ae('v_p5', 'Fecha_Hora_Ingreso'))

    L.append('    -- ===================================================== G. Coincidencia botón <-> procedimiento (incidencias)')
    raw(DEC('v_i1', "'CONFIRMAR'", user='v_u_vig'))
    chk('Coincide: botón apagado para Vigilancia = el SP rechaza (101)', "'N|101'", idt('{v_u_vig}', '{v_i1}', 'Puede_Decidir') + " || '|' || v_cod")
    raw(DEC('v_i1', "'CONFIRMAR'"))
    chk('Coincide: botón encendido para el Coordinador = el SP acepta (100)', "'100'", "v_cod::TEXT")
    chk('Coincide: después de decidirla el botón se apaga', "'N'", idt('{v_u_coo}', '{v_i1}', 'Puede_Decidir'))
    chk('Contadores: se actualizan', "'1/2/1'", ic('{v_u_coo}', 'Registradas') + " || '/' || " + ic('{v_u_coo}', 'Confirmadas') + " || '/' || " + ic('{v_u_coo}', 'Desestimadas'))

mode = sys.argv[2]
if mode == 'escritura':
    escritura()
    name = 'PRUEBAS_FASE1_HITO4_ESCRITURA.sql'
    prop = ('pruebas automáticas de los procedimientos de ESCRITURA del Hito 4:\n--   registrar y decidir incidencias, y la bandeja de correos (cola, envío, errores y reencolado).')
else:
    lectura()
    name = 'PRUEBAS_FASE1_HITO4_LECTURA.sql'
    prop = ('pruebas automáticas de las LECTURAS del Hito 4: incidencias (lista, detalle, personas,\n--   contadores, búsqueda de personas) y reporte de accesos (movimientos, resumen diario, autorizados por zona).\n--   Comprueba que el botón «Puede_Decidir» coincide con lo que de verdad hace el procedimiento.')
with open(out + '/' + name, 'w', encoding='utf-8') as fh:
    fh.write(HEAD.format(nombre=name, proposito=prop))
    fh.write('\n'.join(L) + '\n')
    fh.write(TAIL)
print(name, len(L), 'líneas')
