// ============================================================
// Archivo  : Repo_Desviacion.cs
// Ruta     : Infrastructure.Repositories/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 4 — Repository
// Entidad  : Desviacion
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_DESVIACION_<ACCION>
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).

using System.Data.Common;
using System.Linq;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Desviacion : RepoHelpers, IRepo_Desviacion
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Desviacion(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Desviacion_Lista>>> ListarAsync(long usuarioId, Dto_Filtro_Desviaciones f, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_DESVIACION_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);
                    AddStr(p, "HV_Estado", f.Estado);
                    AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);
                    AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);
                    AddStr(p, "HV_Texto", f.Texto);
                },
                map: MapDesviacion_Lista,
                ct: ct);
            return Result<List<Dto_Desviacion_Lista>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Desviacion_Lista>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<Dto_Desviacion_Detalle?>> DetalleAsync(long usuarioId, long desviacionId, CancellationToken ct = default)
    {
        try
        {
            var dato = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CAF_DESVIACION_DETALLE",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Desviacion", desviacionId);
                },
                map: MapDesviacion_Detalle,
                ct: ct);
            return Result<Dto_Desviacion_Detalle?>.Ok(dato);
        }
        catch (Exception ex)
        {
            return Result<Dto_Desviacion_Detalle?>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<Dto_Desviacion_Contadores?>> ContadoresAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try
        {
            var dato = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CAF_DESVIACION_CONTADORES",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                },
                map: MapDesviacion_Contadores,
                ct: ct);
            return Result<Dto_Desviacion_Contadores?>.Ok(dato);
        }
        catch (Exception ex)
        {
            return Result<Dto_Desviacion_Contadores?>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Desviacion_Coordinador>>> CoordinadoresDropdownAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_DESVIACION_COORDINADORES_DROPDOWN",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                },
                map: MapDesviacion_Coordinador,
                ct: ct);
            return Result<List<Dto_Desviacion_Coordinador>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Desviacion_Coordinador>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Desviacion_Tratamiento>>> TratamientosDropdownAsync(string etapa, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_DESVIACION_TRATAMIENTOS_DROPDOWN",
                bind: p =>
                {
                    AddStrReq(p, "HV_Etapa", etapa);
                },
                map: MapDesviacion_Tratamiento,
                ct: ct);
            return Result<List<Dto_Desviacion_Tratamiento>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Desviacion_Tratamiento>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<ResultSp> ConformidadDarAsync(long desviacionId, string? comentario, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_DESVIACION_CONFORMIDAD_DAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Desviacion", desviacionId);
                AddStr(p, "HV_Comentario", comentario);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

    private static Dto_Desviacion_Lista MapDesviacion_Lista(DbDataReader rd) => new()
    {
        ID_Desviacion      = RdLong(rd, "ID_Desviacion"),
        Codigo             = RdStr(rd, "Codigo"),
        ID_Registro_Acceso = RdLong(rd, "ID_Registro_Acceso"),
        Tipo_Movimiento    = RdStr(rd, "Tipo_Movimiento"),
        Resultado          = RdStrN(rd, "Resultado"),
        Fecha_Hora         = RdDt(rd, "Fecha_Hora"),
        Persona_Nombre     = RdStr(rd, "Persona_Nombre"),
        Numero_Documento   = RdStrN(rd, "Numero_Documento"),
        Empresa_Visitante  = RdStrN(rd, "Empresa_Visitante"),
        Codigo_Solicitud   = RdStr(rd, "Codigo_Solicitud"),
        Descripcion        = RdStr(rd, "Descripcion"),
        Tratamiento        = RdStrN(rd, "Tratamiento"),
        Coordinador_Nombre = RdStrN(rd, "Coordinador_Nombre"),
        Estado             = RdStr(rd, "Estado"),
        Fecha_Conformidad  = RdDtN(rd, "Fecha_Conformidad"),
    };

    private static Dto_Desviacion_Detalle MapDesviacion_Detalle(DbDataReader rd) => new()
    {
        ID_Desviacion                      = RdLong(rd, "ID_Desviacion"),
        Codigo                             = RdStr(rd, "Codigo"),
        ID_Registro_Acceso                 = RdLong(rd, "ID_Registro_Acceso"),
        ID_Solicitud                       = RdLong(rd, "ID_Solicitud"),
        Codigo_Solicitud                   = RdStr(rd, "Codigo_Solicitud"),
        Tipo_Movimiento                    = RdStr(rd, "Tipo_Movimiento"),
        Resultado                          = RdStrN(rd, "Resultado"),
        Fecha_Hora                         = RdDt(rd, "Fecha_Hora"),
        Persona_Nombre                     = RdStr(rd, "Persona_Nombre"),
        Numero_Documento                   = RdStrN(rd, "Numero_Documento"),
        Empresa_Visitante                  = RdStrN(rd, "Empresa_Visitante"),
        Descripcion                        = RdStr(rd, "Descripcion"),
        ID_Catalogo_Tratamiento_Desviacion = RdLong(rd, "ID_Catalogo_Tratamiento_Desviacion"),
        Tratamiento                        = RdStrN(rd, "Tratamiento"),
        Tratamiento_Detalle                = RdStrN(rd, "Tratamiento_Detalle"),
        ID_Usuario_Coordinador_Consultado  = RdLongN(rd, "ID_Usuario_Coordinador_Consultado"),
        Coordinador_Nombre                 = RdStrN(rd, "Coordinador_Nombre"),
        Registrado_Por_Nombre              = RdStrN(rd, "Registrado_Por_Nombre"),
        Estado                             = RdStr(rd, "Estado"),
        Conformidad_Nombre                 = RdStrN(rd, "Conformidad_Nombre"),
        Fecha_Conformidad                  = RdDtN(rd, "Fecha_Conformidad"),
        Comentario_Conformidad             = RdStrN(rd, "Comentario_Conformidad"),
        ID_Incidencia                      = RdLongN(rd, "ID_Incidencia"),
        Puede_Dar_Conformidad              = RdBool(rd, "Puede_Dar_Conformidad"),
        Motivo_No_Conformidad              = RdStrN(rd, "Motivo_No_Conformidad"),
    };

    private static Dto_Desviacion_Contadores MapDesviacion_Contadores(DbDataReader rd) => new()
    {
        Por_Revisar = RdLong(rd, "Por_Revisar"),
        Revisadas   = RdLong(rd, "Revisadas"),
    };

    private static Dto_Desviacion_Coordinador MapDesviacion_Coordinador(DbDataReader rd) => new()
    {
        ID_Usuario = RdLong(rd, "ID_Usuario"),
        Nombre     = RdStr(rd, "Nombre"),
    };

    private static Dto_Desviacion_Tratamiento MapDesviacion_Tratamiento(DbDataReader rd) => new()
    {
        ID_Catalogo_Tratamiento_Desviacion = RdLong(rd, "ID_Catalogo_Tratamiento_Desviacion"),
        Codigo                             = RdStr(rd, "Codigo"),
        Descripcion                        = RdStr(rd, "Descripcion"),
        Es_Otro                            = RdBool(rd, "Es_Otro"),
        Resultado                          = RdStrN(rd, "Resultado"),
    };
}
