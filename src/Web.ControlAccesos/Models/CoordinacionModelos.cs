namespace Web.ControlAccesos.Models;

/// <summary>Decisión del coordinador sobre personas de una solicitud.</summary>
public sealed class DecidirVM
{
    public long SolicitudId { get; set; }
    public string Decision { get; set; } = string.Empty;     // APROBADA | OBSERVADA | RECHAZADA
    public string? Mensaje { get; set; }
    public List<long> PersonasIds { get; set; } = new();     // ID_Solicitud_Persona
    /// <summary>Opcional: decisión para las personas que el coordinador dejó sin marcar (OBSERVADA o RECHAZADA).</summary>
    public string? DecisionResto { get; set; }
    public string? MensajeResto { get; set; }
}

/// <summary>Corrección de emergencia (D-169): agregar a una persona a una solicitud ya aprobada.</summary>
public sealed class CorreccionAgregarVM
{
    public long SolicitudId { get; set; }
    public long PersonaId { get; set; }
    public string? Sustento { get; set; }
}

/// <summary>Corrección de emergencia (D-169): quitar a una persona autorizada que aún no ingresó.</summary>
public sealed class CorreccionRetirarVM
{
    public long SolicitudPersonaId { get; set; }
    public string? Sustento { get; set; }
}
