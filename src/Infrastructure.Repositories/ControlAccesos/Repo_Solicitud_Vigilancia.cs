// ============================================================
// Archivo  : Repo_Solicitud_Vigilancia.cs
// Ruta     : Infrastructure.Repositories/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 4 — Repository
// Entidad  : Solicitud_Vigilancia
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_SOLICITUD_VIGILANCIA_* (lecturas de portería)
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Solicitud_Vigilancia : RepoHelpers, IRepo_Solicitud_Vigilancia
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Solicitud_Vigilancia(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Vigilancia_Persona>>> ListarAsync(long usuarioId, Dto_Filtro_Vigilancia? f = null, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLong(p, "HV_ID_Catalogo_Sede", f?.ID_Catalogo_Sede);
                    AddDate(p, "HV_Fecha", f?.Fecha);
                    AddStr(p, "HV_Texto", f?.Texto);
                    AddStr(p, "HV_Grupo", f?.Grupo);
                },
                map: MapVigilancia_Persona,
                ct: ct);
            return Result<List<Dto_Vigilancia_Persona>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Vigilancia_Persona>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Vigilancia_No_Autorizada>>> NoAutorizadaBuscarAsync(long usuarioId, long sedeId, DateTime fecha, string texto, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                    AddDate(p, "HV_Fecha", fecha);
                    AddStrReq(p, "HV_Texto", texto);
                },
                map: MapVigilancia_No_Autorizada,
                ct: ct);
            return Result<List<Dto_Vigilancia_No_Autorizada>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Vigilancia_No_Autorizada>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

    private static Dto_Vigilancia_Persona MapVigilancia_Persona(DbDataReader rd) => new()
    {
        ID_Solicitud_Persona = RdLong(rd, "ID_Solicitud_Persona"),
        ID_Solicitud         = RdLong(rd, "ID_Solicitud"),
        Codigo               = RdStr(rd, "Codigo"),
        ID_Catalogo_Sede     = RdLong(rd, "ID_Catalogo_Sede"),
        Fecha_Hora_Prevista  = RdDt(rd, "Fecha_Hora_Prevista"),
        Empresa_Visitante    = RdStrN(rd, "Empresa_Visitante"),
        Responsable_Nombre   = RdStrN(rd, "Responsable_Nombre"),
        Tipo_Documento       = RdStrN(rd, "Tipo_Documento"),
        Numero_Documento     = RdStrN(rd, "Numero_Documento"),
        Persona_Nombre       = RdStr(rd, "Persona_Nombre"),
        Estado               = RdStr(rd, "Estado"),
        Grupo                = RdStr(rd, "Grupo"),
        Fecha_Hora_Ingreso   = RdDtN(rd, "Fecha_Hora_Ingreso"),
        Fecha_Hora_Salida    = RdDtN(rd, "Fecha_Hora_Salida"),
        Acceso_Restringido   = RdBool(rd, "Acceso_Restringido"),
        Trae_Equipos         = RdBool(rd, "Trae_Equipos"),
        Trae_Herramientas    = RdBool(rd, "Trae_Herramientas"),
        Exige_SCTR           = RdBool(rd, "Exige_SCTR"),
        Exige_EPP            = RdBool(rd, "Exige_EPP"),
        Zonas_Nombres        = RdStrN(rd, "Zonas_Nombres"),
    };

    private static Dto_Vigilancia_No_Autorizada MapVigilancia_No_Autorizada(DbDataReader rd) => new()
    {
        Codigo            = RdStr(rd, "Codigo"),
        Persona_Nombre    = RdStr(rd, "Persona_Nombre"),
        Numero_Documento  = RdStrN(rd, "Numero_Documento"),
        Empresa_Visitante = RdStrN(rd, "Empresa_Visitante"),
        Motivo_Codigo     = RdStr(rd, "Motivo_Codigo"),
        Motivo_Texto      = RdStrN(rd, "Motivo_Texto"),
    };
}
