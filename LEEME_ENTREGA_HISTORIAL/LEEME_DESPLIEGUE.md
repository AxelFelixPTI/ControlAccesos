# Despliegue de prueba gratuito: Render (web) + Neon (PostgreSQL)

Se agregan 5 archivos nuevos y no se modifica ninguno existente. El `Dockerfile` actual ya sirve: lee la variable `PORT` que pone Render.

| Archivo | Para qué |
|---|---|
| `render.yaml` | Blueprint de Render: web Docker, plan gratuito, rama `main-remoto`, despliegue automático |
| `.dockerignore` | Imagen más liviana; excluye `appsettings.Local.json` (no se filtra nada local) |
| `scripts/restaurar_bd.sh` | Igual que `restaurar_bd.ps1`, pero para bash y para una URL remota (Neon) |
| `.github/workflows/ci.yml` | Comprueba en GitHub que la imagen compila en cada push |
| `LEEME_DESPLIEGUE.md` | Esta guía |

## Puesta en marcha (una sola vez, ~20 min)

1. **Neon** (neon.com, sin tarjeta): crea un proyecto y copia sus datos de conexión **directa** (el host SIN `-pooler`).
2. **Cargar la base** desde tu máquina (Git Bash/WSL/Linux/macOS, con `psql`). Pega la URL solo en tu terminal:
   ```bash
   export DATABASE_URL='postgresql://USUARIO:CLAVE@HOST/neondb?sslmode=require'
   ./scripts/restaurar_bd.sh          # base vacía: 47 tablas, 288 rutinas, 8 usuarios demo
   ./scripts/restaurar_bd.sh --demo   # opcional: 35 solicitudes de ejemplo
   ```
3. **Render** (render.com) → New → Blueprint → elige el repo. Pide estos valores (`sync: false`):
   - `ConnectionStrings__CAF_GOVERNANCE` y `ConnectionStrings__TRIANONSATELITAL_CAF_PRODD`, ambas con el mismo valor:
     `Host=HOST;Port=5432;Database=neondb;Username=USUARIO;Password=CLAVE;SSL Mode=Require;Maximum Pool Size=10;Connection Idle Lifetime=60`
     (si falla el certificado, añade `;Trust Server Certificate=true`)
   - `Correo__UrlBase`: la URL que te dé Render (`https://control-accesos-xxxx.onrender.com`).
4. Entra con `admin.demo@trianon.test` / `Admin.Demo#2026` (usuarios y claves en `11_SEED_DEMO_USUARIOS.sql`).

## Cómo se actualiza

- **Código:** `git push` a `main-remoto` → Render reconstruye y publica solo (3–6 min).
- **Procedimientos cambiados:** `./scripts/restaurar_bd.sh --rutinas`.
- **Tablas nuevas (`NN_*.sql`):** `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f <script>` una sola vez.

## Límites del plan gratuito (hay que conocerlos)

- **La web duerme** tras ~15 min sin visitas; la primera carga tarda 30–60 s. Neon también se suspende a los 5 min (la primera consulta tarda ~1 s).
- **Correo: solo `Simulado`.** Render gratis bloquea SMTP (puertos 25/465/587) desde sept-2025. Para correo real hay que pasar a un plan de pago (US$7/mes) o cambiar el envío a una API HTTP (Resend, Brevo): eso es código nuevo, no incluido. Mientras tanto no saldrá ningún correo.
- **Sesiones:** las claves de cifrado de la cookie viven en el disco efímero; cada despliegue o reinicio cierra las sesiones. Es aceptable para pruebas.
- **Segundo plano:** los procesos de correo y de cierre de proveedor solo corren con la web despierta.
- **Neon gratis:** 1 GB por proyecto. Los adjuntos se guardan en la base (bytea), así que consumen ese espacio.
- **Seguridad:** la URL es pública y los usuarios demo tienen claves públicas. Antes de compartir el enlace, cambia esas claves o ejecuta `LIMPIAR_DATOS_PRUEBA.sql` conservando un administrador. Para no compartir una base con datos reales, no cargues datos reales aquí.

## Qué se probó y qué no

Probado: `restaurar_bd.sh` en PostgreSQL 16 local con base vacía, sin errores (11 + 36 tablas, 59 + 229 rutinas, 8 usuarios).
**No probado:** el build de la imagen Docker, el arranque de la web, la conexión a Neon y el despliegue en Render. En este entorno no hay Docker (daemon) ni .NET. El primer despliegue puede pedir un ajuste (la cadena de conexión SSL es el candidato más probable); revisa el log de Render y avísame con el mensaje exacto.
Tampoco se ejecutaron las pruebas `PRUEBAS_*.sql` (el script no las corre).

## Texto sugerido para DECISIONES_ARRANQUE.md (no se editó)

D-247 · Despliegue de prueba en Render + Neon (planes gratuitos), correo en modo Simulado, sin cambios de código. Alternativa descartada: Render PostgreSQL (caduca a los 30 días).
