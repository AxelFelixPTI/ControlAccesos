// ============================================================
// Archivo  : Dto_Incidencia_Contadores.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 2 — DTOs
// Entidad  : Incidencia_Contadores
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_INCIDENCIA_CONTADORES: números de las pestañas de incidencias.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Incidencia_Contadores
{
    public long Registradas { get; set; }
    public long Confirmadas { get; set; }
    public long Desestimadas { get; set; }
}
