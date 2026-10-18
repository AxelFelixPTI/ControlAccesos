// ============================================================
// Archivo  : Repo_Porteria.cs
// Ruta     : Infrastructure.Repositories/
// Módulo   : ControlAccesos
// Hito     : 3 — Portería y desviaciones
// Fase     : 4 — Repository
// Entidad  : Porteria
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_PORTERIA_<ACCION> (checklist, ficha, bitácora, ingreso, salida, no se presentó)
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).

using System.Data.Common;
using System.Linq;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Porteria : RepoHelpers, IRepo_Porteria
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Porteria(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Porteria_Item>>> ChecklistObtenerAsync(long usuarioId, long solicitudPersonaId, string etapa, bool traeEquipos = false, bool traeHerramientas = false, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PORTERIA_CHECKLIST_OBTENER",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Solicitud_Persona", solicitudPersonaId);
                    AddStrReq(p, "HV_Etapa", etapa);
                    AddChar1(p, "HV_Trae_Equipos", traeEquipos ? "Y" : "N");
                    AddChar1(p, "HV_Trae_Herramientas", traeHerramientas ? "Y" : "N");
                },
                map: MapPorteria_Item,
                ct: ct);
            return Result<List<Dto_Porteria_Item>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Porteria_Item>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<Dto_Porteria_Ficha?>> FichaAsync(long usuarioId, long solicitudPersonaId, CancellationToken ct = default)
    {
        try
        {
            var dato = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PORTERIA_FICHA",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Solicitud_Persona", solicitudPersonaId);
                },
                map: MapPorteria_Ficha,
                ct: ct);
            return Result<Dto_Porteria_Ficha?>.Ok(dato);
        }
        catch (Exception ex)
        {
            return Result<Dto_Porteria_Ficha?>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Porteria_Movimiento>>> MovimientosListarAsync(long usuarioId, Dto_Filtro_Movimientos f, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PORTERIA_MOVIMIENTOS_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", f.ID_Catalogo_Sede);
                    AddDate(p, "HV_Fecha_Desde", f.Fecha_Desde);
                    AddDate(p, "HV_Fecha_Hasta", f.Fecha_Hasta);
                    AddStr(p, "HV_Tipo", f.Tipo);
                    AddStr(p, "HV_Texto", f.Texto);
                },
                map: MapPorteria_Movimiento,
                ct: ct);
            return Result<List<Dto_Porteria_Movimiento>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Porteria_Movimiento>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<Dto_Porteria_Registro?>> RegistroDetalleAsync(long usuarioId, long registroId, CancellationToken ct = default)
    {
        try
        {
            var dato = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PORTERIA_REGISTRO_DETALLE",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Registro_Acceso", registroId);
                },
                map: MapPorteria_Registro,
                ct: ct);
            return Result<Dto_Porteria_Registro?>.Ok(dato);
        }
        catch (Exception ex)
        {
            return Result<Dto_Porteria_Registro?>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Porteria_Registro_Item>>> RegistroChecklistListarAsync(long usuarioId, long registroId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PORTERIA_REGISTRO_CHECKLIST_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Registro_Acceso", registroId);
                },
                map: MapPorteria_Registro_Item,
                ct: ct);
            return Result<List<Dto_Porteria_Registro_Item>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Porteria_Registro_Item>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<ResultSp<Dto_Porteria_Registrado>> IngresoRegistrarAsync(Dto_Porteria_Ingreso dto, long usuarioId, CancellationToken ct = default)
    {
        var r = await _exec.EjecutarEscrituraConSalidasAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PORTERIA_INGRESO_REGISTRAR",
            columnasSalida: new[] { "HV_ID_Registro_Acceso_Result", "HV_ID_Desviacion_Result", "HV_Resultado_Result" },
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud_Persona", dto.ID_Solicitud_Persona);
                AddStr(p, "HV_Items", ItemsTexto(dto.Items));
                AddChar1(p, "HV_Trae_Equipos", dto.Trae_Equipos ? "Y" : "N");
                AddChar1(p, "HV_Trae_Herramientas", dto.Trae_Herramientas ? "Y" : "N");
                AddStr(p, "HV_Observacion", dto.Observacion);
                AddStr(p, "HV_Desv_Descripcion", dto.Desviacion?.Descripcion);
                AddLong(p, "HV_ID_Coordinador", dto.Desviacion?.ID_Coordinador);
                AddLong(p, "HV_ID_Tratamiento", dto.Desviacion?.ID_Tratamiento);
                AddStr(p, "HV_Tratamiento_Detalle", dto.Desviacion?.Tratamiento_Detalle);
                AddStr(p, "HV_Resultado_Elegido", dto.Desviacion?.Resultado_Elegido);
                AddTimestamp(p, "HV_Fecha_Hora_Hecho", dto.Fecha_Hora_Hecho);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
        if (!r.Ok || r.Data is null) return ResultSp<Dto_Porteria_Registrado>.Fail(r.Codigo, r.Mensaje);
        return ResultSp<Dto_Porteria_Registrado>.Success(new Dto_Porteria_Registrado
        {
            ID_Registro_Acceso = Convert.ToInt64(r.Data["HV_ID_Registro_Acceso_Result"] ?? 0L),
            ID_Desviacion = Convert.ToInt64(r.Data["HV_ID_Desviacion_Result"] ?? 0L) is var d && d > 0 ? d : null,
            Resultado = Convert.ToString(r.Data["HV_Resultado_Result"]) ?? string.Empty,
        }, r.Mensaje);
    }

    public async Task<ResultSp<Dto_Porteria_Registrado>> SalidaRegistrarAsync(Dto_Porteria_Salida dto, long usuarioId, CancellationToken ct = default)
    {
        var r = await _exec.EjecutarEscrituraConSalidasAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PORTERIA_SALIDA_REGISTRAR",
            columnasSalida: new[] { "HV_ID_Registro_Acceso_Result", "HV_ID_Desviacion_Result", "HV_Resultado_Result" },
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud_Persona", dto.ID_Solicitud_Persona);
                AddStr(p, "HV_Items", ItemsTexto(dto.Items));
                AddStr(p, "HV_Observacion", dto.Observacion);
                AddStr(p, "HV_Desv_Descripcion", dto.Desviacion?.Descripcion);
                AddLong(p, "HV_ID_Coordinador", dto.Desviacion?.ID_Coordinador);
                AddLong(p, "HV_ID_Tratamiento", dto.Desviacion?.ID_Tratamiento);
                AddStr(p, "HV_Tratamiento_Detalle", dto.Desviacion?.Tratamiento_Detalle);
                AddStr(p, "HV_Resultado_Elegido", dto.Desviacion?.Resultado_Elegido);
                AddTimestamp(p, "HV_Fecha_Hora_Hecho", dto.Fecha_Hora_Hecho);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
        if (!r.Ok || r.Data is null) return ResultSp<Dto_Porteria_Registrado>.Fail(r.Codigo, r.Mensaje);
        return ResultSp<Dto_Porteria_Registrado>.Success(new Dto_Porteria_Registrado
        {
            ID_Registro_Acceso = Convert.ToInt64(r.Data["HV_ID_Registro_Acceso_Result"] ?? 0L),
            ID_Desviacion = Convert.ToInt64(r.Data["HV_ID_Desviacion_Result"] ?? 0L) is var d && d > 0 ? d : null,
            Resultado = Convert.ToString(r.Data["HV_Resultado_Result"]) ?? string.Empty,
        }, r.Mensaje);
    }

    public async Task<ResultSp<long>> NoSePresentoMarcarAsync(DateTime? fechaCorte, long usuarioId, CancellationToken ct = default)
    {
        var r = await _exec.EjecutarEscrituraConSalidasAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR",
            columnasSalida: new[] { "HV_Cantidad_Result" },
            bind: p =>
            {
                AddDate(p, "HV_Fecha_Corte", fechaCorte);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
        if (!r.Ok || r.Data is null) return ResultSp<long>.Fail(r.Codigo, r.Mensaje);
        return ResultSp<long>.Success(Convert.ToInt64(r.Data["HV_Cantidad_Result"] ?? 0L), r.Mensaje);
    }

    /// <summary>Respuestas del checklist como texto «id:Y,id:N» (formato de las rutinas).</summary>
    private static string ItemsTexto(IEnumerable<Dto_Porteria_Respuesta>? items)
        => items is null ? string.Empty
           : string.Join(",", items.Select(i => i.ID_Catalogo_Item_Checklist + ":" + (i.Cumple ? "Y" : "N")));

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

    private static Dto_Porteria_Item MapPorteria_Item(DbDataReader rd) => new()
    {
        ID_Catalogo_Item_Checklist = RdLong(rd, "ID_Catalogo_Item_Checklist"),
        Codigo                     = RdStr(rd, "Codigo"),
        Descripcion                = RdStr(rd, "Descripcion"),
        Ayuda                      = RdStrN(rd, "Ayuda"),
        Es_Critico                 = RdBool(rd, "Es_Critico"),
        Orden                      = RdLong(rd, "Orden"),
    };

    private static Dto_Porteria_Ficha MapPorteria_Ficha(DbDataReader rd) => new()
    {
        ID_Solicitud_Persona           = RdLong(rd, "ID_Solicitud_Persona"),
        ID_Solicitud                   = RdLong(rd, "ID_Solicitud"),
        Codigo                         = RdStr(rd, "Codigo"),
        ID_Catalogo_Sede               = RdLong(rd, "ID_Catalogo_Sede"),
        Fecha_Hora_Prevista            = RdDt(rd, "Fecha_Hora_Prevista"),
        Empresa_Visitante              = RdStrN(rd, "Empresa_Visitante"),
        Responsable_Nombre             = RdStrN(rd, "Responsable_Nombre"),
        Tipo_Documento                 = RdStrN(rd, "Tipo_Documento"),
        Numero_Documento               = RdStrN(rd, "Numero_Documento"),
        Persona_Nombre                 = RdStr(rd, "Persona_Nombre"),
        Estado                         = RdStr(rd, "Estado"),
        Fecha_Hora_Ingreso             = RdDtN(rd, "Fecha_Hora_Ingreso"),
        Fecha_Hora_Salida              = RdDtN(rd, "Fecha_Hora_Salida"),
        Acceso_Restringido             = RdBool(rd, "Acceso_Restringido"),
        Trae_Equipos                   = RdBool(rd, "Trae_Equipos"),
        Trae_Herramientas              = RdBool(rd, "Trae_Herramientas"),
        Exige_SCTR                     = RdBool(rd, "Exige_SCTR"),
        Exige_EPP                      = RdBool(rd, "Exige_EPP"),
        Zonas_Nombres                  = RdStrN(rd, "Zonas_Nombres"),
        Tiene_Respaldo_Equipos         = RdBool(rd, "Tiene_Respaldo_Equipos"),
        Tiene_Respaldo_Herramientas    = RdBool(rd, "Tiene_Respaldo_Herramientas"),
        Puede_Registrar_Ingreso        = RdBool(rd, "Puede_Registrar_Ingreso"),
        Motivo_No_Ingreso              = RdStrN(rd, "Motivo_No_Ingreso"),
        Puede_Registrar_Ingreso_Tardio = RdBool(rd, "Puede_Registrar_Ingreso_Tardio"),
        Puede_Registrar_Salida         = RdBool(rd, "Puede_Registrar_Salida"),
        Motivo_No_Salida               = RdStrN(rd, "Motivo_No_Salida"),
    };

    private static Dto_Porteria_Movimiento MapPorteria_Movimiento(DbDataReader rd) => new()
    {
        ID_Registro_Acceso   = RdLong(rd, "ID_Registro_Acceso"),
        ID_Solicitud_Persona = RdLong(rd, "ID_Solicitud_Persona"),
        ID_Solicitud         = RdLong(rd, "ID_Solicitud"),
        Codigo_Solicitud     = RdStr(rd, "Codigo_Solicitud"),
        Fecha_Hora           = RdDt(rd, "Fecha_Hora"),
        Tipo_Movimiento      = RdStr(rd, "Tipo_Movimiento"),
        Resultado            = RdStrN(rd, "Resultado"),
        Es_Registro_Tardio   = RdBool(rd, "Es_Registro_Tardio"),
        Tipo_Documento       = RdStrN(rd, "Tipo_Documento"),
        Numero_Documento     = RdStrN(rd, "Numero_Documento"),
        Persona_Nombre       = RdStr(rd, "Persona_Nombre"),
        Empresa_Visitante    = RdStrN(rd, "Empresa_Visitante"),
        Vigilante_Nombre     = RdStrN(rd, "Vigilante_Nombre"),
        Observacion          = RdStrN(rd, "Observacion"),
        Tiene_Desviacion     = RdBool(rd, "Tiene_Desviacion"),
        Codigo_Desviacion    = RdStrN(rd, "Codigo_Desviacion"),
    };

    private static Dto_Porteria_Registro MapPorteria_Registro(DbDataReader rd) => new()
    {
        ID_Registro_Acceso   = RdLong(rd, "ID_Registro_Acceso"),
        ID_Solicitud_Persona = RdLong(rd, "ID_Solicitud_Persona"),
        ID_Solicitud         = RdLong(rd, "ID_Solicitud"),
        Codigo_Solicitud     = RdStr(rd, "Codigo_Solicitud"),
        ID_Catalogo_Sede     = RdLong(rd, "ID_Catalogo_Sede"),
        Fecha_Hora           = RdDt(rd, "Fecha_Hora"),
        Fecha_Hora_Sistema   = RdDt(rd, "Fecha_Hora_Sistema"),
        Tipo_Movimiento      = RdStr(rd, "Tipo_Movimiento"),
        Resultado            = RdStrN(rd, "Resultado"),
        Es_Registro_Tardio   = RdBool(rd, "Es_Registro_Tardio"),
        Persona_Nombre       = RdStr(rd, "Persona_Nombre"),
        Numero_Documento     = RdStrN(rd, "Numero_Documento"),
        Empresa_Visitante    = RdStrN(rd, "Empresa_Visitante"),
        Vigilante_Nombre     = RdStrN(rd, "Vigilante_Nombre"),
        Observacion          = RdStrN(rd, "Observacion"),
        ID_Desviacion        = RdLongN(rd, "ID_Desviacion"),
        Codigo_Desviacion    = RdStrN(rd, "Codigo_Desviacion"),
    };

    private static Dto_Porteria_Registro_Item MapPorteria_Registro_Item(DbDataReader rd) => new()
    {
        ID_Catalogo_Item_Checklist = RdLong(rd, "ID_Catalogo_Item_Checklist"),
        Codigo                     = RdStr(rd, "Codigo"),
        Descripcion                = RdStr(rd, "Descripcion"),
        Es_Critico                 = RdBool(rd, "Es_Critico"),
        Cumple                     = RdBool(rd, "Cumple"),
        Orden                      = RdLong(rd, "Orden"),
    };
}
