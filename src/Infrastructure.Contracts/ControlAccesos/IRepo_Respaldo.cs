// ============================================================
// Archivo  : IRepo_Respaldo.cs
// Ruta     : Infrastructure.Contracts/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 3 — Contracts
// Entidad  : Respaldo
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Respaldo
{
    Task<Result<List<Dto_Respaldo>>> ListarPorPersonaAsync(long usuarioId, long solicitudPersonaId, CancellationToken ct = default);
    Task<ResultSp<long>> RegistrarAsync(Dto_Respaldo_Registrar dto, long usuarioId, CancellationToken ct = default);
}
