# Entrega 2C-1: atención por empresa, cierre sin atención y Parámetros (D-238) — acumulativa con 2C-0 (D-237) y 2B (D-236)

ZIP con SOLO lo nuevo o modificado respecto de lo que ya está en GitHub (`main-remoto`, 1B y 2A ya subidas). Como la **2B no se había subido**, esta entrega la incluye: aplícala completa. No incluye tus `appsettings.json` ni `27_ALTER_CHECKLIST_AYUDANTE.sql`.

> **BD existente (en este orden):**
> 1. `30_ALTER_EMPRESAS_SOLICITUD.sql`, `31_ALTER_PROVEEDOR_FORMULARIO.sql` y `32_ALTER_ATENCION_EMPRESA.sql` (tablas; el 32 crea los motivos de «cerrar sin atención», la atención por empresa y el parámetro de atenciones simultáneas).
> 2. Recarga los SP: `SP_CAF_SOLICITUD_EMPRESAS_ALL.sql`, `SP_CAF_SOLICITUD_PROVEEDOR_DATOS_ALL.sql` (nuevo), `SP_CAF_PROVEEDOR_ALL.sql`, `SP_CAF_SOLICITUD_ATENCION_ALL.sql` (nuevo), `SP_CAF_SOLICITUD_TRANSPORTISTA_ALL.sql`, `SP_CAF_SOLICITUD_LECTURA_ALL.sql`, `SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql`, `SP_CAF_CORREO_PLANTILLA_ALL.sql`.
> 3. Compila y publica el sitio web.
> Base nueva: `restaurar_bd.ps1` lo hace solo (sin cambios en el script).

## Qué cambia (2C-1: atención por empresa)
- **Cada empresa del pedido se atiende por separado.** En el calendario, la entrega con varias empresas muestra el estado de cada una (Pendiente · En atención · Atendida · Sin atención) y, para Almacén, el botón **«Atención por empresa»**: una fila por empresa con **Atender**, **Terminar atención** y **Cerrar sin atención**.
- **Almacenero compartido:** solo puede actuar sobre las empresas que él atiende (Catálogos → «Almacén por empresa») **y** que están en el pedido. Ejemplo: atiende PT y TA, el pedido es PT y TS → solo PT; en TS la fila le explica que no es suya.
- **Cerrar sin atención:** lo hace el Almacén de esa empresa. Motivo de una lista (sin mercadería, rechazada, atendida en otra entrega, Otro) y detalle obligatorio si es «Otro».
- **Atenciones simultáneas por empresa** (por defecto 1): si la empresa ya tiene ese número de entregas en atención, **no deja iniciar otra** (mensaje claro). Se cambia en **Catálogos → Parámetros** (sin tocar la base). Esa sección también muestra la hora de corte y la capacidad de la esclusa si existen. Hoy la protege el mismo permiso que Catálogos; cuando la definición de catálogos tenga su propia licencia, solo se cambia una constante (`ParametrosController.Permiso`).
- **Cierre de la entrega:** la primera empresa que empieza pone la entrega «En atención»; cuando todas quedan Atendidas o Cerradas sin atención, la entrega pasa a «Recepcionada» (con la observación que resume cada empresa) y Vigilancia registra la salida como siempre.
- **Una sola empresa:** nada cambia (siguen «Iniciar atención» y «Terminar atención»). Con varias empresas, los botones antiguos devuelven un aviso (409) y hay que usar la atención por empresa.

## Qué cambia en el formulario del proveedor
- **Hora de entrega prevista** (obligatoria) y, si quiere, «+ Indicar franja horaria» (hora final). Es solo informativa: no restringe nada.
- **N.º de OC** obligatorio, en etiquetas (una o varias, mínimo 1, hasta 5).
- **Empresa proveedora** obligatoria; **Empresa transportista** opcional tras «+ Añadir empresa transportista» (vacía = el mismo proveedor transporta).
- **Empresa(s) receptora(s) de la entrega (Cliente(s))**: casillas, 1 a 4.
- Sección **«Contacto del responsable de la entrega»**: nombre completo y **teléfono celular** en etiquetas (mínimo 1, cada uno de 9 dígitos o más, no tiene que empezar con 9); «+ Añadir correo del responsable» (solo dato de contacto).
- Línea separadora, luego **Correos en copia** y, al final, **Detalles adicionales para el correo** (ejemplo: «carga 1.671 TN, requiere montacargas»).
- Paso **Personas**: «Transportista» pasa a llamarse **Conductor**; «Ayudante de descarga» igual. La **placa del vehículo es obligatoria** para cada conductor; RUC, marca, licencia, nombre y dirección del transportista quedan tras «+ Más datos…».
- **Campos opcionales compactados** («+ Añadir …», con «Quitar») también en Contratista (responsable de atención, detalle del área, horas aproximadas). Visitante no tiene otros opcionales. Correos en copia y Detalles adicionales no se compactan.
- **Anchos proporcionales en todos los formularios** (proveedor, contratista, visitante, agregar persona): fecha, hora, placa y selectores cortos tienen ancho corto y comparten fila; empresas receptoras y zonas van en horizontal; solo los textos largos ocupan la línea. En celular, los campos cortos van de dos en dos y los largos a todo el ancho. Cambios en `site.css` (clases `.fila`, `.f-xs/.f-s/.f-m/.f-l`) y en `comun.js`, `nueva.js`, `coordinacion.js`.
- El correo y el detalle de la solicitud muestran OC, empresa transportista (o «El mismo proveedor»), franja y «Contacto de la entrega». El calendario de proveedores muestra OC y transporte.

## Qué cambia (2B, sin variaciones)
- Una solicitud de proveedor puede tener de 1 a 4 empresas; calendario y detalle muestran todas; se quita «Asignar responsable» del calendario.
- Catálogos → «Almacén por empresa». La migración da las 4 empresas a quien hoy tiene la licencia de Almacén. La atención por empresa llegó en la 2C-1; la esclusa configurable llegan en la 2C-1/2C-2.

## Qué probé
- SQL (PostgreSQL 16, base nueva): checklist admin 49/49, Hito 1 143/143, Hito 2 escritura 838/838 (27 pruebas nuevas de D-238 —almacenero compartido PT+TA sobre pedido PT+TS, 101/404/409, límite simultáneo y su parámetro, cierre sin atención con motivo y «Otro», cierre automático de la entrega, calendario— más las 23 de D-237: normalización y validación de celulares y OC, franja, correos, creación completa, lectores y edición con bitácora), Hito 2 lectura 217/217, Hito 3 140/140 y 100/100, Hito 4 138/138 y 113/113, permisos 43/43.
- Compilación del proyecto web con Npgsql/MailKit simulados: 0 errores. JS con `node --check`.
- Navegador (páginas de prueba con respuestas simuladas): calendario con estado por empresa, modal «Atención por empresa» (almacenero PT sobre pedido PT+TS: solo PT tiene botones y TS explica por qué no), Atender → Terminar con observación y errores de «Cerrar sin atención» (motivo y detalle de «Otro»); sección Parámetros (lista, editar, error de validación del servidor).
- Navegador (páginas de prueba con datos simulados): formulario de proveedor (orden de campos, etiquetas de OC y celulares, botones «+ Añadir» y «Quitar», validaciones, franja, edición con valores previos), contratista y visitante, y el asistente de 3 pasos con conductor (placa obligatoria, resumen, datos enviados). Móvil 390 px sin desborde horizontal.

## Qué NO probé
- Npgsql real ni la aplicación completa con datos reales; el envío real de correos.
- `DATOS_DEMO_ESCENARIOS.sql` solo se ajustó a la nueva firma; no lo ejecuté de punta a punta.
- Al editar, los datos del proveedor (OC, transportista, franja, correo) se guardan en un segundo paso tras guardar los datos generales: si fallara el segundo, se avisa pero no se deshace el primero.
- No incluido: el texto SQL del correo «Solicitud nueva» no menciona la OC (sí la tabla del correo); Vigilancia no lista la OC; no se puede buscar por OC en la bandeja ni en el calendario; no verifiqué adjuntar el PDF de la OC (el formulario ya admite documentos adjuntos).
- 2C-1: **no hay correo de aviso al solicitante** por un cierre sin atención (no existe un tipo de correo de recepción en la cola): queda en la bitácora y en la observación de la recepción. Las listas de Vigilancia no muestran el estado por empresa. Las pruebas de navegador usan respuestas simuladas, no el servidor real.
- **Siguiente:** 2C-2 (capacidad de la esclusa configurable o «sin límite», vehículos como aviso informativo, ventana de cancelación, «requiere ingreso vehicular»), cuando lo pidas; luego Entregas C, D y E.
