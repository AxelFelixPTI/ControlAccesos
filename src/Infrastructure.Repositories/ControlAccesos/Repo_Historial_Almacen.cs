// ============================================================
// D-273/D-274. SP: ERP_CAF_PROVEEDOR_HISTORIAL_ALMACEN. Conexión: ConexionesCaf.Modulo.
// ============================================================

using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Historial_Almacen : RepoHelpers, IRepo_Historial_Almacen
{
    private readonly EjecutorSp _exec;
    private readonly ILogger<Repo_Historial_Almacen> _log;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Historial_Almacen(EjecutorSp exec, ILogger<Repo_Historial_Almacen> log) { _exec = exec; _log = log; }

    public async Task<Result<List<Dto_Historial_Almacen>>> ListarAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, string? texto, long? empresaId, string? estado, string? conVehiculo, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(Conn, "ERP_CAF_PROVEEDOR_HISTORIAL_ALMACEN",
                p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId); AddLongReq(p, "HV_ID_Catalogo_Sede", sedeId);
                    AddDate(p, "HV_Desde", desde); AddDate(p, "HV_Hasta", hasta); AddStr(p, "HV_Texto", texto);
                    AddLong(p, "HV_ID_Empresa", empresaId); AddStr(p, "HV_Estado", estado); AddChar1(p, "HV_Con_Vehiculo", conVehiculo);
                },
                rd => new Dto_Historial_Almacen
                {
                    ID_Solicitud = RdLong(rd, "ID_Solicitud"), Codigo = RdStr(rd, "Codigo"), Fecha_Entrega = RdDt(rd, "Fecha_Entrega"), Proveedor = RdStr(rd, "Proveedor"),
                    Solicitante = RdStrN(rd, "Solicitante"), ID_Empresa = RdLong(rd, "ID_Empresa"), Empresa_Codigo = RdStr(rd, "Empresa_Codigo"), Empresa = RdStr(rd, "Empresa"),
                    Estado = RdStr(rd, "Estado"), Reservo = RdStrN(rd, "Reservo"), Inicio_Nombre = RdStrN(rd, "Inicio_Nombre"), Fecha_Inicio = RdDtN(rd, "Fecha_Inicio"),
                    Fin_Nombre = RdStrN(rd, "Fin_Nombre"), Fecha_Fin = RdDtN(rd, "Fecha_Fin"), Minutos_Activos = RdIntN(rd, "Minutos_Activos"), Pausas = RdInt(rd, "Pausas"),
                    Minutos_Pausa = RdInt(rd, "Minutos_Pausa"), Con_Vehiculo = RdStrN(rd, "Con_Vehiculo"), Resultado = RdStrN(rd, "Resultado"),
                    Motivo_Sin_Atencion = RdStrN(rd, "Motivo_Sin_Atencion"), Observacion = RdStrN(rd, "Observacion"),
                    Numeros_OC = RdStrN(rd, "Numeros_OC"), Placa = RdStrN(rd, "Placa"), Conductor = RdStrN(rd, "Conductor"), Empresa_Transportista = RdStrN(rd, "Empresa_Transportista"),
                    Hora_Hasta = RdStrN(rd, "Hora_Hasta"), Estado_Entrega = RdStrN(rd, "Estado_Entrega"), Fecha_Llegada = RdDtN(rd, "Fecha_Llegada"), Fecha_Ingreso = RdDtN(rd, "Fecha_Ingreso"),
                    Fecha_Disponibilidad = RdDtN(rd, "Fecha_Disponibilidad"), Fecha_Salida = RdDtN(rd, "Fecha_Salida"), Minutos_Desvio = RdIntN(rd, "Minutos_Desvio"), Fuera_Franja = RdStrN(rd, "Fuera_Franja"),
                }, ct);
            return Result<List<Dto_Historial_Almacen>>.Ok(lista);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _log.LogError(ex, "PROVEEDOR_HISTORIAL_ALMACEN ERROR");
            return Result<List<Dto_Historial_Almacen>>.Fail("No se pudo cargar el historial de Almacén.");
        }
    }
}
