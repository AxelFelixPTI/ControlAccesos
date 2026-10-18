// ============================================================
// Inicio de sesión, contraseñas y permisos. No maneja cookies ni HTTP: devuelve Dto_Sesion_Usuario
// y la web (al final) lo convierte en la sesión.
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Auth
{
    /// <summary>Valida correo y contraseña, aplica el bloqueo por intentos y devuelve licencias y permisos.</summary>
    Task<Result<Dto_Sesion_Usuario>> IniciarSesionAsync(Dto_Login_Entrada entrada, CancellationToken ct = default);

    /// <summary>Genera un token de un solo uso para definir contraseña. Devuelve el token EN CLARO (solo se guarda su hash).</summary>
    Task<Result<string>> EmitirTokenAsync(long idUsuario, int minutosVigencia, long usuarioId, CancellationToken ct = default);

    /// <summary>Usa el token para definir la contraseña (válido una sola vez, con vencimiento).</summary>
    Task<Result> DefinirPasswordConTokenAsync(string tokenPlano, string passwordNueva, CancellationToken ct = default);

    /// <summary>El usuario con sesión cambia su contraseña conociendo la actual.</summary>
    Task<Result> CambiarPasswordAsync(string correo, string passwordActual, string passwordNueva, CancellationToken ct = default);

    /// <summary>Busca un usuario por correo (para emitir tokens desde la consola o administración).</summary>
    Task<Result<Dto_Usuario_Token?>> BuscarPorCorreoAsync(string correo, CancellationToken ct = default);

    Task<Result<bool>> TienePermisoAsync(long idUsuario, string codigoPermiso, long sedeId, CancellationToken ct = default);
}
