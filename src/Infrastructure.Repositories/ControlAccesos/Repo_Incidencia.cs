// ============================================================
// Archivo  : Repo_Incidencia.cs
// Ruta     : Infrastructure.Repositories/
// Módulo   : ControlAccesos
// Hito     : 4 — Incidencias, correos y reporte
// Fase     : 4 — Repository
// Entidad  : Incidencia
// Versión  : V1.0 — 2026-10-18
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_INCIDENCIA_<ACCION>
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).

using System.Data.Common;
using System.Linq;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Incidencia : RepoHelpers, IRepo_Incidencia
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Incidencia(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Incidencia_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Incidencias f, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_INCIDENCIA_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);
                    AddStr(p, "HV_Estado", f.Estado);
                    AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);
                    AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);
                    AddStr(p, "HV_Texto", f.Texto);
                },
                map: MapIncidencia_Lista,
                ct: ct);
            return Result<List<Dto_Incidencia_Lista>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Incidencia_Lista>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<Dto_Incidencia_Detalle?>> DetalleAsync(long usuarioId, long incidenciaId, CancellationToken ct = default)
    {
        try
        {
            var dato = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CAF_INCIDENCIA_DETALLE",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Incidencia", incidenciaId);
                },
                map: MapIncidencia_Detalle,
                ct: ct);
            return Result<Dto_Incidencia_Detalle?>.Ok(dato);
        }
        catch (Exception ex)
        {
            return Result<Dto_Incidencia_Detalle?>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Incidencia_Persona>>> PersonasListarAsync(long usuarioId, long incidenciaId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_INCIDENCIA_PERSONAS_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Incidencia", incidenciaId);
                },
                map: MapIncidencia_Persona,
                ct: ct);
            return Result<List<Dto_Incidencia_Persona>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Incidencia_Persona>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<Dto_Incidencia_Contadores?>> ContadoresAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try
        {
            var dato = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CAF_INCIDENCIA_CONTADORES",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                },
                map: MapIncidencia_Contadores,
                ct: ct);
            return Result<Dto_Incidencia_Contadores?>.Ok(dato);
        }
        catch (Exception ex)
        {
            return Result<Dto_Incidencia_Contadores?>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Incidencia_Persona_Busqueda>>> PersonasBuscarAsync(long usuarioId, Dto_Filtro_Incidencia_Personas f, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_INCIDENCIA_PERSONAS_BUSCAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);
                    AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);
                    AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);
                    AddStr(p, "HV_Texto", f.Texto);
                },
                map: MapIncidencia_Persona_Busqueda,
                ct: ct);
            return Result<List<Dto_Incidencia_Persona_Busqueda>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Incidencia_Persona_Busqueda>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<ResultSp<Dto_Incidencia_Registrada>> RegistrarAsync(Dto_Incidencia_Registrar dto, long usuarioId, CancellationToken ct = default)
    {
        var r = await _exec.EjecutarEscrituraConSalidasAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_INCIDENCIA_REGISTRAR",
            columnasSalida: new[] { "HV_ID_Incidencia_Result", "HV_Codigo_Result" },
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Catalogo_Sede", dto.ID_Catalogo_Sede);
                AddLongReq(p, "HV_ID_Catalogo_Tipo_Incidencia", dto.ID_Catalogo_Tipo_Incidencia);
                AddStr(p, "HV_Tipo_Detalle", dto.Tipo_Detalle);
                AddTimestamp(p, "HV_Fecha_Hora_Hecho", dto.Fecha_Hora_Hecho);
                AddLong(p, "HV_ID_Catalogo_Zona_Acceso", dto.ID_Catalogo_Zona_Acceso);
                AddStr(p, "HV_Lugar_Detalle", dto.Lugar_Detalle);
                AddStr(p, "HV_Descripcion", dto.Descripcion);
                AddStr(p, "HV_IDs_Solicitud_Persona", dto.IDs_Solicitud_Persona is null ? string.Empty : string.Join(",", dto.IDs_Solicitud_Persona));
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
        if (!r.Ok || r.Data is null) return ResultSp<Dto_Incidencia_Registrada>.Fail(r.Codigo, r.Mensaje);
        return ResultSp<Dto_Incidencia_Registrada>.Success(new Dto_Incidencia_Registrada
        {
            ID_Incidencia = Convert.ToInt64(r.Data["HV_ID_Incidencia_Result"] ?? 0L),
            Codigo = Convert.ToString(r.Data["HV_Codigo_Result"]) ?? string.Empty,
        }, r.Mensaje);
    }

    public async Task<ResultSp> DecidirAsync(Dto_Incidencia_Decision dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_INCIDENCIA_DECIDIR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Incidencia", dto.ID_Incidencia);
                AddStr(p, "HV_Decision", dto.Decision);
                AddStr(p, "HV_Sustento", dto.Sustento);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

    private static Dto_Incidencia_Lista MapIncidencia_Lista(DbDataReader rd) => new()
    {
        ID_Incidencia      = RdLong(rd, "ID_Incidencia"),
        Codigo             = RdStr(rd, "Codigo"),
        Fecha_Hora_Hecho   = RdDt(rd, "Fecha_Hora_Hecho"),
        Tipo_Codigo        = RdStr(rd, "Tipo_Codigo"),
        Tipo_Descripcion   = RdStr(rd, "Tipo_Descripcion"),
        Zona_Descripcion   = RdStrN(rd, "Zona_Descripcion"),
        Lugar_Detalle      = RdStrN(rd, "Lugar_Detalle"),
        Descripcion        = RdStr(rd, "Descripcion"),
        Origen             = RdStr(rd, "Origen"),
        Registrador_Nombre = RdStrN(rd, "Registrador_Nombre"),
        Estado             = RdStr(rd, "Estado"),
        Cantidad_Personas  = RdLong(rd, "Cantidad_Personas"),
        Fecha_Decision     = RdDtN(rd, "Fecha_Decision"),
    };

    private static Dto_Incidencia_Detalle MapIncidencia_Detalle(DbDataReader rd) => new()
    {
        ID_Incidencia               = RdLong(rd, "ID_Incidencia"),
        Codigo                      = RdStr(rd, "Codigo"),
        ID_Catalogo_Sede            = RdLong(rd, "ID_Catalogo_Sede"),
        Fecha_Hora_Hecho            = RdDt(rd, "Fecha_Hora_Hecho"),
        ID_Catalogo_Tipo_Incidencia = RdLong(rd, "ID_Catalogo_Tipo_Incidencia"),
        Tipo_Descripcion            = RdStr(rd, "Tipo_Descripcion"),
        Tipo_Detalle                = RdStrN(rd, "Tipo_Detalle"),
        ID_Catalogo_Zona_Acceso     = RdLongN(rd, "ID_Catalogo_Zona_Acceso"),
        Zona_Descripcion            = RdStrN(rd, "Zona_Descripcion"),
        Lugar_Detalle               = RdStrN(rd, "Lugar_Detalle"),
        Descripcion                 = RdStr(rd, "Descripcion"),
        Origen                      = RdStr(rd, "Origen"),
        Registrador_Nombre          = RdStrN(rd, "Registrador_Nombre"),
        Estado                      = RdStr(rd, "Estado"),
        Decisor_Nombre              = RdStrN(rd, "Decisor_Nombre"),
        Fecha_Decision              = RdDtN(rd, "Fecha_Decision"),
        Sustento_Decision           = RdStrN(rd, "Sustento_Decision"),
        Puede_Decidir               = RdBool(rd, "Puede_Decidir"),
    };

    private static Dto_Incidencia_Persona MapIncidencia_Persona(DbDataReader rd) => new()
    {
        ID_Solicitud_Persona = RdLong(rd, "ID_Solicitud_Persona"),
        ID_Solicitud         = RdLong(rd, "ID_Solicitud"),
        Codigo_Solicitud     = RdStr(rd, "Codigo_Solicitud"),
        Tipo_Documento       = RdStrN(rd, "Tipo_Documento"),
        Numero_Documento     = RdStrN(rd, "Numero_Documento"),
        Persona_Nombre       = RdStr(rd, "Persona_Nombre"),
        Empresa_Visitante    = RdStrN(rd, "Empresa_Visitante"),
        Estado_Persona       = RdStr(rd, "Estado_Persona"),
    };

    private static Dto_Incidencia_Contadores MapIncidencia_Contadores(DbDataReader rd) => new()
    {
        Registradas  = RdLong(rd, "Registradas"),
        Confirmadas  = RdLong(rd, "Confirmadas"),
        Desestimadas = RdLong(rd, "Desestimadas"),
    };

    private static Dto_Incidencia_Persona_Busqueda MapIncidencia_Persona_Busqueda(DbDataReader rd) => new()
    {
        ID_Solicitud_Persona = RdLong(rd, "ID_Solicitud_Persona"),
        ID_Solicitud         = RdLong(rd, "ID_Solicitud"),
        Codigo_Solicitud     = RdStr(rd, "Codigo_Solicitud"),
        Fecha_Hora_Prevista  = RdDt(rd, "Fecha_Hora_Prevista"),
        Tipo_Documento       = RdStrN(rd, "Tipo_Documento"),
        Numero_Documento     = RdStrN(rd, "Numero_Documento"),
        Persona_Nombre       = RdStr(rd, "Persona_Nombre"),
        Empresa_Visitante    = RdStrN(rd, "Empresa_Visitante"),
        Estado_Persona       = RdStr(rd, "Estado_Persona"),
    };
}
