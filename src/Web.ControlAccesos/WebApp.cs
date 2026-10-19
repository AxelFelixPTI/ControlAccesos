// ============================================================
// Archivo  : WebApp.cs
// Ruta     : Web.ControlAccesos/
// Módulo   : ControlAccesos
// Paso     : Capa web — arranque
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Arma la aplicación web: dependencias (Composicion), sesión con cookie, MVC y cabeceras de seguridad.
// `sobrescribir` permite cambiar un servicio en pruebas sin tocar el resto.
// ============================================================

using System.Globalization;
using Composicion.ControlAccesos;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Localization;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos;

public static class WebApp
{
    public static WebApplication Build(string[] args, Action<IServiceCollection>? sobrescribir = null)
    {
        var builder = WebApplication.CreateBuilder(args);
        builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false);

        builder.Services.AddControlAccesos(builder.Configuration);
        sobrescribir?.Invoke(builder.Services);

        var horas = builder.Configuration.GetValue("Sesion:Horas", 8);
        builder.Services
            .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
            .AddCookie(o =>
            {
                o.Cookie.Name = "CAF.Sesion";
                o.Cookie.HttpOnly = true;
                o.Cookie.SameSite = SameSiteMode.Lax;
                o.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
                o.ExpireTimeSpan = TimeSpan.FromHours(horas);
                o.SlidingExpiration = true;
                o.LoginPath = "/Cuenta/Ingresar";
                o.AccessDeniedPath = "/Cuenta/SinAcceso";
            });
        builder.Services.AddAuthorization();
        builder.Services.AddControllersWithViews()
            .AddApplicationPart(typeof(WebApp).Assembly);
        builder.Services.AddSingleton<MenuCaf>();

        var app = builder.Build();

        CultureInfo cultura;
        try { cultura = new CultureInfo("es-PE"); }
        catch (CultureNotFoundException) { cultura = CultureInfo.InvariantCulture; } // equipos sin datos de cultura (modo invariante)
        app.UseRequestLocalization(new RequestLocalizationOptions
        {
            DefaultRequestCulture = new RequestCulture(cultura),
            SupportedCultures = new[] { cultura },
            SupportedUICultures = new[] { cultura },
        });

        if (!app.Environment.IsDevelopment())
            app.UseExceptionHandler("/Inicio/Error");

        app.Use(async (ctx, next) =>
        {
            var h = ctx.Response.Headers;
            h["X-Content-Type-Options"] = "nosniff";
            h["X-Frame-Options"] = "DENY";
            h["Referrer-Policy"] = "same-origin";
            h["Content-Security-Policy"] = "default-src 'self'; style-src 'self'; script-src 'self'; frame-ancestors 'none'";
            await next();
        });

        app.UseStaticFiles();
        app.UseRouting();
        app.UseAuthentication();
        app.UseMiddleware<ExigirCambioPasswordMiddleware>();
        app.UseAuthorization();
        app.MapControllerRoute("default", "{controller=Inicio}/{action=Index}/{id?}");
        return app;
    }
}
