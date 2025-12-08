import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/services/dashboard_service.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/constants/app_colors.dart';
import 'widgets/kpi_card.dart';
import 'widgets/sales_chart.dart';
import 'widgets/balance_chart.dart';

/// Pantalla principal - Dashboard mejorado con gráficos interactivos
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
      final productosStockBajo =
          await _dashboardService.getProductosStockBajo(user.id);

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
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: ErrorState(
          message: _error!,
          onRetry: _loadData,
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
              // Título y fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'es').format(
                          DateTime.now(),
                        ),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KPI Cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  KpiCard(
                    title: 'Ventas del Mes',
                    value: _currencyFormat.format(metrics.ventasMes),
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    trend: metrics.porcentajeCambioVentas >= 0
                        ? '+${metrics.porcentajeCambioVentas.toStringAsFixed(1)}%'
                        : '${metrics.porcentajeCambioVentas.toStringAsFixed(1)}%',
                    isPositiveTrend: metrics.porcentajeCambioVentas >= 0,
                  ),
                  KpiCard(
                    title: 'Gastos del Mes',
                    value: _currencyFormat.format(metrics.gastosMes),
                    icon: Icons.trending_down,
                    color: AppColors.error,
                    trend: metrics.porcentajeCambioGastos >= 0
                        ? '+${metrics.porcentajeCambioGastos.toStringAsFixed(1)}%'
                        : '${metrics.porcentajeCambioGastos.toStringAsFixed(1)}%',
                    isPositiveTrend: metrics.porcentajeCambioGastos < 0,
                  ),
                  KpiCard(
                    title: 'Balance',
                    value: _currencyFormat.format(metrics.gananciaMes),
                    icon: Icons.account_balance_wallet,
                    color: metrics.gananciaMes >= 0
                        ? AppColors.primary
                        : AppColors.warning,
                    subtitle: 'Ventas - Gastos',
                  ),
                  KpiCard(
                    title: 'Productos',
                    value: '${metrics.totalProductos}',
                    icon: Icons.inventory_2,
                    color: AppColors.info,
                    subtitle: metrics.productosStockBajo > 0
                        ? '${metrics.productosStockBajo} con stock bajo'
                        : 'Stock adecuado',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Gráfico de ventas vs gastos
              Text(
                'Ventas vs Gastos (Últimos 7 días)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SalesChart(
                  data: _generateSampleSalesData(),
                ),
              ),
              const SizedBox(height: 8),
              const ChartLegend(),

              const SizedBox(height: 32),

              // Gráfico de balance mensual
              Text(
                'Balance Mensual',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: BalanceChart(
                  data: _generateSampleBalanceData(),
                ),
              ),

              const SizedBox(height: 32),

              // Alertas de stock bajo
              if (_productosStockBajo.isNotEmpty) ...[
                _buildStockBajoSection(),
                const SizedBox(height: 32),
              ],

              // Accesos rápidos
              Text(
                'Accesos Rápidos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              _buildQuickAccessButtons(context),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBajoSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Productos con Stock Bajo',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/admin/productos'),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(
            _productosStockBajo.length.clamp(0, 5),
            (index) {
              final producto = _productosStockBajo[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            producto['nombre'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stock actual: ${producto['stock']} (mínimo: ${producto['stock_minimo']})',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${producto['stock']} unid.',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.warning.withOpacity(0.2),
                      side: BorderSide.none,
                    ),
                  ],
                ),
              );
            },
          ),
          if (_productosStockBajo.length > 5)
            Center(
              child: Text(
                '+${_productosStockBajo.length - 5} productos más',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButtons(BuildContext context) {
    final actions = [
      {
        'title': 'Registrar Venta',
        'icon': Icons.add_shopping_cart,
        'color': AppColors.success,
        'route': '/admin/ventas',
      },
      {
        'title': 'Registrar Gasto',
        'icon': Icons.receipt_long,
        'color': AppColors.error,
        'route': '/admin/gastos',
      },
      {
        'title': 'Gestionar Productos',
        'icon': Icons.inventory_2,
        'color': AppColors.info,
        'route': '/admin/productos',
      },
      {
        'title': 'Ver Reportes',
        'icon': Icons.analytics,
        'color': AppColors.secondary,
        'route': '/admin/reportes',
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: actions.map((action) {
        return InkWell(
          onTap: () => context.go(action['route'] as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    action['title'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Genera datos de ejemplo para el gráfico de ventas
  // TODO: Reemplazar con datos reales del backend
  List<SalesChartData> _generateSampleSalesData() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return SalesChartData(
        date: date,
        ventas: 1000 + (index * 200) + (index % 2 * 300),
        gastos: 500 + (index * 150) + (index % 3 * 200),
      );
    });
  }

  // Genera datos de ejemplo para el gráfico de balance
  // TODO: Reemplazar con datos reales del backend
  List<BalanceChartData> _generateSampleBalanceData() {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
    return List.generate(6, (index) {
      final ventas = 5000 + (index * 1000);
      final gastos = 3000 + (index * 800);
      return BalanceChartData(
        month: months[index],
        balance: (ventas - gastos).toDouble(),
        ventas: ventas.toDouble(),
        gastos: gastos.toDouble(),
      );
    });
  }
}
