// ============================================================
// Archivo  : ISrv_Solicitud_Persona.cs
// Ruta     : Application.Contracts/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 3 — Contracts
// Entidad  : Solicitud_Persona
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Solicitud_Persona
{
    Task<Result<long>> AgregarAsync(long solicitudId, long personaExternaId, long usuarioId, CancellationToken ct = default);
    Task<Result> RetirarAsync(long solicitudPersonaId, long usuarioId, CancellationToken ct = default);
    Task<Result<bool>> CorregirAsync(long solicitudPersonaId, long personaExternaNuevaId, long usuarioId, CancellationToken ct = default);
}
