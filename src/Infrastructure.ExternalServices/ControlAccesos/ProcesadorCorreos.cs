// ============================================================
// Una vuelta del proceso de envío: lee los correos PENDIENTES (solo el usuario del sistema 0 puede,
// D-80), envía cada uno y lo marca ENVIADO; si falla lo marca con error y la rutina decide si queda
// PENDIENTE (reintento) o ERROR definitivo al llegar a MaxIntentos.
// Si el correo salió pero no se pudo marcar, se registra en el log: en el siguiente ciclo se reenviaría
// (se prefiere duplicar a perder un aviso).
// ============================================================

using Application.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed record ResumenEnvio(int Leidos, int Enviados, int Fallidos, string? ErrorGeneral);

public sealed class ProcesadorCorreos
{
    /// <summary>Usuario del sistema (D-12): el proceso en segundo plano.</summary>
    public const long UsuarioSistema = 0;

    private readonly ISrv_Correo _correos;
    private readonly IEnviadorCorreo _enviador;
    private readonly OpcionesCorreo _op;
    private readonly ILogger<ProcesadorCorreos> _log;

    public ProcesadorCorreos(ISrv_Correo correos, IEnviadorCorreo enviador, IOptions<OpcionesCorreo> op, ILogger<ProcesadorCorreos> log)
    {
        _correos = correos;
        _enviador = enviador;
        _op = op.Value;
        _log = log;
    }

    public async Task<ResumenEnvio> ProcesarLoteAsync(CancellationToken ct = default)
    {
        var lectura = await _correos.PendientesListarAsync(UsuarioSistema, _op.Lote, ct).ConfigureAwait(false);
        if (!lectura.Success)
        {
            _log.LogError("No se pudo leer la cola de correos: {Msg}", lectura.Message);
            return new ResumenEnvio(0, 0, 0, lectura.Message);
        }

        int enviados = 0, fallidos = 0;
        var lista = lectura.Data ?? new();
        foreach (var c in lista)
        {
            ct.ThrowIfCancellationRequested();
            try
            {
                await _enviador.EnviarAsync(c.Destinatarios, c.Copia, c.Asunto, c.Cuerpo, ct).ConfigureAwait(false);
            }
            catch (OperationCanceledException) { throw; }
            catch (Exception ex)
            {
                fallidos++;
                var texto = Recortar(ex.Message, 400);
                _log.LogWarning("Correo {ID} no enviado (intento {N}): {Msg}", c.ID_Correo_Pendiente, c.Intentos + 1, texto);
                var r = await _correos.MarcarErrorAsync(c.ID_Correo_Pendiente, texto, _op.MaxIntentos, UsuarioSistema, ct).ConfigureAwait(false);
                if (!r.Success)
                    _log.LogError("No se pudo registrar el error del correo {ID}: {Msg}", c.ID_Correo_Pendiente, r.Message);
                continue;
            }

            var m = await _correos.MarcarEnviadoAsync(c.ID_Correo_Pendiente, UsuarioSistema, ct).ConfigureAwait(false);
            if (m.Success) enviados++;
            else _log.LogError("Correo {ID} ENVIADO pero no se pudo marcar: {Msg}", c.ID_Correo_Pendiente, m.Message);
        }

        if (lista.Count > 0)
            _log.LogInformation("Correos: {L} leídos, {E} enviados, {F} con error.", lista.Count, enviados, fallidos);
        return new ResumenEnvio(lista.Count, enviados, fallidos, null);
    }

    private static string Recortar(string s, int max) => s.Length <= max ? s : s[..max];
}
