// ============================================================
// Archivo  : Dto_Respaldo.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 2 — DTOs
// Entidad  : Respaldo
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_RESPALDO_LISTAR_POR_PERSONA: respaldo que cubre a la persona.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Respaldo
{
    public long ID_Respaldo { get; set; }
    public string Categoria { get; set; } = string.Empty;
    public string Tipo_Respaldo { get; set; } = string.Empty;
    public string? Numero_Documento { get; set; }
    public DateTime Fecha_Hora { get; set; }
    public string? Vigilante_Nombre { get; set; }
    public string? Observacion { get; set; }
    public long Cantidad_Personas { get; set; }
}
