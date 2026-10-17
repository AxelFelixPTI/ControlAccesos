// ============================================================
// Archivo  : EjecutorSp.cs
// Ruta     : Infrastructure.Persistence/
// Módulo   : ControlAccesos
// Hito     : 1 — Catálogos del módulo
// Fase     : 4 — Repository (base compartida)
// Entidad  : Compartido — acceso a datos
// Versión  : V1.1 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// ÚNICO lugar donde se arma una llamada a la base. Ninguna otra capa escribe SQL.
//   Lectura  → SELECT * FROM "RUTINA"(@p...)   (funciones RETURNS TABLE, sin contrato de error)
//   Escritura→ CALL "RUTINA"(@p...)            (procedimientos con HV_Codigo_Resp / HV_Mensaje)
// En escrituras se pasan SOLO los parámetros de entrada, por posición: los INOUT toman su DEFAULT NULL
// y PostgreSQL devuelve una fila con HV_Codigo_Resp, HV_Mensaje y (si existe) HV_<..>_Result.
// ============================================================

using System.Data;
using System.Data.Common;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Infrastructure.Persistence;

public sealed class EjecutorSp
{
    private const string MensajeGenerico = "No se pudo completar la operación en la base de datos.";

    private readonly IConexionFactory _fabrica;
    private readonly ILogger<EjecutorSp> _log;

    public EjecutorSp(IConexionFactory fabrica, ILogger<EjecutorSp> log)
    {
        _fabrica = fabrica;
        _log = log;
    }

    // ── LECTURA ──────────────────────────────────────────────────
    public async Task<List<T>> EjecutarLecturaAsync<T>(
        string clave, string funcion, Action<ParametrosSp> bind, Func<DbDataReader, T> map,
        CancellationToken ct = default)
    {
        var p = new ParametrosSp();
        bind(p);
        await using var cn = _fabrica.Crear(clave);
        await cn.OpenAsync(ct).ConfigureAwait(false);
        await using var cmd = Armar(cn, $"SELECT * FROM {Ident(funcion)}({Marcadores(p)})", p);
        await using var rd = await cmd.ExecuteReaderAsync(ct).ConfigureAwait(false);
        var lista = new List<T>();
        while (await rd.ReadAsync(ct).ConfigureAwait(false))
            lista.Add(map(rd));
        return lista;
    }

    /// <summary>Primera fila o null si la función no devuelve nada.</summary>
    public async Task<T?> EjecutarLecturaUnicaAsync<T>(
        string clave, string funcion, Action<ParametrosSp> bind, Func<DbDataReader, T> map,
        CancellationToken ct = default) where T : class
    {
        var lista = await EjecutarLecturaAsync(clave, funcion, bind, map, ct).ConfigureAwait(false);
        return lista.Count > 0 ? lista[0] : null;
    }

    // ── ESCRITURA ────────────────────────────────────────────────
    public async Task<ResultSp> EjecutarEscrituraAsync(
        string clave, string procedimiento, Action<ParametrosSp> bind, CancellationToken ct = default)
    {
        try
        {
            var r = await LlamarAsync(clave, procedimiento, bind, columnasSalida: null, ct).ConfigureAwait(false);
            return r.Codigo == 100 ? ResultSp.Success(r.Mensaje) : ResultSp.Fail(r.Codigo, r.Mensaje);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "ESCRITURA {Procedimiento} ERROR", procedimiento);
            return ResultSp.Fail(500, MensajeGenerico);
        }
    }

    /// <param name="columnaId">Nombre del INOUT con el ID nuevo, p. ej. HV_ID_Catalogo_Sede_Result.</param>
    public async Task<ResultSp<long>> EjecutarEscrituraConIdAsync(
        string clave, string procedimiento, string columnaId, Action<ParametrosSp> bind,
        CancellationToken ct = default)
    {
        try
        {
            var r = await LlamarAsync(clave, procedimiento, bind, new[] { columnaId }, ct).ConfigureAwait(false);
            var id = r.Salidas.TryGetValue(columnaId, out var v) && v is not null ? Convert.ToInt64(v) : 0L;
            return r.Codigo == 100
                ? ResultSp<long>.Success(id, r.Mensaje)
                : ResultSp<long>.Fail(r.Codigo, r.Mensaje);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "ESCRITURA {Procedimiento} ERROR", procedimiento);
            return ResultSp<long>.Fail(500, MensajeGenerico);
        }
    }

    /// <summary>
    /// Escritura que devuelve varios valores de salida (INOUT *_Result) además del contrato 100/101/...:
    /// p. ej. CREAR de solicitud devuelve el ID y el código visible. V1.1 (Hito 2).
    /// </summary>
    public async Task<ResultSp<IReadOnlyDictionary<string, object?>>> EjecutarEscrituraConSalidasAsync(
        string clave, string procedimiento, string[] columnasSalida, Action<ParametrosSp> bind,
        CancellationToken ct = default)
    {
        try
        {
            var r = await LlamarAsync(clave, procedimiento, bind, columnasSalida, ct).ConfigureAwait(false);
            return r.Codigo == 100
                ? ResultSp<IReadOnlyDictionary<string, object?>>.Success(r.Salidas, r.Mensaje)
                : ResultSp<IReadOnlyDictionary<string, object?>>.Fail(r.Codigo, r.Mensaje);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "ESCRITURA {Procedimiento} ERROR", procedimiento);
            return ResultSp<IReadOnlyDictionary<string, object?>>.Fail(500, MensajeGenerico);
        }
    }

    private async Task<(int Codigo, string Mensaje, IReadOnlyDictionary<string, object?> Salidas)> LlamarAsync(
        string clave, string procedimiento, Action<ParametrosSp> bind, string[]? columnasSalida, CancellationToken ct)
    {
        var p = new ParametrosSp();
        bind(p);
        await using var cn = _fabrica.Crear(clave);
        await cn.OpenAsync(ct).ConfigureAwait(false);
        await using var cmd = Armar(cn, $"CALL {Ident(procedimiento)}({Marcadores(p)})", p);
        await using var rd = await cmd.ExecuteReaderAsync(ct).ConfigureAwait(false);
        if (!await rd.ReadAsync(ct).ConfigureAwait(false))
            throw new InvalidOperationException($"{procedimiento} no devolvió la fila de respuesta.");

        var iCodigo = rd.GetOrdinal("HV_Codigo_Resp");
        var iMensaje = rd.GetOrdinal("HV_Mensaje");
        var codigo = rd.IsDBNull(iCodigo) ? 500 : Convert.ToInt32(rd.GetValue(iCodigo));
        var mensaje = rd.IsDBNull(iMensaje) ? string.Empty : rd.GetString(iMensaje);

        var salidas = new Dictionary<string, object?>();
        if (columnasSalida is not null)
            foreach (var col in columnasSalida)
            {
                var i = rd.GetOrdinal(col);
                salidas[col] = rd.IsDBNull(i) ? null : rd.GetValue(i);
            }
        return (codigo, mensaje, salidas);
    }

    // ── Armado ───────────────────────────────────────────────────
    private static DbCommand Armar(DbConnection cn, string sql, ParametrosSp p)
    {
        var cmd = cn.CreateCommand();
        cmd.CommandText = sql;
        cmd.CommandType = CommandType.Text;
        foreach (var (nombre, tipo, valor) in p.Items)
        {
            var prm = cmd.CreateParameter();
            prm.ParameterName = nombre;
            prm.DbType = tipo;
            prm.Value = valor ?? DBNull.Value;
            cmd.Parameters.Add(prm);
        }
        return cmd;
    }

    private static string Marcadores(ParametrosSp p)
        => string.Join(", ", p.Items.Select(i => "@" + i.Nombre));

    /// <summary>Identificador entre comillas: las rutinas tienen mayúsculas y hay que respetarlas.</summary>
    private static string Ident(string nombre)
        => "\"" + nombre.Replace("\"", "\"\"") + "\"";
}
