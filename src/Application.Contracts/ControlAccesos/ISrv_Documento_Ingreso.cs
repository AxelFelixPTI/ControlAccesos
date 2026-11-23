using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

/// <summary>D-265: documentos de ingreso del día que sube Vigilancia, asociados a una o varias personas que ingresaron.</summary>
public interface ISrv_Documento_Ingreso
{
    Task<Result<long>> AgregarAsync(long sedeId, DateTime fecha, string tipo, string nombreArchivo, byte[] contenido, IEnumerable<long> personasIds, long usuarioId, CancellationToken ct = default);
    Task<Result> AsignarPersonasAsync(long documentoId, IEnumerable<long> personasIds, long usuarioId, CancellationToken ct = default);
    Task<Result> QuitarAsync(long documentoId, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Documento_Ingreso>>> ListarAsync(long usuarioId, long sedeId, DateTime fecha, CancellationToken ct = default);
    Task<Result<List<Dto_Documento_Ingreso_Busqueda>>> BuscarAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, string? texto, CancellationToken ct = default);
    Task<Result<Dto_Documento_Ingreso_Contenido?>> ObtenerAsync(long usuarioId, long documentoId, CancellationToken ct = default);
    Task<Result<List<Dto_Documento_Ingreso_Persona>>> PersonasDiaAsync(long usuarioId, long sedeId, DateTime fecha, string? texto, bool soloConEquipos, CancellationToken ct = default);
    Task<Result<Dto_Documento_Ingreso_Resumen?>> ResumenAsync(long usuarioId, long sedeId, DateTime fecha, CancellationToken ct = default);
    Task<Result<List<Dto_Documento_Ingreso_Solicitud>>> DeSolicitudAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
}
