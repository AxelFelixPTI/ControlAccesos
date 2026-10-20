// ============================================================
// Pantalla Personal (administración): catálogo de personal del grupo. De aquí sale el responsable de atención.
// Estar en este catálogo no da acceso al sistema (eso es un usuario). Se desactiva, no se elimina.
// Valida el formulario; las reglas de negocio viven en los procedimientos.
// ============================================================

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Web.ControlAccesos.Models;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize, ExigirPermiso(PersonalController.Permiso)]
public sealed class PersonalController : Controller
{
    public const string Permiso = "PER_CAF_ADMIN_TRABAJADORES";
    private const string SedeCodigo = "VES";

    private readonly ISrv_Personal _personal;
    private readonly ISrv_Usuario _usuarios;
    private readonly ISrv_Catalogo_Sede _sedes;
    private readonly ISrv_Catalogo_Tipo_Documento _tiposDoc;
    private readonly ISrv_Catalogo_Area _areas;
    private readonly ISrv_Catalogo_Cargo _cargos;
    private readonly ISrv_Catalogo_Empresa_Grupo _empresas;

    public PersonalController(ISrv_Personal personal, ISrv_Usuario usuarios, ISrv_Catalogo_Sede sedes, ISrv_Catalogo_Tipo_Documento tiposDoc,
        ISrv_Catalogo_Area areas, ISrv_Catalogo_Cargo cargos, ISrv_Catalogo_Empresa_Grupo empresas)
    {
        _personal = personal; _usuarios = usuarios; _sedes = sedes; _tiposDoc = tiposDoc; _areas = areas; _cargos = cargos; _empresas = empresas;
    }

    [HttpGet]
    public IActionResult Index() => View();

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        var r = await _personal.ListarAsync(ct: ct);
        if (!r.Success) return Json(new { success = false, message = r.Message });
        var filas = r.Data!.Select(p => new
        {
            id = p.ID_Personal, apellidoPaterno = p.Apellido_Paterno, apellidoMaterno = p.Apellido_Materno, nombres = p.Nombres,
            nombreCompleto = p.Nombre_Completo, tipoDocId = p.ID_Catalogo_Tipo_Documento, tipoDoc = p.Tipo_Documento, doc = p.Numero_Documento,
            areaId = p.ID_Catalogo_Area, area = p.Area, cargoId = p.ID_Catalogo_Cargo, cargo = p.Cargo, empresaId = p.ID_Catalogo_Empresa_Grupo,
            empresa = p.Empresa, correo = p.Correo, anexo = p.Anexo, tieneUsuario = p.Tiene_Usuario == "Y", activo = p.Activo == "Y",
        });
        return Json(new { success = true, data = filas });
    }

    [HttpGet]
    public async Task<IActionResult> Opciones(CancellationToken ct)
    {
        var td = await _tiposDoc.ObtenerDropdownAsync(ct);
        var ar = await _areas.ObtenerDropdownAsync(ct);
        var ca = await _cargos.ObtenerDropdownAsync(ct);
        var em = await _empresas.ObtenerDropdownAsync(ct);
        var falla = new[] { td.Success ? null : td.Message, ar.Success ? null : ar.Message, ca.Success ? null : ca.Message, em.Success ? null : em.Message }.FirstOrDefault(x => x is not null);
        if (falla is not null) return Json(new { success = false, message = falla });
        return Json(new
        {
            success = true,
            data = new
            {
                tiposDoc = td.Data!.Select(x => new { id = x.ID_Catalogo, texto = x.Codigo }),
                areas = ar.Data!.Select(x => new { id = x.ID_Catalogo, texto = x.Descripcion }),
                cargos = ca.Data!.Select(x => new { id = x.ID_Catalogo, texto = x.Descripcion }),
                empresas = em.Data!.Select(x => new { id = x.ID_Catalogo, texto = x.Descripcion }),
            }
        });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Guardar([FromBody] PersonalGuardarVM m, CancellationToken ct)
    {
        var sedes = await _sedes.ListarAsync(false, ct);
        var sede = sedes.Success ? sedes.Data!.FirstOrDefault(x => x.Codigo == SedeCodigo)?.ID_Catalogo : null;
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");

        var dto = new Dto_Personal
        {
            ID_Catalogo_Tipo_Documento = m.TipoDocId, Numero_Documento = (m.Doc ?? string.Empty).Trim(),
            Apellido_Paterno = (m.ApellidoPaterno ?? string.Empty).Trim(), Apellido_Materno = Vacio(m.ApellidoMaterno),
            Nombres = (m.Nombres ?? string.Empty).Trim(), ID_Catalogo_Area = m.AreaId, ID_Catalogo_Cargo = m.CargoId is > 0 ? m.CargoId : null,
            ID_Catalogo_Empresa_Grupo = m.EmpresaId, ID_Catalogo_Sede = sede.Value, Correo = Vacio(m.Correo), Anexo = Vacio(m.Anexo),
            Activo = m.Activo ? "Y" : "N",
        };

        var usuario = User.UsuarioId();
        if (m.Id == 0)
        {
            var c = await _personal.CrearAsync(dto, usuario, ct);
            return Json(new { success = c.Success, message = c.Message, errors = Errores(c) });
        }

        // Regla de la pantalla: no se desactiva a una persona del personal que tiene una cuenta de usuario activa.
        var vinculado = await UsuarioDeAsync(m.Id, ct);
        if (!m.Activo && vinculado is { Activo: true })
            return Falla("Tiene una cuenta de usuario activa: desactive primero el usuario.");

        var a = await _personal.ActualizarAsync(m.Id, dto, usuario, ct);
        if (!a.Success) return Json(new { success = false, message = a.Message, errors = Errores(a) });

        // El usuario guarda una copia de nombre, documento y correo: se mantiene al día con el personal.
        if (vinculado is not null)
        {
            var u = await _usuarios.ActualizarAsync(new Dto_Usuario_Actualizar
            {
                ID_Usuario = vinculado.ID_Usuario, Correo = dto.Correo ?? vinculado.Correo, ID_Catalogo_Tipo_Documento = dto.ID_Catalogo_Tipo_Documento,
                Numero_Documento = dto.Numero_Documento, Apellido_Paterno = dto.Apellido_Paterno, Apellido_Materno = dto.Apellido_Materno,
                Nombres = dto.Nombres, ID_Personal = m.Id, Empresa_Externa = null, Activo = vinculado.Activo,
            }, usuario, ct);
            if (!u.Success)
                return Json(new { success = true, message = "Personal guardado, pero no se pudo actualizar su cuenta de usuario: " + u.Message });
        }
        return Json(new { success = true, message = a.Message });
    }

    // ── apoyo ──────────────────────────────────────────────────────────────────────────────────
    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });
    private static string? Vacio(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
    private static object Errores(Shared.Results.Result r) => r.Errors.Select(e => new { field = e.Field, message = e.Message });

    private async Task<Dto_Usuario_Lista?> UsuarioDeAsync(long idPersonal, CancellationToken ct)
    {
        var l = await _usuarios.ListarAsync(null, null, false, ct);
        return l.Success ? l.Data!.FirstOrDefault(x => x.ID_Personal == idPersonal) : null;
    }
}
