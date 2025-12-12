import 'package:flutter/material.dart';
import 'limites_service.dart';
import 'deals_service.dart';

/// Modelo de notificación
class AppNotification {
  final String id;
  final String titulo;
  final String mensaje;
  final NotificationType tipo;
  final DateTime fecha;
  bool leida;

  AppNotification({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.fecha,
    this.leida = false,
  });
}

/// Tipos de notificación
enum NotificationType {
  pedidoRecibido,
  pedidoEnProceso,
  pedidoEntregado,
  nuevoProducto,
  stock,
  error,
  info,
  // Nuevos tipos
  limiteAlcanzado, // Cuando se alcanza el 80% del límite
  dealProximoVencer, // Deal con fecha de cierre próxima
  suscripcionProxima, // Renovación de suscripción próxima
}

/// Servicio para manejar notificaciones
class NotificationService extends ChangeNotifier {
  final List<AppNotification> _notificaciones = [];
  int _unreadCount = 0;

  // Para evitar notificaciones duplicadas de límites
  bool _limiteClientesNotificado = false;
  bool _limiteEmpleadosNotificado = false;
  final Set<String> _dealsNotificados = {};

  List<AppNotification> get notificaciones => _notificaciones;
  int get unreadCount => _unreadCount;

  /// Agregar una notificación
  void addNotification({
    required String titulo,
    required String mensaje,
    required NotificationType tipo,
  }) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: titulo,
      mensaje: mensaje,
      tipo: tipo,
      fecha: DateTime.now(),
    );

    _notificaciones.insert(0, notification);
    _unreadCount++;

    // Mantener solo las últimas 50 notificaciones
    if (_notificaciones.length > 50) {
      _notificaciones.removeLast();
    }

    notifyListeners();
  }

  /// Verificar límites y generar notificaciones si se alcanza el 80%
  void verificarLimites(PlanLimites limites) {
    // Verificar límite de clientes
    if (limites.porcentajeClientes >= 0.8 && !_limiteClientesNotificado) {
      final porcentaje = (limites.porcentajeClientes * 100).toInt();
      addNotification(
        titulo: '⚠️ Límite de Clientes al $porcentaje%',
        mensaje:
            'Has usado ${limites.clientesActuales} de ${limites.maxClientes} clientes. '
            'Considera actualizar tu plan para agregar más.',
        tipo: NotificationType.limiteAlcanzado,
      );
      _limiteClientesNotificado = true;
    } else if (limites.porcentajeClientes < 0.8) {
      _limiteClientesNotificado = false; // Reset si baja del 80%
    }

    // Verificar límite de empleados
    if (limites.porcentajeEmpleados >= 0.8 && !_limiteEmpleadosNotificado) {
      final porcentaje = (limites.porcentajeEmpleados * 100).toInt();
      addNotification(
        titulo: '⚠️ Límite de Empleados al $porcentaje%',
        mensaje:
            'Has usado ${limites.empleadosActuales} de ${limites.maxEmpleados} empleados. '
            'Considera actualizar tu plan para agregar más.',
        tipo: NotificationType.limiteAlcanzado,
      );
      _limiteEmpleadosNotificado = true;
    } else if (limites.porcentajeEmpleados < 0.8) {
      _limiteEmpleadosNotificado = false; // Reset si baja del 80%
    }
  }

  /// Verificar deals próximos a vencer (≤7 días) y generar notificaciones
  void verificarDealsProximos(List<DealModel> deals) {
    final ahora = DateTime.now();
    final en7Dias = ahora.add(const Duration(days: 7));

    for (final deal in deals) {
      // Solo verificar deals activos con fecha de cierre
      if (deal.fechaCierreEstimada == null) continue;
      if (deal.etapa == EtapasPipeline.ganado ||
          deal.etapa == EtapasPipeline.perdido) {
        continue;
      }

      // Ya notificado este deal?
      if (_dealsNotificados.contains(deal.id)) continue;

      // Está próximo a vencer?
      if (deal.fechaCierreEstimada!.isBefore(en7Dias) &&
          deal.fechaCierreEstimada!.isAfter(ahora)) {
        final diasRestantes = deal.fechaCierreEstimada!
            .difference(ahora)
            .inDays;
        final diasTexto = diasRestantes == 0
            ? 'hoy'
            : diasRestantes == 1
            ? 'mañana'
            : 'en $diasRestantes días';

        addNotification(
          titulo: '🔔 Deal próximo a vencer',
          mensaje:
              '"${deal.titulo}" vence $diasTexto. '
              'Valor: €${deal.valor.toStringAsFixed(0)}',
          tipo: NotificationType.dealProximoVencer,
        );
        _dealsNotificados.add(deal.id);
      }
    }

    // Limpiar deals antiguos del set (evitar memory leak)
    if (_dealsNotificados.length > 100) {
      _dealsNotificados.clear();
    }
  }

  /// Marcar notificación como leída
  void markAsRead(String notificationId) {
    final index = _notificaciones.indexWhere((n) => n.id == notificationId);
    if (index >= 0 && !_notificaciones[index].leida) {
      _notificaciones[index].leida = true;
      _unreadCount--;
      notifyListeners();
    }
  }

  /// Marcar todas como leídas
  void markAllAsRead() {
    for (var notif in _notificaciones) {
      if (!notif.leida) {
        notif.leida = true;
      }
    }
    _unreadCount = 0;
    notifyListeners();
  }

  /// Eliminar notificación
  void deleteNotification(String notificationId) {
    final notification = _notificaciones.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => AppNotification(
        id: '',
        titulo: '',
        mensaje: '',
        tipo: NotificationType.info,
        fecha: DateTime.now(),
      ),
    );

    if (notification.id.isNotEmpty) {
      if (!notification.leida) {
        _unreadCount--;
      }
      _notificaciones.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    }
  }

  /// Limpiar todas las notificaciones
  void clearAll() {
    _notificaciones.clear();
    _unreadCount = 0;
    _limiteClientesNotificado = false;
    _limiteEmpleadosNotificado = false;
    _dealsNotificados.clear();
    notifyListeners();
  }

  /// Obtener notificaciones por tipo
  List<AppNotification> getByType(NotificationType tipo) {
    return _notificaciones.where((n) => n.tipo == tipo).toList();
  }

  /// Obtener solo notificaciones no leídas
  List<AppNotification> getUnread() {
    return _notificaciones.where((n) => !n.leida).toList();
  }
}
