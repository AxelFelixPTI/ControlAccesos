// ============================================================
// Envío real por SMTP con MailKit. Multipart: texto plano + HTML.
// Lleva Message-ID propio y, si es una respuesta, In-Reply-To/References hacia el correo raíz
// de la solicitud para que el cliente de correo lo agrupe en un hilo. Reply-To y nombre del remitente: ver CabecerasCorreo.
// Puerto 587 = STARTTLS (UsarSsl=true); puerto 465 = SSL directo; UsarSsl=false = sin cifrado.
// ============================================================

using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;

namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed class EnviadorSmtp : IEnviadorCorreo
{
    private readonly OpcionesCorreo _op;

    public EnviadorSmtp(IOptions<OpcionesCorreo> op) => _op = op.Value;

    public async Task EnviarAsync(MensajeCorreo m, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(_op.Host) || string.IsNullOrWhiteSpace(_op.Remitente))
            throw new InvalidOperationException("Correo:Host y Correo:Remitente son obligatorios en modo Smtp.");
        if (m.Para.Count == 0) throw new InvalidOperationException("El correo no tiene destinatarios.");

        var msg = new MimeMessage();
        var cab = CabecerasCorreo.Armar(m, _op.NombreRemitente);
        msg.From.Add(new MailboxAddress(cab.NombreRemitente, _op.Remitente));
        // «Responder» llega a quien realizó la acción; «Responder a todos» suma Para y Cc (D-180)
        if (cab.ResponderA is not null && MailboxAddress.TryParse(cab.ResponderA, out var responder))
            msg.ReplyTo.Add(responder);
        foreach (var d in m.Para) msg.To.Add(MailboxAddress.Parse(d));
        foreach (var d in m.Cc) msg.Cc.Add(MailboxAddress.Parse(d));
        msg.Subject = m.Asunto;
        msg.MessageId = m.MessageId.Trim('<', '>');
        if (cab.InReplyTo is not null)
        {
            msg.InReplyTo = cab.InReplyTo;
            foreach (var r in cab.References) msg.References.Add(r);
        }
        msg.Headers.Add("Thread-Topic", cab.ThreadTopic);
        msg.Headers.Add("Auto-Submitted", "auto-generated");
        msg.Body = new BodyBuilder { TextBody = m.Texto, HtmlBody = m.Html }.ToMessageBody();

        var seguridad = !_op.UsarSsl ? SecureSocketOptions.None
                      : _op.Puerto == 465 ? SecureSocketOptions.SslOnConnect
                      : SecureSocketOptions.StartTls;

        using var smtp = new SmtpClient();
        await smtp.ConnectAsync(_op.Host, _op.Puerto, seguridad, ct).ConfigureAwait(false);
        if (!string.IsNullOrWhiteSpace(_op.Usuario))
            await smtp.AuthenticateAsync(_op.Usuario, _op.Clave, ct).ConfigureAwait(false);
        await smtp.SendAsync(msg, ct).ConfigureAwait(false);
        await smtp.DisconnectAsync(true, ct).ConfigureAwait(false);
    }
}
