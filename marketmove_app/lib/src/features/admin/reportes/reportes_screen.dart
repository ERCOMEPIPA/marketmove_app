import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/ventas_service.dart';
import '../../../shared/services/gastos_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/export_service.dart';
import '../../../shared/models/venta_model.dart';
import '../../../shared/models/gasto_model.dart';
import '../../../shared/constants/app_colors.dart';

/// Pantalla de reportes mejorada con gráficos y estadísticas
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _ventasService = VentasService();
  final _gastosService = GastosService();
  final _authService = AuthService();
  final _exportService = ExportService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

  List<VentaModel> _ventas = [];
  List<GastoModel> _gastos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser!;

      // Cargar últimos 30 días
      final hace30Dias = DateTime.now().subtract(const Duration(days: 30));

      final ventas = await _ventasService.getVentas(user.id, desde: hace30Dias);
      final gastos = await _gastosService.getGastos(user.id, desde: hace30Dias);

      setState(() {
        _ventas = ventas;
        _gastos = gastos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, double> _getVentasPorProducto() {
    final Map<String, double> productosVentas = {};

    for (final venta in _ventas) {
      if (venta.detalles != null) {
        for (final detalle in venta.detalles!) {
          final nombre = detalle.productoNombre ?? 'Producto';
          productosVentas[nombre] =
              (productosVentas[nombre] ?? 0) + detalle.subtotal;
        }
      }
    }

    // Ordenar y tomar top 5
    final sortedEntries = productosVentas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(5));
  }

  Map<String, double> _getGastosPorCategoria() {
    final Map<String, double> categoriaGastos = {};

    for (final gasto in _gastos) {
      final categoria = gasto.categoriaNombre ?? 'Sin categoría';
      categoriaGastos[categoria] =
          (categoriaGastos[categoria] ?? 0) + gasto.monto;
    }

    return categoriaGastos;
  }

  List<FlSpot> _getVentasPorDia() {
    final Map<int, double> ventasPorDia = {};
    final ahora = DateTime.now();

    for (final venta in _ventas) {
      final diasAtras = ahora.difference(venta.fecha).inDays;
      if (diasAtras <= 7) {
        ventasPorDia[diasAtras] = (ventasPorDia[diasAtras] ?? 0) + venta.monto;
      }
    }

    return List.generate(8, (i) {
      return FlSpot(i.toDouble(), ventasPorDia[7 - i] ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalVentas = _ventas.fold<double>(0, (sum, v) => sum + v.monto);
    final totalGastos = _gastos.fold<double>(0, (sum, g) => sum + g.monto);
    final ganancia = totalVentas - totalGastos;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y botón de exportar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reportes y Análisis',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Últimos 30 días',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  // Botón de exportar con menú
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.download, color: AppColors.primary),
                    ),
                    tooltip: 'Exportar',
                    onSelected: (value) {
                      final totalVentas = _ventas.fold<double>(
                        0,
                        (sum, v) => sum + v.monto,
                      );
                      final totalGastos = _gastos.fold<double>(
                        0,
                        (sum, g) => sum + g.monto,
                      );

                      switch (value) {
                        case 'ventas':
                          _exportService.exportarVentasCSV(_ventas);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Exportando ventas a CSV...'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          break;
                        case 'reporte':
                          _exportService.exportarReporteMensualCSV(
                            periodo: 'Últimos 30 días',
                            totalVentas: totalVentas,
                            totalGastos: totalGastos,
                            ventas: _ventas,
                            gastos: _gastos,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Exportando reporte mensual a CSV...',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'ventas',
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long, size: 20),
                            SizedBox(width: 8),
                            Text('Exportar Ventas'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reporte',
                        child: Row(
                          children: [
                            Icon(Icons.summarize, size: 20),
                            SizedBox(width: 8),
                            Text('Reporte Completo'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Resumen general
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Ventas',
                      _currencyFormat.format(totalVentas),
                      Colors.green,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Gastos',
                      _currencyFormat.format(totalGastos),
                      Colors.red,
                      Icons.trending_down,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryCard(
                'Ganancia Neta',
                _currencyFormat.format(ganancia),
                ganancia >= 0 ? Colors.blue : Colors.orange,
                Icons.account_balance_wallet,
              ),

              const SizedBox(height: 32),

              // Gráfico de ventas por día (última semana)
              Text(
                'Ventas - Última Semana',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '€${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final dias = [
                              'Hace 7',
                              '6',
                              '5',
                              '4',
                              '3',
                              '2',
                              'Ayer',
                              'Hoy',
                            ];
                            if (value.toInt() >= 0 &&
                                value.toInt() < dias.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  dias[value.toInt()],
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _getVentasPorDia(),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Top 5 productos más vendidos
              Text(
                'Top 5 Productos Más Vendidos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildTopProductos(),

              const SizedBox(height: 32),

              // Gastos por categoría
              if (_gastos.isNotEmpty) ...[
                Text(
                  'Gastos por Categoría',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(height: 250, child: _buildGastosPieChart()),
                const SizedBox(height: 16),
                _buildGastosLegend(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductos() {
    final topProductos = _getVentasPorProducto();

    if (topProductos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No hay datos de ventas',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final maxVenta = topProductos.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: topProductos.entries.map((entry) {
            final porcentaje = (entry.value / maxVenta);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        _currencyFormat.format(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: porcentaje,
                    backgroundColor: Colors.grey[200],
                    color: Colors.green,
                    minHeight: 8,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGastosPieChart() {
    final gastosPorCategoria = _getGastosPorCategoria();

    if (gastosPorCategoria.isEmpty) {
      return const Center(child: Text('No hay datos de gastos'));
    }

    final total = gastosPorCategoria.values.reduce((a, b) => a + b);
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: gastosPorCategoria.entries.toList().asMap().entries.map((
          entry,
        ) {
          final index = entry.key;
          final data = entry.value;
          final porcentaje = (data.value / total * 100);

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: data.value,
            title: '${porcentaje.toStringAsFixed(1)}%',
            radius: 80,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGastosLegend() {
    final gastosPorCategoria = _getGastosPorCategoria();
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: gastosPorCategoria.entries.toList().asMap().entries.map((
            entry,
          ) {
            final index = entry.key;
            final data = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(data.key)),
                  Text(
                    _currencyFormat.format(data.value),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
