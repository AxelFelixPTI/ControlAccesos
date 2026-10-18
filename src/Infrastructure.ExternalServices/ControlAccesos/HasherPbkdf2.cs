// ============================================================
// Hash de contraseñas con PBKDF2-SHA256 (incluido en .NET, sin paquetes).
// Formato guardado: PBKDF2$SHA256$<iteraciones>$<sal base64>$<hash base64>  (cabe en VARCHAR(500)).
// Las iteraciones viajan dentro del hash: se pueden subir en el futuro sin romper los antiguos.
// ============================================================

using System.Security.Cryptography;
using Application.Contracts.ControlAccesos;

namespace Infrastructure.ExternalServices.ControlAccesos;

public sealed class HasherPbkdf2 : IHasherPassword
{
    private const int Iteraciones = 210_000;
    private const int LargoSal = 16;
    private const int LargoHash = 32;

    public string Hashear(string passwordPlano)
    {
        var sal = RandomNumberGenerator.GetBytes(LargoSal);
        var hash = Rfc2898DeriveBytes.Pbkdf2(passwordPlano, sal, Iteraciones, HashAlgorithmName.SHA256, LargoHash);
        return $"PBKDF2$SHA256${Iteraciones}${Convert.ToBase64String(sal)}${Convert.ToBase64String(hash)}";
    }

    public bool Verificar(string passwordPlano, string hashGuardado)
    {
        var partes = hashGuardado.Split('$');
        if (partes.Length != 5 || partes[0] != "PBKDF2" || partes[1] != "SHA256" || !int.TryParse(partes[2], out var it) || it <= 0)
            return false;
        try
        {
            var sal = Convert.FromBase64String(partes[3]);
            var esperado = Convert.FromBase64String(partes[4]);
            var calculado = Rfc2898DeriveBytes.Pbkdf2(passwordPlano, sal, it, HashAlgorithmName.SHA256, esperado.Length);
            return CryptographicOperations.FixedTimeEquals(calculado, esperado);
        }
        catch (FormatException) { return false; }
    }
}
