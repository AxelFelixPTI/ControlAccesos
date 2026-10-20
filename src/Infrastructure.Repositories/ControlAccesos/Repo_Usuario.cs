// ============================================================
// Usuarios — llama a ERP_USUARIO_CREAR, _ACTUALIZAR, _LISTAR, _DETALLE, _PASSWORD_ACTUALIZAR y _LICENCIA_AGREGAR/_QUITAR
// (schema CAF_GOVERNANCE). Parámetros copiados de las firmas reales.
// ============================================================

using System.Data.Common;
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

    // ══ Gestión desde la web ═════════════════════════════════════

    public async Task<Result<List<Dto_Usuario_Lista>>> ListarAsync(string? filtroTexto, string? codigoLicencia, bool incluirEliminados, CancellationToken ct = default)
    {
        try
        {
            var l = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_USUARIO_LISTAR",
                bind: p =>
                {
                    AddStr(p, "HV_Filtro_Texto", filtroTexto);
                    AddStr(p, "HV_Codigo_Licencia", codigoLicencia);
                    AddChar1(p, "HV_Incluir_Eliminados", incluirEliminados ? "Y" : "N");
                },
                map: MapUsuarioLista,
                ct: ct);
            return Result<List<Dto_Usuario_Lista>>.Ok(l);
        }
        catch (Exception ex) { return Result<List<Dto_Usuario_Lista>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<Dto_Usuario_Lista?>> DetalleAsync(long idUsuario, CancellationToken ct = default)
    {
        try
        {
            var u = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_USUARIO_DETALLE",
                bind: p => AddLongReq(p, "HV_ID_Usuario", idUsuario),
                map: MapUsuarioLista,
                ct: ct);
            return Result<Dto_Usuario_Lista?>.Ok(u);
        }
        catch (Exception ex) { return Result<Dto_Usuario_Lista?>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<ResultSp> ActualizarAsync(Dto_Usuario_Actualizar dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_USUARIO_ACTUALIZAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Usuario", dto.ID_Usuario);
                AddStrReq(p, "HV_Correo", dto.Correo);
                AddLongReq(p, "HV_ID_Catalogo_Tipo_Documento", dto.ID_Catalogo_Tipo_Documento);
                AddStrReq(p, "HV_Numero_Documento", dto.Numero_Documento);
                AddStrReq(p, "HV_Apellido_Paterno", dto.Apellido_Paterno);
                AddStr(p, "HV_Apellido_Materno", dto.Apellido_Materno);
                AddStrReq(p, "HV_Nombres", dto.Nombres);
                AddLong(p, "HV_ID_Personal", dto.ID_Personal);
                AddStr(p, "HV_Empresa_Externa", dto.Empresa_Externa);
                AddChar1(p, "HV_Activo", dto.Activo ? "Y" : "N");
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    public async Task<ResultSp> LicenciaQuitarAsync(long idUsuarioLicencia, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_USUARIO_LICENCIA_QUITAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Usuario_Licencia", idUsuarioLicencia);
                AddLongReq(p, "HV_UsuarioID_Update", usuarioId);
            },
            ct: ct);
    }

    // ══ Autenticación ════════════════════════════════════════════

    public async Task<Result<Dto_Usuario_Credencial?>> AutenticacionPorCorreoAsync(string correo, CancellationToken ct = default)
    {
        try
        {
            var u = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_USUARIO_AUTENTICACION_POR_CORREO",
                bind: p => AddStrReq(p, "HV_Correo", correo),
                map: MapCredencial,
                ct: ct);
            return Result<Dto_Usuario_Credencial?>.Ok(u);
        }
        catch (Exception ex) { return Result<Dto_Usuario_Credencial?>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<Dto_Usuario_Token?>> AutenticacionPorTokenAsync(string tokenHash, CancellationToken ct = default)
    {
        try
        {
            var u = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_USUARIO_AUTENTICACION_POR_TOKEN",
                bind: p => AddStrReq(p, "HV_Token_Hash", tokenHash),
                map: MapUsuarioToken,
                ct: ct);
            return Result<Dto_Usuario_Token?>.Ok(u);
        }
        catch (Exception ex) { return Result<Dto_Usuario_Token?>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<ResultSp<Dto_Login_Registro>> LoginRegistrarAsync(long idUsuario, bool exitoso, int maxIntentos, int minutosBloqueo, CancellationToken ct = default)
    {
        var r = await _exec.EjecutarEscrituraConSalidasAsync(
            clave: Conn,
            procedimiento: "ERP_USUARIO_LOGIN_REGISTRAR",
            columnasSalida: new[] { "HV_Intentos_Fallidos", "HV_Bloqueado_Hasta" },
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Usuario", idUsuario);
                AddChar1(p, "HV_Exitoso", exitoso ? "Y" : "N");
                AddLongReq(p, "HV_Max_Intentos", maxIntentos);
                AddLongReq(p, "HV_Minutos_Bloqueo", minutosBloqueo);
            },
            ct: ct);
        if (!r.Ok || r.Data is null) return ResultSp<Dto_Login_Registro>.Fail(r.Codigo, r.Mensaje);
        var bloqueo = r.Data["HV_Bloqueado_Hasta"];
        return ResultSp<Dto_Login_Registro>.Success(new Dto_Login_Registro
        {
            Intentos_Fallidos = Convert.ToInt64(r.Data["HV_Intentos_Fallidos"] ?? 0L),
            Bloqueado_Hasta = bloqueo is null || bloqueo is DBNull ? null : Convert.ToDateTime(bloqueo),
        }, r.Mensaje);
    }

    public async Task<ResultSp> TokenRegistrarAsync(long idUsuario, string tokenHash, int minutosVigencia, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_USUARIO_TOKEN_REGISTRAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Usuario", idUsuario);
                AddStrReq(p, "HV_Token_Hash", tokenHash);
                AddLongReq(p, "HV_Minutos_Vigencia", minutosVigencia);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    public async Task<Result<List<Dto_Usuario_Licencia>>> LicenciasListarAsync(long idUsuario, CancellationToken ct = default)
    {
        try
        {
            var l = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_USUARIO_LICENCIA_LISTAR_POR_PADRE",
                bind: p => AddLongReq(p, "HV_ID_Usuario", idUsuario),
                map: MapUsuarioLicencia,
                ct: ct);
            return Result<List<Dto_Usuario_Licencia>>.Ok(l);
        }
        catch (Exception ex) { return Result<List<Dto_Usuario_Licencia>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<List<Dto_Usuario_Permiso>>> PermisosListarAsync(long idUsuario, CancellationToken ct = default)
    {
        try
        {
            var l = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_USUARIO_PERMISO_LISTAR",
                bind: p => AddLongReq(p, "HV_ID_Usuario", idUsuario),
                map: MapUsuarioPermiso,
                ct: ct);
            return Result<List<Dto_Usuario_Permiso>>.Ok(l);
        }
        catch (Exception ex) { return Result<List<Dto_Usuario_Permiso>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<bool>> PermisoVerificarAsync(long idUsuario, string codigoPermiso, long sedeId, CancellationToken ct = default)
    {
        try
        {
            var l = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_USUARIO_PERMISO_VERIFICAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_ID_Usuario", idUsuario);
                    AddStrReq(p, "HV_Codigo_Permiso", codigoPermiso);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                },
                map: rd => RdBool(rd, "Tiene"),
                ct: ct);
            return Result<bool>.Ok(l.Count > 0 && l[0]);
        }
        catch (Exception ex) { return Result<bool>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    // ── Mapeos ───────────────────────────────────────────────
    private static Dto_Usuario_Lista MapUsuarioLista(DbDataReader rd) => new()
    {
        ID_Usuario = RdLong(rd, "ID_Usuario"),
        Correo = RdStr(rd, "Correo"),
        ID_Catalogo_Tipo_Documento = RdLong(rd, "ID_Catalogo_Tipo_Documento"),
        Tipo_Documento = RdStrN(rd, "Tipo_Documento"),
        Numero_Documento = RdStr(rd, "Numero_Documento"),
        Apellido_Paterno = RdStr(rd, "Apellido_Paterno"),
        Apellido_Materno = RdStrN(rd, "Apellido_Materno"),
        Nombres = RdStr(rd, "Nombres"),
        Nombre_Completo = RdStr(rd, "Nombre_Completo"),
        ID_Personal = RdLongN(rd, "ID_Personal"),
        Area = RdStrN(rd, "Area"),
        Empresa_Externa = RdStrN(rd, "Empresa_Externa"),
        Licencias = RdStrN(rd, "Licencias"),
        Tiene_Password = RdBool(rd, "Tiene_Password"),
        Password_Requiere_Cambio = RdBool(rd, "Password_Requiere_Cambio"),
        Bloqueado = RdBool(rd, "Bloqueado"),
        Ultimo_Acceso = RdDtN(rd, "Ultimo_Acceso"),
        Activo = RdBool(rd, "Activo"),
    };

    private static Dto_Usuario_Credencial MapCredencial(DbDataReader rd) => new()
    {
        ID_Usuario = RdLong(rd, "ID_Usuario"),
        Correo = RdStr(rd, "Correo"),
        Nombre_Completo = RdStr(rd, "Nombre_Completo"),
        Password_Hash = RdStrN(rd, "Password_Hash"),
        Password_Requiere_Cambio = RdBool(rd, "Password_Requiere_Cambio"),
        Intentos_Fallidos = RdLong(rd, "Intentos_Fallidos"),
        Bloqueado_Hasta = RdDtN(rd, "Bloqueado_Hasta"),
        Activo = RdBool(rd, "Activo"),
    };

    private static Dto_Usuario_Token MapUsuarioToken(DbDataReader rd) => new()
    {
        ID_Usuario = RdLong(rd, "ID_Usuario"),
        Correo = RdStr(rd, "Correo"),
        Nombre_Completo = RdStr(rd, "Nombre_Completo"),
    };

    private static Dto_Usuario_Licencia MapUsuarioLicencia(DbDataReader rd) => new()
    {
        ID_Usuario_Licencia = RdLong(rd, "ID_Usuario_Licencia"),
        ID_Catalogo_Licencia = RdLong(rd, "ID_Catalogo_Licencia"),
        Codigo_Licencia = RdStr(rd, "Codigo_Licencia"),
        Licencia = RdStr(rd, "Licencia"),
        ID_Catalogo_Sede = RdLong(rd, "ID_Catalogo_Sede"),
        Codigo_Sede = RdStr(rd, "Codigo_Sede"),
        Sede = RdStr(rd, "Sede"),
    };

    private static Dto_Usuario_Permiso MapUsuarioPermiso(DbDataReader rd) => new()
    {
        Codigo_Permiso = RdStr(rd, "Codigo_Permiso"),
        Descripcion = RdStr(rd, "Descripcion"),
        Modulo = RdStrN(rd, "Modulo"),
        Sedes = RdStrN(rd, "Sedes"),
        Roles = RdStrN(rd, "Roles"),
    };
}
