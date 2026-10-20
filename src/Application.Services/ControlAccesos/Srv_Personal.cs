// ============================================================
// Personal. Valida el formulario; las reglas de negocio (documento, duplicados, existencia de área/empresa/sede)
// viven en los procedimientos: el servicio solo traduce su respuesta.
// ============================================================

using System.ComponentModel.DataAnnotations;
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Personal : ISrv_Personal
{
    private readonly IRepo_Personal _repo;
    private readonly ILogger<Srv_Personal> _logger;

    public Srv_Personal(IRepo_Personal repo, ILogger<Srv_Personal> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<List<Dto_Personal>>> ListarAsync(string? filtroNombre = null, long? idArea = null, long? idSede = null, bool incluirEliminados = false, CancellationToken ct = default)
    {
        try { return await _repo.ListarAsync(filtroNombre, idArea, idSede, incluirEliminados, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "LISTAR Personal ERROR");
            return Result<List<Dto_Personal>>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Personal?>> DetalleAsync(long id, CancellationToken ct = default)
    {
        try
        {
            var r = await _repo.DetalleAsync(id, ct).ConfigureAwait(false);
            if (r.Success && r.Data is null) return Result<Dto_Personal?>.Fail("Persona no encontrada en Personal.", ResultCodes.NotFound);
            return r;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DETALLE Personal ERROR ID={ID}", id);
            return Result<Dto_Personal?>.Fail(ex.Message);
        }
    }

    public async Task<Result<long>> CrearAsync(Dto_Personal dto, long usuarioId, CancellationToken ct = default)
    {
        var errores = Validar(dto);
        if (errores.Count > 0) return Result<long>.Validation("Datos inválidos.", errores);
        try
        {
            var sp = await _repo.CrearAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result<long>.Ok(sp.Data, sp.Mensaje) : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CREAR Personal ERROR UsuarioID={UsuarioID}", usuarioId);
            return Result<long>.Fail(ex.Message);
        }
    }

    public async Task<Result> ActualizarAsync(long id, Dto_Personal dto, long usuarioId, CancellationToken ct = default)
    {
        if (id <= 0) return Result.Validation("Datos inválidos.", new List<ResultError> { new("", "Falta la persona.") });
        var errores = Validar(dto);
        if (errores.Count > 0) return Result.Validation("Datos inválidos.", errores);
        try
        {
            var sp = await _repo.ActualizarAsync(id, dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ACTUALIZAR Personal ERROR ID={ID}", id);
            return Result.Fail(ex.Message);
        }
    }

    private static List<ResultError> Validar(Dto_Personal dto)
    {
        var resultados = new List<ValidationResult>();
        Validator.TryValidateObject(dto, new ValidationContext(dto), resultados, validateAllProperties: true);
        return resultados.Select(r => new ResultError(r.MemberNames.FirstOrDefault() ?? "", r.ErrorMessage ?? "Dato inválido.")).ToList();
    }
}
