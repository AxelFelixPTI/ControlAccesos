# Genera los SPs de catálogos (PostgreSQL), patrón Trianon.
# V1.1 2026-10-11 · una sola plantilla para los dos schemas:
#   - governance : 5 catálogos transversales de CAF_GOVERNANCE (Hito 0). Salida idéntica a la V1.0.
#   - caf        : 6 catálogos del módulo TRIANONSATELITAL_CAF_PRODD (Hito 1).
# Uso: python3 gen_catalogos.py [governance|caf|todos] [carpeta_salida]
# Todo lo que agrega la V1.1 es opcional por catálogo: si una clave no está, la plantilla
# produce exactamente lo mismo que la V1.0 (verificado con diff contra la salida de la V1.0).
import os, sys
OUT = "/mnt/user-data/outputs/ControlAccesos/Docs_Modulos/HITO_00_01_Base_y_Catalogos_2026-10-09/00_BD"
FECHA = "2026-10-11"


# -----------------------------------------------------------------------------
# Columnas propias de cada catálogo
# -----------------------------------------------------------------------------
def val_extra(col, tparam, oblig, default="N"):
    # Normaliza el valor que se guarda (texto: TRIM y vacío -> NULL; CHAR flag: default de la columna)
    if tparam is None:
        return None
    if tparam.startswith("VARCHAR"):
        return f"NULLIF(TRIM(\"HV_{col}\"),'')"
    if tparam == "CHAR(1)":
        return f"COALESCE(\"HV_{col}\",'{default}')"
    return f"\"HV_{col}\""

def X(col, ret, ptype, oblig=False, val="", sel=None, norm=None, param=True, default="N"):
    """Columna propia. param=False: solo se devuelve (viene de un JOIN), no se recibe ni se guarda."""
    return dict(col=col, ret=ret, ptype=ptype, oblig=oblig, val=val, param=param,
                sel=sel or f'T0."{col}"', norm=norm or val_extra(col, ptype, oblig, default))

def norm_extras(ex):
    # La V1.0 describía las columnas como tuplas (col, ret, ptype, oblig, val)
    return [e if isinstance(e, dict) else X(*e) for e in ex]

def FLAG(col, default):
    """Bandera Y/N. El respaldo del COALESCE es el DEFAULT de la columna en la tabla."""
    return X(col, "CHAR(1)", "CHAR(1)", True,
             f"""        IF COALESCE("HV_{col}",'{default}') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := '{col} debe ser Y o N.'; RETURN;
        END IF;
""", default=default)

def LISTA(col, ptype, valores, msg, oblig=True):
    """Texto de valores cerrados (el CHECK de la tabla): se guarda en MAYÚSCULAS."""
    lista = ",".join(f"'{v}'" for v in valores)
    if oblig:
        cond = f'"HV_{col}" IS NULL OR UPPER(TRIM("HV_{col}")) NOT IN ({lista})'
        norm = f'UPPER(TRIM("HV_{col}"))'
    else:
        cond = f'NULLIF(TRIM("HV_{col}"),\'\') IS NOT NULL AND UPPER(TRIM("HV_{col}")) NOT IN ({lista})'
        norm = f'NULLIF(UPPER(TRIM("HV_{col}")),\'\')'
    return X(col, "VARCHAR", ptype, oblig,
             f"""        IF {cond} THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := '{msg}'; RETURN;
        END IF;
""", norm=norm)


# -----------------------------------------------------------------------------
# Hito 0 · CAF_GOVERNANCE (sin cambios respecto de la V1.0)
# -----------------------------------------------------------------------------
# extras: (columna, tipo_retorno, tipo_param, obligatorio, validaciones_sql)
CATS_GOV = [
 dict(t="Catalogo_Sede", e="SEDE", art="La sede", nombre="Sede", g="a",
      extras=[("Direccion","VARCHAR","VARCHAR(500)",False,"")],
      uso=[("Personal","ID_Catalogo_Sede","trabajador(es)"),("Usuario_Licencia","ID_Catalogo_Sede","permiso(s) de usuario")],
      prueba="'LIM','Lima centro','Av. Ejemplo 123'"),
 dict(t="Catalogo_Area", e="AREA", art="El área", nombre="Área", g="a",
      extras=[], uso=[("Personal","ID_Catalogo_Area","trabajador(es)")], prueba="'LEGAL','Legal'"),
 dict(t="Catalogo_Cargo", e="CARGO", art="El cargo", nombre="Cargo", g="o",
      extras=[], uso=[("Personal","ID_Catalogo_Cargo","trabajador(es)")], prueba="'ANALISTA_SST','Analista SST'"),
 dict(t="Catalogo_Tipo_Documento", e="TIPO_DOCUMENTO", art="El tipo de documento", nombre="Tipo de documento", g="o",
      extras=[("Longitud_Min","BIGINT","BIGINT",True,
               """        IF "HV_Longitud_Min" IS NULL OR "HV_Longitud_Min" < 1 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La longitud mínima debe ser 1 o más.'; RETURN;
        END IF;
"""),
              ("Longitud_Max","BIGINT","BIGINT",True,
               """        IF "HV_Longitud_Max" IS NULL OR "HV_Longitud_Max" < "HV_Longitud_Min" THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La longitud máxima no puede ser menor que la mínima.'; RETURN;
        END IF;
"""),
              ("Solo_Numeros","CHAR(1)","CHAR(1)",True,
               """        IF COALESCE("HV_Solo_Numeros",'N') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Solo_Numeros debe ser Y o N.'; RETURN;
        END IF;
""")],
      uso=[("Personal","ID_Catalogo_Tipo_Documento","trabajador(es)"),("Usuario","ID_Catalogo_Tipo_Documento","usuario(s)")],
      prueba="'RUC_DOC','RUC como documento',11,11,'Y'"),
 dict(t="Catalogo_Empresa_Grupo", e="EMPRESA_GRUPO", art="La empresa", nombre="Empresa", g="a",
      extras=[("RUC","VARCHAR","VARCHAR(11)",False,
               """        IF "HV_RUC" IS NOT NULL AND LENGTH(TRIM("HV_RUC")) > 0
           AND (LENGTH(TRIM("HV_RUC")) <> 11 OR LTRIM(TRIM("HV_RUC"),'0123456789') <> '') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El RUC debe tener 11 dígitos.'; RETURN;
        END IF;
""")],
      uso=[("Personal","ID_Catalogo_Empresa_Grupo","trabajador(es)")],
      prueba="'EMPRESA_PRUEBA','Empresa de prueba','20123456789'"),
]


# -----------------------------------------------------------------------------
# Hito 1 · TRIANONSATELITAL_CAF_PRODD
# -----------------------------------------------------------------------------
GOV = '"CAF_GOVERNANCE"'   # schema transversal: siempre calificado; el del módulo, nunca (D-06, D-28)

USO_FUTURO = "        -- Uso por tablas de los Hitos 2 a 4 ({tablas}): se agrega aquí cuando existan.\n"

CATS_CAF = [
 dict(t="Catalogo_Tipo_Acceso", e="TIPO_ACCESO", art="El tipo de acceso", nombre="Tipo de acceso", g="o",
      extras=[FLAG("Requiere_Aprobacion", "Y"), FLAG("Disponible", "N")],
      uso=[("Tipo_Acceso_Item_Checklist","ID_Catalogo_Tipo_Acceso","ítem(s) de checklist asignado(s)")],
      uso_nota=USO_FUTURO.format(tablas="CAF_Solicitud"),
      dd_extra=[("Requiere_Aprobacion","CHAR(1)"),("Disponible","CHAR(1)")],
      prueba="'CONTRATISTA_PRUEBA','Contratista de prueba','Y','N'"),

 dict(t="Catalogo_Zona_Acceso", e="ZONA_ACCESO", art="La zona", nombre="Zona", g="a",
      extras=[X("ID_Catalogo_Sede","BIGINT","BIGINT",True),
              X("Codigo_Sede","VARCHAR",None,sel='S."Codigo"',param=False),
              X("Sede","VARCHAR",None,sel='S."Descripcion"',param=False),
              LISTA("Tipo_Zona","VARCHAR(20)",["ADMINISTRATIVA","OPERATIVA"],
                    "El tipo de zona debe ser ADMINISTRATIVA u OPERATIVA."),
              FLAG("Exige_SCTR","N"), FLAG("Exige_EPP","N")],
      joins=f'      LEFT JOIN {GOV}."Catalogo_Sede" S ON S."ID_Catalogo_Sede" = T0."ID_Catalogo_Sede"\n',
      listar_params=[('"HV_ID_Catalogo_Sede" BIGINT DEFAULT NULL',
                      '("HV_ID_Catalogo_Sede" IS NULL OR T0."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede")')],
      order='S."Orden", S."Codigo", T0."Orden", T0."Codigo"',
      decl="    lv_n         INT := 0;\n",
      val_crear=f"""        SELECT COUNT(*) INTO lv_n FROM {GOV}."Catalogo_Sede"
         WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N' AND "Activo" = 'Y';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La sede no existe o está inactiva.'; RETURN;
        END IF;

""",
      val_act=f"""        SELECT COUNT(*) INTO lv_n FROM {GOV}."Catalogo_Sede"
         WHERE "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede" AND "Eliminado" = 'N';
        IF lv_n = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La sede no existe.'; RETURN;
        END IF;

""",
      # El UNIQUE de la tabla es (sede, código): el mismo código puede repetirse en otra sede
      dup_and=' AND "ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"',
      dup_msg_c="Ya existe una zona con ese código en esa sede (puede estar eliminada).",
      dup_msg_a="Ya existe otra zona con ese código en esa sede.",
      uso=[], uso_nota=USO_FUTURO.format(tablas="CAF_Solicitud_Zona"),
      dd_params=[('"HV_ID_Catalogo_Sede" BIGINT', 'T0."ID_Catalogo_Sede" = "HV_ID_Catalogo_Sede"')],
      dd_extra=[("Tipo_Zona","VARCHAR"),("Exige_SCTR","CHAR(1)"),("Exige_EPP","CHAR(1)")],
      dd_order='T0."Orden", T0."Codigo"',
      dd_nota="solo activos de UNA sede",
      prueba="'ALMACEN_PRUEBA','Almacén de prueba',1,'OPERATIVA','Y','Y'"),

 dict(t="Catalogo_Motivo_Visita", e="MOTIVO_VISITA", art="El motivo", nombre="Motivo de visita", g="o",
      extras=[FLAG("Es_Otro","N")],
      uso=[], uso_nota=USO_FUTURO.format(tablas="CAF_Solicitud"),
      dd_extra=[("Es_Otro","CHAR(1)")],
      prueba="'CAPACITACION','Capacitación','N'"),

 dict(t="Catalogo_Tratamiento_Desviacion", e="TRATAMIENTO_DESVIACION", art="El tratamiento", nombre="Tratamiento", g="o",
      extras=[FLAG("Aplica_Ingreso","N"), FLAG("Aplica_Salida","N"),
              LISTA("Resultado_Ingreso","VARCHAR(30)",["INGRESA","INGRESA_RESTRINGIDO","NO_INGRESA"],
                    "El resultado de ingreso debe ser INGRESA, INGRESA_RESTRINGIDO o NO_INGRESA.", oblig=False),
              LISTA("Resultado_Salida","VARCHAR(30)",["SALE","SALE_RETIENE_ELEMENTO"],
                    "El resultado de salida debe ser SALE o SALE_RETIENE_ELEMENTO.", oblig=False),
              FLAG("Es_Otro","N")],
      # D-11: el efecto se guarda por etapa; para "Otro", Vigilancia lo elige al registrar
      val_neg="""        IF COALESCE("HV_Aplica_Ingreso",'N') = 'N' AND COALESCE("HV_Aplica_Salida",'N') = 'N' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tratamiento debe aplicar al ingreso, a la salida o a ambos.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Ingreso",'N') = 'N' AND NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Si no aplica al ingreso, no lleva resultado de ingreso.'; RETURN;
        END IF;
        IF COALESCE("HV_Aplica_Salida",'N') = 'N' AND NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Si no aplica a la salida, no lleva resultado de salida.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'Y'
           AND (NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NOT NULL OR NULLIF(TRIM("HV_Resultado_Salida"),'') IS NOT NULL) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El tratamiento "Otro" no lleva resultado fijo: Vigilancia lo elige al registrar.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'N' AND COALESCE("HV_Aplica_Ingreso",'N') = 'Y' AND NULLIF(TRIM("HV_Resultado_Ingreso"),'') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el resultado al ingreso.'; RETURN;
        END IF;
        IF COALESCE("HV_Es_Otro",'N') = 'N' AND COALESCE("HV_Aplica_Salida",'N') = 'Y' AND NULLIF(TRIM("HV_Resultado_Salida"),'') IS NULL THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique el resultado a la salida.'; RETURN;
        END IF;
""",
      uso=[], uso_nota=USO_FUTURO.format(tablas="CAF_Desviacion"),
      # Filtro por etapa resuelto en variables antes del SELECT (sin OR anidados: trianon-hana-sp ref 05 §2-bis)
      dd_params=[('"HV_Etapa" VARCHAR DEFAULT NULL',
                  'T0."Aplica_Ingreso" LIKE lv_ingreso AND T0."Aplica_Salida" LIKE lv_salida')],
      dd_decl="""DECLARE
    lv_ingreso VARCHAR(1) := '%';
    lv_salida  VARCHAR(1) := '%';
""",
      dd_pre="""    IF UPPER(TRIM("HV_Etapa")) = 'INGRESO' THEN
        lv_ingreso := 'Y';
    ELSIF UPPER(TRIM("HV_Etapa")) = 'SALIDA' THEN
        lv_salida := 'Y';
    ELSIF LENGTH(TRIM("HV_Etapa")) > 0 THEN
        lv_ingreso := '~';   -- etapa desconocida: ninguna fila
    END IF;
""",
      dd_extra=[("Aplica_Ingreso","CHAR(1)"),("Aplica_Salida","CHAR(1)"),
                ("Resultado_Ingreso","VARCHAR"),("Resultado_Salida","VARCHAR"),("Es_Otro","CHAR(1)")],
      dd_nota="solo activos; HV_Etapa INGRESO / SALIDA / NULL = todos",
      prueba="'RETIENE_PRUEBA','Retiene el elemento','N','Y',NULL,'SALE_RETIENE_ELEMENTO','N'"),

 dict(t="Catalogo_Tipo_Incidencia", e="TIPO_INCIDENCIA", art="El tipo de incidencia", nombre="Tipo de incidencia", g="o",
      extras=[FLAG("Es_Otro","N")],
      uso=[], uso_nota=USO_FUTURO.format(tablas="CAF_Incidencia"),
      dd_extra=[("Es_Otro","CHAR(1)")],
      prueba="'ZONA_NO_AUTORIZADA','Ingreso a zona no autorizada','N'"),

 dict(t="Catalogo_Item_Checklist", e="ITEM_CHECKLIST", art="El ítem", nombre="Ítem de checklist", g="o",
      extras=[X("Ayuda","VARCHAR","VARCHAR(500)",False),
              LISTA("Etapa","VARCHAR(10)",["INGRESO","SALIDA"],"La etapa debe ser INGRESO o SALIDA."),
              LISTA("Condicion","VARCHAR(30)",["SIEMPRE","ZONA_EXIGE_SCTR","ZONA_EXIGE_EPP","TRAE_EQUIPOS","TRAE_HERRAMIENTAS"],
                    "La condición debe ser SIEMPRE, ZONA_EXIGE_SCTR, ZONA_EXIGE_EPP, TRAE_EQUIPOS o TRAE_HERRAMIENTAS."),
              FLAG("Es_Critico","N")],
      order='T0."Etapa", T0."Orden", T0."Codigo"',
      uso=[("Tipo_Acceso_Item_Checklist","ID_Catalogo_Item_Checklist","tipo(s) de acceso")],
      uso_nota=USO_FUTURO.format(tablas="CAF_Registro_Checklist"),
      dd_params=[('"HV_Etapa" VARCHAR DEFAULT NULL', 'T0."Etapa" LIKE lv_etapa')],
      dd_decl="""DECLARE
    lv_etapa VARCHAR(10) := '%';
""",
      dd_pre="""    IF LENGTH(TRIM("HV_Etapa")) > 0 THEN
        lv_etapa := UPPER(TRIM("HV_Etapa"));
    END IF;
""",
      dd_extra=[("Ayuda","VARCHAR"),("Etapa","VARCHAR"),("Condicion","VARCHAR"),("Es_Critico","CHAR(1)")],
      dd_nota="solo activos; HV_Etapa INGRESO / SALIDA / NULL = todos",
      prueba="'CASCO_PRUEBA','Casco de seguridad','Use casco en planta','INGRESO','ZONA_EXIGE_EPP','Y'"),
]


SCHEMAS = {
 "governance": dict(schema="CAF_GOVERNANCE", pref="SP_GOVERNANCE_", usr='"Usuario"', cats=CATS_GOV,
                    hito="0 - Base", pruebas="PRUEBAS_FASE1_HITO0.sql",
                    gen="gen_catalogos.py (misma plantilla para los 5 catálogos transversales)", notas=""),
 "caf": dict(schema="TRIANONSATELITAL_CAF_PRODD", pref="SP_CAF_", usr=f'{GOV}."Usuario"', cats=CATS_CAF,
             hito="1 - Catálogos del módulo", pruebas="PRUEBAS_FASE1_HITO1.sql",
             gen="gen_catalogos.py V1.1 (misma plantilla que los catálogos transversales del Hito 0)",
             notas="""-- Referencias a CAF_GOVERNANCE (Usuario, Catalogo_Sede) siempre calificadas: no
-- hay llave foránea entre schemas y se validan aquí (D-06). El schema del módulo
-- no se escribe en el cuerpo: lo fija el search_path de cada rutina (D-28).
"""),
}


def gen(c, S):
    SCHEMA = S["schema"]
    t, e, pk = c["t"], c["e"], "ID_" + c["t"]
    ex = norm_extras(c["extras"])
    px = [x for x in ex if x["param"]]
    ret_ex = "".join(f'"{x["col"]}" {x["ret"]}, ' for x in ex)
    sel_ex = "".join(f'{x["sel"]}, ' for x in ex)
    in_ex = "".join(f'    IN    "HV_{x["col"]}" {x["ptype"]},\n' for x in px)
    vals_ex = "".join(x["val"] for x in px) + c.get("val_neg", "")
    ins_cols = "".join(f'"{x["col"]}",' for x in px)
    ins_vals = "".join(x["norm"] + ", " for x in px)
    upd_set = "".join(f'"{x["col"]}" = {x["norm"]}, ' for x in px)
    joins = c.get("joins", "")
    order = c.get("order", 'T0."Orden", T0."Codigo"')
    decl = c.get("decl", "")
    dup_and = c.get("dup_and", "")
    lp = c.get("listar_params", [])
    lp_decl = "".join(p[0] + ", " for p in lp)
    lp_where = "".join(f"\n       AND {p[1]}" for p in lp)
    ret = f'''RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Tipo_Entidad" VARCHAR, {ret_ex}"Orden" BIGINT, "Activo" CHAR(1), "Eliminado" CHAR(1),
                "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR, "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)'''
    sel = f'''SELECT T0."{pk}", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), {sel_ex}T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "{t}" T0
{joins}      LEFT JOIN {S["usr"]} T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"'''
    common_val = f'''        IF "HV_Codigo" IS NULL OR LENGTH(TRIM("HV_Codigo")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'El código es obligatorio.'; RETURN;
        END IF;
        IF "HV_Descripcion" IS NULL OR LENGTH(TRIM("HV_Descripcion")) = 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La descripción es obligatoria.'; RETURN;
        END IF;
        IF COALESCE("HV_Activo",'Y') NOT IN ('Y','N') THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Activo debe ser Y o N.'; RETURN;
        END IF;
{vals_ex}'''
    uso_sql = ""
    for (tab, col, txt) in c["uso"]:
        uso_sql += f'''        SELECT COUNT(*) INTO lv_en_uso FROM "{tab}" WHERE "{col}" = "HV_{pk}" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' {txt}. Desactível{c["g"]} en vez de eliminarl{c["g"]}.'; RETURN;
        END IF;
'''
    uso_sql += c.get("uso_nota", "")
    dup_c = c.get("dup_msg_c", "Ya existe un registro con ese código (puede estar eliminado).")
    dup_a = c.get("dup_msg_a", "Ya existe otro registro con ese código.")

    # DROPDOWN
    ddp = c.get("dd_params", [])
    dd_sig = ", ".join(p[0] for p in ddp)
    dd_where = "".join(f" AND {p[1]}" for p in ddp)
    dd_ret_ex = "".join(f', "{n}" {tp}' for (n, tp) in c.get("dd_extra", []))
    dd_sel_ex = "".join(f', T0."{n}"' for (n, tp) in c.get("dd_extra", []))
    dd_decl = c.get("dd_decl", "")
    dd_pre = c.get("dd_pre", "")
    dd_order = c.get("dd_order", order)
    dd_nota = c.get("dd_nota", "solo activos, para listas desplegables")
    dd_prueba = "1" if ddp and "Sede" in ddp[0][0] else ("'INGRESO'" if ddp else "")

    hdr = f'''-- =============================================================================
-- Archivo : {S["pref"]}{t.upper()}_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : {SCHEMA}
-- Hito    : {S["hito"]} | Fase 1 - Procedimientos
-- Entidad : {t} (catálogo)
-- Versión : V1.0 {FECHA}
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver {S["pruebas"]})
-- Generado: {S["gen"]}
-- =============================================================================
-- Orden: 1 LISTAR · 2 CREAR · 3 DETALLE · 4 ACTUALIZAR · 5 ELIMINAR · 6 DROPDOWN
-- Lectura (LISTAR, DETALLE, DROPDOWN): funciones RETURNS TABLE, sin contrato ni
-- manejo de error (en HANA: procedimientos sin OUT ni EXIT HANDLER).
-- Escritura: procedimientos con HV_Codigo_Resp / HV_Mensaje.
-- DETALLE no filtra Eliminado (default del proyecto).
-- Los códigos se guardan en MAYÚSCULAS y no se reutilizan aunque el registro
-- esté eliminado (el UNIQUE de la tabla no distingue eliminados) - D-24.
{S["notas"]}-- =============================================================================

SET search_path TO "{SCHEMA}";
'''
    s = hdr
    s += f'''
-- -----------------------------------------------------------------------------
-- 1. ERP_CATALOGO_{e}_LISTAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_{e}_LISTAR"({lp_decl}"HV_Incluir_Eliminados" CHAR(1) DEFAULT 'N')
{ret}
LANGUAGE plpgsql SET search_path TO "{SCHEMA}" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 {FECHA}
    RETURN QUERY
    {sel}
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N'){lp_where}
     ORDER BY {order};
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_{e}_LISTAR"();

-- -----------------------------------------------------------------------------
-- 2. ERP_CATALOGO_{e}_CREAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_{e}_CREAR"(
    IN    "HV_Codigo" VARCHAR(50),
    IN    "HV_Descripcion" VARCHAR(500),
{in_ex}    IN    "HV_Orden" BIGINT,
    IN    "HV_Activo" CHAR(1),
    IN    "HV_UsuarioID_Create" BIGINT,
    INOUT "HV_{pk}_Result" BIGINT DEFAULT NULL,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "{SCHEMA}" AS $$
DECLARE
    lv_duplicado INT := 0;
{decl}BEGIN
    -- V1.0 {FECHA}
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_{e}_CREAR';
    "HV_{pk}_Result" := 0;
    BEGIN
{common_val}        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

{c.get("val_crear", "")}        SELECT COUNT(*) INTO lv_duplicado FROM "{t}"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")){dup_and};
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := '{dup_c}'; RETURN;
        END IF;

        INSERT INTO "{t}" ("Codigo","Descripcion",{ins_cols}"Orden","Activo","UsuarioID_Create")
        VALUES (UPPER(TRIM("HV_Codigo")), TRIM("HV_Descripcion"), {ins_vals}COALESCE("HV_Orden",0), COALESCE("HV_Activo",'Y'), "HV_UsuarioID_Create")
        RETURNING "{pk}" INTO "HV_{pk}_Result";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := '{c["nombre"]} registrad{c["g"]} correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_{e}_CREAR';
        "HV_{pk}_Result" := 0;
    END;
END;
$$;
-- Prueba: CALL "ERP_CATALOGO_{e}_CREAR"({c["prueba"]},10,'Y',0);

-- -----------------------------------------------------------------------------
-- 3. ERP_CATALOGO_{e}_DETALLE  (no filtra Eliminado)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_{e}_DETALLE"("HV_{pk}" BIGINT)
{ret}
LANGUAGE plpgsql SET search_path TO "{SCHEMA}" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 {FECHA}
    RETURN QUERY
    {sel}
     WHERE T0."{pk}" = "HV_{pk}";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_{e}_DETALLE"(1);

-- -----------------------------------------------------------------------------
-- 4. ERP_CATALOGO_{e}_ACTUALIZAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_{e}_ACTUALIZAR"(
    IN    "HV_{pk}" BIGINT,
    IN    "HV_Codigo" VARCHAR(50),
    IN    "HV_Descripcion" VARCHAR(500),
{in_ex}    IN    "HV_Orden" BIGINT,
    IN    "HV_Activo" CHAR(1),
    IN    "HV_UsuarioID" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "{SCHEMA}" AS $$
DECLARE
    lv_existe    INT := 0;
    lv_duplicado INT := 0;
{decl}BEGIN
    -- V1.0 {FECHA}
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_{e}_ACTUALIZAR';
    BEGIN
{common_val}        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "{t}" WHERE "{pk}" = "HV_{pk}" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

{c.get("val_act", "")}        SELECT COUNT(*) INTO lv_duplicado FROM "{t}"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")){dup_and} AND "{pk}" <> "HV_{pk}";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := '{dup_a}'; RETURN;
        END IF;

        UPDATE "{t}"
           SET "Codigo" = UPPER(TRIM("HV_Codigo")), "Descripcion" = TRIM("HV_Descripcion"), {upd_set}
               "Orden" = COALESCE("HV_Orden",0), "Activo" = COALESCE("HV_Activo",'Y'),
               "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "{pk}" = "HV_{pk}";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := '{c["nombre"]} actualizad{c["g"]} correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_{e}_ACTUALIZAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. ERP_CATALOGO_{e}_ELIMINAR  (borrado lógico; no si está en uso)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE "ERP_CATALOGO_{e}_ELIMINAR"(
    IN    "HV_{pk}" BIGINT,
    IN    "HV_UsuarioID_Update" BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje" VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "{SCHEMA}" AS $$
DECLARE
    lv_existe INT := 0;
    lv_en_uso INT := 0;
BEGIN
    -- V1.0 {FECHA}
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_{e}_ELIMINAR';
    BEGIN
        IF "HV_UsuarioID_Update" IS NULL OR "HV_UsuarioID_Update" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_existe FROM "{t}" WHERE "{pk}" = "HV_{pk}" AND "Eliminado" = 'N';
        IF lv_existe = 0 THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El registro no existe o ya fue eliminado.'; RETURN;
        END IF;

{uso_sql}
        UPDATE "{t}"
           SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID_Update", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "{pk}" = "HV_{pk}";

        "HV_Codigo_Resp" := 100;
        "HV_Mensaje"     := '{c["nombre"]} eliminad{c["g"]} correctamente.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500;
        "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_{e}_ELIMINAR';
    END;
END;
$$;

-- -----------------------------------------------------------------------------
-- 6. ERP_CATALOGO_{e}_DROPDOWN  ({dd_nota})
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_{e}_DROPDOWN"({dd_sig})
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR{dd_ret_ex})
LANGUAGE plpgsql SET search_path TO "{SCHEMA}" AS $$
#variable_conflict use_column
{dd_decl}BEGIN
    -- V1.0 {FECHA}
{dd_pre}    RETURN QUERY
    SELECT T0."{pk}", T0."Codigo", T0."Descripcion"{dd_sel_ex}
      FROM "{t}" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'{dd_where}
     ORDER BY {dd_order};
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_{e}_DROPDOWN"({dd_prueba});
'''
    return s


if __name__ == "__main__":
    cual = sys.argv[1] if len(sys.argv) > 1 else "todos"
    out = sys.argv[2] if len(sys.argv) > 2 else OUT
    os.makedirs(out, exist_ok=True)
    for k in (["governance", "caf"] if cual == "todos" else [cual]):
        S = SCHEMAS[k]
        for c in S["cats"]:
            fn = os.path.join(out, f"{S['pref']}{c['t'].upper()}_ALL.sql")
            open(fn, "w", encoding="utf-8").write(gen(c, S))
            print("ok", fn.split('/')[-1])
