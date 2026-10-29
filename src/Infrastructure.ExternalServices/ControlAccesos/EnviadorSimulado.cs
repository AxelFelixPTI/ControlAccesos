using Microsoft.Extensions.Logging;

namespace Infrastructure.ExternalServices.ControlAccesos;

/// <summary>No envía: registra en el log. Sirve para probar el flujo completo sin SMTP.</summary>
public sealed class EnviadorSimulado : IEnviadorCorreo
{
    private readonly ILogger<EnviadorSimulado> _log;
    public EnviadorSimulado(ILogger<EnviadorSimulado> log) => _log = log;

    public Task EnviarAsync(MensajeCorreo m, CancellationToken ct = default)
    {
        _log.LogInformation("CORREO SIMULADO → {Para} (cc: {Cc}) | {Asunto} | id {Id} responde a {Resp} | responder a {RT} | {Largo} caracteres",
            string.Join("; ", m.Para), m.Cc.Count == 0 ? "-" : string.Join("; ", m.Cc), m.Asunto, m.MessageId, m.EnRespuestaA ?? "-", m.ResponderA ?? "-", m.Html.Length);
        return Task.CompletedTask;
    }
}
