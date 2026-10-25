# Guía · Primer despliegue en tu red local (tu PC como servidor)

Objetivo: que otras computadoras y celulares conectados a la misma red (Wi‑Fi o cable) abran el sistema en tu PC, antes de publicarlo en internet.

> Es una prueba en red de confianza: va por **HTTP** (sin cifrar). Está bien para probar dentro de tu red; **no** se expone a internet así. Antes de internet hay que poner HTTPS (paso 10).

## 1. Requisitos en tu PC
- .NET 10 (ya lo tienes por Visual Studio) y PostgreSQL con la base restaurada.
- La PC y los equipos de prueba en la **misma red**.

## 2. Publicar la aplicación
En PowerShell, en la carpeta del repositorio:
```powershell
dotnet publish src/Web.ControlAccesos -c Release -o C:\ControlAccesos\app
```
Genera la web lista para ejecutar en `C:\ControlAccesos\app` (incluye `wwwroot`).

## 3. Configuración (sin claves en el repositorio)
Crea `C:\ControlAccesos\app\appsettings.Local.json` (ver `GUIA_CORREO.md`, paso 4) con la base, la clave de Postgres, el correo y `UrlBase` con la IP del paso 4. PostgreSQL se queda en `localhost`: **no abras el puerto 5432** a la red.

## 4. Fijar la dirección de tu PC
1. Averigua la IP: `ipconfig` → «Dirección IPv4» (ej. `192.168.1.50`).
2. Que no cambie: en el router reserva esa IP para tu PC (reserva DHCP) o ponla fija en Windows. Si cambia, los enlaces de los correos dejan de servir.
3. Pon en `appsettings.Local.json`: `"UrlBase": "http://192.168.1.50:5080"`.

## 5. Ejecutar escuchando en la red
```powershell
cd C:\ControlAccesos\app
$env:ASPNETCORE_ENVIRONMENT = "Production"
$env:ASPNETCORE_URLS = "http://0.0.0.0:5080"
.\Web.ControlAccesos.exe
```
`0.0.0.0` significa «aceptar conexiones de cualquier equipo de la red» (con el valor por defecto `localhost` solo entras tú).

## 6. Abrir el puerto en el Firewall de Windows
PowerShell **como administrador**:
```powershell
New-NetFirewallRule -DisplayName "Control de Accesos 5080" -Direction Inbound -Protocol TCP -LocalPort 5080 -Action Allow -Profile Private
```
La red debe estar marcada como **Privada** (Configuración → Red e Internet → propiedades de la red). Para quitar la regla: `Remove-NetFirewallRule -DisplayName "Control de Accesos 5080"`.

## 7. Probar
1. En tu PC: `http://localhost:5080` → inicia sesión.
2. En otra PC o celular de la misma red: `http://192.168.1.50:5080`.
3. Si no abre: ¿misma red? ¿regla del firewall? ¿la app sigue corriendo? ¿la IP cambió? (`ipconfig`). Algunas redes de invitados bloquean la comunicación entre equipos.
4. Crea una solicitud con `RedirigirA` activo y revisa que el botón **Ver solicitud** del correo abra desde el celular.

## 8. Mantenerlo funcionando
- La app corre mientras la ventana de PowerShell esté abierta; si cierras o la PC se duerme, deja de responder. Para pruebas largas: Configuración → Energía → «Nunca» suspender en corriente.
- Para que arranque sola se puede usar el Programador de tareas de Windows («al iniciar sesión», ejecutando el comando del paso 5). Instalarla como servicio o en IIS se decide al pasar a un servidor.

## 9. Datos y seguridad en la prueba
- Los usuarios demo tienen contraseñas conocidas: úsalos solo en tu red.
- Haz una copia de la base antes de cargar datos reales (`pg_dump`).
- Las claves van solo en `appsettings.Local.json` (no se sube a git).

## 10. Antes de internet (más adelante)
Certificado HTTPS (la cookie de sesión pasa a «solo HTTPS»), un nombre de dominio, servidor o IIS con arranque automático, `UrlBase` con la dirección definitiva, copias de seguridad programadas y revisión de seguridad con TI.
