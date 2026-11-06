# Entrega: Proveedores — bloques 1 a 4 (calendario, Vigilancia, exclusa hasta la salida, corrección de emergencia y correos en copia)

ZIP acumulado desde la Entrega C. El LEEME anterior está en `LEEME_ENTREGA_HISTORIAL/`. Si ya aplicaste el ZIP de los bloques 1 y 2, mira la sección «Si ya aplicaste los bloques 1 y 2».

## Qué trae
**Bloque 1 (web):** leyenda arriba y plegable; distintivo «EXCLUSA RESERVADA» (borde grueso + cinta) hasta que el camión sale; vista Día; `LIMPIAR_DEMO_PROVEEDOR.sql` (opcional).
**Bloque 2 (BD + web):** en «Control de accesos» los proveedores muestran su estado y sus botones: **Verificar datos** (PROGRAMADO) → **Validar ingreso** (EN_ESPERA, solo con Almacén listo) y **Retiró sin ingresar** → **Registrar salida** (solo Recepción culminada). La exclusa se libera con la **salida** del camión (D-214), no al terminar la atención.
**Bloque 3 (BD + .NET + web) — corrección de emergencia del Coordinador (D-215):**
- **Corregir datos (emergencia):** en la revisión de una solicitud ya aprobada, cada persona autorizada que aún no ingresó tiene este botón. Se corrigen tipo de documento, apellidos y nombres; **el número de documento no se puede cambiar** (si es otra persona, se quita a esta y se agrega la otra). Pide sustento, deja el antes y el después en el historial y avisa por correo al solicitante y a Vigilancia. La autorización se mantiene.
- **Quitar a la única persona:** si la persona es la única de la solicitud, el botón dice «Quitar y rechazar (emergencia)» y muestra una advertencia: la solicitud queda **Rechazada** (cancelar sigue siendo solo del solicitante). Sin confirmar, la base no lo permite.
- **Proveedor:** estas dos acciones solo valen mientras la entrega siga PROGRAMADA; desde «En espera» la base responde 409 y se usa «Retiró sin ingresar» de Vigilancia.

**Bloque 4 (BD + .NET + web) — correos en copia (D-217):** el campo «Correos en copia» (y «Correos» del contacto del contratista) ahora es un buscador con etiquetas. Al escribir 2 letras sugiere primero usuarios del sistema (con su nombre) y luego correos externos usados en solicitudes anteriores; Enter, «;» o «,» agregan; la × quita; no admite repetidos ni correos mal escritos. Lo externo queda disponible solo al enviar la solicitud (no hay tabla nueva). La búsqueda de empresas y personas ya existía; nombre y teléfonos de contactos anteriores aún no se sugieren.

## Cómo aplicarlo (base existente, en este orden)
1. `20_ALTER_PROVEEDOR_RETIRO.sql` y `21_SEED_CHECKLIST_SALIDA_PROVEEDOR.sql` (carpeta `HITO_02.../00_BD`; el 20 una sola vez, el 21 se puede repetir).
2. Re-ejecutar, en este orden: `SP_CAF_SOLICITUD_BASE_ALL.sql`, `SP_CAF_SOLICITUD_PERSONA_ALL.sql` (¡cambia la firma de `RETIRAR_EMERGENCIA`; el script borra la anterior!), `SP_CAF_SOLICITUD_LECTURA_ALL.sql` (trae también la función de correos), `SP_CAF_SOLICITUD_VIGILANCIA_APROBADAS.sql`, `SP_CAF_PROVEEDOR_ALL.sql` y `SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql`. Si ya tienes la demo cargada: `LIMPIAR_DEMO_PROVEEDOR.sql` y luego `DATOS_DEMO_PROVEEDOR.sql`.
3. Compilar y publicar la web. Base nueva: `restaurar_bd.ps1` (incluido).

### Si ya aplicaste los bloques 1 y 2
Faltan el script `21_SEED_CHECKLIST_SALIDA_PROVEEDOR.sql` y luego `SP_CAF_SOLICITUD_BASE_ALL.sql`, `SP_CAF_SOLICITUD_PERSONA_ALL.sql` y `SP_CAF_SOLICITUD_LECTURA_ALL.sql` (en ese orden) y publicar la web. El bloque 3 no cambia tablas.

## Checklist de salida del proveedor (provisional)
Sin ítems de salida no se podía registrar la salida del camión. El script 21 agrega un ítem solo para el transportista principal: «Verifica que el vehículo se retire con la carga y documentación correspondiente, como guía de remisión, documento de despacho, acta de entrega u otro sustento aplicable.» Se puede editar desde el administrador de checklist. Para probar: registra la salida de una entrega en Recepción culminada desde Control de accesos.

## Cómo probar el bloque 3
Con una solicitud aprobada de fecha hoy o futura: entra como Coordinador → Solicitudes → Revisar. Prueba «Corregir datos (emergencia)» (cambia un apellido, mira que el documento esté bloqueado y que el historial muestre el antes y el después). Luego quita personas hasta que quede una: el botón cambia a «Quitar y rechazar (emergencia)» y la advertencia aparece. En una entrega de proveedor ya en espera, comprueba que no deja corregir ni quitar.

## Qué probé
- BD reconstruida desde cero (scripts 01–20 + SPs). Suites: HITO2 escritura **585/585** (28 pruebas nuevas del bloque 3 y la salida con el checklist nuevo: permisos, sustento, sin cambios, documento y tipo inexistentes, persona ya dentro, fecha pasada, proveedor en espera, correo, historial, única persona sin y con confirmación, dos veces), HITO1 143, HITO2 lectura 210 (8 pruebas nuevas de sugerencias de correo), HITO3 140/100, HITO4 138/113, PERMISOS 43.
- Compila con el código real de servicio, repositorio y controlador (host de prueba con servicios simulados).
- Navegador, 1280 y 390 px: correos en copia 14 pruebas (sugerencias, elegir, repetido, inválido, escribir a mano, varios con «;», quitar, valor enviado); bloque 3, 19 pruebas (corregir, documento bloqueado, sin sustento, sin cambios, historial, botón «y rechazar» solo con una persona, advertencia, solicitud queda Rechazada, sin desborde ni errores de consola); calendario 48 y Vigilancia de proveedores 15 (de la entrega anterior).

## Qué NO probé
Npgsql real desde C#, HANA, SMTP, IIS, tiempo real; la verificación completa con el checklist de un proveedor real desde el navegador; el cierre automático «No se presentó» (sigue sin ejecutor). El navegador usó servicios simulados, no la base real.

## Por validar
P-144 (sugerencias muestran todos los usuarios), P-140 (única persona = Rechazada), P-141 (la corrección cambia el registro global de la persona), P-142 (no corregir ni quitar con la entrega ya en espera) y los anteriores (P-134 a P-139).

## Siguen pendientes
Opcional: sugerir nombre y teléfonos de contactos anteriores. Bloque 5: accesos directos desde el dashboard a las pantallas originales.
