# Entrega 2C-0: formulario de proveedor reestructurado (D-237) — acumulativa con la 2B (D-236)

ZIP con SOLO lo nuevo o modificado respecto de lo que ya está en GitHub (`main-remoto`, 1B y 2A ya subidas). Como la **2B no se había subido**, esta entrega la incluye: aplícala completa. No incluye tus `appsettings.json` ni `27_ALTER_CHECKLIST_AYUDANTE.sql`.

> **BD existente (en este orden):**
> 1. `30_ALTER_EMPRESAS_SOLICITUD.sql` y `31_ALTER_PROVEEDOR_FORMULARIO.sql` (tablas).
> 2. Recarga los SP: `SP_CAF_SOLICITUD_EMPRESAS_ALL.sql`, `SP_CAF_SOLICITUD_PROVEEDOR_DATOS_ALL.sql` (nuevo), `SP_CAF_PROVEEDOR_ALL.sql`, `SP_CAF_SOLICITUD_TRANSPORTISTA_ALL.sql`, `SP_CAF_SOLICITUD_LECTURA_ALL.sql`, `SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql`, `SP_CAF_CORREO_PLANTILLA_ALL.sql`.
> 3. Compila y publica el sitio web.
> Base nueva: `restaurar_bd.ps1` lo hace solo (sin cambios en el script).

## Qué cambia en el formulario del proveedor
- **Hora de entrega prevista** (obligatoria) y, si quiere, «+ Indicar franja horaria» (hora final). Es solo informativa: no restringe nada.
- **N.º de OC** obligatorio, en etiquetas (una o varias, mínimo 1, hasta 5).
- **Empresa proveedora** obligatoria; **Empresa transportista** opcional tras «+ Añadir empresa transportista» (vacía = el mismo proveedor transporta).
- **Empresa(s) receptora(s) de la entrega (Cliente(s))**: casillas, 1 a 4.
- Sección **«Contacto del responsable de la entrega»**: nombre completo y **teléfono celular** en etiquetas (mínimo 1, cada uno de 9 dígitos o más, no tiene que empezar con 9); «+ Añadir correo del responsable» (solo dato de contacto).
- Línea separadora, luego **Correos en copia** y, al final, **Detalles adicionales para el correo** (ejemplo: «carga 1.671 TN, requiere montacargas»).
- Paso **Personas**: «Transportista» pasa a llamarse **Conductor**; «Ayudante de descarga» igual. La **placa del vehículo es obligatoria** para cada conductor; RUC, marca, licencia, nombre y dirección del transportista quedan tras «+ Más datos…».
- **Campos opcionales compactados** («+ Añadir …», con «Quitar») también en Contratista (responsable de atención, detalle del área, horas aproximadas). Visitante no tiene otros opcionales. Correos en copia y Detalles adicionales no se compactan.
- El correo y el detalle de la solicitud muestran OC, empresa transportista (o «El mismo proveedor»), franja y «Contacto de la entrega». El calendario de proveedores muestra OC y transporte.

## Qué cambia (2B, sin variaciones)
- Una solicitud de proveedor puede tener de 1 a 4 empresas; calendario y detalle muestran todas; se quita «Asignar responsable» del calendario.
- Catálogos → «Almacén por empresa». La migración da las 4 empresas a quien hoy tiene la licencia de Almacén. La atención sigue siendo por solicitud completa; la atención por empresa y la esclusa configurable llegan en la 2C-1/2C-2.

## Qué probé
- SQL (PostgreSQL 16, base nueva): checklist admin 49/49, Hito 1 143/143, Hito 2 escritura 811/811 (23 pruebas nuevas de D-237: normalización y validación de celulares y OC, franja, correos, creación completa, lectores y edición con bitácora), Hito 2 lectura 217/217, Hito 3 140/140 y 100/100, Hito 4 138/138 y 113/113, permisos 43/43.
- Compilación del proyecto web con Npgsql/MailKit simulados: 0 errores. JS con `node --check`.
- Navegador (páginas de prueba con datos simulados): formulario de proveedor (orden de campos, etiquetas de OC y celulares, botones «+ Añadir» y «Quitar», validaciones, franja, edición con valores previos), contratista y visitante, y el asistente de 3 pasos con conductor (placa obligatoria, resumen, datos enviados). Móvil 390 px sin desborde horizontal.

## Qué NO probé
- Npgsql real ni la aplicación completa con datos reales; el envío real de correos.
- `DATOS_DEMO_ESCENARIOS.sql` solo se ajustó a la nueva firma; no lo ejecuté de punta a punta.
- Al editar, los datos del proveedor (OC, transportista, franja, correo) se guardan en un segundo paso tras guardar los datos generales: si fallara el segundo, se avisa pero no se deshace el primero.
- No incluido: el texto SQL del correo «Solicitud nueva» no menciona la OC (sí la tabla del correo); Vigilancia no lista la OC; no se puede buscar por OC en la bandeja ni en el calendario; no verifiqué adjuntar el PDF de la OC (el formulario ya admite documentos adjuntos).
- **Siguiente:** retomar la 2C-1/2C-2 (esclusa, vehículos como aviso informativo, atención por empresa).
