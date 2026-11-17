# Entrega 2C-2k: buscador en proveedores, «Editar usuario» en ventana y listados móviles

Solo web (vista, JS y CSS). **No hay scripts de BD ni cambios de SP.** Aplicar sobre lo ya entregado (cumulativo con 2C-2i y el demo integral).

## Qué cambia
- **Panel de proveedores:** un campo pequeño «OC, empresa, placa…» dentro de la fila de filtros. Busca por OC, empresa (proveedor o transportista), conductor (nombre o documento) y placa; sin tildes y sin importar guiones o espacios en la placa. Funciona en Mes, Semana y Día, se recuerda en la dirección y «Quitar filtros» lo limpia.
- **Usuarios y roles:** «Editar usuario» y «+ Nuevo usuario» abren una **ventana emergente** (en celular, pantalla completa con Cancelar/Guardar siempre visibles). Ya no hay panel al final de la lista.
- **Listados en celular** (usuarios, personal, catálogos y demás tablas): tarjetas más bajas: título con el nombre, cada dato en una línea (etiqueta a la izquierda) y el botón Editar como pie a todo el ancho.

## Archivos
Web: `Views/Usuarios/Index.cshtml`, `wwwroot/js/usuarios/usuarios.js`, `wwwroot/js/proveedores/proveedores.js`, `wwwroot/css/site.css`, `wwwroot/css/proveedores.css`. Docs: `DECISIONES_ARRANQUE.md` (D-249), `WORKING_CONTEXT.md`.

## Qué probé y qué no
- Probado: compila (0 errores); en navegador (Chromium, celular 390 px y escritorio) con datos simulados: el buscador acierta por OC (con y sin «OC-»), empresa, transportista, conductor, documento y placa (con y sin guion/espacio) y da 0 resultados cuando no hay; «Quitar filtros» lo limpia; el modal de usuario abre, guarda, cierra con Esc y muestra los roles marcados; sin errores de consola. Revisé capturas del buscador, de la lista y del modal en celular.
- **No probado:** con su base y navegador reales (Brave en su celular); modo oscuro; el resto de tablas del sistema (Personal, Catálogos, Incidencias, etc.) con el nuevo estilo de tarjeta: el CSS es común, pero conviene que las revise y me diga cuáles se ven raras.
