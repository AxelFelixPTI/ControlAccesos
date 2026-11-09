# Entrega: Contratista por franja de días (D-227) — Entrega 1

ZIP acumulado (incluye todo lo anterior). El LEEME anterior está en `LEEME_ENTREGA_HISTORIAL/`.

> **BD + .NET + web:** ejecuta `restaurar_bd.ps1` (base nueva). En una base existente: scripts `25_CAF_SOLICITUD_DIA.sql` y `26_SEED_CHECKLIST_CONTRATISTA.sql`, y luego todos los `SP_CAF_*` (cambian las firmas de `ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS` y `ERP_CAF_PORTERIA_FICHA`; cada archivo hace su DROP).

## Añadido: datos de prueba por escenarios (solo pruebas, no los corre `restaurar_bd.ps1`)
Carpeta `Docs_Modulos/HITO_02_Solicitud_Aprobacion_2026-10-09/00_BD/`:
- `DATOS_DEMO_ESCENARIOS.sql` — carga 35 solicitudes con los procedimientos reales (personas DNI `7400NNNN`): **11 de visitante externo**
  (pendiente, observada, rechazada, aprobada, aprobada parcial, cancelada; personas esperada/dentro/salió/denegada/no se presentó; desviaciones
  liberación, denegatoria y retención con conformidad dada o pendiente; incidencias registrada/confirmada/desestimada), **8 de contratista por franja**
  (pendiente, observada, rechazada, parcial, varios días, salida y vuelta a esperada, ingreso fuera de franja con desviación, día agregado por el
  Coordinador, cierre forzado del día) y **16 de proveedor** (pendiente, observada, rechazada, cancelada, programado hoy/mañana, en espera
  conforme/con desviación, ingreso denegado, en atención con ayudante dentro, salió, no se presentó, cierre forzado; responsable de almacén asignado).
  Crea si faltan `almacen1.demo`, `almacen2.demo` y un 2.º Coordinador `coordinador2.demo` (clave `Alma.Demo#2026`) y les da las licencias; ingresos y
  salidas repartidos entre vigilante1/2/3 y aprobaciones entre los dos coordinadores. Se ejecuta una vez (`psql -f` o SSMS/DBeaver); si ya hay datos 7400NNNN se detiene.
- `LIMPIAR_DEMO_ESCENARIOS.sql` — borra solo esas solicitudes (con todo lo que cuelga), las personas 7400NNNN, las incidencias `[DEMO-ESC]` y `coordinador2.demo`; libera la exclusa.
  No toca datos reales ni los usuarios del script 11. Después se puede cargar de nuevo.
- **No los combines con `DATOS_DEMO_PROVEEDOR.sql`** (la exclusa es una sola y ambos ocupan una). Para vaciar todo: `LIMPIAR_DATOS_PRUEBA.sql`.
- Probado en PostgreSQL (base nueva): carga → 35 solicitudes, 60 personas, 6 desviaciones, 3 incidencias; limpieza → todas las tablas vuelven a 0; carga y limpieza repetidas dos veces. **No probado:** SAP HANA (los scripts usan `DO $$`, `ARRAY`, `GENERATE_SERIES`, solo PostgreSQL), ni la vista de cada pantalla con estos datos.

## Qué cambia
- **Solicitud de contratista por días:** rango consecutivo y/o días sueltos (combinables), horas aproximadas de ingreso y salida (opcionales, independientes, no restringen), responsable opcional, área = zonas + detalle, cochera solo en Magdalena.
- **Vigilancia:** el contratista aparece cada día autorizado, puede ingresar y salir varias veces; fuera de franja solo ingresa con desviación; distintivo «Franja de días / Fuera de franja».
- **Cierre del día:** quien sigue dentro sale a las 23:59 de ese día (la solicitud sigue vigente) y se avisa al Coordinador.
- **Aprobada no se modifica:** «Ampliar plazo (solicitud nueva)» para el solicitante; el Coordinador puede **sumar días** (emergencia, con sustento).
- **Corrección:** `APROBADAS` de Vigilancia no traía dos columnas que el código lee (fallaba la pestaña «Aprobadas»); ya las trae.
- Filtro por tipo (Visitante/Proveedor/Contratista) verificado en Mis solicitudes, Vigilancia y Coordinación.

- **Pantalla de días rediseñada:** fechas angostas a la izquierda, lista vertical de tramos a la derecha (un rango = una línea que se quita de un clic), botones compactos.
- **Filtros del rango (solo web, combinables):** frecuencia (todos / interdiario desde lunes / desde martes) por fines de semana (incluidos / sin / con sábados).
- Fuera de franja ahora depende solo del día.

## Qué se probó
SQL (PostgreSQL, base nueva): HITO2 escritura 761/761 (probado de nuevo tras el cambio de horas), lectura 212, HITO1 143, HITO3 140+100, HITO4 138+113, permisos 43. Compilación de la web con servicios simulados. Navegador (servicios simulados) a 1280 y 390 px: selector de días, resumen, detalle, edición con días fijos, ampliar días del Coordinador, filtro por tipo; sin errores de consola.
## Qué NO se probó
Npgsql real desde C#, SAP HANA (T-36, T-37, T-38), SMTP, IIS. La pantalla de Vigilancia con «fuera de franja» solo se revisó por código y SQL, no en navegador. El envío real de crear/ampliar contra la base no pasó por la web (solo SQL y servicios simulados).
## No incluido
Entrega 2 (ajustes de campos y refinamientos de correcciones). Límites: ver P-159.
## Pendiente
P-159, P-158. Siguen entregas D (P-96/P-97) y E (P-95).
