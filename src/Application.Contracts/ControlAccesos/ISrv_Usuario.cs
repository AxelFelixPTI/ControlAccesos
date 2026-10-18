// ============================================================
// Usuarios (schema CAF_GOVERNANCE). Por ahora solo lo necesario para crear el primer administrador;
// el login y la gestión completa llegan con la parte web.
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Usuario
{
    Task<Result<long>> CrearAsync(Dto_Usuario_Crear dto, long usuarioId, CancellationToken ct = default);
    Task<Result> EstablecerPasswordAsync(long idUsuario, string passwordPlano, long usuarioId, CancellationToken ct = default);
    Task<Result<long>> AsignarLicenciaAsync(long idUsuario, long idLicencia, long idSede, long usuarioId, CancellationToken ct = default);
}
