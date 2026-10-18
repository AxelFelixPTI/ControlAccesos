# Entrega del 2026-10-17 · Hito 3 (portería y desviaciones), Fase 1: procedimientos y pruebas

Este zip trae **solo los archivos nuevos o modificados**, con la estructura de tu repositorio: cópialos encima.

## Qué trae
- **Hito 3 / `00_BD`** (4 archivos nuevos, 20 rutinas): desviaciones (validar, crear, dar conformidad), portería (ítems del checklist, regla única de ingreso/salida, registrar ingreso, registrar salida, cierre «no se presentó»), respaldos y 11 lecturas (checklist, ficha, bitácora, detalle, respaldos, desviaciones, contadores, listas desplegables).
- **Pruebas:** `PRUEBAS_FASE1_HITO3_ESCRITURA.sql` (140) y `PRUEBAS_FASE1_HITO3_LECTURA.sql` (100).
- **`DECISIONES_HITO3.md`:** decisiones D-62 a D-73 y pendientes P-40 a P-45 y T-08 (para `PENDIENTES_VALIDACION.md`).
- `restaurar_bd.ps1` (solo cambia el mensaje final), `Docs_BD` regenerado, `WORKING_CONTEXT.md` actualizado y el generador de pruebas en `Docs_BD/_tools`.
- No hay cambios de tablas.

## Qué comprobar en tu equipo
Sobre tu base de trabajo, solo rutinas y pruebas:
```powershell
.\restaurar_bd.ps1 -Database accesos_piloto_prueba -SoloRutinas
.\restaurar_bd.ps1 -Database accesos_piloto_prueba -SoloPruebas
```
Esperado: 59 + 99 rutinas y pruebas 65, 143, 43, 186, 202, **140 y 100** en OK.

## Siguiente
Capas .NET del Hito 3 (DTOs, repositorios, servicios).
