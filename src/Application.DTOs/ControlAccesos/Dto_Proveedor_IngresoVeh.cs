namespace Application.DTOs.ControlAccesos;

/// <summary>D-260: lo que muestra «Confirmar disponibilidad» al abrirse. Una fila por entrega que hoy tiene plaza en la esclusa.
/// Caso: SIN_LIMITE | COMPLETA | ADVERTENCIA | LIBRE.</summary>
public sealed class Dto_Proveedor_IngresoVeh_Estado
{
    public string Caso { get; set; } = string.Empty;
    public int Capacidad { get; set; }
    public int Reservas { get; set; }
    public long? ID_Solicitud_Otra { get; set; }
    public string? Codigo_Otra { get; set; }
    public string? Empresas_Otra { get; set; }
    public string? Almacenero_Otra { get; set; }
    public int Veh_Total { get; set; }
    public int Veh_Por_Ingresar { get; set; }
    public int Veh_Dentro { get; set; }
    public int Veh_Salieron { get; set; }
    public bool Requiere_Conformidad { get; set; }
    public long? ID_Solicitud_Ingreso { get; set; }
    public string? Solicitud_Estado { get; set; }
    public string? Motivo_Rechazo { get; set; }
    /// <summary>D-261: vehículos de la entrega que consulta, plazas libres de la esclusa y plazas que ya tiene la otra entrega.</summary>
    public int Veh_Propios { get; set; }
    public int Plazas_Libres { get; set; }
    public int Plazas_Otra { get; set; }
}

/// <summary>D-260: solicitud de ingreso vehicular vigente (pendiente, o decidida hoy).</summary>
public sealed class Dto_Proveedor_IngresoVeh_Solicitud
{
    public long ID_Solicitud_Ingreso { get; set; }
    public long ID_Solicitud { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string? Empresas { get; set; }
    public string? Solicitante_Nombre { get; set; }
    public long ID_Solicitud_Otra { get; set; }
    public string? Codigo_Otra { get; set; }
    public string? Empresas_Otra { get; set; }
    public string? Responsable_Nombre { get; set; }
    public int Veh_Total_Otra { get; set; }
    public int Veh_Por_Ingresar_Otra { get; set; }
    public string Estado { get; set; } = string.Empty;
    public string? Motivo_Rechazo { get; set; }
    public DateTime? Fecha_Solicitud { get; set; }
    public DateTime? Fecha_Decision { get; set; }
    public string? Decide_Nombre { get; set; }
    public bool Decidida_Por_Coord { get; set; }
    public bool Es_Responsable { get; set; }
    public bool Puede_Decidir { get; set; }
    public bool Es_Solicitante { get; set; }
}

/// <summary>D-263: entrega con varias plazas en la esclusa. Puede_Liberar = este usuario puede liberar una plaza ahora.</summary>
public sealed class Dto_Proveedor_Plaza
{
    public long ID_Solicitud { get; set; }
    public int Plazas { get; set; }
    public int Veh_Declarados { get; set; }
    public int Veh_Dentro { get; set; }
    public bool Puede_Liberar { get; set; }
    public string? Motivo { get; set; }
}

/// <summary>D-263: conductor (un vehículo) con su placa y su estado, para la lista informativa del modal «Terminar atención».</summary>
public sealed class Dto_Proveedor_Vehiculo
{
    public long ID_Solicitud_Persona { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string? Placa { get; set; }
    public string Estado { get; set; } = string.Empty;
}
