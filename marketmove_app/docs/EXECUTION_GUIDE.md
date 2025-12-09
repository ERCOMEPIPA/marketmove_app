# 🚀 Guía de Ejecución - MarketMove CRM

## Requisitos Previos

- ✅ Flutter SDK instalado (versión 3.0+)
- ✅ Dart SDK
- ✅ Android Studio / Xcode (para emulador/simulador)
- ✅ Cuenta de Supabase con proyecto configurado

## Pasos para Ejecutar el Proyecto

### 1. Instalación de Dependencias

```bash
cd marketmove_app
flutter pub get
```

### 2. Configuración de Supabase

Ya está configurado en `lib/src/shared/config/supabase_config.dart` con:
- **URL**: https://lutfgknhzcfhudjepykc.supabase.co
- **Anon Key**: sb_publishable_rX_plpUzoL_5sOOPX9ntLg_bRwPdssR

### 3. Preparar Base de Datos

Ejecuta los scripts SQL en `docs/DATABASE_SETUP.md` en Supabase:
1. Accede a Supabase Dashboard
2. Ve a SQL Editor
3. Copia y ejecuta los scripts de creación de tablas
4. Verifica que la tabla `perfiles` existe

### 4. Crear Usuarios de Prueba

Ejecuta en SQL de Supabase:

```sql
-- Asegúrate de reemplazar los UUIDs con IDs reales de auth.users
-- Primero crea usuarios en la sección Auth de Supabase

-- Luego crea sus perfiles
INSERT INTO perfiles (id, email, rol) VALUES 
  ('uuid-superadmin', 'superadmin@test.com', 'superadmin'),
  ('uuid-dueno', 'dueno@test.com', 'dueno'),
  ('uuid-empleado', 'empleado@test.com', 'empleado');
```

### 5. Ejecutar la Aplicación

#### En Emulador Android
```bash
flutter run -d android
```

#### En Simulador iOS
```bash
flutter run -d ios
```

#### En Web
```bash
flutter run -d web
```

#### Especificar el modo
```bash
flutter run --mode debug      # Modo debug
flutter run --mode release    # Modo release (optimizado)
```

### 6. Credenciales de Prueba

Usa estas credenciales para probar cada rol:

```
SUPERADMIN:
  Email: superadmin@test.com
  Contraseña: (la que configuraste)

DUEÑO:
  Email: dueno@test.com
  Contraseña: (la que configuraste)

EMPLEADO:
  Email: empleado@test.com
  Contraseña: (la que configuraste)
```

## Estructura de Navegación

### SUPERADMIN
```
Login
└─ Superadmin Dashboard
   ├─ Ver todos los dueños
   ├─ Métricas globales
   └─ (Logout)
```

### DUEÑO
```
Login
└─ Admin Dashboard
   ├─ Productos
   ├─ Ventas
   ├─ Gastos
   ├─ Reportes
   └─ (Logout)
```

### EMPLEADO
```
Login
└─ Empleado Catalogo
   ├─ Catálogo (BottomNav)
   ├─ Mis Compras (BottomNav)
   ├─ Perfil (BottomNav)
   └─ (Logout)
```

## Solución de Problemas

### Error: "Supabase URL not configured"
- Verifica que `supabase_config.dart` tiene la URL correcta

### Error: "Connection timeout"
- Verifica tu conexión a internet
- Verifica que Supabase está operativo

### Error: "Row level security" 
- Verifica que las RLS están configuradas correctamente en Supabase
- Asegúrate de que el usuario está autenticado

### Error: "Table 'perfiles' does not exist"
- Ejecuta los scripts SQL en `docs/DATABASE_SETUP.md`
- Verifica en Supabase que la tabla existe

### El login redirige incorrectamente
- Verifica el rol del usuario en la tabla `perfiles`
- Verifica que el rol es uno de: 'superadmin', 'dueno', 'empleado'

## Desarrollo

### Hot Reload
Durante el desarrollo, puedes usar hot reload:
```bash
r     # Hot reload
R     # Hot restart
```

### Análisis de Código
```bash
flutter analyze
```

### Formatear Código
```bash
flutter format .
```

## Compilación para Producción

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS IPA
```bash
flutter build ios --release
# Output: build/ios/iphoneos/Runner.app
```

### Web
```bash
flutter build web --release
# Output: build/web/
```

## Documentación Importante

- 📄 `docs/CRM_STRUCTURE.md` - Estructura y jerarquía de roles
- 📄 `docs/DATABASE_SETUP.md` - Configuración de base de datos
- 📄 `docs/SUPABASE_SETUP.md` - Configuración de Supabase
- 📄 `docs/DATABASE.md` - Documentación de base de datos

## Contacto y Soporte

Para problemas o preguntas, revisa:
1. Los documentos en la carpeta `docs/`
2. Los comentarios en el código
3. La documentación oficial de Flutter: https://flutter.dev

---

**Última actualización**: 8 de diciembre de 2025
