# 🔐 Cuentas de Prueba - MarketMove

## Credenciales de Acceso

| Rol | Email | Contraseña |
|-----|-------|------------|
| **Superadmin** | `superadmin@test.com` | `SuperAdmin123!` |
| **Dueño** | `dueno@test.com` | `Dueno123!` |
| **Empleado** | `empleado@test.com` | `Empleado123!` |

---

## 📌 Descripción de Roles

### 🟣 Superadmin
- Administrador global de toda la plataforma
- Puede gestionar todos los negocios y usuarios
- Acceso completo a todas las funcionalidades

### 🔵 Dueño
- Propietario/administrador de un negocio
- Gestiona productos, categorías y empleados de su negocio
- Dashboard con métricas y estadísticas

### 🟢 Empleado
- Trabaja para un dueño específico
- Acceso al catálogo de productos
- Puede realizar ventas

---

## ⚠️ Nota Importante

Estas cuentas deben existir previamente en **Supabase**:

1. **Authentication > Users**: El usuario debe estar creado
2. **Tabla `perfiles`**: Debe existir un registro con el rol correcto

Si una cuenta no funciona, créala manualmente en el Dashboard de Supabase.

---

*Última actualización: Diciembre 2024*
