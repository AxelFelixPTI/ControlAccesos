// ============================================================
// Archivo  : IRepo_Incidencia.cs
// Ruta     : Infrastructure.Contracts/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 3 — Contracts
// Entidad  : Incidencia
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Incidencia
{
    Task<Result<List<Dto_Incidencia_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Incidencias f, CancellationToken ct = default);
    Task<Result<Dto_Incidencia_Detalle?>> DetalleAsync(long usuarioId, long incidenciaId, CancellationToken ct = default);
    Task<Result<List<Dto_Incidencia_Persona>>> PersonasListarAsync(long usuarioId, long incidenciaId, CancellationToken ct = default);
    Task<Result<Dto_Incidencia_Contadores?>> ContadoresAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<Result<List<Dto_Incidencia_Persona_Busqueda>>> PersonasBuscarAsync(long usuarioId, Dto_Filtro_Incidencia_Personas f, CancellationToken ct = default);
    Task<ResultSp<Dto_Incidencia_Registrada>> RegistrarAsync(Dto_Incidencia_Registrar dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> DecidirAsync(Dto_Incidencia_Decision dto, long usuarioId, CancellationToken ct = default);
}
