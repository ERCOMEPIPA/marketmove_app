import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';
import 'notification_widgets.dart';

/// Shell/Layout para las vistas de empleado
/// Incluye un BottomNavigationBar para navegación entre secciones
class ClienteShell extends StatefulWidget {
  final Widget child;
  final String location;

  const ClienteShell({super.key, required this.child, required this.location});

  @override
  State<ClienteShell> createState() => _ClienteShellState();
}

class _ClienteShellState extends State<ClienteShell> {
  int _getCurrentIndex() {
    final location = widget.location;
    // CRM Routes
    if (location.startsWith('/empleado/dashboard')) return 0;
    if (location.startsWith('/empleado/clientes')) return 1;
    if (location.startsWith('/empleado/deals')) return 2;
    // Marketplace Routes
    if (location.startsWith('/empleado/catalogo')) return 3;
    if (location.startsWith('/empleado/compras')) return 4;
    if (location.startsWith('/empleado/perfil')) return 5;
    // Compatibilidad legacy
    if (location.startsWith('/cliente/catalogo')) return 3;
    if (location.startsWith('/cliente/compras')) return 4;
    if (location.startsWith('/cliente/perfil')) return 5;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/empleado/dashboard');
        break;
      case 1:
        context.go('/empleado/clientes');
        break;
      case 2:
        context.go('/empleado/deals');
        break;
      case 3:
        context.go('/empleado/catalogo');
        break;
      case 4:
        context.go('/empleado/compras');
        break;
      case 5:
        context.go('/empleado/perfil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketMove'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Botón de búsqueda
          IconButton(
            onPressed: () => context.push('/empleado/search'),
            icon: const Icon(Icons.search),
          ),
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
          // Botón del carrito
          Consumer<CartService>(
            builder: (context, cartService, child) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => context.go('/empleado/carrito'),
                    icon: const Icon(Icons.shopping_cart),
                  ),
                  if (cartService.itemCount > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cartService.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getCurrentIndex(),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.handshake), label: 'Deals'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Catálogo'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Compras',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
