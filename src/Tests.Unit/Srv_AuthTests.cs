using Application.DTOs.ControlAccesos;
using Application.Services.ControlAccesos;
using Infrastructure.Contracts.ControlAccesos;
using Infrastructure.ExternalServices.ControlAccesos;
using Microsoft.Extensions.Logging.Abstractions;
using NSubstitute;
using Shared.Results;
using Xunit;
namespace Tests.Unit;

public class Srv_AuthTests
{
    private static readonly DateTime Ahora = new(2026, 11, 24, 10, 0, 0);
    private readonly IRepo_Usuario _repo = Substitute.For<IRepo_Usuario>();
    private readonly HasherPbkdf2 _hasher = new();
    private readonly Srv_Auth _srv;
    public Srv_AuthTests()
    {
        _srv = new Srv_Auth(_repo, _hasher, NullLogger<Srv_Auth>.Instance, ()
=> Ahora);
    }
    private Dto_Usuario_Credencial Usuario(string clave, DateTime?
bloqueadoHasta = null, bool activo = true) => new()
{
    ID_Usuario = 1,
    Correo = "ana@empresa.test",
    Nombre_Completo = "Ana Prueba",
        Password_Hash = _hasher.Hashear(clave),
    Activo = activo,
    Bloqueado_Hasta = bloqueadoHasta,
};
    private void RepoDevuelve(Dto_Usuario_Credencial? u)
        => _repo.AutenticacionPorCorreoAsync(Arg.Any<string>(),
Arg.Any<CancellationToken>())
                .Returns(Result<Dto_Usuario_Credencial?>.Ok(u));
    [Fact]
    public async Task UsuarioInexistente_DaElMismoMensajeGenerico()
    {
        RepoDevuelve(null);
        var r = await _srv.IniciarSesionAsync(new Dto_Login_Entrada
        {
            Correo
= "nadie@x.test",
            Password = "x"
        });
        Assert.False(r.Success);
        Assert.Equal("Correo o contraseña incorrectos.", r.Message);
    }
    [Fact]
    public async Task UsuarioInactivo_DaElMismoMensajeGenerico()
    {
        RepoDevuelve(Usuario("Clave12345", activo: false));
        var r = await _srv.IniciarSesionAsync(new Dto_Login_Entrada
        {
            Correo
= "ana@empresa.test",
            Password = "Clave12345"
        });
        Assert.False(r.Success);
        Assert.Equal("Correo o contraseña incorrectos.", r.Message);
    }
    [Fact]
    public async Task
CuentaBloqueadaVigente_RespondeBloqueado_AunqueLaClaveSeaCorrecta()
    {
        RepoDevuelve(Usuario("Clave12345", bloqueadoHasta:
Ahora.AddMinutes(10)));
        var r = await _srv.IniciarSesionAsync(new Dto_Login_Entrada
        {
            Correo
= "ana@empresa.test",
            Password = "Clave12345"
        });
        Assert.False(r.Success);
        Assert.Equal("BLOQUEADO", r.Code);
    }
    [Fact]
    public async Task BloqueoVencido_PermiteEntrarDeNuevo()
    {
        RepoDevuelve(Usuario("Clave12345", bloqueadoHasta:Ahora.AddMinutes(-1)));
        PrepararLoginExitoso();
        var r = await _srv.IniciarSesionAsync(new Dto_Login_Entrada
        {
            Correo
= "ana@empresa.test",
            Password = "Clave12345"
        });
        Assert.True(r.Success);
    }
    [Fact]
    public async Task ClaveIncorrecta_RegistraElIntentoFallido()
    {
        RepoDevuelve(Usuario("Clave12345"));
        _repo.LoginRegistrarAsync(1, false, 5, 15, Arg.Any<CancellationToken>
())
             .Returns(ResultSp<Dto_Login_Registro>.Success(new
Dto_Login_Registro
             { Intentos_Fallidos = 1 }, "ok"));
        var r = await _srv.IniciarSesionAsync(new Dto_Login_Entrada
        {
            Correo
= "ana@empresa.test",
            Password = "mala"
        });
        Assert.False(r.Success);
        await _repo.Received(1).LoginRegistrarAsync(1, false, 5, 15,
Arg.Any<CancellationToken>());
    }
    [Fact]
    public async Task QuintoIntentoFallido_BloqueaLaCuenta()
    {
        RepoDevuelve(Usuario("Clave12345"));
        _repo.LoginRegistrarAsync(1, false, 5, 15, Arg.Any<CancellationToken>
())
             .Returns(ResultSp<Dto_Login_Registro>.Success(
                 new Dto_Login_Registro
                 {
                     Intentos_Fallidos = 5,
                     Bloqueado_Hasta = Ahora.AddMinutes(15)
                 }, "ok"));
        var r = await _srv.IniciarSesionAsync(new Dto_Login_Entrada
        {
            Correo
= "ana@empresa.test",
            Password = "mala"
        });
        Assert.Equal("BLOQUEADO", r.Code);
    }
    [Fact]
    public async Task ClaveCorrecta_IniciaSesion_YNoDevuelveElHash()
    {
        RepoDevuelve(Usuario("Clave12345"));
        PrepararLoginExitoso();
        var r = await _srv.IniciarSesionAsync(new Dto_Login_Entrada
        {
            Correo
= "ana@empresa.test",
            Password = "Clave12345"
        });
        Assert.True(r.Success);
        Assert.Equal(1, r.Data!.ID_Usuario);
        Assert.Equal("ana@empresa.test", r.Data.Correo);
    }
    [Fact]
    public async Task SinCorreoOSinClave_FallaLaValidacion()
    {
        var r = await _srv.IniciarSesionAsync(new Dto_Login_Entrada
        {
            Correo
= "",
            Password = ""
        });
        Assert.False(r.Success);
        Assert.NotEmpty(r.Errors);
    }
    private void PrepararLoginExitoso()
    {
        _repo.LoginRegistrarAsync(1, true, 5, 15, Arg.Any<CancellationToken>
        ())
        .Returns(ResultSp<Dto_Login_Registro>.Success(new
        Dto_Login_Registro(), "ok"));
        _repo.LicenciasListarAsync(1, Arg.Any<CancellationToken>
        ()).Returns(Result<List<Dto_Usuario_Licencia>>.Ok(new()));
        _repo.PermisosListarAsync(1, Arg.Any<CancellationToken>
        ()).Returns(Result<List<Dto_Usuario_Permiso>>.Ok(new()));
    }
}
