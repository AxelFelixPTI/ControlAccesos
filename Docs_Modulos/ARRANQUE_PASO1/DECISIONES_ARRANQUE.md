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

---

# Decisiones de la solicitud de visita — lado coordinador (2026-10-21)

| N.º | Decisión | Estado |
|---|---|---|
| D-117 | Pantalla **Solicitudes** del coordinador (permisos `PER_CAF_SOLICITUD_APROBAR` o `PER_CAF_SOLICITUD_VER_TODAS`): pestañas **Por decidir (N)** y **Todas**, filtros (empresa, solicitante, persona o DNI, fecha, estado) y ventana **Revisar** con las pestañas Personas e Historial. Si no hay nada por decidir, abre en «Todas». | Candidata |
| D-118 | La decisión se toma **persona por persona**: se marcan las personas y se elige **Aprobar todas / Aprobar seleccionadas / Observar seleccionadas / Rechazar seleccionadas**. Observar y rechazar exigen texto. Si quedan personas sin marcar, la pantalla pregunta qué hacer con ellas: dejarlas pendientes, observarlas o rechazarlas (con su propio mensaje). | Candidata |
| D-119 | El **paso** que se decide lo determina la base de datos (`Pasos_Mis_Decidir`); la web no lo elige. Si las personas marcadas tienen pasos distintos, se hace una decisión por paso. Solo se pueden marcar las personas que el usuario puede decidir; quien tiene solo `VER_TODAS` ve la solicitud en solo lectura. | Candidata |
| D-120 | *(Reemplazada por D-169 el 2026-10-27.)* **«+ Agregar persona (queda aprobada)»** para invitados de último momento: usa `ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA` (servicio nuevo `AgregarAprobadaAsync`). Disponible mientras la solicitud no esté cancelada y la visita no haya pasado. El solicitante recibe el aviso. | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-67** — Insignia con el número de solicitudes por decidir junto a «Solicitudes» en el menú lateral (hoy el número aparece solo dentro de la pantalla).
- **P-68** — Paginación de la bandeja: hoy se listan todas las solicitudes que cumplen el filtro; confirmar el volumen esperado antes de agregar páginas.
- **P-69** — Vista de solo lectura para quien tiene `VER_TODAS` sin `APROBAR` (ej. gerencia): confirmar qué roles la tendrán.
- **T-16** — La pantalla no cambia con HANA; usa `ERP_CAF_SOLICITUD_BANDEJA_LISTAR`, `_DECIDIR` y `_PERSONA_AGREGAR_APROBADA`, ya previstos en T-06.

---

# Decisiones de Vigilancia — «Control de accesos» (2026-10-21)

| N.º | Decisión | Estado |
|---|---|---|
| D-121 | Pantalla **Control de accesos** (menú Vigilancia; permisos `PER_CAF_PORTERIA_VER` o `PER_CAF_PORTERIA_REGISTRAR`): lista de las personas autorizadas **para hoy**, agrupadas por solicitud (código, empresa, hora prevista, quién atiende, zonas y «Exige SCTR / EPP»). Buscador por documento, nombre o empresa; pestañas **Todos / Por ingresar / Dentro / Salieron / Denegados o no vinieron** con su cantidad. Con solo `PORTERIA_VER` la pantalla es de lectura: no aparecen los botones de ingreso ni salida. | Candidata |
| D-122 | La lista se pide una vez por búsqueda (sin filtrar por grupo) y la pantalla reparte y cuenta los grupos; así las cantidades siempre cuadran. Datos: `ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR`. | Candidata |
| D-123 | **Validar ingreso** abre una ventana con: aviso de SCTR/EPP exigidos, interruptores «Trae equipos» y «Trae herramientas o materiales», y el **checklist** (se vuelve a pedir al base cuando cambian los interruptores, conservando lo ya marcado) con «Marcar todo». Los botones permitidos y sus motivos salen de la ficha (`ERP_CAF_PORTERIA_FICHA`); la web no repite reglas. | Candidata |
| D-124 | **Respaldo previo** (RN-14): si la persona trae equipos o herramientas, el respaldo se registra dentro de la misma ventana antes de ingresar: equipos = formato G-FSCA-009; herramientas = guía de remisión (con número) o guía manual G-FSCA-010. Se registra para **una persona** por vez (la base ya admite varias). | Candidata |
| D-125 | **Desviación**: si algún ítem queda sin cumplir aparece el bloque con descripción, **coordinador consultado** y **tratamiento**. Con tratamiento «Otro» se pide el detalle y el **efecto** (ingreso: Ingresa / Ingresa restringido / No ingresa; salida: Sale / Sale y se retiene el elemento). Si falla un ítem **crítico** (identidad) solo se ofrece denegar el ingreso. El resultado calculado se muestra antes de guardar. La validación final la hace la base. | Candidata |
| D-126 | **Registro tardío**: casilla «Es un registro tardío» pide la hora real (de hoy) y obliga a explicar el motivo en la observación. Si el ingreso ya solo es posible como tardío, la casilla viene marcada y no se puede quitar. En la salida es opcional. | Candidata |
| D-127 | **Detalle** (personas que ya no están «Por ingresar»): movimientos de hoy con hora, resultado, vigilante, desviación, observación y el checklist de cada uno (✓ / ✗). | Candidata |
| D-128 | **No autorizado para hoy**: si la búsqueda no encuentra a nadie y tiene 3 letras o más, se consulta `ERP_CAF_SOLICITUD_VIGILANCIA_NO_AUTORIZADA_BUSCAR` y se muestra en rojo quién es y por qué no puede pasar (observada, rechazada, otra fecha, etc.). Si no hay nada: «No debe ingresar». | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-70** — Botón «Registrar incidencia» en cada persona (prototipo): no está hasta construir la pantalla de incidencias.
- **P-71** — Respaldo para varias personas a la vez (ej. un grupo con una sola guía de remisión): la base lo admite, la pantalla lo registra de a una persona. Confirmar si Vigilancia lo necesita.
- **P-72** — «No se presentó» es **automático** (D-70, lo ejecuta el sistema, no una persona). Lo que falta es programarlo: hoy existe la rutina pero ningún proceso en segundo plano la dispara (solo está el de correos). Hacer un proceso diario que corra después de medianoche (hora de Lima) y marque a las personas aprobadas de ayer que no ingresaron. Confirmar con P-44 si es al cierre del mismo día o a primera hora del siguiente.
- **P-73** — La lista de hoy se carga al abrir y al buscar; no se refresca sola entre varios vigilantes. Confirmar si se quiere actualización automática cada cierto tiempo.
- **P-74** — Sede fija VES en la consulta de «No autorizado» y en las opciones de desviación (ver P-57, sede activa).
- **T-17** — La pantalla no cambia con HANA; usa `ERP_CAF_SOLICITUD_VIGILANCIA_*`, `ERP_CAF_PORTERIA_*`, `ERP_CAF_RESPALDO_*` y `ERP_CAF_DESVIACION_*_DROPDOWN`, ya previstos en T-06.

---

# Ajustes del 2026-10-21 (noche): hora de Lima y consulta de aprobadas

| N.º | Decisión | Estado |
|---|---|---|
| D-129 | **Zona horaria**: toda conexión a la base abre con `Timezone=America/Lima` (se agrega sola a la cadena si no la trae). Motivo: `CURRENT_DATE` y `CURRENT_TIMESTAMP` usaban la hora del servidor de la base (UTC); después de las 19:00 en Lima la base ya estaba en el día siguiente y rechazaba «hoy» con «La fecha de la visita no puede ser anterior a hoy». Las rutinas no cambian. | Candidata |
| D-130 | Vigilancia tiene dos modos: **Hoy** (ingreso y salida) y **Aprobadas (todas las fechas)**, de **solo consulta**: búsqueda y rango «visita desde / hasta» (por defecto desde hoy), sin botones de ingreso ni salida; **Detalle** disponible si la persona ya tuvo movimientos. Máximo 500 filas, con aviso. | Candidata |
| D-131 | Rutina nueva `ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS` (archivo `SP_CAF_SOLICITUD_VIGILANCIA_APROBADAS.sql`): mismas columnas y permisos que `_LISTAR`, sin fijar el día. | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-75** — Confirmar el servidor de producción: si usa otra zona horaria o ya está en hora de Lima, el ajuste de D-129 sigue siendo correcto. Datos de prueba guardados antes del ajuste pueden tener horas corridas 5 horas.
- **T-18** — En HANA, la zona horaria se resuelve en la sesión o en el servidor (`CURRENT_DATE` usa la hora del servidor HANA); revisar al traducir. La rutina nueva se traduce igual que `_LISTAR` (T-06), con `TOP 500` en lugar de `LIMIT`.

---

# Usuarios de demostración y limpieza (2026-10-23)

| N.º | Decisión | Estado |
|---|---|---|
| D-132 | Script `11_SEED_DEMO_USUARIOS.sql` (restaurar_bd.ps1 lo corre solo, por su número): 8 personas en Personal y 8 usuarios **ficticios** con licencia en VES: 1 administrador, 1 coordinador, 3 vigilancia y 3 solicitantes. Correos `@trianon.test` (dominio que no existe), documentos `900000xx`, contraseñas de prueba públicas por rol. Sin ellos, una base reconstruida no tendría cómo entrar. Se puede ejecutar varias veces sin duplicar. | Candidata |
| D-133 | Las contraseñas del script se guardan ya convertidas (PBKDF2-SHA256, 210 000 vueltas, el mismo formato de la aplicación). No piden cambio al primer ingreso. Como las contraseñas son públicas, **el script es solo para piloto y pruebas**. | Candidata |
| D-134 | `LIMPIAR_DATOS_PRUEBA.sql` (manual, no lo corre el restaurador): borra los datos de operación (solicitudes, personas externas, decisiones, movimientos, respaldos, desviaciones, incidencias, correos pendientes, bitácora) y reinicia los números; opcionalmente borra los usuarios y Personal de prueba (correo `@trianon.test`) conservando un administrador (`PARAM_ADMIN_CONSERVAR`). No toca catálogos ni usuarios reales. Se cancela entero si no quedara un administrador activo con contraseña. | Candidata |
| D-135 | Las pruebas de Hito 2 (escritura) y Hito 3 (lectura) cuentan quién recibe avisos y cuántos Coordinadores hay; ahora borran los usuarios de demostración al inicio (dentro de su transacción, se deshace con el ROLLBACK). Resultado con los usuarios cargados: todas las pruebas pasan. | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-76** — Los usuarios de demostración tienen correos ficticios: si el envío de correos (P-51) está activo, los avisos a esas direcciones no llegarán a nadie. Usar solo en piloto.
- **P-77** — Producción: definir cómo se crea el primer administrador real (hoy: entrar con el demo, crear el real y ejecutar la limpieza). Alternativa: un procedimiento de arranque que lo cree con una contraseña temporal que obligue a cambiarla.
- **T-19** — Los scripts de usuarios son solo de piloto; en HANA el primer administrador se carga con el procedimiento que se decida en P-77.

---

# Decisiones de la pantalla Desviaciones del coordinador (2026-10-23)

| N.º | Decisión | Estado |
|---|---|---|
| D-136 | Pantalla **Desviaciones** (menú Coordinador; permiso `PER_CAF_DESVIACION_CONFORMIDAD`): pestañas **Por revisar (N)** y **Revisadas (N)**, búsqueda por persona, DNI o código, y tabla con código, fecha, persona (con solicitud y empresa), etapa, descripción y decisión (tratamiento y efecto). Si no hay nada por revisar al abrir y existen revisadas, abre en Revisadas. | Candidata |
| D-137 | **Revisar** abre una ventana con persona, solicitud, momento (quién registró), descripción, a quién se consultó, decisión y efecto, y el **checklist** del movimiento (✓ / ✗). **Dar conformidad** con comentario opcional; la base decide quién puede (`Puede_Dar_Conformidad`) y la web muestra el motivo si no puede. Las revisadas se ven en solo lectura con quién dio la conformidad. | Candidata |
| D-138 | La conformidad es una revisión, no una sanción: el texto de la pantalla aclara que la persona no tiene una falta. | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-78** — El prototipo muestra en la lista la columna «No cumplió» (los ítems fallidos); la rutina `_LISTAR` no los devuelve, por eso solo se ven en el detalle. Ampliar la rutina si se quiere en la lista.
- **P-79** — Si una desviación originó una incidencia, la ventana lo indica; el enlace directo se agrega cuando exista la pantalla de incidencias.
- **P-80** — Sin filtro por rango de fechas en la pantalla (la rutina lo admite). Confirmar si hace falta.
- **T-20** — La pantalla no cambia con HANA; usa `ERP_CAF_DESVIACION_LISTAR`, `_DETALLE`, `_CONTADORES` y `_CONFORMIDAD_DAR`, ya previstos en T-06.



---

# Decisiones de las pantallas de Incidencias (2026-10-24)

| N.º | Decisión | Estado |
|---|---|---|
| D-139 | Pantalla **Incidencias** del Coordinador (permiso `PER_CAF_INCIDENCIA_DECIDIR`): pestañas **Por decidir (N)** y **Todas**, búsqueda, filtros por estado, origen (Vigilancia / Coordinador) y fechas. **Decidir** abre el detalle (tipo, hora, lugar, descripción, quién registró y personas involucradas) y permite **Confirmar** o **Desestimar** con sustento obligatorio. | Candidata |
| D-140 | Pantalla **Incidencias del día** de Vigilancia (permiso `PER_CAF_INCIDENCIA_REGISTRAR`): solo las de hoy, en solo lectura, y el botón **Registrar incidencia**. Es el mismo controlador y el mismo JS; cambia el modo. | Candidata |
| D-141 | Formulario **Registrar incidencia**: personas involucradas (se buscan entre quienes ingresaron hoy, dentro o ya salidos), tipo (si es «Otro» pide especificar), hora aproximada, lugar (zona del catálogo u «Otro lugar» con texto) y descripción. La fecha siempre es hoy. Si quien registra es Coordinador, queda confirmada; si es Vigilancia, queda Registrada. | Candidata |
| D-142 | Una incidencia ya decidida no se vuelve a decidir (la base responde 409 y la pantalla muestra el mensaje). El menú resalta la entrada correcta (Incidencias / Incidencias del día) por acción. | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-81** — Las incidencias solo se registran para personas que ya ingresaron hoy; una incidencia de alguien que no llegó a entrar (p. ej. en la puerta) no se puede registrar. Confirmar si hace falta.
- **P-82** — Falta el botón «Registrar incidencia» dentro de la fila de cada persona en Control de accesos (el formulario ya lo admite con una persona pre-elegida). Confirmar si se agrega (relacionado con P-70).
- **P-83** — La hora de la incidencia es solo de hoy; no se pueden registrar incidencias de días anteriores desde Vigilancia.
- **T-21** — Las pantallas no cambian con HANA; usan `ERP_CAF_INCIDENCIA_LISTAR`, `_DETALLE`, `_CONTADORES`, `_PERSONAS_BUSCAR`, `_REGISTRAR` y `_DECIDIR`, ya previstos en T-06.


---

# Decisiones del Reporte de accesos y del botón de incidencia en Vigilancia (2026-10-24)

| N.º | Decisión | Estado |
|---|---|---|
| D-143 | Pantalla **Reporte de accesos** (menú Coordinador; permiso `PER_CAF_REPORTE_VER`): cada fila es un movimiento en portería (reemplaza el registro en papel G-FSCA-008). Filtros: fechas (por defecto, los últimos 7 días), persona, DNI o empresa, tipo de movimiento y «solo con desviación». Arriba muestra el resumen del rango (ingresos, restringidos, denegados, salidas, desviaciones, incidencias). | Candidata |
| D-144 | El rango máximo es de **92 días** (lo valida el procedimiento y la pantalla avisa). En pantalla se ven hasta 1000 movimientos; si hay más, aparece un aviso y la exportación trae todos. | Candidata |
| D-145 | **Exportar a Excel** genera un archivo **CSV** con los mismos filtros (UTF-8 con BOM, se abre en Excel con tildes correctas). Las celdas que empiezan con `=`, `+`, `-` o `@` llevan un apóstrofo delante para que Excel no las ejecute como fórmula. **Imprimir** usa la impresión del navegador (sirve para guardar en PDF). | Candidata |
| D-146 | **Control de accesos (Vigilancia):** cada persona que está **Dentro** o ya **Salió** tiene el botón **Registrar incidencia**, que abre el mismo formulario de Incidencias con la persona ya elegida (como en el prototipo). Solo aparece con el permiso `PER_CAF_INCIDENCIA_REGISTRAR` y en el modo «Hoy». Cierra P-82. | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-84** — El prototipo muestra la columna «Atendió» (el responsable de la solicitud); la rutina `ERP_CAF_REPORTE_ACCESOS` no la devuelve, por eso no está en la tabla ni en el archivo. Ampliar la rutina si se quiere.
- **P-85** — **Descargar PDF del Reporte de accesos: pendiente de hacer.** Hoy solo existe la exportación a CSV (se abre en Excel). Cuando se haga el PDF, **tanto el CSV como el PDF deben responder a los mismos filtros de la pantalla** (fechas, persona/DNI/empresa, ingresos o salidas y «solo con desviación»). El CSV ya lo cumple (probado: con «Salidas» trae solo salidas; con «solo con desviación» trae solo esas). Para el PDF hay que decidir si se genera con una librería o con la impresión del navegador, y si lleva membrete.
- **P-86** — El reporte no tiene filtro por resultado (Ingresa / Restringido / No ingresa) aunque la rutina lo admite. Confirmar si hace falta.
- **T-22** — La pantalla no cambia con HANA; usa `ERP_CAF_REPORTE_ACCESOS` y `ERP_CAF_REPORTE_RESUMEN_DIARIO`, ya previstos en T-06. La rutina `ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA` aún no tiene pantalla.


## Corrección del 2026-10-24 (tarde)

| N.º | Decisión | Estado |
|---|---|---|
| D-147 | **Exportar a Excel** ya no navega la pestaña hacia el archivo: la pantalla lo pide en segundo plano y lo entrega como descarga. Así no se corta la sesión de depuración de Visual Studio (que se detenía al navegar a la descarga) y un error, como pasar de 92 días, se muestra como aviso. | Candidata |


---

# Orden de pendientes y entorno de desarrollo (2026-10-24, noche)

| N.º | Decisión | Estado |
|---|---|---|
| D-148 | `PENDIENTES_VALIDACION.md` se reorganizó **por relevancia para el MVP** en seis grupos (A por construir, B datos reales, C reglas a confirmar, D mejoras del prototipo, E producción/HANA, F postergado) y trae la fecha en que apareció cada punto y con quién validarlo. | Candidata |
| D-149 | **Entorno de desarrollo:** la detención de la aplicación al descargar el CSV venía de la opción de Visual Studio «detener el depurador cuando se cierre la ventana del navegador», no de la aplicación. Se desactivó esa opción y se resolvió. No afecta a producción. | Resuelta |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-87** — **Pantalla «Autorizados por zona»: postergada, fuera del MVP.** No está en el prototipo y no se tiene claro para qué se usaría. La rutina `ERP_CAF_REPORTE_AUTORIZADOS_POR_ZONA` queda sin pantalla. Se retoma solo si el negocio la pide.


---

# Integración de correo (2026-10-24, noche)

| N.º | Decisión | Estado |
|---|---|---|
| D-150 | **Quién recibe cada aviso (visitante externo).** Solicitud nueva o modificada: Para = quien decide el primer paso; CC = solicitante + correos adicionales del asistente. Decisión: Para = solicitante; CC = aprobadores + adicionales, y **Vigilancia (portería) solo si la solicitud queda Aprobada**. Cancelada con autorizados: Para = aprobadores y Vigilancia; CC = solicitante + adicionales. Se arma con la función `ERP_CAF_FN_COPIA_CORREO`; los repetidos se depuran al enviar (quien va en Para no se repite en CC). | Candidata |
| D-151 | **Hilo de mensajes.** El aviso de solicitud nueva es la raíz (`Message-ID` `<caf-sol-{id}@dominio>`); los demás llevan el mismo asunto con «Re: » y `In-Reply-To`/`References` hacia la raíz. Asunto único: `Solicitud {código} · {empresa}`. | Candidata |
| D-152 | **Plantilla única** HTML sobria (tablas y estilos en línea, 600 px) + versión en texto plano (multipart): título según el tipo, mensaje, tabla con todos los datos de la solicitud, detalles adicionales, tabla de personas con su estado, botón «Ver solicitud» y pie «mensaje automático». Los datos se leen al enviar (el correo refleja el estado actual). Rutinas nuevas, solo del sistema: `ERP_CAF_CORREO_SOLICITUD_DATOS` y `_PERSONAS`. | Candidata |
| D-153 | El campo opcional «Observaciones» del asistente pasa a llamarse **«Detalles adicionales (opcional)»** y se incluye en el correo. No hay campo nuevo ni cambio de tablas. | Candidata |
| D-154 | Configuración nueva en `Correo`: `UrlBase` (dirección de la web para el botón), `RedirigirA` (**modo prueba**: todo sale a una sola dirección con aviso de a quién habría llegado) y `EnviarDesdeWeb` (la web envía los pendientes por sí misma; por defecto sí). La clave del correo va en `appsettings.Local.json` o variable de entorno, nunca en git. | Candidata |
| D-155 | Los cuerpos que dejan los procedimientos pasan de HTML a **texto plano** (saltos de línea); la plantilla los escapa y les da formato. Así la presentación vive en un solo lugar. | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-88** — Confirmar con Sandra la matriz de destinatarios de D-150 (en especial: Vigilancia solo recibe copia cuando queda Aprobada; no recibe avisos de solicitudes nuevas ni observadas).
- **P-89** — Probar en un envío real con Gmail que los correos de una solicitud se agrupan en un solo hilo (Gmail puede reemplazar el `Message-ID`; el asunto «Re: …» debería sostener el hilo igual).
- **P-90** — La casilla remitente no se lee: si alguien responde a todos, esa respuesta no llega a nadie. Decidir si se agrega «Responder a» hacia el coordinador o el solicitante, o si basta el aviso del pie.
- **P-91** — Dirección real de la web (`UrlBase`) y cuenta corporativa definitiva (se suma a P-51).
- **T-23** — En HANA `ERP_CAF_FN_COPIA_CORREO` no puede llamar a un procedimiento con parámetros de salida dentro de una función: traducirla como procedimiento con salida o calcular la lista dentro del procedimiento que encola. `CHR(10)` se traduce a `CHAR(10)`.


---

# Correo en uso real y recuperación de contraseña (2026-10-25)

| N.º | Decisión | Estado |
|---|---|---|
| D-156 | **Orden de configuración:** `appsettings.json` < `appsettings.Local.json` < **variables de entorno** (las variables ganan siempre). Antes el `Local.json` las pisaba (una `Clave` vacía anulaba `Correo__Clave`). Las opciones anidadas se escriben con doble guion bajo: `Correo__Clave`. | Resuelta |
| D-157 | **Envío SMTP con MailKit** en lugar de `System.Net.Mail`, que terminaba en «The connection was closed» al conectar con Gmail. 587 = STARTTLS, 465 = SSL directo. Si falla, `Ultimo_Error` guarda la cadena completa de errores. | Resuelta (probada con Gmail) |
| D-158 | **Ojito para ver la contraseña** en todos los campos de contraseña (ingreso, definir, cambiar), puesto desde `layout.js`; no cambia las vistas. | Candidata |
| D-159 | **«¿Olvidó su contraseña?»** en la pantalla de ingreso: el usuario escribe su correo y recibe un enlace de un solo uso, con vencimiento de 60 minutos (tipo de correo `USUARIO_DEFINIR_PASSWORD`, plantilla propia). La respuesta es siempre la misma exista o no la cuenta; un mismo correo no puede pedir otro enlace antes de 60 segundos. El enlace usa `Correo:UrlBase`, no el encabezado Host. Cierra P-54 y P-63. | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-92** — El límite de un enlace por minuto se guarda en memoria: se pierde al reiniciar la web y no sirve con varias instancias. Si hace falta, moverlo a la base.
- **P-93** — El enlace de restablecer queda en el cuerpo del correo en la cola (`CAF_Correo_Pendiente`). El token es de un solo uso y vence en 60 minutos, pero conviene decidir si se borra el cuerpo al enviarlo.
- ~~**P-94** — Botón «Contraseña» de la parte superior.~~ **Resuelto el 2026-10-26 (D-163).**
- **P-95 a P-99 y P-101 a P-104** — Puntos de mejora recibidos el 2026-10-25. Se resuelven por entregas (A a E); P-100 a P-104 quedaron resueltos el 2026-10-26 (D-160 a D-164). Ver `PENDIENTES_VALIDACION.md`.



---

# Puntos de mejora · Entrega A (2026-10-26)

| N.º | Decisión | Estado |
|---|---|---|
| D-160 | **Reporte de accesos:** «Sale» pasa a **«Salió»** y «Sale y se retiene el elemento» a **«Salió y se retuvo el elemento»**, en pantalla, en el CSV y al imprimir. Las opciones de tratamiento de una desviación no cambian (son acciones, no hechos). | Construido |
| D-161 | **Asistente, paso Personas:** si los nombres se autocompletaron al encontrar un documento y luego se cambia el número, esos nombres se **limpian al instante** (antes de buscar otra vez). Si el nuevo documento tampoco existe, se escriben a mano. Al **editar** una persona ya cargada no se limpia nada. | Construido |
| D-162 | **Autocompletar empresa:** `ERP_CAF_SOLICITUD_EMPRESAS_BUSCAR(texto)` devuelve las empresas ya escritas en solicitudes (sin distinguir mayúsculas ni tildes, agrupadas, las más usadas primero, máximo 10). El campo «Empresa o procedencia» muestra sugerencias desde 2 letras; se puede escribir una nueva. **Autocompletar persona:** al escribir 3 letras en «Apellido paterno» aparecen hasta 8 personas ya registradas (nombre y documento); al elegir una se llenan tipo, número y nombres. Usa `ERP_CAF_PERSONA_EXTERNA_LISTAR`. Disponible también en la ventana de Coordinación para agregar personas. | Construido |
| D-163 | **Se quita el botón «Contraseña»** de la barra superior. La clave se cambia con «¿Olvidó su contraseña?» (enlace por correo, D-159); el cambio obligatorio del primer ingreso sigue funcionando igual. | Construido |
| D-164 | **Correos en copia (P-103):** el campo del asistente **sí se envía** (la prueba de base lo comprueba en cada tipo de correo). En **modo prueba** (`Correo__RedirigirA` con valor) todo el correo sale a esa única dirección, así que la copia no se entrega y el aviso del correo lo dice («Habría llegado a… / Copia a…»). Para ver llegar la copia real hay que **vaciar `RedirigirA`** y usar usuarios con buzones reales. | Aclarado |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **T-24** — En HANA `ERP_CAF_SOLICITUD_EMPRESAS_BUSCAR`: `LIMIT 10` pasa a `TOP 10` (o `LIMIT` fijo), `::` no existe (se usa `CAST`) y el agrupado por minúsculas se calcula igual con `LOWER`.


---

# Puntos de mejora · Entrega B (2026-10-26): incidencias y catálogos de área y cargo

| N.º | Decisión | Estado |
|---|---|---|
| D-165 | **Lo que registra el Coordinador nace CONFIRMADO.** `ERP_CAF_INCIDENCIA_REGISTRAR` fija el estado según el origen: Coordinador → `CONFIRMADA` (con él como decisor, fecha y sustento «Registrada por el Coordinador: confirmada directamente.»); Vigilancia → `REGISTRADA` (espera decisión). Antes el SP la dejaba siempre «Registrada» aunque la pantalla decía lo contrario. `12_ALTER_INCIDENCIA_COORD_CONFIRMADA.sql` confirma las antiguas. | Construido |
| D-166 | **Una sola pantalla de Incidencias.** Quien tiene `PER_CAF_INCIDENCIA_DECIDIR` (Coordinador) ve todas con filtros, decide y registra; quien solo tiene `PER_CAF_INCIDENCIA_REGISTRAR` (Vigilancia) ve las de hoy y registra. El menú muestra una sola entrada «Incidencias» (en Coordinador, o en Vigilancia si no puede decidir). La ruta `/Incidencias/Dia` redirige a `/Incidencias`; la vista `Dia.cshtml` se elimina. El servidor limita a Vigilancia a las de hoy aunque pida otras fechas. | Construido |
| D-167 | **Control de accesos, botón «Registrar incidencia» del Coordinador:** lleva a `/Incidencias?persona=<id>&nombre=<texto>` y abre el formulario con esa persona ya elegida; al guardar queda confirmada. Vigilancia sigue registrando desde la misma ventana (queda «Registrada»). | Construido |
| D-168 | **Áreas y Cargos editables desde Catálogos** (`CatalogosController`, tipos `area` y `cargo`), con el mismo comportamiento que los otros catálogos: crear, editar, activar/desactivar (no se eliminan), código automático, no repetir nombre. Se usan al registrar Personal y Usuarios. Reutiliza `ISrv_Catalogo_Area/Cargo` ya existentes: sin SQL nuevo. | Construido |


---

# Puntos de mejora · Entrega C (2026-10-27): corrección de emergencia del Coordinador (P-98)

| N.º | Decisión | Estado |
|---|---|---|
| D-169 | **Se quita «agregar con aprobación automática» de la revisión normal.** Reemplaza a D-120 y al procedimiento `ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA` (el archivo de rutinas lo elimina con `DROP PROCEDURE IF EXISTS`). En su lugar hay dos acciones de **corrección de emergencia**: `ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA` y `ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA`. Mientras la solicitud está por decidir, el Coordinador solo observa, rechaza o aprueba; las personas las modifica el solicitante. | Construido |
| D-170 | **Cuándo aplica:** solo con la solicitud en estado `APROBADA` o `APROBADA_PARCIAL` y **hasta el día de la visita** (si la fecha ya pasó, 409: es un cambio «en caliente» del mismo día). Exige permiso `PER_CAF_SOLICITUD_APROBAR` y un rol que decida algún paso obligatorio del tipo de acceso. No aplica a solicitudes canceladas. | Construido |
| D-171 | **El sustento es obligatorio** (hasta 300 caracteres) en agregar y en quitar. No se guarda en la persona (`ERP_CAF_SOLICITUD_RECALCULAR` limpia `Aprobacion_Mensaje`): queda en la **bitácora** (eventos `AGREGAR_EMERGENCIA` y `RETIRAR_EMERGENCIA`, con nombre y sustento) y en el **correo**. El historial los muestra como «corrección de emergencia». | Construido |
| D-172 | **Quitar:** solo a una persona `APROBADA` que aún está `ESPERADA`. Si ya ingresó (`DENTRO`) o tiene movimientos, **se bloquea**: Vigilancia registra su salida con una observación. No se quita a la **última** persona (101: el solicitante cancela la solicitud). No se borra nada: la persona pasa a `RETIRADA` y sus decisiones dejan de ser vigentes. Vigilancia lo ve al instante porque sus listas leen `Aprobacion='APROBADA'`. | Construido |
| D-173 | **Agregar:** la persona nace con origen `AGREGADA_COORDINADOR`, hereda los pasos y queda aprobada en los pasos que le tocan al usuario por rol; si faltara algún otro paso queda pendiente y se avisa como cualquier persona por aprobar. | Construido |
| D-174 | **Correo `SOLICITUD_CORRECCION`** (tipo nuevo; `13_ALTER_CORREOS_CORRECCION.sql` amplía el CHECK de `CAF_Correo_Pendiente`): **Para** = solicitante + Vigilancia; **Copia** = aprobadores + correos adicionales del asistente (`ERP_CAF_FN_COPIA_CORREO(sol,'N','Y','N','Y')`). Cambiar quién va en copia es una línea en cada SP. En modo prueba (`Correo__RedirigirA`) todo sale a una sola dirección. | Construido |
| D-175 | **Pantalla de Coordinación:** el botón «+ Agregar persona (emergencia)» está en un bloque de aviso y solo aparece si la solicitud es `APROBADA`/`APROBADA_PARCIAL` y la fecha no pasó; «Quitar (emergencia)» solo en la persona autorizada que aún no ingresó (a la que ya ingresó se le muestra el motivo). Ambos piden el sustento. `puedeCorregir` y `puedeQuitar` solo muestran u ocultan botones: el SP vuelve a validar todo. | Construido |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-106** — Confirmar con Sandra: (a) ¿quién va en copia del correo de emergencia? (hoy aprobadores + correos del asistente); (b) ¿`APROBADA_PARCIAL` también admite corrección? (hoy sí); (c) si es la única persona, ¿debe poder cancelar el Coordinador? (hoy solo el solicitante cancela); (d) ¿se permite quitar a quien ya salió? (hoy no: solo `ESPERADA`).
- **T-25** — En HANA: los dos procedimientos nuevos usan `DROP PROCEDURE IF EXISTS` (ver la forma admitida en esa instancia), parámetros `INOUT`, `CHR(10)` → `CHAR(10)`, concatenación `||` con `COALESCE`, y `13_ALTER_CORREOS_CORRECCION.sql` cambia un CHECK (en HANA, `ALTER TABLE ... DROP CONSTRAINT` y volver a crear).


---

# Puntos de mejora · Entrega D (2026-10-28): rol activo y celular

| N.º | Decisión | Estado |
|---|---|---|
| D-176 | **Rol activo (P-97).** Quien tiene más de un grupo (Solicitante, Coordinador, Vigilancia, Administración) ve en la barra superior un selector «Todos mis roles / <grupo>». Elegir uno **solo filtra el menú** (`MenuCaf.Para(usuario, rol)`); no concede ni quita permisos: cada pantalla y cada procedimiento siguen validando por permiso, y la URL de otra pantalla sigue abriendo si el usuario tiene el permiso. Se guarda en la cookie `caf_rol` (1 año, HttpOnly, SameSite Lax) para entrar con el último rol usado; la primera vez entra con «Todos». Solo se acepta un rol que el usuario tiene; una cookie inválida se ignora. Acción `Cuenta/CambiarRol` (POST con token anti-falsificación) y luego va a Inicio. Con un rol elegido se muestran todas las entradas de ese grupo (p. ej. «Incidencias» en Vigilancia aunque el usuario también decida incidencias). Sin SQL. | Construido |
| D-177 | **Celular, 360 a 414 px (P-96), todas las pantallas.** Un solo bloque de CSS (`site.css`, `@media (max-width:860px)`) y un pequeño script en `layout.js`: (a) las tablas `.tabla` pasan a **tarjetas**, con la etiqueta de cada dato tomada del encabezado (`data-label` que pone el script al cargar y cada vez que una pantalla redibuja filas); (b) las ventanas ocupan **toda la pantalla** con título y botones fijos; (c) botones, pestañas, selectores y menú de **44 px** mínimo; letra de campos de 16 px (evita el zoom de iOS); (d) filtros en dos columnas; (e) barra superior apilada; (f) se corrige el desborde de «Usuarios y roles». No se tocó ninguna vista ni JS de pantalla. En escritorio no cambia nada. | Construido |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-107** — Probar en celulares reales (Android y iPhone) las pantallas de Vigilancia, Coordinación y Mis solicitudes; yo las probé con un navegador simulado a 360, 390 y 414 px, no en un teléfono. Confirmar además si el selector de rol debe ir en la barra superior (como ahora) o en una página de perfil.

---

# Corrección a la Entrega D (2026-10-29): Control de accesos también es del Coordinador

| N.º | Decisión | Estado |
|---|---|---|
| D-178 | **«Control de accesos» está en el menú del Coordinador** (grupo Coordinador, entre sus pantallas) para consultar lo del día y registrar incidencias; le basta `PER_CAF_PORTERIA_VER`, **sin** el rol de Vigilancia (que queda para el personal de portería). En «Todos mis roles» no se repite en el grupo Vigilancia. **«Vigilancia» como rol del selector (D-176) solo lo tiene quien puede REGISTRAR en portería** (`PER_CAF_PORTERIA_REGISTRAR`): ver el control de accesos ya no convierte a nadie en Vigilancia. Con el rol Vigilancia activo se ven Control de accesos e Incidencias; con el rol Coordinador activo, Control de accesos junto a sus pantallas. Solo cambia `MenuCaf` (nuevo campo `ExigirAlguno`); la pantalla ya mostraba al Coordinador sin botones de ingreso/salida y con «Registrar incidencia». Sin SQL. | Construido |

---

# Puntos de mejora · Entrega E (2026-10-29): hilo de correo y «responder a todos» (P-95)

| N.º | Decisión | Estado |
|---|---|---|
| D-179 | **Asunto estable del hilo.** El aviso de solicitud nueva sale con `Solicitud SOL-xxxxx · Empresa` (la empresa **de la creación**). Los demás correos de esa solicitud usan ese mismo asunto con «Re: » delante, aunque después se edite la empresa. `ERP_CAF_CORREO_SOLICITUD_DATOS` devuelve la columna nueva `Asunto_Hilo` (el asunto del correo `SOLICITUD_NUEVA` ya encolado). Las solicitudes anteriores a esta entrega no lo tienen: usan la empresa actual. Así Gmail agrupa los correos aunque pasen días. | Construido |
| D-180 | **«Responder» y «Responder a todos».** Cada correo de una solicitud lleva `Reply-To` = **quien actuó**: el solicitante en nueva, editada y cancelada; el Coordinador en decisión y corrección (`Responder_A` y `Responder_A_Nombre` salen de `UsuarioID_Create` del correo en `ERP_CAF_CORREO_PENDIENTES_LISTAR`). «Responder a todos» = Reply-To + Para + Copia, así que los copiados desde el asistente (p. ej. gerencia) siguen al tanto y proveedores o almacén pueden sumarse a la conversación. El remitente visible pasa a «Nombre · Control de Accesos» (la dirección real sigue siendo la casilla del sistema). El pie ya no dice «no se monitorea» en los correos con quien actuó: explica qué hace cada botón. Se agrega `Thread-Topic` (asunto sin «Re: »). Un `Responder_A` inválido se ignora y el correo vuelve al pie anterior. Los correos sin solicitud (p. ej. definir contraseña) no llevan Reply-To. En modo prueba (`Correo__RedirigirA`) el Reply-To se conserva. **Alcance:** `In-Reply-To` y `References` apuntan solo a la **raíz** del hilo (correo de solicitud nueva), no a toda la cadena. Lógica pura en `CabecerasCorreo.cs`; `EnviadorSmtp` solo la aplica. | Construido |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-95 / P-89** — Probar con Gmail real (ver `Docs_Modulos/HITO_04_Incidencias_Reporte_Correos_2026-10-09/GUIA_CORREO.md`): un solo hilo; «Responder» va a quien actuó; «Responder a todos» incluye la copia. No se pudo probar aquí.
- **P-108** — Decidir si quien responde por correo debe quedar registrado en el sistema (hoy la conversación vive solo en el correo) y si hace falta una cadena `References` completa.
- **T-26** — En HANA: `ERP_CAF_CORREO_SOLICITUD_DATOS` y `ERP_CAF_CORREO_PENDIENTES_LISTAR` cambian de columnas, por eso llevan `DROP FUNCTION IF EXISTS` antes de crear (forma admitida en esa instancia); `LIMIT 1` → `TOP 1` en la subconsulta de `Asunto_Hilo`; el `LEFT JOIN` a `Usuario` es entre schemas.

---

# Corrección de notificaciones · Entrega F (2026-10-29): Vigilancia en aprobación parcial y un solo aviso por revisión

| N.º | Decisión | Estado |
|---|---|---|
| D-181 | **Aviso propio a Vigilancia.** Antes Vigilancia solo iba en copia del aviso de decisión cuando la solicitud completa quedaba `APROBADA`, así que en una aprobación parcial no recibía nada. Ahora, cada vez que una decisión `APROBADA` deja personas con aprobación completa, `ERP_CAF_SOLICITUD_DECIDIR` encola un correo de tipo nuevo `SOLICITUD_VIGILANCIA` para quienes registran en portería de esa sede (`PORTERIA`), con las personas que esa decisión autoriza guardadas en la columna nueva `CAF_Correo_Pendiente.IDs_Personas` (`14_ALTER_CORREOS_VIGILANCIA.sql`). No depende del estado de la solicitud. Al **enviar**, el correo vuelve a filtrar y lista solo a quienes **siguen** `APROBADA` (si alguien se reabrió o se observó entre tanto, no aparece); si no queda nadie, **no se envía** y el correo queda en `ERROR` con el motivo (nunca como enviado). El correo de Vigilancia no muestra estado de la solicitud, conteos de otras personas, observación del coordinador ni motivos de cancelación, solo las personas autorizadas, la visita y las zonas. Vigilancia ya **no** va en copia del aviso de decisión (evita el duplicado). En la pantalla no cambia nada. Una decisión que observa o rechaza no genera aviso a Vigilancia. La evidencia es la propia cola `CAF_Correo_Pendiente` (tipo, solicitud, destinatarios, estado, intentos, error, fecha de envío), visible en la pantalla de correos. | Construido |
| D-182 | **Un solo aviso de decisión por revisión.** El Coordinador decide por grupos (aprobar a unos y observar o rechazar a otros) y cada grupo encolaba su correo, repitiendo la cabecera. Ahora, si el mismo usuario decide otro grupo de la misma solicitud en menos de 2 minutos y el aviso anterior sigue `PENDIENTE` sin intentos, el SP **agrega una línea** («Además: 1 persona observada(s). + motivo») a ese aviso en vez de encolar otro. La cabecera sale una vez y la tabla de personas de la plantilla ya muestra el estado y la observación **de cada persona**. Si el primer aviso ya salió, el siguiente es un correo aparte (no se reescribe lo enviado). Las observaciones por persona ya existían (`Aprobacion_Mensaje` en cada persona): cada grupo observado queda con su propio motivo y no se copia a las demás. | Construido |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-109** — Confirmar con Sandra: (a) ¿el aviso a Vigilancia debe incluir a todas las aprobadas de la solicitud hasta el momento o solo a las que esa decisión autoriza (hoy, solo las de esa decisión)?; (b) ¿la ventana de 2 minutos para fusionar los avisos de decisión es suficiente?
- **T-27** — En HANA: `GET DIAGNOSTICS ... = ROW_COUNT` pasa a `::ROWCOUNT` (o `SELECT COUNT(*)` previo); `INTERVAL '2 minutes'` → `ADD_SECONDS(CURRENT_TIMESTAMP, -120)`; `ALTER TABLE ... ADD ("IDs_Personas" VARCHAR(2000))`; `string_to_array`/`ANY` de las pruebas no existen: usar `SERIES_GENERATE` o `LIKE`; `STRING_AGG` → `STRING_AGG(... ORDER BY ...)` ya admitido en HANA.

---

# Mejora de documentos · Entrega J (2026-10-29): adjuntos de la solicitud y envío por correo

| N.º | Decisión | Estado |
|---|---|---|
| D-183 | **Documentos adjuntos a la solicitud, guardados en la propia BD.** Tabla nueva `CAF_Solicitud_Adjunto` (script `15_CAF_SOLICITUD_ADJUNTO.sql`): nombre, extensión, tipo de contenido, tamaño, hash SHA-256 y `Contenido` (bytea; BLOB en HANA). Máximo **2 documentos por solicitud** y **5 MB** cada uno; solo PDF, DOC, DOCX, XLS y XLSX. El documento pertenece a la **solicitud, no a una persona** (un SCTR trae varios nombres en un solo archivo). Validación doble: en la web (mensaje inmediato) y en el servidor (`ValidadorAdjuntos`: nombre sin ruta, extensión permitida, tamaño, y firma del archivo: `%PDF-`, OLE2 o ZIP según la extensión), más el SP (vacío, >5 MB, máximo 2, duplicado por hash). Se agregan y se quitan (borrado lógico, queda en el historial) solo mientras la solicitud admite edición de datos (`Editar_Datos`), y solo el solicitante. | Cerrada |
| D-184 | **Quién ve los documentos.** El solicitante, el Coordinador que ve la solicitud y Vigilancia **desde la primera aprobación (parcial o total)**, con la misma función `ERP_CAF_FN_ADJUNTO_VISIBLE`. No se esconden a Vigilancia por tener personas observadas: el documento es de la solicitud. La descarga pasa por `AdjuntosController` (`[Authorize]`; la decisión la toma el SP), responde 404 si no es visible y envía `X-Content-Type-Options: nosniff`. | Cerrada |
| D-185 | **Los documentos viajan por correo.** Los correos de solicitud nueva, de aviso a Vigilancia y de corrección llevan los documentos como archivos adjuntos y los listan en el cuerpo («Documentos adjuntos»). El de decisión y el de cancelación **no** los llevan. Si falla la lectura de los documentos, o suman más de 20 MB, el correo **no sale** y queda para reintento (no se envía incompleto). Para que el aviso de «solicitud nueva» no salga antes de terminar de subir los archivos, el procesador **retiene cada correo `RetencionSegundos` (15 s por defecto, `Correo:RetencionSegundos`)** antes de leerlo de la cola (`HV_Retener_Segundos` en `ERP_CAF_CORREO_PENDIENTES_LISTAR`). | Cerrada |
| D-186 | **Arquitectura para varios tipos de ingreso (H e I) sin rehacer nada.** Ya existen `Catalogo_Tipo_Acceso`, `Tipo_Acceso_Item_Checklist`, `CAF_Registro_Checklist` y `CAF_Solicitud.ID_Catalogo_Tipo_Acceso`; los adjuntos cuelgan de la solicitud y no del tipo. Las entregas H (selector de tipo, contratista, proveedor) e I (catálogo de checklist por tipo) son aditivas: datos nuevos y pantallas, sin cambiar tablas ya entregadas. | Cerrada |
| D-187 | **Tipo de ingreso elegido en el asistente (Entrega H).** El paso 1 abre con «Tipo de ingreso» y «Sede» (sin paso extra). Tipos: Visitante externo y Contratista (activos), Proveedor visible pero deshabilitado con «Próximamente: pendiente de definición» (`ERP_CAF_SOLICITUD_TIPOS_OPCIONES`; CREAR lo rechaza igualmente porque `Disponible = 'N'`). «Personal interno visitante» queda oculto (`Activo = 'N'`; reactivable en Catálogos). El tipo decide formulario, validaciones, datos guardados, correos y la versión JSON de la solicitud. Al cambiar de tipo en pantalla se conservan fecha, empresa y responsable, pero **no se envían** los campos del otro tipo. En edición, tipo y sede no se cambian. |
| D-188 | **Una sola validación por tipo en la BD.** `ERP_CAF_FN_TIPO_INGRESO_VALIDAR` (script `SP_CAF_SOLICITUD_TIPO_INGRESO_ALL.sql`) la usan CREAR y EDITAR_DATOS. Sumar un tipo = una rama más en esa función y su formulario web; no cambian tablas ni los SP de crear/editar. Los parámetros nuevos de CREAR/EDITAR_DATOS (cochera, placa, detalle de área, contacto nombre/teléfonos/correos) van **antes** de `HV_UsuarioID` porque `EjecutorSp` omite los INOUT. |
| D-189 | **Cochera por sede.** `Catalogo_Sede.Aplica_Cochera` (MAG = 'Y', VES = 'N'). Solo se pregunta en sedes que la ofrecen; si se pide, la placa es obligatoria (5 a 8 letras o números, se guarda en mayúsculas y sin guiones ni espacios) y sin cochera no se admite placa (CHECK `CK_CAF_Solicitud_Cochera`). Cambiar cochera, placa, área o contacto en una solicitud ya aprobada se registra en el historial y **no** reabre la aprobación; cambiar actividades o zonas sí. |
| D-190 | **Contratista reutiliza columnas existentes.** Empresa contratista = `Empresa_Visitante`; actividades = `Motivo_Detalle` (obligatorio); fecha y hora del servicio = `Fecha_Hora_Prevista`; área de ejecución = zonas del catálogo + `Area_Detalle` libre (opcional); contacto = `Contacto_Nombre` (uno), `Contacto_Telefonos` (varios, mín. 6 dígitos) y `Contacto_Correos` (varios válidos, separados por «;»). Motivo fijo `SERVICIO_CONTRATISTA` (no se ofrece a visitantes). Varias personas con el mismo mecanismo de siempre. Los correos de contacto **no** se copian solos a los avisos. |
| D-191 | **Aprobación del contratista = misma que el visitante:** un paso `AUTORIZACION` con la licencia de Coordinador de la sede (copiado en el script 16). Cambiarlo es dato, no código. |
| D-192 | **Sedes por licencia.** El selector ofrece solo sedes donde el usuario tiene `PER_CAF_SOLICITUD_PROPIA` (`ERP_CAF_SOLICITUD_SEDES_OPCIONES`). Para que Magdalena funcione, el administrador debe asignar licencias **en esa sede** al solicitante y al Coordinador; si no, nadie la ve ni recibe avisos. Las pantallas de Vigilancia siguen siendo solo de VES (sin cambio). Se agregó la zona «Oficinas administrativas» de Magdalena. El detalle, la revisión del Coordinador y los correos muestran tipo, área, contacto y cochera. |
| D-193 | **Restaurador y pruebas claros (2026-10-30).** `restaurar_bd.ps1` silencia los avisos NOTICE de los `DROP IF EXISTS` (`PGOPTIONS=-c client_min_messages=warning`), muestra la salida de cada prueba, marca en rojo las filas FALLA, imprime el total OK/FALLA y, si psql se detiene por un error real, muestra el mensaje de psql. `PRUEBAS_FASE1_HITO0.sql` V1.1 retira dentro de su transaccion (ROLLBACK) los datos demo del script 11 para dar 65/65 tambien sobre la base completa (antes 60/65). |
| D-194 | **Proveedor de abastecimiento: datos propios (Entrega 1, 2026-11-02).** El proveedor reutiliza columnas existentes: `Empresa_Visitante` = razón social, `Fecha_Hora_Prevista` = día y hora estimada de la entrega, `Contacto_Telefonos` = teléfono del transportista y `Placa_Vehiculo` (siempre obligatoria). Columnas nuevas en `CAF_Solicitud`: empresa del grupo que recibe (`ID_Catalogo_Empresa_Grupo_Destino`), `Proveedor_RUC` (11 dígitos), `Proveedor_Direccion`, `Vehiculo_Marca`, `Licencia_Conducir`. `CAF_Solicitud_Persona.Es_Principal` marca al transportista principal (el conductor; el personal de apoyo son los demás). `ID_Personal_Responsable` pasa a ser opcional: el proveedor no tiene «responsable de atención». El CHECK de cochera se relajó a Y/N y la regla «la placa depende de la cochera» pasó a la función de validación (para el proveedor la placa es siempre obligatoria). Solo se admite en sedes con `Catalogo_Sede.Aplica_Proveedor = 'Y'` (hoy VES), un dato y no un código fijo, igual que la cochera. Las reglas viven en `ERP_CAF_FN_PROVEEDOR_VALIDAR`; los demás tipos rechazan estos datos. |
| D-195 | **Licencias y permisos del proveedor.** Permisos nuevos: `PER_CAF_PROVEEDOR_SOLICITAR`, `PER_CAF_PROVEEDOR_VER`, `PER_CAF_PROVEEDOR_VIGILANCIA`, `PER_CAF_PROVEEDOR_ALMACEN`. Licencias nuevas: `LIC_CAF_SOLICITANTE_PROVEEDOR`, `LIC_CAF_COORD_PROVEEDOR` (es la licencia del paso de aprobación del tipo; además tiene `PER_CAF_SOLICITUD_APROBAR`), `LIC_CAF_VIGILANCIA_PROVEEDOR` y `LIC_CAF_ALMACEN`. La Vigilancia y el Coordinador convencionales NO deciden, registran ni ven proveedores. `ERP_CAF_FN_PERMISO_TIPO` y `ERP_CAF_FN_PORTERIA_PERMISO` eligen el permiso según el tipo. El tipo «Proveedor» solo se ofrece (`ERP_CAF_SOLICITUD_TIPOS_OPCIONES` ahora recibe el usuario) a quien tiene `PER_CAF_PROVEEDOR_SOLICITAR` en una sede que lo recibe: el tipo queda Disponible pero nadie lo ve hasta asignar la licencia (lanzamiento oculto). `ERP_CAF_SOLICITUD_SEDES_OPCIONES` devuelve también `Aplica_Proveedor`. |
| D-196 | **Zona, motivo y checklist del proveedor.** Zona fija «Esclusa vehicular» (`ESCLUSA_VEHICULAR`, VES, SCTR y EPP exigidos) y motivo fijo «Entrega de proveedor»: el servidor los impone y descarta lo que envíe el cliente. Checklist de ingreso = identificación, SCTR, EPP y **placa**; la placa usa la condición nueva `SOLO_PRINCIPAL` (solo se pide al transportista principal; el apoyo tiene 3 ítems). El proveedor **no tiene checklist de salida**: `ERP_CAF_PORTERIA_SALIDA_REGISTRAR` acepta cero ítems si la persona es de proveedor (supuesto, ver P-122). |
| D-197 | **Estado operativo separado de la aprobación.** Tablas `CAF_Solicitud_Operacion` (una por solicitud: `PROGRAMADO → EN_ESPERA → INGRESO → EN_ATENCION → RECEPCIONADO → SALIO`, y `NO_SE_PRESENTO`; marca `Activa`) y `CAF_Solicitud_Operacion_Evento` (solo se agrega; usuario 0 = sistema). `ERP_CAF_PROVEEDOR_SINCRONIZAR` (la llama `RECALCULAR` y `CANCELAR`) crea la operación en PROGRAMADO cuando el **principal** queda aprobado y no está cancelada; si deja de estarlo mientras sigue PROGRAMADO la desactiva (sale de Vigilancia), y al aprobar de nuevo la reactiva (una sola fila). Cada transición toma el bloqueo de la solicitud y devuelve 409 si el estado ya no corresponde (dos personas a la vez). SPs: `ERP_CAF_PROVEEDOR_LLEGADA` (Vigilancia de proveedores; solo el día programado), `_ATENDER` (Almacén; responsable de Almacén opcional), `_RECEPCION` (Almacén; CONFORME o CON_OBSERVACION, esta exige descripción). |
| D-198 | **Ingreso y salida reutilizan portería.** No se duplican registros físicos: `ERP_CAF_PORTERIA_REGLA_MOVIMIENTO` llama a `ERP_CAF_PROVEEDOR_REGLA` (el principal ingresa solo tras la llegada; el apoyo solo después de que ingresó el principal; el principal sale solo tras la recepción) y ingreso/salida llaman a `ERP_CAF_PROVEEDOR_PORTERIA_POST` (el ingreso del principal pasa a INGRESO; cuando ya nadie queda dentro y estaba RECEPCIONADO pasa a SALIO). El ingreso con registro tardío no exige la llegada. `ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS` excluye al proveedor (tendrá su propio listado). |
| D-199 | **Editar, reprogramar y cancelar.** Solo mientras la entrega sigue PROGRAMADO (tras la llegada: 409). Reprogramar la fecha o cambiar el RUC reabre la aprobación como en los demás tipos (la entrega queda inactiva hasta aprobar de nuevo); placa, marca, licencia, dirección, teléfono y empresa destinataria se registran sin reabrir. Cancelar es lógico (`CANCELADA`) y desactiva la entrega. Pasada la fecha: «Reutilizar». |
| D-200 | **Almacén en copia y «no se presentó».** `ERP_CAF_FN_COPIA_CORREO` agrega a Almacén (usuarios con `PER_CAF_PROVEEDOR_ALMACEN` en la sede, modo `ALMACEN` de `DESTINATARIOS`) a los correos de la solicitud desde su registro hasta que la entrega figura SALIO o NO_SE_PRESENTO; no hay buzón compartido. Los correos de Vigilancia de una solicitud de proveedor van a quienes tienen `PER_CAF_PROVEEDOR_VIGILANCIA`. Una entrega PROGRAMADA cuyo día pasó se marca NO_SE_PRESENTO (usuario 0) con el cierre del día (`ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR`, que ahora también cuenta estas entregas). Entregas en otro estado al cierre no se tocan (P-118). |
| D-201 | **Calendario de entregas con permiso propio y de solo lectura.** Permiso `PER_CAF_PROVEEDOR_DASHBOARD` y licencia `LIC_CAF_PROVEEDOR_DASHBOARD` (script 18), aparte de las demás. La licencia de Almacén también lo trae. Quien solo lo tiene ve las tarjetas sin botones; las acciones (asignar, atender, terminar) exigen `PER_CAF_PROVEEDOR_ALMACEN` y cada procedimiento lo vuelve a validar (101). Quien lo tiene ve **todas** las entregas de la sede (P-128). Menú: grupo «Proveedores». |
| D-202 | *(Reemplazada por D-206 a D-211, corrección del 2026-11-03.)* **La esclusa es un recurso único.** Tabla `CAF_Exclusa` (una fila por sede). `ERP_CAF_PROVEEDOR_ATENDER` la ocupa con un `UPDATE` condicionado (`... WHERE ID_Solicitud_Actual IS NULL`) y comprueba si le tocó; solo uno gana y el otro recibe 409 «Hay otra atención en curso». `RECEPCION` la libera. Una ocupación huérfana (la solicitud ya no está EN_ATENCION) se libera sola. No se usó índice único parcial porque HANA no lo tiene. Probado con dos sesiones reales. |
| D-203 | **Responsable programado ≠ efectivo.** El programado (`ID_Personal_Programado`, quién lo asignó y cuándo) es informativo y opcional; se puede asignar, cambiar o quitar desde la aprobación hasta el día programado y mientras no se inicie la atención. Cada cambio queda en el historial (`CAF_Solicitud_Operacion_Evento.ID_Personal_Programado`); el primero no se pierde. El efectivo es quien pulsa Atender (`ID_Usuario_Atencion`, y su persona en `ID_Personal_Almacen`); el que termina queda en `ID_Usuario_Recepcion`. El programado no impide que otro atienda. Elegibles: personal activo cuyo usuario activo tiene `LIC_CAF_ALMACEN` en la sede (P-129). |
| D-204 | *(Reemplazada por D-206 a D-211, corrección del 2026-11-03.)* **Atender y terminar.** Atender exige estado INGRESO (Vigilancia ya registró el ingreso), día programado igual o anterior a hoy (P-130) y esclusa libre. Terminar pasa a RECEPCIONADO y libera la esclusa; cualquier usuario de Almacén puede terminarla; la observación es opcional (vacía = CONFORME, con texto = CON_OBSERVACION) (P-131). `ATENDER` ya no recibe la persona de Almacén (firma anterior eliminada). La salida sigue siendo de Vigilancia y solo tras RECEPCIONADO (regla de la Entrega 1). |
| D-205 | *(Reemplazada por D-206 a D-211, corrección del 2026-11-03.)* **Qué aparece en el calendario y cómo se actualiza.** Solo operaciones activas (principal aprobado) de solicitudes no canceladas; si pierde la aprobación mientras está PROGRAMADO, sale solo. Sin tiempo real: botón «Actualizar» y consulta automática cada 60 s con la pestaña visible (P-125). Etiquetas: PROGRAMADO «Programado», EN_ESPERA «Llegó, pendiente de ingreso», INGRESO «En espera de atención», EN_ATENCION «En atención», RECEPCIONADO «Recepción culminada», SALIO «Salió», NO_SE_PRESENTO «No se presentó». |
| D-206 | **Flujo corregido (2026-11-03).** `PROGRAMADO →(verificación de Vigilancia, registra la llegada)→ EN_ESPERA →(Almacén confirma disponibilidad; Vigilancia valida ingreso)→ INGRESO →(Almacén inicia)→ EN_ATENCION →(Almacén termina)→ RECEPCIONADO →(salida de Vigilancia)→ SALIO`. Cierres: `NO_SE_PRESENTO` (cierre automático, aún sin ejecutor) e `INGRESO_DENEGADO` (el Coordinador deniega en la verificación). Ya no existe «llegada» sin verificar: `ERP_CAF_PROVEEDOR_LLEGADA` se eliminó y `Fecha_Llegada`/`ID_Usuario_Llegada` pasan a ser la hora y el usuario de la verificación. Script 19. |
| D-207 | **Verificación = `ERP_CAF_PORTERIA_INGRESO_REGISTRAR` reutilizado** (checklist y desviaciones del visitante). El hook `ERP_CAF_PROVEEDOR_PORTERIA_POST` lo reinterpreta: persona DENEGADA → operación `INGRESO_DENEGADO` y libera la exclusa; DENTRO → la persona vuelve a `ESPERADA` (sin hora de ingreso) y la operación pasa a `EN_ESPERA`; calcula `Con_Desviacion`. Solo desde PROGRAMADO y el día programado (el registro tardío admite PROGRAMADO/EN_ESPERA). La decisión del Coordinador sobre desviaciones se toma en el acto; su panel solo la confirma (no hay estado «En consulta»). |
| D-208 | **Ingreso físico = `ERP_CAF_PROVEEDOR_INGRESO_VALIDAR`** (permiso Vigilancia): exige EN_ESPERA y que la exclusa esté reservada para esa solicitud (409 «Almacén aún no confirmó…»); la persona principal pasa a DENTRO y la operación a INGRESO. |
| D-209 | **La exclusa se reserva al confirmar disponibilidad** (`ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CONFIRMAR`): solo desde EN_ESPERA y **el mismo día programado**; `UPDATE` atómico condicionado (`ID_Solicitud_Actual IS NULL`), 409 si otra entrega la tiene. Una reserva huérfana (titular inactivo o fuera de EN_ESPERA/INGRESO/EN_ATENCION) se libera sola y se muestra LIBRE. `ATENDER` ya no la toma: exige INGRESO, día ≤ hoy y ser el titular. `RECEPCION` la libera. Estados de la exclusa: LIBRE, RESERVADA, DENTRO, EN_ATENCION. Lo que sí se puede hacer con anticipación es asignar responsable programado (D-203). |
| D-210 | **Cancelar disponibilidad** (`ERP_CAF_PROVEEDOR_DISPONIBILIDAD_CANCELAR`): Almacén, motivo obligatorio (≥3 caracteres), solo antes del ingreso (409 si ya está INGRESO/EN_ATENCION); libera la exclusa para otro proveedor en espera; guarda quién/cuándo/por qué; evento `DISP_CANCELADA` (y `DISP_CONFIRMADA` al confirmar) en `CAF_Solicitud_Operacion_Evento`. |
| D-211 | **Calendario V2.** Etiquetas: Programado, En espera, Ingreso, En atención, Recepción culminada, Salió, No se presentó, Ingreso denegado; chips sólidos por estado. Color por empresa que recibe (`Empresa_Destino_Codigo`: Sostenible, Energo, Power Technology, Ascensores) con inicial TS/TE/PT/TA. Filtros por empresa, estado y fecha (en la URL). **Leyenda de estados y empresas siempre visible** al pie. Almacén tiene un botón dinámico de tres etapas (Confirmar disponibilidad → Iniciar atención → Terminar atención) más «Cancelar disponibilidad»; marcas «Almacén listo» y «Con desviación». Almacén no registra ingresos ni salidas. Licencias: `LIC_CAF_VIGILANCIA_PROVEEDOR` recibe `PER_CAF_DESVIACION_REGISTRAR` y `LIC_CAF_COORD_PROVEEDOR` recibe `PER_CAF_DESVIACION_CONFORMIDAD`. |
| D-212 | **Ajustes del calendario (2026-11-05).** La leyenda va arriba y es plegable. Distintivo de reserva: borde grueso + cinta «EXCLUSA RESERVADA» en la entrega titular de la exclusa (regla existente, `exclusa.id`); en RECEPCIONADO borde fino «POR SALIR» (la exclusa ya está libre); se quita en SALIO. Vista Día (Mes/Semana/Día) con filtros. Si se prefiere que la reserva dure hasta la salida (opción B) habrá que cambiar la liberación en `RECEPCION`. Para ajustes pendientes ver la conversación: corrección de datos en emergencia (todo menos el número de documento) y retiro de la única persona → solicitud Rechazada. |
| D-213 | **Vigilancia de proveedores (2026-11-05).** En «Control de accesos» el transportista principal de una entrega muestra su estado operativo: PROGRAMADO → «Verificar datos» (mismo checklist y desviaciones del ingreso normal; el modal dice «Registrar verificación»); EN_ESPERA → «Validar ingreso» (habilitado solo con Almacén listo; `ERP_CAF_PROVEEDOR_INGRESO_VALIDAR`) y «Retiró sin ingresar»; RECEPCIONADO → «Registrar salida»; dentro y sin atender no hay salida. Nuevo estado operativo `RETIRO_SIN_INGRESO` (script 20) y `ERP_CAF_PROVEEDOR_RETIRO_SIN_INGRESO`: Vigilancia (`PER_CAF_PROVEEDOR_VIGILANCIA`), motivo obligatorio, solo desde EN_ESPERA, libera la exclusa si estaba reservada y deja a la persona principal como NO_SE_PRESENTO. `ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR` y `..._APROBADAS` devuelven además `Es_Proveedor`, `Estado_Operativo`, `Disponibilidad_Confirmada` (se recrean con DROP FUNCTION por el cambio de columnas). Los apoyos conservan los botones normales. |
| D-214 | **La exclusa se libera con la SALIDA, no al terminar la atención (opción B, 2026-11-05).** El camión sigue dentro y sale por la misma exclusa por la que entró, así que la reserva dura desde «Confirmar disponibilidad» hasta que Vigilancia registra la salida del principal (`ERP_CAF_PROVEEDOR_PORTERIA_POST` → SALIO libera). `ERP_CAF_PROVEEDOR_RECEPCION` ya no libera. Un titular RECEPCIONADO sigue siendo válido (no es reserva huérfana) y bloquea `CONFIRMAR` de otra entrega; estado nuevo de la exclusa `POR_SALIR`. Sin liberación manual: Vigilancia (24/7) registra la salida. Calendario: el borde grueso llega hasta Salió; cinta «EXCLUSA RESERVADA» → «POR SALIR · EXCLUSA OCUPADA» (desaparece el borde fino). Reemplaza la parte de D-212 sobre «POR SALIR» y la de D-209 «RECEPCION la libera». La demo deja a la entrega 6 recepcionada con la exclusa. |
| D-215 | **Corrección de emergencia: corregir datos y retirar a la única persona (2026-11-05).** (1) Nuevo `ERP_CAF_SOLICITUD_PERSONA_CORREGIR_EMERGENCIA`: el Coordinador corrige tipo de documento, apellidos y nombres de una persona AUTORIZADA y aún `ESPERADA`, de una solicitud aprobada, hasta el día de la visita, con sustento obligatorio. **El número de documento no se cambia** (si es otra persona: quitar y agregar). Escribe en el registro de personas externas (una fila por persona real: el cambio se ve en toda solicitud donde figure) y NO reabre la aprobación. Bitácora con el antes y el después, y correo al solicitante y a Vigilancia (copia a aprobadores y correos adicionales). (2) `ERP_CAF_SOLICITUD_PERSONA_RETIRAR_EMERGENCIA` V2.0 (firma nueva con `HV_Confirmar_Rechazo`; se borra la anterior): si es la **única** persona vigente, sin confirmar responde 409 con el aviso; confirmado, la persona queda RETIRADA y la solicitud **RECHAZADA** (no CANCELADA: cancelar es solo del solicitante), se libera lo reservado de la exclusa, bitácora `SOLICITUD:RECHAZAR_EMERGENCIA` y correo con asunto «la solicitud fue rechazada». (3) Proveedor: las dos acciones solo valen mientras la entrega siga `PROGRAMADO`; desde `EN_ESPERA` responden 409 (Vigilancia usa «Retiró sin ingresar»). Web: en la revisión del Coordinador cada persona autorizada trae «Corregir datos (emergencia)» (documento visible y bloqueado) y «Quitar (emergencia)», que pasa a «Quitar y rechazar (emergencia)» con advertencia cuando es la única. Sin tablas nuevas. |
| D-216 | **Checklist de salida del proveedor, provisional (2026-11-05).** Sin ítems de salida Vigilancia no podía registrar la salida del camión («No hay ítems de checklist para responder»). Script 21 agrega `SAL_PROVEEDOR_DOCUMENTOS` («Verifica que el vehículo se retire con la carga y documentación correspondiente, como guía de remisión, documento de despacho, acta de entrega u otro sustento aplicable»), etapa SALIDA, condición `SOLO_PRINCIPAL`, no crítico, solo tipo PROVEEDOR. Dato editable desde el administrador de checklist. El texto definitivo y si debe ser crítico quedan por validar (P-143). |
| D-217 | **Correos en copia como buscador con etiquetas (2026-11-05).** Nueva función `ERP_CAF_SOLICITUD_CORREOS_SUGERIR(texto)` (en `SP_CAF_SOLICITUD_LECTURA_ALL.sql`): con 2 letras o más sugiere primero los correos de usuarios activos (con su nombre) y después los correos externos ya usados en copias y contactos de solicitudes anteriores, sin repetir y sin distinguir mayúsculas ni tildes; máximo 12; globales. **No hay tabla nueva**: lo externo «se guarda» solo al enviar una solicitud y aparece en las siguientes (cambia lo previsto de un script 21 con tabla). Web: componente `chipsCorreo` en `comun.js` que reemplaza el campo de texto de «Correos en copia» y de «Correos» del contacto del contratista: Enter, «;» o «,» agregan, la × quita, sin repetidos, validación de formato, lo escrito sin confirmar también se envía. El valor viaja igual que antes («a; b»), así que SPs y bitácora no cambian. Endpoint `Solicitudes/Correos`. La reutilización de empresas y personas ya existía (autocompletar de empresa y de persona); los nombres y teléfonos de contacto anteriores no se sugieren todavía. |
| D-218 | **Cierre forzado del día de proveedores (2026-11-06).** Una salida no registrada dejaba la exclusa pegada al día anterior (con la opción B no hay liberación manual). Ahora el *día operativo* termina a la **hora de corte** (parámetro `PROVEEDOR_HORA_CORTE` en la tabla nueva `CAF_Parametro`, por defecto **00:00**, editable con `ERP_CAF_PARAMETRO_GUARDAR`; sin pantalla). `ERP_CAF_PROVEEDOR_CIERRE_DIA` (idempotente) cierra toda entrega activa de un día anterior: `PROGRAMADO` → `NO_SE_PRESENTO`; `EN_ESPERA/INGRESO/EN_ATENCION/RECEPCIONADO` → **`CIERRE_FORZADO`** (estado nuevo); libera la exclusa, las personas aún ESPERADAS pasan a NO_SE_PRESENTO y queda evento del sistema (usuario 0). Quien ya estaba DENTRO sigue DENTRO y Vigilancia puede registrar su **salida tardía**: la entrega pasa a `SALIO`, no vuelve a ocupar la exclusa y se envía correo `PROVEEDOR_AVISO` al **Coordinador** (descuido de Vigilancia; él decide). Mientras la entrega siga `RECEPCIONADO`, `ERP_CAF_PROVEEDOR_AVISOS_SALIDA` encola un correo por hora a Vigilancia (copia a Almacén) con la hora de corte. Lo dispara `CierreProveedorWorker` (cada minuto, registrado con `AddEnvioDeCorreos`) y, de respaldo, el calendario y la lista de Vigilancia. |
| D-219 | **Refresco automático cada 10 s (2026-11-06).** `CAF.autoRefrescar(fn, segundos)` en `caf.js`: vuelve a consultar mientras la pestaña esté a la vista y **no haya una ventana abierta**; al volver a la pestaña refresca de inmediato. Lo usan el calendario de proveedores (antes cada minuto) y «Control de accesos» de Vigilancia (antes sin refresco); en Vigilancia además no refresca mientras el cursor está en el buscador. Los fallos del refresco son silenciosos. El botón «Actualizar» sigue. Sustituye al tiempo real (P-125) mientras no se confirme WebSocket en IIS. Coordinación y «Mis solicitudes» aún no lo tienen. |
| D-220 | **Bloque 5: accesos directos del dashboard a las pantallas originales (2026-11-06).** Cada tarjeta del calendario de proveedores muestra, según los permisos de quien mira, botones que abren la pantalla de siempre con esa entrega ya aplicada (la reutilización de las reglas, sin duplicarlas): **los botones propios de la solicitud**, solo para su dueño: **Ver solicitud** (detalle), **Duplicar** (nueva solicitud a partir de esta) y **Cancelar** (la confirmación con motivo de siempre, que llama al mismo endpoint de «Mis solicitudes»; queda **deshabilitado con el motivo** cuando la entrega ya no está PROGRAMADA —en espera, ingreso, atención…— o ya hubo ingresos: misma regla de `ERP_CAF_SOLICITUD_CANCELAR`). Columnas nuevas de `ERP_CAF_PROVEEDOR_CALENDARIO` (V2.2): `Es_Solicitante`, `Puede_Cancelar_Sol`, `Motivo_No_Cancelar_Sol`; se retiró el botón «Mis solicitudes» y el parámetro `?abrir=`), **Coordinación** (`/Coordinacion?solicitud=id`: abre «Revisar»; la etiqueta es «Revisar / emergencia» con la entrega PROGRAMADA y «Ver en Coordinación» después) y **Vigilancia** (`/Vigilancia?solicitud=id`: abre Verificar datos, Validar ingreso —solo con Almacén listo— o Registrar salida, según el estado; si no hay acción posible, avisa). Tras abrir, la URL se limpia. **Caso límite EN_ESPERA:** si la entrega pierde la aprobación antes del ingreso físico (PROGRAMADO o EN_ESPERA), `ERP_CAF_PROVEEDOR_SINCRONIZAR` la **desactiva** (sale del calendario y de Vigilancia), libera la exclusa y, si estaba EN_ESPERA, la devuelve a PROGRAMADO (los datos pueden haber cambiado: debe verificarse de nuevo al reaprobarse). Antes solo se desactivaba la PROGRAMADA y una EN_ESPERA sin aprobación seguía visible. |
| D-221 | **Filtro por tipo de solicitud en pantalla (2026-11-06).** «Mis solicitudes», la bandeja del Coordinador y «Control de accesos» de Vigilancia muestran casillas «Tipo de solicitud» (`SOL.filtroTipos` en `comun.js`): una por cada tipo que llegó en los datos, todas marcadas por defecto; se pueden quitar tipos y no se puede quitar el último. Es **solo de pantalla** (no cambia las consultas): como cada persona recibe únicamente lo que su licencia le permite, ve solo los tipos que le corresponden, y con un solo tipo el filtro no aparece. La elección se recuerda en el navegador (por pantalla). Almacén no lo tiene (solo ve proveedores). Para que Vigilancia pueda filtrar, `ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR` y `_APROBADAS` devuelven la columna nueva `Tipo_Acceso` (Mis solicitudes y la bandeja ya la devolvían). Los contadores y grupos de cada pantalla respetan el filtro. |
| D-222 | **Documentos adjuntos: hasta 10 por solicitud y 20 MB en total (2026-11-06).** Antes eran 2. Cada archivo sigue ≤ 5 MB (PDF, Word, Excel). Se agregó el tope de **20 MB sumados** porque el correo lleva los documentos como adjuntos y `ProcesadorCorreos` corta en 20 MB: así el envío nunca falla. Cambios: `ERP_CAF_SOLICITUD_ADJUNTO_AGREGAR` (10 y 20 MB, mensajes 409), `ValidadorAdjuntos.MaxPorSolicitud = 10` y `MaxBytesTotal`, textos. Aplica a todos los tipos de solicitud. |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-110** — Probar con Gmail real que el correo llega con los 2 archivos adjuntos y que el hilo se mantiene. `EnviadorSmtp` con MailKit **no se compiló ni se ejecutó aquí** (no hay MailKit en el entorno de pruebas).
- **P-111** — La verificación de firma comprueba que el archivo es de la familia que dice ser, **no** que esté sano ni libre de virus. Decidir si el piloto necesita antivirus o escaneo del servidor antes de producción.
- **P-112** — Ajustar `Correo:RetencionSegundos` (15 s) con el tiempo real de subida de los usuarios; si una subida tarda más, el primer correo sale sin el archivo (queda en la web y en los correos posteriores).
- **P-113** — Confirmar con Sandra: (a) ¿al «Reutilizar» una solicitud deben copiarse sus documentos? (hoy no); (b) ¿deben ir adjuntos también en la decisión o la cancelación? (hoy no); (c) ¿5 MB y 2 documentos bastan?
- **T-28** — En HANA: `bytea` → `BLOB`; `encode(sha256(...))` → `BINTOHEX(HASH_SHA256(...))`; `INTERVAL '1 second'` → `ADD_SECONDS`; parámetros `INOUT` del SP de agregar; `DROP FUNCTION/PROCEDURE IF EXISTS` en la forma admitida; el parámetro de contenido se pasa como `DbType.Binary`.

- **T-29** — En HANA: `ALTER TABLE ... ADD (...)` y el CHECK de cochera del script 16; la expresión regular de la placa (`!~ '^[A-Z0-9]{5,8}$'`) pasa a `NOT LIKE_REGEXPR`; `REGEXP_REPLACE(..., 'g')` a `REPLACE_REGEXPR`; sin sobrecarga de procedimientos (las firmas de CREAR y EDITAR_DATOS cambiaron: se borran las anteriores).

## Pendientes para `PENDIENTES_VALIDACION.md` (Entrega 1 de Proveedor)
- **P-117** — Si el transportista principal es **denegado** en la puerta o se **retira** tras la llegada: hoy la entrega queda EN_ESPERA sin salida automática. Definir qué pasa (cancelar la entrega, reasignar otro principal).
- **P-118** — Entregas que al cierre del día siguen en EN_ESPERA, INGRESO, EN_ATENCION o RECEPCIONADO (alguien olvidó registrar la salida): hoy no se tocan. Definir el cierre (¿SALIO automático con observación?).
- **P-119** — ¿El personal de apoyo puede ingresar después de la recepción y salir antes que el principal? Hoy: ingresa mientras la entrega esté en INGRESO, EN_ATENCION o RECEPCIONADO, y sale cuando quiera.
- **P-120** — Si el principal deja de estar aprobado **después** de la llegada (reabierto, retirado): la entrega no se desactiva (solo lo hace en PROGRAMADO).
- **P-121** — «Responsable de atención» no se pide al proveedor (queda vacío). Confirmar con Sandra; el responsable de Almacén es opcional y no se pide.
- **P-122** — Salida del proveedor **sin checklist** (supuesto mío). Confirmar.
- **P-123** — Reglas supuestas: la llegada solo se registra el día programado; editar y cancelar solo antes de la llegada. Confirmar.
- **P-124** — El cierre «no se presentó» **no tiene quien lo ejecute** en la web (existe el método, nadie lo llama). Se programa como servicio de fondo en la Entrega 3.
- **P-125** — Hosting para tiempo real (Entrega 4): preguntar a TI si la web corre en una sola instancia, si usa IIS o un proxy y si la función WebSocket Protocol está habilitada; si no, el tablero se actualizará solo por consulta cada 60 s.
- **P-126** — Correos por hito a Almacén (llegada, recepción): no pedidos; propuesta = solo tablero. Confirmar.
- **P-127** — **No asigne** las licencias de proveedor a nadie hasta la Entrega 2 (el asistente aún no pide los datos del proveedor).
- **P-128** — Todos los que tienen la licencia de lectura ven **todas** las entregas de la sede (no solo las suyas). Confirmar.
- **P-129** — Responsables programables = personal con usuario que tenga `LIC_CAF_ALMACEN` en la sede. Si hay almaceneros sin usuario no aparecen. Confirmar.
- **P-130** — Atender se permite desde el día programado en adelante (un proveedor que ingresó antes de medianoche no queda bloqueado). Confirmar.
- **P-131** — Terminar la atención con observación opcional (no pedida en el texto del modal). Confirmar.
- **P-132** — El calendario muestra la entrega cuando el transportista principal está aprobado, aunque algún apoyo siga pendiente. Confirmar.
- **P-133** — El cierre automático «no se presentó» sigue sin ejecutor (Entrega 3); hasta entonces una entrega vencida sin llegada figura PROGRAMADA en días pasados.
- **T-30** — En HANA: `ALTER COLUMN ... NULL` y `DROP/ADD CONSTRAINT` del script 17; `REGEXP_REPLACE(...,'g')` y `!~` → `REPLACE_REGEXPR`/`NOT LIKE_REGEXPR` en `ERP_CAF_FN_PROVEEDOR_VALIDAR`; sin sobrecarga: se borran las firmas anteriores de CREAR, EDITAR_DATOS, TIPOS_OPCIONES y SEDES_OPCIONES (la de CREAR tiene 6 parámetros IN nuevos antes de `HV_UsuarioID`); un parámetro IN no se reasigna (usé una variable local `lv_zsel`); llamadas tardías (`RECALCULAR` → `PROVEEDOR_SINCRONIZAR`, ingreso/salida → `PROVEEDOR_PORTERIA_POST`) exigen que el procedimiento exista al ejecutarse; `RETURNS TABLE` de `ERP_CAF_PROVEEDOR_REGLA` → función de tabla; bucles `LOOP ... EXIT` del no-show ya usados en `NO_SE_PRESENTO_MARCAR`.
- **T-31** — En HANA: sin índice único parcial → `CAF_Exclusa` (fila-candado); contar filas con `SELECT COUNT(*)` en lugar de `ROW_COUNT`; `IS NOT DISTINCT FROM` → `(a = b OR (a IS NULL AND b IS NULL))` en `ERP_CAF_PROVEEDOR_PROGRAMAR`; `UPDATE ... WHERE NOT EXISTS (...)` correlacionado con la tabla actualizada de `ATENDER` (liberación huérfana) puede requerir reescribirse con subconsulta `IN`; `ILIKE` solo se usó en pruebas; se borra la firma anterior de `ERP_CAF_PROVEEDOR_ATENDER`; `RETURNS TABLE` → función de tabla.

## Pendientes para `PENDIENTES_VALIDACION.md` (Entrega 2 corregida de Proveedor)
- **P-134** — Los permisos de desviación añadidos a las licencias de Vigilancia y Coordinador de proveedor hacen que el Coordinador de proveedor pueda revisar **todas** las desviaciones de la sede.
- **P-135** — La reserva de exclusa de un proveedor que no llega **no se libera sola al fin del día** (falta el servicio de la Entrega 3); mientras tanto Almacén la cancela a mano.
- **P-136** — Tras la verificación la persona principal vuelve a `ESPERADA`; «DENTRO» solo ocurre al validar el ingreso. No hay re-verificación todavía.
- **P-137** — Cambiar la fecha de una entrega ya EN_ESPERA no está bloqueado; confirmar la fecha de INGRESO_DENEGADO y su color rojo.
- **T-31 (actualizado)** — En HANA además: la migración del script 19 usa tabla temporal y `UPDATE ... FROM` de PostgreSQL → reescribir; se borra la firma anterior de `ERP_CAF_PROVEEDOR_ATENDER` y el SP `ERP_CAF_PROVEEDOR_LLEGADA`.
- **P-138** — «Retiró sin ingresar» deja a la persona principal como `NO_SE_PRESENTO` (grupo «Denegados o no vinieron» de Vigilancia); confirmar que es la lectura correcta.
- **T-31 (ampliado)** — HANA: `DROP FUNCTION` + `CREATE` de `ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR/APROBADAS` con tres columnas nuevas; el `CHECK` del script 20.
- **P-139** — Con la opción B, una salida no registrada bloquea la exclusa para las demás entregas; no hay liberación manual (decisión del usuario: Vigilancia atiende 24/7). Revisar tras el piloto si hace falta una.
- **P-140** — Quitar a la única persona rechaza la solicitud con una advertencia y confirmación; confirmar que «Rechazada» (y no «Cancelada») es el desenlace y que el correo al solicitante basta para que se entere.
- **P-141** — Corregir los datos en emergencia modifica el registro global de la persona: se ve en todas las solicitudes donde figure (incluidas pasadas). Confirmar que es lo deseado o si debe quedar solo en esta solicitud.
- **P-142** — Con la entrega de proveedor ya `EN_ESPERA` o más adelante no se corrigen ni se quitan personas (propuesta, no confirmada por el usuario); el caso real es «Retiró sin ingresar» de Vigilancia.
- **P-143** — Checklist de salida del proveedor: texto provisional dado por el usuario, un solo ítem para el principal y no crítico; confirmar redacción, si el apoyo también lleva checklist y si debe ser crítico.
- **P-144** — Las sugerencias de correo muestran a cualquier solicitante los correos y nombres de todos los usuarios activos (pedido del usuario: usuarios primero). Confirmar que no hay problema de privacidad o si se limita a ciertos roles.
- **T-32** — HANA: `ERP_CAF_SOLICITUD_CORREOS_SUGERIR` usa `REGEXP_SPLIT_TO_TABLE` de PostgreSQL; reescribir con `SERIES_GENERATE`/`SUBSTR_REGEXPR`.

## Pendientes para `PENDIENTES_VALIDACION.md` (Cierre forzado del día)
- **P-145** — La hora de corte (00:00) solo se cambia por SQL (`ERP_CAF_PARAMETRO_GUARDAR`); no hay pantalla. Confirmar si hace falta una de administración.
- **P-146** — El aviso de salida pendiente sale cada hora a Vigilancia (copia a Almacén) y empieza una hora después de la recepción; confirmar frecuencia, destinatarios y que no deba escalar al Coordinador antes del cierre.
- **P-147** — En la salida tardía el aviso va a los aprobadores de la solicitud (Coordinador del tipo). Confirmar que es el destinatario correcto y si lleva copia al jefe de Vigilancia.
- **P-148** — Una entrega cerrada a la fuerza con personas aún DENTRO las deja DENTRO hasta que Vigilancia registre la salida; no hay tope de tiempo. Revisar tras el piloto.
- **P-149** — El cierre de `PROGRAMADO` → `NO_SE_PRESENTO` ya no depende solo de `ERP_CAF_PORTERIA_NO_SE_PRESENTO_MARCAR`: el servicio en segundo plano lo hace para proveedores (resuelve P-133 y P-135 para proveedor; para visitantes normales sigue sin ejecutor).
- **T-33** — HANA: `ERP_CAF_PROVEEDOR_AVISOS_SALIDA` usa un ciclo `FOR ... IN SELECT`; `ERP_CAF_PROVEEDOR_CIERRE_DIA` usa `CREATE TEMP TABLE ... ON COMMIT DROP`, `CAST(.. AS INTERVAL)`, `UPDATE ... FROM` y `!~` (regex): reescribir con tablas temporales de sesión/`#`, `ADD_SECONDS`, `MERGE`/subconsulta y `LIKE_REGEXPR`. El script 22 usa `GENERATED BY DEFAULT AS IDENTITY` y `ALTER ... DROP CONSTRAINT`.

- **P-150** — El refresco de 10 s es una consulta periódica por pantalla abierta (carga en el servidor proporcional a los usuarios conectados). Confirmar el intervalo tras el piloto o pasar a tiempo real (P-125); aplicarlo también a Coordinación y «Mis solicitudes» si se desea.

## Pendientes para `PENDIENTES_VALIDACION.md` (Bloque 5)
- **P-151** — Con la entrega ya `EN_ESPERA` el Coordinador solo consulta («Ver solicitud»): las correcciones de emergencia se rechazan en la base (409, ver P-142). Confirmar que es lo deseado.
- **P-152** — Una entrega que pierde la aprobación estando `EN_ESPERA` vuelve a `PROGRAMADO` y debe verificarse de nuevo al reaprobarse (la verificación anterior y la disponibilidad de Almacén se descartan). Confirmar.
- **P-153** — El acceso a Vigilancia abre directamente la ventana de la acción (verificar, validar o salida); si se prefiere solo resaltar la fila, es un cambio de una línea. En el calendario, el solicitante ve Ver solicitud / Duplicar / Cancelar (D-220); Duplicar puede quitarse si no tiene sentido para proveedores.
- **T-34** — HANA: `DROP FUNCTION` + `CREATE` de `ERP_CAF_PROVEEDOR_CALENDARIO` por la columna nueva `Es_Solicitante`.

## Pendientes para `PENDIENTES_VALIDACION.md` (filtro por tipo)
- **P-154** — El filtro de tipo es solo de pantalla y se recuerda por navegador (no por usuario ni entre equipos). Confirmar si basta o si debe guardarse en el servidor. Las pantallas de Desviaciones e Incidencias no lo llevan (listan desviaciones/incidencias, no solicitudes).
- **P-155** — Con 10 documentos de hasta 5 MB el correo puede acercarse a 20 MB; confirmar con PDF reales (1–2 páginas) que el correo llega completo y que Gmail/Outlook del grupo aceptan ese tamaño. Si hace falta, bajar el tope total.
- **T-35** — HANA: `DROP FUNCTION` + `CREATE` de `ERP_CAF_SOLICITUD_VIGILANCIA_LISTAR` y `_APROBADAS` por la columna nueva `Tipo_Acceso`.

## D-223 — Solicitud de proveedor con transportistas múltiples (2b-1)
- **Formulario (paso 1):** el proveedor pide fecha/hora, empresa proveedora, **empresa del grupo que recibe** (lista), **responsable de la entrega** (nombre + teléfono; no tiene por qué ser el transportista), observaciones y correos en copia. **No** pide responsable de atención (lo define Almacén), zonas, motivo ni cochera.
- **Formulario (paso 2, «Personas»):** DNI y nombres son obligatorios para toda persona. Casilla **«Es transportista»** (debe haber al menos uno; el primero marcado es el **principal**). Al marcarla aparece un interruptor que muestra seis campos **opcionales** por transportista: RUC, nombre de transportista, dirección, placa, marca, licencia. Si algún transportista no trae todos sus datos, la web exige **al menos un adjunto**.
- **Modelo:** tabla nueva `CAF_Solicitud_Transportista` (script 23; migra los principales existentes). Los datos del principal se **replican** en `CAF_Solicitud` (placa, RUC, dirección, marca, licencia) para que calendario y Vigilancia sigan igual.
- **SP:** `ERP_CAF_SOLICITUD_CREAR_PROVEEDOR` (envuelve a `ERP_CAF_SOLICITUD_CREAR`, que no cambia de firma; todo o nada), `ERP_CAF_SOLICITUD_TRANSPORTISTAS` (listado) y `ERP_CAF_FN_TRANSPORTISTA_VALIDAR`. `ERP_CAF_FN_PROVEEDOR_VALIDAR` V1.1: RUC, dirección, marca, placa y licencia ya son opcionales (si se escriben: RUC 11 dígitos, placa 5–8 alfanuméricos); teléfono (≥ 6 dígitos) y empresa destino siguen obligatorios. `EDITAR_DATOS` conserva los datos guardados si llegan vacíos. `DETALLE` V1.2 devuelve la empresa destino.
- **Adjuntos:** ahora hasta 10 documentos, 20 MB en total (D-222).
- **Límites conocidos:** la regla «sin datos ⇒ adjunto obligatorio» solo la aplica la web (la base no ve los adjuntos al crear); `Contacto_Nombre` es opcional en la base pero obligatorio en la web; los datos del transportista no se pueden editar después de enviar.

## Pendientes para `PENDIENTES_VALIDACION.md` (2b-1)
- **P-156** — Un solicitante que solo tiene la licencia de proveedor (`PER_CAF_PROVEEDOR_SOLICITAR`, sin `PER_CAF_SOLICITUD_PROPIA`) puede crear pero **no ve ni edita** su propia solicitud (`ERP_CAF_FN_SOLICITUD_VISIBLE`). El listado de transportistas ya lo contempla; falta decidir si se agrega el permiso a la licencia o se amplía la función de visibilidad.
- **P-157** — 2b-2 (siguiente): Vigilancia verifica y valida el ingreso de **cada** transportista; la entrega pasa a EN_ESPERA cuando **todos** están verificados y a INGRESO cuando entra el primero; Almacén termina la atención una vez; salida de todos y la exclusa se libera al salir el último; una sola conformidad. Falta definir qué pasa si un transportista se retira o se rechaza antes de ingresar.
- **T-36** — HANA: `ERP_CAF_SOLICITUD_CREAR_PROVEEDOR` usa `STRING_TO_ARRAY`/`SPLIT_PART` para separar transportistas (CHR(30)/CHR(31)); en HANA usar `SERIES_GENERATE`/`SUBSTR_REGEXPR` o enviar una tabla de parámetros; además no hay sobrecarga (DROP de firmas previas) y el bloque BEGIN…EXCEPTION debe revisarse.

## D-224 — Quien puede solicitar proveedores gestiona sus propias solicitudes (resuelve P-156)
- Nueva función `ERP_CAF_FN_ES_SOLICITANTE(usuario, sede)` (en `SP_CAF_PROVEEDOR_ALL.sql`): 'Y' si tiene `PER_CAF_SOLICITUD_PROPIA` **o** `PER_CAF_PROVEEDOR_SOLICITAR`. Reemplaza al permiso `PROPIA` en la visibilidad y la gestión de lo propio (`MIS_LISTAR`, `DETALLE`, `PERSONAS_LISTAR`, contadores, agregar/retirar/corregir personas). No se agregan permisos nuevos a las licencias.
- El permiso de proveedor **no** abre otros tipos: `ERP_CAF_SOLICITUD_TIPOS_OPCIONES` V1.2 ofrece a cada usuario solo los tipos para los que tiene permiso (un solicitante de proveedores ve solo «Proveedor»; uno común no ve «Proveedor»).
- Web: `SolicitudesController` y las entradas «Mis solicitudes» / «Nueva solicitud» del menú aceptan cualquiera de los dos permisos.
- Distinto del permiso de solo ver el calendario de proveedores (`PER_CAF_PROVEEDOR_DASHBOARD`), que no da acceso a solicitudes.

## D-225 — Proveedor: varios transportistas y ayudantes de descarga, cada persona con su propio estado (2b-2; resuelve P-157)
- **Roles:** transportista (conduce un vehículo; tiene fila en `CAF_Solicitud_Transportista`) o **ayudante de descarga** (reemplaza «acompañante»). El rol se fija al crear; quien se agrega después es ayudante.
- **Estado por persona:** ESPERADA (verificada o no, `Fecha_Verificacion`) → DENTRO → SALIO, o NO_SE_PRESENTO / DENEGADA. El estado de la entrega se deriva: PROGRAMADO hasta verificar a **todos los transportistas por ingresar** (los ayudantes no bloquean) → EN_ESPERA → INGRESO (entra el primer transportista) → EN_ATENCION → RECEPCIONADO → SALIO (sale el último). Sin transportistas por ingresar (retirados o denegados): RETIRO_SIN_INGRESO / INGRESO_DENEGADO y se libera la exclusa.
- **Almacén:** confirma disponibilidad una vez (reserva la exclusa), atiende y da una sola conformidad; puede terminar con gente dentro: quienes no ingresaron quedan NO_SE_PRESENTO («No ingresó», con nota en el historial).
- **Vigilancia:** por persona o por selección: Verificar datos, **Registrar ingreso** (antes «Validar ingreso»), Registrar salida, Retiró sin ingresar. Una selección usa **un solo checklist** (unión de ítems); la placa y la documentación de la carga solo se exigen a transportistas; las respuestas se guardan por persona. Si alguien no cumple se verifica aparte (la desviación queda a nombre de cada persona verificada). Vigilancia no edita datos ni fuerza ingresos: un dato que no coincide es un ítem sin cumplir → desviación; Vigilancia consulta al Coordinador en el acto, registra el ingreso con desviación o lo deniega, y el Coordinador da su conformidad después. No es una incidencia.
- **Exclusa:** parámetro `EXCLUSA_CAPACIDAD` (por defecto 1) = vehículos (transportistas) dentro a la vez; los ayudantes no cuentan; ingresan con un transportista. La reserva sigue siendo de una solicitud a la vez. Un transportista o ayudante puede **salir antes de la recepción** si aún faltan transportistas por ingresar (dar paso). Cambiar la capacidad: `CALL "ERP_CAF_PARAMETRO_GUARDAR"('EXCLUSA_CAPACIDAD','2', <usuario>, NULL, NULL);` (valida `^[1-9][0-9]?$`).
- **Quitar al único transportista:** la solicitud pasa a RECHAZADA aunque queden ayudantes. Coordinador (emergencia): pide confirmar y sugiere «Corregir datos» o cancelar. Solicitante: se bloquea con ese mensaje. Si hay otro transportista, el principal pasa al siguiente (copia placa, RUC, etc. a `CAF_Solicitud`).
- **Objetos:** script `24_ALTER_PROVEEDOR_GRUPO.sql`; `SP_CAF_PROVEEDOR_GRUPO_ALL.sql` (`INGRESO_FISICO`, `RETIRO_PERSONAS`, `VERIFICAR_GRUPO`, `SALIDA_GRUPO`, todo-o-nada); `ERP_CAF_FN_ES_TRANSPORTISTA`, `ERP_CAF_PROVEEDOR_RECALCULAR`; `INGRESO_VALIDAR` y `RETIRO_SIN_INGRESO` quedan como envoltorios; lectura de Vigilancia (+`Es_Transportista`, `Verificada`) y calendario (+contadores). Web: casillas, «Marcar transportistas / ayudantes / todos», contadores «verificados v/t · dentro d», modales de grupo.
- **T-37** — HANA: los SP de grupo usan `STRING_TO_ARRAY`, `ANY(arreglo)`, `CARDINALITY`, `UNNEST` y `FOR … IN SELECT`; en HANA se reescriben con tabla temporal o `SERIES_GENERATE`/`SUBSTR_REGEXPR` y sin cursores. Pendiente al migrar.

## D-226 — Agregar persona (emergencia) en proveedor: el Coordinador elige transportista o ayudante de descarga (complementa D-169 y D-225)
- **Hueco:** la corrección de emergencia agregaba siempre a la persona como ayudante; no había forma de sumar un transportista (por ejemplo, llega otro camión o el titular).
- **Regla:** en una solicitud de **proveedor** la ventana pregunta «¿Con qué función viene?» (ayudante por defecto). Si es **transportista** se piden sus datos, todos **opcionales** (RUC, razón social, dirección, placa, marca, licencia), con las mismas validaciones de la solicitud (`ERP_CAF_FN_TRANSPORTISTA_VALIDAR`); Vigilancia los completa al verificarlo. En otros tipos de acceso no aparece la pregunta y pedir «transportista» se rechaza (400).
- **Efecto en la entrega:** el transportista nuevo aún no está verificado, así que si la entrega estaba EN_ESPERA vuelve a **PROGRAMADO** hasta que Vigilancia lo verifique (la exclusa ya reservada se mantiene). En INGRESO / EN_ATENCION no se cambia el estado. Con la entrega terminada (SALIO, RECEPCIONADO ya cerrado, sin ingreso, denegada, cierre forzado o inactiva) **no se agrega transportista** (409); un ayudante sí puede agregarse.
- **Objetos:** `ERP_CAF_SOLICITUD_PERSONA_AGREGAR_EMERGENCIA` V1.2: firma nueva (`HV_Es_Transportista` + seis datos opcionales); se hace `DROP` de la firma anterior (HANA no admite sobrecarga). Bitácora y correo indican el rol («transportista» / «ayudante de descarga»). .NET: `Dto_Transportista_Entrada?` opcional en `AgregarEmergenciaAsync`; `CorreccionAgregarVM` con `EsTransportista` y los datos. Web: `coordinacion.js`.
- **No incluye:** corregir los datos de un transportista ya existente ni cambiar el rol de alguien que ya está en la solicitud.

## D-227 — Contratista por franja de días (ingresos y salidas varios días) — Entrega 1
- **Necesidad:** el contratista no entra un solo día: se autoriza una franja (jueves, viernes y lunes siguiente; interdiario dos semanas…) y registra ingreso/salida varias veces.
- **Días:** tabla nueva `CAF_Solicitud_Dia` (script 25), una fila por día (consecutivos y/o sueltos, combinables; la web expande a lista `AAAA-MM-DD`; 1 a 92 días, sin pasados ni repetidos). Horas **aproximadas** de ingreso y de salida, opcionales e **independientes** (se puede indicar solo una), iguales para todos los días; son solo referencia y **no restringen**. Solicitud con días = «de franja».
- **Ingresos múltiples:** `ERP_CAF_PORTERIA_INGRESO/SALIDA` permiten varios movimientos; tras la salida la persona vuelve a **ESPERADA** mientras queden días de hoy en adelante (SALIO si era el último).
- **Fuera de franja** (otro día no autorizado; las horas no cuentan): Vigilancia puede ingresarlo **solo con desviación** (la ficha trae `Fuera_Franja`; la web fuerza el bloque de desviación). Listados de Vigilancia (`VIGILANCIA_LISTAR` V1.5 y `APROBADAS` V1.1) usan los días y traen `Franja_Estado` (NA/DENTRO/FUERA); con texto de búsqueda hoy aparece aunque no sea día autorizado.
- **Cierre del día:** `ERP_CAF_CONTRATISTA_CIERRE_DIA` (lo llama `ERP_CAF_PROVEEDOR_CIERRE_DIA`): quien sigue DENTRO sale a las 23:59 del día de su ingreso, solo ese día (la solicitud sigue vigente) y se avisa al Coordinador (correo tipo `PROVEEDOR_AVISO`).
- **Pantalla:** los días se agregan como **tramos** (un rango o un día suelto) en una lista vertical a la derecha; cada tramo se quita de un clic y hay «Quitar todos».
- **Filtros del rango (solo web, se cruzan):** «Frecuencia» (todos / interdiario desde lunes = lun-mié-vie / desde martes = mar-jue-sáb) × «Fines de semana» (incluidos / sin fines de semana / con sábados). Ej.: interdiario desde martes + sin fines de semana = martes y jueves. La web expande a días explícitos; la base no cambia.
- **Aprobada no se modifica:** el solicitante pide una **solicitud nueva** (botón «Ampliar plazo», precargada con `origen`); pendiente: los días no se editan (cancelar y recrear). El **Coordinador** puede **solo sumar días** (`ERP_CAF_SOLICITUD_DIAS_EXTENDER`, sustento obligatorio, sin cambiar estado; avisa a solicitante y Vigilancia).
- **Campos:** responsable de atención **opcional** para contratista; área = zonas del catálogo + detalle opcional; cochera solo en sedes que la ofrecen (Magdalena). `ERP_CAF_SOLICITUD_CREAR_CONTRATISTA` crea todo o nada. Seed provisional de checklist del contratista (script 26).
- **Fechas «ya pasó»** de los SP de corrección y del detalle usan el **último día** de la franja (`ERP_CAF_FN_FRANJA_FIN`).
- **Filtro visual por tipo** (Visitante/Proveedor/Contratista) ya existía en Mis solicitudes, Vigilancia y Coordinación; verificado que lista Contratista en 1280 y 390 px.
- **T-38** — HANA: los SP de franja usan `STRING_TO_ARRAY`, `UNNEST`, `STRING_AGG`, `::DATE` e `INTERVAL`; reescribir con `SERIES_GENERATE`/`SUBSTR_REGEXPR`/`ADD_SECONDS`.

## D-228 — Datos de prueba por escenarios (solo piloto PostgreSQL)
`DATOS_DEMO_ESCENARIOS.sql` / `LIMPIAR_DEMO_ESCENARIOS.sql` (HITO_02/00_BD, no corren con `restaurar_bd.ps1`). Marca de los datos: DNI `7400NNNN` + incidencias `[DEMO-ESC]`; la limpieza guarda primero los ids de solicitud (el borrado en cascada elimina antes las personas). Crea `coordinador2.demo`, `almacen1/2.demo` si faltan. Incompatible con `DATOS_DEMO_PROVEEDOR.sql` (una sola exclusa). Los escenarios «no se presentó» y «cierre forzado» se simulan retrasando fechas en tabla y llamando a los SP de cierre. Sintaxis PostgreSQL (T-39: no portable a HANA; si se necesitara en HANA habría que reescribirlo).

## D-235 — «Verificación en grupo» en Control de accesos (modal por pasos)
- **Pantalla:** cada solicitud con 2 o más personas muestra un único botón «Verificación en grupo», a la derecha de «Documentos». Desaparecen la barra «Marcar:» y las casillas de cada fila; los botones individuales de cada persona siguen igual. Los contadores (chips) de proveedor se mantienen. Una solicitud de 1 persona no muestra el botón. Solo en «Hoy» (no en «Aprobadas»).
- **Modal por pasos:** 1) elegir la acción con cuántas personas pueden hacerla; 2) elegir a quiénes (casillas, «Todos», «Ninguno» y, en proveedor, «Transportistas» y «Ayudantes»; quienes no pueden aparecen deshabilitados); 3) el checklist o la confirmación de siempre. Proveedor: Verificar datos, Registrar ingreso, Retiró sin ingresar, Registrar salida. Resto de tipos (visitante, contratista y futuros): Validar ingreso (checklist y registro en un paso; quien trae equipos o herramientas se valida de forma individual) y Registrar salida.
- **Acceso directo del calendario de proveedores:** con 2 o más personas abre este modal directo en el paso 2: «Registrar salida» con todos los que están dentro marcados si la entrega ya fue recepcionada o cerrada; si no, la acción que toque (verificar, ingresar o salir).
- **Botón bloqueado sin acciones:** si ninguna persona de la solicitud puede avanzar (p. ej. todos «En atención de Almacén»), «Verificación en grupo» queda deshabilitado con una explicación al pasar el mouse, en lugar de abrir un modal vacío.
- **Cierre forzado aparte:** en Control de accesos, quien sigue dentro por cierre forzado del día (`estadoOp = CIERRE_FORZADO`) sale en su propio grupo «Cierre forzado» y ya no cuenta en «Dentro» (solo en pantalla; el `Grupo` del SP no cambia).
- Se incorpora al repositorio `27_ALTER_CHECKLIST_AYUDANTE.sql` (D-231), que faltaba.
- **BD/.NET:** sin cambios. `ERP_CAF_PROVEEDOR_VERIFICAR_GRUPO` y `ERP_CAF_PROVEEDOR_SALIDA_GRUPO` no limitan por tipo; se agregó una prueba que las usa con 2 contratistas (ingreso y salida a la vez).
- Limitación: el checklist del paso 3 se arma con la persona representante de cada rol (transportista/ayudante en proveedor); en otros tipos con roles de checklist distintos, quien no cumpla un ítem propio de su rol recibirá un 400 del SP («Responda todos los ítems»). El rol (subtipo) aún no viaja en la lista de Vigilancia.

## D-234 — Subtipos (roles) por persona y checklist por subtipo
- **Regla:** si un tipo de ingreso NO tiene subtipos, su checklist se define a nivel de tipo; si los tiene, se define POR SUBTIPO («Todos» = todos los subtipos activos). Cada persona de la solicitud lleva UN subtipo (rol), elegido con la lista «Rol de la persona» (solo aparece si el tipo tiene subtipos). Un subtipo es el predeterminado; los subtipos solo se desactivan (nunca se borran) y el desactivado conserva su checklist.
- **BD (script 29):** `Tipo_Acceso_Subtipo.Es_Predeterminado` (índice único parcial por tipo); `CAF_Solicitud_Persona.ID_Tipo_Acceso_Subtipo` (+FK, relleno de lo existente); triggers: la persona nueva nace con el predeterminado y figurar en `CAF_Solicitud_Transportista` la pasa a TRANSPORTISTA (si deja de figurar vuelve al predeterminado); la unicidad del checklist pasa a (tipo, ítem, subtipo); los ítems «para todo el tipo» de un tipo con subtipos se migran a una fila por subtipo activo.
- **SP:** `SP_CAF_SUBTIPO_ALL.sql` (LISTAR, CREAR, ACTUALIZAR, ESTADO, PREDETERMINADO, `ERP_CAF_SOLICITUD_PERSONA_SUBTIPO_ASIGNAR`); `ERP_CAF_FN_SUBTIPO_PERSONA` V1.1 (subtipo guardado, si no el predeterminado); `ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS` V1.2 (acepta `tipo:subtipo`; un tipo suelto con subtipos = todos los activos); `ERP_CAF_SOLICITUD_PERSONAS_LISTAR` V1.1 (+`ID_Tipo_Acceso_Subtipo`, `Subtipo`). El `ERP_CAF_SUBTIPO_LISTAR` antiguo de TIPO_ACCESO_ADMIN pasa a SP_CAF_SUBTIPO_ALL.
- **Reglas:** el primer subtipo de un tipo hereda el checklist y las personas existentes; uno nuevo puede copiar el checklist de otro; el subtipo del sistema TRANSPORTISTA no se puede desactivar ni asignar a quien no tenga datos de transportista; los subtipos creados por el administrador son neutros. Asignar el rol se hace después de crear la solicitud (si falla, queda el predeterminado y se avisa).
- **Web:** Catálogos → Tipos de ingreso → botón «Subtipos» (alta, edición, predeterminado, activar/desactivar, copiar checklist); Checklist de portería con casillas por subtipo; «Rol de la persona» en Nueva solicitud, en agregar persona (solicitante) y en agregar por emergencia (Coordinador); el rol se muestra en el detalle y en Coordinación.
- **T-41** — HANA: sin `ADD COLUMN IF NOT EXISTS`, sin índices sobre expresión (`COALESCE`; usar columna calculada), triggers a reescribir en SQLScript.
- Pendiente: etiqueta de rol en Vigilancia; verificar P-163 (salida por tipo de persona).

## D-233 — Etiqueta de tipo de ingreso en todo el ciclo y «Personas que ingresan» en los listados
- **Etiqueta de tipo** (`SOL.chipTipo`, CSS `.chip.tp.tp-<código>`): Visitante externo = verde azulado, Contratista = violeta, Proveedor = naranja; cualquier otro tipo (p. ej. uno creado desde Administración) usa el gris neutro. Con variante para tema oscuro. Se muestra en Mis solicitudes, Detalle, vista de revisión de Nueva solicitud, bandeja y modal Revisar del Coordinador, y en cada bloque de Control de accesos (Vigilancia).
- **Sigla de la empresa que recibe** (proveedor; `SOL.chipEmpresa`): TE, PT, TA, TS con los mismos colores del calendario de proveedores. Acepta un código o una lista de códigos, para cuando una solicitud se vincule a varias empresas (Entrega 2, aún por definir); hoy cada solicitud trae una.
- **Listados:** la columna «Responsable de atención» (Mis solicitudes) pasa a «Personas que ingresan», con apellidos, nombres y documento (primeras 3 y «+N más»; el texto completo en el tooltip). La bandeja del Coordinador lo muestra igual y su buscador «Persona o DNI» sigue igual. El responsable queda solo en el detalle.
- **BD:** `ERP_CAF_FN_PERSONAS_RESUMEN(solicitud)` (nueva); `MIS_LISTAR` V1.1 (+`Tipo_Acceso_Codigo`, `Empresa_Destino_Codigo`, `Personas_Resumen`), `BANDEJA_LISTAR` V1.1 (+ los dos códigos; `Personas_Nombres` ahora incluye el documento), `VIGILANCIA_LISTAR` V1.6, `VIGILANCIA_APROBADAS` V1.2 y `DETALLE` (+`Empresa_Destino_Codigo`). `MIS_LISTAR` y `BANDEJA_LISTAR` cambian columnas: el script ya trae `DROP FUNCTION IF EXISTS`.
- **T-40** — HANA: `ERP_CAF_FN_PERSONAS_RESUMEN` usa `STRING_AGG(... ORDER BY ...)` (HANA: `STRING_AGG` admite `ORDER BY` dentro; revisar el tope de `NVARCHAR`) y `LEFT(...,2000)`; las funciones de tabla que cambian columnas se recrean con `DROP FUNCTION` previo.
- No incluye aún las etiquetas en Reporte de accesos ni en Incidencias.

## D-232 — Tipos de ingreso y subtipos administrables
Pantalla «Tipos de ingreso» (Catálogos): alta/edición/disponibilidad de `Catalogo_Tipo_Acceso`; un tipo nuevo es del flujo estándar de visitante y se «prepara» copiando pasos de aprobación y checklist de VISITA_EXTERNA (`ERP_CAF_TIPO_ACCESO_PREPARAR`, idempotente). Los tipos con flujo propio en código (VISITA_EXTERNA, CONTRATISTA, PROVEEDOR, INTERNO_VISITANTE) no cambian su «requiere aprobación». Subtipos: tabla `Tipo_Acceso_Subtipo` (script 28) definida por el desarrollo; la persona se asigna a su subtipo en un solo lugar (`ERP_CAF_FN_SUBTIPO_PERSONA`, hoy solo Proveedor). El ítem de checklist se asigna a tipo + subtipo opcional en `Tipo_Acceso_Item_Checklist.ID_Tipo_Acceso_Subtipo` (NULL = todos); `ERP_CAF_PORTERIA_ITEMS_APLICABLES` V1.2 lo aplica. Las condiciones SOLO_PRINCIPAL / SOLO_AYUDANTE siguen aceptadas por compatibilidad pero ya no se ofrecen; el script 28 migra los ítems del Proveedor a «Siempre» + subtipo. Límite conocido: un ítem tiene un solo subtipo por tipo (para «ambos» se deja «a todas las personas»). Para HANA: sin `IF NOT EXISTS` en el script 28; T-39 sigue vigente.

## D-231 — Checklist de salida para ayudantes (condición SOLO_AYUDANTE)
Condición nueva `SOLO_AYUDANTE` en `Catalogo_Item_Checklist` (script 27 amplía el CHECK): aplica a la persona de una entrega con transportistas que no es transportista (`ERP_CAF_FN_ES_TRANSPORTISTA` = 'N' y existen transportistas en la solicitud, para no alcanzar a visitantes ni contratistas). Ítem sembrado `SAL_AYUDANTE_VERIFICADO` (salida, no crítico, Proveedor), editable desde la pantalla. La selección de ítems sigue siendo por la tabla de asignación a tipos de ingreso: un tipo nuevo no requiere código salvo condiciones propias de su flujo.

## D-230 — Pantalla «Checklist de portería» (Administración)
Sección nueva en Catálogos con el permiso `PER_CAF_ADMIN_CATALOGOS`: ítems de `Catalogo_Item_Checklist` (crear, editar, activar/desactivar; sin borrado) y asignación a `Tipo_Acceso_Item_Checklist` en un solo paso atómico (`ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS`: reemplaza la lista; lo quitado queda con borrado lógico y se reactiva si vuelve). Etapa de un ítem ya usado en `CAF_Registro_Checklist` no se cambia (409). El ítem nuevo toma código `ING_/SAL_` + texto. Las condiciones válidas del CHECK incluyen `SOLO_PRINCIPAL` (antes los SP de catálogo no la aceptaban aunque la tabla sí).
- **T-39** — HANA: `ERP_CAF_ITEM_CHECKLIST_ASIGNAR_TIPOS` usa `POSITION(... IN ...)` (HANA: `LOCATE`) y el operador regex `!~` (HANA: `LIKE_REGEXPR`/`NOT LIKE_REGEXPR`) y concatenación `||`; revisar al portar.

## D-229 — Correo por tipo de ingreso
En el proveedor el «responsable» es el contacto de la empresa proveedora (`Contacto_Nombre/Telefonos`), no el `ID_Personal_Responsable` interno; el correo ahora lo muestra como «Responsable de la entrega». `ERP_CAF_CORREO_SOLICITUD_DATOS` V1.3 suma `Empresa_Destino`, `Dias_Texto`, `Hora_Desde`, `Hora_Hasta`; `ERP_CAF_CORREO_SOLICITUD_PERSONAS` V1.1 suma `Rol`. La agrupación de días en tramos se hace en .NET (`PlantillaCorreo.DiasTexto`). HANA: `TO_CHAR(...,'HH24:MI')` y `STRING_AGG` ya cubiertos por T-38.

