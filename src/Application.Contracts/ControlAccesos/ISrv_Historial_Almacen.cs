using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

/// <summary>D-273: historial de las atenciones de Almacén en entregas de proveedores (licencia «Historial de Almacén»).</summary>
public interface ISrv_Historial_Almacen
{
    Task<Result<List<Dto_Historial_Almacen>>> ListarAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, string? texto, long? empresaId, string? estado, string? conVehiculo, CancellationToken ct = default);
}
