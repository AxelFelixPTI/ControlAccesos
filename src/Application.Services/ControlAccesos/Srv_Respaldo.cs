// ============================================================
// Archivo  : Srv_Respaldo.cs
// Ruta     : Application.Services/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 5 — Service
// Entidad  : Respaldo
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

public sealed class Srv_Respaldo : ISrv_Respaldo
{
    private readonly IRepo_Respaldo _repo;
    private readonly ILogger<Srv_Respaldo> _logger;

    public Srv_Respaldo(IRepo_Respaldo repo, ILogger<Srv_Respaldo> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<List<Dto_Respaldo>>> ListarPorPersonaAsync(long usuarioId, long solicitudPersonaId, CancellationToken ct = default)
    {
        try { return await _repo.ListarPorPersonaAsync(usuarioId, solicitudPersonaId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "LISTAR Respaldo ID={ID} ERROR", solicitudPersonaId);
            return Result<List<Dto_Respaldo>>.Fail(ex.Message);
        }
    }

    public async Task<Result<long>> RegistrarAsync(Dto_Respaldo_Registrar dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = new List<ResultError>();
        if (dto is null)
            return Result<long>.Validation("Datos inválidos.", new List<ResultError> { new ResultError("dto", "Faltan los datos del respaldo.") });
        if (string.IsNullOrWhiteSpace(dto.Categoria))
            errors.Add(new ResultError(nameof(dto.Categoria), "Elija la categoría."));
        if (string.IsNullOrWhiteSpace(dto.Tipo_Respaldo))
            errors.Add(new ResultError(nameof(dto.Tipo_Respaldo), "Elija el tipo de respaldo."));
        if (dto.IDs_Solicitud_Persona is null || dto.IDs_Solicitud_Persona.Count == 0)
            errors.Add(new ResultError(nameof(dto.IDs_Solicitud_Persona), "Elija al menos una persona."));
        if (errors.Count > 0)
            return Result<long>.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.RegistrarAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<long>.Ok(sp.Data!, sp.Mensaje)
                : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "REGISTRAR Respaldo UsuarioID={UsuarioID} ERROR", usuarioId);
            return Result<long>.Fail(ex.Message);
        }
    }

}
