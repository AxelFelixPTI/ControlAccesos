# Entrega del 2026-10-17 · Hito 3, capas .NET

Este zip trae **solo los archivos nuevos o modificados**, con la estructura de tu repositorio: cópialos encima. La base de datos no cambia.

## Qué trae (todo dentro de `src/`)
- **DTOs** (`Application.DTOs`): 11 de respuesta (sacados de las columnas reales de cada rutina) y `Dto_Porteria_Entradas.cs` con los formularios y filtros (ingreso, salida, desviación, respaldo, bitácora). Los botones (`Puede_...`) salen como `bool`.
- **Repositorios** y sus interfaces: `Repo_Porteria` (checklist, ficha, bitácora, detalle, ingreso, salida, «no se presentó»), `Repo_Respaldo` y `Repo_Desviacion` (listado, detalle, contadores, listas desplegables, conformidad).
- **Servicios** y sus interfaces: uno por repositorio. Solo validan el formulario; las reglas viven en la base (D-40, D-63).
- **Herramientas** (`Docs_BD/_tools`): `gen_capas_porteria.py` y `firmas_rutinas_hito3.txt`.
- `WORKING_CONTEXT.md` actualizado y `restaurar_bd.ps1` (sin cambios desde la entrega anterior).

## Qué comprobar en tu equipo
```powershell
dotnet build
```
Esperado: 0 errores (necesita el paquete Npgsql). En mi entorno compila con 0 errores y 0 avisos, y las 16 llamadas a rutinas resuelven contra la base.

## Aún no
Registro de dependencias y pantallas web: van al final, después del Hito 4.
