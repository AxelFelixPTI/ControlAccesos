# Guía · Correo de la solicitud (Gmail de prueba y cuenta corporativa)

Entrega del 2026-10-24. Explica cómo salen los correos, cómo configurar la cuenta `trianon.accesos@gmail.com` y cómo probarlo sin molestar a nadie.

## 1. Quién recibe cada aviso (visitante externo)

| Momento | Para | Copia (CC) |
|---|---|---|
| El solicitante envía la solicitud | Coordinador (quien decide el primer paso) | Solicitante + correos adicionales que puso en el asistente |
| Solicitud modificada (vuelve a revisión) | Coordinador | Solicitante + adicionales |
| El coordinador decide (aprueba, observa o rechaza) | Solicitante | Aprobadores + adicionales; **Vigilancia solo cuando la solicitud queda Aprobada** |
| Persona agregada o corregida | Quien debe decidir ese paso | (igual que hoy) |
| Solicitud cancelada con personas ya autorizadas | Aprobadores y Vigilancia | Solicitante + adicionales |

Cada correo trae todos los datos de la solicitud (código, estado, sede, fecha, empresa, responsable, motivo, zonas, solicitante, requisitos, personas con su estado), los «Detalles adicionales» que escribió el solicitante y el botón **Ver solicitud**.

## 2. Hilo de mensajes

- El aviso de **solicitud nueva** es el correo raíz. Los demás avisos de esa solicitud salen con el **mismo asunto precedido de «Re: »** y con las cabeceras estándar `In-Reply-To` y `References` apuntando a la raíz.
- Como siempre van a la misma gente (solicitante, aprobadores y copias), en Gmail y Outlook se ven como una conversación, con todos al tanto.
- **Lo que hay que probar en un envío real:** Gmail a veces reemplaza el identificador interno (`Message-ID`) de lo que se envía por SMTP. Si lo hace, el agrupamiento lo sostiene igual el asunto idéntico («Re: …») y los mismos participantes, que es lo que Gmail usa para armar conversaciones. Se verificó con un servidor SMTP local que las cabeceras salen bien; falta confirmarlo contra Gmail (ver P-89).
- Limitación: si alguien pulsa «Responder a todos», su respuesta llega a la casilla del sistema, que nadie lee. El correo lo dice al pie. La aprobación se hace siempre dentro del sistema.

## 3. Configurar la cuenta de Gmail

1. Crea la cuenta `trianon.accesos@gmail.com`.
2. Activa la **verificación en dos pasos** (Cuenta de Google → Seguridad).
3. En Seguridad busca **Contraseñas de aplicaciones**, crea una llamada «Control de Accesos» y copia la clave de 16 letras. **No la pegues en el chat ni en un archivo que se suba a git.**
4. Crea el archivo `appsettings.Local.json` junto a la web (no se sube a git):

```json
{
  "CAF_DB_USUARIO": "postgres",
  "CAF_DB_CLAVE": "TU_CLAVE_DE_POSTGRES",
  "CAF_DB_BASE": "accesos_piloto_prueba",
  "Correo": {
    "Modo": "Smtp",
    "Host": "smtp.gmail.com",
    "Puerto": 587,
    "UsarSsl": true,
    "Usuario": "trianon.accesos@gmail.com",
    "Clave": "LA_CLAVE_DE_16_LETRAS",
    "Remitente": "trianon.accesos@gmail.com",
    "NombreRemitente": "Control de Accesos",
    "UrlBase": "http://localhost:5080",
    "RedirigirA": "tu.correo.personal@gmail.com"
  }
}
```

5. **Modo prueba:** mientras `RedirigirA` tenga un valor, todos los correos llegan **solo a esa dirección**, con un aviso arriba que dice a quién habrían llegado. Úsalo hasta que los usuarios reales estén cargados; después déjalo vacío.
6. Reinicia la web. El envío corre dentro de la web cada 30 segundos (`Correo:IntervaloSegundos`).

### Variables de entorno (alternativa recomendada para las claves)
Las variables de entorno **ganan** sobre `appsettings.json` y sobre `appsettings.Local.json`. Se escriben con doble guion bajo, por ejemplo `Correo__Clave`, `Correo__Usuario`, `Correo__Remitente`, `Correo__RedirigirA`, `CAF_DB_CLAVE`. Después de crearlas hay que reiniciar Visual Studio. No dejes en el `Local.json` valores de ejemplo de lo que vayas a poner como variable.

## 4. Qué es `UrlBase` (la «dirección»)

Es la dirección donde la gente abre el sistema; con ella se arma el botón **Ver solicitud**. En desarrollo: `http://localhost:5080`. En la prueba en red: `http://IP-DE-TU-PC:5080` (ver `GUIA_DESPLIEGUE_RED.md`). Al publicar en internet será la dirección definitiva (por ejemplo `https://accesos.grupotrianon.com`).

## 5. Pasar a la cuenta corporativa (`@grupotrianon.com`, dominio Google)

Solo cambian `Usuario`, `Clave` (nueva contraseña de aplicación) y `Remitente`; el servidor sigue siendo `smtp.gmail.com`. TI debe permitir contraseñas de aplicación en Google Workspace o indicar el método de la empresa (P-51).

## 6. Límites y cuidados

- Una cuenta de Gmail gratuita envía hasta unos 500 destinatarios por día; Workspace, más. Para el piloto sobra.
- Si un envío falla se reintenta hasta `MaxIntentos` (5); el administrador puede reencolarlo desde la bandeja de correos.
- Los usuarios de demostración tienen correos ficticios (`@ejemplo.pe`): con el envío real y sin `RedirigirA` esos avisos rebotarían.
- Para ver cómo se ve cada correo sin base de datos: `dotnet run --project src/Consola -- vista-previa-correos carpeta` genera ejemplos HTML. Ya hay unos en `vista_previa_correos/`.
