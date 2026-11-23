// ============================================================
// D-265. SP: ERP_CAF_DOC_INGRESO_<AGREGAR|PERSONAS_ASIGNAR|QUITAR|LISTAR|OBTENER|PERSONAS_DIA|RESUMEN|DE_SOLICITUD>
// Conexión : ConexionesCaf.Modulo. El contenido viaja como DbType.Binary (bytea en PostgreSQL, BLOB en HANA).
// ============================================================

using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Documento_Ingreso : RepoHelpers, IRepo_Documento_Ingreso
{
    private readonly EjecutorSp _exec;
    private readonly ILogger<Repo_Documento_Ingreso> _log;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Documento_Ingreso(EjecutorSp exec, ILogger<Repo_Documento_Ingreso> log) { _exec = exec; _log = log; }

    public Task<ResultSp<long>> AgregarAsync(long sedeId, DateTime fecha, string tipo, string nombreArchivo, string tipoContenido, byte[] contenido, string personasIds, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraConIdAsync(
            clave: Conn, procedimiento: "ERP_CAF_DOC_INGRESO_AGREGAR", columnaId: "HV_ID_Result",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                AddDate(p, "HV_Fecha", fecha);
                AddStrReq(p, "HV_Tipo", tipo);
                AddStrReq(p, "HV_Nombre_Archivo", nombreArchivo);
                AddStr(p, "HV_Tipo_Contenido", tipoContenido);
                AddBytesReq(p, "HV_Contenido", contenido);
                AddStrReq(p, "HV_Personas", personasIds);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public Task<ResultSp> AsignarPersonasAsync(long documentoId, string personasIds, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_DOC_INGRESO_PERSONAS_ASIGNAR",
            bind: p => { AddLongReq(p, "HV_ID_Documento_Ingreso", documentoId); AddStrReq(p, "HV_Personas", personasIds); AddLongReq(p, "HV_UsuarioID", usuarioId); },
            ct: ct);

    public Task<ResultSp> QuitarAsync(long documentoId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_DOC_INGRESO_QUITAR",
            bind: p => { AddLongReq(p, "HV_ID_Documento_Ingreso", documentoId); AddLongReq(p, "HV_UsuarioID", usuarioId); },
            ct: ct);

    public async Task<Result<List<Dto_Documento_Ingreso>>> ListarAsync(long usuarioId, long sedeId, DateTime fecha, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(Conn, "ERP_CAF_DOC_INGRESO_LISTAR",
                p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId); AddDate(p, "HV_Fecha", fecha); },
                rd => new Dto_Documento_Ingreso
                {
                    ID_Documento_Ingreso = RdLong(rd, "ID_Documento_Ingreso"), Tipo = RdStr(rd, "Tipo"), Nombre_Archivo = RdStr(rd, "Nombre_Archivo"),
                    Extension = RdStr(rd, "Extension"), Tamano_Bytes = RdLong(rd, "Tamano_Bytes"), Fecha_Subida = RdDt(rd, "Fecha_Subida"),
                    Subido_Por = RdStrN(rd, "Subido_Por"), Personas = RdStrN(rd, "Personas"), Puede_Modificar = RdBool(rd, "Puede_Modificar"),
                }, ct);
            return Result<List<Dto_Documento_Ingreso>>.Ok(lista);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "DOC_INGRESO_LISTAR ERROR");
            return Result<List<Dto_Documento_Ingreso>>.Fail("No se pudieron leer los documentos.");
        }
    }

    public async Task<Result<List<Dto_Documento_Ingreso_Busqueda>>> BuscarAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, string? texto, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(Conn, "ERP_CAF_DOC_INGRESO_BUSCAR",
                p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                    AddDate(p, "HV_Desde", desde); AddDate(p, "HV_Hasta", hasta); AddStr(p, "HV_Texto", texto);
                },
                rd => new Dto_Documento_Ingreso_Busqueda
                {
                    ID_Documento_Ingreso = RdLong(rd, "ID_Documento_Ingreso"), Fecha_Registro = RdDt(rd, "Fecha_Registro"), Tipo = RdStr(rd, "Tipo"),
                    Nombre_Archivo = RdStr(rd, "Nombre_Archivo"), Extension = RdStr(rd, "Extension"), Tamano_Bytes = RdLong(rd, "Tamano_Bytes"),
                    Fecha_Subida = RdDt(rd, "Fecha_Subida"), Subido_Por = RdStrN(rd, "Subido_Por"), Personas = RdStrN(rd, "Personas"), Puede_Modificar = RdBool(rd, "Puede_Modificar"),
                }, ct);
            return Result<List<Dto_Documento_Ingreso_Busqueda>>.Ok(lista);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "DOC_INGRESO_BUSCAR ERROR");
            return Result<List<Dto_Documento_Ingreso_Busqueda>>.Fail("No se pudieron buscar los documentos.");
        }
    }

    public async Task<Result<Dto_Documento_Ingreso_Contenido?>> ObtenerAsync(long usuarioId, long documentoId, CancellationToken ct = default)
    {
        try
        {
            var d = await _exec.EjecutarLecturaUnicaAsync(Conn, "ERP_CAF_DOC_INGRESO_OBTENER",
                p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Documento_Ingreso", documentoId); },
                rd => new Dto_Documento_Ingreso_Contenido
                {
                    ID_Documento_Ingreso = RdLong(rd, "ID_Documento_Ingreso"), Nombre_Archivo = RdStr(rd, "Nombre_Archivo"),
                    Extension = RdStr(rd, "Extension"), Tamano_Bytes = RdLong(rd, "Tamano_Bytes"), Contenido = RdBytes(rd, "Contenido"),
                }, ct);
            return Result<Dto_Documento_Ingreso_Contenido?>.Ok(d);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "DOC_INGRESO_OBTENER ERROR");
            return Result<Dto_Documento_Ingreso_Contenido?>.Fail("No se pudo leer el documento.");
        }
    }

    public async Task<Result<List<Dto_Documento_Ingreso_Persona>>> PersonasDiaAsync(long usuarioId, long sedeId, DateTime fecha, string? texto, bool soloConEquipos, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(Conn, "ERP_CAF_DOC_INGRESO_PERSONAS_DIA",
                p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId); AddDate(p, "HV_Fecha", fecha);
                    AddStr(p, "HV_Texto", texto); AddChar1(p, "HV_Solo_Con_Equipos", soloConEquipos ? "Y" : "N");
                },
                rd => new Dto_Documento_Ingreso_Persona
                {
                    ID_Solicitud_Persona = RdLong(rd, "ID_Solicitud_Persona"), Nombre = RdStr(rd, "Nombre"), Documento = RdStr(rd, "Documento"),
                    Solicitud = RdStr(rd, "Solicitud"), Empresa = RdStrN(rd, "Empresa"), Trae_Equipos = RdBool(rd, "Trae_Equipos"),
                    Trae_Herramientas = RdBool(rd, "Trae_Herramientas"), Documentos = RdInt(rd, "Documentos"),
                }, ct);
            return Result<List<Dto_Documento_Ingreso_Persona>>.Ok(lista);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "DOC_INGRESO_PERSONAS_DIA ERROR");
            return Result<List<Dto_Documento_Ingreso_Persona>>.Fail("No se pudieron leer las personas del día.");
        }
    }

    public async Task<Result<Dto_Documento_Ingreso_Resumen?>> ResumenAsync(long usuarioId, long sedeId, DateTime fecha, CancellationToken ct = default)
    {
        try
        {
            var d = await _exec.EjecutarLecturaUnicaAsync(Conn, "ERP_CAF_DOC_INGRESO_RESUMEN",
                p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId); AddDate(p, "HV_Fecha", fecha); },
                rd => new Dto_Documento_Ingreso_Resumen
                {
                    Ingresaron = RdInt(rd, "Ingresaron"), Con_Equipos = RdInt(rd, "Con_Equipos"), Sin_Documento = RdInt(rd, "Sin_Documento"),
                    Documentos = RdInt(rd, "Documentos"), Obligatorio = RdBool(rd, "Obligatorio"), Max_MB = RdInt(rd, "Max_MB"), Puede_Subir = RdBool(rd, "Puede_Subir"),
                }, ct);
            return Result<Dto_Documento_Ingreso_Resumen?>.Ok(d);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "DOC_INGRESO_RESUMEN ERROR");
            return Result<Dto_Documento_Ingreso_Resumen?>.Fail("No se pudo leer el resumen del día.");
        }
    }

    public async Task<Result<List<Dto_Documento_Ingreso_Solicitud>>> DeSolicitudAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(Conn, "ERP_CAF_DOC_INGRESO_DE_SOLICITUD",
                p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Solicitud", solicitudId); },
                rd => new Dto_Documento_Ingreso_Solicitud
                {
                    ID_Documento_Ingreso = RdLong(rd, "ID_Documento_Ingreso"), Tipo = RdStr(rd, "Tipo"), Nombre_Archivo = RdStr(rd, "Nombre_Archivo"),
                    Extension = RdStr(rd, "Extension"), Tamano_Bytes = RdLong(rd, "Tamano_Bytes"), Fecha_Registro = RdDt(rd, "Fecha_Registro"),
                    Subido_Por = RdStrN(rd, "Subido_Por"), Personas = RdStrN(rd, "Personas"),
                }, ct);
            return Result<List<Dto_Documento_Ingreso_Solicitud>>.Ok(lista);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "DOC_INGRESO_DE_SOLICITUD ERROR");
            return Result<List<Dto_Documento_Ingreso_Solicitud>>.Fail("No se pudieron leer los documentos de ingreso.");
        }
    }
}
