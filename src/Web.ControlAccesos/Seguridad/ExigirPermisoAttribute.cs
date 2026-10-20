// ============================================================
// Exige que el usuario tenga AL MENOS UNO de los permisos indicados (permisos PER_CAF_*).
// Pantalla normal sin permiso -> redirige a «Sin acceso». Llamada de datos (fetch/JSON) -> responde 403 en JSON.
// La visibilidad del menú es solo comodidad; esta es la protección real.
// ============================================================

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Web.ControlAccesos.Seguridad;

[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public sealed class ExigirPermisoAttribute : Attribute, IAuthorizationFilter
{
    private readonly string[] _permisos;
    public ExigirPermisoAttribute(params string[] permisos) => _permisos = permisos;

    public void OnAuthorization(AuthorizationFilterContext ctx)
    {
        var u = ctx.HttpContext.User;
        if (u.Identity?.IsAuthenticated != true) return; // lo decide [Authorize]
        if (u.TieneAlgunPermiso(_permisos)) return;

        var esDatos = HttpMethods.IsPost(ctx.HttpContext.Request.Method)
            || ctx.HttpContext.Request.Headers["X-Requested-With"] == "fetch";
        ctx.Result = esDatos
            ? new JsonResult(new { success = false, message = "No tiene permiso para esta operación." }) { StatusCode = 403 }
            : new RedirectToActionResult("SinAcceso", "Cuenta", null);
    }
}
