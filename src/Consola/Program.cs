// ============================================================
// Consola de operación de ControlAccesos (piloto). Comandos:
//   probar           Lee los catálogos y la cola de correos: confirma que C# ↔ PostgreSQL funciona.
//   crear-admin      Crea el primer administrador (pide los datos y la contraseña por teclado).
//   enviar-correos   Una sola vuelta de envío de correos pendientes.
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

if (comando is not ("probar" or "crear-admin" or "enviar-correos" or "servir"))
{
    Console.WriteLine("Uso: dotnet run --project src/Consola -- <comando>");
    Console.WriteLine("  probar           lee catálogos y cola de correos (prueba de conexión)");
    Console.WriteLine("  crear-admin      crea el primer administrador");
    Console.WriteLine("  enviar-correos   una vuelta de envío de correos pendientes");
    Console.WriteLine("  servir           envío de correos en segundo plano (Ctrl+C para parar)");
    return 1;
}

var builder = Host.CreateApplicationBuilder(new HostApplicationBuilderSettings { ContentRootPath = AppContext.BaseDirectory });
builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false);
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
