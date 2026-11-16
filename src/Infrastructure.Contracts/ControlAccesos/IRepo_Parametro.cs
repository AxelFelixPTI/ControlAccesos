// D-238: parámetros del sistema. Rutinas: ERP_CAF_PARAMETRO_LISTAR / ERP_CAF_PARAMETRO_GUARDAR.
using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Parametro
{
    Task<Result<List<Dto_Parametro>>> ListarAsync(CancellationToken ct = default);
    Task<ResultSp> GuardarAsync(string clave, string valor, long usuarioId, CancellationToken ct = default);
}
