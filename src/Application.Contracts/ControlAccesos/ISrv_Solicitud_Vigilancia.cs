// ============================================================
// Archivo  : ISrv_Solicitud_Vigilancia.cs
// Ruta     : Application.Contracts/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 3 — Contracts
// Entidad  : Solicitud — Vigilancia
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Solicitud_Vigilancia
{
    Task<Result<List<Dto_Vigilancia_Persona>>> ListarAsync(long usuarioId, Dto_Filtro_Vigilancia? f = null, CancellationToken ct = default);
    Task<Result<List<Dto_Vigilancia_No_Autorizada>>> NoAutorizadaBuscarAsync(long usuarioId, long sedeId, DateTime fecha, string texto, CancellationToken ct = default);
}
