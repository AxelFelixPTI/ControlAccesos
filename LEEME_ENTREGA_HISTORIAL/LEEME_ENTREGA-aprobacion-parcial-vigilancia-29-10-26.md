# Entrega F (2026-10-29) · Vigilancia en aprobación parcial y un solo aviso por revisión

Construye sobre la Entrega E (incluye sus archivos, completos). Aplique antes C, D, D1 y E si aún no lo hizo.

## Qué trae
- **Vigilancia recibe correo en aprobación parcial (D-181):** correo propio `SOLICITUD_VIGILANCIA` con SOLO las personas aprobadas; sin aprobadas no hay correo; no muestra estado general, conteos ni observaciones de otras personas. Ya no va en copia del aviso de decisión.
- **Un solo aviso de decisión (D-182):** aprobar un grupo y observar otro en la misma revisión deja un correo con la cabecera una vez («Además: …») y la tabla con el estado y la observación de cada persona.
- Evidencia: la cola `CAF_Correo_Pendiente` (tipo, solicitud, destinatarios, estado, intentos, error y fecha).

## Pasos
1. **Reconstruya la BD** con `restaurar_bd.ps1` (trae el script nuevo `14_ALTER_CORREOS_VIGILANCIA.sql`: agrega la columna `IDs_Personas` y el tipo `SOLICITUD_VIGILANCIA`). En una BD existente: ejecute `14_...sql` una vez y luego re-ejecute los SP `SP_CAF_SOLICITUD_DECISION_ALL.sql` y `SP_CAF_CORREO_ALL.sql`.
2. Copie los archivos respetando carpetas, compile y reinicie la web. No hay archivos que borrar.
3. Pruebe: solicitud de 3 personas → apruebe 2 y observe 1 con motivo → debe salir 1 correo a Vigilancia con 2 personas y 1 correo al solicitante (no 2). Compruebe en la pantalla de correos.

## Qué probé
- SQL (PostgreSQL 16, BD reconstruida desde cero con 01 a 14): HITO2 escritura 245/245 (nuevas pruebas de F; se actualizaron 4 que esperaban 3 avisos y Vigilancia en copia); HITO1 143/143; HITO2 lectura 202/202; HITO3 140/140 y 100/100; HITO4 138/138 y 113/113; PERMISOS 43/43.
- .NET: compila (0 errores, 0 advertencias) en una copia con sustitutos de Npgsql y MailKit.
- Arnés de consola con correo falso (29/29): el correo a Vigilancia lista solo aprobadas aunque la lista guardada incluya otras; sin aprobadas no se envía y queda con error (no como enviado); más las pruebas de hilo de la entrega E.

## Qué NO probé
- Envío real SMTP/Gmail ni `EnviadorSmtp` con MailKit; C# contra PostgreSQL real; HANA; pantallas en navegador (no cambié ninguna vista).

## Límites y decisiones abiertas
- El aviso a Vigilancia lista solo a las personas que esa decisión autoriza (no a todas las aprobadas hasta ahora) → P-109.
- La fusión de avisos de decisión usa una ventana de 2 minutos y solo si el aviso anterior sigue pendiente; si ya salió, el siguiente es otro correo.
- Los adjuntos (su prioridad) se hacen en la **Entrega J**, la siguiente.
