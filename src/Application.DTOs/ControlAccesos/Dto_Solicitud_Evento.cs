// ============================================================
// Archivo  : Dto_Solicitud_Evento.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 2 — DTOs
// Entidad  : Solicitud_Evento
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_SOLICITUD_HISTORIAL_LISTAR: evento del historial.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_solicitud.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Solicitud_Evento
{
    public long ID_Evento { get; set; }
    public DateTime Fecha_Evento { get; set; }
    public string Entidad { get; set; } = string.Empty;
    public string Accion { get; set; } = string.Empty;
    public string Accion_Texto { get; set; } = string.Empty;
    public string? Detalle { get; set; }
    public long? ID_Usuario { get; set; }
    public string? Usuario_Nombre { get; set; }
}
