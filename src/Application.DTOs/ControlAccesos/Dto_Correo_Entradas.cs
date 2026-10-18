// ============================================================
// Archivo  : Dto_Correo_Entradas.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 2 — DTOs
// Entidad  : Correo — filtros
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Filtros de la bandeja de correos (Administrador).

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

/// <summary>Filtros de la bandeja de correos.</summary>
public sealed class Dto_Filtro_Correos
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    /// <summary>PENDIENTE, ENVIADO, ERROR o nulo (todos).</summary>
    public string? Estado { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
}
