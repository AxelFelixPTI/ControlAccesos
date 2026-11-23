// ============================================================
// D-265. Validación EN EL SERVIDOR de un documento de ingreso (el que sube Vigilancia): PDF, JPG o PNG, tamaño y firma real del archivo.
// El tamaño máximo es un parámetro (DOCUMENTO_INGRESO_MAX_MB, de 1 a 30); el procedimiento lo vuelve a validar con el valor vigente:
// aquí solo se corta el tope absoluto y se comprueba que el contenido coincida con la extensión. Lógica pura, sin dependencias.
// ============================================================

namespace Application.Contracts.ControlAccesos;

public static class ValidadorDocumentosIngreso
{
    public const int MaxMbAbsoluto = 30;
    public const string Permitidos = "PDF, JPG y PNG";
    public static readonly string[] Tipos = { "EQUIPOS", "HERRAMIENTAS", "GUIA", "OTRO" };

    private static readonly HashSet<string> Extensiones = new(StringComparer.OrdinalIgnoreCase) { "pdf", "jpg", "jpeg", "png" };

    /// <summary>null si el archivo es válido; si no, el mensaje para el usuario.</summary>
    public static string? Validar(string? nombreOriginal, byte[]? contenido, out string nombre, out string extension)
    {
        nombre = ValidadorAdjuntos.LimpiarNombre(nombreOriginal);
        extension = ValidadorAdjuntos.Extension(nombre) ?? string.Empty;
        if (nombre.Length == 0 || nombre.Length > 200) return "El nombre del archivo debe tener entre 1 y 200 caracteres.";
        if (!Extensiones.Contains(extension)) return $"«{nombre}»: solo se permiten archivos {Permitidos}.";
        if (contenido is null || contenido.Length == 0) return $"«{nombre}» está vacío.";
        if (contenido.Length > MaxMbAbsoluto * 1024 * 1024) return $"«{nombre}» supera el máximo de {MaxMbAbsoluto} MB.";
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
            case "jpg":
            case "jpeg":  // FF D8 FF
                return b.Length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;
            case "png":   // 89 50 4E 47 0D 0A 1A 0A
                return b.Length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47 && b[4] == 0x0D && b[5] == 0x0A && b[6] == 0x1A && b[7] == 0x0A;
            default:
                return false;
        }
    }
}
