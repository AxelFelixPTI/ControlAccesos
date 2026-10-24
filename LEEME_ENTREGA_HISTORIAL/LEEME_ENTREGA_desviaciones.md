# Entrega del 2026-10-23 · Desviaciones (coordinador)

Solo archivos nuevos o modificados, con la estructura del repositorio. No hay cambios de base de datos ni de proyectos.

## Qué trae
- **Desviaciones** (menú Coordinador): lista **Por revisar / Revisadas** con búsqueda por persona, DNI o código. **Revisar** abre el detalle (persona, solicitud, quién registró, descripción, a quién se consultó, decisión y efecto) con el checklist del movimiento, y permite **Dar conformidad** con un comentario opcional. Las revisadas se ven en solo lectura.
- Archivos: `DesviacionesController`, `DesviacionModelos`, vista `Desviaciones/Index`, `desviaciones.js`, menú (se enciende «Desviaciones»), documentos (D-136 a D-138, P-78 a P-80, T-20).

## Pasos
1. Copia los archivos, Rebuild All, arranca la web y recarga con Ctrl+F5.
2. Entra como `coordinador.demo@trianon.test` (contraseña `Coord.Demo#2026`).

## Qué probar
1. Como `vigilante1.demo@trianon.test` (`Vigi.Demo#2026`): valida un ingreso dejando un ítem sin marcar y completa la desviación (coordinador y tratamiento).
2. Como coordinador: Desviaciones → aparece en **Por revisar** → Revisar → revisa el checklist → Dar conformidad (con o sin comentario).
3. Pasa a **Revisadas**: aparece con quién dio la conformidad. Prueba la búsqueda por nombre, DNI o código.

## Siguiente
Incidencias (coordinador y del día de Vigilancia) y reporte de accesos.
