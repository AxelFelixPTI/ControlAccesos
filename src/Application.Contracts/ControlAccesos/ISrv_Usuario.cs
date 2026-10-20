// ============================================================
// Usuarios (schema CAF_GOVERNANCE). Por ahora solo lo necesario para crear el primer administrador;
// el login y la gestión completa llegan con la parte web.
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Usuario
{
    Task<Result<long>> CrearAsync(Dto_Usuario_Crear dto, long usuarioId, CancellationToken ct = default);
    Task<Result> EstablecerPasswordAsync(long idUsuario, string passwordPlano, long usuarioId, CancellationToken ct = default);
    Task<Result<long>> AsignarLicenciaAsync(long idUsuario, long idLicencia, long idSede, long usuarioId, CancellationToken ct = default);

    // ── Gestión desde la web ─────────────────────────────────
    Task<Result<List<Dto_Usuario_Lista>>> ListarAsync(string? filtroTexto = null, string? codigoLicencia = null, bool incluirEliminados = false, CancellationToken ct = default);
    Task<Result<Dto_Usuario_Lista?>> DetalleAsync(long idUsuario, CancellationToken ct = default);
    Task<Result> ActualizarAsync(Dto_Usuario_Actualizar dto, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Usuario_Licencia>>> LicenciasListarAsync(long idUsuario, CancellationToken ct = default);

    /// <summary>
    /// Deja al usuario con EXACTAMENTE las licencias deseadas dentro de las «gestionadas» en esa sede:
    /// agrega las que faltan y quita las que sobran. Las licencias fuera de «gestionadas» no se tocan.
    /// </summary>
    Task<Result> SincronizarLicenciasAsync(long idUsuario, long idSede, IReadOnlyCollection<long> deseadas, IReadOnlyCollection<long> gestionadas, long usuarioId, CancellationToken ct = default);
}
