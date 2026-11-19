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

    public ParametrosController(ISrv_Parametro param) => _param = param;

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
