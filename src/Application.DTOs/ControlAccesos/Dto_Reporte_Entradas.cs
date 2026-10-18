// ============================================================
// Archivo  : Dto_Reporte_Entradas.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 2 — DTOs
// Entidad  : Reporte — filtros
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Todos los reportes exigen rango de fechas (máximo 92 días, D-83).

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

/// <summary>Filtros del reporte de accesos.</summary>
public sealed class Dto_Filtro_Reporte_Accesos
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    public DateTime Fecha_Desde { get; set; }
    public DateTime Fecha_Hasta { get; set; }
    /// <summary>INGRESO, SALIDA o nulo (ambos).</summary>
    public string? Tipo { get; set; }
    /// <summary>INGRESA, INGRESA_RESTRINGIDO, NO_INGRESA, SALE, SALE_RETIENE_ELEMENTO o nulo.</summary>
    public string? Resultado { get; set; }
    public string? Texto { get; set; }
}

/// <summary>Rango de fechas del resumen diario.</summary>
public sealed class Dto_Filtro_Reporte_Rango
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    public DateTime Fecha_Desde { get; set; }
    public DateTime Fecha_Hasta { get; set; }
}

/// <summary>Autorizados a una zona en una fecha.</summary>
public sealed class Dto_Filtro_Reporte_Zona
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    [Range(1, long.MaxValue, ErrorMessage = "Elija la zona.")]
    public long ID_Catalogo_Zona_Acceso { get; set; }
    public DateTime Fecha { get; set; }
}
