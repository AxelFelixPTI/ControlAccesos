// ============================================================
// Persona externa — registro de visitantes (ERP_CAF_PERSONA_EXTERNA_*, schema del módulo). Se buscan por documento;
// si ya existen se reutilizan, si no se crean. Las reglas (duplicados, documento válido) viven en los procedimientos.
// ============================================================

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Persona_Externa
{
    public long ID_Persona_Externa { get; set; }

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
    public DateTime? Fecha_Ultima_Visita { get; set; }
}
