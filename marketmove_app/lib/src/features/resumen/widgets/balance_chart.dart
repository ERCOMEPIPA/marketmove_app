import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:marketmove_app/src/shared/constants/app_colors.dart';
import 'package:intl/intl.dart';

/// Modelo para datos del gráfico de balance mensual
class BalanceChartData {
  final String month;
  final double balance;
  final double ventas;
  final double gastos;

  BalanceChartData({
    required this.month,
    required this.balance,
    required this.ventas,
    required this.gastos,
  });
}

/// Gráfico de barras: Balance mensual
class BalanceChart extends StatelessWidget {
  final List<BalanceChartData> data;

  const BalanceChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No hay datos para mostrar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY() * 1.2,
          minY: _getMinY() < 0 ? _getMinY() * 1.2 : 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = data[group.x.toInt()];
                return BarTooltipItem(
                  '${item.month}\n',
                  const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text:
                          'Balance: ${NumberFormat.currency(symbol: '\$').format(item.balance)}\n',
                      style: TextStyle(
                        color: item.balance >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    TextSpan(
                      text:
                          'Ventas: ${NumberFormat.currency(symbol: '\$').format(item.ventas)}\n',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    TextSpan(
                      text:
                          'Gastos: ${NumberFormat.currency(symbol: '\$').format(item.gastos)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[value.toInt()].month,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatCurrency(value),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppColors.border),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.border,
                strokeWidth: 1,
              );
            },
          ),
          barGroups: data
              .asMap()
              .entries
              .map((entry) => BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.balance,
                        color: entry.value.balance >= 0
                            ? AppColors.success
                            : AppColors.error,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: _getMaxY() * 1.2,
                          color: AppColors.surfaceVariant,
                        ),
                      ),
                    ],
                  ))
              .toList(),
        ),
      ),
    );
  }

  double _getMaxY() {
    double max = 0;
    for (var item in data) {
      if (item.balance > max) max = item.balance;
    }
    return max > 0 ? max : 100;
  }

  double _getMinY() {
    double min = 0;
    for (var item in data) {
      if (item.balance < min) min = item.balance;
    }
    return min;
  }

  String _formatCurrency(double value) {
    final absValue = value.abs();
    if (absValue >= 1000) {
      return '${value < 0 ? '-' : ''}\$${(absValue / 1000).toStringAsFixed(0)}k';
    }
    return '\$${value.toInt()}';
  }
}
