namespace Application.DTOs.ControlAccesos;

/// <summary>Filtro de la consulta de personas aprobadas de cualquier fecha (Vigilancia, solo lectura).</summary>
public sealed class Dto_Filtro_Vigilancia_Aprobadas
{
    public long? ID_Catalogo_Sede { get; set; }
    /// <summary>Nulo = sin límite inferior.</summary>
    public DateTime? Fecha_Desde { get; set; }
    /// <summary>Nulo = sin límite superior.</summary>
    public DateTime? Fecha_Hasta { get; set; }
    public string? Texto { get; set; }
}
