# Entrega A del 2026-10-26 · Puntos de mejora 6, 7, 8, 9 y 10

## Qué trae
- **«Salió»** en el Reporte de accesos (pantalla, CSV e impresión). Punto 6.
- **Asistente, paso Personas:** si cambias un DNI autocompletado por otro, los nombres y apellidos se **limpian solos**. Punto 8.
- **Autocompletar empresa** (con las ya escritas en otras solicitudes) y **autocompletar persona** escribiendo 3 letras del apellido (se llenan documento y nombres). También en la ventana de Coordinación para agregar personas. Punto 7.
- **Se quitó el botón «Contraseña»** de la barra superior; queda «¿Olvidó su contraseña?». Puntos 3 y 9.
- **Correos en copia (punto 10):** el campo sí se envía. Mientras tengas `Correo__RedirigirA` con valor, todo sale a esa dirección y la copia no se entrega (el aviso del correo dice a quién habría llegado). Para ver llegar la copia, **deja vacío `Correo__RedirigirA`** y usa usuarios con buzones reales.
- Decisiones D-160 a D-164; P-100 a P-104 pasan a «Resueltos».

## Pasos
1. Copia los archivos sobre el repositorio y recompila.
2. **Base de datos:** hay una función nueva (`ERP_CAF_SOLICITUD_EMPRESAS_BUSCAR`). Reconstruye en una base vacía con `.\restaurar_bd.ps1 -Database <nueva> -Crear` y apunta `CAF_DB_BASE` a ella (o ejecuta solo `SP_CAF_SOLICITUD_LECTURA_ALL.sql` sobre tu base actual).
3. Pruebas SQL: `PRUEBAS_FASE1_HITO2_ESCRITURA.sql` (194 de 194 OK).

## Qué revisar
1. En «Nueva solicitud», escribe 2 letras de una empresa ya usada: deben salir sugerencias.
2. En Personas, escribe un DNI registrado (se llena), cámbialo por otro: se vacían los nombres.
3. Escribe 3 letras de un apellido registrado: elige uno y se llena todo.

## Siguiente
Entrega B: Incidencias fusionadas (la del coordinador queda aprobada).
