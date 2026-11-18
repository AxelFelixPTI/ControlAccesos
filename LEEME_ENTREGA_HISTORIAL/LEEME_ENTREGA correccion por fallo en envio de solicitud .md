# Entrega 2C-2l: corrección urgente — no se podía registrar ninguna solicitud

Solo web (1 archivo JS). Sin BD, sin SP, sin recompilar el servidor (basta copiar el archivo; si el navegador guarda caché, Ctrl+F5).

## Qué pasaba
Al pulsar «Enviar» en «Nueva solicitud» la consola mostraba `Uncaught ReferenceError: transportistas is not defined` (`nueva.js`, línea 180) y no se creaba nada. Afectaba a **todos los tipos** (visitante, contratista y proveedor). Los dos avisos rojos de `browserLink` (Content Security Policy) son de Visual Studio y no tienen relación.

## Causa
Error mío en una entrega anterior: la lista de conductores se renombró a `conductores`, pero el envío seguía usando `transportistas`.

## Arreglo
`wwwroot/js/solicitudes/nueva.js` línea 180: `transportistas: conductores`.

## Qué probé y qué no
- Probado en navegador (Chromium) con datos simulados: recorrí el asistente de visitante externo completo (datos, persona, revisión, enviar): la petición de crear sale con todos los datos y la pantalla pasa al detalle. Además pasé ESLint (`no-undef`) por todos los JS del proyecto: no hay otras variables sin definir.
- **No probado:** el envío de contratista y de proveedor en navegador (el arreglo es el mismo punto de código y lo usan los tres tipos, pero no los recorrí); con su base real.
