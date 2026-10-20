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
