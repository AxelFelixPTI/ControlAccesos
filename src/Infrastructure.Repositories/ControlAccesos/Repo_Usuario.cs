// ============================================================
// Usuarios — llama a ERP_USUARIO_CREAR, ERP_USUARIO_PASSWORD_ACTUALIZAR y ERP_USUARIO_LICENCIA_AGREGAR
// (schema CAF_GOVERNANCE). Parámetros copiados de las firmas reales.
// ============================================================

using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Usuario : RepoHelpers, IRepo_Usuario
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Gobierno;

    public Repo_Usuario(EjecutorSp exec) => _exec = exec;

    public async Task<ResultSp<long>> CrearAsync(Dto_Usuario_Crear dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraConIdAsync(
            clave: Conn,
            procedimiento: "ERP_USUARIO_CREAR",
            columnaId: "HV_ID_Usuario_Result",
            bind: p =>
            {
                AddStrReq(p, "HV_Correo", dto.Correo);
                AddLongReq(p, "HV_ID_Catalogo_Tipo_Documento", dto.ID_Catalogo_Tipo_Documento);
                AddStrReq(p, "HV_Numero_Documento", dto.Numero_Documento);
                AddStrReq(p, "HV_Apellido_Paterno", dto.Apellido_Paterno);
                AddStr(p, "HV_Apellido_Materno", dto.Apellido_Materno);
                AddStrReq(p, "HV_Nombres", dto.Nombres);
                AddLong(p, "HV_ID_Personal", dto.ID_Personal);
                AddStr(p, "HV_Empresa_Externa", dto.Empresa_Externa);
                AddChar1(p, "HV_Activo", "Y");
                AddLongReq(p, "HV_UsuarioID_Create", usuarioId);
            },
            ct: ct);
    }

    public async Task<ResultSp> PasswordActualizarAsync(long idUsuario, string passwordHash, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_USUARIO_PASSWORD_ACTUALIZAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Usuario", idUsuario);
                AddStrReq(p, "HV_Password_Hash", passwordHash);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    public async Task<ResultSp<long>> LicenciaAgregarAsync(long idUsuario, long idLicencia, long idSede, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraConIdAsync(
            clave: Conn,
            procedimiento: "ERP_USUARIO_LICENCIA_AGREGAR",
            columnaId: "HV_ID_Usuario_Licencia_Result",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Usuario", idUsuario);
                AddLongReq(p, "HV_ID_Catalogo_Licencia", idLicencia);
                AddLongReq(p, "HV_ID_Catalogo_Sede", idSede);
                AddLongReq(p, "HV_UsuarioID_Create", usuarioId);
            },
            ct: ct);
    }
}
