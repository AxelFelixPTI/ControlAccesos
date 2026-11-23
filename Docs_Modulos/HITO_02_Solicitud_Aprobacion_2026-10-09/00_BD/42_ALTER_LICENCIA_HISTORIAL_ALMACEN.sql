-- =============================================================================
-- Script  : 42_ALTER_LICENCIA_HISTORIAL_ALMACEN.sql   (2026-11-22, D-264)
-- Propósito: licencia adicional «Historial de Almacén». Permiso PER_CAF_PROVEEDOR_HIST_ALMACEN + licencia LIC_CAF_HIST_ALMACEN.
--            Da acceso al bloque «Atención de Almacén» del detalle de una solicitud de proveedor: quién atendió cada empresa,
--            horas, resultado y la línea de tiempo de Almacén. Se asigna a quien lo necesite (Almacén y Vigilancia) en Usuarios y
--            roles, ADEMÁS de su licencia habitual. No se agrega a LIC_CAF_ADMIN. La regla se aplica en el servidor
--            (ERP_CAF_PROVEEDOR_ATENCION_HISTORIAL), no solo en pantalla. Idempotente.
-- =============================================================================
SET search_path TO "CAF_GOVERNANCE";

INSERT INTO "Catalogo_Permiso" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create")
SELECT 'PER_CAF_PROVEEDOR_HIST_ALMACEN','Ver el historial de atención de Almacén de una solicitud de proveedor (quién atendió, cuándo y resultado)','ACCESOS',21,0
 WHERE NOT EXISTS (SELECT 1 FROM "Catalogo_Permiso" WHERE "Codigo"='PER_CAF_PROVEEDOR_HIST_ALMACEN');

INSERT INTO "Catalogo_Licencia" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create")
SELECT 'LIC_CAF_HIST_ALMACEN','Historial de Almacén: ver quién atendió cada entrega y su línea de tiempo (se suma a la licencia de Almacén o Vigilancia)','ACCESOS',28,0
 WHERE NOT EXISTS (SELECT 1 FROM "Catalogo_Licencia" WHERE "Codigo"='LIC_CAF_HIST_ALMACEN');

INSERT INTO "Licencia_Permiso" ("ID_Catalogo_Licencia","ID_Catalogo_Permiso","UsuarioID_Create")
SELECT l."ID_Catalogo_Licencia", p."ID_Catalogo_Permiso", 0
  FROM "Catalogo_Licencia" l
  JOIN "Catalogo_Permiso"  p ON p."Codigo" = 'PER_CAF_PROVEEDOR_HIST_ALMACEN'
 WHERE l."Codigo" = 'LIC_CAF_HIST_ALMACEN'
   AND NOT EXISTS (SELECT 1 FROM "Licencia_Permiso" lp
                    WHERE lp."ID_Catalogo_Licencia" = l."ID_Catalogo_Licencia" AND lp."ID_Catalogo_Permiso" = p."ID_Catalogo_Permiso");
