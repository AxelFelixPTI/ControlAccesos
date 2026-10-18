# Entrega del 2026-10-18 · Login (inicio de sesión, contraseñas y permisos)

Este zip trae **solo los archivos nuevos o modificados**, con la estructura de tu repositorio: cópialos encima. No hay cambios de base de datos.

## Qué trae
- **Nuevos:** `Dto_Auth.cs`, `ISrv_Auth.cs`, `Srv_Auth.cs`.
- **Modificados:** `IRepo_Usuario.cs`, `Repo_Usuario.cs` (7 métodos nuevos), `ServiciosControlAccesos.cs` (registra `ISrv_Auth`) y `src\Consola\Program.cs` (3 comandos nuevos).
- `DECISIONES_ARRANQUE.md` (se agregan D-89 a D-92, P-53 a P-55, T-11), `WORKING_CONTEXT.md`. `restaurar_bd.ps1` sin cambios.

## Qué hace
- **Iniciar sesión:** compara la contraseña con su hash, bloquea 15 minutos tras 5 intentos fallidos y devuelve licencias y permisos del usuario. No revela si el correo existe.
- **Token de un solo uso** para definir contraseña (en la base solo queda su hash), **cambiar contraseña** y **verificar un permiso**.

## Pasos en tu equipo
1. Copia los archivos, **Rebuild All** (10 proyectos).
2. Si aún no lo hiciste, crea tu administrador:
```powershell
dotnet run --project src/Consola -- crear-admin
```
3. Prueba el login con ese usuario:
```powershell
dotnet run --project src/Consola -- login
```
Esperado: «Bienvenido/a …», licencia `LIC_CAF_ADMIN en VES` (o la sede que elegiste) y la lista de permisos.
4. Prueba una contraseña equivocada 5 veces: la quinta debe decir que la cuenta quedó bloqueada.
5. Prueba el token (opcional): `emitir-token` (te da un código) y luego `definir-password` (pega el código y pon una contraseña nueva).

Si algo falla, pégame el mensaje tal cual.

## Siguiente
Capa web: arranque, inicio de sesión con cookie y pantallas.
