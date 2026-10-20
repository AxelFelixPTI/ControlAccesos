// ============================================================
// Persona externa — registro de visitantes (ERP_CAF_PERSONA_EXTERNA_*, schema del módulo). Se buscan por documento;
// si ya existen se reutilizan, si no se crean. Las reglas (duplicados, documento válido) viven en los procedimientos.
// ============================================================

using System.ComponentModel.DataAnnotations;
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Persona_Externa : ISrv_Persona_Externa
{
    private readonly IRepo_Persona_Externa _repo;
    private readonly ILogger<Srv_Persona_Externa> _logger;

    public Srv_Persona_Externa(IRepo_Persona_Externa repo, ILogger<Srv_Persona_Externa> logger) { _repo = repo; _logger = logger; }

    public async Task<Result<Dto_Persona_Externa?>> PorDocumentoAsync(long tipoDocumentoId, string numeroDocumento, CancellationToken ct = default)
    {
        if (tipoDocumentoId <= 0 || string.IsNullOrWhiteSpace(numeroDocumento))
            return Result<Dto_Persona_Externa?>.Validation("Datos inválidos.", new List<ResultError> { new("", "Indique el tipo y el número de documento.") });
        try { return await _repo.PorDocumentoAsync(tipoDocumentoId, numeroDocumento.Trim(), ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "POR_DOCUMENTO Persona_Externa ERROR");
            return Result<Dto_Persona_Externa?>.Fail(ex.Message);
        }
    }

    public async Task<Result<long>> CrearAsync(Dto_Persona_Externa dto, long usuarioId, CancellationToken ct = default)
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
            _logger.LogError(ex, "CREAR Persona_Externa ERROR UsuarioID={UsuarioID}", usuarioId);
            return Result<long>.Fail(ex.Message);
        }
    }

    public async Task<Result> ActualizarAsync(long id, Dto_Persona_Externa dto, long usuarioId, CancellationToken ct = default)
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
            _logger.LogError(ex, "ACTUALIZAR Persona_Externa ERROR ID={ID}", id);
            return Result.Fail(ex.Message);
        }
    }

    private static List<ResultError> Validar(Dto_Persona_Externa dto)
    {
        var resultados = new List<ValidationResult>();
        Validator.TryValidateObject(dto, new ValidationContext(dto), resultados, validateAllProperties: true);
        return resultados.Select(r => new ResultError(r.MemberNames.FirstOrDefault() ?? "", r.ErrorMessage ?? "Dato inválido.")).ToList();
    }
}
