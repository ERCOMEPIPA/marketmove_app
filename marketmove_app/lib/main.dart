import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/resumen/dashboard_screen.dart';
import 'src/features/ventas/ventas_screen.dart';
import 'src/features/gastos/gastos_screen.dart';
import 'src/features/productos/productos_screen.dart';

void main() {
  runApp(const MarketMoveApp());
}

class MarketMoveApp extends StatelessWidget {
  const MarketMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MarketMove',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      routerConfig: _router,
    );
  }
}

// Configuración de rutas con GoRouter
final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/ventas',
      name: 'ventas',
      builder: (context, state) => const VentasScreen(),
    ),
    GoRoute(
      path: '/gastos',
      name: 'gastos',
      builder: (context, state) => const GastosScreen(),
    ),
    GoRoute(
      path: '/productos',
      name: 'productos',
      builder: (context, state) => const ProductosScreen(),
    ),
  ],
);
