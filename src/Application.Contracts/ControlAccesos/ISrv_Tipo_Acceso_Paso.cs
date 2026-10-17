// ============================================================
// Archivo  : ISrv_Tipo_Acceso_Paso.cs
// Ruta     : Application.Contracts/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 3 — Contracts
// Entidad  : Tipo_Acceso_Paso_Aprobacion
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Tipo_Acceso_Paso
{
    Task<Result<List<Dto_Tipo_Acceso_Paso>>> ListarPorPadreAsync(long tipoAccesoId, bool incluirInactivos = false, CancellationToken ct = default);
    Task<Result<long>> AgregarAsync(Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, CancellationToken ct = default);
    Task<Result> ActualizarAsync(long pasoId, Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, CancellationToken ct = default);
    Task<Result> QuitarAsync(long pasoId, long usuarioId, CancellationToken ct = default);
}
