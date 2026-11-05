// ============================================================
// Archivo  : ISrv_Proveedor.cs
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación (Entrega 2 de Proveedor de abastecimiento)
// Versión  : V1.0 — 2026-11-03
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Proveedor
{
    Task<Result<List<Dto_Proveedor_Entrega>>> CalendarioAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, CancellationToken ct = default);
    Task<Result<List<Dto_Proveedor_Responsable>>> ResponsablesAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<Result<Dto_Proveedor_Exclusa?>> ExclusaEstadoAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<Result> ProgramarAsync(long solicitudId, long? personalId, long usuarioId, CancellationToken ct = default);
    Task<Result> ConfirmarDisponibilidadAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<Result> CancelarDisponibilidadAsync(long solicitudId, string? motivo, long usuarioId, CancellationToken ct = default);
    /// <summary>Vigilancia: ingreso físico de un proveedor ya verificado y con Almacén listo.</summary>
    Task<Result> ValidarIngresoAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    /// <summary>Vigilancia: el proveedor verificado se retira sin ingresar (motivo obligatorio).</summary>
    Task<Result> RetiroSinIngresoAsync(long solicitudId, string? motivo, long usuarioId, CancellationToken ct = default);
    Task<Result> AtenderAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<Result> TerminarAsync(long solicitudId, string? observacion, long usuarioId, CancellationToken ct = default);
}
