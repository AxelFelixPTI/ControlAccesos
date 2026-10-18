// ============================================================
// Archivo  : Srv_Desviacion.cs
// Ruta     : Application.Services/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 5 — Service
// Entidad  : Desviacion
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Validación mínima de formulario. Las reglas de negocio viven en la rutina (códigos 101/400/404/409):
// el servicio NO las duplica, solo traduce su respuesta (D-40).
// Quién puede dar conformidad y si la desviación sigue por revisar lo decide la rutina (D-69).

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Desviacion : ISrv_Desviacion
{
    private readonly IRepo_Desviacion _repo;
    private readonly ILogger<Srv_Desviacion> _logger;

    public Srv_Desviacion(IRepo_Desviacion repo, ILogger<Srv_Desviacion> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<List<Dto_Desviacion_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Desviaciones f, CancellationToken ct = default)
    {
        try { return await _repo.ListarAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "LISTAR Desviacion ERROR");
            return Result<List<Dto_Desviacion_Lista>>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Desviacion_Detalle>> DetalleAsync(long usuarioId, long desviacionId, CancellationToken ct = default)
    {
        try
        {
            var r = await _repo.DetalleAsync(usuarioId, desviacionId, ct).ConfigureAwait(false);
            if (!r.Success) return Result<Dto_Desviacion_Detalle>.Fail(r.Message, r.Code);
            if (r.Data is null)
                return Result<Dto_Desviacion_Detalle>.Fail("La desviación no existe o no tiene permiso para verla.", ResultCodes.NotFound);
            return Result<Dto_Desviacion_Detalle>.Ok(r.Data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DETALLE Desviacion ID={ID} ERROR", desviacionId);
            return Result<Dto_Desviacion_Detalle>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Desviacion_Contadores>> ContadoresAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try
        {
            var r = await _repo.ContadoresAsync(usuarioId, sedeId, ct).ConfigureAwait(false);
            if (!r.Success) return Result<Dto_Desviacion_Contadores>.Fail(r.Message, r.Code);
            if (r.Data is null)
                return Result<Dto_Desviacion_Contadores>.Fail("No se pudieron obtener los contadores.", ResultCodes.NotFound);
            return Result<Dto_Desviacion_Contadores>.Ok(r.Data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CONTADORES Desviacion ERROR");
            return Result<Dto_Desviacion_Contadores>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Desviacion_Coordinador>>> CoordinadoresDropdownAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try { return await _repo.CoordinadoresDropdownAsync(usuarioId, sedeId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "COORDINADORES Desviacion ERROR");
            return Result<List<Dto_Desviacion_Coordinador>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Desviacion_Tratamiento>>> TratamientosDropdownAsync(string etapa, CancellationToken ct = default)
    {
        try { return await _repo.TratamientosDropdownAsync(etapa, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "TRATAMIENTOS Desviacion ERROR");
            return Result<List<Dto_Desviacion_Tratamiento>>.Fail(ex.Message);
        }
    }

    public async Task<Result> ConformidadDarAsync(long desviacionId, string? comentario, long usuarioId, CancellationToken ct = default)
    {
        if (desviacionId <= 0)
            return Result.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(desviacionId), "Falta la desviación.") });

        try
        {
            var sp = await _repo.ConformidadDarAsync(desviacionId, comentario, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CONFORMIDAD Desviacion ID={ID} ERROR", desviacionId);
            return Result.Fail(ex.Message);
        }
    }

}
