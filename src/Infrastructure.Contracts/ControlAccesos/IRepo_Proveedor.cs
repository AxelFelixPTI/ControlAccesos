// ============================================================
// Archivo  : IRepo_Proveedor.cs
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación (Entrega 2 de Proveedor de abastecimiento)
// Versión  : V1.0 — 2026-11-03
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Proveedor
{
    Task<Result<List<Dto_Proveedor_Entrega>>> CalendarioAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, CancellationToken ct = default);
    Task<Result<List<Dto_Proveedor_Responsable>>> ResponsablesAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<Result<Dto_Proveedor_Exclusa?>> ExclusaEstadoAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<ResultSp> ProgramarAsync(long solicitudId, long? personalId, long usuarioId, CancellationToken ct = default);
    /// <summary>D-261: plazas = cuántas plazas de la esclusa reserva la entrega (1 por defecto; solo cuenta con ingreso vehicular).</summary>
    Task<ResultSp> ConfirmarDisponibilidadAsync(long solicitudId, bool conVehiculo, long usuarioId, int plazas = 1, CancellationToken ct = default);
    Task<ResultSp> ValidarIngresoAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> RetiroSinIngresoAsync(long solicitudId, string motivo, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> IngresoFisicoAsync(long solicitudId, string idsPersona, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> RetiroPersonasAsync(long solicitudId, string idsPersona, string motivo, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> VerificarGrupoAsync(Dto_Proveedor_Grupo dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> SalidaGrupoAsync(Dto_Proveedor_Grupo dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> AtenderAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> RecepcionarAsync(long solicitudId, string resultado, string? observacion, long usuarioId, CancellationToken ct = default);
    // D-238: atención por empresa
    Task<Result<List<Dto_Atencion_Empresa>>> AtencionListarAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Motivo_Sin_Atencion>>> MotivosSinAtencionAsync(CancellationToken ct = default);
    Task<ResultSp> AtenderEmpresaAsync(long solicitudId, long empresaId, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> RecepcionarEmpresaAsync(long solicitudId, long empresaId, string resultado, string? observacion, long usuarioId, CancellationToken ct = default);
    // D-239: varias empresas a la vez (ids separados por coma), detener y reanudar
    Task<ResultSp> AtenderEmpresasAsync(long solicitudId, string idsEmpresa, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> DetenerEmpresasAsync(long solicitudId, string idsEmpresa, string? motivo, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> ReanudarEmpresasAsync(long solicitudId, string idsEmpresa, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> RecepcionarEmpresasAsync(long solicitudId, string idsEmpresa, string resultado, string? observacion, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> CerrarSinAtencionAsync(long solicitudId, long empresaId, long motivoId, string? detalle, long usuarioId, CancellationToken ct = default);
    // D-244: panel de cupos y Ceder/Tomar la reserva
    Task<Result<List<Dto_Proveedor_Cupo>>> CuposAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    /// <summary>D-260: estado de la esclusa y de las otras entregas para el modal «Confirmar disponibilidad».</summary>
    Task<Result<List<Dto_Proveedor_IngresoVeh_Estado>>> IngresoVehEstadoAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    /// <summary>D-260: solicitudes de ingreso vehicular vigentes de la sede.</summary>
    Task<Result<List<Dto_Proveedor_IngresoVeh_Solicitud>>> IngresoVehListarAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<ResultSp> IngresoVehSolicitarAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> IngresoVehRetirarAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    /// <summary>D-263: liberación temprana de plazas (solo entregas de más de 1 vehículo).</summary>
    Task<ResultSp> PlazaLiberarAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Proveedor_Plaza>>> PlazasListarAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    /// <summary>D-264: bloque «Atención de Almacén» (exige la licencia del historial).</summary>
    Task<Result<List<Dto_Proveedor_Atencion_Resumen>>> AtencionResumenAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<List<Dto_Proveedor_Atencion_Evento>>> AtencionEventosAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<List<Dto_Proveedor_Vehiculo>>> VehiculosListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<ResultSp> IngresoVehResponderAsync(long solicitudIngresoId, string accion, string? motivo, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> CederReservaAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> TomarReservaAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
}
