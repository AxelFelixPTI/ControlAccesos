# Entrega del 2026-10-16 · Hito 2, parte 1: procedimientos de escritura de solicitudes

Este zip trae **solo los archivos nuevos o modificados** desde la entrega anterior, con la estructura de carpetas de tu repositorio. Cópialos encima y revisa los cambios con git. **No reemplaces tu carpeta completa.**

## Qué trae

Los procedimientos con los que se crea y se mueve una solicitud, con las reglas que acordamos para la aprobación por persona. **Lo único que falta del Hito 2 son las lecturas** (listados y detalle), que serán la parte 2.

| Operación | Procedimiento |
| --- | --- |
| Crear y enviar a aprobación (también «Reutilizar») | `ERP_CAF_SOLICITUD_CREAR` |
| Editar los datos de la visita | `ERP_CAF_SOLICITUD_EDITAR_DATOS` |
| Cancelar | `ERP_CAF_SOLICITUD_CANCELAR` |
| Agregar una persona (o volver a agregar a una retirada) | `ERP_CAF_SOLICITUD_PERSONA_AGREGAR` |
| El Coordinador agrega a quien llegó sin estar | `ERP_CAF_SOLICITUD_PERSONA_AGREGAR_APROBADA` |
| Retirar una persona | `ERP_CAF_SOLICITUD_PERSONA_RETIRAR` |
| Corregir y reenviar a una observada | `ERP_CAF_SOLICITUD_PERSONA_CORREGIR` |
| Aprobar, observar o rechazar personas en un paso | `ERP_CAF_SOLICITUD_DECIDIR` |

Más 10 piezas internas en `SP_CAF_SOLICITUD_BASE_ALL.sql`: la bitácora con único escritor, la bandeja de correos, el cálculo de a quién avisar, y el **recálculo de la aprobación**, la única pieza que escribe el estado de cada persona y de la solicitud.

## Archivos

| Archivo | Qué es |
| --- | --- |
| `Docs_Modulos/HITO_02.../00_BD/10_ALTER_CORREOS_DECISION.sql` | **Nuevo.** Dos tipos de correo para las decisiones por persona |
| `.../SP_CAF_SOLICITUD_BASE_ALL.sql` | **Nuevo.** Piezas internas. **Se carga primero** |
| `.../SP_CAF_SOLICITUD_ALL.sql` | **Nuevo.** Crear, editar datos, cancelar |
| `.../SP_CAF_SOLICITUD_PERSONA_ALL.sql` | **Nuevo.** Agregar, agregar aprobada, retirar, corregir |
| `.../SP_CAF_SOLICITUD_DECISION_ALL.sql` | **Nuevo.** Decidir |
| `.../PRUEBAS_FASE1_HITO2_ESCRITURA.sql` | **Nuevo.** 186 pruebas automáticas |
| `Docs_Modulos/MODELO_DATOS_ETAPA1.md` | **Modificado.** Decisiones renumeradas (ver abajo) y las nuevas D-47 a D-55 |
| `Docs_BD/EQUIVALENCIAS_POSTGRESQL_HANA.md` | **Modificado.** Sección 3-quater: lo que hay que traducir y verificar en HANA |
| `Docs_BD/*.sql` y `00_INVENTARIO_GLOBAL.md` | **Regenerados** desde la base con todo aplicado |
| `PENDIENTES_VALIDACION.md` | **Modificado.** Tareas T-05 a T-07 |
| `Docs_Cerebro/WORKING_CONTEXT.md` | **Modificado.** Dónde estamos y qué sigue |

## Cómo instalarlo

**Requisito:** tu base ya tiene los scripts 01 a 09 y las pruebas de la entrega anterior en OK (35 tablas). Para comprobarlo:

```sql
SELECT COUNT(*) FROM information_schema.tables
 WHERE table_schema IN ('CAF_GOVERNANCE','TRIANONSATELITAL_CAF_PRODD') AND table_type = 'BASE TABLE';
```

Debe dar **35**. Si da menos, falta algo de la entrega anterior.

Con eso, desde la carpeta `Docs_Modulos\HITO_02_Solicitud_Aprobacion_2026-10-09\00_BD`:

```powershell
$d = "accesos_piloto"
psql -U postgres -d $d -v ON_ERROR_STOP=1 -f "10_ALTER_CORREOS_DECISION.sql"
psql -U postgres -d $d -v ON_ERROR_STOP=1 -f "SP_CAF_SOLICITUD_BASE_ALL.sql"
foreach ($f in "SP_CAF_SOLICITUD_ALL","SP_CAF_SOLICITUD_PERSONA_ALL","SP_CAF_SOLICITUD_DECISION_ALL") {
  psql -U postgres -d $d -v ON_ERROR_STOP=1 -q -f "$f.sql"
  if ($LASTEXITCODE -ne 0) { Write-Host "Falló $f"; break }
}
psql -U postgres -d $d -f "PRUEBAS_FASE1_HITO2_ESCRITURA.sql"
```

El script 10 va dentro de una transacción y verifica sus requisitos: si faltan los scripts 06 a 09, o si ya se ejecutó, se detiene con un mensaje claro y no deja nada a medias. Los archivos de procedimientos usan `CREATE OR REPLACE`: se pueden volver a ejecutar sin problema.

**Resultado esperado**, verificado el 2026-10-16 en PostgreSQL 16 desde una base limpia:

| Comprobación | Resultado |
| --- | --- |
| Tablas | 35 (11 transversales y 24 del módulo) |
| Rutinas | 124 (59 transversales y 65 del módulo) |
| `PRUEBAS_FASE1_HITO0.sql` | 65 de 65 OK |
| `PRUEBAS_FASE1_HITO1.sql` | 143 de 143 OK |
| `PRUEBAS_FASE1_PERMISOS.sql` | 43 de 43 OK |
| `PRUEBAS_FASE1_HITO2_ESCRITURA.sql` | **186 de 186 OK** |

La prueba nueva muestra **solo las filas que fallan** y un resumen al final. Si todo está bien verás una tabla vacía y `RESULTADO: 186 de 186 OK`. Termina en `ROLLBACK`: no deja nada en tu base y se puede repetir.

Después de instalar, regenera tu propio `Docs_BD` con tu script de `_tools`, para que refleje tu base y no la mía.

## Dos cosas que debes saber

**1. Corregí un choque en la numeración de decisiones.** En la entrega anterior numeré las decisiones de permisos y pasos como D-31 a D-36, pero tu paquete de diseño ya usa D-31 a D-40 para los catálogos del Hito 1 y la capa .NET. Dos decisiones distintas con el mismo número se prestan a confusión. Ahora son **D-41 a D-46**, y las del Hito 2 son **D-47 a D-55**. El `MODELO_DATOS_ETAPA1.md` de este zip reemplaza al anterior.

**2. Un riesgo para cuando llegue HANA.** En PostgreSQL, si un procedimiento de escritura falla a medias, **no queda nada escrito**. En HANA eso no ocurre solo: la capa .NET deberá abrir una transacción por cada escritura y revertirla si el código de respuesta es 500. Está en `PENDIENTES_VALIDACION.md` como T-05, en la sección 3-quater de las equivalencias, y hay que probarlo con una falla provocada antes de instalar.

## Una diferencia con el prototipo

El procedimiento **no permite retirar a la última persona** de una solicitud: pide cancelarla. El prototipo sí lo permitía y mostraba «sin personas». Es la decisión D-50 y la tarea T-07 para confirmarla con Sandra. Si prefiere lo del prototipo, se cambia en un solo lugar.

## Un error que encontraron las pruebas

La primera versión del aviso por correo, al agregar o reenviar una persona, también escribía al área que **ya había aprobado** su parte. Lo detectó una prueba del flujo de tres pasos y quedó corregido: ahora solo se avisa a quien todavía debe decidir. Es el ejemplo de por qué el flujo de varios pasos se probó con datos reales y no solo en papel.

## Qué sigue

1. Instalar y confirmar los 186 en OK.
2. **Parte 2 de la Fase 1 del Hito 2:** los procedimientos de **lectura**: «Mis solicitudes» con filtros, la bandeja del Coordinador por pestañas, el detalle con sus personas y el historial, y los indicadores de qué botón mostrar (`Puede_Editar`, `Puede_Cancelar`), para que esa regla viva en un solo lugar.
3. Las capas .NET del Hito 2, abriendo la transacción por cada escritura.
