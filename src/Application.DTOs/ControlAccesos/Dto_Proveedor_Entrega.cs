// ============================================================
// Archivo  : Dto_Proveedor_Entrega.cs
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación (Entrega 2 de Proveedor de abastecimiento)
// Versión  : V2.0 — 2026-11-03 (flujo corregido: verificación, disponibilidad de Almacén, ingreso físico)
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
    public string? Empresa_Destino_Codigo { get; set; }       // TRIANON_SOSTENIBLE, TRIANON_ENERGO, POWER_TECHNOLOGY, TRIANON_ASCENSORES
    public string Transportista { get; set; } = string.Empty;
    public string? Telefono { get; set; }
    public string? Placa { get; set; }
    public string? Vehiculo_Marca { get; set; }
    public string? Observaciones { get; set; }
    public int Cantidad_Apoyo { get; set; }
    // D-225: avance por persona (solo aprobadas). Los ayudantes de descarga no bloquean la entrega.
    public int Transportistas_Total { get; set; }
    public int Transportistas_Verificados { get; set; }
    public int Transportistas_Dentro { get; set; }
    public int Transportistas_Salieron { get; set; }
    public int Ayudantes_Total { get; set; }
    // D-237
    public string? Numeros_OC { get; set; }
    public string? Empresa_Transportista { get; set; }     // vacía = el mismo proveedor transporta
    public string? Hora_Hasta { get; set; }                // «HH:mm»: fin de la franja estimada (informativa)
    public string Estado_Operativo { get; set; } = string.Empty;
    public bool Con_Desviacion { get; set; }
    public bool Disponibilidad_Confirmada { get; set; }       // «Almacén listo»: la esclusa está reservada para esta entrega
    public DateTime? Fecha_Disponibilidad { get; set; }
    public DateTime? Fecha_Llegada { get; set; }                // = hora de la verificación de datos
    public DateTime? Fecha_Ingreso { get; set; }
    public DateTime? Fecha_Inicio_Atencion { get; set; }
    public DateTime? Fecha_Recepcion { get; set; }
    public DateTime? Fecha_Salida { get; set; }
    public string? Resultado_Recepcion { get; set; }
    public long? ID_Personal_Programado { get; set; }
    public string? Programado_Nombre { get; set; }
    public string? Efectivo_Nombre { get; set; }
    public bool Puede_Programar { get; set; }
    public bool Puede_Confirmar { get; set; }                  // Confirmar disponibilidad (etapa 1 del botón de Almacén)
    public bool Puede_Cancelar_Disp { get; set; }              // Cancelar la disponibilidad
    public bool Puede_Atender { get; set; }                    // Iniciar atención (etapa 2)
    public bool Puede_Terminar { get; set; }                   // Terminar atención (etapa 3)
    public string? Motivo_Bloqueo { get; set; }
    /// <summary>La solicitud es del usuario que consulta (acceso directo a «Mis solicitudes»).</summary>
    public bool Es_Solicitante { get; set; }
    /// <summary>Su dueño puede cancelarla ahora (sin ingresos y la entrega aún PROGRAMADA).</summary>
    public bool Puede_Cancelar_Sol { get; set; }
    public string? Motivo_No_Cancelar_Sol { get; set; }
}
