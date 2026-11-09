-- ============================================================================================================
-- Archivo : LIMPIAR_DEMO_ESCENARIOS.sql      (OPCIONAL, solo pruebas; NO lo corre restaurar_bd.ps1)
-- Version : V1.0 2026-11-09
-- Proposito: borrar SOLO los datos de DATOS_DEMO_ESCENARIOS.sql para poder volver a cargarlo.
-- Borra  : todas las solicitudes que incluyen personas con DNI 7400NNNN (con lo que cuelga: personas, dias, operacion,
--          eventos, checklist, accesos, desviaciones, transportistas, correos pendientes), las incidencias marcadas
--          «[DEMO-ESC]», las personas externas 7400NNNN y el usuario/ficha coordinador2.demo. Libera la exclusa si la
--          tenia una entrega demo.
-- NO toca: ninguna solicitud ni persona real, los usuarios del script 11, almacen1/2.demo (los puede usar DATOS_DEMO_PROVEEDOR
--          o usted), ni las licencias dadas. (Para quitar almacen1/2.demo use LIMPIAR_DEMO_PROVEEDOR.sql, que tambien
--          borra las 9 entregas de ese demo.) Para vaciar TODO use LIMPIAR_DATOS_PRUEBA.sql (HITO_00_01).
-- ============================================================================================================
BEGIN;
SET LOCAL search_path TO "TRIANONSATELITAL_CAF_PRODD";

CREATE OR REPLACE FUNCTION pg_temp.borrar(p_oid regclass, p_cond TEXT, p_prof INT DEFAULT 0) RETURNS VOID LANGUAGE plpgsql AS $f$
DECLARE r RECORD;
BEGIN
    IF p_prof > 8 THEN RAISE EXCEPTION 'Profundidad excesiva en %', p_oid; END IF;
    FOR r IN SELECT c.conrelid::regclass AS hija, a.attname AS col_hija, ra.attname AS col_padre
             FROM pg_constraint c
             JOIN pg_attribute a  ON a.attrelid = c.conrelid  AND a.attnum  = c.conkey[1]
             JOIN pg_attribute ra ON ra.attrelid = c.confrelid AND ra.attnum = c.confkey[1]
             WHERE c.contype = 'f' AND c.confrelid = p_oid AND array_length(c.conkey, 1) = 1 AND c.conrelid <> p_oid
    LOOP
        PERFORM pg_temp.borrar(r.hija, format('%I IN (SELECT %I FROM %s WHERE %s)', r.col_hija, r.col_padre, p_oid, p_cond), p_prof + 1);
    END LOOP;
    EXECUTE format('DELETE FROM %s WHERE %s', p_oid, p_cond);
END $f$;

-- Se guardan primero los ids: al borrar las personas de cada solicitud la condicion ya no las encontraria.
CREATE TEMP TABLE tmp_esc_sol ON COMMIT DROP AS
    SELECT DISTINCT SP."ID_Solicitud" AS id
      FROM "CAF_Solicitud_Persona" SP
      JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = SP."ID_Persona_Externa"
     WHERE PE."Numero_Documento" ~ '^7400[0-9]{4}$';

DO $$
DECLARE v_n INT;
BEGIN
    SELECT COUNT(*) INTO v_n FROM tmp_esc_sol;
    RAISE NOTICE 'Solicitudes de escenarios encontradas: %', v_n;
    UPDATE "CAF_Exclusa" SET "ID_Solicitud_Actual" = NULL WHERE "ID_Solicitud_Actual" IN (SELECT id FROM tmp_esc_sol);
    PERFORM pg_temp.borrar('"CAF_Incidencia"'::regclass, '"Descripcion" LIKE ''[DEMO-ESC]%''');
    PERFORM pg_temp.borrar('"CAF_Solicitud"'::regclass, '"ID_Solicitud" IN (SELECT id FROM tmp_esc_sol)');
    PERFORM pg_temp.borrar('"CAF_Persona_Externa"'::regclass, '"Numero_Documento" ~ ''^7400[0-9]{4}$''');
    PERFORM pg_temp.borrar('"CAF_GOVERNANCE"."Usuario"'::regclass, '"Correo" = ''coordinador2.demo@trianon.test''');
    PERFORM pg_temp.borrar('"CAF_GOVERNANCE"."Personal"'::regclass, '"Correo" = ''coordinador2.demo@trianon.test''');
END $$;
COMMIT;
