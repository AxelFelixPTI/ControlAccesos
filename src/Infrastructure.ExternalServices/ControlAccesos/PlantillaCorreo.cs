// ============================================================
// Plantilla de los correos de solicitud: HTML sobrio (tablas + estilos en línea, único modo que
// respetan los clientes de correo) y su versión en texto plano. Una sola plantilla para todos los
// tipos; cambian el título y el mensaje. El asunto es siempre el mismo para que el cliente arme el hilo.
// ============================================================

using System.Net;
using System.Text;
using Application.DTOs.ControlAccesos;

namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed record CorreoArmado(string Asunto, string Html, string Texto);

public static class PlantillaCorreo
{
    private const string Azul = "#1f3a5f";
    private const string Borde = "#d9dee5";
    private const string Gris = "#5b6573";

    private static readonly Dictionary<string, (string Texto, string Fondo, string Color)> Estados = new()
    {
        ["PENDIENTE"]        = ("Pendiente",        "#fff4d6", "#7a5a00"),
        ["OBSERVADA"]        = ("Observada",        "#ffe9d6", "#8a4300"),
        ["APROBADA"]         = ("Aprobada",         "#dcf3e3", "#1c6b3a"),
        ["APROBADA_PARCIAL"] = ("Aprobada parcial", "#e3f0fb", "#1d5a8f"),
        ["RECHAZADA"]        = ("Rechazada",        "#fbe0e0", "#9a1f1f"),
        ["CANCELADA"]        = ("Cancelada",        "#e7e9ec", "#4a5360"),
    };

    private static readonly Dictionary<string, string> Titulos = new()
    {
        ["SOLICITUD_NUEVA"]     = "Nueva solicitud por aprobar",
        ["SOLICITUD_EDITADA"]   = "Solicitud modificada",
        ["SOLICITUD_DECISION"]  = "Actualización de la solicitud",
        ["PERSONA_POR_APROBAR"] = "Personas por aprobar",
        ["SOLICITUD_CORRECCION"] = "Corrección de emergencia",
        ["SOLICITUD_CANCELADA"] = "Solicitud cancelada",
    };

    /// <summary>
    /// Correo sin solicitud (por ejemplo, el enlace para definir contraseña). Las líneas que empiezan con http
    /// se muestran como botón; en texto plano quedan como dirección.
    /// </summary>
    public static CorreoArmado ArmarSimple(string tipo, string asunto, string mensaje, string? aviso = null)
    {
        var titulo = tipo == "USUARIO_DEFINIR_PASSWORD" ? "Restablecer su contraseña" : "Aviso del sistema";
        var lineas = (mensaje ?? "").Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        var h = new StringBuilder();
        h.Append("<!DOCTYPE html><html lang=\"es\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"></head>");
        h.Append("<body style=\"margin:0;padding:0;background:#f3f5f8;\">");
        h.Append("<table role=\"presentation\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" style=\"background:#f3f5f8;\"><tr><td align=\"center\" style=\"padding:20px 10px;\">");
        h.Append($"<table role=\"presentation\" width=\"600\" cellpadding=\"0\" cellspacing=\"0\" style=\"width:100%;max-width:600px;background:#ffffff;border:1px solid {Borde};font-family:Segoe UI,Arial,sans-serif;color:#1d2530;\">");
        h.Append($"<tr><td style=\"background:{Azul};color:#ffffff;padding:14px 22px;font-size:13px;letter-spacing:.3px;\">Control de Accesos · Grupo Trianon</td></tr>");
        if (!string.IsNullOrWhiteSpace(aviso))
            h.Append($"<tr><td style=\"background:#fff8e1;border-bottom:1px solid #f0d98a;padding:10px 22px;font-size:12px;color:#6b5400;\">{Esc(aviso).Replace("\n", "<br>")}</td></tr>");
        h.Append($"<tr><td style=\"padding:22px 22px 6px 22px;\"><div style=\"font-size:19px;font-weight:600;color:{Azul};\">{Esc(titulo)}</div></td></tr>");
        h.Append("<tr><td style=\"padding:12px 22px 4px 22px;font-size:14px;line-height:1.5;\">");
        foreach (var l in lineas)
        {
            if (l.StartsWith("http", StringComparison.OrdinalIgnoreCase))
                h.Append($"<p style=\"margin:14px 0;\"><a href=\"{Esc(l)}\" style=\"display:inline-block;background:{Azul};color:#ffffff;text-decoration:none;padding:10px 20px;border-radius:4px;font-size:14px;\">Definir mi contraseña</a></p>")
                 .Append($"<p style=\"margin:0 0 8px 0;font-size:11px;color:{Gris};word-break:break-all;\">Si el botón no funciona, copie esta dirección en el navegador:<br>{Esc(l)}</p>");
            else
                h.Append($"<p style=\"margin:0 0 8px 0;\">{Esc(l)}</p>");
        }
        h.Append("</td></tr>");
        h.Append($"<tr><td style=\"padding:20px 22px;font-size:11px;color:{Gris};line-height:1.5;\">Mensaje automático del sistema Control de Accesos. Esta casilla no se monitorea.</td></tr>");
        h.Append("</table></td></tr></table></body></html>");

        var x = new StringBuilder();
        if (!string.IsNullOrWhiteSpace(aviso)) x.AppendLine(aviso).AppendLine();
        x.AppendLine(titulo.ToUpperInvariant()).AppendLine();
        foreach (var l in lineas) x.AppendLine(l);
        x.AppendLine().AppendLine("Mensaje automático. Esta casilla no se monitorea.");
        return new CorreoArmado(asunto, h.ToString(), x.ToString());
    }

    public static string Asunto(Dto_Correo_Solicitud d, bool esRespuesta)
        => (esRespuesta ? "Re: " : "") + $"Solicitud {d.Codigo} · {d.Empresa_Visitante}";

    public static string EtiquetaEstado(string estado)
        => Estados.TryGetValue(estado, out var e) ? e.Texto : estado.Replace('_', ' ');

    /// <param name="mensaje">Texto plano que dejó la rutina (líneas separadas por salto de línea).</param>
    /// <param name="aviso">Texto opcional arriba de todo (modo prueba).</param>
    public static CorreoArmado Armar(string tipo, string mensaje, Dto_Correo_Solicitud d,
        IReadOnlyList<Dto_Correo_Solicitud_Persona> personas, string urlBase, bool esRespuesta, string? aviso = null)
    {
        var titulo = Titulos.TryGetValue(tipo, out var t) ? t : "Solicitud de acceso";
        var lineas = (mensaje ?? "").Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        var url = string.IsNullOrWhiteSpace(urlBase) ? null : $"{urlBase.TrimEnd('/')}/Solicitudes/Detalle/{d.ID_Solicitud}";

        var datos = new List<(string, string)>
        {
            ("Código", d.Codigo),
            ("Estado", EtiquetaEstado(d.Estado)),
            ("Sede", d.Sede ?? "-"),
            ("Tipo de acceso", d.Tipo_Acceso ?? "-"),
            ("Visita prevista", d.Fecha_Hora_Prevista.ToString("dd/MM/yyyy HH:mm")),
            ("Empresa visitante", d.Empresa_Visitante),
            ("Responsable", Responsable(d)),
            ("Motivo", string.IsNullOrWhiteSpace(d.Motivo_Detalle) ? (d.Motivo ?? "-") : $"{d.Motivo} — {d.Motivo_Detalle}"),
            ("Zonas", d.Zonas_Nombres ?? "-"),
            ("Solicitante", string.IsNullOrWhiteSpace(d.Solicitante_Correo) ? (d.Solicitante_Nombre ?? "-") : $"{d.Solicitante_Nombre} ({d.Solicitante_Correo})"),
            ("Personas", Resumen(d)),
        };
        var requisitos = new List<string>();
        if (d.Exige_SCTR) requisitos.Add("SCTR");
        if (d.Exige_EPP) requisitos.Add("EPP");
        datos.Add(("Requisitos", requisitos.Count == 0 ? "Ninguno" : string.Join(" y ", requisitos)));
        if (!string.IsNullOrWhiteSpace(d.Observacion_Coordinador)) datos.Add(("Observación del coordinador", d.Observacion_Coordinador!));
        if (!string.IsNullOrWhiteSpace(d.Motivo_Cancelacion)) datos.Add(("Motivo de cancelación", d.Motivo_Cancelacion!));

        var est = Estados.TryGetValue(d.Estado, out var e) ? e : ("", "#e7e9ec", "#4a5360");

        // ── HTML ──────────────────────────────────────────────
        var h = new StringBuilder();
        h.Append("<!DOCTYPE html><html lang=\"es\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"></head>");
        h.Append("<body style=\"margin:0;padding:0;background:#f3f5f8;\">");
        h.Append("<table role=\"presentation\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" style=\"background:#f3f5f8;\"><tr><td align=\"center\" style=\"padding:20px 10px;\">");
        h.Append($"<table role=\"presentation\" width=\"600\" cellpadding=\"0\" cellspacing=\"0\" style=\"width:100%;max-width:600px;background:#ffffff;border:1px solid {Borde};font-family:Segoe UI,Arial,sans-serif;color:#1d2530;\">");
        h.Append($"<tr><td style=\"background:{Azul};color:#ffffff;padding:14px 22px;font-size:13px;letter-spacing:.3px;\">Control de Accesos · Grupo Trianon</td></tr>");
        if (!string.IsNullOrWhiteSpace(aviso))
            h.Append($"<tr><td style=\"background:#fff8e1;border-bottom:1px solid #f0d98a;padding:10px 22px;font-size:12px;color:#6b5400;\">{Esc(aviso).Replace("\n", "<br>")}</td></tr>");
        h.Append("<tr><td style=\"padding:22px 22px 6px 22px;\">");
        h.Append($"<div style=\"font-size:19px;font-weight:600;color:{Azul};margin-bottom:8px;\">{Esc(titulo)}</div>");
        h.Append($"<span style=\"display:inline-block;padding:3px 10px;border-radius:10px;font-size:12px;background:{est.Item2};color:{est.Item3};\">{Esc(EtiquetaEstado(d.Estado))}</span>");
        h.Append("</td></tr>");
        h.Append("<tr><td style=\"padding:12px 22px 4px 22px;font-size:14px;line-height:1.5;\">");
        foreach (var l in lineas) h.Append($"<p style=\"margin:0 0 8px 0;\">{Esc(l)}</p>");
        h.Append("</td></tr>");

        h.Append("<tr><td style=\"padding:8px 22px;\"><table role=\"presentation\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" style=\"border-top:1px solid " + Borde + ";\">");
        foreach (var (k, v) in datos)
            h.Append($"<tr><td style=\"padding:7px 10px 7px 0;width:38%;vertical-align:top;font-size:12px;color:{Gris};border-bottom:1px solid {Borde};\">{Esc(k)}</td><td style=\"padding:7px 0;vertical-align:top;font-size:13px;border-bottom:1px solid {Borde};\">{Esc(v)}</td></tr>");
        h.Append("</table></td></tr>");

        if (!string.IsNullOrWhiteSpace(d.Observaciones))
        {
            h.Append("<tr><td style=\"padding:10px 22px 4px 22px;\">");
            h.Append($"<div style=\"font-size:12px;color:{Gris};margin-bottom:4px;\">Detalles adicionales del solicitante</div>");
            h.Append($"<div style=\"border-left:3px solid {Azul};background:#f6f8fb;padding:8px 12px;font-size:13px;line-height:1.5;\">{Esc(d.Observaciones!).Replace("\n", "<br>")}</div>");
            h.Append("</td></tr>");
        }

        if (personas.Count > 0)
        {
            h.Append("<tr><td style=\"padding:14px 22px 4px 22px;\">");
            h.Append($"<div style=\"font-size:12px;color:{Gris};margin-bottom:6px;\">Personas ({personas.Count})</div>");
            h.Append($"<table role=\"presentation\" width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" style=\"border:1px solid {Borde};font-size:12px;\">");
            h.Append($"<tr style=\"background:#f3f5f8;color:{Gris};\"><td style=\"padding:6px 8px;\">Nombre</td><td style=\"padding:6px 8px;\">Documento</td><td style=\"padding:6px 8px;\">Aprobación</td></tr>");
            foreach (var p in personas)
            {
                var extra = new List<string>();
                if (p.Trae_Equipos) extra.Add("trae equipos");
                if (p.Trae_Herramientas) extra.Add("trae herramientas");
                var nota = new List<string>();
                if (!string.IsNullOrWhiteSpace(p.Aprobacion_Mensaje) && p.Aprobacion != "APROBADA") nota.Add(p.Aprobacion_Mensaje!);
                if (extra.Count > 0) nota.Add(string.Join(", ", extra));
                h.Append($"<tr><td style=\"padding:6px 8px;border-top:1px solid {Borde};\">{Esc(p.Nombre_Completo)}</td>");
                h.Append($"<td style=\"padding:6px 8px;border-top:1px solid {Borde};\">{Esc((p.Tipo_Documento ?? "") + " " + p.Numero_Documento)}</td>");
                h.Append($"<td style=\"padding:6px 8px;border-top:1px solid {Borde};\">{Esc(EtiquetaPersona(p.Aprobacion))}{(nota.Count > 0 ? $"<div style=\"color:{Gris};font-size:11px;\">{Esc(string.Join(" · ", nota))}</div>" : "")}</td></tr>");
            }
            h.Append("</table></td></tr>");
        }

        if (url is not null)
            h.Append($"<tr><td style=\"padding:18px 22px 6px 22px;\"><a href=\"{Esc(url)}\" style=\"display:inline-block;background:{Azul};color:#ffffff;text-decoration:none;padding:10px 20px;border-radius:4px;font-size:14px;\">Ver solicitud</a></td></tr>");
        h.Append($"<tr><td style=\"padding:20px 22px;font-size:11px;color:{Gris};line-height:1.5;\">Mensaje automático del sistema Control de Accesos. Esta casilla no se monitorea: no responda a este correo; para actuar sobre la solicitud ingrese al sistema.</td></tr>");
        h.Append("</table></td></tr></table></body></html>");

        // ── Texto plano ───────────────────────────────────────
        var x = new StringBuilder();
        if (!string.IsNullOrWhiteSpace(aviso)) x.AppendLine(aviso).AppendLine();
        x.AppendLine(titulo.ToUpperInvariant()).AppendLine();
        foreach (var l in lineas) x.AppendLine(l);
        x.AppendLine();
        foreach (var (k, v) in datos) x.AppendLine($"{k}: {v}");
        if (!string.IsNullOrWhiteSpace(d.Observaciones)) x.AppendLine().AppendLine("Detalles adicionales del solicitante:").AppendLine(d.Observaciones);
        if (personas.Count > 0)
        {
            x.AppendLine().AppendLine($"Personas ({personas.Count}):");
            foreach (var p in personas)
                x.AppendLine($" - {p.Nombre_Completo} · {p.Tipo_Documento} {p.Numero_Documento} · {EtiquetaPersona(p.Aprobacion)}");
        }
        if (url is not null) x.AppendLine().AppendLine($"Ver solicitud: {url}");
        x.AppendLine().AppendLine("Mensaje automático. Esta casilla no se monitorea.");

        return new CorreoArmado(Asunto(d, esRespuesta), h.ToString(), x.ToString());
    }

    private static string Responsable(Dto_Correo_Solicitud d)
    {
        if (string.IsNullOrWhiteSpace(d.Responsable_Nombre)) return "-";
        return d.Responsable_Nombre + (string.IsNullOrWhiteSpace(d.Responsable_Area) ? "" : $" ({d.Responsable_Area})");
    }

    private static string Resumen(Dto_Correo_Solicitud d)
    {
        var partes = new List<string> { $"{d.Total_Personas} en total" };
        if (d.Autorizadas > 0) partes.Add($"{d.Autorizadas} autorizada(s)");
        if (d.Pendientes > 0) partes.Add($"{d.Pendientes} pendiente(s)");
        if (d.Observadas > 0) partes.Add($"{d.Observadas} observada(s)");
        if (d.Rechazadas > 0) partes.Add($"{d.Rechazadas} rechazada(s)");
        return string.Join(" · ", partes);
    }

    private static string EtiquetaPersona(string a) => a switch
    {
        "PENDIENTE" => "Pendiente", "APROBADA" => "Autorizada", "OBSERVADA" => "Observada",
        "RECHAZADA" => "Rechazada", "RETIRADA" => "Retirada", _ => a
    };

    private static string Esc(string s) => WebUtility.HtmlEncode(s);
}
