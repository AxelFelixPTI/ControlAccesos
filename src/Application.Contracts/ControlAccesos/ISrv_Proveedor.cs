// ============================================================
// Archivo  : ISrv_Proveedor.cs
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación (Entrega 2 de Proveedor de abastecimiento)
// Versión  : V1.0 — 2026-11-03
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Application.Contracts.ControlAccesos;

public interface ISrv_Proveedor
{
    Task<Result<List<Dto_Proveedor_Entrega>>> CalendarioAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, CancellationToken ct = default);
    Task<Result<List<Dto_Proveedor_Responsable>>> ResponsablesAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<Result<Dto_Proveedor_Exclusa?>> ExclusaEstadoAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<Result> ProgramarAsync(long solicitudId, long? personalId, long usuarioId, CancellationToken ct = default);
    /// <summary>D-261: plazas = cuántas plazas de la esclusa reserva la entrega (1 por defecto).</summary>
    Task<Result> ConfirmarDisponibilidadAsync(long solicitudId, bool conVehiculo, long usuarioId, int plazas = 1, CancellationToken ct = default);
    /// <summary>D-260: estado de la esclusa y de las otras entregas al abrir «Confirmar disponibilidad».</summary>
    Task<Result<List<Dto_Proveedor_IngresoVeh_Estado>>> IngresoVehEstadoAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    /// <summary>D-260: solicitudes de ingreso vehicular vigentes de la sede.</summary>
    Task<Result<List<Dto_Proveedor_IngresoVeh_Solicitud>>> IngresoVehListarAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    /// <summary>D-260: pide la conformidad del almacenero con la entrega en curso para confirmar CON ingreso vehicular.</summary>
    Task<Result> IngresoVehSolicitarAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    /// <summary>D-260: el solicitante retira su solicitud pendiente.</summary>
    Task<Result> IngresoVehRetirarAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    /// <summary>D-263: liberación temprana de plazas (solo entregas de más de 1 vehículo).</summary>
    Task<Result> PlazaLiberarAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Proveedor_Plaza>>> PlazasListarAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<Result<List<Dto_Proveedor_Vehiculo>>> VehiculosListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default);
    /// <summary>D-260: el almacenero en curso (o el Coordinador de Almacén) confirma o rechaza; el motivo del rechazo es opcional.</summary>
    Task<Result> IngresoVehResponderAsync(long solicitudIngresoId, string accion, string? motivo, long usuarioId, CancellationToken ct = default);
    /// <summary>Vigilancia: ingreso físico de un proveedor ya verificado y con Almacén listo.</summary>
    Task<Result> ValidarIngresoAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    /// <summary>Vigilancia: el proveedor verificado se retira sin ingresar (motivo obligatorio).</summary>
    Task<Result> RetiroSinIngresoAsync(long solicitudId, string? motivo, long usuarioId, CancellationToken ct = default);
    /// <summary>D-225: Vigilancia registra el ingreso físico de las personas indicadas (ya verificadas), respetando la capacidad de la exclusa.</summary>
    Task<Result> IngresoFisicoAsync(long solicitudId, IReadOnlyCollection<long> idsPersona, long usuarioId, CancellationToken ct = default);
    /// <summary>D-225: Vigilancia marca que las personas indicadas se retiraron sin ingresar (motivo obligatorio).</summary>
    Task<Result> RetiroPersonasAsync(long solicitudId, IReadOnlyCollection<long> idsPersona, string? motivo, long usuarioId, CancellationToken ct = default);
    /// <summary>D-225: verificación de datos de varias personas con un solo checklist (todo o nada).</summary>
    Task<Result> VerificarGrupoAsync(Dto_Proveedor_Grupo dto, long usuarioId, CancellationToken ct = default);
    /// <summary>D-225: salida de varias personas con un solo checklist (todo o nada).</summary>
    Task<Result> SalidaGrupoAsync(Dto_Proveedor_Grupo dto, long usuarioId, CancellationToken ct = default);
    Task<Result> AtenderAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<Result> TerminarAsync(long solicitudId, string? observacion, long usuarioId, CancellationToken ct = default);
    /// <summary>D-238: estado de la atención de cada empresa de la entrega y lo que puede hacer el usuario en cada una.</summary>
    Task<Result<List<Dto_Atencion_Empresa>>> AtencionListarAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<Result<List<Dto_Motivo_Sin_Atencion>>> MotivosSinAtencionAsync(CancellationToken ct = default);
    /// <summary>D-238: Almacén inicia la atención de UNA empresa de la entrega (solo las que él atiende y están en el pedido).</summary>
    Task<Result> AtenderEmpresaAsync(long solicitudId, long empresaId, long usuarioId, CancellationToken ct = default);
    /// <summary>D-238: Almacén termina la atención de una empresa. Sin observación la recepción es conforme.</summary>
    Task<Result> TerminarEmpresaAsync(long solicitudId, long empresaId, string? observacion, long usuarioId, CancellationToken ct = default);
    /// <summary>D-238: la empresa no será atendida (motivo de la lista; «Otro» exige detalle).</summary>
    // D-239: varias empresas a la vez, detener y reanudar (solo quien inició la atención)
    Task<Result> AtenderEmpresasAsync(long solicitudId, IEnumerable<long> empresasIds, long usuarioId, CancellationToken ct = default);
    Task<Result> DetenerEmpresasAsync(long solicitudId, IEnumerable<long> empresasIds, string? motivo, long usuarioId, CancellationToken ct = default);
    Task<Result> ReanudarEmpresasAsync(long solicitudId, IEnumerable<long> empresasIds, long usuarioId, CancellationToken ct = default);
    Task<Result> TerminarEmpresasAsync(long solicitudId, IEnumerable<long> empresasIds, string? observacion, long usuarioId, bool liberarPlaza = false, CancellationToken ct = default);
    Task<Result> CerrarSinAtencionAsync(long solicitudId, long empresaId, long motivoId, string? detalle, long usuarioId, CancellationToken ct = default);
    // D-244: panel de cupos y Ceder/Tomar la reserva
    Task<Result<List<Dto_Proveedor_Cupo>>> CuposAsync(long usuarioId, long sedeId, CancellationToken ct = default);
    Task<Result> CederReservaAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
    Task<Result> TomarReservaAsync(long solicitudId, long usuarioId, CancellationToken ct = default);
}
