// ============================================================
// Una vuelta del proceso de envío: lee los correos PENDIENTES (solo el usuario del sistema 0 puede,
// D-80), envía cada uno y lo marca ENVIADO; si falla lo marca con error y la rutina decide si queda
// PENDIENTE (reintento) o ERROR definitivo al llegar a MaxIntentos.
// Si el correo salió pero no se pudo marcar, se registra en el log: en el siguiente ciclo se reenviaría
// (se prefiere duplicar a perder un aviso).
// ============================================================

using System.Net;
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed record ResumenEnvio(int Leidos, int Enviados, int Fallidos, string? ErrorGeneral);

public sealed class ProcesadorCorreos
{
    /// <summary>Usuario del sistema (D-12): el proceso en segundo plano.</summary>
    public const long UsuarioSistema = 0;

    private readonly ISrv_Correo _correos;
    private readonly IEnviadorCorreo _enviador;
    private readonly OpcionesCorreo _op;
    private readonly ILogger<ProcesadorCorreos> _log;

    public ProcesadorCorreos(ISrv_Correo correos, IEnviadorCorreo enviador, IOptions<OpcionesCorreo> op, ILogger<ProcesadorCorreos> log)
    {
        _correos = correos;
        _enviador = enviador;
        _op = op.Value;
        _log = log;
    }

    public async Task<ResumenEnvio> ProcesarLoteAsync(CancellationToken ct = default)
    {
        var lectura = await _correos.PendientesListarAsync(UsuarioSistema, _op.Lote, ct).ConfigureAwait(false);
        if (!lectura.Success)
        {
            _log.LogError("No se pudo leer la cola de correos: {Msg}", lectura.Message);
            return new ResumenEnvio(0, 0, 0, lectura.Message);
        }

        int enviados = 0, fallidos = 0;
        var lista = lectura.Data ?? new();
        foreach (var c in lista)
        {
            ct.ThrowIfCancellationRequested();
            try
            {
                await _enviador.EnviarAsync(await ArmarAsync(c, ct).ConfigureAwait(false), ct).ConfigureAwait(false);
            }
            catch (OperationCanceledException) { throw; }
            catch (Exception ex)
            {
                fallidos++;
                var texto = Recortar(CadenaDeErrores(ex), 400);
                _log.LogWarning("Correo {ID} no enviado (intento {N}): {Msg}", c.ID_Correo_Pendiente, c.Intentos + 1, texto);
                var r = await _correos.MarcarErrorAsync(c.ID_Correo_Pendiente, texto, _op.MaxIntentos, UsuarioSistema, ct).ConfigureAwait(false);
                if (!r.Success)
                    _log.LogError("No se pudo registrar el error del correo {ID}: {Msg}", c.ID_Correo_Pendiente, r.Message);
                continue;
            }

            var m = await _correos.MarcarEnviadoAsync(c.ID_Correo_Pendiente, UsuarioSistema, ct).ConfigureAwait(false);
            if (m.Success) enviados++;
            else _log.LogError("Correo {ID} ENVIADO pero no se pudo marcar: {Msg}", c.ID_Correo_Pendiente, m.Message);
        }

        if (lista.Count > 0)
            _log.LogInformation("Correos: {L} leídos, {E} enviados, {F} con error.", lista.Count, enviados, fallidos);
        return new ResumenEnvio(lista.Count, enviados, fallidos, null);
    }

    private static readonly char[] Separadores = { ';', ',' };

    /// <summary>
    /// Arma el correo completo: lee la solicitud tal como está ahora, aplica la plantilla, depura los
    /// destinatarios (sin repetidos; quien va en Para no se repite en Cc) y fija el hilo:
    /// el aviso de solicitud nueva es la raíz; los demás responden a esa raíz.
    /// </summary>
    internal async Task<MensajeCorreo> ArmarAsync(Dto_Correo_Pendiente c, CancellationToken ct)
    {
        var para = Depurar(c.Destinatarios, null);
        var cc = Depurar(c.Copia, para);
        string? aviso = null;

        if (!string.IsNullOrWhiteSpace(_op.RedirigirA))
        {
            aviso = "MODO PRUEBA: este correo se redirigió a " + _op.RedirigirA + ".\nHabría llegado a: " + string.Join("; ", para)
                    + (cc.Count > 0 ? "\nCon copia a: " + string.Join("; ", cc) : "");
            para = new List<string> { _op.RedirigirA.Trim() };
            cc = new List<string>();
        }

        var dominio = Dominio();
        var esRaiz = c.Tipo == "SOLICITUD_NUEVA";
        var raiz = c.ID_Solicitud is null ? null : $"<caf-sol-{c.ID_Solicitud}@{dominio}>";
        var id = esRaiz && raiz is not null ? raiz : $"<caf-correo-{c.ID_Correo_Pendiente}@{dominio}>";
        var respuestaA = esRaiz ? null : raiz;

        if (c.ID_Solicitud is null)
        {
            var s = PlantillaCorreo.ArmarSimple(c.Tipo, c.Asunto, c.Cuerpo, aviso);
            return new MensajeCorreo(para, cc, s.Asunto, s.Html, s.Texto, id, respuestaA);
        }

        var datos = await _correos.SolicitudDatosAsync(UsuarioSistema, c.ID_Solicitud.Value, ct).ConfigureAwait(false);
        if (!datos.Success || datos.Data is null)
            throw new InvalidOperationException("No se pudieron leer los datos de la solicitud: " + datos.Message);
        var pers = await _correos.SolicitudPersonasAsync(UsuarioSistema, c.ID_Solicitud.Value, ct).ConfigureAwait(false);
        if (!pers.Success)
            throw new InvalidOperationException("No se pudieron leer las personas de la solicitud: " + pers.Message);

        var a = PlantillaCorreo.Armar(c.Tipo, c.Cuerpo, datos.Data, pers.Data ?? new(), _op.UrlBase, !esRaiz, aviso);
        return new MensajeCorreo(para, cc, a.Asunto, a.Html, a.Texto, id, respuestaA);
    }

    private string Dominio()
    {
        var i = _op.Remitente?.IndexOf('@') ?? -1;
        return i >= 0 && i < _op.Remitente!.Length - 1 ? _op.Remitente[(i + 1)..].Trim() : "caf.local";
    }

    internal static List<string> Depurar(string? lista, IEnumerable<string>? excluir)
    {
        var vistos = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        if (excluir is not null) foreach (var e in excluir) vistos.Add(e);
        var res = new List<string>();
        if (string.IsNullOrWhiteSpace(lista)) return res;
        foreach (var d in lista.Split(Separadores, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            if (vistos.Add(d)) res.Add(d);
        return res;
    }

    /// <summary>«Failure sending mail» sola no dice nada: la causa real (clave, red, SSL) viene en las excepciones internas.</summary>
    private static string CadenaDeErrores(Exception ex)
    {
        var partes = new List<string>();
        for (var e = ex; e is not null; e = e.InnerException)
            if (!partes.Contains(e.Message)) partes.Add(e.Message);
        return string.Join(" → ", partes);
    }

    private static string Recortar(string s, int max) => s.Length <= max ? s : s[..max];
}
