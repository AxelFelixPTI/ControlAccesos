// ============================================================
// Convierte una contraseña en hash (para guardar) y la verifica. La contraseña en claro nunca se guarda.
// La implementación vive en Infrastructure.ExternalServices.
// ============================================================

namespace Application.Contracts.ControlAccesos;

public interface IHasherPassword
{
    string Hashear(string passwordPlano);
    bool Verificar(string passwordPlano, string hashGuardado);
}
