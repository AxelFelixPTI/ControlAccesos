// ============================================================
// Archivo  : IRepo_Solicitud_Decision.cs
// Ruta     : Infrastructure.Contracts/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 3 — Contracts
// Entidad  : Solicitud_Decision
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Solicitud_Decision
{
    Task<ResultSp<long>> DecidirAsync(Dto_Solicitud_Decidir dto, long usuarioId, CancellationToken ct = default);
}
