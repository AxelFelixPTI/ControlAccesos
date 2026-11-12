-- =============================================================================
-- 29_ALTER_SUBTIPO_PERSONA.sql   (2026-11-12, D-234)
-- El subtipo (rol) de cada persona se GUARDA en la solicitud y el checklist de un tipo con subtipos se define POR SUBTIPO.
--   1. Tipo_Acceso_Subtipo.Es_Predeterminado: el subtipo que sale elegido por defecto al agregar una persona (uno por tipo).
--   2. CAF_Solicitud_Persona.ID_Tipo_Acceso_Subtipo: el rol de la persona. Se rellena solo (trigger) con el predeterminado del
--      tipo, y pasa a TRANSPORTISTA cuando la persona figura en CAF_Solicitud_Transportista (Proveedor).
--   3. Tipo_Acceso_Item_Checklist: la unicidad pasa de (tipo, ítem) a (tipo, ítem, subtipo) para admitir una fila por subtipo.
--   4. Migración: los ítems de un tipo con subtipos que estaban «para todo el tipo» (subtipo NULL) pasan a una fila por subtipo activo.
-- Se puede ejecutar más de una vez. Schema: TRIANONSATELITAL_CAF_PRODD.
-- HANA (T-41): no admite ADD COLUMN IF NOT EXISTS ni índices sobre expresiones (COALESCE) ni CREATE OR REPLACE TRIGGER con este
--   cuerpo: allí la unicidad se hace con una columna calculada o se valida en el SP, y los triggers se reescriben en SQLScript.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- 1. Subtipo predeterminado ---------------------------------------------------
ALTER TABLE "Tipo_Acceso_Subtipo" ADD COLUMN IF NOT EXISTS "Es_Predeterminado" CHAR(1) DEFAULT 'N' NOT NULL;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'CK_Tipo_Acceso_Subtipo_Pred') THEN
        ALTER TABLE "Tipo_Acceso_Subtipo" ADD CONSTRAINT "CK_Tipo_Acceso_Subtipo_Pred" CHECK ("Es_Predeterminado" IN ('Y','N'));
    END IF;
END $$;
-- Proveedor: el predeterminado es «Ayudante de descarga» (mismo efecto que antes: quien no es transportista es ayudante)
UPDATE "Tipo_Acceso_Subtipo" S SET "Es_Predeterminado" = 'Y', "UsuarioID_Update" = 0, "UpdateDate" = CURRENT_TIMESTAMP
  FROM "Catalogo_Tipo_Acceso" T
 WHERE T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR' AND S."Codigo" = 'AYUDANTE_DESCARGA'
   AND NOT EXISTS (SELECT 1 FROM "Tipo_Acceso_Subtipo" O WHERE O."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND O."Es_Predeterminado" = 'Y' AND O."Eliminado" = 'N');
-- Un solo predeterminado por tipo
CREATE UNIQUE INDEX IF NOT EXISTS "UX_Tipo_Acceso_Subtipo_Pred" ON "Tipo_Acceso_Subtipo" ("ID_Catalogo_Tipo_Acceso") WHERE "Es_Predeterminado" = 'Y' AND "Eliminado" = 'N';

-- 2. Rol guardado en la persona de la solicitud -------------------------------
ALTER TABLE "CAF_Solicitud_Persona" ADD COLUMN IF NOT EXISTS "ID_Tipo_Acceso_Subtipo" BIGINT;
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'FK_CAF_Solicitud_Persona_Subtipo') THEN
        ALTER TABLE "CAF_Solicitud_Persona" ADD CONSTRAINT "FK_CAF_Solicitud_Persona_Subtipo"
            FOREIGN KEY ("ID_Tipo_Acceso_Subtipo") REFERENCES "Tipo_Acceso_Subtipo" ("ID_Tipo_Acceso_Subtipo");
    END IF;
END $$;

-- Datos existentes: transportista si figura en CAF_Solicitud_Transportista; si no, el predeterminado del tipo
UPDATE "CAF_Solicitud_Persona" P
   SET "ID_Tipo_Acceso_Subtipo" = COALESCE(
          (SELECT X."ID_Tipo_Acceso_Subtipo" FROM "Tipo_Acceso_Subtipo" X
            WHERE X."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND X."Eliminado" = 'N' AND X."Codigo" = 'TRANSPORTISTA'
              AND EXISTS (SELECT 1 FROM "CAF_Solicitud_Transportista" T WHERE T."ID_Solicitud_Persona" = P."ID_Solicitud_Persona" AND T."Eliminado" = 'N')),
          (SELECT X."ID_Tipo_Acceso_Subtipo" FROM "Tipo_Acceso_Subtipo" X
            WHERE X."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND X."Eliminado" = 'N' AND X."Es_Predeterminado" = 'Y'))
  FROM "CAF_Solicitud" S
 WHERE S."ID_Solicitud" = P."ID_Solicitud" AND P."ID_Tipo_Acceso_Subtipo" IS NULL;

-- Trigger 1: toda persona nueva nace con el subtipo predeterminado de su tipo (NULL si el tipo no tiene subtipos)
CREATE OR REPLACE FUNCTION "TRG_CAF_Solicitud_Persona_Subtipo"() RETURNS trigger
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
BEGIN
    IF NEW."ID_Tipo_Acceso_Subtipo" IS NULL THEN
        SELECT X."ID_Tipo_Acceso_Subtipo" INTO NEW."ID_Tipo_Acceso_Subtipo"
          FROM "CAF_Solicitud" S JOIN "Tipo_Acceso_Subtipo" X ON X."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso"
         WHERE S."ID_Solicitud" = NEW."ID_Solicitud" AND X."Es_Predeterminado" = 'Y' AND X."Eliminado" = 'N';
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS "TR_CAF_Solicitud_Persona_Subtipo" ON "CAF_Solicitud_Persona";
CREATE TRIGGER "TR_CAF_Solicitud_Persona_Subtipo" BEFORE INSERT ON "CAF_Solicitud_Persona"
    FOR EACH ROW EXECUTE FUNCTION "TRG_CAF_Solicitud_Persona_Subtipo"();

-- Trigger 2: figurar como transportista activo = rol TRANSPORTISTA; dejar de figurar = vuelve al predeterminado
CREATE OR REPLACE FUNCTION "TRG_CAF_Solicitud_Transportista_Subtipo"() RETURNS trigger
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_tipo BIGINT;
    lv_sub  BIGINT;
BEGIN
    SELECT S."ID_Catalogo_Tipo_Acceso" INTO lv_tipo FROM "CAF_Solicitud" S WHERE S."ID_Solicitud" = NEW."ID_Solicitud";
    IF NEW."Eliminado" = 'N' THEN
        SELECT X."ID_Tipo_Acceso_Subtipo" INTO lv_sub FROM "Tipo_Acceso_Subtipo" X
         WHERE X."ID_Catalogo_Tipo_Acceso" = lv_tipo AND X."Codigo" = 'TRANSPORTISTA' AND X."Eliminado" = 'N';
    ELSIF NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Transportista" T WHERE T."ID_Solicitud_Persona" = NEW."ID_Solicitud_Persona" AND T."Eliminado" = 'N') THEN
        SELECT X."ID_Tipo_Acceso_Subtipo" INTO lv_sub FROM "Tipo_Acceso_Subtipo" X
         WHERE X."ID_Catalogo_Tipo_Acceso" = lv_tipo AND X."Es_Predeterminado" = 'Y' AND X."Eliminado" = 'N';
    ELSE
        RETURN NEW;
    END IF;
    IF lv_sub IS NOT NULL THEN
        UPDATE "CAF_Solicitud_Persona" SET "ID_Tipo_Acceso_Subtipo" = lv_sub WHERE "ID_Solicitud_Persona" = NEW."ID_Solicitud_Persona";
    END IF;
    RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS "TR_CAF_Solicitud_Transportista_Subtipo" ON "CAF_Solicitud_Transportista";
CREATE TRIGGER "TR_CAF_Solicitud_Transportista_Subtipo" AFTER INSERT OR UPDATE OF "Eliminado" ON "CAF_Solicitud_Transportista"
    FOR EACH ROW EXECUTE FUNCTION "TRG_CAF_Solicitud_Transportista_Subtipo"();

-- 3. Checklist: una fila por (tipo, ítem, subtipo) ----------------------------
ALTER TABLE "Tipo_Acceso_Item_Checklist" DROP CONSTRAINT IF EXISTS "UQ_Tipo_Acceso_Item_Checklist";
CREATE UNIQUE INDEX IF NOT EXISTS "UX_Tipo_Acceso_Item_Checklist" ON "Tipo_Acceso_Item_Checklist"
    ("ID_Catalogo_Tipo_Acceso", "ID_Catalogo_Item_Checklist", COALESCE("ID_Tipo_Acceso_Subtipo", 0));

-- 4. Migración: un tipo con subtipos activos no deja ítems «para todo el tipo»
INSERT INTO "Tipo_Acceso_Item_Checklist" ("ID_Catalogo_Tipo_Acceso","ID_Catalogo_Item_Checklist","ID_Tipo_Acceso_Subtipo","UsuarioID_Create")
SELECT G."ID_Catalogo_Tipo_Acceso", G."ID_Catalogo_Item_Checklist", S."ID_Tipo_Acceso_Subtipo", 0
  FROM "Tipo_Acceso_Item_Checklist" G
  JOIN "Tipo_Acceso_Subtipo" S ON S."ID_Catalogo_Tipo_Acceso" = G."ID_Catalogo_Tipo_Acceso" AND S."Eliminado" = 'N' AND S."Activo" = 'Y'
 WHERE G."ID_Tipo_Acceso_Subtipo" IS NULL AND G."Eliminado" = 'N'
   AND NOT EXISTS (SELECT 1 FROM "Tipo_Acceso_Item_Checklist" O
                    WHERE O."ID_Catalogo_Tipo_Acceso" = G."ID_Catalogo_Tipo_Acceso" AND O."ID_Catalogo_Item_Checklist" = G."ID_Catalogo_Item_Checklist"
                      AND O."ID_Tipo_Acceso_Subtipo" = S."ID_Tipo_Acceso_Subtipo");
UPDATE "Tipo_Acceso_Item_Checklist" G SET "Eliminado" = 'Y', "UsuarioID_Update" = 0, "UpdateDate" = CURRENT_TIMESTAMP
 WHERE G."ID_Tipo_Acceso_Subtipo" IS NULL AND G."Eliminado" = 'N'
   AND EXISTS (SELECT 1 FROM "Tipo_Acceso_Subtipo" S WHERE S."ID_Catalogo_Tipo_Acceso" = G."ID_Catalogo_Tipo_Acceso" AND S."Eliminado" = 'N' AND S."Activo" = 'Y');
