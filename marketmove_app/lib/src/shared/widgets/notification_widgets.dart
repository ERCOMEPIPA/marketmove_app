import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

/// Widget para mostrar snackbar de notificaciones
class NotificationSnackbar extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onDismiss;

  const NotificationSnackbar({
    super.key,
    required this.notification,
    this.onDismiss,
  });

  Color _getBackgroundColor(NotificationType tipo) {
    switch (tipo) {
      case NotificationType.pedidoRecibido:
        return Colors.blue[600]!;
      case NotificationType.pedidoEnProceso:
        return Colors.amber[600]!;
      case NotificationType.pedidoEntregado:
        return Colors.green[600]!;
      case NotificationType.nuevoProducto:
        return Colors.purple[600]!;
      case NotificationType.stock:
        return Colors.orange[600]!;
      case NotificationType.error:
        return Colors.red[600]!;
      case NotificationType.info:
        return Colors.grey[600]!;
    }
  }

  IconData _getIcon(NotificationType tipo) {
    switch (tipo) {
      case NotificationType.pedidoRecibido:
        return Icons.shopping_cart;
      case NotificationType.pedidoEnProceso:
        return Icons.hourglass_bottom;
      case NotificationType.pedidoEntregado:
        return Icons.check_circle;
      case NotificationType.nuevoProducto:
        return Icons.new_releases;
      case NotificationType.stock:
        return Icons.inventory;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(notification.tipo),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _getIcon(notification.tipo),
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  notification.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  notification.mensaje,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar lista de notificaciones
class NotificationCenter extends StatelessWidget {
  const NotificationCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, _) {
        final notificaciones = notificationService.notificaciones;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notificaciones'),
            elevation: 0,
            actions: [
              if (notificaciones.isNotEmpty)
                TextButton(
                  onPressed: () {
                    notificationService.markAllAsRead();
                  },
                  child: const Text(
                    'Marcar todas como leídas',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          body: notificaciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay notificaciones',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: notificaciones.length,
                  itemBuilder: (context, index) {
                    final notif = notificaciones[index];
                    return NotificationTile(
                      notification: notif,
                      onTap: () {
                        notificationService.markAsRead(notif.id);
                      },
                      onDelete: () {
                        notificationService.deleteNotification(notif.id);
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

/// Widget individual para cada notificación
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  Color _getColor(NotificationType tipo) {
    switch (tipo) {
      case NotificationType.pedidoRecibido:
        return Colors.blue[50]!;
      case NotificationType.pedidoEnProceso:
        return Colors.amber[50]!;
      case NotificationType.pedidoEntregado:
        return Colors.green[50]!;
      case NotificationType.nuevoProducto:
        return Colors.purple[50]!;
      case NotificationType.stock:
        return Colors.orange[50]!;
      case NotificationType.error:
        return Colors.red[50]!;
      case NotificationType.info:
        return Colors.grey[50]!;
    }
  }

  IconData _getIcon(NotificationType tipo) {
    switch (tipo) {
      case NotificationType.pedidoRecibido:
        return Icons.shopping_cart;
      case NotificationType.pedidoEnProceso:
        return Icons.hourglass_bottom;
      case NotificationType.pedidoEntregado:
        return Icons.check_circle;
      case NotificationType.nuevoProducto:
        return Icons.new_releases;
      case NotificationType.stock:
        return Icons.inventory;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.leida ? Colors.white : _getColor(notification.tipo),
      child: ListTile(
        leading: Icon(
          _getIcon(notification.tipo),
          size: 28,
        ),
        title: Text(
          notification.titulo,
          style: TextStyle(
            fontWeight:
                notification.leida ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.mensaje,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.fecha),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inSeconds < 60) {
      return 'hace ${diferencia.inSeconds}s';
    } else if (diferencia.inMinutes < 60) {
      return 'hace ${diferencia.inMinutes}m';
    } else if (diferencia.inHours < 24) {
      return 'hace ${diferencia.inHours}h';
    } else {
      return 'hace ${diferencia.inDays}d';
    }
  }
}

/// Badge para mostrar número de notificaciones no leídas
class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
