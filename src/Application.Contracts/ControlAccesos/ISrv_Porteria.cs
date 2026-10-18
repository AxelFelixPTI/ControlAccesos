// ============================================================
// Archivo  : ISrv_Porteria.cs
// Ruta     : Application.Contracts/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 3 — Contracts
// Entidad  : Porteria
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Porteria
{
    Task<Result<List<Dto_Porteria_Item>>> ChecklistObtenerAsync(long usuarioId, long solicitudPersonaId, string etapa, bool traeEquipos = false, bool traeHerramientas = false, CancellationToken ct = default);
    Task<Result<Dto_Porteria_Ficha>> FichaAsync(long usuarioId, long solicitudPersonaId, CancellationToken ct = default);
    Task<Result<List<Dto_Porteria_Movimiento>>> MovimientosListarAsync(long usuarioId, Dto_Filtro_Movimientos f, CancellationToken ct = default);
    Task<Result<Dto_Porteria_Registro>> RegistroDetalleAsync(long usuarioId, long registroId, CancellationToken ct = default);
    Task<Result<List<Dto_Porteria_Registro_Item>>> RegistroChecklistListarAsync(long usuarioId, long registroId, CancellationToken ct = default);
    Task<Result<Dto_Porteria_Registrado>> IngresoRegistrarAsync(Dto_Porteria_Ingreso dto, long usuarioId, CancellationToken ct = default);
    Task<Result<Dto_Porteria_Registrado>> SalidaRegistrarAsync(Dto_Porteria_Salida dto, long usuarioId, CancellationToken ct = default);
    Task<Result<long>> NoSePresentoMarcarAsync(DateTime? fechaCorte, long usuarioId, CancellationToken ct = default);
}
