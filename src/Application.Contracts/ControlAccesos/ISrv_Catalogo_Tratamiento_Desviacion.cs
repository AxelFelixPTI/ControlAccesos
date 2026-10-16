// ============================================================
// Archivo  : ISrv_Catalogo_Tratamiento_Desviacion.cs
// Ruta     : Application.Contracts/ControlAccesos/
// Módulo   : ControlAccesos
// Hito     : 1 — Catálogos del módulo
// Fase     : 3 — Contracts
// Entidad  : Catalogo_Tratamiento_Desviacion
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Catalogo_Tratamiento_Desviacion
{
    Task<Result<List<Dto_Catalogo_Universal>>> ListarAsync(bool incluirEliminados = false, CancellationToken ct = default);
    Task<Result<long>> CrearAsync(Dto_Catalogo_Universal dto, long usuarioId, CancellationToken ct = default);
    Task<Result<Dto_Catalogo_Universal?>> DetalleAsync(long id, CancellationToken ct = default);
    Task<Result> ActualizarAsync(long id, Dto_Catalogo_Universal dto, long usuarioId, CancellationToken ct = default);
    Task<Result> EliminarAsync(long id, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Catalogo_Universal>>> ObtenerDropdownAsync(string? etapa, CancellationToken ct = default);
}
