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
    /// <summary>Corrección de emergencia (D-169): el coordinador agrega una persona a una solicitud YA aprobada; queda aprobada en los pasos que le corresponden.</summary>
    Task<ResultSp<long>> AgregarEmergenciaAsync(long solicitudId, long personaExternaId, string sustento, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> RetirarAsync(long solicitudPersonaId, long usuarioId, CancellationToken ct = default);
    /// <summary>Corrección de emergencia (D-169): el coordinador quita a una persona autorizada que aún no ingresó.</summary>
    /// <remarks>D-215: si es la única persona de la solicitud, <paramref name="confirmarRechazo"/> debe ser true y la solicitud queda RECHAZADA.</remarks>
    Task<ResultSp> RetirarEmergenciaAsync(long solicitudPersonaId, string sustento, bool confirmarRechazo, long usuarioId, CancellationToken ct = default);
    /// <summary>Corrección de emergencia (D-215): el coordinador corrige tipo de documento, apellidos y nombres de una persona autorizada (nunca el número de documento).</summary>
    Task<ResultSp> CorregirEmergenciaAsync(long solicitudPersonaId, long tipoDocumentoId, string apellidoPaterno, string? apellidoMaterno, string nombres, string sustento, long usuarioId, CancellationToken ct = default);
    Task<ResultSp<bool>> CorregirAsync(long solicitudPersonaId, long personaExternaNuevaId, long usuarioId, CancellationToken ct = default);
}
