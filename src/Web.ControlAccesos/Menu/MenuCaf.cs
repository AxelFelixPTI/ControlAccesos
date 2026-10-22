// ============================================================
// Menú lateral según permisos. Cada entrada se muestra solo si el usuario tiene AL MENOS UNO de los permisos
// indicados. «Disponible = false» se ve en gris (pantalla aún no construida). Al construir una pantalla se
// cambia aquí a true y se le pone controlador/acción.
// ============================================================

using System.Security.Claims;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos;

public sealed record EntradaMenu(string Titulo, string Grupo, string[] Permisos, bool Disponible, string? Controlador = null, string? Accion = null);

public sealed class MenuCaf
{
    private static readonly EntradaMenu[] Todas =
    {
        new("Mis solicitudes",            "Solicitante",    new[] { "PER_CAF_SOLICITUD_PROPIA" }, true, "Solicitudes", "Index"),
        new("Nueva solicitud",            "Solicitante",    new[] { "PER_CAF_SOLICITUD_PROPIA" }, true, "Solicitudes", "Nueva"),
        new("Solicitudes",                "Coordinador",    new[] { "PER_CAF_SOLICITUD_APROBAR", "PER_CAF_SOLICITUD_VER_TODAS" }, true, "Coordinacion", "Index"),
        new("Desviaciones",               "Coordinador",    new[] { "PER_CAF_DESVIACION_CONFORMIDAD" }, false),
        new("Incidencias",                "Coordinador",    new[] { "PER_CAF_INCIDENCIA_DECIDIR" }, false),
        new("Reporte de accesos",         "Coordinador",    new[] { "PER_CAF_REPORTE_VER" }, false),
        new("Control de accesos",         "Vigilancia",     new[] { "PER_CAF_PORTERIA_VER", "PER_CAF_PORTERIA_REGISTRAR" }, false),
        new("Incidencias del día",        "Vigilancia",     new[] { "PER_CAF_INCIDENCIA_REGISTRAR" }, false),
        new("Usuarios y roles",           "Administración", new[] { "PER_CAF_ADMIN_USUARIOS" }, true, "Usuarios", "Index"),
        new("Catálogos",                  "Administración", new[] { "PER_CAF_ADMIN_CATALOGOS" }, true, "Catalogos", "Index"),
        new("Personal",                   "Administración", new[] { "PER_CAF_ADMIN_TRABAJADORES" }, true, "Personal", "Index"),
    };

    public IReadOnlyList<IGrouping<string, EntradaMenu>> Para(ClaimsPrincipal usuario)
        => Todas.Where(e => usuario.TieneAlgunPermiso(e.Permisos)).GroupBy(e => e.Grupo).ToList();
}
