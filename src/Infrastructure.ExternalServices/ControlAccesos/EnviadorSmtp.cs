// ============================================================
// Envío real por SMTP con System.Net.Mail (sin paquetes extra). Texto plano.
// ============================================================

using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Options;

namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed class EnviadorSmtp : IEnviadorCorreo
{
    private static readonly char[] Separadores = { ';', ',' };
    private readonly OpcionesCorreo _op;

    public EnviadorSmtp(IOptions<OpcionesCorreo> op) => _op = op.Value;

    public async Task EnviarAsync(string destinatarios, string? copia, string asunto, string cuerpo, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(_op.Host) || string.IsNullOrWhiteSpace(_op.Remitente))
            throw new InvalidOperationException("Correo:Host y Correo:Remitente son obligatorios en modo Smtp.");

        using var msg = new MailMessage { From = new MailAddress(_op.Remitente, _op.NombreRemitente), Subject = asunto, Body = cuerpo, IsBodyHtml = false };
        Agregar(msg.To, destinatarios);
        if (msg.To.Count == 0) throw new InvalidOperationException("El correo no tiene destinatarios.");
        Agregar(msg.CC, copia);

        using var smtp = new SmtpClient(_op.Host, _op.Puerto) { EnableSsl = _op.UsarSsl };
        if (!string.IsNullOrWhiteSpace(_op.Usuario))
            smtp.Credentials = new NetworkCredential(_op.Usuario, _op.Clave);
        await smtp.SendMailAsync(msg, ct).ConfigureAwait(false);
    }

    private static void Agregar(MailAddressCollection destino, string? lista)
    {
        if (string.IsNullOrWhiteSpace(lista)) return;
        foreach (var d in lista.Split(Separadores, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            destino.Add(d);
    }
}
