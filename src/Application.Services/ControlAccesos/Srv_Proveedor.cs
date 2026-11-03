// ============================================================
// Archivo  : Srv_Proveedor.cs
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación (Entrega 2 de Proveedor de abastecimiento)
// Versión  : V1.0 — 2026-11-03
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Validación mínima de formulario. Las reglas (permiso, estado, fecha, esclusa única) viven en las rutinas
// (códigos 101/400/404/409): el servicio no las duplica, solo traduce su respuesta (D-40).
// Terminar: sin observación la recepción es CONFORME; con observación, CON_OBSERVACION.

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Proveedor : ISrv_Proveedor
{
    private readonly IRepo_Proveedor _repo;
    private readonly ILogger<Srv_Proveedor> _logger;

    public Srv_Proveedor(IRepo_Proveedor repo, ILogger<Srv_Proveedor> logger) { _repo = repo; _logger = logger; }

    public async Task<Result<List<Dto_Proveedor_Entrega>>> CalendarioAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, CancellationToken ct = default)
    {
        try { return await _repo.CalendarioAsync(usuarioId, sedeId, desde, hasta, ct).ConfigureAwait(false); }
        catch (Exception ex) { _logger.LogError(ex, "CALENDARIO Proveedor ERROR"); return Result<List<Dto_Proveedor_Entrega>>.Fail(ex.Message); }
    }

    public async Task<Result<List<Dto_Proveedor_Responsable>>> ResponsablesAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try { return await _repo.ResponsablesAsync(usuarioId, sedeId, ct).ConfigureAwait(false); }
        catch (Exception ex) { _logger.LogError(ex, "RESPONSABLES Proveedor ERROR"); return Result<List<Dto_Proveedor_Responsable>>.Fail(ex.Message); }
    }

    public async Task<Result<Dto_Proveedor_Exclusa?>> ExclusaEstadoAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try { return await _repo.ExclusaEstadoAsync(usuarioId, sedeId, ct).ConfigureAwait(false); }
        catch (Exception ex) { _logger.LogError(ex, "EXCLUSA Proveedor ERROR"); return Result<Dto_Proveedor_Exclusa?>.Fail(ex.Message); }
    }

    public async Task<Result> ProgramarAsync(long solicitudId, long? personalId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.ProgramarAsync(solicitudId, personalId is > 0 ? personalId : null, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "PROGRAMAR Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }

    public async Task<Result> AtenderAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.AtenderAsync(solicitudId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "ATENDER Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }

    public async Task<Result> TerminarAsync(long solicitudId, string? observacion, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var obs = string.IsNullOrWhiteSpace(observacion) ? null : observacion.Trim();
            var sp = await _repo.RecepcionarAsync(solicitudId, obs is null ? "CONFORME" : "CON_OBSERVACION", obs, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "TERMINAR Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }
}
