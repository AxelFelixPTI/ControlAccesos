// ============================================================
// Pantalla «Almacén por empresa» (dentro de Administración · Catálogos): a qué empresas del grupo puede dar atención cada usuario
// de Almacén (D-236). No depende de qué empresa contrató a la persona: el Coordinador de Almacén, por ejemplo, atiende las 4.
// Solo arma la lista y el formulario; las reglas viven en los procedimientos. Mismo permiso que Catálogos.
// ============================================================

using Application.Contracts.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Web.ControlAccesos.Models;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize, ExigirPermiso(CatalogosController.Permiso)]
public sealed class AlmacenEmpresaController : Controller
{
    private readonly ISrv_Almacen_Empresa _almacen;
    private readonly ISrv_Catalogo_Empresa_Grupo _empresas;

    public AlmacenEmpresaController(ISrv_Almacen_Empresa almacen, ISrv_Catalogo_Empresa_Grupo empresas) { _almacen = almacen; _empresas = empresas; }

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        var r = await _almacen.ListarAsync(ct);
        if (!r.Success) return Json(new { success = false, message = r.Message });
        var emp = await _empresas.ObtenerDropdownAsync(ct);
        return Json(new
        {
            success = true,
            data = new
            {
                empresas = (emp.Data ?? new()).Select(x => new { id = x.ID_Catalogo, texto = x.Descripcion }),
                usuarios = r.Data!.Select(u => new
                {
                    id = u.ID_Usuario, nombre = u.Nombre, cargo = u.Cargo,
                    empresasIds = u.IDs_Empresa.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(long.Parse).ToList(), empresas = u.Empresas,
                }),
            }
        });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Guardar([FromBody] AlmacenEmpresaGuardarVM m, CancellationToken ct)
    {
        if (m.UsuarioId <= 0) return Json(new { success = false, message = "Seleccione al usuario de Almacén." });
        var r = await _almacen.GuardarAsync(m.UsuarioId, (m.EmpresasIds ?? new()).Where(x => x > 0).ToList(), User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message });
    }
}
