# Decisiones del paso 1 de arranque (2026-10-18)

| N.º | Decisión | Estado |
|---|---|---|
| D-86 | Contraseña mínima de 10 caracteres (validada en `Srv_Usuario`; sin otras reglas de complejidad por ahora). | Candidata |
| D-87 | Hash de contraseña PBKDF2-SHA256, 210 000 iteraciones, sal de 16 bytes; formato `PBKDF2$SHA256$iter$sal$hash` en `Usuario.Password_Hash`. Las iteraciones viajan en el hash. | Candidata |
| D-88 | El envío de correos usa SMTP de `System.Net.Mail` (texto plano) o modo `Simulado` (solo log); se elige con `Correo:Modo`. Si el correo sale pero no se puede marcar ENVIADO, se registra en el log y se reenvía en la siguiente vuelta (preferible duplicar a perder un aviso). | Candidata |

## Pendientes para `PENDIENTES_VALIDACION.md`
- **P-51** — ¿Con qué servidor SMTP y qué cuenta remitente enviará el grupo? (Host, puerto, SSL, usuario). Hoy el modo es `Simulado`.
- **P-52** — ¿Política de contraseñas del grupo (largo, vigencia, complejidad)? Hoy: mínimo 10 caracteres.
- **T-10** — En HANA el hash y el envío no cambian; solo `ConexionPostgres` se reemplaza por la fábrica de conexiones HANA.
