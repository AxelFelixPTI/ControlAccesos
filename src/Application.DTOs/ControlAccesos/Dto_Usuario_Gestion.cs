// ============================================================
// Usuarios — gestión desde la web (listar y editar). Crear usa Dto_Usuario_Crear.
// Propiedades = nombres EXACTOS de las columnas de ERP_USUARIO_LISTAR / _DETALLE.
// ============================================================

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Usuario_Lista
{
    public long ID_Usuario { get; set; }
    public string Correo { get; set; } = string.Empty;
    public long ID_Catalogo_Tipo_Documento { get; set; }
    public string? Tipo_Documento { get; set; }
    public string Numero_Documento { get; set; } = string.Empty;
    public string Apellido_Paterno { get; set; } = string.Empty;
    public string? Apellido_Materno { get; set; }
    public string Nombres { get; set; } = string.Empty;
    public string Nombre_Completo { get; set; } = string.Empty;
    public long? ID_Personal { get; set; }
    public string? Area { get; set; }
    public string? Empresa_Externa { get; set; }
    /// <summary>Texto «LIC_CAF_ADMIN@VES, LIC_CAF_SOLICITANTE@VES».</summary>
    public string? Licencias { get; set; }
    public bool Tiene_Password { get; set; }
    public bool Password_Requiere_Cambio { get; set; }
    public bool Bloqueado { get; set; }
    public DateTime? Ultimo_Acceso { get; set; }
    public bool Activo { get; set; }
}

public sealed class Dto_Usuario_Actualizar
{
    public long ID_Usuario { get; set; }

    [Required(ErrorMessage = "El correo es obligatorio.")]
    [EmailAddress(ErrorMessage = "El correo no es válido.")]
    [StringLength(200, ErrorMessage = "El correo no puede superar 200 caracteres.")]
    public string Correo { get; set; } = string.Empty;

    [Range(1, long.MaxValue, ErrorMessage = "Elija el tipo de documento.")]
    public long ID_Catalogo_Tipo_Documento { get; set; }

    [Required(ErrorMessage = "El número de documento es obligatorio.")]
    [StringLength(20, ErrorMessage = "El número de documento no puede superar 20 caracteres.")]
    public string Numero_Documento { get; set; } = string.Empty;

    [Required(ErrorMessage = "El apellido paterno es obligatorio.")]
    [StringLength(100)]
    public string Apellido_Paterno { get; set; } = string.Empty;

    [StringLength(100)]
    public string? Apellido_Materno { get; set; }

    [Required(ErrorMessage = "Los nombres son obligatorios.")]
    [StringLength(100)]
    public string Nombres { get; set; } = string.Empty;

    public long? ID_Personal { get; set; }
    public string? Empresa_Externa { get; set; }
    public bool Activo { get; set; } = true;
}
