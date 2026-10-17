# -*- coding: utf-8 -*-
# gen_capas_solicitud.py  V1.0 2026-10-17
# Genera las capas .NET del Hito 2 (solicitudes, personas, decisiones, Vigilancia, pasos de aprobación)
# desde las FIRMAS REALES de las rutinas:  python3 gen_capas_solicitud.py firmas_rutinas_hito2.txt <carpeta src>
# Los DTO de RESPUESTA salen de las columnas que devuelve cada función (no se escriben a mano).
# Los DTO de ENTRADA (formularios y filtros) están en este archivo. Los parámetros de cada escritura
# están en la tabla ESCRITURAS; verificar_llamadas.py comprueba nombres, orden y tipos contra la base.
import re, sys, os

firmas_file, destino = sys.argv[1], sys.argv[2]
FECHA = "V1.0 — 2026-10-17"

# ── 1. Leer firmas ───────────────────────────────────────────────
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

# ── 2. Mapeo de tipos ────────────────────────────────────────────
ID_NO_NULOS = {"ID_Solicitud", "ID_Catalogo_Sede", "ID_Catalogo_Tipo_Acceso", "ID_Solicitud_Persona",
               "ID_Persona_Externa", "ID_Tipo_Acceso_Paso_Aprobacion", "ID_Evento"}
TEXTO_NO_NULO = {"Codigo", "Sede", "Tipo_Acceso", "Estado", "Persona_Nombre", "Nombre_Completo", "Motivo_Codigo",
                 "Paso_Codigo", "Decision", "Grupo", "Accion", "Entidad", "Accion_Texto", "Pestana"}
FECHA_NO_NULA = {"Fecha_Hora_Prevista", "Fecha_Evento"}

def tipo_cs(col, t):
    """→ (tipo C#, ¿nullable?, lector, valor por defecto)"""
    if t == "character":
        return "bool", False, "RdBool"
    if t == "integer":
        return "int", False, "RdInt"
    if t == "bigint":
        if col.startswith("ID_") and col not in ID_NO_NULOS:
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
            f"// Hito     : 2 — Solicitud y aprobación\n// Fase     : {fase}\n// Entidad  : {entidad}\n"
            f"// Versión  : {FECHA}\n// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)\n"
            f"// ============================================================\n{nota}\n")

def escribir(carpeta, nombre, texto):
    d = os.path.join(destino, carpeta, "ControlAccesos")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, nombre), "w", encoding="utf-8", newline="\n") as f:
        f.write(texto)

# ── 3. DTO de RESPUESTA (desde las columnas reales) ──────────────
LECTURAS = {  # función → (DTO, descripción)
    "ERP_CAF_SOLICITUD_MIS_LISTAR":                      ("Dto_Solicitud_Lista",      "fila de «Mis solicitudes» (con sus botones)"),
    "ERP_CAF_SOLICITUD_BANDEJA_LISTAR":                  ("Dto_Solicitud_Bandeja",    "fila de la bandeja de quien aprueba"),
    "ERP_CAF_SOLICITUD_CONTADORES":                      ("Dto_Solicitud_Contadores", "números de las pestañas"),
    "ERP_CAF_SOLICITUD_DETALLE":                         ("Dto_Solicitud_Detalle",    "cabecera completa de una solicitud, con botones"),
    "ERP_CAF_SOLICITUD_PERSONAS_LISTAR":                 ("Dto_Solicitud_Persona",    "persona de una solicitud, con su aprobación y botones"),
    "ERP_CAF_SOLICITUD_PASOS_LISTAR":                    ("Dto_Solicitud_Paso",       "persona × paso de la ruta de aprobación"),
    "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR":                ("Dto_Solicitud_Evento",     "evento del historial"),
    "ERP_CAF_SOLICITUD_VERSION_LISTAR":                  ("Dto_Solicitud_Version",    "foto de lo aprobado (RN-08)"),
    "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR":               ("Dto_Vigilancia_Persona",   "persona esperada hoy en portería"),
    "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR": ("Dto_Vigilancia_No_Autorizada", "persona que aparece pero no está autorizada"),
    "ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE":         ("Dto_Tipo_Acceso_Paso",     "paso de aprobación de un tipo de acceso"),
}
COLS = {}
for fn, (dto, desc) in LECTURAS.items():
    COLS[fn] = columnas(firmas[fn]["res"])
    L = [cabecera(dto + ".cs", "Application.DTOs", "2 — DTOs", dto.replace("Dto_", ""),
                  f"// Respuesta de {fn}: {desc}.\n// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.\n"
                  "// Generado por gen_capas_solicitud.py desde las firmas reales: no editar a mano.\n"),
         "namespace Application.DTOs.ControlAccesos;\n\npublic sealed class " + dto + "\n{\n"]
    for c, t in COLS[fn]:
        ct, nul, rd = tipo_cs(c, t)
        ini = " = string.Empty;" if ct == "string" else ""
        L.append(f"    public {ct} {c} {{ get; set; }}{ini}\n")
    L.append("}\n")
    escribir("Application.DTOs", dto + ".cs", "".join(L))

# ── 4. DTO de ENTRADA (a mano) ───────────────────────────────────
ENTRADAS = cabecera("Dto_Solicitud_Entradas.cs", "Application.DTOs", "2 — DTOs", "Solicitud — formularios y filtros",
"// Lo que la pantalla ENVÍA. Los identificadores múltiples van como lista y el repositorio los convierte al texto\n"
"// separado por comas que esperan las rutinas. Las reglas de negocio viven en la rutina (D-40).\n") + '''using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

/// <summary>Datos para crear y enviar una solicitud (ERP_CAF_SOLICITUD_CREAR).</summary>
public sealed class Dto_Solicitud_Crear
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Seleccione el tipo de acceso.")]
    public long ID_Catalogo_Tipo_Acceso { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Seleccione al responsable.")]
    public long ID_Personal_Responsable { get; set; }

    public DateTime Fecha_Hora_Prevista { get; set; }

    [StringLength(250, ErrorMessage = "La empresa no puede superar 250 caracteres.")]
    public string? Empresa_Visitante { get; set; }

    public long? ID_Catalogo_Motivo_Visita { get; set; }
    public string? Motivo_Detalle { get; set; }
    public string? Observaciones { get; set; }

    /// <summary>Zonas a visitar.</summary>
    public List<long> IDs_Zona { get; set; } = new();

    /// <summary>Personas externas de la visita (al menos una).</summary>
    public List<long> IDs_Persona_Externa { get; set; } = new();

    /// <summary>Correos en copia, separados por «;» o «,» (la rutina los valida).</summary>
    public string? Copias { get; set; }

    /// <summary>Solicitud de la que se reutilizan los datos («Reutilizar»), si hay.</summary>
    public long? ID_Solicitud_Origen { get; set; }
}

/// <summary>Resultado de crear: identificador y código visible (SOL-00001).</summary>
public sealed class Dto_Solicitud_Creada
{
    public long ID_Solicitud { get; set; }
    public string Codigo { get; set; } = string.Empty;
}

/// <summary>Datos que se pueden cambiar de una solicitud (ERP_CAF_SOLICITUD_EDITAR_DATOS).</summary>
public sealed class Dto_Solicitud_Editar
{
    public DateTime Fecha_Hora_Prevista { get; set; }
    public string? Empresa_Visitante { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Seleccione al responsable.")]
    public long ID_Personal_Responsable { get; set; }

    public long? ID_Catalogo_Motivo_Visita { get; set; }
    public string? Motivo_Detalle { get; set; }
    public string? Observaciones { get; set; }
    public List<long> IDs_Zona { get; set; } = new();
    public string? Copias { get; set; }
}

/// <summary>Decisión de quien aprueba (ERP_CAF_SOLICITUD_DECIDIR).</summary>
public sealed class Dto_Solicitud_Decidir
{
    [Range(1, long.MaxValue, ErrorMessage = "Falta la solicitud.")]
    public long ID_Solicitud { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Falta el paso de aprobación.")]
    public long ID_Tipo_Acceso_Paso_Aprobacion { get; set; }

    /// <summary>APROBADA, OBSERVADA o RECHAZADA.</summary>
    public string Decision { get; set; } = string.Empty;

    /// <summary>Obligatorio si la decisión no es APROBADA (la rutina lo exige).</summary>
    public string? Mensaje { get; set; }

    /// <summary>Personas sobre las que se decide (pasos por persona). Vacío en pasos por solicitud.</summary>
    public List<long> IDs_Solicitud_Persona { get; set; } = new();
}

/// <summary>Filtros de «Mis solicitudes». Todo opcional.</summary>
public sealed class Dto_Filtro_Mis_Solicitudes
{
    public long? ID_Catalogo_Sede { get; set; }
    /// <summary>Busca sin distinguir tildes ni mayúsculas: código, empresa, persona o documento.</summary>
    public string? Texto { get; set; }
    public string? Estado { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
}

/// <summary>Filtros de la bandeja de quien aprueba.</summary>
public sealed class Dto_Filtro_Bandeja
{
    public long? ID_Catalogo_Sede { get; set; }
    /// <summary>POR_DECIDIR o TODAS.</summary>
    public string Pestana { get; set; } = "TODAS";
    public string? Empresa { get; set; }
    public string? Solicitante { get; set; }
    public string? Persona { get; set; }
    public DateTime? Fecha { get; set; }
    public string? Estado { get; set; }
}

/// <summary>Filtros del listado de Vigilancia.</summary>
public sealed class Dto_Filtro_Vigilancia
{
    public long? ID_Catalogo_Sede { get; set; }
    /// <summary>Nulo = hoy.</summary>
    public DateTime? Fecha { get; set; }
    public string? Texto { get; set; }
    /// <summary>POR_INGRESAR, DENTRO, SALIERON o DENEGADOS_NO_VINIERON. Nulo = todos.</summary>
    public string? Grupo { get; set; }
}

/// <summary>Alta o cambio de un paso de aprobación de un tipo de acceso (administración).</summary>
public sealed class Dto_Tipo_Acceso_Paso_Entrada
{
    [Range(1, long.MaxValue, ErrorMessage = "Falta el tipo de acceso.")]
    public long ID_Catalogo_Tipo_Acceso { get; set; }
    public long Orden { get; set; } = 1;
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    /// <summary>PERSONA o SOLICITUD.</summary>
    public string Alcance { get; set; } = "PERSONA";
    /// <summary>Hoy solo ROL.</summary>
    public string Tipo_Aprobador { get; set; } = "ROL";
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione el rol que aprueba.")]
    public long ID_Catalogo_Licencia { get; set; }
    public string Condicion { get; set; } = "SIEMPRE";
    public bool Obligatorio { get; set; } = true;
    public bool Activo { get; set; } = true;
}
'''
escribir("Application.DTOs", "Dto_Solicitud_Entradas.cs", ENTRADAS)

# ── 5. Repositorios ──────────────────────────────────────────────
def mapper(nombre, fn):
    L = [f"    private static {LECTURAS[fn][0]} {nombre}(DbDataReader rd) => new()\n    {{\n"]
    w = max(len(c) for c, _ in COLS[fn])
    for c, t in COLS[fn]:
        ct, nul, rd = tipo_cs(c, t)
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

USING_REPO = "using System.Data.Common;\nusing Application.DTOs.ControlAccesos;\nusing Infrastructure.Contracts.ControlAccesos;\nusing Infrastructure.Persistence;\nusing Shared.Results;\n\nnamespace Infrastructure.Repositories.ControlAccesos;\n\n"

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
# --- Repo_Solicitud
b = ""
b += lectura("MisListarAsync", "ERP_CAF_SOLICITUD_MIS_LISTAR", "long usuarioId, Dto_Filtro_Mis_Solicitudes? f = null, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLong(p, "HV_ID_Catalogo_Sede", f?.ID_Catalogo_Sede);',
     'AddStr(p, "HV_Texto", f?.Texto);', 'AddStr(p, "HV_Estado", f?.Estado);',
     'AddDate(p, "HV_Fecha_Desde", f?.Fecha_Desde);', 'AddDate(p, "HV_Fecha_Hasta", f?.Fecha_Hasta);'])
b += lectura("BandejaListarAsync", "ERP_CAF_SOLICITUD_BANDEJA_LISTAR", "long usuarioId, Dto_Filtro_Bandeja? f = null, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLong(p, "HV_ID_Catalogo_Sede", f?.ID_Catalogo_Sede);',
     'AddStr(p, "HV_Pestana", string.IsNullOrWhiteSpace(f?.Pestana) ? "TODAS" : f!.Pestana);',
     'AddStr(p, "HV_Empresa", f?.Empresa);', 'AddStr(p, "HV_Solicitante", f?.Solicitante);',
     'AddStr(p, "HV_Persona", f?.Persona);', 'AddDate(p, "HV_Fecha", f?.Fecha);', 'AddStr(p, "HV_Estado", f?.Estado);'])
b += lectura("ContadoresAsync", "ERP_CAF_SOLICITUD_CONTADORES", "long usuarioId, long? sedeId = null, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLong(p, "HV_ID_Catalogo_Sede", sedeId);'], devuelve_lista=False)
b += lectura("DetalleAsync", "ERP_CAF_SOLICITUD_DETALLE", "long usuarioId, long solicitudId, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Solicitud", solicitudId);'], devuelve_lista=False)
for met, fn in [("PersonasListarAsync", "ERP_CAF_SOLICITUD_PERSONAS_LISTAR"), ("PasosListarAsync", "ERP_CAF_SOLICITUD_PASOS_LISTAR"),
                ("HistorialListarAsync", "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR"), ("VersionesListarAsync", "ERP_CAF_SOLICITUD_VERSION_LISTAR")]:
    b += lectura(met, fn, "long usuarioId, long solicitudId, ",
        ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Solicitud", solicitudId);'])
b += escritura_con_salidas("CrearAsync", "ERP_CAF_SOLICITUD_CREAR", ["HV_ID_Solicitud_Result", "HV_Codigo_Solicitud_Result"], "Dto_Solicitud_Creada",
    '        return ResultSp<Dto_Solicitud_Creada>.Success(new Dto_Solicitud_Creada\n        {\n'
    '            ID_Solicitud = Convert.ToInt64(r.Data["HV_ID_Solicitud_Result"] ?? 0L),\n'
    '            Codigo = Convert.ToString(r.Data["HV_Codigo_Solicitud_Result"]) ?? string.Empty,\n'
    '        }, r.Mensaje);',
    "Dto_Solicitud_Crear dto, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Catalogo_Sede", dto.ID_Catalogo_Sede);', 'AddLongReq(p, "HV_ID_Catalogo_Tipo_Acceso", dto.ID_Catalogo_Tipo_Acceso);',
     'AddLongReq(p, "HV_ID_Personal_Responsable", dto.ID_Personal_Responsable);', 'AddTimestamp(p, "HV_Fecha_Hora_Prevista", dto.Fecha_Hora_Prevista);',
     'AddStr(p, "HV_Empresa_Visitante", dto.Empresa_Visitante);', 'AddLong(p, "HV_ID_Catalogo_Motivo_Visita", dto.ID_Catalogo_Motivo_Visita);',
     'AddStr(p, "HV_Motivo_Detalle", dto.Motivo_Detalle);', 'AddStr(p, "HV_Observaciones", dto.Observaciones);',
     'AddStr(p, "HV_IDs_Zona", Ids(dto.IDs_Zona));', 'AddStr(p, "HV_IDs_Persona_Externa", Ids(dto.IDs_Persona_Externa));',
     'AddStr(p, "HV_Copias", dto.Copias);', 'AddLong(p, "HV_ID_Solicitud_Origen", dto.ID_Solicitud_Origen);',
     'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
b += escritura_con_salidas("EditarDatosAsync", "ERP_CAF_SOLICITUD_EDITAR_DATOS", ["HV_Reabierta_Result"], "bool",
    '        return ResultSp<bool>.Success(string.Equals(Convert.ToString(r.Data["HV_Reabierta_Result"])?.Trim(), "Y", StringComparison.OrdinalIgnoreCase), r.Mensaje);',
    "long solicitudId, Dto_Solicitud_Editar dto, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Solicitud", solicitudId);', 'AddTimestamp(p, "HV_Fecha_Hora_Prevista", dto.Fecha_Hora_Prevista);',
     'AddStr(p, "HV_Empresa_Visitante", dto.Empresa_Visitante);', 'AddLongReq(p, "HV_ID_Personal_Responsable", dto.ID_Personal_Responsable);',
     'AddLong(p, "HV_ID_Catalogo_Motivo_Visita", dto.ID_Catalogo_Motivo_Visita);', 'AddStr(p, "HV_Motivo_Detalle", dto.Motivo_Detalle);',
     'AddStr(p, "HV_Observaciones", dto.Observaciones);', 'AddStr(p, "HV_IDs_Zona", Ids(dto.IDs_Zona));',
     'AddStr(p, "HV_Copias", dto.Copias);', 'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
b += escritura_simple("CancelarAsync", "ERP_CAF_SOLICITUD_CANCELAR", "long solicitudId, string? motivo, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Solicitud", solicitudId);', 'AddStr(p, "HV_Motivo_Cancelacion", motivo);', 'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
b += '''    /// <summary>Lista de identificadores como texto separado por comas (formato de las rutinas).</summary>
    private static string Ids(IEnumerable<long>? ids)
        => ids is null ? string.Empty : string.Join(",", ids);

'''
mp = "\n".join(mapper("Map" + LECTURAS[f][0].replace("Dto_", ""), f) for f in
               ["ERP_CAF_SOLICITUD_MIS_LISTAR", "ERP_CAF_SOLICITUD_BANDEJA_LISTAR", "ERP_CAF_SOLICITUD_CONTADORES", "ERP_CAF_SOLICITUD_DETALLE",
                "ERP_CAF_SOLICITUD_PERSONAS_LISTAR", "ERP_CAF_SOLICITUD_PASOS_LISTAR", "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR", "ERP_CAF_SOLICITUD_VERSION_LISTAR"])
# nombres de mapper alineados con lo que usa lectura(): Map<Dto sin prefijo>
escribir("Infrastructure.Repositories", "Repo_Solicitud.cs",
         repo("Repo_Solicitud", "IRepo_Solicitud", "ERP_CAF_SOLICITUD_<ACCION> (lecturas, CREAR, EDITAR_DATOS, CANCELAR)", b, mp))

# --- Repo_Solicitud_Persona
b = escritura_con_id("AgregarAsync", "ERP_CAF_SOLICITUD_PERSONA_AGREGAR", "HV_ID_Solicitud_Persona_Result", "long solicitudId, long personaExternaId, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Solicitud", solicitudId);', 'AddLongReq(p, "HV_ID_Persona_Externa", personaExternaId);', 'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
b += escritura_simple("RetirarAsync", "ERP_CAF_SOLICITUD_PERSONA_RETIRAR", "long solicitudPersonaId, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Solicitud_Persona", solicitudPersonaId);', 'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
b += escritura_con_salidas("CorregirAsync", "ERP_CAF_SOLICITUD_PERSONA_CORREGIR", ["HV_Reenviada_Result"], "bool",
    '        return ResultSp<bool>.Success(string.Equals(Convert.ToString(r.Data["HV_Reenviada_Result"])?.Trim(), "Y", StringComparison.OrdinalIgnoreCase), r.Mensaje);',
    "long solicitudPersonaId, long personaExternaNuevaId, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Solicitud_Persona", solicitudPersonaId);', 'AddLongReq(p, "HV_ID_Persona_Externa_Nueva", personaExternaNuevaId);', 'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
escribir("Infrastructure.Repositories", "Repo_Solicitud_Persona.cs",
         repo("Repo_Solicitud_Persona", "IRepo_Solicitud_Persona", "ERP_CAF_SOLICITUD_PERSONA_<ACCION> (AGREGAR, RETIRAR, CORREGIR)", b, ""))

# --- Repo_Solicitud_Decision
b = escritura_con_salidas("DecidirAsync", "ERP_CAF_SOLICITUD_DECIDIR", ["HV_Cantidad_Result"], "long",
    '        return ResultSp<long>.Success(Convert.ToInt64(r.Data["HV_Cantidad_Result"] ?? 0L), r.Mensaje);',
    "Dto_Solicitud_Decidir dto, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Solicitud", dto.ID_Solicitud);', 'AddLongReq(p, "HV_ID_Tipo_Acceso_Paso_Aprobacion", dto.ID_Tipo_Acceso_Paso_Aprobacion);',
     'AddStr(p, "HV_Decision", dto.Decision);', 'AddStr(p, "HV_Mensaje_Decision", dto.Mensaje);',
     'AddStr(p, "HV_IDs_Solicitud_Persona", dto.IDs_Solicitud_Persona is null ? string.Empty : string.Join(",", dto.IDs_Solicitud_Persona));',
     'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
escribir("Infrastructure.Repositories", "Repo_Solicitud_Decision.cs",
         repo("Repo_Solicitud_Decision", "IRepo_Solicitud_Decision", "ERP_CAF_SOLICITUD_DECIDIR", b, ""))

# --- Repo_Solicitud_Vigilancia
b = lectura("ListarAsync", "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR", "long usuarioId, Dto_Filtro_Vigilancia? f = null, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLong(p, "HV_ID_Catalogo_Sede", f?.ID_Catalogo_Sede);',
     'AddDate(p, "HV_Fecha", f?.Fecha);', 'AddStr(p, "HV_Texto", f?.Texto);', 'AddStr(p, "HV_Grupo", f?.Grupo);']).replace("MapVigilancia_Persona", "MapVigilancia_Persona")
b += lectura("NoAutorizadaBuscarAsync", "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR", "long usuarioId, long sedeId, DateTime fecha, string texto, ",
    ['AddLongReq(p, "HV_UsuarioID", usuarioId);', 'AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);',
     'AddDate(p, "HV_Fecha", fecha);', 'AddStrReq(p, "HV_Texto", texto);'])
mp = "\n".join(mapper("Map" + LECTURAS[f][0].replace("Dto_", ""), f) for f in
               ["ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR", "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR"])
escribir("Infrastructure.Repositories", "Repo_Solicitud_Vigilancia.cs",
         repo("Repo_Solicitud_Vigilancia", "IRepo_Solicitud_Vigilancia", "ERP_CAF_SOLICITUD_VIGILANCIA_* (lecturas de portería)", b, mp))

# --- Repo_Tipo_Acceso_Paso
b = lectura("ListarPorPadreAsync", "ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE", "long tipoAccesoId, bool incluirInactivos = false, ",
    ['AddLongReq(p, "HV_ID_Catalogo_Tipo_Acceso", tipoAccesoId);', 'AddChar1(p, "HV_Incluir_Inactivos", incluirInactivos ? "Y" : "N");'])
b += escritura_con_id("AgregarAsync", "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR", "HV_ID_Tipo_Acceso_Paso_Aprobacion_Result", "Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Catalogo_Tipo_Acceso", dto.ID_Catalogo_Tipo_Acceso);', 'AddLongReq(p, "HV_Orden", dto.Orden);',
     'AddStrReq(p, "HV_Codigo", dto.Codigo);', 'AddStrReq(p, "HV_Descripcion", dto.Descripcion);', 'AddStrReq(p, "HV_Alcance", dto.Alcance);',
     'AddStrReq(p, "HV_Tipo_Aprobador", dto.Tipo_Aprobador);', 'AddLongReq(p, "HV_ID_Catalogo_Licencia", dto.ID_Catalogo_Licencia);',
     'AddStrReq(p, "HV_Condicion", dto.Condicion);', 'AddChar1(p, "HV_Obligatorio", dto.Obligatorio ? "Y" : "N");',
     'AddLongReq(p, "HV_UsuarioID_Create", usuarioId);'])
b += escritura_simple("ActualizarAsync", "ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR", "long pasoId, Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Tipo_Acceso_Paso_Aprobacion", pasoId);', 'AddLongReq(p, "HV_Orden", dto.Orden);',
     'AddStrReq(p, "HV_Descripcion", dto.Descripcion);', 'AddStrReq(p, "HV_Alcance", dto.Alcance);',
     'AddLongReq(p, "HV_ID_Catalogo_Licencia", dto.ID_Catalogo_Licencia);', 'AddChar1(p, "HV_Obligatorio", dto.Obligatorio ? "Y" : "N");',
     'AddChar1(p, "HV_Activo", dto.Activo ? "Y" : "N");', 'AddLongReq(p, "HV_UsuarioID", usuarioId);'])
b += escritura_simple("QuitarAsync", "ERP_CAF_TIPO_ACCESO_PASO_QUITAR", "long pasoId, long usuarioId, ",
    ['AddLongReq(p, "HV_ID_Tipo_Acceso_Paso_Aprobacion", pasoId);', 'AddLongReq(p, "HV_UsuarioID_Update", usuarioId);'])
mp = mapper("MapTipo_Acceso_Paso", "ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE")
escribir("Infrastructure.Repositories", "Repo_Tipo_Acceso_Paso.cs",
         repo("Repo_Tipo_Acceso_Paso", "IRepo_Tipo_Acceso_Paso", "ERP_CAF_TIPO_ACCESO_PASO_<ACCION>", b, mp))

# ── 6. Interfaces de repositorio y de servicio ──────────────────
def iface(carpeta, proyecto_ns, nombre, fase, entidad, metodos, usings):
    txt = cabecera(nombre + ".cs", carpeta, fase, entidad) + usings + f"\nnamespace {proyecto_ns}.ControlAccesos;\n\npublic interface {nombre}\n{{\n"
    txt += "".join(f"    {m}\n" for m in metodos) + "}\n"
    escribir(carpeta, nombre + ".cs", txt)

U_REPO = "using Application.DTOs.ControlAccesos;\nusing Shared.Results;\n"
R = "CancellationToken ct = default"
REPO_SOL = [
 f"Task<Result<List<Dto_Solicitud_Lista>>> MisListarAsync(long usuarioId, Dto_Filtro_Mis_Solicitudes? f = null, {R});",
 f"Task<Result<List<Dto_Solicitud_Bandeja>>> BandejaListarAsync(long usuarioId, Dto_Filtro_Bandeja? f = null, {R});",
 f"Task<Result<Dto_Solicitud_Contadores?>> ContadoresAsync(long usuarioId, long? sedeId = null, {R});",
 f"Task<Result<Dto_Solicitud_Detalle?>> DetalleAsync(long usuarioId, long solicitudId, {R});",
 f"Task<Result<List<Dto_Solicitud_Persona>>> PersonasListarAsync(long usuarioId, long solicitudId, {R});",
 f"Task<Result<List<Dto_Solicitud_Paso>>> PasosListarAsync(long usuarioId, long solicitudId, {R});",
 f"Task<Result<List<Dto_Solicitud_Evento>>> HistorialListarAsync(long usuarioId, long solicitudId, {R});",
 f"Task<Result<List<Dto_Solicitud_Version>>> VersionesListarAsync(long usuarioId, long solicitudId, {R});",
 f"Task<ResultSp<Dto_Solicitud_Creada>> CrearAsync(Dto_Solicitud_Crear dto, long usuarioId, {R});",
 f"Task<ResultSp<bool>> EditarDatosAsync(long solicitudId, Dto_Solicitud_Editar dto, long usuarioId, {R});",
 f"Task<ResultSp> CancelarAsync(long solicitudId, string? motivo, long usuarioId, {R});",
]
iface("Infrastructure.Contracts", "Infrastructure.Contracts", "IRepo_Solicitud", "3 — Contracts", "Solicitud", REPO_SOL, U_REPO)
iface("Infrastructure.Contracts", "Infrastructure.Contracts", "IRepo_Solicitud_Persona", "3 — Contracts", "Solicitud_Persona", [
 f"Task<ResultSp<long>> AgregarAsync(long solicitudId, long personaExternaId, long usuarioId, {R});",
 f"Task<ResultSp> RetirarAsync(long solicitudPersonaId, long usuarioId, {R});",
 f"Task<ResultSp<bool>> CorregirAsync(long solicitudPersonaId, long personaExternaNuevaId, long usuarioId, {R});"], U_REPO)
iface("Infrastructure.Contracts", "Infrastructure.Contracts", "IRepo_Solicitud_Decision", "3 — Contracts", "Solicitud_Decision", [
 f"Task<ResultSp<long>> DecidirAsync(Dto_Solicitud_Decidir dto, long usuarioId, {R});"], U_REPO)
iface("Infrastructure.Contracts", "Infrastructure.Contracts", "IRepo_Solicitud_Vigilancia", "3 — Contracts", "Solicitud — Vigilancia", [
 f"Task<Result<List<Dto_Vigilancia_Persona>>> ListarAsync(long usuarioId, Dto_Filtro_Vigilancia? f = null, {R});",
 f"Task<Result<List<Dto_Vigilancia_No_Autorizada>>> NoAutorizadaBuscarAsync(long usuarioId, long sedeId, DateTime fecha, string texto, {R});"], U_REPO)
iface("Infrastructure.Contracts", "Infrastructure.Contracts", "IRepo_Tipo_Acceso_Paso", "3 — Contracts", "Tipo_Acceso_Paso_Aprobacion", [
 f"Task<Result<List<Dto_Tipo_Acceso_Paso>>> ListarPorPadreAsync(long tipoAccesoId, bool incluirInactivos = false, {R});",
 f"Task<ResultSp<long>> AgregarAsync(Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, {R});",
 f"Task<ResultSp> ActualizarAsync(long pasoId, Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, {R});",
 f"Task<ResultSp> QuitarAsync(long pasoId, long usuarioId, {R});"], U_REPO)

SRV_SOL = [
 f"Task<Result<List<Dto_Solicitud_Lista>>> MisListarAsync(long usuarioId, Dto_Filtro_Mis_Solicitudes? f = null, {R});",
 f"Task<Result<List<Dto_Solicitud_Bandeja>>> BandejaListarAsync(long usuarioId, Dto_Filtro_Bandeja? f = null, {R});",
 f"Task<Result<Dto_Solicitud_Contadores>> ContadoresAsync(long usuarioId, long? sedeId = null, {R});",
 f"Task<Result<Dto_Solicitud_Detalle>> DetalleAsync(long usuarioId, long solicitudId, {R});",
 f"Task<Result<List<Dto_Solicitud_Persona>>> PersonasListarAsync(long usuarioId, long solicitudId, {R});",
 f"Task<Result<List<Dto_Solicitud_Paso>>> PasosListarAsync(long usuarioId, long solicitudId, {R});",
 f"Task<Result<List<Dto_Solicitud_Evento>>> HistorialListarAsync(long usuarioId, long solicitudId, {R});",
 f"Task<Result<List<Dto_Solicitud_Version>>> VersionesListarAsync(long usuarioId, long solicitudId, {R});",
 f"Task<Result<Dto_Solicitud_Creada>> CrearAsync(Dto_Solicitud_Crear dto, long usuarioId, {R});",
 f"Task<Result<bool>> EditarDatosAsync(long solicitudId, Dto_Solicitud_Editar dto, long usuarioId, {R});",
 f"Task<Result> CancelarAsync(long solicitudId, string? motivo, long usuarioId, {R});",
]
iface("Application.Contracts", "Application.Contracts", "ISrv_Solicitud", "3 — Contracts", "Solicitud", SRV_SOL, U_REPO)
iface("Application.Contracts", "Application.Contracts", "ISrv_Solicitud_Persona", "3 — Contracts", "Solicitud_Persona", [
 f"Task<Result<long>> AgregarAsync(long solicitudId, long personaExternaId, long usuarioId, {R});",
 f"Task<Result> RetirarAsync(long solicitudPersonaId, long usuarioId, {R});",
 f"Task<Result<bool>> CorregirAsync(long solicitudPersonaId, long personaExternaNuevaId, long usuarioId, {R});"], U_REPO)
iface("Application.Contracts", "Application.Contracts", "ISrv_Solicitud_Decision", "3 — Contracts", "Solicitud_Decision", [
 f"Task<Result<long>> DecidirAsync(Dto_Solicitud_Decidir dto, long usuarioId, {R});"], U_REPO)
iface("Application.Contracts", "Application.Contracts", "ISrv_Solicitud_Vigilancia", "3 — Contracts", "Solicitud — Vigilancia", [
 f"Task<Result<List<Dto_Vigilancia_Persona>>> ListarAsync(long usuarioId, Dto_Filtro_Vigilancia? f = null, {R});",
 f"Task<Result<List<Dto_Vigilancia_No_Autorizada>>> NoAutorizadaBuscarAsync(long usuarioId, long sedeId, DateTime fecha, string texto, {R});"], U_REPO)
iface("Application.Contracts", "Application.Contracts", "ISrv_Tipo_Acceso_Paso", "3 — Contracts", "Tipo_Acceso_Paso_Aprobacion", [
 f"Task<Result<List<Dto_Tipo_Acceso_Paso>>> ListarPorPadreAsync(long tipoAccesoId, bool incluirInactivos = false, {R});",
 f"Task<Result<long>> AgregarAsync(Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, {R});",
 f"Task<Result> ActualizarAsync(long pasoId, Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, {R});",
 f"Task<Result> QuitarAsync(long pasoId, long usuarioId, {R});"], U_REPO)

# ── 7. Servicios ─────────────────────────────────────────────────
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

# --- Srv_Solicitud
c = ""
c += srv_lista("MisListarAsync", "Dto_Solicitud_Lista", "long usuarioId, Dto_Filtro_Mis_Solicitudes? f = null, ", "usuarioId, f, ", "MIS_LISTAR Solicitud")
c += srv_lista("BandejaListarAsync", "Dto_Solicitud_Bandeja", "long usuarioId, Dto_Filtro_Bandeja? f = null, ", "usuarioId, f, ", "BANDEJA Solicitud")
c += srv_una("ContadoresAsync", "Dto_Solicitud_Contadores", "long usuarioId, long? sedeId = null, ", "usuarioId, sedeId, ", "CONTADORES Solicitud", "No se pudieron obtener los contadores.")
c += srv_una("DetalleAsync", "Dto_Solicitud_Detalle", "long usuarioId, long solicitudId, ", "usuarioId, solicitudId, ", "DETALLE Solicitud ID={ID}\", solicitudId", "La solicitud no existe o no tiene permiso para verla.")
for met, dto, et in [("PersonasListarAsync", "Dto_Solicitud_Persona", "PERSONAS Solicitud"), ("PasosListarAsync", "Dto_Solicitud_Paso", "PASOS Solicitud"),
                     ("HistorialListarAsync", "Dto_Solicitud_Evento", "HISTORIAL Solicitud"), ("VersionesListarAsync", "Dto_Solicitud_Version", "VERSIONES Solicitud")]:
    c += srv_lista(met, dto, "long usuarioId, long solicitudId, ", "usuarioId, solicitudId, ", et)

val_crear = ('''        var errors = new List<ResultError>();
        if (dto.ID_Catalogo_Sede <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Sede), "Seleccione la sede."));
        if (dto.ID_Catalogo_Tipo_Acceso <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Tipo_Acceso), "Seleccione el tipo de acceso."));
        if (dto.ID_Personal_Responsable <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Personal_Responsable), "Seleccione al responsable."));
        if (dto.Fecha_Hora_Prevista == default)
            errors.Add(new ResultError(nameof(dto.Fecha_Hora_Prevista), "Indique la fecha y hora de la visita."));
        if (dto.IDs_Persona_Externa is null || dto.IDs_Persona_Externa.Count == 0)
            errors.Add(new ResultError(nameof(dto.IDs_Persona_Externa), "Agregue al menos una persona."));
        if (errors.Count > 0)
            return Result<Dto_Solicitud_Creada>.Validation("Datos inválidos.", errors);

''')
c += srv_escritura("CrearAsync", "Dto_Solicitud_Crear dto, long usuarioId, ", "dto, usuarioId, ", "CREAR Solicitud UsuarioID={UsuarioID}\", usuarioId", val_crear, tipo="Dto_Solicitud_Creada")
val_edit = ('''        var errors = new List<ResultError>();
        if (dto.Fecha_Hora_Prevista == default)
            errors.Add(new ResultError(nameof(dto.Fecha_Hora_Prevista), "Indique la fecha y hora de la visita."));
        if (dto.ID_Personal_Responsable <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Personal_Responsable), "Seleccione al responsable."));
        if (errors.Count > 0)
            return Result<bool>.Validation("Datos inválidos.", errors);

''')
c += srv_escritura("EditarDatosAsync", "long solicitudId, Dto_Solicitud_Editar dto, long usuarioId, ", "solicitudId, dto, usuarioId, ", "EDITAR_DATOS Solicitud ID={ID}\", solicitudId", val_edit, tipo="bool")
c += srv_escritura("CancelarAsync", "long solicitudId, string? motivo, long usuarioId, ", "solicitudId, motivo, usuarioId, ", "CANCELAR Solicitud ID={ID}\", solicitudId")
escribir("Application.Services", "Srv_Solicitud.cs", servicio("Srv_Solicitud", "IRepo_Solicitud", "ISrv_Solicitud", "Solicitud", c,
    "// Lecturas: una consulta sin filas (sin permiso o inexistente) sale como NOT_FOUND con un mensaje neutro (D-57).\n"))

# --- Srv_Solicitud_Persona
c = srv_escritura("AgregarAsync", "long solicitudId, long personaExternaId, long usuarioId, ", "solicitudId, personaExternaId, usuarioId, ", "AGREGAR Persona ID={ID}\", solicitudId", tipo="long")
c += srv_escritura("RetirarAsync", "long solicitudPersonaId, long usuarioId, ", "solicitudPersonaId, usuarioId, ", "RETIRAR Persona ID={ID}\", solicitudPersonaId")
c += srv_escritura("CorregirAsync", "long solicitudPersonaId, long personaExternaNuevaId, long usuarioId, ", "solicitudPersonaId, personaExternaNuevaId, usuarioId, ", "CORREGIR Persona ID={ID}\", solicitudPersonaId", tipo="bool")
escribir("Application.Services", "Srv_Solicitud_Persona.cs", servicio("Srv_Solicitud_Persona", "IRepo_Solicitud_Persona", "ISrv_Solicitud_Persona", "Solicitud_Persona", c))

# --- Srv_Solicitud_Decision
val_dec = ('''        var errors = new List<ResultError>();
        if (dto.ID_Solicitud <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Solicitud), "Falta la solicitud."));
        if (dto.ID_Tipo_Acceso_Paso_Aprobacion <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Tipo_Acceso_Paso_Aprobacion), "Falta el paso de aprobación."));
        if (string.IsNullOrWhiteSpace(dto.Decision))
            errors.Add(new ResultError(nameof(dto.Decision), "Elija aprobar, observar o rechazar."));
        if (errors.Count > 0)
            return Result<long>.Validation("Datos inválidos.", errors);

''')
c = srv_escritura("DecidirAsync", "Dto_Solicitud_Decidir dto, long usuarioId, ", "dto, usuarioId, ", "DECIDIR Solicitud ID={ID}\", dto.ID_Solicitud", val_dec, tipo="long")
escribir("Application.Services", "Srv_Solicitud_Decision.cs", servicio("Srv_Solicitud_Decision", "IRepo_Solicitud_Decision", "ISrv_Solicitud_Decision", "Solicitud_Decision", c,
    "// Solo exige que se elija una decisión; el valor válido, el mensaje obligatorio y el orden de los pasos los valida la rutina.\n"))

# --- Srv_Solicitud_Vigilancia
c = srv_lista("ListarAsync", "Dto_Vigilancia_Persona", "long usuarioId, Dto_Filtro_Vigilancia? f = null, ", "usuarioId, f, ", "LISTAR Vigilancia")
c += srv_lista("NoAutorizadaBuscarAsync", "Dto_Vigilancia_No_Autorizada", "long usuarioId, long sedeId, DateTime fecha, string texto, ", "usuarioId, sedeId, fecha, texto ?? string.Empty, ", "NO_AUTORIZADA Vigilancia")
escribir("Application.Services", "Srv_Solicitud_Vigilancia.cs", servicio("Srv_Solicitud_Vigilancia", "IRepo_Solicitud_Vigilancia", "ISrv_Solicitud_Vigilancia", "Solicitud — Vigilancia", c))

# --- Srv_Tipo_Acceso_Paso
c = srv_lista("ListarPorPadreAsync", "Dto_Tipo_Acceso_Paso", "long tipoAccesoId, bool incluirInactivos = false, ", "tipoAccesoId, incluirInactivos, ", "LISTAR Tipo_Acceso_Paso")
val_paso = ('''        var errors = new List<ResultError>();
        if (dto.ID_Catalogo_Tipo_Acceso <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Tipo_Acceso), "Falta el tipo de acceso."));
        if (string.IsNullOrWhiteSpace(dto.Codigo))
            errors.Add(new ResultError(nameof(dto.Codigo), "El Código es obligatorio."));
        if (string.IsNullOrWhiteSpace(dto.Descripcion))
            errors.Add(new ResultError(nameof(dto.Descripcion), "La Descripción es obligatoria."));
        if (dto.ID_Catalogo_Licencia <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Licencia), "Seleccione el rol que aprueba."));
        if (errors.Count > 0)
            return {RET}.Validation("Datos inválidos.", errors);

''')
c += srv_escritura("AgregarAsync", "Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, ", "dto, usuarioId, ", "AGREGAR Tipo_Acceso_Paso", val_paso.replace("{RET}", "Result<long>"), tipo="long")
c += srv_escritura("ActualizarAsync", "long pasoId, Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, ", "pasoId, dto, usuarioId, ", "ACTUALIZAR Tipo_Acceso_Paso ID={ID}\", pasoId", val_paso.replace("{RET}", "Result"))
c = c
c += srv_escritura("QuitarAsync", "long pasoId, long usuarioId, ", "pasoId, usuarioId, ", "QUITAR Tipo_Acceso_Paso ID={ID}\", pasoId")
escribir("Application.Services", "Srv_Tipo_Acceso_Paso.cs", servicio("Srv_Tipo_Acceso_Paso", "IRepo_Tipo_Acceso_Paso", "ISrv_Tipo_Acceso_Paso", "Tipo_Acceso_Paso_Aprobacion", c))
print("generado en", destino)
