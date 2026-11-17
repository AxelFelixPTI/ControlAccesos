namespace Web.ControlAccesos.Models;

/// <summary>Asignar (o quitar, con PersonalId vacío) el responsable de atención programado de una entrega.</summary>
public sealed class ProveedorProgramarVM
{
    public long SolicitudId { get; set; }
    public long? PersonalId { get; set; }
}

/// <summary>Confirmar disponibilidad o iniciar la atención: solo necesitan la entrega.</summary>
public sealed class ProveedorAtenderVM
{
    public long SolicitudId { get; set; }
}

/// <summary>D-225: acción de Vigilancia sobre varias personas de una misma entrega (ingreso, retiro, verificación o salida en grupo).</summary>
public sealed class ProveedorGrupoVM
{
    public long SolicitudId { get; set; }
    public List<long> PersonasIds { get; set; } = new();
    public string? Motivo { get; set; }
    public List<ItemRespuestaVM> Items { get; set; } = new();
    public string? Observacion { get; set; }
    public DesviacionVM? Desviacion { get; set; }
}

/// <summary>Motivo obligatorio (hoy lo usa Vigilancia en «Retiro sin ingreso»).</summary>
public sealed class ProveedorCancelarDispVM
{
    public long SolicitudId { get; set; }
    public string? Motivo { get; set; }
}

/// <summary>D-239: confirmar la disponibilidad eligiendo si la atención será CON o SIN ingreso vehicular (no se puede deshacer).</summary>
public sealed class ProveedorDisponibilidadVM
{
    public long SolicitudId { get; set; }
    public bool ConVehiculo { get; set; }
}

/// <summary>D-239: iniciar, detener, reanudar o terminar la atención de una o varias empresas de la entrega. Motivo solo al detener; observación solo al terminar.</summary>
public sealed class ProveedorEmpresasVM
{
    public long SolicitudId { get; set; }
    public List<long> EmpresasIds { get; set; } = new();
    public string? Motivo { get; set; }
    public string? Observacion { get; set; }
}

/// <summary>Terminar la atención. Sin observación la recepción es conforme.</summary>
public sealed class ProveedorTerminarVM
{
    public long SolicitudId { get; set; }
    public string? Observacion { get; set; }
}

/// <summary>D-238: iniciar la atención de una empresa de la entrega.</summary>
public sealed class ProveedorEmpresaVM
{
    public long SolicitudId { get; set; }
    public long EmpresaId { get; set; }
}

/// <summary>D-238: terminar la atención de una empresa. Sin observación la recepción es conforme.</summary>
public sealed class ProveedorEmpresaTerminarVM
{
    public long SolicitudId { get; set; }
    public long EmpresaId { get; set; }
    public string? Observacion { get; set; }
}

/// <summary>D-238: la empresa no será atendida. El motivo sale de la lista; «Otro» exige detalle.</summary>
public sealed class ProveedorCerrarSinAtencionVM
{
    public long SolicitudId { get; set; }
    public long EmpresaId { get; set; }
    public long MotivoId { get; set; }
    public string? Detalle { get; set; }
}

/// <summary>D-238: guardar un parámetro del sistema.</summary>
public sealed class ParametroGuardarVM
{
    public string Clave { get; set; } = string.Empty;
    public string? Valor { get; set; }
}

