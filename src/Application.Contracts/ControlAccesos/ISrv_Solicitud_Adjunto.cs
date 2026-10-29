// Documentos adjuntos de la solicitud (Entrega J, D-183/D-184). Las reglas (dueño, estado, máximo 2, 5 MB,
// quién ve) viven en las rutinas; aquí solo se valida el archivo en el servidor (extensión, firma, tamaño).

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Solicitud_Adjunto
{
    /// <summary>Valida el archivo (extensión, firma y tamaño) y lo guarda. Devuelve el ID del documento.</summary>
    Task<Result<long>> AgregarAsync(long solicitudId, string nombreArchivo, byte[] contenido, long usuarioId, CancellationToken ct = default);
    Task<Result> QuitarAsync(long adjuntoId, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Solicitud_Adjunto>>> ListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    /// <summary>Documento con su contenido; Data nulo si no existe o el usuario no puede verlo.</summary>
    Task<Result<Dto_Solicitud_Adjunto_Contenido?>> ObtenerAsync(long usuarioId, long adjuntoId, CancellationToken ct = default);
    /// <summary>Solo el proceso de envío (usuario sistema 0): documentos de la solicitud para el correo.</summary>
    Task<Result<List<Dto_Correo_Adjunto>>> CorreoAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
}
