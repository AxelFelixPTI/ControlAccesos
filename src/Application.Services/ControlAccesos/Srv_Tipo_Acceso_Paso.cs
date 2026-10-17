// ============================================================
// Archivo  : Srv_Tipo_Acceso_Paso.cs
// Ruta     : Application.Services/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 5 — Service
// Entidad  : Tipo_Acceso_Paso_Aprobacion
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

public sealed class Srv_Tipo_Acceso_Paso : ISrv_Tipo_Acceso_Paso
{
    private readonly IRepo_Tipo_Acceso_Paso _repo;
    private readonly ILogger<Srv_Tipo_Acceso_Paso> _logger;

    public Srv_Tipo_Acceso_Paso(IRepo_Tipo_Acceso_Paso repo, ILogger<Srv_Tipo_Acceso_Paso> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<List<Dto_Tipo_Acceso_Paso>>> ListarPorPadreAsync(long tipoAccesoId, bool incluirInactivos = false, CancellationToken ct = default)
    {
        try { return await _repo.ListarPorPadreAsync(tipoAccesoId, incluirInactivos, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "LISTAR Tipo_Acceso_Paso ERROR");
            return Result<List<Dto_Tipo_Acceso_Paso>>.Fail(ex.Message);
        }
    }

    public async Task<Result<long>> AgregarAsync(Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = new List<ResultError>();
        if (dto.ID_Catalogo_Tipo_Acceso <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Tipo_Acceso), "Falta el tipo de acceso."));
        if (string.IsNullOrWhiteSpace(dto.Codigo))
            errors.Add(new ResultError(nameof(dto.Codigo), "El Código es obligatorio."));
        if (string.IsNullOrWhiteSpace(dto.Descripcion))
            errors.Add(new ResultError(nameof(dto.Descripcion), "La Descripción es obligatoria."));
        if (dto.ID_Catalogo_Licencia <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Licencia), "Seleccione el rol que aprueba."));
        if (errors.Count > 0)
            return Result<long>.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.AgregarAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<long>.Ok(sp.Data!, sp.Mensaje)
                : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AGREGAR Tipo_Acceso_Paso ERROR");
            return Result<long>.Fail(ex.Message);
        }
    }

    public async Task<Result> ActualizarAsync(long pasoId, Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = new List<ResultError>();
        if (dto.ID_Catalogo_Tipo_Acceso <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Tipo_Acceso), "Falta el tipo de acceso."));
        if (string.IsNullOrWhiteSpace(dto.Codigo))
            errors.Add(new ResultError(nameof(dto.Codigo), "El Código es obligatorio."));
        if (string.IsNullOrWhiteSpace(dto.Descripcion))
            errors.Add(new ResultError(nameof(dto.Descripcion), "La Descripción es obligatoria."));
        if (dto.ID_Catalogo_Licencia <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Licencia), "Seleccione el rol que aprueba."));
        if (errors.Count > 0)
            return Result.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.ActualizarAsync(pasoId, dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ACTUALIZAR Tipo_Acceso_Paso ID={ID} ERROR", pasoId);
            return Result.Fail(ex.Message);
        }
    }

    public async Task<Result> QuitarAsync(long pasoId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.QuitarAsync(pasoId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "QUITAR Tipo_Acceso_Paso ID={ID} ERROR", pasoId);
            return Result.Fail(ex.Message);
        }
    }

}
