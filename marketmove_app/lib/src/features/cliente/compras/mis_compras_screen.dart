import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/constants/app_colors.dart';
import '../../../shared/services/orders_service.dart';

/// Pantalla de historial de compras del empleado
/// Muestra un resumen de compras realizadas
class MisComprasScreen extends StatefulWidget {
  const MisComprasScreen({super.key});

  @override
  State<MisComprasScreen> createState() => _MisComprasScreenState();
}

class _MisComprasScreenState extends State<MisComprasScreen> {
  static final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) return;

      // Obtener el perfil para determinar el rol
      final profile = await Supabase.instance.client
          .from('perfiles')
          .select('rol')
          .eq('id', currentUser.id)
          .single();

      final role = profile['rol'] as String;

      if (!mounted) return;
      final ordersService = context.read<OrdersService>();
      await ordersService.loadOrders(currentUser.id, role);
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersService>(
      builder: (context, ordersService, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: RefreshIndicator(
            onRefresh: _loadOrders,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado con gradiente
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.85),
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
                                  'Mis Compras',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ordersService.totalOrders} pedidos realizados',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
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
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tarjeta de resumen mejorada
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gasto Total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _currencyFormat.format(ordersService.totalSpent),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.trending_up,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItemNew(
                                '${ordersService.totalOrders}',
                                'Total',
                                Icons.receipt_long,
                                AppColors.info,
                              ),
                              _buildStatItemNew(
                                '${ordersService.deliveredCount}',
                                'Entregadas',
                                Icons.check_circle,
                                AppColors.success,
                              ),
                              _buildStatItemNew(
                                '${ordersService.processingCount}',
                                'Procesando',
                                Icons.schedule,
                                AppColors.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lista de órdenes
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ordersService.orders.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Sin compras aún',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tus pedidos aparecerán aquí',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ordersService.orders.length,
                            itemBuilder: (context, index) {
                              final order = ordersService.orders[index];
                              return _buildOrderCard(order);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.info,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItemNew(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final isEntregado = order.estado == 'Entregado';
    final statusColor = isEntregado ? AppColors.success : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // Encabezado de la orden
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: Border(
                bottom: BorderSide(color: statusColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orden #${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _dateFormat.format(order.fecha),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isEntregado
                            ? Icons.check_circle
                            : Icons.schedule,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        order.estado,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items horizontales
          if (order.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                height: 65,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildProductTile(item),
                    );
                  },
                ),
              ),
            ),

          // Divisor
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.grey[200],
          ),

          // Footer con total y detalles
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total de la orden',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(order.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '${order.items.length} ${order.items.length == 1 ? "artículo" : "artículos"}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProductIcon(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('bebida') || name.contains('agua') || name.contains('jugo')) {
      return Icons.local_drink;
    } else if (name.contains('comida') || name.contains('pizza') || name.contains('hamburguesa')) {
      return Icons.fastfood;
    } else if (name.contains('dulce') || name.contains('chocolate') || name.contains('caramelo')) {
      return Icons.cake;
    } else if (name.contains('pan') || name.contains('pastel')) {
      return Icons.lunch_dining;
    } else if (name.contains('fruta') || name.contains('manzana')) {
      return Icons.apple;
    } else if (name.contains('vegetal') || name.contains('lechuga')) {
      return Icons.eco;
    } else if (name.contains('lacteo') || name.contains('leche') || name.contains('queso')) {
      return Icons.water_drop;
    }
    return Icons.shopping_bag;
  }

  Widget _buildProductTile(dynamic item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              _getProductIcon(item.nombre),
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 56,
          child: Text(
            item.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          'x${item.cantidad}',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}