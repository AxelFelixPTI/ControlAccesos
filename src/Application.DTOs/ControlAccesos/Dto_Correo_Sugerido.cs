// Respuesta de ERP_CAF_SOLICITUD_CORREOS_SUGERIR (D-217). Propiedades = nombres de las columnas.
namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Correo_Sugerido
{
    public string Correo { get; set; } = string.Empty;
    /// <summary>Nombre del usuario (solo cuando es un usuario del sistema).</summary>
    public string? Nombre { get; set; }
    /// <summary>USUARIO o USADO (correo externo de una solicitud anterior).</summary>
    public string Origen { get; set; } = string.Empty;
}
