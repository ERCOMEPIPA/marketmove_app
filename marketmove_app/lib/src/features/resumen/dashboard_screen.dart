import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/services/dashboard_service.dart';
import '../../shared/services/auth_service.dart';

/// Pantalla principal - Dashboard con métricas reales
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboardService = DashboardService();
  final _authService = AuthService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

  DashboardMetrics? _metrics;
  List<Map<String, dynamic>> _productosStockBajo = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final metrics = await _dashboardService.getMetrics(user.id);
      final productosStockBajo = await _dashboardService.getProductosStockBajo(
        user.id,
      );

      setState(() {
        _metrics = metrics;
        _productosStockBajo = productosStockBajo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final metrics = _metrics!;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Text(
                'Resumen del Negocio',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Métricas de HOY
              Text(
                'Hoy',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Ventas',
                      value: _currencyFormat.format(metrics.ventasHoy),
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Gastos',
                      value: _currencyFormat.format(metrics.gastosHoy),
                      icon: Icons.trending_down,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildMetricCard(
                context,
                title: 'Ganancia del Día',
                value: _currencyFormat.format(metrics.gananciaHoy),
                icon: Icons.account_balance_wallet,
                color: metrics.gananciaHoy >= 0 ? Colors.blue : Colors.orange,
                large: true,
              ),

              const SizedBox(height: 32),

              // Métricas del MES
              Text(
                'Este Mes',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Ventas',
                      value: _currencyFormat.format(metrics.ventasMes),
                      icon: Icons.point_of_sale,
                      color: Colors.green,
                      subtitle: _buildComparison(
                        metrics.porcentajeCambioVentas,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      title: 'Gastos',
                      value: _currencyFormat.format(metrics.gastosMes),
                      icon: Icons.money_off,
                      color: Colors.red,
                      subtitle: _buildComparison(
                        metrics.porcentajeCambioGastos,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildMetricCard(
                context,
                title: 'Ganancia del Mes',
                value: _currencyFormat.format(metrics.gananciaMes),
                icon: Icons.savings,
                color: metrics.gananciaMes >= 0
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                large: true,
              ),

              const SizedBox(height: 32),

              // Productos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inventario',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/admin/productos'),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Ver todos'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      title: 'Total Productos',
                      value: '${metrics.totalProductos}',
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      title: 'Stock Bajo',
                      value: '${metrics.productosStockBajo}',
                      icon: Icons.warning_amber,
                      color: metrics.productosStockBajo > 0
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                ],
              ),

              // Alertas de stock bajo
              if (_productosStockBajo.isNotEmpty) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Productos con Stock Bajo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._productosStockBajo
                            .take(5)
                            .map(
                              (producto) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        producto['nombre'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Stock: ${producto['stock']} (mín: ${producto['stock_minimo']})',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        if (_productosStockBajo.length > 5) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Y ${_productosStockBajo.length - 5} más...',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Accesos rápidos
              Text(
                'Accesos Rápidos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildQuickAccessCard(
                context,
                title: 'Registrar Venta',
                icon: Icons.point_of_sale,
                color: Colors.green,
                onTap: () => context.go('/admin/ventas'),
              ),
              const SizedBox(height: 8),

              _buildQuickAccessCard(
                context,
                title: 'Registrar Gasto',
                icon: Icons.money_off,
                color: Colors.red,
                onTap: () => context.go('/admin/gastos'),
              ),
              const SizedBox(height: 8),

              _buildQuickAccessCard(
                context,
                title: 'Ver Reportes',
                icon: Icons.analytics,
                color: Colors.purple,
                onTap: () => context.go('/admin/reportes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    Widget? subtitle,
    bool large = false,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(large ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: large ? 32 : 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: large ? 18 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: large ? 32 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[const SizedBox(height: 4), subtitle],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparison(double porcentaje) {
    final isPositive = porcentaje >= 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
          size: 16,
          color: isPositive ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          '${porcentaje.abs().toStringAsFixed(1)}% vs mes anterior',
          style: TextStyle(
            fontSize: 12,
            color: isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
