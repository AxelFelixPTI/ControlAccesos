// D-276. SP: ERP_CAF_ARCHIVO_PENDIENTES_MIGRAR (lectura), ERP_CAF_ARCHIVO_MIGRADO (escritura), ERP_CAF_ARCHIVO_ESTADISTICA (lectura). Usuario sistema = 0.
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Archivo_Migracion : RepoHelpers, IRepo_Archivo_Migracion
{
    private readonly EjecutorSp _exec;
    private readonly ILogger<Repo_Archivo_Migracion> _log;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Archivo_Migracion(EjecutorSp exec, ILogger<Repo_Archivo_Migracion> log) { _exec = exec; _log = log; }

    public async Task<Result<List<ArchivoPendiente>>> PendientesAsync(string tabla, int maximo, CancellationToken ct = default)
    {
        try
        {
            var l = await _exec.EjecutarLecturaAsync(Conn, "ERP_CAF_ARCHIVO_PENDIENTES_MIGRAR",
                p => { AddLongReq(p, "HV_UsuarioID", 0); AddStrReq(p, "HV_Tabla", tabla); AddInt(p, "HV_Maximo", maximo); },
                rd => new ArchivoPendiente
                {
                    ID = RdLong(rd, "ID"), Nombre_Archivo = RdStr(rd, "Nombre_Archivo"), Extension = RdStr(rd, "Extension"),
                    Hash_SHA256 = RdStrN(rd, "Hash_SHA256"), Contenido = RdBytes(rd, "Contenido"),
                }, ct);
            return Result<List<ArchivoPendiente>>.Ok(l);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "ARCHIVO_PENDIENTES_MIGRAR ERROR");
            return Result<List<ArchivoPendiente>>.Fail("No se pudieron leer los archivos pendientes.");
        }
    }

    public Task<ResultSp> MigradoAsync(string tabla, long id, string almacen, string ruta, bool vaciar, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_ARCHIVO_MIGRADO",
            bind: p =>
            {
                AddStrReq(p, "HV_Tabla", tabla); AddLongReq(p, "HV_ID", id); AddStrReq(p, "HV_Almacen", almacen);
                AddStrReq(p, "HV_Ruta_Externa", ruta); AddChar1(p, "HV_Vaciar", vaciar ? "Y" : "N"); AddLongReq(p, "HV_UsuarioID", 0);
            },
            ct: ct);

    public async Task<Result<List<ArchivoEstadistica>>> EstadisticaAsync(CancellationToken ct = default)
    {
        try
        {
            var l = await _exec.EjecutarLecturaAsync(Conn, "ERP_CAF_ARCHIVO_ESTADISTICA",
                p => AddLongReq(p, "HV_UsuarioID", 0),
                rd => new ArchivoEstadistica
                {
                    Tabla = RdStr(rd, "Tabla"), Almacen = RdStr(rd, "Almacen"), Cantidad = RdLong(rd, "Cantidad"),
                    Bytes = RdLong(rd, "Bytes"), Con_Contenido_En_BD = RdLong(rd, "Con_Contenido_En_BD"),
                }, ct);
            return Result<List<ArchivoEstadistica>>.Ok(l);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "ARCHIVO_ESTADISTICA ERROR");
            return Result<List<ArchivoEstadistica>>.Fail("No se pudo leer el resumen de archivos.");
        }
    }
}
