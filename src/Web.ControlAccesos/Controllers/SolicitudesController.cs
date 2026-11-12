// ============================================================
// Pantallas del solicitante: Mis solicitudes, Nueva solicitud (asistente de 3 pasos) y Detalle.
// Valida el formulario; las reglas (quién puede editar, cancelar, fechas, personas) viven en los procedimientos,
// que además devuelven las banderas «Puede_*» y el motivo por el que no se puede.
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

[Authorize, ExigirPermiso(SolicitudesController.Permiso, SolicitudesController.PermisoProveedor)]
public sealed class SolicitudesController : Controller
{
    public const string Permiso = "PER_CAF_SOLICITUD_PROPIA";
    /// <summary>Quien puede solicitar proveedores también gestiona sus propias solicitudes (D-224).</summary>
    public const string PermisoProveedor = "PER_CAF_PROVEEDOR_SOLICITAR";
    private const string MotivoContratista = "SERVICIO_CONTRATISTA";

    private readonly ISrv_Solicitud _sol;
    private readonly ISrv_Solicitud_Persona _solPer;
    private readonly ISrv_Persona_Externa _externas;
    private readonly ISrv_Personal _personal;
    private readonly ISrv_Catalogo_Sede _sedes;
    private readonly ISrv_Catalogo_Tipo_Acceso _tipos;
    private readonly ISrv_Catalogo_Motivo_Visita _motivos;
    private readonly ISrv_Catalogo_Zona_Acceso _zonas;
    private readonly ISrv_Catalogo_Tipo_Documento _tiposDoc;
    private readonly ISrv_Catalogo_Empresa_Grupo _empresasGrupo;

    public SolicitudesController(ISrv_Solicitud sol, ISrv_Solicitud_Persona solPer, ISrv_Persona_Externa externas, ISrv_Personal personal,
        ISrv_Catalogo_Sede sedes, ISrv_Catalogo_Tipo_Acceso tipos, ISrv_Catalogo_Motivo_Visita motivos, ISrv_Catalogo_Zona_Acceso zonas,
        ISrv_Catalogo_Tipo_Documento tiposDoc, ISrv_Catalogo_Empresa_Grupo empresasGrupo)
    {
        _sol = sol; _solPer = solPer; _externas = externas; _personal = personal; _sedes = sedes; _tipos = tipos; _motivos = motivos;
        _zonas = zonas; _tiposDoc = tiposDoc; _empresasGrupo = empresasGrupo;
    }

    // ── pantallas ──────────────────────────────────────────────────────────────────────────────
    [HttpGet] public IActionResult Index() => View();

    [HttpGet] public IActionResult Nueva(long? reutilizar) { ViewData["Reutilizar"] = reutilizar ?? 0; return View(); }

    [HttpGet] public IActionResult Detalle(long id) { ViewData["Id"] = id; return View(); }

    // ── Mis solicitudes ────────────────────────────────────────────────────────────────────────
    [HttpGet]
    public async Task<IActionResult> Mis(string? texto, string? estado, string? desde, string? hasta, CancellationToken ct)
    {
        var r = await _sol.MisListarAsync(User.UsuarioId(), new Dto_Filtro_Mis_Solicitudes
        {
            Texto = Vacio(texto), Estado = Vacio(estado), Fecha_Desde = Fecha(desde), Fecha_Hasta = Fecha(hasta),
        }, ct);
        if (!r.Success) return Falla(r.Message);
        var filas = r.Data!.Select(s => new
        {
            id = s.ID_Solicitud, codigo = s.Codigo, fecha = s.Fecha_Hora_Prevista.ToString("yyyy-MM-dd"), hora = s.Fecha_Hora_Prevista.ToString("HH:mm"),
            empresa = s.Empresa_Visitante, tipo = s.Tipo_Acceso, tipoCodigo = s.Tipo_Acceso_Codigo, empresaCodigo = s.Empresa_Destino_Codigo, personasResumen = s.Personas_Resumen,
            estado = s.Estado, responsable = s.Responsable_Nombre, codigoOrigen = s.Codigo_Origen,
            total = s.Total_Personas, autorizadas = s.Autorizadas, observadas = s.Observadas, pendientes = s.Pendientes, rechazadas = s.Rechazadas, retiradas = s.Retiradas,
            puedeEditar = s.Puede_Editar_Datos, motivoNoEditar = s.Motivo_No_Editar_Datos,
            puedeCancelar = s.Puede_Cancelar, motivoNoCancelar = s.Motivo_No_Cancelar, puedeReutilizar = s.Puede_Reutilizar,
        });
        return Json(new { success = true, data = filas });
    }

    // ── Opciones del asistente ─────────────────────────────────────────────────────────────────
    [HttpGet]
    public async Task<IActionResult> Opciones(CancellationToken ct)
    {
        var tipos = await _sol.TiposOpcionesAsync(User.UsuarioId(), ct);
        var sedes = await _sol.SedesOpcionesAsync(User.UsuarioId(), ct);
        var motivos = await _motivos.ListarAsync(false, ct);
        var td = await _tiposDoc.ObtenerDropdownAsync(ct);
        var grupo = await _empresasGrupo.ObtenerDropdownAsync(ct);
        var subs = await _tipos.ListarSubtiposAsync(false, ct);   // D-234: roles de persona activos por tipo
        if (!subs.Success) return Falla(subs.Message);
        var falla = new[] { tipos.Success ? null : tipos.Message, sedes.Success ? null : sedes.Message, motivos.Success ? null : motivos.Message, td.Success ? null : td.Message, grupo.Success ? null : grupo.Message }.FirstOrDefault(x => x is not null);
        if (falla is not null) return Falla(falla);
        if (!tipos.Data!.Any(t => t.Usable)) return Falla("No hay un tipo de ingreso disponible. Pida al administrador que lo habilite en Catálogos.");
        if (sedes.Data!.Count == 0) return Falla("No tiene una sede habilitada para crear solicitudes. Pida al administrador que le asigne la licencia en su sede.");

        // Zonas de cada sede ofrecida (la zona y la cochera dependen de la sede elegida).
        var sedesJson = new List<object>();
        foreach (var s in sedes.Data!)
        {
            var z = await _zonas.ListarAsync(s.ID_Catalogo_Sede, false, ct);
            if (!z.Success) return Falla(z.Message);
            sedesJson.Add(new
            {
                id = s.ID_Catalogo_Sede, codigo = s.Codigo, texto = s.Descripcion, cochera = s.Aplica_Cochera, proveedor = s.Aplica_Proveedor,
                zonas = z.Data!.Where(x => x.Activo == "Y").OrderBy(x => x.Orden).Select(x => new { id = x.ID_Catalogo, texto = x.Descripcion, sctr = x.Exige_SCTR == "Y", epp = x.Exige_EPP == "Y" }),
            });
        }
        return Json(new
        {
            success = true,
            data = new
            {
                tipos = tipos.Data!.Select(t => new { id = t.ID_Catalogo_Tipo_Acceso, codigo = t.Codigo, texto = t.Descripcion, usable = t.Usable, leyenda = t.Leyenda }),
                sedes = sedesJson,
                // El motivo fijo del contratista no se ofrece a los visitantes.
                motivos = motivos.Data!.Where(m => m.Activo == "Y" && m.Codigo != MotivoContratista).OrderBy(m => m.Orden).Select(m => new { id = m.ID_Catalogo, texto = m.Descripcion, esOtro = m.Es_Otro == "Y" }),
                tiposDoc = td.Data!.Select(x => new { id = x.ID_Catalogo, texto = x.Codigo }),
                // Proveedor: empresas del grupo que pueden recibir la entrega
                empresasGrupo = grupo.Data!.Select(x => new { id = x.ID_Catalogo, texto = x.Descripcion }),
                // D-234: roles (subtipos) por tipo de ingreso; si un tipo no tiene, no se pide el rol
                subtipos = subs.Data!.Select(x => new { id = x.ID_Tipo_Acceso_Subtipo, tipoId = x.ID_Catalogo_Tipo_Acceso, codigo = x.Codigo, texto = x.Descripcion, predeterminado = x.Es_Predeterminado == "Y" }),
            }
        });
    }

    /// <summary>Buscador del responsable de atención (desde 2 letras): solo personal activo.</summary>
    [HttpGet]
    public async Task<IActionResult> Responsables(string? q, CancellationToken ct)
    {
        q = (q ?? string.Empty).Trim();
        if (q.Length < 2) return Json(new { success = true, data = Array.Empty<object>() });
        var r = await _personal.ListarAsync(q, null, null, false, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new
        {
            success = true,
            data = r.Data!.Where(p => p.Activo == "Y").Take(8).Select(p => new { id = p.ID_Personal, nombre = p.Nombre_Completo, area = p.Area, cargo = p.Cargo }),
        });
    }

    /// <summary>Autocompletar «Empresa o procedencia» con las ya escritas en otras solicitudes.</summary>
    [HttpGet]
    public async Task<IActionResult> Empresas(string? q, CancellationToken ct)
    {
        var r = await _sol.EmpresasBuscarAsync(q, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new { success = true, data = r.Data });
    }

    /// <summary>D-217: sugerencias de correo para «Correos en copia»: usuarios del sistema y correos externos ya usados.</summary>
    [HttpGet]
    public async Task<IActionResult> Correos(string? q, CancellationToken ct)
    {
        var r = await _sol.CorreosSugerirAsync(q, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new { success = true, data = r.Data!.Select(c => new { correo = c.Correo, nombre = c.Nombre, origen = c.Origen }) });
    }

    /// <summary>Autocompletar al escribir nombre o apellido de una persona externa ya registrada.</summary>
    [HttpGet]
    public async Task<IActionResult> PersonasBuscar(string? q, CancellationToken ct)
    {
        var r = await _externas.BuscarAsync(q ?? string.Empty, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new { success = true, data = r.Data!.Select(p => new { id = p.ID_Persona_Externa, tipoDocId = p.ID_Catalogo_Tipo_Documento, tipoDoc = p.Tipo_Documento, doc = p.Numero_Documento, apellidoPaterno = p.Apellido_Paterno, apellidoMaterno = p.Apellido_Materno, nombres = p.Nombres, nombreCompleto = p.Nombre_Completo }) });
    }

    // ── Personas externas ──────────────────────────────────────────────────────────────────────
    [HttpGet]
    public async Task<IActionResult> PersonaPorDocumento(long tipoDocId, string? doc, CancellationToken ct)
    {
        var r = await _externas.PorDocumentoAsync(tipoDocId, doc ?? string.Empty, ct);
        if (!r.Success) return Json(new { success = false, message = r.Message, errors = Errores(r) });
        var p = r.Data;
        return Json(new { success = true, data = p is null ? null : new { id = p.ID_Persona_Externa, apellidoPaterno = p.Apellido_Paterno, apellidoMaterno = p.Apellido_Materno, nombres = p.Nombres, nombreCompleto = p.Nombre_Completo } });
    }

    /// <summary>Registra a la persona (si no existía) o corrige sus datos (si ya existía y el solicitante lo pidió).</summary>
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> PersonaGuardar([FromBody] PersonaExternaVM m, CancellationToken ct)
    {
        var dto = new Dto_Persona_Externa
        {
            ID_Persona_Externa = m.Id, ID_Catalogo_Tipo_Documento = m.TipoDocId, Numero_Documento = (m.Doc ?? string.Empty).Trim(),
            Apellido_Paterno = (m.ApellidoPaterno ?? string.Empty).Trim(), Apellido_Materno = Vacio(m.ApellidoMaterno), Nombres = (m.Nombres ?? string.Empty).Trim(),
        };
        var usuario = User.UsuarioId();
        long id = m.Id;
        if (m.Id > 0)
        {
            var a = await _externas.ActualizarAsync(m.Id, dto, usuario, ct);
            if (!a.Success) return Json(new { success = false, message = a.Message, errors = Errores(a) });
        }
        else
        {
            var c = await _externas.CrearAsync(dto, usuario, ct);
            if (!c.Success) return Json(new { success = false, message = c.Message, errors = Errores(c) });
            id = c.Data;
        }
        var nombre = (dto.Apellido_Paterno + " " + (dto.Apellido_Materno ?? "")).Trim() + ", " + dto.Nombres;
        return Json(new { success = true, data = new { id, nombreCompleto = nombre, doc = dto.Numero_Documento } });
    }

    // ── Crear / editar / cancelar ──────────────────────────────────────────────────────────────
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Crear([FromBody] SolicitudGuardarVM m, CancellationToken ct)
    {
        if (m.SedeId <= 0) return Falla("Seleccione la sede.");
        if (m.TipoId <= 0) return Falla("Seleccione el tipo de ingreso.");
        // D-227: contratista por franja: la fecha de la solicitud la fija la rutina (primer día); aquí basta una referencia
        var dias = (m.Dias ?? new()).Select(x => (x ?? "").Trim()).Where(x => x.Length > 0).ToList();
        var fh = dias.Count > 0 ? Fecha(dias.Min(StringComparer.Ordinal)) : FechaHora(m);
        if (fh is null) return Falla(dias.Count > 0 ? "Alguno de los días indicados no es válido." : "Indique la fecha y la hora de la visita.");

        var r = await _sol.CrearAsync(new Dto_Solicitud_Crear
        {
            ID_Catalogo_Sede = m.SedeId, ID_Catalogo_Tipo_Acceso = m.TipoId, ID_Personal_Responsable = m.ResponsableId > 0 ? m.ResponsableId : null,
            Fecha_Hora_Prevista = fh.Value, Empresa_Visitante = Vacio(m.Empresa), ID_Catalogo_Motivo_Visita = m.MotivoId is > 0 ? m.MotivoId : null,
            Motivo_Detalle = Vacio(m.MotivoDetalle), Observaciones = Vacio(m.Observaciones), IDs_Zona = m.ZonasIds ?? new(),
            IDs_Persona_Externa = m.PersonasIds ?? new(), Copias = Vacio(m.Copias), ID_Solicitud_Origen = m.OrigenId is > 0 ? m.OrigenId : null,
            Requiere_Cochera = m.Cochera, Placa_Vehiculo = Vacio(m.Placa), Area_Detalle = Vacio(m.AreaDetalle),
            Contacto_Nombre = Vacio(m.ContactoNombre), Contacto_Telefonos = Vacio(m.ContactoTelefonos), Contacto_Correos = Vacio(m.ContactoCorreos),
            ID_Catalogo_Empresa_Destino = m.EmpresaDestinoId is > 0 ? m.EmpresaDestinoId : null,
            Dias = dias, Hora_Desde = Vacio(m.HoraDesde), Hora_Hasta = Vacio(m.HoraHasta),
            Transportistas = (m.Transportistas ?? new()).Select(t => new Dto_Transportista_Entrada
            {
                ID_Persona_Externa = t.PersonaId, Ruc = Vacio(t.Ruc), Nombre = Vacio(t.Nombre), Direccion = Vacio(t.Direccion),
                Placa = Vacio(t.Placa), Marca = Vacio(t.Marca), Licencia = Vacio(t.Licencia),
            }).ToList(),
        }, User.UsuarioId(), ct);
        if (!r.Success) return Json(new { success = false, message = r.Message, errors = Errores(r) });
        // D-234: rol de cada persona (la solicitud ya existe; quien no trae rol queda con el predeterminado del tipo)
        var avisoRoles = await AplicarRolesAsync(r.Data!.ID_Solicitud, m.Subtipos, ct);
        return Json(new { success = true, message = r.Message, data = new { id = r.Data!.ID_Solicitud, codigo = r.Data.Codigo, avisoRoles } });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Editar(long id, [FromBody] SolicitudGuardarVM m, CancellationToken ct)
    {
        var fh = FechaHora(m);
        if (fh is null) return Falla("Indique la fecha y la hora de la visita.");
        var r = await _sol.EditarDatosAsync(id, new Dto_Solicitud_Editar
        {
            Fecha_Hora_Prevista = fh.Value, Empresa_Visitante = Vacio(m.Empresa), ID_Personal_Responsable = m.ResponsableId > 0 ? m.ResponsableId : null,
            ID_Catalogo_Motivo_Visita = m.MotivoId is > 0 ? m.MotivoId : null, Motivo_Detalle = Vacio(m.MotivoDetalle),
            Observaciones = Vacio(m.Observaciones), IDs_Zona = m.ZonasIds ?? new(), Copias = Vacio(m.Copias),
            Requiere_Cochera = m.Cochera, Placa_Vehiculo = Vacio(m.Placa), Area_Detalle = Vacio(m.AreaDetalle),
            Contacto_Nombre = Vacio(m.ContactoNombre), Contacto_Telefonos = Vacio(m.ContactoTelefonos), Contacto_Correos = Vacio(m.ContactoCorreos),
            ID_Catalogo_Empresa_Destino = m.EmpresaDestinoId is > 0 ? m.EmpresaDestinoId : null,
        }, User.UsuarioId(), ct);
        if (!r.Success) return Json(new { success = false, message = r.Message, errors = Errores(r) });
        return Json(new { success = true, message = r.Message, data = new { reenviadas = r.Data } });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Cancelar([FromBody] SolicitudCancelarVM m, CancellationToken ct)
    {
        var r = await _sol.CancelarAsync(m.SolicitudId, Vacio(m.Motivo), User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    // ── Detalle ────────────────────────────────────────────────────────────────────────────────
    [HttpGet]
    public async Task<IActionResult> Datos(long id, CancellationToken ct)
    {
        var u = User.UsuarioId();
        var d = await _sol.DetalleAsync(u, id, ct);
        if (!d.Success) return Falla(d.Message);
        var per = await _sol.PersonasListarAsync(u, id, ct);
        var his = await _sol.HistorialListarAsync(u, id, ct);
        var tra = await _sol.TransportistasListarAsync(u, id, ct);
        var dia = await _sol.DiasListarAsync(u, id, ct);
        if (!tra.Success) return Falla(tra.Message);
        if (!dia.Success) return Falla(dia.Message);
        if (!per.Success) return Falla(per.Message);
        if (!his.Success) return Falla(his.Message);
        var s = d.Data!;
        var franjaAprobada = dia.Data!.Count > 0 && (s.Estado == "APROBADA" || s.Estado == "APROBADA_PARCIAL");   // D-227
        return Json(new
        {
            success = true,
            data = new
            {
                id = s.ID_Solicitud, codigo = s.Codigo, sede = s.Sede, sedeId = s.ID_Catalogo_Sede, tipo = s.Tipo_Acceso, tipoId = s.ID_Catalogo_Tipo_Acceso,
                tipoCodigo = s.Tipo_Acceso_Codigo, empresaCodigo = s.Empresa_Destino_Codigo, cochera = s.Requiere_Cochera, placa = s.Placa_Vehiculo, areaDetalle = s.Area_Detalle,
                contactoNombre = s.Contacto_Nombre, contactoTelefonos = s.Contacto_Telefonos, contactoCorreos = s.Contacto_Correos, estado = s.Estado, avance = s.Avance,
                fecha = s.Fecha_Hora_Prevista.ToString("yyyy-MM-dd"), hora = s.Fecha_Hora_Prevista.ToString("HH:mm"), empresa = s.Empresa_Visitante,
                responsableId = s.ID_Personal_Responsable, responsable = s.Responsable_Nombre, responsableArea = s.Responsable_Area,
                motivoId = s.ID_Catalogo_Motivo_Visita, motivo = s.Motivo, motivoDetalle = s.Motivo_Detalle, observaciones = s.Observaciones,
                exigeSctr = s.Exige_SCTR, exigeEpp = s.Exige_EPP, zonasIds = ListaIds(s.Zonas_IDs), zonas = s.Zonas_Nombres, copias = s.Copias,
                observacionCoordinador = s.Observacion_Coordinador, motivoCancelacion = s.Motivo_Cancelacion, codigoOrigen = s.Codigo_Origen,
                total = s.Total_Personas, autorizadas = s.Autorizadas, observadas = s.Observadas, pendientes = s.Pendientes, rechazadas = s.Rechazadas, retiradas = s.Retiradas,
                puedeEditar = s.Puede_Editar_Datos && !franjaAprobada,
                motivoNoEditar = franjaAprobada ? "Una solicitud de contratista aprobada no se modifica. Para ampliar el plazo cree una solicitud nueva (el Coordinador también puede agregar días)." : s.Motivo_No_Editar_Datos, puedeModificar = s.Puede_Modificar_Personal,
                motivoNoModificar = s.Motivo_No_Modificar_Personal, puedeCancelar = s.Puede_Cancelar, motivoNoCancelar = s.Motivo_No_Cancelar,
                puedeReutilizar = s.Puede_Reutilizar, esPropia = s.Es_Propia,
                empresaDestinoId = s.ID_Empresa_Destino, empresaDestino = s.Empresa_Destino,
                dias = dia.Data!.Select(x => new { fecha = x.Fecha.ToString("yyyy-MM-dd"), desde = x.Hora_Desde, hasta = x.Hora_Hasta, origen = x.Origen }),
                transportistas = tra.Data!.Select(t => new
                {
                    personaId = t.ID_Persona_Externa, principal = t.Es_Principal, tipoDoc = t.Tipo_Documento, doc = t.Numero_Documento, nombrePersona = t.Nombre_Completo,
                    ruc = t.Ruc, nombre = t.Nombre, direccion = t.Direccion, placa = t.Placa, marca = t.Marca, licencia = t.Licencia, completos = t.Datos_Completos,
                }),
                personas = per.Data!.Select(p => new
                {
                    id = p.ID_Solicitud_Persona, personaId = p.ID_Persona_Externa, tipoDocId = p.ID_Catalogo_Tipo_Documento, tipoDoc = p.Tipo_Documento, doc = p.Numero_Documento,
                    apellidoPaterno = p.Apellido_Paterno, apellidoMaterno = p.Apellido_Materno, nombres = p.Nombres, nombre = p.Nombre_Completo,
                    aprobacion = p.Aprobacion, mensaje = p.Aprobacion_Mensaje, aprobadoPor = p.Aprobado_Por_Nombre, estado = p.Estado,
                    puedeRetirar = p.Puede_Retirar, puedeCorregir = p.Puede_Corregir, puedeReactivar = p.Puede_Reactivar,
                    esTransportista = tra.Data!.Any(t => t.ID_Solicitud_Persona == p.ID_Solicitud_Persona),
                    subtipoId = p.ID_Tipo_Acceso_Subtipo, subtipo = p.Subtipo,   // D-234: rol de la persona
                }),
                historial = his.Data!.Select(h => new { fecha = h.Fecha_Evento.ToString("yyyy-MM-dd HH:mm"), texto = h.Accion_Texto, detalle = h.Detalle, usuario = h.Usuario_Nombre }),
            }
        });
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> PersonaAgregar([FromBody] SolicitudPersonaVM m, CancellationToken ct)
    {
        var r = await _solPer.AgregarAsync(m.SolicitudId, m.PersonaId, User.UsuarioId(), ct);
        if (r.Success && m.SubtipoId is > 0)
        {
            var s = await _solPer.SubtipoAsignarAsync(m.SolicitudId, m.PersonaId, m.SubtipoId.Value, User.UsuarioId(), ct);
            if (!s.Success) return Json(new { success = true, message = r.Message + " Pero no se pudo fijar su rol: " + s.Message, errors = Errores(r) });
        }
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    /// <summary>D-234: fija el rol de cada persona tras crear la solicitud. Devuelve un aviso si alguno no se pudo fijar (la solicitud ya existe).</summary>
    private async Task<string?> AplicarRolesAsync(long solicitudId, List<SubtipoPersonaVM>? roles, CancellationToken ct)
    {
        string? aviso = null;
        foreach (var x in (roles ?? new()).Where(x => x.PersonaId > 0 && x.SubtipoId > 0))
        {
            var s = await _solPer.SubtipoAsignarAsync(solicitudId, x.PersonaId, x.SubtipoId, User.UsuarioId(), ct);
            if (!s.Success) aviso = "No se pudo fijar el rol de alguna persona: " + s.Message;
        }
        return aviso;
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> PersonaRetirar([FromBody] SolicitudPersonaVM m, CancellationToken ct)
    {
        var r = await _solPer.RetirarAsync(m.SolicitudPersonaId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    /// <summary>Cambia a la persona de una fila por otra ya registrada («Corregir y reenviar»).</summary>
    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> PersonaCorregir([FromBody] SolicitudPersonaVM m, CancellationToken ct)
    {
        var r = await _solPer.CorregirAsync(m.SolicitudPersonaId, m.PersonaId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r), data = new { reenviada = r.Data } });
    }

    // ── apoyo ──────────────────────────────────────────────────────────────────────────────────
    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });
    private static string? Vacio(string? s) => string.IsNullOrWhiteSpace(s) ? null : s.Trim();
    private static object Errores(Result r) => r.Errors.Select(e => new { field = e.Field, message = e.Message });
    private static DateTime? Fecha(string? s) => DateTime.TryParseExact(s, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d : null;
    private static DateTime? FechaHora(SolicitudGuardarVM m)
        => DateTime.TryParseExact((m.Fecha ?? "") + " " + (m.Hora ?? ""), "yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d : null;
    private static List<long> ListaIds(string? s)
        => (s ?? "").Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).Select(x => long.TryParse(x, out var n) ? n : 0).Where(n => n > 0).ToList();
}
