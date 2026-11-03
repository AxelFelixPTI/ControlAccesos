# Entrega 1 de Proveedor de abastecimiento (2026-11-02) · Base de datos y reglas (sin pantallas)

Construye sobre las entregas C, D, D1, E, F, J y H (incluye sus archivos, completos; las anteriores están en `LEEME_ENTREGA_HISTORIAL/`, la de H como `LEEME_ENTREGA_H_tipo_de_ingreso.md`). Si ya aplicó alguna, copiar encima no la daña.

## Qué trae (todo en la base de datos; la web solo se adaptó para compilar)
- **Datos propios del proveedor** (D-194): empresa del grupo que recibe, RUC, dirección, marca, licencia de conducir, placa siempre obligatoria, teléfono. Un **transportista principal** (el conductor; sin él no procede nadie) y personal de apoyo opcional. Sin «responsable de atención». Solo sedes con `Aplica_Proveedor` (hoy VES).
- **Zona y motivo fijos** (D-196): esclusa vehicular y «Entrega de proveedor»; el servidor los impone.
- **Licencias y permisos nuevos** (D-195): solicitante de proveedores, coordinador de proveedores (aprueba el paso), vigilancia de proveedores y almacén. La Vigilancia y el Coordinador de siempre no tocan proveedores.
- **Estado operativo** (D-197, D-198): `PROGRAMADO → EN_ESPERA → INGRESO → EN_ATENCION → RECEPCIONADO → SALIO` (y `NO_SE_PRESENTO`), con historial. Llegada (solo el día programado), atender y recepcionar (conforme / con observación + descripción). El ingreso y la salida reutilizan la portería actual: el principal ingresa tras la llegada, el apoyo después del principal, el principal sale tras la recepción. Dos personas a la vez: la segunda recibe 409.
- **Checklist del proveedor**: identificación, SCTR, EPP y placa (la placa solo al principal). Sin checklist de salida.
- **Editar / reprogramar / cancelar** (D-199): solo antes de la llegada; reprogramar la fecha reabre la aprobación; cancelar es lógico y la entrega sale de Vigilancia.
- **Almacén en copia** (D-200) desde el registro hasta la salida, y cierre «no se presentó» para entregas que nunca llegaron.
- Cambios de firma: `ERP_CAF_SOLICITUD_CREAR` (+6 parámetros), `EDITAR_DATOS` (+5), `TIPOS_OPCIONES(usuario)` y `SEDES_OPCIONES` (+ `Aplica_Proveedor`).

## Pasos
1. **Reconstruya la BD** con `restaurar_bd.ps1` (incluye `17_ALTER_PROVEEDOR.sql` y corre todas las pruebas). En una BD existente: ejecute `17_ALTER_PROVEEDOR.sql` **una sola vez** y re-ejecute estos 6 archivos: `SP_CAF_PROVEEDOR_ALL.sql` (nuevo), `SP_CAF_SOLICITUD_BASE_ALL.sql`, `SP_CAF_SOLICITUD_TIPO_INGRESO_ALL.sql`, `SP_CAF_SOLICITUD_ALL.sql`, `SP_CAF_SOLICITUD_VIGILANCIA_APROBADAS.sql` y `SP_CAF_PORTERIA_ALL.sql`.
2. Copie los archivos respetando carpetas, compile y reinicie la web **y el proceso de correo**. No hay archivos que borrar.
3. **No asigne las licencias de proveedor a nadie todavía** (P-127): el asistente de la web aún no pide los datos del proveedor (Entrega 2). Mientras nadie tenga la licencia, el tipo «Proveedor» no se ofrece a nadie y todo se comporta como antes.
4. Compruebe que lo de siempre sigue igual: crear un visitante y un contratista, aprobar, registrar ingreso y salida en Vigilancia.

## Qué probé
- SQL (PostgreSQL 16, BD reconstruida desde cero con 01 a 17): **HITO2 escritura 430/430** (sección O nueva, 91 pruebas: datos de fábrica, quién ve qué, validaciones, creación, aprobación solo con el principal, editar/reprogramar/cancelar, llegada→ingreso→atención→recepción→salida con historial, copia a Almacén, no se presentó); HITO1 143/143; HITO2 lectura 202/202; HITO3 140/140 y 100/100; HITO4 138/138 y 113/113; permisos 43/43 (ahora 17 permisos); HITO0 65/65.
- Los fixtures de pruebas que usaban «Proveedor» como tercer tipo genérico pasaron a «Personal interno visitante» (el Proveedor ya es un flujo real); todas las llamadas existentes de CREAR y EDITAR_DATOS recibieron los parámetros nuevos en NULL.
- .NET: compila (0 errores) en una copia con sustitutos de Npgsql y MailKit. Navegador (servicios simulados): el asistente de visitante y contratista sigue pasando sus comprobaciones.

## Qué NO probé
- Ninguna pantalla del proveedor (no existen todavía), **Npgsql real** (los parámetros nuevos de C# contra PostgreSQL), SMTP/Gmail real ni **HANA**.
- Los correos de Vigilancia y Almacén se comprobaron en SQL (destinatarios), no enviados.

## Límites y decisiones abiertas
- P-117 a P-127 (principal denegado, cierre del día, apoyo, supuestos de salida sin checklist y de llegada/edición, ejecutor del «no se presentó», hosting para tiempo real).
- HANA: T-30.

## Siguiente
Entrega 2: asistente del proveedor, aprobación y visibilidad por usuario.
