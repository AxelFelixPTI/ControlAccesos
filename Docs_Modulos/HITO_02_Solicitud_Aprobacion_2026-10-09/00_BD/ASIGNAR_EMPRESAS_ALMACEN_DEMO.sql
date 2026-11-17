-- =============================================================================
-- Archivo : ASIGNAR_EMPRESAS_ALMACEN_DEMO.sql   (solo pruebas; seguro repetirlo)
-- Que hace : da a almacen1.demo y almacen2.demo todas las empresas del grupo para la atencion (Catalogos -> Almacen por empresa).
--            Sin empresas asignadas un almacenero no puede iniciar, detener, reanudar ni terminar ninguna atencion.
--            (Los scripts DATOS_DEMO_* V1.1 ya lo hacen; este sirve para una base cargada antes.)
-- =============================================================================
BEGIN;
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";
DO $$
DECLARE v_u BIGINT; v_ids TEXT; v_cod INT; v_msg VARCHAR(250);
BEGIN
    SELECT STRING_AGG(CAST("ID_Catalogo_Empresa_Grupo" AS TEXT), ',' ORDER BY "Orden") INTO v_ids
      FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" WHERE "Eliminado" = 'N' AND "Activo" = 'Y';
    FOR v_u IN SELECT "ID_Usuario" FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" IN ('almacen1.demo@trianon.test','almacen2.demo@trianon.test') LOOP
        CALL "ERP_CAF_ALMACEN_EMPRESA_GUARDAR"(v_u, v_ids, 0, v_cod, v_msg);
        IF v_cod <> 100 THEN RAISE EXCEPTION 'No se pudo asignar empresas al usuario %: % %', v_u, v_cod, v_msg; END IF;
    END LOOP;
END $$;
COMMIT;
