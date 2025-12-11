import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../utils/responsive_utils.dart';
import 'notification_widgets.dart';

/// Shell/Layout responsive para las vistas de administrador
/// - Desktop: Sidebar permanente + contenido
/// - Móvil/Tablet: Drawer + AppBar
class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.screenWidth(context) >= 900;

    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  /// Layout para desktop con sidebar permanente
  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar permanente
          SizedBox(width: 260, child: _buildSidebar(context)),
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // AppBar simplificado para desktop
                _buildDesktopAppBar(context),
                // Contenido
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Layout para móvil/tablet con drawer
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketMove'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: _buildAppBarActions(context),
      ),
      drawer: Drawer(child: _buildSidebar(context)),
      body: child,
    );
  }

  /// AppBar para desktop (sin menú hamburguesa)
  Widget _buildDesktopAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Título de la sección actual
          Text(
            _getCurrentSectionTitle(context),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          // Acciones
          ..._buildAppBarActions(context),
        ],
      ),
    );
  }

  /// Acciones del AppBar (notificaciones)
  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      Consumer<NotificationService>(
        builder: (context, notificationService, _) {
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
    ];
  }

  /// Sidebar/Drawer compartido
  Widget _buildSidebar(BuildContext context) {
    final authService = AuthService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.store, size: 40, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'MarketMove',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Panel del Dueño',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Menú scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  context,
                  Icons.dashboard,
                  'Dashboard',
                  '/admin/dashboard',
                ),
                _buildSectionHeader('CRM'),
                _buildNavItem(
                  context,
                  Icons.people,
                  'Clientes',
                  '/admin/clientes',
                ),
                _buildNavItem(
                  context,
                  Icons.view_kanban,
                  'Pipeline',
                  '/admin/pipeline',
                ),
                _buildNavItem(
                  context,
                  Icons.badge,
                  'Empleados',
                  '/admin/empleados',
                ),
                _buildSectionHeader('INVENTARIO'),
                _buildNavItem(
                  context,
                  Icons.inventory_2,
                  'Productos',
                  '/admin/productos',
                ),
                _buildNavItem(
                  context,
                  Icons.point_of_sale,
                  'Ventas',
                  '/admin/ventas',
                ),
                _buildNavItem(
                  context,
                  Icons.receipt_long,
                  'Gastos',
                  '/admin/gastos',
                ),
                _buildNavItem(
                  context,
                  Icons.analytics,
                  'Reportes',
                  '/admin/reportes',
                ),
                _buildSectionHeader('CUENTA'),
                _buildNavItem(
                  context,
                  Icons.card_membership,
                  'Mi Plan',
                  '/admin/planes',
                ),
                _buildNavItem(
                  context,
                  Icons.settings,
                  'Configuración',
                  '/admin/settings',
                ),
              ],
            ),
          ),
          // Logout
          const Divider(height: 1),
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final isSelected = currentRoute == route;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 22,
          color: isSelected ? primaryColor : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? primaryColor : null,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          // Cerrar drawer si está abierto (móvil)
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.pop(context);
          }
          context.go(route);
        },
      ),
    );
  }

  String _getCurrentSectionTitle(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    switch (path) {
      case '/admin/dashboard':
        return 'Dashboard';
      case '/admin/clientes':
        return 'Clientes';
      case '/admin/pipeline':
        return 'Pipeline';
      case '/admin/empleados':
        return 'Empleados';
      case '/admin/productos':
        return 'Productos';
      case '/admin/ventas':
        return 'Ventas';
      case '/admin/gastos':
        return 'Gastos';
      case '/admin/reportes':
        return 'Reportes';
      case '/admin/planes':
        return 'Mi Plan';
      case '/admin/settings':
        return 'Configuración';
      default:
        return 'MarketMove';
    }
  }
}
