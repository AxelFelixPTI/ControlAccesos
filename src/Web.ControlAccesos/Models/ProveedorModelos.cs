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

/// <summary>Cancelar la disponibilidad: el motivo es obligatorio.</summary>
public sealed class ProveedorCancelarDispVM
{
    public long SolicitudId { get; set; }
    public string? Motivo { get; set; }
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

