// ============================================================
// Archivo  : Dto_Item_Checklist_Admin.cs
// Ruta     : Application.DTOs/ControlAccesos/
// Versión  : V1.0 — 2026-11-10
// Qué es   : una fila de la pantalla «Checklist de portería» (ítem + tipos de ingreso a los que se asigna + veces que se usó).
// SP base  : ERP_CAF_ITEM_CHECKLIST_ADMIN_LISTAR
// ============================================================

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Item_Checklist_Admin
{
    public long ID_Catalogo_Item_Checklist { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public string? Ayuda { get; set; }
    public string Etapa { get; set; } = string.Empty;        // INGRESO | SALIDA
    public string Condicion { get; set; } = string.Empty;
    public string Es_Critico { get; set; } = "N";
    public long Orden { get; set; }
    public string Activo { get; set; } = "Y";
    public string? Tipos_IDs { get; set; }                   // «1,3»; nulo si no está asignado a ningún tipo
    public long Usos { get; set; }                           // veces que ya se respondió en portería
}
