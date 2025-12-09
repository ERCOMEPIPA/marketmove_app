# 🔐 Guía: Configurar Empleado en MarketMove

## Estado Actual ✅
- ✅ Credenciales de Supabase configuradas
- ✅ App Flutter lista
- ⏳ **Necesitas**: Crear usuario de empleado en Supabase

---

## 📋 Pasos para Crear Empleado

### PASO 1️⃣: Actualizar Roles en la BD

Ve a tu Supabase Dashboard:
1. **Supabase > Tu Proyecto > SQL Editor**
2. Haz clic en **"New Query"**
3. Copia y ejecuta este comando:

```sql
-- Actualizar tabla perfiles para nuevos roles
ALTER TABLE public.perfiles 
DROP CONSTRAINT IF EXISTS perfiles_rol_check,
ADD CONSTRAINT perfiles_rol_check CHECK (rol IN ('superadmin', 'dueno', 'empleado'));

UPDATE public.perfiles 
SET rol = 'dueno' WHERE rol = 'admin';

UPDATE public.perfiles 
SET rol = 'empleado' WHERE rol = 'cliente';

ALTER TABLE public.perfiles 
ALTER COLUMN rol SET DEFAULT 'empleado';
```

4. Haz clic en **"Run"** ✅

---

### PASO 2️⃣: Crear Usuario de Empleado

En **Supabase > Authentication > Users**:

1. Haz clic en **"New user"** (esquina superior derecha)
2. Rellena:
   - **Email**: `empleado@test.com`
   - **Password**: `Password123!`
3. Marca las opciones que aparezcan
4. Haz clic en **"Create user"**

5. **Copia el UUID** que aparece (es importante)
   - Ejemplo: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`

---

### PASO 3️⃣: Crear Perfil del Empleado

En **Supabase > SQL Editor > New Query**:

```sql
-- Reemplaza 'PEGA_UUID_AQUI' con el UUID que copiaste en PASO 2
INSERT INTO public.perfiles (id, email, nombre_negocio, rol)
VALUES (
  'PEGA_UUID_AQUI',
  'empleado@test.com',
  'Mi Negocio',
  'empleado'
)
ON CONFLICT (id) DO UPDATE SET
  rol = 'empleado';
```

Haz clic en **"Run"** ✅

---

### PASO 4️⃣: Probar en la App

Ahora en tu app Flutter:

1. **Email**: `empleado@test.com`
2. **Contraseña**: `Password123!`
3. Haz clic en **"Iniciar Sesión"**

✅ **Debería llevarte a**: `/empleado/catalogo`

---

## 🆘 Si Tienes Problemas

### "Error al iniciar sesión"
- ✅ Verifica que el usuario existe en Auth > Users
- ✅ Verifica que el email y contraseña son correctos
- ✅ Verifica que el perfil existe en la tabla `perfiles`

### "No se ve el catálogo"
- ✅ Verifica que el rol en BD es exactamente `'empleado'`
- ✅ Intenta hacer `flutter clean` y reiniciar la app
- ✅ Abre la consola de Chrome DevTools (Ctrl+Shift+I en web)

### "No hay productos"
- Eso es normal si es la primera vez
- Ve a **Admin Dashboard** y crea productos de prueba
- El empleado podrá verlos en el catálogo

---

## 📝 Notas

- **Rol `empleado`**: Ve catálogo y puede comprar
- **Rol `dueno`**: Admin del negocio
- **Rol `superadmin`**: Admin global de toda la plataforma

---

## ✅ Checklist Final

- [ ] Actualicé los roles en BD (PASO 1)
- [ ] Creé usuario de empleado (PASO 2)
- [ ] Copié el UUID correctamente
- [ ] Creé el perfil en BD (PASO 3)
- [ ] Inicié sesión en la app (PASO 4)
- [ ] Vi el catálogo vacío o con productos

---

¿Necesitas ayuda? Comparte:
1. El error exacto que ves
2. El UUID del usuario
3. Los datos que insertaste en BD
