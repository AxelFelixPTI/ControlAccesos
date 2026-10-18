// ============================================================
// Configuración de correo (sección "Correo" de appsettings). Modo "Simulado" no envía nada:
// solo escribe en el log, para probar sin servidor de correo.
// ============================================================

namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed class OpcionesCorreo
{
    public const string Seccion = "Correo";

    /// <summary>"Simulado" (por defecto) o "Smtp".</summary>
    public string Modo { get; set; } = "Simulado";

    public string Host { get; set; } = string.Empty;
    public int Puerto { get; set; } = 587;
    public bool UsarSsl { get; set; } = true;
    public string Usuario { get; set; } = string.Empty;
    public string Clave { get; set; } = string.Empty;

    public string Remitente { get; set; } = string.Empty;
    public string NombreRemitente { get; set; } = "Control de Accesos";

    /// <summary>Intentos antes de dejar el correo en ERROR definitivo (la rutina acepta 1..20).</summary>
    public int MaxIntentos { get; set; } = 5;

    /// <summary>Correos por vuelta del proceso.</summary>
    public int Lote { get; set; } = 20;

    /// <summary>Espera entre vueltas del servicio en segundo plano.</summary>
    public int IntervaloSegundos { get; set; } = 30;
}
