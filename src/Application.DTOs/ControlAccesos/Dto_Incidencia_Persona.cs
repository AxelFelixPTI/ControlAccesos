// ============================================================
// Archivo  : Dto_Incidencia_Persona.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 2 — DTOs
// Entidad  : Incidencia_Persona
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_INCIDENCIA_PERSONAS_LISTAR: persona involucrada en una incidencia.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Incidencia_Persona
{
    public long ID_Solicitud_Persona { get; set; }
    public long ID_Solicitud { get; set; }
    public string Codigo_Solicitud { get; set; } = string.Empty;
    public string? Tipo_Documento { get; set; }
    public string? Numero_Documento { get; set; }
    public string Persona_Nombre { get; set; } = string.Empty;
    public string? Empresa_Visitante { get; set; }
    public string Estado_Persona { get; set; } = string.Empty;
}
