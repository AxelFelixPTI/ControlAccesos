-- =============================================================================
-- Archivo : 11_SEED_DEMO_USUARIOS.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Hito    : 0 | Datos de prueba para poder entrar a la aplicación tras reconstruir la base
-- Versión : V1.0 2026-10-23
-- Estado  : CANDIDATO - SOLO PARA PILOTO / PRUEBAS (ver LIMPIAR_DATOS_PRUEBA.sql)
-- =============================================================================
-- Crea 8 personas en Personal y 8 usuarios, TODOS FICTICIOS (correos @trianon.test, que no existe;
-- documentos 900000xx; contraseñas de prueba públicas). Cada usuario tiene una licencia en la sede VES.
--
--   Rol           Correo                              Contraseña
--   Administrador admin.demo@trianon.test             Admin.Demo#2026
--   Coordinador   coordinador.demo@trianon.test       Coord.Demo#2026
--   Vigilancia    vigilante1/2/3.demo@trianon.test    Vigi.Demo#2026
--   Solicitante   solicitante1/2/3.demo@trianon.test  Solic.Demo#2026
--
-- Las contraseñas se guardan con el mismo formato que usa la aplicación (PBKDF2-SHA256, 210 000 vueltas).
-- Se puede ejecutar más de una vez: lo que ya existe no se duplica.
-- NO USAR EN PRODUCCIÓN: antes de trabajar con datos reales cambie las contraseñas o elimine estos usuarios
-- con LIMPIAR_DATOS_PRUEBA.sql (conservando el administrador que usted decida).
-- UsuarioID_Create = 0 significa "SISTEMA - carga inicial".
-- =============================================================================
SET search_path TO "CAF_GOVERNANCE";

-- Personal (por código de catálogo, nunca por ID fijo)
INSERT INTO "Personal" ("ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres",
                        "ID_Catalogo_Area","ID_Catalogo_Cargo","ID_Catalogo_Empresa_Grupo","ID_Catalogo_Sede","Correo","UsuarioID_Create")
SELECT td."ID_Catalogo_Tipo_Documento", v.doc, v.ap, v.am, v.nom, ar."ID_Catalogo_Area", ca."ID_Catalogo_Cargo",
       em."ID_Catalogo_Empresa_Grupo", se."ID_Catalogo_Sede", v.correo, 0
  FROM (VALUES
   ('90000001','Administrador','Demo','Alex','TI','JEFE_TI','TRIANON_ENERGO','admin.demo@trianon.test'),
   ('90000002','Coordinadora','Demo','Carla','CONTROL_ACTIVOS_SST','COORD_CONTROL_ACTIVOS_SST','TRIANON_ENERGO','coordinador.demo@trianon.test'),
   ('90000011','Vigilante','Uno','Victor','CONTROL_ACTIVOS_SST',NULL,'TRIANON_ENERGO','vigilante1.demo@trianon.test'),
   ('90000012','Vigilante','Dos','Valeria','CONTROL_ACTIVOS_SST',NULL,'TRIANON_ENERGO','vigilante2.demo@trianon.test'),
   ('90000013','Vigilante','Tres','Victoria','CONTROL_ACTIVOS_SST',NULL,'TRIANON_ENERGO','vigilante3.demo@trianon.test'),
   ('90000021','Solicitante','Uno','Sergio','INGENIERIA','JEFE_PLANTA','POWER_TECHNOLOGY','solicitante1.demo@trianon.test'),
   ('90000022','Solicitante','Dos','Sofia','COMPRAS',NULL,'TRIANON_ASCENSORES','solicitante2.demo@trianon.test'),
   ('90000023','Solicitante','Tres','Samuel','ALMACEN','JEFE_ALMACEN','TRIANON_ENERGO','solicitante3.demo@trianon.test')
  ) AS v(doc, ap, am, nom, area, cargo, empresa, correo)
  JOIN "Catalogo_Tipo_Documento" td ON td."Codigo" = 'DNI'
  JOIN "Catalogo_Area" ar ON ar."Codigo" = v.area
  LEFT JOIN "Catalogo_Cargo" ca ON ca."Codigo" = v.cargo
  JOIN "Catalogo_Empresa_Grupo" em ON em."Codigo" = v.empresa
  JOIN "Catalogo_Sede" se ON se."Codigo" = 'VES'
ON CONFLICT ("ID_Catalogo_Tipo_Documento","Numero_Documento") DO NOTHING;

-- Usuarios vinculados a su persona de Personal. No piden cambiar la contraseña al primer ingreso (son de prueba).
INSERT INTO "Usuario" ("Correo","ID_Catalogo_Tipo_Documento","Numero_Documento","Apellido_Paterno","Apellido_Materno","Nombres",
                       "ID_Personal","Password_Hash","Password_Requiere_Cambio","UsuarioID_Create")
SELECT v.correo, p."ID_Catalogo_Tipo_Documento", p."Numero_Documento", p."Apellido_Paterno", p."Apellido_Materno", p."Nombres",
       p."ID_Personal", v.hash, 'N', 0
  FROM (VALUES
   ('admin.demo@trianon.test','90000001','PBKDF2$SHA256$210000$H2nbvQ0Dr+XM17gyNjQJ7w==$qfW6lM3VWKipIXw03H5CYY2vd5vPuSDclLClP/+lDnQ='),
   ('coordinador.demo@trianon.test','90000002','PBKDF2$SHA256$210000$hFpgSPgrw0hR+5Y1P6cxsQ==$6ZFx1KDK3Z1CEiud0NU/bt8oFNf8m8ue7PDU26veJyc='),
   ('vigilante1.demo@trianon.test','90000011','PBKDF2$SHA256$210000$KNiRvsV2LdsfcdhsmHGaCA==$CVDBIOufh/UqgGLWNCmRgWAAcwPI48i9ViXXf+3++5s='),
   ('vigilante2.demo@trianon.test','90000012','PBKDF2$SHA256$210000$kTVTO6LUUljItAJ6iug79g==$6pGXK6oeSzYK6N9XMZGfwyccKEdiBcn7p1y3Lr/duXI='),
   ('vigilante3.demo@trianon.test','90000013','PBKDF2$SHA256$210000$iiBRJdRZ97dKIlrV4ARHfw==$OrRjotKXhWU2fYde0JgrGs17+KAG8rPB82XGQKwxfwI='),
   ('solicitante1.demo@trianon.test','90000021','PBKDF2$SHA256$210000$O/JbAbQkkQwrJol6GAVZgw==$yiqNCKEPDr9CIA18aWsr/e/733uO/RP0OOYpxCRidS8='),
   ('solicitante2.demo@trianon.test','90000022','PBKDF2$SHA256$210000$7tkDeqWfF6RK+74p+ZTdLA==$avSEQK6q44xOyHkcFn/SvqmWrfbzL1R47EVvA7HwkJs='),
   ('solicitante3.demo@trianon.test','90000023','PBKDF2$SHA256$210000$2ddkRcnaOS+FlQ/Zf3UFnQ==$x/GjGPh2TdEKvB/F8T6DCuO88wSQhg+0Atxll7ZSsmI=')
  ) AS v(correo, doc, hash)
  JOIN "Catalogo_Tipo_Documento" td ON td."Codigo" = 'DNI'
  JOIN "Personal" p ON p."ID_Catalogo_Tipo_Documento" = td."ID_Catalogo_Tipo_Documento" AND p."Numero_Documento" = v.doc
ON CONFLICT ("Correo") DO NOTHING;

-- Licencias en la sede VES
INSERT INTO "Usuario_Licencia" ("ID_Usuario","ID_Catalogo_Licencia","ID_Catalogo_Sede","UsuarioID_Create")
SELECT u."ID_Usuario", l."ID_Catalogo_Licencia", se."ID_Catalogo_Sede", 0
  FROM (VALUES
   ('admin.demo@trianon.test','LIC_CAF_ADMIN'),
   ('coordinador.demo@trianon.test','LIC_CAF_COORDINADOR'),
   ('vigilante1.demo@trianon.test','LIC_CAF_VIGILANCIA'),
   ('vigilante2.demo@trianon.test','LIC_CAF_VIGILANCIA'),
   ('vigilante3.demo@trianon.test','LIC_CAF_VIGILANCIA'),
   ('solicitante1.demo@trianon.test','LIC_CAF_SOLICITANTE'),
   ('solicitante2.demo@trianon.test','LIC_CAF_SOLICITANTE'),
   ('solicitante3.demo@trianon.test','LIC_CAF_SOLICITANTE')
  ) AS v(correo, licencia)
  JOIN "Usuario" u ON u."Correo" = v.correo
  JOIN "Catalogo_Licencia" l ON l."Codigo" = v.licencia
  JOIN "Catalogo_Sede" se ON se."Codigo" = 'VES'
ON CONFLICT ("ID_Usuario","ID_Catalogo_Licencia","ID_Catalogo_Sede") DO NOTHING;
