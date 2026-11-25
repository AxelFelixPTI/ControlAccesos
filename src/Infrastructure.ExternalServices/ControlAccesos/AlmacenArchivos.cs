// ============================================================
// D-276: almacén de archivos conectable (carpeta de red / Google Drive).
//  RED   : carpeta del parámetro ALMACEN_RED_RUTA (p. ej. \\fileserver\ControlAccesos). Se escribe con la identidad de Windows con que corre la aplicación;
//          esa cuenta necesita permiso de modificación sobre la carpeta. Ruta guardada = relativa (aaaa/mm/guid.ext).
//  DRIVE : Google Drive por OAuth (refresh token). Alcance drive.file: la aplicación solo ve lo que ella misma crea, dentro de su carpeta (ALMACEN_DRIVE_CARPETA).
//          Ruta guardada = id del archivo en Drive. Sin paquetes externos: HttpClient directo a la API REST v3.
// El contenido se verifica con SHA-256 al leerlo.
// ============================================================

using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Application.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Shared.Results;

namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed class AlmacenArchivos : IAlmacenArchivos
{
    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(100) };
    private static readonly SemaphoreSlim Candado = new(1, 1);
    private static string? _token; private static DateTime _tokenVence = DateTime.MinValue;
    private static readonly Dictionary<string, string> CarpetasDrive = new();

    private readonly ISrv_Parametro _param;
    private readonly OpcionesAlmacen _op;
    private readonly ILogger<AlmacenArchivos> _log;

    public AlmacenArchivos(ISrv_Parametro param, IOptions<OpcionesAlmacen> op, ILogger<AlmacenArchivos> log) { _param = param; _op = op.Value; _log = log; }

    public async Task<string> TipoActualAsync(CancellationToken ct = default)
    {
        var t = (await _param.ValorAsync("ALMACEN_ARCHIVOS_TIPO", "BD", ct).ConfigureAwait(false)).ToUpperInvariant();
        return t is "RED" or "DRIVE" ? t : "BD";
    }

    public static string Sha256(byte[] b) => Convert.ToHexString(SHA256.HashData(b)).ToLowerInvariant();

    private static string ExtensionSegura(string nombre)
    {
        var e = Path.GetExtension(nombre ?? string.Empty).TrimStart('.').ToLowerInvariant();
        return e.Length is > 0 and <= 8 && e.All(char.IsAsciiLetterOrDigit) ? e : "bin";
    }

    // ───────────── GUARDAR / LEER / ELIMINAR ─────────────
    public async Task<Result<ReferenciaArchivo>> GuardarAsync(string almacen, string nombreArchivo, byte[] contenido, CancellationToken ct = default)
    {
        try
        {
            var nombreFisico = Guid.NewGuid().ToString("N") + "." + ExtensionSegura(nombreArchivo);
            string ruta;
            if (almacen == "RED") ruta = await GuardarRedAsync(nombreFisico, contenido, ct).ConfigureAwait(false);
            else if (almacen == "DRIVE") ruta = await GuardarDriveAsync(nombreFisico, contenido, ct).ConfigureAwait(false);
            else return Result<ReferenciaArchivo>.Fail("Almacén de archivos no válido.");
            return Result<ReferenciaArchivo>.Ok(new ReferenciaArchivo(almacen, ruta, contenido.LongLength, Sha256(contenido)));
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "ALMACEN {Almacen} GUARDAR ERROR", almacen);
            return Result<ReferenciaArchivo>.Fail($"No se pudo guardar el archivo en el almacén ({almacen}). Avise al administrador.");
        }
    }

    public async Task<Result<byte[]>> LeerAsync(string almacen, string ruta, string? hash, CancellationToken ct = default)
    {
        try
        {
            var b = almacen == "RED" ? await LeerRedAsync(ruta, ct).ConfigureAwait(false)
                  : almacen == "DRIVE" ? await LeerDriveAsync(ruta, ct).ConfigureAwait(false)
                  : throw new InvalidOperationException("Almacén no válido.");
            if (!string.IsNullOrEmpty(hash) && !string.Equals(Sha256(b), hash, StringComparison.OrdinalIgnoreCase))
            {
                _log.LogError("ALMACEN {Almacen} LEER: la huella no coincide. Ruta={Ruta}", almacen, ruta);
                return Result<byte[]>.Fail("El archivo guardado no coincide con su huella (puede estar dañado o modificado).");
            }
            return Result<byte[]>.Ok(b);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "ALMACEN {Almacen} LEER ERROR Ruta={Ruta}", almacen, ruta);
            return Result<byte[]>.Fail($"No se pudo leer el archivo del almacén ({almacen}). Avise al administrador.");
        }
    }

    public async Task EliminarAsync(string almacen, string ruta, CancellationToken ct = default)
    {
        try
        {
            if (almacen == "RED") { var f = await RutaRedAsync(ruta, ct).ConfigureAwait(false); if (File.Exists(f)) File.Delete(f); }
            else if (almacen == "DRIVE") await EliminarDriveAsync(ruta, ct).ConfigureAwait(false);
        }
        catch (Exception ex) when (ex is not OperationCanceledException) { _log.LogWarning(ex, "ALMACEN {Almacen} ELIMINAR no se pudo. Ruta={Ruta}", almacen, ruta); }
    }

    public async Task<Result<string>> ProbarAsync(string almacen, CancellationToken ct = default)
    {
        var datos = Encoding.UTF8.GetBytes("Prueba de ControlAccesos " + DateTime.Now.ToString("O"));
        var g = await GuardarAsync(almacen, "prueba.txt", datos, ct).ConfigureAwait(false);
        if (!g.Success) return Result<string>.Fail("Guardar: " + g.Message);
        var l = await LeerAsync(almacen, g.Data!.Ruta, g.Data.Hash, ct).ConfigureAwait(false);
        await EliminarAsync(almacen, g.Data.Ruta, ct).ConfigureAwait(false);
        if (!l.Success) return Result<string>.Fail("Leer: " + l.Message);
        return l.Data!.SequenceEqual(datos) ? Result<string>.Ok($"Guardó, leyó, comparó y borró un archivo de prueba ({datos.Length} bytes) en {almacen}.")
                                           : Result<string>.Fail("El contenido leído no coincide con el guardado.");
    }

    // ───────────── CARPETA DE RED ─────────────
    private async Task<string> BaseRedAsync(CancellationToken ct)
    {
        var b = (await _param.ValorAsync("ALMACEN_RED_RUTA", string.Empty, ct).ConfigureAwait(false)).Trim();
        if (b.Length == 0) throw new InvalidOperationException("Falta el parámetro ALMACEN_RED_RUTA.");
        return Path.GetFullPath(b);
    }

    /// <summary>Ruta física de una ruta relativa, sin permitir salir de la carpeta base.</summary>
    private async Task<string> RutaRedAsync(string ruta, CancellationToken ct)
    {
        var b = await BaseRedAsync(ct).ConfigureAwait(false);
        var f = Path.GetFullPath(Path.Combine(b, ruta.Replace('\\', Path.DirectorySeparatorChar).Replace('/', Path.DirectorySeparatorChar)));
        var baseSep = b.EndsWith(Path.DirectorySeparatorChar) ? b : b + Path.DirectorySeparatorChar;
        if (!f.StartsWith(baseSep, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Ruta fuera de la carpeta del almacén.");
        return f;
    }

    private async Task<string> GuardarRedAsync(string nombreFisico, byte[] contenido, CancellationToken ct)
    {
        var rel = $"{DateTime.Now:yyyy}/{DateTime.Now:MM}/{nombreFisico}";
        var destino = await RutaRedAsync(rel, ct).ConfigureAwait(false);
        Directory.CreateDirectory(Path.GetDirectoryName(destino)!);
        var tmp = destino + ".tmp";
        await File.WriteAllBytesAsync(tmp, contenido, ct).ConfigureAwait(false);
        File.Move(tmp, destino, overwrite: false);     // escritura atómica: nunca queda un archivo a medias con el nombre final
        return rel;
    }

    private async Task<byte[]> LeerRedAsync(string ruta, CancellationToken ct)
        => await File.ReadAllBytesAsync(await RutaRedAsync(ruta, ct).ConfigureAwait(false), ct).ConfigureAwait(false);

    // ───────────── GOOGLE DRIVE ─────────────
    private async Task<string> TokenAsync(CancellationToken ct)
    {
        if (_token is not null && DateTime.UtcNow < _tokenVence) return _token;
        var d = _op.Drive;
        if (!d.Completo) throw new InvalidOperationException("Faltan las credenciales de Drive (Almacen__Drive__ClientId / ClientSecret / RefreshToken).");
        await Candado.WaitAsync(ct).ConfigureAwait(false);
        try
        {
            if (_token is not null && DateTime.UtcNow < _tokenVence) return _token;
            using var req = new HttpRequestMessage(HttpMethod.Post, "https://oauth2.googleapis.com/token")
            {
                Content = new FormUrlEncodedContent(new Dictionary<string, string>
                {
                    ["client_id"] = d.ClientId, ["client_secret"] = d.ClientSecret, ["refresh_token"] = d.RefreshToken, ["grant_type"] = "refresh_token",
                }),
            };
            using var resp = await Http.SendAsync(req, ct).ConfigureAwait(false);
            var json = await resp.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
            if (!resp.IsSuccessStatusCode) throw new InvalidOperationException($"Google rechazó la renovación del acceso ({(int)resp.StatusCode}): {json}");
            using var doc = JsonDocument.Parse(json);
            _token = doc.RootElement.GetProperty("access_token").GetString();
            _tokenVence = DateTime.UtcNow.AddSeconds(Math.Max(60, doc.RootElement.GetProperty("expires_in").GetInt32() - 120));
            return _token!;
        }
        finally { Candado.Release(); }
    }

    private async Task<HttpResponseMessage> DriveAsync(HttpMethod m, string url, HttpContent? contenido, CancellationToken ct)
    {
        var req = new HttpRequestMessage(m, url) { Content = contenido };
        req.Headers.Authorization = new("Bearer", await TokenAsync(ct).ConfigureAwait(false));
        return await Http.SendAsync(req, ct).ConfigureAwait(false);
    }

    private static async Task<JsonDocument> JsonOkAsync(HttpResponseMessage r, string que, CancellationToken ct)
    {
        var s = await r.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        if (!r.IsSuccessStatusCode) throw new InvalidOperationException($"Drive: {que} falló ({(int)r.StatusCode}): {s}");
        return JsonDocument.Parse(s);
    }

    /// <summary>Id de la carpeta de la aplicación en Drive (la busca por nombre entre lo que la propia aplicación creó; si no existe, la crea).</summary>
    private async Task<string> CarpetaDriveAsync(CancellationToken ct)
    {
        var nombre = (await _param.ValorAsync("ALMACEN_DRIVE_CARPETA", "ControlAccesos_Adjuntos", ct).ConfigureAwait(false)).Trim();
        if (nombre.Length == 0) nombre = "ControlAccesos_Adjuntos";
        lock (CarpetasDrive) { if (CarpetasDrive.TryGetValue(nombre, out var c)) return c; }
        var q = $"name = '{nombre.Replace("\\", "\\\\").Replace("'", "\\'")}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false and 'root' in parents";
        using var rb = await DriveAsync(HttpMethod.Get, "https://www.googleapis.com/drive/v3/files?fields=files(id)&q=" + Uri.EscapeDataString(q), null, ct).ConfigureAwait(false);
        using var jb = await JsonOkAsync(rb, "buscar la carpeta", ct).ConfigureAwait(false);
        string? id = null;
        foreach (var f in jb.RootElement.GetProperty("files").EnumerateArray()) { id = f.GetProperty("id").GetString(); break; }
        if (id is null)
        {
            var meta = JsonSerializer.Serialize(new { name = nombre, mimeType = "application/vnd.google-apps.folder" });
            using var rc = await DriveAsync(HttpMethod.Post, "https://www.googleapis.com/drive/v3/files?fields=id", new StringContent(meta, Encoding.UTF8, "application/json"), ct).ConfigureAwait(false);
            using var jc = await JsonOkAsync(rc, "crear la carpeta", ct).ConfigureAwait(false);
            id = jc.RootElement.GetProperty("id").GetString();
        }
        lock (CarpetasDrive) { CarpetasDrive[nombre] = id!; }
        return id!;
    }

    private async Task<string> GuardarDriveAsync(string nombreFisico, byte[] contenido, CancellationToken ct)
    {
        var carpeta = await CarpetaDriveAsync(ct).ConfigureAwait(false);
        var meta = JsonSerializer.Serialize(new { name = nombreFisico, parents = new[] { carpeta } });
        using var multi = new MultipartContent("related", "ca_" + Guid.NewGuid().ToString("N"));
        multi.Add(new StringContent(meta, Encoding.UTF8, "application/json"));
        var bin = new ByteArrayContent(contenido); bin.Headers.ContentType = new("application/octet-stream");
        multi.Add(bin);
        using var r = await DriveAsync(HttpMethod.Post, "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id", multi, ct).ConfigureAwait(false);
        using var j = await JsonOkAsync(r, "subir el archivo", ct).ConfigureAwait(false);
        return j.RootElement.GetProperty("id").GetString()!;
    }

    private static string IdDrive(string ruta)
    {
        if (ruta.Length is 0 or > 120 || !ruta.All(c => char.IsAsciiLetterOrDigit(c) || c is '-' or '_')) throw new InvalidOperationException("Identificador de Drive no válido.");
        return ruta;
    }

    private async Task<byte[]> LeerDriveAsync(string ruta, CancellationToken ct)
    {
        using var r = await DriveAsync(HttpMethod.Get, $"https://www.googleapis.com/drive/v3/files/{IdDrive(ruta)}?alt=media", null, ct).ConfigureAwait(false);
        if (!r.IsSuccessStatusCode) throw new InvalidOperationException($"Drive: descargar falló ({(int)r.StatusCode}).");
        return await r.Content.ReadAsByteArrayAsync(ct).ConfigureAwait(false);
    }

    private async Task EliminarDriveAsync(string ruta, CancellationToken ct)
    {
        using var r = await DriveAsync(HttpMethod.Delete, $"https://www.googleapis.com/drive/v3/files/{IdDrive(ruta)}", null, ct).ConfigureAwait(false);
        if (!r.IsSuccessStatusCode && (int)r.StatusCode != 404) throw new InvalidOperationException($"Drive: borrar falló ({(int)r.StatusCode}).");
    }
}
