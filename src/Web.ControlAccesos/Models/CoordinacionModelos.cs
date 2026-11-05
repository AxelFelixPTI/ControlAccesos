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
    /// <summary>D-215: true cuando el Coordinador confirmó que, al quitar a la única persona, la solicitud queda rechazada.</summary>
    public bool ConfirmarRechazo { get; set; }
}

/// <summary>Corrección de emergencia (D-215): corregir tipo de documento, apellidos y nombres (nunca el número de documento).</summary>
public sealed class CorreccionCorregirVM
{
    public long SolicitudPersonaId { get; set; }
    public long TipoDocumentoId { get; set; }
    public string? ApellidoPaterno { get; set; }
    public string? ApellidoMaterno { get; set; }
    public string? Nombres { get; set; }
    public string? Sustento { get; set; }
}
