// ============================================================
// Archivo  : Repo_Solicitud.cs
// Ruta     : Infrastructure.Repositories/
// Módulo   : ControlAccesos
// Hito     : 2 — Solicitud y aprobación
// Fase     : 4 — Repository
// Entidad  : Solicitud
// Versión  : V1.0 — 2026-10-17
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// SP base  : ERP_CAF_SOLICITUD_<ACCION> (lecturas, CREAR, EDITAR_DATOS, CANCELAR)
// Conexión : ConexionesCaf.Modulo  (schema TRIANONSATELITAL_CAF_PRODD)
// Las firmas de bind salen de las firmas reales de las rutinas (gen_capas_solicitud.py).

using System.Data.Common;
using Application.DTOs.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.Persistence;
using Shared.Results;

namespace Infrastructure.Repositories.ControlAccesos;

public sealed class Repo_Solicitud : RepoHelpers, IRepo_Solicitud
{
    private readonly EjecutorSp _exec;
    private const string Conn = ConexionesCaf.Modulo;

    public Repo_Solicitud(EjecutorSp exec) => _exec = exec;

    public async Task<Result<List<string>>> EmpresasBuscarAsync(string? texto, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_EMPRESAS_BUSCAR",
                bind: p => AddStr(p, "HV_Texto", texto),
                map: rd => RdStr(rd, "Empresa"),
                ct: ct);
            return Result<List<string>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<string>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Tipo_Opcion>>> TiposOpcionesAsync(CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_TIPOS_OPCIONES",
                bind: _ => { },
                map: rd => new Dto_Solicitud_Tipo_Opcion
                {
                    ID_Catalogo_Tipo_Acceso = RdLong(rd, "ID_Catalogo_Tipo_Acceso"),
                    Codigo = RdStr(rd, "Codigo"),
                    Descripcion = RdStr(rd, "Descripcion"),
                    Usable = RdBool(rd, "Usable"),
                    Leyenda = RdStrN(rd, "Leyenda"),
                },
                ct: ct);
            return Result<List<Dto_Solicitud_Tipo_Opcion>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Solicitud_Tipo_Opcion>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Sede_Opcion>>> SedesOpcionesAsync(long usuarioId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_SEDES_OPCIONES",
                bind: p => AddLongReq(p, "HV_UsuarioID", usuarioId),
                map: rd => new Dto_Solicitud_Sede_Opcion
                {
                    ID_Catalogo_Sede = RdLong(rd, "ID_Catalogo_Sede"),
                    Codigo = RdStr(rd, "Codigo"),
                    Descripcion = RdStr(rd, "Descripcion"),
                    Aplica_Cochera = RdBool(rd, "Aplica_Cochera"),
                },
                ct: ct);
            return Result<List<Dto_Solicitud_Sede_Opcion>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Solicitud_Sede_Opcion>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Lista>>> MisListarAsync(long usuarioId, Dto_Filtro_Mis_Solicitudes? f = null, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_MIS_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLong(p, "HV_ID_Catalogo_Sede", f?.ID_Catalogo_Sede);
                    AddStr(p, "HV_Texto", f?.Texto);
                    AddStr(p, "HV_Estado", f?.Estado);
                    AddDate(p, "HV_Fecha_Desde", f?.Fecha_Desde);
                    AddDate(p, "HV_Fecha_Hasta", f?.Fecha_Hasta);
                },
                map: MapSolicitud_Lista,
                ct: ct);
            return Result<List<Dto_Solicitud_Lista>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Solicitud_Lista>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Bandeja>>> BandejaListarAsync(long usuarioId, Dto_Filtro_Bandeja? f = null, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_BANDEJA_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLong(p, "HV_ID_Catalogo_Sede", f?.ID_Catalogo_Sede);
                    AddStr(p, "HV_Pestana", string.IsNullOrWhiteSpace(f?.Pestana) ? "TODAS" : f!.Pestana);
                    AddStr(p, "HV_Empresa", f?.Empresa);
                    AddStr(p, "HV_Solicitante", f?.Solicitante);
                    AddStr(p, "HV_Persona", f?.Persona);
                    AddDate(p, "HV_Fecha", f?.Fecha);
                    AddStr(p, "HV_Estado", f?.Estado);
                },
                map: MapSolicitud_Bandeja,
                ct: ct);
            return Result<List<Dto_Solicitud_Bandeja>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Solicitud_Bandeja>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<Dto_Solicitud_Contadores?>> ContadoresAsync(long usuarioId, long? sedeId = null, CancellationToken ct = default)
    {
        try
        {
            var dato = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_CONTADORES",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLong(p, "HV_ID_Catalogo_Sede", sedeId);
                },
                map: MapSolicitud_Contadores,
                ct: ct);
            return Result<Dto_Solicitud_Contadores?>.Ok(dato);
        }
        catch (Exception ex)
        {
            return Result<Dto_Solicitud_Contadores?>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<Dto_Solicitud_Detalle?>> DetalleAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var dato = await _exec.EjecutarLecturaUnicaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_DETALLE",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                },
                map: MapSolicitud_Detalle,
                ct: ct);
            return Result<Dto_Solicitud_Detalle?>.Ok(dato);
        }
        catch (Exception ex)
        {
            return Result<Dto_Solicitud_Detalle?>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Persona>>> PersonasListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_PERSONAS_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                },
                map: MapSolicitud_Persona,
                ct: ct);
            return Result<List<Dto_Solicitud_Persona>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Solicitud_Persona>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Paso>>> PasosListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_PASOS_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                },
                map: MapSolicitud_Paso,
                ct: ct);
            return Result<List<Dto_Solicitud_Paso>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Solicitud_Paso>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Evento>>> HistorialListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_HISTORIAL_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                },
                map: MapSolicitud_Evento,
                ct: ct);
            return Result<List<Dto_Solicitud_Evento>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Solicitud_Evento>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<Result<List<Dto_Solicitud_Version>>> VersionesListarAsync(long usuarioId, long solicitudId, CancellationToken ct = default)
    {
        try
        {
            var lista = await _exec.EjecutarLecturaAsync(
                clave: Conn,
                funcion: "ERP_CAF_SOLICITUD_VERSION_LISTAR",
                bind: p =>
                {
                    AddLongReq(p, "HV_UsuarioID", usuarioId);
                    AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                },
                map: MapSolicitud_Version,
                ct: ct);
            return Result<List<Dto_Solicitud_Version>>.Ok(lista);
        }
        catch (Exception ex)
        {
            return Result<List<Dto_Solicitud_Version>>.Fail(ex.InnerException?.Message ?? ex.Message);
        }
    }

    public async Task<ResultSp<Dto_Solicitud_Creada>> CrearAsync(Dto_Solicitud_Crear dto, long usuarioId, CancellationToken ct = default)
    {
        var r = await _exec.EjecutarEscrituraConSalidasAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_SOLICITUD_CREAR",
            columnasSalida: new[] { "HV_ID_Solicitud_Result", "HV_Codigo_Solicitud_Result" },
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Catalogo_Sede", dto.ID_Catalogo_Sede);
                AddLongReq(p, "HV_ID_Catalogo_Tipo_Acceso", dto.ID_Catalogo_Tipo_Acceso);
                AddLongReq(p, "HV_ID_Personal_Responsable", dto.ID_Personal_Responsable);
                AddTimestamp(p, "HV_Fecha_Hora_Prevista", dto.Fecha_Hora_Prevista);
                AddStr(p, "HV_Empresa_Visitante", dto.Empresa_Visitante);
                AddLong(p, "HV_ID_Catalogo_Motivo_Visita", dto.ID_Catalogo_Motivo_Visita);
                AddStr(p, "HV_Motivo_Detalle", dto.Motivo_Detalle);
                AddStr(p, "HV_Observaciones", dto.Observaciones);
                AddStr(p, "HV_IDs_Zona", Ids(dto.IDs_Zona));
                AddStr(p, "HV_IDs_Persona_Externa", Ids(dto.IDs_Persona_Externa));
                AddStr(p, "HV_Copias", dto.Copias);
                AddLong(p, "HV_ID_Solicitud_Origen", dto.ID_Solicitud_Origen);
                AddStr(p, "HV_Requiere_Cochera", dto.Requiere_Cochera ? "Y" : "N");
                AddStr(p, "HV_Placa_Vehiculo", dto.Placa_Vehiculo);
                AddStr(p, "HV_Area_Detalle", dto.Area_Detalle);
                AddStr(p, "HV_Contacto_Nombre", dto.Contacto_Nombre);
                AddStr(p, "HV_Contacto_Telefonos", dto.Contacto_Telefonos);
                AddStr(p, "HV_Contacto_Correos", dto.Contacto_Correos);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
        if (!r.Ok || r.Data is null) return ResultSp<Dto_Solicitud_Creada>.Fail(r.Codigo, r.Mensaje);
        return ResultSp<Dto_Solicitud_Creada>.Success(new Dto_Solicitud_Creada
        {
            ID_Solicitud = Convert.ToInt64(r.Data["HV_ID_Solicitud_Result"] ?? 0L),
            Codigo = Convert.ToString(r.Data["HV_Codigo_Solicitud_Result"]) ?? string.Empty,
        }, r.Mensaje);
    }

    public async Task<ResultSp<bool>> EditarDatosAsync(long solicitudId, Dto_Solicitud_Editar dto, long usuarioId, CancellationToken ct = default)
    {
        var r = await _exec.EjecutarEscrituraConSalidasAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_SOLICITUD_EDITAR_DATOS",
            columnasSalida: new[] { "HV_Reabierta_Result" },
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddTimestamp(p, "HV_Fecha_Hora_Prevista", dto.Fecha_Hora_Prevista);
                AddStr(p, "HV_Empresa_Visitante", dto.Empresa_Visitante);
                AddLongReq(p, "HV_ID_Personal_Responsable", dto.ID_Personal_Responsable);
                AddLong(p, "HV_ID_Catalogo_Motivo_Visita", dto.ID_Catalogo_Motivo_Visita);
                AddStr(p, "HV_Motivo_Detalle", dto.Motivo_Detalle);
                AddStr(p, "HV_Observaciones", dto.Observaciones);
                AddStr(p, "HV_IDs_Zona", Ids(dto.IDs_Zona));
                AddStr(p, "HV_Copias", dto.Copias);
                AddStr(p, "HV_Requiere_Cochera", dto.Requiere_Cochera ? "Y" : "N");
                AddStr(p, "HV_Placa_Vehiculo", dto.Placa_Vehiculo);
                AddStr(p, "HV_Area_Detalle", dto.Area_Detalle);
                AddStr(p, "HV_Contacto_Nombre", dto.Contacto_Nombre);
                AddStr(p, "HV_Contacto_Telefonos", dto.Contacto_Telefonos);
                AddStr(p, "HV_Contacto_Correos", dto.Contacto_Correos);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
        if (!r.Ok || r.Data is null) return ResultSp<bool>.Fail(r.Codigo, r.Mensaje);
        return ResultSp<bool>.Success(string.Equals(Convert.ToString(r.Data["HV_Reabierta_Result"])?.Trim(), "Y", StringComparison.OrdinalIgnoreCase), r.Mensaje);
    }

    public async Task<ResultSp> CancelarAsync(long solicitudId, string? motivo, long usuarioId, CancellationToken ct = default)
    {
        return await _exec.EjecutarEscrituraAsync(
            clave: Conn,
            procedimiento: "ERP_CAF_SOLICITUD_CANCELAR",
            bind: p =>
            {
                AddLongReq(p, "HV_ID_Solicitud", solicitudId);
                AddStr(p, "HV_Motivo_Cancelacion", motivo);
                AddLongReq(p, "HV_UsuarioID", usuarioId);
            },
            ct: ct);
    }

    /// <summary>Lista de identificadores como texto separado por comas (formato de las rutinas).</summary>
    private static string Ids(IEnumerable<long>? ids)
        => ids is null ? string.Empty : string.Join(",", ids);

    // ══════════════════════════════════════════════════════════════
    // MAPPERS (columnas = las que devuelve cada rutina)
    // ══════════════════════════════════════════════════════════════

    private static Dto_Solicitud_Lista MapSolicitud_Lista(DbDataReader rd) => new()
    {
        ID_Solicitud                 = RdLong(rd, "ID_Solicitud"),
        Codigo                       = RdStr(rd, "Codigo"),
        ID_Catalogo_Sede             = RdLong(rd, "ID_Catalogo_Sede"),
        Sede                         = RdStr(rd, "Sede"),
        ID_Catalogo_Tipo_Acceso      = RdLong(rd, "ID_Catalogo_Tipo_Acceso"),
        Tipo_Acceso                  = RdStr(rd, "Tipo_Acceso"),
        Fecha_Hora_Prevista          = RdDt(rd, "Fecha_Hora_Prevista"),
        Empresa_Visitante            = RdStrN(rd, "Empresa_Visitante"),
        Estado                       = RdStr(rd, "Estado"),
        Avance                       = RdStrN(rd, "Avance"),
        Total_Personas               = RdInt(rd, "Total_Personas"),
        Autorizadas                  = RdInt(rd, "Autorizadas"),
        Observadas                   = RdInt(rd, "Observadas"),
        Pendientes                   = RdInt(rd, "Pendientes"),
        Rechazadas                   = RdInt(rd, "Rechazadas"),
        Retiradas                    = RdInt(rd, "Retiradas"),
        Responsable_Nombre           = RdStrN(rd, "Responsable_Nombre"),
        Codigo_Origen                = RdStrN(rd, "Codigo_Origen"),
        Fecha_Envio                  = RdDtN(rd, "Fecha_Envio"),
        CreateDate                   = RdDtN(rd, "CreateDate"),
        Puede_Editar_Datos           = RdBool(rd, "Puede_Editar_Datos"),
        Motivo_No_Editar_Datos       = RdStrN(rd, "Motivo_No_Editar_Datos"),
        Puede_Modificar_Personal     = RdBool(rd, "Puede_Modificar_Personal"),
        Motivo_No_Modificar_Personal = RdStrN(rd, "Motivo_No_Modificar_Personal"),
        Puede_Cancelar               = RdBool(rd, "Puede_Cancelar"),
        Motivo_No_Cancelar           = RdStrN(rd, "Motivo_No_Cancelar"),
        Puede_Reutilizar             = RdBool(rd, "Puede_Reutilizar"),
    };

    private static Dto_Solicitud_Bandeja MapSolicitud_Bandeja(DbDataReader rd) => new()
    {
        ID_Solicitud           = RdLong(rd, "ID_Solicitud"),
        Codigo                 = RdStr(rd, "Codigo"),
        ID_Catalogo_Sede       = RdLong(rd, "ID_Catalogo_Sede"),
        Sede                   = RdStr(rd, "Sede"),
        Tipo_Acceso            = RdStr(rd, "Tipo_Acceso"),
        Fecha_Hora_Prevista    = RdDt(rd, "Fecha_Hora_Prevista"),
        Es_Hoy                 = RdBool(rd, "Es_Hoy"),
        Empresa_Visitante      = RdStrN(rd, "Empresa_Visitante"),
        ID_Usuario_Solicitante = RdLongN(rd, "ID_Usuario_Solicitante"),
        Solicitante_Nombre     = RdStrN(rd, "Solicitante_Nombre"),
        Estado                 = RdStr(rd, "Estado"),
        Avance                 = RdStrN(rd, "Avance"),
        Total_Personas         = RdInt(rd, "Total_Personas"),
        Autorizadas            = RdInt(rd, "Autorizadas"),
        Observadas             = RdInt(rd, "Observadas"),
        Pendientes             = RdInt(rd, "Pendientes"),
        Rechazadas             = RdInt(rd, "Rechazadas"),
        Retiradas              = RdInt(rd, "Retiradas"),
        Por_Decidir_Mis        = RdInt(rd, "Por_Decidir_Mis"),
        Personas_Nombres       = RdStrN(rd, "Personas_Nombres"),
        Fecha_Envio            = RdDtN(rd, "Fecha_Envio"),
    };

    private static Dto_Solicitud_Contadores MapSolicitud_Contadores(DbDataReader rd) => new()
    {
        Mis_Con_Observadas      = RdInt(rd, "Mis_Con_Observadas"),
        Por_Decidir_Solicitudes = RdInt(rd, "Por_Decidir_Solicitudes"),
        Por_Decidir_Personas    = RdInt(rd, "Por_Decidir_Personas"),
    };

    private static Dto_Solicitud_Detalle MapSolicitud_Detalle(DbDataReader rd) => new()
    {
        ID_Solicitud                 = RdLong(rd, "ID_Solicitud"),
        Codigo                       = RdStr(rd, "Codigo"),
        ID_Catalogo_Sede             = RdLong(rd, "ID_Catalogo_Sede"),
        Sede                         = RdStr(rd, "Sede"),
        ID_Catalogo_Tipo_Acceso      = RdLong(rd, "ID_Catalogo_Tipo_Acceso"),
        Tipo_Acceso                  = RdStr(rd, "Tipo_Acceso"),
        Fecha_Hora_Prevista          = RdDt(rd, "Fecha_Hora_Prevista"),
        Empresa_Visitante            = RdStrN(rd, "Empresa_Visitante"),
        ID_Personal_Responsable      = RdLongN(rd, "ID_Personal_Responsable"),
        Responsable_Nombre           = RdStrN(rd, "Responsable_Nombre"),
        Responsable_Correo           = RdStrN(rd, "Responsable_Correo"),
        Responsable_Area             = RdStrN(rd, "Responsable_Area"),
        ID_Catalogo_Motivo_Visita    = RdLongN(rd, "ID_Catalogo_Motivo_Visita"),
        Motivo                       = RdStrN(rd, "Motivo"),
        Motivo_Detalle               = RdStrN(rd, "Motivo_Detalle"),
        Observaciones                = RdStrN(rd, "Observaciones"),
        Exige_SCTR                   = RdBool(rd, "Exige_SCTR"),
        Exige_EPP                    = RdBool(rd, "Exige_EPP"),
        Estado                       = RdStr(rd, "Estado"),
        Avance                       = RdStrN(rd, "Avance"),
        Version                      = RdLong(rd, "Version"),
        Fecha_Envio                  = RdDtN(rd, "Fecha_Envio"),
        ID_Usuario_Solicitante       = RdLongN(rd, "ID_Usuario_Solicitante"),
        Solicitante_Nombre           = RdStrN(rd, "Solicitante_Nombre"),
        Solicitante_Correo           = RdStrN(rd, "Solicitante_Correo"),
        Fecha_Decision               = RdDtN(rd, "Fecha_Decision"),
        Usuario_Decision_Nombre      = RdStrN(rd, "Usuario_Decision_Nombre"),
        Observacion_Coordinador      = RdStrN(rd, "Observacion_Coordinador"),
        Motivo_Cancelacion           = RdStrN(rd, "Motivo_Cancelacion"),
        ID_Solicitud_Origen          = RdLongN(rd, "ID_Solicitud_Origen"),
        Codigo_Origen                = RdStrN(rd, "Codigo_Origen"),
        Zonas_IDs                    = RdStrN(rd, "Zonas_IDs"),
        Zonas_Nombres                = RdStrN(rd, "Zonas_Nombres"),
        Tipo_Acceso_Codigo           = RdStrN(rd, "Tipo_Acceso_Codigo"),
        Requiere_Cochera             = RdBool(rd, "Requiere_Cochera"),
        Placa_Vehiculo               = RdStrN(rd, "Placa_Vehiculo"),
        Area_Detalle                 = RdStrN(rd, "Area_Detalle"),
        Contacto_Nombre              = RdStrN(rd, "Contacto_Nombre"),
        Contacto_Telefonos           = RdStrN(rd, "Contacto_Telefonos"),
        Contacto_Correos             = RdStrN(rd, "Contacto_Correos"),
        Copias                       = RdStrN(rd, "Copias"),
        CreateDate                   = RdDtN(rd, "CreateDate"),
        Total_Personas               = RdInt(rd, "Total_Personas"),
        Autorizadas                  = RdInt(rd, "Autorizadas"),
        Observadas                   = RdInt(rd, "Observadas"),
        Pendientes                   = RdInt(rd, "Pendientes"),
        Rechazadas                   = RdInt(rd, "Rechazadas"),
        Retiradas                    = RdInt(rd, "Retiradas"),
        Es_Propia                    = RdBool(rd, "Es_Propia"),
        Puede_Editar_Datos           = RdBool(rd, "Puede_Editar_Datos"),
        Motivo_No_Editar_Datos       = RdStrN(rd, "Motivo_No_Editar_Datos"),
        Puede_Modificar_Personal     = RdBool(rd, "Puede_Modificar_Personal"),
        Motivo_No_Modificar_Personal = RdStrN(rd, "Motivo_No_Modificar_Personal"),
        Puede_Cancelar               = RdBool(rd, "Puede_Cancelar"),
        Motivo_No_Cancelar           = RdStrN(rd, "Motivo_No_Cancelar"),
        Puede_Reutilizar             = RdBool(rd, "Puede_Reutilizar"),
        Puede_Decidir                = RdBool(rd, "Puede_Decidir"),
        Por_Decidir_Mis              = RdInt(rd, "Por_Decidir_Mis"),
    };

    private static Dto_Solicitud_Persona MapSolicitud_Persona(DbDataReader rd) => new()
    {
        ID_Solicitud_Persona       = RdLong(rd, "ID_Solicitud_Persona"),
        ID_Persona_Externa         = RdLong(rd, "ID_Persona_Externa"),
        ID_Catalogo_Tipo_Documento = RdLongN(rd, "ID_Catalogo_Tipo_Documento"),
        Tipo_Documento             = RdStrN(rd, "Tipo_Documento"),
        Numero_Documento           = RdStrN(rd, "Numero_Documento"),
        Apellido_Paterno           = RdStrN(rd, "Apellido_Paterno"),
        Apellido_Materno           = RdStrN(rd, "Apellido_Materno"),
        Nombres                    = RdStrN(rd, "Nombres"),
        Nombre_Completo            = RdStr(rd, "Nombre_Completo"),
        Aprobacion                 = RdStrN(rd, "Aprobacion"),
        Aprobacion_Mensaje         = RdStrN(rd, "Aprobacion_Mensaje"),
        Aprobado_Por_Nombre        = RdStrN(rd, "Aprobado_Por_Nombre"),
        Fecha_Aprobacion           = RdDtN(rd, "Fecha_Aprobacion"),
        Origen                     = RdStrN(rd, "Origen"),
        Estado                     = RdStr(rd, "Estado"),
        Acceso_Restringido         = RdBool(rd, "Acceso_Restringido"),
        Trae_Equipos               = RdBool(rd, "Trae_Equipos"),
        Trae_Herramientas          = RdBool(rd, "Trae_Herramientas"),
        Fecha_Hora_Ingreso         = RdDtN(rd, "Fecha_Hora_Ingreso"),
        Fecha_Hora_Salida          = RdDtN(rd, "Fecha_Hora_Salida"),
        Puede_Retirar              = RdBool(rd, "Puede_Retirar"),
        Puede_Corregir             = RdBool(rd, "Puede_Corregir"),
        Puede_Reactivar            = RdBool(rd, "Puede_Reactivar"),
        Puede_Decidir              = RdBool(rd, "Puede_Decidir"),
        Pasos_Mis_Decidir          = RdStrN(rd, "Pasos_Mis_Decidir"),
    };

    private static Dto_Solicitud_Paso MapSolicitud_Paso(DbDataReader rd) => new()
    {
        ID_Solicitud_Persona           = RdLong(rd, "ID_Solicitud_Persona"),
        Persona_Nombre                 = RdStr(rd, "Persona_Nombre"),
        ID_Tipo_Acceso_Paso_Aprobacion = RdLong(rd, "ID_Tipo_Acceso_Paso_Aprobacion"),
        Paso_Orden                     = RdLong(rd, "Paso_Orden"),
        Paso_Codigo                    = RdStr(rd, "Paso_Codigo"),
        Paso_Descripcion               = RdStrN(rd, "Paso_Descripcion"),
        Paso_Alcance                   = RdStrN(rd, "Paso_Alcance"),
        Obligatorio                    = RdBool(rd, "Obligatorio"),
        Rol_Aprobador                  = RdStrN(rd, "Rol_Aprobador"),
        Decision                       = RdStr(rd, "Decision"),
        Mensaje                        = RdStrN(rd, "Mensaje"),
        Decidio_Nombre                 = RdStrN(rd, "Decidio_Nombre"),
        Fecha_Decision                 = RdDtN(rd, "Fecha_Decision"),
        Es_Mi_Turno                    = RdBool(rd, "Es_Mi_Turno"),
    };

    private static Dto_Solicitud_Evento MapSolicitud_Evento(DbDataReader rd) => new()
    {
        ID_Evento      = RdLong(rd, "ID_Evento"),
        Fecha_Evento   = RdDt(rd, "Fecha_Evento"),
        Entidad        = RdStr(rd, "Entidad"),
        Accion         = RdStr(rd, "Accion"),
        Accion_Texto   = RdStr(rd, "Accion_Texto"),
        Detalle        = RdStrN(rd, "Detalle"),
        ID_Usuario     = RdLongN(rd, "ID_Usuario"),
        Usuario_Nombre = RdStrN(rd, "Usuario_Nombre"),
    };

    private static Dto_Solicitud_Version MapSolicitud_Version(DbDataReader rd) => new()
    {
        Version              = RdLong(rd, "Version"),
        Fecha_Aprobacion     = RdDtN(rd, "Fecha_Aprobacion"),
        ID_Usuario_Aprobador = RdLongN(rd, "ID_Usuario_Aprobador"),
        Aprobador_Nombre     = RdStrN(rd, "Aprobador_Nombre"),
        Contenido_JSON       = RdStrN(rd, "Contenido_JSON"),
    };
}
