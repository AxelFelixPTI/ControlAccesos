// ============================================================
// Autenticación y sesión (schema CAF_GOVERNANCE). Propiedades = columnas reales de las rutinas
// ERP_USUARIO_AUTENTICACION_POR_CORREO / _POR_TOKEN / _LICENCIA_LISTAR_POR_PADRE / _PERMISO_LISTAR.
// Dto_Usuario_Credencial lleva el hash: es INTERNO (repositorio → Srv_Auth), nunca sale a una pantalla (D-26).
// ============================================================

using System.ComponentModel.DataAnnotations;

namespace Application.DTOs.ControlAccesos;

public sealed class Dto_Usuario_Credencial
{
    public long ID_Usuario { get; set; }
    public string Correo { get; set; } = string.Empty;
    public string Nombre_Completo { get; set; } = string.Empty;
    public string? Password_Hash { get; set; }
    public bool Password_Requiere_Cambio { get; set; }
    public long Intentos_Fallidos { get; set; }
    public DateTime? Bloqueado_Hasta { get; set; }
    public bool Activo { get; set; }
}

public sealed class Dto_Usuario_Token
{
    public long ID_Usuario { get; set; }
    public string Correo { get; set; } = string.Empty;
    public string Nombre_Completo { get; set; } = string.Empty;
}

public sealed class Dto_Usuario_Licencia
{
    public long ID_Usuario_Licencia { get; set; }
    public long ID_Catalogo_Licencia { get; set; }
    public string Codigo_Licencia { get; set; } = string.Empty;
    public string Licencia { get; set; } = string.Empty;
    public long ID_Catalogo_Sede { get; set; }
    public string Codigo_Sede { get; set; } = string.Empty;
    public string Sede { get; set; } = string.Empty;
}

public sealed class Dto_Usuario_Permiso
{
    public string Codigo_Permiso { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public string? Modulo { get; set; }
    /// <summary>Sedes donde aplica (texto tal como lo arma la rutina).</summary>
    public string? Sedes { get; set; }
    public string? Roles { get; set; }
}

/// <summary>Lo que la web guardará en la sesión tras un login correcto. No incluye hash ni token.</summary>
public sealed class Dto_Sesion_Usuario
{
    public long ID_Usuario { get; set; }
    public string Correo { get; set; } = string.Empty;
    public string Nombre_Completo { get; set; } = string.Empty;
    /// <summary>true = la web debe obligar a cambiar la contraseña antes de seguir.</summary>
    public bool Password_Requiere_Cambio { get; set; }
    public List<Dto_Usuario_Licencia> Licencias { get; set; } = new();
    public List<Dto_Usuario_Permiso> Permisos { get; set; } = new();
}

// ── Formularios ──────────────────────────────────────────────

public sealed class Dto_Login_Entrada
{
    [Required(ErrorMessage = "El correo es obligatorio.")]
    public string Correo { get; set; } = string.Empty;

    [Required(ErrorMessage = "La contraseña es obligatoria.")]
    public string Password { get; set; } = string.Empty;
}

/// <summary>Resultado de ERP_USUARIO_LOGIN_REGISTRAR (salidas INOUT).</summary>
public sealed class Dto_Login_Registro
{
    public long Intentos_Fallidos { get; set; }
    public DateTime? Bloqueado_Hasta { get; set; }
}
