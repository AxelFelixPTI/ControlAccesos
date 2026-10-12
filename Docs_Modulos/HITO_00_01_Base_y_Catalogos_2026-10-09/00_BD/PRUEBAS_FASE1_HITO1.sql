-- =============================================================================
-- Archivo : PRUEBAS_FASE1_HITO1.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : TRIANONSATELITAL_CAF_PRODD (usa CAF_GOVERNANCE para preparar datos)
-- Hito    : 1 - Catálogos del módulo | Fase 1 - Procedimientos
-- Versión : V1.0 2026-10-11
-- =============================================================================
-- Qué prueba: las 43 rutinas del Hito 1 (6 catálogos, el pivot de checklist y
-- CAF_Persona_Externa): respuestas 100/101/400/404, reglas de negocio y que lo
-- guardado sea lo que se espera (mayúsculas, valores por defecto, filtros).
--
-- Cómo se ejecuta (PowerShell, desde la carpeta 00_BD):
--   psql -v ON_ERROR_STOP=1 -d accesos_piloto -f PRUEBAS_FASE1_HITO1.sql
--
-- Requisitos: scripts 01 a 05, los 9 SP_GOVERNANCE_* y los 8 SP_CAF_* cargados.
-- No depende de los datos de la carga inicial: crea sus propias sedes, tipos de
-- documento y registros (códigos PRB_H1_*), y al final hace ROLLBACK, así que
-- la base queda exactamente como estaba.
-- Resultado esperado: la última consulta dice "RESULTADO: N de N OK".
-- =============================================================================

SET client_encoding TO 'UTF8';
BEGIN;
SET LOCAL search_path TO "TRIANONSATELITAL_CAF_PRODD";

CREATE TEMP TABLE "_Prueba" (
    "N"         SERIAL,
    "Bloque"    VARCHAR(40),
    "Caso"      VARCHAR(200),
    "Esperado"  VARCHAR(100),
    "Obtenido"  VARCHAR(100),
    "Mensaje"   VARCHAR(250)
);
CREATE TEMP TABLE "_Fixture" ("Clave" VARCHAR(40) PRIMARY KEY, "ID" BIGINT);

CREATE FUNCTION pg_temp.reg(p_bloque TEXT, p_caso TEXT, p_esperado TEXT, p_obtenido TEXT, p_mensaje TEXT DEFAULT NULL)
RETURNS VOID LANGUAGE sql AS $$
    INSERT INTO "_Prueba" ("Bloque","Caso","Esperado","Obtenido","Mensaje")
    VALUES (p_bloque, p_caso, p_esperado, COALESCE(p_obtenido,'(nulo)'), p_mensaje);
$$;
CREATE FUNCTION pg_temp.fx_set(p_clave TEXT, p_id BIGINT)
RETURNS VOID LANGUAGE sql AS $$ INSERT INTO "_Fixture" VALUES (p_clave, p_id); $$;
CREATE FUNCTION pg_temp.fx(p_clave TEXT)
RETURNS BIGINT LANGUAGE sql AS $$ SELECT "ID" FROM "_Fixture" WHERE "Clave" = p_clave; $$;


-- -----------------------------------------------------------------------------
-- 0. Preparación: datos propios en CAF_GOVERNANCE (con sus procedimientos)
-- -----------------------------------------------------------------------------
DO $$
DECLARE v_id BIGINT; v_r INT; v_m VARCHAR;
BEGIN
    CALL "CAF_GOVERNANCE"."ERP_CATALOGO_SEDE_CREAR"('PRB_H1_SEDE_A','Sede de prueba A',NULL,901,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('0 Preparación','Sede A activa','100', v_r::text, v_m); PERFORM pg_temp.fx_set('sedeA', v_id);
    CALL "CAF_GOVERNANCE"."ERP_CATALOGO_SEDE_CREAR"('PRB_H1_SEDE_B','Sede de prueba B',NULL,902,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('0 Preparación','Sede B activa','100', v_r::text, v_m); PERFORM pg_temp.fx_set('sedeB', v_id);
    CALL "CAF_GOVERNANCE"."ERP_CATALOGO_SEDE_CREAR"('PRB_H1_SEDE_INACT','Sede de prueba inactiva',NULL,903,'N',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('0 Preparación','Sede inactiva','100', v_r::text, v_m); PERFORM pg_temp.fx_set('sedeI', v_id);
    CALL "CAF_GOVERNANCE"."ERP_CATALOGO_TIPO_DOCUMENTO_CREAR"('PRB_H1_DOC','Documento de prueba (8 dígitos)',8,8,'Y',901,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('0 Preparación','Tipo de documento numérico','100', v_r::text, v_m); PERFORM pg_temp.fx_set('docN', v_id);
    CALL "CAF_GOVERNANCE"."ERP_CATALOGO_TIPO_DOCUMENTO_CREAR"('PRB_H1_PAS','Pasaporte de prueba',6,12,'N',902,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('0 Preparación','Tipo de documento alfanumérico','100', v_r::text, v_m); PERFORM pg_temp.fx_set('docP', v_id);
END $$;


-- -----------------------------------------------------------------------------
-- A. Catalogo_Tipo_Acceso (plantilla de catálogo + banderas)
-- -----------------------------------------------------------------------------
DO $$
DECLARE v_id BIGINT; v_r INT; v_m VARCHAR; v_n BIGINT; v_t TEXT; v_ta BIGINT;
BEGIN
    CALL "ERP_CATALOGO_TIPO_ACCESO_CREAR"('PRB_H1_TA_1','Tipo de acceso de prueba','Y','Y',901,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','CREAR válido','100', v_r::text, v_m); PERFORM pg_temp.fx_set('ta1', v_id);
    CALL "ERP_CATALOGO_TIPO_ACCESO_CREAR"('prb_h1_ta_1','Repetido en minúsculas','Y','Y',901,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','CREAR código repetido (minúsculas)','101', v_r::text, v_m);
    CALL "ERP_CATALOGO_TIPO_ACCESO_CREAR"('  ','Sin código','Y','Y',901,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','CREAR código vacío','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_TIPO_ACCESO_CREAR"('PRB_H1_TA_X','Bandera inválida','X','N',901,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','CREAR Requiere_Aprobacion = X','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_TIPO_ACCESO_CREAR"('PRB_H1_TA_X','Usuario inválido','Y','N',901,'Y',-1, v_id, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','CREAR UsuarioID = -1','400', v_r::text, v_m);

    -- Banderas omitidas: se guardan con el DEFAULT de la tabla (Y y N), código en MAYÚSCULAS
    CALL "ERP_CATALOGO_TIPO_ACCESO_CREAR"('prb_h1_ta_2','Tipo inactivo',NULL,NULL,902,'N',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','CREAR con banderas nulas e inactivo','100', v_r::text, v_m); PERFORM pg_temp.fx_set('ta2', v_id);
    SELECT "Codigo" || '|' || "Requiere_Aprobacion" || '|' || "Disponible" INTO v_t FROM "ERP_CATALOGO_TIPO_ACCESO_DETALLE"(v_id);
    PERFORM pg_temp.reg('A Tipo de acceso','Guardado: código en mayúsculas y defaults Y/N','PRB_H1_TA_2|Y|N', v_t);

    v_ta := pg_temp.fx('ta1');
    SELECT "Nombre_Usuario" INTO v_t FROM "ERP_CATALOGO_TIPO_ACCESO_DETALLE"(v_ta);
    PERFORM pg_temp.reg('A Tipo de acceso','DETALLE: UsuarioID 0 se muestra como Sistema','Sistema', v_t);
    CALL "ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR"(v_ta,'PRB_H1_TA_1','Tipo de acceso editado','N','Y',901,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','ACTUALIZAR válido','100', v_r::text, v_m);
    SELECT "Requiere_Aprobacion" || '|' || COALESCE("UsuarioID_Update"::text,'nulo') INTO v_t FROM "ERP_CATALOGO_TIPO_ACCESO_DETALLE"(v_ta);
    PERFORM pg_temp.reg('A Tipo de acceso','ACTUALIZAR guarda bandera y auditoría','N|0', v_t);
    CALL "ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR"(-999,'PRB_H1_TA_9','No existe','Y','Y',1,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','ACTUALIZAR ID inexistente','404', v_r::text, v_m);
    CALL "ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR"(v_ta,'PRB_H1_TA_2','Código de otro','Y','Y',1,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','ACTUALIZAR al código de otro registro','101', v_r::text, v_m);

    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TIPO_ACCESO_DROPDOWN"() WHERE "Codigo" LIKE 'PRB_H1_TA_%';
    PERFORM pg_temp.reg('A Tipo de acceso','DROPDOWN solo muestra activos','1', v_n::text);
    SELECT "Disponible" INTO v_t FROM "ERP_CATALOGO_TIPO_ACCESO_DROPDOWN"() WHERE "ID_Catalogo" = v_ta;
    PERFORM pg_temp.reg('A Tipo de acceso','DROPDOWN devuelve Disponible','Y', v_t);

    CALL "ERP_CATALOGO_TIPO_ACCESO_ELIMINAR"(pg_temp.fx('ta2'), 0, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','ELIMINAR sin uso','100', v_r::text, v_m);
    CALL "ERP_CATALOGO_TIPO_ACCESO_ELIMINAR"(pg_temp.fx('ta2'), 0, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','ELIMINAR por segunda vez','404', v_r::text, v_m);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TIPO_ACCESO_LISTAR"() WHERE "ID_Catalogo" = pg_temp.fx('ta2');
    PERFORM pg_temp.reg('A Tipo de acceso','LISTAR no muestra eliminados','0', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TIPO_ACCESO_LISTAR"('Y') WHERE "ID_Catalogo" = pg_temp.fx('ta2');
    PERFORM pg_temp.reg('A Tipo de acceso','LISTAR(''Y'') sí los muestra','1', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TIPO_ACCESO_DETALLE"(pg_temp.fx('ta2'));
    PERFORM pg_temp.reg('A Tipo de acceso','DETALLE no filtra eliminados','1', v_n::text);
    CALL "ERP_CATALOGO_TIPO_ACCESO_CREAR"('PRB_H1_TA_2','Reutiliza código eliminado','Y','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('A Tipo de acceso','CREAR con el código de un eliminado (D-24)','101', v_r::text, v_m);
END $$;


-- -----------------------------------------------------------------------------
-- B. Catalogo_Zona_Acceso (sede en el schema transversal, código único por sede)
-- -----------------------------------------------------------------------------
DO $$
DECLARE v_id BIGINT; v_r INT; v_m VARCHAR; v_n BIGINT; v_t TEXT;
        v_a BIGINT := pg_temp.fx('sedeA'); v_b BIGINT := pg_temp.fx('sedeB'); v_i BIGINT := pg_temp.fx('sedeI');
BEGIN
    CALL "ERP_CATALOGO_ZONA_ACCESO_CREAR"('PRB_H1_ALMACEN','Almacén de prueba', v_a,'OPERATIVA','Y','Y',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','CREAR válido en sede A','100', v_r::text, v_m); PERFORM pg_temp.fx_set('zA1', v_id);
    CALL "ERP_CATALOGO_ZONA_ACCESO_CREAR"('PRB_H1_ALMACEN','Mismo código, otra sede', v_b,'OPERATIVA','N','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','CREAR mismo código en sede B (único por sede)','100', v_r::text, v_m); PERFORM pg_temp.fx_set('zB1', v_id);
    CALL "ERP_CATALOGO_ZONA_ACCESO_CREAR"('prb_h1_almacen','Repetido en sede A', v_a,'OPERATIVA','N','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','CREAR código repetido en la misma sede','101', v_r::text, v_m);
    CALL "ERP_CATALOGO_ZONA_ACCESO_CREAR"('PRB_H1_Z_X','Sede inactiva', v_i,'OPERATIVA','N','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','CREAR en sede inactiva','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_ZONA_ACCESO_CREAR"('PRB_H1_Z_X','Sede inexistente', -999,'OPERATIVA','N','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','CREAR en sede inexistente','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_ZONA_ACCESO_CREAR"('PRB_H1_Z_X','Sin sede', NULL,'OPERATIVA','N','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','CREAR sin sede','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_ZONA_ACCESO_CREAR"('PRB_H1_Z_X','Tipo inválido', v_a,'MIXTA','N','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','CREAR Tipo_Zona fuera de la lista','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_ZONA_ACCESO_CREAR"('PRB_H1_Z_X','Bandera inválida', v_a,'OPERATIVA','S','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','CREAR Exige_SCTR = S','400', v_r::text, v_m);

    CALL "ERP_CATALOGO_ZONA_ACCESO_CREAR"('PRB_H1_OFICINA','Oficinas', v_a,' administrativa ',NULL,NULL,2,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','CREAR tipo en minúsculas y banderas nulas','100', v_r::text, v_m); PERFORM pg_temp.fx_set('zA2', v_id);
    SELECT "Tipo_Zona" || '|' || "Exige_SCTR" || '|' || "Exige_EPP" INTO v_t FROM "ERP_CATALOGO_ZONA_ACCESO_DETALLE"(v_id);
    PERFORM pg_temp.reg('B Zona','Guardado: tipo en mayúsculas y defaults N','ADMINISTRATIVA|N|N', v_t);
    CALL "ERP_CATALOGO_ZONA_ACCESO_CREAR"('PRB_H1_INACTIVA','Zona inactiva', v_a,'OPERATIVA','N','N',3,'N',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','CREAR zona inactiva','100', v_r::text, v_m);

    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_ZONA_ACCESO_LISTAR"(v_a) WHERE "ID_Catalogo_Sede" <> v_a;
    PERFORM pg_temp.reg('B Zona','LISTAR(sede A) no trae zonas de otra sede','0', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_ZONA_ACCESO_LISTAR"(v_a);
    PERFORM pg_temp.reg('B Zona','LISTAR(sede A) trae activas e inactivas','3', v_n::text);
    SELECT "Codigo_Sede" INTO v_t FROM "ERP_CATALOGO_ZONA_ACCESO_DETALLE"(pg_temp.fx('zA1'));
    PERFORM pg_temp.reg('B Zona','DETALLE trae el código de la sede (cruce de schema)','PRB_H1_SEDE_A', v_t);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_ZONA_ACCESO_DROPDOWN"(v_a);
    PERFORM pg_temp.reg('B Zona','DROPDOWN(sede A): solo activas de esa sede','2', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_ZONA_ACCESO_DROPDOWN"(NULL);
    PERFORM pg_temp.reg('B Zona','DROPDOWN sin sede no devuelve nada','0', v_n::text);
    SELECT "Exige_SCTR" || '|' || "Exige_EPP" INTO v_t FROM "ERP_CATALOGO_ZONA_ACCESO_DROPDOWN"(v_a) WHERE "ID_Catalogo" = pg_temp.fx('zA1');
    PERFORM pg_temp.reg('B Zona','DROPDOWN devuelve Exige_SCTR y Exige_EPP','Y|Y', v_t);

    CALL "ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR"(pg_temp.fx('zA1'),'PRB_H1_ALMACEN','Almacén', v_b,'OPERATIVA','Y','Y',1,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','ACTUALIZAR a una sede donde el código ya existe','101', v_r::text, v_m);
    CALL "ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR"(pg_temp.fx('zA1'),'PRB_H1_ALMACEN','Almacén', v_a,'OPERATIVA','Y','N',1,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','ACTUALIZAR válido (Exige_EPP a N)','100', v_r::text, v_m);
    CALL "ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR"(pg_temp.fx('zA2'),'PRB_H1_OFICINA','Oficinas', v_i,'ADMINISTRATIVA','N','N',2,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','ACTUALIZAR a sede inactiva: permitido (igual que Personal)','100', v_r::text, v_m);
    CALL "ERP_CATALOGO_ZONA_ACCESO_ELIMINAR"(pg_temp.fx('zB1'), 0, v_r, v_m);
    PERFORM pg_temp.reg('B Zona','ELIMINAR','100', v_r::text, v_m);
END $$;


-- -----------------------------------------------------------------------------
-- C. Catalogo_Motivo_Visita
-- -----------------------------------------------------------------------------
DO $$
DECLARE v_id BIGINT; v_r INT; v_m VARCHAR; v_t TEXT;
BEGIN
    CALL "ERP_CATALOGO_MOTIVO_VISITA_CREAR"('PRB_H1_REUNION','Reunión de trabajo','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('C Motivo','CREAR válido','100', v_r::text, v_m);
    CALL "ERP_CATALOGO_MOTIVO_VISITA_CREAR"('PRB_H1_OTRO','Otro','Y',99,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('C Motivo','CREAR motivo Otro','100', v_r::text, v_m); PERFORM pg_temp.fx_set('mOtro', v_id);
    CALL "ERP_CATALOGO_MOTIVO_VISITA_CREAR"('PRB_H1_M_X','Bandera inválida','Q',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('C Motivo','CREAR Es_Otro = Q','400', v_r::text, v_m);
    SELECT "Es_Otro" INTO v_t FROM "ERP_CATALOGO_MOTIVO_VISITA_DROPDOWN"() WHERE "ID_Catalogo" = pg_temp.fx('mOtro');
    PERFORM pg_temp.reg('C Motivo','DROPDOWN devuelve Es_Otro','Y', v_t);
    CALL "ERP_CATALOGO_MOTIVO_VISITA_ACTUALIZAR"(pg_temp.fx('mOtro'),'PRB_H1_OTRO','Otro motivo','Y',99,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('C Motivo','ACTUALIZAR válido','100', v_r::text, v_m);
    SELECT "Descripcion" INTO v_t FROM "ERP_CATALOGO_MOTIVO_VISITA_DETALLE"(pg_temp.fx('mOtro'));
    PERFORM pg_temp.reg('C Motivo','DETALLE refleja la edición','Otro motivo', v_t);
    SELECT COUNT(*)::text INTO v_t FROM "ERP_CATALOGO_MOTIVO_VISITA_LISTAR"() WHERE "Codigo" LIKE 'PRB_H1_%';
    PERFORM pg_temp.reg('C Motivo','LISTAR trae los 2 creados','2', v_t);
    CALL "ERP_CATALOGO_MOTIVO_VISITA_ELIMINAR"(pg_temp.fx('mOtro'), 0, v_r, v_m);
    PERFORM pg_temp.reg('C Motivo','ELIMINAR','100', v_r::text, v_m);
END $$;


-- -----------------------------------------------------------------------------
-- D. Catalogo_Tratamiento_Desviacion (efecto por etapa, D-11)
-- -----------------------------------------------------------------------------
DO $$
DECLARE v_id BIGINT; v_r INT; v_m VARCHAR; v_n BIGINT; v_t TEXT;
BEGIN
    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"('PRB_H1_RESTRINGE','Ingresa solo a zona administrativa','Y','N','INGRESA_RESTRINGIDO',NULL,'N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','CREAR solo ingreso','100', v_r::text, v_m); PERFORM pg_temp.fx_set('tIng', v_id);
    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"('PRB_H1_RETIENE','Se retiene el elemento','N','Y',NULL,' sale_retiene_elemento ','N',2,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','CREAR solo salida (resultado en minúsculas)','100', v_r::text, v_m); PERFORM pg_temp.fx_set('tSal', v_id);
    SELECT COALESCE("Resultado_Ingreso",'nulo') || '|' || "Resultado_Salida" INTO v_t FROM "ERP_CATALOGO_TRATAMIENTO_DESVIACION_DETALLE"(v_id);
    PERFORM pg_temp.reg('D Tratamiento','Guardado: resultado en mayúsculas','nulo|SALE_RETIENE_ELEMENTO', v_t);
    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"('PRB_H1_AMBAS','Aplica a ambas','Y','Y','INGRESA','SALE','N',3,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','CREAR ingreso y salida','100', v_r::text, v_m); PERFORM pg_temp.fx_set('tAmb', v_id);
    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"('PRB_H1_OTRO','Otro','Y','Y',NULL,NULL,'Y',99,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','CREAR Otro sin resultado fijo','100', v_r::text, v_m);

    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"('PRB_H1_T_X','No aplica a nada','N','N',NULL,NULL,'N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','CREAR sin etapa','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"('PRB_H1_T_X','Falta resultado','Y','N',NULL,NULL,'N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','CREAR aplica al ingreso sin resultado','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"('PRB_H1_T_X','Resultado sobrante','N','Y','INGRESA','SALE','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','CREAR resultado de ingreso sin aplicar al ingreso','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"('PRB_H1_T_X','Otro con resultado','Y','N','NO_INGRESA',NULL,'Y',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','CREAR Otro con resultado fijo','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"('PRB_H1_T_X','Resultado cruzado','Y','N','SALE',NULL,'N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','CREAR resultado de salida en el campo de ingreso','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR"('PRB_H1_T_X','Resultado cruzado','N','Y',NULL,'NO_INGRESA','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','CREAR resultado de ingreso en el campo de salida','400', v_r::text, v_m);

    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN"('INGRESO') WHERE "Codigo" LIKE 'PRB_H1_%';
    PERFORM pg_temp.reg('D Tratamiento','DROPDOWN(INGRESO): ingreso, ambas y Otro','3', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN"('salida') WHERE "Codigo" LIKE 'PRB_H1_%';
    PERFORM pg_temp.reg('D Tratamiento','DROPDOWN(salida): salida, ambas y Otro','3', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN"('INGRESO') WHERE "ID_Catalogo" = pg_temp.fx('tSal');
    PERFORM pg_temp.reg('D Tratamiento','DROPDOWN(INGRESO) excluye el de solo salida','0', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN"() WHERE "Codigo" LIKE 'PRB_H1_%';
    PERFORM pg_temp.reg('D Tratamiento','DROPDOWN sin etapa: todos','4', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN"('PORTERIA');
    PERFORM pg_temp.reg('D Tratamiento','DROPDOWN con etapa desconocida: nada','0', v_n::text);

    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR"(pg_temp.fx('tAmb'),'PRB_H1_AMBAS','Aplica a ambas','Y','Y','INGRESA',NULL,'N',3,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','ACTUALIZAR quitando un resultado obligatorio','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR"(pg_temp.fx('tAmb'),'PRB_H1_AMBAS','Solo ingreso ahora','Y','N','NO_INGRESA',NULL,'N',3,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','ACTUALIZAR válido (deja de aplicar a la salida)','100', v_r::text, v_m);
    SELECT "Aplica_Salida" || '|' || COALESCE("Resultado_Salida",'nulo') INTO v_t FROM "ERP_CATALOGO_TRATAMIENTO_DESVIACION_DETALLE"(pg_temp.fx('tAmb'));
    PERFORM pg_temp.reg('D Tratamiento','Guardado tras ACTUALIZAR: salida sin resultado','N|nulo', v_t);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TRATAMIENTO_DESVIACION_LISTAR"() WHERE "Codigo" LIKE 'PRB_H1_%';
    PERFORM pg_temp.reg('D Tratamiento','LISTAR trae los 4 creados','4', v_n::text);
    CALL "ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR"(pg_temp.fx('tIng'), 0, v_r, v_m);
    PERFORM pg_temp.reg('D Tratamiento','ELIMINAR','100', v_r::text, v_m);
END $$;


-- -----------------------------------------------------------------------------
-- E. Catalogo_Tipo_Incidencia
-- -----------------------------------------------------------------------------
DO $$
DECLARE v_id BIGINT; v_r INT; v_m VARCHAR; v_n BIGINT; v_t TEXT;
BEGIN
    CALL "ERP_CATALOGO_TIPO_INCIDENCIA_CREAR"('PRB_H1_ZONA_NO_AUT','Ingreso a zona no autorizada','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('E Tipo de incidencia','CREAR válido','100', v_r::text, v_m); PERFORM pg_temp.fx_set('inc1', v_id);
    CALL "ERP_CATALOGO_TIPO_INCIDENCIA_CREAR"('PRB_H1_ZONA_NO_AUT','Repetido','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('E Tipo de incidencia','CREAR código repetido','101', v_r::text, v_m);
    CALL "ERP_CATALOGO_TIPO_INCIDENCIA_CREAR"('PRB_H1_I_X',NULL,'N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('E Tipo de incidencia','CREAR sin descripción','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR"(pg_temp.fx('inc1'),'PRB_H1_ZONA_NO_AUT','Ingreso a zona no autorizada','Q',1,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('E Tipo de incidencia','ACTUALIZAR Es_Otro = Q','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR"(pg_temp.fx('inc1'),'PRB_H1_ZONA_NO_AUT','Ingreso a zona no autorizada','Y',1,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('E Tipo de incidencia','ACTUALIZAR válido','100', v_r::text, v_m);
    SELECT "Es_Otro" INTO v_t FROM "ERP_CATALOGO_TIPO_INCIDENCIA_DETALLE"(pg_temp.fx('inc1'));
    PERFORM pg_temp.reg('E Tipo de incidencia','DETALLE refleja la edición','Y', v_t);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TIPO_INCIDENCIA_DROPDOWN"() WHERE "ID_Catalogo" = pg_temp.fx('inc1') AND "Es_Otro" = 'Y';
    PERFORM pg_temp.reg('E Tipo de incidencia','DROPDOWN lo trae con Es_Otro','1', v_n::text);
    CALL "ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR"(pg_temp.fx('inc1'), 0, v_r, v_m);
    PERFORM pg_temp.reg('E Tipo de incidencia','ELIMINAR','100', v_r::text, v_m);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_TIPO_INCIDENCIA_LISTAR"() WHERE "ID_Catalogo" = pg_temp.fx('inc1');
    PERFORM pg_temp.reg('E Tipo de incidencia','LISTAR ya no lo trae','0', v_n::text);
    CALL "ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR"(pg_temp.fx('inc1'), -1, v_r, v_m);
    PERFORM pg_temp.reg('E Tipo de incidencia','ELIMINAR con UsuarioID = -1','400', v_r::text, v_m);
END $$;


-- -----------------------------------------------------------------------------
-- F. Catalogo_Item_Checklist
-- -----------------------------------------------------------------------------
DO $$
DECLARE v_id BIGINT; v_r INT; v_m VARCHAR; v_n BIGINT; v_t TEXT;
BEGIN
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_CREAR"('PRB_H1_EPP','Usa EPP completo','Casco, chaleco y zapatos','INGRESO','ZONA_EXIGE_EPP','Y',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('F Ítem de checklist','CREAR válido (ingreso)','100', v_r::text, v_m); PERFORM pg_temp.fx_set('itIng', v_id);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_CREAR"('PRB_H1_HERRAMIENTAS','Devuelve sus herramientas','','salida','trae_herramientas',NULL,2,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('F Ítem de checklist','CREAR válido (salida, en minúsculas)','100', v_r::text, v_m); PERFORM pg_temp.fx_set('itSal', v_id);
    SELECT "Etapa" || '|' || "Condicion" || '|' || "Es_Critico" || '|' || COALESCE("Ayuda",'nulo') INTO v_t FROM "ERP_CATALOGO_ITEM_CHECKLIST_DETALLE"(v_id);
    PERFORM pg_temp.reg('F Ítem de checklist','Guardado: mayúsculas, Es_Critico N y ayuda vacía nula','SALIDA|TRAE_HERRAMIENTAS|N|nulo', v_t);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_CREAR"('PRB_H1_INACT','Ítem inactivo',NULL,'INGRESO','SIEMPRE','N',3,'N',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('F Ítem de checklist','CREAR ítem inactivo','100', v_r::text, v_m); PERFORM pg_temp.fx_set('itInact', v_id);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_CREAR"('PRB_H1_IT_X','Etapa inválida',NULL,'PORTERIA','SIEMPRE','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('F Ítem de checklist','CREAR Etapa fuera de la lista','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_CREAR"('PRB_H1_IT_X','Condición inválida',NULL,'INGRESO','NUNCA','N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('F Ítem de checklist','CREAR Condicion fuera de la lista','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_CREAR"('PRB_H1_IT_X','Sin condición',NULL,'INGRESO',NULL,'N',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('F Ítem de checklist','CREAR sin Condicion','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_CREAR"('PRB_H1_IT_X','Bandera inválida',NULL,'INGRESO','SIEMPRE','X',1,'Y',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('F Ítem de checklist','CREAR Es_Critico = X','400', v_r::text, v_m);

    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_ITEM_CHECKLIST_DROPDOWN"('SALIDA') WHERE "Codigo" LIKE 'PRB_H1_%';
    PERFORM pg_temp.reg('F Ítem de checklist','DROPDOWN(SALIDA): solo los de salida activos','1', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_ITEM_CHECKLIST_DROPDOWN"('ingreso') WHERE "Codigo" LIKE 'PRB_H1_%';
    PERFORM pg_temp.reg('F Ítem de checklist','DROPDOWN(ingreso): no trae el inactivo','1', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CATALOGO_ITEM_CHECKLIST_DROPDOWN"() WHERE "Codigo" LIKE 'PRB_H1_%';
    PERFORM pg_temp.reg('F Ítem de checklist','DROPDOWN sin etapa: todos los activos','2', v_n::text);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR"(pg_temp.fx('itSal'),'PRB_H1_HERRAMIENTAS','Devuelve sus herramientas',NULL,'DURANTE','TRAE_HERRAMIENTAS','Y',2,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('F Ítem de checklist','ACTUALIZAR Etapa fuera de la lista','400', v_r::text, v_m);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR"(pg_temp.fx('itSal'),'PRB_H1_HERRAMIENTAS','Devuelve sus herramientas','Revise la guía','SALIDA','TRAE_HERRAMIENTAS','Y',2,'Y',0, v_r, v_m);
    PERFORM pg_temp.reg('F Ítem de checklist','ACTUALIZAR válido (pasa a crítico)','100', v_r::text, v_m);
    SELECT "Es_Critico" || '|' || "Ayuda" INTO v_t FROM "ERP_CATALOGO_ITEM_CHECKLIST_LISTAR"() WHERE "ID_Catalogo" = pg_temp.fx('itSal');
    PERFORM pg_temp.reg('F Ítem de checklist','LISTAR refleja la edición','Y|Revise la guía', v_t);
    SELECT "Etapa" INTO v_t FROM "ERP_CATALOGO_ITEM_CHECKLIST_LISTAR"() WHERE "Codigo" LIKE 'PRB_H1_%' LIMIT 1;
    PERFORM pg_temp.reg('F Ítem de checklist','LISTAR ordena por etapa (INGRESO primero)','INGRESO', v_t);
END $$;


-- -----------------------------------------------------------------------------
-- G. Tipo_Acceso_Item_Checklist (pivot)
-- -----------------------------------------------------------------------------
DO $$
DECLARE v_id BIGINT; v_id1 BIGINT; v_r INT; v_m VARCHAR; v_n BIGINT; v_t TEXT; v_dif BIGINT;
        v_ta BIGINT := pg_temp.fx('ta1');
BEGIN
    CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(v_ta, pg_temp.fx('itSal'), 0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','AGREGAR ítem de salida','100', v_r::text, v_m);
    CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(v_ta, pg_temp.fx('itIng'), 0, v_id1, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','AGREGAR ítem de ingreso','100', v_r::text, v_m);
    CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(v_ta, pg_temp.fx('itIng'), 0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','AGREGAR el mismo ítem otra vez','101', v_r::text, v_m);
    CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(v_ta, pg_temp.fx('itInact'), 0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','AGREGAR ítem inactivo','400', v_r::text, v_m);
    CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(v_ta, -999, 0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','AGREGAR ítem inexistente','400', v_r::text, v_m);
    CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(-999, pg_temp.fx('itIng'), 0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','AGREGAR a un tipo de acceso inexistente','404', v_r::text, v_m);
    CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(pg_temp.fx('ta2'), pg_temp.fx('itIng'), 0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','AGREGAR a un tipo de acceso eliminado','404', v_r::text, v_m);

    SELECT COUNT(*) INTO v_n FROM "ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE"(v_ta);
    PERFORM pg_temp.reg('G Pivot checklist','LISTAR_POR_PADRE trae los 2 asignados','2', v_n::text);
    SELECT "Etapa" INTO v_t FROM "ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE"(v_ta) LIMIT 1;
    PERFORM pg_temp.reg('G Pivot checklist','LISTAR_POR_PADRE ordena INGRESO antes que SALIDA','INGRESO', v_t);

    CALL "ERP_CATALOGO_TIPO_ACCESO_ELIMINAR"(v_ta, 0, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','ELIMINAR tipo de acceso con ítems asignados','101', v_r::text, v_m);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR"(pg_temp.fx('itIng'), 0, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','ELIMINAR ítem asignado a un tipo de acceso','101', v_r::text, v_m);

    CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR"(v_id1, 0, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','QUITAR','100', v_r::text, v_m);
    CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR"(v_id1, 0, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','QUITAR por segunda vez','404', v_r::text, v_m);
    SELECT COUNT(*) INTO v_n FROM "ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE"(v_ta);
    PERFORM pg_temp.reg('G Pivot checklist','LISTAR_POR_PADRE no trae lo quitado','1', v_n::text);
    CALL "ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR"(pg_temp.fx('itIng'), 0, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','ELIMINAR ítem ya sin asignar','100', v_r::text, v_m);

    -- Reasignar reactiva la misma fila (el UNIQUE incluye las quitadas)
    SELECT "ID_Tipo_Acceso_Item_Checklist" INTO v_id FROM "ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE"(v_ta);
    CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR"(v_id, 0, v_r, v_m);
    SELECT "ID_Tipo_Acceso_Item_Checklist" INTO v_id1 FROM "Tipo_Acceso_Item_Checklist"
     WHERE "ID_Catalogo_Tipo_Acceso" = v_ta AND "ID_Catalogo_Item_Checklist" = pg_temp.fx('itSal');
    CALL "ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR"(v_ta, pg_temp.fx('itSal'), 0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','AGREGAR un ítem quitado lo reactiva','100', v_r::text, v_m);
    PERFORM pg_temp.reg('G Pivot checklist','La reactivación conserva el ID de la fila', v_id1::text, v_id::text);

    -- Contra la carga inicial: el SP cuenta igual que la tabla para TODOS los tipos de acceso
    SELECT COUNT(*) INTO v_dif
      FROM "Catalogo_Tipo_Acceso" TA
     WHERE (SELECT COUNT(*) FROM "ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE"(TA."ID_Catalogo_Tipo_Acceso"))
        <> (SELECT COUNT(*) FROM "Tipo_Acceso_Item_Checklist" P WHERE P."ID_Catalogo_Tipo_Acceso" = TA."ID_Catalogo_Tipo_Acceso" AND P."Eliminado" = 'N');
    PERFORM pg_temp.reg('G Pivot checklist','LISTAR_POR_PADRE = tabla, en todos los tipos de acceso','0', v_dif::text);
END $$;


-- -----------------------------------------------------------------------------
-- H. CAF_Persona_Externa
-- -----------------------------------------------------------------------------
DO $$
DECLARE v_id BIGINT; v_r INT; v_m VARCHAR; v_n BIGINT; v_t TEXT;
        v_dn BIGINT := pg_temp.fx('docN'); v_dp BIGINT := pg_temp.fx('docP'); v_p1 BIGINT; v_p2 BIGINT;
BEGIN
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dn,'45678912','Torres','Ríos','Luis Alberto',0, v_p1, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','CREAR válido','100', v_r::text, v_m);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dn,' 45678912 ','Otro','Nombre','Repetido',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','CREAR mismo documento con espacios','101', v_r::text, v_m);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dp,'45678912','Vargas',NULL,'Ana',0, v_p2, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','CREAR mismo número con otro tipo de documento','100', v_r::text, v_m);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dp,'AB12345','Pérez',NULL,'Juan',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','CREAR documento alfanumérico permitido','100', v_r::text, v_m);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dn,'4567891','Corto',NULL,'Siete',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','CREAR documento de 7 dígitos (pide 8)','400', v_r::text, v_m);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dn,'4567891A','Letra',NULL,'Final',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','CREAR letras en documento solo numérico','400', v_r::text, v_m);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(-999,'45678912','Sin','Tipo','Documento',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','CREAR tipo de documento inexistente','400', v_r::text, v_m);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dn,'11112222','Torres',NULL,'  ',0, v_id, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','CREAR sin nombres','400', v_r::text, v_m);
    CALL "ERP_CAF_PERSONA_EXTERNA_CREAR"(v_dn,'11112222','Torres',NULL,'Luis',-1, v_id, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','CREAR UsuarioID = -1','400', v_r::text, v_m);

    SELECT COUNT(*) INTO v_n FROM "ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO"(v_dn,'45678912');
    PERFORM pg_temp.reg('H Persona externa','DETALLE_POR_DOCUMENTO encuentra una sola persona','1', v_n::text);
    SELECT "Nombre_Completo" || '|' || "Tipo_Documento" || '|' || COALESCE("Fecha_Ultima_Visita"::text,'nulo')
      INTO v_t FROM "ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO"(v_dn,'45678912');
    PERFORM pg_temp.reg('H Persona externa','DETALLE_POR_DOCUMENTO: nombre, tipo y última visita','Torres Ríos, Luis Alberto|PRB_H1_DOC|nulo', v_t);
    SELECT "ID_Persona_Externa" INTO v_n FROM "ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO"(v_dp,'45678912');
    PERFORM pg_temp.reg('H Persona externa','DETALLE_POR_DOCUMENTO distingue el tipo de documento', v_p2::text, v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO"(v_dn,'99999999');
    PERFORM pg_temp.reg('H Persona externa','DETALLE_POR_DOCUMENTO inexistente: 0 filas','0', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CAF_PERSONA_EXTERNA_LISTAR"('torres ríos') WHERE "ID_Persona_Externa" = v_p1;
    PERFORM pg_temp.reg('H Persona externa','LISTAR por nombre (minúsculas)','1', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "ERP_CAF_PERSONA_EXTERNA_LISTAR"('45678912');
    PERFORM pg_temp.reg('H Persona externa','LISTAR no busca por documento (eso es DETALLE_POR_DOCUMENTO)','0', v_n::text);

    CALL "ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR"(v_p1, v_dn,'45678912','Torres','','Luis Alberto',0, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','ACTUALIZAR válido (sin apellido materno)','100', v_r::text, v_m);
    SELECT "Nombre_Completo" || '|' || COALESCE("UsuarioID_Update"::text,'nulo') || '|' || COALESCE("Fecha_Ultima_Visita"::text,'nulo')
      INTO v_t FROM "ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO"(v_dn,'45678912');
    PERFORM pg_temp.reg('H Persona externa','Guardado: materno vacío nulo, auditoría, sin tocar última visita','Torres, Luis Alberto|0|nulo', v_t);
    CALL "ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR"(v_p1, v_dp,'45678912','Torres',NULL,'Luis',0, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','ACTUALIZAR al documento de otra persona','101', v_r::text, v_m);
    CALL "ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR"(-999, v_dn,'12345678','No','Existe','Nadie',0, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','ACTUALIZAR ID inexistente','404', v_r::text, v_m);
    CALL "ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR"(v_p1, v_dn,'45678912','Torres',NULL,'Luis',-1, v_r, v_m);
    PERFORM pg_temp.reg('H Persona externa','ACTUALIZAR UsuarioID = -1','400', v_r::text, v_m);
END $$;


-- -----------------------------------------------------------------------------
-- I. Estructura: las 43 rutinas del Hito 1 existen y tienen la forma del patrón
--    (se verifican por nombre: otras rutinas del schema, de hitos posteriores, no cuentan)
-- -----------------------------------------------------------------------------
CREATE TEMP TABLE "_Esperada" AS
SELECT UNNEST(ARRAY[
        'ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR', 'ERP_CAF_PERSONA_EXTERNA_CREAR', 'ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO',
        'ERP_CAF_PERSONA_EXTERNA_LISTAR', 'ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR', 'ERP_CATALOGO_ITEM_CHECKLIST_CREAR',
        'ERP_CATALOGO_ITEM_CHECKLIST_DETALLE', 'ERP_CATALOGO_ITEM_CHECKLIST_DROPDOWN', 'ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR',
        'ERP_CATALOGO_ITEM_CHECKLIST_LISTAR', 'ERP_CATALOGO_MOTIVO_VISITA_ACTUALIZAR', 'ERP_CATALOGO_MOTIVO_VISITA_CREAR',
        'ERP_CATALOGO_MOTIVO_VISITA_DETALLE', 'ERP_CATALOGO_MOTIVO_VISITA_DROPDOWN', 'ERP_CATALOGO_MOTIVO_VISITA_ELIMINAR',
        'ERP_CATALOGO_MOTIVO_VISITA_LISTAR', 'ERP_CATALOGO_TIPO_ACCESO_ACTUALIZAR', 'ERP_CATALOGO_TIPO_ACCESO_CREAR',
        'ERP_CATALOGO_TIPO_ACCESO_DETALLE', 'ERP_CATALOGO_TIPO_ACCESO_DROPDOWN', 'ERP_CATALOGO_TIPO_ACCESO_ELIMINAR',
        'ERP_CATALOGO_TIPO_ACCESO_LISTAR', 'ERP_CATALOGO_TIPO_INCIDENCIA_ACTUALIZAR', 'ERP_CATALOGO_TIPO_INCIDENCIA_CREAR',
        'ERP_CATALOGO_TIPO_INCIDENCIA_DETALLE', 'ERP_CATALOGO_TIPO_INCIDENCIA_DROPDOWN', 'ERP_CATALOGO_TIPO_INCIDENCIA_ELIMINAR',
        'ERP_CATALOGO_TIPO_INCIDENCIA_LISTAR', 'ERP_CATALOGO_TRATAMIENTO_DESVIACION_ACTUALIZAR', 'ERP_CATALOGO_TRATAMIENTO_DESVIACION_CREAR',
        'ERP_CATALOGO_TRATAMIENTO_DESVIACION_DETALLE', 'ERP_CATALOGO_TRATAMIENTO_DESVIACION_DROPDOWN', 'ERP_CATALOGO_TRATAMIENTO_DESVIACION_ELIMINAR',
        'ERP_CATALOGO_TRATAMIENTO_DESVIACION_LISTAR', 'ERP_CATALOGO_ZONA_ACCESO_ACTUALIZAR', 'ERP_CATALOGO_ZONA_ACCESO_CREAR',
        'ERP_CATALOGO_ZONA_ACCESO_DETALLE', 'ERP_CATALOGO_ZONA_ACCESO_DROPDOWN', 'ERP_CATALOGO_ZONA_ACCESO_ELIMINAR',
        'ERP_CATALOGO_ZONA_ACCESO_LISTAR', 'ERP_TIPO_ACCESO_ITEM_CHECKLIST_AGREGAR', 'ERP_TIPO_ACCESO_ITEM_CHECKLIST_LISTAR_POR_PADRE',
        'ERP_TIPO_ACCESO_ITEM_CHECKLIST_QUITAR'
       ]) AS "Nombre";

DO $$
DECLARE v_n BIGINT;
BEGIN
    SELECT COUNT(*) INTO v_n FROM "_Esperada";
    PERFORM pg_temp.reg('I Estructura','Rutinas esperadas en la lista (6 x 6 + 3 + 4)','43', v_n::text);
    SELECT COUNT(*) INTO v_n FROM "_Esperada" E
     WHERE NOT EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace s ON s.oid = p.pronamespace
                        WHERE s.nspname = 'TRIANONSATELITAL_CAF_PRODD' AND p.proname = E."Nombre");
    PERFORM pg_temp.reg('I Estructura','Rutinas esperadas que no existen en el schema','0', v_n::text);
    SELECT COUNT(*) INTO v_n FROM pg_proc p JOIN pg_namespace s ON s.oid = p.pronamespace JOIN "_Esperada" E ON E."Nombre" = p.proname
     WHERE s.nspname = 'TRIANONSATELITAL_CAF_PRODD' AND p.prokind = 'f';
    PERFORM pg_temp.reg('I Estructura','Lecturas (funciones): 6 x 3 + 1 + 2','21', v_n::text);
    SELECT COUNT(*) INTO v_n FROM pg_proc p JOIN pg_namespace s ON s.oid = p.pronamespace JOIN "_Esperada" E ON E."Nombre" = p.proname
     WHERE s.nspname = 'TRIANONSATELITAL_CAF_PRODD'
       AND NOT (COALESCE(p.proconfig, '{}') @> ARRAY['search_path="TRIANONSATELITAL_CAF_PRODD"']);
    PERFORM pg_temp.reg('I Estructura','Rutinas sin search_path propio (D-28)','0', v_n::text);
    SELECT COUNT(*) INTO v_n FROM pg_proc p JOIN pg_namespace s ON s.oid = p.pronamespace JOIN "_Esperada" E ON E."Nombre" = p.proname
     WHERE s.nspname = 'TRIANONSATELITAL_CAF_PRODD' AND p.prokind = 'p'
       AND NOT (p.proargnames[array_length(p.proargnames,1)-1:array_length(p.proargnames,1)] = ARRAY['HV_Codigo_Resp','HV_Mensaje']);
    PERFORM pg_temp.reg('I Estructura','Escrituras que no terminan en HV_Codigo_Resp, HV_Mensaje','0', v_n::text);
END $$;



-- -----------------------------------------------------------------------------
-- Resultado
-- -----------------------------------------------------------------------------
SELECT "N", "Bloque", "Caso", "Esperado", "Obtenido",
       CASE WHEN "Esperado" = "Obtenido" THEN 'OK' ELSE '*** FALLA ***' END AS "Estado",
       "Mensaje"
  FROM "_Prueba" ORDER BY "N";

SELECT 'RESULTADO: ' || COUNT(*) FILTER (WHERE "Esperado" = "Obtenido") || ' de ' || COUNT(*) || ' OK' AS "Resumen"
  FROM "_Prueba";

ROLLBACK;
