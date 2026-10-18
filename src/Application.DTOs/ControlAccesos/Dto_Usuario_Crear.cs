// ============================================================
// Datos para crear un usuario (ERP_USUARIO_CREAR). La contraseña NO va aquí: se define aparte
// (ISrv_Usuario.EstablecerPasswordAsync) y solo se guarda su hash.
// ============================================================

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Usuario_Crear
{
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

    /// <summary>Si el usuario es personal del grupo, su ID_Personal. Nulo para externos.</summary>
    public long? ID_Personal { get; set; }

    public string? Empresa_Externa { get; set; }
}
