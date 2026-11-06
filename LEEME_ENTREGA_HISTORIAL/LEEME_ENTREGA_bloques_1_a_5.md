# Entrega: Proveedores — bloques 1 a 5, cierre forzado del día y refresco automático

ZIP acumulado desde la Entrega C. El LEEME anterior (bloques 1 a 4) está en `LEEME_ENTREGA_HISTORIAL/`. Si ya aplicaste el ZIP de los bloques 1 y 2, mira la sección «Si ya aplicaste los bloques 1 y 2».

## Qué trae
**Bloque 1 (web):** leyenda arriba y plegable; distintivo «EXCLUSA RESERVADA» (borde grueso + cinta) hasta que el camión sale; vista Día; `LIMPIAR_DEMO_PROVEEDOR.sql` (opcional).
**Bloque 2 (BD + web):** en «Control de accesos» los proveedores muestran su estado y sus botones: **Verificar datos** (PROGRAMADO) → **Validar ingreso** (EN_ESPERA, solo con Almacén listo) y **Retiró sin ingresar** → **Registrar salida** (solo Recepción culminada). La exclusa se libera con la **salida** del camión (D-214), no al terminar la atención.
**Bloque 3 (BD + .NET + web) — corrección de emergencia del Coordinador (D-215):**
- **Corregir datos (emergencia):** en la revisión de una solicitud ya aprobada, cada persona autorizada que aún no ingresó tiene este botón. Se corrigen tipo de documento, apellidos y nombres; **el número de documento no se puede cambiar** (si es otra persona, se quita a esta y se agrega la otra). Pide sustento, deja el antes y el después en el historial y avisa por correo al solicitante y a Vigilancia. La autorización se mantiene.
- **Quitar a la única persona:** si la persona es la única de la solicitud, el botón dice «Quitar y rechazar (emergencia)» y muestra una advertencia: la solicitud queda **Rechazada** (cancelar sigue siendo solo del solicitante). Sin confirmar, la base no lo permite.
- **Proveedor:** estas dos acciones solo valen mientras la entrega siga PROGRAMADA; desde «En espera» la base responde 409 y se usa «Retiró sin ingresar» de Vigilancia.

**Bloque 4 (BD + .NET + web) — correos en copia (D-217):** el campo «Correos en copia» (y «Correos» del contacto del contratista) ahora es un buscador con etiquetas. Al escribir 2 letras sugiere primero usuarios del sistema (con su nombre) y luego correos externos usados en solicitudes anteriores; Enter, «;» o «,» agregan; la × quita; no admite repetidos ni correos mal escritos. Lo externo queda disponible solo al enviar la solicitud (no hay tabla nueva). La búsqueda de empresas y personas ya existía; nombre y teléfonos de contactos anteriores aún no se sugieren.

**Cierre forzado del día (BD + .NET + web, D-218):** si Vigilancia no registra la salida, la exclusa ya no queda pegada al día anterior.
- **Hora de corte:** parámetro `PROVEEDOR_HORA_CORTE` (por defecto 00:00). Cámbiala con `CALL "ERP_CAF_PARAMETRO_GUARDAR"('PROVEEDOR_HORA_CORTE','03:00', <tu usuario>, NULL, NULL);` (no hay pantalla todavía).
- **A la hora de corte** lo que siga abierto de un día anterior se cierra: `PROGRAMADO` → «No se presentó»; `EN_ESPERA`, `INGRESO`, `EN_ATENCION` o `RECEPCIONADO` → **«Cierre forzado»** (chip nuevo, color magenta). Se libera la exclusa y queda en el historial como acción del sistema.
- **Aviso horario:** mientras la entrega esté en «Recepción culminada» sin salida, llega un correo por hora a Vigilancia (copia a Almacén) diciendo a qué hora se cerrará a la fuerza.
- **Salida tardía:** quien quedó dentro sigue en la lista de Vigilancia con el botón **«Registrar salida (tardía)»**. Al registrarla, la entrega pasa a «Salió» y se envía un correo al **Coordinador** (descuido de Vigilancia).
- Lo ejecuta un servicio en segundo plano cada minuto (arranca con la web, igual que el envío de correos); calendario y lista de Vigilancia lo repiten como red de seguridad.

**Refresco automático (web, D-219):** el calendario de proveedores y «Control de accesos» de Vigilancia se actualizan solos **cada 10 segundos**, solo con la pestaña a la vista y sin ventana abierta (para no interrumpir un registro); en Vigilancia tampoco mientras escribes en el buscador. El botón «Actualizar» sigue. Es solo web: no requiere scripts de BD.

**Bloque 5 — accesos directos del calendario (BD + .NET + web, D-220):** cada tarjeta del calendario de proveedores muestra, según tus permisos, botones que abren la pantalla de siempre con esa entrega ya aplicada:
- **Mis solicitudes** (solo si la solicitud es tuya): deja la fila destacada con Ver / Reutilizar / Cancelar.
- **Revisar / emergencia** (Coordinador; después del ingreso dice «Ver solicitud»): abre la ventana «Revisar» de esa solicitud.
- **Verificar datos / Validar ingreso / Registrar salida** (Vigilancia, según el estado): abre Control de accesos directo en esa acción. Si no hay acción posible (por ejemplo Almacén aún no confirmó), avisa y no abre nada.
- **Caso límite:** si una entrega pierde la aprobación antes de ingresar, sale del calendario y de Vigilancia hasta que se apruebe de nuevo; si ya estaba verificada («En espera») vuelve a «Programado» y se verifica otra vez.

## Cómo aplicarlo (base existente, en este orden)
1. `20_ALTER_PROVEEDOR_RETIRO.sql`, `21_SEED_CHECKLIST_SALIDA_PROVEEDOR.sql` y **`22_ALTER_PROVEEDOR_CIERRE.sql`** (carpeta `HITO_02.../00_BD`; el 20 y el 22 una sola vez, el 21 se puede repetir). Si aplicaste el 20 antes, solo faltan el 21 y el 22.
2. Re-ejecutar, en este orden: `SP_CAF_SOLICITUD_BASE_ALL.sql`, `SP_CAF_SOLICITUD_PERSONA_ALL.sql` (¡cambia la firma de `RETIRAR_EMERGENCIA`; el script borra la anterior!), `SP_CAF_SOLICITUD_LECTURA_ALL.sql` (trae también la función de correos y la lista de Vigilancia con la salida tardía), `SP_CAF_SOLICITUD_VIGILANCIA_APROBADAS.sql`, `SP_CAF_PROVEEDOR_ALL.sql` y `SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql`. Si ya tienes la demo cargada: `LIMPIAR_DEMO_PROVEEDOR.sql` y luego `DATOS_DEMO_PROVEEDOR.sql`.
3. Compilar y publicar la web. Base nueva: `restaurar_bd.ps1` (incluido).

### Si ya aplicaste los bloques 1 y 2
Faltan el script `21_SEED_CHECKLIST_SALIDA_PROVEEDOR.sql` y luego `SP_CAF_SOLICITUD_BASE_ALL.sql`, `SP_CAF_SOLICITUD_PERSONA_ALL.sql` y `SP_CAF_SOLICITUD_LECTURA_ALL.sql` (en ese orden) y publicar la web. El bloque 3 no cambia tablas.

## Checklist de salida del proveedor (provisional)
Sin ítems de salida no se podía registrar la salida del camión. El script 21 agrega un ítem solo para el transportista principal: «Verifica que el vehículo se retire con la carga y documentación correspondiente, como guía de remisión, documento de despacho, acta de entrega u otro sustento aplicable.» Se puede editar desde el administrador de checklist. Para probar: registra la salida de una entrega en Recepción culminada desde Control de accesos.

## Cómo probar el bloque 3
Con una solicitud aprobada de fecha hoy o futura: entra como Coordinador → Solicitudes → Revisar. Prueba «Corregir datos (emergencia)» (cambia un apellido, mira que el documento esté bloqueado y que el historial muestre el antes y el después). Luego quita personas hasta que quede una: el botón cambia a «Quitar y rechazar (emergencia)» y la advertencia aparece. En una entrega de proveedor ya en espera, comprueba que no deja corregir ni quitar.

## Cómo probar el cierre forzado
En la base de pruebas: lleva una entrega a «Recepción culminada» y en SQL cambia su `Fecha_Hora_Prevista` a ayer; abre el calendario (o espera un minuto): pasa a «Cierre forzado» y la exclusa queda libre. En Control de accesos aparece «Registrar salida (tardía)»; al registrarla, la entrega queda «Salió» y se encola un correo `PROVEEDOR_AVISO` al Coordinador (con el envío en modo Simulado se ve en el registro).

## Qué probé
- **Cierre forzado:** BD reconstruida con el script 22; HITO2 escritura **606/606** (21 pruebas nuevas: parámetro válido/inválido/inexistente, aviso horario y su no repetición, no cierra durante su día, cierra al día siguiente y libera la exclusa, quien estaba dentro sigue dentro, historial del sistema, idempotencia, salida tardía real desde Vigilancia, correo al Coordinador); regresión HITO1 143, lectura 210, HITO3 140/100, HITO4 138/113, PERMISOS 43. Navegador (1280 y 390): chip y leyenda «Cierre forzado» en el calendario, botón y modal «Registrar salida (tardía)» en Vigilancia, sin errores de consola, y los 48 + 15 de las pantallas de proveedor siguen pasando.
- (Bloques 1 a 4, con 585 pruebas antes del cierre forzado) BD reconstruida desde cero. Suites: HITO2 escritura **585/585** (28 pruebas nuevas del bloque 3 y la salida con el checklist nuevo: permisos, sustento, sin cambios, documento y tipo inexistentes, persona ya dentro, fecha pasada, proveedor en espera, correo, historial, única persona sin y con confirmación, dos veces), HITO1 143, HITO2 lectura 210 (8 pruebas nuevas de sugerencias de correo), HITO3 140/100, HITO4 138/113, PERMISOS 43.
- Compila con el código real de servicio, repositorio y controlador (host de prueba con servicios simulados).
- Navegador, 1280 y 390 px: correos en copia 14 pruebas (sugerencias, elegir, repetido, inválido, escribir a mano, varios con «;», quitar, valor enviado); bloque 3, 19 pruebas (corregir, documento bloqueado, sin sustento, sin cambios, historial, botón «y rechazar» solo con una persona, advertencia, solicitud queda Rechazada, sin desborde ni errores de consola); calendario 48 y Vigilancia de proveedores 15 (de la entrega anterior).

- **Bloque 5:** HITO2 escritura **612/612** (6 pruebas nuevas: la entrega que pierde la aprobación desaparece del calendario y vuelve al reaprobarse, vuelve a PROGRAMADO si estaba verificada, `Es_Solicitante` S/N; dos pruebas existentes se ajustaron porque ahora hay que verificar de nuevo). Navegador (1280 px; 390 px 14 pruebas): accesos según permiso y estado, «Mis solicitudes» solo en las propias, solo lectura sin accesos, Mis solicitudes destaca la fila y avisa si no es suya, Coordinación abre «Revisar», Vigilancia abre «Registrar salida» y avisa si no hay acción, URL limpia, sin errores de consola; calendario 48, Vigilancia 15, coordinación 19 y correos 14 siguen pasando.
- **Refresco:** navegador 1280 px: refresca solo a los ~10 s en ambas pantallas, no refresca con una ventana abierta, sin errores de consola; calendario 48 y Vigilancia 15 siguen pasando.

## Qué NO probé
Npgsql real desde C#, HANA, SMTP, IIS, tiempo real; la verificación completa con el checklist de un proveedor real desde el navegador; el servicio en segundo plano corriendo contra la base real (solo probé las rutinas en SQL y la web con servicios simulados), la hora de corte distinta de 00:00 desde un reloj real, el correo realmente enviado (SMTP); el «No se presentó» automático de visitantes normales (sigue sin ejecutor). El navegador usó servicios simulados, no la base real.

## Por validar
P-145 a P-153 (hora de corte sin pantalla, frecuencia y destinatarios de los avisos, personas dentro tras el cierre), P-144 (sugerencias muestran todos los usuarios), P-140 (única persona = Rechazada), P-141 (la corrección cambia el registro global de la persona), P-142 (no corregir ni quitar con la entrega ya en espera) y los anteriores (P-134 a P-139).

## Siguen pendientes
Opcional: sugerir nombre y teléfonos de contactos anteriores. Bloque 5: accesos directos desde el dashboard a las pantallas originales.
