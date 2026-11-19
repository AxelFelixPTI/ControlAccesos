// ============================================================
// Iconos del menú lateral (D-255). SVG en línea, trazo 2, 24×24, geometría tipo Lucide (licencia ISC); toman el color del texto.
// Se buscan por «Controlador/Acción» y, si no hay uno exacto, por el controlador. Sin icono, el menú se ve solo con texto.
// ============================================================

using Microsoft.AspNetCore.Html;

namespace Web.ControlAccesos;

public static class IconosMenu
{
    private static readonly Dictionary<string, string> Trazos = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Inicio"] = "<path d='M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8'/><path d='M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z'/>",
        ["Solicitudes/Index"] = "<rect x='8' y='2' width='8' height='4' rx='1'/><path d='M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2'/><path d='M12 11h4'/><path d='M12 16h4'/><path d='M8 11h.01'/><path d='M8 16h.01'/>",
        ["Solicitudes/Nueva"] = "<path d='M6 22a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.704.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2z'/><path d='M14 2v5a1 1 0 0 0 1 1h5'/><path d='M9 15h6'/><path d='M12 18v-6'/>",
        ["Coordinacion"] = "<path d='M22 12h-6l-2 3h-4l-2-3H2'/><path d='M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z'/>",
        ["Desviaciones"] = "<path d='m18 14 4 4-4 4'/><path d='m18 2 4 4-4 4'/><path d='M2 18h1.973a4 4 0 0 0 3.3-1.7l5.454-8.6a4 4 0 0 1 3.3-1.7H22'/><path d='M2 6h1.972a4 4 0 0 1 3.6 2.2'/><path d='M22 18h-6.041a4 4 0 0 1-3.3-1.8l-.359-.45'/>",
        ["Incidencias"] = "<path d='m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3'/><path d='M12 9v4'/><path d='M12 17h.01'/>",
        ["Reportes"] = "<path d='M3 3v16a2 2 0 0 0 2 2h16'/><path d='M18 17V9'/><path d='M13 17V5'/><path d='M8 17v-3'/>",
        ["Vigilancia"] = "<path d='M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z'/><path d='m9 12 2 2 4-4'/>",
        ["Proveedores"] = "<path d='M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2'/><path d='M15 18H9'/><path d='M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14'/><circle cx='17' cy='18' r='2'/><circle cx='7' cy='18' r='2'/>",
        ["Usuarios"] = "<path d='M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2'/><circle cx='9' cy='7' r='4'/><path d='M22 21v-2a4 4 0 0 0-3-3.87'/><path d='M16 3.13a4 4 0 0 1 0 7.75'/>",
        ["Catalogos"] = "<path d='m16 6 4 14'/><path d='M12 6v14'/><path d='M8 8v12'/><path d='M4 4v16'/>",
        ["Personal"] = "<path d='M16 10h2'/><path d='M16 14h2'/><path d='M6.17 15a3 3 0 0 1 5.66 0'/><circle cx='9' cy='11' r='2'/><rect x='2' y='4' width='20' height='16' rx='2'/>",
    };

    public static IHtmlContent Para(string? controlador, string? accion = null)
    {
        if (!(Trazos.TryGetValue($"{controlador}/{accion}", out var t) || Trazos.TryGetValue(controlador ?? "", out t))) return HtmlString.Empty;
        return new HtmlString($"<svg class='ic nav-ic' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' aria-hidden='true' focusable='false'>{t}</svg>");
    }
}
