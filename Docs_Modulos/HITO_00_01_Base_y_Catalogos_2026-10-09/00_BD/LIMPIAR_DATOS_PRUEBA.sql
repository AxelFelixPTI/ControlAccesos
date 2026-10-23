-- =============================================================================
-- Archivo : LIMPIAR_DATOS_PRUEBA.sql
-- Proyecto: Control de Accesos (piloto PostgreSQL, destino SAP HANA)
-- Versión : V1.0 2026-10-23
-- Uso     : psql -U postgres -d <base> -f LIMPIAR_DATOS_PRUEBA.sql
--           (restaurar_bd.ps1 NO lo ejecuta: es manual y borra datos de verdad).
-- =============================================================================
-- Deja la base lista para trabajar con datos reales:
--   1. BORRA todos los datos de operación: solicitudes, personas externas, decisiones, movimientos de portería,
--      respaldos, desviaciones, incidencias, correos pendientes y bitácora. Los números vuelven a empezar.
--   2. Si PARAM_BORRAR_USUARIOS_DEMO = true, BORRA los usuarios y el Personal de prueba (correo @trianon.test),
--      conservando solo el administrador indicado en PARAM_ADMIN_CONSERVAR.
--   3. NO toca los catálogos (sedes, áreas, cargos, licencias, permisos, zonas, motivos, checklist...) ni a los
--      usuarios y el Personal que usted haya creado con otros correos.
-- Seguridad: todo ocurre en una sola transacción. Si al terminar no quedara ningún administrador activo,
-- se cancela todo y no se borra nada.
--
-- ANTES DE EJECUTAR revise los dos parámetros de abajo. Flujo recomendado para pasar a datos reales:
--   a) Entre como admin.demo@trianon.test y cree su administrador real (Usuarios y roles) con la licencia
--      de administrador; defina su contraseña con el enlace y compruebe que entra.
--   b) Cambie PARAM_ADMIN_CONSERVAR por el correo de su administrador real y ejecute este script:
--      el administrador de prueba también se borra.
-- =============================================================================
DO $limpiar$
DECLARE
    PARAM_BORRAR_USUARIOS_DEMO CONSTANT BOOLEAN      := TRUE;
    PARAM_ADMIN_CONSERVAR      CONSTANT VARCHAR(200) := 'admin.demo@trianon.test';
    lv_admins INT;
    lv_u INT := 0; lv_p INT := 0;
BEGIN
    -- 1. Datos de operación
    TRUNCATE TABLE
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Correo_Pendiente",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Desviacion",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Evento",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Incidencia_Persona",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Persona_Externa",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Acceso",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Registro_Checklist",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Respaldo_Persona",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Copia_Correo",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Decision",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Persona",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Version",
        "TRIANONSATELITAL_CAF_PRODD"."CAF_Solicitud_Zona"
        RESTART IDENTITY;

    -- 2. Usuarios y Personal de prueba
    IF PARAM_BORRAR_USUARIOS_DEMO THEN
        DELETE FROM "CAF_GOVERNANCE"."Usuario_Licencia" UL
         USING "CAF_GOVERNANCE"."Usuario" U
         WHERE UL."ID_Usuario" = U."ID_Usuario" AND U."Correo" LIKE '%@trianon.test' AND U."Correo" <> PARAM_ADMIN_CONSERVAR;
        DELETE FROM "CAF_GOVERNANCE"."Usuario"
         WHERE "Correo" LIKE '%@trianon.test' AND "Correo" <> PARAM_ADMIN_CONSERVAR;
        GET DIAGNOSTICS lv_u = ROW_COUNT;
        DELETE FROM "CAF_GOVERNANCE"."Personal" P
         WHERE P."Correo" LIKE '%@trianon.test'
           AND NOT EXISTS (SELECT 1 FROM "CAF_GOVERNANCE"."Usuario" U WHERE U."ID_Personal" = P."ID_Personal");
        GET DIAGNOSTICS lv_p = ROW_COUNT;
    END IF;

    -- 3. Debe quedar al menos un administrador que pueda entrar
    SELECT COUNT(DISTINCT U."ID_Usuario") INTO lv_admins
      FROM "CAF_GOVERNANCE"."Usuario" U
      JOIN "CAF_GOVERNANCE"."Usuario_Licencia" UL ON UL."ID_Usuario" = U."ID_Usuario" AND UL."Eliminado" = 'N'
      JOIN "CAF_GOVERNANCE"."Catalogo_Licencia" L ON L."ID_Catalogo_Licencia" = UL."ID_Catalogo_Licencia" AND L."Codigo" = 'LIC_CAF_ADMIN'
     WHERE U."Activo" = 'Y' AND U."Eliminado" = 'N' AND U."Password_Hash" IS NOT NULL;
    IF lv_admins = 0 THEN
        RAISE EXCEPTION 'Cancelado: no quedaría ningún administrador activo con contraseña. Revise PARAM_ADMIN_CONSERVAR. No se borró nada.';
    END IF;

    RAISE NOTICE 'Listo. Datos de operación borrados. Usuarios de prueba borrados: %. Personal de prueba borrado: %. Administradores activos: %.', lv_u, lv_p, lv_admins;
END
$limpiar$;
