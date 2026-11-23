# Entrega consolidada D-259 a D-263 (incluye la 2b-2: liberación temprana de plazas)

Este ZIP reemplaza a todas las entregas anteriores desde la Entrega 1: contiene **todos** los archivos nuevos o modificados desde el último commit de su repositorio. Se sube **una sola vez** con `COMMIT_MESSAGE.txt`.

## Qué trae
- **D-259** incidencias después de la salida (regla) y «Cerrar sin atención» con licencia propia.
- **D-260** coordinación de ingreso vehicular entre almaceneros (Confirmar / Rechazar, Coordinador de Almacén).
- **D-261** plazas por entrega, tope por entrega y liberación automática al salir.
- **D-262** datos demo ajustados y limpiador que libera todas las plazas.
- **D-263 (nuevo, 2b-2)** liberación temprana de plazas por Almacén, solo en entregas de más de 1 vehículo:
  - Botón **«Liberar plaza vehicular»** en la tarjeta de la entrega (libera una plaza cada vez; la última se libera al terminar).
  - Casilla opcional **«Liberar plaza vehicular»** en «Terminar atención»; con 2 o más vehículos dentro muestra sus placas (solo informativa).
  - Al terminar toda la atención se liberan **todas** las plazas de golpe.
  - Vigilancia sigue registrando la salida real; el tope físico de la esclusa protege a las demás entregas.
  - Con 1 vehículo todo sigue igual que hoy.

## Cómo aplicarla (en este orden)
1. Descomprima el ZIP sobre la raíz del repositorio (respeta la estructura de carpetas).
2. Base de datos:
   - Si su base ya tiene aplicados los scripts 40 y 41 (Entrega 2), **solo recargue las rutinas**: `.\restaurar_bd.ps1 -Database <su_base> -SoloRutinas`.
   - Si parte de una base vacía: `.\restaurar_bd.ps1 -Database <su_base> -Crear` (aplica 40, 41 y todas las rutinas; no hace falta editar nada, el script descubre los archivos solo).
   - **No hay scripts ALTER nuevos en la 2b-2.** Los cambios son rutinas: `SP_CAF_PROVEEDOR_ALL`, `SP_CAF_PROVEEDOR_GRUPO_ALL`, `SP_CAF_PROVEEDOR_DASHBOARD_ALL`, `SP_CAF_PROVEEDOR_INGRESO_VEHICULAR_ALL` (nuevo en D-260, V1.3 aquí) y `SP_CAF_SOLICITUD_ATENCION_ALL`.
3. Compile y publique la aplicación (hay cambios en Application, Infrastructure y Web).
4. Asigne la licencia **«Coordinador de Almacén»** (`LIC_CAF_COORD_ALMACEN`) a quien corresponda (P-169). Sin ella nadie puede liberar plazas de una entrega que no atiende.
5. Si usa datos demo: ejecute primero el limpiador del demo que tenga cargado y luego el nuevo. **No cargue el integral y el de escenarios a la vez** (el cupo del almacenero queda ocupado y el segundo se detiene con 409).

## Qué probé
- PostgreSQL local, base reconstruida desde cero: **Hito 2 escritura 997/997** (7 pruebas nuevas de D-263; dos de D-261 ajustadas porque ahora la reserva se libera al recepcionar), **las 12 suites en verde** (Permisos 45/45).
- Demos: integral, escenarios y multiempresa cargan y limpian sin error.
- `node --check` de `proveedores.js` y `manual.js`; `tecnica.js` regenerado (294 SP).

## Qué NO probé (dígalo si lo ve)
- **Compilación de C#**: no hay `dotnet` en mi entorno. Revisé a ojo los cambios (DTO, repo, servicio, controlador, VM).
- **La pantalla en navegador**: botón, modal y casilla con placas están escritos y revisados, pero no los vi funcionando.
- ESLint, SAP HANA real y envío real de correo.

## Para validar con Sandra
P-171 (alcance de la liberación temprana, quién puede liberar, qué pasa con el camión que sigue) y las pendientes P-169 y P-170.
