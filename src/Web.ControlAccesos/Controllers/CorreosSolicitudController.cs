// ============================================================
// Entrega 2C-3b (D-252): correos de una solicitud y reenvío manual.
// Sin permiso fijo de pantalla: lo usan el solicitante (Detalle) y el Coordinador (Revisar). Quién puede ver o reenviar lo decide
// la base de datos con la misma regla de visibilidad de la solicitud (ERP_CAF_FN_SOLICITUD_VISIBLE): quien no puede ver la
// solicitud recibe lista vacía o 404, sin saber si existe. El reenvío no edita nada: encola un aviso con el estado actual.
// ============================================================

using Application.Contracts.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Shared.Results;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize]
public sealed class CorreosSolicitudController : Controller
{
    private readonly ISrv_Correo _correos;
    private readonly ISrv_Solicitud _sol;

    public CorreosSolicitudController(ISrv_Correo correos, ISrv_Solicitud sol) { _correos = correos; _sol = sol; }

    /// <summary>Sugerencias para «Correos adicionales» (las mismas de «Correos en copia»): solo para quienes ya las usan al solicitar o decidir.</summary>
    [HttpGet, ExigirPermiso("PER_CAF_SOLICITUD_PROPIA", "PER_CAF_PROVEEDOR_SOLICITAR", "PER_CAF_SOLICITUD_APROBAR", "PER_CAF_SOLICITUD_VER_TODAS")]
    public async Task<IActionResult> Sugerir(string? q, CancellationToken ct)
    {
        var r = await _sol.CorreosSugerirAsync(q, ct);
        if (!r.Success) return Json(new { success = false, message = r.Message });
        return Json(new { success = true, data = r.Data!.Select(c => new { correo = c.Correo, nombre = c.Nombre, origen = c.Origen }) });
    }

    [HttpGet]
    public async Task<IActionResult> Listar(long solicitudId, CancellationToken ct)
    {
        var r = await _correos.SolicitudCorreosAsync(User.UsuarioId(), solicitudId, ct);
        if (!r.Success) return Json(new { success = false, message = r.Message });
        return Json(new
        {
            success = true,
            data = r.Data!.Select(c => new
            {
                id = c.ID_Correo_Pendiente,
                tipo = c.Tipo,
                destinatarios = c.Destinatarios,
                copia = c.Copia,
                asunto = c.Asunto,
                estado = c.Estado,
                intentos = c.Intentos,
                error = c.Ultimo_Error,
                creado = c.CreateDate.ToString("yyyy-MM-dd HH:mm"),
                enviado = c.Fecha_Envio?.ToString("yyyy-MM-dd HH:mm"),
                esReenvio = c.Es_Reenvio,
                enviadoPor = c.Enviado_Por,
            }),
        });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Reenviar([FromBody] ReenviarCorreoVM m, CancellationToken ct)
    {
        var r = await _correos.SolicitudReenviarAsync(User.UsuarioId(), m.SolicitudId, m.Mismos, m.Adicionales, ct);
        if (!r.Success) return Json(new { success = false, message = r.Message });
        return Json(new { success = true, message = r.Message, destinatarios = r.Data });
    }
}

public sealed class ReenviarCorreoVM
{
    public long SolicitudId { get; set; }
    /// <summary>true = a los mismos destinatarios; false = solo a los correos adicionales.</summary>
    public bool Mismos { get; set; } = true;
    public string? Adicionales { get; set; }
}
