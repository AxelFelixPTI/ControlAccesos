namespace Web.ControlAccesos.Models;

/// <summary>Lo que envía el formulario de catálogos. Los datos que no cambian (código, orden) los resuelve el servidor.</summary>
public sealed class CatalogoGuardarVM
{
    public string Tipo { get; set; } = string.Empty;          // zona | motivo | tratamiento | incidencia
    public long Id { get; set; }                               // 0 = nuevo
    public string Descripcion { get; set; } = string.Empty;
    public bool Activo { get; set; } = true;
    public string? TipoZona { get; set; }                      // ADMINISTRATIVA | OPERATIVA
    public bool ExigeSctr { get; set; }
    public bool ExigeEpp { get; set; }
    public string? ResultadoIngreso { get; set; }
    public string? ResultadoSalida { get; set; }
}

/// <summary>Fila ya simplificada para la pantalla (nombres claros en JSON).</summary>
public sealed class CatalogoFila
{
    public long Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public bool Activo { get; set; }
    public bool EsOtro { get; set; }
    public string? TipoZona { get; set; }
    public bool ExigeSctr { get; set; }
    public bool ExigeEpp { get; set; }
    public string? ResultadoIngreso { get; set; }
    public string? ResultadoSalida { get; set; }
}

public sealed class PersonalGuardarVM
{
    public long Id { get; set; }                     // 0 = nuevo
    public string ApellidoPaterno { get; set; } = string.Empty;
    public string? ApellidoMaterno { get; set; }
    public string Nombres { get; set; } = string.Empty;
    public long TipoDocId { get; set; }
    public string Doc { get; set; } = string.Empty;
    public string? Anexo { get; set; }
    public long AreaId { get; set; }
    public long? CargoId { get; set; }
    public long EmpresaId { get; set; }
    public string? Correo { get; set; }
    public bool Activo { get; set; } = true;
}

public sealed class UsuarioGuardarVM
{
    public long Id { get; set; }                     // 0 = nuevo
    public long? PersonalId { get; set; }            // personal vinculado (nulo = externo)
    public string? ApellidoPaterno { get; set; }
    public string? ApellidoMaterno { get; set; }
    public string? Nombres { get; set; }
    public long TipoDocId { get; set; }
    public string? Doc { get; set; }
    public string? Correo { get; set; }
    public string? EmpresaExterna { get; set; }
    public List<long> Roles { get; set; } = new();   // ids de licencia LIC_CAF_*
    public bool Activo { get; set; } = true;
}

public sealed class IdVM
{
    public long Id { get; set; }
}

/// <summary>Datos de la solicitud que envía el asistente (crear) o el formulario «Editar datos». Fecha y hora vienen separadas.</summary>
public sealed class SolicitudGuardarVM
{
    public string? Fecha { get; set; }                 // yyyy-MM-dd
    public string? Hora { get; set; }                  // HH:mm
    public string? Empresa { get; set; }
    public long ResponsableId { get; set; }
    public long? MotivoId { get; set; }
    public string? MotivoDetalle { get; set; }
    public string? Observaciones { get; set; }
    public List<long> ZonasIds { get; set; } = new();
    public List<long> PersonasIds { get; set; } = new();   // solo al crear
    public string? Copias { get; set; }
    public long? OrigenId { get; set; }                    // solo al crear («Reutilizar»)
}

public sealed class PersonaExternaVM
{
    public long Id { get; set; }                       // 0 = nueva; >0 = corregir datos de una ya registrada
    public long TipoDocId { get; set; }
    public string Doc { get; set; } = string.Empty;
    public string ApellidoPaterno { get; set; } = string.Empty;
    public string? ApellidoMaterno { get; set; }
    public string Nombres { get; set; } = string.Empty;
}

public sealed class SolicitudPersonaVM
{
    public long SolicitudId { get; set; }
    public long SolicitudPersonaId { get; set; }
    public long PersonaId { get; set; }
}

public sealed class SolicitudCancelarVM
{
    public long SolicitudId { get; set; }
    public string? Motivo { get; set; }
}
