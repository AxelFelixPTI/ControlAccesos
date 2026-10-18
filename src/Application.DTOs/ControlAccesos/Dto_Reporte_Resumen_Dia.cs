// ============================================================
// Archivo  : Dto_Reporte_Resumen_Dia.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 2 — DTOs
// Entidad  : Reporte_Resumen_Dia
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_REPORTE_RESUMEN_DIARIO: totales de un día.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Reporte_Resumen_Dia
{
    public DateTime Fecha { get; set; }
    public long Ingresos { get; set; }
    public long Ingresos_Restringidos { get; set; }
    public long Ingresos_Denegados { get; set; }
    public long Salidas { get; set; }
    public long Desviaciones { get; set; }
    public long Incidencias { get; set; }
}
