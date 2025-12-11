# 🚀 MarketMove CRM

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Stripe](https://img.shields.io/badge/Stripe-626CD9?style=for-the-badge&logo=stripe&logoColor=white)

**Sistema CRM completo para gestión de clientes, ventas y equipos de trabajo**

</div>

---

## 📋 Descripción

MarketMove es un CRM (Customer Relationship Management) desarrollado con Flutter y Supabase que permite a dueños de negocios gestionar sus clientes, pipeline de ventas, empleados, productos e inventario desde una única plataforma.

### Características principales:

- ✅ **Pipeline visual** tipo Kanban para seguimiento de oportunidades
- ✅ **Gestión de clientes** con estados y notas
- ✅ **Control de empleados** con email de bienvenida automático
- ✅ **Inventario y productos** con control de stock
- ✅ **Registro de ventas y gastos**
- ✅ **Reportes exportables** a CSV
- ✅ **Suscripciones con Stripe** (mensual/trimestral/anual)
- ✅ **Modo oscuro** y diseño responsive
- ✅ **Dashboard con KPIs** y gráficos interactivos

---

## 🛠️ Tecnologías

| Tecnología | Uso |
|------------|-----|
| **Flutter 3.x** | Framework de desarrollo multiplataforma |
| **Dart** | Lenguaje de programación |
| **Supabase** | Backend (Auth, Database, Edge Functions) |
| **PostgreSQL** | Base de datos |
| **Stripe** | Procesamiento de pagos |
| **Resend** | Envío de emails transaccionales |

---

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
└── src/
    ├── features/                # Módulos de la app
    │   ├── admin/               # Panel del dueño
    │   │   ├── clientes/        # Gestión de clientes
    │   │   ├── empleados/       # Gestión de empleados
    │   │   ├── pipeline/        # Pipeline de ventas
    │   │   └── planes/          # Suscripciones
    │   ├── auth/                # Login y registro
    │   ├── gastos/              # Control de gastos
    │   ├── productos/           # Inventario
    │   ├── resumen/             # Dashboard
    │   ├── settings/            # Configuración
    │   ├── superadmin/          # Panel superadmin
    │   └── ventas/              # Registro de ventas
    └── shared/                  # Código compartido
        ├── config/              # Configuración (tema, supabase)
        ├── constants/           # Colores, constantes
        ├── models/              # Modelos de datos
        ├── services/            # Servicios (API, auth, etc)
        └── widgets/             # Widgets reutilizables
```

---

## 🚀 Instalación

### Prerrequisitos

- Flutter SDK 3.x
- Cuenta en [Supabase](https://supabase.com)
- Cuenta en [Stripe](https://stripe.com) (opcional, para pagos)

### Pasos

1. **Clonar el repositorio**
```bash
git clone https://github.com/tu-usuario/marketmove_app.git
cd marketmove_app
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Supabase**

Crea un archivo `lib/src/shared/config/supabase_config.dart`:
```dart
class SupabaseConfig {
  static const String url = 'TU_SUPABASE_URL';
  static const String anonKey = 'TU_ANON_KEY';
}
```

4. **Ejecutar la aplicación**
```bash
flutter run -d chrome
```

---

## 👥 Roles de Usuario

| Rol | Descripción |
|-----|-------------|
| **Superadmin** | Gestiona todos los negocios y usuarios |
| **Dueño** | Administra su negocio, empleados y clientes |
| **Empleado** | Acceso limitado según permisos del dueño |

---

## 📱 Capturas de Pantalla

### Dashboard
- KPIs de ventas y gastos
- Gráficos interactivos
- Productos con stock bajo

### Pipeline
- Vista Kanban arrastrable
- Etapas personalizables
- Valor por etapa

### Clientes
- Lista con filtros
- Estados de cliente
- Historial de interacciones

---

## 📧 Funcionalidades de Email

- Email de bienvenida automático para nuevos empleados
- Integración con Resend API
- Templates HTML profesionales

---

## 💳 Sistema de Suscripciones

Integración completa con Stripe:
- Checkout seguro
- Portal de cliente
- Webhooks para sincronización
- Planes: Emprendedor, Profesional, Empresarial

---

## 📄 Licencia

Este proyecto fue desarrollado como proyecto académico.

---

## 👨‍💻 Autor

Desarrollado con ❤️ usando Flutter y Supabase

---

<div align="center">

**⭐ Si te ha sido útil, dale una estrella al repositorio ⭐**

</div>
