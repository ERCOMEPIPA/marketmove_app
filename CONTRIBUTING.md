# 🤝 Guía de Contribución - MarketMove App

## 📌 Flujo de Trabajo con Git

### 1. Ramas (Branches)

El proyecto utiliza las siguientes ramas:

- **`main`**: Rama principal de producción (código estable)
- **`develop`**: Rama de desarrollo (integración de features)
- **`feature/*`**: Ramas para nuevas funcionalidades
- **`bugfix/*`**: Ramas para corrección de errores
- **`franVirlan`**: Rama personal de desarrollo

### 2. Convenciones de Commits

Utiliza commits descriptivos siguiendo este formato:

```
<tipo>: <descripción breve>

[Descripción detallada opcional]
```

**Tipos de commits:**
- `feat`: Nueva funcionalidad
- `fix`: Corrección de errores
- `docs`: Cambios en documentación
- `style`: Cambios de formato (sin afectar código)
- `refactor`: Refactorización de código
- `test`: Añadir o modificar tests
- `chore`: Tareas de mantenimiento

**Ejemplos:**
```bash
git commit -m "feat: añadir pantalla de login"
git commit -m "fix: corregir cálculo de balance"
git commit -m "docs: actualizar README con instrucciones de instalación"
```

### 3. Workflow Recomendado

```bash
# 1. Actualizar tu rama local
git pull origin main

# 2. Crear una nueva rama para tu feature
git checkout -b feature/nombre-funcionalidad

# 3. Hacer cambios y commits
git add .
git commit -m "feat: descripción de los cambios"

# 4. Subir tu rama al repositorio
git push origin feature/nombre-funcionalidad

# 5. Crear Pull Request en GitHub para revisión
```

## 📝 Estándares de Código Flutter

### Estructura de Archivos
- Usar **snake_case** para nombres de archivos: `login_screen.dart`
- Usar **PascalCase** para nombres de clases: `LoginScreen`
- Usar **camelCase** para variables y funciones: `getUserData()`

### Organización de Imports
```dart
// 1. Imports de Dart
import 'dart:async';

// 2. Imports de Flutter
import 'package:flutter/material.dart';

// 3. Imports de paquetes externos
import 'package:provider/provider.dart';

// 4. Imports internos del proyecto
import '../models/user.dart';
```

### Comentarios
- Usa comentarios para explicar **por qué**, no **qué** hace el código
- Documenta funciones públicas con `///`

```dart
/// Calcula el balance total restando los gastos de las ventas.
/// 
/// Retorna [double] con el balance calculado.
double calculateBalance() {
  // implementación...
}
```

## 🧪 Testing

Antes de hacer push, asegúrate de:
- [ ] El código compila sin errores: `flutter analyze`
- [ ] Los tests pasan: `flutter test`
- [ ] La aplicación corre correctamente: `flutter run`

## 📚 Recursos

- [Documentación de Flutter](https://docs.flutter.dev/)
- [Guía de Estilo de Dart](https://dart.dev/guides/language/effective-dart/style)
- [Supabase Docs](https://supabase.com/docs)

---

*Gracias por contribuir al proyecto MarketMove!* ✨
