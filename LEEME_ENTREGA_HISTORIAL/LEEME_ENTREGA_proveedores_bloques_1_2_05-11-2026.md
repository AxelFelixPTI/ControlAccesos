# Entrega: Proveedores — bloques 1 y 2 (calendario + Vigilancia) y exclusa hasta la salida

ZIP acumulado desde la Entrega C. El LEEME anterior está en `LEEME_ENTREGA_HISTORIAL/`.

## Qué trae
**Bloque 1 (web):** leyenda arriba y plegable; distintivo «EXCLUSA RESERVADA» (borde grueso + cinta) y «POR SALIR» (borde fino); vista Día; `LIMPIAR_DEMO_PROVEEDOR.sql` (opcional).
**Bloque 2 (BD + web):** en «Control de accesos» los proveedores muestran su estado y sus botones: **Verificar datos** (PROGRAMADO) → **Validar ingreso** (EN_ESPERA, solo con Almacén listo) y **Retiró sin ingresar** (motivo obligatorio, libera la exclusa) → **Registrar salida** (solo tras la recepción de Almacén). Nuevo estado «Retiró sin ingresar» en el calendario y la leyenda.

**Cambio de regla (D-214, opción B):** la exclusa ya no se libera al terminar la atención sino cuando Vigilancia registra la **salida** del camión (sale por la misma exclusa). Mientras tanto Almacén no puede confirmar a otro proveedor. El calendario mantiene el borde grueso hasta Salió, con la cinta «POR SALIR · EXCLUSA OCUPADA» tras la recepción.

## Cómo aplicarlo (base existente, en este orden)
1. `20_ALTER_PROVEEDOR_RETIRO.sql` (una sola vez; carpeta `HITO_02.../00_BD`).
2. Re-ejecutar `SP_CAF_SOLICITUD_LECTURA_ALL.sql`, `SP_CAF_SOLICITUD_VIGILANCIA_APROBADAS.sql`, `SP_CAF_PROVEEDOR_ALL.sql` y `SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql`. Si ya tienes la demo cargada: `LIMPIAR_DEMO_PROVEEDOR.sql` y luego `DATOS_DEMO_PROVEEDOR.sql` (la demo cambió: la entrega 6 recepcionada tiene la exclusa; regístrale la salida en Control de accesos para liberarla).
3. Compilar y publicar la web. Base nueva: `restaurar_bd.ps1` (incluido). El usuario de Vigilancia necesita `PER_CAF_PROVEEDOR_VIGILANCIA` para ver Validar ingreso y Retiró sin ingresar (ya lo trae `LIC_CAF_VIGILANCIA_PROVEEDOR`).

## Qué probé
- BD reconstruida desde cero (scripts 01–20 + SPs). Suites: HITO2 escritura **557/557** (retiro, listado de Vigilancia y exclusa hasta la salida), HITO1 143, HITO2 lectura 202, HITO3 140/100, HITO4 138/113, PERMISOS 43: todas OK.
- Compila (host de prueba con servicios simulados).
- Navegador, 1280 y 390 px: calendario 48 pruebas; Vigilancia de proveedores 15 pruebas (botones por estado, permisos, Validar ingreso, retiro con motivo, Verificar datos abre el checklist).

## Qué NO probé
Npgsql real desde C#, HANA, SMTP, IIS, tiempo real; la verificación completa con el checklist de un proveedor real desde el navegador (solo se comprobó que abre); el cierre automático «No se presentó» sigue sin ejecutor.

## Por validar
P-138, P-139 y los anteriores (P-134 a P-137).

## Siguen pendientes
Corregir datos en emergencia y retirar a la única persona (→ Rechazada); correos en copia con sugerencias y reutilización de datos; accesos directos desde el dashboard.
