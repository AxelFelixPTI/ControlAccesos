// D-273: historial de Almacén. Normaliza los filtros; la licencia y el rango máximo los valida el procedimiento.

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Historial_Almacen : ISrv_Historial_Almacen
{
    private static readonly HashSet<string> Estados = new() { "PENDIENTE", "EN_ATENCION", "DETENIDA", "ATENDIDA", "CERRADA_SIN_ATENCION" };
    private readonly IRepo_Historial_Almacen _repo;

    public Srv_Historial_Almacen(IRepo_Historial_Almacen repo) => _repo = repo;

    public Task<Result<List<Dto_Historial_Almacen>>> ListarAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, string? texto, long? empresaId, string? estado, string? conVehiculo, CancellationToken ct = default)
        => _repo.ListarAsync(usuarioId, sedeId, desde?.Date, hasta?.Date, string.IsNullOrWhiteSpace(texto) ? null : texto.Trim(),
                             empresaId is > 0 ? empresaId : null, estado is not null && Estados.Contains(estado) ? estado : null,
                             conVehiculo is "Y" or "N" ? conVehiculo : null, ct);
}
