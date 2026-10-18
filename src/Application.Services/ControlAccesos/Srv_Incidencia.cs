// ============================================================
// Archivo  : Srv_Incidencia.cs
// Ruta     : Application.Services/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 5 — Service
// Entidad  : Incidencia
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Validación mínima de formulario. Las reglas de negocio viven en la rutina (códigos 101/400/404/409):
// el servicio NO las duplica, solo traduce su respuesta (D-40).
// Quién registra o decide y si la incidencia sigue REGISTRADA lo decide la rutina (D-74, D-79).

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Incidencia : ISrv_Incidencia
{
    private readonly IRepo_Incidencia _repo;
    private readonly ILogger<Srv_Incidencia> _logger;

    public Srv_Incidencia(IRepo_Incidencia repo, ILogger<Srv_Incidencia> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<List<Dto_Incidencia_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Incidencias f, CancellationToken ct = default)
    {
        try { return await _repo.ListarAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "LISTAR Incidencia ERROR");
            return Result<List<Dto_Incidencia_Lista>>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Incidencia_Detalle>> DetalleAsync(long usuarioId, long incidenciaId, CancellationToken ct = default)
    {
        try
        {
            var r = await _repo.DetalleAsync(usuarioId, incidenciaId, ct).ConfigureAwait(false);
            if (!r.Success) return Result<Dto_Incidencia_Detalle>.Fail(r.Message, r.Code);
            if (r.Data is null)
                return Result<Dto_Incidencia_Detalle>.Fail("La incidencia no existe o no tiene permiso para verla.", ResultCodes.NotFound);
            return Result<Dto_Incidencia_Detalle>.Ok(r.Data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DETALLE Incidencia ID={ID} ERROR", incidenciaId);
            return Result<Dto_Incidencia_Detalle>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Incidencia_Persona>>> PersonasListarAsync(long usuarioId, long incidenciaId, CancellationToken ct = default)
    {
        try { return await _repo.PersonasListarAsync(usuarioId, incidenciaId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PERSONAS Incidencia ID={ID} ERROR", incidenciaId);
            return Result<List<Dto_Incidencia_Persona>>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Incidencia_Contadores>> ContadoresAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try
        {
            var r = await _repo.ContadoresAsync(usuarioId, sedeId, ct).ConfigureAwait(false);
            if (!r.Success) return Result<Dto_Incidencia_Contadores>.Fail(r.Message, r.Code);
            if (r.Data is null)
                return Result<Dto_Incidencia_Contadores>.Fail("No se pudieron obtener los contadores.", ResultCodes.NotFound);
            return Result<Dto_Incidencia_Contadores>.Ok(r.Data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CONTADORES Incidencia ERROR");
            return Result<Dto_Incidencia_Contadores>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Incidencia_Persona_Busqueda>>> PersonasBuscarAsync(long usuarioId, Dto_Filtro_Incidencia_Personas f, CancellationToken ct = default)
    {
        try { return await _repo.PersonasBuscarAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PERSONAS_BUSCAR Incidencia ERROR");
            return Result<List<Dto_Incidencia_Persona_Busqueda>>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Incidencia_Registrada>> RegistrarAsync(Dto_Incidencia_Registrar dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = new List<ResultError>();
        if (dto is null)
            return Result<Dto_Incidencia_Registrada>.Validation("Datos inválidos.", new List<ResultError> { new ResultError("dto", "Faltan los datos de la incidencia.") });
        if (dto.ID_Catalogo_Tipo_Incidencia <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Tipo_Incidencia), "Elija el tipo de incidencia."));
        if (string.IsNullOrWhiteSpace(dto.Descripcion))
            errors.Add(new ResultError(nameof(dto.Descripcion), "Describa lo ocurrido."));
        if (dto.ID_Catalogo_Zona_Acceso is null && string.IsNullOrWhiteSpace(dto.Lugar_Detalle))
            errors.Add(new ResultError(nameof(dto.Lugar_Detalle), "Indique la zona o describa el lugar."));
        if (errors.Count > 0)
            return Result<Dto_Incidencia_Registrada>.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.RegistrarAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<Dto_Incidencia_Registrada>.Ok(sp.Data!, sp.Mensaje)
                : Result<Dto_Incidencia_Registrada>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "REGISTRAR Incidencia UsuarioID={UsuarioID} ERROR", usuarioId);
            return Result<Dto_Incidencia_Registrada>.Fail(ex.Message);
        }
    }

    public async Task<Result> DecidirAsync(Dto_Incidencia_Decision dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = new List<ResultError>();
        if (dto is null)
            return Result.Validation("Datos inválidos.", new List<ResultError> { new ResultError("dto", "Faltan los datos de la decisión.") });
        if (dto.ID_Incidencia <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Incidencia), "Falta la incidencia."));
        if (string.IsNullOrWhiteSpace(dto.Decision))
            errors.Add(new ResultError(nameof(dto.Decision), "Elija confirmar o desestimar."));
        if (string.IsNullOrWhiteSpace(dto.Sustento))
            errors.Add(new ResultError(nameof(dto.Sustento), "Escriba el sustento de la decisión."));
        if (errors.Count > 0)
            return Result.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.DecidirAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DECIDIR Incidencia UsuarioID={UsuarioID} ERROR", usuarioId);
            return Result.Fail(ex.Message);
        }
    }

}
