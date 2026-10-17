// ============================================================
// Archivo  : Dto_Solicitud_Detalle.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 2 — DTOs
// Entidad  : Solicitud_Detalle
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_SOLICITUD_DETALLE: cabecera completa de una solicitud, con botones.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_solicitud.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Solicitud_Detalle
{
    public long ID_Solicitud { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public long ID_Catalogo_Sede { get; set; }
    public string Sede { get; set; } = string.Empty;
    public long ID_Catalogo_Tipo_Acceso { get; set; }
    public string Tipo_Acceso { get; set; } = string.Empty;
    public DateTime Fecha_Hora_Prevista { get; set; }
    public string? Empresa_Visitante { get; set; }
    public long? ID_Personal_Responsable { get; set; }
    public string? Responsable_Nombre { get; set; }
    public string? Responsable_Correo { get; set; }
    public string? Responsable_Area { get; set; }
    public long? ID_Catalogo_Motivo_Visita { get; set; }
    public string? Motivo { get; set; }
    public string? Motivo_Detalle { get; set; }
    public string? Observaciones { get; set; }
    public bool Exige_SCTR { get; set; }
    public bool Exige_EPP { get; set; }
    public string Estado { get; set; } = string.Empty;
    public string? Avance { get; set; }
    public long Version { get; set; }
    public DateTime? Fecha_Envio { get; set; }
    public long? ID_Usuario_Solicitante { get; set; }
    public string? Solicitante_Nombre { get; set; }
    public string? Solicitante_Correo { get; set; }
    public DateTime? Fecha_Decision { get; set; }
    public string? Usuario_Decision_Nombre { get; set; }
    public string? Observacion_Coordinador { get; set; }
    public string? Motivo_Cancelacion { get; set; }
    public long? ID_Solicitud_Origen { get; set; }
    public string? Codigo_Origen { get; set; }
    public string? Zonas_IDs { get; set; }
    public string? Zonas_Nombres { get; set; }
    public string? Copias { get; set; }
    public DateTime? CreateDate { get; set; }
    public int Total_Personas { get; set; }
    public int Autorizadas { get; set; }
    public int Observadas { get; set; }
    public int Pendientes { get; set; }
    public int Rechazadas { get; set; }
    public int Retiradas { get; set; }
    public bool Es_Propia { get; set; }
    public bool Puede_Editar_Datos { get; set; }
    public string? Motivo_No_Editar_Datos { get; set; }
    public bool Puede_Modificar_Personal { get; set; }
    public string? Motivo_No_Modificar_Personal { get; set; }
    public bool Puede_Cancelar { get; set; }
    public string? Motivo_No_Cancelar { get; set; }
    public bool Puede_Reutilizar { get; set; }
    public bool Puede_Decidir { get; set; }
    public int Por_Decidir_Mis { get; set; }
}
