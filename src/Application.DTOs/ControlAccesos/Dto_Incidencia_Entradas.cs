// ============================================================
// Archivo  : Dto_Incidencia_Entradas.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 2 — DTOs
// Entidad  : Incidencia — formularios y filtros
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Lo que la pantalla ENVÍA. Las reglas de negocio viven en la rutina (D-40).

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

/// <summary>Registrar una incidencia (ERP_CAF_INCIDENCIA_REGISTRAR). El origen lo fija la rutina según el permiso (D-75).</summary>
public sealed class Dto_Incidencia_Registrar
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    [Range(1, long.MaxValue, ErrorMessage = "Elija el tipo de incidencia.")]
    public long ID_Catalogo_Tipo_Incidencia { get; set; }
    /// <summary>Obligatorio con el tipo «Otro».</summary>
    public string? Tipo_Detalle { get; set; }
    public DateTime Fecha_Hora_Hecho { get; set; }
    /// <summary>Zona del catálogo o, si no hay, un lugar escrito (al menos uno).</summary>
    public long? ID_Catalogo_Zona_Acceso { get; set; }
    public string? Lugar_Detalle { get; set; }
    public string Descripcion { get; set; } = string.Empty;
    /// <summary>Personas involucradas (opcional).</summary>
    public List<long> IDs_Solicitud_Persona { get; set; } = new();
}

/// <summary>Resultado de registrar una incidencia.</summary>
public sealed class Dto_Incidencia_Registrada
{
    public long ID_Incidencia { get; set; }
    /// <summary>INC-00001.</summary>
    public string Codigo { get; set; } = string.Empty;
}

/// <summary>Decisión del Coordinador (ERP_CAF_INCIDENCIA_DECIDIR).</summary>
public sealed class Dto_Incidencia_Decision
{
    [Range(1, long.MaxValue, ErrorMessage = "Falta la incidencia.")]
    public long ID_Incidencia { get; set; }
    /// <summary>CONFIRMAR o DESESTIMAR.</summary>
    public string Decision { get; set; } = string.Empty;
    public string Sustento { get; set; } = string.Empty;
}

/// <summary>Filtros del listado de incidencias.</summary>
public sealed class Dto_Filtro_Incidencias
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    /// <summary>REGISTRADA, CONFIRMADA, DESESTIMADA o nulo (todas).</summary>
    public string? Estado { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
    public string? Texto { get; set; }
}

/// <summary>Búsqueda de personas para involucrar en una incidencia. Fechas nulas = ayer y hoy.</summary>
public sealed class Dto_Filtro_Incidencia_Personas
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
    public string? Texto { get; set; }
}
