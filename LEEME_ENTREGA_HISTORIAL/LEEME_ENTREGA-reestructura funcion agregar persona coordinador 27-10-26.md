# Entrega del 2026-10-27 · C · Corrección de emergencia del Coordinador (P-98)

Solo archivos nuevos o modificados, con la estructura del repositorio: cópialos encima. **Trae un script de tablas nuevo (`13_...`) y cambia procedimientos**, así que la base se reconstruye.

## Qué trae
- **Se quita «+ Agregar persona (queda aprobada)»** de la revisión normal. Mientras una solicitud está por decidir, el Coordinador solo aprueba, observa o rechaza; las personas las modifica el solicitante.
- **Corrección de emergencia** (solo con la solicitud `Aprobada` o `Aprobada parcial` y **hasta el día de la visita**; si la fecha ya pasó no se puede):
  - **+ Agregar persona (emergencia)**: la persona queda autorizada de inmediato.
  - **Quitar (emergencia)**: solo a quien está autorizado y **aún no ingresó**. Si ya ingresó, no se quita: Vigilancia registra su salida con una observación. Tampoco se quita a la **única** persona de la solicitud (el solicitante la cancela).
  - **El sustento es obligatorio** en ambas. Queda en el historial de la solicitud y en el correo.
- **Vigilancia lo ve al instante** (sus listas leen a las personas autorizadas).
- **Correo nuevo «Corrección de emergencia»**: Para = solicitante y Vigilancia; Copia = aprobadores y los correos adicionales del asistente (cambiarlo es una línea en cada procedimiento).
- Nada se borra: la persona quitada pasa a «Retirada».
- Archivos: `SP_CAF_SOLICITUD_PERSONA_ALL.sql` (2 procedimientos nuevos; borra el anterior `..._AGREGAR_APROBADA`), `SP_CAF_SOLICITUD_BASE_ALL.sql`, `SP_CAF_SOLICITUD_LECTURA_ALL.sql`, **`13_ALTER_CORREOS_CORRECCION.sql` (nuevo)**, `PRUEBAS_FASE1_HITO2_ESCRITURA.sql`, capas .NET (`IRepo_`/`Repo_`/`ISrv_`/`Srv_Solicitud_Persona`), `PlantillaCorreo.cs`, `CoordinacionController`, `CoordinacionModelos`, `Coordinacion/Index.cshtml`, `coordinacion.js` y documentos (D-169 a D-175, P-106, T-25).

## Archivos a borrar
Ninguno. El procedimiento viejo lo elimina el propio archivo de procedimientos.

## Pasos
1. Copia los archivos encima del repositorio.
2. Reconstruye la base **vacía** (el script 13 se ejecuta una sola vez y se niega a correr dos veces):
   `.\restaurar_bd.ps1 -Database <base_nueva> -Crear` (con las variables de entorno de siempre; no se pasan claves por el chat).
   (Camino alternativo, no probado por mí: en tu base actual ejecuta `13_ALTER_CORREOS_CORRECCION.sql` una vez y luego los tres archivos `SP_CAF_SOLICITUD_*_ALL.sql`.)
3. Rebuild All en Visual Studio, arranca la web y recarga con Ctrl+F5.

## Qué probar
1. Solicitante crea una solicitud para **hoy** con 2 personas; Coordinador la **aprueba**. Abre «Ver»: aparece el bloque amarillo con «+ Agregar persona (emergencia)» y «Quitar (emergencia)» en cada persona.
2. **Agregar** a otra persona sin sustento: debe pedirlo. Con sustento: aparece como Autorizada, el historial dice «corrección de emergencia» con el motivo, y en Vigilancia ya figura.
3. **Quitar** a una que no ha ingresado, con sustento: pasa a Retirada y desaparece de Vigilancia.
4. En Vigilancia registra el ingreso de otra persona y vuelve a la revisión: **no** ofrece «Quitar» y explica que Vigilancia registra su salida.
5. Con una sola persona autorizada, intenta quitarla: lo rechaza y manda a cancelar.
6. Solicitud **pendiente** o con **fecha pasada**: no aparece ninguna acción de emergencia.
7. Revisa los correos (en modo prueba salen todos a `RedirigirA`; el aviso del correo dice a quién habría llegado y en copia a quién).

## Qué se probó y qué no
- **Probado (PostgreSQL 16, base reconstruida desde cero con scripts 01 a 13):** Hito 1 143/143; **Hito 2 escritura 227/227** (33 casos nuevos de la corrección de emergencia); Hito 2 lectura 202/202; Hito 3 140/140 y 100/100; Hito 4 138/138 y 113/113; permisos 43/43. Hito 0: 60 de 65; los 5 fallos son los conocidos por el seed demo 11, no vienen de este cambio.
- **Probado:** compilación completa de la solución, 0 errores y 0 avisos; pantalla de Coordinación en navegador (Playwright, 1280 px y 390 px) con servicios simulados: bloque y botones solo donde corresponden, sustento obligatorio, agregar y quitar, historial, sin errores de consola ni de política de seguridad.
- **No probado:** el código C# contra PostgreSQL real (Npgsql) ni el envío real con Gmail (para compilar sustituí esas dos librerías en una copia de trabajo; no van en esta entrega); PostgreSQL 18; HANA (T-25); tu red.

## Para confirmar con Sandra (P-106)
Quién va en copia; si «Aprobada parcial» también admite corrección; qué hacer si es la única persona; si se puede quitar a quien ya salió.

## Siguiente
**Entrega D**: móvil (P-96) y cambio de rol desde el perfil (P-97). Después **E**: hilo de correo y «responder a todos» (P-95).
