// ============================================================
// Archivo  : Dto_Incidencia_Detalle.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 2 — DTOs
// Entidad  : Incidencia_Detalle
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_INCIDENCIA_DETALLE: incidencia completa, con el botón de decidir.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Incidencia_Detalle
{
    public long ID_Incidencia { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public long ID_Catalogo_Sede { get; set; }
    public DateTime Fecha_Hora_Hecho { get; set; }
    public long ID_Catalogo_Tipo_Incidencia { get; set; }
    public string Tipo_Descripcion { get; set; } = string.Empty;
    public string? Tipo_Detalle { get; set; }
    public long? ID_Catalogo_Zona_Acceso { get; set; }
    public string? Zona_Descripcion { get; set; }
    public string? Lugar_Detalle { get; set; }
    public string Descripcion { get; set; } = string.Empty;
    public string Origen { get; set; } = string.Empty;
    public string? Registrador_Nombre { get; set; }
    public string Estado { get; set; } = string.Empty;
    public string? Decisor_Nombre { get; set; }
    public DateTime? Fecha_Decision { get; set; }
    public string? Sustento_Decision { get; set; }
    public bool Puede_Decidir { get; set; }
}
