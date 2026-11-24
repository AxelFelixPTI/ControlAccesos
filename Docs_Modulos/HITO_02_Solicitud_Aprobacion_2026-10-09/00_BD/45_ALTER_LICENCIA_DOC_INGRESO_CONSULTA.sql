-- =============================================================================
-- Script  : 45_ALTER_LICENCIA_DOC_INGRESO_CONSULTA.sql   (2026-11-24, D-272)
-- Propósito: licencia aparte «Consultar documentos de ingreso». Permiso PER_CAF_DOC_INGRESO_CONSULTAR + licencia LIC_CAF_DOC_INGRESO_CONSULTA.
--            Quien la tiene consulta los documentos que sube Vigilancia (pantalla «Documentos de ingreso», búsqueda por rango y persona,
--            descarga y bloque del detalle de la solicitud); NO puede subir ni retirar. Vigilancia (PER_CAF_PORTERIA_REGISTRAR) sube y consulta
--            sin necesitarla. Almacén NO tiene acceso. Se asigna en Usuarios y roles. No se agrega a LIC_CAF_ADMIN.
--            Valor inicial: se concede una sola vez a quienes ya tienen la licencia de Coordinador (LIC_CAF_COORDINADOR o LIC_CAF_COORD_PROVEEDOR),
--            en su misma sede; después se puede quitar o dar a otros desde Usuarios y roles. Idempotente.
-- =============================================================================
SET search_path TO "CAF_GOVERNANCE";

INSERT INTO "Catalogo_Permiso" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create")
SELECT 'PER_CAF_DOC_INGRESO_CONSULTAR','Consultar los documentos de ingreso que sube Vigilancia (sin subirlos ni retirarlos)','ACCESOS',22,0
 WHERE NOT EXISTS (SELECT 1 FROM "Catalogo_Permiso" WHERE "Codigo"='PER_CAF_DOC_INGRESO_CONSULTAR');

INSERT INTO "Catalogo_Licencia" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create")
SELECT 'LIC_CAF_DOC_INGRESO_CONSULTA','Consultar documentos de ingreso: ver los documentos que sube Vigilancia (guías, listas de equipos o herramientas), sin subirlos','ACCESOS',29,0
 WHERE NOT EXISTS (SELECT 1 FROM "Catalogo_Licencia" WHERE "Codigo"='LIC_CAF_DOC_INGRESO_CONSULTA');

INSERT INTO "Licencia_Permiso" ("ID_Catalogo_Licencia","ID_Catalogo_Permiso","UsuarioID_Create")
SELECT l."ID_Catalogo_Licencia", p."ID_Catalogo_Permiso", 0
  FROM "Catalogo_Licencia" l
  JOIN "Catalogo_Permiso"  p ON p."Codigo" = 'PER_CAF_DOC_INGRESO_CONSULTAR'
 WHERE l."Codigo" = 'LIC_CAF_DOC_INGRESO_CONSULTA'
   AND NOT EXISTS (SELECT 1 FROM "Licencia_Permiso" lp
                    WHERE lp."ID_Catalogo_Licencia" = l."ID_Catalogo_Licencia" AND lp."ID_Catalogo_Permiso" = p."ID_Catalogo_Permiso");

-- Valor inicial: los coordinadores actuales (una sola vez; si ya la tenían, no se repite)
INSERT INTO "Usuario_Licencia" ("ID_Usuario","ID_Catalogo_Licencia","ID_Catalogo_Sede","UsuarioID_Create")
SELECT DISTINCT ul."ID_Usuario", nueva."ID_Catalogo_Licencia", ul."ID_Catalogo_Sede", 0
  FROM "Usuario_Licencia" ul
  JOIN "Catalogo_Licencia" cl    ON cl."ID_Catalogo_Licencia" = ul."ID_Catalogo_Licencia" AND cl."Codigo" IN ('LIC_CAF_COORDINADOR','LIC_CAF_COORD_PROVEEDOR')
  JOIN "Catalogo_Licencia" nueva ON nueva."Codigo" = 'LIC_CAF_DOC_INGRESO_CONSULTA'
 WHERE ul."Eliminado" = 'N'
   AND NOT EXISTS (SELECT 1 FROM "Usuario_Licencia" x
                    WHERE x."ID_Usuario" = ul."ID_Usuario" AND x."ID_Catalogo_Licencia" = nueva."ID_Catalogo_Licencia" AND x."ID_Catalogo_Sede" = ul."ID_Catalogo_Sede");
