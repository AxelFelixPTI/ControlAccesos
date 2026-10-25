# Working context · Control de Accesos

Actualizado: 2026-10-17

## Dónde estamos

- **2026-10-24 · Reporte de accesos hecho (candidato).** `ReportesController` + vista + `reportes.js`: filtros, resumen del rango, exportar CSV, imprimir (D-143..D-145, P-84..P-86, T-22). Además, botón «Registrar incidencia» en Control de accesos (D-146). Sin cambios de base de datos.
- **2026-10-18 · Capa web, corte 1 (arranque, login y menú).** Proyecto `src/Web.ControlAccesos` (ASP.NET Core MVC + Razor): inicio de sesión con cookie, cierre, cambio de contraseña (obligatorio si la cuenta lo exige), menú lateral por permisos, pantalla de inicio con licencias y permisos, pantallas «Sin acceso» y «Error». Probado de punta a punta con peticiones HTTP reales y un servicio de autenticación falso (sin sesión → redirige; token anti-falsificación; clave mala; login; menú; cabeceras; redirección externa bloqueada; salir; cambio de contraseña obligatorio y validaciones). Antes: `login` real contra PostgreSQL funcionó (administrador creado, licencia LIC_CAF_ADMIN y 3 permisos). Decisiones D-93 a D-97, pendientes P-56, P-57, T-12 en `DECISIONES_ARRANQUE.md`.
- **2026-10-18 · Login (capa de aplicación) generado.** `ISrv_Auth`/`Srv_Auth` (iniciar sesión con bloqueo 5 intentos / 15 min, emitir token de un solo uso, definir contraseña con token, cambiar contraseña, buscar por correo, verificar permiso), 7 métodos nuevos en `Repo_Usuario` (autenticación por correo y por token, registrar login, registrar token, licencias y permisos del usuario, verificar permiso), `Dto_Auth.cs` y 3 comandos de consola (`login`, `emitir-token`, `definir-password`). Compila con 0 errores y 0 avisos; las 10 llamadas de `Repo_Usuario` resuelven contra la base; prueba local de `Srv_Auth` con repositorio falso (bloqueo, vencimiento, un solo uso) y token verificado contra la base (vigente / vencido / usado). Antes, el mismo día: `probar` dio 13 de 13 OK (primera ejecución real de C# contra PostgreSQL) y `EjecutorSp` V1.2 califica las rutinas con su schema. Decisiones D-89 a D-92, pendientes P-53 a P-55, T-11 en `DECISIONES_ARRANQUE.md`.
- **2026-10-18 · Paso 1 de arranque: registro de dependencias, envío de correos y consola.** 3 proyectos nuevos en `src/`: `Infrastructure.ExternalServices` (`ProcesadorCorreos`, `CorreoWorker`, `EnviadorSmtp`/`EnviadorSimulado`, `HasherPbkdf2`), `Composicion` (`AddControlAccesos(config)` registra conexión, `EjecutorSp`, 25 repos y 25 servicios) y `Consola` (comandos `probar`, `crear-admin`, `enviar-correos`, `servir`). Mínimo de Usuario: `Repo_Usuario`/`Srv_Usuario` (crear, contraseña, licencia) y `IHasherPassword`. Compila (0 errores, 0 avisos); prueba local: el contenedor de dependencias resuelve las 48 interfaces, hash PBKDF2 verifica, y el procesador de correos marca enviado/error con usuario 0 y MaxIntentos. Las 3 llamadas de `Repo_Usuario` resuelven contra la base. **C# todavía no se ejecutó contra PostgreSQL: lo hace el usuario con `probar`.** Decisiones D-86 a D-88 en `Docs_Modulos/ARRANQUE_PASO1/DECISIONES_ARRANQUE.md`.
- **2026-10-18 · Hito 4, capas .NET (DTOs, repositorios, servicios) generadas.** 13 archivos de DTO (10 de respuesta desde las columnas reales y 3 de entradas: `Dto_Incidencia_Entradas`, `Dto_Correo_Entradas`, `Dto_Reporte_Entradas`), 3 repositorios (`Repo_Incidencia`, `Repo_Correo`, `Repo_Reporte`) y 3 servicios con sus interfaces, generados por `Docs_BD/_tools/gen_capas_incidencias.py` desde `firmas_rutinas_hito4.txt`. Compilan en .NET 10.0.112 con 0 errores y 0 avisos; `verificar_llamadas.py`: **15 de 15 llamadas resuelven contra la base**. **C# todavía no se ejecutó contra PostgreSQL.** Faltan: proceso en segundo plano de envío de correos (usa el usuario 0), registro de dependencias y pantallas web (al final).
- **2026-10-18 · Hito 4 (incidencias, correos y reporte), Fase 1 completa.** Sin cambios de tablas. 3 archivos nuevos en `Docs_Modulos/HITO_04.../00_BD`: `SP_CAF_INCIDENCIA_ALL.sql` (registrar, decidir, listar, detalle, personas, contadores, buscar personas), `SP_CAF_CORREO_ALL.sql` (pendientes, marcar enviado/error, listar, reencolar; el proceso de envío es el usuario 0) y `SP_CAF_REPORTE_ALL.sql` (accesos, resumen diario, autorizados por zona). Pruebas `PRUEBAS_FASE1_HITO4_ESCRITURA.sql` (**135 de 135 OK**) y `PRUEBAS_FASE1_HITO4_LECTURA.sql` (**113 de 113 OK**), generadas por `Docs_BD/_tools/gen_pruebas_hito4.py`. Restauración desde cero: 11 + 24 tablas, 59 + 114 rutinas. Decisiones D-74 a D-85 y pendientes P-46 a P-50, T-09 en `DECISIONES_HITO4.md`. Siguiente: capas .NET del Hito 4.
- **2026-10-17 · Hito 3, capas .NET (DTOs, repositorios, servicios) generadas.** 13 archivos de DTO (11 de respuesta desde las columnas reales y `Dto_Porteria_Entradas.cs` con formularios y filtros), 3 repositorios (`Repo_Porteria`, `Repo_Respaldo`, `Repo_Desviacion`) y 3 servicios, con sus interfaces, generados por `Docs_BD/_tools/gen_capas_porteria.py` desde `firmas_rutinas_hito3.txt`. El checklist se envía como lista de `Dto_Porteria_Respuesta` y el repositorio lo convierte a `id:Y,id:N`. Compilan en .NET 10.0.112 con 0 errores y 0 avisos; `verificar_llamadas.py`: **16 de 16 llamadas resuelven contra la base**. **C# todavía no se ejecutó contra PostgreSQL.** Faltan: registro de dependencias y pantallas (al final), y el Hito 4.

- **2026-10-17 · Hito 3 (portería y desviaciones), Fase 1 completa.** Sin cambios de tablas. 4 archivos nuevos en `Docs_Modulos/HITO_03.../00_BD`: `SP_CAF_DESVIACION_ALL.sql` (validar, crear, dar conformidad), `SP_CAF_PORTERIA_ALL.sql` (ítems aplicables, regla única de movimiento, registrar ingreso, registrar salida, «no se presentó»), `SP_CAF_RESPALDO_ALL.sql` y `SP_CAF_PORTERIA_LECTURA_ALL.sql` (11 lecturas). Pruebas `PRUEBAS_FASE1_HITO3_ESCRITURA.sql` (**140 de 140 OK**) y `PRUEBAS_FASE1_HITO3_LECTURA.sql` (**100 de 100 OK**), generadas por `Docs_BD/_tools/gen_pruebas_hito3.py`. Restauración desde cero: 11 + 24 tablas, 59 + 99 rutinas, pruebas 65, 143, 43, 186, 202, 140 y 100 OK. Decisiones D-62 a D-73 y pendientes P-40 a P-45, T-08 en `DECISIONES_HITO3.md`. Siguiente: capas .NET del Hito 3.

- **2026-10-23 · Pantalla Desviaciones del coordinador hecha (candidata).** `DesviacionesController` + vista + `desviaciones.js`: Por revisar / Revisadas, detalle con checklist y conformidad (D-136..D-138, P-78..P-80, T-20). Sin cambios de base de datos. Probada con servicios simulados y navegador.
- **2026-10-23 · Usuarios de demostración y limpieza.** `11_SEED_DEMO_USUARIOS.sql` (8 usuarios ficticios: admin, coordinador, 3 vigilancia, 3 solicitantes) y `LIMPIAR_DATOS_PRUEBA.sql` manual; pruebas de Hito 2 y 3 aisladas de los usuarios demo (D-132..D-135, P-76, P-77, T-19). Verificado reconstruyendo una base desde cero en PostgreSQL 16: todas las pruebas pasan.
- **2026-10-21 (noche) · Fix hora de Lima + consulta de aprobadas.** Conexión con `Timezone=America/Lima` (D-129); Vigilancia con modo «Aprobadas (todas las fechas)» de solo consulta y rutina nueva `ERP_CAF_SOLICITUD_VIGILANCIA_APROBADAS` (D-130, D-131). Requiere aplicar el SQL nuevo en la base.
- **2026-10-21 · Pantalla de Vigilancia «Control de accesos» hecha (candidata).** `VigilanciaController` + vista + `vigilancia.js`: lista de hoy por solicitud, ingreso y salida con checklist, respaldo, desviación, registro tardío, detalle y «No autorizado». Sin cambios de base de datos. Decisiones D-121..D-128, pendientes P-70..P-74, T-17. Probada con servicios simulados y navegador (Playwright); falta la prueba con la base real en la máquina del usuario.
- **2026-10-17 · Hito 2, capas .NET (DTOs, repositorios, servicios) generadas.** 12 archivos de DTO, 5 repositorios (`Repo_Solicitud`, `_Persona`, `_Decision`, `_Vigilancia`, `Repo_Tipo_Acceso_Paso`) con sus interfaces y 5 servicios con sus interfaces, generados por `Docs_BD/_tools/gen_capas_solicitud.py` desde las firmas reales (`firmas_rutinas_hito2.txt`). `EjecutorSp` V1.1 (escrituras con varias salidas) y `RepoHelpers` V1.1 (`AddDate`). Compilan en .NET 10.0.112 con 0 errores; `verificar_llamadas.py` V1.1: **21 de 21 llamadas resuelven contra la base** y las 10 escrituras responden 400 con parámetros nulos. **C# todavía no se ejecutó contra PostgreSQL** (Npgsql no disponible en el entorno de Claude). Faltan: registro de dependencias y pantallas (al final).

- **2026-10-17 · Hito 2, Fase 1 completa (escritura + lectura).** Lectura: `SP_CAF_SOLICITUD_LECTURA_ALL.sql` (14 rutinas: Mis solicitudes, bandeja por pestañas, contadores, detalle, personas, ruta, historial, versiones, listados de Vigilancia). Pruebas `PRUEBAS_FASE1_HITO2_LECTURA.sql`: **202 de 202 OK**. Restauración desde cero con `restaurar_bd.ps1`: 11 + 24 tablas, 59 + 79 rutinas, pruebas 65, 143, 43, 186 y 202 OK. Decisiones D-56 a D-61 en `Docs_Modulos/HITO_02.../DECISIONES_HITO2_LECTURA.md`. Base de trabajo del usuario: `accesos_piloto_prueba`. **.NET del Hito 2 aún no iniciado.**

- **2026-10-16 · Script 09 aplicado: permisos atómicos y pasos de aprobación.** 4 tablas nuevas (`Catalogo_Permiso`, `Licencia_Permiso`, `Tipo_Acceso_Paso_Aprobacion`, `CAF_Solicitud_Decision`), 9 rutinas nuevas y 43 pruebas (`PRUEBAS_FASE1_PERMISOS.sql`). Total: **35 tablas, 106 rutinas, 251 pruebas en OK** en PostgreSQL 16 desde base limpia. El visitante externo no cambió: es el caso de un paso.
- **Mockup v2 (memoria compartida) terminado y aprobado por el usuario.** Incluye aprobación por persona, estados calculados, Editar según el caso, Reutilizar, detalle de portería y administración funcional.
- **Preguntas para Sandra:** documento «Preguntas pendientes de afinación» (39 preguntas, P-01 a P-39). Resuelta P-33: el sistema se construye independiente, con su propio inicio de sesión; integrarlo a Trianon Satelital queda para más adelante. P-31 enviada al área legal por correo.

- **Hitos 0 y 1:** diseño **aprobado** (OK Arquitectura y OK Hito, 2026-10-11).
- **Fases 2 a 5 de los 12 catálogos: hechas por Claude (candidato, 2026-10-13).** `src/` con 7 proyectos. Compilan en .NET 10.0.112 con 0 errores; las 68 llamadas de los repositorios verificadas contra la base. **Nunca se ejecutó C# contra PostgreSQL** (Npgsql no disponible en el entorno de Claude). Faltan Personal, Usuario, Usuario_Licencia, Tipo_Acceso_Item_Checklist y CAF_Persona_Externa, y las fases 6 a 9.
- **Fase 1 del Hito 1: hecha y verificada.** 43 rutinas en `TRIANONSATELITAL_CAF_PRODD` (8 archivos `SP_CAF_*`). Pruebas: `00_BD/PRUEBAS_FASE1_HITO1.sql`, **143 de 143 OK en PostgreSQL 16 (Claude) y en PostgreSQL 18 (usuario, 2026-10-11; 21 funciones y 22 procedimientos)**.
- **Fase 1 del Hito 0: hecha y verificada.** 54 rutinas en `CAF_GOVERNANCE` (catálogos transversales, Personal, Usuario, Usuario_Licencia). Pruebas: `00_BD/PRUEBAS_FASE1_HITO0.sql`, **65 de 65 OK en PostgreSQL 16 (Claude) y en PostgreSQL 18 (usuario, ejecutado con PowerShell)**.
- **Base:** scripts 01 a 05 probados también por el usuario en PostgreSQL 18. `Docs_BD` exportado con tablas de los Hitos 0 y 1 y los 54 procedimientos.
- **Modelo completo:** Hitos 2 a 4 (scripts 06 a 08) aprobados en principio como borrador; se revisan al iniciar cada hito.

## Última sesión

- **2026-10-11 (segunda).** Fase 1 del Hito 1: 6 catálogos con `gen_catalogos.py` V1.1 (los 5 del Hito 0 salen idénticos), pivot de checklist y persona externa. Decisiones D-31 a D-36 en el paquete. Equivalencias V1.1 (PostgreSQL crea una rutina que nombra una tabla inexistente; HANA no). Los archivos no se entregaron en la primera respuesta: se presentaron en la siguiente.

## Sesión anterior


- **Cerrada el 2026-10-11.** Cubrió: requisitos y mockup validados, modelo de datos completo (31 tablas), convenciones y prefijo `CAF_`, Fase 1 del Hito 0.
- El usuario trabaja en **Windows, con PowerShell y PostgreSQL 18**; tiene ejecutados los scripts 01 a 05 y los 9 archivos `SP_GOVERNANCE_*`. No ha confirmado si ejecutó 06 a 08 (borrador).
- Perfil: aprende mientras construye; prefiere explicaciones claras y paso a paso, y decide él el alcance y los nombres.

## Siguiente paso literal

Usuario copia `PENDIENTES_VALIDACION.md` reorganizado (D-148) y lo usa para decidir con Sandra qué entra al MVP. Código: construir el **proceso automático diario de «No se presentó»** (D-70, P-72), luego revisar con la base real las pantallas de Desviaciones, Incidencias y Reporte de accesos. Todas las pantallas del prototipo ya están hechas. Pendiente aparte: PDF del reporte con los mismos filtros que el CSV (P-85); «Autorizados por zona» postergado (P-87).

## Decisiones vigentes que más condicionan

- Proyecto independiente con convenciones Trianon (D-01); PostgreSQL piloto, HANA destino (D-02).
- Dos schemas `CAF_GOVERNANCE` y `TRIANONSATELITAL_CAF_PRODD`; prefijo `CAF_` (D-03 a D-05).
- Acceso a datos: `EjecutorSp` arma toda llamada y solo `ConexionPostgres` conoce Npgsql (D-37); capas de catálogos generadas desde las firmas reales (D-39); el servicio no duplica reglas del SP (D-40). `Infrastructure.Contracts` agregado, por confirmar (D-38).
- Seguridad de cuentas y login (D-26, D-29); bitácora con un único escritor (D-23).
- `_DETALLE` repite el SELECT de `_LISTAR` (D-27); `search_path` por rutina (D-28).

## Reglas de entrega del usuario (vigentes desde 2026-10-11)

- **Toda entrega va en un ZIP `ControlAccesos.zip` COMPLETO** (todo el proyecto, no solo lo cambiado), y además se presenta cada archivo. Con el último ZIP se reconstruye todo. Para volver a un estado anterior se usa git o se conserva el ZIP de ese momento. (Corregido 2026-10-12: el ZIP del 2026-10-11 salió parcial por error.)
- **Toda entrega trae un mensaje de commit** (git, gestión desde 2026-10-12): una línea de resumen que diga el hito, la fase y el estado de verificación, seguida de viñetas con lo agregado, lo modificado y lo que falta. Se entrega en el chat junto al ZIP. El usuario pega el contenido del ZIP sobre el proyecto y hace `git add .` y `git commit`.
- **Toda entrega incluye `PENDIENTES_VALIDACION.md` actualizado**, en la raíz del proyecto (al lado del README, fuera de `Docs_BD`, `Docs_Modulos` y `Docs_Cerebro`). Por cada punto: código P-xx, D-* relacionado, qué significa en lenguaje no técnico, pregunta sugerida, con quién validarlo y cuándo hace falta. Un punto nuevo se agrega; uno resuelto se mueve a *Resueltos*, nunca se borra.

## Pendientes que no bloquean

- **Todos los pendientes de negocio viven en `PENDIENTES_VALIDACION.md` (P-01 a P-11; tareas internas T-01 y T-02).** La lista de abajo es solo un resumen técnico.

- Confirmar D-32 (reglas del tratamiento de desviación, con Vigilancia) y D-34 (checklist de tipos de acceso inactivos).
- Documentos con letras (CE, pasaporte): ¿se normalizan a mayúsculas en `Personal` y `CAF_Persona_Externa`?
- T-03 (decisión técnica): los archivos `*_01_TABLAS_CONSOLIDADO.sql` incluyen también las rutinas, porque `pg_dump -n` vuelca todo el schema (CAF_GOVERNANCE_01 trae las 54 y, tras regenerar, PRODD_01 traerá las 43). Cada rutina queda en dos archivos. Está en los dos scripts de exportación desde el Hito 0. Corregirlo cambia el contenido de `Docs_BD`: decidir con el usuario.
- D-35: cada Fase 1 de los Hitos 2 a 4 agrega su revisión en el `_ELIMINAR` de los catálogos que referencia.

- Traducir los `(VALUES ...)` del script 05 antes de ejecutar en HANA.
- Con Sandra: listas reales de catálogos; si las copias de correo reciben todos los correos de la solicitud.
- Mockup: nombre en tres campos (D-10) y efecto obligatorio para "Otro" (D-11).

## Qué leer al retomar (en este orden)

1. Este archivo.
2. `Docs_Modulos/HITO_00_01_Base_y_Catalogos_2026-10-09/00_PAQUETE_DISENO.md` (decisiones D-01 a D-30).
3. `Docs_Modulos/MODELO_DATOS_ETAPA1.md` (las 31 tablas y D-13 a D-23).
4. `Docs_BD/TRIANONSATELITAL_CAF_PRODD_01_TABLAS_CONSOLIDADO.sql` (tablas del schema que toca el Hito 1).
5. `Docs_BD/EQUIVALENCIAS_POSTGRESQL_HANA.md` antes de escribir procedimientos.
6. Como patrón: `00_BD/SP_GOVERNANCE_CATALOGO_SEDE_ALL.sql`, `00_BD/SP_CAF_PERSONA_EXTERNA_ALL.sql` y `00_BD/PRUEBAS_FASE1_HITO1.sql`.

## Herramientas

- `Docs_BD/_tools/gen_capas_catalogos.py` + `firmas_rutinas.txt` (2026-10-13): generan DTO, `IRepo_`, `ISrv_`, `Repo_` y `Srv_` de los 12 catálogos desde las firmas reales (`python3 gen_capas_catalogos.py firmas_rutinas.txt <carpeta>`). `verificar_llamadas.py <base> <carpeta Repo_*> <firmas>` ejecuta contra la base cada llamada de los repositorios. **Tras cambiar un SP: regenerar `firmas_rutinas.txt` (comando en su cabecera), regenerar las capas y volver a verificar.**
- `Docs_BD/_tools/generar_docs_bd.ps1` (2026-10-12): versión PowerShell de `generar_docs_bd.sh`. Probada por Claude en PowerShell 7.4 sobre Linux: salida idéntica byte a byte a la de bash, y ante base inexistente, base equivocada o psql ausente no escribe ningún archivo. **No probada en Windows PowerShell 5.1 ni en el equipo del usuario.** Uso: `powershell -ExecutionPolicy Bypass -File .\generar_docs_bd.ps1 -Base <base> -Usuario postgres -RutaBin "C:\Program Files\PostgreSQL\18\bin"`.
- `Docs_BD/_tools/gen_catalogos.py` V1.1: genera los SPs de catálogos de los dos schemas con la plantilla única (`python gen_catalogos.py caf <carpeta>`).
