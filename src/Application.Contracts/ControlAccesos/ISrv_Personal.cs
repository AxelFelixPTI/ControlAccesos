using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Personal
{
    Task<Result<List<Dto_Personal>>> ListarAsync(string? filtroNombre = null, long? idArea = null, long? idSede = null, bool incluirEliminados = false, CancellationToken ct = default);
    Task<Result<Dto_Personal?>> DetalleAsync(long id, CancellationToken ct = default);
    Task<Result<long>> CrearAsync(Dto_Personal dto, long usuarioId, CancellationToken ct = default);
    Task<Result> ActualizarAsync(long id, Dto_Personal dto, long usuarioId, CancellationToken ct = default);
}
