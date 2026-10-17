// ============================================================
// Archivo  : Srv_Solicitud_Persona.cs
// Ruta     : Application.Services/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 5 — Service
// Entidad  : Solicitud_Persona
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Validación mínima de formulario. Las reglas de negocio viven en la rutina (códigos 101/400/404/409):
// el servicio NO las duplica, solo traduce su respuesta (D-40).

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Solicitud_Persona : ISrv_Solicitud_Persona
{
    private readonly IRepo_Solicitud_Persona _repo;
    private readonly ILogger<Srv_Solicitud_Persona> _logger;

    public Srv_Solicitud_Persona(IRepo_Solicitud_Persona repo, ILogger<Srv_Solicitud_Persona> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<long>> AgregarAsync(long solicitudId, long personaExternaId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.AgregarAsync(solicitudId, personaExternaId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<long>.Ok(sp.Data!, sp.Mensaje)
                : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AGREGAR Persona ID={ID} ERROR", solicitudId);
            return Result<long>.Fail(ex.Message);
        }
    }

    public async Task<Result> RetirarAsync(long solicitudPersonaId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.RetirarAsync(solicitudPersonaId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "RETIRAR Persona ID={ID} ERROR", solicitudPersonaId);
            return Result.Fail(ex.Message);
        }
    }

    public async Task<Result<bool>> CorregirAsync(long solicitudPersonaId, long personaExternaNuevaId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.CorregirAsync(solicitudPersonaId, personaExternaNuevaId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<bool>.Ok(sp.Data!, sp.Mensaje)
                : Result<bool>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CORREGIR Persona ID={ID} ERROR", solicitudPersonaId);
            return Result<bool>.Fail(ex.Message);
        }
    }

}
