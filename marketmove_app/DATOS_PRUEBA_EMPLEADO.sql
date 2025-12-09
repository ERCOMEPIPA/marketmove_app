-- ============================================================
-- SCRIPT DE DATOS DE PRUEBA PARA MARKETMOVE - EMPLEADO
-- ============================================================
-- Este script crea un usuario de prueba con rol de EMPLEADO
-- y datos asociados para pruebas

-- IMPORTANTE: Este script asume que:
-- 1. El esquema ya está creado (supabase_schema.sql ejecutado)
-- 2. Tienes acceso a PostgreSQL de Supabase

-- ============================================================
-- PASO 1: Crear usuario de autenticación (EMPLEADO)
-- ============================================================
-- En Supabase Auth > Users, crea manualmente este usuario:
-- Email: empleado@test.com
-- Password: Password123!

-- O ejecuta en SQL Editor:
-- SELECT auth.create_user_with_email_and_password(
--   email := 'empleado@test.com',
--   password := 'Password123!'
-- );

-- ============================================================
-- PASO 2: Actualizar tabla perfiles con rol de EMPLEADO
-- ============================================================
-- NOTA: Reemplaza 'USUARIO_ID_AQUI' con el ID real del usuario creado

-- Primero, ve a Supabase > Auth > Users y copia el UUID del usuario empleado
-- Luego ejecuta:
/*
INSERT INTO public.perfiles (id, email, nombre_negocio, rol)
VALUES (
  'REEMPLAZA_CON_ID_REAL_DEL_USUARIO',
  'empleado@test.com',
  'Empleado Test',
  'empleado'
)
ON CONFLICT (id) DO UPDATE SET
  rol = 'empleado',
  email = 'empleado@test.com';
*/

-- ============================================================
-- PASO 3: Crear datos de prueba para empleado
-- ============================================================

-- Si tienes un dueño/admin existente, puedes crear productos de prueba
-- Reemplaza 'DUENO_ID' con el ID del dueño
/*
INSERT INTO public.categorias (user_id, nombre, tipo, color)
VALUES 
  ('DUENO_ID', 'Electrónica', 'producto', '#FF6B6B'),
  ('DUENO_ID', 'Ropa', 'producto', '#4ECDC4'),
  ('DUENO_ID', 'Alimentos', 'producto', '#45B7D1');

INSERT INTO public.productos (user_id, nombre, descripcion, precio, stock, categoria_id)
VALUES
  ('DUENO_ID', 'Laptop', 'Laptop de prueba', 1500.00, 5, (SELECT id FROM categorias WHERE nombre = 'Electrónica' AND user_id = 'DUENO_ID')),
  ('DUENO_ID', 'Camisa', 'Camisa de algodón', 25.00, 20, (SELECT id FROM categorias WHERE nombre = 'Ropa' AND user_id = 'DUENO_ID')),
  ('DUENO_ID', 'Pan', 'Pan integral fresco', 3.50, 50, (SELECT id FROM categorias WHERE nombre = 'Alimentos' AND user_id = 'DUENO_ID'));
*/

-- ============================================================
-- INSTRUCCIONES MANUALES
-- ============================================================
-- 1. Ve a https://supabase.com/dashboard
-- 2. Selecciona tu proyecto
-- 3. Ve a "SQL Editor"
-- 4. Haz clic en "New Query"
-- 5. Copia y ejecuta el código para crear el usuario auth

-- 6. Luego copia el UUID del usuario y ejecuta el INSERT en perfiles

-- 7. Si quieres datos de productos, copia el ID del dueño y ejecuta los INSERT de categorias y productos
