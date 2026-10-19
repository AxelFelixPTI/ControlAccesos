using System.ComponentModel.DataAnnotations;

namespace Web.ControlAccesos.Models;

public sealed class IngresarVM
{
    [Required(ErrorMessage = "El correo es obligatorio.")]
    [Display(Name = "Correo")]
    public string Correo { get; set; } = string.Empty;

    [Required(ErrorMessage = "La contraseña es obligatoria.")]
    [DataType(DataType.Password)]
    [Display(Name = "Contraseña")]
    public string Password { get; set; } = string.Empty;

    public string? ReturnUrl { get; set; }
}

public sealed class CambiarPasswordVM
{
    [Required(ErrorMessage = "Escriba su contraseña actual.")]
    [DataType(DataType.Password)]
    [Display(Name = "Contraseña actual")]
    public string Actual { get; set; } = string.Empty;

    [Required(ErrorMessage = "Escriba la contraseña nueva.")]
    [MinLength(10, ErrorMessage = "La contraseña nueva debe tener al menos 10 caracteres.")]
    [DataType(DataType.Password)]
    [Display(Name = "Contraseña nueva")]
    public string Nueva { get; set; } = string.Empty;

    [Required(ErrorMessage = "Repita la contraseña nueva.")]
    [Compare(nameof(Nueva), ErrorMessage = "Las contraseñas no coinciden.")]
    [DataType(DataType.Password)]
    [Display(Name = "Repetir contraseña nueva")]
    public string Confirmar { get; set; } = string.Empty;
}
