// ============================================================
// «¿Olvidó su contraseña?»: emite un enlace de un solo uso y lo manda por correo.
// ============================================================

using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Restablecer
{
    /// <summary>
    /// Si el correo pertenece a una cuenta activa, encola un correo con el enlace para definir una contraseña nueva.
    /// SIEMPRE responde igual (éxito), exista o no el correo, para no revelar qué cuentas existen.
    /// </summary>
    Task<Result> SolicitarAsync(string correo, string urlBase, CancellationToken ct = default);
}
