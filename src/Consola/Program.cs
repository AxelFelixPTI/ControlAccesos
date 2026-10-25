// ============================================================
// Consola de operación de ControlAccesos (piloto). Comandos:
//   probar           Lee los catálogos y la cola de correos: confirma que C# ↔ PostgreSQL funciona.
//   crear-admin      Crea el primer administrador (pide los datos y la contraseña por teclado).
//   login            Prueba el inicio de sesión (correo y contraseña) y muestra licencias y permisos.
//   emitir-token     Genera un token de un solo uso para que un usuario defina su contraseña.
//   definir-password Usa ese token para definir la contraseña.
//   enviar-correos   Una sola vuelta de envío de correos pendientes.
//   vista-previa-correos [carpeta]  Genera ejemplos .html de cada correo (sin base de datos).
//   servir           Deja corriendo el envío de correos en segundo plano (Ctrl+C para parar).
// Configuración: appsettings.json y, si existe, appsettings.Local.json (NO se sube a git; ahí va la clave real).
// ============================================================

using Application.Contracts.ControlAccesos;
using Application.DTOs.ControlAccesos;
using Composicion.ControlAccesos;
using Infrastructure.ExternalServices.ControlAccesos;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Shared.Results;

var comando = args.Length > 0 ? args[0].ToLowerInvariant() : "ayuda";

if (comando is not ("probar" or "crear-admin" or "login" or "emitir-token" or "definir-password" or "enviar-correos" or "servir" or "vista-previa-correos"))
{
    Console.WriteLine("Uso: dotnet run --project src/Consola -- <comando>");
    Console.WriteLine("  probar           lee catálogos y cola de correos (prueba de conexión)");
    Console.WriteLine("  crear-admin      crea el primer administrador");
    Console.WriteLine("  login            prueba el inicio de sesión");
    Console.WriteLine("  emitir-token     token de un solo uso para definir contraseña");
    Console.WriteLine("  definir-password usa el token para definir la contraseña");
    Console.WriteLine("  enviar-correos   una vuelta de envío de correos pendientes");
    Console.WriteLine("  servir           envío de correos en segundo plano (Ctrl+C para parar)");
    Console.WriteLine("  vista-previa-correos [carpeta]  genera un .html de ejemplo por tipo de correo (sin base de datos)");
    return 1;
}

if (comando == "vista-previa-correos")
{
    var carpeta = args.Length > 1 ? args[1] : "vista_previa_correos";
    Directory.CreateDirectory(carpeta);
    var d = new Dto_Correo_Solicitud
    {
        ID_Solicitud = 123, Codigo = "SOL-2026-000123", Estado = "PENDIENTE", Fecha_Hora_Prevista = new DateTime(2026, 11, 3, 9, 30, 0),
        Sede = "Villa El Salvador", Tipo_Acceso = "Visitante externo", Empresa_Visitante = "Ferretería Andina S.A.C.",
        Responsable_Nombre = "Quispe Rojas, Marta", Responsable_Correo = "marta@grupotrianon.com", Responsable_Area = "Almacén",
        Motivo = "Entrega de materiales", Motivo_Detalle = "Descarga de 3 pallets", Zonas_Nombres = "Almacén, Patio de maniobras",
        Observaciones = "Llegarán en un camión de 8 toneladas.\nPor favor habilitar el portón lateral.",
        Solicitante_Nombre = "Pérez Díaz, Carlos", Solicitante_Correo = "carlos@grupotrianon.com",
        Exige_SCTR = true, Exige_EPP = true, Total_Personas = 3, Pendientes = 3, Version = 1, Fecha_Envio = DateTime.Now
    };
    var pers = new List<Dto_Correo_Solicitud_Persona>
    {
        new() { Tipo_Documento = "DNI", Numero_Documento = "45871236", Nombre_Completo = "Huamán Soto, Luis", Aprobacion = "PENDIENTE", Trae_Equipos = true },
        new() { Tipo_Documento = "DNI", Numero_Documento = "70125489", Nombre_Completo = "Ramos Vega, Jorge", Aprobacion = "PENDIENTE" },
        new() { Tipo_Documento = "CE",  Numero_Documento = "001458796", Nombre_Completo = "Torres León, Ana", Aprobacion = "PENDIENTE", Trae_Herramientas = true },
    };
    void Guardar(string tipo, string archivo, string msg, string estado, bool resp, Action<List<Dto_Correo_Solicitud_Persona>>? ajusta = null)
    {
        d.Estado = estado;
        var lista = pers.Select(p => new Dto_Correo_Solicitud_Persona { Tipo_Documento = p.Tipo_Documento, Numero_Documento = p.Numero_Documento,
            Nombre_Completo = p.Nombre_Completo, Aprobacion = p.Aprobacion, Trae_Equipos = p.Trae_Equipos, Trae_Herramientas = p.Trae_Herramientas }).ToList();
        ajusta?.Invoke(lista);
        d.Autorizadas = lista.Count(p => p.Aprobacion == "APROBADA"); d.Pendientes = lista.Count(p => p.Aprobacion == "PENDIENTE");
        d.Rechazadas = lista.Count(p => p.Aprobacion == "RECHAZADA"); d.Observadas = lista.Count(p => p.Aprobacion == "OBSERVADA");
        var a = PlantillaCorreo.Armar(tipo, msg, d, lista, "http://192.168.1.50:5080", resp);
        File.WriteAllText(Path.Combine(carpeta, archivo + ".html"), a.Html);
        File.WriteAllText(Path.Combine(carpeta, archivo + ".txt"), "Asunto: " + a.Asunto + "\n\n" + a.Texto);
        Console.WriteLine($"  {archivo}.html  ({a.Asunto})");
    }
    Console.WriteLine($"Ejemplos de correo en: {Path.GetFullPath(carpeta)}");
    Guardar("SOLICITUD_NUEVA", "1_solicitud_nueva", "Se registró una nueva solicitud de acceso y está por aprobar: 3 persona(s) de Ferretería Andina S.A.C., visita prevista el 03/11/2026 09:30.", "PENDIENTE", false);
    Guardar("SOLICITUD_DECISION", "2_aprobada", "Sobre la solicitud: 3 personas aprobada(s).\nEstado de la solicitud: APROBADA.", "APROBADA", true, l => l.ForEach(p => p.Aprobacion = "APROBADA"));
    Guardar("SOLICITUD_DECISION", "3_observada", "Sobre la solicitud: 1 persona observada(s).\nFalta el SCTR vigente de Ramos Vega, Jorge.\nEstado de la solicitud: APROBADA_PARCIAL.", "APROBADA_PARCIAL", true,
        l => { l[0].Aprobacion = "APROBADA"; l[2].Aprobacion = "APROBADA"; l[1].Aprobacion = "OBSERVADA"; l[1].Aprobacion_Mensaje = "Falta el SCTR vigente."; });
    Guardar("SOLICITUD_DECISION", "4_rechazada", "Sobre la solicitud: 3 personas rechazada(s).\nNo se autoriza el ingreso en esa fecha.\nEstado de la solicitud: RECHAZADA.", "RECHAZADA", true,
        l => l.ForEach(p => { p.Aprobacion = "RECHAZADA"; p.Aprobacion_Mensaje = "No se autoriza el ingreso en esa fecha."; }));
    Guardar("SOLICITUD_CANCELADA", "5_cancelada", "La solicitud fue cancelada. La visita se reprogramó.", "CANCELADA", true);
    return 0;
}

var builder = Host.CreateApplicationBuilder(new HostApplicationBuilderSettings { ContentRootPath = AppContext.BaseDirectory });
builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false);
builder.Configuration.AddEnvironmentVariables();
builder.Services.AddControlAccesos(builder.Configuration);
if (comando == "servir") builder.Services.AddEnvioDeCorreos();

using var host = builder.Build();

try
{
    switch (comando)
    {
        case "servir":
            await host.RunAsync();
            return 0;
        case "probar":
            return await Probar(host.Services);
        case "enviar-correos":
            return await EnviarCorreos(host.Services);
        case "login":
            return await Login(host.Services);
        case "emitir-token":
            return await EmitirToken(host.Services);
        case "definir-password":
            return await DefinirPassword(host.Services);
        default:
            return await CrearAdmin(host.Services);
    }
}
catch (Exception ex)
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine($"ERROR: {ex.InnerException?.Message ?? ex.Message}");
    Console.ResetColor();
    return 2;
}

// ─────────────────────────────────────────────────────────────
static async Task<int> Probar(IServiceProvider raiz)
{
    using var ambito = raiz.CreateScope();
    var sp = ambito.ServiceProvider;
    int fallos = 0;

    async Task Paso<T>(string nombre, Func<Task<Result<List<T>>>> llamada)
    {
        try
        {
            var r = await llamada();
            if (r.Success) Console.WriteLine($"  OK    {nombre,-34} {r.Data?.Count ?? 0} filas");
            else { fallos++; Console.WriteLine($"  FALLO {nombre,-34} {r.Message}"); }
        }
        catch (Exception ex) { fallos++; Console.WriteLine($"  FALLO {nombre,-34} {ex.InnerException?.Message ?? ex.Message}"); }
    }

    Console.WriteLine("Prueba de conexión C# ↔ PostgreSQL");
    var sedes = await sp.GetRequiredService<ISrv_Catalogo_Sede>().ObtenerDropdownAsync();
    await Paso("Sedes (dropdown)", () => Task.FromResult(sedes));
    long? primeraSede = sedes.Success ? sedes.Data!.FirstOrDefault()?.ID_Catalogo : null;
    await Paso("Licencias (dropdown)", () => sp.GetRequiredService<ISrv_Catalogo_Licencia>().ObtenerDropdownAsync());
    await Paso("Tipos de documento (dropdown)", () => sp.GetRequiredService<ISrv_Catalogo_Tipo_Documento>().ObtenerDropdownAsync());
    await Paso("Áreas (dropdown)", () => sp.GetRequiredService<ISrv_Catalogo_Area>().ObtenerDropdownAsync());
    await Paso("Cargos (dropdown)", () => sp.GetRequiredService<ISrv_Catalogo_Cargo>().ObtenerDropdownAsync());
    await Paso("Empresas del grupo (dropdown)", () => sp.GetRequiredService<ISrv_Catalogo_Empresa_Grupo>().ObtenerDropdownAsync());
    await Paso("Motivos de visita (dropdown)", () => sp.GetRequiredService<ISrv_Catalogo_Motivo_Visita>().ObtenerDropdownAsync());
    await Paso("Tipos de acceso (dropdown)", () => sp.GetRequiredService<ISrv_Catalogo_Tipo_Acceso>().ObtenerDropdownAsync());
    await Paso("Zonas de acceso (dropdown)", () => sp.GetRequiredService<ISrv_Catalogo_Zona_Acceso>().ObtenerDropdownAsync(primeraSede));
    await Paso("Ítems de checklist (dropdown)", () => sp.GetRequiredService<ISrv_Catalogo_Item_Checklist>().ObtenerDropdownAsync(null));
    await Paso("Tipos de incidencia (dropdown)", () => sp.GetRequiredService<ISrv_Catalogo_Tipo_Incidencia>().ObtenerDropdownAsync());
    await Paso("Tratamientos de desviación (dropdown)", () => sp.GetRequiredService<ISrv_Catalogo_Tratamiento_Desviacion>().ObtenerDropdownAsync(null));
    await Paso("Cola de correos (usuario sistema 0)", () => sp.GetRequiredService<ISrv_Correo>().PendientesListarAsync(ProcesadorCorreos.UsuarioSistema, 5));

    Console.WriteLine(fallos == 0 ? "\nTodo bien: C# lee la base correctamente." : $"\n{fallos} paso(s) fallaron.");
    return fallos == 0 ? 0 : 3;
}

static async Task<int> EnviarCorreos(IServiceProvider raiz)
{
    using var ambito = raiz.CreateScope();
    var r = await ambito.ServiceProvider.GetRequiredService<ProcesadorCorreos>().ProcesarLoteAsync();
    if (r.ErrorGeneral is not null) { Console.WriteLine($"No se pudo leer la cola: {r.ErrorGeneral}"); return 3; }
    Console.WriteLine($"Leídos {r.Leidos} · enviados {r.Enviados} · con error {r.Fallidos}");
    return 0;
}

static async Task<int> Login(IServiceProvider raiz)
{
    using var ambito = raiz.CreateScope();
    var auth = ambito.ServiceProvider.GetRequiredService<ISrv_Auth>();
    var r = await auth.IniciarSesionAsync(new Dto_Login_Entrada { Correo = Pedir("Correo"), Password = PedirPassword("Contraseña") });
    if (!r.Success)
    {
        Console.WriteLine($"Acceso denegado: {r.Message}");
        foreach (var e in r.Errors) Console.WriteLine($"  - {e.Message}");
        return 1;
    }
    var s = r.Data!;
    Console.WriteLine($"Bienvenido/a {s.Nombre_Completo} (ID {s.ID_Usuario}){(s.Password_Requiere_Cambio ? " — debe cambiar su contraseña" : "")}");
    Console.WriteLine($"Licencias ({s.Licencias.Count}):");
    foreach (var l in s.Licencias) Console.WriteLine($"  {l.Codigo_Licencia} en {l.Codigo_Sede}");
    Console.WriteLine($"Permisos ({s.Permisos.Count}):");
    foreach (var p in s.Permisos) Console.WriteLine($"  {p.Codigo_Permiso}  [{p.Sedes}]");
    return 0;
}

static async Task<int> EmitirToken(IServiceProvider raiz)
{
    using var ambito = raiz.CreateScope();
    var auth = ambito.ServiceProvider.GetRequiredService<ISrv_Auth>();
    var u = await auth.BuscarPorCorreoAsync(Pedir("Correo del usuario"));
    if (!u.Success || u.Data is null) { Console.WriteLine(u.Success ? "No existe ese usuario." : u.Message); return 1; }
    var minutos = int.TryParse(Pedir("Vigencia en minutos", "60"), out var m) ? m : 60;
    var t = await auth.EmitirTokenAsync(u.Data.ID_Usuario, minutos, ProcesadorCorreos.UsuarioSistema);
    if (!t.Success) { Console.WriteLine($"No se pudo: {t.Message}"); return 1; }
    Console.WriteLine($"Token para {u.Data.Nombre_Completo} (vale {minutos} min, un solo uso):");
    Console.WriteLine(t.Data);
    return 0;
}

static async Task<int> DefinirPassword(IServiceProvider raiz)
{
    using var ambito = raiz.CreateScope();
    var auth = ambito.ServiceProvider.GetRequiredService<ISrv_Auth>();
    var token = Pedir("Token");
    var p1 = PedirPassword("Contraseña nueva (mínimo 10 caracteres)");
    if (p1 != PedirPassword("Repita la contraseña")) { Console.WriteLine("Las contraseñas no coinciden."); return 1; }
    var r = await auth.DefinirPasswordConTokenAsync(token, p1);
    Console.WriteLine(r.Success ? "Contraseña definida." : $"No se pudo: {r.Message}");
    foreach (var e in r.Errors) Console.WriteLine($"  - {e.Message}");
    return r.Success ? 0 : 1;
}

static async Task<int> CrearAdmin(IServiceProvider raiz)
{
    using var ambito = raiz.CreateScope();
    var sp = ambito.ServiceProvider;
    var usuarios = sp.GetRequiredService<ISrv_Usuario>();

    var tipos = await sp.GetRequiredService<ISrv_Catalogo_Tipo_Documento>().ObtenerDropdownAsync();
    var sedes = await sp.GetRequiredService<ISrv_Catalogo_Sede>().ObtenerDropdownAsync();
    var lics = await sp.GetRequiredService<ISrv_Catalogo_Licencia>().ObtenerDropdownAsync();
    if (!tipos.Success || !sedes.Success || !lics.Success)
    { Console.WriteLine("No se pudieron leer los catálogos. Ejecute primero: probar"); return 3; }

    var lic = lics.Data!.FirstOrDefault(x => x.Codigo == "LIC_CAF_ADMIN");
    if (lic is null) { Console.WriteLine("No existe la licencia LIC_CAF_ADMIN en la base."); return 3; }

    Console.WriteLine("Crear primer administrador (Enter vacío cancela)");
    var tipoCod = Pedir($"Tipo de documento ({string.Join("/", tipos.Data!.Select(t => t.Codigo))})", "DNI");
    var tipo = tipos.Data!.FirstOrDefault(t => string.Equals(t.Codigo, tipoCod, StringComparison.OrdinalIgnoreCase));
    if (tipo is null) { Console.WriteLine("Tipo de documento no válido."); return 1; }
    var sedeCod = Pedir($"Sede ({string.Join("/", sedes.Data!.Select(t => t.Codigo))})", sedes.Data!.First().Codigo);
    var sede = sedes.Data!.FirstOrDefault(t => string.Equals(t.Codigo, sedeCod, StringComparison.OrdinalIgnoreCase));
    if (sede is null) { Console.WriteLine("Sede no válida."); return 1; }

    var dto = new Dto_Usuario_Crear
    {
        ID_Catalogo_Tipo_Documento = tipo.ID_Catalogo,
        Numero_Documento = Pedir("Número de documento"),
        Apellido_Paterno = Pedir("Apellido paterno"),
        Apellido_Materno = NullSiVacio(Pedir("Apellido materno (opcional)", "")),
        Nombres = Pedir("Nombres"),
        Correo = Pedir("Correo"),
    };
    var pass = PedirPassword("Contraseña (mínimo 10 caracteres)");
    if (pass != PedirPassword("Repita la contraseña")) { Console.WriteLine("Las contraseñas no coinciden."); return 1; }

    const long sistema = ProcesadorCorreos.UsuarioSistema;
    var c = await usuarios.CrearAsync(dto, sistema);
    if (!c.Success) { Mostrar(c); return 1; }
    var id = c.Data;

    var p = await usuarios.EstablecerPasswordAsync(id, pass, sistema);
    if (!p.Success) { Console.WriteLine($"Usuario {id} creado, pero la contraseña falló."); Mostrar(p); return 1; }

    var l = await usuarios.AsignarLicenciaAsync(id, lic.ID_Catalogo, sede.ID_Catalogo, sistema);
    if (!l.Success) { Console.WriteLine($"Usuario {id} creado, pero la licencia falló."); Mostrar(l); return 1; }

    Console.WriteLine($"Listo: administrador {dto.Correo} (ID {id}) con licencia {lic.Codigo} en sede {sede.Codigo}.");
    return 0;

    static void Mostrar(Result r)
    {
        Console.WriteLine($"No se pudo: {r.Message}");
        foreach (var e in r.Errors) Console.WriteLine($"  - {e.Message}");
    }
}

static string Pedir(string etiqueta, string? porDefecto = null)
{
    Console.Write(porDefecto is null ? $"{etiqueta}: " : $"{etiqueta} [{porDefecto}]: ");
    var s = (Console.ReadLine() ?? "").Trim();
    return s.Length == 0 ? porDefecto ?? "" : s;
}

static string? NullSiVacio(string s) => string.IsNullOrWhiteSpace(s) ? null : s;

static string PedirPassword(string etiqueta)
{
    Console.Write($"{etiqueta}: ");
    var sb = new System.Text.StringBuilder();
    if (Console.IsInputRedirected) return (Console.ReadLine() ?? "").Trim();
    while (true)
    {
        var k = Console.ReadKey(intercept: true);
        if (k.Key == ConsoleKey.Enter) { Console.WriteLine(); return sb.ToString(); }
        if (k.Key == ConsoleKey.Backspace) { if (sb.Length > 0) sb.Length--; }
        else if (!char.IsControl(k.KeyChar)) sb.Append(k.KeyChar);
    }
}
