# Entrega del 2026-10-23 · Usuarios de demostración y limpieza de datos

Solo archivos nuevos o modificados, con la estructura del repositorio. No hay cambios de código .NET.

## Qué trae
- **`11_SEED_DEMO_USUARIOS.sql`** (Hito 0 · 00_BD): crea en Personal y Usuarios a 8 personas **ficticias**, cada una con su licencia en VES. `restaurar_bd.ps1` lo ejecuta solo (va por su número, después de los catálogos).
- **`LIMPIAR_DATOS_PRUEBA.sql`** (misma carpeta): script **manual** para empezar con datos reales. `restaurar_bd.ps1` no lo ejecuta.
- Dos archivos de pruebas ajustados (`PRUEBAS_FASE1_HITO2_ESCRITURA.sql` y `PRUEBAS_FASE1_HITO3_LECTURA.sql`) para que no se confundan con los usuarios de demostración.
- Documentos: D-132 a D-135, P-76, P-77, T-19.

## Usuarios de prueba (todos ficticios, sede VES)
| Rol | Correo | Contraseña |
|---|---|---|
| Administrador | admin.demo@trianon.test | Admin.Demo#2026 |
| Coordinador | coordinador.demo@trianon.test | Coord.Demo#2026 |
| Vigilancia (3) | vigilante1.demo@trianon.test, vigilante2.demo@…, vigilante3.demo@… | Vigi.Demo#2026 |
| Solicitante (3) | solicitante1.demo@trianon.test, solicitante2.demo@…, solicitante3.demo@… | Solic.Demo#2026 |

Entran directo, sin pedir cambio de contraseña. Los correos no existen: si el envío de correos está activo, esos avisos no llegan a nadie.

## Pasos
1. Copia los archivos al repositorio.
2. **Base nueva o reconstruida:** `.\restaurar_bd.ps1 -Database accesos_piloto_prueba` (con `-Crear` si no existe). Al terminar, ya puedes entrar con los usuarios de arriba.
3. **Tu base actual (sin reconstruir):** `psql -U postgres -d accesos_piloto_prueba -f "Docs_Modulos\HITO_00_01_Base_y_Catalogos_2026-10-09\00_BD\11_SEED_DEMO_USUARIOS.sql"`. Se puede repetir sin duplicar nada.

## Para empezar con datos reales (limpieza)
1. Entra como `admin.demo@trianon.test` → Usuarios y roles → crea **tu administrador real** (con la licencia de administrador), define su contraseña con el enlace y comprueba que puedes entrar con él.
2. Abre `LIMPIAR_DATOS_PRUEBA.sql` y cambia `PARAM_ADMIN_CONSERVAR` por el correo de tu administrador real.
3. Ejecuta: `psql -U postgres -d accesos_piloto_prueba -f "Docs_Modulos\HITO_00_01_Base_y_Catalogos_2026-10-09\00_BD\LIMPIAR_DATOS_PRUEBA.sql"`

Qué hace: **borra** solicitudes, personas externas, decisiones, movimientos de portería, respaldos, desviaciones, incidencias, correos pendientes y bitácora (y reinicia los números); borra los usuarios y el Personal de prueba (correo `@trianon.test`) salvo el administrador que indiques. **No toca** catálogos ni a los usuarios y Personal que hayas creado tú. Si no quedara ningún administrador activo con contraseña, se cancela todo y no se borra nada.

Si solo quieres borrar los datos de operación y dejar los usuarios de prueba, cambia `PARAM_BORRAR_USUARIOS_DEMO` a `FALSE`.

## Qué probar
1. Reconstruye una base y entra con cada rol: cada uno ve su menú (Administrador: Usuarios y roles, Catálogos, Personal; Solicitante: Mis solicitudes y Nueva; Coordinador: Solicitudes; Vigilancia: Control de accesos).
2. Haz el ciclo completo: solicitante crea una solicitud para hoy → coordinador aprueba → vigilancia registra el ingreso.
3. Ejecuta la limpieza y comprueba que las pantallas quedan vacías y que sigues entrando.

## Siguiente
Desviaciones e incidencias (coordinador), incidencias del día (Vigilancia) y reporte de accesos.
