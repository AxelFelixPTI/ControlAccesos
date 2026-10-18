# Entrega del 2026-10-18 · Paso 1 de arranque (dependencias, correos, consola)

Este zip trae **solo los archivos nuevos o modificados**, con la estructura de tu repositorio: cópialos encima.

## Qué trae
- **3 proyectos nuevos en `src/`:** `Infrastructure.ExternalServices` (envío de correos, hash de contraseñas), `Composicion` (registro de dependencias) y `Consola` (comandos de operación).
- **Archivos nuevos en proyectos existentes:** `Dto_Usuario_Crear`, `ISrv_Usuario`, `IHasherPassword`, `IRepo_Usuario`, `Repo_Usuario`, `Srv_Usuario`.
- **`src/ControlAccesos.slnx`** modificado (agrega los 3 proyectos).
- `DECISIONES_ARRANQUE.md` (D-86 a D-88, P-51, P-52, T-10) y `WORKING_CONTEXT.md`. `restaurar_bd.ps1` sin cambios.
- No hay cambios de base de datos.

## Pasos en tu equipo
1. Copia los archivos y abre `src\ControlAccesos.slnx` en Visual Studio → **Rebuild All** (debe compilar 10 proyectos; Npgsql ya lo tienes en `Infrastructure.Persistence`).
2. Copia `src\Consola\appsettings.Local.json.ejemplo` como `src\Consola\appsettings.Local.json` y pon tu clave real de PostgreSQL. **Agrega la línea `appsettings.Local.json` a tu `.gitignore`** para no subir la clave a git.
3. En PowerShell, desde la carpeta del repositorio:
```powershell
dotnet run --project src/Consola -- probar
dotnet run --project src/Consola -- crear-admin
dotnet run --project src/Consola -- enviar-correos
```
- `probar`: lee los 12 catálogos y la cola de correos; es la **primera ejecución real de C# contra PostgreSQL**. Esperado: 13 líneas `OK`.
- `crear-admin`: crea tu primer usuario administrador (te pregunta los datos y la contraseña, mínimo 10 caracteres).
- `enviar-correos`: una vuelta de envío (en modo `Simulado` solo escribe en pantalla). `servir` lo deja corriendo en segundo plano.

Si `probar` falla, pégame el mensaje tal cual.

## Siguiente
Servicio de login y, al final, las pantallas web.
