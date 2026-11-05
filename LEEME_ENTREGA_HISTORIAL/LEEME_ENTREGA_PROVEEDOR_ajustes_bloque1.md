# Entrega: Proveedores — Ajustes del calendario (bloque 1)

ZIP acumulado desde la Entrega C. Solo cambia la web; **no hay scripts de base de datos nuevos**. El LEEME anterior está en `LEEME_ENTREGA_HISTORIAL/`.

## Qué trae
- Leyenda arriba del calendario (plegable): estados, empresas y marcas.
- Distintivo de reserva: borde grueso y cinta «EXCLUSA RESERVADA» en la entrega que tiene la exclusa; «POR SALIR» (borde fino) en Recepción culminada; sin distintivo en Salió (opción A).
- Vista Día junto a Mes y Semana, con filtros y navegación día anterior/siguiente.
- `LIMPIAR_DEMO_PROVEEDOR.sql` (opcional): borra solo la demo de proveedor para volver a cargarla.

## Cómo aplicarlo
Copiar los archivos, compilar y publicar. Sin scripts SQL.

## Qué probé
47 pruebas de navegador (1280 y 390 px) con servicios simulados: leyenda, distintivos, vista Día con filtros y navegación, y lo anterior sin regresión. Compila.

## Qué NO probé
Npgsql real, HANA, SMTP, IIS, tiempo real. La exclusa en tu base se verá con distintivo cuando exista una reserva real.
