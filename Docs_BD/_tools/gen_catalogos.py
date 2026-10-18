# Genera los SPs de catálogos del schema CAF_GOVERNANCE (PostgreSQL), patrón Trianon.
import os
OUT = "/mnt/user-data/outputs/ControlAccesos/Docs_Modulos/HITO_00_01_Base_y_Catalogos_2026-10-09/00_BD"
FECHA = "2026-10-11"
SCHEMA = "CAF_GOVERNANCE"

# extras: (columna, tipo_retorno, tipo_param, obligatorio, validaciones_sql)
CATS = [
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

def val_extra(col, tparam, oblig):
    # Normaliza el valor que se guarda (texto: TRIM y vacío -> NULL; CHAR flag: default N)
    if tparam.startswith("VARCHAR"):
        return f"NULLIF(TRIM(\"HV_{col}\"),'')"
    if tparam == "CHAR(1)":
        return f"COALESCE(\"HV_{col}\",'N')"
    return f"\"HV_{col}\""

def gen(c):
    t, e, pk = c["t"], c["e"], "ID_" + c["t"]
    ex = c["extras"]
    ret_ex = "".join(f'"{x[0]}" {x[1]}, ' for x in ex)
    sel_ex = "".join(f'T0."{x[0]}", ' for x in ex)
    in_ex = "".join(f'    IN    "HV_{x[0]}" {x[2]},\n' for x in ex)
    vals_ex = "".join(x[4] for x in ex)
    ins_cols = "".join(f'"{x[0]}",' for x in ex)
    ins_vals = "".join(val_extra(x[0], x[2], x[3]) + ", " for x in ex)
    upd_set = "".join(f'"{x[0]}" = {val_extra(x[0], x[2], x[3])}, ' for x in ex)
    ret = f'''RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR, "Tipo_Entidad" VARCHAR, {ret_ex}"Orden" BIGINT, "Activo" CHAR(1), "Eliminado" CHAR(1),
                "UsuarioID_Create" BIGINT, "Nombre_Usuario" VARCHAR, "UsuarioID_Update" BIGINT, "CreateDate" TIMESTAMP, "UpdateDate" TIMESTAMP)'''
    sel = f'''SELECT T0."{pk}", T0."Codigo", T0."Descripcion", CAST(NULL AS VARCHAR), {sel_ex}T0."Orden", T0."Activo", T0."Eliminado",
           T0."UsuarioID_Create",
           CAST(CASE WHEN T0."UsuarioID_Create" = 0 THEN 'Sistema' ELSE T1."Nombres" || ' ' || T1."Apellido_Paterno" END AS VARCHAR),
           T0."UsuarioID_Update", T0."CreateDate", T0."UpdateDate"
      FROM "{t}" T0
      LEFT JOIN "Usuario" T1 ON T1."ID_Usuario" = T0."UsuarioID_Create"'''
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
        pass
    for (tab, col, txt) in c["uso"]:
        uso_sql += f'''        SELECT COUNT(*) INTO lv_en_uso FROM "{tab}" WHERE "{col}" = "HV_{pk}" AND "Eliminado" = 'N';
        IF lv_en_uso > 0 THEN
            "HV_Codigo_Resp" := 101;
            "HV_Mensaje" := 'Está en uso por ' || lv_en_uso || ' {txt}. Desactível{c["g"]} en vez de eliminarl{c["g"]}.'; RETURN;
        END IF;
'''
    hdr = f'''-- =============================================================================
-- Archivo : SP_GOVERNANCE_{t.upper()}_ALL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Schema  : {SCHEMA}
-- Hito    : 0 - Base | Fase 1 - Procedimientos
-- Entidad : {t} (catálogo)
-- Versión : V1.0 {FECHA}
-- Estado  : CANDIDATO - probado en PostgreSQL 16 (ver PRUEBAS_FASE1_HITO0.sql)
-- Generado: gen_catalogos.py (misma plantilla para los 5 catálogos transversales)
-- =============================================================================
-- Orden: 1 LISTAR · 2 CREAR · 3 DETALLE · 4 ACTUALIZAR · 5 ELIMINAR · 6 DROPDOWN
-- Lectura (LISTAR, DETALLE, DROPDOWN): funciones RETURNS TABLE, sin contrato ni
-- manejo de error (en HANA: procedimientos sin OUT ni EXIT HANDLER).
-- Escritura: procedimientos con HV_Codigo_Resp / HV_Mensaje.
-- DETALLE no filtra Eliminado (default del proyecto).
-- Los códigos se guardan en MAYÚSCULAS y no se reutilizan aunque el registro
-- esté eliminado (el UNIQUE de la tabla no distingue eliminados) - D-24.
-- =============================================================================

SET search_path TO "{SCHEMA}";
'''
    s = hdr
    s += f'''
-- -----------------------------------------------------------------------------
-- 1. ERP_CATALOGO_{e}_LISTAR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_{e}_LISTAR"("HV_Incluir_Eliminados" CHAR(1) DEFAULT 'N')
{ret}
LANGUAGE plpgsql SET search_path TO "{SCHEMA}" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 {FECHA}
    RETURN QUERY
    {sel}
     WHERE ("HV_Incluir_Eliminados" = 'Y' OR T0."Eliminado" = 'N')
     ORDER BY T0."Orden", T0."Codigo";
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
BEGIN
    -- V1.0 {FECHA}
    "HV_Codigo_Resp" := 500;
    "HV_Mensaje"     := 'Error interno en ERP_CATALOGO_{e}_CREAR';
    "HV_{pk}_Result" := 0;
    BEGIN
{common_val}        IF "HV_UsuarioID_Create" IS NULL OR "HV_UsuarioID_Create" < 0 THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN;
        END IF;

        SELECT COUNT(*) INTO lv_duplicado FROM "{t}"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo"));
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe un registro con ese código (puede estar eliminado).'; RETURN;
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
BEGIN
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

        SELECT COUNT(*) INTO lv_duplicado FROM "{t}"
         WHERE UPPER(TRIM("Codigo")) = UPPER(TRIM("HV_Codigo")) AND "{pk}" <> "HV_{pk}";
        IF lv_duplicado > 0 THEN
            "HV_Codigo_Resp" := 101; "HV_Mensaje" := 'Ya existe otro registro con ese código.'; RETURN;
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
-- 6. ERP_CATALOGO_{e}_DROPDOWN  (solo activos, para listas desplegables)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION "ERP_CATALOGO_{e}_DROPDOWN"()
RETURNS TABLE ("ID_Catalogo" BIGINT, "Codigo" VARCHAR, "Descripcion" VARCHAR)
LANGUAGE plpgsql SET search_path TO "{SCHEMA}" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 {FECHA}
    RETURN QUERY
    SELECT T0."{pk}", T0."Codigo", T0."Descripcion"
      FROM "{t}" T0
     WHERE T0."Eliminado" = 'N' AND T0."Activo" = 'Y'
     ORDER BY T0."Orden", T0."Codigo";
END;
$$;
-- Prueba: SELECT * FROM "ERP_CATALOGO_{e}_DROPDOWN"();
'''
    return s

for c in CATS:
    fn = os.path.join(OUT, f"SP_GOVERNANCE_{c['t'].upper()}_ALL.sql")
    open(fn, "w", encoding="utf-8").write(gen(c))
    print("ok", fn.split('/')[-1])
