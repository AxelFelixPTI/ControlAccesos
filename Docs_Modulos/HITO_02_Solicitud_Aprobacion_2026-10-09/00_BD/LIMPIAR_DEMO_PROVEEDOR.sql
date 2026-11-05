-- ============================================================================================================
-- Archivo : LIMPIAR_DEMO_PROVEEDOR.sql      (OPCIONAL, solo pruebas; NO lo corre restaurar_bd.ps1)
-- Proposito: borrar SOLO los datos de DATOS_DEMO_PROVEEDOR.sql (cualquier version) para poder volver a cargarlo.
-- Borra  : las entregas demo (solicitudes cuyo transportista tiene DNI 7300000n, n=1..9, con todo lo que cuelga de
--          ellas: operacion, eventos, personas, checklist, desviaciones, accesos, correos), los transportistas demo,
--          y los usuarios/fichas almacen1.demo y almacen2.demo (con sus licencias).
-- NO toca: usuarios demo del script 11 (solicitante1, coordinador, vigilante1...), ni las licencias que el demo les
--          dio (no estorban: la carga del demo vuelve a comprobarlas), ni ninguna solicitud real.
-- Despues: ejecute DATOS_DEMO_PROVEEDOR.sql de nuevo.
-- ============================================================================================================
BEGIN;
SET LOCAL search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- Borrado en cascada manual: elimina de "tabla" las filas que cumplen "cond" y, antes, todo lo que las referencia por clave foranea.
CREATE OR REPLACE FUNCTION pg_temp.borrar(p_oid regclass, p_cond TEXT, p_prof INT DEFAULT 0) RETURNS VOID LANGUAGE plpgsql AS $f$
DECLARE r RECORD; pk TEXT; ck TEXT;
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

DO $$
DECLARE v_n INT; v_sol TEXT := '"ID_Solicitud" IN (SELECT SP."ID_Solicitud" FROM "CAF_Solicitud_Persona" SP JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = SP."ID_Persona_Externa" WHERE PE."Numero_Documento" ~ ''^7300000[1-9]$'' AND PE."Nombres" = ''Carlos'')';
BEGIN
    SELECT COUNT(*) INTO v_n FROM "CAF_Solicitud" WHERE "ID_Solicitud" IN (SELECT SP."ID_Solicitud" FROM "CAF_Solicitud_Persona" SP JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = SP."ID_Persona_Externa" WHERE PE."Numero_Documento" ~ '^7300000[1-9]$' AND PE."Nombres" = 'Carlos');
    RAISE NOTICE 'Entregas demo encontradas: %', v_n;
    -- la exclusa: soltar si la tiene una entrega demo
    UPDATE "CAF_Exclusa" SET "ID_Solicitud_Actual" = NULL WHERE "ID_Solicitud_Actual" IN (SELECT "ID_Solicitud" FROM "CAF_Solicitud" WHERE v_n >= 0 AND "ID_Solicitud" IN (SELECT SP."ID_Solicitud" FROM "CAF_Solicitud_Persona" SP JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = SP."ID_Persona_Externa" WHERE PE."Numero_Documento" ~ '^7300000[1-9]$' AND PE."Nombres" = 'Carlos'));
    PERFORM pg_temp.borrar('"CAF_Solicitud"'::regclass, v_sol);
    PERFORM pg_temp.borrar('"CAF_Persona_Externa"'::regclass, '"Numero_Documento" ~ ''^7300000[1-9]$'' AND "Nombres" = ''Carlos''');
    PERFORM pg_temp.borrar('"CAF_GOVERNANCE"."Usuario"'::regclass, '"Correo" IN (''almacen1.demo@trianon.test'',''almacen2.demo@trianon.test'')');
    PERFORM pg_temp.borrar('"CAF_GOVERNANCE"."Personal"'::regclass, '"Correo" IN (''almacen1.demo@trianon.test'',''almacen2.demo@trianon.test'')');
END $$;
COMMIT;
