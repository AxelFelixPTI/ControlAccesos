// ============================================================
// Convierte Dto_Sesion_Usuario en la identidad de la cookie y la lee de vuelta.
// La cookie guarda: id, nombre, correo, licencias, permisos y si debe cambiar la contraseña.
// Nunca guarda hash ni token.
// ============================================================

using System.Security.Claims;
using Application.DTOs.ControlAccesos;

namespace Web.ControlAccesos.Seguridad;

public static class SesionClaims
{
    public const string Licencia = "caf:lic";      // CODIGO_LICENCIA|CODIGO_SEDE|Nombre de sede
    public const string Permiso = "caf:perm";      // CODIGO_PERMISO|Sedes
    public const string CambioPassword = "caf:cambio"; // Y / N

    public static ClaimsPrincipal Crear(Dto_Sesion_Usuario s, string esquema)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, s.ID_Usuario.ToString()),
            new(ClaimTypes.Name, s.Nombre_Completo),
            new(ClaimTypes.Email, s.Correo),
            new(CambioPassword, s.Password_Requiere_Cambio ? "Y" : "N"),
        };
        claims.AddRange(s.Licencias.Select(l => new Claim(Licencia, $"{l.Codigo_Licencia}|{l.Codigo_Sede}|{l.Sede}")));
        claims.AddRange(s.Permisos.Select(p => new Claim(Permiso, $"{p.Codigo_Permiso}|{p.Sedes}")));
        return new ClaimsPrincipal(new ClaimsIdentity(claims, esquema));
    }

    /// <summary>Misma identidad con la bandera de cambio de contraseña modificada (tras cambiarla).</summary>
    public static ClaimsPrincipal ConCambioPassword(ClaimsPrincipal actual, bool requiere, string esquema)
    {
        var claims = actual.Claims.Where(c => c.Type != CambioPassword).ToList();
        claims.Add(new Claim(CambioPassword, requiere ? "Y" : "N"));
        return new ClaimsPrincipal(new ClaimsIdentity(claims, esquema));
    }

    public static long UsuarioId(this ClaimsPrincipal u)
        => long.TryParse(u.FindFirstValue(ClaimTypes.NameIdentifier), out var id) ? id : 0;

    public static string Correo(this ClaimsPrincipal u) => u.FindFirstValue(ClaimTypes.Email) ?? string.Empty;

    public static bool RequiereCambioPassword(this ClaimsPrincipal u) => u.FindFirstValue(CambioPassword) == "Y";

    public static bool TienePermiso(this ClaimsPrincipal u, string codigo)
        => u.FindAll(Permiso).Any(c => c.Value.StartsWith(codigo + "|", StringComparison.Ordinal));

    public static bool TieneAlgunPermiso(this ClaimsPrincipal u, IEnumerable<string> codigos)
        => codigos.Any(u.TienePermiso);

    public static IEnumerable<(string Licencia, string Sede, string NombreSede)> Licencias(this ClaimsPrincipal u)
        => u.FindAll(Licencia).Select(c => c.Value.Split('|')).Where(p => p.Length == 3).Select(p => (p[0], p[1], p[2]));

    public static IEnumerable<(string Codigo, string Sedes)> Permisos(this ClaimsPrincipal u)
        => u.FindAll(Permiso).Select(c => c.Value.Split('|', 2)).Select(p => (p[0], p.Length > 1 ? p[1] : string.Empty));
}
