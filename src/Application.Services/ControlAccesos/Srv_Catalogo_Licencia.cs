// ============================================================
// Archivo  : Srv_Catalogo_Licencia.cs
// Ruta     : Application.Services/ControlAccesos/
// Módulo   : ControlAccesos
// Hito     : 0 — Base
// Fase     : 5 — Service
// Entidad  : Catalogo_Licencia
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

public sealed class Srv_Catalogo_Licencia : ISrv_Catalogo_Licencia
{
    private readonly IRepo_Catalogo_Licencia _repo;
    private readonly ILogger<Srv_Catalogo_Licencia> _logger;

    public Srv_Catalogo_Licencia(IRepo_Catalogo_Licencia repo, ILogger<Srv_Catalogo_Licencia> logger)
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
            _logger.LogError(ex, "LISTAR Catalogo_Licencia ERROR");
            return Result<List<Dto_Catalogo_Universal>>.Fail(ex.Message);
        }
    }

    public async Task<Result<List<Dto_Catalogo_Universal>>> ObtenerDropdownAsync(CancellationToken ct = default)
    {
        try { return await _repo.ObtenerDropdownAsync(ct).ConfigureAwait(false); }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DROPDOWN Catalogo_Licencia ERROR");
            return Result<List<Dto_Catalogo_Universal>>.Fail(ex.Message);
        }
    }
}
