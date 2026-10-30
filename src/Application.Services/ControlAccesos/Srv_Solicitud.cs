// ============================================================
// Archivo  : Srv_Solicitud.cs
// Ruta     : Application.Services/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 5 — Service
// Entidad  : Solicitud
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Validación mínima de formulario. Las reglas de negocio viven en la rutina (códigos 101/400/404/409):
// el servicio NO las duplica, solo traduce su respuesta (D-40).
// Lecturas: una consulta sin filas (sin permiso o inexistente) sale como NOT_FOUND con un mensaje neutro (D-57).

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Solicitud : ISrv_Solicitud
{
    private readonly IRepo_Solicitud _repo;
    private readonly ILogger<Srv_Solicitud> _logger;

    public Srv_Solicitud(IRepo_Solicitud repo, ILogger<Srv_Solicitud> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<List<string>>> EmpresasBuscarAsync(string? texto, CancellationToken ct = default)
    {
        try { return await _repo.EmpresasBuscarAsync(texto, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "EMPRESAS_BUSCAR Solicitud ERROR");
            return Result<List<string>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Lista>>> MisListarAsync(long usuarioId, Dto_Filtro_Mis_Solicitudes? f = null, CancellationToken ct = default)
    {
        try { return await _repo.MisListarAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "MIS_LISTAR Solicitud ERROR");
            return Result<List<Dto_Solicitud_Lista>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Bandeja>>> BandejaListarAsync(long usuarioId, Dto_Filtro_Bandeja? f = null, CancellationToken ct = default)
    {
        try { return await _repo.BandejaListarAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "BANDEJA Solicitud ERROR");
            return Result<List<Dto_Solicitud_Bandeja>>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Solicitud_Contadores>> ContadoresAsync(long usuarioId, long? sedeId = null, CancellationToken ct = default)
    {
        try
        {
            var r = await _repo.ContadoresAsync(usuarioId, sedeId, ct).ConfigureAwait(false);
            if (!r.Success) return Result<Dto_Solicitud_Contadores>.Fail(r.Message, r.Code);
            if (r.Data is null)
                return Result<Dto_Solicitud_Contadores>.Fail("No se pudieron obtener los contadores.", ResultCodes.NotFound);
            return Result<Dto_Solicitud_Contadores>.Ok(r.Data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CONTADORES Solicitud ERROR");
            return Result<Dto_Solicitud_Contadores>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Solicitud_Detalle>> DetalleAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var r = await _repo.DetalleAsync(usuarioId, solicitudId, ct).ConfigureAwait(false);
            if (!r.Success) return Result<Dto_Solicitud_Detalle>.Fail(r.Message, r.Code);
            if (r.Data is null)
                return Result<Dto_Solicitud_Detalle>.Fail("La solicitud no existe o no tiene permiso para verla.", ResultCodes.NotFound);
            return Result<Dto_Solicitud_Detalle>.Ok(r.Data);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DETALLE Solicitud ID={ID} ERROR", solicitudId);
            return Result<Dto_Solicitud_Detalle>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Persona>>> PersonasListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try { return await _repo.PersonasListarAsync(usuarioId, solicitudId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PERSONAS Solicitud ERROR");
            return Result<List<Dto_Solicitud_Persona>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Paso>>> PasosListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try { return await _repo.PasosListarAsync(usuarioId, solicitudId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PASOS Solicitud ERROR");
            return Result<List<Dto_Solicitud_Paso>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Evento>>> HistorialListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try { return await _repo.HistorialListarAsync(usuarioId, solicitudId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "HISTORIAL Solicitud ERROR");
            return Result<List<Dto_Solicitud_Evento>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Version>>> VersionesListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try { return await _repo.VersionesListarAsync(usuarioId, solicitudId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "VERSIONES Solicitud ERROR");
            return Result<List<Dto_Solicitud_Version>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Tipo_Opcion>>> TiposOpcionesAsync(CancellationToken ct = default)
    {
        try { return await _repo.TiposOpcionesAsync(ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "TIPOS_OPCIONES Solicitud ERROR");
            return Result<List<Dto_Solicitud_Tipo_Opcion>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Sede_Opcion>>> SedesOpcionesAsync(long usuarioId, CancellationToken ct = default)
    {
        try { return await _repo.SedesOpcionesAsync(usuarioId, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "SEDES_OPCIONES Solicitud ERROR");
            return Result<List<Dto_Solicitud_Sede_Opcion>>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Solicitud_Creada>> CrearAsync(Dto_Solicitud_Crear dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = new List<ResultError>();
        if (dto.ID_Catalogo_Sede <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Sede), "Seleccione la sede."));
        if (dto.ID_Catalogo_Tipo_Acceso <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Catalogo_Tipo_Acceso), "Seleccione el tipo de acceso."));
        if (dto.ID_Personal_Responsable <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Personal_Responsable), "Seleccione al responsable."));
        if (dto.Fecha_Hora_Prevista == default)
            errors.Add(new ResultError(nameof(dto.Fecha_Hora_Prevista), "Indique la fecha y hora de la visita."));
        if (dto.IDs_Persona_Externa is null || dto.IDs_Persona_Externa.Count == 0)
            errors.Add(new ResultError(nameof(dto.IDs_Persona_Externa), "Agregue al menos una persona."));
        if (errors.Count > 0)
            return Result<Dto_Solicitud_Creada>.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.CrearAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<Dto_Solicitud_Creada>.Ok(sp.Data!, sp.Mensaje)
                : Result<Dto_Solicitud_Creada>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CREAR Solicitud UsuarioID={UsuarioID} ERROR", usuarioId);
            return Result<Dto_Solicitud_Creada>.Fail(ex.Message);
        }
    }

    public async Task<Result<bool>> EditarDatosAsync(long solicitudId, Dto_Solicitud_Editar dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = new List<ResultError>();
        if (dto.Fecha_Hora_Prevista == default)
            errors.Add(new ResultError(nameof(dto.Fecha_Hora_Prevista), "Indique la fecha y hora de la visita."));
        if (dto.ID_Personal_Responsable <= 0)
            errors.Add(new ResultError(nameof(dto.ID_Personal_Responsable), "Seleccione al responsable."));
        if (errors.Count > 0)
            return Result<bool>.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.EditarDatosAsync(solicitudId, dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<bool>.Ok(sp.Data!, sp.Mensaje)
                : Result<bool>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "EDITAR_DATOS Solicitud ID={ID} ERROR", solicitudId);
            return Result<bool>.Fail(ex.Message);
        }
    }

    public async Task<Result> CancelarAsync(long solicitudId, string? motivo, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.CancelarAsync(solicitudId, motivo, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CANCELAR Solicitud ID={ID} ERROR", solicitudId);
            return Result.Fail(ex.Message);
        }
    }

}
