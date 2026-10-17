// ============================================================
// Archivo  : Repo_Solicitud_Persona.cs
// Ruta     : Infrastructure.Repositories/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 4 — Repository
// Entidad  : Solicitud_Persona
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_SOLICITUD_PERSONA_<ACCION> (AGREGAR, RETIRAR, CORREGIR)
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Solicitud_Persona : RepoHelpers, IRepo_Solicitud_Persona
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Solicitud_Persona(EjecutorSp exec) => _exec = exec;

    public async Task<ResultSp<long>> AgregarAsync(long solicitudId, long personaExternaId, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraConIdAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_SOLICITUD_PERSONA_AGREGAR",
            columnaId: "HV_ID_Solicitud_Persona_Result",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddLongReq(p, "HV_ID_Persona_Externa", personaExternaId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    public async Task<ResultSp> RetirarAsync(long solicitudPersonaId, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_SOLICITUD_PERSONA_RETIRAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud_Persona", solicitudPersonaId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    public async Task<ResultSp<bool>> CorregirAsync(long solicitudPersonaId, long personaExternaNuevaId, long usuarioId, CancellationToken ct = default)
    {
        var r = await _exec.EjecutarEscrituraConSalidasAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_SOLICITUD_PERSONA_CORREGIR",
            columnasSalida: new[] { "HV_Reenviada_Result" },
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud_Persona", solicitudPersonaId);
                AddLongReq(p, "HV_ID_Persona_Externa_Nueva", personaExternaNuevaId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
        if (!r.Ok || r.Data is null) return ResultSp<bool>.Fail(r.Codigo, r.Mensaje);
        return ResultSp<bool>.Success(string.Equals(Convert.ToString(r.Data["HV_Reenviada_Result"])?.Trim(), "Y", StringComparison.OrdinalIgnoreCase), r.Mensaje);
    }

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

}
