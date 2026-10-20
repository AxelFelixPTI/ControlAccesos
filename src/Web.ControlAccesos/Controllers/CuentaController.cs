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
    public CuentaController(ISrv_Auth auth) => _auth = auth;

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

    [HttpPost, Authorize, ValidateAntiForgeryToken]
    public async Task<IActionResult> Salir()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction(nameof(Ingresar));
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
