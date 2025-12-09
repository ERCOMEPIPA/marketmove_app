# 📋 Tareas Pendientes CRM - Continuar Mañana

*Última actualización: 10 Diciembre 2024*

---

## 🔴 Prioridad Alta

### 1. Validación de Empleados
- [ ] Agregar validación de límites al crear empleados (similar a clientes)
- [ ] Mostrar barra de uso de empleados en la pantalla correspondiente

### 2. Integrar Rutas de Empleado
- [ ] Agregar rutas `/empleado/dashboard` y `/empleado/clientes` en `main.dart`
- [ ] Actualizar `cliente_shell.dart` para empleados CRM

### 3. Asignar Plan por Defecto
- [ ] Cuando se registra un nuevo dueño, asignarle automáticamente el plan "Básico"

---

## 🟡 Prioridad Media

### 4. Pantalla de Deals para Empleado
- [ ] Crear `MisDealsScreen` - similar a `MisClientesScreen`
- [ ] Solo mostrar deals asignados al empleado

### 5. Crear Deal desde Cliente
- [ ] En `ClientesScreen`, el botón "Crear Deal" debe abrir el formulario con el cliente pre-seleccionado

### 6. Dashboard del Dueño Mejorado
- [ ] Agregar widget `PlanUsageWidget` al dashboard principal
- [ ] Mostrar resumen de clientes y deals

### 7. Historial de Actividades
- [ ] Mostrar actividades recientes en detalle de cliente
- [ ] Permitir registrar notas/llamadas desde detalle

---

## 🟢 Mejoras Opcionales

### 8. Notificaciones de Límites
- [ ] Enviar notificación cuando se alcanza el 80% del límite
- [ ] Recordatorio al dueño de actualizar plan

### 9. Exportar Datos
- [ ] Exportar lista de clientes a CSV
- [ ] Exportar pipeline a PDF

### 10. Filtros Avanzados en Pipeline
- [ ] Filtrar por empleado asignado
- [ ] Filtrar por rango de fechas
- [ ] Buscar por nombre de cliente

### 11. Métricas de Empleados
- [ ] Ranking de empleados por deals cerrados
- [ ] Gráfico de actividad por empleado

---

## 📁 Archivos Clave Creados Hoy

| Archivo | Descripción |
|---------|-------------|
| `services/clientes_service.dart` | CRUD clientes/leads |
| `services/deals_service.dart` | Pipeline y oportunidades |
| `services/actividades_service.dart` | Llamadas, emails, reuniones |
| `services/planes_service.dart` | Gestión de planes |
| `services/limites_service.dart` | Validación de límites |
| `admin/clientes/clientes_screen.dart` | Gestión clientes (dueño) |
| `admin/pipeline/pipeline_screen.dart` | Pipeline Kanban |
| `empleado/dashboard/empleado_dashboard_crm.dart` | Dashboard empleado |
| `empleado/clientes/mis_clientes_screen.dart` | Clientes asignados |
| `superadmin/superadmin_dashboard_v2.dart` | Dashboard global |
| `superadmin/planes_screen.dart` | Gestión planes |
| `widgets/plan_usage_widget.dart` | Widget de uso de plan |

---

## 🚀 Para Empezar Mañana

1. Abre el proyecto en VS Code
2. Ejecuta `flutter run -d chrome`
3. Comienza con la **Prioridad Alta #2** (integrar rutas empleado)
