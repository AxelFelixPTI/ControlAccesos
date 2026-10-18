// ============================================================
// Archivo  : Dto_Desviacion_Tratamiento.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 2 — DTOs
// Entidad  : Desviacion_Tratamiento
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN: tratamiento válido para la etapa.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Desviacion_Tratamiento
{
    public long ID_Catalogo_Tratamiento_Desviacion { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public bool Es_Otro { get; set; }
    public string? Resultado { get; set; }
}
