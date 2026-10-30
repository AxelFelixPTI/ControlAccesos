// ============================================================
// Archivo  : ISrv_Solicitud.cs
// Ruta     : Application.Contracts/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 3 — Contracts
// Entidad  : Solicitud
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Solicitud
{
    /// <summary>Empresas ya escritas en solicitudes, para autocompletar (máx. 10).</summary>
    Task<Result<List<string>>> EmpresasBuscarAsync(string? texto, CancellationToken ct = default);
    /// <summary>Tipos de ingreso activos para el selector (Proveedor sale con Usable = false).</summary>
    Task<Result<List<Dto_Solicitud_Tipo_Opcion>>> TiposOpcionesAsync(CancellationToken ct = default);
    /// <summary>Sedes donde el usuario puede crear solicitudes, con la marca de cochera.</summary>
    Task<Result<List<Dto_Solicitud_Sede_Opcion>>> SedesOpcionesAsync(long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Lista>>> MisListarAsync(long usuarioId, Dto_Filtro_Mis_Solicitudes? f = null, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Bandeja>>> BandejaListarAsync(long usuarioId, Dto_Filtro_Bandeja? f = null, CancellationToken ct = default);
    Task<Result<Dto_Solicitud_Contadores>> ContadoresAsync(long usuarioId, long? sedeId = null, CancellationToken ct = default);
    Task<Result<Dto_Solicitud_Detalle>> DetalleAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Persona>>> PersonasListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Paso>>> PasosListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Evento>>> HistorialListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Version>>> VersionesListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<Dto_Solicitud_Creada>> CrearAsync(Dto_Solicitud_Crear dto, long usuarioId, CancellationToken ct = default);
    Task<Result<bool>> EditarDatosAsync(long solicitudId, Dto_Solicitud_Editar dto, long usuarioId, CancellationToken ct = default);
    Task<Result> CancelarAsync(long solicitudId, string? motivo, long usuarioId, CancellationToken ct = default);
}
