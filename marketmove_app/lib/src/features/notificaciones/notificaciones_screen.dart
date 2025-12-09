import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/widgets/notification_widgets.dart';

/// Widget del icono de notificaciones para el AppBar
class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, _) {
        return NotificationBadge(
          count: notificationService.unreadCount,
          child: IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              context.push('/notifications');
            },
          ),
        );
      },
    );
  }
}

/// Pantalla del centro de notificaciones
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotificationCenter();
  }
}

/// Widget para mostrar notificaciones en un overlay
class NotificationOverlay extends StatefulWidget {
  const NotificationOverlay({super.key});

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay>
    with WidgetsBindingObserver {
  OverlayEntry? _overlayEntry;
  final List<AppNotification> _displayedNotifications = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeOverlay();
    super.dispose();
  }

  void _listenToNotifications() {
    Future.microtask(() {
      if (mounted) {
        final notificationService =
            context.read<NotificationService>();
        notificationService.addListener(_onNotificationAdded);
      }
    });
  }

  void _onNotificationAdded() {
    final notificationService = context.read<NotificationService>();
    final unreadNotifications = notificationService.getUnread();

    for (var notif in unreadNotifications) {
      if (!_displayedNotifications.any((n) => n.id == notif.id)) {
        _displayedNotifications.add(notif);
        _showNotification(notif);
      }
    }
  }

  void _showNotification(AppNotification notification) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: NotificationSnackbar(
            notification: notification,
            onDismiss: () {
              context.read<NotificationService>().markAsRead(notification.id);
              _removeOverlay();
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // Auto-remover después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (_overlayEntry != null) {
        _removeOverlay();
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
