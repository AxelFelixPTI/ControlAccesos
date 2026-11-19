// Propiedades = nombres EXACTOS de las columnas de ERP_CAF_SOLICITUD_CORREOS_LISTAR (D-252).

namespace Application.DTOs.ControlAccesos;

/// <summary>Un correo de la solicitud y cómo le fue al enviarlo. No incluye el cuerpo.</summary>
public sealed class Dto_Solicitud_Correo
{
    public long ID_Correo_Pendiente { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public string Destinatarios { get; set; } = string.Empty;
    public string? Copia { get; set; }
    public string Asunto { get; set; } = string.Empty;
    /// <summary>PENDIENTE, ENVIADO o ERROR.</summary>
    public string Estado { get; set; } = string.Empty;
    public long Intentos { get; set; }
    public string? Ultimo_Error { get; set; }
    public DateTime CreateDate { get; set; }
    public DateTime? Fecha_Envio { get; set; }
    public bool Es_Reenvio { get; set; }
    public string? Enviado_Por { get; set; }
}
