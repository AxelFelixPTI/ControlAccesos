# Entrega del 2026-10-17 · Hito 2, parte 2 (lectura)

Este zip trae **solo los archivos nuevos o modificados**, con la estructura de tu repositorio: cópialos encima.

## Qué trae
- `SP_CAF_SOLICITUD_LECTURA_ALL.sql`: 14 rutinas de lectura (Mis solicitudes, bandeja de quien aprueba, contadores, detalle, personas, ruta de aprobación, historial, versiones y listados de Vigilancia). Los botones (editar, cancelar, retirar...) los decide la base, no la pantalla.
- `PRUEBAS_FASE1_HITO2_LECTURA.sql`: 202 pruebas, terminan en ROLLBACK.
- `DECISIONES_HITO2_LECTURA.md`: decisiones D-56 a D-61 y pendientes T-05 a T-07.
- `restaurar_bd.ps1` actualizado, `Docs_BD` regenerado, `WORKING_CONTEXT.md` actualizado.

## Cómo aplicarlo en tu base `accesos_piloto_prueba`
```powershell
.\restaurar_bd.ps1 -Database accesos_piloto_prueba -SoloRutinas
```
(Nota: ya tiene tablas, por eso `-SoloRutinas`; luego corre las pruebas con `-SoloPruebas`.)
Esperado: pruebas 65, 143, 43, 186 y **202** en OK; 11 + 24 tablas y 59 + **79** rutinas.

## Aún no
La solución .NET del Hito 2 viene después de que confirmes estos resultados.
