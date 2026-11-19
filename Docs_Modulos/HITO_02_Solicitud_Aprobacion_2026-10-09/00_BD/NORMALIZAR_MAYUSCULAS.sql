-- ============================================================================================================
-- Archivo : NORMALIZAR_MAYUSCULAS.sql      (OPCIONAL, una sola vez; NO lo corre restaurar_bd.ps1)
-- Version : V1.0 2026-11-18 (D-250)
-- Proposito: desde la entrega 2C-2m los nombres y empresas se guardan en MAYUSCULAS. Este script pasa a MAYUSCULAS lo que ya
--            estaba guardado con minusculas, para que no queden datos mezclados.
-- Cambia  : apellidos y nombres de Personal, Usuarios y Personas externas; empresa externa del usuario; y de las solicitudes:
--           empresa o procedencia, empresa transportista, contacto, detalle del area, placa, direccion, marca y licencia.
-- No toca : correos, observaciones, motivos, numeros de documento ni ningun catalogo. Es repetible (la segunda vez no cambia nada).
-- ============================================================================================================
BEGIN;
SET LOCAL search_path TO "TRIANONSATELITAL_CAF_PRODD";

UPDATE "CAF_Persona_Externa" SET "Apellido_Paterno" = UPPER("Apellido_Paterno"), "Apellido_Materno" = UPPER("Apellido_Materno"), "Nombres" = UPPER("Nombres")
 WHERE "Apellido_Paterno" <> UPPER("Apellido_Paterno") OR "Apellido_Materno" <> UPPER("Apellido_Materno") OR "Nombres" <> UPPER("Nombres");

UPDATE "CAF_GOVERNANCE"."Personal" SET "Apellido_Paterno" = UPPER("Apellido_Paterno"), "Apellido_Materno" = UPPER("Apellido_Materno"), "Nombres" = UPPER("Nombres")
 WHERE "Apellido_Paterno" <> UPPER("Apellido_Paterno") OR "Apellido_Materno" <> UPPER("Apellido_Materno") OR "Nombres" <> UPPER("Nombres");

UPDATE "CAF_GOVERNANCE"."Usuario" SET "Apellido_Paterno" = UPPER("Apellido_Paterno"), "Apellido_Materno" = UPPER("Apellido_Materno"), "Nombres" = UPPER("Nombres"), "Empresa_Externa" = UPPER("Empresa_Externa")
 WHERE "Apellido_Paterno" <> UPPER("Apellido_Paterno") OR "Apellido_Materno" <> UPPER("Apellido_Materno") OR "Nombres" <> UPPER("Nombres") OR "Empresa_Externa" <> UPPER("Empresa_Externa");

UPDATE "CAF_Solicitud" SET "Empresa_Visitante" = UPPER("Empresa_Visitante"), "Empresa_Transportista" = UPPER("Empresa_Transportista"), "Contacto_Nombre" = UPPER("Contacto_Nombre"),
       "Area_Detalle" = UPPER("Area_Detalle"), "Placa_Vehiculo" = UPPER("Placa_Vehiculo"), "Proveedor_Direccion" = UPPER("Proveedor_Direccion"),
       "Vehiculo_Marca" = UPPER("Vehiculo_Marca"), "Licencia_Conducir" = UPPER("Licencia_Conducir")
 WHERE "Empresa_Visitante" <> UPPER("Empresa_Visitante") OR "Empresa_Transportista" <> UPPER("Empresa_Transportista") OR "Contacto_Nombre" <> UPPER("Contacto_Nombre")
    OR "Area_Detalle" <> UPPER("Area_Detalle") OR "Placa_Vehiculo" <> UPPER("Placa_Vehiculo") OR "Proveedor_Direccion" <> UPPER("Proveedor_Direccion")
    OR "Vehiculo_Marca" <> UPPER("Vehiculo_Marca") OR "Licencia_Conducir" <> UPPER("Licencia_Conducir");
COMMIT;
