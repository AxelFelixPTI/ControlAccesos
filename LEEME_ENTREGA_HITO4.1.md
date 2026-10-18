# Entrega del 2026-10-18 · Hito 4, capas .NET

Este zip trae **solo los archivos nuevos o modificados**, con la estructura de tu repositorio: cópialos encima. La base de datos no cambia.

## Qué trae (todo dentro de `src/`)
- **DTOs** (`Application.DTOs`): 10 de respuesta (sacados de las columnas reales de cada rutina) y 3 archivos de entradas (`Dto_Incidencia_Entradas`, `Dto_Correo_Entradas`, `Dto_Reporte_Entradas`) con formularios y filtros. Los botones (`Puede_Decidir`) salen como `bool`.
- **Repositorios** y sus interfaces: `Repo_Incidencia` (registrar, decidir, listar, detalle, personas, contadores, buscar personas), `Repo_Correo` (pendientes, marcar enviado/error, listar, reencolar) y `Repo_Reporte` (accesos, resumen diario, autorizados por zona).
- **Servicios** y sus interfaces: uno por repositorio. Solo validan el formulario; las reglas viven en la base (D-40).
- **Herramientas** (`Docs_BD/_tools`): `gen_capas_incidencias.py` y `firmas_rutinas_hito4.txt`.
- `WORKING_CONTEXT.md` actualizado y `restaurar_bd.ps1` (sin cambios desde la entrega anterior).

## Qué comprobar en tu equipo
```powershell
dotnet build
```
Esperado: 0 errores (necesita el paquete Npgsql). En mi entorno compila con 0 errores y 0 avisos, y las 15 llamadas a rutinas resuelven contra la base.

## Nota para el envío de correos
`Srv_Correo.PendientesListarAsync`, `MarcarEnviadoAsync` y `MarcarErrorAsync` solo funcionan con el usuario del sistema (`0`). El servicio en segundo plano que envía correos se construye aparte (con el registro de dependencias).

## Aún no
Registro de dependencias, servicio de envío de correos y pantallas web: van al final.
