// ============================================================
// Archivo  : IRepo_Solicitud.cs
// Ruta     : Infrastructure.Contracts/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 3 — Contracts
// Entidad  : Solicitud
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Solicitud
{
    Task<Result<List<string>>> EmpresasBuscarAsync(string? texto, CancellationToken ct = default);
    Task<Result<List<Dto_Correo_Sugerido>>> CorreosSugerirAsync(string? texto, CancellationToken ct = default);
    /// <summary>Tipos de ingreso activos para el selector (el tipo Proveedor solo se ofrece a quien tiene la licencia de solicitante de proveedores).</summary>
    Task<Result<List<Dto_Solicitud_Tipo_Opcion>>> TiposOpcionesAsync(long usuarioId, CancellationToken ct = default);
    /// <summary>Sedes donde el usuario puede crear solicitudes, con la marca de cochera.</summary>
    Task<Result<List<Dto_Solicitud_Sede_Opcion>>> SedesOpcionesAsync(long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Lista>>> MisListarAsync(long usuarioId, Dto_Filtro_Mis_Solicitudes? f = null, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Bandeja>>> BandejaListarAsync(long usuarioId, Dto_Filtro_Bandeja? f = null, CancellationToken ct = default);
    Task<Result<Dto_Solicitud_Contadores?>> ContadoresAsync(long usuarioId, long? sedeId = null, CancellationToken ct = default);
    Task<Result<Dto_Solicitud_Detalle?>> DetalleAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Persona>>> PersonasListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Transportista>>> TransportistasListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    /// <summary>D-227: días autorizados del contratista por franja (vacío si la solicitud no es de franja).</summary>
    Task<Result<List<Dto_Solicitud_Dia>>> DiasListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    /// <summary>D-227: el Coordinador agrega días a una solicitud aprobada (emergencia). Devuelve cuántos agregó.</summary>
    Task<ResultSp<int>> DiasExtenderAsync(long solicitudId, IReadOnlyList<string> dias, string? horaDesde, string? horaHasta, string sustento, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Paso>>> PasosListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Evento>>> HistorialListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Version>>> VersionesListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<ResultSp<Dto_Solicitud_Creada>> CrearAsync(Dto_Solicitud_Crear dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp<bool>> EditarDatosAsync(long solicitudId, Dto_Solicitud_Editar dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> CancelarAsync(long solicitudId, string? motivo, long usuarioId, CancellationToken ct = default);
    /// <summary>D-236: reemplaza las empresas que reciben la solicitud de proveedor (la primera queda como principal).</summary>
    Task<ResultSp> EmpresasAsignarAsync(long solicitudId, IReadOnlyList<long> empresasIds, long usuarioId, CancellationToken ct = default);
    /// <summary>D-237: guarda OC, empresa transportista, franja «Hasta» y correos del responsable de una entrega de proveedor (después de editar los datos).</summary>
    Task<ResultSp> ProveedorDatosGuardarAsync(long solicitudId, Dto_Proveedor_Datos dto, long usuarioId, CancellationToken ct = default);
}
