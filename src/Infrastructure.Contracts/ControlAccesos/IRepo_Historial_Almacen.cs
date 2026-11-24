using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

/// <summary>D-273. SP: ERP_CAF_PROVEEDOR_HISTORIAL_ALMACEN.</summary>
public interface IRepo_Historial_Almacen
{
    Task<Result<List<Dto_Historial_Almacen>>> ListarAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, string? texto, long? empresaId, string? estado, string? conVehiculo, CancellationToken ct = default);
}
