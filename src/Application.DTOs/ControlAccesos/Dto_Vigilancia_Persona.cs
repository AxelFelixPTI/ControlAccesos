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
    public bool Es_Proveedor { get; set; }                 // transportista principal de una entrega de proveedor
    public string? Estado_Operativo { get; set; }          // PROGRAMADO, EN_ESPERA, INGRESO, ... (solo proveedor)
    public string? Tipo_Acceso { get; set; }                // descripción del tipo de solicitud (filtro por tipo en pantalla)
    public bool Disponibilidad_Confirmada { get; set; }    // Almacén ya reservó la exclusa para esta entrega
    public bool Es_Transportista { get; set; }             // D-225: transportista (conduce un vehículo) frente a ayudante de descarga
    public bool Verificada { get; set; }
    /// <summary>D-227: NA (no es de franja), DENTRO o FUERA de la franja autorizada en este momento.</summary>
    public string? Tipo_Acceso_Codigo { get; set; }       // D-233
    public string? Empresa_Destino_Codigo { get; set; }   // D-233
    public string Franja_Estado { get; set; } = "NA";                   // D-225: Vigilancia ya verificó sus datos
}
