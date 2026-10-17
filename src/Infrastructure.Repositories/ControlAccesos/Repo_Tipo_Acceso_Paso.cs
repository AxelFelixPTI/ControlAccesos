// ============================================================
// Archivo  : Repo_Tipo_Acceso_Paso.cs
// Ruta     : Infrastructure.Repositories/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 4 — Repository
// Entidad  : Tipo_Acceso_Paso
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_TIPO_ACCESO_PASO_<ACCION>
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Tipo_Acceso_Paso : RepoHelpers, IRepo_Tipo_Acceso_Paso
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Tipo_Acceso_Paso(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<Dto_Tipo_Acceso_Paso>>> ListarPorPadreAsync(long tipoAccesoId, bool incluirInactivos = false, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_TIPO_ACCESO_PASO_LISTAR_POR_PADRE",
                bind: p =>
                {
                    AddLongReq(p, "HV_ID_Catalogo_Tipo_Acceso", tipoAccesoId);
                    AddChar1(p, "HV_Incluir_Inactivos", incluirInactivos ? "Y" : "N");
                },
                map: MapTipo_Acceso_Paso,
                ct: ct);
            return Result<List<Dto_Tipo_Acceso_Paso>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Tipo_Acceso_Paso>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<ResultSp<long>> AgregarAsync(Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraConIdAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_TIPO_ACCESO_PASO_AGREGAR",
            columnaId: "HV_ID_Tipo_Acceso_Paso_Aprobacion_Result",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Catalogo_Tipo_Acceso", dto.ID_Catalogo_Tipo_Acceso);
                AddLongReq(p, "HV_Orden", dto.Orden);
                AddStrReq(p, "HV_Codigo", dto.Codigo);
                AddStrReq(p, "HV_Descripcion", dto.Descripcion);
                AddStrReq(p, "HV_Alcance", dto.Alcance);
                AddStrReq(p, "HV_Tipo_Aprobador", dto.Tipo_Aprobador);
                AddLongReq(p, "HV_ID_Catalogo_Licencia", dto.ID_Catalogo_Licencia);
                AddStrReq(p, "HV_Condicion", dto.Condicion);
                AddChar1(p, "HV_Obligatorio", dto.Obligatorio ? "Y" : "N");
                AddLongReq(p, "HV_UsuarioID_Create", usuarioId);
            },
            ct: ct);
    }

    public async Task<ResultSp> ActualizarAsync(long pasoId, Dto_Tipo_Acceso_Paso_Entrada dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_TIPO_ACCESO_PASO_ACTUALIZAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Tipo_Acceso_Paso_Aprobacion", pasoId);
                AddLongReq(p, "HV_Orden", dto.Orden);
                AddStrReq(p, "HV_Descripcion", dto.Descripcion);
                AddStrReq(p, "HV_Alcance", dto.Alcance);
                AddLongReq(p, "HV_ID_Catalogo_Licencia", dto.ID_Catalogo_Licencia);
                AddChar1(p, "HV_Obligatorio", dto.Obligatorio ? "Y" : "N");
                AddChar1(p, "HV_Activo", dto.Activo ? "Y" : "N");
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    public async Task<ResultSp> QuitarAsync(long pasoId, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_TIPO_ACCESO_PASO_QUITAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Tipo_Acceso_Paso_Aprobacion", pasoId);
                AddLongReq(p, "HV_UsuarioID_Update", usuarioId);
            },
            ct: ct);
    }

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

    private static Dto_Tipo_Acceso_Paso MapTipo_Acceso_Paso(DbDataReader rd) => new()
    {
        ID_Tipo_Acceso_Paso_Aprobacion = RdLong(rd, "ID_Tipo_Acceso_Paso_Aprobacion"),
        ID_Catalogo_Tipo_Acceso        = RdLong(rd, "ID_Catalogo_Tipo_Acceso"),
        Orden                          = RdLong(rd, "Orden"),
        Codigo                         = RdStr(rd, "Codigo"),
        Descripcion                    = RdStrN(rd, "Descripcion"),
        Alcance                        = RdStrN(rd, "Alcance"),
        Tipo_Aprobador                 = RdStrN(rd, "Tipo_Aprobador"),
        ID_Catalogo_Licencia           = RdLongN(rd, "ID_Catalogo_Licencia"),
        Codigo_Licencia                = RdStrN(rd, "Codigo_Licencia"),
        Rol                            = RdStrN(rd, "Rol"),
        Condicion                      = RdStrN(rd, "Condicion"),
        Obligatorio                    = RdBool(rd, "Obligatorio"),
        Activo                         = RdBool(rd, "Activo"),
        CreateDate                     = RdDtN(rd, "CreateDate"),
    };
}
