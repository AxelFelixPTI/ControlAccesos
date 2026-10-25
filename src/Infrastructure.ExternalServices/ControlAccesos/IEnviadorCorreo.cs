// ============================================================
// Envía UN correo ya armado. Lanza excepción si no pudo (el procesador la convierte en reintento).
// ============================================================

namespace Infrastructure.ExternalServices.ControlAccesos;

/// <summary>Correo listo para salir: destinatarios depurados, HTML + texto y cabeceras del hilo.</summary>
public sealed record MensajeCorreo(
    IReadOnlyList<string> Para,
    IReadOnlyList<string> Cc,
    string Asunto,
    string Html,
    string Texto,
    string MessageId,
    string? EnRespuestaA);

public interface IEnviadorCorreo
{
    Task EnviarAsync(MensajeCorreo mensaje, CancellationToken ct = default);
}
