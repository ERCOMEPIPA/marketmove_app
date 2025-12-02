import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell/Layout para las vistas de cliente
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
    if (location.startsWith('/cliente/catalogo')) return 0;
    if (location.startsWith('/cliente/compras')) return 1;
    if (location.startsWith('/cliente/perfil')) return 2;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/cliente/catalogo');
        break;
      case 1:
        context.go('/cliente/compras');
        break;
      case 2:
        context.go('/cliente/perfil');
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
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getCurrentIndex(),
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Catálogo'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Mis Compras',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
