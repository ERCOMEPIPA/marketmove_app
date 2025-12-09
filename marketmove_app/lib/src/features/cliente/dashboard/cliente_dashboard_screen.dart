import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/services/orders_service.dart';
import '../../../shared/services/productos_service.dart';
import '../../../shared/services/auth_service.dart';

/// Dashboard mejorado para empleados
/// Muestra resumen de actividad y acceso rápido a funciones
class ClienteDashboardScreen extends StatefulWidget {
  const ClienteDashboardScreen({super.key});

  @override
  State<ClienteDashboardScreen> createState() => _ClienteDashboardScreenState();
}

class _ClienteDashboardScreenState extends State<ClienteDashboardScreen> {
  static final _currencyFormat = NumberFormat.currency(
    symbol: '€',
    decimalDigits: 2,
  );
  final _authService = AuthService();
  String? _negocioNombre;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      // Obtener perfil del empleado
      final profile = await Supabase.instance.client
          .from('perfiles')
          .select('negocio_id, rol')
          .eq('id', currentUser.id)
          .single();

      final negocioId = profile['negocio_id'] as String?;
      final role = profile['rol'] as String;

      if (negocioId != null) {
        // Obtener nombre del negocio
        final negocio = await Supabase.instance.client
            .from('perfiles')
            .select('nombre_negocio')
            .eq('id', negocioId)
            .single();

        setState(() {
          _negocioNombre = negocio['nombre_negocio'] as String?;
        });

        // Cargar productos del negocio
        if (mounted) {
          final productosService = context.read<ProductosService>();
          await productosService.loadProductosForEmployee(negocioId);
        }

        // Cargar órdenes
        if (mounted) {
          final ordersService = context.read<OrdersService>();
          await ordersService.loadOrders(currentUser.id, role);
        }
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _authService.currentUser?.email ?? 'Empleado';
    final userName = userEmail.split('@').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header con gradiente
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Hola, $userName!',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (_negocioNombre != null)
                                    Text(
                                      _negocioNombre!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                    ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.storefront,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tarjetas de estadísticas
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Consumer2<OrdersService, ProductosService>(
                        builder: (context, ordersService, productosService, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Estadísticas rápidas
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Mis Pedidos',
                                      '${ordersService.totalOrders}',
                                      Icons.shopping_bag,
                                      AppColors.info,
                                      () => context.go('/empleado/compras'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Productos',
                                      '${productosService.productos.length}',
                                      Icons.inventory_2,
                                      AppColors.success,
                                      () => context.go('/empleado/catalogo'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Total Gastado',
                                      _currencyFormat.format(
                                        ordersService.totalSpent,
                                      ),
                                      Icons.payments,
                                      AppColors.warning,
                                      null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Pendientes',
                                      '${ordersService.processingCount}',
                                      Icons.pending_actions,
                                      Colors.orange,
                                      () => context.go('/empleado/compras'),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Acciones rápidas
                              const Text(
                                'Acciones Rápidas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              _buildActionCard(
                                icon: Icons.store,
                                title: 'Ver Catálogo',
                                subtitle: 'Explora productos disponibles',
                                color: AppColors.primary,
                                onTap: () => context.go('/empleado/catalogo'),
                              ),
                              const SizedBox(height: 10),
                              _buildActionCard(
                                icon: Icons.shopping_cart,
                                title: 'Mi Carrito',
                                subtitle: 'Ver productos seleccionados',
                                color: AppColors.warning,
                                onTap: () => context.go('/empleado/carrito'),
                              ),
                              const SizedBox(height: 10),
                              _buildActionCard(
                                icon: Icons.receipt_long,
                                title: 'Historial de Compras',
                                subtitle: 'Ver mis pedidos anteriores',
                                color: AppColors.info,
                                onTap: () => context.go('/empleado/compras'),
                              ),
                              const SizedBox(height: 10),
                              _buildActionCard(
                                icon: Icons.person,
                                title: 'Mi Perfil',
                                subtitle: 'Configuración de cuenta',
                                color: AppColors.secondary,
                                onTap: () => context.go('/empleado/perfil'),
                              ),

                              const SizedBox(height: 24),

                              // Últimos pedidos
                              if (ordersService.orders.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Últimos Pedidos',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          context.go('/empleado/compras'),
                                      child: const Text('Ver todos'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...ordersService.orders
                                    .take(3)
                                    .map(
                                      (order) => _buildRecentOrderCard(order),
                                    ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderCard(Order order) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isEntregado = order.estado == 'Entregado';
    final statusColor = isEntregado ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEntregado ? Icons.check_circle : Icons.schedule,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(order.fecha),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.estado,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
