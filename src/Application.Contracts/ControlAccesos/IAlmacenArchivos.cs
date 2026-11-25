// D-276: almacén de archivos conectable. Adjuntos de solicitud y documentos de ingreso se guardan en la base (BD), en una carpeta de red (RED) o en Google Drive (DRIVE).
// El almacén vigente lo elige el administrador en «Parámetros» (ALMACEN_ARCHIVOS_TIPO); cada archivo recuerda dónde quedó (Almacen + Ruta_Externa), por eso se pueden mezclar.
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

/// <summary>Dónde quedó un archivo guardado fuera de la base. Ruta = ruta relativa dentro de la carpeta de red, o el id del archivo en Drive. Hash = SHA-256 en hexadecimal minúscula.</summary>
public sealed record ReferenciaArchivo(string Almacen, string Ruta, long Tamano, string Hash);

public interface IAlmacenArchivos
{
    /// <summary>Almacén vigente: BD, RED o DRIVE (BD si no se puede leer el parámetro).</summary>
    Task<string> TipoActualAsync(CancellationToken ct = default);
    /// <summary>Guarda el archivo en el almacén indicado (RED o DRIVE). Devuelve dónde quedó y su huella.</summary>
    Task<Result<ReferenciaArchivo>> GuardarAsync(string almacen, string nombreArchivo, byte[] contenido, CancellationToken ct = default);
    /// <summary>Lee un archivo guardado fuera de la base y verifica su huella (si se conoce).</summary>
    Task<Result<byte[]>> LeerAsync(string almacen, string ruta, string? hash, CancellationToken ct = default);
    /// <summary>Borra un archivo (se usa para deshacer cuando la base rechaza el registro). No lanza errores.</summary>
    Task EliminarAsync(string almacen, string ruta, CancellationToken ct = default);
    /// <summary>Prueba de extremo a extremo: guarda un archivo pequeño, lo lee, compara y lo borra. Devuelve un texto con el detalle.</summary>
    Task<Result<string>> ProbarAsync(string almacen, CancellationToken ct = default);
}
