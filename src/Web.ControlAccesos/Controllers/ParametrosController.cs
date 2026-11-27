// ============================================================
// Pantalla «Parámetros» (dentro de Administración · Catálogos): valores del sistema que antes solo se cambiaban en la base
// (atenciones simultáneas por empresa, capacidad de la esclusa, hora de corte). D-238.
// Hoy usa el mismo permiso que Catálogos; cuando la definición de catálogos tenga su propia licencia, basta con cambiar
// la constante Permiso de esta clase. El formato de cada valor lo valida ERP_CAF_PARAMETRO_GUARDAR.
// ============================================================

using Application.Contracts.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Web.ControlAccesos.Models;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize, ExigirPermiso(ParametrosController.Permiso, ParametrosController.PermisoConfig)]
public sealed class ParametrosController : Controller
{
    /// <summary>Permiso que protege la pantalla. Separable de Catálogos cuando exista la licencia propia.</summary>
    public const string Permiso = CatalogosController.Permiso;
    /// <summary>D-258: licencia de configuración; solo ve y edita los parámetros de ClavesConfig.</summary>
    public const string PermisoConfig = CatalogosController.PermisoConfig;
    private static readonly HashSet<string> ClavesConfig = new()
    {
        "EXCLUSA_CAPACIDAD", "INCIDENCIA_POST_SALIDA", "PLACA_OBLIGATORIA", "SOLICITUD_HORAS_ANTICIPACION_APROBAR", "PROVEEDOR_HORA_CORTE"
    };
    private bool PuedeClave(string? clave) => User.TienePermiso(Permiso) || ClavesConfig.Contains(clave ?? string.Empty);

    private readonly ISrv_Parametro _param;
    private readonly ISrv_Solicitud _sol;

    public ParametrosController(ISrv_Parametro param, ISrv_Solicitud sol) { _param = param; _sol = sol; }

    /// <summary>D-259: cuántas solicitudes pendientes u observadas pasarían a Vencida si se guarda este valor (no cambia nada).
    /// Aplica a las horas de anticipación y a la hora de corte; para cualquier otra clave responde cero.</summary>
    [HttpGet]
    public async Task<IActionResult> Impacto(string clave, string? valor, CancellationToken ct)
    {
        if (!PuedeClave(clave)) return Json(new { success = false, message = "No tiene permiso para este parámetro." });
        int horas = 0; string? corte = null;
        if (clave == "SOLICITUD_HORAS_ANTICIPACION_APROBAR")
        {
            if (!int.TryParse((valor ?? "0").Trim(), out horas) || horas < 0 || horas > 999) return Json(new { success = true, total = 0, solicitudes = Array.Empty<object>() });
        }
        else if (clave == "SOLICITUD_HORA_CORTE_VENCIMIENTO") corte = (valor ?? string.Empty).Trim();
        else return Json(new { success = true, total = 0, solicitudes = Array.Empty<object>() });
        var r = await _sol.VencimientoSimularAsync(horas, corte, ct);
        if (!r.Success) return Json(new { success = false, message = r.Message });
        var lista = r.Data!;
        return Json(new
        {
            success = true, total = lista.Count,
            solicitudes = lista.Take(15).Select(x => new { codigo = x.Codigo, fecha = x.Fecha_Hora_Prevista.ToString("dd/MM HH:mm"), estado = x.Estado, empresa = x.Empresa_Visitante }),
        });
    }

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        var r = await _param.ListarAsync(ct);
        if (!r.Success) return Json(new { success = false, message = r.Message });
        return Json(new { success = true, data = r.Data!.Where(p => PuedeClave(p.Clave)).Select(p => new { clave = p.Clave, valor = p.Valor, descripcion = p.Descripcion }) });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Guardar([FromBody] ParametroGuardarVM m, CancellationToken ct)
    {
        if (!PuedeClave(m.Clave)) return Json(new { success = false, message = "No tiene permiso para este parámetro." });
        var r = await _param.GuardarAsync(m.Clave, m.Valor, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message });
    }
}
