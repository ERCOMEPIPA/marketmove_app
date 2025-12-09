-- ============================================================
-- MIGRACIÓN: Crear tabla ordenes y detalle_ordenes
-- ============================================================
-- Ejecuta este script en Supabase SQL Editor para crear
-- las tablas necesarias para el módulo de órdenes

-- Paso 1: Crear tabla ordenes (si no existe)
CREATE TABLE IF NOT EXISTS public.ordenes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    estado TEXT NOT NULL DEFAULT 'Procesando' CHECK (estado IN ('Procesando', 'Aceptada', 'Entregada')),
    total DECIMAL(10, 2) NOT NULL CHECK (total >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Paso 2: Crear tabla detalle_ordenes (si no existe)
CREATE TABLE IF NOT EXISTS public.detalle_ordenes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    orden_id UUID NOT NULL REFERENCES public.ordenes(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio DECIMAL(10, 2) NOT NULL CHECK (precio >= 0),
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (cantidad * precio) STORED,
    imagen TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Paso 3: Crear índices
CREATE INDEX IF NOT EXISTS idx_ordenes_user_id ON public.ordenes(user_id);
CREATE INDEX IF NOT EXISTS idx_ordenes_owner_id ON public.ordenes(owner_id);
CREATE INDEX IF NOT EXISTS idx_ordenes_estado ON public.ordenes(estado);
CREATE INDEX IF NOT EXISTS idx_detalle_ordenes_orden_id ON public.detalle_ordenes(orden_id);

-- Paso 4: Habilitar RLS
ALTER TABLE public.ordenes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.detalle_ordenes ENABLE ROW LEVEL SECURITY;

-- Paso 5: Crear políticas RLS para ordenes
-- Permitir que los empleados vean solo sus propias órdenes
DROP POLICY IF EXISTS "Empleados ven sus propias ordenes" ON public.ordenes;
CREATE POLICY "Empleados ven sus propias ordenes"
    ON public.ordenes
    FOR SELECT
    USING (
        (auth.uid() = user_id AND auth.jwt()->>'role' = 'empleado')
        OR (auth.uid() = owner_id AND auth.jwt()->>'role' = 'dueno')
    );

-- Permitir que los dueños vean las órdenes de sus empleados
DROP POLICY IF EXISTS "Dueños ven ordenes de empleados" ON public.ordenes;
CREATE POLICY "Dueños ven ordenes de empleados"
    ON public.ordenes
    FOR SELECT
    USING (auth.uid() = owner_id);

-- Permitir crear órdenes
DROP POLICY IF EXISTS "Usuarios pueden crear ordenes" ON public.ordenes;
CREATE POLICY "Usuarios pueden crear ordenes"
    ON public.ordenes
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Permitir actualizar estado de órdenes
DROP POLICY IF EXISTS "Dueños pueden actualizar ordenes" ON public.ordenes;
CREATE POLICY "Dueños pueden actualizar ordenes"
    ON public.ordenes
    FOR UPDATE
    USING (auth.uid() = owner_id);

-- Paso 6: Crear políticas RLS para detalle_ordenes
-- Permitir ver detalles
DROP POLICY IF EXISTS "Ver detalles de ordenes" ON public.detalle_ordenes;
CREATE POLICY "Ver detalles de ordenes"
    ON public.detalle_ordenes
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.ordenes o
            WHERE o.id = orden_id
            AND (auth.uid() = o.user_id OR auth.uid() = o.owner_id)
        )
    );

-- Permitir insertar detalles
DROP POLICY IF EXISTS "Insertar detalles de ordenes" ON public.detalle_ordenes;
CREATE POLICY "Insertar detalles de ordenes"
    ON public.detalle_ordenes
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.ordenes o
            WHERE o.id = orden_id
            AND auth.uid() = o.user_id
        )
    );

-- ✅ ¡Listo! Las tablas han sido creadas correctamente
-- Puedes proceder a usar la aplicación
