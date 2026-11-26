using Infrastructure.ExternalServices.ControlAccesos;
using Xunit;
namespace Tests.Unit;

public class HasherPbkdf2Tests
{
    private readonly HasherPbkdf2 _hasher = new();
    [Fact]
    public void Verificar_ClaveCorrecta_DevuelveTrue()
    {
        var hash = _hasher.Hashear("MiClaveSegura123");
        Assert.True(_hasher.Verificar("MiClaveSegura123", hash));
    }
    [Fact]
    public void Verificar_ClaveIncorrecta_DevuelveFalse()
    {
        var hash = _hasher.Hashear("MiClaveSegura123");
        Assert.False(_hasher.Verificar("otra", hash));
    }
    [Fact]
    public void Hashear_DosVecesLaMismaClave_DaHashesDistintos()
    {
        // Cada hash lleva una sal aleatoria: si fueran iguales, habría un problema de seguridad.
                Assert.NotEqual(_hasher.Hashear("abc"), _hasher.Hashear("abc"));
    }
    [Theory]
    [InlineData("")]
    [InlineData("basura")]
    [InlineData("PBKDF2$SHA256$0$AAAA$AAAA")]
    [InlineData("PBKDF2$SHA256$210000$no-es-base64$no-es-base64")]
    public void
Verificar_HashCorruptoOMalformado_DevuelveFalseSinFallar(string hashRoto)
    {
        Assert.False(_hasher.Verificar("abc", hashRoto));
    }
}
