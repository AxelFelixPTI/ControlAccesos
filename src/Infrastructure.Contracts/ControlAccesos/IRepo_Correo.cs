// ============================================================
// Archivo  : IRepo_Correo.cs
// Ruta     : Infrastructure.Contracts/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 3 — Contracts
// Entidad  : Correo
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Correo
{
    Task<Result<List<Dto_Correo_Pendiente>>> PendientesListarAsync(long usuarioId, int? maximo = null, CancellationToken ct = default);
    Task<Result<List<Dto_Correo_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Correos f, CancellationToken ct = default);
    Task<ResultSp> MarcarEnviadoAsync(long correoId, long usuarioId, CancellationToken ct = default);
    Task<ResultSp<string>> MarcarErrorAsync(long correoId, string? error, int maxIntentos, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> ReencolarAsync(long correoId, long sedeId, long usuarioId, CancellationToken ct = default);
}
