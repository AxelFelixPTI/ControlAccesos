using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Usuario
{
    Task<ResultSp<long>> CrearAsync(Dto_Usuario_Crear dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> PasswordActualizarAsync(long idUsuario, string passwordHash, long usuarioId, CancellationToken ct = default);
    Task<ResultSp<long>> LicenciaAgregarAsync(long idUsuario, long idLicencia, long idSede, long usuarioId, CancellationToken ct = default);
}
