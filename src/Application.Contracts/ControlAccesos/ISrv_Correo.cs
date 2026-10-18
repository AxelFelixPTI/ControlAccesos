// ============================================================
// Archivo  : ISrv_Correo.cs
// Ruta     : Application.Contracts/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 3 — Contracts
// Entidad  : Correo
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Correo
{
    Task<Result<List<Dto_Correo_Pendiente>>> PendientesListarAsync(long usuarioId, int? maximo = null, CancellationToken ct = default);
    Task<Result<List<Dto_Correo_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Correos f, CancellationToken ct = default);
    Task<Result> MarcarEnviadoAsync(long correoId, long usuarioId, CancellationToken ct = default);
    Task<Result<string>> MarcarErrorAsync(long correoId, string? error, int maxIntentos, long usuarioId, CancellationToken ct = default);
    Task<Result> ReencolarAsync(long correoId, long sedeId, long usuarioId, CancellationToken ct = default);
}
