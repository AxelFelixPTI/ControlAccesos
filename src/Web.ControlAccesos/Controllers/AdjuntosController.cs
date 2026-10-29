// ============================================================
// Entrega J (D-183, D-184): documentos adjuntos de una solicitud.
// Sin permiso fijo de pantalla: lo usan el solicitante (adjunta, retira, descarga), Coordinación y Vigilancia (consultan y descargan).
// Quién puede qué lo decide la base de datos (ERP_CAF_FN_ADJUNTO_VISIBLE y las rutinas AGREGAR/QUITAR): si el usuario no
// puede ver un documento, la lista sale vacía y la descarga responde 404, sin revelar si existe.
// El archivo se valida en el servidor (extensión, tamaño y firma) antes de guardarse; el tipo con el que se descarga sale de la
// extensión, nunca de lo que declaró el navegador, y se envía como descarga (no se abre dentro de la página).
// ============================================================

using Application.Contracts.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Shared.Results;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize]
public sealed class AdjuntosController : Controller
{
    private readonly ISrv_Solicitud_Adjunto _adj;

    public AdjuntosController(ISrv_Solicitud_Adjunto adj) => _adj = adj;

    [HttpGet]
    public async Task<IActionResult> Listar(long solicitudId, CancellationToken ct)
    {
        var r = await _adj.ListarAsync(User.UsuarioId(), solicitudId, ct);
        if (!r.Success) return Json(new { success = false, message = r.Message });
        return Json(new
        {
            success = true,
            data = r.Data!.Select(a => new
            {
                id = a.ID_Solicitud_Adjunto, nombre = a.Nombre_Archivo, extension = a.Extension, tamano = a.Tamano_Bytes,
                fecha = a.Fecha.ToString("yyyy-MM-dd HH:mm"), puedeQuitar = a.Puede_Quitar,
            }),
            max = ValidadorAdjuntos.MaxPorSolicitud, maxBytes = ValidadorAdjuntos.MaxBytes,
        });
    }

    [HttpPost, ValidateAntiForgeryToken, RequestSizeLimit(7 * 1024 * 1024)]
    public async Task<IActionResult> Subir(long solicitudId, IFormFile? archivo, CancellationToken ct)
    {
        if (archivo is null || archivo.Length == 0) return Json(new { success = false, message = "Seleccione un archivo." });
        if (archivo.Length > ValidadorAdjuntos.MaxBytes)
            return Json(new { success = false, message = $"«{ValidadorAdjuntos.LimpiarNombre(archivo.FileName)}» supera el máximo de {ValidadorAdjuntos.MaxBytes / (1024 * 1024)} MB." });
        byte[] bytes;
        await using (var ms = new MemoryStream((int)archivo.Length))
        {
            await archivo.CopyToAsync(ms, ct);
            bytes = ms.ToArray();
        }
        var r = await _adj.AgregarAsync(solicitudId, archivo.FileName, bytes, User.UsuarioId(), ct);
        if (!r.Success) return Json(new { success = false, message = r.Message, errors = r.Errors.Select(e => new { field = e.Field, message = e.Message }) });
        return Json(new { success = true, message = r.Message, data = new { id = r.Data } });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Quitar([FromBody] QuitarAdjuntoVM m, CancellationToken ct)
    {
        var r = await _adj.QuitarAsync(m.Id, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message });
    }

    [HttpGet]
    public async Task<IActionResult> Descargar(long id, CancellationToken ct)
    {
        var r = await _adj.ObtenerAsync(User.UsuarioId(), id, ct);
        if (!r.Success || r.Data is null) return NotFound();
        Response.Headers["X-Content-Type-Options"] = "nosniff";
        return File(r.Data.Contenido, ValidadorAdjuntos.TipoContenido(r.Data.Extension), r.Data.Nombre_Archivo);
    }
}

public sealed class QuitarAdjuntoVM { public long Id { get; set; } }
