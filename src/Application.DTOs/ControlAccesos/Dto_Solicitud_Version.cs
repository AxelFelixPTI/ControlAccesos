// ============================================================
// Archivo  : Dto_Solicitud_Version.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 2 — DTOs
// Entidad  : Solicitud_Version
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_SOLICITUD_VERSION_LISTAR: foto de lo aprobado (RN-08).
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_solicitud.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Solicitud_Version
{
    public long Version { get; set; }
    public DateTime? Fecha_Aprobacion { get; set; }
    public long? ID_Usuario_Aprobador { get; set; }
    public string? Aprobador_Nombre { get; set; }
    public string? Contenido_JSON { get; set; }
}
