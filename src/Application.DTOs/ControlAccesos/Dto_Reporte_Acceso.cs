// ============================================================
// Archivo  : Dto_Reporte_Acceso.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 2 — DTOs
// Entidad  : Reporte_Acceso
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_REPORTE_ACCESOS: fila del reporte de accesos (un movimiento).
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Reporte_Acceso
{
    public long ID_Registro_Acceso { get; set; }
    public DateTime Fecha_Hora { get; set; }
    public string Tipo_Movimiento { get; set; } = string.Empty;
    public string Resultado { get; set; } = string.Empty;
    public bool Es_Registro_Tardio { get; set; }
    public string Codigo_Solicitud { get; set; } = string.Empty;
    public string? Tipo_Documento { get; set; }
    public string? Numero_Documento { get; set; }
    public string Persona_Nombre { get; set; } = string.Empty;
    public string? Empresa_Visitante { get; set; }
    public string? Zonas { get; set; }
    public string? Vigilante_Nombre { get; set; }
    public long Items_Incumplidos { get; set; }
    public string? Codigo_Desviacion { get; set; }
    public string? Estado_Desviacion { get; set; }
    public string? Observacion { get; set; }
}
