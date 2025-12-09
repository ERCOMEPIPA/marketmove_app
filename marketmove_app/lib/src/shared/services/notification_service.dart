import 'package:flutter/material.dart';

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
}

/// Servicio para manejar notificaciones
class NotificationService extends ChangeNotifier {
  final List<AppNotification> _notificaciones = [];
  int _unreadCount = 0;

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
