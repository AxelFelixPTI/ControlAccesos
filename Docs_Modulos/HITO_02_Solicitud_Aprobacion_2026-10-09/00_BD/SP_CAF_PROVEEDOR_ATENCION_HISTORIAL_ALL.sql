-- =============================================================================
-- SP_CAF_PROVEEDOR_ATENCION_HISTORIAL_ALL.sql   (2026-11-22, D-264)
-- Bloque «Atención de Almacén» del detalle de una solicitud de proveedor.
--   ERP_CAF_FN_ATENDIDO_POR(solicitud)                      «nombre:EMP1,EMP2|nombre:EMP3»: quienes iniciaron la atención de cada empresa
--   ERP_CAF_PROVEEDOR_ATENCION_RESUMEN(usuario, solicitud)  una fila por empresa: estado, quién inició y terminó, horas, resultado, motivos
--   ERP_CAF_PROVEEDOR_ATENCION_EVENTOS(usuario, solicitud)  línea de tiempo de Almacén (bitácora CAF_Solicitud_Operacion_Evento)
-- Las dos de lectura exigen el permiso PER_CAF_PROVEEDOR_HIST_ALMACEN (licencia LIC_CAF_HIST_ALMACEN, script 42); sin él devuelven vacío.
-- Schema: TRIANONSATELITAL_CAF_PRODD.  HANA (T-59): funciones de tabla; STRING_AGG nativo.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD", "CAF_GOVERNANCE";

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_ATENDIDO_POR"("HV_ID_Solicitud" BIGINT)
RETURNS VARCHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE lv_r VARCHAR;
BEGIN
    -- V1.0 2026-11-22 (D-264): quien inició la atención de cada empresa (una empresa cerrada sin atención no cuenta); agrupa por almacenero
    SELECT STRING_AGG(X.n || ':' || X.e, '|' ORDER BY X.ord) INTO lv_r
      FROM (SELECT "ERP_CAF_FN_USUARIO_NOMBRE"(A."ID_Usuario_Inicio") AS n, MIN(A."Fecha_Inicio") AS ord,
                   STRING_AGG(EG."Codigo", ',' ORDER BY EG."Orden") AS e
              FROM "CAF_Solicitud_Atencion" A
              JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG ON EG."ID_Catalogo_Empresa_Grupo" = A."ID_Catalogo_Empresa_Grupo"
             WHERE A."ID_Solicitud" = "HV_ID_Solicitud" AND A."Eliminado" = 'N' AND A."ID_Usuario_Inicio" IS NOT NULL
               AND A."Estado" IN ('EN_ATENCION','DETENIDA','ATENDIDA')
             GROUP BY A."ID_Usuario_Inicio") X
     WHERE X.n IS NOT NULL;
    RETURN lv_r;
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_ATENCION_RESUMEN"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("ID_Empresa" BIGINT, "Codigo" VARCHAR, "Empresa" VARCHAR, "Estado" VARCHAR, "Inicio_Nombre" VARCHAR, "Fecha_Inicio" TIMESTAMP,
               "Fin_Nombre" VARCHAR, "Fecha_Fin" TIMESTAMP, "Resultado" VARCHAR, "Observacion" VARCHAR, "Motivo_Sin_Atencion" VARCHAR, "Motivo_Detencion" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE lv_sede BIGINT;
BEGIN
    -- V1.0 2026-11-22 (D-264)
    SELECT S."ID_Catalogo_Sede" INTO lv_sede FROM "CAF_Solicitud" S
      JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
     WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
    IF lv_sede IS NULL OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_HIST_ALMACEN', lv_sede) <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT E."ID_Catalogo_Empresa_Grupo", CAST(EG."Codigo" AS VARCHAR), CAST(EG."Descripcion" AS VARCHAR),
           CAST("ERP_CAF_FN_ATENCION_ESTADO"(E."ID_Solicitud", E."ID_Catalogo_Empresa_Grupo") AS VARCHAR),
           "ERP_CAF_FN_USUARIO_NOMBRE"(A."ID_Usuario_Inicio"), A."Fecha_Inicio",
           "ERP_CAF_FN_USUARIO_NOMBRE"(A."ID_Usuario_Fin"), A."Fecha_Fin",
           CAST(A."Resultado" AS VARCHAR), CAST(A."Observacion" AS VARCHAR), CAST(M."Descripcion" AS VARCHAR), CAST(A."Motivo_Detencion" AS VARCHAR)
      FROM "CAF_Solicitud_Empresa" E
      JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG ON EG."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo"
      LEFT JOIN "CAF_Solicitud_Atencion" A ON A."ID_Solicitud" = E."ID_Solicitud" AND A."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo" AND A."Eliminado" = 'N'
      LEFT JOIN "CAF_Motivo_Sin_Atencion" M ON M."ID_Motivo_Sin_Atencion" = A."ID_Motivo_Sin_Atencion"
     WHERE E."ID_Solicitud" = "HV_ID_Solicitud" AND E."Eliminado" = 'N'
     ORDER BY EG."Orden", EG."ID_Catalogo_Empresa_Grupo";
END;
$$;

CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_ATENCION_EVENTOS"("HV_UsuarioID" BIGINT, "HV_ID_Solicitud" BIGINT)
RETURNS TABLE ("Fecha_Evento" TIMESTAMP, "Usuario_Nombre" VARCHAR, "Estado_Anterior" VARCHAR, "Estado_Nuevo" VARCHAR, "Resultado" VARCHAR, "Detalle" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE lv_sede BIGINT;
BEGIN
    -- V1.0 2026-11-22 (D-264): lo más antiguo primero (es una línea de tiempo)
    SELECT S."ID_Catalogo_Sede" INTO lv_sede FROM "CAF_Solicitud" S
      JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
     WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
    IF lv_sede IS NULL OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_HIST_ALMACEN', lv_sede) <> 'Y' THEN RETURN; END IF;
    RETURN QUERY
    SELECT V."Fecha_Evento", CASE WHEN V."ID_Usuario" = 0 THEN CAST('Sistema' AS VARCHAR) ELSE "ERP_CAF_FN_USUARIO_NOMBRE"(V."ID_Usuario") END,
           CAST(V."Estado_Anterior" AS VARCHAR), CAST(V."Estado_Nuevo" AS VARCHAR), CAST(V."Resultado" AS VARCHAR), CAST(V."Observacion" AS VARCHAR)
      FROM "CAF_Solicitud_Operacion_Evento" V
     WHERE V."ID_Solicitud" = "HV_ID_Solicitud"
     ORDER BY V."Fecha_Evento", V."ID_Operacion_Evento";
END;
$$;
