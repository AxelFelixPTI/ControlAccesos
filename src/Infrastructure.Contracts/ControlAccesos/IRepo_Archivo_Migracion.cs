// D-276: acceso a datos de la migración de archivos a un almacén externo (ERP_CAF_ARCHIVO_PENDIENTES_MIGRAR / _MIGRADO / _ESTADISTICA). Solo la consola de operación (usuario sistema 0).
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public sealed class ArchivoPendiente
{
    public long ID { get; set; }
    public string Nombre_Archivo { get; set; } = string.Empty;
    public string Extension { get; set; } = string.Empty;
    public string? Hash_SHA256 { get; set; }
    public byte[] Contenido { get; set; } = Array.Empty<byte>();
}

public sealed class ArchivoEstadistica
{
    public string Tabla { get; set; } = string.Empty;
    public string Almacen { get; set; } = string.Empty;
    public long Cantidad { get; set; }
    public long Bytes { get; set; }
    public long Con_Contenido_En_BD { get; set; }
}

public interface IRepo_Archivo_Migracion
{
    Task<Result<List<ArchivoPendiente>>> PendientesAsync(string tabla, int maximo, CancellationToken ct = default);
    Task<ResultSp> MigradoAsync(string tabla, long id, string almacen, string ruta, bool vaciar, CancellationToken ct = default);
    Task<Result<List<ArchivoEstadistica>>> EstadisticaAsync(CancellationToken ct = default);
}
