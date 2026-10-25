# Entrega del 2026-10-24 · Integración de correo

## Qué trae
- **Base de datos:** `ERP_CAF_FN_COPIA_CORREO` (nueva) y los avisos de solicitud con Para/CC según tu flujo; rutinas `ERP_CAF_CORREO_SOLICITUD_DATOS` y `_PERSONAS` (archivo nuevo `SP_CAF_CORREO_PLANTILLA_ALL.sql`); prueba actualizada y ampliada.
- **Aplicación:** plantilla HTML sobria + texto, hilo de mensajes, `UrlBase`, `RedirigirA` (modo prueba), envío dentro de la web y comando `vista-previa-correos`.
- **Asistente de solicitud:** «Observaciones» → «Detalles adicionales (opcional)».
- **Guías:** `GUIA_CORREO.md` (Gmail, hilo, destinatarios) y `GUIA_DESPLIEGUE_RED.md` (tu PC como servidor en la red). Ejemplos de correo en `Docs_Modulos/ARRANQUE_PASO1/vista_previa_correos/` (abre los `.html` en el navegador).

## Pasos
1. Copia los archivos sobre el repositorio (conservan su carpeta).
2. **Base nueva y vacía:** `.\restaurar_bd.ps1 -Database accesos_piloto_correo -Crear` (con `-SoloRutinas` no se crean las tablas). Debe terminar con las pruebas en OK.
3. Configura el correo siguiendo `GUIA_CORREO.md` (la clave de aplicación va solo en `appsettings.Local.json`, nunca en el chat). Empieza con `RedirigirA` apuntando a tu correo personal.
4. Ejecuta la web, crea una solicitud como solicitante y espera hasta 30 segundos: llega un correo con los datos y el botón.
5. Aprueba como coordinador: debe llegar una respuesta en la misma conversación.

## Qué revisar
1. El diseño de los correos (carpeta `vista_previa_correos`).
2. Que el hilo se agrupe en Gmail (P-89) y la lista de destinatarios (P-88).

## Siguiente
Primer despliegue en tu red con `GUIA_DESPLIEGUE_RED.md`; luego los rediseños de pantallas.
