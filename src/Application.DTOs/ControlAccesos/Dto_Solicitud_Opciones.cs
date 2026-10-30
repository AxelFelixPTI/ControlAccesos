// ============================================================
// Archivo  : Dto_Solicitud_Opciones.cs
// Ruta     : Application.DTOs/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación (Entrega H: tipo de ingreso)
// Fase     : 2 — DTOs
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Respuesta de ERP_CAF_SOLICITUD_TIPOS_OPCIONES y ERP_CAF_SOLICITUD_SEDES_OPCIONES: lo que ofrece el asistente de «Nueva solicitud».

namespace Application.DTOs.ControlAccesos;

/// <summary>Un tipo de ingreso del selector. Usable = false: se muestra deshabilitado con su leyenda (Proveedor).</summary>
public sealed class Dto_Solicitud_Tipo_Opcion
{
    public long ID_Catalogo_Tipo_Acceso { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public bool Usable { get; set; }
    public string? Leyenda { get; set; }
}

/// <summary>Sede donde el usuario puede crear solicitudes; Aplica_Cochera indica si se pregunta por el estacionamiento.</summary>
public sealed class Dto_Solicitud_Sede_Opcion
{
    public long ID_Catalogo_Sede { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public bool Aplica_Cochera { get; set; }
}
