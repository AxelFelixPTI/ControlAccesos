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
    Task<ResultSp> ConfirmarDisponibilidadAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> CancelarDisponibilidadAsync(long solicitudId, string motivo, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> ValidarIngresoAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> RetiroSinIngresoAsync(long solicitudId, string motivo, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> AtenderAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> RecepcionarAsync(long solicitudId, string resultado, string? observacion, long usuarioId, CancellationToken ct = default);
}
