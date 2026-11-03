# Entrega H (2026-10-29, corrección del restaurador 2026-10-30) · Tipo de ingreso: Visitante externo, Contratista y Proveedor (deshabilitado)

Construye sobre las entregas C, D, D1, E, F y J (incluye sus archivos, completos). Si ya aplicó alguna, copiar encima no la daña.

## Qué trae
- **Selector «Tipo de ingreso» y «Sede»** al inicio del paso 1 del asistente (sin paso extra). **Visitante externo** y **Contratista** funcionan; **Proveedor** se ve deshabilitado con «Próximamente: pendiente de definición» y el servidor lo rechaza aunque lo fuercen (D-187).
- **Visitante externo:** igual que antes. Si la sede ofrece cochera (Magdalena) pregunta «¿Requiere cochera?» y, si es Sí, la placa (D-189).
- **Contratista (D-190):** empresa contratista, actividad(es) a realizar, fecha y hora del servicio, área de ejecución (zonas de la sede + detalle libre opcional), un contacto con varios teléfonos y varios correos, cochera/placa en Magdalena y varias personas. No arrastra campos de visitante (si cambia de tipo en pantalla, los del otro tipo no se envían).
- **Aprobación:** el mismo paso del Coordinador de la sede (D-191).
- **Se adaptan** el resumen del paso 3, el detalle, la edición (tipo y sede bloqueados), «Reutilizar», la revisión del Coordinador y los correos (rótulos «Servicio previsto», «Empresa contratista», «Actividad(es)», «Área de trabajo», contacto y cochera).
- **Sedes (D-192):** el selector solo ofrece sedes donde el usuario tiene permiso de solicitar. Magdalena trae su zona «Oficinas administrativas».

## Pasos
1. **Reconstruya la BD** con `restaurar_bd.ps1` (incluye `16_ALTER_TIPO_INGRESO.sql`). En una BD existente: ejecute `16_ALTER_TIPO_INGRESO.sql` **una sola vez** y luego re-ejecute estos 5 archivos: `SP_CAF_SOLICITUD_TIPO_INGRESO_ALL.sql` (nuevo), `SP_CAF_SOLICITUD_BASE_ALL.sql`, `SP_CAF_SOLICITUD_ALL.sql`, `SP_CAF_SOLICITUD_LECTURA_ALL.sql` y `SP_CAF_CORREO_PLANTILLA_ALL.sql`. (CREAR y EDITAR_DATOS cambiaron de firma: el script borra las anteriores.)
2. **Licencias en Magdalena:** en Usuarios, asigne al solicitante y al Coordinador sus licencias **en la sede Magdalena**. Sin eso, Magdalena no aparece o nadie recibe ni decide esas solicitudes.
3. Copie los archivos respetando carpetas, compile y reinicie la web **y el proceso de correo**. No hay archivos que borrar.
4. Pruebe:
   - Nueva solicitud como Visitante en VES (no debe preguntar cochera) y en Magdalena (sí).
   - Nueva solicitud como Contratista: actividad, área, contacto, cochera con placa; revise el resumen y el detalle.
   - Que Proveedor no se pueda elegir.
   - Como Coordinador: abra la solicitud del contratista y apruebe; revise el correo.
   - Editar placa o contacto de una solicitud aprobada: no debe reabrir la aprobación.

## Qué probé
- SQL (PostgreSQL 16, BD reconstruida desde cero con 01 a 16): HITO2 escritura **339/339** (sección N nueva: tipos, cochera, placa, contratista, Proveedor bloqueado, edición sin reabrir, versión JSON); HITO1 143/143; HITO2 lectura 202/202; HITO3 140/140 y 100/100; HITO4 138/138 y 113/113; permisos 43/43.
- .NET: compila (0 errores) en una copia con sustitutos de Npgsql y MailKit.
- Arnés de correo **52/52** (49 previos + 3 nuevos: contratista, rótulos, visitante sin cambios).
- Navegador (servicios simulados en memoria), escritorio 1280 px y celular 390 px, 23 comprobaciones cada uno: tipos y Proveedor deshabilitado, conservar datos al cambiar de tipo, validaciones del cliente, cambio de sede (zonas y cochera), placa normalizada, resumen, detalle, edición con tipo y sede bloqueados, revisión del Coordinador, «Reutilizar», visitante sin datos de contratista, sin errores de consola ni de CSP.

## Qué NO probé
- **Envío real por SMTP/Gmail** (MailKit no está en mi entorno), **Npgsql real** (los parámetros nuevos de C# contra PostgreSQL) y **HANA**.
- Permisos por rol en el navegador (se probaron en SQL; el navegador usó servicios simulados).
- (Corregido el 2026-10-30) `PRUEBAS_FASE1_HITO0.sql` daba 60/65 sobre la BD completa porque suponía una base sin los datos demo; la V1.1 los retira dentro de su transacción y da 65/65.

## Límites y decisiones abiertas
- Vigilancia sigue siendo solo de VES; Magdalena no tiene pantallas de portería (P-115).
- Los correos de contacto del contratista no se copian solos a los avisos (P-116).
- Proveedor, sus campos y su checklist siguen pendientes de definición (P-114).
- HANA: T-29 (regex, ALTER, firmas).

## Siguiente
I (checklist por tipo) y G (observaciones, pospuesta).

## Corrección del 2026-10-30 (solo `restaurar_bd.ps1` y `PRUEBAS_FASE1_HITO0.sql`)
- Las líneas «NOTICE: no existe ... omitiendo» **no son errores**: son avisos normales de los `DROP ... IF EXISTS` al re-crear procedimientos. Ahora se silencian.
- El restaurador ahora muestra la salida de cada prueba, marca en rojo las filas FALLA, imprime el total y, si psql se detiene por un error real, imprime su mensaje.
- HITO0 pasa 65/65 (V1.1). Copie ambos archivos y vuelva a ejecutar el restaurador con una base nueva (o `-SoloPruebas` sobre la actual).
- Si vuelve a detenerse, envíeme las **últimas 30 líneas** de la consola: el log que me llegó terminaba en `PRUEBAS_FASE1_HITO0.sql` sin ningún mensaje de error, así que no pude ver la causa real. No pude ejecutar PowerShell aquí: el script lo probé solo leyéndolo; las pruebas SQL sí las ejecuté.
