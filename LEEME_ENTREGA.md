# Entrega del 2026-10-21 · Solicitud de visita (lado coordinador)

Solo archivos nuevos o modificados, con la estructura del repositorio: cópialos encima. No hay cambios de base de datos ni de proyectos (no hace falta tocar el .slnx).

## Qué trae
- **Solicitudes** (menú Coordinador): pestañas «Por decidir (N)» y «Todas», filtros por empresa, solicitante, persona o DNI, fecha y estado.
- **Revisar**: ventana con los datos de la visita, las personas (con su estado) y el historial. Se marcan personas y se elige: Aprobar todas, Aprobar seleccionadas, Observar seleccionadas o Rechazar seleccionadas. Observar y rechazar piden texto.
- Si quedan personas sin marcar, la pantalla pregunta si se dejan pendientes, se observan o se rechazan.
- **«+ Agregar persona (queda aprobada)»** para invitados de último momento.
- Servicio nuevo `AgregarAprobadaAsync` (repositorio, servicio y contratos de `Solicitud_Persona`).
- El menú habilita «Solicitudes». Documentos: D-117 a D-120, P-67 a P-69, T-16.

## Pasos
1. Copia los archivos y haz Rebuild All. Arranca la web y recarga con Ctrl+F5.
2. Necesitas un usuario con el rol **Coordinador** (LIC_CAF_COORDINADOR) en VES. Créalo en Usuarios y roles, vinculado a una persona de Personal, y define su contraseña con el enlace. Tu administrador no decide solicitudes.
3. Con un usuario **Solicitante** (puede ser otro, o el mismo con ambos roles) crea una solicitud con 3 personas.

## Qué probar
1. Entra como coordinador → **Solicitudes**: debe decir «Por decidir (1)». Pulsa **Revisar**.
2. Marca una persona y pulsa «Aprobar seleccionadas»: pregunta por las otras dos; elige «Dejarlas pendientes». Queda **Autorizada**.
3. Marca otra, escribe un texto y «Observar seleccionadas»; la tercera, «Rechazar seleccionadas» con motivo.
4. Entra como solicitante → Detalle: debe ver Autorizada / Observada (con el mensaje) / Rechazada. En la observada usa «Corregir y reenviar»; vuelve a quedar pendiente.
5. Como coordinador, «+ Agregar persona (queda aprobada)» con un DNI nuevo: aparece autorizada y marcada «Agregada por coordinación».
6. Prueba los filtros y la pestaña «Todas».

Los datos de prueba quedan en tu base; puedes reiniciar con `restaurar_bd.ps1`.

## Siguiente
Vigilancia: control de accesos (ingreso y salida con checklist), luego desviaciones, incidencias y reporte.
