// D-236: solo traduce; las reglas (usuario de Almacén, empresas activas) viven en el procedimiento.
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Almacen_Empresa : ISrv_Almacen_Empresa
{
    private readonly IRepo_Almacen_Empresa _repo;
    private readonly ILogger<Srv_Almacen_Empresa> _logger;

    public Srv_Almacen_Empresa(IRepo_Almacen_Empresa repo, ILogger<Srv_Almacen_Empresa> logger) { _repo = repo; _logger = logger; }

    public async Task<Result<List<Dto_Almacen_Empresa>>> ListarAsync(CancellationToken ct = default)
    {
        try { return await _repo.ListarAsync(ct).ConfigureAwait(false); }
        catch (Exception ex) { _logger.LogError(ex, "ALMACEN_EMPRESA_LISTAR ERROR"); return Result<List<Dto_Almacen_Empresa>>.Fail(ex.Message); }
    }

    public async Task<Result> GuardarAsync(long usuarioAlmacenId, IReadOnlyList<long> empresasIds, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.GuardarAsync(usuarioAlmacenId, empresasIds, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "ALMACEN_EMPRESA_GUARDAR Usuario={ID} ERROR", usuarioAlmacenId); return Result.Fail(ex.Message); }
    }
}
