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

-- =============================================================================
-- D-273/D-274. Pantalla «Historial de Almacén»: listado de todas las atenciones de entregas de proveedores (una fila por entrega y empresa de destino).
--   ERP_CAF_PROVEEDOR_HISTORIAL_ALMACEN(usuario, sede, desde, hasta, texto, empresa, estado, con_vehiculo)
--     Rango sobre la fecha prevista de la entrega (sin fechas: últimos 30 días; máximo 366 días). Solo solicitudes APROBADAS de proveedor.
--     texto: código de la solicitud, N.° de OC, proveedor, empresa transportista, placa, conductor, solicitante, quien reservó / atendió.
--     empresa: ID de empresa del grupo (NULL = todas). estado: estado de la atención (NULL = todos). con_vehiculo: 'Y' / 'N' / NULL = todos.
--     Máximo 500 filas, la entrega más reciente primero.
--     Tiempo activo = (fin o ahora) - inicio - pausas. Pausas salen de la bitácora (ATENCION_DETENIDA / ATENCION_REANUDADA) de esa empresa.
--     D-274: + OC, placa, conductor, transportista; franja programada (Fecha_Entrega = «desde», Hora_Hasta = «hasta»); estado de la entrega
--     (Estado_Entrega: PROGRAMADO … SALIO / CIERRE_FORZADO) con sus marcas (llegada, ingreso, confirmación de disponibilidad, salida) tomadas de la operación;
--     Minutos_Desvio = minutos entre el inicio de la franja y el inicio real de la atención (negativo = antes); Fuera_Franja = 'Y' si inició después de «hasta».
--     Exige PER_CAF_PROVEEDOR_HIST_ALMACEN; sin él devuelve vacío.
-- =============================================================================
DROP FUNCTION IF EXISTS "ERP_CAF_PROVEEDOR_HISTORIAL_ALMACEN"(BIGINT, BIGINT, DATE, DATE, VARCHAR, BIGINT, VARCHAR, CHAR);
CREATE OR REPLACE FUNCTION "ERP_CAF_PROVEEDOR_HISTORIAL_ALMACEN"("HV_UsuarioID" BIGINT, "HV_ID_Catalogo_Sede" BIGINT, "HV_Desde" DATE, "HV_Hasta" DATE,
        "HV_Texto" VARCHAR, "HV_ID_Empresa" BIGINT, "HV_Estado" VARCHAR, "HV_Con_Vehiculo" CHAR)
RETURNS TABLE ("ID_Solicitud" BIGINT, "Codigo" VARCHAR, "Fecha_Entrega" TIMESTAMP, "Proveedor" VARCHAR, "Solicitante" VARCHAR, "ID_Empresa" BIGINT, "Empresa_Codigo" VARCHAR,
               "Empresa" VARCHAR, "Estado" VARCHAR, "Reservo" VARCHAR, "Inicio_Nombre" VARCHAR, "Fecha_Inicio" TIMESTAMP, "Fin_Nombre" VARCHAR, "Fecha_Fin" TIMESTAMP,
               "Minutos_Activos" INT, "Pausas" INT, "Minutos_Pausa" INT, "Con_Vehiculo" CHAR, "Resultado" VARCHAR, "Motivo_Sin_Atencion" VARCHAR, "Observacion" VARCHAR,
               "Numeros_OC" VARCHAR, "Placa" VARCHAR, "Conductor" VARCHAR, "Empresa_Transportista" VARCHAR, "Hora_Hasta" VARCHAR, "Estado_Entrega" VARCHAR,
               "Fecha_Llegada" TIMESTAMP, "Fecha_Ingreso" TIMESTAMP, "Fecha_Disponibilidad" TIMESTAMP, "Fecha_Salida" TIMESTAMP, "Minutos_Desvio" INT, "Fuera_Franja" CHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
DECLARE
    lv_h DATE := COALESCE("HV_Hasta", CURRENT_DATE);
    lv_d DATE := COALESCE("HV_Desde", COALESCE("HV_Hasta", CURRENT_DATE) - 30);
    lv_t VARCHAR := NULLIF(TRIM(COALESCE("HV_Texto", '')), '');
BEGIN
    -- V2.0 2026-11-24 (D-274): + OC, placa, conductor, transportista, franja «hasta», estado y marcas de la entrega, desvío contra la franja; el texto busca también por OC, placa, conductor y transportista
    -- V1.0 2026-11-24 (D-273)
    IF "HV_UsuarioID" IS NULL OR "ERP_CAF_FN_USUARIO_TIENE_PERMISO"("HV_UsuarioID", 'PER_CAF_PROVEEDOR_HIST_ALMACEN', "HV_ID_Catalogo_Sede") <> 'Y' THEN RETURN; END IF;
    IF lv_d > lv_h THEN RETURN; END IF;
    IF lv_h - lv_d > 366 THEN lv_d := lv_h - 366; END IF;
    RETURN QUERY
    WITH base AS (
        SELECT S."ID_Solicitud" AS sid, S."Codigo" AS cod, S."Fecha_Hora_Prevista" AS fe, S."Empresa_Visitante" AS prov, S."ID_Usuario_Solicitante" AS sol,
               E."ID_Catalogo_Empresa_Grupo" AS eid, EG."Codigo" AS ecod, EG."Descripcion" AS edes, EG."Orden" AS eord,
               "ERP_CAF_FN_ATENCION_ESTADO"(S."ID_Solicitud", E."ID_Catalogo_Empresa_Grupo") AS est,
               O."ID_Usuario_Disponibilidad" AS res, O."Con_Vehiculo" AS cv,
               A."ID_Usuario_Inicio" AS ui, A."Fecha_Inicio" AS fi, A."ID_Usuario_Fin" AS uf, A."Fecha_Fin" AS ff,
               A."Resultado" AS rs, A."Observacion" AS ob, M."Descripcion" AS mo,
               S."Numeros_OC" AS oc, S."Placa_Vehiculo" AS placa, S."Empresa_Transportista" AS trans, S."Hora_Hasta_Prevista" AS hh,
               CAST(PE."Apellido_Paterno" || COALESCE(' ' || PE."Apellido_Materno", '') || ', ' || PE."Nombres" AS VARCHAR) AS cond,
               O."Estado_Operativo" AS eo, O."Fecha_Llegada" AS fll, O."Fecha_Ingreso" AS fin_, O."Fecha_Disponibilidad" AS fdi, O."Fecha_Salida" AS fsa
          FROM "CAF_Solicitud" S
          JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
          JOIN "CAF_Solicitud_Empresa" E ON E."ID_Solicitud" = S."ID_Solicitud" AND E."Eliminado" = 'N'
          JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG ON EG."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo"
          LEFT JOIN "CAF_Solicitud_Operacion" O ON O."ID_Solicitud" = S."ID_Solicitud" AND O."Eliminado" = 'N'
          LEFT JOIN "CAF_Solicitud_Atencion" A ON A."ID_Solicitud" = S."ID_Solicitud" AND A."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo" AND A."Eliminado" = 'N'
          LEFT JOIN "CAF_Motivo_Sin_Atencion" M ON M."ID_Motivo_Sin_Atencion" = A."ID_Motivo_Sin_Atencion"
          LEFT JOIN "CAF_Solicitud_Persona" PR ON PR."ID_Solicitud" = S."ID_Solicitud" AND PR."Eliminado" = 'N' AND PR."Es_Principal" = 'Y'
          LEFT JOIN "CAF_Persona_Externa" PE ON PE."ID_Persona_Externa" = PR."ID_Persona_Externa"
         WHERE S."Eliminado" = 'N' AND S."Estado" = 'APROBADA' AND S."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"
           AND CAST(S."Fecha_Hora_Prevista" AS DATE) BETWEEN lv_d AND lv_h
           AND ("HV_ID_Empresa" IS NULL OR E."ID_Catalogo_Empresa_Grupo" = "HV_ID_Empresa")
    ), pausas AS (
        -- cada «detenida» de esa empresa, con su «reanudada» siguiente (o el fin / ahora si quedó abierta)
        SELECT b.sid, b.eid, COUNT(*) AS n,
               COALESCE(SUM(EXTRACT(EPOCH FROM (COALESCE(r.fr, b.ff, CURRENT_TIMESTAMP) - d."Fecha_Evento")) / 60.0), 0) AS min
          FROM base b
          JOIN "CAF_Solicitud_Operacion_Evento" d ON d."ID_Solicitud" = b.sid AND d."Resultado" = 'ATENCION_DETENIDA'
               AND (d."Observacion" = 'Atención detenida: ' || b.ecod OR d."Observacion" LIKE 'Atención detenida: ' || b.ecod || ' (%')
          LEFT JOIN LATERAL (SELECT MIN(x."Fecha_Evento") AS fr FROM "CAF_Solicitud_Operacion_Evento" x
                              WHERE x."ID_Solicitud" = b.sid AND x."Resultado" = 'ATENCION_REANUDADA' AND x."Observacion" = 'Atención reanudada: ' || b.ecod
                                AND x."Fecha_Evento" > d."Fecha_Evento") r ON TRUE
         GROUP BY b.sid, b.eid
    )
    SELECT b.sid, CAST(b.cod AS VARCHAR), b.fe, CAST(b.prov AS VARCHAR), "ERP_CAF_FN_USUARIO_NOMBRE"(b.sol), b.eid, CAST(b.ecod AS VARCHAR), CAST(b.edes AS VARCHAR),
           CAST(b.est AS VARCHAR), "ERP_CAF_FN_USUARIO_NOMBRE"(b.res), "ERP_CAF_FN_USUARIO_NOMBRE"(b.ui), b.fi, "ERP_CAF_FN_USUARIO_NOMBRE"(b.uf), b.ff,
           CASE WHEN b.fi IS NULL THEN NULL
                ELSE CAST(GREATEST(0, ROUND(EXTRACT(EPOCH FROM (COALESCE(b.ff, CURRENT_TIMESTAMP) - b.fi)) / 60.0 - COALESCE(p.min, 0))) AS INT) END,
           CAST(COALESCE(p.n, 0) AS INT), CAST(ROUND(COALESCE(p.min, 0)) AS INT), CAST(b.cv AS CHAR), CAST(b.rs AS VARCHAR), CAST(b.mo AS VARCHAR), CAST(b.ob AS VARCHAR),
           CAST(b.oc AS VARCHAR), CAST(b.placa AS VARCHAR), CAST(b.cond AS VARCHAR), CAST(b.trans AS VARCHAR), CAST(TO_CHAR(b.hh, 'HH24:MI') AS VARCHAR),
           CAST(b.eo AS VARCHAR), b.fll, b.fin_, b.fdi, b.fsa,
           CASE WHEN b.fi IS NULL THEN NULL ELSE CAST(ROUND(EXTRACT(EPOCH FROM (b.fi - b.fe)) / 60.0) AS INT) END,
           CAST(CASE WHEN b.fi IS NOT NULL AND b.hh IS NOT NULL AND CAST(b.fi AS TIME) > b.hh THEN 'Y' ELSE 'N' END AS CHAR)
      FROM base b
      LEFT JOIN pausas p ON p.sid = b.sid AND p.eid = b.eid
     WHERE ("HV_Estado" IS NULL OR b.est = "HV_Estado")
       AND ("HV_Con_Vehiculo" IS NULL OR b.cv = "HV_Con_Vehiculo")
       AND (lv_t IS NULL OR b.cod ILIKE '%' || lv_t || '%' OR b.prov ILIKE '%' || lv_t || '%'
            OR COALESCE(b.oc, '') ILIKE '%' || lv_t || '%' OR COALESCE(b.placa, '') ILIKE '%' || lv_t || '%'
            OR COALESCE(b.cond, '') ILIKE '%' || lv_t || '%' OR COALESCE(b.trans, '') ILIKE '%' || lv_t || '%'
            OR COALESCE("ERP_CAF_FN_USUARIO_NOMBRE"(b.sol), '') ILIKE '%' || lv_t || '%'
            OR COALESCE("ERP_CAF_FN_USUARIO_NOMBRE"(b.res), '') ILIKE '%' || lv_t || '%'
            OR COALESCE("ERP_CAF_FN_USUARIO_NOMBRE"(b.ui), '') ILIKE '%' || lv_t || '%' OR COALESCE("ERP_CAF_FN_USUARIO_NOMBRE"(b.uf), '') ILIKE '%' || lv_t || '%')
     ORDER BY b.fe DESC, b.sid DESC, b.eord
     LIMIT 500;
END;
$$;
