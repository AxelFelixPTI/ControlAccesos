// ============================================================
// Pantalla del coordinador «Reporte de accesos»: cada fila es un movimiento en portería (reemplaza el registro en papel G-FSCA-008).
// Filtra por fechas, persona/DNI/empresa, tipo de movimiento y «solo con desviación»; exporta lo que se ve a un archivo CSV (se abre en Excel).
// Los permisos y el rango máximo (92 días) los valida el procedimiento; aquí solo se arman los filtros.
// ============================================================

using System.Globalization;
using System.Text;
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize, ExigirPermiso("PER_CAF_REPORTE_VER")]
public sealed class ReportesController : Controller
{
    private const string SedeCodigo = "VES";
    private const int MaxFilasPantalla = 1000;
    private const int MaxDias = 92;

    private readonly ISrv_Reporte _rep;
    private readonly ISrv_Catalogo_Sede _sedes;

    public ReportesController(ISrv_Reporte rep, ISrv_Catalogo_Sede sedes) { _rep = rep; _sedes = sedes; }

    [HttpGet] public IActionResult Index() => View();

    [HttpGet]
    public async Task<IActionResult> Lista(string? desde, string? hasta, string? texto, string? tipo, bool soloDesviacion, CancellationToken ct)
    {
        var b = await BuscarAsync(desde, hasta, texto, tipo, soloDesviacion, ct);
        if (b.Error is not null) return Json(new { success = false, message = b.Error });
        var filas = b.Filas!;
        return Json(new
        {
            success = true,
            total = filas.Count,
            truncado = filas.Count > MaxFilasPantalla,
            desde = b.Desde!.Value.ToString("yyyy-MM-dd"),
            hasta = b.Hasta!.Value.ToString("yyyy-MM-dd"),
            resumen = b.Resumen,
            data = filas.Take(MaxFilasPantalla).Select(a => new
            {
                id = a.ID_Registro_Acceso, fecha = a.Fecha_Hora.ToString("yyyy-MM-dd"), hora = a.Fecha_Hora.ToString("HH:mm"),
                tipo = a.Tipo_Movimiento, resultado = a.Resultado, tardio = a.Es_Registro_Tardio,
                solicitud = a.Codigo_Solicitud, persona = a.Persona_Nombre, doc = a.Numero_Documento, empresa = a.Empresa_Visitante,
                zonas = a.Zonas, vigilante = a.Vigilante_Nombre, incumplidos = a.Items_Incumplidos,
                desviacion = a.Codigo_Desviacion, estadoDesviacion = a.Estado_Desviacion, observacion = a.Observacion,
            })
        });
    }

    /// <summary>Descarga un CSV con los mismos filtros de la pantalla (todas las filas, sin el tope de pantalla).</summary>
    [HttpGet]
    public async Task<IActionResult> Exportar(string? desde, string? hasta, string? texto, string? tipo, bool soloDesviacion, CancellationToken ct)
    {
        var b = await BuscarAsync(desde, hasta, texto, tipo, soloDesviacion, ct);
        if (b.Error is not null) return BadRequest(b.Error);
        var sb = new StringBuilder();
        sb.Append("Fecha,Hora,Movimiento,Resultado,Registro tardío,Persona,Documento,Empresa,Solicitud,Zonas,Vigilante,Ítems incumplidos,Desviación,Estado de la desviación,Observación\r\n");
        foreach (var a in b.Filas!)
        {
            sb.Append(string.Join(',', new[]
            {
                Csv(a.Fecha_Hora.ToString("yyyy-MM-dd")), Csv(a.Fecha_Hora.ToString("HH:mm")),
                Csv(a.Tipo_Movimiento == "INGRESO" ? "Ingreso" : "Salida"), Csv(Resultado(a.Resultado)), Csv(a.Es_Registro_Tardio ? "Sí" : "No"),
                Csv(a.Persona_Nombre), Csv((a.Tipo_Documento + " " + a.Numero_Documento).Trim()), Csv(a.Empresa_Visitante), Csv(a.Codigo_Solicitud),
                Csv(a.Zonas), Csv(a.Vigilante_Nombre), Csv(a.Items_Incumplidos.ToString(CultureInfo.InvariantCulture)),
                Csv(a.Codigo_Desviacion), Csv(EstadoDesv(a.Estado_Desviacion)), Csv(a.Observacion),
            })).Append("\r\n");
        }
        var bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(sb.ToString())).ToArray();
        var nombre = "accesos_" + SedeCodigo + "_" + b.Desde!.Value.ToString("yyyyMMdd") + "_" + b.Hasta!.Value.ToString("yyyyMMdd") + ".csv";
        return File(bytes, "text/csv; charset=utf-8", nombre);
    }

    // ── apoyo ──────────────────────────────────────────────────────────────────────────────────
    private sealed record Busqueda(string? Error, List<Dto_Reporte_Acceso>? Filas, object? Resumen, DateTime? Desde, DateTime? Hasta);

    private async Task<Busqueda> BuscarAsync(string? desde, string? hasta, string? texto, string? tipo, bool soloDesviacion, CancellationToken ct)
    {
        var d = Fecha(desde); var h = Fecha(hasta);
        if (d is null || h is null) return new("Indique las fechas «Desde» y «Hasta».", null, null, null, null);
        if (h < d) return new("«Hasta» no puede ser anterior a «Desde».", null, null, null, null);
        if ((h.Value - d.Value).TotalDays > MaxDias) return new("El rango máximo es de " + MaxDias + " días.", null, null, null, null);
        var sede = await SedeIdAsync(ct);
        if (sede is null) return new("No se encontró la sede " + SedeCodigo + ".", null, null, null, null);
        var u = User.UsuarioId();
        var t = tipo is "INGRESO" or "SALIDA" ? tipo : null;
        var r = await _rep.AccesosAsync(u, new Dto_Filtro_Reporte_Accesos { ID_Catalogo_Sede = sede.Value, Fecha_Desde = d.Value, Fecha_Hasta = h.Value, Tipo = t, Texto = Vacio(texto) }, ct);
        if (!r.Success) return new(r.Message, null, null, null, null);
        var filas = r.Data!.Where(a => !soloDesviacion || a.Codigo_Desviacion is not null).OrderByDescending(a => a.Fecha_Hora).ThenByDescending(a => a.ID_Registro_Acceso).ToList();
        var res = await _rep.ResumenDiarioAsync(u, new Dto_Filtro_Reporte_Rango { ID_Catalogo_Sede = sede.Value, Fecha_Desde = d.Value, Fecha_Hasta = h.Value }, ct);
        object resumen = res.Success
            ? new
            {
                ingresos = res.Data!.Sum(x => x.Ingresos), restringidos = res.Data!.Sum(x => x.Ingresos_Restringidos), denegados = res.Data!.Sum(x => x.Ingresos_Denegados),
                salidas = res.Data!.Sum(x => x.Salidas), desviaciones = res.Data!.Sum(x => x.Desviaciones), incidencias = res.Data!.Sum(x => x.Incidencias),
            }
            : new { ingresos = 0L, restringidos = 0L, denegados = 0L, salidas = 0L, desviaciones = 0L, incidencias = 0L };
        return new(null, filas, resumen, d, h);
    }

    private async Task<long?> SedeIdAsync(CancellationToken ct)
    {
        var l = await _sedes.ListarAsync(false, ct);
        var s = l.Success ? l.Data!.FirstOrDefault(x => x.Codigo == SedeCodigo) : null;
        return s?.ID_Catalogo;
    }

    private static string? Vacio(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();

    private static DateTime? Fecha(string? s) =>
        DateTime.TryParseExact(s, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d.Date : null;

    private static string Resultado(string r) => r switch
    {
        "INGRESA" => "Ingresa", "INGRESA_RESTRINGIDO" => "Ingresa restringido a la zona administrativa", "NO_INGRESA" => "No ingresa",
        "SALE" => "Sale", "SALE_RETIENE_ELEMENTO" => "Sale y se retiene el elemento", _ => r,
    };

    private static string? EstadoDesv(string? e) => e switch { "POR_REVISAR" => "Por revisar", "REVISADA" => "Revisada", _ => e };

    /// <summary>Celda CSV entre comillas. Si empieza con = + - @ se antepone un apóstrofo para que Excel no lo trate como fórmula.</summary>
    private static string Csv(string? v)
    {
        var s = v ?? string.Empty;
        if (s.Length > 0 && (s[0] is '=' or '+' or '-' or '@' or '\t' or '\r')) s = "'" + s;
        return "\"" + s.Replace("\"", "\"\"") + "\"";
    }
}
