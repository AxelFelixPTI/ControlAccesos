# -*- coding: utf-8 -*-
# gen_capas_incidencias.py  V1.0 2026-10-18
# Genera las capas .NET del Hito 4 (incidencias, correos y reporte) desde las FIRMAS REALES de las rutinas:
#   python3 gen_capas_incidencias.py firmas_rutinas_hito4.txt <carpeta src>
# Los DTO de RESPUESTA salen de las columnas que devuelve cada función. Los de ENTRADA están en este archivo.
# verificar_llamadas.py comprueba nombres, orden y tipos de cada llamada contra la base.
import re, sys, os

firmas_file, destino = sys.argv[1], sys.argv[2]
FECHA = "V1.0 — 2026-10-18"

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

ID_NO_NULOS = {"ID_Solicitud", "ID_Catalogo_Sede", "ID_Solicitud_Persona", "ID_Registro_Acceso", "ID_Incidencia", "ID_Correo_Pendiente",
               "ID_Catalogo_Tipo_Incidencia"}
NULABLE_EN = {("ERP_CAF_CORREO_LISTAR", "ID_Solicitud"), ("ERP_CAF_CORREO_PENDIENTES_LISTAR", "ID_Solicitud")}
TEXTO_NO_NULO = {"Codigo", "Codigo_Solicitud", "Estado", "Persona_Nombre", "Tipo_Movimiento", "Resultado", "Descripcion", "Tipo_Descripcion",
                 "Tipo_Codigo", "Origen", "Tipo", "Destinatarios", "Asunto", "Cuerpo", "Estado_Persona"}
FECHA_NO_NULA = {"Fecha_Hora_Prevista", "Fecha_Hora", "Fecha_Hora_Hecho", "Fecha", "CreateDate"}

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
        return ("DateTime", False, "RdDt") if col in FECHA_NO_NULA else ("DateTime?", True, "RdDtN")
    if col in TEXTO_NO_NULO:
        return "string", False, "RdStr"
    return "string?", True, "RdStrN"

def cabecera(archivo, ruta, fase, entidad, nota=""):
    return (f"// ============================================================\n"
            f"// Archivo  : {archivo}\n// Ruta     : {ruta}/\n// Módulo   : ControlAccesos\n"
            f"// Hito     : 4 — Incidencias, correos y reporte\n// Fase     : {fase}\n// Entidad  : {entidad}\n"
            f"// Versión  : {FECHA}\n// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)\n"
            f"// ============================================================\n{nota}\n")

def escribir(carpeta, nombre, texto):
    d = os.path.join(destino, carpeta, "ControlAccesos")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, nombre), "w", encoding="utf-8", newline="\n") as f:
        f.write(texto)

LECTURAS = {
    "ERP_CAF_INCIDENCIA_LISTAR":            ("Dto_Incidencia_Lista",         "fila del listado de incidencias"),
    "ERP_CAF_INCIDENCIA_DETALLE":           ("Dto_Incidencia_Detalle",       "incidencia completa, con el botón de decidir"),
    "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR":   ("Dto_Incidencia_Persona",       "persona involucrada en una incidencia"),
    "ERP_CAF_INCIDENCIA_CONTADORES":        ("Dto_Incidencia_Contadores",    "números de las pestañas de incidencias"),
    "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR":   ("Dto_Incidencia_Persona_Busqueda", "persona que se puede involucrar en una incidencia"),
    "ERP_CAF_CORREO_PENDIENTES_LISTAR":     ("Dto_Correo_Pendiente",         "correo por enviar (solo lo lee el proceso de envío)"),
    "ERP_CAF_CORREO_LISTAR":                ("Dto_Correo_Lista",             "fila de la bandeja de correos (sin cuerpo)"),
    "ERP_CAF_REPORTE_ACCESOS":              ("Dto_Reporte_Acceso",           "fila del reporte de accesos (un movimiento)"),
    "ERP_CAF_REPORTE_RESUMEN_DIARIO":       ("Dto_Reporte_Resumen_Dia",      "totales de un día"),
    "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA": ("Dto_Reporte_Autorizado",       "persona autorizada a una zona en una fecha"),
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

ENTRADAS_INC = cabecera("Dto_Incidencia_Entradas.cs", "Application.DTOs", "2 — DTOs", "Incidencia — formularios y filtros",
"// Lo que la pantalla ENVÍA. Las reglas de negocio viven en la rutina (D-40).\n") + """using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

/// <summary>Registrar una incidencia (ERP_CAF_INCIDENCIA_REGISTRAR). El origen lo fija la rutina según el permiso (D-75).</summary>
public sealed class Dto_Incidencia_Registrar
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    [Range(1, long.MaxValue, ErrorMessage = "Elija el tipo de incidencia.")]
    public long ID_Catalogo_Tipo_Incidencia { get; set; }
    /// <summary>Obligatorio con el tipo «Otro».</summary>
    public string? Tipo_Detalle { get; set; }
    public DateTime Fecha_Hora_Hecho { get; set; }
    /// <summary>Zona del catálogo o, si no hay, un lugar escrito (al menos uno).</summary>
    public long? ID_Catalogo_Zona_Acceso { get; set; }
    public string? Lugar_Detalle { get; set; }
    public string Descripcion { get; set; } = string.Empty;
    /// <summary>Personas involucradas (opcional).</summary>
    public List<long> IDs_Solicitud_Persona { get; set; } = new();
}

/// <summary>Resultado de registrar una incidencia.</summary>
public sealed class Dto_Incidencia_Registrada
{
    public long ID_Incidencia { get; set; }
    /// <summary>INC-00001.</summary>
    public string Codigo { get; set; } = string.Empty;
}

/// <summary>Decisión del Coordinador (ERP_CAF_INCIDENCIA_DECIDIR).</summary>
public sealed class Dto_Incidencia_Decision
{
    [Range(1, long.MaxValue, ErrorMessage = "Falta la incidencia.")]
    public long ID_Incidencia { get; set; }
    /// <summary>CONFIRMAR o DESESTIMAR.</summary>
    public string Decision { get; set; } = string.Empty;
    public string Sustento { get; set; } = string.Empty;
}

/// <summary>Filtros del listado de incidencias.</summary>
public sealed class Dto_Filtro_Incidencias
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    /// <summary>REGISTRADA, CONFIRMADA, DESESTIMADA o nulo (todas).</summary>
    public string? Estado { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
    public string? Texto { get; set; }
}

/// <summary>Búsqueda de personas para involucrar en una incidencia. Fechas nulas = ayer y hoy.</summary>
public sealed class Dto_Filtro_Incidencia_Personas
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
    public string? Texto { get; set; }
}
"""
escribir("Application.DTOs", "Dto_Incidencia_Entradas.cs", ENTRADAS_INC)

ENTRADAS_COR = cabecera("Dto_Correo_Entradas.cs", "Application.DTOs", "2 — DTOs", "Correo — filtros",
"// Filtros de la bandeja de correos (Administrador).\n") + """using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

/// <summary>Filtros de la bandeja de correos.</summary>
public sealed class Dto_Filtro_Correos
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    /// <summary>PENDIENTE, ENVIADO, ERROR o nulo (todos).</summary>
    public string? Estado { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
}
"""
escribir("Application.DTOs", "Dto_Correo_Entradas.cs", ENTRADAS_COR)

ENTRADAS_REP = cabecera("Dto_Reporte_Entradas.cs", "Application.DTOs", "2 — DTOs", "Reporte — filtros",
"// Todos los reportes exigen rango de fechas (máximo 92 días, D-83).\n") + """using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

/// <summary>Filtros del reporte de accesos.</summary>
public sealed class Dto_Filtro_Reporte_Accesos
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    public DateTime Fecha_Desde { get; set; }
    public DateTime Fecha_Hasta { get; set; }
    /// <summary>INGRESO, SALIDA o nulo (ambos).</summary>
    public string? Tipo { get; set; }
    /// <summary>INGRESA, INGRESA_RESTRINGIDO, NO_INGRESA, SALE, SALE_RETIENE_ELEMENTO o nulo.</summary>
    public string? Resultado { get; set; }
    public string? Texto { get; set; }
}

/// <summary>Rango de fechas del resumen diario.</summary>
public sealed class Dto_Filtro_Reporte_Rango
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    public DateTime Fecha_Desde { get; set; }
    public DateTime Fecha_Hasta { get; set; }
}

/// <summary>Autorizados a una zona en una fecha.</summary>
public sealed class Dto_Filtro_Reporte_Zona
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    [Range(1, long.MaxValue, ErrorMessage = "Elija la zona.")]
    public long ID_Catalogo_Zona_Acceso { get; set; }
    public DateTime Fecha { get; set; }
}
"""
escribir("Application.DTOs", "Dto_Reporte_Entradas.cs", ENTRADAS_REP)

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


def mp(fns):
    return "\n".join(mapper("Map" + LECTURAS[f][0].replace("Dto_", ""), f) for f in fns)

UID = 'AddLongReq(p, "HV_UsuarioID", usuarioId);'
def idlist(expr): return f'AddStr(p, "HV_IDs_Solicitud_Persona", {expr} is null ? string.Empty : string.Join(",", {expr}));'

# --- Repo_Incidencia
b = lectura("ListarAsync", "ERP_CAF_INCIDENCIA_LISTAR", "long usuarioId, Dto_Filtro_Incidencias f, ",
    [UID, 'AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);', 'AddStr(p, "HV_Estado", f.Estado);',
     'AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);', 'AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);', 'AddStr(p, "HV_Texto", f.Texto);'])
b += lectura("DetalleAsync", "ERP_CAF_INCIDENCIA_DETALLE", "long usuarioId, long incidenciaId, ",
    [UID, 'AddLongReq(p, "HV_ID_Incidencia", incidenciaId);'], devuelve_lista=False)
b += lectura("PersonasListarAsync", "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR", "long usuarioId, long incidenciaId, ",
    [UID, 'AddLongReq(p, "HV_ID_Incidencia", incidenciaId);'])
b += lectura("ContadoresAsync", "ERP_CAF_INCIDENCIA_CONTADORES", "long usuarioId, long sedeId, ",
    [UID, 'AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);'], devuelve_lista=False)
b += lectura("PersonasBuscarAsync", "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR", "long usuarioId, Dto_Filtro_Incidencia_Personas f, ",
    [UID, 'AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);', 'AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);',
     'AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);', 'AddStr(p, "HV_Texto", f.Texto);'])
CONV_INC = ('        return ResultSp<Dto_Incidencia_Registrada>.Success(new Dto_Incidencia_Registrada\n        {\n'
            '            ID_Incidencia = Convert.ToInt64(r.Data["HV_ID_Incidencia_Result"] ?? 0L),\n'
            '            Codigo = Convert.ToString(r.Data["HV_Codigo_Result"]) ?? string.Empty,\n'
            '        }, r.Mensaje);')
b += escritura_con_salidas("RegistrarAsync", "ERP_CAF_INCIDENCIA_REGISTRAR", ["HV_ID_Incidencia_Result", "HV_Codigo_Result"],
    "Dto_Incidencia_Registrada", CONV_INC, "Dto_Incidencia_Registrar dto, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Catalogo_Sede", dto.ID_Catalogo_Sede);', 'AddLongReq(p, "HV_ID_Catalogo_Tipo_Incidencia", dto.ID_Catalogo_Tipo_Incidencia);',
     'AddStr(p, "HV_Tipo_Detalle", dto.Tipo_Detalle);', 'AddTimestamp(p, "HV_Fecha_Hora_Hecho", dto.Fecha_Hora_Hecho);',
     'AddLong(p, "HV_ID_Catalogo_Zona_Acceso", dto.ID_Catalogo_Zona_Acceso);', 'AddStr(p, "HV_Lugar_Detalle", dto.Lugar_Detalle);',
     'AddStr(p, "HV_Descripcion", dto.Descripcion);', idlist("dto.IDs_Solicitud_Persona"), UID])
b += escritura_simple("DecidirAsync", "ERP_CAF_INCIDENCIA_DECIDIR", "Dto_Incidencia_Decision dto, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Incidencia", dto.ID_Incidencia);', 'AddStr(p, "HV_Decision", dto.Decision);', 'AddStr(p, "HV_Sustento", dto.Sustento);', UID])
escribir("Infrastructure.Repositories", "Repo_Incidencia.cs", repo("Repo_Incidencia", "IRepo_Incidencia", "ERP_CAF_INCIDENCIA_<ACCION>", b,
    mp(["ERP_CAF_INCIDENCIA_LISTAR", "ERP_CAF_INCIDENCIA_DETALLE", "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR",
        "ERP_CAF_INCIDENCIA_CONTADORES", "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR"])))

# --- Repo_Correo
b = lectura("PendientesListarAsync", "ERP_CAF_CORREO_PENDIENTES_LISTAR", "long usuarioId, int? maximo = null, ",
    [UID, 'AddInt(p, "HV_Maximo", maximo);'])
b += lectura("ListarAsync", "ERP_CAF_CORREO_LISTAR", "long usuarioId, Dto_Filtro_Correos f, ",
    [UID, 'AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);', 'AddStr(p, "HV_Estado", f.Estado);',
     'AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);', 'AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);'])
b += escritura_simple("MarcarEnviadoAsync", "ERP_CAF_CORREO_MARCAR_ENVIADO", "long correoId, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Correo_Pendiente", correoId);', UID])
b += escritura_con_salidas("MarcarErrorAsync", "ERP_CAF_CORREO_MARCAR_ERROR", ["HV_Estado_Result"], "string",
    '        return ResultSp<string>.Success(Convert.ToString(r.Data["HV_Estado_Result"]) ?? string.Empty, r.Mensaje);',
    "long correoId, string? error, int maxIntentos, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Correo_Pendiente", correoId);', 'AddStr(p, "HV_Error", error);', 'AddInt(p, "HV_Max_Intentos", maxIntentos);', UID])
b += escritura_simple("ReencolarAsync", "ERP_CAF_CORREO_REENCOLAR", "long correoId, long sedeId, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Correo_Pendiente", correoId);', 'AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);', UID])
escribir("Infrastructure.Repositories", "Repo_Correo.cs", repo("Repo_Correo", "IRepo_Correo", "ERP_CAF_CORREO_<ACCION> (la cola se escribe con ERP_CAF_CORREO_ENCOLAR desde los SP de negocio)", b,
    mp(["ERP_CAF_CORREO_PENDIENTES_LISTAR", "ERP_CAF_CORREO_LISTAR"])))

# --- Repo_Reporte
b = lectura("AccesosAsync", "ERP_CAF_REPORTE_ACCESOS", "long usuarioId, Dto_Filtro_Reporte_Accesos f, ",
    [UID, 'AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);', 'AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);',
     'AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);', 'AddStr(p, "HV_Tipo", f.Tipo);', 'AddStr(p, "HV_Resultado", f.Resultado);', 'AddStr(p, "HV_Texto", f.Texto);'])
b += lectura("ResumenDiarioAsync", "ERP_CAF_REPORTE_RESUMEN_DIARIO", "long usuarioId, Dto_Filtro_Reporte_Rango f, ",
    [UID, 'AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);', 'AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);', 'AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);'])
b += lectura("AutorizadosPorZonaAsync", "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA", "long usuarioId, Dto_Filtro_Reporte_Zona f, ",
    [UID, 'AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);', 'AddLong(p, "HV_ID_Catalogo_Zona_Acceso", f.ID_Catalogo_Zona_Acceso);', 'AddDate(p, "HV_Fecha", f.Fecha);'])
escribir("Infrastructure.Repositories", "Repo_Reporte.cs", repo("Repo_Reporte", "IRepo_Reporte", "ERP_CAF_REPORTE_<ACCION>", b,
    mp(["ERP_CAF_REPORTE_ACCESOS", "ERP_CAF_REPORTE_RESUMEN_DIARIO", "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA"])))

# ══ Interfaces ═════════════════════════════════════════════════
REPO_INC = [
 f"Task<Result<List<Dto_Incidencia_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Incidencias f, {R});",
 f"Task<Result<Dto_Incidencia_Detalle?>> DetalleAsync(long usuarioId, long incidenciaId, {R});",
 f"Task<Result<List<Dto_Incidencia_Persona>>> PersonasListarAsync(long usuarioId, long incidenciaId, {R});",
 f"Task<Result<Dto_Incidencia_Contadores?>> ContadoresAsync(long usuarioId, long sedeId, {R});",
 f"Task<Result<List<Dto_Incidencia_Persona_Busqueda>>> PersonasBuscarAsync(long usuarioId, Dto_Filtro_Incidencia_Personas f, {R});",
 f"Task<ResultSp<Dto_Incidencia_Registrada>> RegistrarAsync(Dto_Incidencia_Registrar dto, long usuarioId, {R});",
 f"Task<ResultSp> DecidirAsync(Dto_Incidencia_Decision dto, long usuarioId, {R});",
]
REPO_COR = [
 f"Task<Result<List<Dto_Correo_Pendiente>>> PendientesListarAsync(long usuarioId, int? maximo = null, {R});",
 f"Task<Result<List<Dto_Correo_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Correos f, {R});",
 f"Task<ResultSp> MarcarEnviadoAsync(long correoId, long usuarioId, {R});",
 f"Task<ResultSp<string>> MarcarErrorAsync(long correoId, string? error, int maxIntentos, long usuarioId, {R});",
 f"Task<ResultSp> ReencolarAsync(long correoId, long sedeId, long usuarioId, {R});",
]
REPO_REP = [
 f"Task<Result<List<Dto_Reporte_Acceso>>> AccesosAsync(long usuarioId, Dto_Filtro_Reporte_Accesos f, {R});",
 f"Task<Result<List<Dto_Reporte_Resumen_Dia>>> ResumenDiarioAsync(long usuarioId, Dto_Filtro_Reporte_Rango f, {R});",
 f"Task<Result<List<Dto_Reporte_Autorizado>>> AutorizadosPorZonaAsync(long usuarioId, Dto_Filtro_Reporte_Zona f, {R});",
]
iface("Infrastructure.Contracts", "Infrastructure.Contracts", "IRepo_Incidencia", "3 — Contracts", "Incidencia", REPO_INC, U_REPO)
iface("Infrastructure.Contracts", "Infrastructure.Contracts", "IRepo_Correo", "3 — Contracts", "Correo", REPO_COR, U_REPO)
iface("Infrastructure.Contracts", "Infrastructure.Contracts", "IRepo_Reporte", "3 — Contracts", "Reporte", REPO_REP, U_REPO)

def a_servicio(lst):
    out = []
    for m in lst:
        m = m.replace("Result<Dto_Incidencia_Detalle?>", "Result<Dto_Incidencia_Detalle>").replace("Result<Dto_Incidencia_Contadores?>", "Result<Dto_Incidencia_Contadores>")
        m = m.replace("Task<ResultSp<", "Task<Result<").replace("Task<ResultSp>", "Task<Result>")
        out.append(m)
    return out
iface("Application.Contracts", "Application.Contracts", "ISrv_Incidencia", "3 — Contracts", "Incidencia", a_servicio(REPO_INC), U_REPO)
iface("Application.Contracts", "Application.Contracts", "ISrv_Correo", "3 — Contracts", "Correo", a_servicio(REPO_COR), U_REPO)
iface("Application.Contracts", "Application.Contracts", "ISrv_Reporte", "3 — Contracts", "Reporte", a_servicio(REPO_REP), U_REPO)

# ══ Servicios ══════════════════════════════════════════════════
val_reg = """        var errors = new List<ResultError>();
        if (dto is null)
            return Result<Dto_Incidencia_Registrada>.Validation("Datos inválidos.", new List<ResultError> { new ResultError("dto", "Faltan los datos de la incidencia.") });
        if (dto.ID_Catalogo_Tipo_Incidencia <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Tipo_Incidencia), "Elija el tipo de incidencia."));
        if (string.IsNullOrWhiteSpace(dto.Descripcion))
            errors.Add(new ResultError(nameof(dto.Descripcion), "Describa lo ocurrido."));
        if (dto.ID_Catalogo_Zona_Acceso is null && string.IsNullOrWhiteSpace(dto.Lugar_Detalle))
            errors.Add(new ResultError(nameof(dto.Lugar_Detalle), "Indique la zona o describa el lugar."));
        if (errors.Count > 0)
            return Result<Dto_Incidencia_Registrada>.Validation("Datos inválidos.", errors);

"""
val_dec = """        var errors = new List<ResultError>();
        if (dto is null)
            return Result.Validation("Datos inválidos.", new List<ResultError> { new ResultError("dto", "Faltan los datos de la decisión.") });
        if (dto.ID_Incidencia <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Incidencia), "Falta la incidencia."));
        if (string.IsNullOrWhiteSpace(dto.Decision))
            errors.Add(new ResultError(nameof(dto.Decision), "Elija confirmar o desestimar."));
        if (string.IsNullOrWhiteSpace(dto.Sustento))
            errors.Add(new ResultError(nameof(dto.Sustento), "Escriba el sustento de la decisión."));
        if (errors.Count > 0)
            return Result.Validation("Datos inválidos.", errors);

"""
c = srv_lista("ListarAsync", "Dto_Incidencia_Lista", "long usuarioId, Dto_Filtro_Incidencias f, ", "usuarioId, f, ", "LISTAR Incidencia")
c += srv_una("DetalleAsync", "Dto_Incidencia_Detalle", "long usuarioId, long incidenciaId, ", "usuarioId, incidenciaId, ", "DETALLE Incidencia ID={ID}\", incidenciaId", "La incidencia no existe o no tiene permiso para verla.")
c += srv_lista("PersonasListarAsync", "Dto_Incidencia_Persona", "long usuarioId, long incidenciaId, ", "usuarioId, incidenciaId, ", "PERSONAS Incidencia ID={ID}\", incidenciaId")
c += srv_una("ContadoresAsync", "Dto_Incidencia_Contadores", "long usuarioId, long sedeId, ", "usuarioId, sedeId, ", "CONTADORES Incidencia", "No se pudieron obtener los contadores.")
c += srv_lista("PersonasBuscarAsync", "Dto_Incidencia_Persona_Busqueda", "long usuarioId, Dto_Filtro_Incidencia_Personas f, ", "usuarioId, f, ", "PERSONAS_BUSCAR Incidencia")
c += srv_escritura("RegistrarAsync", "Dto_Incidencia_Registrar dto, long usuarioId, ", "dto, usuarioId, ", "REGISTRAR Incidencia UsuarioID={UsuarioID}\", usuarioId", val_reg, tipo="Dto_Incidencia_Registrada")
c += srv_escritura("DecidirAsync", "Dto_Incidencia_Decision dto, long usuarioId, ", "dto, usuarioId, ", "DECIDIR Incidencia UsuarioID={UsuarioID}\", usuarioId", val_dec)
escribir("Application.Services", "Srv_Incidencia.cs", servicio("Srv_Incidencia", "IRepo_Incidencia", "ISrv_Incidencia", "Incidencia", c,
    "// Quién registra o decide y si la incidencia sigue REGISTRADA lo decide la rutina (D-74, D-79).\n"))

val_env = """        if (correoId <= 0)
            return Result.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(correoId), "Falta el correo.") });

"""
val_err = """        if (correoId <= 0)
            return Result<string>.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(correoId), "Falta el correo.") });

"""
c = srv_lista("PendientesListarAsync", "Dto_Correo_Pendiente", "long usuarioId, int? maximo = null, ", "usuarioId, maximo, ", "PENDIENTES Correo")
c += srv_lista("ListarAsync", "Dto_Correo_Lista", "long usuarioId, Dto_Filtro_Correos f, ", "usuarioId, f, ", "LISTAR Correo")
c += srv_escritura("MarcarEnviadoAsync", "long correoId, long usuarioId, ", "correoId, usuarioId, ", "MARCAR_ENVIADO Correo ID={ID}\", correoId", val_env)
c += srv_escritura("MarcarErrorAsync", "long correoId, string? error, int maxIntentos, long usuarioId, ", "correoId, error, maxIntentos, usuarioId, ", "MARCAR_ERROR Correo ID={ID}\", correoId", val_err, tipo="string")
c += srv_escritura("ReencolarAsync", "long correoId, long sedeId, long usuarioId, ", "correoId, sedeId, usuarioId, ", "REENCOLAR Correo ID={ID}\", correoId", val_env)
escribir("Application.Services", "Srv_Correo.cs", servicio("Srv_Correo", "IRepo_Correo", "ISrv_Correo", "Correo", c,
    "// El proceso de envío usa el usuario del sistema (0, D-80); el servicio no lo decide, la rutina lo exige.\n"))

c = srv_lista("AccesosAsync", "Dto_Reporte_Acceso", "long usuarioId, Dto_Filtro_Reporte_Accesos f, ", "usuarioId, f, ", "ACCESOS Reporte")
c += srv_lista("ResumenDiarioAsync", "Dto_Reporte_Resumen_Dia", "long usuarioId, Dto_Filtro_Reporte_Rango f, ", "usuarioId, f, ", "RESUMEN_DIARIO Reporte")
c += srv_lista("AutorizadosPorZonaAsync", "Dto_Reporte_Autorizado", "long usuarioId, Dto_Filtro_Reporte_Zona f, ", "usuarioId, f, ", "AUTORIZADOS_POR_ZONA Reporte")
escribir("Application.Services", "Srv_Reporte.cs", servicio("Srv_Reporte", "IRepo_Reporte", "ISrv_Reporte", "Reporte", c,
    "// Un rango inválido o sin permiso devuelve lista vacía (D-83): la rutina decide, el servicio no la duplica.\n"))
print("generado en", destino)
