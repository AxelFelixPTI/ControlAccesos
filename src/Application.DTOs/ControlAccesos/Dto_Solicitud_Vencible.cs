// Respuesta de ERP_CAF_SOLICITUD_VENCIMIENTO_SIMULAR (D-259): solicitudes que pasarían a VENCIDA con el valor que se va a guardar.
namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Solicitud_Vencible
{
    public long ID_Solicitud { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public DateTime Fecha_Hora_Prevista { get; set; }
    public string Estado { get; set; } = string.Empty;
    public string? Empresa_Visitante { get; set; }
}
