# Entrega del 2026-10-19 · Catálogos y botón de tema

Solo archivos nuevos o modificados, con la estructura del repositorio: cópialos encima. No hay cambios de base de datos ni de proyectos (no hace falta tocar el .slnx).

## Qué trae
- **Pantalla Catálogos** (menú Administración): zonas de VES, motivos de visita, tratamientos de desviación y tipos de incidencia. Crear, editar y desactivar. «Otro» es fijo.
- **Botón de tema** (luna/sol) en la barra superior derecha. Por defecto es claro; recuerda tu elección en el navegador.
- Archivos nuevos: `Controllers/CatalogosController.cs`, `Models/CatalogoModelos.cs`, `Seguridad/ExigirPermisoAttribute.cs`, `Views/Catalogos/Index.cshtml`, `wwwroot/js/caf.js`, `wwwroot/js/tema.js`, `wwwroot/js/catalogos/catalogos.js`.
- Modificados: `WebApp.cs`, `Menu/MenuCaf.cs`, `Views/Shared/_Layout.cshtml`, `wwwroot/css/site.css`, `wwwroot/js/layout.js`, y los documentos (D-101 a D-104, P-58 a P-60).

## Pasos
1. Copia los archivos y haz Rebuild All. Arranca la web y recarga con Ctrl+F5.
2. Entra con tu administrador y abre **Catálogos** en el menú.

## Qué probar
- Se ven las 7 zonas, 4 motivos (+ Otro), 5 tratamientos (+ Otro) y los tipos de incidencia.
- «+ Nueva zona»: escribe un nombre, elige tipo y marca SCTR/EPP; al guardar aparece en la tabla.
- Escribe un nombre que ya existe: dice «Ya existe uno con ese nombre.»
- Tratamiento sin efecto al ingreso ni a la salida: lo rechaza.
- Editar un elemento y desmarcar «Activo»: queda en gris con «inactivo».
- Botón luna: cambia a oscuro; al recargar se mantiene.

Los datos de prueba que crees quedan en tu base; puedes desactivarlos o reiniciar con `restaurar_bd.ps1`.

## Siguiente
Trabajadores y Usuarios y roles.
