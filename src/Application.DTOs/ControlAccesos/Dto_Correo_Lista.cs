// ============================================================
// Archivo  : Dto_Correo_Lista.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 2 — DTOs
// Entidad  : Correo_Lista
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_CORREO_LISTAR: fila de la bandeja de correos (sin cuerpo).
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Correo_Lista
{
    public long ID_Correo_Pendiente { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public long? ID_Solicitud { get; set; }
    public string Codigo_Solicitud { get; set; } = string.Empty;
    public string Destinatarios { get; set; } = string.Empty;
    public string Asunto { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public long Intentos { get; set; }
    public string? Ultimo_Error { get; set; }
    public DateTime CreateDate { get; set; }
    public DateTime? Fecha_Envio { get; set; }
}
