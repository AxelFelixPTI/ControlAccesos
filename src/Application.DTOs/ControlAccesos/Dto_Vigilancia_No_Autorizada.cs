// ============================================================
// Archivo  : Dto_Vigilancia_No_Autorizada.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 2 — DTOs
// Entidad  : Vigilancia_No_Autorizada
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR: persona que aparece pero no está autorizada.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_solicitud.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Vigilancia_No_Autorizada
{
    public string Codigo { get; set; } = string.Empty;
    public string Persona_Nombre { get; set; } = string.Empty;
    public string? Numero_Documento { get; set; }
    public string? Empresa_Visitante { get; set; }
    public string Motivo_Codigo { get; set; } = string.Empty;
    public string? Motivo_Texto { get; set; }
}
