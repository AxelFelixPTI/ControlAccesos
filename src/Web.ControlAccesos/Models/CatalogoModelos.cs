namespace Web.ControlAccesos.Models;

/// <summary>Lo que envía el formulario de catálogos. Los datos que no cambian (código, orden) los resuelve el servidor.</summary>
public sealed class CatalogoGuardarVM
{
    public string Tipo { get; set; } = string.Empty;          // zona | motivo | tratamiento | incidencia
    public long Id { get; set; }                               // 0 = nuevo
    public string Descripcion { get; set; } = string.Empty;
    public bool Activo { get; set; } = true;
    public string? Sede { get; set; }                          // código de sede (solo zonas); vacío = VES
    public string? TipoZona { get; set; }                      // ADMINISTRATIVA | OPERATIVA
    public bool ExigeSctr { get; set; }
    public bool ExigeEpp { get; set; }
    public string? ResultadoIngreso { get; set; }
    public string? ResultadoSalida { get; set; }
}

/// <summary>Fila ya simplificada para la pantalla (nombres claros en JSON).</summary>
public sealed class CatalogoFila
{
    public long Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public bool Activo { get; set; }
    public bool EsOtro { get; set; }
    public string? TipoZona { get; set; }
    public bool ExigeSctr { get; set; }
    public bool ExigeEpp { get; set; }
    public string? ResultadoIngreso { get; set; }
    public string? ResultadoSalida { get; set; }
}

public sealed class PersonalGuardarVM
{
    public long Id { get; set; }                     // 0 = nuevo
    private string _apellidoPaterno = string.Empty;
    public string ApellidoPaterno { get => _apellidoPaterno; set => _apellidoPaterno = Mayus.De(value) ?? string.Empty; }
    private string? _apellidoMaterno;
    public string? ApellidoMaterno { get => _apellidoMaterno; set => _apellidoMaterno = Mayus.De(value); }
    private string _nombres = string.Empty;
    public string Nombres { get => _nombres; set => _nombres = Mayus.De(value) ?? string.Empty; }
    public long TipoDocId { get; set; }
    public string Doc { get; set; } = string.Empty;
    public string? Anexo { get; set; }
    public long AreaId { get; set; }
    public long? CargoId { get; set; }
    public long EmpresaId { get; set; }
    public string? Correo { get; set; }
    public bool Activo { get; set; } = true;
}

public sealed class UsuarioGuardarVM
{
    public long Id { get; set; }                     // 0 = nuevo
    public long? PersonalId { get; set; }            // personal vinculado (nulo = externo)
    private string? _apellidoPaterno;
    public string? ApellidoPaterno { get => _apellidoPaterno; set => _apellidoPaterno = Mayus.De(value); }
    private string? _apellidoMaterno;
    public string? ApellidoMaterno { get => _apellidoMaterno; set => _apellidoMaterno = Mayus.De(value); }
    private string? _nombres;
    public string? Nombres { get => _nombres; set => _nombres = Mayus.De(value); }
    public long TipoDocId { get; set; }
    public string? Doc { get; set; }
    public string? Correo { get; set; }
    private string? _empresaExterna;
    public string? EmpresaExterna { get => _empresaExterna; set => _empresaExterna = Mayus.De(value); }
    public List<long> Roles { get; set; } = new();   // ids de licencia LIC_CAF_*
    public bool Activo { get; set; } = true;
}

public sealed class IdVM
{
    public long Id { get; set; }
}

/// <summary>Datos de la solicitud que envía el asistente (crear) o el formulario «Editar datos». Fecha y hora vienen separadas.</summary>
public sealed class SolicitudGuardarVM
{
    public string? Fecha { get; set; }                 // yyyy-MM-dd
    public string? Hora { get; set; }                  // HH:mm
    private string? _empresa;
    public string? Empresa { get => _empresa; set => _empresa = Mayus.De(value); }
    public long ResponsableId { get; set; }
    public long? MotivoId { get; set; }
    public string? MotivoDetalle { get; set; }
    public string? Observaciones { get; set; }
    public List<long> ZonasIds { get; set; } = new();
    public List<long> PersonasIds { get; set; } = new();   // solo al crear
    public string? Copias { get; set; }
    public long? OrigenId { get; set; }                    // solo al crear («Reutilizar»)
    public long SedeId { get; set; }                       // solo al crear (Entrega H)
    public long TipoId { get; set; }                       // solo al crear (Entrega H)
    public bool Cochera { get; set; }
    private string? _placa;
    public string? Placa { get => _placa; set => _placa = Mayus.De(value); }
    private string? _areaDetalle;
    public string? AreaDetalle { get => _areaDetalle; set => _areaDetalle = Mayus.De(value); }
    private string? _contactoNombre;
    public string? ContactoNombre { get => _contactoNombre; set => _contactoNombre = Mayus.De(value); }
    public string? ContactoTelefonos { get; set; }
    public string? ContactoCorreos { get; set; }
    public long? EmpresaDestinoId { get; set; }            // proveedor: empresa del grupo que recibe (D-223); con varias, la primera
    public List<long>? EmpresasIds { get; set; }           // D-236: proveedor: todas las empresas que reciben (1 a 4)
    public List<string>? NumerosOc { get; set; }           // D-237: proveedor: OC de la entrega (al menos una). Nulo = no es proveedor
    private string? _empresaTransportista;
    public string? EmpresaTransportista { get => _empresaTransportista; set => _empresaTransportista = Mayus.De(value); }      // D-237: proveedor: vacía = el mismo proveedor transporta (HoraHasta = fin de la franja estimada)
    public List<TransportistaVM> Transportistas { get; set; } = new();   // proveedor, solo al crear
    public List<SubtipoPersonaVM> Subtipos { get; set; } = new();         // D-234: rol de cada persona, solo al crear
    public List<string>? Dias { get; set; }                // contratista por franja (D-227): «AAAA-MM-DD», solo al crear
    public string? HoraDesde { get; set; }                 // contratista: horario opcional «HH:mm»
    public string? HoraHasta { get; set; }
}

/// <summary>Datos opcionales de un transportista (D-223). El primero de la lista es el principal.</summary>
public sealed class TransportistaVM
{
    public long PersonaId { get; set; }
    public string? Ruc { get; set; }
    private string? _nombre;
    public string? Nombre { get => _nombre; set => _nombre = Mayus.De(value); }
    private string? _direccion;
    public string? Direccion { get => _direccion; set => _direccion = Mayus.De(value); }
    private string? _placa;
    public string? Placa { get => _placa; set => _placa = Mayus.De(value); }
    private string? _marca;
    public string? Marca { get => _marca; set => _marca = Mayus.De(value); }
    private string? _licencia;
    public string? Licencia { get => _licencia; set => _licencia = Mayus.De(value); }
}

public sealed class PersonaExternaVM
{
    public long Id { get; set; }                       // 0 = nueva; >0 = corregir datos de una ya registrada
    public long TipoDocId { get; set; }
    public string Doc { get; set; } = string.Empty;
    private string _apellidoPaterno = string.Empty;
    public string ApellidoPaterno { get => _apellidoPaterno; set => _apellidoPaterno = Mayus.De(value) ?? string.Empty; }
    private string? _apellidoMaterno;
    public string? ApellidoMaterno { get => _apellidoMaterno; set => _apellidoMaterno = Mayus.De(value); }
    private string _nombres = string.Empty;
    public string Nombres { get => _nombres; set => _nombres = Mayus.De(value) ?? string.Empty; }
}

/// <summary>Rol (subtipo) elegido para una persona externa de la solicitud (D-234).</summary>
public sealed class SubtipoPersonaVM
{
    public long PersonaId { get; set; }
    public long SubtipoId { get; set; }
}

public sealed class SolicitudPersonaVM
{
    public long? SubtipoId { get; set; }               // D-234: rol de la persona que se agrega
    public long SolicitudId { get; set; }
    public long SolicitudPersonaId { get; set; }
    public long PersonaId { get; set; }
}

public sealed class SolicitudCancelarVM
{
    public long SolicitudId { get; set; }
    public string? Motivo { get; set; }
}

/// <summary>Formulario de un ítem del checklist de portería (pantalla «Checklist de portería»).</summary>
public sealed class ChecklistItemGuardarVM
{
    public long Id { get; set; }                               // 0 = nuevo
    public string Descripcion { get; set; } = string.Empty;
    public string? Ayuda { get; set; }
    public string Etapa { get; set; } = "INGRESO";             // INGRESO | SALIDA
    public string Condicion { get; set; } = "SIEMPRE";
    public bool EsCritico { get; set; }
    public int? Orden { get; set; }                            // nulo = al final de su etapa
    public bool Activo { get; set; } = true;
    public List<TipoAsignadoVM> Tipos { get; set; } = new();   // tipos de ingreso a los que se ofrece (con subtipo opcional)
}

/// <summary>Un tipo de ingreso al que se asigna un ítem; Subtipo nulo = a todas las personas del tipo.</summary>
public sealed class TipoAsignadoVM
{
    public long Tipo { get; set; }
    public long? Subtipo { get; set; }
}

/// <summary>Formulario de un tipo de ingreso (pantalla «Tipos de ingreso»).</summary>
public sealed class TipoIngresoGuardarVM
{
    public long Id { get; set; }                               // 0 = nuevo
    public string Descripcion { get; set; } = string.Empty;
    public bool RequiereAprobacion { get; set; } = true;
    public bool Disponible { get; set; }
    public int? Orden { get; set; }                            // nulo = al final
    public bool Activo { get; set; } = true;
}

/// <summary>Alta o edición de un subtipo (rol de persona) de un tipo de ingreso (D-234). Id = 0 crea; el código se genera del nombre.</summary>
public sealed class SubtipoGuardarVM
{
    public long Id { get; set; }
    public long TipoId { get; set; }                   // solo al crear
    public string? Descripcion { get; set; }
    public int? Orden { get; set; }
    public long? CopiarDeId { get; set; }              // solo al crear: subtipo del que se copia el checklist
}

public sealed class SubtipoEstadoVM
{
    public long Id { get; set; }
    public bool Activo { get; set; }
}

/// <summary>D-236: empresas del grupo a las que da atención un usuario de Almacén.</summary>
public sealed class AlmacenEmpresaGuardarVM
{
    public long UsuarioId { get; set; }
    public List<long>? EmpresasIds { get; set; }
}
