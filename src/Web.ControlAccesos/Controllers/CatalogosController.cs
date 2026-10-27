// ============================================================
// Pantalla de Catálogos (administración): zonas de VES, motivos de visita, tratamientos de desviación y tipos de incidencia.
// Solo valida el formulario y arma el DTO; las reglas de negocio viven en los procedimientos (a través de los servicios).
// El elemento «Otro» de cada lista es fijo: no se edita.
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
public sealed class CatalogosController : Controller
{
    public const string Permiso = "PER_CAF_ADMIN_CATALOGOS";
    private const string SedeCodigo = "VES";
    private static readonly string[] ResIng = { "INGRESA", "INGRESA_RESTRINGIDO", "NO_INGRESA" };
    private static readonly string[] ResSal = { "SALE", "SALE_RETIENE_ELEMENTO" };

    private readonly ISrv_Catalogo_Sede _sedes;
    private readonly ISrv_Catalogo_Zona_Acceso _zonas;
    private readonly ISrv_Catalogo_Motivo_Visita _motivos;
    private readonly ISrv_Catalogo_Tratamiento_Desviacion _tratamientos;
    private readonly ISrv_Catalogo_Tipo_Incidencia _incidencias;
    private readonly ISrv_Catalogo_Area _areas;
    private readonly ISrv_Catalogo_Cargo _cargos;

    public CatalogosController(ISrv_Catalogo_Sede sedes, ISrv_Catalogo_Zona_Acceso zonas, ISrv_Catalogo_Motivo_Visita motivos,
        ISrv_Catalogo_Tratamiento_Desviacion tratamientos, ISrv_Catalogo_Tipo_Incidencia incidencias,
        ISrv_Catalogo_Area areas, ISrv_Catalogo_Cargo cargos)
    {
        _sedes = sedes; _zonas = zonas; _motivos = motivos; _tratamientos = tratamientos; _incidencias = incidencias; _areas = areas; _cargos = cargos;
    }

    [HttpGet]
    public IActionResult Index() => View();

    [HttpGet]
    public async Task<IActionResult> Listar(string tipo, CancellationToken ct)
    {
        var r = await CargarAsync(tipo, ct);
        return r.Success
            ? Json(new { success = true, message = "", data = r.Data!.Select(Fila).ToList() })
            : Json(new { success = false, message = r.Message });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Guardar([FromBody] CatalogoGuardarVM m, CancellationToken ct)
    {
        var descripcion = (m.Descripcion ?? string.Empty).Trim();
        if (descripcion.Length == 0) return Falla("Escriba el nombre.");
        if (descripcion.Length > 500) return Falla("El nombre no puede superar 500 caracteres.");

        var tipo = (m.Tipo ?? string.Empty).ToLowerInvariant();
        string? tipoZona = null, resIng = null, resSal = null;
        if (tipo == "zona")
        {
            tipoZona = (m.TipoZona ?? string.Empty).ToUpperInvariant();
            if (tipoZona != "ADMINISTRATIVA" && tipoZona != "OPERATIVA") return Falla("Elija el tipo de zona.");
        }
        if (tipo == "tratamiento")
        {
            resIng = string.IsNullOrWhiteSpace(m.ResultadoIngreso) ? null : m.ResultadoIngreso;
            resSal = string.IsNullOrWhiteSpace(m.ResultadoSalida) ? null : m.ResultadoSalida;
            if (resIng is not null && !ResIng.Contains(resIng)) return Falla("Efecto al ingreso no válido.");
            if (resSal is not null && !ResSal.Contains(resSal)) return Falla("Efecto a la salida no válido.");
            if (resIng is null && resSal is null) return Falla("El tratamiento debe aplicar al ingreso, a la salida o a ambos.");
        }

        var existentes = await CargarAsync(tipo, ct, incluirTodos: true);
        if (!existentes.Success) return Falla(existentes.Message);
        var lista = existentes.Data!;
        if (lista.Any(x => x.Eliminado != "Y" && x.ID_Catalogo != m.Id && Norm(x.Descripcion) == Norm(descripcion)))
            return Falla("Ya existe uno con ese nombre.");

        var usuario = User.UsuarioId();
        Dto_Catalogo_Universal dto;
        if (m.Id == 0)
        {
            dto = new Dto_Catalogo_Universal
            {
                Codigo = CodigoUnico(descripcion, lista),
                Orden = lista.Where(x => x.Es_Otro != "Y").Select(x => x.Orden).DefaultIfEmpty(0).Max() + 1,
                Es_Otro = "N",
            };
        }
        else
        {
            var actual = lista.FirstOrDefault(x => x.ID_Catalogo == m.Id);
            if (actual is null) return Falla("Registro no encontrado.");
            if (actual.Es_Otro == "Y") return Falla("Este elemento es fijo y no se puede editar.");
            dto = actual;
        }

        dto.Descripcion = descripcion;
        dto.Activo = m.Activo ? "Y" : "N";
        if (tipo == "zona")
        {
            var sede = await IdSedeAsync(ct);
            if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
            dto.ID_Catalogo_Sede = sede;
            dto.Tipo_Zona = tipoZona;
            dto.Exige_SCTR = m.ExigeSctr ? "Y" : "N";
            dto.Exige_EPP = m.ExigeEpp ? "Y" : "N";
        }
        if (tipo == "tratamiento")
        {
            dto.Resultado_Ingreso = resIng;
            dto.Resultado_Salida = resSal;
            dto.Aplica_Ingreso = resIng is null ? "N" : "Y";
            dto.Aplica_Salida = resSal is null ? "N" : "Y";
        }

        Result r = m.Id == 0 ? await CrearAsync(tipo, dto, usuario, ct) : await ActualizarAsync(tipo, m.Id, dto, usuario, ct);
        return Json(new { success = r.Success, message = r.Message, errors = r.Errors.Select(e => new { field = e.Field, message = e.Message }) });
    }

    // ── apoyo ──────────────────────────────────────────────────────────────────────────────────
    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });

    private async Task<long?> IdSedeAsync(CancellationToken ct)
    {
        var s = await _sedes.ListarAsync(false, ct);
        return s.Success ? s.Data!.FirstOrDefault(x => x.Codigo == SedeCodigo)?.ID_Catalogo : null;
    }

    private async Task<Result<List<Dto_Catalogo_Universal>>> CargarAsync(string tipo, CancellationToken ct, bool incluirTodos = false)
    {
        switch ((tipo ?? string.Empty).ToLowerInvariant())
        {
            case "zona":
                var sede = await IdSedeAsync(ct);
                return sede is null
                    ? Result<List<Dto_Catalogo_Universal>>.Fail("No se encontró la sede " + SedeCodigo + ".")
                    : await _zonas.ListarAsync(sede, incluirTodos, ct);
            case "motivo": return await _motivos.ListarAsync(incluirTodos, ct);
            case "tratamiento": return await _tratamientos.ListarAsync(incluirTodos, ct);
            case "incidencia": return await _incidencias.ListarAsync(incluirTodos, ct);
            case "area": return await _areas.ListarAsync(incluirTodos, ct);
            case "cargo": return await _cargos.ListarAsync(incluirTodos, ct);
            default: return Result<List<Dto_Catalogo_Universal>>.Fail("Tipo de catálogo no válido.");
        }
    }

    private Task<Result<long>> CrearAsync(string tipo, Dto_Catalogo_Universal d, long u, CancellationToken ct) => tipo switch
    {
        "zona" => _zonas.CrearAsync(d, u, ct),
        "motivo" => _motivos.CrearAsync(d, u, ct),
        "tratamiento" => _tratamientos.CrearAsync(d, u, ct),
        "area" => _areas.CrearAsync(d, u, ct),
        "cargo" => _cargos.CrearAsync(d, u, ct),
        _ => _incidencias.CrearAsync(d, u, ct),
    };

    private async Task<Result> ActualizarAsync(string tipo, long id, Dto_Catalogo_Universal d, long u, CancellationToken ct) => tipo switch
    {
        "zona" => await _zonas.ActualizarAsync(id, d, u, ct),
        "motivo" => await _motivos.ActualizarAsync(id, d, u, ct),
        "tratamiento" => await _tratamientos.ActualizarAsync(id, d, u, ct),
        "area" => await _areas.ActualizarAsync(id, d, u, ct),
        "cargo" => await _cargos.ActualizarAsync(id, d, u, ct),
        _ => await _incidencias.ActualizarAsync(id, d, u, ct),
    };

    private static CatalogoFila Fila(Dto_Catalogo_Universal d) => new()
    {
        Id = d.ID_Catalogo, Codigo = d.Codigo, Descripcion = d.Descripcion, Activo = d.Activo == "Y", EsOtro = d.Es_Otro == "Y",
        TipoZona = d.Tipo_Zona, ExigeSctr = d.Exige_SCTR == "Y", ExigeEpp = d.Exige_EPP == "Y",
        ResultadoIngreso = d.Resultado_Ingreso, ResultadoSalida = d.Resultado_Salida,
    };

    private static string Norm(string s)
        => Quitar(s).Trim().ToLowerInvariant();

    private static string Quitar(string s)
    {
        var d = s.Normalize(NormalizationForm.FormD);
        var sb = new StringBuilder();
        foreach (var c in d) if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark) sb.Append(c);
        return sb.ToString().Normalize(NormalizationForm.FormC);
    }

    /// <summary>MAYUSCULAS_CON_GUION_BAJO, sin tildes, hasta 50 caracteres; si ya existe se agrega _2, _3...</summary>
    private static string CodigoUnico(string descripcion, List<Dto_Catalogo_Universal> lista)
    {
        var baseCod = Regex.Replace(Quitar(descripcion).ToUpperInvariant(), "[^A-Z0-9]+", "_").Trim('_');
        if (baseCod.Length == 0) baseCod = "ITEM";
        if (baseCod.Length > 44) baseCod = baseCod[..44].TrimEnd('_');
        var cod = baseCod; var n = 2;
        while (lista.Any(x => string.Equals(x.Codigo, cod, StringComparison.OrdinalIgnoreCase))) cod = baseCod + "_" + n++;
        return cod;
    }
}
