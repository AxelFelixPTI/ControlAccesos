// ============================================================
// Personal — llama a ERP_PERSONAL_LISTAR / _DETALLE / _CREAR / _ACTUALIZAR (schema CAF_GOVERNANCE).
// Parámetros copiados de las firmas reales.
// ============================================================

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Personal : RepoHelpers, IRepo_Personal
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Gobierno;

    public Repo_Personal(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Personal>>> ListarAsync(string? filtroNombre, long? idArea, long? idSede, bool incluirEliminados, CancellationToken ct = default)
    {
        try
        {
            var l = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_PERSONAL_LISTAR",
                bind: p =>
                {
                    AddStr(p, "HV_Filtro_Nombre", filtroNombre);
                    AddLong(p, "HV_ID_Catalogo_Area", idArea);
                    AddLong(p, "HV_ID_Catalogo_Sede", idSede);
                    AddChar1(p, "HV_Incluir_Eliminados", incluirEliminados ? "Y" : "N");
                },
                map: Mapear,
                ct: ct);
            return Result<List<Dto_Personal>>.Ok(l);
        }
        catch (Exception ex) { return Result<List<Dto_Personal>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<Dto_Personal?>> DetalleAsync(long id, CancellationToken ct = default)
    {
        try
        {
            var d = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_PERSONAL_DETALLE",
                bind: p => AddLongReq(p, "HV_ID_Personal", id),
                map: Mapear,
                ct: ct);
            return Result<Dto_Personal?>.Ok(d);
        }
        catch (Exception ex) { return Result<Dto_Personal?>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<ResultSp<long>> CrearAsync(Dto_Personal dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraConIdAsync(
            clave: Conn,
            procedimiento: "ERP_PERSONAL_CREAR",
            columnaId: "HV_ID_Personal_Result",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Catalogo_Tipo_Documento", dto.ID_Catalogo_Tipo_Documento);
                AddStrReq(p, "HV_Numero_Documento", dto.Numero_Documento);
                AddStrReq(p, "HV_Apellido_Paterno", dto.Apellido_Paterno);
                AddStr(p, "HV_Apellido_Materno", dto.Apellido_Materno);
                AddStrReq(p, "HV_Nombres", dto.Nombres);
                AddLongReq(p, "HV_ID_Catalogo_Area", dto.ID_Catalogo_Area);
                AddLong(p, "HV_ID_Catalogo_Cargo", dto.ID_Catalogo_Cargo);
                AddLongReq(p, "HV_ID_Catalogo_Empresa_Grupo", dto.ID_Catalogo_Empresa_Grupo);
                AddLongReq(p, "HV_ID_Catalogo_Sede", dto.ID_Catalogo_Sede);
                AddStr(p, "HV_Correo", dto.Correo);
                AddStr(p, "HV_Anexo", dto.Anexo);
                AddChar1(p, "HV_Activo", dto.Activo ?? "Y");
                AddLongReq(p, "HV_UsuarioID_Create", usuarioId);
            },
            ct: ct);
    }

    public async Task<ResultSp> ActualizarAsync(long id, Dto_Personal dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_PERSONAL_ACTUALIZAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Personal", id);
                AddLongReq(p, "HV_ID_Catalogo_Tipo_Documento", dto.ID_Catalogo_Tipo_Documento);
                AddStrReq(p, "HV_Numero_Documento", dto.Numero_Documento);
                AddStrReq(p, "HV_Apellido_Paterno", dto.Apellido_Paterno);
                AddStr(p, "HV_Apellido_Materno", dto.Apellido_Materno);
                AddStrReq(p, "HV_Nombres", dto.Nombres);
                AddLongReq(p, "HV_ID_Catalogo_Area", dto.ID_Catalogo_Area);
                AddLong(p, "HV_ID_Catalogo_Cargo", dto.ID_Catalogo_Cargo);
                AddLongReq(p, "HV_ID_Catalogo_Empresa_Grupo", dto.ID_Catalogo_Empresa_Grupo);
                AddLongReq(p, "HV_ID_Catalogo_Sede", dto.ID_Catalogo_Sede);
                AddStr(p, "HV_Correo", dto.Correo);
                AddStr(p, "HV_Anexo", dto.Anexo);
                AddChar1(p, "HV_Activo", dto.Activo ?? "Y");
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    private static Dto_Personal Mapear(DbDataReader rd) => new()
    {
        ID_Personal = RdLong(rd, "ID_Personal"),
        ID_Catalogo_Tipo_Documento = RdLong(rd, "ID_Catalogo_Tipo_Documento"),
        Tipo_Documento = RdStrN(rd, "Tipo_Documento"),
        Numero_Documento = RdStr(rd, "Numero_Documento"),
        Apellido_Paterno = RdStr(rd, "Apellido_Paterno"),
        Apellido_Materno = RdStrN(rd, "Apellido_Materno"),
        Nombres = RdStr(rd, "Nombres"),
        Nombre_Completo = RdStrN(rd, "Nombre_Completo"),
        ID_Catalogo_Area = RdLong(rd, "ID_Catalogo_Area"),
        Area = RdStrN(rd, "Area"),
        ID_Catalogo_Cargo = RdLongN(rd, "ID_Catalogo_Cargo"),
        Cargo = RdStrN(rd, "Cargo"),
        ID_Catalogo_Empresa_Grupo = RdLong(rd, "ID_Catalogo_Empresa_Grupo"),
        Empresa = RdStrN(rd, "Empresa"),
        ID_Catalogo_Sede = RdLong(rd, "ID_Catalogo_Sede"),
        Sede = RdStrN(rd, "Sede"),
        Correo = RdStrN(rd, "Correo"),
        Anexo = RdStrN(rd, "Anexo"),
        Tiene_Usuario = RdStrN(rd, "Tiene_Usuario"),
        Activo = RdStrN(rd, "Activo"),
        Eliminado = RdStrN(rd, "Eliminado"),
    };
}
