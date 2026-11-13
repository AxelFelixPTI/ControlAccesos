// D-236: empresas a las que da atención cada usuario de Almacén.
using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Almacen_Empresa
{
    Task<Result<List<Dto_Almacen_Empresa>>> ListarAsync(CancellationToken ct = default);
    Task<Result> GuardarAsync(long usuarioAlmacenId, IReadOnlyList<long> empresasIds, long usuarioId, CancellationToken ct = default);
}
