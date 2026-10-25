# Corrección del 2026-10-24 · Exportar el Reporte de accesos

Solo archivos modificados. No hay cambios de base de datos. Aplícala después del zip de Reporte de accesos.

## Qué cambia
- **Exportar a Excel (CSV)** ya no lleva la pestaña hacia el archivo: lo pide en segundo plano y lo entrega como descarga. La aplicación ya no debe detenerse, y si hay un error (por ejemplo, más de 92 días) se muestra un aviso.
- Documentos: D-147; P-85 reescrito (el PDF queda pendiente y debe respetar los mismos filtros que el CSV) y P-72 aclarado («No se presentó» es automático; falta programarlo).

## Pasos
1. Copia los archivos, Rebuild All y recarga con Ctrl+F5.

## Qué probar
1. Coordinador → Reporte de accesos → elige «Salidas» y pulsa **Exportar a Excel (CSV)**: baja el archivo con solo salidas y la página sigue igual.
2. Repite con «Solo con desviación» y con una búsqueda por nombre.
3. Pon un «Desde» de hace más de 92 días y exporta: debe salir un aviso, sin cambiar de página.
4. Si la aplicación se detiene otra vez, copia el mensaje de la ventana Salida/Output (busca «Unhandled exception») y envíamelo.
