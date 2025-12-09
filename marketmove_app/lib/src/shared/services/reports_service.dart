import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de reporte de ventas
class SalesReport {
  final String periodo;
  final double totalVentas;
  final int totalOrdenenes;
  final double ventaPromedio;
  final List<ProductoVenta> productosTopVentas;
  final List<VentaDiaria> ventasPorDia;

  SalesReport({
    required this.periodo,
    required this.totalVentas,
    required this.totalOrdenenes,
    required this.ventaPromedio,
    required this.productosTopVentas,
    required this.ventasPorDia,
  });
}

/// Modelo de producto más vendido
class ProductoVenta {
  final String nombreProducto;
  final int cantidadVendida;
  final double ingresoTotal;
  final double porcentajeDelTotal;

  ProductoVenta({
    required this.nombreProducto,
    required this.cantidadVendida,
    required this.ingresoTotal,
    required this.porcentajeDelTotal,
  });
}

/// Modelo de venta diaria
class VentaDiaria {
  final DateTime fecha;
  final double total;
  final int ordenes;

  VentaDiaria({
    required this.fecha,
    required this.total,
    required this.ordenes,
  });
}

/// Servicio de reportes
class ReportsService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  SalesReport? _currentReport;
  bool _isLoading = false;
  String _selectedPeriod = 'mes'; // 'semana', 'mes', 'año'

  SalesReport? get currentReport => _currentReport;
  bool get isLoading => _isLoading;
  String get selectedPeriod => _selectedPeriod;

  /// Generar reporte de ventas
  Future<void> generateSalesReport(String ownerId, {String period = 'mes'}) async {
    _isLoading = true;
    _selectedPeriod = period;
    notifyListeners();

    try {
      final (startDate, endDate) = _getDateRange(period);

      // Obtener órdenes del periodo
      final orders = await _supabase
          .from('ordenes')
          .select()
          .eq('owner_id', ownerId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      if (orders.isEmpty) {
        _currentReport = SalesReport(
          periodo: _getPeriodLabel(period),
          totalVentas: 0,
          totalOrdenenes: 0,
          ventaPromedio: 0,
          productosTopVentas: [],
          ventasPorDia: [],
        );
      } else {
        // Calcular totales
        double totalVentas = 0;
        for (var order in orders) {
          totalVentas += (order['total'] as num).toDouble();
        }

        final ventaPromedio = totalVentas / orders.length;

        // Obtener detalles de órdenes
        final orderIds = (orders as List)
            .map((o) => o['id'] as String)
            .toList();

        final detalles = await _supabase
            .from('detalle_ordenes')
            .select()
            .inFilter('orden_id', orderIds);

        // Procesar productos top vendidos
        final productosMap = <String, (int, double)>{};
        for (var detalle in detalles) {
          final nombre = detalle['nombre'] as String;
          final cantidad = detalle['cantidad'] as int;
          final precio = (detalle['precio'] as num).toDouble();

          if (productosMap.containsKey(nombre)) {
            final (cantActual, totalActual) = productosMap[nombre]!;
            productosMap[nombre] = (cantActual + cantidad, totalActual + (precio * cantidad));
          } else {
            productosMap[nombre] = (cantidad, precio * cantidad);
          }
        }

        final productosTopVentas = productosMap.entries
            .map((entry) => ProductoVenta(
              nombreProducto: entry.key,
              cantidadVendida: entry.value.$1,
              ingresoTotal: entry.value.$2,
              porcentajeDelTotal: (entry.value.$2 / totalVentas) * 100,
            ))
            .toList()
          ..sort((a, b) => b.ingresoTotal.compareTo(a.ingresoTotal))
          ..take(10)
          .toList();

        // Agrupar ventas por día
        final ventasPorDiaMap = <String, (double, int)>{};
        for (var order in orders) {
          final fecha = DateTime.parse(order['created_at'] as String);
          final key = '${fecha.year}-${fecha.month}-${fecha.day}';
          final total = (order['total'] as num).toDouble();

          if (ventasPorDiaMap.containsKey(key)) {
            final (totalActual, ordenesActuales) = ventasPorDiaMap[key]!;
            ventasPorDiaMap[key] = (totalActual + total, ordenesActuales + 1);
          } else {
            ventasPorDiaMap[key] = (total, 1);
          }
        }

        final ventasPorDia = ventasPorDiaMap.entries
            .map((entry) {
              final partes = entry.key.split('-');
              return VentaDiaria(
                fecha: DateTime(
                  int.parse(partes[0]),
                  int.parse(partes[1]),
                  int.parse(partes[2]),
                ),
                total: entry.value.$1,
                ordenes: entry.value.$2,
              );
            })
            .toList()
          ..sort((a, b) => a.fecha.compareTo(b.fecha));

        _currentReport = SalesReport(
          periodo: _getPeriodLabel(period),
          totalVentas: totalVentas,
          totalOrdenenes: orders.length,
          ventaPromedio: ventaPromedio,
          productosTopVentas: productosTopVentas,
          ventasPorDia: ventasPorDia,
        );
      }

      notifyListeners();
    } catch (e) {
      print('Error generating sales report: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtener rango de fechas según el periodo
  (DateTime, DateTime) _getDateRange(String period) {
    final ahora = DateTime.now();
    DateTime inicio;

    switch (period) {
      case 'semana':
        inicio = ahora.subtract(Duration(days: ahora.weekday - 1));
        break;
      case 'mes':
        inicio = DateTime(ahora.year, ahora.month, 1);
        break;
      case 'año':
        inicio = DateTime(ahora.year, 1, 1);
        break;
      default:
        inicio = ahora.subtract(const Duration(days: 30));
    }

    return (inicio, ahora);
  }

  /// Obtener etiqueta del periodo
  String _getPeriodLabel(String period) {
    switch (period) {
      case 'semana':
        return 'Esta semana';
      case 'mes':
        return 'Este mes';
      case 'año':
        return 'Este año';
      default:
        return 'Últimos 30 días';
    }
  }

  /// Obtener tasa de crecimiento vs periodo anterior
  Future<double> getGrowthRate(String ownerId, String period) async {
    final periodoActual = _currentReport?.totalVentas ?? 0;

    if (periodoActual == 0) return 0;

    // Calcular ventas del periodo anterior
    final (startPrev, endPrev) = _getPreviousPeriodRange(period);

    try {
      final ordersPrev = await _supabase
          .from('ordenes')
          .select()
          .eq('owner_id', ownerId)
          .gte('created_at', startPrev.toIso8601String())
          .lte('created_at', endPrev.toIso8601String());

      double totalPrev = 0;
      for (var order in ordersPrev) {
        totalPrev += (order['total'] as num).toDouble();
      }

      if (totalPrev == 0) return 0;
      return ((periodoActual - totalPrev) / totalPrev) * 100;
    } catch (e) {
      print('Error calculating growth rate: $e');
      return 0;
    }
  }

  /// Obtener rango de fechas del periodo anterior
  (DateTime, DateTime) _getPreviousPeriodRange(String period) {
    final ahora = DateTime.now();
    DateTime inicio, fin;

    switch (period) {
      case 'semana':
        fin = ahora.subtract(Duration(days: ahora.weekday));
        inicio = fin.subtract(const Duration(days: 7));
        break;
      case 'mes':
        fin = DateTime(ahora.year, ahora.month - 1, 0);
        inicio = DateTime(ahora.year, ahora.month - 1, 1);
        break;
      case 'año':
        fin = DateTime(ahora.year - 1, 12, 31);
        inicio = DateTime(ahora.year - 1, 1, 1);
        break;
      default:
        fin = ahora.subtract(const Duration(days: 30));
        inicio = fin.subtract(const Duration(days: 30));
    }

    return (inicio, fin);
  }
}
