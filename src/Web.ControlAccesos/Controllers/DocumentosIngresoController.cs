// ============================================================
// D-265. «Documentos de ingreso»: Vigilancia sube, después de registrar entradas y salidas, los documentos del día
// (guías, listas de equipos o herramientas; casi siempre PDF escaneado) y los asocia a una o varias personas que ingresaron.
//   Subir / asignar / quitar : PER_CAF_PORTERIA_REGISTRAR (solo Vigilancia; lo vuelve a exigir el procedimiento)
//   Consultar                : PER_CAF_DOC_INGRESO_CONSULTAR (D-272, licencia aparte); solo consulta. Almacén no tiene acceso
// PER_CAF_PORTERIA_VER no basta (lo tiene quien solo ve el tablero).
// ============================================================

using System.Globalization;
using Application.Contracts.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Shared.Results;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize, ExigirPermiso(PermSubir, PermConsultar)]
public sealed class DocumentosIngresoController : Controller
{
    private const string SedeCodigo = "VES";
    private const string PermSubir = "PER_CAF_PORTERIA_REGISTRAR";
    private const string PermConsultar = "PER_CAF_DOC_INGRESO_CONSULTAR";   // D-272: licencia aparte para consultar (no sube)
    private const long MaxBytes = (long)ValidadorDocumentosIngreso.MaxMbAbsoluto * 1024 * 1024;

    private readonly ISrv_Documento_Ingreso _doc;
    private readonly ISrv_Catalogo_Sede _sedes;

    public DocumentosIngresoController(ISrv_Documento_Ingreso doc, ISrv_Catalogo_Sede sedes) { _doc = doc; _sedes = sedes; }

    [HttpGet]
    public IActionResult Index()
    {
        ViewData["PuedeSubir"] = User.TienePermiso(PermSubir);
        return View();
    }

    [HttpGet]
    public async Task<IActionResult> Datos(string? fecha, CancellationToken ct)
    {
        var (sede, f) = await ContextoAsync(fecha, ct);
        if (sede is null) return Falla("No se encontró la sede.");
        var res = await _doc.ResumenAsync(User.UsuarioId(), sede.Value, f, ct);
        var lis = await _doc.ListarAsync(User.UsuarioId(), sede.Value, f, ct);
        if (!res.Success) return Falla(res.Message);
        if (!lis.Success) return Falla(lis.Message);
        return Json(new
        {
            success = true,
            fecha = f.ToString("yyyy-MM-dd"),
            resumen = res.Data,
            documentos = lis.Data!.Select(d => new
            {
                id = d.ID_Documento_Ingreso, tipo = d.Tipo, nombre = d.Nombre_Archivo, extension = d.Extension, bytes = d.Tamano_Bytes,
                subido = d.Fecha_Subida.ToString("yyyy-MM-dd HH:mm"), por = d.Subido_Por, puedeModificar = d.Puede_Modificar,
                personas = ParsePersonas(d.Personas),
            }),
        });
    }

    /// <summary>D-269: consulta por rango de días y texto (persona, documento, solicitud, empresa o archivo). Sin fechas: últimos 30 días.</summary>
    [HttpGet]
    public async Task<IActionResult> Buscar(string? desde, string? hasta, string? q, CancellationToken ct)
    {
        var (sede, _) = await ContextoAsync(null, ct);
        if (sede is null) return Falla("No se encontró la sede.");
        var d = DateTime.TryParseExact(desde, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d1) ? d1 : (DateTime?)null;
        var h = DateTime.TryParseExact(hasta, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var h1) ? h1 : (DateTime?)null;
        var r = await _doc.BuscarAsync(User.UsuarioId(), sede.Value, d, h, q, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new
        {
            success = true,
            data = r.Data!.Select(x => new
            {
                id = x.ID_Documento_Ingreso, fecha = x.Fecha_Registro.ToString("yyyy-MM-dd"), tipo = x.Tipo, nombre = x.Nombre_Archivo, extension = x.Extension, bytes = x.Tamano_Bytes,
                subido = x.Fecha_Subida.ToString("yyyy-MM-dd HH:mm"), por = x.Subido_Por, personas = ParsePersonas(x.Personas),
            }),
        });
    }

    /// <summary>Autocompletar: personas que ingresaron ese día. Con soloEquipos=Y solo las que trajeron equipos o herramientas.</summary>
    [HttpGet]
    public async Task<IActionResult> Personas(string? fecha, string? q, string? soloEquipos, CancellationToken ct)
    {
        var (sede, f) = await ContextoAsync(fecha, ct);
        if (sede is null) return Falla("No se encontró la sede.");
        var r = await _doc.PersonasDiaAsync(User.UsuarioId(), sede.Value, f, q, soloEquipos != "N", ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new
        {
            success = true,
            data = r.Data!.Select(p => new
            {
                id = p.ID_Solicitud_Persona, nombre = p.Nombre, documento = p.Documento, solicitud = p.Solicitud, empresa = p.Empresa,
                equipos = p.Trae_Equipos, herramientas = p.Trae_Herramientas, documentos = p.Documentos,
            }),
        });
    }

    /// <summary>Sube UN archivo (la pantalla los sube de a uno para mostrar el avance de cada uno). Personas = ids separados por coma.</summary>
    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermSubir)]
    [RequestSizeLimit(MaxBytes + 1024 * 1024)]
    [RequestFormLimits(MultipartBodyLengthLimit = MaxBytes + 1024 * 1024)]
    public async Task<IActionResult> Subir(string? fecha, string? tipo, string? personas, IFormFile? archivo, CancellationToken ct)
    {
        var (sede, f) = await ContextoAsync(fecha, ct);
        if (sede is null) return Falla("No se encontró la sede.");
        if (archivo is null || archivo.Length == 0) return Falla("Elija un archivo.");
        if (archivo.Length > MaxBytes) return Falla($"El archivo supera el máximo de {ValidadorDocumentosIngreso.MaxMbAbsoluto} MB.");
        byte[] bytes;
        await using (var ms = new MemoryStream((int)archivo.Length))
        {
            await archivo.CopyToAsync(ms, ct);
            bytes = ms.ToArray();
        }
        var r = await _doc.AgregarAsync(sede.Value, f, tipo ?? string.Empty, archivo.FileName, bytes, Ids(personas), User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r), id = r.Success ? r.Data : 0 });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermSubir)]
    public async Task<IActionResult> Asignar([FromBody] AsignarDocIngresoVM m, CancellationToken ct)
    {
        var r = await _doc.AsignarPersonasAsync(m.Id, m.Personas ?? new List<long>(), User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermSubir)]
    public async Task<IActionResult> Quitar([FromBody] QuitarDocIngresoVM m, CancellationToken ct)
    {
        var r = await _doc.QuitarAsync(m.Id, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    [HttpGet]
    public async Task<IActionResult> Descargar(long id, CancellationToken ct)
    {
        var r = await _doc.ObtenerAsync(User.UsuarioId(), id, ct);
        if (!r.Success || r.Data is null) return NotFound();
        var tipo = r.Data.Extension.ToLowerInvariant() switch { "pdf" => "application/pdf", "png" => "image/png", _ => "image/jpeg" };
        Response.Headers["X-Content-Type-Options"] = "nosniff";
        return File(r.Data.Contenido, tipo, r.Data.Nombre_Archivo);
    }

    /// <summary>Bloque «Documentos de ingreso» del detalle de una solicitud (Almacén y Vigilancia).</summary>
    [HttpGet]
    public async Task<IActionResult> DeSolicitud(long id, CancellationToken ct)
    {
        var r = await _doc.DeSolicitudAsync(User.UsuarioId(), id, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new
        {
            success = true,
            data = r.Data!.Select(d => new
            {
                id = d.ID_Documento_Ingreso, tipo = d.Tipo, nombre = d.Nombre_Archivo, extension = d.Extension, bytes = d.Tamano_Bytes,
                fecha = d.Fecha_Registro.ToString("yyyy-MM-dd"), por = d.Subido_Por,
                personas = (d.Personas ?? string.Empty).Split('|', StringSplitOptions.RemoveEmptyEntries),
            }),
        });
    }

    // ── auxiliares ──────────────────────────────────────────────
    private async Task<(long? sede, DateTime fecha)> ContextoAsync(string? fecha, CancellationToken ct)
    {
        var f = DateTime.TryParseExact(fecha, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d.Date : DateTime.Today;
        var l = await _sedes.ListarAsync(false, ct);
        var s = l.Success ? l.Data!.FirstOrDefault(x => x.Codigo == SedeCodigo) : null;
        return (s?.ID_Catalogo, f);
    }

    private static IEnumerable<long> Ids(string? csv)
        => (csv ?? string.Empty).Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(x => long.TryParse(x, out var n) ? n : 0).Where(n => n > 0);

    /// <summary>«id~Apellidos, Nombres~Documento~SOL-xxxx~Empresa» separados por «|» → objetos para la pantalla.</summary>
    private static object ParsePersonas(string? t) => (t ?? string.Empty).Split('|', StringSplitOptions.RemoveEmptyEntries).Select(x =>
    {
        var p = x.Split('~');
        return new { id = p.Length > 0 ? p[0] : "", nombre = p.Length > 1 ? p[1] : "", documento = p.Length > 2 ? p[2] : "", solicitud = p.Length > 3 ? p[3] : "", empresa = p.Length > 4 ? p[4] : "" };
    }).ToList();

    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });
    private static object Errores(Result r) => r.Errors.Select(e => new { field = e.Field, message = e.Message });
}

public sealed class AsignarDocIngresoVM { public long Id { get; set; } public List<long>? Personas { get; set; } }
public sealed class QuitarDocIngresoVM { public long Id { get; set; } }
