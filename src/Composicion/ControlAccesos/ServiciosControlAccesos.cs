// ============================================================
// Archivo  : ServiciosControlAccesos.cs
// Ruta     : Composicion/ControlAccesos/
// Módulo   : ControlAccesos
// Paso     : Arranque — registro de dependencias
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// UNICO lugar que sabe qué clase implementa cada interfaz. La consola y la futura web llaman a
// AddControlAccesos(configuration) y reciben todo armado.
// Cadenas de conexión (appsettings, sección ConnectionStrings), una por schema; cada una DEBE llevar
// "Search Path=...". Generado desde los archivos Repo_* / Srv_* existentes (se regenera al añadir entidades).
// ============================================================

using Application.Contracts.ControlAccesos;
using Application.Services.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.ExternalServices.ControlAccesos;
using Infrastructure.Persistence;
using Infrastructure.Repositories.ControlAccesos;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Composicion.ControlAccesos;

public static class ServiciosControlAccesos
{
    public static IServiceCollection AddControlAccesos(this IServiceCollection s, IConfiguration config)
    {
        // ── Conexión (la única pieza que conoce el motor) ───────────
        var cadenas = new Dictionary<string, string>
        {
            [ConexionesCaf.Gobierno] = Cadena(config, ConexionesCaf.Gobierno),
            [ConexionesCaf.Modulo]   = Cadena(config, ConexionesCaf.Modulo),
        };
        s.AddSingleton<IConexionFactory>(new ConexionPostgres(cadenas));
        s.AddSingleton<EjecutorSp>();

        // ── Repositorios ────────────────────────────────────────────
        s.AddScoped<IRepo_Personal, Repo_Personal>();
        s.AddScoped<IRepo_Persona_Externa, Repo_Persona_Externa>();
        s.AddScoped<IRepo_Catalogo_Area, Repo_Catalogo_Area>();
        s.AddScoped<IRepo_Catalogo_Cargo, Repo_Catalogo_Cargo>();
        s.AddScoped<IRepo_Catalogo_Empresa_Grupo, Repo_Catalogo_Empresa_Grupo>();
        s.AddScoped<IRepo_Catalogo_Item_Checklist, Repo_Catalogo_Item_Checklist>();
        s.AddScoped<IRepo_Catalogo_Licencia, Repo_Catalogo_Licencia>();
        s.AddScoped<IRepo_Catalogo_Motivo_Visita, Repo_Catalogo_Motivo_Visita>();
        s.AddScoped<IRepo_Catalogo_Sede, Repo_Catalogo_Sede>();
        s.AddScoped<IRepo_Catalogo_Tipo_Acceso, Repo_Catalogo_Tipo_Acceso>();
        s.AddScoped<IRepo_Catalogo_Tipo_Documento, Repo_Catalogo_Tipo_Documento>();
        s.AddScoped<IRepo_Catalogo_Tipo_Incidencia, Repo_Catalogo_Tipo_Incidencia>();
        s.AddScoped<IRepo_Catalogo_Tratamiento_Desviacion, Repo_Catalogo_Tratamiento_Desviacion>();
        s.AddScoped<IRepo_Catalogo_Zona_Acceso, Repo_Catalogo_Zona_Acceso>();
        s.AddScoped<IRepo_Correo, Repo_Correo>();
        s.AddScoped<IRepo_Desviacion, Repo_Desviacion>();
        s.AddScoped<IRepo_Incidencia, Repo_Incidencia>();
        s.AddScoped<IRepo_Porteria, Repo_Porteria>();
        s.AddScoped<IRepo_Reporte, Repo_Reporte>();
        s.AddScoped<IRepo_Respaldo, Repo_Respaldo>();
        s.AddScoped<IRepo_Solicitud, Repo_Solicitud>();
        s.AddScoped<IRepo_Solicitud_Decision, Repo_Solicitud_Decision>();
        s.AddScoped<IRepo_Solicitud_Persona, Repo_Solicitud_Persona>();
        s.AddScoped<IRepo_Solicitud_Vigilancia, Repo_Solicitud_Vigilancia>();
        s.AddScoped<IRepo_Tipo_Acceso_Paso, Repo_Tipo_Acceso_Paso>();
        s.AddScoped<IRepo_Usuario, Repo_Usuario>();

        // ── Servicios ───────────────────────────────────────────────
        s.AddScoped<ISrv_Personal, Srv_Personal>();
        s.AddScoped<ISrv_Persona_Externa, Srv_Persona_Externa>();
        s.AddScoped<ISrv_Catalogo_Area, Srv_Catalogo_Area>();
        s.AddScoped<ISrv_Catalogo_Cargo, Srv_Catalogo_Cargo>();
        s.AddScoped<ISrv_Catalogo_Empresa_Grupo, Srv_Catalogo_Empresa_Grupo>();
        s.AddScoped<ISrv_Catalogo_Item_Checklist, Srv_Catalogo_Item_Checklist>();
        s.AddScoped<ISrv_Catalogo_Licencia, Srv_Catalogo_Licencia>();
        s.AddScoped<ISrv_Catalogo_Motivo_Visita, Srv_Catalogo_Motivo_Visita>();
        s.AddScoped<ISrv_Catalogo_Sede, Srv_Catalogo_Sede>();
        s.AddScoped<ISrv_Catalogo_Tipo_Acceso, Srv_Catalogo_Tipo_Acceso>();
        s.AddScoped<ISrv_Catalogo_Tipo_Documento, Srv_Catalogo_Tipo_Documento>();
        s.AddScoped<ISrv_Catalogo_Tipo_Incidencia, Srv_Catalogo_Tipo_Incidencia>();
        s.AddScoped<ISrv_Catalogo_Tratamiento_Desviacion, Srv_Catalogo_Tratamiento_Desviacion>();
        s.AddScoped<ISrv_Catalogo_Zona_Acceso, Srv_Catalogo_Zona_Acceso>();
        s.AddScoped<ISrv_Correo, Srv_Correo>();
        s.AddScoped<ISrv_Desviacion, Srv_Desviacion>();
        s.AddScoped<ISrv_Incidencia, Srv_Incidencia>();
        s.AddScoped<ISrv_Porteria, Srv_Porteria>();
        s.AddScoped<ISrv_Reporte, Srv_Reporte>();
        s.AddScoped<ISrv_Respaldo, Srv_Respaldo>();
        s.AddScoped<ISrv_Solicitud, Srv_Solicitud>();
        s.AddScoped<ISrv_Solicitud_Decision, Srv_Solicitud_Decision>();
        s.AddScoped<ISrv_Solicitud_Persona, Srv_Solicitud_Persona>();
        s.AddScoped<ISrv_Solicitud_Vigilancia, Srv_Solicitud_Vigilancia>();
        s.AddScoped<ISrv_Tipo_Acceso_Paso, Srv_Tipo_Acceso_Paso>();
        s.AddScoped<ISrv_Usuario, Srv_Usuario>();
        s.AddScoped<ISrv_Auth, Srv_Auth>();
        s.AddScoped<ISrv_Restablecer, Srv_Restablecer>();

        // ── Correo y seguridad ──────────────────────────────────────
        s.Configure<OpcionesCorreo>(config.GetSection(OpcionesCorreo.Seccion));
        s.AddSingleton<IHasherPassword, HasherPbkdf2>();
        s.AddScoped<IEnviadorCorreo>(sp =>
        {
            var op = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<OpcionesCorreo>>().Value;
            return string.Equals(op.Modo, "Smtp", StringComparison.OrdinalIgnoreCase)
                ? ActivatorUtilities.CreateInstance<EnviadorSmtp>(sp)
                : ActivatorUtilities.CreateInstance<EnviadorSimulado>(sp);
        });
        s.AddScoped<ProcesadorCorreos>();
        return s;
    }

    /// <summary>Registra además el servicio en segundo plano que envía los correos pendientes.</summary>
    public static IServiceCollection AddEnvioDeCorreos(this IServiceCollection s)
        => s.AddHostedService<CorreoWorker>();

    /// <summary>
    /// Lee la cadena de conexión y reemplaza los marcadores {CAF_DB_USUARIO}, {CAF_DB_CLAVE} y {CAF_DB_BASE}
    /// por el valor de la variable de entorno (o de appsettings.Local.json) con ese mismo nombre.
    /// La base tiene valor por defecto; usuario y clave son obligatorios. Así la clave nunca vive en un archivo.
    /// </summary>
    private static string Cadena(IConfiguration config, string clave)
    {
        var c = config.GetConnectionString(clave);
        if (string.IsNullOrWhiteSpace(c))
            throw new InvalidOperationException($"Falta ConnectionStrings:{clave} en la configuración.");

        c = Reemplazar(config, c, "CAF_DB_BASE", "accesos_piloto_prueba");
        c = Reemplazar(config, c, "CAF_DB_USUARIO", null);
        c = Reemplazar(config, c, "CAF_DB_CLAVE", null);
        // Toda fecha del servidor (CURRENT_DATE, CURRENT_TIMESTAMP) debe ser la de Lima, no la del servidor de la base (UTC).
        if (!c.Contains("Timezone", StringComparison.OrdinalIgnoreCase)) c = c.TrimEnd(';') + ";Timezone=America/Lima";
        return c;
    }

    private static string Reemplazar(IConfiguration config, string cadena, string nombre, string? porDefecto)
    {
        var marcador = "{" + nombre + "}";
        if (!cadena.Contains(marcador, StringComparison.Ordinal)) return cadena;
        var valor = config[nombre];
        if (string.IsNullOrEmpty(valor)) valor = porDefecto;
        if (string.IsNullOrEmpty(valor))
            throw new InvalidOperationException($"Falta la variable de entorno {nombre} (defínala en las variables de entorno de Windows y reabra la ventana o el IDE).");
        return cadena.Replace(marcador, valor, StringComparison.Ordinal);
    }
}
