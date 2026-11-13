// D-236: empresas a las que da atención cada usuario de Almacén (SP_CAF_SOLICITUD_EMPRESAS_ALL).
using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Almacen_Empresa
{
    Task<Result<List<Dto_Almacen_Empresa>>> ListarAsync(CancellationToken ct = default);
    Task<ResultSp> GuardarAsync(long usuarioAlmacenId, IReadOnlyList<long> empresasIds, long usuarioId, CancellationToken ct = default);
}
