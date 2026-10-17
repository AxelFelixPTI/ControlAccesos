// ============================================================
// Archivo  : Dto_Solicitud_Paso.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 2 — DTOs
// Entidad  : Solicitud_Paso
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_SOLICITUD_PASOS_LISTAR: persona × paso de la ruta de aprobación.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_solicitud.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Solicitud_Paso
{
    public long ID_Solicitud_Persona { get; set; }
    public string Persona_Nombre { get; set; } = string.Empty;
    public long ID_Tipo_Acceso_Paso_Aprobacion { get; set; }
    public long Paso_Orden { get; set; }
    public string Paso_Codigo { get; set; } = string.Empty;
    public string? Paso_Descripcion { get; set; }
    public string? Paso_Alcance { get; set; }
    public bool Obligatorio { get; set; }
    public string? Rol_Aprobador { get; set; }
    public string Decision { get; set; } = string.Empty;
    public string? Mensaje { get; set; }
    public string? Decidio_Nombre { get; set; }
    public DateTime? Fecha_Decision { get; set; }
    public bool Es_Mi_Turno { get; set; }
}
