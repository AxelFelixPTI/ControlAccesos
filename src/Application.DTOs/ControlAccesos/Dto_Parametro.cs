// D-238: parámetro del sistema (clave/valor) editable desde Administración · Catálogos · Parámetros.
namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Parametro
{
    public string Clave { get; set; } = string.Empty;
    public string Valor { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
}
