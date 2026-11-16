// D-238: parámetros del sistema.
using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Parametro
{
    Task<Result<List<Dto_Parametro>>> ListarAsync(CancellationToken ct = default);
    Task<Result> GuardarAsync(string clave, string? valor, long usuarioId, CancellationToken ct = default);
}
