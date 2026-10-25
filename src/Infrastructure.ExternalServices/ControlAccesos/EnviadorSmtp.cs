// ============================================================
// Envío real por SMTP con MailKit. Multipart: texto plano + HTML.
// Lleva Message-ID propio y, si es una respuesta, In-Reply-To/References hacia el correo raíz
// de la solicitud para que el cliente de correo lo agrupe en un hilo.
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
        msg.From.Add(new MailboxAddress(_op.NombreRemitente, _op.Remitente));
        foreach (var d in m.Para) msg.To.Add(MailboxAddress.Parse(d));
        foreach (var d in m.Cc) msg.Cc.Add(MailboxAddress.Parse(d));
        msg.Subject = m.Asunto;
        msg.MessageId = m.MessageId.Trim('<', '>');
        if (!string.IsNullOrWhiteSpace(m.EnRespuestaA))
        {
            var raiz = m.EnRespuestaA.Trim('<', '>');
            msg.InReplyTo = raiz;
            msg.References.Add(raiz);
        }
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
