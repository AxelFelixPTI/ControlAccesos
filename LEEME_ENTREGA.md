# Entrega del 2026-10-16 · Permisos atómicos y pasos de aprobación

Este zip trae **solo los archivos nuevos o modificados**. Su estructura de carpetas es la misma de tu repositorio, así que puedes copiarlos encima y revisar los cambios con tu control de versiones.

**No reemplaces tu carpeta completa:** tu copia (con los procedimientos del Hito 1 y la solución .NET) es la buena. Aquí solo hay lo que cambia.

## Qué cambia y por qué

El sistema estaba atado a un solo aprobador (el Coordinador) y los permisos se preguntaban por el nombre del rol. Eso iba a estorbar al habilitar contratistas, proveedores y personal interno visitante. Ahora:

- Un rol es un **conjunto de permisos** y se edita como dato. Un aprobador de almacén puede aprobar sin ver desviaciones, incidencias ni el reporte.
- Cada tipo de acceso define sus **pasos de aprobación**: cuántos, en qué orden, qué rol decide y si se decide por persona o por toda la solicitud.
- La aprobación pasa a registrarse **por persona y por paso**, con su historial.

**El flujo de visitante externo no cambia:** es el caso de un solo paso. Las 208 pruebas que ya tenías siguen pasando.

## Archivos

| Archivo | Qué es |
| --- | --- |
| `Docs_Modulos/HITO_02.../00_BD/09_ALTER_PERMISOS_Y_FLUJOS.sql` | **Nuevo.** Las 4 tablas, las columnas nuevas y la carga inicial |
| `Docs_Modulos/HITO_00_01.../00_BD/SP_GOVERNANCE_PERMISO_ALL.sql` | **Nuevo.** 5 rutinas de permisos y roles |
| `Docs_Modulos/HITO_02.../00_BD/SP_CAF_TIPO_ACCESO_PASO_APROBACION_ALL.sql` | **Nuevo.** 4 rutinas de los pasos de aprobación |
| `Docs_Modulos/HITO_02.../00_BD/PRUEBAS_FASE1_PERMISOS.sql` | **Nuevo.** 43 pruebas automáticas |
| `Docs_Modulos/MODELO_DATOS_ETAPA1.md` | **Modificado.** Sección 3-bis y decisiones D-31 a D-36 |
| `Docs_BD/EQUIVALENCIAS_POSTGRESQL_HANA.md` | **Modificado.** Sección 3-ter y dos diferencias nuevas registradas |
| `Docs_BD/*.sql` y `00_INVENTARIO_GLOBAL.md` | **Regenerados** desde la base con todo aplicado |
| `Docs_Cerebro/WORKING_CONTEXT.md` | **Modificado.** Dónde estamos y qué sigue |

## Cómo instalarlo

**Antes de empezar, comprueba tu base.** El script 09 necesita que ya existan las tablas de los scripts 06 a 08. Ejecuta esto en `psql` y mira el número:

```sql
SELECT COUNT(*) FROM information_schema.tables
 WHERE table_schema = 'TRIANONSATELITAL_CAF_PRODD' AND table_type = 'BASE TABLE';
```

- **22** → tu base ya tiene los scripts 06 a 08. Sigue con "Instalación".
- **8** → faltan los scripts 06 a 08. Ejecútalos primero, en este orden:

```powershell
cd <tu repo>\Docs_Modulos
psql -U postgres -d accesos_piloto -v ON_ERROR_STOP=1 -f "HITO_02_Solicitud_Aprobacion_2026-10-09\00_BD\06_CAF_SOLICITUD.sql"
psql -U postgres -d accesos_piloto -v ON_ERROR_STOP=1 -f "HITO_03_Porteria_Desviaciones_2026-10-09\00_BD\07_CAF_PORTERIA.sql"
psql -U postgres -d accesos_piloto -v ON_ERROR_STOP=1 -f "HITO_04_Incidencias_Reporte_Correos_2026-10-09\00_BD\08_CAF_INCIDENCIAS_CORREOS.sql"
```

### Si ya ejecutaste una versión anterior del 09 y falló

La versión 1.0 no verificaba sus requisitos y pudo dejar cambios a medias. Antes de reintentar, limpia (es seguro: esas tablas están vacías):

```sql
DROP TABLE IF EXISTS "TRIANONSATELITAL_CAF_PRODD"."Tipo_Acceso_Paso_Aprobacion";
DROP TABLE IF EXISTS "CAF_GOVERNANCE"."Licencia_Permiso";
DROP TABLE IF EXISTS "CAF_GOVERNANCE"."Catalogo_Permiso";
ALTER TABLE "CAF_GOVERNANCE"."Catalogo_Licencia" DROP CONSTRAINT IF EXISTS "CK_Catalogo_Licencia_Sistema";
ALTER TABLE "CAF_GOVERNANCE"."Catalogo_Licencia" DROP COLUMN IF EXISTS "Es_Sistema";
```

### Instalación

Con tu base ya en 22 tablas (scripts 01 a 08 aplicados):

```powershell
cd <tu repo>\Docs_Modulos\HITO_02_Solicitud_Aprobacion_2026-10-09\00_BD
psql -U postgres -d accesos_piloto -v ON_ERROR_STOP=1 -f "09_ALTER_PERMISOS_Y_FLUJOS.sql"
psql -U postgres -d accesos_piloto -v ON_ERROR_STOP=1 -f "..\..\HITO_00_01_Base_y_Catalogos_2026-10-09\00_BD\SP_GOVERNANCE_PERMISO_ALL.sql"
psql -U postgres -d accesos_piloto -v ON_ERROR_STOP=1 -f "SP_CAF_TIPO_ACCESO_PASO_APROBACION_ALL.sql"
psql -U postgres -d accesos_piloto -f "PRUEBAS_FASE1_PERMISOS.sql"
```

**El script 09 versión 1.1 es todo o nada**: va dentro de una transacción y verifica sus requisitos antes de tocar nada. Si faltan los scripts 06 a 08, o si ya se ejecutó, se detiene con un mensaje claro y no deja nada a medias. Se ejecuta **una sola vez**.

**Resultado esperado**, verificado el 16/10/2026 en PostgreSQL 16 desde una base limpia:

| Comprobación | Resultado |
| --- | --- |
| Tablas | 11 en `CAF_GOVERNANCE`, 24 en el módulo (35 en total) |
| Rutinas | 59 en `CAF_GOVERNANCE`, 47 en el módulo (106 en total) |
| `PRUEBAS_FASE1_HITO0.sql` | 65 de 65 OK |
| `PRUEBAS_FASE1_HITO1.sql` | 143 de 143 OK |
| `PRUEBAS_FASE1_PERMISOS.sql` | 43 de 43 OK |

Después de instalarlo, regenera tu `Docs_BD` con tu propio script, para que refleje tu base y no la mía.

## Un error que encontraron las pruebas

La primera versión de `ERP_LICENCIA_PERMISO_ASIGNAR` usaba una tabla temporal y fallaba al llamarla dos veces en la misma transacción. Se reescribió sin tablas temporales, con una lista de códigos separados por comas. La versión corregida es la que va en este zip, y la diferencia quedó registrada en la tabla de equivalencias.

## Lo que no se tocó

- Las 97 rutinas del Hito 0 y 1, ni la solución .NET.
- Los scripts 01 a 08: un script ejecutado no se edita.
- Las tablas de portería, checklist, desviaciones, incidencias y bitácora.

## Qué sigue

1. Instalar y confirmar las 251 pruebas en OK.
2. Fase 1 del Hito 2: los procedimientos de solicitudes, ya con varios pasos de aprobación.
3. Las capas .NET de lo nuevo, con tu generador de capas.
4. Las preguntas para Sandra están en el documento **Preguntas pendientes de afinación**.
