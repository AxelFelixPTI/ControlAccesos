// ============================================================
// Archivo  : Srv_Proveedor.cs
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación (Entrega 2 de Proveedor de abastecimiento)
// Versión  : V1.0 — 2026-11-03
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Validación mínima de formulario. Las reglas (permiso, estado, fecha, esclusa única) viven en las rutinas
// (códigos 101/400/404/409): el servicio no las duplica, solo traduce su respuesta (D-40).
// Terminar: sin observación la recepción es CONFORME; con observación, CON_OBSERVACION.

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Proveedor : ISrv_Proveedor
{
    private readonly IRepo_Proveedor _repo;
    private readonly ILogger<Srv_Proveedor> _logger;

    public Srv_Proveedor(IRepo_Proveedor repo, ILogger<Srv_Proveedor> logger) { _repo = repo; _logger = logger; }

    public async Task<Result<List<Dto_Proveedor_Entrega>>> CalendarioAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, CancellationToken ct = default)
    {
        try { return await _repo.CalendarioAsync(usuarioId, sedeId, desde, hasta, ct).ConfigureAwait(false); }
        catch (Exception ex) { _logger.LogError(ex, "CALENDARIO Proveedor ERROR"); return Result<List<Dto_Proveedor_Entrega>>.Fail(ex.Message); }
    }

    public async Task<Result<List<Dto_Proveedor_Responsable>>> ResponsablesAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try { return await _repo.ResponsablesAsync(usuarioId, sedeId, ct).ConfigureAwait(false); }
        catch (Exception ex) { _logger.LogError(ex, "RESPONSABLES Proveedor ERROR"); return Result<List<Dto_Proveedor_Responsable>>.Fail(ex.Message); }
    }

    public async Task<Result<Dto_Proveedor_Exclusa?>> ExclusaEstadoAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try { return await _repo.ExclusaEstadoAsync(usuarioId, sedeId, ct).ConfigureAwait(false); }
        catch (Exception ex) { _logger.LogError(ex, "EXCLUSA Proveedor ERROR"); return Result<Dto_Proveedor_Exclusa?>.Fail(ex.Message); }
    }

    public async Task<Result> ProgramarAsync(long solicitudId, long? personalId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.ProgramarAsync(solicitudId, personalId is > 0 ? personalId : null, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "PROGRAMAR Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }

    public async Task<Result> ConfirmarDisponibilidadAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.ConfirmarDisponibilidadAsync(solicitudId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "DISPONIBILIDAD Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }

    public async Task<Result> CancelarDisponibilidadAsync(long solicitudId, string? motivo, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(motivo)) return Result.Fail("Indique el motivo de la cancelación.", MapeoSp.Codigo(400));
            var sp = await _repo.CancelarDisponibilidadAsync(solicitudId, motivo.Trim(), usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "CANCELAR DISPONIBILIDAD Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }

    public async Task<Result> ValidarIngresoAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.ValidarIngresoAsync(solicitudId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "VALIDAR INGRESO Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }

    public async Task<Result> RetiroSinIngresoAsync(long solicitudId, string? motivo, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(motivo)) return Result.Fail("Indique el motivo del retiro.", MapeoSp.Codigo(400));
            var sp = await _repo.RetiroSinIngresoAsync(solicitudId, motivo.Trim(), usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "RETIRO SIN INGRESO Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }

    public async Task<Result> IngresoFisicoAsync(long solicitudId, IReadOnlyCollection<long> idsPersona, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            if (idsPersona is null || idsPersona.Count == 0) return Result.Fail("Seleccione al menos una persona.", MapeoSp.Codigo(400));
            var sp = await _repo.IngresoFisicoAsync(solicitudId, string.Join(",", idsPersona), usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "INGRESO FISICO Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }

    public async Task<Result> RetiroPersonasAsync(long solicitudId, IReadOnlyCollection<long> idsPersona, string? motivo, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            if (idsPersona is null || idsPersona.Count == 0) return Result.Fail("Seleccione al menos una persona.", MapeoSp.Codigo(400));
            if (string.IsNullOrWhiteSpace(motivo)) return Result.Fail("Indique el motivo del retiro.", MapeoSp.Codigo(400));
            var sp = await _repo.RetiroPersonasAsync(solicitudId, string.Join(",", idsPersona), motivo.Trim(), usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "RETIRO PERSONAS Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }

    public async Task<Result> VerificarGrupoAsync(Dto_Proveedor_Grupo dto, long usuarioId, CancellationToken ct = default)
    {
        var err = ValidarGrupo(dto);
        if (err is not null) return err;
        try
        {
            var sp = await _repo.VerificarGrupoAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "VERIFICAR GRUPO Proveedor ID={ID} ERROR", dto.ID_Solicitud); return Result.Fail(ex.Message); }
    }

    public async Task<Result> SalidaGrupoAsync(Dto_Proveedor_Grupo dto, long usuarioId, CancellationToken ct = default)
    {
        var err = ValidarGrupo(dto);
        if (err is not null) return err;
        try
        {
            var sp = await _repo.SalidaGrupoAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "SALIDA GRUPO Proveedor ID={ID} ERROR", dto.ID_Solicitud); return Result.Fail(ex.Message); }
    }

    private static Result? ValidarGrupo(Dto_Proveedor_Grupo? dto)
    {
        if (dto is null || dto.ID_Solicitud <= 0) return Result.Fail("Faltan los datos de la entrega.", MapeoSp.Codigo(400));
        if (dto.IDs_Persona is null || dto.IDs_Persona.Count == 0) return Result.Fail("Seleccione al menos una persona.", MapeoSp.Codigo(400));
        return null;
    }

    public async Task<Result> AtenderAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.AtenderAsync(solicitudId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "ATENDER Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }

    public async Task<Result> TerminarAsync(long solicitudId, string? observacion, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var obs = string.IsNullOrWhiteSpace(observacion) ? null : observacion.Trim();
            var sp = await _repo.RecepcionarAsync(solicitudId, obs is null ? "CONFORME" : "CON_OBSERVACION", obs, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "TERMINAR Proveedor ID={ID} ERROR", solicitudId); return Result.Fail(ex.Message); }
    }
}
