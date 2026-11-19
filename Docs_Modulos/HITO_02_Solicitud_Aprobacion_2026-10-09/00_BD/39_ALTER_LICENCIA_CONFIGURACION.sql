-- =============================================================================
-- Script  : 39_ALTER_LICENCIA_CONFIGURACION.sql   (2026-11-19, D-258)
-- Propósito: licencia de configuración. Permiso PER_CAF_CONFIG_SISTEMA + licencia LIC_CAF_CONFIGURACION, para que el
--            Coordinador (o el coordinador que se designe) ajuste zonas, motivos, tratamientos, tipos de incidencia,
--            checklist de portería y cinco parámetros sin depender del Administrador. El Administrador también la tiene.
--            Asignar la licencia a un usuario: Usuarios y roles. Idempotente.
-- =============================================================================
SET search_path TO "CAF_GOVERNANCE";

INSERT INTO "Catalogo_Permiso" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create")
SELECT 'PER_CAF_CONFIG_SISTEMA','Configurar catálogos y parámetros del sistema','ADMIN',14,0
 WHERE NOT EXISTS (SELECT 1 FROM "Catalogo_Permiso" WHERE "Codigo"='PER_CAF_CONFIG_SISTEMA');

INSERT INTO "Catalogo_Licencia" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create")
SELECT 'LIC_CAF_CONFIGURACION','Configuración: catálogos y parámetros del sistema (sin administrar usuarios)','CAF',25,0
 WHERE NOT EXISTS (SELECT 1 FROM "Catalogo_Licencia" WHERE "Codigo"='LIC_CAF_CONFIGURACION');

INSERT INTO "Licencia_Permiso" ("ID_Catalogo_Licencia","ID_Catalogo_Permiso","UsuarioID_Create")
SELECT l."ID_Catalogo_Licencia", p."ID_Catalogo_Permiso", 0
  FROM (VALUES ('LIC_CAF_CONFIGURACION','PER_CAF_CONFIG_SISTEMA'),
               ('LIC_CAF_ADMIN','PER_CAF_CONFIG_SISTEMA')) AS v(lic, per)
  JOIN "Catalogo_Licencia" l ON l."Codigo" = v.lic
  JOIN "Catalogo_Permiso"  p ON p."Codigo" = v.per
 WHERE NOT EXISTS (SELECT 1 FROM "Licencia_Permiso" lp
                    WHERE lp."ID_Catalogo_Licencia" = l."ID_Catalogo_Licencia" AND lp."ID_Catalogo_Permiso" = p."ID_Catalogo_Permiso");
