// ============================================================
// Entrega J (D-183): documentos adjuntos de la solicitud.
// Dto_Solicitud_Adjunto            lista (sin contenido) · ERP_CAF_SOLICITUD_ADJUNTO_LISTAR
// Dto_Solicitud_Adjunto_Contenido  un documento con su contenido · ERP_CAF_SOLICITUD_ADJUNTO_OBTENER
// Dto_Correo_Adjunto               documentos para el correo (solo el proceso de envío) · ERP_CAF_SOLICITUD_ADJUNTO_CORREO
// Propiedades = nombres EXACTOS de las columnas.
// ============================================================

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Solicitud_Adjunto
{
    public long ID_Solicitud_Adjunto { get; set; }
    public long ID_Solicitud { get; set; }
    public string Nombre_Archivo { get; set; } = string.Empty;
    public string Extension { get; set; } = string.Empty;
    public long Tamano_Bytes { get; set; }
    public DateTime Fecha { get; set; }
    public bool Puede_Quitar { get; set; }
}

public sealed class Dto_Solicitud_Adjunto_Contenido
{
    public long ID_Solicitud_Adjunto { get; set; }
    public long ID_Solicitud { get; set; }
    public string Nombre_Archivo { get; set; } = string.Empty;
    public string Extension { get; set; } = string.Empty;
    public long Tamano_Bytes { get; set; }
    public byte[] Contenido { get; set; } = Array.Empty<byte>();
}

public sealed class Dto_Correo_Adjunto
{
    public long ID_Solicitud_Adjunto { get; set; }
    public string Nombre_Archivo { get; set; } = string.Empty;
    public string Extension { get; set; } = string.Empty;
    public byte[] Contenido { get; set; } = Array.Empty<byte>();
}
