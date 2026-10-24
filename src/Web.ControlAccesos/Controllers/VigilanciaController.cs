// ============================================================
// Pantalla de Vigilancia «Control de accesos»: quién espera hoy, quién está dentro, ingreso y salida con checklist.
// Las reglas (checklist completo, respaldo previo de equipos/herramientas, desviación y su efecto, registro tardío)
// viven en los procedimientos; aquí solo se arman los datos de la pantalla y se reenvía lo que Vigilancia marcó.
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

[Authorize, ExigirPermiso("PER_CAF_PORTERIA_VER", "PER_CAF_PORTERIA_REGISTRAR")]
public sealed class VigilanciaController : Controller
{
    private const string SedeCodigo = "VES";
    private const string PermRegistrar = "PER_CAF_PORTERIA_REGISTRAR";

    private readonly ISrv_Solicitud_Vigilancia _vig;
    private readonly ISrv_Porteria _por;
    private readonly ISrv_Respaldo _res;
    private readonly ISrv_Desviacion _des;
    private readonly ISrv_Catalogo_Sede _sedes;

    public VigilanciaController(ISrv_Solicitud_Vigilancia vig, ISrv_Porteria por, ISrv_Respaldo res, ISrv_Desviacion des, ISrv_Catalogo_Sede sedes)
    {
        _vig = vig; _por = por; _res = res; _des = des; _sedes = sedes;
    }

    [HttpGet]
    public IActionResult Index()
    {
        ViewData["PuedeRegistrar"] = User.TienePermiso(PermRegistrar);
        ViewData["PuedeIncidencia"] = User.TienePermiso("PER_CAF_INCIDENCIA_REGISTRAR");
        return View();
    }

    /// <summary>Todas las personas esperadas hoy que calzan con el texto; la pantalla las reparte por grupo y cuenta.</summary>
    [HttpGet]
    public async Task<IActionResult> Lista(string? texto, CancellationToken ct)
    {
        var r = await _vig.ListarAsync(User.UsuarioId(), new Dto_Filtro_Vigilancia { Texto = Vacio(texto) }, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new
        {
            success = true,
            data = r.Data!.Select(p => new
            {
                id = p.ID_Solicitud_Persona, solicitudId = p.ID_Solicitud, codigo = p.Codigo, fecha = p.Fecha_Hora_Prevista.ToString("yyyy-MM-dd"), hora = p.Fecha_Hora_Prevista.ToString("HH:mm"),
                empresa = p.Empresa_Visitante, atiende = p.Responsable_Nombre, tipoDoc = p.Tipo_Documento, doc = p.Numero_Documento,
                nombre = p.Persona_Nombre, estado = p.Estado, grupo = p.Grupo, ingreso = Hora(p.Fecha_Hora_Ingreso), salida = Hora(p.Fecha_Hora_Salida),
                restringido = p.Acceso_Restringido, traeEquipos = p.Trae_Equipos, traeHerramientas = p.Trae_Herramientas,
                exigeSctr = p.Exige_SCTR, exigeEpp = p.Exige_EPP, zonas = p.Zonas_Nombres,
            })
        });
    }

    /// <summary>Solo consulta: personas aprobadas de cualquier fecha (por defecto desde hoy). No permite registrar nada.</summary>
    [HttpGet]
    public async Task<IActionResult> Aprobadas(string? texto, string? desde, string? hasta, CancellationToken ct)
    {
        var r = await _vig.AprobadasListarAsync(User.UsuarioId(), new Dto_Filtro_Vigilancia_Aprobadas
        {
            Texto = Vacio(texto), Fecha_Desde = Fecha(desde), Fecha_Hasta = Fecha(hasta),
        }, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new
        {
            success = true,
            limite = r.Data!.Count >= 500,
            data = r.Data!.Select(p => new
            {
                id = p.ID_Solicitud_Persona, solicitudId = p.ID_Solicitud, codigo = p.Codigo, fecha = p.Fecha_Hora_Prevista.ToString("yyyy-MM-dd"), hora = p.Fecha_Hora_Prevista.ToString("HH:mm"),
                empresa = p.Empresa_Visitante, atiende = p.Responsable_Nombre, tipoDoc = p.Tipo_Documento, doc = p.Numero_Documento,
                nombre = p.Persona_Nombre, estado = p.Estado, grupo = p.Grupo, ingreso = Hora(p.Fecha_Hora_Ingreso), salida = Hora(p.Fecha_Hora_Salida),
                restringido = p.Acceso_Restringido, traeEquipos = p.Trae_Equipos, traeHerramientas = p.Trae_Herramientas,
                exigeSctr = p.Exige_SCTR, exigeEpp = p.Exige_EPP, zonas = p.Zonas_Nombres,
            })
        });
    }

    /// <summary>Quien aparece en la búsqueda pero no está autorizado para hoy, con el motivo.</summary>
    [HttpGet]
    public async Task<IActionResult> NoAutorizada(string? texto, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(texto)) return Json(new { success = true, data = Array.Empty<object>() });
        var sede = await SedeIdAsync(ct);
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        var r = await _vig.NoAutorizadaBuscarAsync(User.UsuarioId(), sede.Value, DateTime.Today, texto.Trim(), ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new
        {
            success = true,
            data = r.Data!.Select(n => new { codigo = n.Codigo, nombre = n.Persona_Nombre, doc = n.Numero_Documento, empresa = n.Empresa_Visitante, motivoCodigo = n.Motivo_Codigo, motivo = n.Motivo_Texto })
        });
    }

    /// <summary>Lo que necesita la ventana de movimiento: ficha con botones permitidos, respaldos y, para el ingreso, las listas de desviación.</summary>
    [HttpGet]
    public async Task<IActionResult> Ficha(long id, CancellationToken ct)
    {
        var u = User.UsuarioId();
        var f = await _por.FichaAsync(u, id, ct);
        if (!f.Success) return Falla(f.Message);
        var res = await _res.ListarPorPersonaAsync(u, id, ct);
        if (!res.Success) return Falla(res.Message);
        var x = f.Data!;
        return Json(new
        {
            success = true,
            data = new
            {
                id = x.ID_Solicitud_Persona, codigo = x.Codigo, hora = x.Fecha_Hora_Prevista.ToString("HH:mm"), empresa = x.Empresa_Visitante, atiende = x.Responsable_Nombre,
                tipoDoc = x.Tipo_Documento, doc = x.Numero_Documento, nombre = x.Persona_Nombre, estado = x.Estado,
                ingreso = Hora(x.Fecha_Hora_Ingreso), salida = Hora(x.Fecha_Hora_Salida), restringido = x.Acceso_Restringido,
                traeEquipos = x.Trae_Equipos, traeHerramientas = x.Trae_Herramientas, exigeSctr = x.Exige_SCTR, exigeEpp = x.Exige_EPP, zonas = x.Zonas_Nombres,
                respaldoEquipos = x.Tiene_Respaldo_Equipos, respaldoHerramientas = x.Tiene_Respaldo_Herramientas,
                puedeIngreso = x.Puede_Registrar_Ingreso, motivoNoIngreso = x.Motivo_No_Ingreso, puedeIngresoTardio = x.Puede_Registrar_Ingreso_Tardio,
                puedeSalida = x.Puede_Registrar_Salida, motivoNoSalida = x.Motivo_No_Salida,
                respaldos = res.Data!.Select(r => new { id = r.ID_Respaldo, categoria = r.Categoria, tipo = r.Tipo_Respaldo, numero = r.Numero_Documento, hora = r.Fecha_Hora.ToString("HH:mm"), vigilante = r.Vigilante_Nombre, personas = r.Cantidad_Personas }),
            }
        });
    }

    /// <summary>Ítems del checklist que aplican (para el ingreso dependen de lo que la persona trae).</summary>
    [HttpGet]
    public async Task<IActionResult> Checklist(long id, string etapa, bool equipos, bool herramientas, CancellationToken ct)
    {
        var e = (etapa ?? string.Empty).ToUpperInvariant();
        if (e != "INGRESO" && e != "SALIDA") return Falla("Etapa no válida.");
        var r = await _por.ChecklistObtenerAsync(User.UsuarioId(), id, e, equipos, herramientas, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new { success = true, data = r.Data!.Select(i => new { id = i.ID_Catalogo_Item_Checklist, codigo = i.Codigo, texto = i.Descripcion, ayuda = i.Ayuda, critico = i.Es_Critico }) });
    }

    /// <summary>Coordinadores consultables y tratamientos válidos para la etapa (se piden solo si hay un ítem sin cumplir).</summary>
    [HttpGet]
    public async Task<IActionResult> OpcionesDesviacion(string etapa, CancellationToken ct)
    {
        var e = (etapa ?? string.Empty).ToUpperInvariant();
        if (e != "INGRESO" && e != "SALIDA") return Falla("Etapa no válida.");
        var sede = await SedeIdAsync(ct);
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        var u = User.UsuarioId();
        var c = await _des.CoordinadoresDropdownAsync(u, sede.Value, ct);
        if (!c.Success) return Falla(c.Message);
        var t = await _des.TratamientosDropdownAsync(e, ct);
        if (!t.Success) return Falla(t.Message);
        return Json(new
        {
            success = true,
            data = new
            {
                coordinadores = c.Data!.Select(x => new { id = x.ID_Usuario, texto = x.Nombre }),
                tratamientos = t.Data!.Select(x => new { id = x.ID_Catalogo_Tratamiento_Desviacion, codigo = x.Codigo, texto = x.Descripcion, esOtro = x.Es_Otro, resultado = x.Resultado }),
            }
        });
    }

    /// <summary>Movimientos de hoy de la persona, con el checklist de cada uno.</summary>
    [HttpGet]
    public async Task<IActionResult> Detalle(long id, CancellationToken ct)
    {
        var u = User.UsuarioId();
        var f = await _por.FichaAsync(u, id, ct);
        if (!f.Success) return Falla(f.Message);
        var x = f.Data!;
        var mov = await _por.MovimientosListarAsync(u, new Dto_Filtro_Movimientos
        {
            ID_Catalogo_Sede = x.ID_Catalogo_Sede, Fecha_Desde = x.Fecha_Hora_Prevista.Date, Fecha_Hasta = x.Fecha_Hora_Prevista.Date, Texto = x.Numero_Documento,
        }, ct);
        if (!mov.Success) return Falla(mov.Message);
        var regs = new List<object>();
        foreach (var m in mov.Data!.Where(m => m.ID_Solicitud_Persona == id).OrderBy(m => m.Fecha_Hora))
        {
            var it = await _por.RegistroChecklistListarAsync(u, m.ID_Registro_Acceso, ct);
            regs.Add(new
            {
                id = m.ID_Registro_Acceso, tipo = m.Tipo_Movimiento, resultado = m.Resultado, hora = m.Fecha_Hora.ToString("HH:mm"), tardio = m.Es_Registro_Tardio,
                vigilante = m.Vigilante_Nombre, observacion = m.Observacion, desviacion = m.Codigo_Desviacion,
                items = it.Success ? it.Data!.Select(i => (object)new { texto = i.Descripcion, cumple = i.Cumple, critico = i.Es_Critico }).ToList() : new List<object>(),
            });
        }
        return Json(new { success = true, data = regs });
    }

    // ── escritura ──────────────────────────────────────────────────────────────────────────────
    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermRegistrar)]
    public async Task<IActionResult> RespaldoRegistrar([FromBody] RespaldoVM m, CancellationToken ct)
    {
        var r = await _res.RegistrarAsync(new Dto_Respaldo_Registrar
        {
            Categoria = m.Categoria ?? string.Empty, Tipo_Respaldo = m.Tipo ?? string.Empty, Numero_Documento = Vacio(m.Numero),
            IDs_Solicitud_Persona = m.PersonasIds, Observacion = Vacio(m.Observacion),
        }, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Success ? "Respaldo registrado." : r.Message, errors = Errores(r) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermRegistrar)]
    public async Task<IActionResult> Ingreso([FromBody] MovimientoVM m, CancellationToken ct)
    {
        var fh = FechaHecho(m, out var errFecha);
        if (errFecha is not null) return Falla(errFecha);
        var r = await _por.IngresoRegistrarAsync(new Dto_Porteria_Ingreso
        {
            ID_Solicitud_Persona = m.PersonaId, Items = Items(m), Trae_Equipos = m.TraeEquipos, Trae_Herramientas = m.TraeHerramientas,
            Observacion = Vacio(m.Observacion), Desviacion = Desv(m), Fecha_Hora_Hecho = fh,
        }, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r), data = r.Success ? new { registroId = r.Data!.ID_Registro_Acceso, desviacionId = r.Data.ID_Desviacion, resultado = r.Data.Resultado } : null });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermRegistrar)]
    public async Task<IActionResult> Salida([FromBody] MovimientoVM m, CancellationToken ct)
    {
        var fh = FechaHecho(m, out var errFecha);
        if (errFecha is not null) return Falla(errFecha);
        var r = await _por.SalidaRegistrarAsync(new Dto_Porteria_Salida
        {
            ID_Solicitud_Persona = m.PersonaId, Items = Items(m), Observacion = Vacio(m.Observacion), Desviacion = Desv(m), Fecha_Hora_Hecho = fh,
        }, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r), data = r.Success ? new { registroId = r.Data!.ID_Registro_Acceso, desviacionId = r.Data.ID_Desviacion, resultado = r.Data.Resultado } : null });
    }

    // ── apoyo ──────────────────────────────────────────────────────────────────────────────────
    private static List<Dto_Porteria_Respuesta> Items(MovimientoVM m)
        => m.Items.Select(i => new Dto_Porteria_Respuesta { ID_Catalogo_Item_Checklist = i.Id, Cumple = i.Cumple }).ToList();

    private static Dto_Porteria_Desviacion_Entrada? Desv(MovimientoVM m)
        => m.Desviacion is null ? null : new Dto_Porteria_Desviacion_Entrada
        {
            Descripcion = Vacio(m.Desviacion.Descripcion), ID_Coordinador = m.Desviacion.CoordinadorId, ID_Tratamiento = m.Desviacion.TratamientoId,
            Tratamiento_Detalle = Vacio(m.Desviacion.TratamientoDetalle), Resultado_Elegido = Vacio(m.Desviacion.ResultadoElegido),
        };

    /// <summary>Registro tardío: la hora real viene como HH:mm del día de hoy; sin hora es un registro en vivo.</summary>
    private static DateTime? FechaHecho(MovimientoVM m, out string? error)
    {
        error = null;
        if (string.IsNullOrWhiteSpace(m.HoraReal)) return null;
        if (!TimeSpan.TryParseExact(m.HoraReal.Trim(), "hh\\:mm", CultureInfo.InvariantCulture, out var t)) { error = "La hora real no es válida."; return null; }
        return DateTime.Today.Add(t);
    }

    private async Task<long?> SedeIdAsync(CancellationToken ct)
    {
        var l = await _sedes.ListarAsync(false, ct);
        var s = l.Success ? l.Data!.FirstOrDefault(x => x.Codigo == SedeCodigo) : null;
        return s?.ID_Catalogo;
    }

    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });
    private static string? Vacio(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
    private static DateTime? Fecha(string? t) => DateTime.TryParseExact(t, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d : null;
    private static string? Hora(DateTime? d) => d?.ToString("HH:mm");
    private static object Errores(Result r) => r.Errors.Select(e => new { field = e.Field, message = e.Message });
}
