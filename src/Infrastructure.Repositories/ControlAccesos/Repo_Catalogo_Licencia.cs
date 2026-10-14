// ============================================================
// Archivo  : Repo_Catalogo_Licencia.cs
// Ruta     : Infrastructure.Repositories/ControlAccesos/
// Módulo   : ControlAccesos
// Hito     : 0 — Base
// Fase     : 4 — Repository
// Entidad  : Catalogo_Licencia
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CATALOGO_LICENCIA_<ACCION>
// Conexión : ConexionesCaf.Gobierno  (schema CAF_GOVERNANCE)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_catalogos.py).
// ============================================================

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Catalogo_Licencia : RepoHelpers, IRepo_Catalogo_Licencia
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Gobierno;

    public Repo_Catalogo_Licencia(EjecutorSp exec) => _exec = exec;

    // ── LISTAR ────────────────────────────────────────────────────
    public async Task<Result<List<Dto_Catalogo_Universal>>> ListarAsync(
        bool incluirEliminados = false, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CATALOGO_LICENCIA_LISTAR",
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

    // ── DROPDOWN (solo activos) ───────────────────────────────────
    public async Task<Result<List<Dto_Catalogo_Universal>>> ObtenerDropdownAsync(CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CATALOGO_LICENCIA_DROPDOWN",
                bind: p =>
                {
                    // sin parámetros
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
    };
}
