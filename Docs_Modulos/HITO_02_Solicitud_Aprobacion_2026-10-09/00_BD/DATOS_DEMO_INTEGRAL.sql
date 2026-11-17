-- =============================================================================
-- Archivo : DATOS_DEMO_INTEGRAL.sql   (OPCIONAL, solo pruebas; NO lo corre restaurar_bd.ps1)
-- Version : V1.0 2026-11-17
-- Requiere: scripts 01 a 35, todos los SP, y 11_SEED_DEMO_USUARIOS.sql. No necesita los otros demos: crea lo que le falta
--           (almacen1.demo, almacen2.demo, coordinador2.demo con clave Alma.Demo#2026) y da las licencias.
-- Que hace: carga 69 solicitudes de los TRES tipos con los procedimientos reales y personas de DNI 7600NNNN, repartidas en el
--           tiempo: PASADAS (hasta hace 10 dias, ya cerradas o historicas), de HOY (en curso) y PROGRAMADAS (hasta 14 dias adelante).
--           Las pasadas se crean hoy con los SP reales y luego se «envejecen» (se retroceden todas sus fechas), porque los SP no
--           aceptan fechas vencidas.
--   VISITA EXTERNA  VI01-VI22  pasadas: salio, con desviacion liberada, ingreso denegado, no se presento, retencion + incidencia
--                              confirmada/desestimada, rechazada, cancelada, aprobada parcial · hoy: dentro, salio, desviacion con conformidad
--                              pendiente, incidencia pendiente, pendiente, observada, parcial · programadas: aprobadas, pendientes, observada, cancelada.
--   CONTRATISTA     CI01-CI16  pasadas: franja completada, rechazada, cierre forzado, ingreso denegado, no vino · hoy: personas dentro / salieron / esperadas,
--                              dia agregado por el Coordinador, pendiente, observada, parcial · programadas: franjas de 1 a 5 dias, fuera de franja, cancelada.
--   PROVEEDOR 1 EMPRESA  PS01-PS18  pasadas: salio conforme / con observacion, ingreso denegado, no se presento, cierre forzado (queda DENTRO),
--                              rechazada, cancelada · hoy: programado, en espera (conforme / con desviacion), ingreso denegado, pendiente, observada
--                              · programadas: aprobadas con responsable de Almacen, pendiente, cancelada. Con chofer, ayudante y documentos adjuntos.
--   PROVEEDOR VARIAS EMPRESAS  PM01-PM13  (2, 3 o 4 empresas receptoras) pasadas: atendidas una por una y salio, con observacion, rechazada
--                              · hoy: programado, en espera, con desviacion, pendiente, observada y PM13 EN ATENCION (la 1.a empresa atendida y la 2.a
--                              en atencion: tiene la exclusa) · programadas: aprobadas, pendiente, observada.
--   Usuarios para verlo (todos @trianon.test, clave del script 11 / Alma.Demo#2026): solicitante1/2/3, coordinador, coordinador2,
--   vigilante1/2/3, almacen1/2 (.demo).
-- Es seguro correrlo UNA vez por base: si ya hay personas 7600NNNN se detiene. Para repetir, ejecute antes LIMPIAR_DEMO_INTEGRAL.sql.
-- Si otro demo dejo una entrega EN ATENCION (escenarios, proveedor, multiempresa), el script se detiene con un aviso: ejecute antes el LIMPIAR_DEMO_* de ese demo.
-- Nota: la exclusa (capacidad 1 por defecto) solo puede tener una entrega en atencion, por eso hay una sola «En atencion».
-- =============================================================================
BEGIN;
-- Hora de Lima: la app trabaja con Timezone=America/Lima (D-129). Sin esto, CURRENT_DATE usa la zona del servidor (UTC) y de noche cae en el dia siguiente.
SET LOCAL TIME ZONE 'America/Lima';
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

CREATE OR REPLACE FUNCTION pg_temp.ok(p_cod INT, p_msg TEXT, p_etq TEXT) RETURNS VOID LANGUAGE plpgsql AS $f$
BEGIN IF p_cod IS DISTINCT FROM 100 THEN RAISE EXCEPTION '[%] codigo %: %', p_etq, p_cod, p_msg; END IF; END $f$;

-- items del checklist: todo cumple salvo el codigo indicado (marca N)
CREATE OR REPLACE FUNCTION pg_temp.items(p_sp BIGINT, p_etapa TEXT, p_falla TEXT) RETURNS TEXT LANGUAGE sql AS $f$
  SELECT COALESCE(STRING_AGG(A."ID_Catalogo_Item_Checklist" || ':' || CASE WHEN A."Codigo" = p_falla THEN 'N' ELSE 'Y' END, ','), '')
  FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(p_sp, p_etapa, 'N', 'N') A $f$;

CREATE OR REPLACE FUNCTION pg_temp.trat(p_cod TEXT) RETURNS BIGINT LANGUAGE sql AS $f$
  SELECT "ID_Catalogo_Tratamiento_Desviacion" FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = p_cod $f$;

CREATE OR REPLACE FUNCTION pg_temp.tinc(p_cod TEXT) RETURNS BIGINT LANGUAGE sql AS $f$
  SELECT "ID_Catalogo_Tipo_Incidencia" FROM "Catalogo_Tipo_Incidencia" WHERE "Codigo" = p_cod $f$;

-- ---------------------------------------------------------------------------------------------------------------------
-- Desplaza hacia atras TODAS las fechas de una solicitud y de lo que cuelga de ella (dias, personas, eventos, accesos...).
-- Asi las solicitudes "pasadas" se crean con los procedimientos reales (que no aceptan fechas vencidas) y luego se envejecen.
CREATE TEMP TABLE tmp_int_vis (oid OID) ON COMMIT DROP;
CREATE OR REPLACE FUNCTION pg_temp.retro_r(p_oid regclass, p_cond TEXT, p_dias INT, p_prof INT) RETURNS VOID LANGUAGE plpgsql AS $f$
DECLARE r RECORD; c TEXT;
BEGIN
    IF p_prof > 8 THEN RETURN; END IF;
    IF EXISTS (SELECT 1 FROM tmp_int_vis WHERE oid = p_oid::OID) THEN RETURN; END IF;
    INSERT INTO tmp_int_vis VALUES (p_oid::OID);
    SELECT STRING_AGG(format('%I = %I - %L::INTERVAL', a.attname, a.attname, p_dias || ' days'), ', ') INTO c
      FROM pg_attribute a WHERE a.attrelid = p_oid AND a.attnum > 0 AND NOT a.attisdropped AND a.attgenerated = ''
       AND a.atttypid IN ('timestamp'::regtype, 'date'::regtype);
    IF c IS NOT NULL THEN EXECUTE format('UPDATE %s SET %s WHERE %s', p_oid, c, p_cond); END IF;
    FOR r IN SELECT c2.conrelid::regclass AS hija, a.attname AS col_hija, ra.attname AS col_padre
             FROM pg_constraint c2
             JOIN pg_attribute a  ON a.attrelid = c2.conrelid  AND a.attnum  = c2.conkey[1]
             JOIN pg_attribute ra ON ra.attrelid = c2.confrelid AND ra.attnum = c2.confkey[1]
             WHERE c2.contype = 'f' AND c2.confrelid = p_oid AND array_length(c2.conkey, 1) = 1 AND c2.conrelid <> p_oid
    LOOP
        PERFORM pg_temp.retro_r(r.hija, format('%I IN (SELECT %I FROM %s WHERE %s)', r.col_hija, r.col_padre, p_oid, p_cond), p_dias, p_prof + 1);
    END LOOP;
END $f$;
CREATE OR REPLACE FUNCTION pg_temp.retro(p_sol BIGINT, p_dias INT) RETURNS VOID LANGUAGE plpgsql AS $f$
BEGIN
    DELETE FROM tmp_int_vis;
    PERFORM pg_temp.retro_r('"CAF_Solicitud"'::regclass, format('"ID_Solicitud" = %s', p_sol), p_dias, 0);
END $f$;

-- ids de empresas del grupo a partir de letras: S=Sostenible, E=Energo, P=Power Technology, A=Ascensores (en el orden dado)
CREATE OR REPLACE FUNCTION pg_temp.emps2(p TEXT) RETURNS TEXT LANGUAGE sql AS $f$
    SELECT STRING_AGG(CAST(E."ID_Catalogo_Empresa_Grupo" AS TEXT), ',' ORDER BY X.ord)
      FROM UNNEST(STRING_TO_ARRAY(p, ',')) WITH ORDINALITY AS X(l, ord)
      JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" E ON E."Eliminado" = 'N' AND E."Codigo" =
           CASE X.l WHEN 'S' THEN 'TRIANON_SOSTENIBLE' WHEN 'E' THEN 'TRIANON_ENERGO' WHEN 'P' THEN 'POWER_TECHNOLOGY' WHEN 'A' THEN 'TRIANON_ASCENSORES' END $f$;

-- Lo que hace Porteria con UNA persona de visita/contratista segun su «plan»:
--   -  nada (queda esperada / no se presenta)   I  ingresa y queda DENTRO          IS  ingresa y sale
--   ILS igual que IL y luego sale     D  ingreso DENEGADO                          IL ingresa con desviacion liberada (conformidad dada)   ILP igual, conformidad pendiente
--   IRI ingresa y sale con RETENCION + incidencia confirmada   ISD ingresa/sale + incidencia desestimada   ISX ingresa/sale + incidencia pendiente
CREATE OR REPLACE FUNCTION pg_temp.accion(p_plan TEXT, p_sp BIGINT, p_ves BIGINT, p_vg BIGINT, p_co BIGINT, p_falla TEXT, p_txt TEXT) RETURNS VOID LANGUAGE plpgsql AS $f$
DECLARE v_r BIGINT; v_d BIGINT; v_x VARCHAR(30); v_cod INT; v_msg VARCHAR(250); v_cs VARCHAR(30);
BEGIN
    IF p_plan = '-' THEN RETURN; END IF;
    IF p_plan = 'D' THEN
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(p_sp,pg_temp.items(p_sp,'INGRESO','ING_IDENTIDAD'),'N','N',NULL,'El documento presentado no coincide con la solicitud.',p_co,pg_temp.trat('DENEGATORIA'),NULL,NULL,NULL,p_vg,v_r,v_d,v_x,v_cod,v_msg);
        PERFORM pg_temp.ok(v_cod,v_msg,'accion D'); RETURN;
    END IF;
    IF p_plan IN ('IL','ILP','ILS') THEN
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(p_sp,pg_temp.items(p_sp,'INGRESO',p_falla),'N','N',NULL,p_txt,p_co,pg_temp.trat('LIBERACION'),NULL,NULL,NULL,p_vg,v_r,v_d,v_x,v_cod,v_msg);
        PERFORM pg_temp.ok(v_cod,v_msg,'accion ingreso con desviacion');
        IF p_plan IN ('IL','ILS') THEN
            CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_d,'Conforme: el coordinador autorizo por correo.',p_co,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'accion conformidad');
        END IF;
    ELSE
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(p_sp,pg_temp.items(p_sp,'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,p_vg,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'accion ingreso');
    END IF;
    IF p_plan = 'IRI' THEN
        CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(p_sp,pg_temp.items(p_sp,'SALIDA','SAL_SIN_ELEMENTOS'),NULL,'Lleva una herramienta de la planta.',p_co,pg_temp.trat('RETENCION_ELEMENTO'),NULL,NULL,NULL,p_vg,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'accion salida retencion');
        CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(p_ves,pg_temp.tinc('HURTO'),NULL,LOCALTIMESTAMP-INTERVAL '30 minutes',NULL::BIGINT,'Almacen general','[DEMO-INT] Falta una herramienta tras la visita.',p_sp::TEXT,p_vg,v_r,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'accion inc hurto');
        CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_r,'CONFIRMAR','Se verifico con las camaras: la herramienta salio con la persona.',p_co,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'accion inc confirmar');
    ELSIF p_plan IN ('IS','ISD','ISX','ILS') THEN
        CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(p_sp,pg_temp.items(p_sp,'SALIDA',''),NULL,NULL,NULL,NULL,NULL,NULL,NULL,p_vg,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'accion salida');
        IF p_plan = 'ISD' THEN
            CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(p_ves,pg_temp.tinc('USO_NO_AUTORIZADO_AREA'),NULL,LOCALTIMESTAMP-INTERVAL '20 minutes',NULL::BIGINT,'Pasillo de produccion','[DEMO-INT] Se vio a un visitante fuera de su zona autorizada.',p_sp::TEXT,p_vg,v_r,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'accion inc area');
            CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_r,'DESESTIMAR','Se aclaro: iba acompanado por su responsable.',p_co,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'accion inc desestimar');
        ELSIF p_plan = 'ISX' THEN
            CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(p_ves,pg_temp.tinc('USO_NO_AUTORIZADO_EQUIPO'),NULL,LOCALTIMESTAMP-INTERVAL '10 minutes',NULL::BIGINT,'Oficinas','[DEMO-INT] Uso de un equipo sin autorizacion (pendiente de decision).',p_sp::TEXT,p_vg,v_r,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'accion inc equipo');
        END IF;
    END IF;
END $f$;

DO $$
DECLARE
    v_ves BIGINT; v_dni BIGINT; v_area BIGINT; v_emp BIGINT; v_empg BIGINT;
    t_ext BIGINT; t_ctr BIGINT; t_prov BIGINT; p_ext BIGINT; p_ctr BIGINT; p_prov BIGINT;
    v_zadm BIGINT; v_z1p BIGINT; v_mot BIGINT; v_hash TEXT := 'PBKDF2$SHA256$210000$plD+RU/Zn0negwQkCR/TdA==$aGG/NTy2AAA7MON8IT2iKnoDtuj/MWd4jb0mj+McOp4=';
    s1 BIGINT; s2 BIGINT; s3 BIGINT; c1 BIGINT; c2 BIGINT; vg1 BIGINT; vg2 BIGINT; vg3 BIGINT; a1 BIGINT; a2 BIGINT;
    pe_s1 BIGINT; pe_s2 BIGINT; pe_s3 BIGINT; pe_a1 BIGINT; pe_a2 BIGINT; pe_c2 BIGINT;
    v_ul BIGINT; v_cod INT; v_msg VARCHAR(250); v_cant BIGINT;
    v_id BIGINT; v_cs VARCHAR(30); v_r BIGINT; v_d BIGINT; v_x VARCHAR(30); v_n INT; v_ag INT;
    n INT := 0; v_hoy TIMESTAMP := CAST(CURRENT_DATE AS TIMESTAMP); v_h TEXT := TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD');
    v_m1 TEXT := TO_CHAR(CURRENT_DATE + 1, 'YYYY-MM-DD'); v_m2 TEXT := TO_CHAR(CURRENT_DATE + 2, 'YYYY-MM-DD');
    q1 BIGINT; q2 BIGINT; q3 BIGINT; sp1 BIGINT; sp2 BIGINT; sp3 BIGINT; k INT; v_tr TEXT;
    c_cf BIGINT; ids_p BIGINT[] := ARRAY_FILL(0::BIGINT, ARRAY[20]); sps_p BIGINT[] := ARRAY_FILL(0::BIGINT, ARRAY[20]); sps_a BIGINT[] := ARRAY_FILL(0::BIGINT, ARRAY[20]);
    nom TEXT[] := ARRAY['Ramos','Quispe','Flores','Torres','Castillo','Vargas','Medina','Rojas','Salazar','Herrera','Campos','Paredes'];
    pn  TEXT[] := ARRAY['Luis','Maria','Jorge','Ana','Pedro','Rosa','Hugo','Elena','Raul','Carla','Diego','Sofia'];
    paso_ext BIGINT; paso_ctr BIGINT; paso_prov BIGINT; v_pa BIGINT;
BEGIN
    IF EXISTS (SELECT 1 FROM "CAF_Persona_Externa" WHERE "Numero_Documento" ~ '^7600[0-9]{4}$') THEN
        RAISE EXCEPTION 'Ya hay datos del demo integral (DNI 7600NNNN). Ejecute antes LIMPIAR_DEMO_INTEGRAL.sql.';
    END IF;
    -- La exclusa es de uso exclusivo: si otro demo (escenarios, proveedor o multiempresa) dejo una entrega EN ATENCION, este no puede avanzar.
    IF EXISTS (SELECT 1 FROM "CAF_Exclusa" WHERE "ID_Solicitud_Actual" IS NOT NULL) OR EXISTS (SELECT 1 FROM "CAF_Solicitud_Atencion" WHERE "Estado" = 'EN_ATENCION' AND "Eliminado" = 'N') THEN
        RAISE EXCEPTION 'Hay una entrega ocupando la exclusa o en atencion (probablemente de otro demo). Terminela o ejecute antes el LIMPIAR_DEMO_* correspondiente y vuelva a correr este script.';
    END IF;
    SELECT "ID_Catalogo_Sede" INTO v_ves FROM "CAF_GOVERNANCE"."Catalogo_Sede" WHERE "Codigo" = 'VES';
    SELECT "ID_Catalogo_Tipo_Documento" INTO v_dni FROM "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" WHERE "Codigo" = 'DNI';
    SELECT MIN("ID_Catalogo_Area") INTO v_area FROM "CAF_GOVERNANCE"."Catalogo_Area";
    SELECT "ID_Catalogo_Tipo_Acceso" INTO t_ext  FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'VISITA_EXTERNA';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO t_ctr  FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'CONTRATISTA';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO t_prov FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'PROVEEDOR';
    SELECT "ID_Tipo_Acceso_Paso_Aprobacion" INTO paso_ext  FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "ID_Catalogo_Tipo_Acceso" = t_ext  AND "Eliminado" = 'N' LIMIT 1;
    SELECT "ID_Tipo_Acceso_Paso_Aprobacion" INTO paso_ctr  FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "ID_Catalogo_Tipo_Acceso" = t_ctr  AND "Eliminado" = 'N' LIMIT 1;
    SELECT "ID_Tipo_Acceso_Paso_Aprobacion" INTO paso_prov FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "ID_Catalogo_Tipo_Acceso" = t_prov AND "Eliminado" = 'N' LIMIT 1;
    SELECT "ID_Catalogo_Zona_Acceso" INTO v_zadm FROM "Catalogo_Zona_Acceso" WHERE "Codigo" = 'OFICINAS_ADM' AND "ID_Catalogo_Sede" = v_ves;
    SELECT "ID_Catalogo_Zona_Acceso" INTO v_z1p  FROM "Catalogo_Zona_Acceso" WHERE "Codigo" = 'OFICINA_1P' AND "ID_Catalogo_Sede" = v_ves;
    SELECT "ID_Catalogo_Motivo_Visita" INTO v_mot FROM "Catalogo_Motivo_Visita" WHERE "Codigo" = 'REUNION_COORDINACION';
    SELECT "ID_Catalogo_Empresa_Grupo" INTO v_empg FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "Codigo" = 'TRIANON_ENERGO';
    IF v_empg IS NULL THEN SELECT MIN("ID_Catalogo_Empresa_Grupo") INTO v_empg FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo"; END IF;
    SELECT MIN("ID_Catalogo_Empresa_Grupo") INTO v_emp FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo";

    SELECT "ID_Usuario", "ID_Personal" INTO s1, pe_s1 FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'solicitante1.demo@trianon.test';
    SELECT "ID_Usuario", "ID_Personal" INTO s2, pe_s2 FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'solicitante2.demo@trianon.test';
    SELECT "ID_Usuario", "ID_Personal" INTO s3, pe_s3 FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'solicitante3.demo@trianon.test';
    SELECT "ID_Usuario" INTO c1  FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'coordinador.demo@trianon.test';
    SELECT "ID_Usuario" INTO vg1 FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'vigilante1.demo@trianon.test';
    SELECT "ID_Usuario" INTO vg2 FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'vigilante2.demo@trianon.test';
    SELECT "ID_Usuario" INTO vg3 FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'vigilante3.demo@trianon.test';
    IF s1 IS NULL OR s2 IS NULL OR s3 IS NULL OR c1 IS NULL OR vg1 IS NULL OR vg2 IS NULL OR vg3 IS NULL THEN
        RAISE EXCEPTION 'Faltan los usuarios demo (script 11_SEED_DEMO_USUARIOS.sql).'; END IF;

    -- ---- Usuarios que faltan: almacen1/2 y coordinador2 (con ficha de Personal)
    FOR k IN 1..3 LOOP
        DECLARE v_mail TEXT := (ARRAY['almacen1.demo','almacen2.demo','coordinador2.demo'])[k] || '@trianon.test'; v_pe BIGINT; v_u BIGINT;
                v_dc TEXT := '9000004' || k; v_ap TEXT := (ARRAY['Almacen Uno','Almacen Dos','Dos'])[k]; v_no TEXT := (ARRAY['Alma','Ana','Coordinador'])[k];
        BEGIN
            SELECT "ID_Usuario", "ID_Personal" INTO v_u, v_pe FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = v_mail;
            IF v_u IS NULL THEN
                SELECT "ID_Personal" INTO v_pe FROM "CAF_GOVERNANCE"."Personal" WHERE "Correo" = v_mail;
                IF v_pe IS NULL THEN
                    INSERT INTO "CAF_GOVERNANCE"."Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","UsuarioID_Create")
                    VALUES (v_dni, v_dc, 'Demo', v_ap, v_no, v_area, v_emp, v_ves, v_mail, 0) RETURNING "ID_Personal" INTO v_pe;
                END IF;
                INSERT INTO "CAF_GOVERNANCE"."Usuario" ("Correo","ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","ID_Personal","Password_Hash","Password_Requiere_Cambio","UsuarioID_Create")
                VALUES (v_mail, v_dni, v_dc, 'Demo', v_ap, v_no, v_pe, v_hash, 'N', 0) RETURNING "ID_Usuario" INTO v_u;
            END IF;
            IF k = 1 THEN a1 := v_u; pe_a1 := v_pe; ELSIF k = 2 THEN a2 := v_u; pe_a2 := v_pe; ELSE c2 := v_u; pe_c2 := v_pe; END IF;
        END;
    END LOOP;

    -- ---- Licencias (si ya las tenia, el SP lo informa y se ignora)
    DECLARE r RECORD; v_lic BIGINT;
    BEGIN
        FOR r IN SELECT * FROM (VALUES
            (s1,'LIC_CAF_SOLICITANTE'),(s1,'LIC_CAF_SOLICITANTE_PROVEEDOR'),(s2,'LIC_CAF_SOLICITANTE'),(s2,'LIC_CAF_SOLICITANTE_PROVEEDOR'),
            (s3,'LIC_CAF_SOLICITANTE'),(s3,'LIC_CAF_SOLICITANTE_PROVEEDOR'),
            (c1,'LIC_CAF_COORDINADOR'),(c1,'LIC_CAF_COORD_PROVEEDOR'),(c1,'LIC_CAF_PROVEEDOR_DASHBOARD'),
            (c2,'LIC_CAF_COORDINADOR'),(c2,'LIC_CAF_COORD_PROVEEDOR'),(c2,'LIC_CAF_PROVEEDOR_DASHBOARD'),
            (vg1,'LIC_CAF_VIGILANCIA'),(vg1,'LIC_CAF_VIGILANCIA_PROVEEDOR'),(vg2,'LIC_CAF_VIGILANCIA'),(vg2,'LIC_CAF_VIGILANCIA_PROVEEDOR'),
            (vg3,'LIC_CAF_VIGILANCIA'),(vg3,'LIC_CAF_VIGILANCIA_PROVEEDOR'),(a1,'LIC_CAF_ALMACEN'),(a2,'LIC_CAF_ALMACEN')) AS t(u, l)
        LOOP
            SELECT "ID_Catalogo_Licencia" INTO v_lic FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = r.l;
            IF NOT EXISTS (SELECT 1 FROM "CAF_GOVERNANCE"."Usuario_Licencia" WHERE "ID_Usuario" = r.u AND "ID_Catalogo_Licencia" = v_lic AND "ID_Catalogo_Sede" = v_ves AND "Eliminado" = 'N') THEN
                CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(r.u, v_lic, v_ves, 0, v_ul, v_cod, v_msg);
                PERFORM pg_temp.ok(v_cod, v_msg, 'licencia ' || r.l);
            END IF;
        END LOOP;
    END;

    -- Empresas que atienden los almaceneros demo (sin esto no pueden iniciar/detener/terminar ninguna atencion)
    DECLARE v_ids TEXT; v_u BIGINT;
    BEGIN
        SELECT STRING_AGG(CAST("ID_Catalogo_Empresa_Grupo" AS TEXT), ',' ORDER BY "Orden") INTO v_ids FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "Eliminado" = 'N' AND "Activo" = 'Y';
        FOREACH v_u IN ARRAY ARRAY[a1, a2] LOOP
            CALL "ERP_CAF_ALMACEN_EMPRESA_GUARDAR"(v_u, v_ids, 0, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'empresas de almacen');
        END LOOP;
    END;

    -- =========================================================================================== MOTOR
    DECLARE
        r RECORD; kk INT := 0; np INT := 0; i INT; j INT; ne INT; u INT; cc INT;
        su BIGINT[] := ARRAY[s1,s2,s3]; spe BIGINT[] := ARRAY[pe_s1,pe_s2,pe_s3]; co BIGINT[] := ARRAY[c1,c2]; vg BIGINT[] := ARRAY[vg1,vg2,vg3];
        al BIGINT[] := ARRAY[a1,a2]; ape BIGINT[] := ARRAY[pe_a1,pe_a2];
        pq BIGINT[]; psp BIGINT[]; v_fecha TIMESTAMP; v_pers TEXT; v_sps TEXT; v_dias TEXT; v_zona BIGINT; v_plan TEXT; v_falla TEXT; v_txt TEXT;
        v_es TEXT; v_e TEXT; v_adj BIGINT; v_t_den BIGINT; v_t_rest BIGINT; v_vig BIGINT; v_alm BIGINT; v_sol BIGINT; v_coo BIGINT; v_pe BIGINT; v_nobs TEXT;
    BEGIN
        SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_den  FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'DENEGATORIA';
        SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_rest FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'RESTRICCION_ZONA_ADM';

        -- ======================================================================= VISITA EXTERNA (VI) y CONTRATISTA (CI)
        -- off: dia relativo a hoy (-N pasado, 0 hoy, +N futuro) · nd: dias de la franja (contratista) · dec: decision · plan: lo que hizo Porteria con cada persona
        FOR r IN SELECT * FROM (VALUES
            -- ---- pasadas
            ('V','VI01',-1, 10.0,1,2,'APR','IS,IS',   'Energia Verde S.A.C.',        'Reunion de coordinacion',          NULL,                  NULL),
            ('V','VI02',-2, 14.0,1,3,'APR','IS,IS,ILS','Soluciones Andinas S.A.',     'Presentacion de propuesta',        NULL,                  NULL),
            ('V','VI03',-3,  9.0,1,1,'APR','D',       'Servicios Rapidos',           'Entrega de documentos',            NULL,                  NULL),
            ('V','VI04',-4, 11.0,1,2,'APR','-,-',     'Eventos del Sur',             'Reunion (nadie se presento)',      NULL,                  NULL),
            ('V','VI05',-5, 15.0,1,2,'APR','IRI,ISD', 'Mantenimiento Industrial',    'Revision de equipos',              NULL,                  NULL),
            ('V','VI06',-6, 10.0,1,1,'RECH','-',      'Vendedores Libres',           'Visita comercial',                 NULL,                  NULL),
            ('V','VI07',-8, 16.0,1,1,'CANC','-',      'Reunion cancelada S.A.',      'Reunion reprogramada',             NULL,                  NULL),
            ('V','VI08',-10,10.0,1,3,'PARC','IS,-,-', 'Consultora Delta',            'Auditoria interna (aprobada parcial)', NULL,              NULL),
            -- ---- de hoy
            ('V','VI09', 0,  9.0,1,3,'APR','IS,I,-',  'Constructora del Pacifico',   'Inspeccion de obra',               NULL,                  NULL),
            ('V','VI10', 0, 10.0,1,2,'APR','ILP,-',   'Auditores Asociados',         'Auditoria (ingreso con desviacion pendiente)', NULL,      NULL),
            ('V','VI11', 0, 11.0,1,2,'APR','I,ISX',   'Capacitaciones Peru',         'Capacitacion con incidencia pendiente', NULL,             NULL),
            ('V','VI12', 0, 22.0,1,2,'APR','-,-',     'Logistica del Norte',         'Reunion de la tarde (aun no llegan)', NULL,               NULL),
            ('V','VI13', 0, 12.0,1,1,'PEND','-',      'Asesores Financieros',        'Reunion pendiente de aprobar',     NULL,                  NULL),
            ('V','VI14', 0, 13.0,1,2,'OBS','-',       'Tecnologia Aplicada',         'Demo de producto (observada)',     NULL,                  NULL),
            ('V','VI15', 0, 14.0,1,3,'PARC','I,-,-',  'Obras y Montajes',            'Visita tecnica (aprobada parcial)', NULL,                 NULL),
            -- ---- programadas
            ('V','VI16', 1, 10.0,1,2,'APR','-,-',     'Capacitaciones Peru',         'Reunion de manana',                NULL,                  NULL),
            ('V','VI17', 2,  9.0,1,1,'PEND','-',      'Inversiones Sur',             'Reunion pendiente de aprobar',     NULL,                  NULL),
            ('V','VI18', 3, 11.0,1,2,'APR','-,-',     'Seguros del Pacifico',        'Visita de seguros',                NULL,                  NULL),
            ('V','VI19', 5, 15.0,1,1,'OBS','-',       'Marketing Integral',          'Presentacion (observada)',         NULL,                  NULL),
            ('V','VI20', 7, 10.0,1,3,'APR','-,-,-',   'Ingenieria y Proyectos',      'Reunion de proyecto',              NULL,                  NULL),
            ('V','VI21',10,  9.0,1,1,'CANC','-',      'Turismo Andino',              'Visita cancelada',                 NULL,                  NULL),
            ('V','VI22',14, 10.0,1,2,'PEND','-,-',    'Importaciones Lima',          'Reunion del mes siguiente',        NULL,                  NULL),
            -- ---- contratistas pasados
            ('C','CI01',-4,  8.0,2,2,'APR','IS,IS',   'Montajes Electricos Lima S.A.C.','Cambio de tablero electrico',   'Sala de tableros',    '17:00'),
            ('C','CI02',-7,  8.0,3,1,'APR','IS',      'Pinturas y Acabados S.A.',    'Pintado de oficinas',              'Oficina primer piso', NULL),
            ('C','CI03',-2,  8.0,1,1,'RECH','-',      'Soldaduras del Norte',        'Soldadura en caliente',            'Taller',              NULL),
            ('C','CI04',-1,  7.5,2,1,'APR','I',       'Carpinteria Fina S.A.',       'Muebles de oficina (cierre forzado)','Oficina segundo piso',NULL),
            ('C','CI05',-3,  8.0,2,2,'APR','D,-',     'Seguridad Industrial SAC',    'Instalacion de camaras',           'Pasillos',            NULL),
            ('C','CI06',-6,  9.0,2,1,'APR','-',       'Gasfiteria Total E.I.R.L.',   'Reparacion de tuberias (no vino)', 'Banos administrativos',NULL),
            -- ---- contratistas de hoy
            ('C','CI07', 0,  8.0,4,3,'APR','IS,I,-',  'Techos y Coberturas SAC',     'Cambio de cobertura (se agrega un dia)','Techo del almacen','16:00'),
            ('C','CI08', 1,  8.0,2,1,'APR','IL',      'Electro Servicios SAC',       'Luminarias (llego un dia antes: fuera de franja)','Pasillos',NULL),
            ('C','CI09', 0,  8.0,2,2,'PEND','-',      'Limpieza Total SAC',          'Limpieza profunda',                'Oficinas',            NULL),
            ('C','CI10', 0,  9.0,2,1,'OBS','-',       'Jardineria Verde SAC',        'Mantenimiento de jardines',        'Exteriores',          NULL),
            ('C','CI11', 0,  8.0,3,2,'PARC','I,-',    'Mecanica Industrial SAC',     'Mantenimiento de montacargas',     'Patio',               NULL),
            -- ---- contratistas programados
            ('C','CI12', 2,  8.0,5,2,'APR','-,-',     'Obras Civiles del Sur SAC',   'Ampliacion de oficina',            'Oficina tercer piso', '17:00'),
            ('C','CI13', 3,  8.0,2,1,'PEND','-',      'Aire Frio SAC',               'Instalacion de aire acondicionado','Sala de reuniones',   NULL),
            ('C','CI14', 1,  8.0,3,1,'APR','-',       'Pinturas y Acabados S.A.',    'Pintado de fachada',               'Fachada',             NULL),
            ('C','CI15', 6,  8.0,4,1,'CANC','-',      'Vidrios y Aluminio SAC',      'Cambio de ventanas',               'Oficinas',            NULL),
            ('C','CI16', 4,  8.0,1,1,'RECH','-',      'Demoliciones Peru SAC',       'Demolicion de muro',               'Patio',               NULL)
        ) t(kind, cod, off, hora, nd, nper, dec, plan, emp, trabajo, lugar, hfin) LOOP
            kk := kk + 1; u := (kk % 3) + 1; cc := (kk % 2) + 1;
            v_zona := CASE WHEN kk % 2 = 0 THEN v_zadm ELSE v_z1p END;
            pq := ARRAY[]::BIGINT[];
            FOR i IN 1..r.nper LOOP
                np := np + 1;
                CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'7600'||LPAD(np::TEXT,4,'0'),nom[((np+kk) % 12)+1],nom[((np+kk+4) % 12)+1],pn[((np+2*kk) % 12)+1],0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' persona '||i);
                pq := pq || q1;
            END LOOP;
            v_pers := ARRAY_TO_STRING(pq, ',');
            IF r.kind = 'V' THEN
                v_fecha := v_hoy + (CASE WHEN r.off > 0 THEN r.off ELSE 0 END) * INTERVAL '1 day' + r.hora * INTERVAL '1 hour';
                CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,spe[u],v_fecha,r.emp,v_mot,NULL,r.cod||' '||r.trabajo,v_zona::TEXT,v_pers,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,su[u],v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' crear');
                v_pa := paso_ext;
            ELSE
                SELECT STRING_AGG(TO_CHAR(CURRENT_DATE + (CASE WHEN r.off > 0 THEN r.off ELSE 0 END) + g, 'YYYY-MM-DD'), ',' ORDER BY g) INTO v_dias FROM GENERATE_SERIES(0, r.nd - 1) g;
                CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves,NULL,r.emp,r.trabajo,r.cod||' '||r.trabajo,v_zona::TEXT,v_pers,NULL,NULL,NULL,NULL,r.lugar,'Contacto '||r.cod,'9'||LPAD((88000000+kk)::TEXT,8,'0'),'contacto'||kk||'@contratista.pe',v_dias,TO_CHAR(r.hora * INTERVAL '1 hour','HH24:MI'),r.hfin,su[u],v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' crear');
                v_pa := paso_ctr;
            END IF;
            psp := ARRAY[]::BIGINT[];
            FOR i IN 1..r.nper LOOP
                SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = pq[i];
                psp := psp || sp1;
            END LOOP;
            v_sps := ARRAY_TO_STRING(psp, ',');
            IF r.dec = 'APR' THEN
                CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,v_pa,'APROBADA',NULL,v_sps,co[cc],v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' aprobar');
            ELSIF r.dec = 'PARC' THEN
                CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,v_pa,'APROBADA',NULL,psp[1]::TEXT,co[cc],v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' aprobar 1');
                IF r.nper >= 2 THEN CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,v_pa,'OBSERVADA','Falta el segundo apellido; corrija y reenvie.',psp[2]::TEXT,co[cc],v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' observar 2'); END IF;
                IF r.nper >= 3 THEN CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,v_pa,'RECHAZADA','Persona con restriccion de acceso.',psp[3]::TEXT,co[cc],v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' rechazar 3'); END IF;
            ELSIF r.dec = 'OBS' THEN
                CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,v_pa,'OBSERVADA','Indique el detalle de la actividad y corrija los datos de las personas.',v_sps,co[cc],v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' observar');
            ELSIF r.dec = 'RECH' THEN
                CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,v_pa,'RECHAZADA','No hay autorizacion de seguridad para esa fecha.',v_sps,co[cc],v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' rechazar');
            ELSIF r.dec = 'CANC' THEN
                CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_id,'El solicitante reprogramo la actividad.',su[u],v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' cancelar');
            END IF;
            IF r.dec IN ('APR','PARC') THEN
                FOR i IN 1..r.nper LOOP
                    v_plan := COALESCE((STRING_TO_ARRAY(r.plan, ','))[i], '-');
                    v_falla := CASE WHEN r.kind = 'V' THEN 'ING_PERTENENCIAS' ELSE '' END;
                    v_txt := CASE WHEN r.kind = 'V' THEN 'Trae pertenencias no declaradas; el coordinador libera el ingreso.' ELSE 'Llega fuera de su franja autorizada; el coordinador libera el ingreso.' END;
                    PERFORM pg_temp.accion(v_plan, psp[i], v_ves, vg[((kk+i) % 3)+1], co[cc], v_falla, v_txt);
                END LOOP;
                IF r.cod = 'CI07' THEN
                    CALL "ERP_CAF_SOLICITUD_DIAS_EXTENDER"(v_id,TO_CHAR(CURRENT_DATE+5,'YYYY-MM-DD'),'08:00',NULL,'El cliente pidio un dia adicional por retraso de materiales.',co[cc],v_ag,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'CI07 extender');
                END IF;
            END IF;
            IF r.off < 0 THEN PERFORM pg_temp.retro(v_id, -r.off); END IF;
        END LOOP;

        -- ======================================================================= PROVEEDOR DE ABASTECIMIENTO (PS = 1 empresa, PM = varias)
        -- emps: letras de las empresas receptoras (S,E,P,A); flow: hasta donde llego la entrega; docs: documentos adjuntos
        -- Orden importa: la exclusa es una sola, por eso las que terminan van primero y la que queda EN ATENCION va al final.
        FOR r IN SELECT * FROM (VALUES
            -- ---- pasadas
            ('PS01',-1, 9.0,'E',    'APR','SALIO',    1,'Distribuidora Andina S.A.',     'Y'),
            ('PS02',-2,11.0,'S',    'APR','SALIO_OBS',0,'Insumos del Sur E.I.R.L.',      'N'),
            ('PS03',-3,13.0,'P',    'APR','DENEG',    0,'Ferreteria Industrial Norte',   'N'),
            ('PS04',-4,10.0,'A',    'APR','NOSHOW',   0,'Empaques Lima S.A.C.',          'Y'),
            ('PS05',-6, 8.5,'E',    'RECH','-',       0,'Maderas del Oriente S.A.C.',    'N'),
            ('PS06',-9,14.0,'S',    'CANC','-',       0,'Plasticos Unidos SAC',          'N'),
            ('PM01',-2,10.0,'S,E,P','APR','SALIO',    2,'Logistica Cordillera S.A.C.',   'Y'),
            ('PM02',-5, 9.0,'E,A',  'APR','SALIO_OBS',1,'Quimicos del Centro S.A.',      'N'),
            ('PM03',-4,15.0,'S,P',  'RECH','-',       0,'Aceros Peruanos S.A.',          'N'),
            ('PS07',-1,16.0,'P',    'APR','CIERRE',   0,'Repuestos Andes SAC',           'N'),
            -- ---- de hoy
            ('PS08', 0,16.5,'S',    'APR','PROG',     1,'Cables y Conductores SA',       'Y'),
            ('PS09', 0, 8.0,'E',    'APR','PROG',     0,'Envases Modernos SAC',          'N'),
            ('PS10', 0,11.0,'P',    'APR','ESPERA',   1,'Aceites Selectos SA',           'Y'),
            ('PS11', 0,13.0,'A',    'APR','ESPERA_DESV',0,'Pinturas Tricolor SAC',       'N'),
            ('PS12', 0,12.0,'S',    'APR','DENEG',    0,'Alimentos del Valle SAC',       'N'),
            ('PS13', 0,14.0,'E',    'PEND','-',       1,'Textiles del Sur SAC',          'N'),
            ('PS14', 0,15.0,'P',    'OBS','-',        0,'Bebidas Andinas SAC',           'N'),
            ('PM04', 0,16.0,'S,E,A','APR','PROG',     2,'Distribuidora del Centro SAC',  'Y'),
            ('PM05', 0, 9.5,'E,P,A','APR','ESPERA',   1,'Mayorista Pacifico SAC',        'N'),
            ('PM06', 0,10.5,'S,P',  'APR','ESPERA_DESV',0,'Comercial Altiplano SAC',     'N'),
            ('PM07', 0,14.5,'S,E',  'PEND','-',       1,'Importadora Norte SAC',         'N'),
            ('PM08', 0,15.5,'P,A',  'OBS','-',        0,'Suministros Tecnicos SAC',      'N'),
            -- ---- programadas
            ('PS15', 1,10.0,'S',    'APR','PROG',     1,'Ferreteria El Maestro SAC',     'Y'),
            ('PS16', 3, 9.0,'E',    'APR','PROG',     0,'Lubricantes del Peru SAC',      'N'),
            ('PS17', 6,11.0,'A',    'PEND','-',       1,'Herramientas Pro SAC',          'N'),
            ('PS18', 2,14.0,'P',    'CANC','-',       0,'Embalajes Rapidos SAC',         'N'),
            ('PM09', 1,11.0,'S,E',  'APR','PROG',     2,'Grupo Comercial Andino SAC',    'Y'),
            ('PM10', 4, 8.5,'E,P,A','APR','PROG',     1,'Abastecedora Lima SAC',         'N'),
            ('PM11', 8,10.0,'S,E,P,A','PEND','-',     1,'Mega Distribuciones SAC',       'N'),
            ('PM12', 5,13.0,'S,A',  'OBS','-',        0,'Servicios Logisticos SAC',      'N'),
            -- ---- la que ocupa la exclusa AHORA (va al final)
            ('PM13', 0, 8.5,'S,P',  'APR','ATENCION', 2,'Proveedora Integral SAC',       'Y')
        ) t(cod, off, hora, emps, dec, flow, docs, prov, prog) LOOP
            IF r.cod = 'PM13' THEN   -- antes de dejar a alguien EN ATENCION se cierran los dias vencidos (libera la exclusa de la entrega que se quedo dentro)
                CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(CURRENT_DATE,0,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'no se presento');
                CALL "ERP_CAF_PROVEEDOR_CIERRE_DIA"(0, v_n, v_cod, v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'cierre del dia');
            END IF;
            kk := kk + 1; u := (kk % 3) + 1; cc := (kk % 2) + 1;
            v_vig := vg[(kk % 3) + 1]; v_alm := al[(kk % 2) + 1]; v_sol := su[u]; v_coo := co[cc];
            v_es := pg_temp.emps2(r.emps);
            ne := CARDINALITY(STRING_TO_ARRAY(v_es, ','));
            np := np + 1;
            CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'7600'||LPAD(np::TEXT,4,'0'),'Chofer',nom[(kk % 12)+1],pn[(kk % 12)+1],0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' chofer');
            np := np + 1;
            CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'7600'||LPAD(np::TEXT,4,'0'),'Ayudante',nom[((kk+5) % 12)+1],pn[((kk+3) % 12)+1],0,q2,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' ayudante');
            v_tr := q1::TEXT||CHR(31)||'20456'||LPAD((70000+kk)::TEXT,6,'0')||CHR(31)||'Transportes '||r.prov||CHR(31)||'Av. Industrial '||kk||CHR(31)||'INT'||(100+kk)||CHR(31)||'Volvo'||CHR(31)||'Q77'||(1000+kk);
            v_fecha := v_hoy + (CASE WHEN r.off > 0 THEN r.off ELSE 0 END) * INTERVAL '1 day' + r.hora * INTERVAL '1 hour';
            CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_fecha, r.prov, r.cod||' - entrega para '||ne||CASE WHEN ne = 1 THEN ' empresa' ELSE ' empresas' END, q1||','||q2, NULL, NULL,
                  'Jefe de almacen '||kk, '9966'||LPAD(kk::TEXT,5,'0'), SPLIT_PART(v_es, ',', 1)::BIGINT, v_tr, 'OC-'||(88000+kk)||',OC-'||(89000+kk), NULL, NULL, NULL, v_sol, v_id, v_cs, v_cod, v_msg);
            PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' crear');
            IF ne > 1 THEN CALL "ERP_CAF_SOLICITUD_EMPRESAS_ASIGNAR"(v_id, v_es, v_coo, v_cod, v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' empresas'); END IF;
            FOR i IN 1..r.docs LOOP
                CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_id, CASE i WHEN 1 THEN 'Orden de compra OC-'||(88000+kk)||'.pdf' ELSE 'Guia de remision '||r.cod||'.pdf' END,
                      'application/pdf', convert_to('%PDF-1.4 demo integral '||r.cod||' doc '||i, 'UTF8'), v_sol, v_adj, v_cod, v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' adjunto');
            END LOOP;
            SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q1;
            SELECT "ID_Solicitud_Persona" INTO sp2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q2;
            IF r.dec = 'APR' THEN
                CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_prov,'APROBADA',NULL,sp1||','||sp2,v_coo,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' aprobar');
            ELSIF r.dec = 'OBS' THEN
                CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_prov,'OBSERVADA','Falta indicar la placa del vehiculo y el N.o de guia.',sp1||','||sp2,v_coo,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' observar');
            ELSIF r.dec = 'RECH' THEN
                CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_prov,'RECHAZADA','Entrega no programada con Almacen.',sp1||','||sp2,v_coo,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' rechazar');
            ELSIF r.dec = 'CANC' THEN
                CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_id,'El proveedor reprogramo la entrega.',v_sol,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' cancelar');
            END IF;
            IF r.dec = 'APR' AND (r.flow IN ('PROG','ESPERA','ESPERA_DESV') OR kk % 2 = 0) AND r.flow NOT IN ('NOSHOW') THEN
                SELECT "ID_Personal" INTO v_pe FROM "CAF_GOVERNANCE"."Usuario" WHERE "ID_Usuario" = al[((kk+1) % 2)+1];
                CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_id, v_pe, al[(kk % 2)+1], v_cod, v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' programar');
            END IF;
            IF r.flow IN ('ESPERA','SALIO','SALIO_OBS','CIERRE','ATENCION') THEN
                CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp1,pg_temp.items(sp1,'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,v_vig,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' verificar');
            ELSIF r.flow = 'ESPERA_DESV' THEN
                CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp1,pg_temp.items(sp1,'INGRESO','ING_EPP'),'N','N',NULL,'El conductor no porta el EPP completo; el coordinador autoriza el ingreso restringido a la zona administrativa.',v_coo,v_t_rest,NULL,NULL,NULL,v_vig,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' verificar con desviacion');
            ELSIF r.flow = 'DENEG' THEN
                CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp1,pg_temp.items(sp1,'INGRESO','ING_PLACA'),'N','N',NULL,'La placa del vehiculo no coincide con la solicitud; el coordinador deniega el ingreso.',v_coo,v_t_den,NULL,NULL,NULL,v_vig,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' denegar');
            END IF;
            IF r.flow IN ('SALIO','SALIO_OBS','CIERRE','ATENCION') THEN
                CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_id,v_alm,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' disponibilidad');
                CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_id,v_vig,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' ingreso');
                CALL "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(v_id,sp2::TEXT,pg_temp.items(sp2,'INGRESO',''),NULL,NULL,NULL,NULL,NULL,NULL,v_vig,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' verificar ayudante');
                CALL "ERP_CAF_PROVEEDOR_INGRESO_FISICO"(v_id,sp2::TEXT,v_vig,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' ayudante entra');
                FOR i IN 1..ne LOOP
                    v_e := (STRING_TO_ARRAY(v_es, ','))[i];
                    v_nobs := CASE WHEN r.flow = 'SALIO_OBS' AND i = ne THEN 'CON_OBSERVACION' ELSE 'CONFORME' END;
                    IF ne = 1 THEN
                        CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_id,v_alm,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' atender');
                        IF r.flow <> 'ATENCION' THEN CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_id,v_nobs,CASE WHEN v_nobs = 'CONFORME' THEN NULL ELSE 'Faltaron 2 cajas del pedido.' END,v_alm,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' recepcion'); END IF;
                    ELSE
                        CALL "ERP_CAF_PROVEEDOR_ATENDER_EMPRESA"(v_id,v_e::BIGINT,v_alm,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' atender '||i);
                        IF NOT (r.flow = 'ATENCION' AND i = ne) THEN CALL "ERP_CAF_PROVEEDOR_RECEPCION_EMPRESA"(v_id,v_e::BIGINT,v_nobs,CASE WHEN v_nobs = 'CONFORME' THEN NULL ELSE 'Faltaron 2 cajas del pedido.' END,v_alm,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' recepcion '||i); END IF;
                    END IF;
                END LOOP;
                IF r.flow IN ('SALIO','SALIO_OBS') THEN
                    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(sp1,pg_temp.items(sp1,'SALIDA',''),NULL,NULL,NULL,NULL,NULL,NULL,NULL,v_vig,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' salida');
                    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(sp2,pg_temp.items(sp2,'SALIDA',''),NULL,NULL,NULL,NULL,NULL,NULL,NULL,v_vig,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,r.cod||' salida ayudante');
                END IF;
            END IF;
            IF r.off < 0 THEN PERFORM pg_temp.retro(v_id, -r.off); END IF;
        END LOOP;

        -- ======================================================================= cierres del dia para lo que quedo en el pasado
        RAISE NOTICE 'Demo integral cargado: % solicitudes, % personas.', kk, np;
    END;
END $$;
COMMIT;
