// ============================================================
// Envía UN correo. Lanza excepción si no pudo (el procesador la convierte en reintento).
// ============================================================

namespace Infrastructure.ExternalServices.ControlAccesos;

public interface IEnviadorCorreo
{
    Task EnviarAsync(string destinatarios, string? copia, string asunto, string cuerpo, CancellationToken ct = default);
}
