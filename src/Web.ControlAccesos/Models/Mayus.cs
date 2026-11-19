namespace Web.ControlAccesos.Models;

/// <summary>Nombres, empresas y datos de vehículo se guardan siempre en MAYÚSCULAS (sin mezclar minúsculas); aunque el navegador no lo haya hecho.</summary>
public static class Mayus
{
    private static readonly System.Globalization.CultureInfo Cultura = new("es-PE");
    public static string? De(string? texto) => texto?.Trim().ToUpper(Cultura);
}
