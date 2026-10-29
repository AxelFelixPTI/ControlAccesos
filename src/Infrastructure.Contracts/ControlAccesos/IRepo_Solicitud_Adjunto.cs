// Acceso a datos de los documentos adjuntos (ERP_CAF_SOLICITUD_ADJUNTO_*). Entrega J.

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Solicitud_Adjunto
{
    Task<ResultSp<long>> AgregarAsync(long solicitudId, string nombreArchivo, string tipoContenido, byte[] contenido, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> QuitarAsync(long adjuntoId, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Adjunto>>> ListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    Task<Result<Dto_Solicitud_Adjunto_Contenido?>> ObtenerAsync(long usuarioId, long adjuntoId, CancellationToken ct = default);
    Task<Result<List<Dto_Correo_Adjunto>>> CorreoAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
}
