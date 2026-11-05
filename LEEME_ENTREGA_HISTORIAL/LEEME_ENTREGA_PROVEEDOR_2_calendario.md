# Entrega: Proveedor de abastecimiento, Entrega 2 — Calendario de entregas de Almacén

ZIP acumulado desde la Entrega C: contiene todos los archivos nuevos o modificados, completos y con la estructura del repositorio.

## Qué trae
- **Calendario de entregas** (menú «Proveedores → Entregas de proveedores»): vista semana y mes, tarjetas con empresa, hora, proveedor, entrega, responsable programado y estado. Solo aparecen entregas aprobadas.
- **Solo lectura** para quien tenga `LIC_CAF_PROVEEDOR_DASHBOARD` (Abastecimiento, Coordinador, Vigilancia); botón **Actualizar** para todos y consulta automática cada 60 s (sin tiempo real).
- **Almacén** (`LIC_CAF_ALMACEN`) además puede: asignar responsable (opcional, informativo), **Atender** y **Terminar atención** con ventanas de confirmación.
- **Una sola atención a la vez por sede** (esclusa), validada en la base de datos. Si dos pulsan Atender a la vez, solo uno gana.
- Se conserva el responsable programado y el efectivo (quien pulsó Atender) en el historial.

## Cómo aplicarlo
**Base existente:** ejecutar una sola vez `18_ALTER_PROVEEDOR_DASHBOARD.sql`, luego re-ejecutar `SP_CAF_PROVEEDOR_ALL.sql` y `SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql` (carpeta `HITO_02.../00_BD`). **Base nueva:** `restaurar_bd.ps1` (ya descubre ambos).
Después compilar la web y publicar. Asignar a los usuarios la licencia nueva desde el administrador.

**Para ver algo ya mismo (opcional, solo pruebas):** `DATOS_DEMO_PROVEEDOR.sql` crea `almacen1.demo@trianon.test` y `almacen2.demo@trianon.test` (clave de demostración `Alma.Demo#2026`, cámbiela) y 5 entregas de ejemplo. No lo ejecute en producción.

## Qué probé
- Reconstrucción limpia de la BD (scripts 01–18 + SPs) y suites: HITO1 143, HITO2 escritura 484, lectura 202, HITO3 140/100, HITO4 138/113, PERMISOS 43, HITO0 65: todas OK.
- Concurrencia real con dos sesiones: la segunda esperó y recibió 409; solo una quedó EN_ATENCION.
- Compila sin errores (host de prueba con servicios simulados).
- Navegador (escritorio y móvil 390 px): sin permiso → acceso denegado; solo lectura sin botones; Almacén asigna/atiende/termina; bloqueo de las demás mientras hay una en curso; actualizar; mes → semana.

## Qué NO probé
- Los parámetros reales de Npgsql desde C# contra los SP (la web se probó con servicios simulados).
- SAP HANA, SMTP, IIS ni tiempo real.
- Inicio de sesión web con los usuarios demo.
- Observación: el test #96 de HITO2 lectura (preexistente, orden de `STRING_AGG`) falló una vez bajo carga y pasó en dos reprocesos; no depende de este cambio.

## Pendiente (aún NO existe)
- Asistente «Nueva solicitud» del proveedor y aprobación del Coordinador (Entrega 2b).
- Pantallas de Vigilancia para proveedor: llegada, ingreso y salida (Entrega 3), y el cierre automático «no se presentó».
- Tiempo real (Entrega 4, depende de P-125) y checklist en el administrador (Entrega 5).

## Por validar
P-128 a P-133 en `PENDIENTES_VALIDACION.md` (alcance del calendario, responsables elegibles, atender desde el día programado, observación opcional, principal aprobado, cierre automático). Nota: `ATENDER` cambió de firma (ya no recibe la persona de Almacén).
