-- =============================================================================
-- Archivo : PRUEBAS_FASE1_HITO2_DESPACHO.sql   (2026-11-27, D-276)
-- Propósito: pruebas automáticas del nuevo flujo de DESPACHO (salida de productos): datos de fábrica (script 46),
--   quién solicita, creación con OF/OV/orden, transporte por empresa, aprobación del Coordinador de despachos, verificación
--   de Vigilancia, «con ingreso vehicular» obligatorio (parámetro), atención de Almacén, revisión de la guía en la salida,
--   modo del dashboard y que Proveedores sigue igual.
--   Termina en ROLLBACK: la base queda exactamente como estaba.
-- Requiere: scripts 01 a 46 y todos los SP_CAF_* (como las demás suites). Usa funciones temporales de PostgreSQL (no van a HANA).
-- =============================================================================

BEGIN;
SET search_path TO "TRIANONSATELITAL_CAF_PRODD", "CAF_GOVERNANCE";
UPDATE "CAF_Parametro" SET "Valor" = 'SIN_LIMITE' WHERE "Clave" = 'ATENCIONES_SIMULTANEAS_ALMACENERO';
DELETE FROM "CAF_GOVERNANCE"."Usuario_Licencia" WHERE "ID_Usuario" IN (SELECT "ID_Usuario" FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" LIKE '%@trianon.test');
DELETE FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" LIKE '%@trianon.test';

CREATE TEMP TABLE pruebas (n SERIAL, prueba TEXT, esperado TEXT, obtenido TEXT, detalle TEXT) ON COMMIT DROP;
CREATE FUNCTION pg_temp.chk(p TEXT, e TEXT, o TEXT, d TEXT) RETURNS void LANGUAGE sql
AS $f$ INSERT INTO pruebas (prueba, esperado, obtenido, detalle) VALUES (p, e, o, COALESCE(d, '')) $f$;
CREATE FUNCTION pg_temp.q(s TEXT) RETURNS TEXT LANGUAGE plpgsql
AS $f$ DECLARE r TEXT; BEGIN EXECUTE s INTO r; RETURN COALESCE(r, '(nulo)'); END $f$;
CREATE FUNCTION pg_temp.sp(sol BIGINT, ext BIGINT) RETURNS BIGINT LANGUAGE sql
AS $f$ SELECT "ID_Solicitud_Persona" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud" = sol AND "ID_Persona_Externa" = ext $f$;
CREATE FUNCTION pg_temp.items(p BIGINT, etapa TEXT, fallan TEXT) RETURNS TEXT LANGUAGE sql
AS $f$ SELECT STRING_AGG(A."ID_Catalogo_Item_Checklist" || ':' || CASE WHEN A."Codigo" = ANY(STRING_TO_ARRAY(fallan, ',')) THEN 'N' ELSE 'Y' END, ',' ORDER BY A."Orden")
         FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(p, etapa, 'N', 'N') A $f$;
-- Registro del conductor: «datos» = ID_Persona_Externa, RUC, nombre, dirección, placa, marca, licencia
CREATE FUNCTION pg_temp.cond(p_id BIGINT, p_ruc TEXT, p_nom TEXT, p_pla TEXT) RETURNS TEXT LANGUAGE sql
AS $f$ SELECT p_id::TEXT || CHR(31) || COALESCE(p_ruc, '') || CHR(31) || COALESCE(p_nom, '') || CHR(31) || CHR(31) || COALESCE(p_pla, '') || CHR(31) || CHR(31) $f$;

DO $$
DECLARE
    v_cod INT; v_msg VARCHAR(250); v_cant BIGINT; v_cs VARCHAR(20); v_ul BIGINT; v_reab CHAR(1);
    v_ves BIGINT; v_mag BIGINT; v_dni BIGINT; v_desp BIGINT; v_prov BIGINT; v_paso BIGINT;
    v_te BIGINT; v_pt BIGINT; v_ta BIGINT; v_ts BIGINT;      -- empresas: Trianon Energo, Power Technology, Trianon Ascensores, Trianon Sostenible
    v_lic_sd BIGINT; v_lic_cd BIGINT; v_lic_cp BIGINT; v_lic_vp BIGINT; v_lic_al BIGINT; v_lic_sol BIGINT; v_lic_adm BIGINT; v_lic_sp BIGINT; v_lic_h BIGINT;
    v_usd BIGINT; v_ucd BIGINT; v_uvp BIGINT; v_ual BIGINT; v_usc BIGINT; v_usp BIGINT; v_ucp BIGINT; v_uadm BIGINT;
    v_q1 BIGINT; v_q2 BIGINT; v_q3 BIGINT; v_q4 BIGINT; v_s1 BIGINT; v_s2 BIGINT; v_s3 BIGINT; v_s4 BIGINT; v_s5 BIGINT; v_x BIGINT;
    v_sp1 BIGINT; v_sp2 BIGINT; v_reg BIGINT; v_des BIGINT; v_res VARCHAR(30);
    v_fhoy TIMESTAMP; v_fut TIMESTAMP; v_pas TIMESTAMP; v_f TIMESTAMP;
    v_i TEXT;
BEGIN
    SELECT "ID_Catalogo_Sede" INTO v_ves FROM "Catalogo_Sede" WHERE "Codigo" = 'VES';
    SELECT "ID_Catalogo_Sede" INTO v_mag FROM "Catalogo_Sede" WHERE "Codigo" = 'MAG';
    SELECT "ID_Catalogo_Tipo_Documento" INTO v_dni FROM "Catalogo_Tipo_Documento" WHERE "Codigo" = 'DNI';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_desp FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'DESPACHO';
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_prov FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'PROVEEDOR';
    SELECT "ID_Catalogo_Empresa_Grupo" INTO v_te FROM "Catalogo_Empresa_Grupo" WHERE "Codigo" = 'TRIANON_ENERGO';
    SELECT "ID_Catalogo_Empresa_Grupo" INTO v_pt FROM "Catalogo_Empresa_Grupo" WHERE "Codigo" = 'POWER_TECHNOLOGY';
    SELECT "ID_Catalogo_Empresa_Grupo" INTO v_ta FROM "Catalogo_Empresa_Grupo" WHERE "Codigo" = 'TRIANON_ASCENSORES';
    SELECT "ID_Catalogo_Empresa_Grupo" INTO v_ts FROM "Catalogo_Empresa_Grupo" WHERE "Codigo" = 'TRIANON_SOSTENIBLE';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_sd  FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_SOLICITANTE_DESPACHO';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_cd  FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_COORD_DESPACHO';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_cp  FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_COORD_PROVEEDOR';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_vp  FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_VIGILANCIA_PROVEEDOR';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_al  FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_ALMACEN';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_sol FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_SOLICITANTE';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_sp FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_SOLICITANTE_PROVEEDOR';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_h FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_HIST_ALMACEN';
    SELECT "ID_Catalogo_Licencia" INTO v_lic_adm FROM "Catalogo_Licencia" WHERE "Codigo" = 'LIC_CAF_ADMIN';
    SELECT "ID_Tipo_Acceso_Paso_Aprobacion" INTO v_paso FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "ID_Catalogo_Tipo_Acceso" = v_desp AND "Eliminado" = 'N' LIMIT 1;
    v_fhoy := CAST(CURRENT_DATE AS TIMESTAMP) + INTERVAL '23 hours';
    v_fut  := CAST(CURRENT_DATE AS TIMESTAMP) + INTERVAL '2 days 10 hours';
    v_pas  := CURRENT_TIMESTAMP - INTERVAL '2 days';

    -- ===================================================== A. DATOS DE FÁBRICA (script 46)
    PERFORM pg_temp.chk('Fábrica: el tipo Despacho existe, disponible y con aprobación', 'Y|Y|Despacho (salida de productos)',
        pg_temp.q('SELECT "Disponible" || ''|'' || "Requiere_Aprobacion" || ''|'' || "Descripcion" FROM "Catalogo_Tipo_Acceso" WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_desp), '');
    PERFORM pg_temp.chk('Fábrica: un paso de aprobación con la licencia de Coordinador de despachos', '1|LIC_CAF_COORD_DESPACHO',
        pg_temp.q('SELECT COUNT(*) || ''|'' || MAX(L."Codigo") FROM "Tipo_Acceso_Paso_Aprobacion" S JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = S."ID_Catalogo_Licencia" WHERE S."ID_Catalogo_Tipo_Acceso" = ' || v_desp), '');
    PERFORM pg_temp.chk('Fábrica: solo VES hace despachos', 'VES', pg_temp.q('SELECT STRING_AGG("Codigo", '','') FROM "CAF_GOVERNANCE"."Catalogo_Sede" WHERE "Aplica_Despacho" = ''Y'''), '');
    PERFORM pg_temp.chk('Fábrica: solo el conductor como subtipo (no hay ayudante de descarga)', 'TRANSPORTISTA|Conductor|Y|1',
        pg_temp.q('SELECT MAX("Codigo") || ''|'' || MAX("Descripcion") || ''|'' || MAX("Es_Predeterminado") || ''|'' || COUNT(*) FROM "Tipo_Acceso_Subtipo" WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_desp), '');
    PERFORM pg_temp.chk('Fábrica: checklist del despacho = identidad y placa al ingreso, revisión de la guía a la salida', 'ING_IDENTIDAD,ING_PLACA,SAL_DESPACHO_GUIA',
        pg_temp.q('SELECT STRING_AGG(I."Codigo", '','' ORDER BY I."Codigo") FROM "Tipo_Acceso_Item_Checklist" T JOIN "Catalogo_Item_Checklist" I ON I."ID_Catalogo_Item_Checklist" = T."ID_Catalogo_Item_Checklist" WHERE T."Eliminado" = ''N'' AND T."ID_Catalogo_Tipo_Acceso" = ' || v_desp), '');
    PERFORM pg_temp.chk('Fábrica: la guía de remisión es un ítem crítico de SALIDA', 'SALIDA|Y',
        pg_temp.q('SELECT "Etapa" || ''|'' || "Es_Critico" FROM "Catalogo_Item_Checklist" WHERE "Codigo" = ''SAL_DESPACHO_GUIA'''), '');
    PERFORM pg_temp.chk('Fábrica: transporte por empresa — PT y TA solo servicio tipo Cabify; TE y TS cliente o contratado', 'PROPIO_CLIENTE;CONTRATADO|SERVICIO_APP|SERVICIO_APP|PROPIO_CLIENTE;CONTRATADO',
        pg_temp.q('SELECT STRING_AGG(X."Transportes_Permitidos", ''|'' ORDER BY X."ID_Catalogo_Empresa_Grupo") FROM "ERP_CAF_DESPACHO_CONFIG_LISTAR"() X WHERE X."ID_Catalogo_Empresa_Grupo" IN (' || v_pt || ',' || v_ta || ',' || v_te || ',' || v_ts || ')'), '');
    PERFORM pg_temp.chk('Fábrica: parámetros — dashboard AMBOS; sin ingreso vehicular: proveedor Y, despacho N', 'AMBOS|Y|N',
        "ERP_CAF_PARAMETRO_VALOR"('DASHBOARD_ENTREGAS_MODO') || '|' || "ERP_CAF_PARAMETRO_VALOR"('PROVEEDOR_PERMITE_SIN_INGRESO_VEHICULAR') || '|' || "ERP_CAF_PARAMETRO_VALOR"('DESPACHO_PERMITE_SIN_INGRESO_VEHICULAR'), '');
    PERFORM pg_temp.chk('Fábrica: la licencia de Coordinador de despachos nace con aprobar y ver', 'PER_CAF_PORTERIA_VER,PER_CAF_PROVEEDOR_VER,PER_CAF_SOLICITUD_APROBAR',
        pg_temp.q('SELECT STRING_AGG(P."Codigo", '','' ORDER BY P."Codigo") FROM "CAF_GOVERNANCE"."Licencia_Permiso" LP JOIN "CAF_GOVERNANCE"."Catalogo_Permiso" P ON P."ID_Catalogo_Permiso" = LP."ID_Catalogo_Permiso" WHERE LP."ID_Catalogo_Licencia" = ' || v_lic_cd || ' AND P."Codigo" <> ''PER_CAF_DESVIACION_CONFORMIDAD'''), '');

    -- ===================================================== B. USUARIOS Y PERSONAS
    CALL "ERP_USUARIO_CREAR"('vendedor.desp@ejemplo.pe', v_dni,'40000001','Ventas','Desp','Vera',NULL,'Ejemplo','Y',0, v_usd, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('coord.desp@ejemplo.pe',    v_dni,'40000002','Coord','Desp','Cora',NULL,'Ejemplo','Y',0, v_ucd, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('vig.desp@ejemplo.pe',      v_dni,'40000003','Vigilante','Desp','Vico',NULL,'Ejemplo','Y',0, v_uvp, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('almacen.desp@ejemplo.pe',  v_dni,'40000004','Almacen','Desp','Alma',NULL,'Ejemplo','Y',0, v_ual, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('comun.desp@ejemplo.pe',    v_dni,'40000005','Comun','Desp','Carlos',NULL,'Ejemplo','Y',0, v_usc, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('solprov.desp@ejemplo.pe',  v_dni,'40000006','Prov','Desp','Pedro',NULL,'Ejemplo','Y',0, v_usp, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('coordprov.desp@ejemplo.pe',v_dni,'40000007','CoordProv','Desp','Paco',NULL,'Ejemplo','Y',0, v_ucp, v_cod, v_msg);
    CALL "ERP_USUARIO_CREAR"('admin.desp@ejemplo.pe',    v_dni,'40000008','Admin','Desp','Ada',NULL,'Ejemplo','Y',0, v_uadm, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_usd, v_lic_sd,  v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_usd, v_lic_sd,  v_mag, 0, v_ul, v_cod, v_msg);   -- para probar que MAG no hace despachos
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_ucd, v_lic_cd,  v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_uvp, v_lic_vp,  v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_ual, v_lic_al,  v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_usc, v_lic_sol, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_usp, v_lic_sp, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_ucp, v_lic_cp,  v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_ual, v_lic_h, v_ves, 0, v_ul, v_cod, v_msg);
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_uadm, v_lic_adm, v_ves, 0, v_ul, v_cod, v_msg);
    INSERT INTO "CAF_Usuario_Empresa_Almacen" ("ID_Usuario","ID_Catalogo_Empresa_Grupo","UsuarioID_Create") VALUES (v_ual, v_pt, 0), (v_ual, v_ta, 0), (v_ual, v_te, 0);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'73000001','Chofer','Uno','Carlos',0, v_q1, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'73000002','Chofer','Dos','Raúl',0,   v_q2, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'73000003','Chofer','Tres','Saúl',0,  v_q3, v_cod, v_msg);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dni,'73000004','Chofer','Cuatro','Iván',0,v_q4, v_cod, v_msg);

    -- ===================================================== C. QUIÉN SOLICITA
    PERFORM pg_temp.chk('Quién: el solicitante de despachos ve el tipo Despacho', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_usd || ') WHERE "Codigo" = ''DESPACHO'' AND "Usable" = ''Y'''), '');
    PERFORM pg_temp.chk('Quién: el permiso de despacho no abre otros tipos', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_usd || ') WHERE "Codigo" <> ''DESPACHO'' AND "Usable" = ''Y'''), '');
    PERFORM pg_temp.chk('Quién: un solicitante común no ve Despacho', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_usc || ') WHERE "Codigo" = ''DESPACHO'''), '');
    PERFORM pg_temp.chk('Quién: el solicitante de proveedores no ve Despacho', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_usp || ') WHERE "Codigo" = ''DESPACHO'''), '');
    PERFORM pg_temp.chk('Quién: la sede se ofrece con la marca de despacho (solo VES)', 'VES|Y',
        pg_temp.q('SELECT STRING_AGG("Codigo" || ''|'' || "Aplica_Despacho", '','' ORDER BY "Codigo") FROM "ERP_CAF_SOLICITUD_SEDES_OPCIONES"(' || v_usd || ')'), '');
    PERFORM pg_temp.chk('Quién: Almacén no solicita hasta que el administrador le dé el permiso', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_ual || ') WHERE "Codigo" = ''DESPACHO'''), '');
    CALL "ERP_USUARIO_LICENCIA_AGREGAR"(v_ual, v_lic_sd, v_ves, 0, v_ul, v_cod, v_msg);
    PERFORM pg_temp.chk('Quién: con la licencia de solicitante de despachos, Almacén también solicita (permiso de extraoficial)', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_ual || ') WHERE "Codigo" = ''DESPACHO'' AND "Usable" = ''Y'''), '');

    -- ===================================================== D. CREAR (validaciones)
    v_x := (SELECT COUNT(*) FROM "CAF_Solicitud");
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-1001', NULL, NULL, NULL, NULL, NULL, NULL, v_usc, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: sin permiso de despacho (solicitante común)', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-1001', NULL, NULL, NULL, NULL, NULL, NULL, v_usp, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: el solicitante de proveedores no crea despachos', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_mag, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-1001', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: la sede que no hace despachos (MAG) se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: la OF es obligatoria', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF 1001 ??', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: una OF con caracteres no válidos se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-1;OF-2;OF-3;OF-4;OF-5;OF-6', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: más de 5 OF no se admite', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-1001', 'OV@@', NULL, NULL, NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: una OV mal escrita también se valida (aunque es opcional)', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-1001', NULL, NULL, 'CLIENTE', 'Fletes SAC', NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: PT solo permite servicio tipo Cabify (pedir transporte del cliente se rechaza)', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_te::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-2001', NULL, NULL, 'SERVICIO_APP', NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: TE no admite servicio tipo Cabify (carga grande)', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_te::TEXT, pg_temp.cond(v_q1, '20123456789', 'Carlos Chofer', 'abc-123'),
        'OF-2001', NULL, NULL, 'PROPIO_CLIENTE', NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: con transporte del cliente se exige la empresa de transporte', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_te::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-2001', NULL, NULL, 'PROPIO_CLIENTE', 'Fletes SAC', NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: con transporte del cliente se exige el RUC del conductor principal', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', NULL),
        'OF-1001', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: la placa del conductor es obligatoria (parámetro PLACA_OBLIGATORIA)', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1 || ',' || v_q2, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-1001', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: todas las personas son conductores (no hay ayudante de descarga)', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt || ',' || v_te, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-1001', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: empresas sin transporte en común (PT con TE) se rechazan', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '12', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-1001', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: el celular del responsable de ventas es obligatorio y se valida', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_pas, 'Cliente Norte S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        'OF-1001', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: la fecha anterior a hoy se rechaza', '400', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Crear: lo rechazado no dejó nada creado', '0', ((SELECT COUNT(*) FROM "CAF_Solicitud") - v_x)::TEXT, '');

    -- ===================================================== E. CREAR (correctos)
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Norte S.A.', 'Paneles menores', v_q1::TEXT, NULL, NULL, 'Vera Ventas', '+51 999-111-222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'abc-123'),
        ' of-1001 ; of-1002, OF-1001', ' ov-77 ', 'Ord-5', NULL, NULL, NULL, 'ventas@ejemplo.pe', v_usd, v_s1, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear PT: servicio tipo Cabify, solo nombre, DNI y placa (sin RUC ni empresa de transporte)', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Crear PT: tipo Despacho, estado PENDIENTE y código SOL-nnnnn', 'DESPACHO|PENDIENTE|SOL-' || LPAD(v_s1::TEXT, 5, '0'),
        pg_temp.q('SELECT T."Codigo" || ''|'' || S."Estado" || ''|'' || S."Codigo" FROM "CAF_Solicitud" S JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" WHERE S."ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Crear PT: OF, OV y orden normalizadas; transporte fijo de la empresa', 'OF-1001;OF-1002|OV-77|ORD-5|SERVICIO_APP',
        pg_temp.q('SELECT "Numeros_OF" || ''|'' || "Numeros_OV" || ''|'' || "Numeros_Orden" || ''|'' || "Despacho_Transporte" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Crear PT: empresa, placa normalizada, contacto y correo del responsable', POSITION('x' IN 'x')::TEXT || '|' || 'ABC123|Vera Ventas|51999111222|ventas@ejemplo.pe',
        pg_temp.q('SELECT (S."ID_Catalogo_Empresa_Grupo_Destino" = ' || v_pt || ')::INT || ''|'' || S."Placa_Vehiculo" || ''|'' || S."Contacto_Nombre" || ''|'' || S."Contacto_Telefonos" || ''|'' || S."Contacto_Correos" FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Crear PT: motivo fijo «Despacho de productos» y sin responsable de atención', 'DESPACHO_PRODUCTOS|(nulo)',
        pg_temp.q('SELECT M."Codigo" || ''|'' || COALESCE(CAST(S."ID_Personal_Responsable" AS TEXT), ''(nulo)'') FROM "CAF_Solicitud" S JOIN "Catalogo_Motivo_Visita" M ON M."ID_Catalogo_Motivo_Visita" = S."ID_Catalogo_Motivo_Visita" WHERE S."ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Crear PT: el único conductor es principal y tiene el rol Conductor', '1|1|TRANSPORTISTA',
        pg_temp.q('SELECT COUNT(*) || ''|'' || SUM(CASE WHEN P."Es_Principal" = ''Y'' THEN 1 ELSE 0 END) || ''|'' || MAX(X."Codigo") FROM "CAF_Solicitud_Persona" P JOIN "Tipo_Acceso_Subtipo" X ON X."ID_Tipo_Acceso_Subtipo" = P."ID_Tipo_Acceso_Subtipo" WHERE P."ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Crear PT: aviso al Coordinador de despachos (y no al de proveedores)', 'true|false',
        pg_temp.q('SELECT (COALESCE(STRING_AGG("Destinatarios", '';''), '''') LIKE ''%coord.desp@ejemplo.pe%'') || ''|'' || (COALESCE(STRING_AGG("Destinatarios", '';''), '''') LIKE ''%coordprov.desp@ejemplo.pe%'') FROM "CAF_Correo_Pendiente" WHERE "ID_Solicitud" = ' || v_s1 || ' AND "Tipo" = ''SOLICITUD_NUEVA'''), '');
    PERFORM pg_temp.chk('Crear PT: Almacén va en copia', 'true', pg_temp.q('SELECT COALESCE("ERP_CAF_FN_COPIA_CORREO"(' || v_s1 || ', ''N'', ''N'', ''N'', ''N'') LIKE ''%almacen.desp@ejemplo.pe%'', false)'), '');
    PERFORM pg_temp.chk('Crear PT: el solicitante la ve en Mis solicitudes y en su detalle', '1|1', pg_temp.q('SELECT (SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_MIS_LISTAR"(' || v_usd || ') X WHERE X."ID_Solicitud" = ' || v_s1 || ') || ''|'' || (SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_usd || ',' || v_s1 || '))'), '');
    PERFORM pg_temp.chk('Crear PT: el solicitante de proveedores no la ve', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_DETALLE"(' || v_usp || ',' || v_s1 || ')'), '');

    -- TE: transporte por defecto o elegido; PT + TA juntas (misma dirección)
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Sur S.A.', NULL, v_q2::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_te::TEXT, pg_temp.cond(v_q2, '20123456789', 'Raúl Chofer', 'xyz-987'),
        'OF-2001', NULL, NULL, NULL, 'Fletes del Cliente SAC', NULL, NULL, v_usd, v_s2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear TE: sin elegir, queda el transporte predeterminado de la empresa (cliente)', '100|PROPIO_CLIENTE|Fletes del Cliente SAC',
        v_cod::TEXT || '|' || pg_temp.q('SELECT "Despacho_Transporte" || ''|'' || "Empresa_Transportista" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s2), v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Sur S.A.', NULL, v_q3::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_ts::TEXT, pg_temp.cond(v_q3, '20999888777', 'Saúl Chofer', 'lmn-456'),
        'OF-3001', NULL, NULL, 'CONTRATADO', 'Transportes Contratados SAC', '14:30', NULL, v_usd, v_s3, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear TS: elige transporte contratado por la empresa, con RUC y franja', '100|CONTRATADO|14:30|20999888777',
        v_cod::TEXT || '|' || pg_temp.q('SELECT "Despacho_Transporte" || ''|'' || TO_CHAR("Hora_Hasta_Prevista", ''HH24:MI'') || ''|'' || "Proveedor_RUC" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s3), v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Este S.A.', NULL, v_q4::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt || ',' || v_ta, pg_temp.cond(v_q4, NULL, 'Iván Chofer', 'pqr-111'),
        'OF-1500', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s4, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear PT + TA: pueden ir juntas hacia la misma dirección (dos empresas, la primera principal)', '100|2|' || v_pt,
        v_cod::TEXT || '|' || pg_temp.q('SELECT COUNT(*) FROM "CAF_Solicitud_Empresa" WHERE "ID_Solicitud" = ' || v_s4 || ' AND "Eliminado" = ''N''') || '|' || pg_temp.q('SELECT "ID_Catalogo_Empresa_Grupo_Destino" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s4), v_msg);

    -- ===================================================== F. EDICIÓN DE DATOS PROPIOS
    CALL "ERP_CAF_SOLICITUD_DESPACHO_DATOS_GUARDAR"(v_s1, 'OF-9000', 'OV-1', NULL, NULL, NULL, '12:00', NULL, v_usd, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: el dueño cambia OF, OV y franja y quita el orden', '100|OF-9000|OV-1|(nulo)|12:00', v_cod::TEXT || '|' ||
        pg_temp.q('SELECT "Numeros_OF" || ''|'' || "Numeros_OV" || ''|'' || COALESCE("Numeros_Orden", ''(nulo)'') || ''|'' || TO_CHAR("Hora_Hasta_Prevista", ''HH24:MI'') FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s1), v_msg);
    CALL "ERP_CAF_SOLICITUD_DESPACHO_DATOS_GUARDAR"(v_s1, 'OF-9000', NULL, NULL, NULL, NULL, NULL, NULL, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: otro usuario no puede', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DESPACHO_DATOS_GUARDAR"(v_s1, '', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: sin OF no se guarda', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DESPACHO_DATOS_GUARDAR"(v_s1, 'OF-9000', NULL, NULL, 'CONTRATADO', 'Fletes SAC', NULL, NULL, v_usd, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: el transporte debe seguir siendo permitido por la empresa', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DESPACHO_DATOS_GUARDAR"(999999999, 'OF-9000', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_cod, v_msg);
    PERFORM pg_temp.chk('Editar: una solicitud que no existe da 404', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DESPACHO_DATOS_GUARDAR"(v_s1, 'OF-1001', 'OV-77', 'ORD-5', NULL, NULL, NULL, NULL, v_usd, v_cod, v_msg);

    -- ===================================================== G. CONFIGURACIÓN DE TRANSPORTE POR EMPRESA (Administrador)
    CALL "ERP_CAF_DESPACHO_CONFIG_GUARDAR"(v_ts, 'SERVICIO_APP;PROPIO_CLIENTE;CONTRATADO', 'CONTRATADO', v_uadm, v_cod, v_msg);
    PERFORM pg_temp.chk('Config: libre elección (los tres transportes) con predeterminado contratado', '100|SERVICIO_APP;PROPIO_CLIENTE;CONTRATADO|CONTRATADO|N', v_cod::TEXT || '|' ||
        pg_temp.q('SELECT "Transportes_Permitidos" || ''|'' || "Transporte_Predeterminado" || ''|'' || "Es_Fijo" FROM "ERP_CAF_DESPACHO_CONFIG_LISTAR"() WHERE "ID_Catalogo_Empresa_Grupo" = ' || v_ts), v_msg);
    CALL "ERP_CAF_DESPACHO_CONFIG_GUARDAR"(v_ts, 'CONTRATADO;SERVICIO_APP', 'SERVICIO_APP', v_uadm, v_cod, v_msg);
    PERFORM pg_temp.chk('Config: los transportes se guardan en orden fijo', 'SERVICIO_APP;CONTRATADO', pg_temp.q('SELECT "Transportes_Permitidos" FROM "ERP_CAF_DESPACHO_CONFIG_LISTAR"() WHERE "ID_Catalogo_Empresa_Grupo" = ' || v_ts), v_msg);
    CALL "ERP_CAF_DESPACHO_CONFIG_GUARDAR"(v_ts, 'SERVICIO_APP', 'CONTRATADO', v_uadm, v_cod, v_msg);
    PERFORM pg_temp.chk('Config: el predeterminado debe estar entre los permitidos', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_DESPACHO_CONFIG_GUARDAR"(v_ts, '', 'SERVICIO_APP', v_uadm, v_cod, v_msg);
    PERFORM pg_temp.chk('Config: al menos un transporte permitido', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_DESPACHO_CONFIG_GUARDAR"(v_ts, 'AVION', 'AVION', v_uadm, v_cod, v_msg);
    PERFORM pg_temp.chk('Config: un transporte desconocido se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_DESPACHO_CONFIG_GUARDAR"(999999, 'SERVICIO_APP', 'SERVICIO_APP', v_uadm, v_cod, v_msg);
    PERFORM pg_temp.chk('Config: una empresa que no existe da 404', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_DESPACHO_CONFIG_GUARDAR"(v_ts, 'SERVICIO_APP', 'SERVICIO_APP', v_uadm, v_cod, v_msg);
    PERFORM pg_temp.chk('Config: un solo transporte lo deja FIJO', '100|Y', v_cod::TEXT || '|' || pg_temp.q('SELECT "Es_Fijo" FROM "ERP_CAF_DESPACHO_CONFIG_LISTAR"() WHERE "ID_Catalogo_Empresa_Grupo" = ' || v_ts), v_msg);
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fut, 'Cliente Sur S.A.', NULL, v_q3::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_ts::TEXT, pg_temp.cond(v_q3, NULL, 'Saúl Chofer', 'lmn-456'),
        'OF-3002', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s5, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Config: la nueva configuración rige en las solicitudes nuevas (TS ahora solo Cabify)', '100|SERVICIO_APP', v_cod::TEXT || '|' || pg_temp.q('SELECT "Despacho_Transporte" FROM "CAF_Solicitud" WHERE "ID_Solicitud" = ' || v_s5), v_msg);
    CALL "ERP_CAF_DESPACHO_CONFIG_GUARDAR"(v_ts, 'PROPIO_CLIENTE;CONTRATADO', 'PROPIO_CLIENTE', v_uadm, v_cod, v_msg);

    -- ===================================================== H. APROBACIÓN (Coordinador de despachos, por solicitud)
    v_sp1 := pg_temp.sp(v_s1, v_q1);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso, 'APROBADA', NULL, v_sp1::TEXT, v_ucp, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Aprobar: el Coordinador de proveedores no aprueba despachos (falta la licencia del paso)', '101', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso, 'APROBADA', NULL, v_sp1::TEXT, v_usd, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Aprobar: el solicitante no aprueba su propio despacho', '101', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Aprobar: el Coordinador de despachos ve la solicitud en su bandeja', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_BANDEJA_LISTAR"(' || v_ucd || ', NULL, ''POR_DECIDIR'') X WHERE X."ID_Solicitud" = ' || v_s1), '');
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s1, v_paso, 'APROBADA', NULL, v_sp1::TEXT, v_ucd, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Aprobar: el Coordinador de despachos aprueba', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Aprobar: queda APROBADA y la entrega PROGRAMADA y activa', 'APROBADA|PROGRAMADO|Y',
        pg_temp.q('SELECT S."Estado" || ''|'' || O."Estado_Operativo" || ''|'' || O."Activa" FROM "CAF_Solicitud" S JOIN "CAF_Solicitud_Operacion" O ON O."ID_Solicitud" = S."ID_Solicitud" WHERE S."ID_Solicitud" = ' || v_s1), '');
    PERFORM pg_temp.chk('Aprobar: no aparece en la lista de Vigilancia convencional (usa la de entregas)', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS"(' || v_uvp || ', ' || v_ves || ') WHERE "ID_Solicitud" = ' || v_s1), '');

    -- ===================================================== I. CALENDARIO Y MODO DEL DASHBOARD (la entrega de hoy se crea abajo; ésta es futura)
    PERFORM pg_temp.chk('Calendario AMBOS: el despacho aparece con su tipo, OF, OV, orden y transporte', 'DESPACHO|OF-1001|OV-77|ORD-5|SERVICIO_APP',
        pg_temp.q('SELECT X."Tipo_Codigo" || ''|'' || X."Numeros_OF" || ''|'' || X."Numeros_OV" || ''|'' || X."Numeros_Orden" || ''|'' || X."Despacho_Transporte" FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) X WHERE X."ID_Solicitud" = ' || v_s1), '');
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('DASHBOARD_ENTREGAS_MODO', 'PROVEEDORES', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Modo PROVEEDORES: el despacho no se ve en el calendario (proveedores aislado)', '100|0', v_cod::TEXT || '|' || pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) X WHERE X."ID_Solicitud" = ' || v_s1), v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('DASHBOARD_ENTREGAS_MODO', 'DESPACHOS', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Modo DESPACHOS: solo despachos en el calendario', '100|DESPACHO', v_cod::TEXT || '|' || pg_temp.q('SELECT STRING_AGG(DISTINCT X."Tipo_Codigo", '','') FROM "ERP_CAF_PROVEEDOR_CALENDARIO"(' || v_ual || ',' || v_ves || ', NULL, NULL) X'), v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('DASHBOARD_ENTREGAS_MODO', 'TODO', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Modo: un valor desconocido se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('DASHBOARD_ENTREGAS_MODO:VES', 'PROVEEDORES', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Modo por sede: el de la sede manda sobre el general (VES = PROVEEDORES)', '100|PROVEEDORES|DESPACHOS',
        v_cod::TEXT || '|' || "ERP_CAF_FN_DASHBOARD_ENTREGAS_MODO"(v_ves) || '|' || "ERP_CAF_FN_DASHBOARD_ENTREGAS_MODO"(v_mag), v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('DASHBOARD_ENTREGAS_MODO:XXX', 'AMBOS', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Modo por sede: una sede que no existe da 404', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('DASHBOARD_ENTREGAS_MODO:VES', 'AMBOS', 0, v_cod, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('DASHBOARD_ENTREGAS_MODO', 'AMBOS', 0, v_cod, v_msg);

    -- ===================================================== J. LA ENTREGA DE HOY: verificación, ingreso vehicular obligatorio, atención, guía y salida
    CALL "ERP_CAF_SOLICITUD_CREAR_DESPACHO"(v_ves, v_fhoy, 'Cliente Hoy S.A.', NULL, v_q1::TEXT, NULL, NULL, 'Vera Ventas', '999111222', v_pt::TEXT, pg_temp.cond(v_q1, NULL, 'Carlos Chofer', 'hoy-111'),
        'OF-7777', NULL, NULL, NULL, NULL, NULL, NULL, v_usd, v_s2, v_cs, v_cod, v_msg);
    PERFORM pg_temp.chk('Hoy: despacho del día creado', '100', v_cod::TEXT, v_msg);
    v_sp1 := pg_temp.sp(v_s2, v_q1);
    CALL "ERP_CAF_SOLICITUD_DECIDIR"(v_s2, v_paso, 'APROBADA', NULL, v_sp1::TEXT, v_ucd, v_cant, v_cod, v_msg);
    PERFORM pg_temp.chk('Hoy: aprobado', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Hoy: el conductor tiene 2 ítems de ingreso (identidad y placa) y 1 de salida (la guía)', '2|1|SAL_DESPACHO_GUIA',
        pg_temp.q('SELECT (SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_sp1 || ', ''INGRESO'', ''N'', ''N'')) || ''|'' || (SELECT COUNT(*) FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_sp1 || ', ''SALIDA'', ''N'', ''N'')) || ''|'' || (SELECT MAX("Codigo") FROM "ERP_CAF_PORTERIA_ITEMS_APLICABLES"(' || v_sp1 || ', ''SALIDA'', ''N'', ''N''))'), '');
    PERFORM pg_temp.chk('Hoy: Vigilancia de entregas tiene permiso sobre la persona del despacho', 'Y|N',
        "ERP_CAF_FN_PORTERIA_PERMISO"(v_uvp, v_sp1, v_ves) || '|' || "ERP_CAF_FN_PORTERIA_PERMISO"(v_usd, v_sp1, v_ves), '');
    CALL "ERP_CAF_PORTERIA_INGRESO_REGISTRAR"(v_sp1, pg_temp.items(v_sp1, 'INGRESO', ''), 'N', 'N', NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Hoy: Vigilancia verifica los datos del conductor (queda EN_ESPERA)', '100|EN_ESPERA', v_cod::TEXT || '|' || pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s2), v_msg);
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_PLAZAS"(v_s2, v_ual, 'N', 1, v_cod, v_msg);
    PERFORM pg_temp.chk('Hoy: el despacho exige ingreso vehicular — «sin ingreso vehicular» se rechaza (parámetro en N)', '409', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Hoy: el rechazo no dejó la disponibilidad confirmada', 'N', "ERP_CAF_FN_DISPONIBLE"(v_s2), '');
    CALL "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_PLAZAS"(v_s2, v_ual, 'Y', 1, v_cod, v_msg);
    PERFORM pg_temp.chk('Hoy: Almacén confirma CON ingreso vehicular (reserva la esclusa)', '100|true', v_cod::TEXT || '|' || pg_temp.q('SELECT (X."ID_Solicitud_Actual" = ' || v_s2 || ')::TEXT FROM "CAF_Exclusa" X WHERE X."ID_Catalogo_Sede" = ' || v_ves), v_msg);
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_s2, v_uvp, v_cod, v_msg);
    PERFORM pg_temp.chk('Hoy: Vigilancia valida el ingreso del vehículo', '100|INGRESO|DENTRO', v_cod::TEXT || '|' || pg_temp.q('SELECT O."Estado_Operativo" || ''|'' || P."Estado" FROM "CAF_Solicitud_Operacion" O JOIN "CAF_Solicitud_Persona" P ON P."ID_Solicitud" = O."ID_Solicitud" AND P."Es_Principal" = ''Y'' WHERE O."ID_Solicitud" = ' || v_s2), v_msg);
    CALL "ERP_CAF_PROVEEDOR_ATENDER"(v_s2, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Hoy: Almacén inicia la entrega del producto (atención)', '100|EN_ATENCION', v_cod::TEXT || '|' || pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s2), v_msg);
    CALL "ERP_CAF_PROVEEDOR_RECEPCION"(v_s2, 'CONFORME', NULL, v_ual, v_cod, v_msg);
    PERFORM pg_temp.chk('Hoy: Almacén termina la atención (RECEPCIONADO)', '100|RECEPCIONADO', v_cod::TEXT || '|' || pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s2), v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_sp1, pg_temp.items(v_sp1, 'SALIDA', 'SAL_DESPACHO_GUIA'), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Hoy: salir con la guía de remisión marcada como no conforme exige tratar la desviación (no es salida limpia)', 'true', (v_cod <> 100 OR v_res IS DISTINCT FROM 'CONFORME')::TEXT, v_msg);
    CALL "ERP_CAF_PORTERIA_SALIDA_REGISTRAR"(v_sp1, pg_temp.items(v_sp1, 'SALIDA', ''), NULL, NULL, NULL, NULL, NULL, NULL, NULL, v_uvp, v_reg, v_des, v_res, v_cod, v_msg);
    PERFORM pg_temp.chk('Hoy: con la guía revisada y conforme, el conductor sale', '100|SALIO|SALIO', v_cod::TEXT || '|' || pg_temp.q('SELECT "Estado" FROM "CAF_Solicitud_Persona" WHERE "ID_Solicitud_Persona" = ' || v_sp1) || '|' || pg_temp.q('SELECT "Estado_Operativo" FROM "CAF_Solicitud_Operacion" WHERE "ID_Solicitud" = ' || v_s2), v_msg);
    PERFORM pg_temp.chk('Hoy: al salir, la esclusa queda libre', '0', pg_temp.q('SELECT COUNT(*) FROM "CAF_Exclusa" X WHERE X."ID_Catalogo_Sede" = ' || v_ves || ' AND X."ID_Solicitud_Actual" = ' || v_s2), '');
    PERFORM pg_temp.chk('Hoy: el historial de Almacén lista el despacho', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_PROVEEDOR_HISTORIAL_ALMACEN"(' || v_ual || ', ' || v_ves || ', NULL, NULL, NULL, NULL, NULL, NULL) X WHERE X."ID_Solicitud" = ' || v_s2), '');

    -- ===================================================== K. «SIN INGRESO VEHICULAR» CONFIGURABLE, TAMBIÉN PARA PROVEEDORES
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('DESPACHO_PERMITE_SIN_INGRESO_VEHICULAR', 'Z', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Parámetro: solo Y o N', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('DESPACHO_PERMITE_SIN_INGRESO_VEHICULAR', 'Y', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Parámetro: el administrador permite «sin ingreso vehicular» para despachos', '100|Y', v_cod::TEXT || '|' || "ERP_CAF_PARAMETRO_VALOR"('DESPACHO_PERMITE_SIN_INGRESO_VEHICULAR'), v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('DESPACHO_PERMITE_SIN_INGRESO_VEHICULAR', 'N', 0, v_cod, v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('PROVEEDOR_PERMITE_SIN_INGRESO_VEHICULAR', 'N', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Parámetro: el administrador apaga «sin ingreso vehicular» para proveedores', '100|N', v_cod::TEXT || '|' || "ERP_CAF_PARAMETRO_VALOR"('PROVEEDOR_PERMITE_SIN_INGRESO_VEHICULAR'), v_msg);
    CALL "ERP_CAF_PARAMETRO_GUARDAR"('PROVEEDOR_PERMITE_SIN_INGRESO_VEHICULAR', 'Y', 0, v_cod, v_msg);

    -- ===================================================== L. PROVEEDORES NO CAMBIA
    PERFORM pg_temp.chk('Proveedores: sigue viendo el tipo Proveedor', '1', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_usp || ') WHERE "Codigo" = ''PROVEEDOR'' AND "Usable" = ''Y'''), '');
    PERFORM pg_temp.chk('Proveedores: el solicitante de despachos no ve Proveedor', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SOLICITUD_TIPOS_OPCIONES"(' || v_usd || ') WHERE "Codigo" = ''PROVEEDOR'''), '');
    PERFORM pg_temp.chk('Proveedores: el paso de aprobación sigue siendo el del Coordinador de proveedores', '1|LIC_CAF_COORD_PROVEEDOR',
        pg_temp.q('SELECT COUNT(*) || ''|'' || MAX(L."Codigo") FROM "Tipo_Acceso_Paso_Aprobacion" S JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = S."ID_Catalogo_Licencia" WHERE S."ID_Catalogo_Tipo_Acceso" = ' || v_prov), '');
END $$;

SELECT n || '|' || prueba || '|' || esperado || '|' || obtenido || '|' || CASE WHEN esperado = obtenido THEN 'OK' ELSE '*** FALLA ***' END || '|' || detalle FROM pruebas ORDER BY n;
SELECT 'RESULTADO: ' || COUNT(*) FILTER (WHERE esperado = obtenido) || ' de ' || COUNT(*) || CASE WHEN COUNT(*) FILTER (WHERE esperado <> obtenido) = 0 THEN ' OK' ELSE ' (HAY FALLAS)' END FROM pruebas;
ROLLBACK;
