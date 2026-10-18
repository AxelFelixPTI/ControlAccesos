// ============================================================
// Archivo  : Dto_Desviacion_Coordinador.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 2 — DTOs
// Entidad  : Desviacion_Coordinador
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN: Coordinador al que se puede consultar.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Desviacion_Coordinador
{
    public long ID_Usuario { get; set; }
    public string Nombre { get; set; } = string.Empty;
}
