// D-273: una fila del «Historial de Almacén»: la atención de una empresa de destino en una entrega de proveedor.
namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Historial_Almacen
{
    public long ID_Solicitud { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public DateTime Fecha_Entrega { get; set; }
    public string Proveedor { get; set; } = string.Empty;
    public string? Solicitante { get; set; }
    public long ID_Empresa { get; set; }
    public string Empresa_Codigo { get; set; } = string.Empty;
    public string Empresa { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public string? Reservo { get; set; }
    public string? Inicio_Nombre { get; set; }
    public DateTime? Fecha_Inicio { get; set; }
    public string? Fin_Nombre { get; set; }
    public DateTime? Fecha_Fin { get; set; }
    public int? Minutos_Activos { get; set; }
    public int Pausas { get; set; }
    public int Minutos_Pausa { get; set; }
    /// <summary>"Y" con ingreso vehicular, "N" sin ingreso, null = Almacén aún no confirmó.</summary>
    public string? Con_Vehiculo { get; set; }
    public string? Resultado { get; set; }
    public string? Motivo_Sin_Atencion { get; set; }
    public string? Observacion { get; set; }
    // D-274: datos de la entrega y franja programada
    public string? Numeros_OC { get; set; }
    public string? Placa { get; set; }
    public string? Conductor { get; set; }
    public string? Empresa_Transportista { get; set; }
    /// <summary>Fin de la franja horaria (HH:mm); el inicio es la hora de Fecha_Entrega.</summary>
    public string? Hora_Hasta { get; set; }
    /// <summary>Estado de la entrega completa: PROGRAMADO, EN_ESPERA, INGRESO, EN_ATENCION, RECEPCIONADO, SALIO, CIERRE_FORZADO, NO_SE_PRESENTO.</summary>
    public string? Estado_Entrega { get; set; }
    public DateTime? Fecha_Llegada { get; set; }
    public DateTime? Fecha_Ingreso { get; set; }
    public DateTime? Fecha_Disponibilidad { get; set; }
    public DateTime? Fecha_Salida { get; set; }
    /// <summary>Minutos entre el inicio de la franja y el inicio real de la atención (negativo = antes).</summary>
    public int? Minutos_Desvio { get; set; }
    public string? Fuera_Franja { get; set; }
}
