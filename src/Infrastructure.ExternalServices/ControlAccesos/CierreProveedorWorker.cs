// ============================================================
// D-218. Servicio en segundo plano del día operativo de proveedores. Cada minuto:
//   1) cierra a la fuerza lo que siguió abierto de un día anterior (libera la exclusa);
//   2) encola el aviso horario de «salida pendiente» a Vigilancia.
// Las rutinas son idempotentes y deciden por la hora de corte (parámetro PROVEEDOR_HORA_CORTE); este servicio solo
// las dispara. Un fallo de una vuelta se registra y se reintenta en la siguiente; nunca detiene el servicio.
// El usuario 0 es «el sistema» (igual que el cierre de «No se presentó»).
// ============================================================

using Application.Contracts.ControlAccesos;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed class CierreProveedorWorker : BackgroundService
{
    private static readonly TimeSpan Espera = TimeSpan.FromMinutes(1);
    private const long UsuarioSistema = 0;

    private readonly IServiceProvider _sp;
    private readonly ILogger<CierreProveedorWorker> _log;

    public CierreProveedorWorker(IServiceProvider sp, ILogger<CierreProveedorWorker> log)
    {
        _sp = sp;
        _log = log;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _log.LogInformation("Cierre del día de proveedores activo (cada {M} min).", Espera.TotalMinutes);
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var ambito = _sp.CreateScope();
                var por = ambito.ServiceProvider.GetRequiredService<ISrv_Porteria>();
                var c = await por.ProveedorCierreDiaAsync(UsuarioSistema, stoppingToken);
                if (c.Success && c.Data > 0) _log.LogWarning("Cierre forzado del día: {N} entrega(s) de proveedor cerradas.", c.Data);
                else if (!c.Success) _log.LogError("Cierre del día de proveedores falló: {M}", c.Message);
                var a = await por.ProveedorAvisosSalidaAsync(UsuarioSistema, stoppingToken);
                if (a.Success && a.Data > 0) _log.LogInformation("Avisos de salida pendiente encolados: {N}.", a.Data);
                else if (!a.Success) _log.LogError("Avisos de salida de proveedores falló: {M}", a.Message);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { break; }
            catch (Exception ex) { _log.LogError(ex, "Falló una vuelta del cierre de proveedores; se reintenta."); }

            try { await Task.Delay(Espera, stoppingToken); }
            catch (OperationCanceledException) { break; }
        }
    }
}
