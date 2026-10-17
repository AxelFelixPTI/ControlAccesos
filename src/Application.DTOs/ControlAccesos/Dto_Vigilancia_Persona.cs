// ============================================================
// Archivo  : Dto_Vigilancia_Persona.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 2 — DTOs
// Entidad  : Vigilancia_Persona
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR: persona esperada hoy en portería.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_solicitud.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Vigilancia_Persona
{
    public long ID_Solicitud_Persona { get; set; }
    public long ID_Solicitud { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public long ID_Catalogo_Sede { get; set; }
    public DateTime Fecha_Hora_Prevista { get; set; }
    public string? Empresa_Visitante { get; set; }
    public string? Responsable_Nombre { get; set; }
    public string? Tipo_Documento { get; set; }
    public string? Numero_Documento { get; set; }
    public string Persona_Nombre { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public string Grupo { get; set; } = string.Empty;
    public DateTime? Fecha_Hora_Ingreso { get; set; }
    public DateTime? Fecha_Hora_Salida { get; set; }
    public bool Acceso_Restringido { get; set; }
    public bool Trae_Equipos { get; set; }
    public bool Trae_Herramientas { get; set; }
    public bool Exige_SCTR { get; set; }
    public bool Exige_EPP { get; set; }
    public string? Zonas_Nombres { get; set; }
}
