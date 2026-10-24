namespace Web.ControlAccesos.Models;

/// <summary>Incidencia que se registra (la hora es de hoy, HH:mm).</summary>
public sealed class IncidenciaVM
{
    public long TipoId { get; set; }
    public string? TipoDetalle { get; set; }
    public string? Hora { get; set; }
    public long? ZonaId { get; set; }
    public string? LugarDetalle { get; set; }
    public string? Descripcion { get; set; }
    public List<long>? PersonasIds { get; set; }
}

/// <summary>Decisión del coordinador: CONFIRMAR o DESESTIMAR, con sustento.</summary>
public sealed class IncidenciaDecisionVM
{
    public long Id { get; set; }
    public string? Decision { get; set; }
    public string? Sustento { get; set; }
}
