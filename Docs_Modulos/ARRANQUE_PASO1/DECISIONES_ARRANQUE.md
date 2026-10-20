# Decisiones del paso 1 de arranque (2026-10-18)

| N.º | Decisión | Estado |
|---|---|---|
| D-86 | Contraseña mínima de 10 caracteres (validada en `Srv_Usuario`; sin otras reglas de complejidad por ahora). | Candidata |
| D-87 | Hash de contraseña PBKDF2-SHA256, 210 000 iteraciones, sal de 16 bytes; formato `PBKDF2$SHA256$iter$sal$hash` en `Usuario.Password_Hash`. Las iteraciones viajan en el hash. | Candidata |
| D-88 | El envío de correos usa SMTP de `System.Net.Mail` (texto plano) o modo `Simulado` (solo log); se elige con `Correo:Modo`. Si el correo sale pero no se puede marcar ENVIADO, se registra en el log y se reenvía en la siguiente vuelta (preferible duplicar a perder un aviso). | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-51** — ¿Con qué servidor SMTP y qué cuenta remitente enviará el grupo? (Host, puerto, SSL, usuario). Hoy el modo es `Simulado`.
- **P-52** — ¿Política de contraseñas del grupo (largo, vigencia, complejidad)? Hoy: mínimo 10 caracteres.
- **T-10** — En HANA el hash y el envío no cambian; solo `ConexionPostgres` se reemplaza por la fábrica de conexiones HANA.

---

# Decisiones del login (2026-10-18)

| N.º | Decisión | Estado |
|---|---|---|
| D-89 | Bloqueo de cuenta: 5 intentos fallidos seguidos bloquean 15 minutos (constantes `Srv_Auth.MaxIntentos` y `MinutosBloqueo`; el conteo lo guarda `ERP_USUARIO_LOGIN_REGISTRAR`). Un login correcto reinicia el conteo. | Candidata |
| D-90 | El login no revela si el correo existe: usuario inexistente, inactivo, sin contraseña o contraseña errónea responden igual («Correo o contraseña incorrectos.») y con tiempo similar. Solo el bloqueo tiene mensaje propio. | Candidata |
| D-91 | Token para definir contraseña: 32 bytes aleatorios; en la base solo se guarda su SHA-256 en hexadecimal; vigencia 1 minuto a 7 días (límite de la rutina); un solo uso (al definir la contraseña la rutina borra el token). | Candidata |
| D-92 | `Srv_Auth` no maneja cookies ni HTTP: devuelve `Dto_Sesion_Usuario` (usuario, licencias y permisos) y la web lo convertirá en sesión al final. | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-53** — ¿Bloqueo 5 intentos / 15 minutos y mínimo de 10 caracteres es la política del grupo? (Relacionada con P-52.)
- **P-54** — ¿Cómo recibirá el usuario su token para definir contraseña? Hoy se entrega por consola; falta un tipo de correo «definir contraseña» (el CHECK de `CAF_Correo_Pendiente.Tipo` no lo incluye).
- **P-55** — El bloqueo compara `Bloqueado_Hasta` (hora de la base) con la hora del servidor de la aplicación; deben estar en la misma zona horaria. Revisar al desplegar.
- **T-11** — En HANA el login no cambia; solo las rutinas `ERP_USUARIO_*` ya están previstas en T-06.

---

# Decisiones de la capa web — corte 1: arranque, login y menú (2026-10-18)

| N.º | Decisión | Estado |
|---|---|---|
| D-93 | Capa web con ASP.NET Core MVC + Razor + JavaScript simple (igual que Trianon Satelital). Proyecto `src/Web.ControlAccesos`. Vistas generadas en el servidor; sin librerías externas por ahora (hoja de estilos propia `site.css`; ver D-98). | Candidata |
| D-94 | Sesión con cookie `CAF.Sesion`: HttpOnly, SameSite Lax, no persistente, vence a las 8 horas de inactividad (`Sesion:Horas`). La cookie guarda id, nombre, correo, licencias y permisos; nunca hash ni token. | Candidata |
| D-95 | Formularios con token anti-falsificación en todas las operaciones de escritura (incluido «Salir»). Cabeceras de seguridad (nosniff, no incrustar en marcos, política de contenido restrictiva). Solo se redirige a direcciones locales tras el login. | Candidata |
| D-96 | Si la cuenta debe cambiar su contraseña, solo se permite la pantalla de cambio y salir hasta que la cambie (`ExigirCambioPasswordMiddleware`). | Candidata |
| D-97 | El menú lateral muestra cada entrada solo si el usuario tiene al menos uno de sus permisos; las pantallas aún no construidas salen en gris con la marca «pronto» (`MenuCaf`). | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- ~~**P-56**~~ — Resuelta (2026-10-19): no hay archivos de Inspinia disponibles; se usa el diseño de los mockups aprobados (ver D-98).
- **P-57** — POSTERGADA (2026-10-19) hasta que se contemple MAG: selección de sede activa al entrar. En la Etapa 1 solo existe VES.
- **T-12** — La capa web no cambia con HANA: depende solo de `Composicion`.

---

# Decisiones de diseño web (2026-10-19)

| N.º | Decisión | Estado |
|---|---|---|
| D-98 | Diseño de la web = mockups aprobados: **funcionalidad e interacciones** del `Prototipo - Control de Accesos VES - Etapa 1.1`; **paleta** de la primera fase (fondo `#F3F5F8`, tarjetas blancas, lateral navy `#15233B`, acento verde-azulado `#0B7A6E`, resto en grises). No se usa Inspinia por ahora; si se consigue otro layout se rediseña (el diseño vive en `wwwroot/css/site.css` y `Views/Shared/_Layout.cshtml`). | Candidata |
| D-99 | Tipografía del sistema (Segoe UI) en vez de IBM Plex del prototipo, porque la política de contenido (`style-src 'self'`) no permite fuentes externas. Se quitó el azul saturado del prototipo (`btn-navy`); el botón principal es verde-azulado. | Candidata |
| D-100 | Menú lateral agrupado como el prototipo (Solicitante, Coordinador, Vigilancia, Administración), siempre filtrado por permisos. Con cambio de contraseña obligatorio no se muestra el lateral. | Candidata |

---

# Decisiones de la pantalla Catálogos y tema (2026-10-19)

| N.º | Decisión | Estado |
|---|---|---|
| D-101 | Pantalla **Catálogos** (permiso `PER_CAF_ADMIN_CATALOGOS`) como el prototipo 1.1: zonas de VES (tipo, exige SCTR/EPP), motivos de visita, tratamientos de desviación (efecto al ingreso y a la salida) y tipos de incidencia. Crear y editar; **no se elimina, se desactiva**. El elemento «Otro» de cada lista es fijo y no se edita. | Candidata |
| D-102 | El usuario escribe solo el **nombre**; el **código** lo genera el servidor (MAYÚSCULAS_CON_GUION_BAJO, sin tildes; si existe agrega _2, _3) y no cambia al editar. El **orden** de un elemento nuevo es el siguiente al mayor (queda antes de «Otro»). Nombre duplicado (sin distinguir tildes ni mayúsculas) se rechaza. | Candidata |
| D-103 | Tema claro por defecto; botón sol/luna en la barra superior; la elección se guarda en el navegador (no en la base). Ya no se sigue el modo oscuro del sistema operativo. | Candidata |
| D-104 | Protección real de pantallas y llamadas de datos con `ExigirPermiso(...)` (redirige a «Sin acceso» o responde 403 en JSON); el menú solo es comodidad. Las pantallas usan JavaScript propio (`caf.js`) sin librerías externas, con texto siempre insertado como texto (nunca HTML). | Candidata |

| D-105 | Hasta que se responda P-58, los datos de las personas externas se conservan sin límite de tiempo y no hay bloque «Datos personales» en Catálogos. | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-58** — Datos personales de las personas externas (documento, nombres y apellidos registrados en las solicitudes): ¿por cuánto tiempo se conservan y qué aviso de privacidad se les muestra (Ley 29733)? **Para consultar en la presentación del prototipo.** Mientras tanto se guardan sin límite de tiempo (D-105). El prototipo traía un bloque «Datos personales» (meses de conservación y texto del aviso) que no se construyó; si se aprueba, requiere una tabla de parámetros.
- **P-59** — Aviso «está en uso» (ejemplo: al editar el motivo «Visita técnica», avisar que ya lo usan 12 solicitudes y que por eso se desactiva y no se elimina). El prototipo lo muestra; requiere un procedimiento que cuente usos. Antes decía: el prototipo avisa «está en uso en N registros» al editar un catálogo; requiere un procedimiento que cuente usos. Por ahora el aviso es general.
- **P-60** — Autogestión de contraseña (olvidé mi contraseña por correo): se evalúa después del MVP.
- **T-13** — La pantalla no cambia con HANA: usa los servicios existentes.

---

# Decisiones de Personal y Usuarios y roles (2026-10-19)

| N.º | Decisión | Estado |
|---|---|---|
| D-106 | «Trabajadores» pasa a llamarse **Personal** en el menú, la pantalla y los textos. El código técnico del permiso (`PER_CAF_ADMIN_TRABAJADORES`) y los textos de los procedimientos no cambian por ahora (ver P-61). | Candidata |
| D-107 | **Personal** = catálogo del personal del grupo (documento, nombres, área, cargo, empresa, correo, anexo). De aquí sale el responsable de atención. Estar en Personal no da acceso al sistema. Se desactiva, no se elimina; no se desactiva a quien tiene una cuenta de usuario activa. Al editar a una persona se actualiza la copia de sus datos en su usuario. | Candidata |
| D-108 | **Usuarios y roles**: un usuario es una persona de Personal (sus datos vienen de allí) o un externo con empresa (por ejemplo vigilancia contratista). Los roles son las licencias `LIC_CAF_*` en la sede VES y puede tener varios. Las reglas (último administrador activo, duplicados) las aplican los procedimientos. | Candidata |
| D-109 | El administrador **no define contraseñas**: al crear un usuario (o al generar otro enlace) el sistema muestra una sola vez un enlace de un solo uso, válido 3 días, que el administrador entrega al usuario; el usuario define su propia contraseña. Sin envío por correo por ahora (resuelve provisionalmente P-54). | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-61** — Renombrar «trabajador» a «personal» también en el código del permiso y en los mensajes de los procedimientos (cambio en la base y en la traducción a HANA).
- **P-62** — «Importar desde Excel» del prototipo (carga masiva de personal): no construido; confirmar si entra en el MVP.
- **P-63** — Envío del enlace de contraseña por correo (hoy lo entrega el administrador): requiere un tipo de correo nuevo en `CAF_Correo_Pendiente`.
- **T-14** — Las pantallas no cambian con HANA; los procedimientos `ERP_PERSONAL_*` y `ERP_USUARIO_*` ya están previstos en T-06.

---

# Decisiones de la solicitud de visita — lado solicitante (2026-10-19)

| N.º | Decisión | Estado |
|---|---|---|
| D-110 | Pantallas del **solicitante** (permiso `PER_CAF_SOLICITUD_PROPIA`): **Mis solicitudes** (contadores por estado, filtros por empresa/persona/DNI/fecha, acciones Ver / Reutilizar / Cancelar), **Nueva solicitud** (asistente de 3 pasos: datos de la visita, personas, revisión y envío) y **Detalle** (datos, personas con sus acciones, historial). Funcionalidad del prototipo 1.1. | Candidata |
| D-111 | Los botones salen de las banderas `Puede_*` que calcula la base de datos, y cuando no se puede se muestra el motivo (`Motivo_No_*`). La web no repite reglas. | Candidata |
| D-112 | **Editar** una solicitud ya enviada se hace en el **Detalle** («Editar datos» en una ventana, y las personas se editan, retiran o corrigen allí mismo), no reabriendo el asistente. Es una diferencia con el prototipo (que reutiliza el asistente); el resultado para el usuario es el mismo. El asistente se usa solo para crear y para «Reutilizar». | Candidata |
| D-113 | **Reutilizar** copia empresa, responsable, motivo, zonas, observaciones, correos y personas (no las retiradas) de otra solicitud; la fecha y la hora se eligen de nuevo. La nueva solicitud guarda de cuál viene. | Candidata |
| D-114 | Las personas externas se **buscan por tipo y número de documento**: si ya existen, sus nombres se completan solos y se pueden corregir (se actualiza el registro); si no, se registran al agregarlas. Servicio nuevo `ISrv_Persona_Externa` (buscar por documento, crear, actualizar). | Candidata |
| D-115 | El **tipo de acceso** no se elige en esta etapa: se usa el único habilitado (hoy «Visita externa»). La sede es VES fija. Si más adelante se habilita otro tipo, hay que añadir el selector. | Candidata |
| D-116 | El **responsable de atención** se busca escribiendo 2 letras del nombre y solo aparece personal activo. | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-64** — Selector de tipo de acceso en el asistente cuando se habiliten Contratista, Proveedor o Interno visitante (D-115).
- **P-65** — El prototipo muestra un aviso cuando una persona ya está aprobada el mismo día en otra solicitud; no está construido (requiere un procedimiento de consulta). Confirmar si se quiere.
- **P-66** — Correos en copia: hoy se escriben separados por «;» en un solo campo; el prototipo los muestra como etiquetas. Cambiar si se prefiere.
- **T-15** — Las pantallas no cambian con HANA; usan los servicios `ERP_CAF_SOLICITUD_*` y `ERP_CAF_PERSONA_EXTERNA_*` ya previstos en T-06.

