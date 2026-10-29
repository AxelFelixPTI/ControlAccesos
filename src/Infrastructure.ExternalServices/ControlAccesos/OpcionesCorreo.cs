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

    /// <summary>
    /// Dirección web donde está publicada la aplicación, sin barra final (ej. "http://192.168.1.50:5080").
    /// Se usa para el botón «Ver solicitud» del correo. Vacío = el correo sale sin botón.
    /// </summary>
    public string UrlBase { get; set; } = string.Empty;

    /// <summary>
    /// Modo prueba: si tiene valor, TODOS los correos salen solo a esa dirección (con un aviso arriba que lista
    /// a quién habría llegado). Vacío = envío normal a los destinatarios reales.
    /// </summary>
    public string RedirigirA { get; set; } = string.Empty;

    /// <summary>La web envía los correos pendientes por sí misma (true) o lo hace la consola con «servir» (false).</summary>
    public bool EnviarDesdeWeb { get; set; } = true;

    /// <summary>Intentos antes de dejar el correo en ERROR definitivo (la rutina acepta 1..20).</summary>
    public int MaxIntentos { get; set; } = 5;

    /// <summary>Correos por vuelta del proceso.</summary>
    public int Lote { get; set; } = 20;

    /// <summary>
    /// Segundos que un correo espera en la cola antes de enviarse (D-185): da tiempo a que se carguen los documentos
    /// adjuntos recién creados y a que se fusionen los avisos de una misma revisión. 0 = sin espera.
    /// </summary>
    public int RetencionSegundos { get; set; } = 15;

    /// <summary>Espera entre vueltas del servicio en segundo plano.</summary>
    public int IntervaloSegundos { get; set; } = 30;
}
