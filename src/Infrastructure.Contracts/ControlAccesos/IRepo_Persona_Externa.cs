// ============================================================
// Persona externa — registro de visitantes (ERP_CAF_PERSONA_EXTERNA_*, schema del módulo). Se buscan por documento;
// si ya existen se reutilizan, si no se crean. Las reglas (duplicados, documento válido) viven en los procedimientos.
// ============================================================

using Application.DTOs.ControlAccesos;
using Shared.Results;

namespace Infrastructure.Contracts.ControlAccesos;

public interface IRepo_Persona_Externa
{
    Task<Result<Dto_Persona_Externa?>> PorDocumentoAsync(long tipoDocumentoId, string numeroDocumento, CancellationToken ct = default);
    Task<ResultSp<long>> CrearAsync(Dto_Persona_Externa dto, long usuarioId, CancellationToken ct = default);
    Task<ResultSp> ActualizarAsync(long id, Dto_Persona_Externa dto, long usuarioId, CancellationToken ct = default);
}
