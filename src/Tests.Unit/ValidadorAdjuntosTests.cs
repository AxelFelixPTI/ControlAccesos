using System.Text;
using Application.Contracts.ControlAccesos;
using Xunit;
namespace Tests.Unit;

public class ValidadorAdjuntosTests
{
    private static byte[] PdfValido() => Encoding.ASCII.GetBytes("%PDF-1.4 contenido de prueba");
    private static byte[] ZipValido() => new byte[] { 0x50, 0x4B, 0x03, 0x04,
0x00, 0x00 };
    [Fact]
    public void PdfConFirmaCorrecta_EsValido()
    {
        var error = ValidadorAdjuntos.Validar("acta.pdf", PdfValido(), out
var nombre, out var ext);
        Assert.Null(error);
        Assert.Equal("acta.pdf", nombre);
        Assert.Equal("pdf", ext);
    }
    [Fact]
    public void DocxConFirmaZip_EsValido()
    {
        Assert.Null(ValidadorAdjuntos.Validar("informe.docx", ZipValido(),
out _, out _));
    }
    [Fact]
    public void ExtensionNoPermitida_SeRechaza()
    {
        var error = ValidadorAdjuntos.Validar("virus.exe", PdfValido(), out
_, out _);
        Assert.NotNull(error);
    }
    [Fact]
    public void PdfFalso_ContenidoNoCoincideConLaExtension_SeRechaza()
    {
        var imagen = new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A,
0x0A }; // cabecera de un PNG
        Assert.NotNull(ValidadorAdjuntos.Validar("foto.pdf", imagen, out _,
out _));
    }

    [Fact]
    public void ArchivoVacio_SeRechaza()
    {
        Assert.NotNull(ValidadorAdjuntos.Validar("a.pdf", Array.Empty<byte>
(), out _, out _));
    }
    [Fact]
    public void ExactamenteElMaximo_Pasa_UnByteMas_Falla()
    {
        var justo = new byte[ValidadorAdjuntos.MaxBytes];
        Array.Copy(PdfValido(), justo, PdfValido().Length);
        Assert.Null(ValidadorAdjuntos.Validar("a.pdf", justo, out _, out _));
        var excede = new byte[ValidadorAdjuntos.MaxBytes + 1];
        Array.Copy(PdfValido(), excede, PdfValido().Length);
        Assert.NotNull(ValidadorAdjuntos.Validar("a.pdf", excede, out _, out
_));
    }
    [Theory]
    [InlineData("..\\..\\secreto.pdf", "secreto.pdf")]
    [InlineData("C:\\Users\\ana\\acta.pdf", "acta.pdf")]
    [InlineData("/etc/passwd.pdf", "passwd.pdf")]
    public void LimpiarNombre_QuitaCarpetasYRutas(string entrada, string
esperado)
    {
        Assert.Equal(esperado, ValidadorAdjuntos.LimpiarNombre(entrada));
    }
    [Fact]
    public void TipoContenido_SeDeduceDeLaExtension_NoDelCliente()
    {
        Assert.Equal("application/pdf",
ValidadorAdjuntos.TipoContenido("pdf"));
        Assert.Equal("application/octet-stream",
ValidadorAdjuntos.TipoContenido("html"));
    }
}
