// ============================================================
// Archivo  : ISrv_Solicitud_Decision.cs
// Ruta     : Application.Contracts/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 3 — Contracts
// Entidad  : Solicitud_Decision
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Solicitud_Decision
{
    Task<Result<long>> DecidirAsync(Dto_Solicitud_Decidir dto, long usuarioId, CancellationToken ct = default);
}
