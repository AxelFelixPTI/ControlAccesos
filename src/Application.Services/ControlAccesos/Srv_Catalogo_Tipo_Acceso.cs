// ============================================================
// Archivo  : Srv_Catalogo_Tipo_Acceso.cs
// Ruta     : Application.Services/ControlAccesos/
// Módulo   : ControlAccesos
// Hito     : 1 — Catálogos del módulo
// Fase     : 5 — Service
// Entidad  : Catalogo_Tipo_Acceso
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Validación mínima de formulario (código y descripción). Las reglas de negocio viven en el SP
// (códigos 101/400/404): el servicio NO las duplica, solo traduce su respuesta.
// ============================================================

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Catalogo_Tipo_Acceso : ISrv_Catalogo_Tipo_Acceso
{
    private readonly IRepo_Catalogo_Tipo_Acceso _repo;
    private readonly ILogger<Srv_Catalogo_Tipo_Acceso> _logger;

    public Srv_Catalogo_Tipo_Acceso(IRepo_Catalogo_Tipo_Acceso repo, ILogger<Srv_Catalogo_Tipo_Acceso> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<List<Dto_Catalogo_Universal>>> ListarAsync(
        bool incluirEliminados = false, CancellationToken ct = default)
    {
        try { return await _repo.ListarAsync(incluirEliminados, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "LISTAR Catalogo_Tipo_Acceso ERROR");
            return Result<List<Dto_Catalogo_Universal>>.Fail(ex.Message);
        }
    }

    public async Task<Result<long>> CrearAsync(Dto_Catalogo_Universal dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = Validar(dto);
        if (errors.Count > 0)
            return Result<long>.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.CrearAsync(dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok
                ? Result<long>.Ok(sp.Data, sp.Mensaje)
                : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "CREAR Catalogo_Tipo_Acceso ERROR UsuarioID={UsuarioID}", usuarioId);
            return Result<long>.Fail(ex.Message);
        }
    }

    public async Task<Result<Dto_Catalogo_Universal?>> DetalleAsync(long id, CancellationToken ct = default)
    {
        try
        {
            var r = await _repo.DetalleAsync(id, ct).ConfigureAwait(false);
            if (!r.Success) return r;
            if (r.Data is null)
                return Result<Dto_Catalogo_Universal?>.Fail("Registro no encontrado.", ResultCodes.NotFound);
            return r;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DETALLE Catalogo_Tipo_Acceso ERROR ID={ID}", id);
            return Result<Dto_Catalogo_Universal?>.Fail(ex.Message);
        }
    }

    public async Task<Result> ActualizarAsync(long id, Dto_Catalogo_Universal dto, long usuarioId, CancellationToken ct = default)
    {
        var errors = Validar(dto);
        if (errors.Count > 0)
            return Result.Validation("Datos inválidos.", errors);

        try
        {
            var sp = await _repo.ActualizarAsync(id, dto, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ACTUALIZAR Catalogo_Tipo_Acceso ERROR ID={ID}", id);
            return Result.Fail(ex.Message);
        }
    }

    public async Task<Result> EliminarAsync(long id, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.EliminarAsync(id, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ELIMINAR Catalogo_Tipo_Acceso ERROR ID={ID}", id);
            return Result.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Catalogo_Universal>>> ObtenerDropdownAsync(CancellationToken ct = default)
    {
        try { return await _repo.ObtenerDropdownAsync(ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DROPDOWN Catalogo_Tipo_Acceso ERROR");
            return Result<List<Dto_Catalogo_Universal>>.Fail(ex.Message);
        }
    }

    private static List<ResultError> Validar(Dto_Catalogo_Universal dto)
    {
        var errors = new List<ResultError>();
        if (string.IsNullOrWhiteSpace(dto.Codigo))
            errors.Add(new ResultError(nameof(dto.Codigo), "El Código es obligatorio."));
        if (string.IsNullOrWhiteSpace(dto.Descripcion))
            errors.Add(new ResultError(nameof(dto.Descripcion), "La Descripción es obligatoria."));
        return errors;
    }
}
