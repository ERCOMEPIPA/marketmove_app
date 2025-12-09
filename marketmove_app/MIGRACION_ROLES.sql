-- ============================================================
-- MIGRACIÓN DE ROLES - MARKETMOVE
-- ============================================================
-- Este script actualiza el esquema de roles de 'admin/cliente' 
-- a 'superadmin/dueno/empleado'

-- ============================================================
-- PASO 1: Actualizar la tabla perfiles
-- ============================================================

-- Modificar la columna rol para aceptar los nuevos valores
ALTER TABLE public.perfiles 
DROP CONSTRAINT IF EXISTS perfiles_rol_check,
ADD CONSTRAINT perfiles_rol_check CHECK (rol IN ('superadmin', 'dueno', 'empleado'));

-- Actualizar datos existentes (convertir roles antiguos a nuevos)
UPDATE public.perfiles 
SET rol = 'dueno' 
WHERE rol = 'admin';

UPDATE public.perfiles 
SET rol = 'empleado' 
WHERE rol = 'cliente';

-- Cambiar el valor por defecto
ALTER TABLE public.perfiles 
ALTER COLUMN rol SET DEFAULT 'empleado';

-- ============================================================
-- PASO 2: Crear usuario de prueba EMPLEADO
-- ============================================================
-- Ejecuta esto en SQL Editor de Supabase para crear el usuario auth

-- Opción A: Crear manualmente en Auth > Users (recomendado)
-- Email: empleado@test.com
-- Password: Password123!

-- Opción B: O ejecuta en SQL Editor (requiere permisos especiales):
-- SELECT auth.create_user_with_email_and_password(
--   email := 'empleado@test.com',
--   password := 'Password123!'
-- );

-- ============================================================
-- PASO 3: Insertar perfil del empleado (después de crear el usuario auth)
-- ============================================================
-- IMPORTANTE: Reemplaza 'USER_ID_AQUI' con el ID real del usuario

-- INSERT INTO public.perfiles (id, email, nombre_negocio, rol)
-- VALUES (
--   'USER_ID_AQUI',
--   'empleado@test.com',
--   'Empleado Test',
--   'empleado'
-- )
-- ON CONFLICT (id) DO UPDATE SET
--   rol = 'empleado';

-- ============================================================
-- PASO 4: (Opcional) Crear superadmin de prueba
-- ============================================================
-- Crear usuario auth:
-- Email: superadmin@test.com
-- Password: SuperAdmin123!

-- Luego insertar en perfiles:
-- INSERT INTO public.perfiles (id, email, nombre_negocio, rol)
-- VALUES (
--   'SUPERADMIN_ID_AQUI',
--   'superadmin@test.com',
--   'SuperAdmin Test',
--   'superadmin'
-- )
-- ON CONFLICT (id) DO UPDATE SET
--   rol = 'superadmin';

-- ============================================================
-- VERIFICACIÓN
-- ============================================================
-- Ejecuta esto para verificar los cambios:
-- SELECT id, email, nombre_negocio, rol FROM public.perfiles;
