// Día autorizado de una solicitud de contratista por franja (ERP_CAF_SOLICITUD_DIAS, D-227).
namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Solicitud_Dia
{
    public DateTime Fecha { get; set; }
    public string? Hora_Desde { get; set; }
    public string? Hora_Hasta { get; set; }
    /// <summary>SOLICITUD (original) o EXTENSION (agregado por el Coordinador).</summary>
    public string Origen { get; set; } = "SOLICITUD";
}
