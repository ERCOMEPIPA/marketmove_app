-- ============================================================
-- MIGRACIÓN: Agregar Sistema de Roles
-- ============================================================
-- Este script actualiza una base de datos existente para agregar
-- el sistema de roles (admin/cliente)
-- ============================================================

-- ============================================================
-- 1. AGREGAR COLUMNA 'ROL' A LA TABLA PERFILES
-- ============================================================

-- Agregar la columna rol si no existe
ALTER TABLE public.perfiles 
ADD COLUMN IF NOT EXISTS rol TEXT DEFAULT 'cliente';

-- Actualizar valores NULL a 'cliente'
UPDATE public.perfiles 
SET rol = 'cliente' 
WHERE rol IS NULL;

-- Hacer la columna NOT NULL
ALTER TABLE public.perfiles 
ALTER COLUMN rol SET NOT NULL;

-- Agregar constraint de validación
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'perfiles_rol_check'
    ) THEN
        ALTER TABLE public.perfiles 
        ADD CONSTRAINT perfiles_rol_check 
        CHECK (rol IN ('admin', 'cliente'));
    END IF;
END $$;

-- ============================================================
-- 2. AGREGAR COLUMNA 'CLIENTE_ID' A LA TABLA VENTAS
-- ============================================================

ALTER TABLE public.ventas 
ADD COLUMN IF NOT EXISTS cliente_id UUID REFERENCES public.perfiles(id) ON DELETE SET NULL;

-- Crear índice para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_ventas_cliente_id ON public.ventas(cliente_id);

-- ============================================================
-- 3. ACTUALIZAR POLÍTICAS RLS
-- ============================================================

-- IMPORTANTE: Primero eliminamos las políticas existentes y las recreamos

-- ============================================================
-- Políticas para CATEGORIAS
-- ============================================================

DROP POLICY IF EXISTS "Users can view own categories" ON public.categorias;
DROP POLICY IF EXISTS "Users can insert own categories" ON public.categorias;
DROP POLICY IF EXISTS "Users can update own categories" ON public.categorias;
DROP POLICY IF EXISTS "Users can delete own categories" ON public.categorias;

-- Solo los admins pueden gestionar categorías
CREATE POLICY "Admins can view own categories"
    ON public.categorias FOR SELECT
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

CREATE POLICY "Admins can insert categories"
    ON public.categorias FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

CREATE POLICY "Admins can update own categories"
    ON public.categorias FOR UPDATE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

CREATE POLICY "Admins can delete own categories"
    ON public.categorias FOR DELETE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- ============================================================
-- Políticas para PRODUCTOS
-- ============================================================

DROP POLICY IF EXISTS "Users can view own products" ON public.productos;
DROP POLICY IF EXISTS "Users can insert own products" ON public.productos;
DROP POLICY IF EXISTS "Users can update own products" ON public.productos;
DROP POLICY IF EXISTS "Users can delete own products" ON public.productos;

-- Admins ven sus productos, clientes ven productos activos
CREATE POLICY "Users can view products"
    ON public.productos FOR SELECT
    USING (
        auth.uid() = user_id OR 
        (activo = true AND stock > 0 AND 
         EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'cliente'))
    );

CREATE POLICY "Admins can insert products"
    ON public.productos FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

CREATE POLICY "Admins can update own products"
    ON public.productos FOR UPDATE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

CREATE POLICY "Admins can delete own products"
    ON public.productos FOR DELETE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- ============================================================
-- Políticas para VENTAS
-- ============================================================

DROP POLICY IF EXISTS "Users can view own sales" ON public.ventas;
DROP POLICY IF EXISTS "Users can insert own sales" ON public.ventas;
DROP POLICY IF EXISTS "Users can update own sales" ON public.ventas;
DROP POLICY IF EXISTS "Users can delete own sales" ON public.ventas;

-- Admins ven sus ventas, clientes ven sus compras
CREATE POLICY "Users can view sales"
    ON public.ventas FOR SELECT
    USING (
        auth.uid() = user_id OR 
        (auth.uid() = cliente_id AND 
         EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'cliente'))
    );

CREATE POLICY "Admins can insert sales"
    ON public.ventas FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

CREATE POLICY "Admins can update own sales"
    ON public.ventas FOR UPDATE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

CREATE POLICY "Admins can delete own sales"
    ON public.ventas FOR DELETE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- ============================================================
-- Políticas para DETALLE_VENTAS
-- ============================================================

DROP POLICY IF EXISTS "Users can view own sale details" ON public.detalle_ventas;

CREATE POLICY "Users can view sale details"
    ON public.detalle_ventas FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.ventas
            WHERE id = detalle_ventas.venta_id
            AND (user_id = auth.uid() OR cliente_id = auth.uid())
        )
    );

-- ============================================================
-- Políticas para GASTOS
-- ============================================================

DROP POLICY IF EXISTS "Users can view own expenses" ON public.gastos;
DROP POLICY IF EXISTS "Users can insert own expenses" ON public.gastos;
DROP POLICY IF EXISTS "Users can update own expenses" ON public.gastos;
DROP POLICY IF EXISTS "Users can delete own expenses" ON public.gastos;

-- Solo admins pueden gestionar gastos
CREATE POLICY "Admins can view own expenses"
    ON public.gastos FOR SELECT
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

CREATE POLICY "Admins can insert expenses"
    ON public.gastos FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

CREATE POLICY "Admins can update own expenses"
    ON public.gastos FOR UPDATE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

CREATE POLICY "Admins can delete own expenses"
    ON public.gastos FOR DELETE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- ============================================================
-- 4. CREAR USUARIO ADMIN DE PRUEBA (OPCIONAL)
-- ============================================================

-- Si ya tienes un usuario registrado, actualiza su rol a admin
-- Descomenta y actualiza con tu email:


UPDATE public.perfiles 
SET rol = 'admin' 
WHERE email = 'iscov@marketmove.com';


-- ============================================================
-- VERIFICACIÓN
-- ============================================================

-- Verificar que la columna rol existe
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'perfiles' AND column_name = 'rol';

-- Ver todos los usuarios y sus roles
SELECT id, email, rol, created_at 
FROM public.perfiles;

-- ============================================================
-- FIN DE LA MIGRACIÓN
-- ============================================================
