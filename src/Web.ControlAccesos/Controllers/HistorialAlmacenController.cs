// ============================================================
// D-273/D-274. «Historial de Almacén»: listado de las atenciones de Almacén en entregas de proveedores (una fila por entrega y empresa de destino):
// quién atendió, horas, tiempo activo, pausas, con o sin ingreso vehicular y resultado. Sirve para consultar entregas pasadas.
// Exige la licencia «Historial de Almacén» (PER_CAF_PROVEEDOR_HIST_ALMACEN); el procedimiento la vuelve a exigir. Exporta a CSV lo que se filtra.
// ============================================================

using System.Globalization;
using System.Text;
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize, ExigirPermiso("PER_CAF_PROVEEDOR_HIST_ALMACEN")]
public sealed class HistorialAlmacenController : Controller
{
    private const string SedeCodigo = "VES";
    private const int MaxDias = 366;

    private readonly ISrv_Historial_Almacen _hist;
    private readonly ISrv_Catalogo_Sede _sedes;
    private readonly ISrv_Catalogo_Empresa_Grupo _empresas;

    public HistorialAlmacenController(ISrv_Historial_Almacen hist, ISrv_Catalogo_Sede sedes, ISrv_Catalogo_Empresa_Grupo empresas) { _hist = hist; _sedes = sedes; _empresas = empresas; }

    [HttpGet]
    public async Task<IActionResult> Index(CancellationToken ct)
    {
        var l = await _empresas.ListarAsync(false, ct);
        ViewData["Empresas"] = l.Success ? l.Data!.Where(e => e.Activo != "N").OrderBy(e => e.Orden).Select(e => (e.ID_Catalogo, e.Descripcion)).ToList() : new List<(long, string)>();
        return View();
    }

    [HttpGet]
    public async Task<IActionResult> Lista(string? desde, string? hasta, string? texto, long? empresa, string? estado, string? vehiculo, CancellationToken ct)
    {
        var (error, filas, d, h) = await BuscarAsync(desde, hasta, texto, empresa, estado, vehiculo, ct);
        if (error is not null) return Json(new { success = false, message = error });
        return Json(new
        {
            success = true,
            total = filas!.Count,
            data = filas.Select(x => new
            {
                solicitud = x.ID_Solicitud, codigo = x.Codigo, fecha = x.Fecha_Entrega.ToString("yyyy-MM-dd"), proveedor = x.Proveedor, solicitante = x.Solicitante,
                empresaCodigo = x.Empresa_Codigo, empresa = x.Empresa, estado = x.Estado, reservo = x.Reservo,
                inicio = x.Fecha_Inicio?.ToString("yyyy-MM-dd HH:mm"), inicioPor = x.Inicio_Nombre, fin = x.Fecha_Fin?.ToString("yyyy-MM-dd HH:mm"), finPor = x.Fin_Nombre,
                minutosActivos = x.Minutos_Activos, pausas = x.Pausas, minutosPausa = x.Minutos_Pausa, conVehiculo = x.Con_Vehiculo,
                resultado = x.Resultado, motivoSin = x.Motivo_Sin_Atencion, observacion = x.Observacion,
                oc = x.Numeros_OC, placa = x.Placa, conductor = x.Conductor, transportista = x.Empresa_Transportista, horaDesde = x.Fecha_Entrega.ToString("HH:mm"), horaHasta = x.Hora_Hasta,
                estadoEntrega = x.Estado_Entrega, llegada = x.Fecha_Llegada?.ToString("yyyy-MM-dd HH:mm"), ingreso = x.Fecha_Ingreso?.ToString("yyyy-MM-dd HH:mm"),
                disponibilidad = x.Fecha_Disponibilidad?.ToString("yyyy-MM-dd HH:mm"), salida = x.Fecha_Salida?.ToString("yyyy-MM-dd HH:mm"), desvio = x.Minutos_Desvio, fueraFranja = x.Fuera_Franja == "Y",
            }),
        });
    }

    /// <summary>Descarga un CSV con los mismos filtros de la pantalla.</summary>
    [HttpGet]
    public async Task<IActionResult> Exportar(string? desde, string? hasta, string? texto, long? empresa, string? estado, string? vehiculo, CancellationToken ct)
    {
        var (error, filas, d, h) = await BuscarAsync(desde, hasta, texto, empresa, estado, vehiculo, ct);
        if (error is not null) return BadRequest(error);
        var sb = new StringBuilder();
        sb.Append("Fecha de entrega,Franja desde,Franja hasta,Solicitud,N.° de OC,Proveedor,Placa,Conductor,Empresa transportista,Solicitante,Empresa de destino,Estado de la atención,Estado de la entrega,Llegada,Ingreso,Disponibilidad confirmada,Salida,Reservó,Atendió (inició),Inicio de la atención,Terminó,Fin de la atención,Desvío contra la franja (min),Fuera de la franja,Tiempo activo (min),Pausas,Tiempo en pausa (min),Ingreso vehicular,Resultado,Motivo sin atención,Observación\r\n");
        foreach (var x in filas!)
        {
            sb.Append(string.Join(',', new[]
            {
                Csv(x.Fecha_Entrega.ToString("yyyy-MM-dd")), Csv(x.Fecha_Entrega.ToString("HH:mm")), Csv(x.Hora_Hasta), Csv(x.Codigo), Csv(x.Numeros_OC), Csv(x.Proveedor), Csv(x.Placa), Csv(x.Conductor), Csv(x.Empresa_Transportista),
                Csv(x.Solicitante), Csv(x.Empresa), Csv(Estado(x.Estado)), Csv(EstadoEntrega(x.Estado_Entrega)),
                Csv(x.Fecha_Llegada?.ToString("yyyy-MM-dd HH:mm")), Csv(x.Fecha_Ingreso?.ToString("yyyy-MM-dd HH:mm")), Csv(x.Fecha_Disponibilidad?.ToString("yyyy-MM-dd HH:mm")), Csv(x.Fecha_Salida?.ToString("yyyy-MM-dd HH:mm")), Csv(x.Reservo),
                Csv(x.Inicio_Nombre), Csv(x.Fecha_Inicio?.ToString("yyyy-MM-dd HH:mm")), Csv(x.Fin_Nombre), Csv(x.Fecha_Fin?.ToString("yyyy-MM-dd HH:mm")),
                Csv(x.Minutos_Desvio?.ToString(CultureInfo.InvariantCulture)), Csv(x.Fuera_Franja == "Y" ? "Sí" : x.Fecha_Inicio is null ? "" : "No"),
                Csv(x.Minutos_Activos?.ToString(CultureInfo.InvariantCulture)), Csv(x.Pausas.ToString(CultureInfo.InvariantCulture)), Csv(x.Minutos_Pausa.ToString(CultureInfo.InvariantCulture)),
                Csv(x.Con_Vehiculo == "Y" ? "Con ingreso vehicular" : x.Con_Vehiculo == "N" ? "Sin ingreso vehicular" : ""), Csv(x.Resultado == "CONFORME" ? "Conforme" : x.Resultado == "CON_OBSERVACION" ? "Con observación" : x.Resultado),
                Csv(x.Motivo_Sin_Atencion), Csv(x.Observacion),
            })).Append("\r\n");
        }
        var bytes = Encoding.UTF8.GetPreamble().Concat(Encoding.UTF8.GetBytes(sb.ToString())).ToArray();
        return File(bytes, "text/csv; charset=utf-8", "historial_almacen_" + SedeCodigo + "_" + d!.Value.ToString("yyyyMMdd") + "_" + h!.Value.ToString("yyyyMMdd") + ".csv");
    }

    private async Task<(string? Error, List<Dto_Historial_Almacen>? Filas, DateTime? Desde, DateTime? Hasta)> BuscarAsync(string? desde, string? hasta, string? texto, long? empresa, string? estado, string? vehiculo, CancellationToken ct)
    {
        var d = Fecha(desde); var h = Fecha(hasta);
        if (d is null || h is null) return ("Indique las fechas «Desde» y «Hasta».", null, null, null);
        if (h < d) return ("«Hasta» no puede ser anterior a «Desde».", null, null, null);
        if ((h.Value - d.Value).TotalDays > MaxDias) return ("El rango máximo es de " + MaxDias + " días.", null, null, null);
        var l = await _sedes.ListarAsync(false, ct);
        var sede = l.Success ? l.Data!.FirstOrDefault(x => x.Codigo == SedeCodigo) : null;
        if (sede is null) return ("No se encontró la sede " + SedeCodigo + ".", null, null, null);
        var r = await _hist.ListarAsync(User.UsuarioId(), sede.ID_Catalogo, d, h, texto, empresa, estado, vehiculo, ct);
        return r.Success ? (null, r.Data, d, h) : (r.Message, null, null, null);
    }

    private static DateTime? Fecha(string? s) =>
        DateTime.TryParseExact(s, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d.Date : null;

    private static string Estado(string e) => e switch
    {
        "PENDIENTE" => "Pendiente", "EN_ATENCION" => "En atención", "DETENIDA" => "Detenida", "ATENDIDA" => "Atendida", "CERRADA_SIN_ATENCION" => "Cerrada sin atención", _ => e,
    };

    private static string EstadoEntrega(string? e) => e switch
    {
        "PROGRAMADO" => "Programado", "EN_ESPERA" => "En espera", "INGRESO" => "Ingresó", "EN_ATENCION" => "En atención", "RECEPCIONADO" => "Recepción culminada",
        "SALIO" => "Salió", "CIERRE_FORZADO" => "Cierre forzado", "NO_SE_PRESENTO" => "No se presentó", _ => e ?? string.Empty,
    };

    /// <summary>Celda CSV entre comillas. Si empieza con = + - @ se antepone un apóstrofo para que Excel no lo trate como fórmula.</summary>
    private static string Csv(string? v)
    {
        var s = v ?? string.Empty;
        if (s.Length > 0 && (s[0] is '=' or '+' or '-' or '@' or '\t' or '\r')) s = "'" + s;
        return "\"" + s.Replace("\"", "\"\"") + "\"";
    }
}
