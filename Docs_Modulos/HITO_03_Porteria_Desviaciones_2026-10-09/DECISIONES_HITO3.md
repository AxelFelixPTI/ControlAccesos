# Hito 3 · Fase 1 (portería y desviaciones) · decisiones D-62 a D-73
V1.0 2026-10-17 · archivos en `00_BD/`: `SP_CAF_DESVIACION_ALL.sql` (3 rutinas), `SP_CAF_PORTERIA_ALL.sql` (5), `SP_CAF_RESPALDO_ALL.sql` (1), `SP_CAF_PORTERIA_LECTURA_ALL.sql` (11) · pruebas `PRUEBAS_FASE1_HITO3_ESCRITURA.sql` (140 de 140 OK) y `PRUEBAS_FASE1_HITO3_LECTURA.sql` (100 de 100 OK), PostgreSQL 16. No hubo cambios de tablas (el script 07 ya estaba desplegado).

## Decisiones
- **D-62** Un movimiento (ingreso o salida) = un `CAF_Registro_Acceso` con TODOS los ítems mostrados, cumplan o no. Si algún ítem no cumple, nace UNA desviación por movimiento.
- **D-63** La regla «¿puede ingresar / salir ahora?» vive en un solo lugar: `ERP_CAF_PORTERIA_REGLA_MOVIMIENTO`. La usan los dos procedimientos de escritura y la ficha de portería (los botones `Puede_Registrar_*` y su motivo). Las pruebas comprueban que botón apagado = rechazo 409 del procedimiento (igual que D-56).
- **D-64** Un ítem crítico (identidad) que no cumple solo permite denegar el ingreso (`NO_INGRESA`); liberarlo se rechaza con 101.
- **D-65** Una denegación también es un registro. La persona queda `DENEGADA` y no se reintenta en la misma visita (409); no hay salida para ella.
- **D-66** Quien llega con equipos o herramientas y entra necesita antes un respaldo de la categoría correcta que lo cubra (`ERP_CAF_RESPALDO_REGISTRAR`): G-FSCA-009 para equipos; guía de remisión (con número) o G-FSCA-010 para herramientas/materiales. Los ítems de salida de equipos/herramientas dependen de lo que la persona declaró al ingresar.
- **D-67** Registro tardío: si Vigilancia indica la hora del hecho, se guarda como tardío; la hora no puede ser futura, debe ser del mismo día de la visita (en la salida, no anterior al ingreso) y la observación es obligatoria. La hora real de la carga queda en `Fecha_Hora_Sistema`. Una visita de fecha pasada solo se registra como tardía; una futura no se registra.
- **D-68** La salida siempre se registra y la persona siempre queda `SALIO`; la desviación solo decide si se retiene un elemento (`SALE` / `SALE_RETIENE_ELEMENTO`).
- **D-69** Permisos: registrar ingreso/salida/respaldo = `PER_CAF_PORTERIA_REGISTRAR` en la sede; levantar una desviación además exige `PER_CAF_DESVIACION_REGISTRAR`; el Coordinador consultado debe tener `PER_CAF_DESVIACION_CONFORMIDAD` en la sede; dar conformidad exige ese mismo permiso y la desviación debe estar `POR_REVISAR`.
- **D-70** «No se presentó»: solo lo ejecuta el proceso automático (usuario 0), marca personas APROBADAS en `ESPERADA` de solicitudes no canceladas con fecha anterior al corte (por defecto hoy); se puede repetir sin riesgo y deja un evento por persona.
- **D-71** El checklist se envía completo como texto `id:Y,id:N,...` (ni más ni menos ítems que los que devuelve `ERP_CAF_PORTERIA_CHECKLIST_OBTENER`).
- **D-72** Lecturas: sin permiso devuelven cero filas (D-57). Ficha, checklist y respaldos: `PORTERIA_REGISTRAR` o `PORTERIA_VER`; bitácora y detalle de movimientos: además `REPORTE_VER`; desviaciones: además `DESVIACION_CONFORMIDAD` y `DESVIACION_REGISTRAR`. Sin paginación en el servidor (D-58); búsqueda sin tildes (D-59).
- **D-73** El Hito 3 no envía correos; las notificaciones (desviación, incidencia) se ven en el Hito 4.

## Para PENDIENTES_VALIDACION.md
- **P-40** (para Sandra) ¿El respaldo debe existir ANTES del ingreso con equipos/herramientas (supuesto actual) o puede registrarse después?
- **P-41** ¿Qué pasa si a alguien se le deniega el ingreso y luego se corrige (p. ej. trae el DNI)? Hoy no reingresa en la misma visita; habría que anular el registro o crear una solicitud nueva.
- **P-42** Registro tardío: ¿lo puede hacer cualquier vigilante o solo con visto bueno? ¿hasta cuántos días después?
- **P-43** ¿Se acepta como «Coordinador consultado» a cualquier usuario con permiso de conformidad en la sede (supuesto actual)?
- **P-44** «No se presentó»: ¿se marca al cierre del mismo día o al día siguiente? (hoy: visitas con fecha anterior al corte, normalmente ayer).
- **P-45** Desviación ↔ incidencia: `ID_Incidencia` queda vacío hasta el Hito 4; confirmar cuándo una desviación debe convertirse en incidencia.
- **T-08** Traducción a HANA del Hito 3: `CROSS JOIN LATERAL` de la ficha (llamar la regla tres veces a variables), `EXTRACT(EPOCH …)` del orden de desviaciones (SECONDS_BETWEEN), `!~` (LIKE_REGEXPR), `RETURN QUERY` (procedimiento con tabla OUT), `RETURNING … INTO` (leer el identificador con la secuencia). Mismas reglas que T-06.
