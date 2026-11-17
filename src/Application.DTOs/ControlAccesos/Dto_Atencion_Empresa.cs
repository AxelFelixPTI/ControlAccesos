// D-238: atención de una entrega por empresa destinataria (ERP_CAF_ATENCION_LISTAR). Los Puede_* ya vienen calculados para el usuario que consulta.
namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Atencion_Empresa
{
    public long ID_Empresa { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Empresa { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;          // PENDIENTE, EN_ATENCION, DETENIDA, ATENDIDA, CERRADA_SIN_ATENCION
    public string? Resultado { get; set; }
    public string? Observacion { get; set; }
    public string? Motivo { get; set; }
    public DateTime? Fecha_Inicio { get; set; }
    public DateTime? Fecha_Fin { get; set; }
    public string? Atiende { get; set; }
    public bool Autorizado { get; set; }
    public bool Puede_Atender { get; set; }
    public bool Puede_Recepcionar { get; set; }
    public bool Puede_Cerrar_Sin { get; set; }
    public string? Motivo_No { get; set; }
    // D-239: detener / reanudar (solo quien inició la atención)
    public bool Puede_Detener { get; set; }
    public bool Puede_Reanudar { get; set; }
    public string? Motivo_Detencion { get; set; }
}

public sealed class Dto_Motivo_Sin_Atencion
{
    public long ID_Motivo { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public bool Es_Otro { get; set; }
}
