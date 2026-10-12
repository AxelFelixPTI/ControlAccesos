# Pendientes de validación · Control de Accesos

Actualizado: 2026-10-11 · tras la Fase 1 del Hito 1

Este archivo reúne todo lo que el sistema necesita que **una persona del negocio confirme o decida**. Ninguno de estos puntos detiene el desarrollo hoy: el sistema se construyó con una suposición razonable, que puede ajustarse después. Cada punto dice **cuándo** hace falta la respuesta. Pasada esa fecha, cambiar la suposición cuesta más.

Cómo usarlo:

1. Antes de cada reunión, filtra por la persona (sección 2).
2. Haz la **pregunta sugerida** tal cual o con tus palabras.
3. Anota la respuesta en la columna *Estado* de la tabla de resumen y avísame en la siguiente sesión. Yo ajusto el sistema y el documento técnico.

Los códigos **D-xx** son las decisiones del documento técnico (`Docs_Modulos/.../00_PAQUETE_DISENO.md`). Los **P-xx** son los números de este archivo y no cambian aunque se resuelvan.

---

## 1. Resumen

| # | Tema | D-* | Con quién | Se necesita antes de | Estado |
| --- | --- | --- | --- | --- | --- |
| P-01 | Listas reales de áreas, cargos, motivos de visita y tipos de incidencia | — | Sandra, con Control de Activos y SST | Cargar datos reales (piloto con usuarios) | Pendiente |
| P-02 | Zonas reales de VES y cuáles exigen SCTR y EPP | D-08, D-18 | SST, con Control de Activos | Cargar datos reales | Pendiente |
| P-03 | Copias de correo: ¿reciben todos los avisos de la solicitud? | — | Sandra | Hito 4 (correos) | Pendiente |
| P-04 | Qué pasa con la persona en cada tratamiento de desviación | D-11, D-32 | Vigilancia | Hito 3 (portería) | Pendiente |
| P-05 | Pantalla de solicitud con el nombre en tres campos | D-10 | Quien aprobó el mockup *(por definir; sugerido: Sandra)* | Hito 2 (pantalla de solicitud) | Pendiente |
| P-06 | Preparar el checklist de contratistas antes de habilitarlos | D-34 | Sandra *(sugerido)* | Etapa 2 (contratistas) | Pendiente |
| P-07 | Pasaporte y carné de extranjería: mayúsculas y largo | — | Vigilancia y RRHH *(sugerido)* | Hito 2 (registro de visitantes) | Pendiente |
| P-08 | Razón social y RUC de las cuatro empresas del grupo | — | *Por definir (sugerido: Contabilidad)* | Cargar datos reales | Pendiente |
| P-09 | Dirección de las sedes | — | *Por definir (sugerido: Administración)* | Cargar datos reales | Pendiente |
| P-10 | Nombres de las bases en el servidor de producción | D-03, D-04 | TI | Instalación en HANA | Pendiente |
| P-11 | Estados de la visita y empresa del visitante | D-13 | Vigilancia y Sandra | Inicio del Hito 2 | Pendiente |

Cuando la persona no figura en los documentos del proyecto, dice **por definir** con una sugerencia. Confírmala tú.

---

## 2. Por persona

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

## 3. Tareas internas (no requieren preguntar a nadie)

| # | Qué es | Cuándo |
| --- | --- | --- |
| T-01 | **D-35.** Cuando existan las tablas de solicitudes, portería e incidencias, los procedimientos que **eliminan** zonas, motivos, tratamientos, tipos de incidencia, tipos de acceso e ítems deben revisar también esas tablas, para que no se borre algo que está en uso. El lugar está marcado en el código. | Fase 1 de los Hitos 2, 3 y 4 |
| T-02 | Traducir a la forma de HANA la carga inicial de zonas (script 05), que hoy usa una construcción que HANA no tiene. | Antes de instalar en HANA |
| T-03 | **Decisión técnica del usuario.** Los archivos de `Docs_BD` que dicen "TABLAS" traen también las rutinas, y cada rutina aparece en dos archivos. No rompe nada, pero un buscador encuentra cada rutina duplicada y el archivo de tablas del módulo pasará de 21 KB a unos 120 KB. Se puede separar para que "TABLAS" tenga solo tablas. | Cuando quiera; conviene antes de la Fase 2 |

---

## 4. Resueltos

*(Cuando un punto se resuelva, se mueve aquí con la fecha y la respuesta.)*

| # | Fecha | Respuesta | Quién respondió |
| --- | --- | --- | --- |
| — | — | — | — |
