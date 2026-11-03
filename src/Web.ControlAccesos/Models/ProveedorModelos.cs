namespace Web.ControlAccesos.Models;

/// <summary>Asignar (o quitar, con PersonalId vacío) el responsable de atención programado de una entrega.</summary>
public sealed class ProveedorProgramarVM
{
    public long SolicitudId { get; set; }
    public long? PersonalId { get; set; }
}

public sealed class ProveedorAtenderVM
{
    public long SolicitudId { get; set; }
}

/// <summary>Terminar la atención. Sin observación la recepción es conforme.</summary>
public sealed class ProveedorTerminarVM
{
    public long SolicitudId { get; set; }
    public string? Observacion { get; set; }
}
