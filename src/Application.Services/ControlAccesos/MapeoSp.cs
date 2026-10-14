// ============================================================
// Archivo  : MapeoSp.cs
// Ruta     : Application.Services/ControlAccesos/
// Módulo   : ControlAccesos
// Hito     : 0 y 1 — Catálogos
// Fase     : 5 — Service
// Entidad  : Compartido — traducción del contrato del SP
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Traduce HV_Codigo_Resp a los códigos de Result para que el controlador elija el HTTP adecuado.
// ============================================================

using Shared.Results;

namespace Application.Services.ControlAccesos;

public static class MapeoSp
{
    public static string Codigo(int codigoSp) => codigoSp switch
    {
        400 => ResultCodes.Validation,
        404 => ResultCodes.NotFound,
        _ => ResultCodes.Fail,
    };
}
