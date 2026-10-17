# Entrega del 2026-10-17 · Hito 2, capas .NET

Este zip trae **solo los archivos nuevos o modificados**, con la estructura de tu repositorio: cópialos encima.

## Qué trae (todo dentro de `src/`)
- **DTOs** (`Application.DTOs`): 11 de respuesta (sacados de las columnas reales de cada rutina) y `Dto_Solicitud_Entradas.cs` con los formularios y filtros. Los botones (`Puede_...`) salen como `bool`.
- **Repositorios** y sus interfaces: `Repo_Solicitud` (mis solicitudes, bandeja, contadores, detalle, personas, ruta, historial, versiones, crear, editar, cancelar), `Repo_Solicitud_Persona`, `Repo_Solicitud_Decision`, `Repo_Solicitud_Vigilancia` y `Repo_Tipo_Acceso_Paso`.
- **Servicios** y sus interfaces: uno por repositorio. Solo validan el formulario; las reglas viven en la base (D-40).
- **Modificados:** `EjecutorSp` V1.1 (escrituras que devuelven varios valores, p. ej. ID y código al crear) y `RepoHelpers` V1.1 (`AddDate`).
- **Herramientas** (`Docs_BD/_tools`): `gen_capas_solicitud.py`, `firmas_rutinas_hito2.txt` y `verificar_llamadas.py` V1.1.
- `restaurar_bd.ps1` (sin cambios), `WORKING_CONTEXT.md` actualizado.

## Qué comprobar en tu equipo
Compilar la solución (necesita el paquete Npgsql, que mi entorno no puede descargar):
```powershell
dotnet build
```
Esperado: 0 errores. La base de datos no cambia en esta entrega.

## Aún no
Registro de dependencias y pantallas web: van al final, después de los Hitos 3 y 4.
