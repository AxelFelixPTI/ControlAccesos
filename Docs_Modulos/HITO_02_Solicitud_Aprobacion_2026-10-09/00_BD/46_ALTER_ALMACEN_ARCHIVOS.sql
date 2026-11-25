-- =============================================================================
-- Script  : 46_ALTER_ALMACEN_ARCHIVOS.sql   (2026-11-24, D-276)
-- Propósito: almacén de archivos conectable. Los adjuntos (CAF_Solicitud_Adjunto) y los documentos de ingreso (CAF_Documento_Ingreso)
--            pueden guardarse en la base ('BD', como hasta ahora), en una carpeta de red ('RED') o en Google Drive ('DRIVE').
--            Fuera de la base queda solo el archivo; en la tabla se guardan nombre, tamaño, hash, el almacén y la ruta (o el ID de Drive).
--   1. Columnas Almacen (BD | RED | DRIVE, por defecto BD) y Ruta_Externa; Contenido pasa a admitir NULL.
--   2. Regla: en 'BD' el contenido es obligatorio; fuera de la base la ruta es obligatoria (el contenido puede conservarse como copia).
--   3. Parámetros editables en «Parámetros»: ALMACEN_ARCHIVOS_TIPO, ALMACEN_RED_RUTA, ALMACEN_DRIVE_CARPETA. Las credenciales de Drive NO van aquí: variables de entorno.
-- Idempotente. Nota HANA: ADD COLUMN IF NOT EXISTS → comprobar en SYS.TABLE_COLUMNS; DROP NOT NULL → ALTER COLUMN ... NULL; el CHECK se reescribe igual.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD", "CAF_GOVERNANCE";

ALTER TABLE "CAF_Solicitud_Adjunto" ADD COLUMN IF NOT EXISTS "Almacen"      VARCHAR(10) DEFAULT 'BD' NOT NULL;
ALTER TABLE "CAF_Solicitud_Adjunto" ADD COLUMN IF NOT EXISTS "Ruta_Externa" VARCHAR(500);
ALTER TABLE "CAF_Solicitud_Adjunto" ALTER COLUMN "Contenido" DROP NOT NULL;
ALTER TABLE "CAF_Solicitud_Adjunto" DROP CONSTRAINT IF EXISTS "CK_CAF_Solicitud_Adjunto_Almacen";
ALTER TABLE "CAF_Solicitud_Adjunto" ADD CONSTRAINT "CK_CAF_Solicitud_Adjunto_Almacen"
    CHECK ("Almacen" IN ('BD','RED','DRIVE') AND (("Almacen" = 'BD' AND "Contenido" IS NOT NULL) OR ("Almacen" <> 'BD' AND "Ruta_Externa" IS NOT NULL)));

ALTER TABLE "CAF_Documento_Ingreso" ADD COLUMN IF NOT EXISTS "Almacen"      VARCHAR(10) DEFAULT 'BD' NOT NULL;
ALTER TABLE "CAF_Documento_Ingreso" ADD COLUMN IF NOT EXISTS "Ruta_Externa" VARCHAR(500);
ALTER TABLE "CAF_Documento_Ingreso" ALTER COLUMN "Contenido" DROP NOT NULL;
ALTER TABLE "CAF_Documento_Ingreso" DROP CONSTRAINT IF EXISTS "CK_CAF_Documento_Ingreso_Almacen";
ALTER TABLE "CAF_Documento_Ingreso" ADD CONSTRAINT "CK_CAF_Documento_Ingreso_Almacen"
    CHECK ("Almacen" IN ('BD','RED','DRIVE') AND (("Almacen" = 'BD' AND "Contenido" IS NOT NULL) OR ("Almacen" <> 'BD' AND "Ruta_Externa" IS NOT NULL)));

INSERT INTO "CAF_Parametro" ("Clave","Valor","Descripcion","UsuarioID_Create")
SELECT 'ALMACEN_ARCHIVOS_TIPO', 'BD', 'Dónde se guardan los archivos nuevos (adjuntos y documentos de ingreso): BD (base de datos), RED (carpeta de red) o DRIVE (Google Drive).', 0
 WHERE NOT EXISTS (SELECT 1 FROM "CAF_Parametro" WHERE "Clave" = 'ALMACEN_ARCHIVOS_TIPO');
INSERT INTO "CAF_Parametro" ("Clave","Valor","Descripcion","UsuarioID_Create")
SELECT 'ALMACEN_RED_RUTA', '', 'Carpeta de red donde se guardan los archivos cuando el tipo es RED (ej. \\servidor\recurso\adjuntos). La cuenta que ejecuta la aplicación debe poder escribir en ella.', 0
 WHERE NOT EXISTS (SELECT 1 FROM "CAF_Parametro" WHERE "Clave" = 'ALMACEN_RED_RUTA');
INSERT INTO "CAF_Parametro" ("Clave","Valor","Descripcion","UsuarioID_Create")
SELECT 'ALMACEN_DRIVE_CARPETA', 'ControlAccesos_Adjuntos', 'Nombre de la carpeta de Google Drive donde se guardan los archivos cuando el tipo es DRIVE (la aplicación la crea si no existe).', 0
 WHERE NOT EXISTS (SELECT 1 FROM "CAF_Parametro" WHERE "Clave" = 'ALMACEN_DRIVE_CARPETA');
