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

