# Entrega del 2026-10-19 · Personal y Usuarios y roles

Solo archivos nuevos o modificados, con la estructura del repositorio: cópialos encima. No hay cambios de base de datos ni de proyectos (no hace falta tocar el .slnx).

## Qué trae
- **Personal** (menú Administración): catálogo del personal del grupo. Buscar por nombre, documento o cargo; filtrar por área; crear y editar; activar/desactivar.
- **Usuarios y roles**: crear usuarios vinculados a una persona de Personal o externos (con empresa); asignar uno o varios roles en VES; buscar y filtrar por rol; activar/desactivar.
- **Enlace para definir contraseña**: al crear un usuario aparece un enlace de un solo uso (vale 3 días). Tú se lo entregas y el usuario define su propia contraseña. En un usuario existente, «Generar enlace de contraseña» crea otro y anula el anterior.
- Pantallas de definir contraseña (`/Cuenta/DefinirPassword`) y de enlace inválido.
- Archivos: servicios, repositorios y DTOs de Personal y de gestión de usuarios; `PersonalController`, `UsuariosController`, `CuentaController`; vistas y JavaScript de ambas pantallas; menú; `site.css`; documentos (D-106 a D-109, P-61 a P-63).

## Pasos
1. Copia los archivos y haz Rebuild All. Arranca la web y recarga con Ctrl+F5.
2. Entra con tu administrador. En el menú aparecen **Usuarios y roles**, **Catálogos** y **Personal**.

## Qué probar
1. **Personal**: «+ Nueva persona» con datos de prueba (DNI de 8 dígitos y correo). Aparece en la tabla. Repite el mismo documento: dice que ya existe.
2. **Usuarios y roles**: «+ Nuevo usuario», elige esa persona en «Personal vinculado» (los datos vienen de Personal), marca un rol y crea. Sale el enlace.
3. Abre el enlace en una ventana privada, define una contraseña (mínimo 10 caracteres) e ingresa con el correo de esa persona. Debes ver solo el menú de su rol.
4. Un usuario externo: deja «Sin vínculo», completa nombres, documento, correo y empresa.
5. Intenta quitarte el rol de administrador o desactivarte: debe impedírtelo mientras seas el único administrador.

Los datos de prueba quedan en tu base; puedes desactivarlos o reiniciar con `restaurar_bd.ps1`.

## Siguiente
Solicitud de visita y su aprobación.
