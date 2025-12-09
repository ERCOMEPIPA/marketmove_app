-- =====================================================
-- CRM MarketMove - Script de Base de Datos
-- Ejecutar en Supabase SQL Editor
-- =====================================================

-- 1. Tabla de Planes de Suscripción (Superadmin)
CREATE TABLE IF NOT EXISTS planes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  descripcion TEXT,
  precio DECIMAL(10,2) DEFAULT 0,
  max_empleados INTEGER DEFAULT 5,
  max_clientes INTEGER DEFAULT 100,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Agregar campos a perfiles
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS plan_id UUID REFERENCES planes(id);
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS suscripcion_estado TEXT DEFAULT 'activa';
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS suscripcion_vencimiento DATE;
ALTER TABLE perfiles ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT true;

-- 3. Tabla de Clientes/Leads
CREATE TABLE IF NOT EXISTS clientes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  negocio_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
  empleado_asignado_id UUID REFERENCES perfiles(id),
  nombre TEXT NOT NULL,
  email TEXT,
  telefono TEXT,
  empresa TEXT,
  cargo TEXT,
  estado TEXT DEFAULT 'lead', -- lead, contactado, calificado, cliente, inactivo
  fuente TEXT, -- web, referido, llamada, evento, otro
  etiquetas TEXT[],
  notas TEXT,
  valor_estimado DECIMAL(12,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Tabla de Deals/Oportunidades
CREATE TABLE IF NOT EXISTS deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  negocio_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
  cliente_id UUID REFERENCES clientes(id) ON DELETE SET NULL,
  empleado_asignado_id UUID REFERENCES perfiles(id),
  titulo TEXT NOT NULL,
  descripcion TEXT,
  valor DECIMAL(12,2) DEFAULT 0,
  etapa TEXT DEFAULT 'prospecto', -- prospecto, calificado, propuesta, negociacion, ganado, perdido
  probabilidad INTEGER DEFAULT 10, -- 0-100
  fecha_cierre_estimada DATE,
  fecha_cierre_real DATE,
  motivo_perdida TEXT,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Tabla de Actividades
CREATE TABLE IF NOT EXISTS actividades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  negocio_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
  empleado_id UUID NOT NULL REFERENCES perfiles(id),
  cliente_id UUID REFERENCES clientes(id) ON DELETE CASCADE,
  deal_id UUID REFERENCES deals(id) ON DELETE CASCADE,
  tipo TEXT NOT NULL, -- llamada, email, reunion, nota, tarea
  titulo TEXT NOT NULL,
  descripcion TEXT,
  fecha_programada TIMESTAMPTZ,
  fecha_completada TIMESTAMPTZ,
  duracion_minutos INTEGER,
  completada BOOLEAN DEFAULT false,
  resultado TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Tabla de Etapas del Pipeline (personalizable por negocio)
CREATE TABLE IF NOT EXISTS etapas_pipeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  negocio_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE CASCADE,
  nombre TEXT NOT NULL,
  orden INTEGER DEFAULT 0,
  color TEXT DEFAULT '#6366F1',
  probabilidad_defecto INTEGER DEFAULT 10,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- INDICES para mejor rendimiento
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_clientes_negocio ON clientes(negocio_id);
CREATE INDEX IF NOT EXISTS idx_clientes_empleado ON clientes(empleado_asignado_id);
CREATE INDEX IF NOT EXISTS idx_deals_negocio ON deals(negocio_id);
CREATE INDEX IF NOT EXISTS idx_deals_empleado ON deals(empleado_asignado_id);
CREATE INDEX IF NOT EXISTS idx_deals_cliente ON deals(cliente_id);
CREATE INDEX IF NOT EXISTS idx_actividades_negocio ON actividades(negocio_id);
CREATE INDEX IF NOT EXISTS idx_actividades_empleado ON actividades(empleado_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Habilitar RLS
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE actividades ENABLE ROW LEVEL SECURITY;
ALTER TABLE etapas_pipeline ENABLE ROW LEVEL SECURITY;
ALTER TABLE planes ENABLE ROW LEVEL SECURITY;

-- Políticas para CLIENTES
CREATE POLICY "Dueños ven clientes de su negocio" ON clientes
  FOR ALL USING (
    negocio_id = auth.uid() OR
    negocio_id IN (SELECT negocio_id FROM perfiles WHERE id = auth.uid())
  );

CREATE POLICY "Empleados ven clientes asignados" ON clientes
  FOR SELECT USING (
    empleado_asignado_id = auth.uid() OR
    negocio_id = auth.uid() OR
    negocio_id IN (SELECT negocio_id FROM perfiles WHERE id = auth.uid() AND rol = 'dueno')
  );

-- Políticas para DEALS
CREATE POLICY "Dueños ven deals de su negocio" ON deals
  FOR ALL USING (
    negocio_id = auth.uid() OR
    negocio_id IN (SELECT negocio_id FROM perfiles WHERE id = auth.uid())
  );

-- Políticas para ACTIVIDADES
CREATE POLICY "Usuarios ven actividades de su negocio" ON actividades
  FOR ALL USING (
    negocio_id = auth.uid() OR
    negocio_id IN (SELECT negocio_id FROM perfiles WHERE id = auth.uid()) OR
    empleado_id = auth.uid()
  );

-- Políticas para PLANES (solo superadmin)
CREATE POLICY "Superadmin gestiona planes" ON planes
  FOR ALL USING (
    EXISTS (SELECT 1 FROM perfiles WHERE id = auth.uid() AND rol = 'superadmin')
  );

CREATE POLICY "Todos pueden ver planes" ON planes
  FOR SELECT USING (true);

-- =====================================================
-- DATOS INICIALES
-- =====================================================

-- Planes por defecto
INSERT INTO planes (nombre, descripcion, precio, max_empleados, max_clientes) VALUES
  ('Básico', 'Para pequeños negocios', 0, 3, 50),
  ('Profesional', 'Para negocios en crecimiento', 29.99, 10, 500),
  ('Empresarial', 'Para grandes empresas', 99.99, 50, 5000)
ON CONFLICT DO NOTHING;

-- Etapas de pipeline por defecto (se crearán para cada nuevo negocio)
-- Esto se hará desde el código cuando se cree un dueño
