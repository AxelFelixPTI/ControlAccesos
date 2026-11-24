// D-238: parámetros del sistema.
using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Parametro
{
    Task<Result<List<Dto_Parametro>>> ListarAsync(CancellationToken ct = default);
    /// <summary>D-239: ¿se exige la placa del vehículo del conductor? (PLACA_OBLIGATORIA; por defecto sí, también si no se puede leer).</summary>
    Task<bool> PlacaObligatoriaAsync(CancellationToken ct = default);
    /// <summary>D-257: ¿Vigilancia puede registrar incidencias a personas que ya salieron? (INCIDENCIA_POST_SALIDA; por defecto no, también si no se puede leer).</summary>
    Task<bool> IncidenciaPostSalidaAsync(CancellationToken ct = default);
    /// <summary>D-271: ¿la aplicación envía sola los avisos por correo? (CORREO_ENVIO_AUTOMATICO; por defecto no, también si no se puede leer).</summary>
    Task<bool> CorreoEnvioAutomaticoAsync(CancellationToken ct = default);
    Task<Result> GuardarAsync(string clave, string? valor, long usuarioId, CancellationToken ct = default);
}
