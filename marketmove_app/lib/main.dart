import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/auth/register_screen.dart';
import 'src/features/resumen/dashboard_screen.dart';
import 'src/features/ventas/ventas_screen.dart';
import 'src/features/gastos/gastos_screen.dart';
import 'src/features/productos/productos_screen.dart';
import 'src/features/admin/reportes/reportes_screen.dart';
import 'src/features/admin/clientes/clientes_screen.dart';
import 'src/features/admin/pipeline/pipeline_screen.dart';
import 'src/features/admin/empleados/empleados_screen.dart';
import 'src/features/superadmin/superadmin_dashboard_v2.dart';
import 'src/features/superadmin/planes_screen.dart';
import 'src/features/admin/planes/seleccion_plan_screen.dart';
import 'src/features/notificaciones/notificaciones_screen.dart';
import 'src/shared/config/supabase_config.dart';
import 'src/shared/config/theme_config.dart';
import 'src/shared/widgets/superadmin_shell.dart';
import 'src/shared/widgets/admin_shell.dart';
import 'src/shared/services/auth_service.dart';
import 'src/shared/services/cart_service.dart';
import 'src/shared/services/orders_service.dart';
import 'src/shared/services/productos_service.dart';
import 'src/shared/services/notification_service.dart';
import 'src/shared/services/search_service.dart';
import 'src/shared/services/reports_service.dart';

// Instancia global del servicio de autenticación
final _authService = AuthService();

Future<void> main() async {
  // Inicializar Flutter binding
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MarketMoveApp());
}

class MarketMoveApp extends StatelessWidget {
  const MarketMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartService()),
        ChangeNotifierProvider(create: (context) => notificationService),
        ChangeNotifierProvider(
          create: (context) => OrdersService(notificationService),
        ),
        ChangeNotifierProvider(create: (context) => ProductosService()),
        ChangeNotifierProvider(
          create: (context) => SearchService(context.read<ProductosService>()),
        ),
        ChangeNotifierProvider(create: (context) => ReportsService()),
      ],
      child: MaterialApp.router(
        title: 'MarketMove',
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.lightTheme,
        routerConfig: _router,
        builder: (context, child) {
          return Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const NotificationOverlay(),
            ],
          );
        },
      ),
    );
  }
}

// Configuración de rutas con GoRouter y control de acceso por roles
// Solo existen 2 roles: Superadmin y Dueño
final GoRouter _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final isAuthenticated = _authService.isAuthenticated;
    final isLoggingIn = state.uri.path == '/login';
    final isRegistering = state.uri.path == '/register';

    // Si no está autenticado y no está en login/register, redirigir a login
    if (!isAuthenticated && !isLoggingIn && !isRegistering) {
      return '/login';
    }

    // Si está autenticado y está en login, redirigir según el rol
    if (isAuthenticated && isLoggingIn) {
      final userRole = await _authService.getCurrentUserRole();
      if (userRole != null) {
        // Redirigir según el rol: Superadmin o Dueño
        if (userRole.isSuperadmin) {
          return '/superadmin/dashboard';
        } else {
          return '/admin/dashboard';
        }
      }
    }

    return null; // No redirigir
  },
  routes: [
    // Ruta de login
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    // Ruta de registro (solo para dueños)
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Rutas de Superadmin
    ShellRoute(
      builder: (context, state, child) => SuperadminShell(child: child),
      routes: [
        GoRoute(
          path: '/superadmin/dashboard',
          name: 'superadmin_dashboard',
          builder: (context, state) => const SuperadminDashboardV2(),
        ),
        GoRoute(
          path: '/superadmin/duenos',
          name: 'superadmin_duenos',
          builder: (context, state) =>
              const SuperadminDashboardV2(), // Mismo dashboard muestra dueños
        ),
        GoRoute(
          path: '/superadmin/planes',
          name: 'superadmin_planes',
          builder: (context, state) => const PlanesScreen(),
        ),
      ],
    ),

    // Rutas de Admin (Dueño del negocio)
    ShellRoute(
      builder: (context, state, child) => AdminShell(child: child),
      routes: [
        GoRoute(
          path: '/admin/dashboard',
          name: 'admin_dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/admin/clientes',
          name: 'admin_clientes',
          builder: (context, state) {
            final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
            return ClientesScreen(negocioId: userId);
          },
        ),
        GoRoute(
          path: '/admin/pipeline',
          name: 'admin_pipeline',
          builder: (context, state) {
            final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
            return PipelineScreen(negocioId: userId);
          },
        ),
        GoRoute(
          path: '/admin/productos',
          name: 'admin_productos',
          builder: (context, state) => const ProductosScreen(),
        ),
        GoRoute(
          path: '/admin/ventas',
          name: 'admin_ventas',
          builder: (context, state) => const VentasScreen(),
        ),
        GoRoute(
          path: '/admin/gastos',
          name: 'admin_gastos',
          builder: (context, state) => const GastosScreen(),
        ),
        GoRoute(
          path: '/admin/reportes',
          name: 'admin_reportes',
          builder: (context, state) => const ReportesScreen(),
        ),
        GoRoute(
          path: '/admin/empleados',
          name: 'admin_empleados',
          builder: (context, state) => const EmpleadosScreen(),
        ),
        GoRoute(
          path: '/admin/planes',
          name: 'admin_planes',
          builder: (context, state) => const SeleccionPlanScreen(),
        ),
      ],
    ),

    // Ruta de notificaciones (accesible desde cualquier lugar)
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    // Rutas legacy para compatibilidad (redirigir a admin)
    GoRoute(
      path: '/dashboard',
      redirect: (context, state) => '/admin/dashboard',
    ),
    GoRoute(path: '/ventas', redirect: (context, state) => '/admin/ventas'),
    GoRoute(path: '/gastos', redirect: (context, state) => '/admin/gastos'),
    GoRoute(
      path: '/productos',
      redirect: (context, state) => '/admin/productos',
    ),
  ],
);
