// ============================================================
// Archivo  : Dto_Proveedor_Entrega.cs
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación (Entrega 2 de Proveedor de abastecimiento)
// Versión  : V1.0 — 2026-11-03
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_PROVEEDOR_CALENDARIO: una entrega aprobada del calendario de Almacén.
// Puede_* ya vienen calculados para el usuario que consulta (permiso + estado + esclusa).

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Proveedor_Entrega
{
    public long ID_Solicitud { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public DateTime Fecha_Hora_Prevista { get; set; }
    public string Empresa_Proveedor { get; set; } = string.Empty;
    public string? Proveedor_RUC { get; set; }
    public string? Empresa_Destino { get; set; }
    public string Transportista { get; set; } = string.Empty;
    public string? Telefono { get; set; }
    public string? Placa { get; set; }
    public string? Vehiculo_Marca { get; set; }
    public string? Observaciones { get; set; }
    public int Cantidad_Apoyo { get; set; }
    public string Estado_Operativo { get; set; } = string.Empty;
    public DateTime? Fecha_Llegada { get; set; }
    public DateTime? Fecha_Ingreso { get; set; }
    public DateTime? Fecha_Inicio_Atencion { get; set; }
    public DateTime? Fecha_Recepcion { get; set; }
    public DateTime? Fecha_Salida { get; set; }
    public string? Resultado_Recepcion { get; set; }
    public long? ID_Personal_Programado { get; set; }
    public string? Programado_Nombre { get; set; }
    public string? Efectivo_Nombre { get; set; }
    public bool Puede_Programar { get; set; }
    public bool Puede_Atender { get; set; }
    public bool Puede_Terminar { get; set; }
    public string? Motivo_No_Atender { get; set; }
}
