# Entrega del 2026-10-18 · Hito 4 (incidencias, correos y reporte), Fase 1: procedimientos y pruebas

Este zip trae **solo los archivos nuevos o modificados**, con la estructura de tu repositorio: cópialos encima.

## Qué trae
- **Hito 4 / `00_BD`** (3 archivos nuevos, 15 rutinas): incidencias (registrar, decidir, listar, detalle, personas, contadores, buscar personas), bandeja de correos (pendientes, marcar enviado, marcar error, listar, reencolar) y reporte (accesos, resumen diario, autorizados por zona).
- **Pruebas:** `PRUEBAS_FASE1_HITO4_ESCRITURA.sql` (135) y `PRUEBAS_FASE1_HITO4_LECTURA.sql` (113).
- **`DECISIONES_HITO4.md`:** decisiones D-74 a D-85 y pendientes P-46 a P-50 y T-09 (para `PENDIENTES_VALIDACION.md`).
- `restaurar_bd.ps1` (solo cambia el mensaje final), `Docs_BD` regenerado, `WORKING_CONTEXT.md` actualizado y el generador de pruebas en `Docs_BD/_tools`.
- No hay cambios de tablas.

## Qué comprobar en tu equipo
Sobre tu base de trabajo, solo rutinas y pruebas:
```powershell
.\restaurar_bd.ps1 -Database accesos_piloto_prueba -SoloRutinas
.\restaurar_bd.ps1 -Database accesos_piloto_prueba -SoloPruebas
```
Esperado: 59 + 114 rutinas y pruebas 65, 143, 43, 186, 202, 140, 100, **135 y 113** en OK.

## Siguiente
Capas .NET del Hito 4 (DTOs, repositorios, servicios).
