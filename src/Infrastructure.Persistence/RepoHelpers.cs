// ============================================================
// Archivo  : RepoHelpers.cs
// Ruta     : Infrastructure.Persistence/
// Módulo   : ControlAccesos
// Hito     : 1 — Catálogos del módulo
// Fase     : 4 — Repository (base compartida)
// Entidad  : Compartido — acceso a datos
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Clase base de TODOS los repositorios. Convención de Trianon: Bind = Add*, Read = Rd*.
//   Sin "Req" = acepta null (→ NULL en la rutina) · Con "Req" = obligatorio (null es un bug del llamador).
// Uso:  public sealed class Repo_X : RepoHelpers, IRepo_X
// ============================================================

using System.Data;
using System.Data.Common;

namespace Infrastructure.Persistence;

public abstract class RepoHelpers
{
    // ── BIND: parámetros de entrada ──────────────────────────────
    protected static void AddStr(ParametrosSp p, string name, string? value)
        => p.Agregar(name, DbType.String, value);

    protected static void AddStrReq(ParametrosSp p, string name, string value)
        => p.Agregar(name, DbType.String, value ?? throw new ArgumentNullException(name, $"El parámetro {name} es requerido."));

    /// <summary>CHAR(1) (banderas Y/N): se envía como texto de un carácter.</summary>
    protected static void AddChar1(ParametrosSp p, string name, string? value)
        => p.Agregar(name, DbType.String, string.IsNullOrWhiteSpace(value) ? null : value.Trim());

    protected static void AddLong(ParametrosSp p, string name, long? value)
        => p.Agregar(name, DbType.Int64, value);

    protected static void AddLongReq(ParametrosSp p, string name, long value)
        => p.Agregar(name, DbType.Int64, value);

    protected static void AddInt(ParametrosSp p, string name, int? value)
        => p.Agregar(name, DbType.Int32, value);

    protected static void AddTimestamp(ParametrosSp p, string name, DateTime? value)
        => p.Agregar(name, DbType.DateTime, value);

    // ── READ: columnas del lector, por NOMBRE (nunca por posición) ───
    protected static string RdStr(DbDataReader rd, string col)
        => RdStrN(rd, col) ?? string.Empty;

    protected static string? RdStrN(DbDataReader rd, string col)
    {
        var i = rd.GetOrdinal(col);
        return rd.IsDBNull(i) ? null : rd.GetString(i);
    }

    protected static long RdLong(DbDataReader rd, string col)
        => RdLongN(rd, col) ?? 0L;

    protected static long? RdLongN(DbDataReader rd, string col)
    {
        var i = rd.GetOrdinal(col);
        return rd.IsDBNull(i) ? null : Convert.ToInt64(rd.GetValue(i));
    }

    protected static int RdInt(DbDataReader rd, string col)
        => RdIntN(rd, col) ?? 0;

    protected static int? RdIntN(DbDataReader rd, string col)
    {
        var i = rd.GetOrdinal(col);
        return rd.IsDBNull(i) ? null : Convert.ToInt32(rd.GetValue(i));
    }

    protected static DateTime RdDt(DbDataReader rd, string col)
        => RdDtN(rd, col) ?? DateTime.MinValue;

    protected static DateTime? RdDtN(DbDataReader rd, string col)
    {
        var i = rd.GetOrdinal(col);
        return rd.IsDBNull(i) ? null : rd.GetDateTime(i);
    }

    /// <summary>Bandera CHAR(1): true si vale 'Y'.</summary>
    protected static bool RdBool(DbDataReader rd, string col)
        => string.Equals(RdStrN(rd, col)?.Trim(), "Y", StringComparison.OrdinalIgnoreCase);
}
