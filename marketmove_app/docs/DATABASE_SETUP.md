# Configuración Necesaria de Base de Datos

## Requerimientos SQL para MarketMove CRM

### 1. Tabla `perfiles` - Debe contener estos campos

```sql
CREATE TABLE perfiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL,
  nombre_negocio VARCHAR(255),
  telefono VARCHAR(20),
  rol VARCHAR(50) NOT NULL CHECK (rol IN ('superadmin', 'dueno', 'empleado')),
  negocio_id UUID REFERENCES perfiles(id), -- Para empleados
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices recomendados
CREATE INDEX idx_perfiles_rol ON perfiles(rol);
CREATE INDEX idx_perfiles_negocio_id ON perfiles(negocio_id);
CREATE INDEX idx_perfiles_email ON perfiles(email);
```

### 2. Validaciones Requeridas

#### Regla de Negocio 1: Rol y Negocio
- **SUPERADMIN**: `negocio_id` debe ser NULL
- **DUEÑO**: `negocio_id` debe ser NULL (es el propietario)
- **EMPLEADO**: `negocio_id` debe apuntar al DUEÑO que lo controla

#### Regla de Negocio 2: Permisos por Rol
```
SUPERADMIN
├─ Ver todos los DUEÑOS (admin)
├─ Ver métricas globales
└─ Acceso completo a todo

DUEÑO
├─ Ver su propio negocio
├─ Gestionar productos
├─ Registrar ventas
├─ Gestionar gastos
├─ Crear reportes
└─ Crear/gestionar empleados

EMPLEADO
├─ Ver catálogo
├─ Realizar compras
└─ Ver su perfil
```

### 3. Tablas Recomendadas (por tipos de datos)

```sql
-- Tabla de productos
CREATE TABLE productos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES perfiles(id),
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  precio DECIMAL(10, 2) NOT NULL,
  stock INT NOT NULL DEFAULT 0,
  stock_minimo INT NOT NULL DEFAULT 10,
  imagen_url VARCHAR(500),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de ventas
CREATE TABLE ventas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES perfiles(id),
  monto DECIMAL(10, 2) NOT NULL,
  descripcion TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Tabla de gastos
CREATE TABLE gastos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES perfiles(id),
  monto DECIMAL(10, 2) NOT NULL,
  categoria VARCHAR(100),
  descripcion TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 4. Roles de Supabase (RLS - Row Level Security) - IMPORTANTE

Para seguridad, se recomienda implementar RLS en todas las tablas:

```sql
-- Habilitar RLS
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas ENABLE ROW LEVEL SECURITY;
ALTER TABLE gastos ENABLE ROW LEVEL SECURITY;

-- Política: SUPERADMIN ve todo
CREATE POLICY "superadmin_see_all" ON perfiles
  FOR SELECT USING (
    (SELECT rol FROM perfiles WHERE id = auth.uid()) = 'superadmin'
    OR id = auth.uid()
  );

-- Política: DUEÑO ve su datos y empleados
CREATE POLICY "dueno_see_own_and_empleados" ON perfiles
  FOR SELECT USING (
    (SELECT rol FROM perfiles WHERE id = auth.uid()) = 'superadmin'
    OR (SELECT rol FROM perfiles WHERE id = auth.uid()) = 'dueno' 
      AND negocio_id = auth.uid()
    OR id = auth.uid()
  );

-- Política: EMPLEADO ve solo su perfil
CREATE POLICY "empleado_see_own" ON perfiles
  FOR SELECT USING (id = auth.uid());
```

### 5. Trigger para Actualizar `updated_at`

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_perfiles_updated_at
  BEFORE UPDATE ON perfiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 6. Datos de Prueba

```sql
-- Crear SUPERADMIN (usa el ID de tu usuario en auth.users)
INSERT INTO perfiles (id, email, nombre_negocio, rol)
VALUES ('superadmin-uuid-here', 'superadmin@app.com', NULL, 'superadmin');

-- Crear DUEÑO (usuario de negocio)
INSERT INTO perfiles (id, email, nombre_negocio, rol, negocio_id)
VALUES ('dueno-uuid-here', 'dueno@app.com', 'Mi Tienda', 'dueno', NULL);

-- Crear EMPLEADO
INSERT INTO perfiles (id, email, nombre_negocio, rol, negocio_id)
VALUES ('empleado-uuid-here', 'empleado@app.com', NULL, 'empleado', 'dueno-uuid-here');
```

## Verificación Post-Implementación

1. ✅ Verifica que la tabla `perfiles` tiene la columna `rol`
2. ✅ Verifica que los valores de `rol` son válidos
3. ✅ Verifica que los `negocio_id` apuntan correctamente
4. ✅ Verifica las RLS están habilitadas (recomendado)
5. ✅ Verifica los índices para optimizar queries
