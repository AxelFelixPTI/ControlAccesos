// ============================================================
// Archivo  : ISrv_Desviacion.cs
// Ruta     : Application.Contracts/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 3 — Contracts
// Entidad  : Desviacion
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Desviacion
{
    Task<Result<List<Dto_Desviacion_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Desviaciones f, CancellationToken ct = default);
    Task<Result<Dto_Desviacion_Detalle>> DetalleAsync(long usuarioId, long desviacionId, CancellationToken ct = default);
    Task<Result<Dto_Desviacion_Contadores>> ContadoresAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<Result<List<Dto_Desviacion_Coordinador>>> CoordinadoresDropdownAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<Result<List<Dto_Desviacion_Tratamiento>>> TratamientosDropdownAsync(string etapa, CancellationToken ct = default);
    Task<Result> ConformidadDarAsync(long desviacionId, string? comentario, long usuarioId, CancellationToken ct = default);
}
