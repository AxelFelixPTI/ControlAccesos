# Hito 2 · Fase 1 · parte 2 (lectura) · decisiones D-56 a D-61
V1.0 2026-10-17 · archivo `00_BD/SP_CAF_SOLICITUD_LECTURA_ALL.sql` (14 rutinas) · pruebas `PRUEBAS_FASE1_HITO2_LECTURA.sql` (202 de 202 OK, PostgreSQL 16)

- **D-56** Las reglas de los botones (`Puede_Editar_Datos`, `Puede_Cancelar`, `Puede_Modificar_Personal`, `Puede_Retirar`, `Puede_Corregir`, `Puede_Reactivar`, `Puede_Decidir`) viven en un solo lugar (`ERP_CAF_SOLICITUD_INDICADORES` y `ERP_CAF_SOLICITUD_PASOS_DECIDIBLES`). Las pruebas comprueban que cada botón apagado coincide con el rechazo (409/101) del procedimiento de escritura. El servicio .NET no repite estas reglas (D-40).
- **D-57** Sin permiso, las lecturas devuelven cero filas (no error): quien no es dueño ni aprueba ni tiene «ver todas» no ve la solicitud.
- **D-58** Sin paginación en el servidor: la pantalla filtra/ordena con las filas devueltas (volumen de piloto). Revisar si crece.
- **D-59** Búsqueda sin tildes ni mayúsculas con `ERP_CAF_FN_NORMALIZAR` (TRANSLATE en PostgreSQL; en HANA se traduce con REPLACE anidados, no hay TRANSLATE equivalente).
- **D-60** Listas (zonas, copias, pasos que me tocan) salen como texto separado por comas; la capa .NET las separa.
- **D-61** Vigilancia solo ve personas APROBADAS de solicitudes no canceladas; la búsqueda de «no autorizadas» exige 3 letras y explica el motivo (cancelada, pendiente, observada, rechazada, retirada).

## Para PENDIENTES_VALIDACION.md
- **T-05** El procedimiento de escritura deja la transacción abierta a cargo de la aplicación (una transacción por operación en .NET).
- **T-06** Traducir a HANA el Hito 2 completo, lecturas incluidas (funciones RETURNS TABLE pasan a procedimientos con tabla OUT; sin cursores ni tablas temporales).
- **T-07** Búsqueda sin tildes en HANA (REPLACE anidados) y ausencia de paginación en el servidor (D-58).
