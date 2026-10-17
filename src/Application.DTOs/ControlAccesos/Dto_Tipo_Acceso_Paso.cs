// ============================================================
// Archivo  : Dto_Tipo_Acceso_Paso.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 2 — DTOs
// Entidad  : Tipo_Acceso_Paso
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE: paso de aprobación de un tipo de acceso.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_solicitud.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Tipo_Acceso_Paso
{
    public long ID_Tipo_Acceso_Paso_Aprobacion { get; set; }
    public long ID_Catalogo_Tipo_Acceso { get; set; }
    public long Orden { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public string? Alcance { get; set; }
    public string? Tipo_Aprobador { get; set; }
    public long? ID_Catalogo_Licencia { get; set; }
    public string? Codigo_Licencia { get; set; }
    public string? Rol { get; set; }
    public string? Condicion { get; set; }
    public bool Obligatorio { get; set; }
    public bool Activo { get; set; }
    public DateTime? CreateDate { get; set; }
}
