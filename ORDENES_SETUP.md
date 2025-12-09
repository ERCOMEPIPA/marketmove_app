# 🔧 Solución: Error "owner_id" en Órdenes

## 📋 Problema
Al intentar realizar un pedido, sale el error:
```
PostgresException: Could not find the 'owner_id' column of 'ordenes' in the schema cache
```

## ✅ Solución

Las tablas `ordenes` y `detalle_ordenes` necesitan ser creadas en tu Supabase.

### Paso 1: Abre Supabase
1. Ve a https://supabase.com
2. Inicia sesión con tu cuenta
3. Selecciona tu proyecto: **lutfgknhzcfhudjepykc**

### Paso 2: Abre SQL Editor
1. En el menú lateral, busca **SQL Editor**
2. Haz clic en **New Query**

### Paso 3: Copia y Ejecuta el Script
1. Abre el archivo: `MIGRACION_ORDENES.sql` (en la raíz del proyecto)
2. Copia TODO el contenido
3. Pégalo en el SQL Editor de Supabase
4. Haz clic en **"Run"** (botón verde)

### Paso 4: Verifica
Deberías ver mensajes como:
- ✅ CREATE TABLE
- ✅ CREATE INDEX
- ✅ CREATE POLICY

Si no hay errores rojos, ¡está listo!

### Paso 5: Prueba la App
1. Regresa a la app Flutter
2. Vuelve a intentar hacer una orden
3. ¡Debería funcionar ahora! 🎉

---

## ❓ ¿Qué hace el script?

✅ Crea tabla `ordenes` con:
- `user_id` (empleado que hace la orden)
- `owner_id` (dueño del negocio)
- `estado` (Procesando, Aceptada, Entregada)
- `total` y `created_at`

✅ Crea tabla `detalle_ordenes` con:
- Productos de cada orden
- Cantidad, precio, subtotal
- Relación con la orden

✅ Crea índices para optimizar búsquedas

✅ Configura políticas de seguridad RLS

---

## 🆘 Si algo falla

Si ves errores con mensajes sobre "constraint" o "reference", es porque:
- La tabla `perfiles` podría no existir
- Los UUIDs de test en `perfiles` podrían no ser válidos

En ese caso, verifica que en tu Supabase tienes:
1. Tabla `perfiles` creada
2. Al menos un registro con rol `dueno` (dueño)
3. Un registro con rol `empleado` que tenga un `owner_id` válido

---

**¿Listo? ¡Ejecuta el script y prueba! 🚀**
