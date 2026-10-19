# Entrega del 2026-10-19 · Rediseño de la web con los mockups

Solo archivos nuevos o modificados, con la estructura del repositorio: cópialos encima. No hay cambios de base de datos.

## Qué cambia
- La web ahora usa el diseño de los mockups: lateral navy, acento verde-azulado, tarjetas blancas, chips y botones del prototipo 1.1, con la paleta de la primera fase. El «casi todo azul» venía de mi hoja de estilos anterior.
- Pantallas rehechas: ingreso, cambiar contraseña, inicio, sin acceso y error. Menú agrupado como el prototipo (Solicitante, Coordinador, Vigilancia, Administración) y filtrado por permisos.
- Con cambio de contraseña obligatorio ya no se ve el menú lateral.
- Archivos: `wwwroot/css/site.css`, `wwwroot/js/layout.js` (nuevo, abre el menú en pantallas angostas), `Views/Shared/_Layout.cshtml`, vistas de Cuenta e Inicio, `Menu/MenuCaf.cs`, y los documentos (D-98 a D-100; P-56 resuelta; P-57 postergada).

## Pasos
1. Copia los archivos y haz Rebuild All.
2. `dotnet run --project src/Web.ControlAccesos` y abre http://localhost:5080
3. Si el navegador muestra el estilo anterior, recarga con Ctrl+F5.

## Siguiente
Pantallas de negocio con la funcionalidad del prototipo 1.1, empezando por Catálogos.
