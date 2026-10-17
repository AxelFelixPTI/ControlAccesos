// ============================================================
// Archivo  : IRepo_Tipo_Acceso_Paso.cs
// Ruta     : Infrastructure.Contracts/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 3 — Contracts
// Entidad  : Tipo_Acceso_Paso_Aprobacion
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Tipo_Acceso_Paso
{
    Task<Result<List<Dto_Tipo_Acceso_Paso>>> ListarPorPadreAsync(long tipoAccesoId, bool incluirInactivos = false, CancellationToken ct = default);
    Task<ResultSp<long>> AgregarAsync(Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> ActualizarAsync(long pasoId, Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> QuitarAsync(long pasoId, long usuarioId, CancellationToken ct = default);
}
