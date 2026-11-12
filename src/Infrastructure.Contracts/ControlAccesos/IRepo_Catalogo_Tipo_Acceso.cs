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
    // Pantalla «Tipos de ingreso» (V1.1 2026-11-11, D-232)
    Task<Result<List<Dto_Tipo_Acceso_Admin>>> ListarAdminAsync(CancellationToken ct = default);
    Task<Result<List<Dto_Subtipo>>> ListarSubtiposAsync(bool incluirInactivos = false, CancellationToken ct = default);
    // Subtipos (roles de persona) administrables (D-234)
    Task<ResultSp<long>> SubtipoCrearAsync(long idTipo, string codigo, string descripcion, long? idSubtipoCopiar, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> SubtipoActualizarAsync(long idSubtipo, string descripcion, long? orden, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> SubtipoEstadoAsync(long idSubtipo, bool activo, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> SubtipoPredeterminadoAsync(long idSubtipo, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> PrepararAsync(long idTipo, long usuarioId, CancellationToken ct = default);
}
