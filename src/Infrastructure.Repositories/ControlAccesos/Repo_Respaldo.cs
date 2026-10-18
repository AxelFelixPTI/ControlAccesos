// ============================================================
// Archivo  : Repo_Respaldo.cs
// Ruta     : Infrastructure.Repositories/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 4 — Repository
// Entidad  : Respaldo
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_RESPALDO_<ACCION>
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).

using System.Data.Common;
using System.Linq;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Respaldo : RepoHelpers, IRepo_Respaldo
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Respaldo(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Respaldo>>> ListarPorPersonaAsync(long usuarioId, long solicitudPersonaId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_RESPALDO_LISTAR_POR_PERSONA",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Solicitud_Persona", solicitudPersonaId);
                },
                map: MapRespaldo,
                ct: ct);
            return Result<List<Dto_Respaldo>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Respaldo>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<ResultSp<long>> RegistrarAsync(Dto_Respaldo_Registrar dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraConIdAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_RESPALDO_REGISTRAR",
            columnaId: "HV_ID_Respaldo_Result",
            bind: p =>
            {
                AddStrReq(p, "HV_Categoria", dto.Categoria);
                AddStrReq(p, "HV_Tipo_Respaldo", dto.Tipo_Respaldo);
                AddStr(p, "HV_Numero_Documento", dto.Numero_Documento);
                AddStr(p, "HV_IDs_Solicitud_Persona", dto.IDs_Solicitud_Persona is null ? string.Empty : string.Join(",", dto.IDs_Solicitud_Persona));
                AddStr(p, "HV_Observacion", dto.Observacion);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

    private static Dto_Respaldo MapRespaldo(DbDataReader rd) => new()
    {
        ID_Respaldo       = RdLong(rd, "ID_Respaldo"),
        Categoria         = RdStr(rd, "Categoria"),
        Tipo_Respaldo     = RdStr(rd, "Tipo_Respaldo"),
        Numero_Documento  = RdStrN(rd, "Numero_Documento"),
        Fecha_Hora        = RdDt(rd, "Fecha_Hora"),
        Vigilante_Nombre  = RdStrN(rd, "Vigilante_Nombre"),
        Observacion       = RdStrN(rd, "Observacion"),
        Cantidad_Personas = RdLong(rd, "Cantidad_Personas"),
    };
}
