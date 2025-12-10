import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'notification_widgets.dart';

/// Shell/Layout para las vistas de administrador
/// Incluye un Drawer con navegación a todas las secciones admin
class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dueño - MarketMove'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Botón de notificaciones
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              return NotificationBadge(
                count: notificationService.unreadCount,
                child: IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.store, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Panel del Dueño',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              route: '/admin/dashboard',
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'CRM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.people,
              title: 'Clientes',
              route: '/admin/clientes',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.view_kanban,
              title: 'Pipeline',
              route: '/admin/pipeline',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.badge,
              title: 'Empleados',
              route: '/admin/empleados',
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'INVENTARIO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.inventory_2,
              title: 'Productos',
              route: '/admin/productos',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.point_of_sale,
              title: 'Ventas',
              route: '/admin/ventas',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.receipt_long,
              title: 'Gastos',
              route: '/admin/gastos',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.analytics,
              title: 'Reportes',
              route: '/admin/reportes',
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'CUENTA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.card_membership,
              title: 'Mi Plan',
              route: '/admin/planes',
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                await authService.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
  }) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context); // Cerrar drawer
        context.go(route);
      },
    );
  }
}
