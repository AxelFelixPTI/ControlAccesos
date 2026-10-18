using Microsoft.Extensions.Logging;

namespace Infrastructure.ExternalServices.ControlAccesos;

/// <summary>No envía: registra en el log. Sirve para probar el flujo completo sin SMTP.</summary>
public sealed class EnviadorSimulado : IEnviadorCorreo
{
    private readonly ILogger<EnviadorSimulado> _log;
    public EnviadorSimulado(ILogger<EnviadorSimulado> log) => _log = log;

    public Task EnviarAsync(string destinatarios, string? copia, string asunto, string cuerpo, CancellationToken ct = default)
    {
        _log.LogInformation("CORREO SIMULADO → {Para} (cc: {Cc}) | {Asunto} | {Largo} caracteres",
            destinatarios, copia ?? "-", asunto, cuerpo.Length);
        return Task.CompletedTask;
    }
}
