// ============================================================
// Archivo  : Dto_Solicitud_Bandeja.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 2 — DTOs
// Entidad  : Solicitud_Bandeja
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_SOLICITUD_BANDEJA_LISTAR: fila de la bandeja de quien aprueba.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_solicitud.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Solicitud_Bandeja
{
    public long ID_Solicitud { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public long ID_Catalogo_Sede { get; set; }
    public string Sede { get; set; } = string.Empty;
    public string Tipo_Acceso { get; set; } = string.Empty;
    public DateTime Fecha_Hora_Prevista { get; set; }
    public bool Es_Hoy { get; set; }
    public string? Empresa_Visitante { get; set; }
    public long? ID_Usuario_Solicitante { get; set; }
    public string? Solicitante_Nombre { get; set; }
    public string Estado { get; set; } = string.Empty;
    public string? Avance { get; set; }
    public int Total_Personas { get; set; }
    public int Autorizadas { get; set; }
    public int Observadas { get; set; }
    public int Pendientes { get; set; }
    public int Rechazadas { get; set; }
    public int Retiradas { get; set; }
    public int Por_Decidir_Mis { get; set; }
    public string? Personas_Nombres { get; set; }
    public DateTime? Fecha_Envio { get; set; }
}
