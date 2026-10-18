// ============================================================
// Archivo  : Dto_Porteria_Entradas.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 2 — DTOs
// Entidad  : Portería — formularios y filtros
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Lo que la pantalla ENVÍA. Las listas se convierten en el texto que esperan las rutinas (id:Y,id:N / 1,2,3).
// Las reglas de negocio viven en la rutina (D-40).

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

/// <summary>Respuesta de Vigilancia a un ítem del checklist.</summary>
public sealed class Dto_Porteria_Respuesta
{
    public long ID_Catalogo_Item_Checklist { get; set; }
    /// <summary>true = cumple (Y); false = no cumple (N).</summary>
    public bool Cumple { get; set; }
}

/// <summary>Desviación que se levanta cuando algún ítem no cumple (ingreso o salida).</summary>
public sealed class Dto_Porteria_Desviacion_Entrada
{
    public string? Descripcion { get; set; }
    /// <summary>Coordinador consultado (ver ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN).</summary>
    public long? ID_Coordinador { get; set; }
    public long? ID_Tratamiento { get; set; }
    /// <summary>Obligatorio con el tratamiento «Otro».</summary>
    public string? Tratamiento_Detalle { get; set; }
    /// <summary>Solo con «Otro»: el efecto que decide el Coordinador.</summary>
    public string? Resultado_Elegido { get; set; }
}

/// <summary>Registrar un ingreso (ERP_CAF_PORTERIA_INGRESO_REGISTRAR).</summary>
public sealed class Dto_Porteria_Ingreso
{
    [Range(1, long.MaxValue, ErrorMessage = "Falta la persona.")]
    public long ID_Solicitud_Persona { get; set; }
    /// <summary>TODOS los ítems que devolvió el checklist, cumplan o no.</summary>
    public List<Dto_Porteria_Respuesta> Items { get; set; } = new();
    public bool Trae_Equipos { get; set; }
    public bool Trae_Herramientas { get; set; }
    public string? Observacion { get; set; }
    /// <summary>Solo si algún ítem no cumple.</summary>
    public Dto_Porteria_Desviacion_Entrada? Desviacion { get; set; }
    /// <summary>Solo para un registro tardío: hora real del hecho (la observación pasa a ser obligatoria).</summary>
    public DateTime? Fecha_Hora_Hecho { get; set; }
}

/// <summary>Registrar una salida (ERP_CAF_PORTERIA_SALIDA_REGISTRAR).</summary>
public sealed class Dto_Porteria_Salida
{
    [Range(1, long.MaxValue, ErrorMessage = "Falta la persona.")]
    public long ID_Solicitud_Persona { get; set; }
    public List<Dto_Porteria_Respuesta> Items { get; set; } = new();
    public string? Observacion { get; set; }
    public Dto_Porteria_Desviacion_Entrada? Desviacion { get; set; }
    public DateTime? Fecha_Hora_Hecho { get; set; }
}

/// <summary>Resultado de registrar un movimiento.</summary>
public sealed class Dto_Porteria_Registrado
{
    public long ID_Registro_Acceso { get; set; }
    /// <summary>Nulo si no hubo desviación.</summary>
    public long? ID_Desviacion { get; set; }
    /// <summary>INGRESA, INGRESA_RESTRINGIDO, NO_INGRESA, SALE o SALE_RETIENE_ELEMENTO.</summary>
    public string Resultado { get; set; } = string.Empty;
}

/// <summary>Registrar un respaldo (G-FSCA-009, guía de remisión o G-FSCA-010).</summary>
public sealed class Dto_Respaldo_Registrar
{
    /// <summary>EQUIPOS o HERRAMIENTAS_MATERIALES.</summary>
    public string Categoria { get; set; } = string.Empty;
    /// <summary>G_FSCA_009, GUIA_REMISION o GUIA_MANUAL_G_FSCA_010.</summary>
    public string Tipo_Respaldo { get; set; } = string.Empty;
    /// <summary>Solo la guía de remisión lleva número.</summary>
    public string? Numero_Documento { get; set; }
    public List<long> IDs_Solicitud_Persona { get; set; } = new();
    public string? Observacion { get; set; }
}

/// <summary>Filtros de la bitácora de portería. Fechas nulas = hoy.</summary>
public sealed class Dto_Filtro_Movimientos
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
    /// <summary>INGRESO, SALIDA o nulo (ambos).</summary>
    public string? Tipo { get; set; }
    public string? Texto { get; set; }
}

/// <summary>Filtros del listado de desviaciones.</summary>
public sealed class Dto_Filtro_Desviaciones
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }
    /// <summary>POR_REVISAR, REVISADA o nulo (todas).</summary>
    public string? Estado { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
    public string? Texto { get; set; }
}
