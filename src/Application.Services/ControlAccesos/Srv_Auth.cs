// ============================================================
// Autenticación — reglas de la aplicación (no del SP): comparar la contraseña con su hash, no revelar si
// el correo existe, y decidir el bloqueo (D-89: 5 intentos, 15 minutos). El conteo y el bloqueo los guarda
// ERP_USUARIO_LOGIN_REGISTRAR. El hash de un token de restablecimiento es SHA-256 en hexadecimal; el token
// en claro solo existe en el momento de emitirlo (D-26).
// ============================================================

using System.ComponentModel.DataAnnotations;
using System.Security.Cryptography;
using System.Text;
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Auth : ISrv_Auth
{
    public const int MaxIntentos = 5;
    public const int MinutosBloqueo = 15;
    private const string MensajeCredenciales = "Correo o contraseña incorrectos.";
    private const string MensajeBloqueo = "Cuenta bloqueada temporalmente por intentos fallidos. Intente más tarde.";

    private readonly IRepo_Usuario _repo;
    private readonly IHasherPassword _hasher;
    private readonly ILogger<Srv_Auth> _logger;
    private readonly Func<DateTime> _ahora;

    public Srv_Auth(IRepo_Usuario repo, IHasherPassword hasher, ILogger<Srv_Auth> logger)
        : this(repo, hasher, logger, () => DateTime.Now) { }

    /// <summary>Constructor con reloj inyectable (pruebas).</summary>
    public Srv_Auth(IRepo_Usuario repo, IHasherPassword hasher, ILogger<Srv_Auth> logger, Func<DateTime> ahora)
    {
        _repo = repo;
        _hasher = hasher;
        _logger = logger;
        _ahora = ahora;
    }

    public async Task<Result<Dto_Sesion_Usuario>> IniciarSesionAsync(Dto_Login_Entrada entrada, CancellationToken ct = default)
    {
        var errores = Validar(entrada);
        if (errores.Count > 0) return Result<Dto_Sesion_Usuario>.Validation("Datos inválidos.", errores);

        try
        {
            var lectura = await _repo.AutenticacionPorCorreoAsync(entrada.Correo.Trim(), ct).ConfigureAwait(false);
            if (!lectura.Success) return Result<Dto_Sesion_Usuario>.Fail(lectura.Message);
            var u = lectura.Data;

            // Usuario inexistente, inactivo o sin contraseña definida: misma respuesta y mismo tiempo aproximado.
            if (u is null || !u.Activo || string.IsNullOrEmpty(u.Password_Hash))
            {
                _hasher.Verificar(entrada.Password, FalsoHash);
                return Result<Dto_Sesion_Usuario>.Fail(MensajeCredenciales, ResultCodes.Fail);
            }

            if (u.Bloqueado_Hasta is { } hasta && hasta > _ahora())
                return Result<Dto_Sesion_Usuario>.Fail(MensajeBloqueo, "BLOQUEADO");

            if (!_hasher.Verificar(entrada.Password, u.Password_Hash))
            {
                var reg = await _repo.LoginRegistrarAsync(u.ID_Usuario, false, MaxIntentos, MinutosBloqueo, ct).ConfigureAwait(false);
                if (reg.Ok && reg.Data?.Bloqueado_Hasta is not null)
                    return Result<Dto_Sesion_Usuario>.Fail(MensajeBloqueo, "BLOQUEADO");
                return Result<Dto_Sesion_Usuario>.Fail(MensajeCredenciales, ResultCodes.Fail);
            }

            var ok = await _repo.LoginRegistrarAsync(u.ID_Usuario, true, MaxIntentos, MinutosBloqueo, ct).ConfigureAwait(false);
            if (!ok.Ok) return Result<Dto_Sesion_Usuario>.Fail(ok.Mensaje, MapeoSp.Codigo(ok.Codigo));

            var lic = await _repo.LicenciasListarAsync(u.ID_Usuario, ct).ConfigureAwait(false);
            if (!lic.Success) return Result<Dto_Sesion_Usuario>.Fail(lic.Message);
            var per = await _repo.PermisosListarAsync(u.ID_Usuario, ct).ConfigureAwait(false);
            if (!per.Success) return Result<Dto_Sesion_Usuario>.Fail(per.Message);

            return Result<Dto_Sesion_Usuario>.Ok(new Dto_Sesion_Usuario
            {
                ID_Usuario = u.ID_Usuario,
                Correo = u.Correo,
                Nombre_Completo = u.Nombre_Completo,
                Password_Requiere_Cambio = u.Password_Requiere_Cambio,
                Licencias = lic.Data ?? new(),
                Permisos = per.Data ?? new(),
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "LOGIN ERROR");
            return Result<Dto_Sesion_Usuario>.Fail("No se pudo iniciar sesión.");
        }
    }

    public async Task<Result<string>> EmitirTokenAsync(long idUsuario, int minutosVigencia, long usuarioId, CancellationToken ct = default)
    {
        if (idUsuario <= 0)
            return Result<string>.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(idUsuario), "Falta el usuario.") });
        try
        {
            var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32)).Replace('+', '-').Replace('/', '_').TrimEnd('=');
            var sp = await _repo.TokenRegistrarAsync(idUsuario, HashToken(token), minutosVigencia, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result<string>.Ok(token, sp.Mensaje) : Result<string>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "EMITIR_TOKEN ERROR ID={ID}", idUsuario);
            return Result<string>.Fail(ex.Message);
        }
    }

    public async Task<Result> DefinirPasswordConTokenAsync(string tokenPlano, string passwordNueva, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(tokenPlano))
            return Result.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(tokenPlano), "Falta el token.") });
        var err = ValidarPasswordNueva(passwordNueva);
        if (err is not null) return Result.Validation("Datos inválidos.", new List<ResultError> { err });

        try
        {
            var t = await _repo.AutenticacionPorTokenAsync(HashToken(tokenPlano.Trim()), ct).ConfigureAwait(false);
            if (!t.Success) return Result.Fail(t.Message);
            if (t.Data is null) return Result.Fail("El enlace no es válido o ya venció.", ResultCodes.NotFound);

            var sp = await _repo.PasswordActualizarAsync(t.Data.ID_Usuario, _hasher.Hashear(passwordNueva), t.Data.ID_Usuario, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DEFINIR_PASSWORD ERROR");
            return Result.Fail("No se pudo definir la contraseña.");
        }
    }

    public async Task<Result> CambiarPasswordAsync(string correo, string passwordActual, string passwordNueva, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(correo) || string.IsNullOrEmpty(passwordActual))
            return Result.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(passwordActual), "Falta la contraseña actual.") });
        var err = ValidarPasswordNueva(passwordNueva);
        if (err is not null) return Result.Validation("Datos inválidos.", new List<ResultError> { err });

        try
        {
            var lectura = await _repo.AutenticacionPorCorreoAsync(correo.Trim(), ct).ConfigureAwait(false);
            if (!lectura.Success) return Result.Fail(lectura.Message);
            var u = lectura.Data;
            if (u is null || !u.Activo || string.IsNullOrEmpty(u.Password_Hash) || !_hasher.Verificar(passwordActual, u.Password_Hash))
                return Result.Fail("La contraseña actual no es correcta.");

            var sp = await _repo.PasswordActualizarAsync(u.ID_Usuario, _hasher.Hashear(passwordNueva), u.ID_Usuario, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CAMBIAR_PASSWORD ERROR");
            return Result.Fail("No se pudo cambiar la contraseña.");
        }
    }

    public async Task<Result<Dto_Usuario_Token?>> BuscarPorCorreoAsync(string correo, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(correo))
            return Result<Dto_Usuario_Token?>.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(correo), "Falta el correo.") });
        try
        {
            var r = await _repo.AutenticacionPorCorreoAsync(correo.Trim(), ct).ConfigureAwait(false);
            if (!r.Success) return Result<Dto_Usuario_Token?>.Fail(r.Message);
            var u = r.Data;
            return Result<Dto_Usuario_Token?>.Ok(u is null ? null : new Dto_Usuario_Token { ID_Usuario = u.ID_Usuario, Correo = u.Correo, Nombre_Completo = u.Nombre_Completo });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "BUSCAR_POR_CORREO ERROR");
            return Result<Dto_Usuario_Token?>.Fail(ex.Message);
        }
    }

    public async Task<Result<bool>> TienePermisoAsync(long idUsuario, string codigoPermiso, long sedeId, CancellationToken ct = default)
    {
        if (idUsuario <= 0 || string.IsNullOrWhiteSpace(codigoPermiso) || sedeId <= 0)
            return Result<bool>.Validation("Datos inválidos.", new List<ResultError> { new ResultError("", "Faltan usuario, permiso o sede.") });
        try { return await _repo.PermisoVerificarAsync(idUsuario, codigoPermiso, sedeId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "TIENE_PERMISO ERROR");
            return Result<bool>.Fail(ex.Message);
        }
    }

    // ── Utilidades ───────────────────────────────────────────
    public static string HashToken(string tokenPlano)
        => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(tokenPlano))).ToLowerInvariant();

    // Hash válido de una contraseña al azar: se compara contra él cuando el usuario no existe, para no delatarlo por tiempo.
    private const string FalsoHash = "PBKDF2$SHA256$210000$AAAAAAAAAAAAAAAAAAAAAA==$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

    private static List<ResultError> Validar(Dto_Login_Entrada e)
    {
        var res = new List<ValidationResult>();
        Validator.TryValidateObject(e, new ValidationContext(e), res, true);
        return res.Select(r => new ResultError(r.MemberNames.FirstOrDefault() ?? "", r.ErrorMessage ?? "Dato inválido.")).ToList();
    }

    private static ResultError? ValidarPasswordNueva(string? p)
        => string.IsNullOrEmpty(p) || p.Length < Srv_Usuario.PasswordMinimo
            ? new ResultError("passwordNueva", $"La contraseña debe tener al menos {Srv_Usuario.PasswordMinimo} caracteres.")
            : null;
}
