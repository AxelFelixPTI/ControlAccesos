-- =============================================================================
-- Archivo : 05_SEED_INICIAL.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Hito    : 0 y 1 | Carga inicial
-- Versión : V1.0 2026-10-09
-- Estado  : CANDIDATO - probado en PostgreSQL 16
-- =============================================================================
-- UsuarioID_Create = 0 significa "SISTEMA - carga inicial" (convención Trianon:
-- el UsuarioID de una carga inicial se declara). No existe un Usuario con ID 0.
-- Las referencias entre tablas se resuelven por CÓDIGO, nunca por ID fijo.
-- Valores marcados [POR VALIDAR] deben confirmarse con Control de Activos y SST.
-- No se crea ningún usuario aquí: el primer administrador se crea con el
-- procedimiento de arranque descrito en 00_PAQUETE_DISENO.md (sin contraseñas en scripts).
-- =============================================================================

-- ---------------------------------------------------------------- GOVERNANCE
SET search_path TO "CAF_GOVERNANCE";

INSERT INTO "Catalogo_Sede" ("Codigo","Descripcion","Direccion","Orden","UsuarioID_Create") VALUES
 ('VES','Villa El Salvador','[POR VALIDAR]',1,0),
 ('MAG','Oficinas de Magdalena','[POR VALIDAR]',2,0);

INSERT INTO "Catalogo_Tipo_Documento" ("Codigo","Descripcion","Longitud_Min","Longitud_Max","Solo_Numeros","Orden","UsuarioID_Create") VALUES
 ('DNI','DNI',8,8,'Y',1,0),
 ('CE','Carné de extranjería',9,12,'N',2,0),          -- [POR VALIDAR] longitudes
 ('PAS','Pasaporte',6,12,'N',3,0);                     -- [POR VALIDAR] longitudes

INSERT INTO "Catalogo_Empresa_Grupo" ("Codigo","Descripcion","Orden","UsuarioID_Create") VALUES
 ('TRIANON_ENERGO','Trianon Energo',1,0),
 ('POWER_TECHNOLOGY','Power Technology',2,0),
 ('TRIANON_ASCENSORES','Trianon Ascensores',3,0),
 ('TRIANON_SOSTENIBLE','Trianon Sostenible',4,0);    -- [POR VALIDAR] razón social y RUC

INSERT INTO "Catalogo_Area" ("Codigo","Descripcion","Orden","UsuarioID_Create") VALUES   -- [POR VALIDAR] lista real
 ('ADMINISTRACION','Administración',1,0),
 ('ALMACEN','Almacén',2,0),
 ('CALIDAD','Calidad',3,0),
 ('COMPRAS','Compras',4,0),
 ('CONTROL_ACTIVOS_SST','Control de Activos y SST',5,0),
 ('INGENIERIA','Ingeniería',6,0),
 ('PLANTA','Planta',7,0),
 ('TI','Tecnologías de la información',8,0);

INSERT INTO "Catalogo_Cargo" ("Codigo","Descripcion","Orden","UsuarioID_Create") VALUES  -- [POR VALIDAR] lista real
 ('COORD_CONTROL_ACTIVOS_SST','Coordinador de Control de Activos y SST',1,0),
 ('GERENTE_ADMINISTRACION','Gerente de Administración',2,0),
 ('JEFE_PLANTA','Jefe de Planta',3,0),
 ('JEFE_ALMACEN','Jefe de Almacén',4,0),
 ('JEFE_TI','Jefe de TI',5,0);

INSERT INTO "Catalogo_Licencia" ("Codigo","Descripcion","Modulo","Orden","UsuarioID_Create") VALUES
 ('LIC_CAF_SOLICITANTE','Solicitante: crea y gestiona solicitudes de visita','CAF',1,0),
 ('LIC_CAF_COORDINADOR','Coordinador: aprueba u observa, desviaciones, incidencias y reporte','CAF',2,0),
 ('LIC_CAF_VIGILANCIA','Vigilancia: ingreso, salida, desviaciones e incidencias en portería','CAF',3,0),
 ('LIC_CAF_ADMIN','Administrador: usuarios, licencias y catálogos','CAF',4,0);

-- ---------------------------------------------------------------- MÓDULO
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

INSERT INTO "Catalogo_Tipo_Acceso" ("Codigo","Descripcion","Requiere_Aprobacion","Disponible","Orden","UsuarioID_Create") VALUES
 ('VISITA_EXTERNA','Visitante externo','Y','Y',1,0),
 ('CONTRATISTA','Contratista','Y','N',2,0),
 ('PROVEEDOR','Proveedor de abastecimiento','Y','N',3,0),
 ('INTERNO_VISITANTE','Personal interno visitante','Y','N',4,0);

-- Zonas de VES tomadas del cuadro 4.18 del G-PSCA-002 + oficinas administrativas. [POR VALIDAR]
INSERT INTO "Catalogo_Zona_Acceso" ("ID_Catalogo_Sede","Codigo","Descripcion","Tipo_Zona","Exige_SCTR","Exige_EPP","Orden","UsuarioID_Create")
SELECT s."ID_Catalogo_Sede", z.codigo, z.descripcion, z.tipo, z.sctr, z.epp, z.orden, 0
  FROM "CAF_GOVERNANCE"."Catalogo_Sede" s
 CROSS JOIN (VALUES
   ('OFICINAS_ADM','Oficinas administrativas','ADMINISTRATIVA','N','N',1),
   ('OFICINA_1P','Oficina 1er piso','ADMINISTRATIVA','N','N',2),
   ('OFICINA_2P','Oficina 2do piso','ADMINISTRATIVA','N','N',3),
   ('ALMACEN_GENERAL','Almacén general','OPERATIVA','Y','Y',4),
   ('PRODUCTO_TERMINADO','Producto terminado','OPERATIVA','Y','Y',5),
   ('ALMACEN_MANTENIMIENTO','Almacén de material para mantenimiento y reparación','OPERATIVA','Y','Y',6),
   ('CORTE_CU','Corte Cu (planta)','OPERATIVA','Y','Y',7)
 ) AS z(codigo, descripcion, tipo, sctr, epp, orden)
 WHERE s."Codigo" = 'VES';

INSERT INTO "Catalogo_Motivo_Visita" ("Codigo","Descripcion","Es_Otro","Orden","UsuarioID_Create") VALUES   -- [POR VALIDAR]
 ('PRESENTACION_COMERCIAL','Presentación de propuesta comercial','N',1,0),
 ('REUNION_COORDINACION','Reunión de coordinación','N',2,0),
 ('VISITA_TECNICA','Visita técnica','N',3,0),
 ('AUDITORIA_INSPECCION','Auditoría o inspección','N',4,0),
 ('OTRO','Otro','Y',99,0);

INSERT INTO "Catalogo_Tratamiento_Desviacion" ("Codigo","Descripcion","Aplica_Ingreso","Aplica_Salida","Resultado_Ingreso","Resultado_Salida","Es_Otro","Orden","UsuarioID_Create") VALUES
 ('LIBERACION','Liberación','Y','Y','INGRESA','SALE','N',1,0),
 ('REGULARIZACION','Regularización','Y','Y','INGRESA','SALE','N',2,0),
 ('RESTRICCION_ZONA_ADM','Restricción a zona administrativa','Y','N','INGRESA_RESTRINGIDO',NULL,'N',3,0),
 ('DENEGATORIA','Denegatoria de acceso','Y','N','NO_INGRESA',NULL,'N',4,0),
 ('RETENCION_ELEMENTO','Retención del elemento','N','Y',NULL,'SALE_RETIENE_ELEMENTO','N',5,0),
 ('OTRO','Otro','Y','Y',NULL,NULL,'Y',99,0);

INSERT INTO "Catalogo_Tipo_Incidencia" ("Codigo","Descripcion","Es_Otro","Orden","UsuarioID_Create") VALUES
 ('HURTO','Hurto','N',1,0),
 ('ROBO','Robo','N',2,0),
 ('USO_NO_AUTORIZADO_AREA','Uso no autorizado de área','N',3,0),
 ('USO_NO_AUTORIZADO_EQUIPO','Uso no autorizado de equipos','N',4,0),
 ('DANO_INSTALACIONES','Daño a instalaciones','N',5,0),
 ('OTRO','Otro','Y',99,0);

INSERT INTO "Catalogo_Item_Checklist" ("Codigo","Descripcion","Ayuda","Etapa","Condicion","Es_Critico","Orden","UsuarioID_Create") VALUES
 ('ING_IDENTIDAD','Identidad verificada con documento físico','Compare DNI o CE con la solicitud.','INGRESO','SIEMPRE','Y',1,0),
 ('ING_RESPONSABLE_CONFIRMA','Responsable de atención confirmó la llegada',NULL,'INGRESO','SIEMPRE','N',2,0),
 ('ING_SCTR','SCTR vigente',NULL,'INGRESO','ZONA_EXIGE_SCTR','N',3,0),
 ('ING_EPP','EPP básicos completos','Casco, lentes, zapatos de seguridad y chaleco con cinta reflectiva.','INGRESO','ZONA_EXIGE_EPP','N',4,0),
 ('ING_PERTENENCIAS','Pertenencias revisadas',NULL,'INGRESO','SIEMPRE','N',5,0),
 ('ING_ARCO','Pasó por el arco detector de metales',NULL,'INGRESO','SIEMPRE','N',6,0),
 ('ING_FICHA_ENTREGADA','Ficha de visita G-FSCA-011 entregada',NULL,'INGRESO','SIEMPRE','N',7,0),
 ('SAL_RESPONSABLE_ACOMPANA','Responsable de atención acompañó hasta la salida',NULL,'SALIDA','SIEMPRE','N',1,0),
 ('SAL_FICHA_DEVUELTA','Ficha G-FSCA-011 devuelta, llenada y firmada',NULL,'SALIDA','SIEMPRE','N',2,0),
 ('SAL_ARCO','Pasó por el arco detector de metales',NULL,'SALIDA','SIEMPRE','N',3,0),
 ('SAL_SIN_ELEMENTOS','No retira elementos sin autorización o sustento',NULL,'SALIDA','SIEMPRE','N',4,0),
 ('SAL_EQUIPOS','Equipos verificados contra el G-FSCA-009',NULL,'SALIDA','TRAE_EQUIPOS','N',5,0),
 ('SAL_HERRAMIENTAS','Herramientas y materiales verificados contra la guía',NULL,'SALIDA','TRAE_HERRAMIENTAS','N',6,0);

-- Todos los ítems aplican al visitante externo.
INSERT INTO "Tipo_Acceso_Item_Checklist" ("ID_Catalogo_Tipo_Acceso","ID_Catalogo_Item_Checklist","UsuarioID_Create")
SELECT t."ID_Catalogo_Tipo_Acceso", i."ID_Catalogo_Item_Checklist", 0
  FROM "Catalogo_Tipo_Acceso" t
 CROSS JOIN "Catalogo_Item_Checklist" i
 WHERE t."Codigo" = 'VISITA_EXTERNA';
