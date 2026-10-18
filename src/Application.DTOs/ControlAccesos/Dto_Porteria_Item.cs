// ============================================================
// Archivo  : Dto_Porteria_Item.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 2 — DTOs
// Entidad  : Porteria_Item
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_PORTERIA_CHECKLIST_OBTENER: ítem del checklist que Vigilancia debe marcar.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Porteria_Item
{
    public long ID_Catalogo_Item_Checklist { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public string? Ayuda { get; set; }
    public bool Es_Critico { get; set; }
    public long Orden { get; set; }
}
