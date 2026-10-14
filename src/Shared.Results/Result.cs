// ============================================================
// Archivo  : Result.cs
// Ruta     : Shared.Results/
// Módulo   : ControlAccesos
// Hito     : 1 — Catálogos del módulo
// Fase     : 2 — Base compartida
// Entidad  : Compartido — respuesta estándar
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Contrato de respuesta de todas las capas (misma API que Shared.Results de Trianon):
//   Result / Result<T>      → servicios y controladores (Success, Message, Code, Errors, Data)
//   ResultSp / ResultSp<T>  → repositorios: espejo del contrato del SP (Ok, Codigo, Mensaje, Data)
// ============================================================

namespace Shared.Results;

public static class ResultCodes
{
    public const string Validation = "VALIDATION";
    public const string NotFound   = "NOT_FOUND";
    public const string Fail       = "FAIL";
}

public sealed record ResultError(string Field, string Message);

public class Result
{
    public bool Success { get; protected init; }
    public string Message { get; protected init; } = string.Empty;
    public string? Code { get; protected init; }
    public IReadOnlyList<ResultError> Errors { get; protected init; } = Array.Empty<ResultError>();

    protected Result() { }

    public static Result Ok(string message = "")
        => new() { Success = true, Message = message };

    public static Result Fail(string message, string? code = null, IEnumerable<ResultError>? errors = null)
        => new() { Success = false, Message = message, Code = code ?? ResultCodes.Fail, Errors = errors?.ToList() ?? new List<ResultError>() };

    public static Result Validation(string message, IEnumerable<ResultError> errors)
        => Fail(message, ResultCodes.Validation, errors);
}

public sealed class Result<T> : Result
{
    public T? Data { get; private init; }

    private Result() { }

    public static Result<T> Ok(T data, string message = "")
        => new() { Success = true, Data = data, Message = message };

    public static new Result<T> Fail(string message, string? code = null, IEnumerable<ResultError>? errors = null)
        => new() { Success = false, Message = message, Code = code ?? ResultCodes.Fail, Errors = errors?.ToList() ?? new List<ResultError>() };

    public static new Result<T> Validation(string message, IEnumerable<ResultError> errors)
        => Fail(message, ResultCodes.Validation, errors);
}
