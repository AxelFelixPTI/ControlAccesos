// ============================================================
// Entrega J (D-183). SP: ERP_CAF_SOLICITUD_ADJUNTO_<AGREGAR|QUITAR|LISTAR|OBTENER|CORREO>
// Conexión : ConexionesCaf.Modulo
// El contenido viaja como DbType.Binary (bytea en PostgreSQL, BLOB en HANA).
// ============================================================

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Solicitud_Adjunto : RepoHelpers, IRepo_Solicitud_Adjunto
{
    private readonly EjecutorSp _exec;
    private readonly ILogger<Repo_Solicitud_Adjunto> _log;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Solicitud_Adjunto(EjecutorSp exec, ILogger<Repo_Solicitud_Adjunto> log) { _exec = exec; _log = log; }

    public Task<ResultSp<long>> AgregarAsync(long solicitudId, string nombreArchivo, string tipoContenido, byte[] contenido, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraConIdAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR",
            columnaId: "HV_ID_Adjunto_Result",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddStrReq(p, "HV_Nombre_Archivo", nombreArchivo);
                AddStr(p, "HV_Tipo_Contenido", tipoContenido);
                AddBytesReq(p, "HV_Contenido", contenido);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public Task<ResultSp> QuitarAsync(long adjuntoId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_SOLICITUD_ADJUNTO_QUITAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud_Adjunto", adjuntoId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public async Task<Result<List<Dto_Solicitud_Adjunto>>> ListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(Conn, "ERP_CAF_SOLICITUD_ADJUNTO_LISTAR",
                p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Solicitud", solicitudId); },
                rd => new Dto_Solicitud_Adjunto
                {
                    ID_Solicitud_Adjunto = RdLong(rd, "ID_Solicitud_Adjunto"), ID_Solicitud = RdLong(rd, "ID_Solicitud"),
                    Nombre_Archivo = RdStr(rd, "Nombre_Archivo"), Extension = RdStr(rd, "Extension"),
                    Tamano_Bytes = RdLong(rd, "Tamano_Bytes"), Fecha = RdDt(rd, "Fecha"), Puede_Quitar = RdBool(rd, "Puede_Quitar"),
                }, ct);
            return Result<List<Dto_Solicitud_Adjunto>>.Ok(lista);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "ADJUNTO_LISTAR ERROR");
            return Result<List<Dto_Solicitud_Adjunto>>.Fail("No se pudieron leer los documentos.");
        }
    }

    public async Task<Result<Dto_Solicitud_Adjunto_Contenido?>> ObtenerAsync(long usuarioId, long adjuntoId, CancellationToken ct = default)
    {
        try
        {
            var d = await _exec.EjecutarLecturaUnicaAsync(Conn, "ERP_CAF_SOLICITUD_ADJUNTO_OBTENER",
                p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Solicitud_Adjunto", adjuntoId); },
                rd => new Dto_Solicitud_Adjunto_Contenido
                {
                    ID_Solicitud_Adjunto = RdLong(rd, "ID_Solicitud_Adjunto"), ID_Solicitud = RdLong(rd, "ID_Solicitud"),
                    Nombre_Archivo = RdStr(rd, "Nombre_Archivo"), Extension = RdStr(rd, "Extension"),
                    Tamano_Bytes = RdLong(rd, "Tamano_Bytes"), Contenido = RdBytes(rd, "Contenido"),
                }, ct);
            return Result<Dto_Solicitud_Adjunto_Contenido?>.Ok(d);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "ADJUNTO_OBTENER ERROR");
            return Result<Dto_Solicitud_Adjunto_Contenido?>.Fail("No se pudo leer el documento.");
        }
    }

    public async Task<Result<List<Dto_Correo_Adjunto>>> CorreoAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(Conn, "ERP_CAF_SOLICITUD_ADJUNTO_CORREO",
                p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Solicitud", solicitudId); },
                rd => new Dto_Correo_Adjunto
                {
                    ID_Solicitud_Adjunto = RdLong(rd, "ID_Solicitud_Adjunto"), Nombre_Archivo = RdStr(rd, "Nombre_Archivo"),
                    Extension = RdStr(rd, "Extension"), Contenido = RdBytes(rd, "Contenido"),
                }, ct);
            return Result<List<Dto_Correo_Adjunto>>.Ok(lista);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "ADJUNTO_CORREO ERROR");
            return Result<List<Dto_Correo_Adjunto>>.Fail("No se pudieron leer los documentos del correo.");
        }
    }
}
