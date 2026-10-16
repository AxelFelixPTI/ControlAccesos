// ============================================================
// Archivo  : ConexionPostgres.cs
// Ruta     : Infrastructure.Persistence/
// Módulo   : ControlAccesos
// Hito     : 1 — Catálogos del módulo
// Fase     : 4 — Repository (base compartida)
// Entidad  : Compartido — acceso a datos
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Implementación PostgreSQL de IConexionFactory (paquete NuGet Npgsql).
// Cadena de conexión por clave; cada una DEBE fijar el schema con "Search Path":
//   Host=localhost;Port=5432;Database=accesos_piloto;Username=...;Password=...;Search Path=CAF_GOVERNANCE
// Las rutinas llevan su propio search_path (D-28); el de la conexión solo resuelve el NOMBRE de la rutina.
// ============================================================

using System.Data.Common;
using Npgsql;

namespace Infrastructure.Persistence;

public sealed class ConexionPostgres : IConexionFactory
{
    private readonly IReadOnlyDictionary<string, string> _cadenas;

    public ConexionPostgres(IReadOnlyDictionary<string, string> cadenas) => _cadenas = cadenas;

    public DbConnection Crear(string clave)
    {
        if (!_cadenas.TryGetValue(clave, out var cadena) || string.IsNullOrWhiteSpace(cadena))
            throw new InvalidOperationException($"No hay cadena de conexión configurada para la clave '{clave}'.");
        return new NpgsqlConnection(cadena);
    }
}
