# Entrega del 2026-10-28 · D · Celular (P-96) y rol activo (P-97)

Solo archivos nuevos o modificados, con la estructura del repositorio: cópialos encima. **No hay cambios de base de datos**: no hace falta reconstruir; `restaurar_bd.ps1` va igual que siempre. Si todavía no aplicaste la entrega C, aplícala primero (sus documentos se acumulan en estos).

## Qué trae
- **Rol activo.** Si tu usuario tiene varios grupos (Solicitante, Coordinador, Vigilancia, Administración), en la barra superior, bajo tu correo, aparece un selector **«Todos mis roles / …»**. Al elegir uno, el menú muestra solo ese grupo. **No cambia permisos**: la seguridad sigue igual, y entras con el último rol que usaste (se recuerda en una cookie del navegador).
- **Celular (360 a 414 px), todas las pantallas:**
  - Las tablas se ven como **tarjetas** (cada dato con su etiqueta).
  - Las ventanas ocupan **toda la pantalla**, con título y botones siempre visibles.
  - Botones, pestañas, selectores y menú de **44 px**; letra de 16 px en los campos.
  - Filtros en dos columnas; barra superior apilada; se corrige el desborde de «Usuarios y roles».
  - En escritorio no cambia nada.
- Archivos: `Menu/MenuCaf.cs`, `CuentaController.cs`, `Views/Shared/_Layout.cshtml`, `wwwroot/js/layout.js`, `wwwroot/css/site.css`, documentos (D-176, D-177, P-107).

## Archivos a borrar
Ninguno.

## Pasos
1. Copia los archivos y haz Rebuild All (cambió una vista y el controlador). Arranca la web y recarga con Ctrl+F5.

## Qué probar
1. **Rol:** con un usuario con varios grupos (el administrador de pruebas los tiene todos), elige «Vigilancia»: el menú queda solo con Vigilancia. Sal y vuelve a entrar: sigue en Vigilancia. Elige «Todos mis roles»: vuelve todo.
2. Un usuario con un solo grupo **no** ve el selector.
3. **Celular:** abre la web en tu teléfono (o en el navegador con F12 → modo móvil, 390 px) y recorre Mis solicitudes, Nueva solicitud, Coordinación (abre una solicitud con «Ver»: la ventana ocupa toda la pantalla), Control de accesos, Incidencias, Desviaciones, Reporte, y las de Administración. Revisa que no haya que mover la pantalla de lado y que los botones se toquen bien.

## Qué se probó y qué no
- **Probado (Playwright, navegador simulado con servicios falsos):** las 11 pantallas a **360, 390 y 414 px**: sin desborde horizontal y sin controles de menos de 40 px de alto; tablas como tarjetas; ventana de Coordinación a pantalla completa (390×800); selector de rol (5 opciones, filtra el menú, conserva «Incidencias» en Vigilancia, recuerda el rol tras salir y entrar, ignora una cookie inválida, rechaza el envío sin token con 400); escritorio a 1280 px sin cambios; sin errores de consola ni de política de seguridad. La solución compila con 0 errores.
- **No probado:** teléfonos reales (Android/iPhone, teclado en pantalla, gestos); la web con base de datos real (usé servicios falsos); SQL no cambió, por eso no repetí las pruebas de base.

## Para confirmar (P-107)
Si el selector de rol va en la barra superior (como ahora) o en una página de perfil; y revisar en teléfonos reales.

## Siguiente
**Entrega E**: hilo de correo y «responder a todos», Reply-To al Coordinador y prueba con Gmail (P-95).
