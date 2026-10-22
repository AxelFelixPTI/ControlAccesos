namespace Web.ControlAccesos.Models;

/// <summary>Respuesta a un ítem del checklist.</summary>
public sealed class ItemRespuestaVM
{
    public long Id { get; set; }
    public bool Cumple { get; set; }
}

/// <summary>Desviación que Vigilancia declara cuando algún ítem no se cumple.</summary>
public sealed class DesviacionVM
{
    public string? Descripcion { get; set; }
    public long? CoordinadorId { get; set; }
    public long? TratamientoId { get; set; }
    public string? TratamientoDetalle { get; set; }
    /// <summary>Solo con tratamiento «Otro»: el efecto que Vigilancia elige.</summary>
    public string? ResultadoElegido { get; set; }
}

/// <summary>Ingreso o salida de una persona.</summary>
public sealed class MovimientoVM
{
    public long PersonaId { get; set; }
    public List<ItemRespuestaVM> Items { get; set; } = new();
    public bool TraeEquipos { get; set; }
    public bool TraeHerramientas { get; set; }
    public string? Observacion { get; set; }
    public DesviacionVM? Desviacion { get; set; }
    /// <summary>HH:mm de hoy. Solo en el registro tardío.</summary>
    public string? HoraReal { get; set; }
}

/// <summary>Respaldo de equipos (G-FSCA-009) o de herramientas/materiales (guía de remisión o G-FSCA-010).</summary>
public sealed class RespaldoVM
{
    public string? Categoria { get; set; }
    public string? Tipo { get; set; }
    public string? Numero { get; set; }
    public List<long> PersonasIds { get; set; } = new();
    public string? Observacion { get; set; }
}
