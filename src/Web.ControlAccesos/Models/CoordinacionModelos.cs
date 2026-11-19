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

/// <summary>D-227: ampliar los días autorizados de un contratista por franja (solo suma).</summary>
public sealed class CorreccionDiasVM
{
    public long SolicitudId { get; set; }
    public List<string>? Dias { get; set; }
    public string? HoraDesde { get; set; }
    public string? HoraHasta { get; set; }
    public string? Sustento { get; set; }
}

/// <summary>Corrección de emergencia (D-169): agregar a una persona a una solicitud ya aprobada.</summary>
public sealed class CorreccionAgregarVM
{
    public long SolicitudId { get; set; }
    public long PersonaId { get; set; }
    public string? Sustento { get; set; }
    public long? SubtipoId { get; set; }               // D-234: rol de la persona (si el tipo tiene subtipos)
    /// <summary>D-226: solo en solicitudes de proveedor; si es transportista, sus datos son opcionales.</summary>
    public bool EsTransportista { get; set; }
    public string? Ruc { get; set; }
    private string? _nombre;
    public string? Nombre { get => _nombre; set => _nombre = Mayus.De(value); }
    private string? _direccion;
    public string? Direccion { get => _direccion; set => _direccion = Mayus.De(value); }
    private string? _placa;
    public string? Placa { get => _placa; set => _placa = Mayus.De(value); }
    private string? _marca;
    public string? Marca { get => _marca; set => _marca = Mayus.De(value); }
    private string? _licencia;
    public string? Licencia { get => _licencia; set => _licencia = Mayus.De(value); }
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
    private string? _apellidoPaterno;
    public string? ApellidoPaterno { get => _apellidoPaterno; set => _apellidoPaterno = Mayus.De(value); }
    private string? _apellidoMaterno;
    public string? ApellidoMaterno { get => _apellidoMaterno; set => _apellidoMaterno = Mayus.De(value); }
    private string? _nombres;
    public string? Nombres { get => _nombres; set => _nombres = Mayus.De(value); }
    public string? Sustento { get; set; }
}
