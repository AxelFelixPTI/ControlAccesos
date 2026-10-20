using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Usuario
{
    Task<ResultSp<long>> CrearAsync(Dto_Usuario_Crear dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> PasswordActualizarAsync(long idUsuario, string passwordHash, long usuarioId, CancellationToken ct = default);
    Task<ResultSp<long>> LicenciaAgregarAsync(long idUsuario, long idLicencia, long idSede, long usuarioId, CancellationToken ct = default);

    // ── Gestión desde la web ─────────────────────────────────
    Task<Result<List<Dto_Usuario_Lista>>> ListarAsync(string? filtroTexto, string? codigoLicencia, bool incluirEliminados, CancellationToken ct = default);
    Task<Result<Dto_Usuario_Lista?>> DetalleAsync(long idUsuario, CancellationToken ct = default);
    Task<ResultSp> ActualizarAsync(Dto_Usuario_Actualizar dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> LicenciaQuitarAsync(long idUsuarioLicencia, long usuarioId, CancellationToken ct = default);

    // ── Autenticación (Hito de login) ────────────────────────
    Task<Result<Dto_Usuario_Credencial?>> AutenticacionPorCorreoAsync(string correo, CancellationToken ct = default);
    Task<Result<Dto_Usuario_Token?>> AutenticacionPorTokenAsync(string tokenHash, CancellationToken ct = default);
    Task<ResultSp<Dto_Login_Registro>> LoginRegistrarAsync(long idUsuario, bool exitoso, int maxIntentos, int minutosBloqueo, CancellationToken ct = default);
    Task<ResultSp> TokenRegistrarAsync(long idUsuario, string tokenHash, int minutosVigencia, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Usuario_Licencia>>> LicenciasListarAsync(long idUsuario, CancellationToken ct = default);
    Task<Result<List<Dto_Usuario_Permiso>>> PermisosListarAsync(long idUsuario, CancellationToken ct = default);
    Task<Result<bool>> PermisoVerificarAsync(long idUsuario, string codigoPermiso, long sedeId, CancellationToken ct = default);
}
