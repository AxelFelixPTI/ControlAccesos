// ============================================================
// Archivo  : IConexionFactory.cs
// Ruta     : Infrastructure.Persistence/
// Módulo   : ControlAccesos
// Hito     : 1 — Catálogos del módulo
// Fase     : 4 — Repository (base compartida)
// Entidad  : Compartido — acceso a datos
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Abre conexiones por CLAVE (una por schema), igual que Hana:Connections:{key} en Trianon.
// Es la ÚNICA pieza que conoce el motor: cambiar a HANA es otra implementación de esta interfaz.
// ============================================================

using System.Data.Common;

namespace Infrastructure.Persistence;

public interface IConexionFactory
{
    /// <summary>Crea (sin abrir) una conexión para la clave indicada.</summary>
    DbConnection Crear(string clave);
}

/// <summary>Claves de conexión del proyecto. Cada una apunta a un schema (SearchPath en la cadena).</summary>
public static class ConexionesCaf
{
    /// <summary>Schema transversal: identidad, personal, sedes, licencias.</summary>
    public const string Gobierno = "CAF_GOVERNANCE";

    /// <summary>Schema del módulo: catálogos propios y tablas CAF_*.</summary>
    public const string Modulo = "TRIANONSATELITAL_CAF_PRODD";
}
