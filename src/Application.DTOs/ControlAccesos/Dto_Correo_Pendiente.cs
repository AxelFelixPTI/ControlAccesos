// ============================================================
// Archivo  : Dto_Correo_Pendiente.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 2 — DTOs
// Entidad  : Correo_Pendiente
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_CORREO_PENDIENTES_LISTAR: correo por enviar (solo lo lee el proceso de envío).
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Correo_Pendiente
{
    public long ID_Correo_Pendiente { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public long? ID_Solicitud { get; set; }
    public string Destinatarios { get; set; } = string.Empty;
    public string? Copia { get; set; }
    public string Asunto { get; set; } = string.Empty;
    public string Cuerpo { get; set; } = string.Empty;
    public long Intentos { get; set; }
    /// <summary>Correo de quien realizó la acción (a quien llega «Responder»). Vacío en correos sin solicitud.</summary>
    public string? Responder_A { get; set; }
    public string? Responder_A_Nombre { get; set; }
    /// <summary>Solo SOLICITUD_VIGILANCIA: las personas (ID_Solicitud_Persona, separadas por coma) que ese aviso autoriza.</summary>
    public string? IDs_Personas { get; set; }
}
