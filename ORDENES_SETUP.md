# 🔧 Solución: Error "owner_id" en Órdenes

## 📋 Problema
Al intentar realizar un pedido, sale el error:
```
ERROR: 42703: column "owner_id" does not exist
```

**Esto significa:** La tabla `ordenes` existe pero NO tiene la columna `owner_id`

## ✅ Solución (3 pasos simples)

### OPCIÓN A: Si la tabla `ordenes` YA EXISTE

**Paso 1:** Abre Supabase
1. Ve a https://supabase.com
2. Inicia sesión con tu cuenta
3. Selecciona tu proyecto

**Paso 2:** Abre SQL Editor
1. En el menú lateral, busca **SQL Editor**
2. Haz clic en **New Query**

**Paso 3:** Ejecuta este script
```sql
-- Agregar la columna owner_id
ALTER TABLE public.ordenes 
ADD COLUMN IF NOT EXISTS owner_id UUID;

-- Asignar owner_id a órdenes existentes (mismo que user_id)
UPDATE public.ordenes 
SET owner_id = user_id 
WHERE owner_id IS NULL;

-- Hacer la columna NOT NULL
ALTER TABLE public.ordenes
ALTER COLUMN owner_id SET NOT NULL;

-- Agregar Foreign Key
ALTER TABLE public.ordenes
ADD CONSTRAINT ordenes_owner_id_fkey 
FOREIGN KEY (owner_id) 
REFERENCES public.perfiles(id) ON DELETE CASCADE;

-- Crear índice
CREATE INDEX IF NOT EXISTS idx_ordenes_owner_id ON public.ordenes(owner_id);
```

---

### OPCIÓN B: Si la tabla `ordenes` NO EXISTE aún

1. Abre el archivo: `MIGRACION_ORDENES.sql`
2. Copia TODO el contenido
3. Pégalo en SQL Editor de Supabase
4. Ejecuta con el botón **Run**

---

### Paso 4: Prueba la App
1. Regresa a la app Flutter
2. Hot reload (tecla `r` en terminal)
3. Vuelve a intentar hacer un pedido
4. ¡Debería funcionar ahora! 🎉

---

## 📊 Estructura final de la tabla

La tabla `ordenes` tendrá estas columnas:
```
id              UUID (Primary Key)
user_id         UUID (Empleado que hace la orden)
owner_id        UUID (Dueño del negocio)  ← NUEVA
estado          TEXT (Procesando/Aceptada/Entregada)
total           DECIMAL (Total del pedido)
created_at      TIMESTAMP (Fecha de creación)
updated_at      TIMESTAMP (Fecha de actualización)
```

---

## 🆘 Si algo falla

**Error: "violates foreign key constraint"**
- Significa que hay un `user_id` en `ordenes` que no existe en `perfiles`
- Solución: Verifica que todos tus usuarios existan en la tabla `perfiles`

**Error: "column owner_id already exists"**
- La columna ya existe, no necesitas hacer nada más
- Solo verifica que está correctamente vinculada

---

**¿Listo? Ejecuta el script y prueba! 🚀**
