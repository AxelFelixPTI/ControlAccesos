// ============================================================
// Archivo  : Repo_Correo.cs
// Ruta     : Infrastructure.Repositories/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 4 — Repository
// Entidad  : Correo
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_CORREO_<ACCION> (la cola se escribe con ERP_CAF_CORREO_ENCOLAR desde los SP de negocio)
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).

using System.Data.Common;
using System.Linq;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Correo : RepoHelpers, IRepo_Correo
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Correo(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Correo_Pendiente>>> PendientesListarAsync(long usuarioId, int? maximo = null, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_CORREO_PENDIENTES_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddInt(p, "HV_Maximo", maximo);
                },
                map: MapCorreo_Pendiente,
                ct: ct);
            return Result<List<Dto_Correo_Pendiente>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Correo_Pendiente>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Correo_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Correos f, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_CORREO_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);
                    AddStr(p, "HV_Estado", f.Estado);
                    AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);
                    AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);
                },
                map: MapCorreo_Lista,
                ct: ct);
            return Result<List<Dto_Correo_Lista>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Correo_Lista>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<ResultSp> MarcarEnviadoAsync(long correoId, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_CORREO_MARCAR_ENVIADO",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Correo_Pendiente", correoId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    public async Task<ResultSp<string>> MarcarErrorAsync(long correoId, string? error, int maxIntentos, long usuarioId, CancellationToken ct = default)
    {
        var r = await _exec.EjecutarEscrituraConSalidasAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_CORREO_MARCAR_ERROR",
            columnasSalida: new[] { "HV_Estado_Result" },
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Correo_Pendiente", correoId);
                AddStr(p, "HV_Error", error);
                AddInt(p, "HV_Max_Intentos", maxIntentos);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
        if (!r.Ok || r.Data is null) return ResultSp<string>.Fail(r.Codigo, r.Mensaje);
        return ResultSp<string>.Success(Convert.ToString(r.Data["HV_Estado_Result"]) ?? string.Empty, r.Mensaje);
    }

    public async Task<ResultSp> ReencolarAsync(long correoId, long sedeId, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_CORREO_REENCOLAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Correo_Pendiente", correoId);
                AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

    private static Dto_Correo_Pendiente MapCorreo_Pendiente(DbDataReader rd) => new()
    {
        ID_Correo_Pendiente = RdLong(rd, "ID_Correo_Pendiente"),
        Tipo                = RdStr(rd, "Tipo"),
        ID_Solicitud        = RdLongN(rd, "ID_Solicitud"),
        Destinatarios       = RdStr(rd, "Destinatarios"),
        Copia               = RdStrN(rd, "Copia"),
        Asunto              = RdStr(rd, "Asunto"),
        Cuerpo              = RdStr(rd, "Cuerpo"),
        Intentos            = RdLong(rd, "Intentos"),
    };

    private static Dto_Correo_Lista MapCorreo_Lista(DbDataReader rd) => new()
    {
        ID_Correo_Pendiente = RdLong(rd, "ID_Correo_Pendiente"),
        Tipo                = RdStr(rd, "Tipo"),
        ID_Solicitud        = RdLongN(rd, "ID_Solicitud"),
        Codigo_Solicitud    = RdStr(rd, "Codigo_Solicitud"),
        Destinatarios       = RdStr(rd, "Destinatarios"),
        Asunto              = RdStr(rd, "Asunto"),
        Estado              = RdStr(rd, "Estado"),
        Intentos            = RdLong(rd, "Intentos"),
        Ultimo_Error        = RdStrN(rd, "Ultimo_Error"),
        CreateDate          = RdDt(rd, "CreateDate"),
        Fecha_Envio         = RdDtN(rd, "Fecha_Envio"),
    };
}
