# Guía de verificación del hilo de correo con Gmail (P-95 / P-89)

Requisito: envío real configurado (`Correo__Modo=Smtp`). Para probar solo, `Correo__RedirigirA` = su propio Gmail (todo llega a esa dirección y sin copias); para probar «Responder a todos» de verdad, desactívelo y use destinatarios y copias reales de prueba.

1. Cree una solicitud con una empresa reconocible (p. ej. «Energía Verde»). Debe llegar «Solicitud SOL-xxxxx · Energía Verde».
2. Edite la empresa de la solicitud y apruébela como Coordinador. El correo de decisión debe llegar **en la misma conversación**, con asunto «Re: Solicitud SOL-xxxxx · Energía Verde» (el nombre original, no el nuevo).
3. En el correo de decisión pulse **Responder**: el destinatario debe ser el Coordinador que aprobó (el remitente se ve como «Nombre · Control de Accesos»).
4. Pulse **Responder a todos**: deben aparecer el Coordinador, el solicitante y quienes iban en copia (p. ej. gerencia).
5. Repita con un correo de cancelación (Responder → solicitante) y con una corrección de emergencia (Para incluye a Vigilancia).

Si Gmail separa los correos en conversaciones distintas, anote la fecha y el asunto exacto de cada uno y avise: Gmail agrupa por asunto más `References`/`In-Reply-To`, y hoy estos apuntan solo al correo de solicitud nueva (P-108).
