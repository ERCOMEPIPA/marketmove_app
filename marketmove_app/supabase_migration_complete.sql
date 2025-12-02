-- ============================================================
-- MIGRACIÓN 2: Campos Completos + Sistema de 3 Roles
-- ============================================================
-- Esta migración actualiza la base de datos para cumplir con
-- todos los requisitos del cliente
-- ============================================================

-- ============================================================
-- 1. AGREGAR CAMPOS FALTANTES
-- ============================================================

-- 1.1 Agregar método de pago a VENTAS
ALTER TABLE public.ventas 
ADD COLUMN IF NOT EXISTS metodo_pago TEXT CHECK (
    metodo_pago IN ('efectivo', 'tarjeta_debito', 'tarjeta_credito', 'transferencia', 'otro')
);

-- Establecer valor por defecto para registros existentes
UPDATE public.ventas 
SET metodo_pago = 'efectivo' 
WHERE metodo_pago IS NULL;

-- 1.2 Agregar método de pago a GASTOS
ALTER TABLE public.gastos 
ADD COLUMN IF NOT EXISTS metodo_pago TEXT CHECK (
    metodo_pago IN ('efectivo', 'tarjeta_debito', 'tarjeta_credito', 'transferencia', 'otro')
);

-- Establecer valor por defecto para registros existentes
UPDATE public.gastos 
SET metodo_pago = 'efectivo' 
WHERE metodo_pago IS NULL;

-- 1.3 Agregar campo para foto en GASTOS
ALTER TABLE public.gastos 
ADD COLUMN IF NOT EXISTS foto_url TEXT;

-- 1.4 Agregar código de barras a PRODUCTOS
ALTER TABLE public.productos 
ADD COLUMN IF NOT EXISTS codigo_barras TEXT;

-- Crear índice para búsqueda rápida por código de barras
CREATE INDEX IF NOT EXISTS idx_productos_codigo_barras 
ON public.productos(codigo_barras);

-- ============================================================
-- 2. EXPANDIR SISTEMA DE ROLES (2 → 3 niveles)
-- ============================================================

-- 2.1 Eliminar constraint anterior
ALTER TABLE public.perfiles 
DROP CONSTRAINT IF EXISTS perfiles_rol_check;

-- 2.2 Migrar roles existentes
-- admin → dueno (dueño del negocio)
-- cliente → empleado (empleado del negocio)
UPDATE public.perfiles 
SET rol = 'dueno' 
WHERE rol = 'admin';

UPDATE public.perfiles 
SET rol = 'empleado' 
WHERE rol = 'cliente';

-- 2.3 Agregar nuevo constraint con 3 roles
ALTER TABLE public.perfiles 
ADD CONSTRAINT perfiles_rol_check 
CHECK (rol IN ('superadmin', 'dueno', 'empleado'));

-- 2.4 Establecer valor por defecto como 'empleado'
ALTER TABLE public.perfiles 
ALTER COLUMN rol SET DEFAULT 'empleado';

-- ============================================================
-- 3. CREAR TABLA NEGOCIOS (Multi-tenancy)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.negocios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nombre TEXT NOT NULL,
    descripcion TEXT,
    logo_url TEXT,
    telefono TEXT,
    direccion TEXT,
    email TEXT,
    dueno_id UUID REFERENCES public.perfiles(id) ON DELETE SET NULL,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.1 Agregar campo negocio_id a perfiles
ALTER TABLE public.perfiles 
ADD COLUMN IF NOT EXISTS negocio_id UUID REFERENCES public.negocios(id) ON DELETE SET NULL;

-- 3.2 Índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_negocios_dueno ON public.negocios(dueno_id);
CREATE INDEX IF NOT EXISTS idx_perfiles_negocio ON public.perfiles(negocio_id);

-- ============================================================
-- 4. ACTUALIZAR POLÍTICAS RLS PARA 3 ROLES
-- ============================================================

-- 4.1 Políticas para PRODUCTOS

DROP POLICY IF EXISTS "Users can view products" ON public.productos;
DROP POLICY IF EXISTS "Admins can insert products" ON public.productos;
DROP POLICY IF EXISTS "Admins can update own products" ON public.productos;
DROP POLICY IF EXISTS "Admins can delete own products" ON public.productos;

-- Superadmin: ve todos los productos
-- Dueño: ve sus productos
-- Empleado: ve productos de su negocio
CREATE POLICY "View products by role"
    ON public.productos FOR SELECT
    USING (
        -- Superadmin ve todo
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
        OR
        -- Dueño ve sus productos
        (auth.uid() = user_id AND EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'dueno'))
        OR
        -- Empleado ve productos de su negocio
        (EXISTS (
            SELECT 1 FROM public.perfiles p 
            WHERE p.id = auth.uid() 
            AND p.rol = 'empleado' 
            AND p.negocio_id = (SELECT negocio_id FROM public.perfiles WHERE id = productos.user_id)
        ))
    );

-- Solo superadmin y dueño pueden crear productos
CREATE POLICY "Insert products by role"
    ON public.productos FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol IN ('superadmin', 'dueno'))
    );

-- Solo superadmin y dueño pueden actualizar productos
CREATE POLICY "Update products by role"
    ON public.productos FOR UPDATE
    USING (
        (auth.uid() = user_id AND EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'dueno'))
        OR
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
    );

-- Solo superadmin y dueño pueden eliminar productos
CREATE POLICY "Delete products by role"
    ON public.productos FOR DELETE
    USING (
        (auth.uid() = user_id AND EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'dueno'))
        OR
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
    );

-- 4.2 Políticas para VENTAS

DROP POLICY IF EXISTS "Users can view sales" ON public.ventas;
DROP POLICY IF EXISTS "Admins can insert sales" ON public.ventas;
DROP POLICY IF EXISTS "Admins can update own sales" ON public.ventas;
DROP POLICY IF EXISTS "Admins can delete own sales" ON public.ventas;

-- Ver ventas según rol
CREATE POLICY "View sales by role"
    ON public.ventas FOR SELECT
    USING (
        -- Superadmin ve todo
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
        OR
        -- Dueño ve ventas de su negocio
        (auth.uid() = user_id AND EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'dueno'))
        OR
        -- Empleado ve ventas de su negocio
        (EXISTS (
            SELECT 1 FROM public.perfiles p 
            WHERE p.id = auth.uid() 
            AND p.rol = 'empleado' 
            AND p.negocio_id = (SELECT negocio_id FROM public.perfiles WHERE id = ventas.user_id)
        ))
    );

-- Dueño y empleado pueden crear ventas
CREATE POLICY "Insert sales by role"
    ON public.ventas FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol IN ('dueno', 'empleado'))
    );

-- Solo dueño puede actualizar/eliminar ventas
CREATE POLICY "Update sales by role"
    ON public.ventas FOR UPDATE
    USING (
        (auth.uid() = user_id AND EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'dueno'))
        OR
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
    );

CREATE POLICY "Delete sales by role"
    ON public.ventas FOR DELETE
    USING (
        (auth.uid() = user_id AND EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'dueno'))
        OR
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
    );

-- 4.3 Políticas para GASTOS (solo dueño y superadmin)

DROP POLICY IF EXISTS "Admins can view own expenses" ON public.gastos;
DROP POLICY IF EXISTS "Admins can insert expenses" ON public.gastos;
DROP POLICY IF EXISTS "Admins can update own expenses" ON public.gastos;
DROP POLICY IF EXISTS "Admins can delete own expenses" ON public.gastos;

CREATE POLICY "View expenses by role"
    ON public.gastos FOR SELECT
    USING (
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
        OR
        (auth.uid() = user_id AND EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'dueno'))
    );

CREATE POLICY "Insert expenses by role"
    ON public.gastos FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol IN ('superadmin', 'dueno'))
    );

CREATE POLICY "Update expenses by role"
    ON public.gastos FOR UPDATE
    USING (
        (auth.uid() = user_id AND EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'dueno'))
        OR
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
    );

CREATE POLICY "Delete expenses by role"
    ON public.gastos FOR DELETE
    USING (
        (auth.uid() = user_id AND EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'dueno'))
        OR
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
    );

-- ============================================================
-- 5. POLÍTICAS RLS PARA NEGOCIOS
-- ============================================================

ALTER TABLE public.negocios ENABLE ROW LEVEL SECURITY;

-- Superadmin ve todos los negocios
-- Dueños ven su negocio
-- Empleados ven su negocio
CREATE POLICY "View negocios by role"
    ON public.negocios FOR SELECT
    USING (
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
        OR
        auth.uid() = dueno_id
        OR
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND negocio_id = negocios.id)
    );

-- Solo superadmin puede crear negocios
CREATE POLICY "Superadmin can insert negocios"
    ON public.negocios FOR INSERT
    WITH CHECK (
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
    );

-- Superadmin y dueño pueden actualizar
CREATE POLICY "Update negocios by role"
    ON public.negocios FOR UPDATE
    USING (
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
        OR
        auth.uid() = dueno_id
    );

-- Solo superadmin puede eliminar negocios
CREATE POLICY "Superadmin can delete negocios"
    ON public.negocios FOR DELETE
    USING (
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'superadmin')
    );

-- ============================================================
-- 6. TRIGGER PARA UPDATED_AT EN NEGOCIOS
-- ============================================================

DROP TRIGGER IF EXISTS update_negocios_updated_at ON public.negocios;
CREATE TRIGGER update_negocios_updated_at
    BEFORE UPDATE ON public.negocios
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- 7. VERIFICACIÓN
-- ============================================================

-- Ver todos los usuarios y sus nuevos roles
SELECT id, email, rol, negocio_id, created_at 
FROM public.perfiles 
ORDER BY rol, email;

-- Ver estructura de ventas con nuevos campos
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'ventas' 
ORDER BY ordinal_position;

-- Ver estructura de gastos con nuevos campos
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'gastos' 
ORDER BY ordinal_position;

-- Ver estructura de productos con código de barras
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'productos' 
ORDER BY ordinal_position;

-- ============================================================
-- FIN DE LA MIGRACIÓN
-- ============================================================
