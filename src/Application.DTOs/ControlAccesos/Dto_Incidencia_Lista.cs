// ============================================================
// Archivo  : Dto_Incidencia_Lista.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 2 — DTOs
// Entidad  : Incidencia_Lista
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_INCIDENCIA_LISTAR: fila del listado de incidencias.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Incidencia_Lista
{
    public long ID_Incidencia { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public DateTime Fecha_Hora_Hecho { get; set; }
    public string Tipo_Codigo { get; set; } = string.Empty;
    public string Tipo_Descripcion { get; set; } = string.Empty;
    public string? Zona_Descripcion { get; set; }
    public string? Lugar_Detalle { get; set; }
    public string Descripcion { get; set; } = string.Empty;
    public string Origen { get; set; } = string.Empty;
    public string? Registrador_Nombre { get; set; }
    public string Estado { get; set; } = string.Empty;
    public long Cantidad_Personas { get; set; }
    public DateTime? Fecha_Decision { get; set; }
}
