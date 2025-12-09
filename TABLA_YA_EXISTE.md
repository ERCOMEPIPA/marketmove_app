# ✅ TABLA YA EXISTE - PRÓXIMOS PASOS

## 🎯 Tu Situación

La tabla `perfiles` **ya está creada** en Supabase.

**Esto es BUENO** ✅ - Significa que alguien ya hizo Paso 1.

---

## 📋 QUÉ HACER AHORA

### Paso 2: Crear Usuarios de Prueba

Ve a tu Supabase Dashboard:
1. **Authentication** → **Users**
2. Haz clic en **+ New user**
3. Crea estos 3 usuarios:

```
SUPERADMIN:
  Email: superadmin@test.com
  Contraseña: Superadmin123!
  
DUEÑO:
  Email: dueno@test.com
  Contraseña: Dueno123!
  
EMPLEADO:
  Email: empleado@test.com
  Contraseña: Empleado123!
```

**Copia el UUID de cada usuario** (aparece en la lista)

---

### Paso 3: Insertar Usuarios en la Tabla

En SQL Editor, ejecuta esto (reemplaza los UUIDs):

```sql
-- Reemplaza con tus UUIDs reales
INSERT INTO perfiles (id, email, rol)
VALUES ('tu-uuid-superadmin-aqui', 'superadmin@test.com', 'superadmin');

INSERT INTO perfiles (id, email, nombre_negocio, rol)
VALUES ('tu-uuid-dueno-aqui', 'dueno@test.com', 'Mi Tienda', 'dueno');

INSERT INTO perfiles (id, email, rol, negocio_id)
VALUES ('tu-uuid-empleado-aqui', 'empleado@test.com', 'empleado', 'tu-uuid-dueno-aqui');
```

---

### Paso 4: Verificar Tablas

En **Database**, verifica que existen:
- ✅ `perfiles` (ya existe)
- ✅ `productos` (debe existir)
- ✅ `ventas` (debe existir)
- ✅ `gastos` (debe existir)

Si faltan, copia esto en SQL Editor:

```sql
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

CREATE TABLE IF NOT EXISTS ventas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES perfiles(id),
  monto DECIMAL(10, 2) NOT NULL,
  descripcion TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gastos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES perfiles(id),
  monto DECIMAL(10, 2) NOT NULL,
  categoria VARCHAR(100),
  descripcion TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_productos_user_id ON productos(user_id);
CREATE INDEX IF NOT EXISTS idx_ventas_user_id ON ventas(user_id);
CREATE INDEX IF NOT EXISTS idx_gastos_user_id ON gastos(user_id);
```

---

## 🚀 EJECUTAR LA APP

Cuando hayas terminado los 3 pasos anteriores:

```bash
flutter pub get
flutter run
```

---

## 🔑 Credenciales

```
SUPERADMIN: superadmin@test.com / Superadmin123!
DUEÑO: dueno@test.com / Dueno123!
EMPLEADO: empleado@test.com / Empleado123!
```

---

## ✅ CHECKLIST

- [ ] Creé 3 usuarios en Auth
- [ ] Copié sus UUIDs
- [ ] Inserté los usuarios en tabla perfiles
- [ ] Verifiqué que productos, ventas, gastos existen
- [ ] Ejecuté `flutter pub get`
- [ ] Ejecuté `flutter run`
- [ ] Probé login con cada usuario

---

## 🎯 SIGUIENTE PASO

**→ Crea los 3 usuarios en Authentication**

Luego continúa con los pasos de arriba.

¡Casi listo! 🚀
