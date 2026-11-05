# Entrega: Proveedor de abastecimiento, Entrega 2 corregida — flujo operativo

ZIP acumulado desde la Entrega C: contiene todos los archivos nuevos o modificados, completos y con la estructura del repositorio. Reemplaza el flujo de la Entrega 2 anterior (el LEEME anterior está en `LEEME_ENTREGA_HISTORIAL/`).

## Flujo
Programado → (Vigilancia verifica datos y registra llegada) → **En espera** → (Almacén **Confirmar disponibilidad**, solo el día programado, reserva la exclusa; Vigilancia **Valida ingreso**) → **Ingreso** → (Almacén **Iniciar atención**) → **En atención** → (Almacén **Terminar**, libera la exclusa) → **Recepción culminada** → (Vigilancia salida) → **Salió**. Otros cierres: **No se presentó**, **Ingreso denegado** (el Coordinador deniega en la verificación).
- Almacén puede **cancelar la disponibilidad** (motivo obligatorio) antes del ingreso: libera la exclusa para otro proveedor en espera.
- Una sola reserva por sede, atómica en la base de datos.
- Desviaciones: la decisión del Coordinador se toma en la verificación; su panel solo la confirma.
- Calendario: chips de estado llamativos, color por empresa que recibe, filtros por empresa/estado/fecha, **leyenda de estados y empresas** al pie, marcas «Almacén listo» y «Con desviación», botón Actualizar y consulta cada 60 s.

## Cómo aplicarlo
**Base existente:** ejecutar una sola vez `19_ALTER_PROVEEDOR_ESTADOS.sql` (carpeta `HITO_02.../00_BD`; sirve haya aplicado o no la Entrega 2 anterior), luego re-ejecutar `SP_CAF_PROVEEDOR_ALL.sql` y `SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql`. **Base nueva:** `restaurar_bd.ps1` (incluido). Compilar y publicar la web.
**Demo (opcional, solo pruebas):** `DATOS_DEMO_PROVEEDOR.sql` (9 entregas, una sola con la exclusa) y `DEMO_PROVEEDOR_VALIDAR_INGRESO.sql` (valida el ingreso de la que espera, como vigilante).

## Qué probé
- Reconstrucción limpia de la BD (scripts 01–19 + SPs); suites SQL OK, HITO2 escritura 541/541 (flujo completo, desviación autorizada y denegada, reserva única, cancelación, reserva huérfana); concurrencia SQL de la exclusa; carga de la demo.
- Compila (host de prueba con servicios simulados).
- Navegador (1280 y 390 px, servicios simulados): sin permiso 403; solo lectura; Confirmar/Cancelar (motivo obligatorio)/Iniciar/Terminar; bloqueo mientras otra entrega tiene la exclusa; filtros; leyenda; tema oscuro revisado en captura.

## Qué NO probé
- Parámetros reales de Npgsql desde C#, SAP HANA, SMTP, IIS, tiempo real.
- Las pantallas de Vigilancia (Verificación y Validar ingreso) **no existen aún** (Entrega 3); sus SP solo se probaron por SQL.
- «No se presentó» sigue sin ejecutor automático; la reserva no se libera sola al fin del día.
- La migración del script 19 usa sintaxis de PostgreSQL (HANA: T-31).

## Por validar
P-134 a P-137 (y P-128 a P-133 vigentes). Nota: `ERP_CAF_PROVEEDOR_LLEGADA` fue eliminado y `ATENDER` cambió de comportamiento.
