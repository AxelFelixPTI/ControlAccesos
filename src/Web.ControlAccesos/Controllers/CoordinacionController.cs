// ============================================================
// Pantalla del coordinador «Solicitudes»: bandeja (Por decidir / Todas) y revisión por persona.
// La decisión se toma persona por persona; las reglas (quién decide qué paso, orden de pasos, fechas) viven en los
// procedimientos, que además dicen qué personas puede decidir el usuario y con qué paso.
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

[Authorize, ExigirPermiso("PER_CAF_SOLICITUD_APROBAR", "PER_CAF_SOLICITUD_VER_TODAS")]
public sealed class CoordinacionController : Controller
{
    private readonly ISrv_Solicitud _sol;
    private readonly ISrv_Solicitud_Decision _decision;
    private readonly ISrv_Solicitud_Persona _solPer;
    private readonly ISrv_Persona_Externa _externas;
    private readonly ISrv_Catalogo_Tipo_Documento _tiposDoc;

    public CoordinacionController(ISrv_Solicitud sol, ISrv_Solicitud_Decision decision, ISrv_Solicitud_Persona solPer,
        ISrv_Persona_Externa externas, ISrv_Catalogo_Tipo_Documento tiposDoc)
    {
        _sol = sol; _decision = decision; _solPer = solPer; _externas = externas; _tiposDoc = tiposDoc;
    }

    [HttpGet] public IActionResult Index() => View();

    [HttpGet]
    public async Task<IActionResult> Lista(string? pestana, string? empresa, string? solicitante, string? persona, string? fecha, string? estado, CancellationToken ct)
    {
        var u = User.UsuarioId();
        var r = await _sol.BandejaListarAsync(u, new Dto_Filtro_Bandeja
        {
            Pestana = pestana == "POR_DECIDIR" ? "POR_DECIDIR" : "TODAS", Empresa = Vacio(empresa), Solicitante = Vacio(solicitante),
            Persona = Vacio(persona), Fecha = DateTime.TryParseExact(fecha, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d : null,
            Estado = Vacio(estado),
        }, ct);
        if (!r.Success) return Falla(r.Message);
        var c = await _sol.ContadoresAsync(u, null, ct);
        return Json(new
        {
            success = true,
            porDecidir = c.Success ? c.Data!.Por_Decidir_Solicitudes : 0,
            data = r.Data!.Select(s => new
            {
                id = s.ID_Solicitud, codigo = s.Codigo, fecha = s.Fecha_Hora_Prevista.ToString("yyyy-MM-dd"), hora = s.Fecha_Hora_Prevista.ToString("HH:mm"),
                esHoy = s.Es_Hoy, empresa = s.Empresa_Visitante, solicitante = s.Solicitante_Nombre, estado = s.Estado, total = s.Total_Personas,
                autorizadas = s.Autorizadas, observadas = s.Observadas, pendientes = s.Pendientes, rechazadas = s.Rechazadas, porDecidirMis = s.Por_Decidir_Mis,
                personas = s.Personas_Nombres,
            })
        });
    }

    [HttpGet]
    public async Task<IActionResult> Revisar(long id, CancellationToken ct)
    {
        var u = User.UsuarioId();
        var d = await _sol.DetalleAsync(u, id, ct);
        if (!d.Success) return Falla(d.Message);
        var per = await _sol.PersonasListarAsync(u, id, ct);
        var his = await _sol.HistorialListarAsync(u, id, ct);
        if (!per.Success) return Falla(per.Message);
        if (!his.Success) return Falla(his.Message);
        var s = d.Data!;
        return Json(new
        {
            success = true,
            data = new
            {
                id = s.ID_Solicitud, codigo = s.Codigo, sede = s.Sede, estado = s.Estado, fecha = s.Fecha_Hora_Prevista.ToString("yyyy-MM-dd"), hora = s.Fecha_Hora_Prevista.ToString("HH:mm"),
                empresa = s.Empresa_Visitante, motivo = s.Motivo, motivoDetalle = s.Motivo_Detalle, zonas = s.Zonas_Nombres, observaciones = s.Observaciones,
                responsable = s.Responsable_Nombre, responsableArea = s.Responsable_Area, solicitante = s.Solicitante_Nombre, solicitanteCorreo = s.Solicitante_Correo,
                exigeSctr = s.Exige_SCTR, exigeEpp = s.Exige_EPP, motivoCancelacion = s.Motivo_Cancelacion, codigoOrigen = s.Codigo_Origen,
                puedeDecidir = s.Puede_Decidir,
                // Se puede agregar una persona ya aprobada mientras la solicitud siga abierta y la visita no haya pasado.
                puedeAgregar = s.Puede_Decidir && s.Estado != "CANCELADA" && s.Fecha_Hora_Prevista.Date >= DateTime.Today,
                personas = per.Data!.Select(p => new
                {
                    id = p.ID_Solicitud_Persona, personaId = p.ID_Persona_Externa, tipoDoc = p.Tipo_Documento, doc = p.Numero_Documento, nombre = p.Nombre_Completo,
                    aprobacion = p.Aprobacion, mensaje = p.Aprobacion_Mensaje, aprobadoPor = p.Aprobado_Por_Nombre, estado = p.Estado, origen = p.Origen,
                    puedeDecidir = p.Puede_Decidir,
                }),
                historial = his.Data!.Select(h => new { fecha = h.Fecha_Evento.ToString("yyyy-MM-dd HH:mm"), texto = h.Accion_Texto, detalle = h.Detalle, usuario = h.Usuario_Nombre }),
            }
        });
    }

    /// <summary>
    /// Registra la decisión. Cada persona se decide en el primer paso que el usuario puede decidir para ella; si las
    /// personas elegidas tienen pasos distintos, se hace una llamada por paso. Si se indicó qué hacer con las que
    /// quedaron sin marcar, se decide también sobre ellas.
    /// </summary>
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Decidir([FromBody] DecidirVM m, CancellationToken ct)
    {
        var u = User.UsuarioId();
        var per = await _sol.PersonasListarAsync(u, m.SolicitudId, ct);
        if (!per.Success) return Falla(per.Message);
        var decidibles = per.Data!.Where(p => p.Puede_Decidir).ToList();

        var pedido = new List<(string Decision, string? Mensaje, List<Dto_Solicitud_Persona> Personas)>();
        var marcadas = decidibles.Where(p => m.PersonasIds.Contains(p.ID_Solicitud_Persona)).ToList();
        if (marcadas.Count == 0) return Falla("Elija al menos una persona.");
        pedido.Add((m.Decision, m.Mensaje, marcadas));
        var resto = decidibles.Where(p => !m.PersonasIds.Contains(p.ID_Solicitud_Persona)).ToList();
        if (!string.IsNullOrWhiteSpace(m.DecisionResto) && resto.Count > 0)
            pedido.Add((m.DecisionResto!, m.MensajeResto, resto));

        int hechas = 0;
        foreach (var (decision, mensaje, personas) in pedido)
        {
            // Agrupa por el paso que le toca decidir a este usuario (primero de la lista, ya ordenado por la base).
            var porPaso = personas.GroupBy(p => PrimerPaso(p.Pasos_Mis_Decidir));
            foreach (var g in porPaso)
            {
                if (g.Key <= 0) return Falla("No se encontró el paso que le corresponde decidir.");
                var r = await _decision.DecidirAsync(new Dto_Solicitud_Decidir
                {
                    ID_Solicitud = m.SolicitudId, ID_Tipo_Acceso_Paso_Aprobacion = g.Key, Decision = decision, Mensaje = Vacio(mensaje),
                    IDs_Solicitud_Persona = g.Select(p => p.ID_Solicitud_Persona).ToList(),
                }, u, ct);
                if (!r.Success)
                    return Json(new { success = false, message = (hechas > 0 ? "Se registró una parte, pero: " : "") + r.Message, errors = Errores(r), parcial = hechas > 0 });
                hechas += g.Count();
            }
        }
        return Json(new { success = true, message = "Decisión registrada.", data = new { personas = hechas } });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> AgregarAprobada([FromBody] AgregarAprobadaVM m, CancellationToken ct)
    {
        var r = await _solPer.AgregarAprobadaAsync(m.SolicitudId, m.PersonaId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    // ── personas externas (mismo comportamiento que en Mis solicitudes) ───────────────────────────
    [HttpGet]
    public async Task<IActionResult> Opciones(CancellationToken ct)
    {
        var td = await _tiposDoc.ObtenerDropdownAsync(ct);
        if (!td.Success) return Falla(td.Message);
        return Json(new { success = true, data = new { tiposDoc = td.Data!.Select(x => new { id = x.ID_Catalogo, texto = x.Codigo }) } });
    }

    [HttpGet]
    public async Task<IActionResult> PersonasBuscar(string? q, CancellationToken ct)
    {
        var r = await _externas.BuscarAsync(q ?? string.Empty, ct);
        if (!r.Success) return Json(new { success = false, message = r.Message, errors = Errores(r) });
        return Json(new { success = true, data = r.Data!.Select(p => new { id = p.ID_Persona_Externa, tipoDocId = p.ID_Catalogo_Tipo_Documento, tipoDoc = p.Tipo_Documento, doc = p.Numero_Documento, apellidoPaterno = p.Apellido_Paterno, apellidoMaterno = p.Apellido_Materno, nombres = p.Nombres, nombreCompleto = p.Nombre_Completo }) });
    }

    [HttpGet]
    public async Task<IActionResult> PersonaPorDocumento(long tipoDocId, string? doc, CancellationToken ct)
    {
        var r = await _externas.PorDocumentoAsync(tipoDocId, doc ?? string.Empty, ct);
        if (!r.Success) return Json(new { success = false, message = r.Message, errors = Errores(r) });
        var p = r.Data;
        return Json(new { success = true, data = p is null ? null : new { id = p.ID_Persona_Externa, apellidoPaterno = p.Apellido_Paterno, apellidoMaterno = p.Apellido_Materno, nombres = p.Nombres, nombreCompleto = p.Nombre_Completo } });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> PersonaGuardar([FromBody] PersonaExternaVM m, CancellationToken ct)
    {
        var dto = new Dto_Persona_Externa
        {
            ID_Persona_Externa = m.Id, ID_Catalogo_Tipo_Documento = m.TipoDocId, Numero_Documento = (m.Doc ?? string.Empty).Trim(),
            Apellido_Paterno = (m.ApellidoPaterno ?? string.Empty).Trim(), Apellido_Materno = Vacio(m.ApellidoMaterno), Nombres = (m.Nombres ?? string.Empty).Trim(),
        };
        long id = m.Id;
        if (m.Id > 0)
        {
            var a = await _externas.ActualizarAsync(m.Id, dto, User.UsuarioId(), ct);
            if (!a.Success) return Json(new { success = false, message = a.Message, errors = Errores(a) });
        }
        else
        {
            var c = await _externas.CrearAsync(dto, User.UsuarioId(), ct);
            if (!c.Success) return Json(new { success = false, message = c.Message, errors = Errores(c) });
            id = c.Data;
        }
        var nombre = (dto.Apellido_Paterno + " " + (dto.Apellido_Materno ?? "")).Trim() + ", " + dto.Nombres;
        return Json(new { success = true, data = new { id, nombreCompleto = nombre, doc = dto.Numero_Documento } });
    }

    // ── apoyo ──────────────────────────────────────────────────────────────────────────────────
    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });
    private static string? Vacio(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
    private static object Errores(Result r) => r.Errors.Select(e => new { field = e.Field, message = e.Message });
    private static long PrimerPaso(string? lista)
        => long.TryParse((lista ?? "").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).FirstOrDefault(), out var n) ? n : 0;
}
