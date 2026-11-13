-- =============================================================================
-- Archivo : PRUEBAS_FASE1_CHECKLIST_ADMIN.sql
-- Versión : V1.1 2026-11-11 (subtipos y tipos de ingreso, D-232) · V1.0 2026-11-10
-- Qué prueba: apoyo de la pantalla «Checklist de portería»: ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR, ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS y los
--   cambios de ERP_CATALOGO_ITEM_CHECKLIST_CREAR / _ACTUALIZAR (condición SOLO_PRINCIPAL; la etapa de un ítem usado no cambia).
-- Se ejecuta con psql -v ON_ERROR_STOP=1 -d <base> -f PRUEBAS_FASE1_CHECKLIST_ADMIN.sql (hace ROLLBACK al final). Resultado: «RESULTADO: N de N OK».
-- =============================================================================
SET client_encoding TO 'UTF8';
BEGIN;
SET LOCAL search_path TO "TRIANONSATELITAL_CAF_PRODD";
CREATE TEMP TABLE "_Prueba" ("N" SERIAL, "Caso" VARCHAR(200), "Esperado" VARCHAR(100), "Obtenido" VARCHAR(100), "Mensaje" VARCHAR(250));
CREATE FUNCTION pg_temp.chk(p_caso TEXT, p_esp TEXT, p_obt TEXT, p_msg TEXT DEFAULT NULL) RETURNS VOID LANGUAGE sql AS $$
    INSERT INTO "_Prueba" ("Caso","Esperado","Obtenido","Mensaje") VALUES (p_caso, p_esp, COALESCE(p_obt,'(nulo)'), p_msg); $$;
CREATE FUNCTION pg_temp.q(p_sql TEXT) RETURNS TEXT LANGUAGE plpgsql AS $$ DECLARE r TEXT; BEGIN EXECUTE p_sql INTO r; RETURN r; END $$;
-- Tipos (sin repetir) a los que aplica un ítem; Tipos_IDs trae «tipo» o «tipo:subtipo» y un tipo con subtipos aparece una vez por subtipo (D-234)
CREATE FUNCTION pg_temp.tp(p_item BIGINT) RETURNS TEXT LANGUAGE sql AS $$
    SELECT STRING_AGG(DISTINCT SPLIT_PART(x, ':', 1), ',' ORDER BY SPLIT_PART(x, ':', 1)) FROM "ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR"() L, UNNEST(STRING_TO_ARRAY(L."Tipos_IDs", ',')) x WHERE L."ID_Catalogo_Item_Checklist" = p_item $$;
CREATE FUNCTION pg_temp.tt(p_cod TEXT) RETURNS BIGINT LANGUAGE sql AS $$ SELECT "ID_Catalogo_Tipo_Acceso" FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = p_cod $$;

DO $$
DECLARE
    v_cod INT; v_msg VARCHAR(250); v_id BIGINT; v_id2 BIGINT; v_t1 BIGINT := pg_temp.tt('VISITA_EXTERNA'); v_t2 BIGINT := pg_temp.tt('CONTRATISTA'); v_t3 BIGINT := pg_temp.tt('PROVEEDOR');
    v_n0 BIGINT; v_tr BIGINT; v_ay BIGINT; v_tn BIGINT; v_base BIGINT;
BEGIN
    -- ---------- LISTAR
    SELECT COUNT(*) INTO v_n0 FROM "Catalogo_Item_Checklist" WHERE "Eliminado" = 'N';
    PERFORM pg_temp.chk('Listar: trae todos los ítems no eliminados', v_n0::TEXT, pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR"()'));
    PERFORM pg_temp.chk('Listar: la identidad aplica a los 3 tipos y es de ingreso', 'INGRESO|3',
        pg_temp.q('SELECT "Etapa" || ''|'' || (SELECT COUNT(DISTINCT SPLIT_PART(x, '':'', 1)) FROM UNNEST(STRING_TO_ARRAY("Tipos_IDs", '','')) x) FROM "ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR"() WHERE "Codigo" = ''ING_IDENTIDAD'''));
    PERFORM pg_temp.chk('Listar: el ítem de salida de proveedor es solo del transportista (siempre + subtipo)', 'SALIDA|SIEMPRE|' || v_t3 || ':' || pg_temp.q('SELECT "ID_Tipo_Acceso_Subtipo" FROM "Tipo_Acceso_Subtipo" WHERE "Codigo" = ''TRANSPORTISTA'''),
        pg_temp.q('SELECT "Etapa" || ''|'' || "Condicion" || ''|'' || "Tipos_IDs" FROM "ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR"() WHERE "Codigo" = ''SAL_PROVEEDOR_DOCUMENTOS'''));
    PERFORM pg_temp.chk('Listar: INGRESO va antes que SALIDA', 'INGRESO',
        pg_temp.q('SELECT "Etapa" FROM "ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR"() LIMIT 1'));

    -- ---------- CREAR / ACTUALIZAR con la condición nueva
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_CREAR"('PRB_CK_1', 'Ítem de prueba', NULL, 'SALIDA', 'SOLO_PRINCIPAL', 'N', 99, 'Y', 0, v_id, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: acepta la condición SOLO_PRINCIPAL', '100', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_CREAR"('PRB_CK_2', 'Otro', NULL, 'SALIDA', 'CUALQUIERA', 'N', 99, 'Y', 0, v_id2, v_cod, v_msg);
    PERFORM pg_temp.chk('Crear: una condición inventada se rechaza', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR"(v_id, 'PRB_CK_1', 'Ítem de prueba (editado)', 'Ayuda', 'SALIDA', 'SIEMPRE', 'Y', 98, 'Y', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Actualizar: cambia la condición a SIEMPRE', '100|SIEMPRE|Y|98', v_cod || '|' || pg_temp.q('SELECT "Condicion" || ''|'' || "Es_Critico" || ''|'' || "Orden" FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = ' || v_id), v_msg);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR"(v_id, 'PRB_CK_1', 'Ítem de prueba', NULL, 'INGRESO', 'SOLO_PRINCIPAL', 'N', 98, 'Y', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Actualizar: sin uso, la etapa sí se puede cambiar', '100|INGRESO', v_cod || '|' || pg_temp.q('SELECT "Etapa" FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = ' || v_id), v_msg);

    -- Un ítem «usado»: se simula una respuesta guardada (sin las llaves foráneas, solo para esta prueba)
    SET LOCAL session_replication_role = replica;
    INSERT INTO "CAF_Registro_Checklist" ("ID_Registro_Acceso","ID_Catalogo_Item_Checklist","Cumple","UsuarioID_Create") VALUES (987654321, v_id, 'Y', 0);
    SET LOCAL session_replication_role = origin;
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR"(v_id, 'PRB_CK_1', 'Ítem de prueba', NULL, 'SALIDA', 'SOLO_PRINCIPAL', 'N', 98, 'Y', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Actualizar: un ítem ya usado no cambia de etapa', '409|INGRESO', v_cod || '|' || pg_temp.q('SELECT "Etapa" FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = ' || v_id), v_msg);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR"(v_id, 'PRB_CK_1', 'Usado y editado', 'Ayuda nueva', 'INGRESO', 'ZONA_EXIGE_EPP', 'Y', 50, 'N', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Actualizar: un ítem usado sí cambia su texto, condición y estado', '100|Usado y editado|ZONA_EXIGE_EPP|N', v_cod || '|' || pg_temp.q('SELECT "Descripcion" || ''|'' || "Condicion" || ''|'' || "Activo" FROM "Catalogo_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = ' || v_id), v_msg);
    PERFORM pg_temp.chk('Listar: cuenta los usos', '1', pg_temp.q('SELECT "Usos" FROM "ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR"() WHERE "ID_Catalogo_Item_Checklist" = ' || v_id));
    UPDATE "Catalogo_Item_Checklist" SET "Activo" = 'Y' WHERE "ID_Catalogo_Item_Checklist" = v_id;

    -- ---------- ASIGNAR TIPOS
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, v_t1 || ',' || v_t3, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: queda en visita externa y proveedor', '100|' || v_t1 || ',' || v_t3, v_cod || '|' || pg_temp.tp(v_id), v_msg);
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, v_t2::TEXT, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: reemplaza (solo contratista)', '100|' || v_t2, v_cod || '|' || pg_temp.tp(v_id), v_msg);
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, v_t3 || ', ' || v_t2, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: acepta espacios y reactiva sin duplicar filas (4 filas: visita externa con borrado lógico y proveedor una por subtipo)', '100|' || LEAST(v_t2, v_t3) || ',' || GREATEST(v_t2, v_t3) || '|4', v_cod || '|' || pg_temp.tp(v_id) || '|' || pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = ' || v_id), v_msg);
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, '', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: lista vacía = ningún tipo (ya no se ofrece a nadie)', '100|(nulo)', v_cod || '|' || COALESCE(pg_temp.tp(v_id), '(nulo)'), v_msg);
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, 'a,b', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: lista mal escrita', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(999999, '1', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: ítem inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, '1', -1, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: usuario no válido', '400', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, '999999', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: un tipo que no existe se ignora', '100|(nulo)', v_cod || '|' || COALESCE(pg_temp.tp(v_id), '(nulo)'), v_msg);

    -- El ítem asignado aparece en el checklist de verdad (lo que ve Vigilancia)
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, v_t3::TEXT, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Efecto: un ítem asignado a proveedor se ofrece a ese tipo, una fila por subtipo (TIPO_ACCESO_ITEM_CHECKLIST)', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE"(' || v_t3 || ') WHERE "ID_Catalogo_Item_Checklist" = ' || v_id));
    PERFORM pg_temp.chk('Efecto: y no a otro tipo', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE"(' || v_t1 || ') WHERE "ID_Catalogo_Item_Checklist" = ' || v_id));

    -- ---------- SUBTIPOS (D-232)
    SELECT "ID_Tipo_Acceso_Subtipo" INTO v_tr FROM "Tipo_Acceso_Subtipo" WHERE "ID_Catalogo_Tipo_Acceso" = v_t3 AND "Codigo" = 'TRANSPORTISTA';
    SELECT "ID_Tipo_Acceso_Subtipo" INTO v_ay FROM "Tipo_Acceso_Subtipo" WHERE "ID_Catalogo_Tipo_Acceso" = v_t3 AND "Codigo" = 'AYUDANTE_DESCARGA';
    PERFORM pg_temp.chk('Subtipos: el proveedor tiene transportista y ayudante', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SUBTIPO_LISTAR"() WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_t3));
    PERFORM pg_temp.chk('Subtipos: los otros tipos no tienen', '0', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SUBTIPO_LISTAR"() WHERE "ID_Catalogo_Tipo_Acceso" <> ' || v_t3));
    PERFORM pg_temp.chk('Migración: documentos de salida quedó Siempre + transportista', 'SIEMPRE|' || v_t3 || ':' || v_tr,
        pg_temp.q('SELECT "Condicion" || ''|'' || "Tipos_IDs" FROM "ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR"() WHERE "Codigo" = ''SAL_PROVEEDOR_DOCUMENTOS'''));
    PERFORM pg_temp.chk('Migración: la placa quedó Siempre + transportista', 'SIEMPRE|' || v_t3 || ':' || v_tr,
        pg_temp.q('SELECT "Condicion" || ''|'' || "Tipos_IDs" FROM "ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR"() WHERE "Codigo" = ''ING_PLACA'''));
    PERFORM pg_temp.chk('Migración: la salida del ayudante quedó Siempre + ayudante', 'SIEMPRE|' || v_t3 || ':' || v_ay,
        pg_temp.q('SELECT "Condicion" || ''|'' || "Tipos_IDs" FROM "ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR"() WHERE "Codigo" = ''SAL_AYUDANTE_VERIFICADO'''));
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, v_t1 || ',' || v_t3 || ':' || v_ay, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar con subtipo: visita (todos) y proveedor solo ayudantes', '100|2|' || v_ay, v_cod || '|' ||
        pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = ' || v_id || ' AND "Eliminado" = ''N''') || '|' ||
        pg_temp.q('SELECT "ID_Tipo_Acceso_Subtipo" FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_t3 || ' AND "ID_Catalogo_Item_Checklist" = ' || v_id), v_msg);
    PERFORM pg_temp.chk('Asignar con subtipo: visita queda sin subtipo', '(nulo)', COALESCE(pg_temp.q('SELECT "ID_Tipo_Acceso_Subtipo" FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_t1 || ' AND "ID_Catalogo_Item_Checklist" = ' || v_id), '(nulo)'));
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, v_t3 || ':' || v_ay || ',' || v_t1 || ':' || v_ay, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: subtipo de otro tipo -> 400', '400', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Asignar: el 400 no cambió nada (se valida antes de aplicar)', '2|' || v_ay, pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = ' || v_id || ' AND "Eliminado" = ''N''') || '|' ||
        pg_temp.q('SELECT "ID_Tipo_Acceso_Subtipo" FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_t3 || ' AND "ID_Catalogo_Item_Checklist" = ' || v_id));
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, v_t3::TEXT, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: volver a «todos» = todos los subtipos activos (D-234)', '100|2', v_cod || '|' || pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_t3 || ' AND "ID_Catalogo_Item_Checklist" = ' || v_id || ' AND "Eliminado" = ''N'' AND "ID_Tipo_Acceso_Subtipo" IS NOT NULL'), v_msg);
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, v_t3 || ':x', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: formato inválido con dos puntos', '400', v_cod::TEXT, v_msg);

    -- ---------- TIPOS DE INGRESO (D-232)
    PERFORM pg_temp.chk('Tipos: el listado trae los no eliminados', pg_temp.q('SELECT COUNT(*) FROM "Catalogo_Tipo_Acceso" WHERE "Eliminado" = ''N'''), pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR"()'));
    PERFORM pg_temp.chk('Tipos: el proveedor muestra sus subtipos', 'Conductor, Ayudante de descarga', pg_temp.q('SELECT "Subtipos" FROM "ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR"() WHERE "Codigo" = ''PROVEEDOR'''));
    SELECT "ID_Catalogo_Tipo_Acceso" INTO v_base FROM "Catalogo_Tipo_Acceso" WHERE "Codigo" = 'VISITA_EXTERNA';
    CALL "ERP_CATALOGO_TIPO_ACCESO_CREAR"('PRB_TIPO', 'Tipo de prueba', 'Y', 'N', 90, 'Y', 0, v_tn, v_cod, v_msg);
    PERFORM pg_temp.chk('Tipos: se crea un tipo nuevo', '100', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Tipos: recién creado no tiene pasos ni ítems', '0|0', pg_temp.q('SELECT "Pasos" FROM "ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR"() WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_tn) || '|' || pg_temp.q('SELECT "Items" FROM "ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR"() WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_tn));
    PERFORM pg_temp.chk('Tipos: la visita externa tiene pasos (base a copiar)', '1', CASE WHEN pg_temp.q('SELECT "Pasos" FROM "ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR"() WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_base)::INT > 0 THEN '1' ELSE '0' END);
    CALL "ERP_CAF_TIPO_ACCESO_PREPARAR"(v_tn, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparar: copia los pasos y el checklist de Visita externa', '100|' || pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Paso_Aprobacion" WHERE "Eliminado" = ''N'' AND "ID_Catalogo_Tipo_Acceso" = ' || v_base) || '|' ||
        pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" WHERE "Eliminado" = ''N'' AND "ID_Tipo_Acceso_Subtipo" IS NULL AND "ID_Catalogo_Tipo_Acceso" = ' || v_base),
        v_cod || '|' || pg_temp.q('SELECT "Pasos" FROM "ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR"() WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_tn) || '|' || pg_temp.q('SELECT "Items" FROM "ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR"() WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_tn), v_msg);
    CALL "ERP_CAF_TIPO_ACCESO_PREPARAR"(v_tn, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparar: repetir no duplica', pg_temp.q('SELECT "Pasos" FROM "ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR"() WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_base), pg_temp.q('SELECT "Pasos" FROM "ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR"() WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_tn));
    CALL "ERP_CAF_TIPO_ACCESO_PREPARAR"(999999, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparar: tipo inexistente', '404', v_cod::TEXT, v_msg);
    CALL "ERP_CAF_TIPO_ACCESO_PREPARAR"(v_tn, -1, v_cod, v_msg);
    PERFORM pg_temp.chk('Preparar: usuario no válido', '400', v_cod::TEXT, v_msg);

    -- ---------- D-234: el checklist de un tipo con subtipos se define por subtipo
    v_tr := pg_temp.q('SELECT "ID_Tipo_Acceso_Subtipo" FROM "Tipo_Acceso_Subtipo" WHERE "Codigo" = ''TRANSPORTISTA''')::BIGINT;
    v_ay := pg_temp.q('SELECT "ID_Tipo_Acceso_Subtipo" FROM "Tipo_Acceso_Subtipo" WHERE "Codigo" = ''AYUDANTE_DESCARGA''')::BIGINT;
    v_id := pg_temp.q('SELECT "ID_Catalogo_Item_Checklist" FROM "Catalogo_Item_Checklist" WHERE "Codigo" = ''ING_PLACA''')::BIGINT;
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, v_t3 || ':' || v_tr, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar por subtipo: la placa solo al transportista', '100|' || v_tr, v_cod || '|' || pg_temp.q('SELECT STRING_AGG("ID_Tipo_Acceso_Subtipo"::TEXT, '','') FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = ' || v_id || ' AND "ID_Catalogo_Tipo_Acceso" = ' || v_t3 || ' AND "Eliminado" = ''N'''), v_msg);
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, v_t3 || ':' || v_tr || ',' || v_t3 || ':' || v_ay, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar por subtipo: varios subtipos del mismo tipo', '100|2', v_cod || '|' || pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = ' || v_id || ' AND "ID_Catalogo_Tipo_Acceso" = ' || v_t3 || ' AND "Eliminado" = ''N'''), v_msg);
    CALL "ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS"(v_id, v_t3 || ':99999', 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Asignar: subtipo que no es de ese tipo', '400', v_cod::TEXT, v_msg);
    PERFORM pg_temp.chk('Asignar: tras ese error no cambió nada', '2', pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Item_Checklist" = ' || v_id || ' AND "ID_Catalogo_Tipo_Acceso" = ' || v_t3 || ' AND "Eliminado" = ''N'''), '');
    -- Primer subtipo de un tipo que no tenía: hereda el checklist del tipo
    v_base := pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_t1 || ' AND "Eliminado" = ''N''')::BIGINT;
    CALL "ERP_CAF_SUBTIPO_CREAR"(v_t1, 'GENERAL', 'General', NULL, 0, v_id2, v_cod, v_msg);
    PERFORM pg_temp.chk('Primer subtipo: nace predeterminado y recibe el checklist del tipo', '100|Y|' || v_base || '|0',
        v_cod || '|' || pg_temp.q('SELECT "Es_Predeterminado" FROM "Tipo_Acceso_Subtipo" WHERE "ID_Tipo_Acceso_Subtipo" = ' || v_id2) || '|' ||
        pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Tipo_Acceso_Subtipo" = ' || v_id2 || ' AND "Eliminado" = ''N''') || '|' ||
        pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_t1 || ' AND "ID_Tipo_Acceso_Subtipo" IS NULL AND "Eliminado" = ''N'''), v_msg);
    CALL "ERP_CAF_SUBTIPO_CREAR"(v_t1, 'SEGUNDO', 'Segundo', v_id2, 0, v_id, v_cod, v_msg);
    PERFORM pg_temp.chk('Segundo subtipo: copia el checklist del que se indica', '100|' || v_base, v_cod || '|' || pg_temp.q('SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" WHERE "ID_Tipo_Acceso_Subtipo" = ' || v_id || ' AND "Eliminado" = ''N'''), v_msg);
    CALL "ERP_CAF_SUBTIPO_PREDETERMINADO"(v_id, 0, v_cod, v_msg);
    PERFORM pg_temp.chk('Predeterminado: pasa al segundo y el primero deja de serlo', '100|Y|N', v_cod || '|' || pg_temp.q('SELECT "Es_Predeterminado" FROM "Tipo_Acceso_Subtipo" WHERE "ID_Tipo_Acceso_Subtipo" = ' || v_id) || '|' || pg_temp.q('SELECT "Es_Predeterminado" FROM "Tipo_Acceso_Subtipo" WHERE "ID_Tipo_Acceso_Subtipo" = ' || v_id2), v_msg);
    PERFORM pg_temp.chk('Listar subtipos: con inactivos incluye todos los del tipo', '2', pg_temp.q('SELECT COUNT(*) FROM "ERP_CAF_SUBTIPO_LISTAR"(''Y'') WHERE "ID_Catalogo_Tipo_Acceso" = ' || v_t1), '');
END $$;

SELECT "N", "Caso", "Esperado", "Obtenido", CASE WHEN "Esperado" = "Obtenido" THEN 'OK' ELSE '*** FALLA ***' END AS "Estado", "Mensaje" FROM "_Prueba" ORDER BY "N";
SELECT 'RESULTADO: ' || COUNT(*) FILTER (WHERE "Esperado" = "Obtenido") || ' de ' || COUNT(*) || ' OK' AS "Resumen" FROM "_Prueba";
ROLLBACK;
