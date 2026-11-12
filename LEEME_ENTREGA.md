# Entrega 2A: «Verificación en grupo» en Control de accesos (D-235)

ZIP con SOLO lo nuevo o modificado respecto de la Entrega 1B. **Aplica antes la 1B** (comparte `site.css`).

> **BD:** sin cambios. Solo se agregó una prueba (grupo con 2 contratistas) en `PRUEBAS_FASE1_HITO2_ESCRITURA.sql`.

## Qué cambia
- Un botón «Verificación en grupo» por solicitud con 2 o más personas, a la derecha de «Documentos». Se quita la barra «Marcar:» y las casillas de las filas.
- Modal por pasos: acción → personas (con atajos) → checklist/confirmación. Sirve para proveedor, visitante, contratista y tipos futuros, en ingreso (verificar / validar) y en salida.
- El acceso directo del calendario de proveedores abre este modal; en entregas recepcionadas o cerradas, directo en «Registrar salida» con todos los que están dentro marcados.

## Qué probé
- SQL: escritura 775/775 (PostgreSQL 16, base nueva), con la prueba nueva de ingreso y salida en grupo de 2 contratistas.
- Navegador (página de prueba con datos simulados, 1280 y 390 px, sin errores de JS ni desborde): botón solo en solicitudes con 2+ personas, pasos 1 y 2, personas no elegibles deshabilitadas, y el acceso directo abre «Registrar salida» con los 2 marcados.

## Qué NO probé
- El paso 3 (checklist y envío) contra el servidor real: reutiliza las funciones y los endpoints que ya existían, pero no corrí la aplicación completa.
- Ingreso en grupo de visitantes con roles de checklist distintos (ver limitación en D-235).
- Etiqueta de rol en Vigilancia.
