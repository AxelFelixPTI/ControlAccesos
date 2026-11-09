// ============================================================
// Archivo  : Dto_Proveedor_Grupo.cs
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación (D-225: varios transportistas y ayudantes por entrega)
// Versión  : V1.0 — 2026-11-09
// ============================================================
namespace Application.DTOs.ControlAccesos;

/// <summary>
/// Verificar datos o registrar la salida de varias personas de una misma entrega con UN solo checklist.
/// Las respuestas son la unión de los ítems de la selección; cada persona guarda solo los que le aplican.
/// </summary>
public sealed class Dto_Proveedor_Grupo
{
    public long ID_Solicitud { get; set; }
    public List<long> IDs_Persona { get; set; } = new();
    public List<Dto_Porteria_Respuesta> Items { get; set; } = new();
    public string? Observacion { get; set; }
    /// <summary>Solo si algún ítem no cumple.</summary>
    public Dto_Porteria_Desviacion_Entrada? Desviacion { get; set; }
}
