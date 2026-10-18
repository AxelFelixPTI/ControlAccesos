// ============================================================
// Archivo  : Dto_Porteria_Movimiento.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 2 — DTOs
// Entidad  : Porteria_Movimiento
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR: fila de la bitácora de ingresos y salidas.
// Propiedades = nombres EXACTOS de las columnas. Las banderas Y/N salen como bool.
// Generado por gen_capas_porteria.py desde las firmas reales: no editar a mano.

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Porteria_Movimiento
{
    public long ID_Registro_Acceso { get; set; }
    public long ID_Solicitud_Persona { get; set; }
    public long ID_Solicitud { get; set; }
    public string Codigo_Solicitud { get; set; } = string.Empty;
    public DateTime Fecha_Hora { get; set; }
    public string Tipo_Movimiento { get; set; } = string.Empty;
    public string? Resultado { get; set; }
    public bool Es_Registro_Tardio { get; set; }
    public string? Tipo_Documento { get; set; }
    public string? Numero_Documento { get; set; }
    public string Persona_Nombre { get; set; } = string.Empty;
    public string? Empresa_Visitante { get; set; }
    public string? Vigilante_Nombre { get; set; }
    public string? Observacion { get; set; }
    public bool Tiene_Desviacion { get; set; }
    public string? Codigo_Desviacion { get; set; }
}
