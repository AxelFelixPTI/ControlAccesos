// ============================================================
// Pantalla «Checklist de portería» (dentro de Administración · Catálogos): crear, editar, activar/desactivar los ítems que
// responde el vigilante y elegir a qué tipos de ingreso se ofrece cada uno, con su etapa, condición, criticidad y orden.
// Solo valida el formulario y arma el DTO; las reglas de negocio viven en los procedimientos (a través del servicio).
// Se protege con el mismo permiso que Catálogos.
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
public sealed class ChecklistPorteriaController : Controller
{
    private static readonly string[] Etapas = { "INGRESO", "SALIDA" };
    // «Solo transportista / solo ayudante» ya no se ofrecen: ahora se elige el subtipo al asignar el ítem a un tipo (D-232).
    // Un ítem que todavía tiene una de esas condiciones antiguas la conserva (se comprueba al guardar).
    private static readonly string[] Condiciones =
        { "SIEMPRE", "ZONA_EXIGE_SCTR", "ZONA_EXIGE_EPP", "TRAE_EQUIPOS", "TRAE_HERRAMIENTAS" };
    private static readonly string[] CondicionesAntiguas = { "SOLO_PRINCIPAL", "SOLO_AYUDANTE" };

    private readonly ISrv_Catalogo_Item_Checklist _items;
    private readonly ISrv_Catalogo_Tipo_Acceso _tipos;   // tipos y subtipos

    public ChecklistPorteriaController(ISrv_Catalogo_Item_Checklist items, ISrv_Catalogo_Tipo_Acceso tipos)
    {
        _items = items; _tipos = tipos;
    }

    [HttpGet]
    public async Task<IActionResult> Listar(CancellationToken ct)
    {
        var r = await _items.ListarAdminAsync(ct);
        if (!r.Success) return Json(new { success = false, message = r.Message });
        var t = await _tipos.ObtenerDropdownAsync(ct);
        if (!t.Success) return Json(new { success = false, message = t.Message });

        var s = await _tipos.ListarSubtiposAsync(true, ct);   // D-234: también los desactivados, para no perder lo ya asignado
        if (!s.Success) return Json(new { success = false, message = s.Message });

        var filas = r.Data!.Select(x => new
        {
            id = x.ID_Catalogo_Item_Checklist, codigo = x.Codigo, descripcion = x.Descripcion, ayuda = x.Ayuda,
            etapa = x.Etapa, condicion = x.Condicion, esCritico = x.Es_Critico == "Y", orden = x.Orden, activo = x.Activo == "Y",
            usos = x.Usos,
            tipos = (x.Tipos_IDs ?? string.Empty).Split(',', StringSplitOptions.RemoveEmptyEntries).Select(Par).ToList(),
        }).ToList();
        var tipos = t.Data!.Select(x => new { id = x.ID_Catalogo, codigo = x.Codigo, nombre = x.Descripcion }).ToList();
        var subtipos = s.Data!.Select(x => new { id = x.ID_Tipo_Acceso_Subtipo, tipoId = x.ID_Catalogo_Tipo_Acceso, nombre = x.Descripcion, activo = x.Activo == "Y" }).ToList();
        return Json(new { success = true, message = "", data = new { items = filas, tipos, subtipos } });
    }

    /// <summary>«3» o «3:7» (tipo y subtipo opcional) → objeto para la pantalla.</summary>
    private static object Par(string t)
    {
        var p = t.Split(':');
        return new { tipo = long.Parse(p[0]), subtipo = p.Length > 1 ? (long?)long.Parse(p[1]) : null };
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Guardar([FromBody] ChecklistItemGuardarVM m, CancellationToken ct)
    {
        var descripcion = (m.Descripcion ?? string.Empty).Trim();
        var ayuda = string.IsNullOrWhiteSpace(m.Ayuda) ? null : m.Ayuda.Trim();
        var etapa = (m.Etapa ?? string.Empty).ToUpperInvariant();
        var condicion = (m.Condicion ?? string.Empty).ToUpperInvariant();
        if (descripcion.Length == 0) return Falla("Escriba lo que debe verificar el vigilante.");
        if (descripcion.Length > 500) return Falla("El texto no puede superar 500 caracteres.");
        if (ayuda is not null && ayuda.Length > 500) return Falla("La ayuda no puede superar 500 caracteres.");
        if (!Etapas.Contains(etapa)) return Falla("Elija la etapa (ingreso o salida).");
        if (!Condiciones.Contains(condicion) && !CondicionesAntiguas.Contains(condicion)) return Falla("Elija cuándo aplica el ítem.");
        if (m.Orden is < 0 or > 9999) return Falla("El orden debe estar entre 0 y 9999.");

        var todos = await _items.ListarAsync(true, ct);
        if (!todos.Success) return Falla(todos.Message);
        var lista = todos.Data!;
        if (lista.Any(x => x.Eliminado != "Y" && x.ID_Catalogo != m.Id && x.Etapa == etapa && Norm(x.Descripcion) == Norm(descripcion)))
            return Falla("Ya existe un ítem con ese texto en esa etapa.");

        var usuario = User.UsuarioId();
        Dto_Catalogo_Universal dto;
        if (m.Id == 0)
        {
            dto = new Dto_Catalogo_Universal
            {
                Codigo = CodigoUnico((etapa == "INGRESO" ? "ING_" : "SAL_") + descripcion, lista),
                Orden = m.Orden ?? (lista.Where(x => x.Etapa == etapa).Select(x => x.Orden).DefaultIfEmpty(0).Max() + 10),
            };
        }
        else
        {
            var actual = lista.FirstOrDefault(x => x.ID_Catalogo == m.Id);
            if (actual is null) return Falla("Ítem no encontrado.");
            dto = actual;
            if (m.Orden is not null) dto.Orden = m.Orden.Value;
            if (CondicionesAntiguas.Contains(condicion) && actual.Condicion != condicion) return Falla("Elija cuándo aplica el ítem.");
        }
        if (m.Id == 0 && CondicionesAntiguas.Contains(condicion)) return Falla("Elija cuándo aplica el ítem.");
        dto.Descripcion = descripcion; dto.Ayuda = ayuda; dto.Etapa = etapa; dto.Condicion = condicion;
        dto.Es_Critico = m.EsCritico ? "Y" : "N"; dto.Activo = m.Activo ? "Y" : "N";

        long id = m.Id;
        if (m.Id == 0)
        {
            var c = await _items.CrearAsync(dto, usuario, ct);
            if (!c.Success) return Respuesta(c);
            id = c.Data;
        }
        else
        {
            var a = await _items.ActualizarAsync(m.Id, dto, usuario, ct);
            if (!a.Success) return Respuesta(a);
        }

        // D-234: un tipo puede repetirse con varios subtipos
        var asig = await _items.AsignarTiposAsync(id, m.Tipos.Select(t => (t.Tipo, t.Subtipo)).Distinct().ToList(), usuario, ct);
        if (!asig.Success) return Falla("El ítem se guardó, pero no se pudo asignar a los tipos de ingreso: " + asig.Message);
        return Json(new { success = true, message = "" });
    }

    // ── apoyo ──────────────────────────────────────────────────────────────────────────────────
    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });

    private IActionResult Respuesta(Result r)
        => Json(new { success = r.Success, message = r.Message, errors = r.Errors.Select(e => new { field = e.Field, message = e.Message }) });

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
        if (baseCod.Length > 44) baseCod = baseCod[..44].TrimEnd('_');
        var cod = baseCod; var n = 2;
        while (lista.Any(x => string.Equals(x.Codigo, cod, StringComparison.OrdinalIgnoreCase))) cod = baseCod + "_" + n++;
        return cod;
    }
}
