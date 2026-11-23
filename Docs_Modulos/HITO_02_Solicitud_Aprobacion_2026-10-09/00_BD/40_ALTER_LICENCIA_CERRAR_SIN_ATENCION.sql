-- =============================================================================
-- Script  : 40_ALTER_LICENCIA_CERRAR_SIN_ATENCION.sql   (2026-11-20, D-259)
-- Propósito: licencia adicional «Cerrar sin atención». Permiso PER_CAF_PROVEEDOR_CERRAR_SIN_ATENCION + licencia
--            LIC_CAF_PROVEEDOR_CERRAR_SIN_ATENCION.
--            Quien inició la atención de una empresa siempre puede cerrarla sin atención. Con esta licencia, un almacenero
--            puede cerrar CUALQUIER atención, aunque no la haya iniciado, pero solo de las empresas que tiene asignadas en
--            «Almacén por empresa». La licencia es un complemento: se asigna ADEMÁS de LIC_CAF_ALMACEN (que da el acceso a
--            Almacén) en Usuarios y roles. No se agrega a LIC_CAF_ADMIN: el Administrador no atiende entregas.
--            La regla se aplica en el servidor (ERP_CAF_PROVEEDOR_CERRAR_SIN_ATENCION), no solo en pantalla. Idempotente.
-- =============================================================================
SET search_path TO "CAF_GOVERNANCE";

INSERT INTO "Catalogo_Permiso" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create")
SELECT 'PER_CAF_PROVEEDOR_CERRAR_SIN_ATENCION','Cerrar sin atención cualquier empresa que tenga asignada (aunque no haya iniciado la atención)','ACCESOS',19,0
 WHERE NOT EXISTS (SELECT 1 FROM "Catalogo_Permiso" WHERE "Codigo"='PER_CAF_PROVEEDOR_CERRAR_SIN_ATENCION');

INSERT INTO "Catalogo_Licencia" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create")
SELECT 'LIC_CAF_PROVEEDOR_CERRAR_SIN_ATENCION','Almacén: cerrar sin atención cualquier empresa asignada (se suma a la licencia de Almacén)','ACCESOS',26,0
 WHERE NOT EXISTS (SELECT 1 FROM "Catalogo_Licencia" WHERE "Codigo"='LIC_CAF_PROVEEDOR_CERRAR_SIN_ATENCION');

INSERT INTO "Licencia_Permiso" ("ID_Catalogo_Licencia","ID_Catalogo_Permiso","UsuarioID_Create")
SELECT l."ID_Catalogo_Licencia", p."ID_Catalogo_Permiso", 0
  FROM "Catalogo_Licencia" l
  JOIN "Catalogo_Permiso"  p ON p."Codigo" = 'PER_CAF_PROVEEDOR_CERRAR_SIN_ATENCION'
 WHERE l."Codigo" = 'LIC_CAF_PROVEEDOR_CERRAR_SIN_ATENCION'
   AND NOT EXISTS (SELECT 1 FROM "Licencia_Permiso" lp
                    WHERE lp."ID_Catalogo_Licencia" = l."ID_Catalogo_Licencia" AND lp."ID_Catalogo_Permiso" = p."ID_Catalogo_Permiso");

-- D-259 (incidencias post-salida): el parámetro INCIDENCIA_POST_SALIDA ahora vale igual para Vigilancia y para Coordinación.
-- Solo se actualiza el texto descriptivo del parámetro; su valor no cambia. Idempotente.
SET search_path TO "TRIANONSATELITAL_CAF_PRODD", "CAF_GOVERNANCE";
UPDATE "CAF_Parametro"
   SET "Descripcion" = 'Permitir que Vigilancia y Coordinación registren incidencias a personas que ya salieron del establecimiento (Y/N). Por defecto N.'
 WHERE "Clave" = 'INCIDENCIA_POST_SALIDA';
