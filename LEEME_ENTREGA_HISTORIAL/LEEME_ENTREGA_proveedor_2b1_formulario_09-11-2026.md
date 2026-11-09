# Entrega: Proveedor — formulario con transportistas múltiples (2b-1)

ZIP acumulado. El LEEME anterior está en `LEEME_ENTREGA_HISTORIAL/`.

> **BD + .NET + web:** ejecuta `restaurar_bd.ps1` (base nueva) o, en una base existente, los scripts `23_CAF_SOLICITUD_TRANSPORTISTA.sql`, `SP_CAF_PROVEEDOR_ALL.sql`, `SP_CAF_SOLICITUD_ALL.sql`, `SP_CAF_SOLICITUD_LECTURA_ALL.sql`, `SP_CAF_SOLICITUD_TRANSPORTISTA_ALL.sql` y `SP_CAF_SOLICITUD_ADJUNTO_ALL.sql`; reemplaza `src`.

## Qué cambia (D-223)
- **Nueva solicitud, tipo Proveedor:** paso 1 con empresa proveedora, **empresa del grupo que recibe**, **responsable de la entrega** (nombre y teléfono), observaciones y copias. Ya no pide responsable de atención, zonas, motivo ni cochera.
- **Paso 2:** casilla **«Es transportista»** (al menos uno; el primero es el principal). Un interruptor muestra RUC, nombre, dirección, placa, marca y licencia, todos opcionales. Si falta algún dato de algún transportista, se exige adjuntar al menos un documento.
- Detalle de la solicitud y «Revisar» (Coordinación) muestran empresa que recibe, responsable y transportistas.
- Adjuntos: 10 documentos / 20 MB en total.

## Corrección 2026-11-09 (D-224): el solicitante de proveedores gestiona lo suyo
Quien puede crear solicitudes de proveedor ahora también las ve, edita y administra («Mis solicitudes», detalle, personas, adjuntos); antes la base y la web se lo negaban. Aplica a SQL: `SP_CAF_PROVEEDOR_ALL.sql`, `SP_CAF_SOLICITUD_LECTURA_ALL.sql`, `SP_CAF_SOLICITUD_PERSONA_ALL.sql`, `SP_CAF_SOLICITUD_TIPO_INGRESO_ALL.sql`, y web (`SolicitudesController`, `MenuCaf`). Solo ve el tipo «Proveedor». No hace falta tocar licencias.

## Qué se probó
SQL (PostgreSQL, base nueva): HITO2 escritura 648/648, lectura 212, HITO1 143, HITO3 140/100, HITO4 138/113, PERMISOS 43, HITO0 65. Compilación .NET: 0 errores. Navegador (Playwright con servicios simulados, 1280 y 390 px): formulario de proveedor 27 comprobaciones, calendario y botones (prov, b5).
## Qué NO se probó
Npgsql real desde C#, SAP HANA (ver T-36), SMTP, IIS ni el servicio en segundo plano. Pruebas de navegador antiguas desactualizadas por diseño: límite de 2 adjuntos (adj/adj2) y un chequeo de menú de roles (rol).
## Pendiente
P-156 (permiso del proveedor-solicitante), P-157 / 2b-2 (verificación por transportista en Vigilancia).
