-- =============================================================================
-- Archivo : DATOS_DEMO_ESCENARIOS.sql   (OPCIONAL, solo pruebas; NO lo corre restaurar_bd.ps1)
-- Version : V1.0 2026-11-09
-- Requiere: scripts 01 a 26, todos los SP, y 11_SEED_DEMO_USUARIOS.sql. (No necesita DATOS_DEMO_PROVEEDOR.sql: crea lo que le falta.)
-- Que hace: carga ~35 solicitudes de los tres tipos usando SOLO los procedimientos reales, con personas de DNI 7400NNNN:
--   Usuarios que crea si faltan (clave Alma.Demo#2026): almacen1.demo, almacen2.demo, coordinador2.demo (2.o Coordinador).
--   Licencias que da (sede VES): los 3 solicitantes (visita, contratista y proveedor), coordinador.demo y coordinador2.demo
--   (visita/contratista + proveedor), vigilante1/2/3 (accesos + proveedor), almacen1/2 (almacen).
--   VISITANTE EXTERNO (V01-V12): pendiente, observada, rechazada, aprobada, aprobada parcial, cancelada; personas ESPERADA, DENTRO,
--     SALIO, DENEGADA, NO_SE_PRESENTO; ingresos y salidas por vigilante1/2/3; desviaciones (liberacion, denegatoria, retencion de
--     elemento) con conformidad dada o pendiente; incidencias registrada / confirmada / desestimada; aprobaciones de los 2 coordinadores.
--   CONTRATISTA POR FRANJA (C01-C08): pendiente, observada, rechazada, aprobada con varios dias, persona que sale y vuelve a
--     ESPERADA, persona DENTRO, ingreso FUERA DE FRANJA con desviacion, dias agregados por el Coordinador, cierre forzado.
--   PROVEEDOR (P01-P14): pendiente, observada, rechazada, cancelada, programado (hoy/manana), en espera (conforme / con desviacion),
--     ingreso denegado, recepcion culminada (con la exclusa), salio, no se presento, cierre forzado; transportista con datos +
--     ayudante; responsable de almacen asignado (PROGRAMAR) y disponibilidad confirmada por almacen1 / almacen2.
-- Es seguro correrlo UNA vez por base: si ya hay datos 7400NNNN se detiene. Para repetir, ejecute antes LIMPIAR_DEMO_ESCENARIOS.sql.
-- Para verlo: entre como solicitante1/2/3.demo, coordinador.demo, coordinador2.demo, vigilante1/2/3.demo o almacen1/2.demo
--   (todos @trianon.test, clave del script 11 / Alma.Demo#2026).
-- =============================================================================
BEGIN;
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

CREATE FUNCTION pg_temp.ok(p_cod INT, p_msg TEXT, p_etq TEXT) RETURNS VOID LANGUAGE plpgsql AS $f$
BEGIN IF p_cod IS DISTINCT FROM 100 THEN RAISE EXCEPTION '[%] codigo %: %', p_etq, p_cod, p_msg; END IF; END $f$;

-- items del checklist: todo cumple salvo el codigo indicado (marca N)
CREATE FUNCTION pg_temp.items(p_sp BIGINT, p_etapa TEXT, p_falla TEXT) RETURNS TEXT LANGUAGE sql AS $f$
  SELECT COALESCE(STRING_AGG(A."ID_Catalogo_Item_Checklist" || ':' || CASE WHEN A."Codigo" = p_falla THEN 'N' ELSE 'Y' END, ','), '')
  FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(p_sp, p_etapa, 'N', 'N') A $f$;

CREATE FUNCTION pg_temp.trat(p_cod TEXT) RETURNS BIGINT LANGUAGE sql AS $f$
  SELECT "ID_Catalogo_Tratamiento_Desviacion" FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = p_cod $f$;

CREATE FUNCTION pg_temp.tinc(p_cod TEXT) RETURNS BIGINT LANGUAGE sql AS $f$
  SELECT "ID_Catalogo_Tipo_Incidencia" FROM "Catalogo_Tipo_Incidencia" WHERE "Codigo" = p_cod $f$;

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
    paso_ext BIGINT; paso_ctr BIGINT; paso_prov BIGINT;
BEGIN
    IF EXISTS (SELECT 1 FROM "CAF_Persona_Externa" WHERE "Numero_Documento" ~ '^7400[0-9]{4}$') THEN
        RAISE EXCEPTION 'Ya hay datos de escenarios (DNI 7400NNNN). Ejecute antes LIMPIAR_DEMO_ESCENARIOS.sql.';
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

    -- =========================================================================================== VISITANTE EXTERNO
    -- V01 pendiente
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000001','Ramos','Quispe','Luis',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V01 p1');
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000002','Quispe','Flores','Maria',0,q2,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V01 p2');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,pe_s1,v_hoy+INTERVAL '23 hours','Energia Verde S.A.C.',v_mot,NULL,'V01 pendiente',v_zadm::TEXT,q1||','||q2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,s1,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V01');

    -- V02 OBSERVADA (solicitante2): el coordinador observa al unico visitante
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000003','Flores','Torres','Pedro',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V02 p1');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,pe_s2,v_hoy+INTERVAL '1 day 10 hours','Soluciones Andinas S.A.',v_mot,NULL,'V02 observada',v_zadm::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,s2,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V02');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ext,'OBSERVADA','El DNI no coincide con el nombre; corrija y reenvie.',sp1::TEXT,c1,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V02 decidir');

    -- V03 RECHAZADA (solicitante3) por coordinador2
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000004','Torres','Castillo','Ana',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V03 p1');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,pe_s3,v_hoy+INTERVAL '1 day 11 hours','Vendedores Libres',v_mot,NULL,'V03 rechazada',v_z1p::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,s3,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V03');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ext,'RECHAZADA','Visita comercial no autorizada por seguridad.',sp1::TEXT,c2,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V03 decidir');

    -- V04 APROBADA (solicitante1, coord1): p1 entra y sale (vig1), p2 entra con DESVIACION liberada (vig1) y sigue DENTRO, p3 ESPERADA
    FOR k IN 1..3 LOOP
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'7400000'||(4+k),nom[k],nom[k+1],pn[k],0,v_r,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V04 persona');
        IF k = 1 THEN q1 := v_r; ELSIF k = 2 THEN q2 := v_r; ELSE q3 := v_r; END IF;
    END LOOP;
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,pe_s1,v_hoy+INTERVAL '23 hours','Constructora del Pacifico',v_mot,NULL,'V04 aprobada con ingresos y desviacion',v_zadm::TEXT,q1||','||q2||','||q3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,s1,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V04');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q1;
    SELECT "ID_Solicitud_Persona" INTO sp2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q2;
    SELECT "ID_Solicitud_Persona" INTO sp3 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q3;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ext,'APROBADA',NULL,sp1||','||sp2||','||sp3,c1,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V04 decidir');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp1,pg_temp.items(sp1,'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg1,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V04 ingreso1');
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(sp1,pg_temp.items(sp1,'SALIDA',''),NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg1,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V04 salida1');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp2,pg_temp.items(sp2,'INGRESO','ING_PERTENENCIAS'),'N','N',NULL,'Trae pertenencias no declaradas; el coordinador libera el ingreso.',c1,pg_temp.trat('LIBERACION'),NULL,NULL,NULL,vg1,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V04 ingreso2 desviacion');
    CALL "ERP_CAF_DESVIACION_CONFORMIDAD_DAR"(v_d,'Conforme: el coordinador autorizo por correo.',c1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V04 conformidad');

    -- V05 APROBADA (solicitante2, coord2): p1 DENTRO (vig2), p2 ESPERADA
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000008','Medina','Rojas','Hugo',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V05 p1');
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000009','Rojas','Salazar','Elena',0,q2,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V05 p2');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,pe_s2,v_hoy+INTERVAL '23 hours','Auditores Asociados',v_mot,NULL,'V05 aprobada una persona dentro',v_z1p::TEXT,q1||','||q2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,s2,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V05');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q1;
    SELECT "ID_Solicitud_Persona" INTO sp2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q2;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ext,'APROBADA',NULL,sp1||','||sp2,c2,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V05 decidir');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp1,pg_temp.items(sp1,'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg2,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V05 ingreso');

    -- V06 APROBADA_PARCIAL (solicitante3): p1 aprobada e ingresa (vig3), p2 observada, p3 rechazada
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000010','Salazar','Herrera','Raul',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V06 p1');
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000011','Herrera','Campos','Carla',0,q2,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V06 p2');
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000012','Campos','Paredes','Diego',0,q3,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V06 p3');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,pe_s3,v_hoy+INTERVAL '23 hours','Consultora Delta',v_mot,NULL,'V06 aprobada parcial',v_zadm::TEXT,q1||','||q2||','||q3,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,s3,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V06');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q1;
    SELECT "ID_Solicitud_Persona" INTO sp2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q2;
    SELECT "ID_Solicitud_Persona" INTO sp3 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q3;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ext,'APROBADA',NULL,sp1::TEXT,c1,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V06 aprobar');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ext,'OBSERVADA','Falta el segundo apellido.',sp2::TEXT,c1,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V06 observar');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ext,'RECHAZADA','Persona con restriccion de acceso.',sp3::TEXT,c1,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V06 rechazar');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp1,pg_temp.items(sp1,'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg3,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V06 ingreso');

    -- V07 APROBADA: ingreso DENEGADO por desviacion (vig2, coord2) -> persona DENEGADA
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000013','Paredes','Ramos','Sofia',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V07 p1');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,pe_s1,v_hoy+INTERVAL '23 hours','Servicios Rapidos',v_mot,NULL,'V07 ingreso denegado',v_zadm::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,s1,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V07');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ext,'APROBADA',NULL,sp1::TEXT,c2,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V07 decidir');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp1,pg_temp.items(sp1,'INGRESO','ING_IDENTIDAD'),'N','N',NULL,'El documento presentado no coincide con la solicitud.',c2,pg_temp.trat('DENEGATORIA'),NULL,NULL,NULL,vg2,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V07 denegado');

    -- V08 APROBADA con fecha de AYER: nadie llego -> NO_SE_PRESENTO
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000014','Ramos','Flores','Jorge',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V08 p1');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,pe_s2,v_hoy+INTERVAL '23 hours','Eventos del Sur',v_mot,NULL,'V08 no se presento',v_zadm::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,s2,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V08');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ext,'APROBADA',NULL,sp1::TEXT,c1,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V08 decidir');
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = v_hoy - INTERVAL '1 day' + INTERVAL '10 hours' WHERE "ID_Solicitud" = v_id;
    CALL "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR"(CURRENT_DATE,0,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V08 no se presento');

    -- V09 APROBADA: salida con RETENCION de elemento (vig2) + 3 incidencias (registrada, confirmada, desestimada)
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000015','Flores','Medina','Rosa',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09 p1');
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000016','Vargas','Rojas','Elena',0,q2,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09 p2');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,pe_s3,v_hoy+INTERVAL '23 hours','Mantenimiento Industrial',v_mot,NULL,'V09 retencion e incidencias',v_zadm::TEXT,q1||','||q2,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,s3,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q1;
    SELECT "ID_Solicitud_Persona" INTO sp2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q2;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ext,'APROBADA',NULL,sp1||','||sp2,c1,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09 decidir');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp1,pg_temp.items(sp1,'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg2,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09 ingreso1');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp2,pg_temp.items(sp2,'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg2,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09 ingreso2');
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(sp1,pg_temp.items(sp1,'SALIDA','SAL_SIN_ELEMENTOS'),NULL,'Lleva una herramienta de la planta.',c1,pg_temp.trat('RETENCION_ELEMENTO'),NULL,NULL,NULL,vg2,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09 salida retencion');
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves,pg_temp.tinc('HURTO'),NULL,LOCALTIMESTAMP-INTERVAL '30 minutes',NULL::BIGINT,'Almacen general','[DEMO-ESC] Falta una herramienta tras la visita de mantenimiento.',sp1::TEXT,vg2,v_r,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09 inc1');
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_r,'CONFIRMAR','Se verifico con las camaras: la herramienta salio con la persona.',c2,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09 inc1 confirmar');
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves,pg_temp.tinc('USO_NO_AUTORIZADO_AREA'),NULL,LOCALTIMESTAMP-INTERVAL '20 minutes',NULL,'Pasillo de produccion','[DEMO-ESC] Se vio a un visitante fuera de su zona autorizada.',sp2::TEXT,vg3,v_r,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09 inc2');
    CALL "ERP_CAF_INCIDENCIA_DECIDIR"(v_r,'DESESTIMAR','Se aclaro: iba acompanado por su responsable.',c1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09 inc2 desestimar');
    CALL "ERP_CAF_INCIDENCIA_REGISTRAR"(v_ves,pg_temp.tinc('USO_NO_AUTORIZADO_EQUIPO'),NULL,LOCALTIMESTAMP-INTERVAL '10 minutes',NULL,'Oficinas','[DEMO-ESC] Uso de un equipo sin autorizacion (pendiente de decision).',sp2::TEXT,vg1,v_r,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V09 inc3');

    -- V10 APROBADA para MANANA (coord2): todos ESPERADA
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000017','Medina','Quispe','Diego',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V10 p1');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,pe_s1,v_hoy+INTERVAL '1 day 15 hours','Capacitaciones Peru',v_mot,NULL,'V10 aprobada para manana',v_z1p::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,s1,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V10');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ext,'APROBADA',NULL,sp1::TEXT,c2,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V10 decidir');

    -- V11 CANCELADA por el solicitante
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000018','Rojas','Vargas','Maria',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V11 p1');
    CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves,t_ext,pe_s2,v_hoy+INTERVAL '2 days 9 hours','Reunion cancelada S.A.',v_mot,NULL,'V11 cancelada',v_zadm::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,s2,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V11');
    CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_id,'El visitante reprogramo su viaje.',s2,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'V11 cancelar');

    -- =========================================================================================== CONTRATISTA POR FRANJA
    -- C01 (solicitante1, coord1): hoy, +1 y +2, horas aproximadas; p1 entra y sale (vuelve a ESPERADA), p2 queda DENTRO; luego el Coordinador agrega un dia
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000019','Obrero','Uno','Anibal',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C01 p1');
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000020','Obrero','Dos','Beto',0,q2,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C01 p2');
    CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves,NULL,'Montajes Electricos Lima S.A.C.','Cambio de tablero electrico','C01 franja de 3 dias',v_zadm::TEXT,q1||','||q2,NULL,NULL,NULL,NULL,'Sala de tableros','Juan Perez','999888777','juan@montajes.pe',v_h||','||v_m1||','||v_m2,'08:00','17:00',s1,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C01');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q1;
    SELECT "ID_Solicitud_Persona" INTO sp2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q2;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ctr,'APROBADA',NULL,sp1||','||sp2,c1,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C01 decidir');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp1,pg_temp.items(sp1,'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg1,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C01 ingreso1');
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(sp1,pg_temp.items(sp1,'SALIDA',''),NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg1,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C01 salida1');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp2,pg_temp.items(sp2,'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg2,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C01 ingreso2');
    CALL "ERP_CAF_SOLICITUD_DIAS_EXTENDER"(v_id,TO_CHAR(CURRENT_DATE+4,'YYYY-MM-DD'),'08:00',NULL,'El cliente pidio un dia adicional por retraso de materiales.',c1,v_ag,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C01 extender');

    -- C02 PENDIENTE (solicitante2): dias sueltos
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000021','Pintor','Uno','Carlos',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C02 p1');
    CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves,NULL,'Pinturas y Acabados S.A.','Pintado de oficinas','C02 pendiente',v_z1p::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,'Oficina primer piso','Rosa Diaz','988777666','rosa@pinturas.pe',TO_CHAR(CURRENT_DATE+3,'YYYY-MM-DD')||','||TO_CHAR(CURRENT_DATE+5,'YYYY-MM-DD'),NULL,NULL,s2,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C02');

    -- C03 OBSERVADA (solicitante3)
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000022','Gasfitero','Uno','Daniel',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C03 p1');
    CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves,NULL,'Gasfiteria Total E.I.R.L.','Reparacion de tuberias','C03 observada',v_zadm::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,'Banos administrativos','Luis Soto','977666555','luis@gasfiteria.pe',v_m1||','||v_m2,'09:00',NULL,s3,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C03');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ctr,'OBSERVADA','Indique los trabajos y adjunte el SCTR vigente.',sp1::TEXT,c2,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C03 decidir');

    -- C04 RECHAZADA (solicitante1, coord2)
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000023','Soldador','Uno','Elias',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C04 p1');
    CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves,NULL,'Soldaduras del Norte','Soldadura en caliente','C04 rechazada',v_zadm::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,'Taller','Mario Vega','966555444','mario@soldaduras.pe',v_m2,NULL,NULL,s1,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C04');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ctr,'RECHAZADA','No hay permiso de trabajo en caliente para esa fecha.',sp1::TEXT,c2,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C04 decidir');

    -- C05 (solicitante2, coord2): dias manana y +2; hoy llega igual -> ingreso FUERA DE FRANJA con desviacion liberada
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000024','Electricista','Uno','Fausto',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C05 p1');
    CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves,NULL,'Electro Servicios SAC','Instalacion de luminarias','C05 fuera de franja',v_zadm::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,'Pasillos','Ana Ruiz','955444333','ana@electro.pe',v_m1||','||v_m2,NULL,NULL,s2,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C05');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ctr,'APROBADA',NULL,sp1::TEXT,c2,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C05 decidir');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp1,pg_temp.items(sp1,'INGRESO',''),'N','N',NULL,'Llega un dia antes de su franja autorizada; el coordinador libera el ingreso.',c2,pg_temp.trat('LIBERACION'),NULL,NULL,NULL,vg3,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C05 ingreso fuera de franja');

    -- C06 (solicitante3, coord1): hoy y manana; la persona ingresa y no sale; al final se corre su ingreso a ayer y el cierre del dia registra su salida forzada (vuelve a ESPERADA para manana)
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000025','Carpintero','Uno','Gaston',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C06 p1');
    CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves,NULL,'Carpinteria Fina S.A.','Muebles de oficina','C06 cierre forzado',v_z1p::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,'Oficina segundo piso','Eva Luna','944333222','eva@carpinteria.pe',v_h||','||v_m1,'07:30',NULL,s3,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C06');
    c_cf := v_id;
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ctr,'APROBADA',NULL,sp1::TEXT,c1,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C06 decidir');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sp1,pg_temp.items(sp1,'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg1,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C06 ingreso');

    -- C07 (solicitante1, coord1): una semana de lunes a viernes, aun nadie ingreso
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000026','Techista','Uno','Hector',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C07 p1');
    SELECT STRING_AGG(TO_CHAR(d,'YYYY-MM-DD'),',') INTO v_tr FROM GENERATE_SERIES(CURRENT_DATE + 1, CURRENT_DATE + 14, INTERVAL '1 day') g(d) WHERE EXTRACT(ISODOW FROM d) < 6;
    CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves,NULL,'Techos y Coberturas SAC','Cambio de cobertura','C07 dos semanas habiles',v_zadm::TEXT,q1::TEXT,NULL,NULL,NULL,NULL,'Techo del almacen','Raul Paz','933222111','raul@techos.pe',v_tr,'08:00','16:00',s1,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C07');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ctr,'APROBADA',NULL,sp1::TEXT,c1,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C07 decidir');

    -- C08 APROBADA_PARCIAL (solicitante2, coord2): p1 aprobada, p2 rechazada
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000027','Mecanico','Uno','Ivan',0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C08 p1');
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'74000028','Mecanico','Dos','Julio',0,q2,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C08 p2');
    CALL "ERP_CAF_SOLICITUD_CREAR_CONTRATISTA"(v_ves,NULL,'Mecanica Industrial SAC','Mantenimiento de montacargas','C08 aprobada parcial',v_zadm::TEXT,q1||','||q2,NULL,NULL,NULL,NULL,'Patio','Nora Gil','922111000','nora@mecanica.pe',v_m1||','||v_m2,NULL,NULL,s2,v_id,v_cs,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C08');
    SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q1;
    SELECT "ID_Solicitud_Persona" INTO sp2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q2;
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ctr,'APROBADA',NULL,sp1::TEXT,c2,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C08 aprobar');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_ctr,'RECHAZADA','Sin SCTR vigente.',sp2::TEXT,c2,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'C08 rechazar');

    -- =========================================================================================== PROVEEDOR
    FOR k IN 1..16 LOOP
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'7400'||LPAD((40+2*k-1)::TEXT,4,'0'),'Chofer',nom[(k % 12)+1],pn[(k % 12)+1],0,q1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P'||k||' chofer');
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'7400'||LPAD((40+2*k)::TEXT,4,'0'),'Ayudante',nom[((k+5) % 12)+1],pn[((k+3) % 12)+1],0,q2,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P'||k||' ayudante');
        v_tr := q1::TEXT||CHR(31)||'2034567890'||(k % 10)||CHR(31)||'Transportes '||nom[(k % 12)+1]||' SAC'||CHR(31)||'Av. Industrial '||k||CHR(31)||'ABC'||(100+k)||CHR(31)||'Volvo'||CHR(31)||'Q1234'||(1000+k);
        SELECT "ID_Catalogo_Empresa_Grupo" INTO v_empg FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "Codigo" = (ARRAY['TRIANON_SOSTENIBLE','TRIANON_ENERGO','POWER_TECHNOLOGY','TRIANON_ASCENSORES'])[(k % 4)+1];
        IF v_empg IS NULL THEN SELECT MIN("ID_Catalogo_Empresa_Grupo") INTO v_empg FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo"; END IF;
        CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_hoy + (ARRAY[16.5,8,11,13,9.5,8.5,7.5,12,10,14,15,15.5,9,6.5,7,10.5])[k] * INTERVAL '1 hour' + (CASE WHEN k = 9 THEN INTERVAL '1 day' ELSE INTERVAL '0' END),
              (ARRAY['Distribuidora Andina S.A.','Logistica Cordillera S.A.C.','Ferreteria Industrial Norte','Insumos del Sur E.I.R.L.','Proveedora Pacifico S.A.C.','Aceros Peruanos S.A.','Empaques Lima S.A.C.','Quimicos del Centro S.A.','Maderas del Oriente S.A.C.','Plasticos Unidos SAC','Repuestos Andes SAC','Cables y Conductores SA','Envases Modernos SAC','Aceites Selectos SA','Pinturas Tricolor SAC','Alimentos del Valle SA'])[k],
              'P'||LPAD(k::TEXT,2,'0'), q1||','||q2, NULL, NULL, 'Jefe de almacen '||k, '99911'||LPAD(k::TEXT,4,'0'), v_empg, v_tr, (ARRAY[s1,s2,s3])[(k % 3)+1], v_id, v_cs, v_cod, v_msg);
        PERFORM pg_temp.ok(v_cod,v_msg,'P'||k||' crear');
        SELECT "ID_Solicitud_Persona" INTO sp1 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q1;
        SELECT "ID_Solicitud_Persona" INTO sp2 FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_id AND "ID_Persona_Externa" = q2;
        ids_p[k] := v_id; sps_p[k] := sp1; sps_a[k] := sp2;
        IF k = 10 THEN NULL;                                    -- pendiente: nadie decide
        ELSIF k = 11 THEN CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_prov,'OBSERVADA','Falta indicar la placa de la unidad.',sp1||','||sp2,(ARRAY[c1,c2])[(k % 2)+1],v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P11 observar');
        ELSIF k = 12 THEN CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_prov,'RECHAZADA','Entrega no programada con Almacen.',sp1||','||sp2,c2,v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P12 rechazar');
        ELSIF k = 13 THEN CALL "ERP_CAF_SOLICITUD_CANCELAR"(v_id,'El proveedor reprogramo la entrega.',(ARRAY[s1,s2,s3])[(k % 3)+1],v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P13 cancelar');
        ELSE CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_id,paso_prov,'APROBADA',NULL,sp1||','||sp2,(ARRAY[c1,c2])[(k % 2)+1],v_cant,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P'||k||' aprobar');
        END IF;
    END LOOP;

    -- Responsable de almacen asignado (PROGRAMAR) en varias entregas
    FOREACH k IN ARRAY ARRAY[1,2,3,5,9] LOOP
        CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(ids_p[k], (ARRAY[pe_a1,pe_a2])[(k % 2)+1], (ARRAY[a1,a2])[((k+1) % 2)+1], v_cod, v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P'||k||' programar');
    END LOOP;

    -- Recorridos completos primero (la exclusa es una sola): 7 SALIO (vig2), 14 y 15 se cierran al final; 16 En atencion
    FOREACH k IN ARRAY ARRAY[7,14] LOOP
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sps_p[k],pg_temp.items(sps_p[k],'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,(ARRAY[vg1,vg2,vg3])[(k % 3)+1],v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P'||k||' verificar');
        CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(ids_p[k],(ARRAY[a1,a2])[(k % 2)+1],v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P'||k||' disponibilidad');
        CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(ids_p[k],(ARRAY[vg1,vg2,vg3])[(k % 3)+1],v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P'||k||' ingreso');
        CALL "ERP_CAF_PROVEEDOR_ATENDER"(ids_p[k],(ARRAY[a1,a2])[(k % 2)+1],v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P'||k||' atender');
        CALL "ERP_CAF_PROVEEDOR_RECEPCION"(ids_p[k],CASE WHEN k = 14 THEN 'CON_OBSERVACION' ELSE 'CONFORME' END,CASE WHEN k = 14 THEN 'Faltaron 2 cajas del pedido.' ELSE NULL END,(ARRAY[a1,a2])[(k % 2)+1],v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P'||k||' recepcion');
        IF k = 7 THEN
            CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(sps_p[k],pg_temp.items(sps_p[k],'SALIDA',''),NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg2,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P7 salida');
        END IF;
    END LOOP;
    -- 14: se queda abierta y su dia pasa -> CIERRE_FORZADO; 15: nunca se presento -> NO_SE_PRESENTO
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = "Fecha_Hora_Prevista" - INTERVAL '1 day' WHERE "ID_Solicitud" IN (ids_p[14], ids_p[15]);
    UPDATE "CAF_Solicitud_Dia" SET "Fecha" = CURRENT_DATE - 1 WHERE "ID_Solicitud" = c_cf AND "Fecha" = CURRENT_DATE;
    UPDATE "CAF_Solicitud_Persona" SET "Fecha_Hora_Ingreso" = "Fecha_Hora_Ingreso" - INTERVAL '1 day' WHERE "ID_Solicitud" = c_cf AND "Estado" = 'DENTRO';
    UPDATE "CAF_Registro_Acceso" SET "Fecha_Hora" = "Fecha_Hora" - INTERVAL '1 day' WHERE "ID_Solicitud_Persona" IN (SELECT "ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = c_cf);
    UPDATE "CAF_Solicitud" SET "Fecha_Hora_Prevista" = "Fecha_Hora_Prevista" - INTERVAL '1 day' WHERE "ID_Solicitud" = c_cf;
    CALL "ERP_CAF_PROVEEDOR_CIERRE_DIA"(0, v_n, v_cod, v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'cierre del dia');
    RAISE NOTICE 'Cierre del dia: % entregas/franjas cerradas', v_n;

    -- 4: verificada con DESVIACION autorizada (restriccion a zona administrativa); 3: verificada conforme; 8: ingreso denegado
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sps_p[3],pg_temp.items(sps_p[3],'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg1,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P3 verificar');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sps_p[4],pg_temp.items(sps_p[4],'INGRESO','ING_EPP'),'N','N',NULL,'El transportista no porta el EPP completo; el coordinador autoriza el ingreso restringido a la zona administrativa.',c1,pg_temp.trat('RESTRICCION_ZONA_ADM'),NULL,NULL,NULL,vg2,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P4 verificar con desviacion');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sps_p[8],pg_temp.items(sps_p[8],'INGRESO','ING_PLACA'),'N','N',NULL,'La placa no coincide con la solicitud; el coordinador deniega el ingreso.',c2,pg_temp.trat('DENEGATORIA'),NULL,NULL,NULL,vg3,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P8 denegado');
    -- 5: verificada (En espera; la disponibilidad la confirma Almacen en vivo: la exclusa la tiene la 16)
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sps_p[5],pg_temp.items(sps_p[5],'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg3,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P5 verificar');
    -- 16: En atencion (tiene la exclusa)
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(sps_p[16],pg_temp.items(sps_p[16],'INGRESO',''),'N','N',NULL,NULL,NULL,NULL,NULL,NULL,NULL,vg1,v_r,v_d,v_x,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P16 verificar');
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(ids_p[16],a1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P16 disponibilidad');
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(ids_p[16],vg1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P16 ingreso');
    CALL "ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO"(ids_p[16],sps_a[16]::TEXT,pg_temp.items(sps_a[16],'INGRESO',''),NULL,NULL,NULL,NULL,NULL,NULL,vg1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P16 verificar ayudante');
    CALL "ERP_CAF_PROVEEDOR_INGRESO_FISICO"(ids_p[16],sps_a[16]::TEXT,vg1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P16 ayudante entra');
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(ids_p[16],a1,v_cod,v_msg); PERFORM pg_temp.ok(v_cod,v_msg,'P16 atender');

    RAISE NOTICE 'Escenarios cargados.';
END $$;
COMMIT;
