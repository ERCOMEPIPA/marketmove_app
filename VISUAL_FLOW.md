# 📊 FLUJO VISUAL DE LA APP - MarketMove CRM

## 🔐 FLUJO DE AUTENTICACIÓN

```
┌─────────────────────────────────────────────────────────┐
│                    PANTALLA LOGIN                       │
│  Email: _______________________________________________│
│  Contraseña: __________________________________________│
│  [INICIAR SESIÓN]                                       │
└─────────────────────────────────────────────────────────┘
                          │
                          ↓ (SignIn)
┌─────────────────────────────────────────────────────────┐
│        OBTENER ROL DEL USUARIO EN BD (perfiles)        │
└─────────────────────────────────────────────────────────┘
                          │
            ┌─────────────┼─────────────┐
            ↓             ↓             ↓
       SUPERADMIN      DUEÑO       EMPLEADO
            │             │             │
            ↓             ↓             ↓
    /superadmin/    /admin/       /empleado/
     dashboard      dashboard      catalogo
```

---

## 👑 FLUJO SUPERADMIN

```
┌────────────────────────────────────────────────┐
│      SUPERADMIN DASHBOARD                      │
│  ┌──────────────────────────────────────────┐ │
│  │ Lista de todos los DUEÑOS                │ │
│  │                                          │ │
│  │ ┌─ Dueño 1 - "Mi Tienda"               │ │
│  │ │  Ventas: €10,000 | Productos: 50    │ │
│  │ │  [Ver Detalles]                     │ │
│  │ │                                     │ │
│  │ ┌─ Dueño 2 - "Otra Tienda"             │ │
│  │ │  Ventas: €5,500 | Productos: 30     │ │
│  │ │  [Ver Detalles]                     │ │
│  │ └────────────────────────────────────────│ │
│  │                                          │ │
│  │ MÉTRICAS GLOBALES:                       │ │
│  │ • Total Negocios: 2                      │ │
│  │ • Ventas Globales: €15,500               │ │
│  │ • Productos Totales: 80                  │ │
│  │                                          │ │
│  │ [LOGOUT]                                 │ │
│  └──────────────────────────────────────────┘ │
└────────────────────────────────────────────────┘
```

---

## 🏪 FLUJO DUEÑO (ADMIN)

```
┌────────────────────────────────────────────────┐
│      DUEÑO - DASHBOARD DE SU NEGOCIO           │
│                                                │
│  Mi Tienda: "Mi Tienda XYZ"                   │
│  ┌───────────────────────────────────────────┐│
│  │ RESUMEN:                                  ││
│  │ • Ventas Hoy: €1,250                      ││
│  │ • Productos: 45                           ││
│  │ • Gastos Este Mes: €2,500                 ││
│  └───────────────────────────────────────────┘│
│                                                │
│  ┌─────────┬──────────┬────────┬──────────┐  │
│  │PRODUCTOS│  VENTAS  │ GASTOS │REPORTES  │  │
│  └─────────┴──────────┴────────┴──────────┘  │
│       ↓         ↓         ↓         ↓        │
│   (Gestion) (Registrar)(Control)(Análisis)  │
│                                                │
│                    [LOGOUT]                    │
└────────────────────────────────────────────────┘
```

### Submenús del DUEÑO:

```
PRODUCTOS (/admin/productos)
├─ Agregar Producto
├─ Editar Producto
├─ Ver Stock
└─ Eliminar Producto

VENTAS (/admin/ventas)
├─ Registrar Venta
├─ Ver Historial
├─ Filtrar por Fecha
└─ Exportar

GASTOS (/admin/gastos)
├─ Registrar Gasto
├─ Ver Historial
├─ Por Categoría
└─ Análisis de Gastos

REPORTES (/admin/reportes)
├─ Reporte de Ventas
├─ Reporte de Gastos
├─ Inventario
└─ Gráficas
```

---

## 👷 FLUJO EMPLEADO (CLIENTE)

```
┌────────────────────────────────────────────────┐
│     EMPLEADO - COMPRADOR DEL CATÁLOGO         │
│                                                │
│  ┌─────────────────────────────────────────┐ │
│  │ CATÁLOGO DE PRODUCTOS                   │ │
│  │                                         │ │
│  │  ┌──────────┐  ┌──────────┐            │ │
│  │  │ Producto │  │ Producto │  ...      │ │
│  │  │   Foto   │  │   Foto   │           │ │
│  │  │ Nombre   │  │ Nombre   │           │ │
│  │  │ €15.99   │  │ €25.50   │           │ │
│  │  │ [Comprar]│  │ [Comprar]│           │ │
│  │  └──────────┘  └──────────┘           │ │
│  │                                         │ │
│  └─────────────────────────────────────────┘ │
│                                                │
│  ┌──────────┬──────────┬──────────┐           │
│  │ Catálogo │  Compras │ Perfil   │           │
│  └──────────┴──────────┴──────────┘           │
│      (activo)                                  │
│                                                │
│ ← Swipe o toca para cambiar sección           │
│                                                │
└────────────────────────────────────────────────┘
```

### Submenús del EMPLEADO:

```
CATÁLOGO (/empleado/catalogo) 📦
├─ Ver todos los productos
├─ Buscar/Filtrar
├─ Ver detalles del producto
└─ Agregar al carrito

MIS COMPRAS (/empleado/compras) 🛒
├─ Carrito de compras
├─ Historial de compras
├─ Estado de pedidos
└─ Descargar recibos

PERFIL (/empleado/perfil) 👤
├─ Datos personales
├─ Historial de compras
├─ Direcciones guardadas
└─ Editar información
```

---

## 🔄 NAVEGACIÓN COMPLETA

```
LOGIN
  │
  ├─→ SUPERADMIN
  │     │
  │     └─→ /superadmin/dashboard
  │           ├─ Ver Dueños
  │           ├─ Métricas
  │           └─ [LOGOUT]
  │
  ├─→ DUEÑO
  │     │
  │     ├─→ /admin/dashboard
  │     ├─→ /admin/productos
  │     ├─→ /admin/ventas
  │     ├─→ /admin/gastos
  │     ├─→ /admin/reportes
  │     └─→ [LOGOUT]
  │
  └─→ EMPLEADO
        │
        ├─→ /empleado/catalogo (BottomNav)
        ├─→ /empleado/compras (BottomNav)
        ├─→ /empleado/perfil (BottomNav)
        └─→ [LOGOUT]
```

---

## 🔒 RESTRICCIONES DE ACCESO

```
RUTA                        SUPERADMIN  DUEÑO  EMPLEADO
────────────────────────────────────────────────────────
/login                         ✅       ✅      ✅
/superadmin/dashboard          ✅       ❌      ❌
/admin/dashboard               ❌       ✅      ❌
/admin/productos               ❌       ✅      ❌
/admin/ventas                  ❌       ✅      ❌
/admin/gastos                  ❌       ✅      ❌
/admin/reportes                ❌       ✅      ❌
/empleado/catalogo             ❌       ❌      ✅
/empleado/compras              ❌       ❌      ✅
/empleado/perfil               ❌       ❌      ✅

✅ = Acceso permitido
❌ = Acceso denegado (redirige a login)
```

---

## 📱 ESTRUCTURA DE SCREENS

```
Screens
├── LoginScreen (Pública)
│
├── Superadmin/
│   └── SuperadminDashboard
│       └── SuperadminShell (AppBar + contenido)
│
├── Admin/
│   ├── DashboardScreen
│   ├── ProductosScreen
│   ├── VentasScreen
│   ├── GastosScreen
│   ├── ReportesScreen
│   └── AdminShell (AppBar + contenido)
│
└── Cliente (↔ Empleado)/
    ├── CatalogoScreen
    ├── MisComprasScreen
    ├── PerfilClienteScreen
    └── ClienteShell (AppBar + BottomNav)
```

---

## 💾 FLUJO DE DATOS

```
AUTH (Supabase)
    ↓
LOGIN_SCREEN
    ↓
AUTH_SERVICE.signIn()
    ↓
OBTIENE PERFIL DE BD (perfiles)
    ↓
LEE CAMPO 'rol'
    ↓
REDIRECT SEGÚN ROL
    ↓
SHELL ESPECÍFICO
    ↓
PANTALLA PRINCIPAL DEL ROL
    ↓
ACCESO A SERVICIOS SEGÚN PERMISOS
    ↓
MUESTRA DATOS AL USUARIO
```

---

## ⚡ FLUJO RÁPIDO DE TESTING

### Test 1: Superadmin
```
1. Login: superadmin@test.com
2. ¿Va a /superadmin/dashboard? ✅
3. ¿Ve lista de dueños? ✅
4. ¿Ve métricas? ✅
5. Logout funciona? ✅
```

### Test 2: Dueño
```
1. Login: dueno@test.com
2. ¿Va a /admin/dashboard? ✅
3. ¿Ve botones: Productos, Ventas, Gastos, Reportes? ✅
4. ¿No ve /superadmin/dashboard? ✅
5. Logout funciona? ✅
```

### Test 3: Empleado
```
1. Login: empleado@test.com
2. ¿Va a /empleado/catalogo? ✅
3. ¿Ve BottomNav (3 opciones)? ✅
4. ¿No ve /admin/*? ✅
5. Logout funciona? ✅
```

---

## 🎯 DIAGRAMA GENERAL

```
┌─────────────────────────────────────────────────────┐
│                  MARKETMOVE CRM                      │
├─────────────────────────────────────────────────────┤
│                                                      │
│   SUPERADMIN          DUEÑO           EMPLEADO      │
│   ─────────────      ─────────        ──────────   │
│   • 1 por plataforma • N por admin    • N por dueño│
│   • Ve todo          • Ve su negocio  • Ve catálogo│
│   • Métricas global  • Gestiona       • Compra     │
│   • Monitor          • Reportes       • Perfil     │
│                                                      │
│   ┌──────────┐      ┌──────────┐      ┌─────────┐ │
│   │Dashboard │      │Dashboard │      │Catálogo │ │
│   │Superadmin│      │ Negocio  │      │ Tienda  │ │
│   └──────────┘      └──────────┘      └─────────┘ │
│                          │                   │      │
│                    ┌─────┼─────┐             │      │
│                    ↓     ↓     ↓             ↓      │
│               Productos                   Compras  │
│               Ventas                      Perfil   │
│               Gastos                               │
│               Reportes                             │
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

**Versión**: 1.0.0  
**Fecha**: 8 de diciembre de 2025  
**Estado**: Implementado ✅
