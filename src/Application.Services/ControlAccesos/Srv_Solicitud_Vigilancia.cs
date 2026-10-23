// ============================================================
// Archivo  : Srv_Solicitud_Vigilancia.cs
// Ruta     : Application.Services/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 5 — Service
// Entidad  : Solicitud — Vigilancia
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

public sealed class Srv_Solicitud_Vigilancia : ISrv_Solicitud_Vigilancia
{
    private readonly IRepo_Solicitud_Vigilancia _repo;
    private readonly ILogger<Srv_Solicitud_Vigilancia> _logger;

    public Srv_Solicitud_Vigilancia(IRepo_Solicitud_Vigilancia repo, ILogger<Srv_Solicitud_Vigilancia> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<List<Dto_Vigilancia_Persona>>> ListarAsync(long usuarioId, Dto_Filtro_Vigilancia? f = null, CancellationToken ct = default)
    {
        try { return await _repo.ListarAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "LISTAR Vigilancia ERROR");
            return Result<List<Dto_Vigilancia_Persona>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Vigilancia_Persona>>> AprobadasListarAsync(long usuarioId, Dto_Filtro_Vigilancia_Aprobadas f, CancellationToken ct = default)
    {
        try { return await _repo.AprobadasListarAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "APROBADAS Vigilancia ERROR");
            return Result<List<Dto_Vigilancia_Persona>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Vigilancia_No_Autorizada>>> NoAutorizadaBuscarAsync(long usuarioId, long sedeId, DateTime fecha, string texto, CancellationToken ct = default)
    {
        try { return await _repo.NoAutorizadaBuscarAsync(usuarioId, sedeId, fecha, texto ?? string.Empty, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "NO_AUTORIZADA Vigilancia ERROR");
            return Result<List<Dto_Vigilancia_No_Autorizada>>.Fail(ex.Message);
        }
    }

}
