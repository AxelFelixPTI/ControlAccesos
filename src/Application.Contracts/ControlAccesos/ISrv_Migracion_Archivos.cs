// D-276: pasa a un almacén externo (RED o DRIVE) los archivos que hoy están en la base. Solo lo usa la consola de operación.
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public sealed record ResumenMigracion(int Revisados, int Migrados, int Fallidos, long Bytes, List<string> Errores);
public sealed record LineaEstadistica(string Tabla, string Almacen, long Cantidad, long Bytes, long ConContenidoEnBd);

public interface ISrv_Migracion_Archivos
{
    Task<Result<List<LineaEstadistica>>> EstadisticaAsync(CancellationToken ct = default);
    /// <summary>Migra hasta <paramref name="maximo"/> archivos por tabla. Cada archivo se guarda en el destino, se vuelve a leer y se compara su huella ANTES de anotarlo en la base; con <paramref name="vaciar"/> se borra además su contenido de la base.</summary>
    Task<Result<ResumenMigracion>> MigrarAsync(string destino, bool vaciar, int maximo, CancellationToken ct = default);
}
