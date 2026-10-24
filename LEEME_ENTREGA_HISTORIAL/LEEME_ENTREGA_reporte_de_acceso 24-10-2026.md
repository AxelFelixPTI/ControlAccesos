# Entrega del 2026-10-24 · Reporte de accesos

Solo archivos nuevos o modificados, con la estructura del repositorio. No hay cambios de base de datos ni de proyectos. **Aplícala después del zip de Incidencias** (comparten `MenuCaf.cs` y los documentos; este trae la versión final de ambos).

## Qué trae
- **Reporte de accesos** (menú Coordinador): tabla de movimientos de portería con filtros (fechas, persona/DNI/empresa, ingresos o salidas, solo con desviación), resumen del rango arriba, **Exportar a Excel (CSV)** e **Imprimir**.
- **Control de accesos (Vigilancia):** botón **Registrar incidencia** en las personas que están Dentro o ya Salieron; abre el formulario con la persona elegida.
- Archivos: `ReportesController`, vista `Reportes/Index`, `reportes.js`, `VigilanciaController`, `Vigilancia/Index.cshtml`, `vigilancia.js`, `MenuCaf.cs`, documentos (D-143 a D-146, P-84 a P-86, T-22).

## Pasos
1. Copia los archivos, Rebuild All, arranca la web y recarga con Ctrl+F5.
2. Coordinador: `coordinador.demo@trianon.test` / `Coord.Demo#2026`. Vigilante: `vigilante1.demo@trianon.test` / `Vigi.Demo#2026`.

## Qué probar
1. Como vigilante, registra un ingreso y una salida; en la persona que quedó Dentro pulsa **Registrar incidencia** (la persona ya viene elegida).
2. Como coordinador: **Reporte de accesos** → aparecen los movimientos de hoy. Prueba los filtros y «Solo con desviación».
3. Pulsa **Exportar a Excel (CSV)** y ábrelo en Excel; pulsa **Imprimir** para ver la vista de impresión.

## Siguiente
Marcado «No se presentó», pantalla de autorizados por zona y revisión de pendientes.
