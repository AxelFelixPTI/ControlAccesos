// ============================================================
// Si la cuenta está marcada «debe cambiar la contraseña», solo deja entrar a la pantalla de cambio, a salir
// y a los archivos estáticos hasta que la cambie.
// ============================================================

namespace Web.ControlAccesos.Seguridad;

public sealed class ExigirCambioPasswordMiddleware
{
    private static readonly string[] Permitidas = { "/Cuenta/CambiarPassword", "/Cuenta/Salir", "/css/", "/js/", "/favicon" };
    private readonly RequestDelegate _next;

    public ExigirCambioPasswordMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext ctx)
    {
        if (ctx.User.Identity?.IsAuthenticated == true && ctx.User.RequiereCambioPassword()
            && !Permitidas.Any(p => ctx.Request.Path.StartsWithSegments(p.TrimEnd('/'), StringComparison.OrdinalIgnoreCase)))
        {
            ctx.Response.Redirect("/Cuenta/CambiarPassword");
            return;
        }
        await _next(ctx);
    }
}
