# Entrega del 2026-10-21 · Vigilancia: Control de accesos

Solo archivos nuevos o modificados, con la estructura del repositorio: cópialos encima. No hay cambios de base de datos ni de proyectos (no hace falta tocar el .slnx).

## Qué trae
- **Control de accesos** (menú Vigilancia): las personas autorizadas **para hoy**, agrupadas por solicitud. Buscador (documento, nombre o empresa) y pestañas Todos / Por ingresar / Dentro / Salieron / Denegados o no vinieron, con su cantidad.
- **Validar ingreso**: checklist (con «Marcar todo»), interruptores «Trae equipos» y «Trae herramientas o materiales» que cambian los ítems, **respaldo** (G-FSCA-009, guía de remisión o G-FSCA-010) que se registra ahí mismo, **desviación** cuando un ítem no se cumple (coordinador consultado, tratamiento, efecto si es «Otro») y **registro tardío** (hora real + motivo).
- **Registrar salida** con su checklist, y **Detalle** con los movimientos de la persona.
- **No autorizado para hoy**: si buscas a alguien que no está en la lista, te dice quién es y por qué no puede pasar.
- Archivos: `VigilanciaController`, `VigilanciaModelos`, vista `Vigilancia/Index`, `vigilancia.js`, menú (se enciende «Control de accesos»), documentos (D-121 a D-128, P-70 a P-74, T-17).

## Pasos
1. Copia los archivos y haz Rebuild All. Arranca la web y recarga con Ctrl+F5.
2. Necesitas un usuario con rol **Vigilancia** (permiso de portería) y una solicitud **aprobada con fecha de hoy**. Si no la tienes: crea una solicitud para hoy como Solicitante y apruébala como Coordinador.

## Qué probar
1. Entra como Vigilancia: en el menú aparece **Control de accesos** con la lista de hoy.
2. **Ingreso limpio**: «Validar ingreso» → «Marcar todo» → Registrar. La persona pasa a «Dentro».
3. **Con equipos**: marca «Trae equipos»; intenta registrar sin respaldo (debe pedirlo); registra el respaldo y vuelve a registrar.
4. **Con desviación**: deja un ítem sin marcar; aparece el bloque amarillo; elige coordinador y tratamiento. Si el ítem es de identidad (crítico) solo deja denegar.
5. **Salida** de la persona que está dentro, y **Detalle** para ver el checklist guardado.
6. Busca un documento que no esté en ninguna solicitud de hoy: aparece el cuadro rojo.

Si algo falla con «No se pudo completar la operación en la base de datos», envíame la línea «ESCRITURA ... ERROR» de la ventana de salida de Visual Studio.

## Siguiente
Desviaciones y incidencias (coordinador), incidencias del día (Vigilancia) y reporte de accesos.
