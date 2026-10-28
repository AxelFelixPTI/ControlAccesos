// ============================================================
// Menú lateral según permisos. Cada entrada se muestra solo si el usuario tiene AL MENOS UNO de los permisos
// indicados. «Disponible = false» se ve en gris (pantalla aún no construida). Al construir una pantalla se
// cambia aquí a true y se le pone controlador/acción.
// ============================================================

using System.Security.Claims;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos;

public sealed record EntradaMenu(string Titulo, string Grupo, string[] Permisos, bool Disponible, string? Controlador = null, string? Accion = null, string[]? OcultarSiTiene = null);

public sealed class MenuCaf
{
    private static readonly EntradaMenu[] Todas =
    {
        new("Mis solicitudes",            "Solicitante",    new[] { "PER_CAF_SOLICITUD_PROPIA" }, true, "Solicitudes", "Index"),
        new("Nueva solicitud",            "Solicitante",    new[] { "PER_CAF_SOLICITUD_PROPIA" }, true, "Solicitudes", "Nueva"),
        new("Solicitudes",                "Coordinador",    new[] { "PER_CAF_SOLICITUD_APROBAR", "PER_CAF_SOLICITUD_VER_TODAS" }, true, "Coordinacion", "Index"),
        new("Desviaciones",               "Coordinador",    new[] { "PER_CAF_DESVIACION_CONFORMIDAD" }, true, "Desviaciones", "Index"),
        new("Incidencias", "Coordinador", new[] { "PER_CAF_INCIDENCIA_DECIDIR" }, true, "Incidencias", "Index"),
        new("Reporte de accesos", "Coordinador", new[] { "PER_CAF_REPORTE_VER" }, true, "Reportes", "Index"),
        new("Control de accesos",         "Vigilancia",     new[] { "PER_CAF_PORTERIA_VER", "PER_CAF_PORTERIA_REGISTRAR" }, true, "Vigilancia", "Index"),
        // Misma pantalla que la del Coordinador; quien puede decidir la ve en su grupo y no se repite en Vigilancia.
        new("Incidencias", "Vigilancia", new[] { "PER_CAF_INCIDENCIA_REGISTRAR" }, true, "Incidencias", "Index", new[] { "PER_CAF_INCIDENCIA_DECIDIR" }),
        new("Usuarios y roles",           "Administración", new[] { "PER_CAF_ADMIN_USUARIOS" }, true, "Usuarios", "Index"),
        new("Catálogos",                  "Administración", new[] { "PER_CAF_ADMIN_CATALOGOS" }, true, "Catalogos", "Index"),
        new("Personal",                   "Administración", new[] { "PER_CAF_ADMIN_TRABAJADORES" }, true, "Personal", "Index"),
    };

    /// <summary>Nombre de la cookie donde se recuerda el rol activo (solo filtra el menú; la seguridad sigue por permisos).</summary>
    public const string CookieRol = "caf_rol";

    /// <summary>
    /// Entradas del menú del usuario. Con <paramref name="rolActivo"/> (D-176) solo se muestran las del grupo elegido; sin él, todas.
    /// Al elegir un grupo se muestran todas sus entradas permitidas, aunque otra entrada del mismo nombre se oculte cuando se ven todos los roles.
    /// </summary>
    public IReadOnlyList<IGrouping<string, EntradaMenu>> Para(ClaimsPrincipal usuario, string? rolActivo = null)
        => Todas.Where(e => usuario.TieneAlgunPermiso(e.Permisos)
                            && (string.IsNullOrEmpty(rolActivo)
                                ? e.OcultarSiTiene is null || !usuario.TieneAlgunPermiso(e.OcultarSiTiene)
                                : e.Grupo == rolActivo))
            .GroupBy(e => e.Grupo).ToList();

    /// <summary>Roles (grupos del menú) a los que el usuario tiene acceso, en el orden del menú.</summary>
    public IReadOnlyList<string> Roles(ClaimsPrincipal usuario)
        => Todas.Where(e => usuario.TieneAlgunPermiso(e.Permisos)).Select(e => e.Grupo).Distinct().ToList();

    /// <summary>Rol activo válido para este usuario según la cookie, o null (= todos mis roles) si no existe o ya no le corresponde.</summary>
    public string? RolActivo(ClaimsPrincipal usuario, string? valorCookie)
        => !string.IsNullOrEmpty(valorCookie) && Roles(usuario).Contains(valorCookie) ? valorCookie : null;
}
