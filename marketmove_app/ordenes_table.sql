-- ============================================================
-- TABLA: ordenes (Para el módulo de empleado/cliente)
-- ============================================================
-- Esta tabla almacena las órdenes realizadas por empleados
-- Permite que los dueños vean las órdenes de sus empleados

CREATE TABLE IF NOT EXISTS public.ordenes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    owner_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    estado TEXT NOT NULL DEFAULT 'Procesando' CHECK (estado IN ('Procesando', 'Aceptada', 'Entregada')),
    total DECIMAL(10, 2) NOT NULL CHECK (total >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla: detalle_ordenes
-- Descripción: Items/productos incluidos en cada orden
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

-- ============================================================
-- POLÍTICAS RLS (Row Level Security)
-- ============================================================

-- Habilitar RLS en la tabla ordenes
ALTER TABLE public.ordenes ENABLE ROW LEVEL SECURITY;

-- Permitir que los empleados vean solo sus propias órdenes
CREATE POLICY "Empleados ven sus propias ordenes"
    ON public.ordenes
    FOR SELECT
    USING (auth.uid() = user_id);

-- Permitir que los dueños vean todas las órdenes de sus empleados
CREATE POLICY "Dueños ven ordenes de sus empleados"
    ON public.ordenes
    FOR SELECT
    USING (auth.uid() = owner_id);

-- Permitir que los empleados creen órdenes
CREATE POLICY "Empleados pueden crear ordenes"
    ON public.ordenes
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Permitir que los dueños actualicen el estado de órdenes
CREATE POLICY "Dueños pueden actualizar estado de ordenes"
    ON public.ordenes
    FOR UPDATE
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- Habilitar RLS en detalle_ordenes
ALTER TABLE public.detalle_ordenes ENABLE ROW LEVEL SECURITY;

-- Permitir acceso a detalle_ordenes si el usuario puede acceder a la orden
CREATE POLICY "Acceso a detalle de ordenes"
    ON public.detalle_ordenes
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.ordenes
            WHERE ordenes.id = detalle_ordenes.orden_id
            AND (ordenes.user_id = auth.uid() OR ordenes.owner_id = auth.uid())
        )
    );
