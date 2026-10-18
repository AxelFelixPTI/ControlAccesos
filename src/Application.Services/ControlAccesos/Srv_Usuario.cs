// ============================================================
// Usuarios — solo valida el formulario (D-40) y, para la contraseña, la convierte en hash antes de
// enviarla a la base. Las reglas de negocio (correo repetido, usuario inexistente) las responde la rutina.
// ============================================================

using System.ComponentModel.DataAnnotations;
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Usuario : ISrv_Usuario
{
    /// <summary>Largo mínimo de contraseña (decisión D-86).</summary>
    public const int PasswordMinimo = 10;

    private readonly IRepo_Usuario _repo;
    private readonly IHasherPassword _hasher;
    private readonly ILogger<Srv_Usuario> _logger;

    public Srv_Usuario(IRepo_Usuario repo, IHasherPassword hasher, ILogger<Srv_Usuario> logger)
    {
        _repo = repo;
        _hasher = hasher;
        _logger = logger;
    }

    public async Task<Result<long>> CrearAsync(Dto_Usuario_Crear dto, long usuarioId, CancellationToken ct = default)
    {
        var resultados = new List<ValidationResult>();
        if (!Validator.TryValidateObject(dto, new ValidationContext(dto), resultados, validateAllProperties: true))
        {
            var errores = resultados.Select(r => new ResultError(r.MemberNames.FirstOrDefault() ?? "", r.ErrorMessage ?? "Dato inválido.")).ToList();
            return Result<long>.Validation("Datos inválidos.", errores);
        }

        try
        {
            var sp = await _repo.CrearAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result<long>.Ok(sp.Data, sp.Mensaje) : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CREAR Usuario ERROR");
            return Result<long>.Fail(ex.Message);
        }
    }

    public async Task<Result> EstablecerPasswordAsync(long idUsuario, string passwordPlano, long usuarioId, CancellationToken ct = default)
    {
        if (idUsuario <= 0)
            return Result.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(idUsuario), "Falta el usuario.") });
        if (string.IsNullOrEmpty(passwordPlano) || passwordPlano.Length < PasswordMinimo)
            return Result.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(passwordPlano), $"La contraseña debe tener al menos {PasswordMinimo} caracteres.") });

        try
        {
            var hash = _hasher.Hashear(passwordPlano);
            var sp = await _repo.PasswordActualizarAsync(idUsuario, hash, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PASSWORD Usuario ID={ID} ERROR", idUsuario);
            return Result.Fail(ex.Message);
        }
    }

    public async Task<Result<long>> AsignarLicenciaAsync(long idUsuario, long idLicencia, long idSede, long usuarioId, CancellationToken ct = default)
    {
        if (idUsuario <= 0 || idLicencia <= 0 || idSede <= 0)
            return Result<long>.Validation("Datos inválidos.", new List<ResultError> { new ResultError("", "Faltan usuario, licencia o sede.") });

        try
        {
            var sp = await _repo.LicenciaAgregarAsync(idUsuario, idLicencia, idSede, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result<long>.Ok(sp.Data, sp.Mensaje) : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "LICENCIA_AGREGAR Usuario ID={ID} ERROR", idUsuario);
            return Result<long>.Fail(ex.Message);
        }
    }
}
