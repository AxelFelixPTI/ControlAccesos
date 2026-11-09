# Entrega: Proveedor — varios transportistas y ayudantes de descarga (2b-2, D-225)

ZIP acumulado. El LEEME anterior está en `LEEME_ENTREGA_HISTORIAL/`.

> **BD + .NET + web:** ejecuta `restaurar_bd.ps1` (base nueva) o, en una base existente, en este orden: `24_ALTER_PROVEEDOR_GRUPO.sql`, `SP_CAF_PROVEEDOR_ALL.sql`, `SP_CAF_PROVEEDOR_GRUPO_ALL.sql`, `SP_CAF_SOLICITUD_TRANSPORTISTA_ALL.sql`, `SP_CAF_SOLICITUD_PERSONA_ALL.sql`, `SP_CAF_SOLICITUD_LECTURA_ALL.sql`, `SP_CAF_PROVEEDOR_DASHBOARD_ALL.sql`, `SP_CAF_PORTERIA_ALL.sql`; reemplaza `src`.

## Qué cambia
- **Cada persona tiene su estado.** Transportista o «Ayudante de descarga» (antes «Acompañante»). La entrega pasa a EN_ESPERA cuando están verificados **todos los transportistas** (los ayudantes no bloquean), a INGRESO cuando entra el primero, y a SALIO cuando sale el último.
- **Vigilancia:** casillas por persona y «Marcar: Transportistas / Ayudantes / Todos». Con lo marcado: **Verificar datos**, **Registrar ingreso** (antes «Validar ingreso»), **Registrar salida** y **Retiró sin ingresar**, con **un solo checklist** (la placa y la documentación solo para transportistas). Contadores «verificados v/t · dentro d».
- **Exclusa:** capacidad configurable (`EXCLUSA_CAPACIDAD`, por defecto 1 vehículo). Un camión puede salir antes de la recepción para dar paso al siguiente.
- **Almacén:** confirma una vez y da una sola conformidad; quien no ingresó queda «No ingresó».
- **Quitar al único transportista** rechaza la solicitud aunque queden ayudantes: el Coordinador debe confirmar (se le sugiere corregir el nombre o cancelar); el solicitante queda bloqueado con ese aviso.
- Calendario de proveedores muestra el avance por persona.
- Cambiar la capacidad: `CALL "ERP_CAF_PARAMETRO_GUARDAR"('EXCLUSA_CAPACIDAD','2', <usuario>, NULL, NULL);`

## Qué se probó
SQL (PostgreSQL, base nueva): HITO2 escritura 701/701 (52 pruebas nuevas D-225), lectura 212, HITO1 143, HITO3 140/100, HITO4 138/113, PERMISOS 43, HITO0 65. Compilación .NET: 0 errores. Navegador (Playwright con servicios simulados, 1280 y 390 px): escenario de 2 camiones + 3 ayudantes (30 comprobaciones), más regresión de formulario, calendario y Vigilancia.
## Qué NO se probó
Npgsql real desde C#, SAP HANA (T-36 y T-37), SMTP, IIS ni el servicio en segundo plano. Las reglas del navegador usan servicios simulados que replican las rutinas, no la base real. Pruebas de navegador antiguas desactualizadas: adj/adj2 (2 adjuntos), rol, t/t2, cierre. No hay prueba SQL explícita de «persona sin verificar no ingresa» ni del correo al quitar al único transportista.
## Pendiente
P-158 (cinco puntos para validar con Sandra). Siguen las entregas C (P-98), D (P-96/97) y E (P-95) del encargo original.
