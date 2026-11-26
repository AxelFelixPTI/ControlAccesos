// ============================================================
// Archivo  : Repo_Proveedor.cs
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación (Entrega 2 de Proveedor de abastecimiento)
// Versión  : V2.0 — 2026-11-03
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_PROVEEDOR_CALENDARIO / _RESPONSABLES / _EXCLUSA_ESTADO (lecturas) y _PROGRAMAR / _DISPONIBILIDAD_CONFIRMAR / _DISPONIBILIDAD_CANCELAR / _ATENDER / _RECEPCION (escrituras)
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// El orden de los parámetros de bind es el de las rutinas (los INOUT no se enlazan).

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Proveedor : RepoHelpers, IRepo_Proveedor
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Proveedor(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Proveedor_Entrega>>> CalendarioAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PROVEEDOR_CALENDARIO",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                    AddDate(p, "HV_Fecha_Desde", desde);
                    AddDate(p, "HV_Fecha_Hasta", hasta);
                },
                map: MapEntrega,
                ct: ct);
            return Result<List<Dto_Proveedor_Entrega>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Proveedor_Entrega>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<List<Dto_Proveedor_Responsable>>> ResponsablesAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PROVEEDOR_RESPONSABLES",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                },
                map: rd => new Dto_Proveedor_Responsable
                {
                    ID_Personal = RdLong(rd, "ID_Personal"),
                    Nombre = RdStr(rd, "Nombre"),
                    Cargo = RdStrN(rd, "Cargo"),
                },
                ct: ct);
            return Result<List<Dto_Proveedor_Responsable>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Proveedor_Responsable>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<Dto_Proveedor_Exclusa?>> ExclusaEstadoAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try
        {
            var filas = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                },
                map: rd => new Dto_Proveedor_Exclusa
                {
                    Ocupada = RdBool(rd, "Ocupada"),
                    Estado = RdStr(rd, "Estado"),
                    ID_Solicitud = RdLongN(rd, "ID_Solicitud"),
                    Codigo = RdStrN(rd, "Codigo"),
                    Empresa = RdStrN(rd, "Empresa"),
                    Desde = RdDtN(rd, "Desde"),
                    Atiende = RdStrN(rd, "Atiende"),
                    Capacidad = RdInt(rd, "Capacidad"),
                    Usadas = RdInt(rd, "Usadas"),
                },
                ct: ct);
            // D-247: una fila por plaza ocupada; la primera da los campos de siempre y la lista trae todas
            var primera = filas.FirstOrDefault();
            if (primera is not null) primera.Plazas = filas.Where(f => f.Ocupada).ToList();
            return Result<Dto_Proveedor_Exclusa?>.Ok(primera);
        }
        catch (Exception ex) { return Result<Dto_Proveedor_Exclusa?>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public Task<ResultSp> ProgramarAsync(long solicitudId, long? personalId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_PROGRAMAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddLong(p, "HV_ID_Personal", personalId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    /// <summary>D-244: panel de cupos (quién ocupa qué solicitud y cuántos cupos hay usados por almacenero y por empresa).</summary>
    public async Task<Result<List<Dto_Proveedor_Cupo>>> CuposAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PROVEEDOR_CUPOS",
                bind: p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId); },
                map: rd => new Dto_Proveedor_Cupo
                {
                    Tipo = RdStr(rd, "Tipo"),
                    Nombre = RdStr(rd, "Nombre"),
                    Codigo = RdStrN(rd, "Codigo"),
                    Solicitud = RdStrN(rd, "Solicitud"),
                    Ocupa = RdStrN(rd, "Ocupa"),
                    Detalle = RdStrN(rd, "Detalle"),
                    Usados = RdInt(rd, "Usados"),
                    Limite = RdInt(rd, "Limite"),
                },
                ct: ct);
            return Result<List<Dto_Proveedor_Cupo>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Proveedor_Cupo>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    /// <summary>D-260: estado de la esclusa y de las otras entregas para el modal «Confirmar disponibilidad».</summary>
    public async Task<Result<List<Dto_Proveedor_IngresoVeh_Estado>>> IngresoVehEstadoAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PROVEEDOR_INGRESO_VEH_ESTADO",
                bind: p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Solicitud", solicitudId); },
                map: rd => new Dto_Proveedor_IngresoVeh_Estado
                {
                    Caso = RdStr(rd, "Caso"),
                    Capacidad = RdInt(rd, "Capacidad"),
                    Reservas = RdInt(rd, "Reservas"),
                    ID_Solicitud_Otra = RdLongN(rd, "ID_Solicitud_Otra"),
                    Codigo_Otra = RdStrN(rd, "Codigo_Otra"),
                    Empresas_Otra = RdStrN(rd, "Empresas_Otra"),
                    Almacenero_Otra = RdStrN(rd, "Almacenero_Otra"),
                    Veh_Total = RdInt(rd, "Veh_Total"),
                    Veh_Por_Ingresar = RdInt(rd, "Veh_Por_Ingresar"),
                    Veh_Dentro = RdInt(rd, "Veh_Dentro"),
                    Veh_Salieron = RdInt(rd, "Veh_Salieron"),
                    Requiere_Conformidad = RdBool(rd, "Requiere_Conformidad"),
                    ID_Solicitud_Ingreso = RdLongN(rd, "ID_Solicitud_Ingreso"),
                    Solicitud_Estado = RdStrN(rd, "Solicitud_Estado"),
                    Motivo_Rechazo = RdStrN(rd, "Motivo_Rechazo"),
                    Veh_Propios = RdInt(rd, "Veh_Propios"),
                    Plazas_Libres = RdInt(rd, "Plazas_Libres"),
                    Plazas_Otra = RdInt(rd, "Plazas_Otra"),
                },
                ct: ct);
            return Result<List<Dto_Proveedor_IngresoVeh_Estado>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Proveedor_IngresoVeh_Estado>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    /// <summary>D-260: solicitudes de ingreso vehicular vigentes de la sede.</summary>
    public async Task<Result<List<Dto_Proveedor_IngresoVeh_Solicitud>>> IngresoVehListarAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PROVEEDOR_INGRESO_VEH_LISTAR",
                bind: p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId); },
                map: rd => new Dto_Proveedor_IngresoVeh_Solicitud
                {
                    ID_Solicitud_Ingreso = RdLong(rd, "ID_Solicitud_Ingreso"),
                    ID_Solicitud = RdLong(rd, "ID_Solicitud"),
                    Codigo = RdStr(rd, "Codigo"),
                    Empresas = RdStrN(rd, "Empresas"),
                    Solicitante_Nombre = RdStrN(rd, "Solicitante_Nombre"),
                    ID_Solicitud_Otra = RdLong(rd, "ID_Solicitud_Otra"),
                    Codigo_Otra = RdStrN(rd, "Codigo_Otra"),
                    Empresas_Otra = RdStrN(rd, "Empresas_Otra"),
                    Responsable_Nombre = RdStrN(rd, "Responsable_Nombre"),
                    Veh_Total_Otra = RdInt(rd, "Veh_Total_Otra"),
                    Veh_Por_Ingresar_Otra = RdInt(rd, "Veh_Por_Ingresar_Otra"),
                    Estado = RdStr(rd, "Estado"),
                    Motivo_Rechazo = RdStrN(rd, "Motivo_Rechazo"),
                    Fecha_Solicitud = RdDtN(rd, "Fecha_Solicitud"),
                    Fecha_Decision = RdDtN(rd, "Fecha_Decision"),
                    Decide_Nombre = RdStrN(rd, "Decide_Nombre"),
                    Decidida_Por_Coord = RdBool(rd, "Decidida_Por_Coord"),
                    Es_Responsable = RdBool(rd, "Es_Responsable"),
                    Puede_Decidir = RdBool(rd, "Puede_Decidir"),
                    Es_Solicitante = RdBool(rd, "Es_Solicitante"),
                },
                ct: ct);
            return Result<List<Dto_Proveedor_IngresoVeh_Solicitud>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Proveedor_IngresoVeh_Solicitud>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public Task<ResultSp> IngresoVehSolicitarAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_PROVEEDOR_INGRESO_VEH_SOLICITAR",
            bind: p => { AddLongReq(p, "HV_ID_Solicitud", solicitudId); AddLongReq(p, "HV_UsuarioID", usuarioId); },
            ct: ct);

    public Task<ResultSp> IngresoVehRetirarAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_PROVEEDOR_INGRESO_VEH_RETIRAR",
            bind: p => { AddLongReq(p, "HV_ID_Solicitud", solicitudId); AddLongReq(p, "HV_UsuarioID", usuarioId); },
            ct: ct);

    public Task<ResultSp> PlazaLiberarAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_PROVEEDOR_PLAZA_LIBERAR",
            bind: p => { AddLongReq(p, "HV_ID_Solicitud", solicitudId); AddLongReq(p, "HV_UsuarioID", usuarioId); },
            ct: ct);

    public async Task<Result<List<Dto_Proveedor_Plaza>>> PlazasListarAsync(long usuarioId, long sedeId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn, funcion: "ERP_CAF_PROVEEDOR_PLAZAS_LISTAR",
                bind: p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId); },
                map: rd => new Dto_Proveedor_Plaza
                {
                    ID_Solicitud = RdLong(rd, "ID_Solicitud"),
                    Plazas = RdInt(rd, "Plazas"),
                    Veh_Declarados = RdInt(rd, "Veh_Declarados"),
                    Veh_Dentro = RdInt(rd, "Veh_Dentro"),
                    Puede_Liberar = RdBool(rd, "Puede_Liberar"),
                    Motivo = RdStrN(rd, "Motivo"),
                },
                ct: ct);
            return Result<List<Dto_Proveedor_Plaza>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Proveedor_Plaza>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<List<Dto_Proveedor_Vehiculo>>> VehiculosListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn, funcion: "ERP_CAF_PROVEEDOR_VEHICULOS_LISTAR",
                bind: p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Solicitud", solicitudId); },
                map: rd => new Dto_Proveedor_Vehiculo
                {
                    ID_Solicitud_Persona = RdLong(rd, "ID_Solicitud_Persona"),
                    Nombre = RdStr(rd, "Nombre"),
                    Placa = RdStrN(rd, "Placa"),
                    Estado = RdStr(rd, "Estado"),
                },
                ct: ct);
            return Result<List<Dto_Proveedor_Vehiculo>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Proveedor_Vehiculo>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<List<Dto_Proveedor_Atencion_Resumen>>> AtencionResumenAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn, funcion: "ERP_CAF_PROVEEDOR_ATENCION_RESUMEN",
                bind: p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Solicitud", solicitudId); },
                map: rd => new Dto_Proveedor_Atencion_Resumen
                {
                    ID_Empresa = RdLong(rd, "ID_Empresa"),
                    Codigo = RdStr(rd, "Codigo"),
                    Empresa = RdStr(rd, "Empresa"),
                    Estado = RdStr(rd, "Estado"),
                    Inicio_Nombre = RdStrN(rd, "Inicio_Nombre"),
                    Fecha_Inicio = RdDtN(rd, "Fecha_Inicio"),
                    Fin_Nombre = RdStrN(rd, "Fin_Nombre"),
                    Fecha_Fin = RdDtN(rd, "Fecha_Fin"),
                    Resultado = RdStrN(rd, "Resultado"),
                    Observacion = RdStrN(rd, "Observacion"),
                    Motivo_Sin_Atencion = RdStrN(rd, "Motivo_Sin_Atencion"),
                    Motivo_Detencion = RdStrN(rd, "Motivo_Detencion"),
                },
                ct: ct);
            return Result<List<Dto_Proveedor_Atencion_Resumen>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Proveedor_Atencion_Resumen>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<List<Dto_Proveedor_Atencion_Evento>>> AtencionEventosAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn, funcion: "ERP_CAF_PROVEEDOR_ATENCION_EVENTOS",
                bind: p => { AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Solicitud", solicitudId); },
                map: rd => new Dto_Proveedor_Atencion_Evento
                {
                    Fecha_Evento = RdDt(rd, "Fecha_Evento"),
                    Usuario_Nombre = RdStrN(rd, "Usuario_Nombre"),
                    Estado_Anterior = RdStrN(rd, "Estado_Anterior"),
                    Estado_Nuevo = RdStrN(rd, "Estado_Nuevo"),
                    Resultado = RdStrN(rd, "Resultado"),
                    Detalle = RdStrN(rd, "Detalle"),
                },
                ct: ct);
            return Result<List<Dto_Proveedor_Atencion_Evento>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Proveedor_Atencion_Evento>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public Task<ResultSp> IngresoVehResponderAsync(long solicitudIngresoId, string accion, string? motivo, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_PROVEEDOR_INGRESO_VEH_RESPONDER",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud_Ingreso", solicitudIngresoId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
                AddStrReq(p, "HV_Accion", accion);
                AddStr(p, "HV_Motivo", motivo);
            },
            ct: ct);

    /// <summary>D-244: quien confirmó la disponibilidad cede la reserva (antes de iniciar la atención).</summary>
    public Task<ResultSp> CederReservaAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_PROVEEDOR_RESERVA_CEDER",
            bind: p => { AddLongReq(p, "HV_ID_Solicitud", solicitudId); AddLongReq(p, "HV_UsuarioID", usuarioId); },
            ct: ct);

    /// <summary>D-244: otro almacenero de esas empresas toma la reserva cedida (si tiene cupo).</summary>
    public Task<ResultSp> TomarReservaAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_PROVEEDOR_RESERVA_TOMAR",
            bind: p => { AddLongReq(p, "HV_ID_Solicitud", solicitudId); AddLongReq(p, "HV_UsuarioID", usuarioId); },
            ct: ct);

    public Task<ResultSp> ConfirmarDisponibilidadAsync(long solicitudId, bool conVehiculo, long usuarioId, int plazas = 1, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_PLAZAS",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
                AddStrReq(p, "HV_Con_Vehiculo", conVehiculo ? "Y" : "N");
                AddInt(p, "HV_Plazas", plazas < 1 ? 1 : plazas);   // D-261: va antes de las salidas del procedimiento (el ejecutor pasa por posición)
            },
            ct: ct);

    public Task<ResultSp> ValidarIngresoAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_INGRESO_VALIDAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public Task<ResultSp> RetiroSinIngresoAsync(long solicitudId, string motivo, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_RETIRO_SIN_INGRESO",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddStrReq(p, "HV_Motivo", motivo);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public Task<ResultSp> IngresoFisicoAsync(long solicitudId, string idsPersona, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_INGRESO_FISICO",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddStrReq(p, "HV_IDs_Persona", idsPersona);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public Task<ResultSp> RetiroPersonasAsync(long solicitudId, string idsPersona, string motivo, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_RETIRO_PERSONAS",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddStrReq(p, "HV_IDs_Persona", idsPersona);
                AddStrReq(p, "HV_Motivo", motivo);
                AddChar1(p, "HV_Exigir_En_Espera", "N");
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public Task<ResultSp> VerificarGrupoAsync(Dto_Proveedor_Grupo dto, long usuarioId, CancellationToken ct = default)
        => GrupoAsync("ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO", dto, usuarioId, ct);

    public Task<ResultSp> SalidaGrupoAsync(Dto_Proveedor_Grupo dto, long usuarioId, CancellationToken ct = default)
        => GrupoAsync("ERP_CAF_PROVEEDOR_SALIDA_GRUPO", dto, usuarioId, ct);

    private Task<ResultSp> GrupoAsync(string procedimiento, Dto_Proveedor_Grupo dto, long usuarioId, CancellationToken ct)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: procedimiento,
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", dto.ID_Solicitud);
                AddStrReq(p, "HV_IDs_Persona", string.Join(",", dto.IDs_Persona));
                AddStr(p, "HV_Items", string.Join(",", dto.Items.Select(i => i.ID_Catalogo_Item_Checklist + ":" + (i.Cumple ? "Y" : "N"))));
                AddStr(p, "HV_Observacion", dto.Observacion);
                AddStr(p, "HV_Desv_Descripcion", dto.Desviacion?.Descripcion);
                AddLong(p, "HV_ID_Coordinador", dto.Desviacion?.ID_Coordinador);
                AddLong(p, "HV_ID_Tratamiento", dto.Desviacion?.ID_Tratamiento);
                AddStr(p, "HV_Tratamiento_Detalle", dto.Desviacion?.Tratamiento_Detalle);
                AddStr(p, "HV_Resultado_Elegido", dto.Desviacion?.Resultado_Elegido);
                if (procedimiento == "ERP_CAF_PROVEEDOR_SALIDA_GRUPO") AddStr(p, "HV_Motivo_Anticipada", dto.Motivo_Anticipada);   // D-245
                else
                {   // D-275: verificación en grupo; quién trae equipos / herramientas (subconjunto de la selección)
                    AddStr(p, "HV_IDs_Con_Equipos", dto.IDs_Con_Equipos.Count == 0 ? null : string.Join(",", dto.IDs_Con_Equipos));
                    AddStr(p, "HV_IDs_Con_Herramientas", dto.IDs_Con_Herramientas.Count == 0 ? null : string.Join(",", dto.IDs_Con_Herramientas));
                }
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public Task<ResultSp> AtenderAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_ATENDER",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public Task<ResultSp> RecepcionarAsync(long solicitudId, string resultado, string? observacion, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_RECEPCION",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddStrReq(p, "HV_Resultado", resultado);
                AddStr(p, "HV_Observacion", observacion);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    // ===== D-238: atención por empresa =====
    public async Task<Result<List<Dto_Atencion_Empresa>>> AtencionListarAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_ATENCION_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                },
                map: rd => new Dto_Atencion_Empresa
                {
                    ID_Empresa = RdLong(rd, "ID_Empresa"),
                    Codigo = RdStr(rd, "Codigo"),
                    Empresa = RdStr(rd, "Empresa"),
                    Estado = RdStr(rd, "Estado"),
                    Resultado = RdStrN(rd, "Resultado"),
                    Observacion = RdStrN(rd, "Observacion"),
                    Motivo = RdStrN(rd, "Motivo"),
                    Fecha_Inicio = RdDtN(rd, "Fecha_Inicio"),
                    Fecha_Fin = RdDtN(rd, "Fecha_Fin"),
                    Atiende = RdStrN(rd, "Atiende"),
                    Autorizado = RdBool(rd, "Autorizado"),
                    Puede_Atender = RdBool(rd, "Puede_Atender"),
                    Puede_Recepcionar = RdBool(rd, "Puede_Recepcionar"),
                    Puede_Cerrar_Sin = RdBool(rd, "Puede_Cerrar_Sin"),
                    Motivo_No = RdStrN(rd, "Motivo_No"),
                    Puede_Detener = RdBool(rd, "Puede_Detener"),
                    Puede_Reanudar = RdBool(rd, "Puede_Reanudar"),
                    Motivo_Detencion = RdStrN(rd, "Motivo_Detencion"),
                },
                ct: ct);
            return Result<List<Dto_Atencion_Empresa>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Atencion_Empresa>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public async Task<Result<List<Dto_Motivo_Sin_Atencion>>> MotivosSinAtencionAsync(CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_MOTIVO_SIN_ATENCION_LISTAR",
                bind: _ => { },
                map: rd => new Dto_Motivo_Sin_Atencion
                {
                    ID_Motivo = RdLong(rd, "ID_Motivo_Sin_Atencion"),
                    Codigo = RdStr(rd, "Codigo"),
                    Descripcion = RdStr(rd, "Descripcion"),
                    Es_Otro = RdBool(rd, "Es_Otro"),
                },
                ct: ct);
            return Result<List<Dto_Motivo_Sin_Atencion>>.Ok(lista);
        }
        catch (Exception ex) { return Result<List<Dto_Motivo_Sin_Atencion>>.Fail(ex.InnerException?.Message ?? ex.Message); }
    }

    public Task<ResultSp> AtenderEmpresaAsync(long solicitudId, long empresaId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_ATENDER_EMPRESA",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddLongReq(p, "HV_ID_Empresa", empresaId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public Task<ResultSp> RecepcionarEmpresaAsync(long solicitudId, long empresaId, string resultado, string? observacion, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_RECEPCION_EMPRESA",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddLongReq(p, "HV_ID_Empresa", empresaId);
                AddStrReq(p, "HV_Resultado", resultado);
                AddStr(p, "HV_Observacion", observacion);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public Task<ResultSp> AtenderEmpresasAsync(long solicitudId, string idsEmpresa, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_PROVEEDOR_ATENDER_EMPRESAS",
            bind: p => { AddLongReq(p, "HV_ID_Solicitud", solicitudId); AddStrReq(p, "HV_IDs_Empresa", idsEmpresa); AddLongReq(p, "HV_UsuarioID", usuarioId); },
            ct: ct);

    public Task<ResultSp> DetenerEmpresasAsync(long solicitudId, string idsEmpresa, string? motivo, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_PROVEEDOR_DETENER_EMPRESAS",
            bind: p => { AddLongReq(p, "HV_ID_Solicitud", solicitudId); AddStrReq(p, "HV_IDs_Empresa", idsEmpresa); AddStr(p, "HV_Motivo", motivo); AddLongReq(p, "HV_UsuarioID", usuarioId); },
            ct: ct);

    public Task<ResultSp> ReanudarEmpresasAsync(long solicitudId, string idsEmpresa, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_PROVEEDOR_REANUDAR_EMPRESAS",
            bind: p => { AddLongReq(p, "HV_ID_Solicitud", solicitudId); AddStrReq(p, "HV_IDs_Empresa", idsEmpresa); AddLongReq(p, "HV_UsuarioID", usuarioId); },
            ct: ct);

    public Task<ResultSp> RecepcionarEmpresasAsync(long solicitudId, string idsEmpresa, string resultado, string? observacion, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn, procedimiento: "ERP_CAF_PROVEEDOR_RECEPCION_EMPRESAS",
            bind: p => { AddLongReq(p, "HV_ID_Solicitud", solicitudId); AddStrReq(p, "HV_IDs_Empresa", idsEmpresa); AddStrReq(p, "HV_Resultado", resultado); AddStr(p, "HV_Observacion", observacion); AddLongReq(p, "HV_UsuarioID", usuarioId); },
            ct: ct);

    public Task<ResultSp> CerrarSinAtencionAsync(long solicitudId, long empresaId, long motivoId, string? detalle, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_CERRAR_SIN_ATENCION",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddLongReq(p, "HV_ID_Empresa", empresaId);
                AddLongReq(p, "HV_ID_Motivo", motivoId);
                AddStr(p, "HV_Detalle", detalle);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    private static Dto_Proveedor_Entrega MapEntrega(DbDataReader rd) => new()
    {
        ID_Solicitud = RdLong(rd, "ID_Solicitud"),
        Codigo = RdStr(rd, "Codigo"),
        Fecha_Hora_Prevista = RdDt(rd, "Fecha_Hora_Prevista"),
        Empresa_Proveedor = RdStr(rd, "Empresa_Proveedor"),
        Proveedor_RUC = RdStrN(rd, "Proveedor_RUC"),
        Empresa_Destino = RdStrN(rd, "Empresa_Destino"),
        Empresa_Destino_Codigo = RdStrN(rd, "Empresa_Destino_Codigo"),
        Transportista = RdStr(rd, "Transportista"),
        Telefono = RdStrN(rd, "Telefono"),
        Placa = RdStrN(rd, "Placa"),
        Vehiculo_Marca = RdStrN(rd, "Vehiculo_Marca"),
        Observaciones = RdStrN(rd, "Observaciones"),
        Cantidad_Apoyo = RdInt(rd, "Cantidad_Apoyo"),
        Transportistas_Total = RdInt(rd, "Transportistas_Total"),
        Transportistas_Verificados = RdInt(rd, "Transportistas_Verificados"),
        Transportistas_Dentro = RdInt(rd, "Transportistas_Dentro"),
        Transportistas_Salieron = RdInt(rd, "Transportistas_Salieron"),
        Ayudantes_Total = RdInt(rd, "Ayudantes_Total"),
        Numeros_OC = RdStrN(rd, "Numeros_OC"),
        Empresa_Transportista = RdStrN(rd, "Empresa_Transportista"),
        Hora_Hasta = RdStrN(rd, "Hora_Hasta"),
        Atencion_Resumen = RdStrN(rd, "Atencion_Resumen"),
        Modo_Ingreso = RdStrN(rd, "Modo_Ingreso"),
        Conductor_Documento = RdStrN(rd, "Conductor_Documento"),
        Puede_Detener = RdBool(rd, "Puede_Detener"),
        Puede_Reanudar = RdBool(rd, "Puede_Reanudar"),
        Puede_Cerrar_Sin = RdBool(rd, "Puede_Cerrar_Sin"),
        Motivo_Iniciar = RdStrN(rd, "Motivo_Iniciar"),
        Motivo_Reanudar = RdStrN(rd, "Motivo_Reanudar"),
        Puede_Ceder = RdBool(rd, "Puede_Ceder"),
        Puede_Tomar = RdBool(rd, "Puede_Tomar"),
        Motivo_Tomar = RdStrN(rd, "Motivo_Tomar"),
        Reserva_Nombre = RdStrN(rd, "Reserva_Nombre"),
        Pausada = RdBool(rd, "Pausada"),
        Solicitante_Nombre = RdStrN(rd, "Solicitante_Nombre"),
        Atendido_Por = RdStrN(rd, "Atendido_Por"),
        Estado_Operativo = RdStr(rd, "Estado_Operativo"),
        Con_Desviacion = RdBool(rd, "Con_Desviacion"),
        Disponibilidad_Confirmada = RdBool(rd, "Disponibilidad_Confirmada"),
        Fecha_Disponibilidad = RdDtN(rd, "Fecha_Disponibilidad"),
        Fecha_Llegada = RdDtN(rd, "Fecha_Llegada"),
        Fecha_Ingreso = RdDtN(rd, "Fecha_Ingreso"),
        Fecha_Inicio_Atencion = RdDtN(rd, "Fecha_Inicio_Atencion"),
        Fecha_Recepcion = RdDtN(rd, "Fecha_Recepcion"),
        Fecha_Salida = RdDtN(rd, "Fecha_Salida"),
        Resultado_Recepcion = RdStrN(rd, "Resultado_Recepcion"),
        ID_Personal_Programado = RdLongN(rd, "ID_Personal_Programado"),
        Programado_Nombre = RdStrN(rd, "Programado_Nombre"),
        Efectivo_Nombre = RdStrN(rd, "Efectivo_Nombre"),
        Puede_Programar = RdBool(rd, "Puede_Programar"),
        Puede_Confirmar = RdBool(rd, "Puede_Confirmar"),
        Puede_Atender = RdBool(rd, "Puede_Atender"),
        Puede_Terminar = RdBool(rd, "Puede_Terminar"),
        Motivo_Bloqueo = RdStrN(rd, "Motivo_Bloqueo"),
        Es_Solicitante = RdBool(rd, "Es_Solicitante"),
        Puede_Cancelar_Sol = RdBool(rd, "Puede_Cancelar_Sol"),
        Motivo_No_Cancelar_Sol = RdStrN(rd, "Motivo_No_Cancelar_Sol"),
    };
}
