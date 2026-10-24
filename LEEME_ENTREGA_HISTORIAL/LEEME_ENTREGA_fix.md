# Entrega del 2026-10-21 (noche) · Fix de fecha «hoy» y consulta de aprobadas en Vigilancia

## Por qué no dejaba agendar para hoy
La base de datos calcula «hoy» con la hora de **su servidor**, que está en UTC (5 horas por delante de Lima). Tu visita era el 21/10 a las 23:55, pero a las 22:51 en Lima la base ya estaba en el 22/10 y respondía «La fecha de la visita no puede ser anterior a hoy». Pasa todos los días desde las 19:00. Solución: la conexión ahora le dice a la base que trabaje en hora de Lima. Las rutinas no cambian.

## Qué trae
- **Fix de zona horaria** (`ServiciosControlAccesos.cs`): agrega `Timezone=America/Lima` a la cadena de conexión. Arregla también «Hoy» en Vigilancia pasadas las 19:00.
- **Vigilancia → pestañas «Hoy» y «Aprobadas (todas las fechas)»**: la segunda es solo consulta (búsqueda y «visita desde / hasta», por defecto desde hoy). No muestra ingreso ni salida, porque eso solo se registra el día de la visita; «Detalle» aparece si la persona ya tuvo movimientos.
- **Rutina nueva** `SP_CAF_SOLICITUD_VIGILANCIA_APROBADAS.sql` y su cadena .NET (DTO, contrato, repositorio, servicio, controlador, vista, JS).
- Documentos: D-129 a D-131, P-75, T-18.

## Pasos
1. **Aplica el SQL nuevo** en tu base (PowerShell, desde la raíz del repo; ajusta usuario y base):
   `psql -U postgres -d accesos_piloto_prueba -f "Docs_Modulos\HITO_02_Solicitud_Aprobacion_2026-10-09\00_BD\SP_CAF_SOLICITUD_VIGILANCIA_APROBADAS.sql"`
   (o `.\restaurar_bd.ps1 -Database accesos_piloto_prueba -SoloRutinas`).
2. Copia los archivos, Rebuild All, **detén y vuelve a iniciar la web** (la cadena se lee al arrancar) y recarga con Ctrl+F5.

## Qué probar
1. Nueva solicitud para **hoy** con hora posterior a la actual: debe enviarse sin el error de fecha.
2. Vigilancia → **Aprobadas**: lista las personas aprobadas desde hoy; cambia las fechas, busca por nombre o DNI; no hay botones de ingreso ni salida.
3. Vuelve a **Hoy**: sigue igual que antes, con sus botones.

Nota: los datos de prueba guardados antes de este cambio pueden mostrar horas corridas 5 horas; no afecta el funcionamiento.
