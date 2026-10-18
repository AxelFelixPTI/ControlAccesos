# Hito 4 · Fase 1 (incidencias, correos y reporte) · decisiones D-74 a D-85
V1.0 2026-10-18 · archivos en `00_BD/`: `SP_CAF_INCIDENCIA_ALL.sql` (7 rutinas), `SP_CAF_CORREO_ALL.sql` (5), `SP_CAF_REPORTE_ALL.sql` (3) · pruebas `PRUEBAS_FASE1_HITO4_ESCRITURA.sql` (135 de 135 OK) y `PRUEBAS_FASE1_HITO4_LECTURA.sql` (113 de 113 OK), PostgreSQL 16. No hubo cambios de tablas (el script 08 ya estaba desplegado). Total tras este hito: 59 + 114 rutinas.

## Decisiones
- **D-74** Una incidencia nace `REGISTRADA`; un Coordinador la `CONFIRMA` o `DESESTIMA` (una sola vez, 409 si ya fue decidida). El sustento es obligatorio en ambos casos.
- **D-75** `Origen` lo fija el procedimiento: `COORDINADOR` si quien registra tiene `PER_CAF_INCIDENCIA_DECIDIR` en la sede, `VIGILANCIA` si no. La pantalla no lo envía.
- **D-76** Lugar: se exige zona del catálogo (de la misma sede, activa) o un lugar escrito; pueden ir ambos. «Otro» exige explicar el tipo; en los demás tipos el detalle se descarta.
- **D-77** Personas involucradas: opcionales (cero, una o varias), de visitas de la sede **en cualquier estado** (una persona pudo haber salido, o su visita estar cancelada). Lista `12,15` sin repetidos. La fecha del hecho no puede ser futura (tolerancia 5 min) y puede ser de días atrás.
- **D-78** Bitácora: `INCIDENCIA` + `REGISTRAR`/`CONFIRMAR`/`DESESTIMAR`. El evento apunta a la solicitud solo si todas las personas son de la misma visita; si no, queda sin solicitud.
- **D-79** Permisos: registrar = `PER_CAF_INCIDENCIA_REGISTRAR`; decidir = `PER_CAF_INCIDENCIA_DECIDIR`; ver lista, detalle, personas y contadores = cualquiera de registrar, decidir, `PORTERIA_VER` o `REPORTE_VER`; buscar personas para la incidencia = registrar. El botón `Puede_Decidir` del detalle repite la regla del SP y las pruebas lo verifican (D-56/D-63).
- **D-80** Correos: los SP de negocio solo encolan (D-19). El proceso en segundo plano se identifica como usuario del sistema (`0`, D-12): únicos que pueden listar pendientes (con cuerpo), marcar `ENVIADO` o registrar un error. Una persona (aunque sea Administrador) recibe 101 o cero filas.
- **D-81** Reintentos: cada error suma un intento; al llegar a `HV_Max_Intentos` (1 a 20, lo decide la aplicación) el correo pasa a `ERROR` y deja de salir en pendientes; antes sigue `PENDIENTE`. Los pendientes salen del más antiguo, máximo 1 a 100 por lectura (por defecto 20).
- **D-82** Administración de la bandeja: `PER_CAF_ADMIN_USUARIOS` en la sede. Lista sin cuerpo (solicitudes de la sede y correos sin solicitud); `REENCOLAR` devuelve un correo en `ERROR` a `PENDIENTE` con intentos en cero.
- **D-83** Reporte: exige `PER_CAF_REPORTE_VER` (Coordinador; Vigilancia no). Rango obligatorio y máximo 92 días; fuera de rango devuelve cero filas. `REPORTE_ACCESOS` es una fila por movimiento (base de la exportación a Excel) con zonas, ítems incumplidos y desviación.
- **D-84** `REPORTE_RESUMEN_DIARIO`: por día, ingresos (incluye restringidos), restringidos, denegados, salidas, desviaciones e incidencias (por fecha del hecho; las desestimadas no cuentan).
- **D-85** `REPORTE_AUTORIZADOS_POR_ZONA`: personas APROBADAS de solicitudes no canceladas de esa fecha que incluyen la zona, con su estado actual (llegaron a entrar o no): responde «¿quién estaba autorizado a esa zona ese día?».

## Para PENDIENTES_VALIDACION.md
- **P-46** (para Sandra) ¿Un Coordinador puede decidir una incidencia que él mismo registró (supuesto actual: sí)?
- **P-47** ¿Una incidencia confirmada debe avisar por correo (a quién)? Hoy no se envía ninguno: el CHECK de `CAF_Correo_Pendiente.Tipo` no tiene tipo de incidencia; agregarlo sería un `ALTER` de la tabla.
- **P-48** ¿Una incidencia puede corregirse o anularse después de registrada? Hoy no hay edición (solo decidir).
- **P-49** Reporte: ¿92 días de rango máximo es suficiente? ¿Qué columnas necesita el Excel del G-FSCA-008?
- **P-50** Correos: ¿máximo de reintentos (propuesta 5) y espera entre intentos (propuesta 5 minutos)? Lo aplica el proceso en segundo plano de la aplicación.
- **T-09** Traducción a HANA del Hito 4: `STRING_AGG` (existe en HANA con `ORDER BY` dentro), `LIMIT n` con variable (usar `TOP`/`LIMIT` con parámetro), `OFFSET`, `RETURN QUERY`, `RETURNING … INTO`, `!~` (LIKE_REGEXPR), `EXTRACT(EPOCH …)`. Mismas reglas que T-06/T-08.
