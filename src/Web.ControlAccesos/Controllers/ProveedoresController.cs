// ============================================================
// Calendario de entregas de proveedores (Almacén y consulta).
//   Ver el calendario       : PER_CAF_PROVEEDOR_DASHBOARD (solo lectura; Abastecimiento, Coordinador, Vigilancia, Almacén)
//   Asignar / Atender / Terminar : PER_CAF_PROVEEDOR_ALMACEN (solo Almacén)
// Las reglas (estado, día, esclusa única, permisos) viven en los procedimientos; aquí solo se arman los datos y se
// reenvía la acción. Cada acción vuelve a validarse en la BD aunque la pantalla no muestre el botón.
// ============================================================

using System.Globalization;
using Application.Contracts.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Shared.Results;
using Web.ControlAccesos.Models;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize, ExigirPermiso(PermVer)]
public sealed class ProveedoresController : Controller
{
    private const string SedeCodigo = "VES";
    private const string PermVer = "PER_CAF_PROVEEDOR_DASHBOARD";
    private const string PermAlmacen = "PER_CAF_PROVEEDOR_ALMACEN";

    private readonly ISrv_Proveedor _prov;
    private readonly ISrv_Catalogo_Sede _sedes;

    public ProveedoresController(ISrv_Proveedor prov, ISrv_Catalogo_Sede sedes) { _prov = prov; _sedes = sedes; }

    [HttpGet]
    public IActionResult Index()
    {
        ViewData["PuedeAlmacen"] = User.TienePermiso(PermAlmacen);
        return View();
    }

    /// <summary>Entregas del rango (fechas yyyy-MM-dd) y estado de la esclusa. La pantalla lo llama al abrir, al pulsar Actualizar y cada minuto.</summary>
    [HttpGet]
    public async Task<IActionResult> Datos(string? desde, string? hasta, CancellationToken ct)
    {
        var sede = await SedeIdAsync(ct);
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        var uid = User.UsuarioId();
        var r = await _prov.CalendarioAsync(uid, sede.Value, Fecha(desde), Fecha(hasta), ct);
        if (!r.Success) return Falla(r.Message);
        var x = await _prov.ExclusaEstadoAsync(uid, sede.Value, ct);
        var ex = x.Success ? x.Data : null;
        return Json(new
        {
            success = true,
            hoy = DateTime.Today.ToString("yyyy-MM-dd"),
            ahora = DateTime.Now.ToString("HH:mm:ss"),
            exclusa = new
            {
                ocupada = ex?.Ocupada ?? false, codigo = ex?.Codigo, empresa = ex?.Empresa, desde = Hora(ex?.Desde), atiende = ex?.Atiende,
            },
            data = r.Data!.Select(e => new
            {
                id = e.ID_Solicitud, codigo = e.Codigo, fecha = e.Fecha_Hora_Prevista.ToString("yyyy-MM-dd"), hora = e.Fecha_Hora_Prevista.ToString("HH:mm"),
                empresa = e.Empresa_Proveedor, ruc = e.Proveedor_RUC, destino = e.Empresa_Destino, transportista = e.Transportista, telefono = e.Telefono,
                placa = e.Placa, marca = e.Vehiculo_Marca, observaciones = e.Observaciones, apoyo = e.Cantidad_Apoyo, estado = e.Estado_Operativo,
                llegada = Hora(e.Fecha_Llegada), ingreso = Hora(e.Fecha_Ingreso), inicio = Hora(e.Fecha_Inicio_Atencion), recepcion = Hora(e.Fecha_Recepcion), salida = Hora(e.Fecha_Salida),
                resultado = e.Resultado_Recepcion, programadoId = e.ID_Personal_Programado, programado = e.Programado_Nombre, efectivo = e.Efectivo_Nombre,
                puedeProgramar = e.Puede_Programar, puedeAtender = e.Puede_Atender, puedeTerminar = e.Puede_Terminar, motivoNoAtender = e.Motivo_No_Atender,
            }),
        });
    }

    /// <summary>Personal de Almacén que puede ser responsable programado (para el desplegable).</summary>
    [HttpGet, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> Responsables(CancellationToken ct)
    {
        var sede = await SedeIdAsync(ct);
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        var r = await _prov.ResponsablesAsync(User.UsuarioId(), sede.Value, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new { success = true, data = r.Data!.Select(p => new { id = p.ID_Personal, nombre = p.Nombre, cargo = p.Cargo }) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> Programar([FromBody] ProveedorProgramarVM m, CancellationToken ct)
    {
        var r = await _prov.ProgramarAsync(m.SolicitudId, m.PersonalId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> Atender([FromBody] ProveedorAtenderVM m, CancellationToken ct)
    {
        var r = await _prov.AtenderAsync(m.SolicitudId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> Terminar([FromBody] ProveedorTerminarVM m, CancellationToken ct)
    {
        var r = await _prov.TerminarAsync(m.SolicitudId, m.Observacion, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    private async Task<long?> SedeIdAsync(CancellationToken ct)
    {
        var l = await _sedes.ListarAsync(false, ct);
        var s = l.Success ? l.Data!.FirstOrDefault(x => x.Codigo == SedeCodigo) : null;
        return s?.ID_Catalogo;
    }

    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });
    private static DateTime? Fecha(string? t) => DateTime.TryParseExact(t, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d : null;
    private static string? Hora(DateTime? d) => d?.ToString("HH:mm");
    private static object Errores(Result r) => r.Errors.Select(e => new { field = e.Field, message = e.Message });
}
