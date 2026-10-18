// ============================================================
// Archivo  : Repo_Reporte.cs
// Ruta     : Infrastructure.Repositories/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 4 — Repository
// Entidad  : Reporte
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_REPORTE_<ACCION>
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).

using System.Data.Common;
using System.Linq;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Reporte : RepoHelpers, IRepo_Reporte
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Reporte(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Reporte_Acceso>>> AccesosAsync(long usuarioId, Dto_Filtro_Reporte_Accesos f, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_REPORTE_ACCESOS",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);
                    AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);
                    AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);
                    AddStr(p, "HV_Tipo", f.Tipo);
                    AddStr(p, "HV_Resultado", f.Resultado);
                    AddStr(p, "HV_Texto", f.Texto);
                },
                map: MapReporte_Acceso,
                ct: ct);
            return Result<List<Dto_Reporte_Acceso>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Reporte_Acceso>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Reporte_Resumen_Dia>>> ResumenDiarioAsync(long usuarioId, Dto_Filtro_Reporte_Rango f, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_REPORTE_RESUMEN_DIARIO",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);
                    AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);
                    AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);
                },
                map: MapReporte_Resumen_Dia,
                ct: ct);
            return Result<List<Dto_Reporte_Resumen_Dia>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Reporte_Resumen_Dia>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Reporte_Autorizado>>> AutorizadosPorZonaAsync(long usuarioId, Dto_Filtro_Reporte_Zona f, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);
                    AddLong(p, "HV_ID_Catalogo_Zona_Acceso", f.ID_Catalogo_Zona_Acceso);
                    AddDate(p, "HV_Fecha", f.Fecha);
                },
                map: MapReporte_Autorizado,
                ct: ct);
            return Result<List<Dto_Reporte_Autorizado>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Reporte_Autorizado>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

    private static Dto_Reporte_Acceso MapReporte_Acceso(DbDataReader rd) => new()
    {
        ID_Registro_Acceso = RdLong(rd, "ID_Registro_Acceso"),
        Fecha_Hora         = RdDt(rd, "Fecha_Hora"),
        Tipo_Movimiento    = RdStr(rd, "Tipo_Movimiento"),
        Resultado          = RdStr(rd, "Resultado"),
        Es_Registro_Tardio = RdBool(rd, "Es_Registro_Tardio"),
        Codigo_Solicitud   = RdStr(rd, "Codigo_Solicitud"),
        Tipo_Documento     = RdStrN(rd, "Tipo_Documento"),
        Numero_Documento   = RdStrN(rd, "Numero_Documento"),
        Persona_Nombre     = RdStr(rd, "Persona_Nombre"),
        Empresa_Visitante  = RdStrN(rd, "Empresa_Visitante"),
        Zonas              = RdStrN(rd, "Zonas"),
        Vigilante_Nombre   = RdStrN(rd, "Vigilante_Nombre"),
        Items_Incumplidos  = RdLong(rd, "Items_Incumplidos"),
        Codigo_Desviacion  = RdStrN(rd, "Codigo_Desviacion"),
        Estado_Desviacion  = RdStrN(rd, "Estado_Desviacion"),
        Observacion        = RdStrN(rd, "Observacion"),
    };

    private static Dto_Reporte_Resumen_Dia MapReporte_Resumen_Dia(DbDataReader rd) => new()
    {
        Fecha                 = RdDt(rd, "Fecha"),
        Ingresos              = RdLong(rd, "Ingresos"),
        Ingresos_Restringidos = RdLong(rd, "Ingresos_Restringidos"),
        Ingresos_Denegados    = RdLong(rd, "Ingresos_Denegados"),
        Salidas               = RdLong(rd, "Salidas"),
        Desviaciones          = RdLong(rd, "Desviaciones"),
        Incidencias           = RdLong(rd, "Incidencias"),
    };

    private static Dto_Reporte_Autorizado MapReporte_Autorizado(DbDataReader rd) => new()
    {
        ID_Solicitud_Persona = RdLong(rd, "ID_Solicitud_Persona"),
        Codigo_Solicitud     = RdStr(rd, "Codigo_Solicitud"),
        Fecha_Hora_Prevista  = RdDt(rd, "Fecha_Hora_Prevista"),
        Tipo_Documento       = RdStrN(rd, "Tipo_Documento"),
        Numero_Documento     = RdStrN(rd, "Numero_Documento"),
        Persona_Nombre       = RdStr(rd, "Persona_Nombre"),
        Empresa_Visitante    = RdStrN(rd, "Empresa_Visitante"),
        Estado_Persona       = RdStr(rd, "Estado_Persona"),
        Acceso_Restringido   = RdBool(rd, "Acceso_Restringido"),
        Fecha_Hora_Ingreso   = RdDtN(rd, "Fecha_Hora_Ingreso"),
        Fecha_Hora_Salida    = RdDtN(rd, "Fecha_Hora_Salida"),
    };
}
