// ============================================================
// Archivo  : Dto_Catalogo_Universal.cs
// Ruta     : Application.DTOs/ControlAccesos/
// Módulo   : ControlAccesos
// Hito     : 0 y 1 — Catálogos
// Fase     : 2 — DTOs
// Entidad  : Compartido — TODAS las tablas Catalogo_*
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Cubre LISTAR, CREAR, DETALLE, ACTUALIZAR y DROPDOWN de cualquier tabla Catalogo_*.
// Una sola clase para todos los catálogos: nunca se crean DTOs por tabla.
// Propiedades = nombres EXACTOS de las columnas que devuelven los procedimientos.
// La PK real de cada tabla sale como alias "ID_Catalogo" en el SP.
// Generado por gen_capas_catalogos.py desde las firmas reales: no editar a mano.
// ============================================================

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Catalogo_Universal
{
    // ── PK genérica (alias "ID_Catalogo" del SP) ─────────────────
    // CREAR: siempre 0 (el SP genera el ID). EDITAR: viene de la ruta.
    public long ID_Catalogo { get; set; }

    // ── Datos principales ─────────────────────────────────────────
    [Required(ErrorMessage = "El Código es obligatorio.")]
    [StringLength(50, ErrorMessage = "El Código no puede superar 50 caracteres.")]
    public string Codigo { get; set; } = string.Empty;

    [Required(ErrorMessage = "La Descripción es obligatoria.")]
    [StringLength(500, ErrorMessage = "La Descripción no puede superar 500 caracteres.")]
    public string Descripcion { get; set; } = string.Empty;

    public string? Tipo_Entidad { get; set; }

    public long Orden { get; set; }

    /// <summary>'Y' / 'N'. Nulo en CREAR = el servicio envía 'Y'.</summary>
    public string? Activo { get; set; }

    // ── Auditoría — la gestiona el SP, nunca el formulario ───────
    public string? Eliminado { get; set; }
    public long? UsuarioID_Create { get; set; }
    public string? Nombre_Usuario { get; set; }
    public long? UsuarioID_Update { get; set; }
    public DateTime? CreateDate { get; set; }
    public DateTime? UpdateDate { get; set; }

    // ── Catalogo_Sede (V1.0 2026-10-13) ──────────────────────────
    public string? Direccion { get; set; }

    // ── Catalogo_Tipo_Documento (V1.0 2026-10-13) ──────────────────────────
    public long? Longitud_Min { get; set; }
    public long? Longitud_Max { get; set; }
    public string? Solo_Numeros { get; set; }

    // ── Catalogo_Empresa_Grupo (V1.0 2026-10-13) ──────────────────────────
    public string? RUC { get; set; }

    // ── Catalogo_Tipo_Acceso (V1.0 2026-10-13) ──────────────────────────
    public string? Requiere_Aprobacion { get; set; }
    public string? Disponible { get; set; }

    // ── Catalogo_Zona_Acceso (V1.0 2026-10-13) ──────────────────────────
    public long? ID_Catalogo_Sede { get; set; }
    public string? Codigo_Sede { get; set; }
    public string? Sede { get; set; }
    public string? Tipo_Zona { get; set; }
    public string? Exige_SCTR { get; set; }
    public string? Exige_EPP { get; set; }

    // ── Catalogo_Motivo_Visita (V1.0 2026-10-13) ──────────────────────────
    public string? Es_Otro { get; set; }

    // ── Catalogo_Tratamiento_Desviacion (V1.0 2026-10-13) ──────────────────────────
    public string? Aplica_Ingreso { get; set; }
    public string? Aplica_Salida { get; set; }
    public string? Resultado_Ingreso { get; set; }
    public string? Resultado_Salida { get; set; }

    // ── Catalogo_Item_Checklist (V1.0 2026-10-13) ──────────────────────────
    public string? Ayuda { get; set; }
    public string? Etapa { get; set; }
    public string? Condicion { get; set; }
    public string? Es_Critico { get; set; }
}
