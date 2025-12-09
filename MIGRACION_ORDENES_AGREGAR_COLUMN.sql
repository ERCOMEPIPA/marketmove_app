-- ============================================================
-- MIGRACIÓN: Agregar owner_id a tabla ordenes existente
-- ============================================================
-- Este script agrega la columna owner_id si no existe

-- Paso 1: Agregar la columna owner_id si no existe
-- (Primero necesita tener un valor temporal)
ALTER TABLE public.ordenes 
ADD COLUMN IF NOT EXISTS owner_id UUID;

-- Paso 2: Si la tabla ya tiene datos sin owner_id, necesitamos asignar uno
-- Esto asume que cada user_id es empleado y necesita un owner_id
-- IMPORTANTE: Debes ajustar esto según tu lógica de negocio
-- Por ahora, si hay órdenes antiguas sin owner_id, las asignamos al mismo user_id
UPDATE public.ordenes 
SET owner_id = user_id 
WHERE owner_id IS NULL;

-- Paso 3: Ahora hacemos la columna NOT NULL y agregamos la referencia
ALTER TABLE public.ordenes
ALTER COLUMN owner_id SET NOT NULL;

-- Paso 4: Agregar la constrainta de Foreign Key
ALTER TABLE public.ordenes
ADD CONSTRAINT ordenes_owner_id_fkey 
FOREIGN KEY (owner_id) 
REFERENCES public.perfiles(id) ON DELETE CASCADE;

-- Paso 5: Crear índice para optimizar búsquedas
CREATE INDEX IF NOT EXISTS idx_ordenes_owner_id ON public.ordenes(owner_id);

-- ✅ ¡Listo! La columna owner_id ha sido agregada correctamente
