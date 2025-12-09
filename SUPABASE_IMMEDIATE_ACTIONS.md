+# 🔧 ACCIONES INMEDIATAS EN SUPABASE

## Paso 1: Crear la Tabla `perfiles` (O Verificar que Existe)

### En Supabase Dashboard:
1. Abre tu proyecto: https://lutfgknhzcfhudjepykc.supabase.co
2. Ve a **SQL Editor**

### OPCIÓN A: Si la tabla NO existe, copia y pega este código:

```sql
-- Crear tabla perfiles
CREATE TABLE perfiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL,
  nombre_negocio VARCHAR(255),
  telefono VARCHAR(20),
  rol VARCHAR(50) NOT NULL CHECK (rol IN ('superadmin', 'dueno', 'empleado')),
  negocio_id UUID REFERENCES perfiles(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Crear índices para optimizar búsquedas
CREATE INDEX idx_perfiles_rol ON perfiles(rol);
CREATE INDEX idx_perfiles_negocio_id ON perfiles(negocio_id);
CREATE INDEX idx_perfiles_email ON perfiles(email);

-- Crear trigger para actualizar updated_at automáticamente
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

### OPCIÓN B: Si la tabla YA existe (como es tu caso), ejecuta SOLO esto:

```sql
-- Limpiar datos existentes (OPCIONAL - si quieres empezar de cero)
-- DELETE FROM perfiles;

-- O simplemente continúa al Paso 2 para insertar tus usuarios
```

**Haz clic en Run o presiona `Ctrl+Enter`**

---

## Paso 2: Crear Usuarios de Prueba

### En Supabase Dashboard:
1. Ve a **Authentication** → **Users**
2. Haz clic en **+ New user**
3. Crea estos usuarios:

**Usuario 1 - SUPERADMIN:**
- Email: `superadmin@test.com`
- Contraseña: `Superadmin123!` (cámbiala después)
- Copia el UUID del usuario (aparece en la lista)

**Usuario 2 - DUEÑO:**
- Email: `dueno@test.com`
- Contraseña: `Dueno123!` (cámbiala después)
- Copia el UUID del usuario

**Usuario 3 - EMPLEADO:**
- Email: `empleado@test.com`
- Contraseña: `Empleado123!` (cámbiala después)
- Copia el UUID del usuario

---

## Paso 3: Crear los Perfiles en la BD

### ⚠️ IMPORTANTE: DEBES COPIAR LOS UUIDs REALES

En Supabase **Authentication → Users**, verás tus usuarios creados. Cada uno tiene un UUID (ID) que parece así:

```
550e8400-e29b-41d4-a716-446655440000
```

**Copia exactamente los UUIDs de tus usuarios.**

### En SQL Editor de Supabase:

Reemplaza estos valores con TUS UUIDs reales:
- `TU-UUID-SUPERADMIN-AQUI`
- `TU-UUID-DUENO-AQUI`
- `TU-UUID-EMPLEADO-AQUI`

```sql
-- ⚠️ CAMBIA ESTOS POR TUS UUIDS REALES DE SUPABASE AUTH

INSERT INTO perfiles (id, email, rol)
VALUES ('TU-UUID-SUPERADMIN-AQUI', 'superadmin@test.com', 'superadmin');

INSERT INTO perfiles (id, email, nombre_negocio, rol)
VALUES ('TU-UUID-DUENO-AQUI', 'dueno@test.com', 'Mi Tienda XYZ', 'dueno');

INSERT INTO perfiles (id, email, rol, negocio_id)
VALUES ('TU-UUID-EMPLEADO-AQUI', 'empleado@test.com', 'empleado', 'TU-UUID-DUENO-AQUI');
```

### ✅ TUS UUIDs REALES (LISTA PARA COPIAR Y PEGAR):
```sql
-- Primero, limpia registros duplicados (EJECUTA ESTO PRIMERO)
DELETE FROM perfiles 
WHERE id IN ('dcb3c84a-16f8-4074-8047-b6c280421603', '51d9cb85-cc10-4b1a-8edb-afb76ecd3904', 'f8ac1e1f-1132-44a9-916a-4d359426f3ee');

-- Luego inserta los usuarios
INSERT INTO perfiles (id, email, rol)
VALUES ('dcb3c84a-16f8-4074-8047-b6c280421603', 'superadmin@test.com', 'superadmin');

INSERT INTO perfiles (id, email, nombre_negocio, rol)
VALUES ('51d9cb85-cc10-4b1a-8edb-afb76ecd3904', 'dueno@test.com', 'Mi Tienda', 'dueno');

INSERT INTO perfiles (id, email, rol, negocio_id)
VALUES ('f8ac1e1f-1132-44a9-916a-4d359426f3ee', 'empleado@test.com', 'empleado', '51d9cb85-cc10-4b1a-8edb-afb76ecd3904');
```

**Solo copia, pega y ejecuta el código anterior en SQL Editor. ¡Eso es todo!**

### 📋 Pasos:
1. Abre **Authentication → Users** en Supabase
2. Copia el UUID (columna "ID") de cada usuario
3. Reemplaza en el SQL anterior
4. Ejecuta en SQL Editor

---

## Paso 4: Verificar que las Tablas Existen

### Verifica que tienes estas tablas en Supabase:
1. Ve a **Database** en el sidebar
2. Confirma que existen:
   - ✅ `perfiles` (ya creada en Paso 1)
   - ✅ `productos` (debe existir)
   - ✅ `ventas` (debe existir)
   - ✅ `gastos` (debe existir)

Si faltan `productos`, `ventas` o `gastos`, crea estas:

```sql
-- Crear tabla productos (si no existe)
CREATE TABLE IF NOT EXISTS productos (
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

-- Crear tabla ventas (si no existe)
CREATE TABLE IF NOT EXISTS ventas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES perfiles(id),
  monto DECIMAL(10, 2) NOT NULL,
  descripcion TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Crear tabla gastos (si no existe)
CREATE TABLE IF NOT EXISTS gastos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES perfiles(id),
  monto DECIMAL(10, 2) NOT NULL,
  categoria VARCHAR(100),
  descripcion TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Crear índices
CREATE INDEX IF NOT EXISTS idx_productos_user_id ON productos(user_id);
CREATE INDEX IF NOT EXISTS idx_ventas_user_id ON ventas(user_id);
CREATE INDEX IF NOT EXISTS idx_gastos_user_id ON gastos(user_id);
```

---

## Paso 5: (OPCIONAL - RECOMENDADO) Habilitar Row Level Security

Para mayor seguridad, implementa RLS:

```sql
-- Habilitar RLS en tablas
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

---

## ✅ CHECKLIST - Antes de Ejecutar `flutter run`

- [ ] ✅ Creada tabla `perfiles` en Supabase
- [ ] ✅ Creados 3 usuarios en Auth (superadmin, dueno, empleado)
- [ ] ✅ Insertados registros en tabla `perfiles` para cada usuario
- [ ] ✅ Verificadas tablas: productos, ventas, gastos
- [ ] ✅ (Opcional) Habilitado RLS
- [ ] ✅ Anotadas las contraseñas de prueba
- [ ] ✅ Ejecutado `flutter pub get`

---

## 🚀 Ejecutar la Aplicación

```bash
# En la carpeta del proyecto
flutter run

# O en emulador específico
flutter run -d android   # Para Android
flutter run -d ios       # Para iOS
flutter run -d web       # Para Web
```

---

## 🔑 Credenciales de Prueba

**SUPERADMIN:**
```
Email: superadmin@test.com
Contraseña: Superadmin123!
```

**DUEÑO:**
```
Email: dueno@test.com
Contraseña: Dueno123!
```

**EMPLEADO:**
```
Email: empleado@test.com
Contraseña: Empleado123!
```

---

## ⚠️ Problemas Comunes

### "Table 'perfiles' does not exist"
- Verifica que ejecutaste el SQL en Paso 1
- Recarga la página de Supabase

### "ERROR: 42P07: relation 'perfiles' already exists" ✅ TU CASO
- ¡Excelente! La tabla ya existe
- **No necesitas crear la tabla**
- Continúa directamente al Paso 2 para crear usuarios
- O ejecuta `DELETE FROM perfiles;` si quieres limpiar datos existentes

### "User authentication failed"
- Verifica que el usuario está en Auth
- Verifica que está confirmado el email
- Revisa la contraseña

### "Row level security violation"
- Si habilitaste RLS, asegúrate de que está correctamente configurado
- O deshabilita RLS temporalmente para testing

### Redirección incorrecta después de login
- Verifica que el `rol` en `perfiles` es: 'superadmin', 'dueno' o 'empleado'
- Verifica que no hay espacios extras en el rol

---

**¡Ya está todo listo! 🎉**

Sigue estos pasos y la app debería funcionar correctamente.
