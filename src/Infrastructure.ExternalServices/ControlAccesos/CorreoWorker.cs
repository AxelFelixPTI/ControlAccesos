// ============================================================
// Servicio en segundo plano: repite ProcesarLoteAsync cada Correo:IntervaloSegundos.
// Un fallo de una vuelta (base caída, etc.) se registra y se reintenta en la siguiente; nunca detiene el servicio.
// ============================================================

using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed class CorreoWorker : BackgroundService
{
    private readonly IServiceProvider _sp;
    private readonly OpcionesCorreo _op;
    private readonly ILogger<CorreoWorker> _log;

    public CorreoWorker(IServiceProvider sp, IOptions<OpcionesCorreo> op, ILogger<CorreoWorker> log)
    {
        _sp = sp;
        _op = op.Value;
        _log = log;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var espera = TimeSpan.FromSeconds(Math.Max(5, _op.IntervaloSegundos));
        _log.LogInformation("Envío de correos activo (modo {Modo}, cada {S} s).", _op.Modo, espera.TotalSeconds);
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var ambito = _sp.CreateScope();
                await ambito.ServiceProvider.GetRequiredService<ProcesadorCorreos>().ProcesarLoteAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            catch (Exception ex) { _log.LogError(ex, "Falló una vuelta del envío de correos; se reintenta."); }

            try { await Task.Delay(espera, stoppingToken); }
            catch (OperationCanceledException) { break; }
        }
    }
}
