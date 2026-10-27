// ============================================================
// Incidencias: faltas de personas que ingresaron. Dos pantallas sobre los mismos datos:
//  · Coordinador «Incidencias» (permiso INCIDENCIA_DECIDIR): todas, decidir (confirmar o desestimar) y registrar (queda confirmada).
//  · Vigilancia «Incidencias del día» (permiso INCIDENCIA_REGISTRAR): las de hoy y registrar (queda a la espera del coordinador).
// Las reglas (origen, estado, permisos, personas válidas) viven en los procedimientos.
// ============================================================

using System.Globalization;
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Shared.Results;
using Web.ControlAccesos.Models;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize, ExigirPermiso("PER_CAF_INCIDENCIA_DECIDIR", "PER_CAF_INCIDENCIA_REGISTRAR")]
public sealed class IncidenciasController : Controller
{
    private const string SedeCodigo = "VES";

    private readonly ISrv_Incidencia _inc;
    private readonly ISrv_Catalogo_Tipo_Incidencia _tipos;
    private readonly ISrv_Catalogo_Zona_Acceso _zonas;
    private readonly ISrv_Catalogo_Sede _sedes;

    public IncidenciasController(ISrv_Incidencia inc, ISrv_Catalogo_Tipo_Incidencia tipos, ISrv_Catalogo_Zona_Acceso zonas, ISrv_Catalogo_Sede sedes)
    {
        _inc = inc; _tipos = tipos; _zonas = zonas; _sedes = sedes;
    }

    // ── pantallas ──────────────────────────────────────────────────────────────────────────────
    /// <summary>Pantalla única de Incidencias. Con permiso de decidir (Coordinador) ve todas y decide; con solo registrar (Vigilancia) ve las de hoy.</summary>
    [HttpGet]
    public IActionResult Index()
    {
        ViewData["PuedeRegistrar"] = User.TienePermiso("PER_CAF_INCIDENCIA_REGISTRAR");
        ViewData["PuedeDecidir"] = User.TienePermiso("PER_CAF_INCIDENCIA_DECIDIR");
        return View();
    }

    /// <summary>Ruta anterior de «Incidencias del día»: ahora es la misma pantalla.</summary>
    [HttpGet]
    public IActionResult Dia() => RedirectToAction(nameof(Index));

    // ── datos ──────────────────────────────────────────────────────────────────────────────────
    /// <summary>hoy=true: solo las de hoy (pantalla de Vigilancia). Si no, se filtra por estado, texto y fechas.</summary>
    [HttpGet]
    public async Task<IActionResult> Lista(string? estado, string? texto, string? desde, string? hasta, bool hoy, CancellationToken ct)
    {
        var sede = await SedeIdAsync(ct);
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        var u = User.UsuarioId();
        var f = new Dto_Filtro_Incidencias { ID_Catalogo_Sede = sede.Value, Texto = Vacio(texto), Estado = Estado(estado) };
        if (!User.TienePermiso("PER_CAF_INCIDENCIA_DECIDIR")) hoy = true;   // Vigilancia solo ve las de hoy
        if (hoy) { f.Fecha_Desde = DateTime.Today; f.Fecha_Hasta = DateTime.Today; }
        else { f.Fecha_Desde = Fecha(desde); f.Fecha_Hasta = Fecha(hasta); }
        var r = await _inc.ListarAsync(u, f, ct);
        if (!r.Success) return Falla(r.Message);
        var c = await _inc.ContadoresAsync(u, sede.Value, ct);
        return Json(new
        {
            success = true,
            registradas = c.Success ? c.Data!.Registradas : 0,
            data = r.Data!.Select(i => new
            {
                id = i.ID_Incidencia, codigo = i.Codigo, fecha = i.Fecha_Hora_Hecho.ToString("yyyy-MM-dd"), hora = i.Fecha_Hora_Hecho.ToString("HH:mm"),
                tipo = i.Tipo_Descripcion, zona = i.Zona_Descripcion, lugar = i.Lugar_Detalle, descripcion = i.Descripcion, origen = i.Origen,
                registrador = i.Registrador_Nombre, estado = i.Estado, personas = i.Cantidad_Personas,
            })
        });
    }

    [HttpGet]
    public async Task<IActionResult> Detalle(long id, CancellationToken ct)
    {
        var u = User.UsuarioId();
        var r = await _inc.DetalleAsync(u, id, ct);
        if (!r.Success) return Falla(r.Message);
        var p = await _inc.PersonasListarAsync(u, id, ct);
        if (!p.Success) return Falla(p.Message);
        var d = r.Data!;
        return Json(new
        {
            success = true,
            data = new
            {
                id = d.ID_Incidencia, codigo = d.Codigo, fecha = d.Fecha_Hora_Hecho.ToString("yyyy-MM-dd"), hora = d.Fecha_Hora_Hecho.ToString("HH:mm"),
                tipo = d.Tipo_Descripcion, tipoDetalle = d.Tipo_Detalle, zona = d.Zona_Descripcion, lugar = d.Lugar_Detalle, descripcion = d.Descripcion,
                origen = d.Origen, registrador = d.Registrador_Nombre, estado = d.Estado, decisor = d.Decisor_Nombre,
                fechaDecision = d.Fecha_Decision?.ToString("yyyy-MM-dd HH:mm"), sustento = d.Sustento_Decision, puedeDecidir = d.Puede_Decidir,
                personas = p.Data!.Select(x => new { id = x.ID_Solicitud_Persona, nombre = x.Persona_Nombre, doc = x.Numero_Documento, empresa = x.Empresa_Visitante, solicitud = x.Codigo_Solicitud, estado = x.Estado_Persona }),
            }
        });
    }

    [HttpGet]
    public async Task<IActionResult> Opciones(CancellationToken ct)
    {
        var sede = await SedeIdAsync(ct);
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        var t = await _tipos.ListarAsync(false, ct);
        if (!t.Success) return Falla(t.Message);
        var z = await _zonas.ListarAsync(sede.Value, false, ct);
        if (!z.Success) return Falla(z.Message);
        return Json(new
        {
            success = true,
            data = new
            {
                tipos = t.Data!.Where(x => x.Activo == "Y").OrderBy(x => x.Orden).Select(x => new { id = x.ID_Catalogo, texto = x.Descripcion, esOtro = x.Es_Otro == "Y" }),
                zonas = z.Data!.Where(x => x.Activo == "Y").OrderBy(x => x.Orden).Select(x => new { id = x.ID_Catalogo, texto = x.Descripcion }),
            }
        });
    }

    /// <summary>Personas que ingresaron hoy (dentro o ya salieron) y coinciden con el texto.</summary>
    [HttpGet, ExigirPermiso("PER_CAF_INCIDENCIA_REGISTRAR")]
    public async Task<IActionResult> Personas(string? texto, CancellationToken ct)
    {
        var sede = await SedeIdAsync(ct);
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        var r = await _inc.PersonasBuscarAsync(User.UsuarioId(), new Dto_Filtro_Incidencia_Personas
        {
            ID_Catalogo_Sede = sede.Value, Fecha_Desde = DateTime.Today, Fecha_Hasta = DateTime.Today, Texto = Vacio(texto),
        }, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new
        {
            success = true,
            data = r.Data!.Where(p => p.Estado_Persona is "DENTRO" or "SALIO").Take(8)
                .Select(p => new { id = p.ID_Solicitud_Persona, nombre = p.Persona_Nombre, doc = p.Numero_Documento, empresa = p.Empresa_Visitante, solicitud = p.Codigo_Solicitud, estado = p.Estado_Persona })
        });
    }

    // ── escritura ──────────────────────────────────────────────────────────────────────────────
    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso("PER_CAF_INCIDENCIA_REGISTRAR")]
    public async Task<IActionResult> Registrar([FromBody] IncidenciaVM m, CancellationToken ct)
    {
        var sede = await SedeIdAsync(ct);
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        if (!TimeSpan.TryParseExact((m.Hora ?? string.Empty).Trim(), "hh\\:mm", CultureInfo.InvariantCulture, out var h)) return Falla("Indique la hora aproximada.");
        var r = await _inc.RegistrarAsync(new Dto_Incidencia_Registrar
        {
            ID_Catalogo_Sede = sede.Value, ID_Catalogo_Tipo_Incidencia = m.TipoId, Tipo_Detalle = Vacio(m.TipoDetalle),
            Fecha_Hora_Hecho = DateTime.Today.Add(h), ID_Catalogo_Zona_Acceso = m.ZonaId, Lugar_Detalle = Vacio(m.LugarDetalle),
            Descripcion = (m.Descripcion ?? string.Empty).Trim(), IDs_Solicitud_Persona = m.PersonasIds ?? new(),
        }, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r), data = r.Success ? new { id = r.Data!.ID_Incidencia, codigo = r.Data.Codigo } : null });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso("PER_CAF_INCIDENCIA_DECIDIR")]
    public async Task<IActionResult> Decidir([FromBody] IncidenciaDecisionVM m, CancellationToken ct)
    {
        var r = await _inc.DecidirAsync(new Dto_Incidencia_Decision
        {
            ID_Incidencia = m.Id, Decision = m.Decision == "CONFIRMAR" ? "CONFIRMAR" : "DESESTIMAR", Sustento = (m.Sustento ?? string.Empty).Trim(),
        }, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    // ── apoyo ──────────────────────────────────────────────────────────────────────────────────
    private async Task<long?> SedeIdAsync(CancellationToken ct)
    {
        var l = await _sedes.ListarAsync(false, ct);
        var s = l.Success ? l.Data!.FirstOrDefault(x => x.Codigo == SedeCodigo) : null;
        return s?.ID_Catalogo;
    }
    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });
    private static string? Vacio(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
    private static string? Estado(string? e) => e is "REGISTRADA" or "CONFIRMADA" or "DESESTIMADA" ? e : null;
    private static DateTime? Fecha(string? t) => DateTime.TryParseExact(t, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d : null;
    private static object Errores(Result r) => r.Errors.Select(e => new { field = e.Field, message = e.Message });
}
