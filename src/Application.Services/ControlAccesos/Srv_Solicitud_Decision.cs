// ============================================================
// Archivo  : Srv_Solicitud_Decision.cs
// Ruta     : Application.Services/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 5 — Service
// Entidad  : Solicitud_Decision
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Validación mínima de formulario. Las reglas de negocio viven en la rutina (códigos 101/400/404/409):
// el servicio NO las duplica, solo traduce su respuesta (D-40).
// Solo exige que se elija una decisión; el valor válido, el mensaje obligatorio y el orden de los pasos los valida la rutina.

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Solicitud_Decision : ISrv_Solicitud_Decision
{
    private readonly IRepo_Solicitud_Decision _repo;
    private readonly ILogger<Srv_Solicitud_Decision> _logger;

    public Srv_Solicitud_Decision(IRepo_Solicitud_Decision repo, ILogger<Srv_Solicitud_Decision> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<long>> DecidirAsync(Dto_Solicitud_Decidir dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = new List<ResultError>();
        if (dto.ID_Solicitud <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Solicitud), "Falta la solicitud."));
        if (dto.ID_Tipo_Acceso_Paso_Aprobacion <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Tipo_Acceso_Paso_Aprobacion), "Falta el paso de aprobación."));
        if (string.IsNullOrWhiteSpace(dto.Decision))
            errors.Add(new ResultError(nameof(dto.Decision), "Elija aprobar, observar o rechazar."));
        if (errors.Count > 0)
            return Result<long>.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.DecidirAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<long>.Ok(sp.Data!, sp.Mensaje)
                : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DECIDIR Solicitud ID={ID} ERROR", dto.ID_Solicitud);
            return Result<long>.Fail(ex.Message);
        }
    }

}
