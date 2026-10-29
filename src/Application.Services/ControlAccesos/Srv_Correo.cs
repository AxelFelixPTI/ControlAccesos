// ============================================================
// Archivo  : Srv_Correo.cs
// Ruta     : Application.Services/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 5 — Service
// Entidad  : Correo
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Validación mínima de formulario. Las reglas de negocio viven en la rutina (códigos 101/400/404/409):
// el servicio NO las duplica, solo traduce su respuesta (D-40).
// El proceso de envío usa el usuario del sistema (0, D-80); el servicio no lo decide, la rutina lo exige.

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Correo : ISrv_Correo
{
    private readonly IRepo_Correo _repo;
    private readonly ILogger<Srv_Correo> _logger;

    public Srv_Correo(IRepo_Correo repo, ILogger<Srv_Correo> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<List<Dto_Correo_Pendiente>>> PendientesListarAsync(long usuarioId, int? maximo = null, int? retenerSegundos = null, CancellationToken ct = default)
    {
        try { return await _repo.PendientesListarAsync(usuarioId, maximo, retenerSegundos, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PENDIENTES Correo ERROR");
            return Result<List<Dto_Correo_Pendiente>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Correo_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Correos f, CancellationToken ct = default)
    {
        try { return await _repo.ListarAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "LISTAR Correo ERROR");
            return Result<List<Dto_Correo_Lista>>.Fail(ex.Message);
        }
    }

    public async Task<Result> MarcarEnviadoAsync(long correoId, long usuarioId, CancellationToken ct = default)
    {
        if (correoId <= 0)
            return Result.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(correoId), "Falta el correo.") });

        try
        {
            var sp = await _repo.MarcarEnviadoAsync(correoId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "MARCAR_ENVIADO Correo ID={ID} ERROR", correoId);
            return Result.Fail(ex.Message);
        }
    }

    public async Task<Result<string>> MarcarErrorAsync(long correoId, string? error, int maxIntentos, long usuarioId, CancellationToken ct = default)
    {
        if (correoId <= 0)
            return Result<string>.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(correoId), "Falta el correo.") });

        try
        {
            var sp = await _repo.MarcarErrorAsync(correoId, error, maxIntentos, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<string>.Ok(sp.Data!, sp.Mensaje)
                : Result<string>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "MARCAR_ERROR Correo ID={ID} ERROR", correoId);
            return Result<string>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Correo_Solicitud>> SolicitudDatosAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try { return await _repo.SolicitudDatosAsync(usuarioId, solicitudId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "SOLICITUD_DATOS Correo ID={ID} ERROR", solicitudId);
            return Result<Dto_Correo_Solicitud>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Correo_Solicitud_Persona>>> SolicitudPersonasAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try { return await _repo.SolicitudPersonasAsync(usuarioId, solicitudId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "SOLICITUD_PERSONAS Correo ID={ID} ERROR", solicitudId);
            return Result<List<Dto_Correo_Solicitud_Persona>>.Fail(ex.Message);
        }
    }

    public async Task<Result> ReencolarAsync(long correoId, long sedeId, long usuarioId, CancellationToken ct = default)
    {
        if (correoId <= 0)
            return Result.Validation("Datos inválidos.", new List<ResultError> { new ResultError(nameof(correoId), "Falta el correo.") });

        try
        {
            var sp = await _repo.ReencolarAsync(correoId, sedeId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "REENCOLAR Correo ID={ID} ERROR", correoId);
            return Result.Fail(ex.Message);
        }
    }

}
