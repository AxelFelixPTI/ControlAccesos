# Entrega: Agregar persona (emergencia) en proveedor — transportista o ayudante (D-226)

ZIP acumulado (incluye todo lo anterior: bloques de proveedor, 2b-1, 2b-2 y las entregas C y D). El LEEME anterior está en `LEEME_ENTREGA_HISTORIAL/`.

> **BD + .NET + web:** ejecuta `restaurar_bd.ps1` (base nueva) o, en una base existente, vuelve a ejecutar `SP_CAF_SOLICITUD_PERSONA_ALL.sql` (cambia la firma del SP de emergencia y hace el `DROP` de la anterior), además de lo pendiente de entregas previas (`24_ALTER_PROVEEDOR_GRUPO.sql`, `SP_CAF_PROVEEDOR_ALL.sql`, `SP_CAF_PROVEEDOR_GRUPO_ALL.sql`). Luego recompila y publica la web.

## Qué cambia
- En **Coordinación → Agregar persona (emergencia)**, si la solicitud es de **proveedor**, aparece «¿Con qué función viene?»: **Ayudante de descarga** (por defecto) o **Transportista**. Con transportista se muestran sus datos (RUC, razón social, dirección, placa, marca, licencia), todos opcionales.
- Si se agrega un transportista cuando la entrega ya estaba **EN_ESPERA**, vuelve a **PROGRAMADO** hasta que Vigilancia lo verifique. Con la entrega ya terminada no se puede agregar un transportista (sí un ayudante).
- En otros tipos de acceso la ventana no cambia.
- La bitácora y el correo de aviso indican el rol.
- **Corrección:** al enviar una solicitud de proveedor aparecía «Seleccione al responsable». El proveedor no lleva responsable de atención (lleva un responsable de la entrega escrito a mano) y la web enviaba 0; ahora `SolicitudesController` (Crear y Editar) envía vacío cuando no hay responsable, y la regla de «responsable obligatorio» sigue valiendo en los demás tipos.

## Qué se probó
SQL (PostgreSQL, base nueva): HITO2 escritura **711/711** (9 pruebas nuevas D-226 y llamadas existentes actualizadas a la firma nueva), lectura 212, HITO1 143, HITO3 140/100, HITO4 138/113, PERMISOS 43, HITO0 65. Compilación sin errores. Navegador (servicios simulados) a 1280 y 390 px: sin pregunta de función en tipos que no son proveedor; en proveedor aparece, los datos del transportista solo se ven si se elige «Transportista», el envío entrega al servicio el RUC y la placa normalizada, sin scroll horizontal ni errores de consola.
## Qué NO se probó
Npgsql real desde C#, SAP HANA (T-36 y T-37), SMTP, IIS. El navegador usó servicios simulados, no la base real.
Nota: esta corrección del responsable se verificó solo compilando; no pude correr el envío real contra la base (los servicios simulados no pasan por esa validación).
## No incluido
Corregir los datos de un transportista ya existente y cambiar el rol de alguien que ya está en la solicitud.
## Pendiente
P-158 (cinco puntos para Sandra; el (c) se actualizó). Sigue la entrega E (P-95 hilo de correo).
