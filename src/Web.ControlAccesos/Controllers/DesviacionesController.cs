// ============================================================
// Pantalla del coordinador «Desviaciones»: pasos del registro en portería que no se cumplieron y cómo se resolvieron.
// El coordinador revisa y da su conformidad. Las reglas (quién puede, qué estado) viven en los procedimientos.
// ============================================================

using System.Globalization;
using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Shared.Results;
using Web.ControlAccesos.Models;
using Web.ControlAccesos.Seguridad;

namespace Web.ControlAccesos.Controllers;

[Authorize, ExigirPermiso("PER_CAF_DESVIACION_CONFORMIDAD")]
public sealed class DesviacionesController : Controller
{
    private const string SedeCodigo = "VES";

    private readonly ISrv_Desviacion _des;
    private readonly ISrv_Porteria _por;
    private readonly ISrv_Catalogo_Sede _sedes;

    public DesviacionesController(ISrv_Desviacion des, ISrv_Porteria por, ISrv_Catalogo_Sede sedes) { _des = des; _por = por; _sedes = sedes; }

    [HttpGet] public IActionResult Index() => View();

    [HttpGet]
    public async Task<IActionResult> Lista(string? estado, string? texto, CancellationToken ct)
    {
        var sede = await SedeIdAsync(ct);
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        var u = User.UsuarioId();
        var est = estado == "REVISADA" ? "REVISADA" : "POR_REVISAR";
        var r = await _des.ListarAsync(u, new Dto_Filtro_Desviaciones { ID_Catalogo_Sede = sede.Value, Estado = est, Texto = Vacio(texto) }, ct);
        if (!r.Success) return Falla(r.Message);
        var c = await _des.ContadoresAsync(u, sede.Value, ct);
        return Json(new
        {
            success = true,
            porRevisar = c.Success ? c.Data!.Por_Revisar : 0,
            revisadas = c.Success ? c.Data!.Revisadas : 0,
            data = r.Data!.Select(d => new
            {
                id = d.ID_Desviacion, codigo = d.Codigo, tipo = d.Tipo_Movimiento, resultado = d.Resultado,
                fecha = d.Fecha_Hora.ToString("yyyy-MM-dd"), hora = d.Fecha_Hora.ToString("HH:mm"),
                persona = d.Persona_Nombre, doc = d.Numero_Documento, empresa = d.Empresa_Visitante, solicitud = d.Codigo_Solicitud,
                descripcion = d.Descripcion, tratamiento = d.Tratamiento, coordinador = d.Coordinador_Nombre, estado = d.Estado,
                fechaConformidad = d.Fecha_Conformidad?.ToString("yyyy-MM-dd HH:mm"),
            })
        });
    }

    [HttpGet]
    public async Task<IActionResult> Detalle(long id, CancellationToken ct)
    {
        var u = User.UsuarioId();
        var r = await _des.DetalleAsync(u, id, ct);
        if (!r.Success) return Falla(r.Message);
        var d = r.Data!;
        var it = await _por.RegistroChecklistListarAsync(u, d.ID_Registro_Acceso, ct);
        return Json(new
        {
            success = true,
            data = new
            {
                id = d.ID_Desviacion, codigo = d.Codigo, solicitud = d.Codigo_Solicitud, tipo = d.Tipo_Movimiento, resultado = d.Resultado,
                fecha = d.Fecha_Hora.ToString("yyyy-MM-dd"), hora = d.Fecha_Hora.ToString("HH:mm"), persona = d.Persona_Nombre, doc = d.Numero_Documento,
                empresa = d.Empresa_Visitante, descripcion = d.Descripcion, tratamiento = d.Tratamiento, tratamientoDetalle = d.Tratamiento_Detalle,
                consultado = d.Coordinador_Nombre, registradoPor = d.Registrado_Por_Nombre, estado = d.Estado,
                conformidadPor = d.Conformidad_Nombre, fechaConformidad = d.Fecha_Conformidad?.ToString("yyyy-MM-dd HH:mm"), comentario = d.Comentario_Conformidad,
                incidencia = d.ID_Incidencia, puedeConformidad = d.Puede_Dar_Conformidad, motivoNoConformidad = d.Motivo_No_Conformidad,
                items = it.Success ? it.Data!.Select(i => (object)new { texto = i.Descripcion, cumple = i.Cumple, critico = i.Es_Critico }).ToList() : new List<object>(),
            }
        });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Conformidad([FromBody] ConformidadVM m, CancellationToken ct)
    {
        var r = await _des.ConformidadDarAsync(m.Id, Vacio(m.Comentario), User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Success ? "Conformidad registrada." : r.Message, errors = r.Errors.Select(e => new { field = e.Field, message = e.Message }) });
    }

    private async Task<long?> SedeIdAsync(CancellationToken ct)
    {
        var l = await _sedes.ListarAsync(false, ct);
        var s = l.Success ? l.Data!.FirstOrDefault(x => x.Codigo == SedeCodigo) : null;
        return s?.ID_Catalogo;
    }
    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });
    private static string? Vacio(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
}
