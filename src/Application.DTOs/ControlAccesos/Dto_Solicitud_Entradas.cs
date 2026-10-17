// ============================================================
// Archivo  : Dto_Solicitud_Entradas.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 2 — DTOs
// Entidad  : Solicitud — formularios y filtros
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Lo que la pantalla ENVÍA. Los identificadores múltiples van como lista y el repositorio los convierte al texto
// separado por comas que esperan las rutinas. Las reglas de negocio viven en la rutina (D-40).

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

/// <summary>Datos para crear y enviar una solicitud (ERP_CAF_SOLICITUD_CREAR).</summary>
public sealed class Dto_Solicitud_Crear
{
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione la sede.")]
    public long ID_Catalogo_Sede { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Seleccione el tipo de acceso.")]
    public long ID_Catalogo_Tipo_Acceso { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Seleccione al responsable.")]
    public long ID_Personal_Responsable { get; set; }

    public DateTime Fecha_Hora_Prevista { get; set; }

    [StringLength(250, ErrorMessage = "La empresa no puede superar 250 caracteres.")]
    public string? Empresa_Visitante { get; set; }

    public long? ID_Catalogo_Motivo_Visita { get; set; }
    public string? Motivo_Detalle { get; set; }
    public string? Observaciones { get; set; }

    /// <summary>Zonas a visitar.</summary>
    public List<long> IDs_Zona { get; set; } = new();

    /// <summary>Personas externas de la visita (al menos una).</summary>
    public List<long> IDs_Persona_Externa { get; set; } = new();

    /// <summary>Correos en copia, separados por «;» o «,» (la rutina los valida).</summary>
    public string? Copias { get; set; }

    /// <summary>Solicitud de la que se reutilizan los datos («Reutilizar»), si hay.</summary>
    public long? ID_Solicitud_Origen { get; set; }
}

/// <summary>Resultado de crear: identificador y código visible (SOL-00001).</summary>
public sealed class Dto_Solicitud_Creada
{
    public long ID_Solicitud { get; set; }
    public string Codigo { get; set; } = string.Empty;
}

/// <summary>Datos que se pueden cambiar de una solicitud (ERP_CAF_SOLICITUD_EDITAR_DATOS).</summary>
public sealed class Dto_Solicitud_Editar
{
    public DateTime Fecha_Hora_Prevista { get; set; }
    public string? Empresa_Visitante { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Seleccione al responsable.")]
    public long ID_Personal_Responsable { get; set; }

    public long? ID_Catalogo_Motivo_Visita { get; set; }
    public string? Motivo_Detalle { get; set; }
    public string? Observaciones { get; set; }
    public List<long> IDs_Zona { get; set; } = new();
    public string? Copias { get; set; }
}

/// <summary>Decisión de quien aprueba (ERP_CAF_SOLICITUD_DECIDIR).</summary>
public sealed class Dto_Solicitud_Decidir
{
    [Range(1, long.MaxValue, ErrorMessage = "Falta la solicitud.")]
    public long ID_Solicitud { get; set; }

    [Range(1, long.MaxValue, ErrorMessage = "Falta el paso de aprobación.")]
    public long ID_Tipo_Acceso_Paso_Aprobacion { get; set; }

    /// <summary>APROBADA, OBSERVADA o RECHAZADA.</summary>
    public string Decision { get; set; } = string.Empty;

    /// <summary>Obligatorio si la decisión no es APROBADA (la rutina lo exige).</summary>
    public string? Mensaje { get; set; }

    /// <summary>Personas sobre las que se decide (pasos por persona). Vacío en pasos por solicitud.</summary>
    public List<long> IDs_Solicitud_Persona { get; set; } = new();
}

/// <summary>Filtros de «Mis solicitudes». Todo opcional.</summary>
public sealed class Dto_Filtro_Mis_Solicitudes
{
    public long? ID_Catalogo_Sede { get; set; }
    /// <summary>Busca sin distinguir tildes ni mayúsculas: código, empresa, persona o documento.</summary>
    public string? Texto { get; set; }
    public string? Estado { get; set; }
    public DateTime? Fecha_Desde { get; set; }
    public DateTime? Fecha_Hasta { get; set; }
}

/// <summary>Filtros de la bandeja de quien aprueba.</summary>
public sealed class Dto_Filtro_Bandeja
{
    public long? ID_Catalogo_Sede { get; set; }
    /// <summary>POR_DECIDIR o TODAS.</summary>
    public string Pestana { get; set; } = "TODAS";
    public string? Empresa { get; set; }
    public string? Solicitante { get; set; }
    public string? Persona { get; set; }
    public DateTime? Fecha { get; set; }
    public string? Estado { get; set; }
}

/// <summary>Filtros del listado de Vigilancia.</summary>
public sealed class Dto_Filtro_Vigilancia
{
    public long? ID_Catalogo_Sede { get; set; }
    /// <summary>Nulo = hoy.</summary>
    public DateTime? Fecha { get; set; }
    public string? Texto { get; set; }
    /// <summary>POR_INGRESAR, DENTRO, SALIERON o DENEGADOS_NO_VINIERON. Nulo = todos.</summary>
    public string? Grupo { get; set; }
}

/// <summary>Alta o cambio de un paso de aprobación de un tipo de acceso (administración).</summary>
public sealed class Dto_Tipo_Acceso_Paso_Entrada
{
    [Range(1, long.MaxValue, ErrorMessage = "Falta el tipo de acceso.")]
    public long ID_Catalogo_Tipo_Acceso { get; set; }
    public long Orden { get; set; } = 1;
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    /// <summary>PERSONA o SOLICITUD.</summary>
    public string Alcance { get; set; } = "PERSONA";
    /// <summary>Hoy solo ROL.</summary>
    public string Tipo_Aprobador { get; set; } = "ROL";
    [Range(1, long.MaxValue, ErrorMessage = "Seleccione el rol que aprueba.")]
    public long ID_Catalogo_Licencia { get; set; }
    public string Condicion { get; set; } = "SIEMPRE";
    public bool Obligatorio { get; set; } = true;
    public bool Activo { get; set; } = true;
}
