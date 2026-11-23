namespace Application.DTOs.ControlAccesos;

/// <summary>D-265: un documento de ingreso del día (sin contenido). Personas = «idPersona~Apellidos, Nombres~Documento~SOL-xxxx~Empresa» separadas por «|».</summary>
public class Dto_Documento_Ingreso
{
    public long ID_Documento_Ingreso { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public string Nombre_Archivo { get; set; } = string.Empty;
    public string Extension { get; set; } = string.Empty;
    public long Tamano_Bytes { get; set; }
    public DateTime Fecha_Subida { get; set; }
    public string? Subido_Por { get; set; }
    public string? Personas { get; set; }
    public bool Puede_Modificar { get; set; }
}

public sealed class Dto_Documento_Ingreso_Contenido
{
    public long ID_Documento_Ingreso { get; set; }
    public string Nombre_Archivo { get; set; } = string.Empty;
    public string Extension { get; set; } = string.Empty;
    public long Tamano_Bytes { get; set; }
    public byte[] Contenido { get; set; } = Array.Empty<byte>();
}

/// <summary>D-265: persona que ingresó ese día (autocompletar). Documentos = cuántos documentos tiene ese día.</summary>
public sealed class Dto_Documento_Ingreso_Persona
{
    public long ID_Solicitud_Persona { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Documento { get; set; } = string.Empty;
    public string Solicitud { get; set; } = string.Empty;
    public string? Empresa { get; set; }
    public bool Trae_Equipos { get; set; }
    public bool Trae_Herramientas { get; set; }
    public int Documentos { get; set; }
}

public sealed class Dto_Documento_Ingreso_Resumen
{
    public int Ingresaron { get; set; }
    public int Con_Equipos { get; set; }
    public int Sin_Documento { get; set; }
    public int Documentos { get; set; }
    public bool Obligatorio { get; set; }
    public int Max_MB { get; set; }
    public bool Puede_Subir { get; set; }
}

/// <summary>D-265: documento vinculado a personas de UNA solicitud (bloque del detalle). Personas = «Apellidos, Nombres» separadas por «|».</summary>
public sealed class Dto_Documento_Ingreso_Solicitud
{
    public long ID_Documento_Ingreso { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public string Nombre_Archivo { get; set; } = string.Empty;
    public string Extension { get; set; } = string.Empty;
    public long Tamano_Bytes { get; set; }
    public DateTime Fecha_Registro { get; set; }
    public string? Subido_Por { get; set; }
    public string? Personas { get; set; }
}

/// <summary>D-269: documento encontrado en la consulta por rango de días (trae además el día al que corresponde).</summary>
public sealed class Dto_Documento_Ingreso_Busqueda : Dto_Documento_Ingreso
{
    public DateTime Fecha_Registro { get; set; }
}
