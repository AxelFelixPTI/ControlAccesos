// ============================================================
// Archivo  : Dto_Solicitud_Contadores.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 2 — DTOs
// Entidad  : Solicitud_Contadores
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_SOLICITUD_CONTADORES: números de las pestañas.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_solicitud.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Solicitud_Contadores
{
    public int Mis_Con_Observadas { get; set; }
    public int Por_Decidir_Solicitudes { get; set; }
    public int Por_Decidir_Personas { get; set; }
}
