// ============================================================
// Restablecer contraseña por correo. Reutiliza el token de un solo uso de ISrv_Auth (guarda solo su hash)
// y la cola de correos. Vigencia 60 minutos. Un mismo correo no puede pedir otro enlace antes de 60 segundos.
// ============================================================

using System.Collections.Concurrent;
using Application.Contracts.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Restablecer : ISrv_Restablecer
{
    public const int MinutosVigencia = 60;
    private static readonly ConcurrentDictionary<string, DateTime> Ultimo = new();

    private readonly ISrv_Auth _auth;
    private readonly IRepo_Correo _correos;
    private readonly ILogger<Srv_Restablecer> _logger;

    public Srv_Restablecer(ISrv_Auth auth, IRepo_Correo correos, ILogger<Srv_Restablecer> logger)
    {
        _auth = auth;
        _correos = correos;
        _logger = logger;
    }

    public async Task<Result> SolicitarAsync(string correo, string urlBase, CancellationToken ct = default)
    {
        var generico = Result.Ok("Si el correo está registrado, le enviamos un enlace para definir una contraseña nueva. Revise también la carpeta de spam.");
        if (string.IsNullOrWhiteSpace(correo) || !correo.Contains('@') || string.IsNullOrWhiteSpace(urlBase)) return generico;

        var clave = correo.Trim().ToLowerInvariant();
        var ahora = DateTime.UtcNow;
        if (Ultimo.TryGetValue(clave, out var previo) && (ahora - previo).TotalSeconds < 60) return generico;
        Ultimo[clave] = ahora;

        try
        {
            var u = await _auth.BuscarPorCorreoAsync(clave, ct).ConfigureAwait(false);
            if (!u.Success || u.Data is null) return generico;

            var t = await _auth.EmitirTokenAsync(u.Data.ID_Usuario, MinutosVigencia, 0, ct).ConfigureAwait(false);
            if (!t.Success || string.IsNullOrEmpty(t.Data)) return generico;

            var enlace = $"{urlBase.TrimEnd('/')}/Cuenta/DefinirPassword?token={Uri.EscapeDataString(t.Data)}";
            var cuerpo = "Recibimos una solicitud para definir una contraseña nueva en su cuenta de Control de Accesos.\n"
                       + $"Use este enlace (sirve una sola vez y vence en {MinutosVigencia} minutos):\n"
                       + enlace + "\n"
                       + "Si usted no lo pidió, ignore este mensaje: su contraseña actual sigue igual.";
            var r = await _correos.EncolarAsync("USUARIO_DEFINIR_PASSWORD", null, u.Data.Correo, null,
                "Restablecer su contraseña · Control de Accesos", cuerpo, 0, ct).ConfigureAwait(false);
            if (!r.Ok) _logger.LogWarning("RESTABLECER: no se pudo encolar el correo: {Msg}", r.Mensaje);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "RESTABLECER ERROR");
        }
        return generico;
    }
}
