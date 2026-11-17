// D-238: parámetros del sistema.
using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Parametro
{
    Task<Result<List<Dto_Parametro>>> ListarAsync(CancellationToken ct = default);
    /// <summary>D-239: ¿se exige la placa del vehículo del conductor? (PLACA_OBLIGATORIA; por defecto sí, también si no se puede leer).</summary>
    Task<bool> PlacaObligatoriaAsync(CancellationToken ct = default);
    Task<Result> GuardarAsync(string clave, string? valor, long usuarioId, CancellationToken ct = default);
}
