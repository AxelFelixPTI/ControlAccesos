// ============================================================
// Inicio y cierre de sesión, cambio de contraseña y pantalla de «sin acceso».
// La lógica (hash, bloqueo, permisos) vive en ISrv_Auth; aquí solo se traduce a cookie y vistas.
// ============================================================

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Web.ControlAccesos.Models;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

public sealed class CuentaController : Controller
{
    private readonly ISrv_Auth _auth;
    private readonly ISrv_Restablecer _restablecer;
    private readonly IConfiguration _config;
    private readonly MenuCaf _menu;
    public CuentaController(ISrv_Auth auth, ISrv_Restablecer restablecer, IConfiguration config, MenuCaf menu)
    {
        _auth = auth; _restablecer = restablecer; _config = config; _menu = menu;
    }

    [HttpGet, AllowAnonymous]
    public IActionResult Ingresar(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true) return RedirectToAction("Index", "Inicio");
        return View(new IngresarVM { ReturnUrl = returnUrl });
    }

    [HttpPost, AllowAnonymous, ValidateAntiForgeryToken]
    public async Task<IActionResult> Ingresar(IngresarVM vm, CancellationToken ct)
    {
        if (!ModelState.IsValid) return View(vm);

        var r = await _auth.IniciarSesionAsync(new Dto_Login_Entrada { Correo = vm.Correo, Password = vm.Password }, ct);
        if (!r.Success || r.Data is null)
        {
            ModelState.AddModelError(string.Empty, r.Message);
            vm.Password = string.Empty;
            return View(vm);
        }

        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            SesionClaims.Crear(r.Data, CookieAuthenticationDefaults.AuthenticationScheme),
            new AuthenticationProperties { IsPersistent = false });

        if (r.Data.Password_Requiere_Cambio) return RedirectToAction(nameof(CambiarPassword));
        return !string.IsNullOrEmpty(vm.ReturnUrl) && Url.IsLocalUrl(vm.ReturnUrl)
            ? LocalRedirect(vm.ReturnUrl)
            : RedirectToAction("Index", "Inicio");
    }

    // «¿Olvidó su contraseña?»: pide el correo y envía un enlace de un solo uso. La respuesta es la misma exista o no la cuenta.
    [HttpGet, AllowAnonymous]
    public IActionResult OlvidePassword()
    {
        if (User.Identity?.IsAuthenticated == true) return RedirectToAction("Index", "Inicio");
        return View(new OlvidePasswordVM());
    }

    [HttpPost, AllowAnonymous, ValidateAntiForgeryToken]
    public async Task<IActionResult> OlvidePassword(OlvidePasswordVM vm, CancellationToken ct)
    {
        if (!ModelState.IsValid) return View(vm);
        // El enlace usa la dirección configurada (Correo:UrlBase), nunca la del encabezado Host, que alguien podría falsear.
        var baseUrl = _config["Correo:UrlBase"];
        if (string.IsNullOrWhiteSpace(baseUrl)) baseUrl = $"{Request.Scheme}://{Request.Host}";
        var r = await _restablecer.SolicitarAsync(vm.Correo, baseUrl, ct);
        TempData["Aviso"] = r.Message;
        return RedirectToAction(nameof(Ingresar));
    }

    [HttpPost, Authorize, ValidateAntiForgeryToken]
    public async Task<IActionResult> Salir()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction(nameof(Ingresar));
    }

    /// <summary>
    /// Rol activo (D-176): solo decide qué grupos del menú se muestran. No concede ni quita permisos: cada pantalla y cada
    /// procedimiento siguen validando por permiso. Se recuerda en una cookie para entrar con el último rol usado.
    /// Solo se acepta un rol que el usuario realmente tiene; vacío = todos sus roles.
    /// </summary>
    [HttpPost, Authorize, ValidateAntiForgeryToken]
    public IActionResult CambiarRol(string? rol)
    {
        if (!string.IsNullOrEmpty(rol) && _menu.Roles(User).Contains(rol))
            Response.Cookies.Append(MenuCaf.CookieRol, rol, new CookieOptions
            {
                HttpOnly = true, SameSite = SameSiteMode.Lax, Secure = Request.IsHttps, IsEssential = true, Expires = DateTimeOffset.UtcNow.AddYears(1),
            });
        else
            Response.Cookies.Delete(MenuCaf.CookieRol);
        return RedirectToAction("Index", "Inicio");
    }

    [HttpGet, Authorize]
    public IActionResult CambiarPassword() => View(new CambiarPasswordVM());

    [HttpPost, Authorize, ValidateAntiForgeryToken]
    public async Task<IActionResult> CambiarPassword(CambiarPasswordVM vm, CancellationToken ct)
    {
        if (!ModelState.IsValid) return View(vm);

        var r = await _auth.CambiarPasswordAsync(User.Correo(), vm.Actual, vm.Nueva, ct);
        if (!r.Success)
        {
            ModelState.AddModelError(string.Empty, r.Message);
            foreach (var e in r.Errors) ModelState.AddModelError(string.Empty, e.Message);
            return View(new CambiarPasswordVM());
        }

        // La cookie sigue siendo válida: solo se actualiza la bandera de «debe cambiar».
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            SesionClaims.ConCambioPassword(User, false, CookieAuthenticationDefaults.AuthenticationScheme));
        TempData["Aviso"] = "Su contraseña se cambió correctamente.";
        return RedirectToAction("Index", "Inicio");
    }

    // Enlace que el administrador entrega a un usuario nuevo (o que olvidó su contraseña): un solo uso, con vencimiento.
    [HttpGet, AllowAnonymous]
    public IActionResult DefinirPassword(string? token)
    {
        if (string.IsNullOrWhiteSpace(token)) return View("DefinirPasswordInvalido");
        return View(new DefinirPasswordVM { Token = token });
    }

    [HttpPost, AllowAnonymous, ValidateAntiForgeryToken]
    public async Task<IActionResult> DefinirPassword(DefinirPasswordVM vm, CancellationToken ct)
    {
        if (!ModelState.IsValid) { vm.Nueva = vm.Confirmar = string.Empty; return View(vm); }

        var r = await _auth.DefinirPasswordConTokenAsync(vm.Token, vm.Nueva, ct);
        if (!r.Success)
        {
            ModelState.AddModelError(string.Empty, r.Message);
            foreach (var e in r.Errors) ModelState.AddModelError(string.Empty, e.Message);
            vm.Nueva = vm.Confirmar = string.Empty;
            return View(vm);
        }
        TempData["Aviso"] = "Su contraseña quedó definida. Ya puede ingresar.";
        return RedirectToAction(nameof(Ingresar));
    }

    [HttpGet, AllowAnonymous]
    public IActionResult SinAcceso() => View();
}
