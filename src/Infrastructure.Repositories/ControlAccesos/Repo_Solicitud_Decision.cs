// ============================================================
// Archivo  : Repo_Solicitud_Decision.cs
// Ruta     : Infrastructure.Repositories/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 4 — Repository
// Entidad  : Solicitud_Decision
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_SOLICITUD_DECIDIR
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Solicitud_Decision : RepoHelpers, IRepo_Solicitud_Decision
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Solicitud_Decision(EjecutorSp exec) => _exec = exec;

    public async Task<ResultSp<long>> DecidirAsync(Dto_Solicitud_Decidir dto, long usuarioId, CancellationToken ct = default)
    {
        var r = await _exec.EjecutarEscrituraConSalidasAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_SOLICITUD_DECIDIR",
            columnasSalida: new[] { "HV_Cantidad_Result" },
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", dto.ID_Solicitud);
                AddLongReq(p, "HV_ID_Tipo_Acceso_Paso_Aprobacion", dto.ID_Tipo_Acceso_Paso_Aprobacion);
                AddStr(p, "HV_Decision", dto.Decision);
                AddStr(p, "HV_Mensaje_Decision", dto.Mensaje);
                AddStr(p, "HV_IDs_Solicitud_Persona", dto.IDs_Solicitud_Persona is null ? string.Empty : string.Join(",", dto.IDs_Solicitud_Persona));
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
        if (!r.Ok || r.Data is null) return ResultSp<long>.Fail(r.Codigo, r.Mensaje);
        return ResultSp<long>.Success(Convert.ToInt64(r.Data["HV_Cantidad_Result"] ?? 0L), r.Mensaje);
    }

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

}
