// D-238: solo traduce; el formato de cada parámetro se valida en ERP_CAF_PARAMETRO_GUARDAR.
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Parametro : ISrv_Parametro
{
    private readonly IRepo_Parametro _repo;
    private readonly ILogger<Srv_Parametro> _logger;

    public Srv_Parametro(IRepo_Parametro repo, ILogger<Srv_Parametro> logger) { _repo = repo; _logger = logger; }

    public async Task<Result<List<Dto_Parametro>>> ListarAsync(CancellationToken ct = default)
    {
        try { return await _repo.ListarAsync(ct).ConfigureAwait(false); }
        catch (Exception ex) { _logger.LogError(ex, "PARAMETRO_LISTAR ERROR"); return Result<List<Dto_Parametro>>.Fail(ex.Message); }
    }

    public async Task<Result> GuardarAsync(string clave, string? valor, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(clave)) return Result.Fail("Falta el parámetro.", MapeoSp.Codigo(400));
            var sp = await _repo.GuardarAsync(clave.Trim(), (valor ?? string.Empty).Trim(), usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "PARAMETRO_GUARDAR Clave={Clave} ERROR", clave); return Result.Fail(ex.Message); }
    }
}
