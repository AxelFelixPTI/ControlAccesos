// D-236: empresas a las que da atención cada usuario de Almacén. Rutinas: ERP_CAF_ALMACEN_EMPRESA_LISTAR / _GUARDAR.
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Almacen_Empresa : RepoHelpers, IRepo_Almacen_Empresa
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Almacen_Empresa(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Almacen_Empresa>>> ListarAsync(CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_ALMACEN_EMPRESA_LISTAR",
                bind: _ => { },
                map: rd => new Dto_Almacen_Empresa
                {
                    ID_Usuario  = RdLong(rd, "ID_Usuario"),
                    Nombre      = RdStr(rd, "Nombre"),
                    Cargo       = RdStrN(rd, "Cargo"),
                    IDs_Empresa = RdStr(rd, "IDs_Empresa"),
                    Empresas    = RdStr(rd, "Empresas"),
                },
                ct: ct);
            return Result<List<Dto_Almacen_Empresa>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Almacen_Empresa>>.Fail(ex.Message); }
    }

    public async Task<ResultSp> GuardarAsync(long usuarioAlmacenId, IReadOnlyList<long> empresasIds, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_ALMACEN_EMPRESA_GUARDAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Usuario", usuarioAlmacenId);
                AddStr(p, "HV_IDs_Empresa", string.Join(",", empresasIds.Distinct()));
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }
}
