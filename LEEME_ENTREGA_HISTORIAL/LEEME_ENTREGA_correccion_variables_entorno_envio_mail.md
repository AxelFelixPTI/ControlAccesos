# Fix · las variables de entorno ganan sobre appsettings.Local.json

Antes, `appsettings.Local.json` se leía después de las variables y las pisaba (una `Clave` vacía anulaba `Correo__Clave`). Ahora el orden es: `appsettings.json` < `appsettings.Local.json` < **variables de entorno**.

## Qué trae
- `src/Web.ControlAccesos/WebApp.cs`
- `src/Consola/Program.cs`

## Pasos
1. Copia los dos archivos y recompila.
2. Reencola los correos con error:
   `UPDATE "TRIANONSATELITAL_CAF_PRODD"."CAF_Correo_Pendiente" SET "Estado"='PENDIENTE',"Intentos"=0 WHERE "Estado"='ERROR';`
3. Ejecuta la web y espera el siguiente ciclo de envío.
