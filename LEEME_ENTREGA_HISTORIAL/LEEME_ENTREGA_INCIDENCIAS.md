# Entrega del 2026-10-24 · Incidencias

Solo archivos nuevos o modificados, con la estructura del repositorio. No hay cambios de base de datos ni de proyectos.

## Qué trae
- **Incidencias** (menú Coordinador): pestañas **Por decidir / Todas**, búsqueda y filtros (estado, origen, fechas). **Decidir** abre el detalle y permite **Confirmar** o **Desestimar** con sustento obligatorio.
- **Incidencias del día** (menú Vigilancia): las de hoy y el botón **Registrar incidencia** (personas que ingresaron hoy, tipo, hora, lugar, descripción).
- Archivos: `IncidenciasController`, `IncidenciaModelos`, vistas `Incidencias/Index` y `Dia`, `incidencias.js`, `_Layout.cshtml` (resalte del menú), `MenuCaf.cs` (se encienden las dos entradas), documentos (D-139 a D-142, P-81 a P-83, T-21).

## Pasos
1. Copia los archivos, Rebuild All, arranca la web y recarga con Ctrl+F5.
2. Vigilancia: `vigilante1.demo@trianon.test` / `Vigi.Demo#2026`. Coordinador: `coordinador.demo@trianon.test` / `Coord.Demo#2026`.

## Qué probar
1. Como vigilante: valida un ingreso en Control de accesos, luego Incidencias del día → Registrar incidencia → elige a esa persona, tipo, lugar y descripción.
2. Como coordinador: Incidencias → Por decidir → Decidir → intenta sin sustento (debe pedirlo) → Confirmar.
3. Revisa la pestaña Todas y los filtros. Una incidencia registrada por el coordinador queda confirmada directamente.

## Siguiente
Reporte de accesos y marcado «No se presentó».
