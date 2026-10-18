// ============================================================
// Archivo  : Srv_Reporte.cs
// Ruta     : Application.Services/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 5 — Service
// Entidad  : Reporte
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Validación mínima de formulario. Las reglas de negocio viven en la rutina (códigos 101/400/404/409):
// el servicio NO las duplica, solo traduce su respuesta (D-40).
// Un rango inválido o sin permiso devuelve lista vacía (D-83): la rutina decide, el servicio no la duplica.

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Reporte : ISrv_Reporte
{
    private readonly IRepo_Reporte _repo;
    private readonly ILogger<Srv_Reporte> _logger;

    public Srv_Reporte(IRepo_Reporte repo, ILogger<Srv_Reporte> logger)
    {
        _repo = repo;
        _logger = logger;
    }

    public async Task<Result<List<Dto_Reporte_Acceso>>> AccesosAsync(long usuarioId, Dto_Filtro_Reporte_Accesos f, CancellationToken ct = default)
    {
        try { return await _repo.AccesosAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ACCESOS Reporte ERROR");
            return Result<List<Dto_Reporte_Acceso>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Reporte_Resumen_Dia>>> ResumenDiarioAsync(long usuarioId, Dto_Filtro_Reporte_Rango f, CancellationToken ct = default)
    {
        try { return await _repo.ResumenDiarioAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "RESUMEN_DIARIO Reporte ERROR");
            return Result<List<Dto_Reporte_Resumen_Dia>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Reporte_Autorizado>>> AutorizadosPorZonaAsync(long usuarioId, Dto_Filtro_Reporte_Zona f, CancellationToken ct = default)
    {
        try { return await _repo.AutorizadosPorZonaAsync(usuarioId, f, ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "AUTORIZADOS_POR_ZONA Reporte ERROR");
            return Result<List<Dto_Reporte_Autorizado>>.Fail(ex.Message);
        }
    }

}
