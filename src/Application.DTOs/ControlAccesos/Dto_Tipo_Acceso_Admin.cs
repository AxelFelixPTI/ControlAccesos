// ============================================================
// Archivo  : Dto_Tipo_Acceso_Admin.cs
// Ruta     : Application.DTOs/ControlAccesos/
// Versión  : V1.0 — 2026-11-11 (D-232)
// Qué es   : una fila de la pantalla «Tipos de ingreso» (con sus subtipos y cuánto tiene configurado) y un subtipo de persona.
// SP base  : ERP_CAF_TIPO_ACCESO_ADMIN_LISTAR, ERP_CAF_SUBTIPO_LISTAR
// ============================================================

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Tipo_Acceso_Admin
{
    public long ID_Catalogo_Tipo_Acceso { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public string Requiere_Aprobacion { get; set; } = "Y";
    public string Disponible { get; set; } = "N";
    public long Orden { get; set; }
    public string Activo { get; set; } = "Y";
    public string? Subtipos { get; set; }       // «Transportista, Ayudante de descarga»; nulo si el tipo no tiene
    public long Pasos { get; set; }             // pasos de aprobación
    public long Items { get; set; }             // ítems de checklist asignados
    public long Solicitudes { get; set; }       // solicitudes ya creadas con este tipo
}

public sealed class Dto_Subtipo
{
    // V1.1 2026-11-12 (D-234): + Orden, Activo, Es_Predeterminado, Es_Sistema, Personas
    public long ID_Tipo_Acceso_Subtipo { get; set; }
    public long ID_Catalogo_Tipo_Acceso { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public long Orden { get; set; }
    public string Activo { get; set; } = "Y";
    public string Es_Predeterminado { get; set; } = "N";
    public string Es_Sistema { get; set; } = "N";   // TRANSPORTISTA: lo usa el flujo de proveedores, no se desactiva
    public long Personas { get; set; }              // personas de solicitudes que ya tienen este rol
}
