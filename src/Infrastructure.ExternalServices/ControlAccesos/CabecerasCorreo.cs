// ============================================================
// Cabeceras que dan forma al hilo y a las respuestas de un correo (D-151, D-179, D-180).
// Es lógica pura (sin MailKit) para poder probarla sin servidor de correo; EnviadorSmtp la aplica al mensaje.
// ============================================================

namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed record CabecerasHilo(
    string NombreRemitente,
    string? ResponderA,
    string? ResponderANombre,
    string ThreadTopic,
    string? InReplyTo,
    IReadOnlyList<string> References);

public static class CabecerasCorreo
{
    /// <summary>
    /// - Remitente visible: «Nombre de quien actuó · Control de Accesos» (la dirección sigue siendo la del sistema).
    /// - «Responder» va a quien actuó (Reply-To); «Responder a todos» suma Para y Cc del correo.
    /// - In-Reply-To y References apuntan a la raíz del hilo; Thread-Topic (Outlook) es el asunto sin «Re: ».
    /// </summary>
    public static CabecerasHilo Armar(MensajeCorreo m, string nombreBase)
    {
        var quien = string.IsNullOrWhiteSpace(m.ResponderA) ? null : m.ResponderA.Trim();
        var nombre = string.IsNullOrWhiteSpace(m.ResponderANombre) ? null : m.ResponderANombre.Trim();
        var remitente = quien is not null && nombre is not null ? $"{nombre} · {nombreBase}" : nombreBase;

        var tema = (m.Asunto ?? string.Empty).Trim();
        while (tema.StartsWith("Re:", StringComparison.OrdinalIgnoreCase)) tema = tema[3..].TrimStart();

        string? raiz = string.IsNullOrWhiteSpace(m.EnRespuestaA) ? null : m.EnRespuestaA.Trim().Trim('<', '>');
        return new CabecerasHilo(remitente, quien, quien is null ? null : nombre, tema, raiz, raiz is null ? Array.Empty<string>() : new[] { raiz });
    }
}
