// ============================================================
// Datos de una solicitud para armar el correo (ERP_CAF_CORREO_SOLICITUD_DATOS / _PERSONAS).
// Solo los lee el proceso de envío (usuario del sistema 0).
// ============================================================

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Correo_Solicitud
{
    public long ID_Solicitud { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public DateTime Fecha_Hora_Prevista { get; set; }
    public string? Sede { get; set; }
    public string? Tipo_Acceso { get; set; }
    public string Empresa_Visitante { get; set; } = string.Empty;
    public string? Responsable_Nombre { get; set; }
    public string? Responsable_Correo { get; set; }
    public string? Responsable_Area { get; set; }
    public string? Motivo { get; set; }
    public string? Motivo_Detalle { get; set; }
    public string? Observaciones { get; set; }
    public string? Zonas_Nombres { get; set; }
    public string? Solicitante_Nombre { get; set; }
    public string? Solicitante_Correo { get; set; }
    public bool Exige_SCTR { get; set; }
    public bool Exige_EPP { get; set; }
    public int Total_Personas { get; set; }
    public int Autorizadas { get; set; }
    public int Observadas { get; set; }
    public int Pendientes { get; set; }
    public int Rechazadas { get; set; }
    public int Retiradas { get; set; }
    public string? Observacion_Coordinador { get; set; }
    public string? Motivo_Cancelacion { get; set; }
    public long Version { get; set; }
    public DateTime? Fecha_Envio { get; set; }
    /// <summary>Asunto del aviso de solicitud nueva (código + empresa de la creación): se usa en todo el hilo. Vacío en solicitudes anteriores.</summary>
    public string? Asunto_Hilo { get; set; }
    // Entrega H
    public string? Tipo_Acceso_Codigo { get; set; }
    public bool Requiere_Cochera { get; set; }
    public string? Placa_Vehiculo { get; set; }
    public string? Area_Detalle { get; set; }
    public string? Contacto_Nombre { get; set; }
    public string? Contacto_Telefonos { get; set; }
    public string? Contacto_Correos { get; set; }
}

public sealed class Dto_Correo_Solicitud_Persona
{
    public long ID_Solicitud_Persona { get; set; }
    public string? Tipo_Documento { get; set; }
    public string Numero_Documento { get; set; } = string.Empty;
    public string Nombre_Completo { get; set; } = string.Empty;
    public string Aprobacion { get; set; } = string.Empty;
    public string? Aprobacion_Mensaje { get; set; }
    public bool Trae_Equipos { get; set; }
    public bool Trae_Herramientas { get; set; }
}
