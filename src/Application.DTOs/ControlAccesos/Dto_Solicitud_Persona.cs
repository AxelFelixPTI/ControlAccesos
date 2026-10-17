// ============================================================
// Archivo  : Dto_Solicitud_Persona.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 2 — DTOs
// Entidad  : Solicitud_Persona
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_SOLICITUD_PERSONAS_LISTAR: persona de una solicitud, con su aprobación y botones.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_solicitud.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Solicitud_Persona
{
    public long ID_Solicitud_Persona { get; set; }
    public long ID_Persona_Externa { get; set; }
    public long? ID_Catalogo_Tipo_Documento { get; set; }
    public string? Tipo_Documento { get; set; }
    public string? Numero_Documento { get; set; }
    public string? Apellido_Paterno { get; set; }
    public string? Apellido_Materno { get; set; }
    public string? Nombres { get; set; }
    public string Nombre_Completo { get; set; } = string.Empty;
    public string? Aprobacion { get; set; }
    public string? Aprobacion_Mensaje { get; set; }
    public string? Aprobado_Por_Nombre { get; set; }
    public DateTime? Fecha_Aprobacion { get; set; }
    public string? Origen { get; set; }
    public string Estado { get; set; } = string.Empty;
    public bool Acceso_Restringido { get; set; }
    public bool Trae_Equipos { get; set; }
    public bool Trae_Herramientas { get; set; }
    public DateTime? Fecha_Hora_Ingreso { get; set; }
    public DateTime? Fecha_Hora_Salida { get; set; }
    public bool Puede_Retirar { get; set; }
    public bool Puede_Corregir { get; set; }
    public bool Puede_Reactivar { get; set; }
    public bool Puede_Decidir { get; set; }
    public string? Pasos_Mis_Decidir { get; set; }
}
