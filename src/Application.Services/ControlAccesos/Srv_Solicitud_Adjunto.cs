// Entrega J (D-183): documentos adjuntos. Valida el archivo en el servidor y traduce la respuesta de las rutinas (D-40).

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Solicitud_Adjunto : ISrv_Solicitud_Adjunto
{
    private readonly IRepo_Solicitud_Adjunto _repo;
    private readonly ILogger<Srv_Solicitud_Adjunto> _logger;

    public Srv_Solicitud_Adjunto(IRepo_Solicitud_Adjunto repo, ILogger<Srv_Solicitud_Adjunto> logger) { _repo = repo; _logger = logger; }

    public async Task<Result<long>> AgregarAsync(long solicitudId, string nombreArchivo, byte[] contenido, long usuarioId, CancellationToken ct = default)
    {
        var error = ValidadorAdjuntos.Validar(nombreArchivo, contenido, out var nombre, out var ext);
        if (error is not null)
            return Result<long>.Validation("Datos inválidos.", new[] { new ResultError("Archivo", error) });
        try
        {
            var sp = await _repo.AgregarAsync(solicitudId, nombre, ValidadorAdjuntos.TipoContenido(ext), contenido, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result<long>.Ok(sp.Data!, sp.Mensaje) : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ADJUNTO_AGREGAR Solicitud ID={ID} ERROR", solicitudId);
            return Result<long>.Fail("No se pudo guardar el documento.");
        }
    }

    public async Task<Result> QuitarAsync(long adjuntoId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.QuitarAsync(adjuntoId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ADJUNTO_QUITAR ID={ID} ERROR", adjuntoId);
            return Result.Fail("No se pudo retirar el documento.");
        }
    }

    public Task<Result<List<Dto_Solicitud_Adjunto>>> ListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
        => _repo.ListarAsync(usuarioId, solicitudId, ct);

    public Task<Result<Dto_Solicitud_Adjunto_Contenido?>> ObtenerAsync(long usuarioId, long adjuntoId, CancellationToken ct = default)
        => _repo.ObtenerAsync(usuarioId, adjuntoId, ct);

    public Task<Result<List<Dto_Correo_Adjunto>>> CorreoAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
        => _repo.CorreoAsync(usuarioId, solicitudId, ct);
}
