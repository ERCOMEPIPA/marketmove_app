# Estructura CRM de MarketMove

## Jerarquía de Roles

### 1. **SUPERADMIN** 👑
- **Objetivo**: Gestionar toda la plataforma y monitorear a todos los dueños de negocios
- **Acceso**:
  - `/superadmin/dashboard` - Visualizar todos los negocios registrados
  - Métricas globales de la plataforma
  - Lista de todos los ADMIN (dueños)
  - Resumen de ventas, productos y negocios totales
- **Responsabilidades**:
  - Aprobar nuevos dueños de negocio
  - Ver estadísticas globales de la plataforma
  - Gestionar la plataforma completa

### 2. **ADMIN / DUEÑO** 🏪
- **Objetivo**: Gestionar su propio negocio (CRM real para pequeños comercios)
- **Acceso**:
  - `/admin/dashboard` - Resumen del negocio
  - `/admin/productos` - Gestión de inventario
  - `/admin/ventas` - Registro de ventas
  - `/admin/gastos` - Gestión de gastos
  - `/admin/reportes` - Análisis y reportes
- **Responsabilidades**:
  - Gestionar inventario de productos
  - Registrar y controlar ventas
  - Administrar gastos operacionales
  - Crear reportes y análisis
  - Gestionar su equipo de empleados (futura expansión)

### 3. **EMPLEADO / CLIENTE** 👷
- **Objetivo**: Acceder al catálogo de productos y realizar compras
- **Acceso**:
  - `/empleado/catalogo` - Ver catálogo de productos disponibles
  - `/empleado/compras` - Historial y gestión de compras
  - `/empleado/perfil` - Perfil personal y datos
- **Responsabilidades**:
  - Ver productos disponibles
  - Realizar compras
  - Gestionar su perfil
  - Ver historial de compras

## Flujo de Autenticación

### Login
1. Usuario ingresa credenciales
2. Sistema valida en Supabase
3. Se obtiene el rol del usuario
4. Se redirige según el rol:
   - `SUPERADMIN` → `/superadmin/dashboard`
   - `DUEÑO` → `/admin/dashboard`
   - `EMPLEADO` → `/empleado/catalogo`

### Registro (Futura Expansión)
- Nuevos usuarios se registran como **DUEÑO** por defecto
- Solo SUPERADMIN puede crear nuevos SUPERADMIN
- DUEÑO puede crear y gestionar EMPLEADOS

## Estructura de Base de Datos

### Tabla: `perfiles`
```sql
- id (uuid, PK)
- email (varchar)
- nombre_negocio (varchar)
- telefono (varchar)
- rol (varchar) - 'superadmin' | 'dueno' | 'empleado'
- negocio_id (uuid, FK - para empleados que pertenecen a un dueño)
- created_at (timestamp)
- updated_at (timestamp)
```

## Rutas Protegidas (A Implementar)

```dart
// Rutas solo para SUPERADMIN
/superadmin/dashboard

// Rutas solo para ADMIN (DUEÑO)
/admin/dashboard
/admin/productos
/admin/ventas
/admin/gastos
/admin/reportes

// Rutas solo para EMPLEADO
/empleado/catalogo
/empleado/compras
/empleado/perfil

// Rutas públicas
/login
```

## Validación de Permisos

Se usa `RouteGuard` para validar acceso a rutas protegidas.

Ejemplo de uso:
```dart
final guard = RouteGuard();
if (await guard.isSuperadmin()) {
  // Acceso permitido
}
```

## Nomenclatura

- **SUPERADMIN**: Administrador supremo de la plataforma
- **DUEÑO / ADMIN**: Propietario del negocio (usamos "dueno" en código)
- **EMPLEADO / CLIENTE**: Trabajador o cliente del negocio

**Nota**: El término "cliente" se refiere a un empleado o usuario que compra en el catálogo. No confundir con clientes externos.

## Próximas Mejoras

1. [ ] Implementar validación de rutas en GoRouter
2. [ ] Crear pantalla de registro selectiva por rol
3. [ ] Agregar gestión de equipos (DUEÑO crea EMPLEADOS)
4. [ ] Implementar auditoría de cambios
5. [ ] Agregar roles personalizados
