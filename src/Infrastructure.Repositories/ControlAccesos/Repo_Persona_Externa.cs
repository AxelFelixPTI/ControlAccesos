// ============================================================
// Persona externa — registro de visitantes (ERP_CAF_PERSONA_EXTERNA_*, schema del módulo). Se buscan por documento;
// si ya existen se reutilizan, si no se crean. Las reglas (duplicados, documento válido) viven en los procedimientos.
// ============================================================

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Persona_Externa : RepoHelpers, IRepo_Persona_Externa
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Persona_Externa(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Persona_Externa>>> BuscarAsync(string texto, CancellationToken ct = default)
    {
        try
        {
            var l = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PERSONA_EXTERNA_LISTAR",
                bind: p => { AddStr(p, "HV_Filtro_Nombre", texto); AddStr(p, "HV_Incluir_Eliminados", "N"); },
                map: Mapear,
                ct: ct);
            return Result<List<Dto_Persona_Externa>>.Ok(l);
        }
        catch (Exception ex) { return Result<List<Dto_Persona_Externa>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<Dto_Persona_Externa?>> PorDocumentoAsync(long tipoDocumentoId, string numeroDocumento, CancellationToken ct = default)
    {
        try
        {
            var d = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PERSONA_EXTERNA_DETALLE_POR_DOCUMENTO",
                bind: p =>
                {
                    AddLongReq(p, "HV_ID_Catalogo_Tipo_Documento", tipoDocumentoId);
                    AddStrReq(p, "HV_Numero_Documento", numeroDocumento);
                },
                map: Mapear,
                ct: ct);
            return Result<Dto_Persona_Externa?>.Ok(d);
        }
        catch (Exception ex) { return Result<Dto_Persona_Externa?>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<ResultSp<long>> CrearAsync(Dto_Persona_Externa dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraConIdAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PERSONA_EXTERNA_CREAR",
            columnaId: "HV_ID_Persona_Externa_Result",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Catalogo_Tipo_Documento", dto.ID_Catalogo_Tipo_Documento);
                AddStrReq(p, "HV_Numero_Documento", dto.Numero_Documento);
                AddStrReq(p, "HV_Apellido_Paterno", dto.Apellido_Paterno);
                AddStr(p, "HV_Apellido_Materno", dto.Apellido_Materno);
                AddStrReq(p, "HV_Nombres", dto.Nombres);
                AddLongReq(p, "HV_UsuarioID_Create", usuarioId);
            },
            ct: ct);
    }

    public async Task<ResultSp> ActualizarAsync(long id, Dto_Persona_Externa dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PERSONA_EXTERNA_ACTUALIZAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Persona_Externa", id);
                AddLongReq(p, "HV_ID_Catalogo_Tipo_Documento", dto.ID_Catalogo_Tipo_Documento);
                AddStrReq(p, "HV_Numero_Documento", dto.Numero_Documento);
                AddStrReq(p, "HV_Apellido_Paterno", dto.Apellido_Paterno);
                AddStr(p, "HV_Apellido_Materno", dto.Apellido_Materno);
                AddStrReq(p, "HV_Nombres", dto.Nombres);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    private static Dto_Persona_Externa Mapear(DbDataReader rd) => new()
    {
        ID_Persona_Externa = RdLong(rd, "ID_Persona_Externa"),
        ID_Catalogo_Tipo_Documento = RdLong(rd, "ID_Catalogo_Tipo_Documento"),
        Tipo_Documento = RdStrN(rd, "Tipo_Documento"),
        Numero_Documento = RdStr(rd, "Numero_Documento"),
        Apellido_Paterno = RdStr(rd, "Apellido_Paterno"),
        Apellido_Materno = RdStrN(rd, "Apellido_Materno"),
        Nombres = RdStr(rd, "Nombres"),
        Nombre_Completo = RdStrN(rd, "Nombre_Completo"),
        Fecha_Ultima_Visita = RdDtN(rd, "Fecha_Ultima_Visita"),
    };
}
