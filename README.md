# 📱 MarketMove App

> Aplicación móvil para la gestión de ventas, gastos y stock en pequeños comercios

## 📋 Descripción del Proyecto

**MarketMove** es una aplicación móvil desarrollada para **MarketMove S.L.**, diseñada para ayudar a los dueños de pequeños comercios a llevar un control simple y eficiente de sus operaciones diarias desde su dispositivo móvil.

La aplicación permite:
- ✅ Registro e inicio de sesión de usuarios
- 💰 Registro de ventas diarias
- 💸 Control de gastos
- 📦 Gestión de productos y stock
- 📊 Visualización de balance (ganancias - gastos)

## 👥 Integrantes del Equipo

- **Francisco Virlan** - Desarrollador Full Stack

## 🚀 Tecnología Utilizada

Este proyecto está desarrollado con **Flutter**, un framework de desarrollo multiplataforma que permite:
- Desarrollo simultáneo para iOS y Android con un único código base
- Interfaz de usuario moderna y fluida
- Alto rendimiento nativo
- Desarrollo rápido con Hot Reload

**Backend:** Supabase (Base de datos y autenticación)

## 📅 Fases del Proyecto

### 1. Análisis y Toma de Requisitos
- Reunión con el cliente
- Documentación de requisitos funcionales
- Definición de alcance del MVP

### 2. Diseño UX/UI
- Creación de wireframes
- Diseño de interfaces de usuario
- Flujo de navegación

### 3. Arquitectura del Proyecto
- Estructura de carpetas
- Definición de modelos de datos
- Configuración de proveedores de estado
- Integración con Supabase

### 4. Desarrollo Frontend
- Implementación de pantallas
- Navegación entre vistas
- Validaciones de formularios
- Gestión de estado

### 5. Integración con Base de Datos
- Configuración de Supabase
- Implementación de autenticación
- CRUD de ventas, gastos y productos
- Sincronización de datos

### 6. Pruebas Funcionales
- Testing de funcionalidades
- Corrección de errores
- Optimización de rendimiento

### 7. Documentación Final
- Manual de usuario
- Documentación técnica
- Guías de despliegue

### 8. Entrega y Publicación
- Preparación para publicación (mock)
- Entrega de documentación
- Demostración al cliente

## 🛠️ Requisitos Técnicos

### Desarrollo
- **Flutter SDK:** 3.x o superior
- **Dart:** 3.x o superior
- **IDE:** Android Studio / VS Code con extensiones de Flutter
- **Cuenta de Supabase:** Para backend y base de datos

### Dispositivos soportados
- Android 5.0 (API 21) o superior
- iOS 12.0 o superior

## 📂 Estructura del Proyecto

```
marketmove_app/
├── lib/
│   └── src/
│       ├── features/
│       │   ├── auth/          # Autenticación
│       │   ├── ventas/        # Módulo de ventas
│       │   ├── gastos/        # Módulo de gastos
│       │   ├── productos/     # Gestión de productos
│       │   └── resumen/       # Dashboard y balance
│       └── shared/
│           ├── widgets/       # Componentes reutilizables
│           ├── models/        # Modelos de datos
│           ├── services/      # Servicios (API, BD)
│           └── providers/     # Gestión de estado
├── assets/
│   ├── images/
│   └── icons/
└── docs/                      # Documentación del proyecto
```

## 🚀 Cómo Ejecutar el Proyecto

### 1. Clonar el repositorio
```bash
git clone https://github.com/ERCOMEPIPA/marketmove_app.git
cd marketmove_app
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Configurar Supabase
- Crear un proyecto en [Supabase](https://supabase.com)
- Copiar las credenciales (URL y API Key)
- Configurar en el archivo de configuración del proyecto

### 4. Ejecutar la aplicación
```bash
flutter run
```

## 📄 Documentación

Toda la documentación del proyecto se encuentra en la carpeta `/docs`:
- **Presupuesto:** Documento completo de análisis y costes
- **Manual de usuario:** Guía de uso de la aplicación
- **Documentación técnica:** Arquitectura y decisiones de diseño

## 📝 Estado del Proyecto

🔄 **En desarrollo** - Fase inicial de configuración

### Próximos pasos:
- [ ] Crear proyecto Flutter
- [ ] Configurar estructura de carpetas
- [ ] Desarrollar MVP básico
- [ ] Integrar con Supabase

## 📞 Contacto

Para consultas sobre el proyecto:
- **Cliente:** MarketMove S.L.
- **Repositorio:** [GitHub](https://github.com/ERCOMEPIPA/marketmove_app)

---

*Proyecto desarrollado como parte del curso de Desarrollo de Aplicaciones Móviles* 🎓
