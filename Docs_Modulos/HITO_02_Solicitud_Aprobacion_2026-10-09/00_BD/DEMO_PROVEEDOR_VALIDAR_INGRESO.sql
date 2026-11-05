-- =============================================================================
-- Archivo : DEMO_PROVEEDOR_VALIDAR_INGRESO.sql    (OPCIONAL, solo pruebas del piloto; NO lo corre restaurar_bd.ps1)
-- Version : V1.0 2026-11-03
-- Requiere: DATOS_DEMO_PROVEEDOR.sql ya cargado.
-- Que hace: hace de Vigilancia hasta que exista su pantalla de proveedores. Valida el ingreso fisico (como
--   vigilante1.demo) de la entrega que tiene la disponibilidad de Almacen confirmada y sigue "En espera".
--   Se puede ejecutar cuantas veces haga falta; si no hay ninguna lista, no hace nada y lo avisa.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";
DO $$
DECLARE
    v_vig BIGINT; v_sol BIGINT; v_cod INT; v_msg VARCHAR(250); v_codigo VARCHAR(20);
BEGIN
    SELECT "ID_Usuario" INTO v_vig FROM "CAF_GOVERNANCE"."Usuario" WHERE "Correo" = 'vigilante1.demo@trianon.test';
    IF v_vig IS NULL THEN RAISE EXCEPTION 'Falta el usuario vigilante1.demo (script 11).'; END IF;
    SELECT O."ID_Solicitud", S."Codigo" INTO v_sol, v_codigo
      FROM "CAF_Exclusa" X
      JOIN "CAF_Solicitud_Operacion" O ON O."ID_Solicitud" = X."ID_Solicitud_Actual" AND O."Estado_Operativo" = 'EN_ESPERA' AND O."Activa" = 'Y'
      JOIN "CAF_Solicitud" S ON S."ID_Solicitud" = O."ID_Solicitud"
     ORDER BY O."ID_Solicitud" LIMIT 1;
    IF v_sol IS NULL THEN
        RAISE NOTICE 'No hay entregas En espera con la disponibilidad de Almacen confirmada.';
        RETURN;
    END IF;
    CALL "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR"(v_sol, v_vig, v_cod, v_msg);
    RAISE NOTICE '% -> %: %', v_codigo, v_cod, v_msg;
END $$;
