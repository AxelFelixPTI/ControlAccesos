// ============================================================
// Archivo  : Dto_Desviacion_Detalle.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 2 — DTOs
// Entidad  : Desviacion_Detalle
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_DESVIACION_DETALLE: desviación completa, con el botón de conformidad.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Desviacion_Detalle
{
    public long ID_Desviacion { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public long ID_Registro_Acceso { get; set; }
    public long ID_Solicitud { get; set; }
    public string Codigo_Solicitud { get; set; } = string.Empty;
    public string Tipo_Movimiento { get; set; } = string.Empty;
    public string? Resultado { get; set; }
    public DateTime Fecha_Hora { get; set; }
    public string Persona_Nombre { get; set; } = string.Empty;
    public string? Numero_Documento { get; set; }
    public string? Empresa_Visitante { get; set; }
    public string Descripcion { get; set; } = string.Empty;
    public long ID_Catalogo_Tratamiento_Desviacion { get; set; }
    public string? Tratamiento { get; set; }
    public string? Tratamiento_Detalle { get; set; }
    public long? ID_Usuario_Coordinador_Consultado { get; set; }
    public string? Coordinador_Nombre { get; set; }
    public string? Registrado_Por_Nombre { get; set; }
    public string Estado { get; set; } = string.Empty;
    public string? Conformidad_Nombre { get; set; }
    public DateTime? Fecha_Conformidad { get; set; }
    public string? Comentario_Conformidad { get; set; }
    public long? ID_Incidencia { get; set; }
    public bool Puede_Dar_Conformidad { get; set; }
    public string? Motivo_No_Conformidad { get; set; }
}
