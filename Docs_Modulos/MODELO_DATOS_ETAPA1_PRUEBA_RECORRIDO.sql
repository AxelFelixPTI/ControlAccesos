-- =============================================================================
-- Archivo : MODELO_DATOS_ETAPA1_PRUEBA_RECORRIDO.sql
-- Proyecto: Control de Accesos · Versión V1.0 2026-10-09
-- Propósito: PRUEBA DEL MODELO, no es un script de despliegue.
--   Guarda la visita SOL de Energía Verde del mockup (2 visitantes) por todas
--   las tablas y responde 4 preguntas reales. Termina en ROLLBACK: la base
--   queda exactamente como estaba.
-- Requiere: scripts 01 a 08 ejecutados. Datos ficticios.
-- Nota: aquí se escribe directo en las tablas solo para probar el modelo. En la
-- aplicación, TODO pasa por procedimientos ERP_* (que asignan códigos, validan
-- reglas y escriben la bitácora).
-- =============================================================================

BEGIN;
SET search_path TO "TRIANONSATELITAL_CAF_PRODD";

-- ---------------------------------------------------------------- 1. Personas internas
INSERT INTO "CAF_GOVERNANCE"."Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","ID_Catalogo_Area","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","Anexo","UsuarioID_Create")
SELECT td."ID_Catalogo_Tipo_Documento", v.doc, v.pat, v.mat, v.nom, a."ID_Catalogo_Area", e."ID_Catalogo_Empresa_Grupo", s."ID_Catalogo_Sede", v.correo, v.anexo, 0
  FROM (VALUES
    ('45120933','Núñez','Paredes','Gabriela','INGENIERIA','gabriela.nunez@ejemplo.pe','214'),
    ('45231987','Mendoza','Ríos','Carlos Alberto','INGENIERIA','carlos.mendoza@ejemplo.pe','210'),
    ('25847561','Paredes','Huanca','Roberto José','CONTROL_ACTIVOS_SST','roberto.paredes@ejemplo.pe','101')
  ) AS v(doc,pat,mat,nom,area,correo,anexo)
  JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" td ON td."Codigo" = 'DNI'
  JOIN "CAF_GOVERNANCE"."Catalogo_Area" a ON a."Codigo" = v.area
  JOIN "CAF_GOVERNANCE"."Catalogo_Empresa_Grupo" e ON e."Codigo" = 'TRIANON_ASCENSORES'
  JOIN "CAF_GOVERNANCE"."Catalogo_Sede" s ON s."Codigo" = 'VES';

-- ---------------------------------------------------------------- 2. Usuarios y licencias
INSERT INTO "CAF_GOVERNANCE"."Usuario" ("Correo","ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","ID_Personal","Empresa_Externa","UsuarioID_Create")
SELECT v.correo, td."ID_Catalogo_Tipo_Documento", v.doc, v.pat, v.mat, v.nom, p."ID_Personal", v.externa, 0
  FROM (VALUES
    ('carlos.mendoza@ejemplo.pe','45231987','Mendoza','Ríos','Carlos Alberto',NULL),
    ('roberto.paredes@ejemplo.pe','25847561','Paredes','Huanca','Roberto José',NULL),
    ('maria.quispe@ejemplo.pe','41239987','Quispe','Torres','María',  'Seguridad Ejemplo S.A.C.')
  ) AS v(correo,doc,pat,mat,nom,externa)
  JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" td ON td."Codigo" = 'DNI'
  LEFT JOIN "CAF_GOVERNANCE"."Personal" p ON p."Numero_Documento" = v.doc;

INSERT INTO "CAF_GOVERNANCE"."Usuario_Licencia" ("ID_Usuario","ID_Catalogo_Licencia","ID_Catalogo_Sede","UsuarioID_Create")
SELECT u."ID_Usuario", l."ID_Catalogo_Licencia", s."ID_Catalogo_Sede", 0
  FROM (VALUES ('carlos.mendoza@ejemplo.pe','LIC_CAF_SOLICITANTE'),
               ('roberto.paredes@ejemplo.pe','LIC_CAF_COORDINADOR'),
               ('maria.quispe@ejemplo.pe','LIC_CAF_VIGILANCIA')) AS v(correo,lic)
  JOIN "CAF_GOVERNANCE"."Usuario" u ON u."Correo" = v.correo
  JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" l ON l."Codigo" = v.lic
  JOIN "CAF_GOVERNANCE"."Catalogo_Sede" s ON s."Codigo" = 'VES';

-- ---------------------------------------------------------------- 3. Personas externas
INSERT INTO "CAF_Persona_Externa" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres","UsuarioID_Create")
SELECT td."ID_Catalogo_Tipo_Documento", v.doc, v.pat, v.mat, v.nom, 0
  FROM (VALUES ('72341890','Torres','Quispe','Luis Miguel'), ('45871236','Vargas','Ríos','Ana Lucía')) AS v(doc,pat,mat,nom)
  JOIN "CAF_GOVERNANCE"."Catalogo_Tipo_Documento" td ON td."Codigo" = 'DNI';

-- ---------------------------------------------------------------- 4. Carlos crea y envía la solicitud
INSERT INTO "CAF_Solicitud" ("ID_Catalogo_Sede","ID_Catalogo_Tipo_Acceso","ID_Usuario_Solicitante","ID_Personal_Responsable","Fecha_Hora_Prevista","Empresa_Visitante","ID_Catalogo_Motivo_Visita","Observaciones","Exige_SCTR","Exige_EPP","Estado","Fecha_Envio","UsuarioID_Create")
SELECT s."ID_Catalogo_Sede", t."ID_Catalogo_Tipo_Acceso", u."ID_Usuario", p."ID_Personal", TIMESTAMP '2026-10-08 09:00:00',
       'Energía Verde S.A.C.', m."ID_Catalogo_Motivo_Visita", 'Traerán una laptop y un proyector.', 'Y', 'Y', 'PENDIENTE', TIMESTAMP '2026-10-08 07:40:00', u."ID_Usuario"
  FROM "CAF_GOVERNANCE"."Catalogo_Sede" s, "Catalogo_Tipo_Acceso" t, "CAF_GOVERNANCE"."Usuario" u, "CAF_GOVERNANCE"."Personal" p, "Catalogo_Motivo_Visita" m
 WHERE s."Codigo" = 'VES' AND t."Codigo" = 'VISITA_EXTERNA' AND u."Correo" = 'carlos.mendoza@ejemplo.pe'
   AND p."Numero_Documento" = '45120933' AND m."Codigo" = 'PRESENTACION_COMERCIAL';
-- El SP asigna el código a partir del ID (D-15).
UPDATE "CAF_Solicitud" SET "Codigo" = 'SOL-' || LPAD(CAST("ID_Solicitud" AS VARCHAR), 5, '0') WHERE "Codigo" IS NULL;

INSERT INTO "CAF_Solicitud_Zona" ("ID_Solicitud","ID_Catalogo_Zona_Acceso","UsuarioID_Create")
SELECT so."ID_Solicitud", z."ID_Catalogo_Zona_Acceso", 0
  FROM "CAF_Solicitud" so JOIN "Catalogo_Zona_Acceso" z ON z."Codigo" IN ('OFICINAS_ADM','PRODUCTO_TERMINADO')
 WHERE so."Empresa_Visitante" = 'Energía Verde S.A.C.';

INSERT INTO "CAF_Solicitud_Persona" ("ID_Solicitud","ID_Persona_Externa","UsuarioID_Create")
SELECT so."ID_Solicitud", pe."ID_Persona_Externa", 0
  FROM "CAF_Solicitud" so CROSS JOIN "CAF_Persona_Externa" pe
 WHERE so."Empresa_Visitante" = 'Energía Verde S.A.C.';

INSERT INTO "CAF_Correo_Pendiente" ("Tipo","ID_Solicitud","Destinatarios","Asunto","Cuerpo","UsuarioID_Create")
SELECT 'SOLICITUD_NUEVA', "ID_Solicitud", 'roberto.paredes@ejemplo.pe', 'Nueva solicitud ' || "Codigo", '<p>Solicitud pendiente de aprobación.</p>', 0
  FROM "CAF_Solicitud";

INSERT INTO "CAF_Evento" ("Entidad","ID_Entidad","ID_Solicitud","Accion","Detalle","ID_Usuario","Fecha_Evento","UsuarioID_Create")
SELECT 'SOLICITUD', so."ID_Solicitud", so."ID_Solicitud", 'CREAR_Y_ENVIAR', 'Solicitud creada y enviada a aprobación', so."ID_Usuario_Solicitante", TIMESTAMP '2026-10-08 07:40:00', so."ID_Usuario_Solicitante"
  FROM "CAF_Solicitud" so;

-- ---------------------------------------------------------------- 5. Roberto aprueba
UPDATE "CAF_Solicitud" so SET "Estado" = 'APROBADA', "ID_Usuario_Decision" = u."ID_Usuario", "Fecha_Decision" = TIMESTAMP '2026-10-08 08:05:00',
       "UsuarioID_Update" = u."ID_Usuario", "UpdateDate" = CURRENT_TIMESTAMP
  FROM "CAF_GOVERNANCE"."Usuario" u WHERE u."Correo" = 'roberto.paredes@ejemplo.pe';

INSERT INTO "CAF_Solicitud_Version" ("ID_Solicitud","Version","Contenido_JSON","ID_Usuario_Aprobador","Fecha_Aprobacion","UsuarioID_Create")
SELECT so."ID_Solicitud", so."Version", '{"codigo":"' || so."Codigo" || '","personas":2,"zonas":["OFICINAS_ADM","PRODUCTO_TERMINADO"]}',
       so."ID_Usuario_Decision", so."Fecha_Decision", so."ID_Usuario_Decision"
  FROM "CAF_Solicitud" so;

INSERT INTO "CAF_Evento" ("Entidad","ID_Entidad","ID_Solicitud","Accion","Detalle","ID_Usuario","Fecha_Evento","UsuarioID_Create")
SELECT 'SOLICITUD', "ID_Solicitud", "ID_Solicitud", 'APROBAR', 'Solicitud aprobada', "ID_Usuario_Decision", "Fecha_Decision", "ID_Usuario_Decision" FROM "CAF_Solicitud";

-- ---------------------------------------------------------------- 6. Luis ingresa 08:52 con SCTR vencido
INSERT INTO "CAF_Registro_Acceso" ("ID_Solicitud_Persona","ID_Catalogo_Sede","Tipo_Movimiento","Resultado","Fecha_Hora","ID_Usuario_Vigilante","UsuarioID_Create")
SELECT sp."ID_Solicitud_Persona", so."ID_Catalogo_Sede", 'INGRESO', 'INGRESA_RESTRINGIDO', TIMESTAMP '2026-10-08 08:52:00', u."ID_Usuario", u."ID_Usuario"
  FROM "CAF_Solicitud_Persona" sp
  JOIN "CAF_Solicitud" so ON so."ID_Solicitud" = sp."ID_Solicitud"
  JOIN "CAF_Persona_Externa" pe ON pe."ID_Persona_Externa" = sp."ID_Persona_Externa" AND pe."Numero_Documento" = '72341890'
  JOIN "CAF_GOVERNANCE"."Usuario" u ON u."Correo" = 'maria.quispe@ejemplo.pe';

-- Checklist: los 7 ítems de ingreso que aplican (zona exige SCTR y EPP); SCTR no cumple.
INSERT INTO "CAF_Registro_Checklist" ("ID_Registro_Acceso","ID_Catalogo_Item_Checklist","Cumple","UsuarioID_Create")
SELECT ra."ID_Registro_Acceso", i."ID_Catalogo_Item_Checklist", CASE WHEN i."Codigo" = 'ING_SCTR' THEN 'N' ELSE 'Y' END, ra."ID_Usuario_Vigilante"
  FROM "CAF_Registro_Acceso" ra CROSS JOIN "Catalogo_Item_Checklist" i
 WHERE i."Etapa" = 'INGRESO';

INSERT INTO "CAF_Desviacion" ("ID_Registro_Acceso","Descripcion","ID_Usuario_Coordinador_Consultado","ID_Catalogo_Tratamiento_Desviacion","Resultado","UsuarioID_Create")
SELECT ra."ID_Registro_Acceso", 'SCTR vencido el 30/09/2026; presenta constancia de renovación en trámite.', u."ID_Usuario",
       t."ID_Catalogo_Tratamiento_Desviacion", t."Resultado_Ingreso", ra."ID_Usuario_Vigilante"
  FROM "CAF_Registro_Acceso" ra, "CAF_GOVERNANCE"."Usuario" u, "Catalogo_Tratamiento_Desviacion" t
 WHERE u."Correo" = 'roberto.paredes@ejemplo.pe' AND t."Codigo" = 'RESTRICCION_ZONA_ADM';
UPDATE "CAF_Desviacion" SET "Codigo" = 'DES-' || LPAD(CAST("ID_Desviacion" AS VARCHAR), 5, '0') WHERE "Codigo" IS NULL;

UPDATE "CAF_Solicitud_Persona" sp SET "Estado" = 'DENTRO', "Acceso_Restringido" = 'Y', "Fecha_Hora_Ingreso" = TIMESTAMP '2026-10-08 08:52:00'
  FROM "CAF_Persona_Externa" pe WHERE pe."ID_Persona_Externa" = sp."ID_Persona_Externa" AND pe."Numero_Documento" = '72341890';

-- ---------------------------------------------------------------- 7. Ana ingresa 09:04 con herramientas (guía manual)
INSERT INTO "CAF_Registro_Acceso" ("ID_Solicitud_Persona","ID_Catalogo_Sede","Tipo_Movimiento","Resultado","Fecha_Hora","ID_Usuario_Vigilante","UsuarioID_Create")
SELECT sp."ID_Solicitud_Persona", so."ID_Catalogo_Sede", 'INGRESO', 'INGRESA', TIMESTAMP '2026-10-08 09:04:00', u."ID_Usuario", u."ID_Usuario"
  FROM "CAF_Solicitud_Persona" sp
  JOIN "CAF_Solicitud" so ON so."ID_Solicitud" = sp."ID_Solicitud"
  JOIN "CAF_Persona_Externa" pe ON pe."ID_Persona_Externa" = sp."ID_Persona_Externa" AND pe."Numero_Documento" = '45871236'
  JOIN "CAF_GOVERNANCE"."Usuario" u ON u."Correo" = 'maria.quispe@ejemplo.pe';

INSERT INTO "CAF_Registro_Checklist" ("ID_Registro_Acceso","ID_Catalogo_Item_Checklist","Cumple","UsuarioID_Create")
SELECT ra."ID_Registro_Acceso", i."ID_Catalogo_Item_Checklist", 'Y', ra."ID_Usuario_Vigilante"
  FROM "CAF_Registro_Acceso" ra CROSS JOIN "Catalogo_Item_Checklist" i
 WHERE i."Etapa" = 'INGRESO' AND ra."Fecha_Hora" = TIMESTAMP '2026-10-08 09:04:00';

INSERT INTO "CAF_Respaldo" ("ID_Catalogo_Sede","Categoria","Tipo_Respaldo","Fecha_Hora","ID_Usuario_Vigilante","UsuarioID_Create")
SELECT s."ID_Catalogo_Sede", 'HERRAMIENTAS_MATERIALES', 'GUIA_MANUAL_G_FSCA_010', TIMESTAMP '2026-10-08 09:04:00', u."ID_Usuario", u."ID_Usuario"
  FROM "CAF_GOVERNANCE"."Catalogo_Sede" s, "CAF_GOVERNANCE"."Usuario" u WHERE s."Codigo" = 'VES' AND u."Correo" = 'maria.quispe@ejemplo.pe';

INSERT INTO "CAF_Respaldo_Persona" ("ID_Respaldo","ID_Solicitud_Persona","UsuarioID_Create")
SELECT r."ID_Respaldo", sp."ID_Solicitud_Persona", r."ID_Usuario_Vigilante"
  FROM "CAF_Respaldo" r, "CAF_Solicitud_Persona" sp JOIN "CAF_Persona_Externa" pe ON pe."ID_Persona_Externa" = sp."ID_Persona_Externa"
 WHERE pe."Numero_Documento" = '45871236';

UPDATE "CAF_Solicitud_Persona" sp SET "Estado" = 'DENTRO', "Trae_Herramientas" = 'Y', "Fecha_Hora_Ingreso" = TIMESTAMP '2026-10-08 09:04:00'
  FROM "CAF_Persona_Externa" pe WHERE pe."ID_Persona_Externa" = sp."ID_Persona_Externa" AND pe."Numero_Documento" = '45871236';

-- ---------------------------------------------------------------- 8. Vigilancia registra una incidencia sobre Luis
INSERT INTO "CAF_Incidencia" ("ID_Catalogo_Sede","ID_Catalogo_Tipo_Incidencia","Fecha_Hora_Hecho","ID_Catalogo_Zona_Acceso","Descripcion","Origen","ID_Usuario_Registro","Estado","UsuarioID_Create")
SELECT s."ID_Catalogo_Sede", ti."ID_Catalogo_Tipo_Incidencia", TIMESTAMP '2026-10-08 10:20:00', z."ID_Catalogo_Zona_Acceso",
       'Con acceso restringido, fue encontrado en Producto terminado sin acompañamiento.', 'VIGILANCIA', u."ID_Usuario", 'REGISTRADA', u."ID_Usuario"
  FROM "CAF_GOVERNANCE"."Catalogo_Sede" s, "Catalogo_Tipo_Incidencia" ti, "Catalogo_Zona_Acceso" z, "CAF_GOVERNANCE"."Usuario" u
 WHERE s."Codigo" = 'VES' AND ti."Codigo" = 'USO_NO_AUTORIZADO_AREA' AND z."Codigo" = 'PRODUCTO_TERMINADO' AND u."Correo" = 'maria.quispe@ejemplo.pe';
UPDATE "CAF_Incidencia" SET "Codigo" = 'INC-' || LPAD(CAST("ID_Incidencia" AS VARCHAR), 5, '0') WHERE "Codigo" IS NULL;

INSERT INTO "CAF_Incidencia_Persona" ("ID_Incidencia","ID_Solicitud_Persona","UsuarioID_Create")
SELECT i."ID_Incidencia", sp."ID_Solicitud_Persona", i."ID_Usuario_Registro"
  FROM "CAF_Incidencia" i, "CAF_Solicitud_Persona" sp JOIN "CAF_Persona_Externa" pe ON pe."ID_Persona_Externa" = sp."ID_Persona_Externa"
 WHERE pe."Numero_Documento" = '72341890';

-- ---------------------------------------------------------------- 9. Ana sale 11:42 (checklist de salida, incluye herramientas)
INSERT INTO "CAF_Registro_Acceso" ("ID_Solicitud_Persona","ID_Catalogo_Sede","Tipo_Movimiento","Resultado","Fecha_Hora","ID_Usuario_Vigilante","UsuarioID_Create")
SELECT sp."ID_Solicitud_Persona", so."ID_Catalogo_Sede", 'SALIDA', 'SALE', TIMESTAMP '2026-10-08 11:42:00', u."ID_Usuario", u."ID_Usuario"
  FROM "CAF_Solicitud_Persona" sp
  JOIN "CAF_Solicitud" so ON so."ID_Solicitud" = sp."ID_Solicitud"
  JOIN "CAF_Persona_Externa" pe ON pe."ID_Persona_Externa" = sp."ID_Persona_Externa" AND pe."Numero_Documento" = '45871236'
  JOIN "CAF_GOVERNANCE"."Usuario" u ON u."Correo" = 'maria.quispe@ejemplo.pe';

INSERT INTO "CAF_Registro_Checklist" ("ID_Registro_Acceso","ID_Catalogo_Item_Checklist","Cumple","UsuarioID_Create")
SELECT ra."ID_Registro_Acceso", i."ID_Catalogo_Item_Checklist", 'Y', ra."ID_Usuario_Vigilante"
  FROM "CAF_Registro_Acceso" ra CROSS JOIN "Catalogo_Item_Checklist" i
 WHERE ra."Tipo_Movimiento" = 'SALIDA' AND i."Etapa" = 'SALIDA' AND i."Condicion" IN ('SIEMPRE','TRAE_HERRAMIENTAS');

UPDATE "CAF_Solicitud_Persona" sp SET "Estado" = 'SALIO', "Fecha_Hora_Salida" = TIMESTAMP '2026-10-08 11:42:00'
  FROM "CAF_Persona_Externa" pe WHERE pe."ID_Persona_Externa" = sp."ID_Persona_Externa" AND pe."Numero_Documento" = '45871236';

-- =============================================================================
-- PREGUNTAS
-- =============================================================================

\echo '--- P1. ¿Quién estuvo autorizado a entrar a Producto terminado el jueves 08/10/2026?'
SELECT pe."Apellido_Paterno" || ' ' || pe."Apellido_Materno" || ', ' || pe."Nombres" AS "Persona",
       pe."Numero_Documento" AS "DNI", so."Empresa_Visitante" AS "Empresa",
       TO_CHAR(sp."Fecha_Hora_Ingreso",'HH24:MI') AS "Ingreso", COALESCE(TO_CHAR(sp."Fecha_Hora_Salida",'HH24:MI'),'—') AS "Salida",
       CASE sp."Acceso_Restringido" WHEN 'Y' THEN 'No: restringido a zona administrativa' ELSE 'Sí' END AS "¿Podía entrar a esa zona?"
  FROM "CAF_Solicitud_Persona" sp
  JOIN "CAF_Solicitud" so ON so."ID_Solicitud" = sp."ID_Solicitud"
  JOIN "CAF_Solicitud_Zona" sz ON sz."ID_Solicitud" = so."ID_Solicitud"
  JOIN "Catalogo_Zona_Acceso" z ON z."ID_Catalogo_Zona_Acceso" = sz."ID_Catalogo_Zona_Acceso" AND z."Codigo" = 'PRODUCTO_TERMINADO'
  JOIN "CAF_Persona_Externa" pe ON pe."ID_Persona_Externa" = sp."ID_Persona_Externa"
 WHERE CAST(sp."Fecha_Hora_Ingreso" AS DATE) = DATE '2026-10-08'
 ORDER BY sp."Fecha_Hora_Ingreso";

\echo '--- P2. Reporte de ingresos y salidas del día (reemplaza el G-FSCA-008)'
SELECT TO_CHAR(ra."Fecha_Hora",'DD/MM HH24:MI') AS "Fecha y hora", ra."Tipo_Movimiento" AS "Movimiento",
       pe."Apellido_Paterno" || ', ' || pe."Nombres" AS "Persona", so."Codigo" AS "Solicitud",
       ra."Resultado", vig."Nombres" || ' ' || vig."Apellido_Paterno" AS "Vigilante",
       COALESCE(d."Codigo",'—') AS "Desviación"
  FROM "CAF_Registro_Acceso" ra
  JOIN "CAF_Solicitud_Persona" sp ON sp."ID_Solicitud_Persona" = ra."ID_Solicitud_Persona"
  JOIN "CAF_Solicitud" so ON so."ID_Solicitud" = sp."ID_Solicitud"
  JOIN "CAF_Persona_Externa" pe ON pe."ID_Persona_Externa" = sp."ID_Persona_Externa"
  JOIN "CAF_GOVERNANCE"."Usuario" vig ON vig."ID_Usuario" = ra."ID_Usuario_Vigilante"
  LEFT JOIN "CAF_Desviacion" d ON d."ID_Registro_Acceso" = ra."ID_Registro_Acceso"
 ORDER BY ra."Fecha_Hora";

\echo '--- P3. Desviaciones por revisar, con los ítems que no se cumplieron'
SELECT d."Codigo", pe."Apellido_Paterno" || ', ' || pe."Nombres" AS "Persona",
       STRING_AGG(i."Descripcion", '; ') AS "No cumplió", t."Descripcion" AS "Decisión indicada", d."Resultado"
  FROM "CAF_Desviacion" d
  JOIN "CAF_Registro_Acceso" ra ON ra."ID_Registro_Acceso" = d."ID_Registro_Acceso"
  JOIN "CAF_Registro_Checklist" rc ON rc."ID_Registro_Acceso" = ra."ID_Registro_Acceso" AND rc."Cumple" = 'N'
  JOIN "Catalogo_Item_Checklist" i ON i."ID_Catalogo_Item_Checklist" = rc."ID_Catalogo_Item_Checklist"
  JOIN "Catalogo_Tratamiento_Desviacion" t ON t."ID_Catalogo_Tratamiento_Desviacion" = d."ID_Catalogo_Tratamiento_Desviacion"
  JOIN "CAF_Solicitud_Persona" sp ON sp."ID_Solicitud_Persona" = ra."ID_Solicitud_Persona"
  JOIN "CAF_Persona_Externa" pe ON pe."ID_Persona_Externa" = sp."ID_Persona_Externa"
 WHERE d."Estado" = 'POR_REVISAR'
 GROUP BY d."Codigo", pe."Apellido_Paterno", pe."Nombres", t."Descripcion", d."Resultado";

\echo '--- P4. Estado de cada persona de la solicitud y sus incidencias'
SELECT so."Codigo", so."Estado" AS "Estado solicitud", pe."Nombres" || ' ' || pe."Apellido_Paterno" AS "Persona",
       sp."Estado" AS "Estado persona", sp."Trae_Herramientas" AS "Herramientas",
       COALESCE(STRING_AGG(inc."Codigo" || ' (' || inc."Estado" || ')', ', '), '—') AS "Incidencias"
  FROM "CAF_Solicitud" so
  JOIN "CAF_Solicitud_Persona" sp ON sp."ID_Solicitud" = so."ID_Solicitud"
  JOIN "CAF_Persona_Externa" pe ON pe."ID_Persona_Externa" = sp."ID_Persona_Externa"
  LEFT JOIN "CAF_Incidencia_Persona" ip ON ip."ID_Solicitud_Persona" = sp."ID_Solicitud_Persona"
  LEFT JOIN "CAF_Incidencia" inc ON inc."ID_Incidencia" = ip."ID_Incidencia"
 GROUP BY so."Codigo", so."Estado", pe."Nombres", pe."Apellido_Paterno", sp."Estado", sp."Trae_Herramientas"
 ORDER BY pe."Apellido_Paterno";

ROLLBACK;
