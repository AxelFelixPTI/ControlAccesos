// ============================================================
// Archivo  : IRepo_Reporte.cs
// Ruta     : Infrastructure.Contracts/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 3 — Contracts
// Entidad  : Reporte
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Reporte
{
    Task<Result<List<Dto_Reporte_Acceso>>> AccesosAsync(long usuarioId, Dto_Filtro_Reporte_Accesos f, CancellationToken ct = default);
    Task<Result<List<Dto_Reporte_Resumen_Dia>>> ResumenDiarioAsync(long usuarioId, Dto_Filtro_Reporte_Rango f, CancellationToken ct = default);
    Task<Result<List<Dto_Reporte_Autorizado>>> AutorizadosPorZonaAsync(long usuarioId, Dto_Filtro_Reporte_Zona f, CancellationToken ct = default);
}
