// ============================================================
// Archivo  : Dto_Porteria_Ficha.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 2 — DTOs
// Entidad  : Porteria_Ficha
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_PORTERIA_FICHA: ficha de la persona en portería, con botones y motivos.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Porteria_Ficha
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
    public DateTime? Fecha_Hora_Ingreso { get; set; }
    public DateTime? Fecha_Hora_Salida { get; set; }
    public bool Acceso_Restringido { get; set; }
    public bool Trae_Equipos { get; set; }
    public bool Trae_Herramientas { get; set; }
    public bool Exige_SCTR { get; set; }
    public bool Exige_EPP { get; set; }
    public string? Zonas_Nombres { get; set; }
    public bool Tiene_Respaldo_Equipos { get; set; }
    public bool Tiene_Respaldo_Herramientas { get; set; }
    public bool Puede_Registrar_Ingreso { get; set; }
    public string? Motivo_No_Ingreso { get; set; }
    public bool Puede_Registrar_Ingreso_Tardio { get; set; }
    public bool Puede_Registrar_Salida { get; set; }
    public string? Motivo_No_Salida { get; set; }
}
