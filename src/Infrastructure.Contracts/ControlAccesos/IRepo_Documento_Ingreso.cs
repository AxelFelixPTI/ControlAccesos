using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

/// <summary>D-265: documentos de ingreso del día (los sube Vigilancia). Procedimientos ERP_CAF_DOC_INGRESO_*.</summary>
public interface IRepo_Documento_Ingreso
{
    Task<ResultSp<long>> AgregarAsync(long sedeId, DateTime fecha, string tipo, string nombreArchivo, string tipoContenido, byte[] contenido, string personasIds, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> AsignarPersonasAsync(long documentoId, string personasIds, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> QuitarAsync(long documentoId, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Documento_Ingreso>>> ListarAsync(long usuarioId, long sedeId, DateTime fecha, CancellationToken ct = default);
    Task<Result<List<Dto_Documento_Ingreso_Busqueda>>> BuscarAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, string? texto, CancellationToken ct = default);
    Task<Result<Dto_Documento_Ingreso_Contenido?>> ObtenerAsync(long usuarioId, long documentoId, CancellationToken ct = default);
    Task<Result<List<Dto_Documento_Ingreso_Persona>>> PersonasDiaAsync(long usuarioId, long sedeId, DateTime fecha, string? texto, bool soloConEquipos, CancellationToken ct = default);
    Task<Result<Dto_Documento_Ingreso_Resumen?>> ResumenAsync(long usuarioId, long sedeId, DateTime fecha, CancellationToken ct = default);
    Task<Result<List<Dto_Documento_Ingreso_Solicitud>>> DeSolicitudAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
}
