# Entrega D-276 · Despacho (salida de productos) — SOLO base de datos (primera parte)

Aplicar con `restaurar_bd.ps1` (toma `46_ALTER_DESPACHO.sql` y los SP por número/nombre). Todavía NO hay pantalla: falta la capa .NET y web.

## Probado
- Reconstrucción completa de la BD y todas las suites SQL (nueva: `PRUEBAS_FASE1_HITO2_DESPACHO.sql`, 92/92; escritura 1037/1037). En una corrida, `HITO2_LECTURA` falló 1 vez («Vigilancia: el estado y el grupo», orden no determinista); en 3 repeticiones pasó 217/217.
## No probado
- C# (no compilado), navegador, correo, HANA.
## Pendiente
Ver D-276 y P-179 a P-181.

## Añadido: «Horario de ingreso programado» con los días reales
- La columna «Visita» pasa a llamarse **Horario de ingreso programado** (Mis solicitudes y bandeja de Coordinación).
- Un día: como antes. Varios días consecutivos: «26/11/2026 – 27/11/2026». Con huecos: «23/11/2026 … 27/11/2026». Al pasar el mouse sale «3 días de trabajo: 23/11/2026, 25/11/2026, 27/11/2026».
- Si la solicitud tiene varios días, debajo aparece la nota «Revisar detalle» que abre el detalle (en la bandeja, el modal; en Mis solicitudes, la página de detalle).
- BD (solo lectura, sin tablas ni datos nuevos): `ERP_CAF_SOLICITUD_MIS_LISTAR` y `ERP_CAF_SOLICITUD_BANDEJA_LISTAR` devuelven `Dias_Fechas` (con DROP previo). Código: DTOs Lista/Bandeja, `Repo_Solicitud`, 2 controladores, `comun.js` (`SOL.celdaHorario`), `coordinacion.js`, `mis.js`, `site.css`, 2 vistas.
- Probado: lógica del rango en Node (consecutivo, con huecos, un día), reconstrucción de la BD y las 12 suites (la consulta corre, aunque sin solicitudes de varios días en los datos de prueba). NO probado: compilación C#, pantalla en navegador, la agregación de fechas con una solicitud real de varios días.
