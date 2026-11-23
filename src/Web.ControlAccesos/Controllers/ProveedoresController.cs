// ============================================================
// Calendario de entregas de proveedores (Almacén y consulta).
//   Ver el calendario       : PER_CAF_PROVEEDOR_DASHBOARD (solo lectura; Abastecimiento, Coordinador, Vigilancia, Almacén)
//   Asignar / Atender / Terminar : PER_CAF_PROVEEDOR_ALMACEN (solo Almacén)
// Las reglas (estado, día, esclusa única, permisos) viven en los procedimientos; aquí solo se arman los datos y se
// reenvía la acción. Cada acción vuelve a validarse en la BD aunque la pantalla no muestre el botón.
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

[Authorize, ExigirPermiso(PermVer)]
public sealed class ProveedoresController : Controller
{
    private const string SedeCodigo = "VES";
    private const string PermVer = "PER_CAF_PROVEEDOR_DASHBOARD";
    private const string PermAlmacen = "PER_CAF_PROVEEDOR_ALMACEN";

    private readonly ISrv_Proveedor _prov;
    private readonly ISrv_Catalogo_Sede _sedes;
    private readonly ISrv_Porteria _por;
    private readonly ISrv_Solicitud _sol;

    public ProveedoresController(ISrv_Proveedor prov, ISrv_Catalogo_Sede sedes, ISrv_Porteria por, ISrv_Solicitud sol) { _prov = prov; _sedes = sedes; _por = por; _sol = sol; }

    [HttpGet]
    public IActionResult Index()
    {
        ViewData["PuedeAlmacen"] = User.TienePermiso(PermAlmacen);
        // Accesos directos a las pantallas originales (cada una vuelve a validar el permiso al abrirse).
        ViewData["PuedeSolicitar"] = User.TienePermiso("PER_CAF_PROVEEDOR_SOLICITAR");
        ViewData["PuedeCoordinar"] = User.TienePermiso("PER_CAF_SOLICITUD_APROBAR");
        ViewData["PuedeVigilar"] = User.TienePermiso("PER_CAF_PROVEEDOR_VIGILANCIA");
        return View();
    }

    // D-246: Almacén consulta (solo lectura) la solicitud de proveedor de una entrega y sus documentos adjuntos.
    // La BD decide qué solicitudes puede ver (ERP_CAF_FN_SOLICITUD_VISIBLE); aquí además se exige ser Almacén.
    [HttpGet, ExigirPermiso(PermAlmacen)]
    public IActionResult Solicitud(long id) { ViewData["Id"] = id; return View(); }

    [HttpGet, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> SolicitudDatos(long id, CancellationToken ct)
    {
        var (error, data) = await SolicitudesController.ArmarDatosAsync(_sol, User.UsuarioId(), id, ct);
        if (error is not null) return Falla(error);
        return Json(new { success = true, data });
    }

    /// <summary>Entregas del rango (fechas yyyy-MM-dd) y estado de la esclusa. La pantalla lo llama al abrir, al pulsar Actualizar y cada minuto.</summary>
    [HttpGet]
    public async Task<IActionResult> Datos(string? desde, string? hasta, CancellationToken ct)
    {
        var sede = await SedeIdAsync(ct);
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        var uid = User.UsuarioId();
        await _por.ProveedorCierreDiaAsync(0, ct); // D-218: red de seguridad; el servicio en segundo plano ya lo hace cada minuto (idempotente).
        var r = await _prov.CalendarioAsync(uid, sede.Value, Fecha(desde), Fecha(hasta), ct);
        if (!r.Success) return Falla(r.Message);
        var x = await _prov.ExclusaEstadoAsync(uid, sede.Value, ct);
        var ex = x.Success ? x.Data : null;
        var cu = await _prov.CuposAsync(uid, sede.Value, ct);                                  // D-244: panel de cupos
        var cupos = cu.Success ? cu.Data! : new List<Dto_Proveedor_Cupo>();
        var iv = await _prov.IngresoVehListarAsync(uid, sede.Value, ct);                       // D-260: solicitudes de ingreso vehicular
        var ingresoVeh = iv.Success ? iv.Data! : new List<Dto_Proveedor_IngresoVeh_Solicitud>();
        var pz = await _prov.PlazasListarAsync(uid, sede.Value, ct);                           // D-263: entregas con varias plazas (botón «Liberar plaza vehicular»)
        var plazasVeh = pz.Success ? pz.Data! : new List<Dto_Proveedor_Plaza>();
        return Json(new
        {
            success = true,
            hoy = DateTime.Today.ToString("yyyy-MM-dd"),
            ahora = DateTime.Now.ToString("HH:mm:ss"),
            exclusa = new
            {
                ocupada = ex?.Ocupada ?? false, estado = ex?.Estado ?? "LIBRE", id = ex?.ID_Solicitud, codigo = ex?.Codigo, empresa = ex?.Empresa, desde = Hora(ex?.Desde), atiende = ex?.Atiende,
                capacidad = ex?.Capacidad ?? 1, usadas = ex?.Usadas ?? 0,   // D-247
                plazas = (ex?.Plazas ?? new List<Dto_Proveedor_Exclusa>()).Select(x => new { estado = x.Estado, id = x.ID_Solicitud, codigo = x.Codigo, empresa = x.Empresa, desde = Hora(x.Desde), atiende = x.Atiende }),
            },
            cupos = cupos.Select(c => new { tipo = c.Tipo, nombre = c.Nombre, codigo = c.Codigo, solicitud = c.Solicitud, ocupa = c.Ocupa, detalle = (c.Detalle ?? "").Split(';', StringSplitOptions.RemoveEmptyEntries).Select(t => t.Split(':')).Where(t => t.Length == 2).Select(t => new { codigo = t[0], estado = t[1] }), usados = c.Usados, limite = c.Limite, sinLimite = c.Limite >= int.MaxValue }),
            plazasVeh = plazasVeh.Select(x => new { solicitudId = x.ID_Solicitud, plazas = x.Plazas, vehDeclarados = x.Veh_Declarados, vehDentro = x.Veh_Dentro, puede = x.Puede_Liberar, motivo = x.Motivo }),
            ingresoVeh = ingresoVeh.Select(s => new
            {
                id = s.ID_Solicitud_Ingreso, solicitudId = s.ID_Solicitud, codigo = s.Codigo, empresas = s.Empresas, solicitante = s.Solicitante_Nombre,
                otraId = s.ID_Solicitud_Otra, otraCodigo = s.Codigo_Otra, otraEmpresas = s.Empresas_Otra, responsable = s.Responsable_Nombre,
                vehTotal = s.Veh_Total_Otra, vehPorIngresar = s.Veh_Por_Ingresar_Otra, estado = s.Estado, motivo = s.Motivo_Rechazo,
                solicitada = Hora(s.Fecha_Solicitud), decidida = Hora(s.Fecha_Decision), decide = s.Decide_Nombre, porCoord = s.Decidida_Por_Coord,
                esResponsable = s.Es_Responsable, puedeDecidir = s.Puede_Decidir, esSolicitante = s.Es_Solicitante,
            }),
            data = r.Data!.Select(e => new
            {
                id = e.ID_Solicitud, codigo = e.Codigo, fecha = e.Fecha_Hora_Prevista.ToString("yyyy-MM-dd"), hora = e.Fecha_Hora_Prevista.ToString("HH:mm"),
                empresa = e.Empresa_Proveedor, solicitante = e.Solicitante_Nombre, ruc = e.Proveedor_RUC, destino = e.Empresa_Destino, destinoCodigo = e.Empresa_Destino_Codigo, transportista = e.Transportista, documento = e.Conductor_Documento, telefono = e.Telefono,
                numerosOc = (e.Numeros_OC ?? "").Split(';', StringSplitOptions.RemoveEmptyEntries), empresaTransportista = e.Empresa_Transportista, horaHasta = e.Hora_Hasta,   // D-237
                atencion = (e.Atencion_Resumen ?? "").Split(';', StringSplitOptions.RemoveEmptyEntries).Select(t => t.Split(':')).Where(t => t.Length == 2).Select(t => new { codigo = t[0], estado = t[1] }),   // D-238
                placa = e.Placa, marca = e.Vehiculo_Marca, observaciones = e.Observaciones, apoyo = e.Cantidad_Apoyo, transportistas = e.Transportistas_Total, verificados = e.Transportistas_Verificados, dentro = e.Transportistas_Dentro, salieron = e.Transportistas_Salieron, ayudantes = e.Ayudantes_Total, estado = e.Estado_Operativo, conDesviacion = e.Con_Desviacion,
                disponible = e.Disponibilidad_Confirmada, modoIngreso = e.Modo_Ingreso, disponibleDesde = Hora(e.Fecha_Disponibilidad),
                llegada = Hora(e.Fecha_Llegada), ingreso = Hora(e.Fecha_Ingreso), inicio = Hora(e.Fecha_Inicio_Atencion), recepcion = Hora(e.Fecha_Recepcion), salida = Hora(e.Fecha_Salida),
                resultado = e.Resultado_Recepcion, programadoId = e.ID_Personal_Programado, programado = e.Programado_Nombre, efectivo = e.Efectivo_Nombre,
                puedeProgramar = e.Puede_Programar, puedeConfirmar = e.Puede_Confirmar,
                puedeAtender = e.Puede_Atender, puedeTerminar = e.Puede_Terminar, puedeDetener = e.Puede_Detener, puedeReanudar = e.Puede_Reanudar, puedeCerrar = e.Puede_Cerrar_Sin, motivoIniciar = e.Motivo_Iniciar, motivoReanudar = e.Motivo_Reanudar, puedeCeder = e.Puede_Ceder, puedeTomar = e.Puede_Tomar, motivoTomar = e.Motivo_Tomar, reservaNombre = e.Reserva_Nombre, pausada = e.Pausada, motivoBloqueo = e.Motivo_Bloqueo, esMia = e.Es_Solicitante, puedeCancelarSol = e.Puede_Cancelar_Sol, motivoNoCancelarSol = e.Motivo_No_Cancelar_Sol,
            }),
        });
    }

    /// <summary>Personal de Almacén que puede ser responsable programado (para el desplegable).</summary>
    [HttpGet, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> Responsables(CancellationToken ct)
    {
        var sede = await SedeIdAsync(ct);
        if (sede is null) return Falla("No se encontró la sede " + SedeCodigo + ".");
        var r = await _prov.ResponsablesAsync(User.UsuarioId(), sede.Value, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new { success = true, data = r.Data!.Select(p => new { id = p.ID_Personal, nombre = p.Nombre, cargo = p.Cargo }) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> Programar([FromBody] ProveedorProgramarVM m, CancellationToken ct)
    {
        var r = await _prov.ProgramarAsync(m.SolicitudId, m.PersonalId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    /// <summary>D-239: Almacén confirma la disponibilidad (solo tras la verificación de Vigilancia) y elige CON o SIN ingreso vehicular. No se puede deshacer.</summary>
    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> ConfirmarDisponibilidad([FromBody] ProveedorDisponibilidadVM m, CancellationToken ct)
    {
        var r = await _prov.ConfirmarDisponibilidadAsync(m.SolicitudId, m.ConVehiculo, User.UsuarioId(), m.Plazas, ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    /// <summary>D-260: al abrir «Confirmar disponibilidad»: estado de la esclusa (caso A advertencia / caso B completa) y de la solicitud de ingreso vehicular propia.</summary>
    [HttpGet, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> IngresoVehEstado(long id, CancellationToken ct)
    {
        var r = await _prov.IngresoVehEstadoAsync(User.UsuarioId(), id, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new
        {
            success = true,
            data = r.Data!.Select(x => new
            {
                caso = x.Caso, capacidad = x.Capacidad, reservas = x.Reservas, otraId = x.ID_Solicitud_Otra, otraCodigo = x.Codigo_Otra, otraEmpresas = x.Empresas_Otra, otraAlmacenero = x.Almacenero_Otra,
                vehTotal = x.Veh_Total, vehPorIngresar = x.Veh_Por_Ingresar, vehDentro = x.Veh_Dentro, vehSalieron = x.Veh_Salieron, requiere = x.Requiere_Conformidad,
                solicitudId = x.ID_Solicitud_Ingreso, solicitudEstado = x.Solicitud_Estado, motivoRechazo = x.Motivo_Rechazo,
                vehPropios = x.Veh_Propios, plazasLibres = x.Plazas_Libres, plazasOtra = x.Plazas_Otra,
            }),
        });
    }

    /// <summary>D-263: Almacén libera UNA plaza de la esclusa (entregas de más de 1 vehículo); Vigilancia sigue registrando la salida real.</summary>
    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> LiberarPlaza([FromBody] ProveedorAtenderVM m, CancellationToken ct)
    {
        var r = await _prov.PlazaLiberarAsync(m.SolicitudId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    /// <summary>D-263: conductores de la entrega con su placa y estado (lista informativa del modal «Terminar atención»).</summary>
    [HttpGet, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> VehiculosListar(long id, CancellationToken ct)
    {
        var r = await _prov.VehiculosListarAsync(User.UsuarioId(), id, ct);
        if (!r.Success) return Falla(r.Message);
        return Json(new { success = true, data = r.Data!.Select(x => new { personaId = x.ID_Solicitud_Persona, nombre = x.Nombre, placa = x.Placa, estado = x.Estado }) });
    }

    /// <summary>D-260: pide la conformidad del almacenero con la entrega en curso para confirmar CON ingreso vehicular.</summary>
    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> SolicitarIngresoVeh([FromBody] ProveedorAtenderVM m, CancellationToken ct)
    {
        var r = await _prov.IngresoVehSolicitarAsync(m.SolicitudId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    /// <summary>D-260: el solicitante retira su solicitud pendiente (puede elegir «Sin ingreso vehicular»).</summary>
    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> RetirarIngresoVeh([FromBody] ProveedorAtenderVM m, CancellationToken ct)
    {
        var r = await _prov.IngresoVehRetirarAsync(m.SolicitudId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    /// <summary>D-260: confirmar o rechazar una solicitud de ingreso vehicular (almacenero en curso o Coordinador de Almacén).</summary>
    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> ResponderIngresoVeh([FromBody] ProveedorIngresoVehRespuestaVM m, CancellationToken ct)
    {
        var r = await _prov.IngresoVehResponderAsync(m.SolicitudIngresoId, m.Accion ?? string.Empty, m.Motivo, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    /// <summary>D-244: quien confirmó la disponibilidad cede la reserva (solo antes de iniciar la atención) para que otro almacenero de esas empresas la tome.</summary>
    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> CederReserva([FromBody] ProveedorAtenderVM m, CancellationToken ct)
    {
        var r = await _prov.CederReservaAsync(m.SolicitudId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    /// <summary>D-244: otro almacenero toma la reserva cedida; desde ahí es él quien inicia la atención (si tiene cupo).</summary>
    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> TomarReserva([FromBody] ProveedorAtenderVM m, CancellationToken ct)
    {
        var r = await _prov.TomarReservaAsync(m.SolicitudId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> Atender([FromBody] ProveedorAtenderVM m, CancellationToken ct)
    {
        var r = await _prov.AtenderAsync(m.SolicitudId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> Terminar([FromBody] ProveedorTerminarVM m, CancellationToken ct)
    {
        var r = await _prov.TerminarAsync(m.SolicitudId, m.Observacion, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    /// <summary>D-238: empresas de la entrega con su estado de atención y lo que el usuario puede hacer en cada una, más los motivos de «cerrar sin atención».</summary>
    [HttpGet]
    public async Task<IActionResult> AtencionEmpresas(long id, CancellationToken ct)
    {
        var r = await _prov.AtencionListarAsync(id, User.UsuarioId(), ct);
        if (!r.Success) return Falla(r.Message);
        var m = await _prov.MotivosSinAtencionAsync(ct);
        return Json(new
        {
            success = true,
            data = new
            {
                empresas = r.Data!.Select(a => new
                {
                    id = a.ID_Empresa, codigo = a.Codigo, nombre = a.Empresa, estado = a.Estado, resultado = a.Resultado, observacion = a.Observacion, motivo = a.Motivo,
                    inicio = Hora(a.Fecha_Inicio), fin = Hora(a.Fecha_Fin), atiende = a.Atiende, autorizado = a.Autorizado,
                    puedeAtender = a.Puede_Atender, puedeDetener = a.Puede_Detener, puedeReanudar = a.Puede_Reanudar, motivoDetencion = a.Motivo_Detencion, puedeRecepcionar = a.Puede_Recepcionar, puedeCerrar = a.Puede_Cerrar_Sin, motivoNo = a.Motivo_No,
                }),
                motivos = (m.Data ?? new()).Select(x => new { id = x.ID_Motivo, texto = x.Descripcion, otro = x.Es_Otro }),
            }
        });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> AtenderEmpresa([FromBody] ProveedorEmpresaVM m, CancellationToken ct)
    {
        var r = await _prov.AtenderEmpresaAsync(m.SolicitudId, m.EmpresaId, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> TerminarEmpresa([FromBody] ProveedorEmpresaTerminarVM m, CancellationToken ct)
    {
        var r = await _prov.TerminarEmpresaAsync(m.SolicitudId, m.EmpresaId, m.Observacion, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    /// <summary>D-239: inicia la atención de una o varias empresas a la vez (las que tengan cupo; el resto se informa en el mensaje).</summary>
    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> AtenderEmpresas([FromBody] ProveedorEmpresasVM m, CancellationToken ct)
    {
        var r = await _prov.AtenderEmpresasAsync(m.SolicitudId, m.EmpresasIds, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> DetenerEmpresas([FromBody] ProveedorEmpresasVM m, CancellationToken ct)
    {
        var r = await _prov.DetenerEmpresasAsync(m.SolicitudId, m.EmpresasIds, m.Motivo, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> ReanudarEmpresas([FromBody] ProveedorEmpresasVM m, CancellationToken ct)
    {
        var r = await _prov.ReanudarEmpresasAsync(m.SolicitudId, m.EmpresasIds, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> TerminarEmpresas([FromBody] ProveedorEmpresasVM m, CancellationToken ct)
    {
        var r = await _prov.TerminarEmpresasAsync(m.SolicitudId, m.EmpresasIds, m.Observacion, User.UsuarioId(), m.LiberarPlaza, ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    [HttpPost, ValidateAntiForgeryToken, ExigirPermiso(PermAlmacen)]
    public async Task<IActionResult> CerrarSinAtencion([FromBody] ProveedorCerrarSinAtencionVM m, CancellationToken ct)
    {
        var r = await _prov.CerrarSinAtencionAsync(m.SolicitudId, m.EmpresaId, m.MotivoId, m.Detalle, User.UsuarioId(), ct);
        return Json(new { success = r.Success, message = r.Message, errors = Errores(r) });
    }

    private async Task<long?> SedeIdAsync(CancellationToken ct)
    {
        var l = await _sedes.ListarAsync(false, ct);
        var s = l.Success ? l.Data!.FirstOrDefault(x => x.Codigo == SedeCodigo) : null;
        return s?.ID_Catalogo;
    }

    private IActionResult Falla(string mensaje) => Json(new { success = false, message = mensaje });
    private static DateTime? Fecha(string? t) => DateTime.TryParseExact(t, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var d) ? d : null;
    private static string? Hora(DateTime? d) => d?.ToString("HH:mm");
    private static object Errores(Result r) => r.Errors.Select(e => new { field = e.Field, message = e.Message });
}
