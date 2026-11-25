// D-276: credenciales del almacén Google Drive. Van en variables de entorno (Almacen__Drive__ClientId, Almacen__Drive__ClientSecret, Almacen__Drive__RefreshToken), nunca en el repositorio ni en la base.
namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed class OpcionesAlmacen
{
    public const string Seccion = "Almacen";
    public OpcionesDrive Drive { get; set; } = new();
}

public sealed class OpcionesDrive
{
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public bool Completo => ClientId.Length > 0 && ClientSecret.Length > 0 && RefreshToken.Length > 0;
}
