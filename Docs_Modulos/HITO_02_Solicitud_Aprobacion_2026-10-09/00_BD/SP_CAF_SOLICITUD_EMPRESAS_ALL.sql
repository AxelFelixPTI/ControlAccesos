-- =============================================================================
-- SP_CAF_SOLICITUD_EMPRESAS_ALL.sql   V1.0 2026-11-12 (D-236)
-- Empresas de una solicitud de proveedor (1 a 4) y empresas a las que da atención cada usuario de Almacén.
--   ERP_CAF_FN_EMPRESAS_SOLICITUD(solicitud, 'C'|'I'|'N')   códigos, ids o nombres de las empresas, separados por coma o « / »
--   ERP_CAF_SOLICITUD_EMPRESAS_ASIGNAR                  reemplaza las empresas de la solicitud (la primera queda como principal)
--   ERP_CAF_ALMACEN_EMPRESA_LISTAR                      usuarios con licencia de Almacén y sus empresas
--   ERP_CAF_ALMACEN_EMPRESA_GUARDAR                     reemplaza las empresas de un usuario de Almacén
-- Requiere el script 30. Schema: TRIANONSATELITAL_CAF_PRODD.
-- =============================================================================
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

CREATE OR REPLACE FUNCTION "ERP_CAF_FN_EMPRESAS_SOLICITUD"("HV_ID_Solicitud" BIGINT, "HV_Modo" VARCHAR)
RETURNS VARCHAR
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_r VARCHAR;
BEGIN
    -- V1.0 2026-11-12: 'C' = códigos (TRIANON_ENERGO,POWER_TECHNOLOGY), 'I' = ids (3,1), otro = nombres separados por « / »
    SELECT CAST(STRING_AGG(CASE "HV_Modo" WHEN 'C' THEN CAST(EG."Codigo" AS VARCHAR) WHEN 'I' THEN CAST(EG."ID_Catalogo_Empresa_Grupo" AS VARCHAR) ELSE CAST(EG."Descripcion" AS VARCHAR) END,
                           CASE WHEN "HV_Modo" IN ('C','I') THEN ',' ELSE ' / ' END ORDER BY EG."Orden", EG."ID_Catalogo_Empresa_Grupo") AS VARCHAR)
      INTO lv_r
      FROM "CAF_Solicitud_Empresa" E
      JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG ON EG."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo"
     WHERE E."ID_Solicitud" = "HV_ID_Solicitud" AND E."Eliminado" = 'N';
    RETURN lv_r;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_SOLICITUD_EMPRESAS_ASIGNAR"(
    IN    "HV_ID_Solicitud" BIGINT,
    IN    "HV_IDs_Empresa"  VARCHAR(100),
    IN    "HV_UsuarioID"    BIGINT,
    INOUT "HV_Codigo_Resp"  INT DEFAULT NULL,
    INOUT "HV_Mensaje"      VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_arr  BIGINT[];
    lv_ids  BIGINT[] := ARRAY[]::BIGINT[];
    lv_x    BIGINT;
    lv_prov INT;
BEGIN
    -- V1.0 2026-11-12 (D-236)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SOLICITUD_EMPRESAS_ASIGNAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        IF COALESCE(TRIM("HV_IDs_Empresa"), '') = '' OR REPLACE("HV_IDs_Empresa", ' ', '') !~ '^[0-9]+(,[0-9]+)*$' THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Indique al menos una empresa que recibe.'; RETURN;
        END IF;
        SELECT COUNT(*) INTO lv_prov FROM "CAF_Solicitud" S
          JOIN "Catalogo_Tipo_Acceso" T ON T."ID_Catalogo_Tipo_Acceso" = S."ID_Catalogo_Tipo_Acceso" AND T."Codigo" = 'PROVEEDOR'
         WHERE S."ID_Solicitud" = "HV_ID_Solicitud" AND S."Eliminado" = 'N';
        IF lv_prov = 0 THEN "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'La solicitud de proveedor no existe.'; RETURN; END IF;
        lv_arr := CAST(STRING_TO_ARRAY(REPLACE("HV_IDs_Empresa", ' ', ''), ',') AS BIGINT[]);
        FOREACH lv_x IN ARRAY lv_arr LOOP                       -- sin repetidos y respetando el orden indicado (la primera es la principal)
            IF NOT (lv_x = ANY(lv_ids)) THEN lv_ids := lv_ids || lv_x; END IF;
        END LOOP;
        IF CARDINALITY(lv_ids) > 4 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Una solicitud admite como máximo 4 empresas.'; RETURN; END IF;
        IF (SELECT COUNT(*) FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG
             WHERE EG."ID_Catalogo_Empresa_Grupo" = ANY(lv_ids) AND EG."Eliminado" = 'N' AND EG."Activo" = 'Y') <> CARDINALITY(lv_ids) THEN
            "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Alguna de las empresas no existe o no está activa.'; RETURN;
        END IF;
        UPDATE "CAF_Solicitud_Empresa" SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Solicitud" = "HV_ID_Solicitud" AND "Eliminado" = 'N' AND NOT ("ID_Catalogo_Empresa_Grupo" = ANY(lv_ids));
        INSERT INTO "CAF_Solicitud_Empresa" ("ID_Solicitud","ID_Catalogo_Empresa_Grupo","UsuarioID_Create")
        SELECT "HV_ID_Solicitud", X, "HV_UsuarioID" FROM UNNEST(lv_ids) AS X
         WHERE NOT EXISTS (SELECT 1 FROM "CAF_Solicitud_Empresa" E WHERE E."ID_Solicitud" = "HV_ID_Solicitud" AND E."ID_Catalogo_Empresa_Grupo" = X AND E."Eliminado" = 'N');
        UPDATE "CAF_Solicitud" SET "ID_Catalogo_Empresa_Grupo_Destino" = lv_ids[1] WHERE "ID_Solicitud" = "HV_ID_Solicitud";
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Empresas de la solicitud guardadas.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_SOLICITUD_EMPRESAS_ASIGNAR';
    END;
END;
$$;

DROP FUNCTION IF EXISTS "ERP_CAF_ALMACEN_EMPRESA_LISTAR"();
CREATE OR REPLACE FUNCTION "ERP_CAF_ALMACEN_EMPRESA_LISTAR"()
RETURNS TABLE ("ID_Usuario" BIGINT, "Nombre" VARCHAR, "Cargo" VARCHAR, "IDs_Empresa" VARCHAR, "Empresas" VARCHAR)
LANGUAGE plpgsql STABLE SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
#variable_conflict use_column
BEGIN
    -- V1.0 2026-11-12: usuarios activos con la licencia LIC_CAF_ALMACEN y las empresas a las que dan atención
    RETURN QUERY
    SELECT U."ID_Usuario",
           CAST(P."Apellido_Paterno" || COALESCE(' ' || P."Apellido_Materno", '') || ', ' || P."Nombres" AS VARCHAR),
           CAST(C."Descripcion" AS VARCHAR),
           CAST(COALESCE((SELECT STRING_AGG(CAST(E."ID_Catalogo_Empresa_Grupo" AS VARCHAR), ',' ORDER BY EG."Orden", EG."ID_Catalogo_Empresa_Grupo")
                            FROM "CAF_Usuario_Empresa_Almacen" E JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG ON EG."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo"
                           WHERE E."ID_Usuario" = U."ID_Usuario" AND E."Eliminado" = 'N'), '') AS VARCHAR),
           CAST(COALESCE((SELECT STRING_AGG(CAST(EG."Codigo" AS VARCHAR), ',' ORDER BY EG."Orden", EG."ID_Catalogo_Empresa_Grupo")
                            FROM "CAF_Usuario_Empresa_Almacen" E JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG ON EG."ID_Catalogo_Empresa_Grupo" = E."ID_Catalogo_Empresa_Grupo"
                           WHERE E."ID_Usuario" = U."ID_Usuario" AND E."Eliminado" = 'N'), '') AS VARCHAR)
      FROM "CAF_GOVERNANCE"."Usuario" U
      JOIN "CAF_GOVERNANCE"."Personal" P ON P."ID_Personal" = U."ID_Personal" AND P."Eliminado" = 'N'
      LEFT JOIN "CAF_GOVERNANCE"."Catalogo_Cargo" C ON C."ID_Catalogo_Cargo" = P."ID_Catalogo_Cargo"
     WHERE U."Eliminado" = 'N' AND U."Activo" = 'Y'
       AND EXISTS (SELECT 1 FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
                     JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Codigo" = 'LIC_CAF_ALMACEN' AND L."Eliminado" = 'N'
                    WHERE UL."ID_Usuario" = U."ID_Usuario" AND UL."Eliminado" = 'N')
     ORDER BY 2;
END;
$$;

CREATE OR REPLACE PROCEDURE "ERP_CAF_ALMACEN_EMPRESA_GUARDAR"(
    IN    "HV_ID_Usuario"  BIGINT,
    IN    "HV_IDs_Empresa" VARCHAR(100),
    IN    "HV_UsuarioID"   BIGINT,
    INOUT "HV_Codigo_Resp" INT DEFAULT NULL,
    INOUT "HV_Mensaje"     VARCHAR(250) DEFAULT NULL
)
LANGUAGE plpgsql SET search_path TO "TRIANONSATELITAL_CAF_PRODD" AS $$
DECLARE
    lv_ids BIGINT[] := ARRAY[]::BIGINT[];
    lv_x   BIGINT;
BEGIN
    -- V1.0 2026-11-12 (D-236): reemplaza las empresas del usuario; lista vacía = ninguna (no podrá atender)
    "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_ALMACEN_EMPRESA_GUARDAR';
    BEGIN
        IF "HV_UsuarioID" IS NULL OR "HV_UsuarioID" < 0 THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Usuario no válido.'; RETURN; END IF;
        IF NOT EXISTS (SELECT 1 FROM "ERP_CAF_ALMACEN_EMPRESA_LISTAR"() L WHERE L."ID_Usuario" = "HV_ID_Usuario") THEN
            "HV_Codigo_Resp" := 404; "HV_Mensaje" := 'El usuario no es de Almacén o no existe.'; RETURN;
        END IF;
        IF COALESCE(TRIM("HV_IDs_Empresa"), '') <> '' THEN
            IF REPLACE("HV_IDs_Empresa", ' ', '') !~ '^[0-9]+(,[0-9]+)*$' THEN "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'La lista de empresas no es válida.'; RETURN; END IF;
            FOREACH lv_x IN ARRAY CAST(STRING_TO_ARRAY(REPLACE("HV_IDs_Empresa", ' ', ''), ',') AS BIGINT[]) LOOP
                IF NOT (lv_x = ANY(lv_ids)) THEN lv_ids := lv_ids || lv_x; END IF;
            END LOOP;
            IF (SELECT COUNT(*) FROM "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" EG
                 WHERE EG."ID_Catalogo_Empresa_Grupo" = ANY(lv_ids) AND EG."Eliminado" = 'N' AND EG."Activo" = 'Y') <> CARDINALITY(lv_ids) THEN
                "HV_Codigo_Resp" := 400; "HV_Mensaje" := 'Alguna de las empresas no existe o no está activa.'; RETURN;
            END IF;
        END IF;
        UPDATE "CAF_Usuario_Empresa_Almacen" SET "Eliminado" = 'Y', "UsuarioID_Update" = "HV_UsuarioID", "UpdateDate" = CURRENT_TIMESTAMP
         WHERE "ID_Usuario" = "HV_ID_Usuario" AND "Eliminado" = 'N' AND NOT ("ID_Catalogo_Empresa_Grupo" = ANY(lv_ids));
        INSERT INTO "CAF_Usuario_Empresa_Almacen" ("ID_Usuario","ID_Catalogo_Empresa_Grupo","UsuarioID_Create")
        SELECT "HV_ID_Usuario", X, "HV_UsuarioID" FROM UNNEST(lv_ids) AS X
         WHERE NOT EXISTS (SELECT 1 FROM "CAF_Usuario_Empresa_Almacen" E WHERE E."ID_Usuario" = "HV_ID_Usuario" AND E."ID_Catalogo_Empresa_Grupo" = X AND E."Eliminado" = 'N');
        "HV_Codigo_Resp" := 100; "HV_Mensaje" := 'Empresas del usuario guardadas.';
    EXCEPTION WHEN OTHERS THEN
        "HV_Codigo_Resp" := 500; "HV_Mensaje" := 'Error interno en ERP_CAF_ALMACEN_EMPRESA_GUARDAR';
    END;
END;
$$;
