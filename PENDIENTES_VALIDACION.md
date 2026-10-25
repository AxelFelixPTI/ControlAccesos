# Pendientes de validación · Control de Accesos

Actualizado: 2026-10-24 · ordenado por relevancia para el MVP

Este archivo reúne lo que el sistema necesita que **una persona del negocio confirme o decida**, y lo que queda por construir. Está ordenado de lo más importante a lo menos: primero lo que hay que resolver para usar el sistema con datos reales, y al final lo que puede esperar. Dentro de cada grupo, de lo más antiguo a lo más nuevo cuando tienen la misma importancia.

Cómo usarlo:

1. Antes de cada reunión, filtra la columna **Con quién**.
2. Los puntos P-01 a P-11 tienen su explicación y pregunta sugerida en la sección 3. Los demás se explican en la propia tabla.
3. Anota la respuesta en **Estado** y avísame en la siguiente sesión; yo ajusto el sistema y el documento técnico.

La columna **Registrado** es la fecha de la entrega en que apareció cada punto. Los códigos **D-xx** son decisiones del documento técnico y **T-xx** son tareas internas.

> **Nota:** las preguntas P-12 a P-39 del documento «Preguntas pendientes de afinación» (39 preguntas) no están integradas aquí porque ese documento no está entre los archivos del proyecto. Si quieres que las ordene junto con estas, compártelo.

---

## 1. Resumen por grupo

| Grupo | Qué contiene | Puntos |
| --- | --- | --- |
| A | Por construir antes de cerrar el MVP | 1 |
| B | Necesario para operar con datos reales | 12 |
| C | Reglas de portería e incidencias a confirmar | 21 |
| D | Mejoras del prototipo que pueden esperar | 11 |
| E | Para instalar en producción o en HANA | 7 |
| F | Postergado, fuera del MVP | 2 |

---

## 2. Lista ordenada

### A. Por construir antes de cerrar el MVP

| # | Tema | Registrado | Con quién | Se necesita antes de | Estado |
| --- | --- | --- | --- | --- | --- |
| P-72 | **«No se presentó» automático:** hoy la rutina existe pero ningún proceso la dispara. Hay que programar un proceso diario que marque, después de medianoche (hora de Lima), a las personas aprobadas de ayer que no ingresaron. Con P-44 se confirma si es al cierre del mismo día o a primera hora del siguiente. | 2026-10-21 | Equipo (construir) y Sandra (P-44) | Piloto con usuarios | Por construir |

### B. Necesario para operar con datos reales

| # | Tema | Registrado | Con quién | Se necesita antes de | Estado |
| --- | --- | --- | --- | --- | --- |
| P-77 | **Primer administrador real en producción.** Hoy se entra con el administrador demo, se crea el real y se corre la limpieza. Alternativa: un procedimiento de arranque que lo cree con contraseña temporal que obligue a cambiarla. | 2026-10-23 | Equipo y TI | Salida a producción | Pendiente |
| P-01 | Listas reales de áreas, cargos, motivos de visita y tipos de incidencia (detalle en la sección 3). | 2026-10-13 | Sandra, con Control de Activos y SST | Cargar datos reales | Pendiente |
| P-02 | Zonas reales de VES y cuáles exigen SCTR y EPP (sección 3). | 2026-10-13 | SST, con Control de Activos | Cargar datos reales | Pendiente |
| P-51 | **Correo saliente:** servidor SMTP, puerto, SSL y cuenta remitente del grupo. Ya existe el envío real por SMTP (Gmail de prueba `trianon.accesos@gmail.com`, ver `GUIA_CORREO.md`); falta definir la cuenta corporativa. | 2026-10-18 | TI | Piloto con usuarios | Pendiente |
| P-54 y P-63 | **Enlace para definir contraseña por correo:** hoy lo entrega el administrador. Para enviarlo por correo hay que agregar ese tipo de correo en la base. | 2026-10-18 | Sandra y TI | Piloto con usuarios | Pendiente |
| P-52 y P-53 | **Política de contraseñas del grupo:** largo, vigencia, complejidad, y si el bloqueo de 5 intentos por 15 minutos es la regla. Hoy: mínimo 10 caracteres. | 2026-10-18 | TI / Seguridad | Piloto con usuarios | Pendiente |
| P-58 | **Datos personales (Ley 29733):** cuánto tiempo se conservan los datos de los visitantes y qué aviso de privacidad se les muestra. Hoy se guardan sin límite de tiempo. | 2026-10-19 | Legal (consulta ya enviada en P-31) y Sandra | Piloto con usuarios | Pendiente |
| P-08 | Razón social y RUC de las cuatro empresas del grupo (sección 3). | 2026-10-13 | Contabilidad (sugerido) | Cargar datos reales | Pendiente |
| P-09 | Dirección de las sedes (sección 3). | 2026-10-13 | Administración (sugerido) | Cargar datos reales | Pendiente |
| P-76 | Los usuarios de demostración tienen correos ficticios: con el envío real activo (P-51) esos avisos no llegarán a nadie. Usarlos solo en piloto y borrarlos con la limpieza antes de usar datos reales. | 2026-10-23 | Equipo | Cargar datos reales | Pendiente |
| P-50 | Correos: máximo de reintentos (propuesta: 5) y espera entre intentos (propuesta: 5 minutos). | 2026-10-18 | TI | Piloto con usuarios | Pendiente |
| P-47 | ¿Una incidencia confirmada debe avisar por correo y a quién? Hoy no se envía ninguno; agregarlo requiere un tipo de correo nuevo. | 2026-10-18 | Sandra | Piloto con usuarios | Pendiente |
| P-88 | **Destinatarios de cada aviso (D-150):** confirmar que Vigilancia solo recibe copia cuando la solicitud queda Aprobada. | 2026-10-24 | Sandra | Piloto con usuarios | Pendiente |
| P-89 | **Hilo de correos en Gmail:** probar en un envío real que los avisos de una solicitud se agrupan en una conversación. | 2026-10-24 | Equipo | Piloto con usuarios | Pendiente |
| P-90 | **Respuestas al correo:** la casilla del sistema no se lee; decidir si se agrega «Responder a» o basta el aviso del pie. | 2026-10-24 | Sandra | Piloto con usuarios | Pendiente |
| P-91 | **Dirección real de la web** (`UrlBase`) y cuenta de correo corporativa definitiva. | 2026-10-24 | TI | Publicar en internet | Pendiente |

### C. Reglas de portería e incidencias a confirmar

| # | Tema | Registrado | Con quién | Se necesita antes de | Estado |
| --- | --- | --- | --- | --- | --- |
| P-04 | Qué pasa con la persona en cada tratamiento de desviación (entra, entra restringida, no entra; sale o se retiene un elemento). Detalle en la sección 3. | 2026-10-13 | Vigilancia | Piloto con usuarios | Pendiente |
| P-40 | ¿El respaldo de equipos o herramientas debe existir **antes** del ingreso (supuesto actual) o puede registrarse después? | 2026-10-17 | Sandra | Piloto con usuarios | Pendiente |
| P-41 | Si se deniega el ingreso y luego se corrige (por ejemplo, trae el DNI): hoy no reingresa en la misma visita; habría que anular el registro o crear otra solicitud. | 2026-10-17 | Vigilancia | Piloto con usuarios | Pendiente |
| P-42 | Registro tardío: ¿lo puede hacer cualquier vigilante o solo con visto bueno? ¿Hasta cuántos días después? | 2026-10-17 | Sandra y Vigilancia | Piloto con usuarios | Pendiente |
| P-43 | ¿Se acepta como «Coordinador consultado» a cualquier usuario con permiso de conformidad en la sede (supuesto actual)? | 2026-10-17 | Sandra | Piloto con usuarios | Pendiente |
| P-44 | «No se presentó»: ¿se marca al cierre del mismo día o al día siguiente? (hoy: visitas anteriores al corte, normalmente ayer). | 2026-10-17 | Sandra | Al construir P-72 | Pendiente |
| P-45 y P-79 | Desviación e incidencia: hoy están separadas. Confirmar cuándo una desviación debe convertirse en incidencia y si la pantalla debe enlazarlas. | 2026-10-17 | Sandra | Piloto con usuarios | Pendiente |
| P-46 | ¿Un Coordinador puede decidir una incidencia que él mismo registró (supuesto actual: sí)? | 2026-10-18 | Sandra | Piloto con usuarios | Pendiente |
| P-48 | ¿Una incidencia puede corregirse o anularse después de registrada? Hoy solo se decide (confirmar o desestimar). | 2026-10-18 | Sandra | Piloto con usuarios | Pendiente |
| P-81 y P-83 | Incidencias: hoy solo se registran para personas que **ya ingresaron hoy** y con la hora de hoy. No se puede registrar la de alguien que no llegó a entrar ni la de un día anterior. | 2026-10-24 | Vigilancia y Sandra | Piloto con usuarios | Pendiente |
| P-07 | Pasaporte y carné de extranjería: mayúsculas y largo mínimo y máximo (sección 3). | 2026-10-13 | Vigilancia y RRHH (sugerido) | Piloto con usuarios | Pendiente |
| P-11 | Estados de la visita y empresa del visitante (¿lista o texto libre?) (sección 3). | 2026-10-13 | Vigilancia y Sandra | Piloto con usuarios | Pendiente |
| P-03 | Copias de correo: ¿reciben todos los avisos de la solicitud o solo algunos? (sección 3). | 2026-10-13 | Sandra | Piloto con usuarios | Pendiente |
| P-05 | Nombre del visitante en tres casillas en vez de una (sección 3). | 2026-10-13 | Sandra (quien aprobó el mockup) | Presentación del prototipo | Pendiente |
| P-71 | Respaldo para varias personas a la vez (un grupo con una sola guía de remisión): la base lo admite, la pantalla lo registra de a una persona. | 2026-10-21 | Vigilancia | Piloto con usuarios | Pendiente |
| P-73 | La lista de hoy no se actualiza sola entre varios vigilantes (hay que volver a buscar). ¿Se quiere actualización automática cada cierto tiempo? | 2026-10-21 | Vigilancia | Piloto con usuarios | Pendiente |
| P-49 y P-86 | Reporte: ¿92 días de rango máximo es suficiente? ¿Qué columnas necesita el Excel del G-FSCA-008? ¿Falta un filtro por resultado (ingresa, restringido, no ingresa)? | 2026-10-18 | Sandra y Vigilancia | Piloto con usuarios | Pendiente |
| P-84 | Reporte: el prototipo muestra la columna «Atendió» (responsable de la solicitud); la base no la devuelve y por eso no está. | 2026-10-24 | Sandra | Después del piloto | Pendiente |
| P-69 | Vista de solo lectura para quien puede ver todas las solicitudes pero no aprobar (por ejemplo, gerencia): ¿qué roles la tendrán? | 2026-10-21 | Sandra | Piloto con usuarios | Pendiente |
| P-68 | Bandeja de solicitudes del coordinador: hoy lista todas las que cumplen el filtro. Confirmar el volumen esperado antes de agregar páginas. | 2026-10-21 | Sandra | Después del piloto | Pendiente |
| P-80 | Desviaciones: sin filtro por fechas en la pantalla (la base lo admite). ¿Hace falta? | 2026-10-23 | Sandra | Después del piloto | Pendiente |

### D. Mejoras del prototipo que pueden esperar

| # | Tema | Registrado | Con quién | Se necesita antes de | Estado |
| --- | --- | --- | --- | --- | --- |
| P-85 | **Descargar PDF del Reporte de accesos.** Hoy solo existe la exportación a CSV (se abre en Excel). **Tanto el CSV como el PDF deben responder a los mismos filtros de la pantalla** (fechas, persona/DNI/empresa, ingresos o salidas, solo con desviación). El CSV ya lo cumple. Para el PDF hay que decidir librería o impresión del navegador, y si lleva membrete. | 2026-10-24 | Sandra (formato) y Equipo | Después del piloto | Por construir |
| P-59 | Aviso «está en uso» al editar un catálogo (ejemplo: «lo usan 12 solicitudes, por eso se desactiva y no se elimina»). El prototipo lo muestra; falta una rutina que cuente usos. Hoy el aviso es general. | 2026-10-19 | Sandra | Después del piloto | Pendiente |
| P-62 | «Importar desde Excel» del prototipo (carga masiva de personal): no construido. ¿Entra en el MVP? | 2026-10-19 | Sandra | Decidir alcance del MVP | Pendiente |
| P-65 | El prototipo avisa cuando una persona ya está aprobada el mismo día en otra solicitud. No está construido. | 2026-10-19 | Sandra | Después del piloto | Pendiente |
| P-66 | Correos en copia: hoy se escriben separados por «;» en un solo campo; el prototipo los muestra como etiquetas. | 2026-10-19 | Sandra | Después del piloto | Pendiente |
| P-67 | Insignia con el número de solicitudes por decidir junto a «Solicitudes» en el menú (hoy el número aparece solo dentro de la pantalla). | 2026-10-21 | Sandra | Después del piloto | Pendiente |
| P-78 | Desviaciones: el prototipo muestra la columna «No cumplió» (ítems fallidos) en la lista; hoy solo se ve en el detalle. | 2026-10-23 | Sandra | Después del piloto | Pendiente |
| P-61 | Renombrar «trabajador» a «personal» también en el código del permiso y en los mensajes internos de la base. | 2026-10-19 | Equipo | Antes de traducir a HANA | Pendiente |
| P-60 | Autogestión de contraseña («olvidé mi contraseña» por correo). Se evalúa después del MVP. | 2026-10-19 | Sandra y TI | Después del MVP | Pendiente |
| P-06 | Preparar el checklist de contratistas antes de habilitarlos (sección 3). | 2026-10-13 | Sandra (sugerido) | Etapa 2 (contratistas) | Pendiente |
| P-64 | Selector de tipo de acceso en la solicitud cuando se habiliten Contratista, Proveedor o Interno visitante. | 2026-10-19 | Sandra | Etapa 2 | Pendiente |

### E. Para instalar en producción o en HANA

| # | Tema | Registrado | Con quién | Se necesita antes de | Estado |
| --- | --- | --- | --- | --- | --- |
| P-10 | Nombres de los esquemas (bases) en el servidor de producción HANA y en qué servidor se instala (sección 3). | 2026-10-13 | TI | Instalación en HANA | Pendiente |
| P-55 y P-75 | **Hora:** la aplicación y la base deben estar en la misma zona horaria. La conexión ya fuerza hora de Lima (D-129); confirmar cómo está el servidor de producción. Los datos de prueba guardados antes del ajuste pueden tener horas corridas 5 horas. | 2026-10-18 | TI | Instalación en HANA | Pendiente |
| T-05 | **Riesgo para HANA:** si un procedimiento de escritura falla a medias, HANA no deshace solo; la aplicación debe abrir una transacción por cada escritura y revertirla si hay error. Probar con una falla provocada. | 2026-10-13 | Equipo | Instalación en HANA | Por probar |
| T-06 a T-22 | **Traducción a HANA** de todas las rutinas (Hitos 2 a 4, login, personal, pantallas). Las pantallas no cambian; sí las rutinas (cursores, tablas temporales, `RETURN QUERY`, etc.). Reglas en `EQUIVALENCIAS_POSTGRESQL_HANA.md`. | 2026-10-13 | Equipo | Instalación en HANA | Por hacer |
| T-02 | Traducir a HANA la carga inicial de zonas (script 05). | 2026-10-13 | Equipo | Instalación en HANA | Por hacer |
| T-03 y T-04 | **Decisiones técnicas del usuario:** separar «TABLAS» de las rutinas en `Docs_BD` (T-03) y mantener o no el proyecto `Infrastructure.Contracts` (T-04). | 2026-10-13 | Axel | Cuando quiera | Por decidir |
| T-07 | Confirmar con Sandra: el sistema no deja retirar a la última persona de una solicitud (pide cancelarla); el prototipo sí lo permitía. | 2026-10-17 | Sandra | Presentación del prototipo | Pendiente |

### F. Postergado, fuera del MVP

| # | Tema | Registrado | Con quién | Se necesita antes de | Estado |
| --- | --- | --- | --- | --- | --- |
| P-87 | **Pantalla «Autorizados por zona»** (quién estaba autorizado a una zona en una fecha y si llegó a entrar). No está en el prototipo y no se tiene claro para qué se usaría. La rutina de la base ya existe. Se retoma solo si el negocio la pide. | 2026-10-24 | Sandra | Sin fecha (fuera del MVP) | Postergado |
| P-57 y P-74 | Selección de sede activa al entrar (hoy VES fija). Se retoma cuando se contemple la sede Magdalena. | 2026-10-19 | Sandra | Etapa con sede MAG | Postergado |

---

## 3. Detalle de los puntos P-01 a P-11 (por persona)

### Sandra

**P-01 · Listas reales de los catálogos**

- **Qué significa:** las listas desplegables del sistema (áreas, cargos, motivos de visita, tipos de incidencia) tienen hoy valores de ejemplo. Hacen falta las listas que la empresa usa de verdad.
- **Pregunta sugerida:** *"¿Me puedes pasar la lista oficial de áreas y cargos, y junto con Control de Activos y SST, los motivos de visita y los tipos de incidencia que quieren registrar? Si hay un motivo 'Otro', ¿debe pedir que la persona escriba el detalle?"*
- **Si no se resuelve:** el piloto arranca con listas de ejemplo y luego hay que reemplazarlas.

**P-03 · Copias de correo**

- **Qué significa:** al crear una solicitud se pueden poner personas "en copia". No está decidido si esas personas reciben **todos** los avisos (creada, aprobada, rechazada, ingresó, salió) o solo algunos.
- **Pregunta sugerida:** *"Si pongo a alguien en copia de una solicitud de visita, ¿debe enterarse de todo lo que pasa con ella, o solo de cuándo se aprueba o rechaza?"*
- **Si no se resuelve:** se envían todos, que es lo más seguro pero puede saturar bandejas.

**P-06 · Preparar el checklist de contratistas por adelantado** *(sugerido: Sandra)*

- **Qué significa:** cada tipo de visitante tiene su lista de verificación en portería (por ejemplo, "trae EPP", "SCTR vigente"). El sistema permite armar la lista de **contratistas** ahora, aunque ese tipo de visita todavía no se pueda usar.
- **Pregunta sugerida:** *"¿Les sirve poder preparar desde ya qué se le revisa en portería a un contratista, aunque los contratistas empiecen a usar el sistema más adelante?"*
- **Si no se resuelve:** queda permitido. Es fácil de cambiar.

**P-05 · Nombre en tres campos en la solicitud** *(confirmar quién aprobó el mockup)*

- **Qué significa:** el diseño de la pantalla de solicitud tiene un solo campo "Nombre". El sistema lo guarda en tres (apellido paterno, apellido materno y nombres) para buscar mejor, distinguir personas con el mismo nombre y poder conectarse a RENIEC en el futuro.
- **Pregunta sugerida:** *"En la pantalla de solicitud, ¿está bien pedir el nombre del visitante en tres casillas (apellido paterno, materno y nombres) en lugar de una sola?"*
- **Si no se resuelve:** la pantalla se construye con tres casillas.

### Vigilancia

**P-04 · Qué pasa con la persona en cada tratamiento de desviación**

- **Qué significa:** cuando en portería algo no cumple (por ejemplo, el SCTR vencido), el vigilante elige un "tratamiento". Cada tratamiento define qué pasa: al **entrar** (ingresa, ingresa solo a zona administrativa, no ingresa) y al **salir** (sale, o sale pero se le retiene algo). Para el tratamiento "Otro", el vigilante decide en el momento qué pasa. El sistema exige tres reglas:
  1. Todo tratamiento sirve para la entrada, para la salida o para ambas.
  2. Si sirve para la entrada, debe decir qué pasa al entrar; lo mismo para la salida.
  3. "Otro" no tiene un resultado fijo: lo elige el vigilante cada vez.
- **Pregunta sugerida:** *"Cuando algo no cumple en portería, ¿cada solución que ustedes aplican tiene siempre el mismo efecto? Por ejemplo, 'ingresa con escolta' ¿siempre significa que la persona entra? Y cuando eligen 'Otro', ¿deciden ustedes en ese momento si entra o no?"*
- **Si no se resuelve:** quedan las tres reglas de arriba.

**P-07 · Pasaporte y carné de extranjería** *(junto con RRHH, sugerido)*

- **Qué significa:** el DNI solo tiene números, pero el pasaporte y el carné de extranjería pueden llevar letras. Hoy el sistema guarda el documento tal como se escribe, así que "ab12345" y "AB12345" quedarían como **dos personas distintas**. Además falta saber el largo mínimo y máximo de esos documentos.
- **Pregunta sugerida:** *"¿Un mismo pasaporte puede escribirse con minúsculas y mayúsculas y ser el mismo? ¿Cuántos caracteres tienen como mínimo y como máximo un pasaporte y un carné de extranjería?"*
- **Recomendación:** guardar siempre en mayúsculas, en visitantes y en trabajadores. Basta con un sí para aplicarlo.

**P-11 · Estados de la visita y empresa del visitante** *(junto con Sandra)*

- **Qué significa:** para los próximos hitos, el sistema usa estados como "Pendiente", "Aprobada", "Dentro", "Salió" o "Por revisar". Además, la empresa de donde viene el visitante se escribe a mano: no se elige de una lista.
- **Pregunta sugerida:** *"¿Estos nombres de estado reflejan cómo hablan ustedes de una visita? ¿Les falta alguno? ¿Necesitan elegir la empresa del visitante de una lista, o basta con escribirla?"*
- **Si no se resuelve:** se mantienen los estados del modelo y la empresa como texto libre.

### SST (con Control de Activos)

**P-02 · Zonas de Villa El Salvador y lo que exige cada una**

- **Qué significa:** el sistema tiene 7 zonas de ejemplo para VES. Cada zona es **administrativa** u **operativa**, y puede exigir SCTR, EPP o ambos. De eso depende qué se le revisa a un visitante en portería.
- **Pregunta sugerida:** *"¿Cuáles son las zonas reales de la sede VES a las que puede ir un visitante? En cada una, ¿se exige SCTR? ¿Se exige EPP?"*
- **Si no se resuelve:** portería revisa según las zonas de ejemplo.

### TI

**P-10 · Nombres de las bases en el servidor de producción**

- **Qué significa:** el sistema guarda su información en dos "contenedores": uno con lo común a la empresa (usuarios, sedes) y otro solo de Control de Accesos. Sus nombres en el servidor final tienen que acordarse con TI para que no choquen con lo que ya existe.
- **Pregunta sugerida:** *"Para instalar Control de Accesos en HANA, ¿podemos usar los schemas `CAF_GOVERNANCE` y `TRIANONSATELITAL_CAF_PRODD`, o prefieren otros nombres? ¿En qué servidor se instalaría?"*
- **Si no se resuelve:** no bloquea el piloto en PostgreSQL. Bloquea la instalación en HANA.

### Por definir

**P-08 · Razón social y RUC de las cuatro empresas del grupo** *(sugerido: Contabilidad)*

- **Qué significa:** cada trabajador pertenece a una de las empresas del grupo. Faltan sus datos oficiales.
- **Pregunta sugerida:** *"¿Me confirmas la razón social y el RUC de las cuatro empresas del grupo?"*

**P-09 · Dirección de las sedes** *(sugerido: Administración)*

- **Qué significa:** las sedes (VES y, más adelante, Magdalena) se registran sin dirección.
- **Pregunta sugerida:** *"¿Cuál es la dirección oficial de cada sede, como debe aparecer en los documentos?"*

---

## 4. Tareas internas T-01 a T-07 (no requieren preguntar a nadie)

| # | Qué es | Cuándo |
| --- | --- | --- |
| T-01 | **D-35.** Cuando existan las tablas de solicitudes, portería e incidencias, los procedimientos que **eliminan** zonas, motivos, tratamientos, tipos de incidencia, tipos de acceso e ítems deben revisar también esas tablas, para que no se borre algo que está en uso. El lugar está marcado en el código. | Fase 1 de los Hitos 2, 3 y 4 |
| T-02 | Traducir a la forma de HANA la carga inicial de zonas (script 05), que hoy usa una construcción que HANA no tiene. | Antes de instalar en HANA |
| T-03 | **Decisión técnica del usuario.** Los archivos de `Docs_BD` que dicen "TABLAS" traen también las rutinas, y cada rutina aparece en dos archivos. No rompe nada, pero un buscador encuentra cada rutina duplicada y el archivo de tablas del módulo pasará de 21 KB a unos 120 KB. Se puede separar para que "TABLAS" tenga solo tablas. | Cuando quiera; conviene antes de la Fase 2 |
| T-04 | **Decisión técnica del usuario (D-38).** Se agregó el proyecto `Infrastructure.Contracts` para las interfaces de los repositorios, como hace Trianon; no estaba en la estructura aprobada. La alternativa es guardarlas dentro de `Application.Contracts` (un proyecto menos). | Antes de la Fase 6 |
| T-05 | **Riesgo para HANA (D-48).** En PostgreSQL, si un procedimiento de escritura falla a medias, no queda nada escrito. En HANA no ocurre solo: la capa .NET debe abrir una transacción por cada llamada de escritura y revertirla si el código de respuesta es 500. Hay que probarlo con una falla provocada antes de instalar. | Fase 2 de .NET del Hito 2, y antes de instalar en HANA |
| T-06 | Traducir a HANA los procedimientos del Hito 2 siguiendo la sección 3-quater de `EQUIVALENCIAS_POSTGRESQL_HANA.md` (alias en `UPDATE`, bucle `WHILE`, `LIKE_REGEXPR`, `LOCATE`, funciones escalares). | Antes de instalar en HANA |
| T-07 | **Confirmar con Sandra (D-50).** El procedimiento no permite retirar a la última persona de una solicitud: pide cancelarla. El prototipo sí lo permitía y mostraba «sin personas». Si prefiere lo del prototipo, se cambia en un solo lugar. | Presentación del prototipo |

---

## 5. Resueltos

| # | Tema | Registrado | Resolución |
| --- | --- | --- | --- |
| P-70 y P-82 | Botón «Registrar incidencia» en cada persona de Control de accesos (como el prototipo). | 2026-10-24 | Construido (D-146) |
| P-56 | Estilo de la web: se construyó con el diseño del prototipo aprobado. | 2026-10-19 | Construido (según prototipo) |
