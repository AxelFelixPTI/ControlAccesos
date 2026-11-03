-- =============================================================================
-- Archivo : DATOS_DEMO_PROVEEDOR.sql      (OPCIONAL: solo para probar el calendario en el piloto; NO lo corre restaurar_bd.ps1)
-- Version : V1.0 2026-11-03
-- Requiere: scripts 01 a 18, los SP, y 11_SEED_DEMO_USUARIOS.sql (usuarios de demostracion).
-- Que hace (una sola vez; falla si ya se ejecuto):
--   1. Crea 2 usuarios de Almacen (con su ficha de Personal): almacen1.demo@trianon.test y almacen2.demo@trianon.test, clave Alma.Demo#2026
--   2. Da licencias de proveedor a usuarios demo, sede VES:
--        solicitante1.demo -> LIC_CAF_SOLICITANTE_PROVEEDOR + LIC_CAF_PROVEEDOR_DASHBOARD
--        coordinador.demo  -> LIC_CAF_COORD_PROVEEDOR      + LIC_CAF_PROVEEDOR_DASHBOARD
--        vigilante1.demo   -> LIC_CAF_VIGILANCIA_PROVEEDOR + LIC_CAF_PROVEEDOR_DASHBOARD
--        almacen1/2.demo   -> LIC_CAF_ALMACEN
--   3. Crea 5 entregas de proveedor (por los procedimientos reales, aprobadas por el Coordinador):
--        hoy 09:30 y 11:00 con llegada e ingreso ya registrados (listas para Atender), hoy 14:00 solo con llegada,
--        hoy 16:30 programada, y manana 10:00 programada.
-- Para quitarlo: reconstruir la BD con restaurar_bd.ps1.
-- =============================================================================
BEGIN;
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

DO $$
DECLARE
    v_ves BIGINT; v_dni BIGINT; v_area BIGINT; v_emp BIGINT; v_prov BIGINT; v_paso BIGINT;
    v_sol BIGINT; v_coo BIGINT; v_vig BIGINT; v_al1 BIGINT; v_al2 BIGINT; v_pe1 BIGINT; v_pe2 BIGINT; v_ul BIGINT;
    l_sp BIGINT; l_cp BIGINT; l_vp BIGINT; l_al BIGINT; l_da BIGINT;
    v_cod INT; v_msg VARCHAR(250); v_cant BIGINT;
    v_q BIGINT; v_s BIGINT; v_cs VARCHAR(20); v_sp BIGINT; v_it TEXT; v_r BIGINT; v_d BIGINT; v_x VARCHAR(30);
    v_h TIMESTAMP := CAST(CURRENT_DATE AS TIMESTAMP);
    v_hash TEXT := 'PBKDF2$SHA256$210000$plD+RU/Zn0negwQkCR/TdA==$aGG/NTy2AAA7MON8IT2iKnoDtuj/MWd4jb0mj+McOp4=';
    i INT;
    emp TEXT[] := ARRAY['Distribuidora Andina S.A.','Transportes y Logistica Cordillera Blanca S.A.C.','Ferreteria Industrial Norte','Insumos del Sur E.I.R.L.','Proveedora Pacifico S.A.C.'];
    dia INT[] := ARRAY[0,0,0,0,1];
    hora NUMERIC[] := ARRAY[9.5,11,14,16.5,10];
    hasta_estado INT[] := ARRAY[2,2,1,0,0];   -- 0 = solo aprobada, 1 = llegada, 2 = llegada + ingreso
BEGIN
    IF EXISTS (SELECT 1 FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'almacen1.demo@trianon.test') THEN
        RAISE EXCEPTION 'Los datos de demostracion de proveedor ya se cargaron.';
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

    -- 1. Usuarios de Almacen (con ficha de Personal, que es lo que alimenta el desplegable de responsables)
    INSERT INTO "CAF_GOVERNANCE"."Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","UsuarioID_Create")
    VALUES (v_dni,'90000031','Demo','Almacen Uno','Alma',v_area,v_emp,v_ves,'almacen1.demo@trianon.test',0) RETURNING "ID_Personal" INTO v_pe1;
    INSERT INTO "CAF_GOVERNANCE"."Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","UsuarioID_Create")
    VALUES (v_dni,'90000032','Demo','Almacen Dos','Ana',v_area,v_emp,v_ves,'almacen2.demo@trianon.test',0) RETURNING "ID_Personal" INTO v_pe2;
    INSERT INTO "CAF_GOVERNANCE"."Usuario" ("Correo","ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","ID_Personal","Password_Hash","Password_Requiere_Cambio","UsuarioID_Create")
    VALUES ('almacen1.demo@trianon.test',v_dni,'90000031','Demo','Almacen Uno','Alma',v_pe1,v_hash,'N',0) RETURNING "ID_Usuario" INTO v_al1;
    INSERT INTO "CAF_GOVERNANCE"."Usuario" ("Correo","ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","ID_Personal","Password_Hash","Password_Requiere_Cambio","UsuarioID_Create")
    VALUES ('almacen2.demo@trianon.test',v_dni,'90000032','Demo','Almacen Dos','Ana',v_pe2,v_hash,'N',0) RETURNING "ID_Usuario" INTO v_al2;

    -- 2. Licencias
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_sol, l_sp, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_sol, l_da, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_coo, l_cp, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_coo, l_da, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_vig, l_vp, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_vig, l_da, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_al1, l_al, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "CAF_GOVERNANCE"."ERP_USUARIO_LICENCIA_AGREGAR"(v_al2, l_al, v_ves, 0, v_ul, v_cod, v_msg);

    -- 3. Entregas
    FOR i IN 1..5 LOOP
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni, '7300000' || i, 'Chofer', 'Demo ' || i, 'Carlos', 0, v_q, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'persona %: %', i, v_msg; END IF;
        CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_h + dia[i] * INTERVAL '1 day' + hora[i] * INTERVAL '1 hour', emp[i], NULL, NULL, NULL, NULL, v_q::TEXT, NULL, NULL, NULL,
              'DEM10' || i, NULL, NULL, '98877766' || i, NULL, v_emp, '2012345678' || i, 'Av. Demo ' || i, 'Hino', 'Q1234567' || i, v_q, v_sol, v_s, v_cs, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'solicitud %: %', i, v_msg; END IF;
        SELECT "ID_Solicitud_Persona" INTO v_sp FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_s AND "ID_Persona_Externa" = v_q;
        CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s, v_paso, 'APROBADA', NULL, v_sp::TEXT, v_coo, v_cant, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'aprobacion %: %', i, v_msg; END IF;
        IF hasta_estado[i] >= 1 THEN
            CALL "ERP_CAF_PROVEEDOR_LLEGADA"(v_s, v_vig, v_cod, v_msg);
            IF v_cod <> 100 THEN RAISE EXCEPTION 'llegada %: %', i, v_msg; END IF;
        END IF;
        IF hasta_estado[i] >= 2 THEN
            SELECT STRING_AGG("ID_Catalogo_Item_Checklist" || ':Y', ',') INTO v_it FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(v_sp, 'INGRESO', 'N', 'N');
            CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sp, v_it, 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg);
            IF v_cod <> 100 THEN RAISE EXCEPTION 'ingreso %: %', i, v_msg; END IF;
        END IF;
    END LOOP;
END $$;

COMMIT;
