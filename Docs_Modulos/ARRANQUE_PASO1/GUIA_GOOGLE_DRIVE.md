# Guía paso a paso: conectar ControlAccesos a Google Drive (cuenta trianon.accesos@gmail.com)

Qué se logra: los adjuntos de solicitudes y los documentos de ingreso nuevos se guardan en una carpeta de Drive de esa cuenta, en vez de la base de datos. La base solo anota dónde quedó cada archivo. La aplicación crea y usa **su propia carpeta** (por defecto `ControlAccesos_Adjuntos`) y solo puede ver lo que ella misma sube (permiso `drive.file`).

Tiempo aproximado: 20–30 minutos. No hay que instalar nada en Google. Las claves **nunca** se escriben en el chat ni en el repositorio: van en variables de entorno del servidor.

> Los nombres de menús de Google Cloud cambian de vez en cuando. Si algo no aparece donde se indica, use el buscador de la parte superior de la consola (escriba el nombre del servicio).

## Parte 1 · Crear el proyecto en Google Cloud

1. Entre a https://console.cloud.google.com con la cuenta **trianon.accesos@gmail.com**. Si es la primera vez, acepte los términos.
2. Arriba a la izquierda, junto al logo, abra el selector de proyectos → **Proyecto nuevo**.
3. Nombre: `ControlAccesos` → **Crear**. Espere unos segundos y compruebe que quedó seleccionado arriba.

## Parte 2 · Activar la API de Drive

4. Menú ☰ → **APIs y servicios** → **Biblioteca**.
5. Busque **Google Drive API** → ábrala → **Habilitar**.

## Parte 3 · Pantalla de consentimiento (OAuth)

6. **APIs y servicios** → **Pantalla de consentimiento de OAuth** (en el menú nuevo aparece como **Google Auth Platform** → **Branding / Audiencia / Acceso a los datos**).
7. Tipo de usuario / audiencia: **Externo** (una cuenta @gmail.com personal no permite «Interno»). → Crear.
8. Datos de la aplicación: nombre `ControlAccesos`, correo de asistencia y correo de contacto del desarrollador: `trianon.accesos@gmail.com`. Guardar.
9. **Acceso a los datos** (Scopes) → **Agregar o quitar permisos** → marque solo `.../auth/drive.file` («Ver y administrar los archivos de Google Drive que usted usó con esta aplicación») → Actualizar → Guardar. Es un permiso **no sensible**: no exige verificación de Google.
10. **Audiencia** → en «Usuarios de prueba» agregue `trianon.accesos@gmail.com` (solo hace falta mientras la app esté en «Pruebas»).

## Parte 4 · Evitar que el acceso caduque a los 7 días (¡importante!)

11. En **Audiencia** (o «Estado de publicación») verá el estado **Pruebas**. Con una aplicación **Externa en Pruebas**, Google vence el *refresh token* a los **7 días** y la subida de archivos dejaría de funcionar.
12. Pulse **Publicar aplicación** → confirme. El estado pasa a **En producción**. Con el permiso `drive.file` no se necesita verificación de Google; solo aparecerá un aviso de «aplicación no verificada» la primera vez que autorice, que usted puede aceptar con **Avanzado → Ir a ControlAccesos (no seguro)**, porque la aplicación es suya.
13. Nota: el token también deja de servir si la cuenta cambia su contraseña o se revoca el acceso en https://myaccount.google.com/permissions; en ese caso repita la Parte 6.

## Parte 5 · Crear las credenciales

14. **APIs y servicios** → **Credenciales** → **Crear credenciales** → **ID de cliente de OAuth**.
15. Tipo de aplicación: **Aplicación de escritorio** → nombre `ControlAccesos consola` → **Crear**.
16. Se muestra el **ID de cliente** y el **Secreto del cliente**. Cópielos (también puede **Descargar JSON**). Guárdelos como contraseñas: quien los tenga puede pedir acceso a ese Drive.

## Parte 6 · Cargar las claves y autorizar (en el servidor o PC donde corre la aplicación)

17. Defina las variables de entorno (PowerShell, ejemplo; para que persistan use el panel de variables del sistema o el servicio/IIS):
    ```powershell
    $env:Almacen__Drive__ClientId     = "<ID de cliente>"
    $env:Almacen__Drive__ClientSecret = "<Secreto del cliente>"
    ```
18. Desde la carpeta del repositorio ejecute: `dotnet run --project src/Consola -- drive-autorizar`
19. Se abre el navegador (o copie la dirección que imprime). Inicie sesión con **trianon.accesos@gmail.com** → acepte el permiso. Verá «Listo. Puede cerrar esta ventana».
20. En la consola aparece un valor largo: es el **refresh token**. Guárdelo en la tercera variable:
    ```powershell
    $env:Almacen__Drive__RefreshToken = "<valor mostrado>"
    ```
    (Si la consola dice que no devolvió refresh token: quite el acceso en https://myaccount.google.com/permissions y repita el paso 18.)
21. Reinicie la aplicación web / el servicio para que lea las tres variables.

## Parte 7 · Activar y probar

22. Pruebe la conexión (guarda un archivito, lo lee, lo compara y lo borra):
    `dotnet run --project src/Consola -- probar-almacen DRIVE` → debe decir **OK**.
23. En la aplicación: **Catálogos → Parámetros** → «Dónde se guardan los archivos nuevos» → **Google Drive**. (Opcional: cambie «Carpeta de Google Drive».)
24. Suba un adjunto en una solicitud y descárguelo: debe funcionar igual que antes. En el Drive de la cuenta aparecerá la carpeta `ControlAccesos_Adjuntos` con archivos de nombre aleatorio (no se publican ni se comparten con nadie).

## Parte 8 · Pasar a Drive lo que ya está en la base (opcional)

25. Vea cuánto hay: `dotnet run --project src/Consola -- resumen-archivos`
26. Copie sin borrar nada de la base (recomendado la primera vez): `dotnet run --project src/Consola -- migrar-archivos DRIVE`
27. Cada archivo se sube, se vuelve a leer y se compara su huella antes de anotarse. Cuando esté conforme, libere espacio en la base: `... migrar-archivos DRIVE --vaciar-bd`. (Se hace un lote de 50 por tabla; repite solo hasta terminar. Con `--max N` cambia el lote.)

## Carpeta de red (alternativa o complemento)

- Parámetros → «Carpeta de red de los archivos» = por ejemplo `\\servidor\ControlAccesos`; «Dónde se guardan…» = **Carpeta de red**.
- La cuenta de Windows con que corre la aplicación (el grupo de aplicaciones de IIS o el usuario del servicio) debe tener permiso de **modificar** esa carpeta. La aplicación no usa otras credenciales.
- Pruebe con `dotnet run --project src/Consola -- probar-almacen RED` y migre con `migrar-archivos RED`.
- Pueden convivir: cada archivo recuerda dónde quedó; cambiar el parámetro solo afecta a los archivos nuevos.

## Seguridad y operación

- Los archivos se descargan **a través de la aplicación** (con los permisos de siempre); no se crean enlaces públicos.
- Al leer, la aplicación verifica la huella SHA-256: si el archivo fue alterado o dañado, no lo entrega.
- Respaldo: la base ya no contiene los archivos migrados con `--vaciar-bd`; respalde también la carpeta de Drive o de red.
- Si Drive o la red no responden, solo fallan los archivos de ese almacén; el resto de la aplicación sigue.
- Límites de la cuenta Gmail gratuita: 15 GB compartidos con Gmail y Fotos. Para producción real conviene Google Workspace o la carpeta de red.
