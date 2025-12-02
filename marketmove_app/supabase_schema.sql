-- ============================================================
-- MARKETMOVE - ESQUEMA DE BASE DE DATOS SUPABASE
-- ============================================================
-- Este script crea todas las tablas, políticas RLS, triggers
-- y funciones necesarias para la aplicación MarketMove
-- ============================================================

-- ============================================================
-- 1. EXTENSIONES
-- ============================================================

-- Habilitar la extensión UUID (ya está habilitada por defecto en Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 2. TABLAS
-- ============================================================

-- Tabla: perfiles
-- Descripción: Extiende la información de los usuarios de auth.users
-- Incluye el campo 'rol' para diferenciar entre admin y cliente
CREATE TABLE IF NOT EXISTS public.perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    nombre_negocio TEXT,
    telefono TEXT,
    rol TEXT NOT NULL DEFAULT 'cliente' CHECK (rol IN ('admin', 'cliente')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla: categorias
-- Descripción: Categorías para clasificar productos y gastos
CREATE TABLE IF NOT EXISTS public.categorias (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('producto', 'gasto')),
    color TEXT DEFAULT '#6366f1',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, nombre, tipo)
);

-- Tabla: productos
-- Descripción: Inventario de productos del negocio
CREATE TABLE IF NOT EXISTS public.productos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10, 2) NOT NULL CHECK (precio >= 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    stock_minimo INTEGER DEFAULT 10 CHECK (stock_minimo >= 0),
    categoria_id UUID REFERENCES public.categorias(id) ON DELETE SET NULL,
    imagen_url TEXT,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla: ventas
-- Descripción: Registro de todas las ventas realizadas
-- user_id: el admin/negocio que registra la venta
-- cliente_id: el cliente que realiza la compra (puede ser NULL para ventas sin cliente registrado)
CREATE TABLE IF NOT EXISTS public.ventas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    cliente_id UUID REFERENCES public.perfiles(id) ON DELETE SET NULL,
    concepto TEXT NOT NULL,
    monto DECIMAL(10, 2) NOT NULL CHECK (monto >= 0),
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla: detalle_ventas
-- Descripción: Detalle de productos vendidos en cada venta
CREATE TABLE IF NOT EXISTS public.detalle_ventas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venta_id UUID NOT NULL REFERENCES public.ventas(id) ON DELETE CASCADE,
    producto_id UUID REFERENCES public.productos(id) ON DELETE SET NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla: gastos
-- Descripción: Registro de todos los gastos del negocio
CREATE TABLE IF NOT EXISTS public.gastos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
    concepto TEXT NOT NULL,
    monto DECIMAL(10, 2) NOT NULL CHECK (monto >= 0),
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    categoria_id UUID REFERENCES public.categorias(id) ON DELETE SET NULL,
    notas TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. ÍNDICES
-- ============================================================

-- Índices para mejorar el rendimiento de las consultas
CREATE INDEX IF NOT EXISTS idx_categorias_user_id ON public.categorias(user_id);
CREATE INDEX IF NOT EXISTS idx_productos_user_id ON public.productos(user_id);
CREATE INDEX IF NOT EXISTS idx_productos_categoria ON public.productos(categoria_id);
CREATE INDEX IF NOT EXISTS idx_ventas_user_id ON public.ventas(user_id);
CREATE INDEX IF NOT EXISTS idx_ventas_fecha ON public.ventas(fecha);
CREATE INDEX IF NOT EXISTS idx_detalle_ventas_venta_id ON public.detalle_ventas(venta_id);
CREATE INDEX IF NOT EXISTS idx_detalle_ventas_producto_id ON public.detalle_ventas(producto_id);
CREATE INDEX IF NOT EXISTS idx_gastos_user_id ON public.gastos(user_id);
CREATE INDEX IF NOT EXISTS idx_gastos_fecha ON public.gastos(fecha);
CREATE INDEX IF NOT EXISTS idx_gastos_categoria ON public.gastos(categoria_id);

-- ============================================================
-- 4. FUNCIONES
-- ============================================================

-- Función: update_updated_at_column
-- Descripción: Actualiza automáticamente el campo updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función: handle_new_user
-- Descripción: Crea automáticamente un perfil cuando se registra un nuevo usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.perfiles (id, email)
    VALUES (NEW.id, NEW.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 5. TRIGGERS
-- ============================================================

-- Trigger: Crear perfil automáticamente al registrar usuario
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Triggers: Actualizar updated_at automáticamente
DROP TRIGGER IF EXISTS update_perfiles_updated_at ON public.perfiles;
CREATE TRIGGER update_perfiles_updated_at
    BEFORE UPDATE ON public.perfiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_productos_updated_at ON public.productos;
CREATE TRIGGER update_productos_updated_at
    BEFORE UPDATE ON public.productos
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_ventas_updated_at ON public.ventas;
CREATE TRIGGER update_ventas_updated_at
    BEFORE UPDATE ON public.ventas
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_gastos_updated_at ON public.gastos;
CREATE TRIGGER update_gastos_updated_at
    BEFORE UPDATE ON public.gastos
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================
-- 6. ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ventas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.detalle_ventas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gastos ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- Políticas RLS para: perfiles
-- ============================================================

-- Los usuarios pueden ver solo su propio perfil
CREATE POLICY "Users can view own profile"
    ON public.perfiles FOR SELECT
    USING (auth.uid() = id);

-- Los usuarios pueden actualizar solo su propio perfil
CREATE POLICY "Users can update own profile"
    ON public.perfiles FOR UPDATE
    USING (auth.uid() = id);

-- ============================================================
-- Políticas RLS para: categorias
-- ============================================================

-- Solo los admins pueden ver sus propias categorías
CREATE POLICY "Admins can view own categories"
    ON public.categorias FOR SELECT
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- Solo los admins pueden crear categorías
CREATE POLICY "Admins can insert categories"
    ON public.categorias FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- Solo los admins pueden actualizar sus propias categorías
CREATE POLICY "Admins can update own categories"
    ON public.categorias FOR UPDATE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- Solo los admins pueden eliminar sus propias categorías
CREATE POLICY "Admins can delete own categories"
    ON public.categorias FOR DELETE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- ============================================================
-- Políticas RLS para: productos
-- ============================================================

-- Los admins pueden ver sus productos, los clientes pueden ver productos activos de cualquier admin
CREATE POLICY "Users can view products"
    ON public.productos FOR SELECT
    USING (
        auth.uid() = user_id OR 
        (activo = true AND stock > 0 AND 
         EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'cliente'))
    );

-- Solo los admins pueden crear productos
CREATE POLICY "Admins can insert products"
    ON public.productos FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- Solo los admins pueden actualizar sus propios productos
CREATE POLICY "Admins can update own products"
    ON public.productos FOR UPDATE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- Solo los admins pueden eliminar sus propios productos
CREATE POLICY "Admins can delete own products"
    ON public.productos FOR DELETE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- ============================================================
-- Políticas RLS para: ventas
-- ============================================================

-- Los admins ven sus ventas, los clientes ven sus compras
CREATE POLICY "Users can view sales"
    ON public.ventas FOR SELECT
    USING (
        auth.uid() = user_id OR 
        (auth.uid() = cliente_id AND 
         EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'cliente'))
    );

-- Solo los admins pueden crear ventas
CREATE POLICY "Admins can insert sales"
    ON public.ventas FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- Solo los admins pueden actualizar sus propias ventas
CREATE POLICY "Admins can update own sales"
    ON public.ventas FOR UPDATE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- Solo los admins pueden eliminar sus propias ventas
CREATE POLICY "Admins can delete own sales"
    ON public.ventas FOR DELETE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- ============================================================
-- Políticas RLS para: detalle_ventas
-- ============================================================

-- Los admins ven detalles de sus ventas, los clientes ven detalles de sus compras
CREATE POLICY "Users can view sale details"
    ON public.detalle_ventas FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.ventas
            WHERE id = detalle_ventas.venta_id
            AND (user_id = auth.uid() OR cliente_id = auth.uid())
        )
    );

-- Los usuarios pueden crear detalles en sus propias ventas
CREATE POLICY "Users can insert own sale details"
    ON public.detalle_ventas FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.ventas
            WHERE id = detalle_ventas.venta_id
            AND user_id = auth.uid()
        )
    );

-- Los usuarios pueden actualizar detalles de sus propias ventas
CREATE POLICY "Users can update own sale details"
    ON public.detalle_ventas FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.ventas
            WHERE id = detalle_ventas.venta_id
            AND user_id = auth.uid()
        )
    );

-- Los usuarios pueden eliminar detalles de sus propias ventas
CREATE POLICY "Users can delete own sale details"
    ON public.detalle_ventas FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.ventas
            WHERE id = detalle_ventas.venta_id
            AND user_id = auth.uid()
        )
    );

-- ============================================================
-- Políticas RLS para: gastos
-- ============================================================

-- Solo los admins pueden ver sus propios gastos
CREATE POLICY "Admins can view own expenses"
    ON public.gastos FOR SELECT
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- Solo los admins pueden crear gastos
CREATE POLICY "Admins can insert expenses"
    ON public.gastos FOR INSERT
    WITH CHECK (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- Solo los admins pueden actualizar sus propios gastos
CREATE POLICY "Admins can update own expenses"
    ON public.gastos FOR UPDATE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- Solo los admins pueden eliminar sus propios gastos
CREATE POLICY "Admins can delete own expenses"
    ON public.gastos FOR DELETE
    USING (
        auth.uid() = user_id AND 
        EXISTS (SELECT 1 FROM public.perfiles WHERE id = auth.uid() AND rol = 'admin')
    );

-- ============================================================
-- 7. VISTAS ÚTILES
-- ============================================================

-- Vista: Balance general del usuario
CREATE OR REPLACE VIEW public.vista_balance AS
SELECT
    v.user_id,
    COALESCE(SUM(v.monto), 0) AS total_ventas,
    COALESCE(SUM(g.monto), 0) AS total_gastos,
    COALESCE(SUM(v.monto), 0) - COALESCE(SUM(g.monto), 0) AS balance
FROM public.perfiles p
LEFT JOIN public.ventas v ON p.id = v.user_id
LEFT JOIN public.gastos g ON p.id = g.user_id
GROUP BY v.user_id;

-- Vista: Productos con stock bajo
CREATE OR REPLACE VIEW public.vista_productos_bajo_stock AS
SELECT
    id,
    user_id,
    nombre,
    stock,
    stock_minimo,
    precio
FROM public.productos
WHERE stock <= stock_minimo AND activo = true
ORDER BY stock ASC;

-- ============================================================
-- 8. DATOS DE EJEMPLO (OPCIONAL - CATEGORÍAS PREDEFINIDAS)
-- ============================================================

-- Nota: Este INSERT solo funciona si ya tienes un usuario creado
-- Puedes comentar esta sección si prefieres crear las categorías manualmente

/*
-- Ejemplo de categorías predefinidas para gastos
INSERT INTO public.categorias (user_id, nombre, tipo, color) VALUES
    ((SELECT id FROM public.perfiles LIMIT 1), 'Alquiler', 'gasto', '#ef4444'),
    ((SELECT id FROM public.perfiles LIMIT 1), 'Servicios', 'gasto', '#f59e0b'),
    ((SELECT id FROM public.perfiles LIMIT 1), 'Inventario', 'gasto', '#3b82f6'),
    ((SELECT id FROM public.perfiles LIMIT 1), 'Marketing', 'gasto', '#8b5cf6'),
    ((SELECT id FROM public.perfiles LIMIT 1), 'Otros', 'gasto', '#6b7280')
ON CONFLICT (user_id, nombre, tipo) DO NOTHING;

-- Ejemplo de categorías predefinidas para productos
INSERT INTO public.categorias (user_id, nombre, tipo, color) VALUES
    ((SELECT id FROM public.perfiles LIMIT 1), 'Electrónica', 'producto', '#10b981'),
    ((SELECT id FROM public.perfiles LIMIT 1), 'Ropa', 'producto', '#ec4899'),
    ((SELECT id FROM public.perfiles LIMIT 1), 'Alimentos', 'producto', '#f97316'),
    ((SELECT id FROM public.perfiles LIMIT 1), 'Otros', 'producto', '#6b7280')
ON CONFLICT (user_id, nombre, tipo) DO NOTHING;
*/

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================

-- Para verificar que todo se creó correctamente, ejecuta:
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
