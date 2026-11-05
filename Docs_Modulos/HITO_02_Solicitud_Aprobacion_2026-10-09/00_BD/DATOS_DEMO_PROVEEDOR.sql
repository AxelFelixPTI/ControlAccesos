-- =============================================================================
-- Archivo : DATOS_DEMO_PROVEEDOR.sql      (OPCIONAL: solo para probar el calendario en el piloto; NO lo corre restaurar_bd.ps1)
-- Version : V2.0 2026-11-03 (flujo corregido: verificacion -> disponibilidad de Almacen -> ingreso fisico)
-- Requiere: scripts 01 a 19, los SP, y 11_SEED_DEMO_USUARIOS.sql (usuarios de demostracion).
-- Que hace (una sola vez; falla si ya se ejecuto):
--   1. Crea 2 usuarios de Almacen (con su ficha de Personal): almacen1.demo@trianon.test y almacen2.demo@trianon.test, clave Alma.Demo#2026
--   2. Da licencias de proveedor a usuarios demo, sede VES:
--        solicitante1.demo -> LIC_CAF_SOLICITANTE_PROVEEDOR + LIC_CAF_PROVEEDOR_DASHBOARD
--        coordinador.demo  -> LIC_CAF_COORD_PROVEEDOR      + LIC_CAF_PROVEEDOR_DASHBOARD
--        vigilante1.demo   -> LIC_CAF_VIGILANCIA_PROVEEDOR + LIC_CAF_PROVEEDOR_DASHBOARD
--        almacen1/2.demo   -> LIC_CAF_ALMACEN
--   3. Crea 9 entregas de proveedor de HOY (y una de manana) por los procedimientos reales. SOLO UNA tiene la esclusa
--      reservada u ocupada (la exclusa es una sola); las demas estan en otro punto del recorrido:
--        1  Programado, 16:30 (todavia no se presenta)              Sostenible
--        2  Programado, 08:00 (hora vencida, sin verificar)         Energo
--        3  En espera, 11:00 (datos verificados, sin disponibilidad) Power Technology
--        4  En espera, 13:00 (verificada con DESVIACION autorizada) Ascensores
--        5  En espera, 09:30 (datos verificados, sin disponibilidad) Sostenible
--        6  Recepcion culminada, 08:30 (el camion sigue dentro: falta su salida)  <- tiene la exclusa   Energo
--        7  Salio, 07:30                                            Power Technology
--        8  Ingreso denegado, 12:00 (el coordinador deniega)        Ascensores
--        9  Programado, manana 10:00                                Power Technology
--      Para probar el resto en vivo: la exclusa esta ocupada por la 6 hasta que Vigilancia registre su salida (vigilante1.demo,
--      Control de accesos, Registrar salida). Luego, con almacen1.demo, Confirmar disponibilidad en la 3, 4 o 5; con vigilante1.demo
--      Validar ingreso (o DEMO_PROVEEDOR_VALIDAR_INGRESO.sql); y con almacen1.demo Iniciar y Terminar atencion.
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
    v_ids BIGINT[] := ARRAY[]::BIGINT[]; v_sps BIGINT[] := ARRAY[]::BIGINT[]; v_dest BIGINT[]; v_t_den BIGINT; v_t_rest BIGINT; k INT;
    v_h TIMESTAMP := CAST(CURRENT_DATE AS TIMESTAMP);
    v_hash TEXT := 'PBKDF2$SHA256$210000$plD+RU/Zn0negwQkCR/TdA==$aGG/NTy2AAA7MON8IT2iKnoDtuj/MWd4jb0mj+McOp4=';
    i INT;
    emp TEXT[] := ARRAY['Distribuidora Andina S.A.','Transportes y Logistica Cordillera Blanca S.A.C.','Ferreteria Industrial Norte','Insumos del Sur E.I.R.L.','Proveedora Pacifico S.A.C.','Aceros Peruanos S.A.','Empaques Lima S.A.C.','Quimicos del Centro S.A.','Maderas del Oriente S.A.C.'];
    emp_cod TEXT[] := ARRAY['TRIANON_SOSTENIBLE','TRIANON_ENERGO','POWER_TECHNOLOGY','TRIANON_ASCENSORES','TRIANON_SOSTENIBLE','TRIANON_ENERGO','POWER_TECHNOLOGY','TRIANON_ASCENSORES','POWER_TECHNOLOGY'];
    dia INT[]  := ARRAY[0,0,0,0,0,0,0,0,1];
    hora NUMERIC[] := ARRAY[16.5,8,11,13,9.5,8.5,7.5,12,10];
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

    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_den  FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'DENEGATORIA';
    SELECT "ID_Catalogo_Tratamiento_Desviacion" INTO v_t_rest FROM "Catalogo_Tratamiento_Desviacion" WHERE "Codigo" = 'RESTRICCION_ZONA_ADM';

    -- 3. Entregas: se crean y aprueban las 9
    FOR i IN 1..9 LOOP
        SELECT "ID_Catalogo_Empresa_Grupo" INTO v_emp FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "Codigo" = emp_cod[i];
        CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni, '7300000' || i, 'Chofer', 'Demo ' || i, 'Carlos', 0, v_q, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'persona %: %', i, v_msg; END IF;
        CALL "ERP_CAF_SOLICITUD_CREAR"(v_ves, v_prov, NULL, v_h + dia[i] * INTERVAL '1 day' + hora[i] * INTERVAL '1 hour', emp[i], NULL, NULL, NULL, NULL, v_q::TEXT, NULL, NULL, NULL,
              'DEM10' || i, NULL, NULL, '98877766' || i, NULL, v_emp, '2012345678' || i, 'Av. Demo ' || i, 'Hino', 'Q1234567' || i, v_q, v_sol, v_s, v_cs, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'solicitud %: %', i, v_msg; END IF;
        SELECT "ID_Solicitud_Persona" INTO v_sp FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = v_s AND "ID_Persona_Externa" = v_q;
        CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s, v_paso, 'APROBADA', NULL, v_sp::TEXT, v_coo, v_cant, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'aprobacion %: %', i, v_msg; END IF;
        v_ids := v_ids || v_s; v_sps := v_sps || v_sp;
    END LOOP;

    -- 4. Recorridos. Primero las que ya terminaron (la exclusa es una sola): 7 (salio) y 6 (recepcion culminada: queda con la exclusa hasta su salida)
    FOREACH k IN ARRAY ARRAY[7,6] LOOP
        SELECT STRING_AGG(A."ID_Catalogo_Item_Checklist" || ':Y', ',') INTO v_it FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(v_sps[k], 'INGRESO', 'N', 'N') A;
        CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sps[k], v_it, 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'verificacion %: %', k, v_msg; END IF;
        CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR"(v_ids[k], v_al1, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'disponibilidad %: %', k, v_msg; END IF;
        CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_ids[k], v_vig, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'ingreso %: %', k, v_msg; END IF;
        CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_ids[k], v_al1, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'atender %: %', k, v_msg; END IF;
        CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_ids[k], 'CONFORME', NULL, v_al1, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'recepcion %: %', k, v_msg; END IF;
        IF k = 7 THEN
            CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_sps[k], '', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg);
            IF v_cod <> 100 THEN RAISE EXCEPTION 'salida %: %', k, v_msg; END IF;
        END IF;
    END LOOP;

    -- Solo verificadas (En espera): 3 conforme, 4 con desviacion autorizada
    SELECT STRING_AGG(A."ID_Catalogo_Item_Checklist" || ':Y', ',') INTO v_it FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(v_sps[3], 'INGRESO', 'N', 'N') A;
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sps[3], v_it, 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg);
    IF v_cod <> 100 THEN RAISE EXCEPTION 'verificacion 3: %', v_msg; END IF;
    SELECT STRING_AGG(A."ID_Catalogo_Item_Checklist" || ':' || CASE WHEN A."Codigo" = 'ING_EPP' THEN 'N' ELSE 'Y' END, ',') INTO v_it FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(v_sps[4], 'INGRESO', 'N', 'N') A;
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sps[4], v_it, 'N', 'N', NULL, 'El transportista no porta el EPP completo; el coordinador autoriza el ingreso restringido a la zona administrativa.', v_coo, v_t_rest, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg);
    IF v_cod <> 100 THEN RAISE EXCEPTION 'verificacion 4: %', v_msg; END IF;
    -- 8: desviacion con ingreso denegado
    SELECT STRING_AGG(A."ID_Catalogo_Item_Checklist" || ':' || CASE WHEN A."Codigo" = 'ING_PLACA' THEN 'N' ELSE 'Y' END, ',') INTO v_it FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(v_sps[8], 'INGRESO', 'N', 'N') A;
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sps[8], v_it, 'N', 'N', NULL, 'La placa del vehiculo no coincide con la solicitud; el coordinador deniega el ingreso.', v_coo, v_t_den, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg);
    IF v_cod <> 100 THEN RAISE EXCEPTION 'verificacion 8: %', v_msg; END IF;

    -- La 5: solo verificada (En espera, sin disponibilidad)
    SELECT STRING_AGG(A."ID_Catalogo_Item_Checklist" || ':Y', ',') INTO v_it FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(v_sps[5], 'INGRESO', 'N', 'N') A;
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sps[5], v_it, 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_vig, v_r, v_d, v_x, v_cod, v_msg);
    IF v_cod <> 100 THEN RAISE EXCEPTION 'verificacion 5: %', v_msg; END IF;
END $$;

COMMIT;
