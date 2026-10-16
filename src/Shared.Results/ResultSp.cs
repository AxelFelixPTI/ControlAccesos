// ============================================================
// Archivo  : ResultSp.cs
// Ruta     : Shared.Results/
// Módulo   : ControlAccesos
// Hito     : 1 — Catálogos del módulo
// Fase     : 2 — Base compartida
// Entidad  : Compartido — respuesta del procedimiento
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Espejo del contrato de los SP de escritura: HV_Codigo_Resp (100 ok, 101 regla/duplicado,
// 400 dato inválido, 404 no existe, 409 conflicto, 500 error interno) y HV_Mensaje.
// ============================================================

namespace Shared.Results;

public class ResultSp
{
    public bool Ok => Codigo == 100;
    public int Codigo { get; protected init; }
    public string Mensaje { get; protected init; } = string.Empty;

    protected ResultSp() { }

    public static ResultSp Success(string mensaje) => new() { Codigo = 100, Mensaje = mensaje };
    public static ResultSp Fail(int codigo, string mensaje) => new() { Codigo = codigo, Mensaje = mensaje };
}

public sealed class ResultSp<T> : ResultSp
{
    public T? Data { get; private init; }

    private ResultSp() { }

    public static ResultSp<T> Success(T data, string mensaje) => new() { Codigo = 100, Data = data, Mensaje = mensaje };
    public static new ResultSp<T> Fail(int codigo, string mensaje) => new() { Codigo = codigo, Mensaje = mensaje };
}
