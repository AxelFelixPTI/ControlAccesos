# Genera las capas .NET de los catálogos (Fases 2 a 5) desde las FIRMAS REALES de la base.
# V1.0 2026-10-13 · una sola plantilla para los catálogos de CAF_GOVERNANCE y del módulo.
#
# Entrada : firmas_rutinas.txt  (una línea por rutina: schema|nombre|prokind|argumentos|resultado)
#           se obtiene con el comando que está en la cabecera de ese archivo.
# Salida  : <carpeta>/<Proyecto>/ControlAccesos/*.cs  (DTO universal, IRepo_, ISrv_, Repo_, Srv_)
# Uso     : python3 gen_capas_catalogos.py <firmas_rutinas.txt> <carpeta_salida>
#
# El orden y el tipo de cada parámetro que el repositorio envía salen de la firma de la rutina,
# no de lo que "debería" ser: si el SP cambia, se regenera y el desvío es imposible.
import os, re, sys

FECHA = "2026-10-13"
NS = "ControlAccesos"

# (E, tabla, schema, solo_lectura)   E = nombre en ERP_CATALOGO_<E>_*
CATALOGOS = [
    ("SEDE", "Catalogo_Sede", "CAF_GOVERNANCE", False),
    ("AREA", "Catalogo_Area", "CAF_GOVERNANCE", False),
    ("CARGO", "Catalogo_Cargo", "CAF_GOVERNANCE", False),
    ("TIPO_DOCUMENTO", "Catalogo_Tipo_Documento", "CAF_GOVERNANCE", False),
    ("EMPRESA_GRUPO", "Catalogo_Empresa_Grupo", "CAF_GOVERNANCE", False),
    ("LICENCIA", "Catalogo_Licencia", "CAF_GOVERNANCE", True),
    ("TIPO_ACCESO", "Catalogo_Tipo_Acceso", "TRIANONSATELITAL_CAF_PRODD", False),
    ("ZONA_ACCESO", "Catalogo_Zona_Acceso", "TRIANONSATELITAL_CAF_PRODD", False),
    ("MOTIVO_VISITA", "Catalogo_Motivo_Visita", "TRIANONSATELITAL_CAF_PRODD", False),
    ("TRATAMIENTO_DESVIACION", "Catalogo_Tratamiento_Desviacion", "TRIANONSATELITAL_CAF_PRODD", False),
    ("TIPO_INCIDENCIA", "Catalogo_Tipo_Incidencia", "TRIANONSATELITAL_CAF_PRODD", False),
    ("ITEM_CHECKLIST", "Catalogo_Item_Checklist", "TRIANONSATELITAL_CAF_PRODD", False),
]
CONEXION = {"CAF_GOVERNANCE": "ConexionesCaf.Gobierno", "TRIANONSATELITAL_CAF_PRODD": "ConexionesCaf.Modulo"}
HITO = {"CAF_GOVERNANCE": "0 — Base", "TRIANONSATELITAL_CAF_PRODD": "1 — Catálogos del módulo"}

# ------------------------------------------------------------------ lectura de firmas
def partir(s):
    """Separa por comas de primer nivel (los tipos no llevan comas, los DEFAULT tampoco)."""
    return [x.strip() for x in s.split(", ") if x.strip()]

def parse_args(txt):
    out = []
    for a in partir(txt):
        m = re.match(r'^(?:(IN|INOUT|OUT)\s+)?"([^"]+)"\s+(.+?)(?:\s+DEFAULT\s+.+)?$', a)
        if not m:
            raise SystemExit(f"No entiendo el argumento: {a}")
        out.append((m.group(1) or "IN", m.group(2), m.group(3).strip()))
    return out

def parse_cols(txt):
    m = re.match(r"^TABLE\((.*)\)$", txt)
    if not m:
        return []
    return [(c[0], c[1]) for c in (re.match(r'^"([^"]+)"\s+(.+)$', x).groups() for x in partir(m.group(1)))]

def leer(path):
    R = {}
    for ln in open(path, encoding="utf-8"):
        if ln.startswith("#") or not ln.strip():
            continue
        sch, nom, kind, args, res = ln.rstrip("\n").split("|", 4)
        R[nom] = dict(schema=sch, kind=kind, args=parse_args(args) if args else [], cols=parse_cols(res))
    return R

# ------------------------------------------------------------------ tipos
def camel(nom):
    p = nom.split("_")
    return p[0].lower() + "".join(x[:1].upper() + x[1:] for x in p[1:])

NO_NULOS = {"ID_Catalogo", "Orden"}   # el resto de bigint/timestamp pueden venir nulos

def HDR(archivo, ruta, fase, entidad, hito):
    return f"""// ============================================================
// Archivo  : {archivo}
// Ruta     : {ruta}
// Módulo   : ControlAccesos
// Hito     : {hito}
// Fase     : {fase}
// Entidad  : {entidad}
// Versión  : V1.0 — {FECHA}
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
"""

# ------------------------------------------------------------------ modelo de cada catálogo
def modelo(R, E, tabla, schema, solo_lectura):
    r = lambda a: R.get(f"ERP_CATALOGO_{E}_{a}")
    m = dict(E=E, t=tabla, schema=schema, ro=solo_lectura, conn=CONEXION[schema], hito=HITO[schema],
             listar=r("LISTAR"), dropdown=r("DROPDOWN"))
    for a in ("CREAR", "DETALLE", "ACTUALIZAR", "ELIMINAR"):
        m[a.lower()] = None if solo_lectura else r(a)
    faltan = [k for k, v in m.items() if k in ("listar", "dropdown") and v is None]
    if faltan or (not solo_lectura and any(m[k] is None for k in ("crear", "detalle", "actualizar", "eliminar"))):
        raise SystemExit(f"Faltan rutinas de {E}")
    m["pk"] = "ID_" + tabla
    return m

def props_dto(cats):
    """Propiedades del DTO universal: columnas devueltas + parámetros de CREAR/ACTUALIZAR, con su origen."""
    P = {}   # nombre -> (tipo_sql, origen)
    orden = []
    def add(n, t, origen):
        if n not in P:
            P[n] = (t, origen); orden.append(n)
    for c in cats:
        for clave in ("listar", "detalle", "dropdown"):
            if c[clave]:
                for n, t in c[clave]["cols"]:
                    add(n, t, c["t"])
        for clave in ("crear", "actualizar"):
            if c[clave]:
                for modo, n, t in c[clave]["args"]:
                    if modo == "IN" and n.startswith("HV_") and not re.match(r"HV_(UsuarioID.*|ID_" + re.escape(c["t"]) + ")$", n):
                        add(n[3:], t, c["t"])
    return P, orden

# ------------------------------------------------------------------ DTO universal
def gen_dto(cats):
    P, orden = props_dto(cats)
    base = ["ID_Catalogo", "Codigo", "Descripcion", "Tipo_Entidad", "Orden", "Activo", "Eliminado",
            "UsuarioID_Create", "Nombre_Usuario", "UsuarioID_Update", "CreateDate", "UpdateDate"]
    for b in base:
        assert b in P, b
    s = HDR("Dto_Catalogo_Universal.cs", "Application.DTOs/ControlAccesos/", "2 — DTOs",
            "Compartido — TODAS las tablas Catalogo_*", "0 y 1 — Catálogos")
    s += """// Cubre LISTAR, CREAR, DETALLE, ACTUALIZAR y DROPDOWN de cualquier tabla Catalogo_*.
// Una sola clase para todos los catálogos: nunca se crean DTOs por tabla.
// Propiedades = nombres EXACTOS de las columnas que devuelven los procedimientos.
// La PK real de cada tabla sale como alias "ID_Catalogo" en el SP.
// Generado por gen_capas_catalogos.py desde las firmas reales: no editar a mano.
// ============================================================

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Catalogo_Universal
{
    // ── PK genérica (alias "ID_Catalogo" del SP) ─────────────────
    // CREAR: siempre 0 (el SP genera el ID). EDITAR: viene de la ruta.
    public long ID_Catalogo { get; set; }

    // ── Datos principales ─────────────────────────────────────────
    [Required(ErrorMessage = "El Código es obligatorio.")]
    [StringLength(50, ErrorMessage = "El Código no puede superar 50 caracteres.")]
    public string Codigo { get; set; } = string.Empty;

    [Required(ErrorMessage = "La Descripción es obligatoria.")]
    [StringLength(500, ErrorMessage = "La Descripción no puede superar 500 caracteres.")]
    public string Descripcion { get; set; } = string.Empty;

    public string? Tipo_Entidad { get; set; }

    public long Orden { get; set; }

    /// <summary>'Y' / 'N'. Nulo en CREAR = el servicio envía 'Y'.</summary>
    public string? Activo { get; set; }

    // ── Auditoría — la gestiona el SP, nunca el formulario ───────
    public string? Eliminado { get; set; }
    public long? UsuarioID_Create { get; set; }
    public string? Nombre_Usuario { get; set; }
    public long? UsuarioID_Update { get; set; }
    public DateTime? CreateDate { get; set; }
    public DateTime? UpdateDate { get; set; }
"""
    por_origen = {}
    for n in orden:
        if n in base:
            continue
        por_origen.setdefault(P[n][1], []).append(n)
    for c in cats:
        ns = por_origen.get(c["t"])
        if not ns:
            continue
        s += f"\n    // ── {c['t']} (V1.0 {FECHA}) ──────────────────────────\n"
        for n in ns:
            t = P[n][0]
            tipo = {"bigint": "long?", "integer": "int?", "character varying": "string?", "character": "string?",
                    "timestamp without time zone": "DateTime?"}[t]
            s += f"    public {tipo} {n} {{ get; set; }}\n"
    s += "}\n"
    return s, P

# ------------------------------------------------------------------ bind y mapper
def tipo_prop(P, n):
    t = P[n][0]
    return {"bigint": "long", "integer": "int", "character varying": "string", "character": "string",
            "timestamp without time zone": "DateTime"}[t]

def bind_linea(modo, n, t, m, P, accion):
    """Línea de bind para un parámetro IN de CREAR / ACTUALIZAR."""
    if n == "HV_UsuarioID_Create" or n == "HV_UsuarioID" or n == "HV_UsuarioID_Update":
        return f'AddLongReq(p, "{n}", usuarioId);'
    if n == "HV_" + m["pk"]:
        return f'AddLongReq(p, "{n}", id);'
    prop = n[3:]
    if prop == "Codigo":
        return f'AddStrReq(p, "{n}", dto.Codigo);'
    if prop == "Descripcion":
        return f'AddStrReq(p, "{n}", dto.Descripcion);'
    if prop == "Orden":
        return f'AddLongReq(p, "{n}", dto.Orden);'
    if prop == "Activo":
        return f'AddChar1(p, "{n}", dto.Activo ?? "Y");'
    if t == "bigint":
        return f'AddLong(p, "{n}", dto.{prop});'
    if t == "integer":
        return f'AddInt(p, "{n}", dto.{prop});'
    if t == "character":
        return f'AddChar1(p, "{n}", dto.{prop});'
    if t == "character varying":
        return f'AddStr(p, "{n}", dto.{prop});'
    raise SystemExit(f"Sin bind para {n} {t}")

def bind_param_simple(n, t, var):
    if t == "bigint":
        return f'AddLong(p, "{n}", {var});'
    if t == "integer":
        return f'AddInt(p, "{n}", {var});'
    if t == "character":
        return f'AddChar1(p, "{n}", {var});'
    return f'AddStr(p, "{n}", {var});'

def mapper(nombre, cols, P):
    s = f"    private static Dto_Catalogo_Universal {nombre}(DbDataReader rd) => new()\n    {{\n"
    w = max(len(n) for n, _ in cols)
    for n, t in cols:
        if n in ("Codigo", "Descripcion"):
            f = "RdStr"
        elif t == "bigint":
            f = "RdLong" if n in NO_NULOS else "RdLongN"
        elif t == "integer":
            f = "RdIntN"
        elif t == "timestamp without time zone":
            f = "RdDtN"
        else:
            f = "RdStrN"
        s += f'        {n.ljust(w)} = {f}(rd, "{n}"),\n'
    s += "    };\n"
    return s

def args_in(rutina, excluir=()):
    return [(n, t) for modo, n, t in rutina["args"] if modo == "IN" and n not in excluir]

def firma_cs(params):
    """[(HV_x, tipo_sql)] -> ('long? idX, string? etapa', [(HV_x, tipo_sql, var)])"""
    out, ps = [], []
    for n, t in params:
        var = camel(n[3:])
        ps.append(f"{ {'bigint': 'long?', 'integer': 'int?', 'character varying': 'string?', 'character': 'string?', 'timestamp without time zone': 'DateTime?'}[t] } {var}")
        out.append((n, t, var))
    return ps, out

# ------------------------------------------------------------------ IRepo / ISrv
def gen_irepo(m):
    lp, _ = firma_cs(args_in(m["listar"], ("HV_Incluir_Eliminados",)))
    dp, _ = firma_cs(args_in(m["dropdown"]))
    D = "Dto_Catalogo_Universal"
    s = HDR(f"IRepo_{m['t']}.cs", "Infrastructure.Contracts/ControlAccesos/", "3 — Contracts", m["t"], m["hito"])
    s += f"""
using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_{m['t']}
{{
    Task<Result<List<{D}>>> ListarAsync({"".join(x + ", " for x in lp)}bool incluirEliminados = false, CancellationToken ct = default);
"""
    if not m["ro"]:
        s += f"""    Task<ResultSp<long>> CrearAsync({D} dto, long usuarioId, CancellationToken ct = default);
    Task<Result<{D}?>> DetalleAsync(long id, CancellationToken ct = default);
    Task<ResultSp> ActualizarAsync(long id, {D} dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> EliminarAsync(long id, long usuarioId, CancellationToken ct = default);
"""
    s += f"    Task<Result<List<{D}>>> ObtenerDropdownAsync({', '.join(dp + ['CancellationToken ct = default'])});\n}}\n"
    return s

def gen_isrv(m):
    lp, _ = firma_cs(args_in(m["listar"], ("HV_Incluir_Eliminados",)))
    dp, _ = firma_cs(args_in(m["dropdown"]))
    D = "Dto_Catalogo_Universal"
    s = HDR(f"ISrv_{m['t']}.cs", "Application.Contracts/ControlAccesos/", "3 — Contracts", m["t"], m["hito"])
    s += f"""
using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_{m['t']}
{{
    Task<Result<List<{D}>>> ListarAsync({"".join(x + ", " for x in lp)}bool incluirEliminados = false, CancellationToken ct = default);
"""
    if not m["ro"]:
        s += f"""    Task<Result<long>> CrearAsync({D} dto, long usuarioId, CancellationToken ct = default);
    Task<Result<{D}?>> DetalleAsync(long id, CancellationToken ct = default);
    Task<Result> ActualizarAsync(long id, {D} dto, long usuarioId, CancellationToken ct = default);
    Task<Result> EliminarAsync(long id, long usuarioId, CancellationToken ct = default);
"""
    s += f"    Task<Result<List<{D}>>> ObtenerDropdownAsync({', '.join(dp + ['CancellationToken ct = default'])});\n}}\n"
    return s

# ------------------------------------------------------------------ Repo
def gen_repo(m, P):
    D = "Dto_Catalogo_Universal"
    E, t = m["E"], m["t"]
    lp, lv = firma_cs(args_in(m["listar"], ("HV_Incluir_Eliminados",)))
    dp, dv = firma_cs(args_in(m["dropdown"]))
    s = HDR(f"Repo_{t}.cs", "Infrastructure.Repositories/ControlAccesos/", "4 — Repository", t, m["hito"])
    s += f"""// SP base  : ERP_CATALOGO_{E}_<ACCION>
// Conexión : {m['conn']}  (schema {m['schema']})
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_catalogos.py).
// ============================================================

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_{t} : RepoHelpers, IRepo_{t}
{{
    private readonly EjecutorSp _exec;
    private const string Conn = {m['conn']};

    public Repo_{t}(EjecutorSp exec) => _exec = exec;

    // ── LISTAR ────────────────────────────────────────────────────
    public async Task<Result<List<{D}>>> ListarAsync(
        {"".join(x + ", " for x in lp)}bool incluirEliminados = false, CancellationToken ct = default)
    {{
        try
        {{
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CATALOGO_{E}_LISTAR",
                bind: p =>
                {{
"""
    for n, tt, var in lv:
        s += f"                    {bind_param_simple(n, tt, var)}\n"
    s += f"""                    AddChar1(p, "HV_Incluir_Eliminados", incluirEliminados ? "Y" : "N");
                }},
                map: MapLista,
                ct: ct);
            return Result<List<{D}>>.Ok(lista);
        }}
        catch (Exception ex)
        {{
            return Result<List<{D}>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }}
    }}
"""
    if not m["ro"]:
        for nombre, rut, con_id, firma in (("CrearAsync", m["crear"], True, f"{D} dto, long usuarioId"),
                                           ("ActualizarAsync", m["actualizar"], False, f"long id, {D} dto, long usuarioId")):
            accion = "CREAR" if con_id else "ACTUALIZAR"
            tipo = "ResultSp<long>" if con_id else "ResultSp"
            ent = args_in(rut)
            llamada = "EjecutarEscrituraConIdAsync" if con_id else "EjecutarEscrituraAsync"
            col = ""
            if con_id:
                col_id = [n for modo, n, tt in rut["args"] if modo == "INOUT" and n.endswith("_Result")]
                assert len(col_id) == 1, rut["args"]
                col = f'\n            columnaId: "{col_id[0]}",'
            s += f"""
    // ── {accion} ─────────────────────────────────────────────────
    public async Task<{tipo}> {nombre}(
        {firma}, CancellationToken ct = default)
    {{
        return await _exec.{llamada}(
            clave: Conn,
            procedimiento: "ERP_CATALOGO_{E}_{accion}",{col}
            bind: p =>
            {{
"""
            for n, tt in ent:
                s += f"                {bind_linea('IN', n, tt, m, P, accion)}\n"
            s += """            },
            ct: ct);
    }
"""
        det = m["detalle"]
        s += f"""
    // ── DETALLE ───────────────────────────────────────────────────
    public async Task<Result<{D}?>> DetalleAsync(long id, CancellationToken ct = default)
    {{
        try
        {{
            var dato = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CATALOGO_{E}_DETALLE",
                bind: p => AddLongReq(p, "HV_{m['pk']}", id),
                map: MapDetalle,
                ct: ct);
            return Result<{D}?>.Ok(dato);
        }}
        catch (Exception ex)
        {{
            return Result<{D}?>.Fail(ex.InnerException?.Message ?? ex.Message);
        }}
    }}

    // ── ELIMINAR (borrado lógico) ─────────────────────────────────
    public async Task<ResultSp> EliminarAsync(long id, long usuarioId, CancellationToken ct = default)
    {{
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CATALOGO_{E}_ELIMINAR",
            bind: p =>
            {{
                AddLongReq(p, "HV_{m['pk']}", id);
                AddLongReq(p, "HV_UsuarioID_Update", usuarioId);
            }},
            ct: ct);
    }}
"""
    s += f"""
    // ── DROPDOWN (solo activos) ───────────────────────────────────
    public async Task<Result<List<{D}>>> ObtenerDropdownAsync({', '.join(dp + ['CancellationToken ct = default'])})
    {{
        try
        {{
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CATALOGO_{E}_DROPDOWN",
                bind: p =>
                {{
"""
    if dv:
        for n, tt, var in dv:
            s += f"                    {bind_param_simple(n, tt, var)}\n"
    else:
        s += "                    // sin parámetros\n"
    s += f"""                }},
                map: MapDropdown,
                ct: ct);
            return Result<List<{D}>>.Ok(lista);
        }}
        catch (Exception ex)
        {{
            return Result<List<{D}>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }}
    }}

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

"""
    s += mapper("MapLista", m["listar"]["cols"], P) + "\n"
    if not m["ro"]:
        s += mapper("MapDetalle", m["detalle"]["cols"], P) + "\n"
    s += mapper("MapDropdown", m["dropdown"]["cols"], P)
    s += "}\n"
    return s

# ------------------------------------------------------------------ Srv
def gen_srv(m):
    D = "Dto_Catalogo_Universal"
    t = m["t"]
    lp, lv = firma_cs(args_in(m["listar"], ("HV_Incluir_Eliminados",)))
    dp, dv = firma_cs(args_in(m["dropdown"]))
    la = "".join(f"{v}, " for _, _, v in lv)
    da = ", ".join(v for _, _, v in dv)
    s = HDR(f"Srv_{t}.cs", "Application.Services/ControlAccesos/", "5 — Service", t, m["hito"])
    s += f"""// Validación mínima de formulario (código y descripción). Las reglas de negocio viven en el SP
// (códigos 101/400/404): el servicio NO las duplica, solo traduce su respuesta.
// ============================================================

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_{t} : ISrv_{t}
{{
    private readonly IRepo_{t} _repo;
    private readonly ILogger<Srv_{t}> _logger;

    public Srv_{t}(IRepo_{t} repo, ILogger<Srv_{t}> logger)
    {{
        _repo = repo;
        _logger = logger;
    }}

    public async Task<Result<List<{D}>>> ListarAsync(
        {"".join(x + ", " for x in lp)}bool incluirEliminados = false, CancellationToken ct = default)
    {{
        try {{ return await _repo.ListarAsync({la}incluirEliminados, ct).ConfigureAwait(false); }}
        catch (Exception ex)
        {{
            _logger.LogError(ex, "LISTAR {t} ERROR");
            return Result<List<{D}>>.Fail(ex.Message);
        }}
    }}
"""
    if not m["ro"]:
        s += f"""
    public async Task<Result<long>> CrearAsync({D} dto, long usuarioId, CancellationToken ct = default)
    {{
        var errors = Validar(dto);
        if (errors.Count > 0)
            return Result<long>.Validation("Datos inválidos.", errors);

        try
        {{
            var sp = await _repo.CrearAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<long>.Ok(sp.Data, sp.Mensaje)
                : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }}
        catch (Exception ex)
        {{
            _logger.LogError(ex, "CREAR {t} ERROR UsuarioID={{UsuarioID}}", usuarioId);
            return Result<long>.Fail(ex.Message);
        }}
    }}

    public async Task<Result<{D}?>> DetalleAsync(long id, CancellationToken ct = default)
    {{
        try
        {{
            var r = await _repo.DetalleAsync(id, ct).ConfigureAwait(false);
            if (!r.Success) return r;
            if (r.Data is null)
                return Result<{D}?>.Fail("Registro no encontrado.", ResultCodes.NotFound);
            return r;
        }}
        catch (Exception ex)
        {{
            _logger.LogError(ex, "DETALLE {t} ERROR ID={{ID}}", id);
            return Result<{D}?>.Fail(ex.Message);
        }}
    }}

    public async Task<Result> ActualizarAsync(long id, {D} dto, long usuarioId, CancellationToken ct = default)
    {{
        var errors = Validar(dto);
        if (errors.Count > 0)
            return Result.Validation("Datos inválidos.", errors);

        try
        {{
            var sp = await _repo.ActualizarAsync(id, dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }}
        catch (Exception ex)
        {{
            _logger.LogError(ex, "ACTUALIZAR {t} ERROR ID={{ID}}", id);
            return Result.Fail(ex.Message);
        }}
    }}

    public async Task<Result> EliminarAsync(long id, long usuarioId, CancellationToken ct = default)
    {{
        try
        {{
            var sp = await _repo.EliminarAsync(id, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }}
        catch (Exception ex)
        {{
            _logger.LogError(ex, "ELIMINAR {t} ERROR ID={{ID}}", id);
            return Result.Fail(ex.Message);
        }}
    }}
"""
    s += f"""
    public async Task<Result<List<{D}>>> ObtenerDropdownAsync({', '.join(dp + ['CancellationToken ct = default'])})
    {{
        try {{ return await _repo.ObtenerDropdownAsync({da}{', ' if da else ''}ct).ConfigureAwait(false); }}
        catch (Exception ex)
        {{
            _logger.LogError(ex, "DROPDOWN {t} ERROR");
            return Result<List<{D}>>.Fail(ex.Message);
        }}
    }}
"""
    if not m["ro"]:
        s += f"""
    private static List<ResultError> Validar({D} dto)
    {{
        var errors = new List<ResultError>();
        if (string.IsNullOrWhiteSpace(dto.Codigo))
            errors.Add(new ResultError(nameof(dto.Codigo), "El Código es obligatorio."));
        if (string.IsNullOrWhiteSpace(dto.Descripcion))
            errors.Add(new ResultError(nameof(dto.Descripcion), "La Descripción es obligatoria."));
        return errors;
    }}
"""
    s += "}\n"
    return s

MAPEO = HDR("MapeoSp.cs", "Application.Services/ControlAccesos/", "5 — Service", "Compartido — traducción del contrato del SP", "0 y 1 — Catálogos") + """// Traduce HV_Codigo_Resp a los códigos de Result para que el controlador elija el HTTP adecuado.
// ============================================================

using Shared.Results;

namespace Application.Services.ControlAccesos;

public static class MapeoSp
{
    public static string Codigo(int codigoSp) => codigoSp switch
    {
        400 => ResultCodes.Validation,
        404 => ResultCodes.NotFound,
        _ => ResultCodes.Fail,
    };
}
"""

CSPROJ = {
 "Application.DTOs": ("", []),
 "Infrastructure.Contracts": ("", ["Application.DTOs", "Shared.Results"]),
 "Application.Contracts": ("", ["Application.DTOs", "Shared.Results"]),
 "Infrastructure.Repositories": ("", ["Infrastructure.Persistence", "Infrastructure.Contracts", "Application.DTOs", "Shared.Results"]),
 "Application.Services": ("fw", ["Application.Contracts", "Infrastructure.Contracts", "Application.DTOs", "Shared.Results"]),
}

def csproj(nombre):
    fw, refs = CSPROJ[nombre]
    s = """<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
"""
    if fw:
        s += """
  <ItemGroup>
    <!-- Da ILogger sin paquetes sueltos de Microsoft.Extensions.* -->
    <FrameworkReference Include="Microsoft.AspNetCore.App" />
  </ItemGroup>
"""
    if refs:
        s += "\n  <ItemGroup>\n" + "".join(f'    <ProjectReference Include="..\\{r}\\{r}.csproj" />\n' for r in refs) + "  </ItemGroup>\n"
    return s + "\n</Project>\n"

def escribir(base, proyecto, archivo, texto, sub=NS):
    d = os.path.join(base, proyecto, sub) if sub else os.path.join(base, proyecto)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, archivo), "w", encoding="utf-8", newline="\n") as f:
        f.write(texto)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(__doc__ if __doc__ else "uso: gen_capas_catalogos.py <firmas> <salida>")
    R = leer(sys.argv[1]); out = sys.argv[2]
    cats = [modelo(R, *c) for c in CATALOGOS]
    dto, P = gen_dto(cats)
    escribir(out, "Application.DTOs", "Dto_Catalogo_Universal.cs", dto)
    escribir(out, "Application.Services", "MapeoSp.cs", MAPEO)
    for m in cats:
        escribir(out, "Infrastructure.Contracts", f"IRepo_{m['t']}.cs", gen_irepo(m))
        escribir(out, "Application.Contracts", f"ISrv_{m['t']}.cs", gen_isrv(m))
        escribir(out, "Infrastructure.Repositories", f"Repo_{m['t']}.cs", gen_repo(m, P))
        escribir(out, "Application.Services", f"Srv_{m['t']}.cs", gen_srv(m))
        print("ok", m["t"])
    for p in CSPROJ:
        escribir(out, p, f"{p}.csproj", csproj(p), sub=None)
