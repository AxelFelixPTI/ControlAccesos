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
