namespace Application.DTOs.ControlAccesos;

/// <summary>D-244: una fila del panel de cupos. Tipo ALMACENERO = solicitud que ocupa el cupo de un almacenero (RESERVA o ATENCION);
/// Tipo EMPRESA = cupo de atenciones simultáneas de una empresa (Limite 2147483647 = sin límite).</summary>
public sealed class Dto_Proveedor_Cupo
{
    public string Tipo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string? Codigo { get; set; }
    public string? Solicitud { get; set; }
    public string? Ocupa { get; set; }
    public string? Detalle { get; set; }
    public int Usados { get; set; }
    public int Limite { get; set; }
}
