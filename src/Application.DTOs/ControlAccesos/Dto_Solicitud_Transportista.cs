// Transportista de una solicitud de proveedor (ERP_CAF_SOLICITUD_TRANSPORTISTAS, D-223).
namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Solicitud_Transportista
{
    public long ID_Solicitud_Persona { get; set; }
    public long ID_Persona_Externa { get; set; }
    public bool Es_Principal { get; set; }
    public string? Tipo_Documento { get; set; }
    public string? Numero_Documento { get; set; }
    public string Nombre_Completo { get; set; } = string.Empty;
    public string? Ruc { get; set; }
    public string? Nombre { get; set; }
    public string? Direccion { get; set; }
    public string? Placa { get; set; }
    public string? Marca { get; set; }
    public string? Licencia { get; set; }
    /// <summary>Tiene los seis datos; si no, el resto debe constar en los documentos adjuntos.</summary>
    public bool Datos_Completos { get; set; }
}
