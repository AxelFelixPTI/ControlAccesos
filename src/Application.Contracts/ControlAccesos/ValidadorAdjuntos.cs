// ============================================================
// Entrega J (D-183). Validación de un documento adjunto EN EL SERVIDOR: extensión permitida, tamaño y
// firma real del archivo (no se confía solo en la extensión ni en el tipo que declara el navegador).
// Lógica pura, sin dependencias (vive en Application.Contracts para que la usen el servicio y el envío de correos). El SP repite extensión y tamaño: la última palabra la tiene la base.
// Límite: la firma confirma la familia del formato (PDF, Office antiguo, Office moderno) pero no prueba que
// el archivo sea un Word o un Excel válido ni que esté libre de código malicioso.
// ============================================================

namespace Application.Contracts.ControlAccesos;

public static class ValidadorAdjuntos
{
    public const int MaxBytes = 5 * 1024 * 1024;
    public const int MaxPorSolicitud = 2;

    public const string Permitidos = "PDF, Word (DOC, DOCX) y Excel (XLS, XLSX)";

    private static readonly Dictionary<string, string> Tipos = new(StringComparer.OrdinalIgnoreCase)
    {
        ["pdf"]  = "application/pdf",
        ["doc"]  = "application/msword",
        ["docx"] = "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        ["xls"]  = "application/vnd.ms-excel",
        ["xlsx"] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    };

    /// <summary>Nombre sin carpetas ni caracteres de control (lo que el navegador envía puede traer la ruta).</summary>
    public static string LimpiarNombre(string? nombre)
    {
        var n = (nombre ?? string.Empty).Trim();
        var i = Math.Max(n.LastIndexOf('/'), n.LastIndexOf('\\'));
        if (i >= 0) n = n[(i + 1)..];
        return new string(n.Where(c => !char.IsControl(c)).ToArray()).Trim();
    }

    public static string? Extension(string nombre)
    {
        var i = nombre.LastIndexOf('.');
        return i > 0 && i < nombre.Length - 1 ? nombre[(i + 1)..].ToLowerInvariant() : null;
    }

    /// <summary>Tipo de contenido que se guarda y se devuelve al descargar: sale de la extensión, no del cliente.</summary>
    public static string TipoContenido(string extension)
        => Tipos.TryGetValue(extension, out var t) ? t : "application/octet-stream";

    /// <summary>null si el archivo es válido; si no, el mensaje para el usuario.</summary>
    public static string? Validar(string? nombreOriginal, byte[]? contenido, out string nombre, out string extension)
    {
        nombre = LimpiarNombre(nombreOriginal);
        extension = Extension(nombre) ?? string.Empty;
        if (nombre.Length == 0 || nombre.Length > 200) return "El nombre del archivo debe tener entre 1 y 200 caracteres.";
        if (!Tipos.ContainsKey(extension)) return $"«{nombre}»: solo se permiten archivos {Permitidos}.";
        if (contenido is null || contenido.Length == 0) return $"«{nombre}» está vacío.";
        if (contenido.Length > MaxBytes) return $"«{nombre}» supera el máximo de {MaxBytes / (1024 * 1024)} MB.";
        if (!FirmaCoincide(extension, contenido)) return $"«{nombre}» no parece un archivo {extension.ToUpperInvariant()} válido (el contenido no coincide con la extensión).";
        return null;
    }

    private static bool FirmaCoincide(string ext, byte[] b)
    {
        switch (ext.ToLowerInvariant())
        {
            case "pdf":   // "%PDF-" dentro de los primeros 1024 bytes
                var limite = Math.Min(b.Length - 4, 1024);
                for (var i = 0; i < limite; i++)
                    if (b[i] == 0x25 && b[i + 1] == 0x50 && b[i + 2] == 0x44 && b[i + 3] == 0x46 && b[i + 4] == 0x2D) return true;
                return false;
            case "doc":
            case "xls":   // contenedor OLE2
                return b.Length >= 8 && b[0] == 0xD0 && b[1] == 0xCF && b[2] == 0x11 && b[3] == 0xE0 && b[4] == 0xA1 && b[5] == 0xB1 && b[6] == 0x1A && b[7] == 0xE1;
            case "docx":
            case "xlsx":  // ZIP (Office Open XML)
                return b.Length >= 4 && b[0] == 0x50 && b[1] == 0x4B && b[2] == 0x03 && b[3] == 0x04;
            default:
                return false;
        }
    }
}
