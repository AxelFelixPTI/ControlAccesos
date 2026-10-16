# Working context · Control de Accesos

Actualizado: 2026-10-11

## Dónde estamos

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

Fase 1 del Hito 2: los procedimientos de solicitudes, escritos ya con varios pasos de aprobación. El primero es el que calcula la aprobación de cada persona y el estado de la solicitud, porque todos los demás lo llaman. Después, las capas .NET de lo nuevo con `gen_capas_catalogos.py`.

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
