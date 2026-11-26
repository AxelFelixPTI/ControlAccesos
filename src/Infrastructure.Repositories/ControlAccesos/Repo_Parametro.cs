// D-238: parámetros del sistema. Rutinas: ERP_CAF_PARAMETRO_LISTAR / ERP_CAF_PARAMETRO_GUARDAR (la validación por clave vive en la rutina).
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Parametro : RepoHelpers, IRepo_Parametro
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Parametro(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Parametro>>> ListarAsync(CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PARAMETRO_LISTAR",
                bind: _ => { },
                map: rd => new Dto_Parametro
                {
                    Clave = RdStr(rd, "Clave"),
                    Valor = RdStr(rd, "Valor"),
                    Descripcion = RdStr(rd, "Descripcion"),
                },
                ct: ct);
            return Result<List<Dto_Parametro>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Parametro>>.Fail(ex.Message); }
    }

    public Task<ResultSp> GuardarAsync(string clave, string valor, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PARAMETRO_GUARDAR",
            bind: p =>
            {
                AddStrReq(p, "HV_Clave", clave);
                AddStr(p, "HV_Valor", valor);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
}
