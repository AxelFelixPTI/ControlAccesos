// D-276: migración de archivos de la base a RED o DRIVE. Seguridad: guarda → relee → compara SHA-256 → recién entonces anota en la base (y vacía si se pidió).
using Application.Contracts.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Migracion_Archivos : ISrv_Migracion_Archivos
{
    private readonly IRepo_Archivo_Migracion _repo;
    private readonly IAlmacenArchivos _almacen;
    private readonly ILogger<Srv_Migracion_Archivos> _logger;

    public Srv_Migracion_Archivos(IRepo_Archivo_Migracion repo, IAlmacenArchivos almacen, ILogger<Srv_Migracion_Archivos> logger) { _repo = repo; _almacen = almacen; _logger = logger; }

    public async Task<Result<List<LineaEstadistica>>> EstadisticaAsync(CancellationToken ct = default)
    {
        var r = await _repo.EstadisticaAsync(ct).ConfigureAwait(false);
        if (!r.Success) return Result<List<LineaEstadistica>>.Fail(r.Message);
        return Result<List<LineaEstadistica>>.Ok(r.Data!.Select(x => new LineaEstadistica(x.Tabla, x.Almacen, x.Cantidad, x.Bytes, x.Con_Contenido_En_BD)).ToList());
    }

    public async Task<Result<ResumenMigracion>> MigrarAsync(string destino, bool vaciar, int maximo, CancellationToken ct = default)
    {
        if (destino is not ("RED" or "DRIVE")) return Result<ResumenMigracion>.Fail("El destino debe ser RED o DRIVE.");
        int rev = 0, ok = 0, mal = 0; long bytes = 0; var errores = new List<string>();
        foreach (var tabla in new[] { "ADJUNTO", "DOC_INGRESO" })
        {
            var lote = await _repo.PendientesAsync(tabla, maximo, ct).ConfigureAwait(false);
            if (!lote.Success) return Result<ResumenMigracion>.Fail(lote.Message);
            foreach (var a in lote.Data!)
            {
                rev++;
                var g = await _almacen.GuardarAsync(destino, a.Nombre_Archivo + "." + a.Extension, a.Contenido, ct).ConfigureAwait(false);
                if (!g.Success) { mal++; errores.Add($"{tabla} {a.ID}: {g.Message}"); continue; }
                var l = await _almacen.LeerAsync(destino, g.Data!.Ruta, g.Data.Hash, ct).ConfigureAwait(false);
                if (!l.Success || !l.Data!.AsSpan().SequenceEqual(a.Contenido))
                {
                    await _almacen.EliminarAsync(destino, g.Data.Ruta, ct).ConfigureAwait(false);
                    mal++; errores.Add($"{tabla} {a.ID}: la copia no coincide con el original; no se anotó."); continue;
                }
                var sp = await _repo.MigradoAsync(tabla, a.ID, destino, g.Data.Ruta, vaciar, ct).ConfigureAwait(false);
                if (!sp.Ok) { await _almacen.EliminarAsync(destino, g.Data.Ruta, ct).ConfigureAwait(false); mal++; errores.Add($"{tabla} {a.ID}: {sp.Mensaje}"); continue; }
                ok++; bytes += a.Contenido.LongLength;
            }
        }
        _logger.LogInformation("MIGRAR_ARCHIVOS destino={Destino} revisados={Rev} migrados={Ok} fallidos={Mal}", destino, rev, ok, mal);
        return Result<ResumenMigracion>.Ok(new ResumenMigracion(rev, ok, mal, bytes, errores));
    }
}
