// ============================================================
// Archivo  : Repo_Catalogo_Item_Checklist.cs
// Ruta     : Infrastructure.Repositories/ControlAccesos/
// Módulo   : ControlAccesos
// Hito     : 1 — Catálogos del módulo
// Fase     : 4 — Repository
// Entidad  : Catalogo_Item_Checklist
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CATALOGO_ITEM_CHECKLIST_<ACCION>
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_catalogos.py).
// ============================================================

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Catalogo_Item_Checklist : RepoHelpers, IRepo_Catalogo_Item_Checklist
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Catalogo_Item_Checklist(EjecutorSp exec) => _exec = exec;

    // ── LISTAR ────────────────────────────────────────────────────
    public async Task<Result<List<Dto_Catalogo_Universal>>> ListarAsync(
        bool incluirEliminados = false, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CATALOGO_ITEM_CHECKLIST_LISTAR",
                bind: p =>
                {
                    AddChar1(p, "HV_Incluir_Eliminados", incluirEliminados ? "Y" : "N");
                },
                map: MapLista,
                ct: ct);
            return Result<List<Dto_Catalogo_Universal>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Catalogo_Universal>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    // ── CREAR ─────────────────────────────────────────────────
    public async Task<ResultSp<long>> CrearAsync(
        Dto_Catalogo_Universal dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraConIdAsync(
            clave: Conn,
            procedimiento: "ERP_CATALOGO_ITEM_CHECKLIST_CREAR",
            columnaId: "HV_ID_Catalogo_Item_Checklist_Result",
            bind: p =>
            {
                AddStrReq(p, "HV_Codigo", dto.Codigo);
                AddStrReq(p, "HV_Descripcion", dto.Descripcion);
                AddStr(p, "HV_Ayuda", dto.Ayuda);
                AddStr(p, "HV_Etapa", dto.Etapa);
                AddStr(p, "HV_Condicion", dto.Condicion);
                AddChar1(p, "HV_Es_Critico", dto.Es_Critico);
                AddLongReq(p, "HV_Orden", dto.Orden);
                AddChar1(p, "HV_Activo", dto.Activo ?? "Y");
                AddLongReq(p, "HV_UsuarioID_Create", usuarioId);
            },
            ct: ct);
    }

    // ── ACTUALIZAR ─────────────────────────────────────────────────
    public async Task<ResultSp> ActualizarAsync(
        long id, Dto_Catalogo_Universal dto, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CATALOGO_ITEM_CHECKLIST_ACTUALIZAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Catalogo_Item_Checklist", id);
                AddStrReq(p, "HV_Codigo", dto.Codigo);
                AddStrReq(p, "HV_Descripcion", dto.Descripcion);
                AddStr(p, "HV_Ayuda", dto.Ayuda);
                AddStr(p, "HV_Etapa", dto.Etapa);
                AddStr(p, "HV_Condicion", dto.Condicion);
                AddChar1(p, "HV_Es_Critico", dto.Es_Critico);
                AddLongReq(p, "HV_Orden", dto.Orden);
                AddChar1(p, "HV_Activo", dto.Activo ?? "Y");
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    // ── DETALLE ───────────────────────────────────────────────────
    public async Task<Result<Dto_Catalogo_Universal?>> DetalleAsync(long id, CancellationToken ct = default)
    {
        try
        {
            var dato = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CATALOGO_ITEM_CHECKLIST_DETALLE",
                bind: p => AddLongReq(p, "HV_ID_Catalogo_Item_Checklist", id),
                map: MapDetalle,
                ct: ct);
            return Result<Dto_Catalogo_Universal?>.Ok(dato);
        }
        catch (Exception ex)
        {
            return Result<Dto_Catalogo_Universal?>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    // ── ELIMINAR (borrado lógico) ─────────────────────────────────
    public async Task<ResultSp> EliminarAsync(long id, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CATALOGO_ITEM_CHECKLIST_ELIMINAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Catalogo_Item_Checklist", id);
                AddLongReq(p, "HV_UsuarioID_Update", usuarioId);
            },
            ct: ct);
    }

    // ── DROPDOWN (solo activos) ───────────────────────────────────
    public async Task<Result<List<Dto_Catalogo_Universal>>> ObtenerDropdownAsync(string? etapa, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CATALOGO_ITEM_CHECKLIST_DROPDOWN",
                bind: p =>
                {
                    AddStr(p, "HV_Etapa", etapa);
                },
                map: MapDropdown,
                ct: ct);
            return Result<List<Dto_Catalogo_Universal>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Catalogo_Universal>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

    private static Dto_Catalogo_Universal MapLista(DbDataReader rd) => new()
    {
        ID_Catalogo      = RdLong(rd, "ID_Catalogo"),
        Codigo           = RdStr(rd, "Codigo"),
        Descripcion      = RdStr(rd, "Descripcion"),
        Tipo_Entidad     = RdStrN(rd, "Tipo_Entidad"),
        Ayuda            = RdStrN(rd, "Ayuda"),
        Etapa            = RdStrN(rd, "Etapa"),
        Condicion        = RdStrN(rd, "Condicion"),
        Es_Critico       = RdStrN(rd, "Es_Critico"),
        Orden            = RdLong(rd, "Orden"),
        Activo           = RdStrN(rd, "Activo"),
        Eliminado        = RdStrN(rd, "Eliminado"),
        UsuarioID_Create = RdLongN(rd, "UsuarioID_Create"),
        Nombre_Usuario   = RdStrN(rd, "Nombre_Usuario"),
        UsuarioID_Update = RdLongN(rd, "UsuarioID_Update"),
        CreateDate       = RdDtN(rd, "CreateDate"),
        UpdateDate       = RdDtN(rd, "UpdateDate"),
    };

    private static Dto_Catalogo_Universal MapDetalle(DbDataReader rd) => new()
    {
        ID_Catalogo      = RdLong(rd, "ID_Catalogo"),
        Codigo           = RdStr(rd, "Codigo"),
        Descripcion      = RdStr(rd, "Descripcion"),
        Tipo_Entidad     = RdStrN(rd, "Tipo_Entidad"),
        Ayuda            = RdStrN(rd, "Ayuda"),
        Etapa            = RdStrN(rd, "Etapa"),
        Condicion        = RdStrN(rd, "Condicion"),
        Es_Critico       = RdStrN(rd, "Es_Critico"),
        Orden            = RdLong(rd, "Orden"),
        Activo           = RdStrN(rd, "Activo"),
        Eliminado        = RdStrN(rd, "Eliminado"),
        UsuarioID_Create = RdLongN(rd, "UsuarioID_Create"),
        Nombre_Usuario   = RdStrN(rd, "Nombre_Usuario"),
        UsuarioID_Update = RdLongN(rd, "UsuarioID_Update"),
        CreateDate       = RdDtN(rd, "CreateDate"),
        UpdateDate       = RdDtN(rd, "UpdateDate"),
    };

    private static Dto_Catalogo_Universal MapDropdown(DbDataReader rd) => new()
    {
        ID_Catalogo = RdLong(rd, "ID_Catalogo"),
        Codigo      = RdStr(rd, "Codigo"),
        Descripcion = RdStr(rd, "Descripcion"),
        Ayuda       = RdStrN(rd, "Ayuda"),
        Etapa       = RdStrN(rd, "Etapa"),
        Condicion   = RdStrN(rd, "Condicion"),
        Es_Critico  = RdStrN(rd, "Es_Critico"),
    };
}
