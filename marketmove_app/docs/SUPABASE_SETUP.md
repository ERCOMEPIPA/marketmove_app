# 🚀 Guía Rápida: Configurar Supabase

Esta guía te llevará paso a paso para configurar la base de datos de MarketMove en Supabase.

## ⏱️ Tiempo estimado: 10-15 minutos

---

## 📋 Paso 1: Crear proyecto en Supabase

1. Ve a **[https://supabase.com](https://supabase.com)**
2. Inicia sesión o crea una cuenta gratuita
3. Haz clic en **"New Project"**
4. Completa la información:
   - **Name**: `marketmove` (o el nombre que prefieras)
   - **Database Password**: Crea una contraseña segura (guárdala)
   - **Region**: Selecciona la más cercana a ti
5. Haz clic en **"Create new project"**
6. ⏳ Espera 2-3 minutos mientras se inicializa el proyecto

---

## 📝 Paso 2: Ejecutar el script SQL

1. En el panel de Supabase, busca en el menú lateral: **SQL Editor**
2. Haz clic en **"New query"**
3. En tu computadora, abre el archivo:
   ```
   marketmove_app/supabase_schema.sql
   ```
4. Copia **TODO** el contenido del archivo
5. Pégalo en el editor SQL de Supabase
6. Haz clic en el botón **"Run"** (esquina inferior derecha)
7. ✅ Verifica que aparezca: **"Success. No rows returned"**

Si hay errores, revisa que hayas copiado todo el contenido correctamente.

---

## 🔑 Paso 3: Obtener credenciales

1. En Supabase, ve a **Settings** ⚙️ (esquina inferior izquierda)
2. Haz clic en **API**
3. Encontrarás dos valores importantes:

   **a) Project URL**
   ```
   Ejemplo: https://abcdefghijk.supabase.co
   ```
   
   **b) Project API keys > anon public**
   ```
   Ejemplo: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

4. 📋 Copia estos valores (los necesitarás en el siguiente paso)

---

## ⚙️ Paso 4: Configurar en Flutter

1. Ve a la carpeta:
   ```
   marketmove_app/lib/src/shared/config/
   ```

2. Copia el archivo `supabase_config_example.dart` y renómbralo a:
   ```
   supabase_config.dart
   ```

3. Abre `supabase_config.dart` en tu editor

4. Reemplaza los valores:
   ```dart
   // ANTES:
   static const String supabaseUrl = 'https://tu-proyecto.supabase.co';
   static const String supabaseAnonKey = 'tu-clave-anon-aqui';

   // DESPUÉS (usa tus valores reales):
   static const String supabaseUrl = 'https://abcdefghijk.supabase.co';
   static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   ```

5. ✅ Guarda el archivo

> **⚠️ IMPORTANTE**: `supabase_config.dart` ya está en el `.gitignore`, así que tus credenciales **NO** se subirán a Git.

---

## ✅ Paso 5: Verificar que funciona

1. Ve a Supabase > **Table Editor**
2. Deberías ver las siguientes tablas:
   - ✅ perfiles
   - ✅ categorias
   - ✅ productos
   - ✅ ventas
   - ✅ detalle_ventas
   - ✅ gastos

3. Haz clic en cualquier tabla para explorarla
4. Verifica que cada tabla muestre: 🔒 **RLS enabled**

---

## 🎯 Próximos pasos

Ahora que la base de datos está configurada, puedes:

1. **Inicializar Supabase en tu app**
   - Mira la documentación en [`docs/DATABASE.md`](file:///C:/Users/iscov/ProyectoPresupuesto/marketmove_app/docs/DATABASE.md)

2. **Implementar autenticación**
   - Registrar usuarios
   - Iniciar sesión

3. **Conectar las pantallas con la base de datos**
   - Ventas
   - Gastos
   - Productos

---

## 🆘 Solución de Problemas

### Error al ejecutar el script SQL

- **Problema**: "relation already exists"
  - **Solución**: Las tablas ya fueron creadas. Esto está bien.

- **Problema**: "permission denied"
  - **Solución**: Asegúrate de estar usando el editor SQL de Supabase con tu cuenta.

### No veo las tablas en Table Editor

- Recarga la página de Supabase
- Verifica que el script se ejecutó sin errores

### ¿Dónde encuentro la documentación completa?

- Lee [`docs/DATABASE.md`](file:///C:/Users/iscov/ProyectoPresupuesto/marketmove_app/docs/DATABASE.md) para:
  - Diagrama de la base de datos
  - Descripción detallada de cada tabla
  - Ejemplos de código

---

## 📚 Recursos Adicionales

- **Documentación de Supabase**: [https://supabase.com/docs](https://supabase.com/docs)
- **Supabase Flutter**: [https://supabase.com/docs/reference/dart/introduction](https://supabase.com/docs/reference/dart/introduction)
- **Database Schema**: [`supabase_schema.sql`](file:///C:/Users/iscov/ProyectoPresupuesto/marketmove_app/supabase_schema.sql)

---

✨ **¡Listo! Tu base de datos está configurada y lista para usar.**
