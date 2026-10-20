# Entrega del 2026-10-19 · Solicitud de visita (lado solicitante)

Solo archivos nuevos o modificados, con la estructura del repositorio: cópialos encima. No hay cambios de base de datos ni de proyectos (no hace falta tocar el .slnx).

## Qué trae
- **Mis solicitudes**: contadores (Todas / Pendientes / Observadas / Aprobadas / Canceladas), búsqueda por empresa, persona o DNI, filtro por fechas, y las acciones Ver, Reutilizar y Cancelar.
- **Nueva solicitud**: asistente de 3 pasos (datos de la visita → personas → revisión y envío).
- **Detalle**: datos de la visita, personas con su estado y acciones (Editar, Corregir y reenviar, Retirar, Volver a agregar), «+ Agregar persona», «Editar datos», cancelar e historial.
- **Reutilizar**: copia los datos y las personas de otra solicitud; tú eliges la nueva fecha y hora.
- Servicio nuevo para **personas externas** (buscar por documento, registrar, corregir) y registrado en `Composicion`.
- El menú habilita «Mis solicitudes» y «Nueva solicitud». Documentos: D-110 a D-116, P-64 a P-66, T-15.

## Pasos
1. Copia los archivos y haz Rebuild All. Arranca la web y recarga con Ctrl+F5.
2. Necesitas un usuario con el rol **Solicitante** (créalo en Usuarios y roles, vinculado a una persona de Personal, y define su contraseña con el enlace). También puedes darle ese rol a tu usuario administrador.
3. Para elegir responsable de atención debe haber personas activas en **Personal**; para elegir zonas y motivos, los de **Catálogos**.

## Qué probar
1. **Nueva solicitud**: elige fecha futura, hora, empresa, responsable (escribe 2 letras), motivo (prueba «Otro»: pide detalle) y una zona. Continúa.
2. **Personas**: agrega una con DNI nuevo (se registra) y otra repitiendo el mismo DNI en otra solicitud (se completa sola). Envía.
3. **Detalle**: debe mostrar el aviso de envío. Prueba «Editar datos», «+ Agregar persona», «Retirar» y «Volver a agregar».
4. **Cancelar** desde Mis solicitudes: pide motivo opcional; la solicitud pasa a Canceladas.
5. **Reutilizar** una solicitud: los datos y personas vienen copiados; elige fecha y envía.
6. Todavía no puedes aprobar: eso es la pantalla del coordinador (siguiente entrega). Para ver estados «Observada» o «Autorizada» hay que esperar esa pantalla.

Los datos de prueba quedan en tu base; puedes reiniciar con `restaurar_bd.ps1`.

## Siguiente
Pantalla del coordinador: Solicitudes (Por decidir / Todas) y revisión por persona (aprobar, observar, rechazar).
