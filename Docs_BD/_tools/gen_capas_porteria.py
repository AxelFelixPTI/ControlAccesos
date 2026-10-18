# -*- coding: utf-8 -*-
# gen_capas_porteria.py  V1.0 2026-10-17
# Genera las capas .NET del Hito 3 (portería, desviaciones y respaldos) desde las FIRMAS REALES de las rutinas:
#   python3 gen_capas_porteria.py firmas_rutinas_hito3.txt <carpeta src>
# Los DTO de RESPUESTA salen de las columnas que devuelve cada función. Los de ENTRADA están en este archivo.
# verificar_llamadas.py comprueba nombres, orden y tipos de cada llamada contra la base.
import re, sys, os

firmas_file, destino = sys.argv[1], sys.argv[2]
FECHA = "V1.0 — 2026-10-17"

firmas = {}
for ln in open(firmas_file, encoding="utf-8"):
    if ln.startswith("#") or not ln.strip():
        continue
    sch, nom, kind, args, res = ln.rstrip("\n").split("|")
    firmas[nom] = dict(schema=sch, kind=kind, args=args, res=res)

def columnas(res):
    m = re.match(r'TABLE\((.*)\)$', res)
    out = []
    for c in re.findall(r'"([A-Za-z_0-9]+)" ([a-z ]+?)(?=, "|$)', m.group(1)):
        out.append((c[0], c[1].strip()))
    return out

ID_NO_NULOS = {"ID_Solicitud", "ID_Catalogo_Sede", "ID_Solicitud_Persona", "ID_Registro_Acceso", "ID_Desviacion", "ID_Respaldo",
               "ID_Catalogo_Item_Checklist", "ID_Usuario", "ID_Catalogo_Tratamiento_Desviacion"}
NULABLE_EN = {("ERP_CAF_PORTERIA_REGISTRO_DETALLE", "ID_Desviacion")}
TEXTO_NO_NULO = {"Codigo", "Codigo_Solicitud", "Estado", "Persona_Nombre", "Tipo_Movimiento", "Categoria", "Tipo_Respaldo",
                 "Descripcion", "Nombre"}
FECHA_NO_NULA = {"Fecha_Hora_Prevista", "Fecha_Hora", "Fecha_Hora_Sistema"}

def tipo_cs(col, t, fn=None):
    """→ (tipo C#, ¿nullable?, lector)"""
    if t == "character":
        return "bool", False, "RdBool"
    if t == "integer":
        return "int", False, "RdInt"
    if t == "bigint":
        if col.startswith("ID_") and (col not in ID_NO_NULOS or (fn, col) in NULABLE_EN):
            return "long?", True, "RdLongN"
        return "long", False, "RdLong"
    if t.startswith("timestamp"):
        if col in FECHA_NO_NULA:
            return "DateTime", False, "RdDt"
        return "DateTime?", True, "RdDtN"
    if t == "date":
        return "DateTime?", True, "RdDtN"
    if col in TEXTO_NO_NULO:
        return "string", False, "RdStr"
    return "string?", True, "RdStrN"

def cabecera(archivo, ruta, fase, entidad, nota=""):
    return (f"// ============================================================\n"
            f"// Archivo  : {archivo}\n// Ruta     : {ruta}/\n// Módulo   : ControlAccesos\n"
            f"// Hito     : 3 — Portería y desviaciones\n// Fase     : {fase}\n// Entidad  : {entidad}\n"
            f"// Versión  : {FECHA}\n// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)\n"
            f"// ============================================================\n{nota}\n")

def escribir(carpeta, nombre, texto):
    d = os.path.join(destino, carpeta, "ControlAccesos")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, nombre), "w", encoding="utf-8", newline="\n") as f:
        f.write(texto)

LECTURAS = {
    "ERP_CAF_PORTERIA_CHECKLIST_OBTENER":          ("Dto_Porteria_Item",          "ítem del checklist que Vigilancia debe marcar"),
    "ERP_CAF_PORTERIA_FICHA":                      ("Dto_Porteria_Ficha",         "ficha de la persona en portería, con botones y motivos"),
    "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR":         ("Dto_Porteria_Movimiento",    "fila de la bitácora de ingresos y salidas"),
    "ERP_CAF_PORTERIA_REGISTRO_DETALLE":           ("Dto_Porteria_Registro",      "un movimiento de portería"),
    "ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR":  ("Dto_Porteria_Registro_Item", "ítem marcado en un movimiento"),
    "ERP_CAF_RESPALDO_LISTAR_POR_PERSONA":         ("Dto_Respaldo",               "respaldo que cubre a la persona"),
    "ERP_CAF_DESVIACION_LISTAR":                   ("Dto_Desviacion_Lista",       "fila del listado de desviaciones"),
    "ERP_CAF_DESVIACION_DETALLE":                  ("Dto_Desviacion_Detalle",     "desviación completa, con el botón de conformidad"),
    "ERP_CAF_DESVIACION_CONTADORES":               ("Dto_Desviacion_Contadores",  "números de las insignias de desviaciones"),
    "ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN":   ("Dto_Desviacion_Coordinador", "Coordinador al que se puede consultar"),
    "ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN":    ("Dto_Desviacion_Tratamiento", "tratamiento válido para la etapa"),
}
COLS = {}
for fn, (dto, desc) in LECTURAS.items():
    COLS[fn] = columnas(firmas[fn]["res"])
    L = [cabecera(dto + ".cs", "Application.DTOs", "2 — DTOs", dto.replace("Dto_", ""),
                  f"// Respuesta de {fn}: {desc}.\n// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.\n"
                  "// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.\n"),
         "namespace Application.DTOs.ControlAccesos;\n\npublic sealed class " + dto + "\n{\n"]
    for c, t in COLS[fn]:
        ct, nul, rd = tipo_cs(c, t, fn)
        ini = " = string.Empty;" if ct == "string" else ""
        L.append(f"    public {ct} {c} {{ get; set; }}{ini}\n")
    L.append("}\n")
    escribir("Application.DTOs", dto + ".cs", "".join(L))

ENTRADAS = cabecera("Dto_Porteria_Entradas.cs", "Application.DTOs", "2 — DTOs", "Portería — formularios y filtros",
"// Lo que la pantalla ENVÍA. Las listas se convierten en el texto que esperan las rutinas (id:Y,id:N / 1,2,3).\n"
"// Las reglas de negocio viven en la rutina (D-40).\n") + """using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

/// <summary>Respuesta de Vigilancia a un ítem del checklist.</summary>
public sealed class Dto_Porteria_Respuesta
{
    public long ID_Catalogo_Item_Checklist { get; set; }
    /// <summary>true = cumple (Y); false = no cumple (N).</summary>
    public bool Cumple { get; set; }
}

/// <summary>Desviación que se levanta cuando algún ítem no cumple (ingreso o salida).</summary>
public sealed class Dto_Porteria_Desviacion_Entrada
{
    public string? Descripcion { get; set; }
    /// <summary>Coordinador consultado (ver ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN).</summary>
    public long? ID_Coordinador { get; set; }
    public long? ID_Tratamiento { get; set; }
    /// <summary>Obligatorio con el tratamiento «Otro».</summary>
    public string? Tratamiento_Detalle { get; set; }
    /// <summary>Solo con «Otro»: el efecto que decide el Coordinador.</summary>
    public string? Resultado_Elegido { get; set; }
}

/// <summary>Registrar un ingreso (ERP_CAF_PORTERIA_INGRESO_REGISTRAR).</summary>
public sealed class Dto_Porteria_Ingreso
{
    [Range(1, long.MaxValue, ErrorMessage = "Falta la persona.")]
    public long ID_Solicitud_Persona { get; set; }
    /// <summary>TODOS los ítems que devolvió el checklist, cumplan o no.</summary>
    public List<Dto_Porteria_Respuesta> Items { get; set; } = new();
    public bool Trae_Equipos { get; set; }
    public bool Trae_Herramientas { get; set; }
    public string? Observacion { get; set; }
    /// <summary>Solo si algún ítem no cumple.</summary>
    public Dto_Porteria_Desviacion_Entrada? Desviacion { get; set; }
    /// <summary>Solo para un registro tardío: hora real del hecho (la observación pasa a ser obligatoria).</summary>
    public DateTime? Fecha_Hora_Hecho { get; set; }
}

/// <summary>Registrar una salida (ERP_CAF_PORTERIA_SALIDA_REGISTRAR).</summary>
public sealed class Dto_Porteria_Salida
{
    [Range(1, long.MaxValue, ErrorMessage = "Falta la persona.")]
    public long ID_Solicitud_Persona { get; set; }
    public List<Dto_Porteria_Respuesta> Items { get; set; } = new();
    public string? Observacion { get; set; }
    public Dto_Porteria_Desviacion_Entrada? Desviacion { get; set; }
    public DateTime? Fecha_Hora_Hecho { get; set; }
}

/// <summary>Resultado de registrar un movimiento.</summary>
public sealed class Dto_Porteria_Registrado
{
    public long ID_Registro_Acceso { get; set; }
    /// <summary>Nulo si no hubo desviación.</summary>
    public long? ID_Desviacion { get; set; }
    /// <summary>INGRESA, INGRESA_RESTRINGIDO, NO_INGRESA, SALE o SALE_RETIENE_ELEMENTO.</summary>
    public string Resultado { get; set; } = string.Empty;
}

/// <summary>Registrar un respaldo (G-FSCA-009, guía de remisión o G-FSCA-010).</summary>
public sealed class Dto_Respaldo_Registrar
{
    /// <summary>EQUIPOS o HERRAMIENTAS_MATERIALES.</summary>
    public string Categoria { get; set; } = string.Empty;
    /// <summary>G_FSCA_009, GUIA_REMISION o GUIA_MANUAL_G_FSCA_010.</summary>
    public string Tipo_Respaldo { get; set; } = string.Empty;
    /// <summary>Solo la guía de remisión lleva número.</summary>
    public string? Numero_Documento { get; set; }
    public List<long> IDs_Solicitud_Persona { get; set; } = new();
    public string? Observacion { get; set; }
}

/// <summary>Filtros de la bitácora de portería. Fechas nulas = hoy.</summary>
public sealed class Dto_Filtro_Movimientos
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
    /// <summary>INGRESO, SALIDA o nulo (ambos).</summary>
    public string? Tipo { get; set; }
    public string? Texto { get; set; }
}

/// <summary>Filtros del listado de desviaciones.</summary>
public sealed class Dto_Filtro_Desviaciones
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    /// <summary>POR_REVISAR, REVISADA o nulo (todas).</summary>
    public string? Estado { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
    public string? Texto { get; set; }
}
"""
escribir("Application.DTOs", "Dto_Porteria_Entradas.cs", ENTRADAS)

# ══ Helpers (iguales al Hito 2) ═══════════════════════════════
def mapper(nombre, fn):
    L = [f"    private static {LECTURAS[fn][0]} {nombre}(DbDataReader rd) => new()\n    {{\n"]
    w = max(len(c) for c, _ in COLS[fn])
    for c, t in COLS[fn]:
        ct, nul, rd = tipo_cs(c, t, fn)
        L.append(f"        {c.ljust(w)} = {rd}(rd, \"{c}\"),\n")
    L.append("    };\n")
    return "".join(L)

def lectura(metodo, fn, firma_cs, binds, devuelve_lista=True, usa_f=False):
    dto = LECTURAS[fn][0]
    cuerpo_binds = "".join(f"                    {b}\n" for b in binds)
    if devuelve_lista:
        return f'''    public async Task<Result<List<{dto}>>> {metodo}({firma_cs}CancellationToken ct = default)
    {{
        try
        {{
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "{fn}",
                bind: p =>
                {{
{cuerpo_binds}                }},
                map: Map{dto.replace("Dto_", "")},
                ct: ct);
            return Result<List<{dto}>>.Ok(lista);
        }}
        catch (Exception ex)
        {{
            return Result<List<{dto}>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }}
    }}

'''
    return f'''    public async Task<Result<{dto}?>> {metodo}({firma_cs}CancellationToken ct = default)
    {{
        try
        {{
            var dato = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "{fn}",
                bind: p =>
                {{
{cuerpo_binds}                }},
                map: Map{dto.replace("Dto_", "")},
                ct: ct);
            return Result<{dto}?>.Ok(dato);
        }}
        catch (Exception ex)
        {{
            return Result<{dto}?>.Fail(ex.InnerException?.Message ?? ex.Message);
        }}
    }}

'''

def escritura_simple(metodo, proc, firma_cs, binds):
    b = "".join(f"                {x}\n" for x in binds)
    return f'''    public async Task<ResultSp> {metodo}({firma_cs}CancellationToken ct = default)
    {{
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "{proc}",
            bind: p =>
            {{
{b}            }},
            ct: ct);
    }}

'''

def escritura_con_id(metodo, proc, col, firma_cs, binds):
    b = "".join(f"                {x}\n" for x in binds)
    return f'''    public async Task<ResultSp<long>> {metodo}({firma_cs}CancellationToken ct = default)
    {{
        return await _exec.EjecutarEscrituraConIdAsync(
            clave: Conn,
            procedimiento: "{proc}",
            columnaId: "{col}",
            bind: p =>
            {{
{b}            }},
            ct: ct);
    }}

'''

def escritura_con_salidas(metodo, proc, columnas_salida, tipo_ret, conversion, firma_cs, binds):
    b = "".join(f"                {x}\n" for x in binds)
    cols = ", ".join(f'"{c}"' for c in columnas_salida)
    return f'''    public async Task<ResultSp<{tipo_ret}>> {metodo}({firma_cs}CancellationToken ct = default)
    {{
        var r = await _exec.EjecutarEscrituraConSalidasAsync(
            clave: Conn,
            procedimiento: "{proc}",
            columnasSalida: new[] {{ {cols} }},
            bind: p =>
            {{
{b}            }},
            ct: ct);
        if (!r.Ok || r.Data is null) return ResultSp<{tipo_ret}>.Fail(r.Codigo, r.Mensaje);
{conversion}
    }}

'''

USING_REPO = "using System.Data.Common;\nusing System.Linq;\nusing Application.DTOs.ControlAccesos;\nusing Infrastructure.Contracts.ControlAccesos;\nusing Infrastructure.Persistence;\nusing Shared.Results;\n\nnamespace Infrastructure.Repositories.ControlAccesos;\n\n"

def repo(clase, interfaz, nota_sp, cuerpo, mappers):
    return (cabecera(clase + ".cs", "Infrastructure.Repositories", "4 — Repository", clase.replace("Repo_", ""),
            f"// SP base  : {nota_sp}\n// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)\n"
            "// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).\n") + USING_REPO +
            f"public sealed class {clase} : RepoHelpers, {interfaz}\n{{\n    private readonly EjecutorSp _exec;\n"
            "    private const string Conn = ConexionesCaf.Modulo;\n\n"
            f"    public {clase}(EjecutorSp exec) => _exec = exec;\n\n" + cuerpo +
            "    // ══════════════════════════════════════════════════════════════\n    // MAPPERS (columnas = las que devuelve cada rutina)\n"
            "    // ══════════════════════════════════════════════════════════════\n\n" + mappers + "}\n")

CSV = 'string.Join(",", {0})'

def iface(carpeta, proyecto_ns, nombre, fase, entidad, metodos, usings):
    txt = cabecera(nombre + ".cs", carpeta, fase, entidad) + usings + f"\nnamespace {proyecto_ns}.ControlAccesos;\n\npublic interface {nombre}\n{{\n"
    txt += "".join(f"    {m}\n" for m in metodos) + "}\n"
    escribir(carpeta, nombre + ".cs", txt)

U_REPO = "using Application.DTOs.ControlAccesos;\nusing Shared.Results;\n"
R = "CancellationToken ct = default"

USING_SRV = ("using Application.Contracts.ControlAccesos;\nusing Application.DTOs.ControlAccesos;\n"
             "using Infrastructure.Contracts.ControlAccesos;\nusing Microsoft.Extensions.Logging;\nusing Shared.Results;\n\n"
             "namespace Application.Services.ControlAccesos;\n\n")

def servicio(clase, repo_if, srv_if, entidad, cuerpo, nota=""):
    return (cabecera(clase + ".cs", "Application.Services", "5 — Service", entidad,
            "// Validación mínima de formulario. Las reglas de negocio viven en la rutina (códigos 101/400/404/409):\n"
            "// el servicio NO las duplica, solo traduce su respuesta (D-40).\n" + nota) + USING_SRV +
            f"public sealed class {clase} : {srv_if}\n{{\n    private readonly {repo_if} _repo;\n"
            f"    private readonly ILogger<{clase}> _logger;\n\n"
            f"    public {clase}({repo_if} repo, ILogger<{clase}> logger)\n    {{\n        _repo = repo;\n        _logger = logger;\n    }}\n\n" + cuerpo + "}\n")

def logmsg(et):
    """etiqueta 'TEXTO", arg' → \"TEXTO ERROR\", arg ; sin arg → \"TEXTO ERROR\"."""
    if '", ' in et:
        t, a = et.split('", ', 1)
        return '"' + t + ' ERROR", ' + a
    return '"' + et + ' ERROR"'

def srv_lista(metodo, dto, firma, llamada, etiqueta):
    return f'''    public async Task<Result<List<{dto}>>> {metodo}({firma}{R})
    {{
        try {{ return await _repo.{metodo}({llamada}ct).ConfigureAwait(false); }}
        catch (Exception ex)
        {{
            _logger.LogError(ex, {logmsg(etiqueta)});
            return Result<List<{dto}>>.Fail(ex.Message);
        }}
    }}

'''

def srv_una(metodo, dto, firma, llamada, etiqueta, mensaje_no):
    return f'''    public async Task<Result<{dto}>> {metodo}({firma}{R})
    {{
        try
        {{
            var r = await _repo.{metodo}({llamada}ct).ConfigureAwait(false);
            if (!r.Success) return Result<{dto}>.Fail(r.Message, r.Code);
            if (r.Data is null)
                return Result<{dto}>.Fail("{mensaje_no}", ResultCodes.NotFound);
            return Result<{dto}>.Ok(r.Data);
        }}
        catch (Exception ex)
        {{
            _logger.LogError(ex, {logmsg(etiqueta)});
            return Result<{dto}>.Fail(ex.Message);
        }}
    }}

'''

def srv_escritura(metodo, firma, llamada, etiqueta, validacion="", ok_data=None, tipo=None):
    v = validacion
    if tipo is None:
        return f'''    public async Task<Result> {metodo}({firma}{R})
    {{
{v}        try
        {{
            var sp = await _repo.{metodo}({llamada}ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }}
        catch (Exception ex)
        {{
            _logger.LogError(ex, {logmsg(etiqueta)});
            return Result.Fail(ex.Message);
        }}
    }}

'''
    return f'''    public async Task<Result<{tipo}>> {metodo}({firma}{R})
    {{
{v}        try
        {{
            var sp = await _repo.{metodo}({llamada}ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<{tipo}>.Ok(sp.Data!, sp.Mensaje)
                : Result<{tipo}>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }}
        catch (Exception ex)
        {{
            _logger.LogError(ex, {logmsg(etiqueta)});
            return Result<{tipo}>.Fail(ex.Message);
        }}
    }}

'''

def valida_ids(*pares):
    s = "        var errors = new List<ResultError>();\n"
    for campo, expr, msg in pares:
        s += f'        if ({expr})\n            errors.Add(new ResultError("{campo}", "{msg}"));\n'
    s += '        if (errors.Count > 0)\n            return {RET}.Validation("Datos inválidos.", errors);\n\n'
    return s

# ══ Repositorios ═══════════════════════════════════════════════
ITEMS_TXT = '''    /// <summary>Respuestas del checklist como texto «id:Y,id:N» (formato de las rutinas).</summary>
    private static string ItemsTexto(IEnumerable<Dto_Porteria_Respuesta>? items)
        => items is null ? string.Empty
           : string.Join(",", items.Select(i => i.ID_Catalogo_Item_Checklist + ":" + (i.Cumple ? "Y" : "N")));

'''
def mp(fns):
    return "\n".join(mapper("Map" + LECTURAS[f][0].replace("Dto_", ""), f) for f in fns)

def desv_binds(dto):
    return [f'AddStr(p, "HV_Desv_Descripcion", {dto}.Desviacion?.Descripcion);',
            f'AddLong(p, "HV_ID_Coordinador", {dto}.Desviacion?.ID_Coordinador);',
            f'AddLong(p, "HV_ID_Tratamiento", {dto}.Desviacion?.ID_Tratamiento);',
            f'AddStr(p, "HV_Tratamiento_Detalle", {dto}.Desviacion?.Tratamiento_Detalle);',
            f'AddStr(p, "HV_Resultado_Elegido", {dto}.Desviacion?.Resultado_Elegido);']

CONV_REG = ('        return ResultSp<Dto_Porteria_Registrado>.Success(new Dto_Porteria_Registrado\n        {\n'
            '            ID_Registro_Acceso = Convert.ToInt64(r.Data["HV_ID_Registro_Acceso_Result"] ?? 0L),\n'
            '            ID_Desviacion = Convert.ToInt64(r.Data["HV_ID_Desviacion_Result"] ?? 0L) is var d && d > 0 ? d : null,\n'
            '            Resultado = Convert.ToString(r.Data["HV_Resultado_Result"]) ?? string.Empty,\n'
            '        }, r.Mensaje);')
SAL_REG = ["HV_ID_Registro_Acceso_Result", "HV_ID_Desviacion_Result", "HV_Resultado_Result"]

# --- Repo_Porteria
b = lectura("ChecklistObtenerAsync", "ERP_CAF_PORTERIA_CHECKLIST_OBTENER", "long usuarioId, long solicitudPersonaId, string etapa, bool traeEquipos = false, bool traeHerramientas = false, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Solicitud_Persona", solicitudPersonaId);', 'AddStrReq(p, "HV_Etapa", etapa);',
     'AddChar1(p, "HV_Trae_Equipos", traeEquipos ? "Y" : "N");', 'AddChar1(p, "HV_Trae_Herramientas", traeHerramientas ? "Y" : "N");'])
b += lectura("FichaAsync", "ERP_CAF_PORTERIA_FICHA", "long usuarioId, long solicitudPersonaId, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Solicitud_Persona", solicitudPersonaId);'], devuelve_lista=False)
b += lectura("MovimientosListarAsync", "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR", "long usuarioId, Dto_Filtro_Movimientos f, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);',
     'AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);', 'AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);',
     'AddStr(p, "HV_Tipo", f.Tipo);', 'AddStr(p, "HV_Texto", f.Texto);'])
b += lectura("RegistroDetalleAsync", "ERP_CAF_PORTERIA_REGISTRO_DETALLE", "long usuarioId, long registroId, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Registro_Acceso", registroId);'], devuelve_lista=False)
b += lectura("RegistroChecklistListarAsync", "ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR", "long usuarioId, long registroId, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Registro_Acceso", registroId);'])
b += escritura_con_salidas("IngresoRegistrarAsync", "ERP_CAF_PORTERIA_INGRESO_REGISTRAR", SAL_REG, "Dto_Porteria_Registrado", CONV_REG,
    "Dto_Porteria_Ingreso dto, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Solicitud_Persona", dto.ID_Solicitud_Persona);', 'AddStr(p, "HV_Items", ItemsTexto(dto.Items));',
     'AddChar1(p, "HV_Trae_Equipos", dto.Trae_Equipos ? "Y" : "N");', 'AddChar1(p, "HV_Trae_Herramientas", dto.Trae_Herramientas ? "Y" : "N");',
     'AddStr(p, "HV_Observacion", dto.Observacion);'] + desv_binds("dto") +
    ['AddTimestamp(p, "HV_Fecha_Hora_Hecho", dto.Fecha_Hora_Hecho);', 'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
b += escritura_con_salidas("SalidaRegistrarAsync", "ERP_CAF_PORTERIA_SALIDA_REGISTRAR", SAL_REG, "Dto_Porteria_Registrado", CONV_REG,
    "Dto_Porteria_Salida dto, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Solicitud_Persona", dto.ID_Solicitud_Persona);', 'AddStr(p, "HV_Items", ItemsTexto(dto.Items));',
     'AddStr(p, "HV_Observacion", dto.Observacion);'] + desv_binds("dto") +
    ['AddTimestamp(p, "HV_Fecha_Hora_Hecho", dto.Fecha_Hora_Hecho);', 'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
b += escritura_con_salidas("NoSePresentoMarcarAsync", "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR", ["HV_Cantidad_Result"], "long",
    '        return ResultSp<long>.Success(Convert.ToInt64(r.Data["HV_Cantidad_Result"] ?? 0L), r.Mensaje);',
    "DateTime? fechaCorte, long usuarioId, ",
    ['AddDate(p, "HV_Fecha_Corte", fechaCorte);', 'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
b += ITEMS_TXT
escribir("Infrastructure.Repositories", "Repo_Porteria.cs", repo("Repo_Porteria", "IRepo_Porteria",
    "ERP_CAF_PORTERIA_<ACCION> (checklist, ficha, bitácora, ingreso, salida, no se presentó)", b,
    mp(["ERP_CAF_PORTERIA_CHECKLIST_OBTENER", "ERP_CAF_PORTERIA_FICHA", "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR",
        "ERP_CAF_PORTERIA_REGISTRO_DETALLE", "ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR"])))

# --- Repo_Respaldo
b = lectura("ListarPorPersonaAsync", "ERP_CAF_RESPALDO_LISTAR_POR_PERSONA", "long usuarioId, long solicitudPersonaId, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Solicitud_Persona", solicitudPersonaId);'])
b += escritura_con_id("RegistrarAsync", "ERP_CAF_RESPALDO_REGISTRAR", "HV_ID_Respaldo_Result", "Dto_Respaldo_Registrar dto, long usuarioId, ",
    ['AddStrReq(p, "HV_Categoria", dto.Categoria);', 'AddStrReq(p, "HV_Tipo_Respaldo", dto.Tipo_Respaldo);',
     'AddStr(p, "HV_Numero_Documento", dto.Numero_Documento);',
     'AddStr(p, "HV_IDs_Solicitud_Persona", dto.IDs_Solicitud_Persona is null ? string.Empty : string.Join(",", dto.IDs_Solicitud_Persona));',
     'AddStr(p, "HV_Observacion", dto.Observacion);', 'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
escribir("Infrastructure.Repositories", "Repo_Respaldo.cs", repo("Repo_Respaldo", "IRepo_Respaldo", "ERP_CAF_RESPALDO_<ACCION>", b,
    mp(["ERP_CAF_RESPALDO_LISTAR_POR_PERSONA"])))

# --- Repo_Desviacion
b = lectura("ListarAsync", "ERP_CAF_DESVIACION_LISTAR", "long usuarioId, Dto_Filtro_Desviaciones f, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);', 'AddStr(p, "HV_Estado", f.Estado);',
     'AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);', 'AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);', 'AddStr(p, "HV_Texto", f.Texto);'])
b += lectura("DetalleAsync", "ERP_CAF_DESVIACION_DETALLE", "long usuarioId, long desviacionId, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Desviacion", desviacionId);'], devuelve_lista=False)
b += lectura("ContadoresAsync", "ERP_CAF_DESVIACION_CONTADORES", "long usuarioId, long sedeId, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);'], devuelve_lista=False)
b += lectura("CoordinadoresDropdownAsync", "ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN", "long usuarioId, long sedeId, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);'])
b += lectura("TratamientosDropdownAsync", "ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN", "string etapa, ",
    ['AddStrReq(p, "HV_Etapa", etapa);'])
b += escritura_simple("ConformidadDarAsync", "ERP_CAF_DESVIACION_CONFORMIDAD_DAR", "long desviacionId, string? comentario, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Desviacion", desviacionId);', 'AddStr(p, "HV_Comentario", comentario);', 'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
escribir("Infrastructure.Repositories", "Repo_Desviacion.cs", repo("Repo_Desviacion", "IRepo_Desviacion", "ERP_CAF_DESVIACION_<ACCION>", b,
    mp(["ERP_CAF_DESVIACION_LISTAR", "ERP_CAF_DESVIACION_DETALLE", "ERP_CAF_DESVIACION_CONTADORES",
        "ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN", "ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN"])))

# ══ Interfaces ═════════════════════════════════════════════════
REPO_POR = [
 f"Task<Result<List<Dto_Porteria_Item>>> ChecklistObtenerAsync(long usuarioId, long solicitudPersonaId, string etapa, bool traeEquipos = false, bool traeHerramientas = false, {R});",
 f"Task<Result<Dto_Porteria_Ficha?>> FichaAsync(long usuarioId, long solicitudPersonaId, {R});",
 f"Task<Result<List<Dto_Porteria_Movimiento>>> MovimientosListarAsync(long usuarioId, Dto_Filtro_Movimientos f, {R});",
 f"Task<Result<Dto_Porteria_Registro?>> RegistroDetalleAsync(long usuarioId, long registroId, {R});",
 f"Task<Result<List<Dto_Porteria_Registro_Item>>> RegistroChecklistListarAsync(long usuarioId, long registroId, {R});",
 f"Task<ResultSp<Dto_Porteria_Registrado>> IngresoRegistrarAsync(Dto_Porteria_Ingreso dto, long usuarioId, {R});",
 f"Task<ResultSp<Dto_Porteria_Registrado>> SalidaRegistrarAsync(Dto_Porteria_Salida dto, long usuarioId, {R});",
 f"Task<ResultSp<long>> NoSePresentoMarcarAsync(DateTime? fechaCorte, long usuarioId, {R});",
]
REPO_RES = [
 f"Task<Result<List<Dto_Respaldo>>> ListarPorPersonaAsync(long usuarioId, long solicitudPersonaId, {R});",
 f"Task<ResultSp<long>> RegistrarAsync(Dto_Respaldo_Registrar dto, long usuarioId, {R});",
]
REPO_DES = [
 f"Task<Result<List<Dto_Desviacion_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Desviaciones f, {R});",
 f"Task<Result<Dto_Desviacion_Detalle?>> DetalleAsync(long usuarioId, long desviacionId, {R});",
 f"Task<Result<Dto_Desviacion_Contadores?>> ContadoresAsync(long usuarioId, long sedeId, {R});",
 f"Task<Result<List<Dto_Desviacion_Coordinador>>> CoordinadoresDropdownAsync(long usuarioId, long sedeId, {R});",
 f"Task<Result<List<Dto_Desviacion_Tratamiento>>> TratamientosDropdownAsync(string etapa, {R});",
 f"Task<ResultSp> ConformidadDarAsync(long desviacionId, string? comentario, long usuarioId, {R});",
]
iface("Infrastructure.Contracts", "Infrastructure.Contracts", "IRepo_Porteria", "3 — Contracts", "Porteria", REPO_POR, U_REPO)
iface("Infrastructure.Contracts", "Infrastructure.Contracts", "IRepo_Respaldo", "3 — Contracts", "Respaldo", REPO_RES, U_REPO)
iface("Infrastructure.Contracts", "Infrastructure.Contracts", "IRepo_Desviacion", "3 — Contracts", "Desviacion", REPO_DES, U_REPO)

def a_servicio(lst):
    out = []
    for m in lst:
        m = m.replace("Result<Dto_Porteria_Ficha?>", "Result<Dto_Porteria_Ficha>").replace("Result<Dto_Porteria_Registro?>", "Result<Dto_Porteria_Registro>")
        m = m.replace("Result<Dto_Desviacion_Detalle?>", "Result<Dto_Desviacion_Detalle>").replace("Result<Dto_Desviacion_Contadores?>", "Result<Dto_Desviacion_Contadores>")
        m = m.replace("Task<ResultSp<", "Task<Result<").replace("Task<ResultSp>", "Task<Result>")
        out.append(m)
    return out
iface("Application.Contracts", "Application.Contracts", "ISrv_Porteria", "3 — Contracts", "Porteria", a_servicio(REPO_POR), U_REPO)
iface("Application.Contracts", "Application.Contracts", "ISrv_Respaldo", "3 — Contracts", "Respaldo", a_servicio(REPO_RES), U_REPO)
iface("Application.Contracts", "Application.Contracts", "ISrv_Desviacion", "3 — Contracts", "Desviacion", a_servicio(REPO_DES), U_REPO)

# ══ Servicios ══════════════════════════════════════════════════
def val_mov(dto_t):
    return (f"""        var errors = new List<ResultError>();
        if (dto is null)
            return Result<Dto_Porteria_Registrado>.Validation("Datos inválidos.", new List<ResultError> {{ new ResultError("dto", "Faltan los datos del movimiento.") }});
        if (dto.ID_Solicitud_Persona <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Solicitud_Persona), "Falta la persona."));
        if (dto.Items is null || dto.Items.Count == 0)
            errors.Add(new ResultError(nameof(dto.Items), "Responda el checklist."));
        if (errors.Count > 0)
            return Result<Dto_Porteria_Registrado>.Validation("Datos inválidos.", errors);

""")
c = srv_lista("ChecklistObtenerAsync", "Dto_Porteria_Item", "long usuarioId, long solicitudPersonaId, string etapa, bool traeEquipos = false, bool traeHerramientas = false, ",
              "usuarioId, solicitudPersonaId, etapa, traeEquipos, traeHerramientas, ", "CHECKLIST Porteria ID={ID}\", solicitudPersonaId")
c += srv_una("FichaAsync", "Dto_Porteria_Ficha", "long usuarioId, long solicitudPersonaId, ", "usuarioId, solicitudPersonaId, ", "FICHA Porteria ID={ID}\", solicitudPersonaId", "La persona no existe o no tiene permiso para verla.")
c += srv_lista("MovimientosListarAsync", "Dto_Porteria_Movimiento", "long usuarioId, Dto_Filtro_Movimientos f, ", "usuarioId, f, ", "MOVIMIENTOS Porteria")
c += srv_una("RegistroDetalleAsync", "Dto_Porteria_Registro", "long usuarioId, long registroId, ", "usuarioId, registroId, ", "REGISTRO_DETALLE Porteria ID={ID}\", registroId", "El movimiento no existe o no tiene permiso para verlo.")
c += srv_lista("RegistroChecklistListarAsync", "Dto_Porteria_Registro_Item", "long usuarioId, long registroId, ", "usuarioId, registroId, ", "REGISTRO_CHECKLIST Porteria ID={ID}\", registroId")
c += srv_escritura("IngresoRegistrarAsync", "Dto_Porteria_Ingreso dto, long usuarioId, ", "dto, usuarioId, ", "INGRESO Porteria UsuarioID={UsuarioID}\", usuarioId", val_mov("ingreso"), tipo="Dto_Porteria_Registrado")
c += srv_escritura("SalidaRegistrarAsync", "Dto_Porteria_Salida dto, long usuarioId, ", "dto, usuarioId, ", "SALIDA Porteria UsuarioID={UsuarioID}\", usuarioId", val_mov("salida"), tipo="Dto_Porteria_Registrado")
c += srv_escritura("NoSePresentoMarcarAsync", "DateTime? fechaCorte, long usuarioId, ", "fechaCorte, usuarioId, ", "NO_SE_PRESENTO Porteria", tipo="long")
escribir("Application.Services", "Srv_Porteria.cs", servicio("Srv_Porteria", "IRepo_Porteria", "ISrv_Porteria", "Porteria", c,
    "// Solo exige que lleguen la persona y las respuestas. Qué se puede registrar y cuándo lo decide la rutina (D-63).\n"))

c = srv_lista("ListarPorPersonaAsync", "Dto_Respaldo", "long usuarioId, long solicitudPersonaId, ", "usuarioId, solicitudPersonaId, ", "LISTAR Respaldo ID={ID}\", solicitudPersonaId")
val_resp = """        var errors = new List<ResultError>();
        if (dto is null)
            return Result<long>.Validation("Datos inválidos.", new List<ResultError> { new ResultError("dto", "Faltan los datos del respaldo.") });
        if (string.IsNullOrWhiteSpace(dto.Categoria))
            errors.Add(new ResultError(nameof(dto.Categoria), "Elija la categoría."));
        if (string.IsNullOrWhiteSpace(dto.Tipo_Respaldo))
            errors.Add(new ResultError(nameof(dto.Tipo_Respaldo), "Elija el tipo de respaldo."));
        if (dto.IDs_Solicitud_Persona is null || dto.IDs_Solicitud_Persona.Count == 0)
            errors.Add(new ResultError(nameof(dto.IDs_Solicitud_Persona), "Elija al menos una persona."));
        if (errors.Count > 0)
            return Result<long>.Validation("Datos inválidos.", errors);

"""
c += srv_escritura("RegistrarAsync", "Dto_Respaldo_Registrar dto, long usuarioId, ", "dto, usuarioId, ", "REGISTRAR Respaldo UsuarioID={UsuarioID}\", usuarioId", val_resp, tipo="long")
escribir("Application.Services", "Srv_Respaldo.cs", servicio("Srv_Respaldo", "IRepo_Respaldo", "ISrv_Respaldo", "Respaldo", c))

c = srv_lista("ListarAsync", "Dto_Desviacion_Lista", "long usuarioId, Dto_Filtro_Desviaciones f, ", "usuarioId, f, ", "LISTAR Desviacion")
c += srv_una("DetalleAsync", "Dto_Desviacion_Detalle", "long usuarioId, long desviacionId, ", "usuarioId, desviacionId, ", "DETALLE Desviacion ID={ID}\", desviacionId", "La desviación no existe o no tiene permiso para verla.")
c += srv_una("ContadoresAsync", "Dto_Desviacion_Contadores", "long usuarioId, long sedeId, ", "usuarioId, sedeId, ", "CONTADORES Desviacion", "No se pudieron obtener los contadores.")
c += srv_lista("CoordinadoresDropdownAsync", "Dto_Desviacion_Coordinador", "long usuarioId, long sedeId, ", "usuarioId, sedeId, ", "COORDINADORES Desviacion")
c += srv_lista("TratamientosDropdownAsync", "Dto_Desviacion_Tratamiento", "string etapa, ", "etapa, ", "TRATAMIENTOS Desviacion")
val_conf = """        if (desviacionId <= 0)
            return Result.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(desviacionId), "Falta la desviación.") });

"""
c += srv_escritura("ConformidadDarAsync", "long desviacionId, string? comentario, long usuarioId, ", "desviacionId, comentario, usuarioId, ", "CONFORMIDAD Desviacion ID={ID}\", desviacionId", val_conf)
escribir("Application.Services", "Srv_Desviacion.cs", servicio("Srv_Desviacion", "IRepo_Desviacion", "ISrv_Desviacion", "Desviacion", c,
    "// Quién puede dar conformidad y si la desviación sigue por revisar lo decide la rutina (D-69).\n"))
print("generado en", destino)
