# Control de Accesos · Grupo Trianon

Sistema de control de ingreso y salida de visitantes externos en la sede VES (etapa 1), basado en los procedimientos G-PSCA-002 y G-PSCA-003.

- **Stack:** ASP.NET Core MVC (.NET 10), Razor, JavaScript, procedimientos almacenados sin ORM.
- **Base de datos:** PostgreSQL en el piloto; SAP HANA en el despliegue.
- **Convenciones:** las de Trianon Satelital, para permitir una integración futura.

## Estructura

| Carpeta | Para qué sirve |
| --- | --- |
| `Docs_BD/` | Export de la base de datos por schema. **Fuente de verdad.** Se regenera con `_tools/generar_docs_bd.sh` tras cada despliegue; nunca se edita a mano. Incluye la tabla de equivalencias PostgreSQL → HANA. |
| `Docs_Modulos/` | Una carpeta por hito (`HITO_<NN>_<Nombre>_<fecha>`), con su paquete de diseño, scripts SQL en `00_BD/` y el handoff al cerrarlo. |
| `Docs_Cerebro/` | Contexto vivo del proyecto para retomar entre sesiones. |
| `src/` | Código de la solución (se crea en la Fase 2 del Hito 0). |
| `PENDIENTES_VALIDACION.md` | Preguntas para el negocio (qué significa cada una, a quién preguntar, cuándo hace falta). Se actualiza en cada entrega. |

## Orden de lectura para retomar el trabajo

1. `Docs_Cerebro/WORKING_CONTEXT.md`: en qué estamos.
2. El paquete de diseño del hito activo en `Docs_Modulos/`.
3. `Docs_BD/00_INVENTARIO_GLOBAL.md` y el consolidado del schema que se va a tocar.
4. `Docs_BD/EQUIVALENCIAS_POSTGRESQL_HANA.md` antes de escribir un procedimiento.

## Reglas que no se negocian

- Antes de proponer una tabla, revisar `Docs_BD/`: puede que ya exista.
- Todo acceso a datos pasa por un procedimiento `ERP_*`; ninguna capa escribe SQL.
- Borrado lógico (`Eliminado = 'Y'`), nunca `DELETE`.
- Lo generado es **candidato** hasta que se ejecuta en la base y se regenera `Docs_BD/`.
