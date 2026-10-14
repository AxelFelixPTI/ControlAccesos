// ============================================================
// Archivo  : IRepo_Catalogo_Licencia.cs
// Ruta     : Infrastructure.Contracts/ControlAccesos/
// Módulo   : ControlAccesos
// Hito     : 0 — Base
// Fase     : 3 — Contracts
// Entidad  : Catalogo_Licencia
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Catalogo_Licencia
{
    Task<Result<List<Dto_Catalogo_Universal>>> ListarAsync(bool incluirEliminados = false, CancellationToken ct = default);
    Task<Result<List<Dto_Catalogo_Universal>>> ObtenerDropdownAsync(CancellationToken ct = default);
}
