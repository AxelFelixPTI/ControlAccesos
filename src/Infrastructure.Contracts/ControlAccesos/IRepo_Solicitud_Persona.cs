// ============================================================
// Archivo  : IRepo_Solicitud_Persona.cs
// Ruta     : Infrastructure.Contracts/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 3 — Contracts
// Entidad  : Solicitud_Persona
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Solicitud_Persona
{
    Task<ResultSp<long>> AgregarAsync(long solicitudId, long personaExternaId, long usuarioId, CancellationToken ct = default);
    /// <summary>El coordinador agrega una persona que queda ya aprobada en los pasos que le corresponden.</summary>
    Task<ResultSp<long>> AgregarAprobadaAsync(long solicitudId, long personaExternaId, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> RetirarAsync(long solicitudPersonaId, long usuarioId, CancellationToken ct = default);
    Task<ResultSp<bool>> CorregirAsync(long solicitudPersonaId, long personaExternaNuevaId, long usuarioId, CancellationToken ct = default);
}
