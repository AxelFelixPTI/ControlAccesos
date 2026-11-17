# Entrega: demo integral (solicitudes de todo tipo) + su limpiador

Solo scripts de prueba y documentación. **No cambia ningún SP ni código web**: no hay nada que recompilar.

## Qué es
`DATOS_DEMO_INTEGRAL.sql` carga **69 solicitudes** con los procedimientos reales (personas DNI `7600NNNN`):
- **Visita externa (22)**: pasadas (salió, con desviación liberada, ingreso denegado, no se presentó, retención con incidencia confirmada / desestimada, rechazada, cancelada, aprobada parcial), de hoy (dentro, salió, desviación con conformidad pendiente, incidencia pendiente, pendiente, observada, parcial) y programadas (hasta 14 días).
- **Contratista (16)**: franjas pasadas completadas, rechazada, cierre forzado, ingreso denegado, no vino; de hoy (dentro / salió / esperada, día agregado por el Coordinador, pendiente, observada, parcial); programadas de 1 a 5 días, fuera de franja, cancelada.
- **Proveedor de una empresa (18)** y **de varias empresas (13: 2, 3 y 4)**: pasadas (salió conforme / con observación, ingreso denegado, no se presentó, cierre forzado, rechazada, cancelada), de hoy (programado, en espera, con desviación, ingreso denegado, pendiente, observada y **una EN ATENCIÓN** que tiene la exclusa) y programadas. Con chofer, ayudante y documentos adjuntos.
- Crea si faltan `almacen1.demo`, `almacen2.demo` y `coordinador2.demo` (clave `Alma.Demo#2026`) y da las licencias. Para entrar use `solicitante1/2/3`, `coordinador`, `coordinador2`, `vigilante1/2/3`, `almacen1/2` (`.demo@trianon.test`).

`LIMPIAR_DEMO_INTEGRAL.sql` borra solo esos datos (solicitudes y lo que cuelga, incidencias `[DEMO-INT]`, personas) y libera la exclusa. No borra usuarios ni toca otros demos.

## Cómo usarlo
1. Ejecute `DATOS_DEMO_INTEGRAL.sql` (una sola vez; si ya hay datos 7600NNNN se detiene).
2. Para repetir: `LIMPIAR_DEMO_INTEGRAL.sql` y otra vez el de datos.
3. **Si ya tiene cargado otro demo** (escenarios, proveedor o multiempresa) con una entrega «En atención», el script se detiene con un aviso: la exclusa es de uso exclusivo. Ejecute antes el `LIMPIAR_DEMO_*` de ese demo (este demo ya trae sus propias entregas multiempresa, así que no necesita el otro).
4. Lo «pasado» se crea hoy y se retrocede en fechas; por eso las fechas de creación/registro también aparecen en el pasado.

## Archivos
BD (`Docs_Modulos/HITO_02_Solicitud_Aprobacion_2026-10-09/00_BD/`): `DATOS_DEMO_INTEGRAL.sql`, `LIMPIAR_DEMO_INTEGRAL.sql`. Docs: `DECISIONES_ARRANQUE.md` (D-248, T-51), `WORKING_CONTEXT.md`.

## Qué probé y qué no
- Probado en una base PostgreSQL reconstruida desde cero: carga completa sin errores (69 solicitudes, 127 personas, 19 documentos, 3 incidencias en sus 3 estados, 10 desviaciones); verifiqué estados por solicitud (pasadas cerradas, de hoy en curso, futuras programadas; una sola EN_ATENCION con la exclusa tomada); limpiar → 0 datos y exclusa libre; recargar; segunda carga se detiene con el aviso; el aviso cuando otro demo ocupa la exclusa.
- No cambié SP ni código, por eso no repetí las suites ni la compilación.
- **No probado:** en su base y navegador reales; verlo en las pantallas con cada usuario; convivencia con otros demos cuando hay una entrega «En atención» (por diseño se detiene).
- Conocido: en una entrega con cierre forzado el chofer y el ayudante quedan «Dentro» (es la regla del sistema: Vigilancia aún puede registrar la salida tardía).
