// D-265: documentos de ingreso. Valida el archivo en el servidor y traduce la respuesta de las rutinas (D-40).

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Microsoft.Extensions.Logging;
using Shared.Results;

namespace Application.Services.ControlAccesos;

public sealed class Srv_Documento_Ingreso : ISrv_Documento_Ingreso
{
    private readonly IRepo_Documento_Ingreso _repo;
    private readonly ILogger<Srv_Documento_Ingreso> _logger;

    public Srv_Documento_Ingreso(IRepo_Documento_Ingreso repo, ILogger<Srv_Documento_Ingreso> logger) { _repo = repo; _logger = logger; }

    private static string? Ids(IEnumerable<long>? ids)
    {
        var l = (ids ?? Enumerable.Empty<long>()).Where(x => x > 0).Distinct().ToList();
        return l.Count == 0 ? null : string.Join(",", l);
    }

    public async Task<Result<long>> AgregarAsync(long sedeId, DateTime fecha, string tipo, string nombreArchivo, byte[] contenido, IEnumerable<long> personasIds, long usuarioId, CancellationToken ct = default)
    {
        var error = ValidadorDocumentosIngreso.Validar(nombreArchivo, contenido, out var nombre, out var ext);
        if (error is not null) return Result<long>.Validation("Datos inválidos.", new[] { new ResultError("Archivo", error) });
        if (!ValidadorDocumentosIngreso.Tipos.Contains(tipo ?? string.Empty)) return Result<long>.Fail("Elija el tipo de documento.", MapeoSp.Codigo(400));
        var ids = Ids(personasIds);
        if (ids is null) return Result<long>.Fail("Elija al menos una persona.", MapeoSp.Codigo(400));
        try
        {
            var tc = ext == "pdf" ? "application/pdf" : ext == "png" ? "image/png" : "image/jpeg";
            var sp = await _repo.AgregarAsync(sedeId, fecha.Date, tipo!, nombre, tc, contenido, ids, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result<long>.Ok(sp.Data!, sp.Mensaje) : Result<long>.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "DOC_INGRESO_AGREGAR ERROR");
            return Result<long>.Fail("No se pudo guardar el documento.");
        }
    }

    public async Task<Result> AsignarPersonasAsync(long documentoId, IEnumerable<long> personasIds, long usuarioId, CancellationToken ct = default)
    {
        var ids = Ids(personasIds);
        if (ids is null) return Result.Fail("Elija al menos una persona.", MapeoSp.Codigo(400));
        try
        {
            var sp = await _repo.AsignarPersonasAsync(documentoId, ids, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "DOC_INGRESO_ASIGNAR ID={ID} ERROR", documentoId); return Result.Fail("No se pudieron actualizar las personas."); }
    }

    public async Task<Result> QuitarAsync(long documentoId, long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var sp = await _repo.QuitarAsync(documentoId, usuarioId, ct).ConfigureAwait(false);
            return sp.Ok ? Result.Ok(sp.Mensaje) : Result.Fail(sp.Mensaje, MapeoSp.Codigo(sp.Codigo));
        }
        catch (Exception ex) { _logger.LogError(ex, "DOC_INGRESO_QUITAR ID={ID} ERROR", documentoId); return Result.Fail("No se pudo retirar el documento."); }
    }

    public Task<Result<List<Dto_Documento_Ingreso>>> ListarAsync(long usuarioId, long sedeId, DateTime fecha, CancellationToken ct = default)
        => _repo.ListarAsync(usuarioId, sedeId, fecha.Date, ct);

    public Task<Result<List<Dto_Documento_Ingreso_Busqueda>>> BuscarAsync(long usuarioId, long sedeId, DateTime? desde, DateTime? hasta, string? texto, CancellationToken ct = default)
        => _repo.BuscarAsync(usuarioId, sedeId, desde?.Date, hasta?.Date, string.IsNullOrWhiteSpace(texto) ? null : texto.Trim(), ct);

    public Task<Result<Dto_Documento_Ingreso_Contenido?>> ObtenerAsync(long usuarioId, long documentoId, CancellationToken ct = default)
        => _repo.ObtenerAsync(usuarioId, documentoId, ct);

    public Task<Result<List<Dto_Documento_Ingreso_Persona>>> PersonasDiaAsync(long usuarioId, long sedeId, DateTime fecha, string? texto, bool soloConEquipos, CancellationToken ct = default)
        => _repo.PersonasDiaAsync(usuarioId, sedeId, fecha.Date, string.IsNullOrWhiteSpace(texto) ? null : texto.Trim(), soloConEquipos, ct);

    public Task<Result<Dto_Documento_Ingreso_Resumen?>> ResumenAsync(long usuarioId, long sedeId, DateTime fecha, CancellationToken ct = default)
        => _repo.ResumenAsync(usuarioId, sedeId, fecha.Date, ct);

    public Task<Result<List<Dto_Documento_Ingreso_Solicitud>>> DeSolicitudAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
        => _repo.DeSolicitudAsync(usuarioId, solicitudId, ct);
}
