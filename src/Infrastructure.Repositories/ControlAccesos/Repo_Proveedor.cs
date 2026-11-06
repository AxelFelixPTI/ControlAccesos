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
                    Nombre      = RdStr(rd, "Nombre"),
                    Cargo       = RdStrN(rd, "Cargo"),
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
            var fila = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CAF_PROVEEDOR_EXCLUSA_ESTADO",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                },
                map: rd => new Dto_Proveedor_Exclusa
                {
                    Ocupada      = RdBool(rd, "Ocupada"),
                    Estado       = RdStr(rd, "Estado"),
                    ID_Solicitud = RdLongN(rd, "ID_Solicitud"),
                    Codigo       = RdStrN(rd, "Codigo"),
                    Empresa      = RdStrN(rd, "Empresa"),
                    Desde        = RdDtN(rd, "Desde"),
                    Atiende      = RdStrN(rd, "Atiende"),
                },
                ct: ct);
            return Result<Dto_Proveedor_Exclusa?>.Ok(fila);
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

    public Task<ResultSp> ConfirmarDisponibilidadAsync(long solicitudId, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);

    public Task<ResultSp> CancelarDisponibilidadAsync(long solicitudId, string motivo, long usuarioId, CancellationToken ct = default)
        => _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddStrReq(p, "HV_Motivo", motivo);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
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

    private static Dto_Proveedor_Entrega MapEntrega(DbDataReader rd) => new()
    {
        ID_Solicitud           = RdLong(rd, "ID_Solicitud"),
        Codigo                 = RdStr(rd, "Codigo"),
        Fecha_Hora_Prevista    = RdDt(rd, "Fecha_Hora_Prevista"),
        Empresa_Proveedor      = RdStr(rd, "Empresa_Proveedor"),
        Proveedor_RUC          = RdStrN(rd, "Proveedor_RUC"),
        Empresa_Destino        = RdStrN(rd, "Empresa_Destino"),
        Empresa_Destino_Codigo = RdStrN(rd, "Empresa_Destino_Codigo"),
        Transportista          = RdStr(rd, "Transportista"),
        Telefono               = RdStrN(rd, "Telefono"),
        Placa                  = RdStrN(rd, "Placa"),
        Vehiculo_Marca         = RdStrN(rd, "Vehiculo_Marca"),
        Observaciones          = RdStrN(rd, "Observaciones"),
        Cantidad_Apoyo         = RdInt(rd, "Cantidad_Apoyo"),
        Estado_Operativo       = RdStr(rd, "Estado_Operativo"),
        Con_Desviacion         = RdBool(rd, "Con_Desviacion"),
        Disponibilidad_Confirmada = RdBool(rd, "Disponibilidad_Confirmada"),
        Fecha_Disponibilidad   = RdDtN(rd, "Fecha_Disponibilidad"),
        Fecha_Llegada          = RdDtN(rd, "Fecha_Llegada"),
        Fecha_Ingreso          = RdDtN(rd, "Fecha_Ingreso"),
        Fecha_Inicio_Atencion  = RdDtN(rd, "Fecha_Inicio_Atencion"),
        Fecha_Recepcion        = RdDtN(rd, "Fecha_Recepcion"),
        Fecha_Salida           = RdDtN(rd, "Fecha_Salida"),
        Resultado_Recepcion    = RdStrN(rd, "Resultado_Recepcion"),
        ID_Personal_Programado = RdLongN(rd, "ID_Personal_Programado"),
        Programado_Nombre      = RdStrN(rd, "Programado_Nombre"),
        Efectivo_Nombre        = RdStrN(rd, "Efectivo_Nombre"),
        Puede_Programar        = RdBool(rd, "Puede_Programar"),
        Puede_Confirmar        = RdBool(rd, "Puede_Confirmar"),
        Puede_Cancelar_Disp    = RdBool(rd, "Puede_Cancelar_Disp"),
        Puede_Atender          = RdBool(rd, "Puede_Atender"),
        Puede_Terminar         = RdBool(rd, "Puede_Terminar"),
        Motivo_Bloqueo         = RdStrN(rd, "Motivo_Bloqueo"),
        Es_Solicitante         = RdBool(rd, "Es_Solicitante"),
        Puede_Cancelar_Sol     = RdBool(rd, "Puede_Cancelar_Sol"),
        Motivo_No_Cancelar_Sol = RdStrN(rd, "Motivo_No_Cancelar_Sol"),
    };
}
