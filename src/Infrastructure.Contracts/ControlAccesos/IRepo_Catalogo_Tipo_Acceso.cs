// ============================================================
// Archivo  : IRepo_Catalogo_Tipo_Acceso.cs
// Ruta     : Infrastructure.Contracts/ControlAccesos/
// Módulo   : ControlAccesos
// Hito     : 1 — Catálogos del módulo
// Fase     : 3 — Contracts
// Entidad  : Catalogo_Tipo_Acceso
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Catalogo_Tipo_Acceso
{
    Task<Result<List<Dto_Catalogo_Universal>>> ListarAsync(bool incluirEliminados = false, CancellationToken ct = default);
    Task<ResultSp<long>> CrearAsync(Dto_Catalogo_Universal dto, long usuarioId, CancellationToken ct = default);
    Task<Result<Dto_Catalogo_Universal?>> DetalleAsync(long id, CancellationToken ct = default);
    Task<ResultSp> ActualizarAsync(long id, Dto_Catalogo_Universal dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> EliminarAsync(long id, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Catalogo_Universal>>> ObtenerDropdownAsync(CancellationToken ct = default);
}
