// ============================================================
// Personal (tabla Personal, schema CAF_GOVERNANCE). Una sola clase para listar, ver, crear y editar.
// Propiedades = nombres EXACTOS de las columnas de ERP_PERSONAL_LISTAR / _DETALLE.
// ============================================================

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Personal
{
    public long ID_Personal { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Elija el tipo de documento.")]
    public long ID_Catalogo_Tipo_Documento { get; set; }
    public string? Tipo_Documento { get; set; }

    [Required(ErrorMessage = "El número de documento es obligatorio.")]
    [StringLength(20, ErrorMessage = "El número de documento no puede superar 20 caracteres.")]
    public string Numero_Documento { get; set; } = string.Empty;

    [Required(ErrorMessage = "El apellido paterno es obligatorio.")]
    [StringLength(100, ErrorMessage = "El apellido paterno no puede superar 100 caracteres.")]
    public string Apellido_Paterno { get; set; } = string.Empty;

    [StringLength(100, ErrorMessage = "El apellido materno no puede superar 100 caracteres.")]
    public string? Apellido_Materno { get; set; }

    [Required(ErrorMessage = "Los nombres son obligatorios.")]
    [StringLength(200, ErrorMessage = "Los nombres no pueden superar 200 caracteres.")]
    public string Nombres { get; set; } = string.Empty;

    public string? Nombre_Completo { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Elija el área.")]
    public long ID_Catalogo_Area { get; set; }
    public string? Area { get; set; }

    public long? ID_Catalogo_Cargo { get; set; }
    public string? Cargo { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Elija la empresa.")]
    public long ID_Catalogo_Empresa_Grupo { get; set; }
    public string? Empresa { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Elija la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    public string? Sede { get; set; }

    [StringLength(200, ErrorMessage = "El correo no puede superar 200 caracteres.")]
    public string? Correo { get; set; }

    [StringLength(20, ErrorMessage = "El anexo no puede superar 20 caracteres.")]
    public string? Anexo { get; set; }

    /// <summary>'Y' / 'N'. Solo lectura: indica si la persona ya tiene cuenta de usuario.</summary>
    public string? Tiene_Usuario { get; set; }

    /// <summary>'Y' / 'N'. Nulo en CREAR = 'Y'.</summary>
    public string? Activo { get; set; }
    public string? Eliminado { get; set; }
}
