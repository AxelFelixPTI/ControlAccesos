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
