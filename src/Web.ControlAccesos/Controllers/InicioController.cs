using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace Web.ControlAccesos.Controllers;

public sealed class InicioController : Controller
{
    [HttpGet, Authorize]
    public IActionResult Index() => View();

    [HttpGet, HttpPost, AllowAnonymous]
    public IActionResult Error()
    {
        HttpContext.Features.Get<IExceptionHandlerFeature>(); // el detalle queda en el log del servidor, no en pantalla
        return View();
    }
}
