// ============================================================
// Pantalla «Tipos de ingreso» (dentro de Administración · Catálogos): alta, edición, disponibilidad y orden de los tipos de ingreso,
// y lista de los subtipos de persona que define cada flujo (ej. Proveedor: Transportista y Ayudante de descarga).
// Un tipo NUEVO usa el flujo estándar de visitante: al crearlo se le copian los pasos de aprobación y el checklist de «Visita externa».
// Un flujo con pantalla o reglas propias (contratista, proveedor) sigue siendo trabajo de desarrollo.
// Solo valida el formulario y arma el DTO; las reglas de negocio viven en los procedimientos (a través del servicio).
// ============================================================

using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Shared.Results;
using Web.ControlAccesos.Models;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize, ExigirPermiso(CatalogosController.Permiso)]
public sealed class TiposIngresoController : Controller
{
    // Tipos con flujo propio en el código: su código y si requieren aprobación no se tocan desde la pantalla.
    private static readonly string[] Propios = { "VISITA_EXTERNA", "CONTRATISTA", "PROVEEDOR", "INTERNO_VISITANTE" };

    private readonly ISrv_Catalogo_Tipo_Acceso _tipos;

    public TiposIngresoController(ISrv_Catalogo_Tipo_Acceso tipos) => _tipos = tipos;

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        var r = await _tipos.ListarAdminAsync(ct);
        if (!r.Success) return Json(new { success = false, message = r.Message });
        var filas = r.Data!.Select(x => new
        {
            id = x.ID_Catalogo_Tipo_Acceso, codigo = x.Codigo, descripcion = x.Descripcion, requiereAprobacion = x.Requiere_Aprobacion == "Y",
            disponible = x.Disponible == "Y", orden = x.Orden, activo = x.Activo == "Y", subtipos = x.Subtipos, pasos = x.Pasos, items = x.Items,
            solicitudes = x.Solicitudes, propio = Propios.Contains(x.Codigo),
        }).ToList();
        return Json(new { success = true, message = "", data = filas });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Guardar([FromBody] TipoIngresoGuardarVM m, CancellationToken ct)
    {
        var descripcion = (m.Descripcion ?? string.Empty).Trim();
        if (descripcion.Length == 0) return Falla("Escriba el nombre del tipo de ingreso.");
        if (descripcion.Length > 500) return Falla("El nombre no puede superar 500 caracteres.");
        if (m.Orden is < 0 or > 9999) return Falla("El orden debe estar entre 0 y 9999.");

        var todos = await _tipos.ListarAsync(true, ct);
        if (!todos.Success) return Falla(todos.Message);
        var lista = todos.Data!;
        if (lista.Any(x => x.Eliminado != "Y" && x.ID_Catalogo != m.Id && Norm(x.Descripcion) == Norm(descripcion)))
            return Falla("Ya existe un tipo de ingreso con ese nombre.");

        var usuario = User.UsuarioId();
        Dto_Catalogo_Universal dto;
        if (m.Id == 0)
        {
            dto = new Dto_Catalogo_Universal
            {
                Codigo = CodigoUnico(descripcion, lista),
                Orden = m.Orden ?? (lista.Select(x => x.Orden).DefaultIfEmpty(0).Max() + 10),
                Requiere_Aprobacion = m.RequiereAprobacion ? "Y" : "N",
            };
        }
        else
        {
            var actual = lista.FirstOrDefault(x => x.ID_Catalogo == m.Id);
            if (actual is null) return Falla("Tipo de ingreso no encontrado.");
            dto = actual;
            if (m.Orden is not null) dto.Orden = m.Orden.Value;
            if (!Propios.Contains(actual.Codigo)) dto.Requiere_Aprobacion = m.RequiereAprobacion ? "Y" : "N";
        }
        dto.Descripcion = descripcion;
        dto.Disponible = m.Disponible ? "Y" : "N";
        dto.Activo = m.Activo ? "Y" : "N";

        if (m.Id == 0)
        {
            var c = await _tipos.CrearAsync(dto, usuario, ct);
            if (!c.Success) return Json(new { success = false, message = c.Message, errors = c.Errors.Select(e => new { field = e.Field, message = e.Message }) });
            var p = await _tipos.PrepararAsync(c.Data, usuario, ct);
            if (!p.Success) return Falla("El tipo se creó, pero no se pudieron copiar los pasos y el checklist de Visita externa: " + p.Message);
            return Json(new { success = true, message = "" });
        }
        var a = await _tipos.ActualizarAsync(m.Id, dto, usuario, ct);
        return Json(new { success = a.Success, message = a.Message, errors = a.Errors.Select(e => new { field = e.Field, message = e.Message }) });
    }

    // ── apoyo ──────────────────────────────────────────────────────────────────────────────────
    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });

    private static string Norm(string s) => Quitar(s).Trim().ToLowerInvariant();

    private static string Quitar(string s)
    {
        var d = s.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder();
        foreach (var c in d) if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark) sb.Append(c);
        return sb.ToString().Normalize(NormalizationForm.FormC);
    }

    /// <summary>MAYUSCULAS_CON_GUION_BAJO, sin tildes, hasta 50 caracteres; si ya existe se agrega _2, _3...</summary>
    private static string CodigoUnico(string texto, List<Dto_Catalogo_Universal> lista)
    {
        var baseCod = Regex.Replace(Quitar(texto).ToUpperInvariant(), "[^A-Z0-9]+", "_").Trim('_');
        if (baseCod.Length == 0) baseCod = "TIPO";
        if (baseCod.Length > 44) baseCod = baseCod[..44].TrimEnd('_');
        var cod = baseCod; var n = 2;
        while (lista.Any(x => string.Equals(x.Codigo, cod, StringComparison.OrdinalIgnoreCase))) cod = baseCod + "_" + n++;
        return cod;
    }
}
