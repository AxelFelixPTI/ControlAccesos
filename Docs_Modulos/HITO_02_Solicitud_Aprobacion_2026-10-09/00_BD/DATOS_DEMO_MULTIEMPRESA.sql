-- =============================================================================
-- Archivo : DATOS_DEMO_MULTIEMPRESA.sql   (OPCIONAL, solo pruebas; NO lo corre restaurar_bd.ps1)
-- Version : V1.0 2026-11-16 (D-246)
-- Requiere: scripts 01 a 34, todos los SP, y 11_SEED_DEMO_USUARIOS.sql. No necesita los otros demos: si faltan almacen1.demo y
--           almacen2.demo los crea (clave Alma.Demo#2026) con su licencia y sus empresas; las licencias de proveedor las da si faltan.
-- Que hace: carga 11 entregas de PROVEEDOR de HOY (y una de manana) que reciben mercaderia para MAS DE UNA empresa del grupo
--           (2, 3 o 4 empresas), con los procedimientos reales y personas de DNI 7500NNNN. Sirve para probar: la atencion empresa
--           por empresa, los cupos, «Pausada», el panel de cupos, la salida y, para Almacen, el boton «Ver solicitud» (solo lectura,
--           con los documentos adjuntos, que varias entregas traen).
--   M01 Programado 16:30        2 empresas (Sostenible + Energo)                   con 2 documentos
--   M02 Programado 08:00        3 empresas (hora vencida, sin verificar)           con 1 documento
--   M03 En espera 11:00         4 empresas (datos verificados)                     con 2 documentos
--   M04 En espera 13:00         2 empresas (verificada con DESVIACION autorizada)
--   M05 En espera 09:30         3 empresas (datos verificados, responsable de Almacen asignado)
--   M06 En atencion 08:30       2 empresas: la 1.a ya ATENDIDA y la 2.a EN ATENCION (almacen1)   <- tiene la exclusa
--   M07 Salio 07:30             3 empresas atendidas una por una y salida registrada            con 1 documento
--   M08 Ingreso denegado 12:00  2 empresas (placa no coincide, el coordinador deniega)
--   M09 Programado manana 10:00 2 empresas
--   M10 Pendiente de aprobar    2 empresas (nadie ha decidido)                     con 1 documento
--   M11 Observada               3 empresas (Coordinacion pide corregir)
-- Es seguro correrlo UNA vez por base: si ya hay personas 7500NNNN se detiene. Para repetir, ejecute antes LIMPIAR_DEMO_MULTIEMPRESA.sql.
-- Para verlo: almacen1.demo / almacen2.demo (calendario de proveedores, «Ver solicitud»), coordinador.demo, vigilante1.demo, solicitante1.demo.
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

-- ids de empresas del grupo (por codigo) en el orden pedido, separados por coma
CREATE OR REPLACE FUNCTION pg_temp.emps(VARIADIC p_cods TEXT[]) RETURNS TEXT LANGUAGE sql AS $f$
    SELECT STRING_AGG(CAST(E."ID_Catalogo_Empresa_Grupo" AS TEXT), ',' ORDER BY X.ord)
      FROM UNNEST(p_cods) WITH ORDINALITY AS X(cod, ord)
      JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" E ON E."Codigo" = X.cod AND E."Eliminado" = 'N' $f$;

DO $$
DECLARE
    v_ves BIGINT; v_dni BIGINT; v_area BIGINT; v_emp BIGINT; v_prov BIGINT; v_paso BIGINT;
    v_sol BIGINT; v_coo BIGINT; v_vig BIGINT; v_al1 BIGINT; v_al2 BIGINT; v_pe BIGINT; v_ul BIGINT;
    l_sp BIGINT; l_cp BIGINT; l_vp BIGINT; l_al BIGINT; l_da BIGINT;
    v_cod INT; v_msg VARCHAR(250); v_cant BIGINT;
    v_q1 BIGINT; v_q2 BIGINT; v_s BIGINT; v_cs VARCHAR(20); v_it TEXT; v_r BIGINT; v_d BIGINT; v_x VARCHAR(30); v_tr TEXT;
    v_ids BIGINT[] := ARRAY[]::BIGINT[]; v_sps BIGINT[] := ARRAY[]::BIGINT[]; v_spa BIGINT[] := ARRAY[]::BIGINT[]; v_es TEXT[] := ARRAY[]::TEXT[];
    v_adj BIGINT; v_e TEXT; v_nuevos BIGINT[] := ARRAY[]::BIGINT[]; v_t_den BIGINT; v_t_rest BIGINT; k INT; i INT;
    v_h TIMESTAMP := CAST(CURRENT_DATE AS TIMESTAMP);
    v_hash TEXT := 'PBKDF2$SHA256$210000$plD+RU/Zn0negwQkCR/TdA==$aGG/NTy2AAA7MON8IT2iKnoDtuj/MWd4jb0mj+McOp4=';
    -- por entrega: dia (0 hoy, 1 manana), hora, empresas, n.o de documentos, proveedor
    dia   INT[]     := ARRAY[0,0,0,0,0,0,0,0,1,0,0];
    hora  NUMERIC[] := ARRAY[16.5,8,11,13,9.5,8.5,7.5,12,10,14,15];
    emps  TEXT[]    := ARRAY[
        pg_temp.emps('TRIANON_SOSTENIBLE','TRIANON_ENERGO'),
        pg_temp.emps('TRIANON_SOSTENIBLE','TRIANON_ENERGO','POWER_TECHNOLOGY'),
        pg_temp.emps('TRIANON_SOSTENIBLE','TRIANON_ENERGO','POWER_TECHNOLOGY','TRIANON_ASCENSORES'),
        pg_temp.emps('POWER_TECHNOLOGY','TRIANON_ASCENSORES'),
        pg_temp.emps('TRIANON_ENERGO','POWER_TECHNOLOGY','TRIANON_ASCENSORES'),
        pg_temp.emps('TRIANON_SOSTENIBLE','TRIANON_ASCENSORES'),
        pg_temp.emps('TRIANON_SOSTENIBLE','TRIANON_ENERGO','POWER_TECHNOLOGY'),
        pg_temp.emps('TRIANON_ENERGO','TRIANON_ASCENSORES'),
        pg_temp.emps('POWER_TECHNOLOGY','TRIANON_SOSTENIBLE'),
        pg_temp.emps('TRIANON_ASCENSORES','TRIANON_ENERGO'),
        pg_temp.emps('TRIANON_SOSTENIBLE','POWER_TECHNOLOGY','TRIANON_ASCENSORES')];
    docs  INT[]     := ARRAY[2,1,2,0,0,0,1,0,0,1,0];
    prov  TEXT[]    := ARRAY['Distribuidora Andina S.A.','Logistica Cordillera Blanca S.A.C.','Ferreteria Industrial Norte','Insumos del Sur E.I.R.L.','Proveedora Pacifico S.A.C.','Aceros Peruanos S.A.','Empaques Lima S.A.C.','Quimicos del Centro S.A.','Maderas del Oriente S.A.C.','Plasticos Unidos S.A.C.','Repuestos Andinos S.A.'];
BEGIN
    IF EXISTS (SELECT 1 FROM "CAF_Persona_Externa" WHERE "Numero_Documento" ~ '^7500[0-9]{4}$') THEN
        RAISE EXCEPTION 'Los datos de demostracion multiempresa ya se cargaron. Ejecute antes LIMPIAR_DEMO_MULTIEMPRESA.sql.';
    END IF;
    SELECT "ID_Catalogo_Sede" INTO v_ves FROM "CAF_GOVERNANCE"."Catalogo_Sede" WHERE "Codigo" = 'VES';
    SELECT "ID_Catalogo_Tipo_Documento" INTO v_dni FROM "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" WHERE "Codigo" = 'DNI';
    SELECT MIN("ID_Catalogo_Area") INTO v_area FROM "CAF_GOVERNANCE"."Catalogo_Area";
    SELECT MIN("ID_Catalogo_Empresa_Grupo") INTO v_emp FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo";
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_prov FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'PROVEEDOR';
    SELECT "ID_Tipo_Acceso_Paso_Aprobacion" INTO v_paso FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "ID_Catalogo_Tipo_Acceso" = v_prov AND "Eliminado" = 'N' LIMIT 1;
    SELECT "ID_Usuario" INTO v_sol FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'solicitante1.demo@trianon.test';
    SELECT "ID_Usuario" INTO v_coo FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'coordinador.demo@trianon.test';
    SELECT "ID_Usuario" INTO v_vig FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'vigilante1.demo@trianon.test';
    IF v_sol IS NULL OR v_coo IS NULL OR v_vig IS NULL THEN RAISE EXCEPTION 'Faltan los usuarios demo (script 11).'; END IF;
    SELECT "ID_Catalogo_Licencia" INTO l_sp FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_SOLICITANTE_PROVEEDOR';
    SELECT "ID_Catalogo_Licencia" INTO l_cp FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_COORD_PROVEEDOR';
    SELECT "ID_Catalogo_Licencia" INTO l_vp FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_VIGILANCIA_PROVEEDOR';
    SELECT "ID_Catalogo_Licencia" INTO l_al FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_ALMACEN';
    SELECT "ID_Catalogo_Licencia" INTO l_da FROM "CAF_GOVERNANCE"."Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_PROVEEDOR_DASHBOARD';

    -- 1. Almaceneros demo: se crean solo si faltan (con ficha de Personal y todas las empresas del grupo)
    FOR i IN 1..2 LOOP
        v_e := 'almacen' || i || '.demo@trianon.test';
        IF NOT EXISTS (SELECT 1 FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = v_e) THEN
            INSERT INTO "CAF_GOVERNANCE"."Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","UsuarioID_Create")
            VALUES (v_dni,'9000003' || i,'Demo',CASE i WHEN 1 THEN 'Almacen Uno' ELSE 'Almacen Dos' END,CASE i WHEN 1 THEN 'Alma' ELSE 'Ana' END,v_area,v_emp,v_ves,v_e,0) RETURNING "ID_Personal" INTO v_pe;
            INSERT INTO "CAF_GOVERNANCE"."Usuario" ("Correo","ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","ID_Personal","Password_Hash","Password_Requiere_Cambio","UsuarioID_Create")
            VALUES (v_e,v_dni,'9000003' || i,'Demo',CASE i WHEN 1 THEN 'Almacen Uno' ELSE 'Almacen Dos' END,CASE i WHEN 1 THEN 'Alma' ELSE 'Ana' END,v_pe,v_hash,'N',0) RETURNING "ID_Usuario" INTO v_x;
            v_nuevos := v_nuevos || v_x::BIGINT;
        END IF;
    END LOOP;
    SELECT "ID_Usuario" INTO v_al1 FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'almacen1.demo@trianon.test';
    SELECT "ID_Usuario" INTO v_al2 FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'almacen2.demo@trianon.test';

    -- 2. Licencias (si el usuario ya la tiene, el procedimiento lo avisa y no pasa nada)
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_sol, l_sp, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_sol, l_da, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_coo, l_cp, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_coo, l_da, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_vig, l_vp, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_vig, l_da, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_al1, l_al, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_al2, l_al, v_ves, 0, v_ul, v_cod, v_msg);

    -- Los almaceneros recien creados atienden todas las empresas del grupo (sin esto no podrian iniciar ninguna atencion)
    SELECT STRING_AGG(CAST("ID_Catalogo_Empresa_Grupo" AS TEXT), ',') INTO v_tr FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "Eliminado" = 'N' AND "Activo" = 'Y';
    FOREACH v_adj IN ARRAY v_nuevos LOOP
        CALL "ERP_CAF_ALMACEN_EMPRESA_GUARDAR"(v_adj, v_tr, 0, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'empresas de almacenero ' || v_adj);
    END LOOP;

    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_den  FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'DENEGATORIA';
    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_rest FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'RESTRICCION_ZONA_ADM';

    -- 3. Entregas: chofer + ayudante, empresas receptoras (las asigna el Coordinador), documentos y decision
    FOR k IN 1..11 LOOP
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni, '7500' || LPAD((2*k-1)::TEXT, 4, '0'), 'Chofer', 'Multi ' || k, 'Marco', 0, v_q1, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' chofer');
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni, '7500' || LPAD((2*k)::TEXT, 4, '0'), 'Ayudante', 'Multi ' || k, 'Luis', 0, v_q2, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' ayudante');
        v_tr := v_q1::TEXT || CHR(31) || '204567' || LPAD(k::TEXT, 5, '0') || CHR(31) || 'Transportes ' || prov[k] || CHR(31) || 'Av. Industrial ' || k || CHR(31) || 'MUL' || (100 + k) || CHR(31) || 'Volvo' || CHR(31) || 'Q55' || (1000 + k);
        CALL "ERP_CAF_SOLICITUD_CREAR_PROVEEDOR"(v_ves, v_h + dia[k] * INTERVAL '1 day' + hora[k] * INTERVAL '1 hour', prov[k],
              'M' || LPAD(k::TEXT, 2, '0') || ' - entrega para ' || (LENGTH(emps[k]) - LENGTH(REPLACE(emps[k], ',', '')) + 1) || ' empresas', v_q1 || ',' || v_q2, NULL, NULL,
              'Jefe de almacen ' || k, '9955' || LPAD(k::TEXT, 5, '0'), SPLIT_PART(emps[k], ',', 1)::BIGINT, v_tr, 'OC-' || (77000 + k) || ',OC-' || (78000 + k), NULL, NULL, NULL, v_sol, v_s, v_cs, v_cod, v_msg);
        PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' crear');
        CALL "ERP_CAF_SOLICITUD_EMPRESAS_ASIGNAR"(v_s, emps[k], v_coo, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' empresas');
        FOR i IN 1..docs[k] LOOP
            CALL "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR"(v_s, CASE i WHEN 1 THEN 'Orden de compra OC-' || (77000 + k) || '.pdf' ELSE 'Guia de remision M' || LPAD(k::TEXT, 2, '0') || '.pdf' END,
                  'application/pdf', convert_to('%PDF-1.4 demo multiempresa M' || k || ' doc ' || i, 'UTF8'), v_sol, v_adj, v_cod, v_msg);
            PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' adjunto');
        END LOOP;
        SELECT "ID_Solicitud_Persona" INTO v_r FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_s AND "ID_Persona_Externa" = v_q1;
        SELECT "ID_Solicitud_Persona" INTO v_d FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_s AND "ID_Persona_Externa" = v_q2;
        v_ids := v_ids || v_s; v_sps := v_sps || v_r; v_spa := v_spa || v_d; v_es := v_es || emps[k];
        IF k = 10 THEN NULL;                                                   -- pendiente: nadie decide
        ELSIF k = 11 THEN
            CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s, v_paso, 'OBSERVADA', 'Falta indicar la placa del vehiculo y el N.o de guia.', v_r || ',' || v_d, v_coo, v_cant, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M11 observar');
        ELSE
            CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s, v_paso, 'APROBADA', NULL, v_r || ',' || v_d, v_coo, v_cant, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' aprobar');
        END IF;
    END LOOP;

    -- 4. Responsable de Almacen asignado en algunas entregas
    FOREACH k IN ARRAY ARRAY[1,3,5,9] LOOP
        SELECT "ID_Personal" INTO v_pe FROM "CAF_GOVERNANCE"."Usuario" WHERE "ID_Usuario" = (CASE WHEN k % 2 = 1 THEN v_al1 ELSE v_al2 END);
        CALL "ERP_CAF_PROVEEDOR_PROGRAMAR"(v_ids[k], v_pe, (CASE WHEN k % 2 = 1 THEN v_al2 ELSE v_al1 END), v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' programar');
    END LOOP;

    -- 5. Recorridos. La exclusa es una sola: primero la M07 (termina y sale), despues la M06 (queda en atencion con la exclusa).
    FOREACH k IN ARRAY ARRAY[7,6] LOOP
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sps[k], pg_temp.items(v_sps[k], 'INGRESO', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' verificar');
        CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_ids[k], v_al1, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' disponibilidad');
        CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_ids[k], v_vig, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' ingreso');
        FOR i IN 1..CARDINALITY(STRING_TO_ARRAY(v_es[k], ',')) LOOP
            v_e := (STRING_TO_ARRAY(v_es[k], ','))[i];
            IF k = 6 AND i = 2 THEN
                CALL "ERP_CAF_PROVEEDOR_ATENDER_EMPRESA"(v_ids[k], v_e::BIGINT, v_al1, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M6 atender 2.a empresa');
            ELSE
                CALL "ERP_CAF_PROVEEDOR_ATENDER_EMPRESA"(v_ids[k], v_e::BIGINT, v_al1, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' atender');
                CALL "ERP_CAF_PROVEEDOR_RECEPCION_EMPRESA"(v_ids[k], v_e::BIGINT, 'CONFORME', NULL, v_al1, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' recepcion');
            END IF;
        END LOOP;
        IF k = 7 THEN
            CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_sps[k], pg_temp.items(v_sps[k], 'SALIDA', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M7 salida');
        END IF;
    END LOOP;

    -- En espera: 3 y 5 conformes, 4 con desviacion autorizada; 8 con ingreso denegado
    FOREACH k IN ARRAY ARRAY[3,5] LOOP
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sps[k], pg_temp.items(v_sps[k], 'INGRESO', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg); PERFORM pg_temp.ok(v_cod, v_msg, 'M' || k || ' verificar');
    END LOOP;
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sps[4], pg_temp.items(v_sps[4], 'INGRESO', 'ING_EPP'), 'N', 'N', NULL, 'El conductor no porta el EPP completo; el coordinador autoriza el ingreso restringido a la zona administrativa.', v_coo, v_t_rest, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg);
    PERFORM pg_temp.ok(v_cod, v_msg, 'M4 verificar con desviacion');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sps[8], pg_temp.items(v_sps[8], 'INGRESO', 'ING_PLACA'), 'N', 'N', NULL, 'La placa del vehiculo no coincide con la solicitud; el coordinador deniega el ingreso.', v_coo, v_t_den, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg);
    PERFORM pg_temp.ok(v_cod, v_msg, 'M8 denegar');
END $$;

COMMIT;
