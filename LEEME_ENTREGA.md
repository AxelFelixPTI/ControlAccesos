# Entrega consolidada D-259 a D-275 (incluye la 2b-2, la 2c, la 2d y las correcciones D-266, D-267, D-268 D-269 y D-270)

Este ZIP reemplaza a todas las entregas anteriores (incluida la «Entrega_2b-2_D-263.zip» si aún no la subió) desde la Entrega 1: contiene **todos** los archivos nuevos o modificados desde el último commit de su repositorio. Se sube **una sola vez** con `COMMIT_MESSAGE.txt`.

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

- **D-264 (nuevo, 2c)** «Atendido por» completo y bloque «Atención de Almacén»:
  - La tarjeta del calendario lista a **todos** los almaceneros que atendieron, con la empresa de cada uno («Atendió: Ana (E1), Luis (E3)»).
  - En el detalle de la solicitud de proveedor hay un bloque aparte «Atención de Almacén»: por empresa, quién inició y terminó, horas, resultado y motivos, más la línea de tiempo de Almacén.
  - Solo lo ve quien tenga la nueva licencia **«Historial de Almacén»** (`LIC_CAF_HIST_ALMACEN`), pensada para Almacén y Vigilancia.

- **D-265 (nuevo, 2d)** «Documentos de ingreso»:
  - Pantalla nueva (menú **Vigilancia → Documentos de ingreso**; Almacén la ve en **Proveedores**): Vigilancia sube PDF, JPG o PNG del día, de forma asíncrona (barra de avance por archivo), y los asocia con etiquetas a una o varias personas que ingresaron ese día. Autocompletado con filtro «solo quienes trajeron equipos o herramientas» (activo por defecto).
  - Almacén solo consulta y descarga; el Coordinador no los ve. En el detalle de la solicitud aparece el bloque «Documentos de ingreso» (con la licencia «Historial de Almacén»).
  - Dos parámetros en Catálogos → Parámetros: **Documento de ingreso obligatorio** (por defecto No; si es Sí solo marca pendientes, nunca bloquea) y **Tamaño máximo (MB)** (1 a 30, por defecto 10).
  - No hay licencia nueva: reutiliza permisos existentes.

- **D-266 (corrección)** «Cerrar sin atención»: antes cualquier almacenero de la empresa podía cerrarla mientras estuviera pendiente. Ahora solo: quien tiene la licencia «Cerrar sin atención», quien inició esa empresa, quien reservó la entrega, o —una vez que ya empezó la atención de la solicitud— el almacenero de la empresa que falta (solo esa). Siempre limitado a las empresas que tiene asignadas. Solo cambia una rutina (`SP_CAF_SOLICITUD_ATENCION_ALL`); recárguela con `-SoloRutinas`.

- **D-267 (corrección)**: solo puede **confirmar la disponibilidad** (y tomar la reserva) un almacenero asignado a al menos una empresa de esa entrega; a los demás ya no se les ofrece el botón y se les explica por qué. Además, **«Iniciar atención» siempre abre la ventana de empresas** y pide confirmar, aunque quede una sola. Cambian dos rutinas (`SP_CAF_SOLICITUD_ATENCION_ALL`, `SP_CAF_PROVEEDOR_DASHBOARD_ALL`) y `proveedores.js`.

- **D-275 (equipos y herramientas en el grupo)**: en la verificación o validación en grupo, Vigilancia marca por persona quién trae **equipos** o **herramientas**; a cada marcada se le pide su respaldo (uno puede cubrir a varias) y, si falta, se rechaza todo el grupo con el nombre de quien falta. Para aplicar: recargar rutinas (`restaurar_bd.ps1 -SoloRutinas`, el procedimiento se recrea) y reemplazar el .NET. Pruebas: Hito 2 escritura 1037/1037 y las otras 12 suites en verde; C# sin compilar y pantalla sin ver en navegador.
- **D-274 (Historial de Almacén ampliado)**: ahora muestra la **OC**, placa, conductor y transportista; la **franja programada** frente a la hora real de atención (con el desvío y si quedó fuera de la franja); el **estado de la entrega** con llegada, ingreso y salida; con/sin ingreso vehicular juntos en esa misma columna; y busca por OC. Donde no hay dato explica el motivo en vez de «—». Para aplicar: recargar rutinas (`restaurar_bd.ps1 -SoloRutinas`; la función se recrea) y reemplazar el .NET. Pruebas: Hito 2 escritura 1035/1035 y las otras 12 suites en verde; C# sin compilar y pantalla sin ver en navegador.
- **D-273 (Historial de Almacén)**: pantalla nueva «Historial de Almacén» (menú Proveedores) con el listado de todas las atenciones de Almacén en entregas de proveedores (quién atendió, tiempo activo, pausas, con o sin ingreso vehicular, resultado), con filtros, exportar a CSV e imprimir. La ve quien tenga la licencia «Historial de Almacén». Solo recarga de rutinas (`-SoloRutinas`); no hay script de tablas nuevo.
- **D-272 (documentos de ingreso)**: Almacén ya **no** ve los documentos; la consulta es una licencia aparte, **«Consultar documentos de ingreso»**, que el script **45** concede a los coordinadores actuales (se asigna o quita en Usuarios y roles). Íconos en el menú y las pestañas. El bloque «Documentos de ingreso» del detalle de la solicitud ya no depende de la licencia «Historial de Almacén». Ejecute el script 45 (y el 44 si no lo hizo) y recargue rutinas (`-SoloRutinas`).
- **D-271 (correos)**: el envío automático de correos es ahora el parámetro **«Envío automático de correos»** en Parámetros (por defecto **No**: solo salen los reenvíos manuales; los avisos esperan en la cola). Hay un script nuevo de tablas, **44** (si ya tenía hasta el 43, ejecute solo el 44), y debe recargar rutinas (`-SoloRutinas`). Ejecute `DESCARTAR_CORREOS_PENDIENTES.sql` una vez para limpiar lo que dejaron los demos. En producción, póngalo en Sí desde Parámetros.
- **D-270**: el Coordinador que aprueba también **consulta** los documentos de ingreso (no sube). Recargar rutinas.
- **D-269 (Documentos de ingreso, rediseño)**: pantalla en dos pestañas **Subir** y **Consultar**; selector de archivos con «Adjuntar documento» y «Quitar»; botón con ícono; nombres como etiquetas; búsqueda por rango de días y por persona (nueva función `ERP_CAF_DOC_INGRESO_BUSCAR`). Se aplica recargando rutinas (`restaurar_bd.ps1 -SoloRutinas`); no hay script nuevo de tablas.
- **D-268 (correos y formularios)**: el correo de proveedor (automático y reenvío) ahora muestra las **empresas receptoras** y el **«Contacto responsable de la entrega»**; en contratista el rótulo es **«Responsable designado del área usuaria»** y en visitante **«Responsable de atención»**. En el formulario del contratista ese campo ya se ve siempre y es obligatorio. Cambia la rutina `SP_CAF_CORREO_PLANTILLA_ALL`, el código del correo (C#) y cuatro archivos JS.

## Cómo aplicarla (en este orden)
1. Descomprima el ZIP sobre la raíz del repositorio (respeta la estructura de carpetas).
2. Base de datos:
   - Si su base ya tiene aplicados los scripts 40 y 41 (Entrega 2), ejecute **solo los scripts nuevos 42 y 43** (`42_ALTER_LICENCIA_HISTORIAL_ALMACEN.sql` y `43_CAF_DOCUMENTO_INGRESO.sql`, idempotentes, en ese orden) y luego recargue las rutinas: `.\restaurar_bd.ps1 -Database <su_base> -SoloRutinas`.
   - Si parte de una base vacía: `.\restaurar_bd.ps1 -Database <su_base> -Crear` (aplica 40 a 43 y todas las rutinas; no hace falta editar nada, el script descubre los archivos solo).
   - La 2b-2 no trae ALTER; la 2c trae el 42 y la 2d el 43. Los cambios de rutinas son: `SP_CAF_PROVEEDOR_ALL`, `SP_CAF_PROVEEDOR_GRUPO_ALL`, `SP_CAF_PROVEEDOR_DASHBOARD_ALL`, `SP_CAF_PROVEEDOR_INGRESO_VEHICULAR_ALL` (nuevo en D-260, V1.3 aquí) y `SP_CAF_SOLICITUD_ATENCION_ALL` el archivo nuevo `SP_CAF_PROVEEDOR_ATENCION_HISTORIAL_ALL` y el archivo nuevo `SP_CAF_DOCUMENTO_INGRESO_ALL` (además `SP_CAF_PROVEEDOR_ALL` valida los dos parámetros nuevos).
3. Compile y publique la aplicación (hay cambios en Application, Infrastructure y Web).
4. Asigne la licencia **«Historial de Almacén»** a quien deba ver el bloque (Almacén y Vigilancia). Asigne la licencia **«Coordinador de Almacén»** (`LIC_CAF_COORD_ALMACEN`) a quien corresponda (P-169). Sin ella nadie puede liberar plazas de una entrega que no atiende.
5. Si usa datos demo: ejecute primero el limpiador del demo que tenga cargado y luego el nuevo. **No cargue el integral y el de escenarios a la vez** (el cupo del almacenero queda ocupado y el segundo se detiene con 409).

## Qué probé
- PostgreSQL local, base reconstruida desde cero: **Hito 2 escritura 1034/1034** (7 pruebas nuevas de D-263, 6 de D-264, 14 de D-265, 6 de D-266 3 de D-267 1 de D-268 y 2 de D-269; dos de D-261 ajustadas porque ahora la reserva se libera al recepcionar), **las 13 suites en verde** (Hito 2 lectura 217, vencida 79, correo 37, Hito 3 100/140, Hito 1 143, checklist 49, Hito 4 115/149) (Permisos 45/45, ahora con 22 permisos).
- Demos: integral, escenarios y multiempresa cargan y limpian sin error.
- `node --check` de `proveedores.js` y `manual.js`; `documentos-ingreso.js`, `detalle.js` y `parametros.js` también; `tecnica.js` regenerado (306 SP).

## Qué NO probé (dígalo si lo ve)
- **Compilación de C#**: no hay `dotnet` en mi entorno. Revisé a ojo los cambios (DTO, repo, servicio, controlador, VM).
- **El correo generado**: la plantilla (C#) no tiene pruebas automáticas ni la compilé; revise un correo real de proveedor, contratista y visitante.
- **La pantalla en navegador**: botón, modal y casilla con placas (D-263) el bloque «Atención de Almacén» y la línea «Atendió» (D-264), y la pantalla «Documentos de ingreso» (subida con progreso, etiquetas, descarga) y su bloque en el detalle (D-265) están escritos y revisados, pero no los vi funcionando. **La subida real de un PDF por el servidor web no se ejecutó** (solo el procedimiento con bytes de prueba).
- ESLint, SAP HANA real y envío real de correo.

## Para validar con Sandra
P-171 (liberación temprana), P-172 (licencia y alcance del bloque de Almacén), P-173 (documentos de ingreso), P-174 (quién cierra sin atención), P-175 (ceder atención, por decidir), P-176 (responsable del contratista en la base) y las pendientes P-169 y P-170.
