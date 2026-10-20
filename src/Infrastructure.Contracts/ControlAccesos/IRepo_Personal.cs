using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Personal
{
    Task<Result<List<Dto_Personal>>> ListarAsync(string? filtroNombre, long? idArea, long? idSede, bool incluirEliminados, CancellationToken ct = default);
    Task<Result<Dto_Personal?>> DetalleAsync(long id, CancellationToken ct = default);
    Task<ResultSp<long>> CrearAsync(Dto_Personal dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> ActualizarAsync(long id, Dto_Personal dto, long usuarioId, CancellationToken ct = default);
}
