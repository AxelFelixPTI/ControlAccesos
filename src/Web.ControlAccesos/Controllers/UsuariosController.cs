// ============================================================
// Pantalla Usuarios y roles (administración): quién entra al sistema y con qué roles (licencias LIC_CAF_*) en la sede VES.
// - Un usuario puede estar vinculado a una persona del personal (sus datos vienen del catálogo de Personal) o ser externo
//   (por ejemplo, vigilancia de una empresa contratista).
// - Un usuario nuevo NO recibe contraseña del administrador: se le entrega un enlace de un solo uso para que él la defina.
// - Las reglas (último administrador, no desactivarse a sí mismo, duplicados) viven en los procedimientos.
// ============================================================

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Shared.Results;
using Web.ControlAccesos.Models;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize, ExigirPermiso(UsuariosController.Permiso)]
public sealed class UsuariosController : Controller
{
    public const string Permiso = "PER_CAF_ADMIN_USUARIOS";
    private const string SedeCodigo = "VES";
    private const string PrefijoLicencia = "LIC_CAF_";
    private const int MinutosEnlace = 3 * 24 * 60; // el enlace para definir contraseña vale 3 días

    private readonly ISrv_Usuario _usuarios;
    private readonly ISrv_Auth _auth;
    private readonly ISrv_Personal _personal;
    private readonly ISrv_Catalogo_Sede _sedes;
    private readonly ISrv_Catalogo_Licencia _licencias;
    private readonly ISrv_Catalogo_Tipo_Documento _tiposDoc;

    public UsuariosController(ISrv_Usuario usuarios, ISrv_Auth auth, ISrv_Personal personal, ISrv_Catalogo_Sede sedes,
        ISrv_Catalogo_Licencia licencias, ISrv_Catalogo_Tipo_Documento tiposDoc)
    {
        _usuarios = usuarios; _auth = auth; _personal = personal; _sedes = sedes; _licencias = licencias; _tiposDoc = tiposDoc;
    }

    [HttpGet]
    public IActionResult Index() => View();

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        var r = await _usuarios.ListarAsync(null, null, false, ct);
        if (!r.Success) return Json(new { success = false, message = r.Message });
        var filas = r.Data!.Select(u => new
        {
            id = u.ID_Usuario, nombreCompleto = u.Nombre_Completo, correo = u.Correo,
            apellidoPaterno = u.Apellido_Paterno, apellidoMaterno = u.Apellido_Materno, nombres = u.Nombres,
            tipoDocId = u.ID_Catalogo_Tipo_Documento, tipoDoc = u.Tipo_Documento, doc = u.Numero_Documento,
            personalId = u.ID_Personal, area = u.Area, empresaExterna = u.Empresa_Externa,
            roles = RolesEnSede(u.Licencias), activo = u.Activo, tienePassword = u.Tiene_Password, bloqueado = u.Bloqueado,
        });
        return Json(new { success = true, data = filas });
    }

    [HttpGet]
    public async Task<IActionResult> Opciones(CancellationToken ct)
    {
        var td = await _tiposDoc.ObtenerDropdownAsync(ct);
        var lic = await _licencias.ListarAsync(false, ct);
        var per = await _personal.ListarAsync(ct: ct);
        var falla = new[] { td.Success ? null : td.Message, lic.Success ? null : lic.Message, per.Success ? null : per.Message }.FirstOrDefault(x => x is not null);
        if (falla is not null) return Json(new { success = false, message = falla });
        return Json(new
        {
            success = true,
            data = new
            {
                tiposDoc = td.Data!.Select(x => new { id = x.ID_Catalogo, texto = x.Codigo }),
                roles = RolesGestionados(lic.Data!).Select(x => new { id = x.ID_Catalogo, codigo = x.Codigo, nombre = Nombre(x.Descripcion), descripcion = Detalle(x.Descripcion) }),
                personal = per.Data!.Select(p => new { id = p.ID_Personal, texto = p.Nombre_Completo + " · " + p.Area, tieneUsuario = p.Tiene_Usuario == "Y", activo = p.Activo == "Y" }),
            }
        });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Guardar([FromBody] UsuarioGuardarVM m, CancellationToken ct)
    {
        if (m.Roles.Count == 0) return Falla("Marque al menos un rol.");

        var lic = await _licencias.ListarAsync(false, ct);
        var sedes = await _sedes.ListarAsync(false, ct);
        if (!lic.Success) return Falla(lic.Message);
        var sede = sedes.Success ? sedes.Data!.FirstOrDefault(x => x.Codigo == SedeCodigo)?.ID_Catalogo : null;
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        var gestionadas = RolesGestionados(lic.Data!).Select(x => x.ID_Catalogo).ToList();
        if (m.Roles.Any(r => !gestionadas.Contains(r))) return Falla("Rol no válido.");

        // Datos de la persona: del personal vinculado, o del formulario si es externo.
        string correo, apPat, nombres, doc; string? apMat, empresa; long tipoDoc;
        if (m.PersonalId is > 0)
        {
            var p = await _personal.DetalleAsync(m.PersonalId.Value, ct);
            if (!p.Success || p.Data is null) return Falla("La persona vinculada no existe en Personal.");
            if (string.IsNullOrWhiteSpace(p.Data.Correo)) return Falla("La persona no tiene correo registrado. Complételo primero en Personal.");
            correo = p.Data.Correo!; apPat = p.Data.Apellido_Paterno; apMat = p.Data.Apellido_Materno; nombres = p.Data.Nombres;
            doc = p.Data.Numero_Documento; tipoDoc = p.Data.ID_Catalogo_Tipo_Documento; empresa = null;
        }
        else
        {
            if (string.IsNullOrWhiteSpace(m.EmpresaExterna)) return Falla("Vincule a una persona del personal o indique la empresa externa.");
            correo = (m.Correo ?? string.Empty).Trim(); apPat = (m.ApellidoPaterno ?? string.Empty).Trim(); apMat = Vacio(m.ApellidoMaterno);
            nombres = (m.Nombres ?? string.Empty).Trim(); doc = (m.Doc ?? string.Empty).Trim(); tipoDoc = m.TipoDocId; empresa = m.EmpresaExterna.Trim();
        }

        var admin = User.UsuarioId();
        long idUsuario = m.Id;
        if (m.Id == 0)
        {
            var c = await _usuarios.CrearAsync(new Dto_Usuario_Crear
            {
                Correo = correo, ID_Catalogo_Tipo_Documento = tipoDoc, Numero_Documento = doc, Apellido_Paterno = apPat,
                Apellido_Materno = apMat, Nombres = nombres, ID_Personal = m.PersonalId is > 0 ? m.PersonalId : null, Empresa_Externa = empresa,
            }, admin, ct);
            if (!c.Success) return Json(new { success = false, message = c.Message, errors = Errores(c) });
            idUsuario = c.Data;
            if (!m.Activo)
            {
                var d = await _usuarios.ActualizarAsync(Actualizar(idUsuario, correo, tipoDoc, doc, apPat, apMat, nombres, m.PersonalId, empresa, false), admin, ct);
                if (!d.Success) return Json(new { success = false, id = idUsuario, message = "El usuario se creó, pero no se pudo dejar inactivo: " + d.Message });
            }
        }
        else
        {
            var a = await _usuarios.ActualizarAsync(Actualizar(idUsuario, correo, tipoDoc, doc, apPat, apMat, nombres, m.PersonalId, empresa, m.Activo), admin, ct);
            if (!a.Success) return Json(new { success = false, message = a.Message, errors = Errores(a) });
        }

        var s = await _usuarios.SincronizarLicenciasAsync(idUsuario, sede.Value, m.Roles, gestionadas, admin, ct);
        if (!s.Success)
            return Json(new { success = false, id = idUsuario, message = (m.Id == 0 ? "El usuario se creó, pero los roles no se pudieron asignar: " : "Los datos se guardaron, pero los roles no se pudieron actualizar: ") + s.Message });

        if (m.Id != 0) return Json(new { success = true, id = idUsuario, message = "Usuario actualizado." });

        // Usuario nuevo: enlace para que defina su contraseña.
        var enlace = await CrearEnlaceAsync(idUsuario, admin, ct);
        return Json(new { success = true, id = idUsuario, message = "Usuario creado.", enlace = enlace.Data, enlaceError = enlace.Success ? null : enlace.Message });
    }

    /// <summary>Nuevo enlace para definir contraseña (usuario nuevo que no lo usó, o que olvidó la suya). Invalida el anterior.</summary>
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Enlace([FromBody] IdVM m, CancellationToken ct)
    {
        var d = await _usuarios.DetalleAsync(m.Id, ct);
        if (!d.Success || d.Data is null) return Falla("Usuario no encontrado.");
        if (!d.Data.Activo) return Falla("El usuario está inactivo. Actívelo primero.");
        var e = await CrearEnlaceAsync(m.Id, User.UsuarioId(), ct);
        return e.Success ? Json(new { success = true, enlace = e.Data }) : Falla(e.Message);
    }

    // ── apoyo ──────────────────────────────────────────────────────────────────────────────────
    private async Task<Result<string>> CrearEnlaceAsync(long idUsuario, long admin, CancellationToken ct)
    {
        var t = await _auth.EmitirTokenAsync(idUsuario, MinutosEnlace, admin, ct);
        if (!t.Success) return Result<string>.Fail(t.Message);
        var url = Url.Action("DefinirPassword", "Cuenta", new { token = t.Data }, Request.Scheme);
        return Result<string>.Ok(url ?? string.Empty);
    }

    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });
    private static string? Vacio(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
    private static object Errores(Result r) => r.Errors.Select(e => new { field = e.Field, message = e.Message });

    private static Dto_Usuario_Actualizar Actualizar(long id, string correo, long tipoDoc, string doc, string apPat, string? apMat, string nombres, long? personalId, string? empresa, bool activo) => new()
    {
        ID_Usuario = id, Correo = correo, ID_Catalogo_Tipo_Documento = tipoDoc, Numero_Documento = doc, Apellido_Paterno = apPat,
        Apellido_Materno = apMat, Nombres = nombres, ID_Personal = personalId is > 0 ? personalId : null, Empresa_Externa = empresa, Activo = activo,
    };

    private static IEnumerable<Dto_Catalogo_Universal> RolesGestionados(IEnumerable<Dto_Catalogo_Universal> licencias)
        => licencias.Where(l => l.Codigo.StartsWith(PrefijoLicencia, StringComparison.Ordinal) && l.Activo != "N").OrderBy(l => l.Orden);

    /// <summary>De «LIC_CAF_ADMIN@VES, LIC_CAF_SOLICITANTE@MAG» devuelve los códigos de licencia de la sede VES.</summary>
    private static string[] RolesEnSede(string? licencias)
        => (licencias ?? string.Empty).Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(x => x.Split('@')).Where(p => p.Length == 2 && p[1] == SedeCodigo).Select(p => p[0]).ToArray();

    private static string Nombre(string descripcion) => descripcion.Contains(':') ? descripcion[..descripcion.IndexOf(':')].Trim() : descripcion;
    private static string Detalle(string descripcion) => descripcion.Contains(':') ? descripcion[(descripcion.IndexOf(':') + 1)..].Trim() : string.Empty;
}
