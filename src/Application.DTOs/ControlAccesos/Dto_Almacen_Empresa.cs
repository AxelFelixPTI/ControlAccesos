// D-236: usuario de Almacén y las empresas del grupo a las que puede dar atención (puede ser distinta de la que lo contrató).
namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Almacen_Empresa
{
    public long ID_Usuario { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string? Cargo { get; set; }
    /// <summary>Ids de empresa separados por coma ('' = ninguna: no podrá atender).</summary>
    public string IDs_Empresa { get; set; } = string.Empty;
    public string Empresas { get; set; } = string.Empty;
}
