// ============================================================
// Archivo  : Srv_Porteria.cs
// Ruta     : Application.Services/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 5 — Service
// Entidad  : Porteria
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Validación mínima de formulario. Las reglas de negocio viven en la rutina (códigos 101/400/404/409):
// el servicio NO las duplica, solo traduce su respuesta (D-40).
// Solo exige que lleguen la persona y las respuestas. Qué se puede registrar y cuándo lo decide la rutina (D-63).

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Porteria : ISrv_Porteria
{
    private readonly IRepo_Porteria _repo;
    private readonly ILogger<Srv_Porteria> _logger;

    public Srv_Porteria(IRepo_Porteria repo, ILogger<Srv_Porteria> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<List<Dto_Porteria_Item>>> ChecklistObtenerAsync(long usuarioId, long solicitudPersonaId, string etapa, bool traeEquipos = false, bool traeHerramientas = false, CancellationToken ct = default)
    {
        try { return await _repo.ChecklistObtenerAsync(usuarioId, solicitudPersonaId, etapa, traeEquipos, traeHerramientas, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CHECKLIST Porteria ID={ID} ERROR", solicitudPersonaId);
            return Result<List<Dto_Porteria_Item>>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Porteria_Ficha>> FichaAsync(long usuarioId, long solicitudPersonaId, CancellationToken ct = default)
    {
        try
        {
            var r = await _repo.FichaAsync(usuarioId, solicitudPersonaId, ct).ConfigureAwait(false);
            if (!r.Success) return Result<Dto_Porteria_Ficha>.Fail(r.Message, r.Code);
            if (r.Data is null)
                return Result<Dto_Porteria_Ficha>.Fail("La persona no existe o no tiene permiso para verla.", ResultCodes.NotFound);
            return Result<Dto_Porteria_Ficha>.Ok(r.Data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "FICHA Porteria ID={ID} ERROR", solicitudPersonaId);
            return Result<Dto_Porteria_Ficha>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Porteria_Movimiento>>> MovimientosListarAsync(long usuarioId, Dto_Filtro_Movimientos f, CancellationToken ct = default)
    {
        try { return await _repo.MovimientosListarAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "MOVIMIENTOS Porteria ERROR");
            return Result<List<Dto_Porteria_Movimiento>>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Porteria_Registro>> RegistroDetalleAsync(long usuarioId, long registroId, CancellationToken ct = default)
    {
        try
        {
            var r = await _repo.RegistroDetalleAsync(usuarioId, registroId, ct).ConfigureAwait(false);
            if (!r.Success) return Result<Dto_Porteria_Registro>.Fail(r.Message, r.Code);
            if (r.Data is null)
                return Result<Dto_Porteria_Registro>.Fail("El movimiento no existe o no tiene permiso para verlo.", ResultCodes.NotFound);
            return Result<Dto_Porteria_Registro>.Ok(r.Data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "REGISTRO_DETALLE Porteria ID={ID} ERROR", registroId);
            return Result<Dto_Porteria_Registro>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Porteria_Registro_Item>>> RegistroChecklistListarAsync(long usuarioId, long registroId, CancellationToken ct = default)
    {
        try { return await _repo.RegistroChecklistListarAsync(usuarioId, registroId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "REGISTRO_CHECKLIST Porteria ID={ID} ERROR", registroId);
            return Result<List<Dto_Porteria_Registro_Item>>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Porteria_Registrado>> IngresoRegistrarAsync(Dto_Porteria_Ingreso dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = new List<ResultError>();
        if (dto is null)
            return Result<Dto_Porteria_Registrado>.Validation("Datos inválidos.", new List<ResultError> { new ResultError("dto", "Faltan los datos del movimiento.") });
        if (dto.ID_Solicitud_Persona <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Solicitud_Persona), "Falta la persona."));
        if (dto.Items is null || dto.Items.Count == 0)
            errors.Add(new ResultError(nameof(dto.Items), "Responda el checklist."));
        if (errors.Count > 0)
            return Result<Dto_Porteria_Registrado>.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.IngresoRegistrarAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<Dto_Porteria_Registrado>.Ok(sp.Data!, sp.Mensaje)
                : Result<Dto_Porteria_Registrado>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "INGRESO Porteria UsuarioID={UsuarioID} ERROR", usuarioId);
            return Result<Dto_Porteria_Registrado>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Porteria_Registrado>> SalidaRegistrarAsync(Dto_Porteria_Salida dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = new List<ResultError>();
        if (dto is null)
            return Result<Dto_Porteria_Registrado>.Validation("Datos inválidos.", new List<ResultError> { new ResultError("dto", "Faltan los datos del movimiento.") });
        if (dto.ID_Solicitud_Persona <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Solicitud_Persona), "Falta la persona."));
        if (dto.Items is null || dto.Items.Count == 0)
            errors.Add(new ResultError(nameof(dto.Items), "Responda el checklist."));
        if (errors.Count > 0)
            return Result<Dto_Porteria_Registrado>.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.SalidaRegistrarAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<Dto_Porteria_Registrado>.Ok(sp.Data!, sp.Mensaje)
                : Result<Dto_Porteria_Registrado>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "SALIDA Porteria UsuarioID={UsuarioID} ERROR", usuarioId);
            return Result<Dto_Porteria_Registrado>.Fail(ex.Message);
        }
    }

    public async Task<Result<long>> NoSePresentoMarcarAsync(DateTime? fechaCorte, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.NoSePresentoMarcarAsync(fechaCorte, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<long>.Ok(sp.Data!, sp.Mensaje)
                : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "NO_SE_PRESENTO Porteria ERROR");
            return Result<long>.Fail(ex.Message);
        }
    }

}
