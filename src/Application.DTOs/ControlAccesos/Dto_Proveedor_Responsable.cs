// ============================================================
// Archivo  : Dto_Proveedor_Responsable.cs
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación (Entrega 2 de Proveedor de abastecimiento)
// Versión  : V1.0 — 2026-11-03
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_PROVEEDOR_RESPONSABLES (personal de Almacén elegible) y de ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Proveedor_Responsable
{
    public long ID_Personal { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string? Cargo { get; set; }
}

public sealed class Dto_Proveedor_Exclusa
{
    public bool Ocupada { get; set; }
    public string Estado { get; set; } = "LIBRE";   // LIBRE | RESERVADA | DENTRO | EN_ATENCION
    public long? ID_Solicitud { get; set; }
    public string? Codigo { get; set; }
    public string? Empresa { get; set; }
    public DateTime? Desde { get; set; }
    public string? Atiende { get; set; }
    public int Capacidad { get; set; } = 1;       // D-247: plazas de la esclusa
    public int Usadas { get; set; }               // D-247: plazas reservadas u ocupadas ahora
    public List<Dto_Proveedor_Exclusa> Plazas { get; set; } = new();   // D-247: una por entrega que ocupa una plaza (la primera repite los campos de arriba)
}
