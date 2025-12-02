import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo para las métricas del dashboard
class DashboardMetrics {
  final double ventasHoy;
  final double gastosHoy;
  final double gananciaHoy;
  final double ventasMes;
  final double gastosMes;
  final double gananciaMes;
  final double ventasMesAnterior;
  final double gastosMesAnterior;
  final int totalProductos;
  final int productosStockBajo;

  const DashboardMetrics({
    required this.ventasHoy,
    required this.gastosHoy,
    required this.gananciaHoy,
    required this.ventasMes,
    required this.gastosMes,
    required this.gananciaMes,
    required this.ventasMesAnterior,
    required this.gastosMesAnterior,
    required this.totalProductos,
    required this.productosStockBajo,
  });

  double get porcentajeCambioVentas {
    if (ventasMesAnterior == 0) return 0;
    return ((ventasMes - ventasMesAnterior) / ventasMesAnterior) * 100;
  }

  double get porcentajeCambioGastos {
    if (gastosMesAnterior == 0) return 0;
    return ((gastosMes - gastosMesAnterior) / gastosMesAnterior) * 100;
  }
}

/// Servicio para obtener métricas del dashboard
class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene todas las métricas del dashboard
  Future<DashboardMetrics> getMetrics(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final mesActual = DateTime(now.year, now.month, 1);
      final mesAnterior = DateTime(now.year, now.month - 1, 1);
      final finMesAnterior = DateTime(now.year, now.month, 0, 23, 59, 59);

      // Obtener ventas de hoy
      final ventasHoyResponse = await _supabase
          .from('ventas')
          .select('monto')
          .eq('user_id', userId)
          .gte('fecha', today.toIso8601String())
          .lt('fecha', today.add(const Duration(days: 1)).toIso8601String());

      final ventasHoy = (ventasHoyResponse as List).fold<double>(
        0,
        (sum, item) => sum + (item['monto'] as num).toDouble(),
      );

      // Obtener gastos de hoy
      final gastosHoyResponse = await _supabase
          .from('gastos')
          .select('monto')
          .eq('user_id', userId)
          .gte('fecha', today.toIso8601String())
          .lt('fecha', today.add(const Duration(days: 1)).toIso8601String());

      final gastosHoy = (gastosHoyResponse as List).fold<double>(
        0,
        (sum, item) => sum + (item['monto'] as num).toDouble(),
      );

      // Obtener ventas del mes actual
      final ventasMesResponse = await _supabase
          .from('ventas')
          .select('monto')
          .eq('user_id', userId)
          .gte('fecha', mesActual.toIso8601String());

      final ventasMes = (ventasMesResponse as List).fold<double>(
        0,
        (sum, item) => sum + (item['monto'] as num).toDouble(),
      );

      // Obtener gastos del mes actual
      final gastosMesResponse = await _supabase
          .from('gastos')
          .select('monto')
          .eq('user_id', userId)
          .gte('fecha', mesActual.toIso8601String());

      final gastosMes = (gastosMesResponse as List).fold<double>(
        0,
        (sum, item) => sum + (item['monto'] as num).toDouble(),
      );

      // Obtener ventas del mes anterior
      final ventasMesAnteriorResponse = await _supabase
          .from('ventas')
          .select('monto')
          .eq('user_id', userId)
          .gte('fecha', mesAnterior.toIso8601String())
          .lte('fecha', finMesAnterior.toIso8601String());

      final ventasMesAnterior = (ventasMesAnteriorResponse as List)
          .fold<double>(
            0,
            (sum, item) => sum + (item['monto'] as num).toDouble(),
          );

      // Obtener gastos del mes anterior
      final gastosMesAnteriorResponse = await _supabase
          .from('gastos')
          .select('monto')
          .eq('user_id', userId)
          .gte('fecha', mesAnterior.toIso8601String())
          .lte('fecha', finMesAnterior.toIso8601String());

      final gastosMesAnterior = (gastosMesAnteriorResponse as List)
          .fold<double>(
            0,
            (sum, item) => sum + (item['monto'] as num).toDouble(),
          );

      // Obtener total de productos
      final productosResponse = await _supabase
          .from('productos')
          .select('id, stock, stock_minimo')
          .eq('user_id', userId)
          .eq('activo', true);

      final productos = productosResponse as List;
      final totalProductos = productos.length;
      final productosStockBajo = productos
          .where((p) => (p['stock'] as int) <= (p['stock_minimo'] as int))
          .length;

      return DashboardMetrics(
        ventasHoy: ventasHoy,
        gastosHoy: gastosHoy,
        gananciaHoy: ventasHoy - gastosHoy,
        ventasMes: ventasMes,
        gastosMes: gastosMes,
        gananciaMes: ventasMes - gastosMes,
        ventasMesAnterior: ventasMesAnterior,
        gastosMesAnterior: gastosMesAnterior,
        totalProductos: totalProductos,
        productosStockBajo: productosStockBajo,
      );
    } catch (e) {
      throw Exception('Error al obtener métricas: $e');
    }
  }

  /// Obtiene productos con stock bajo
  Future<List<Map<String, dynamic>>> getProductosStockBajo(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('productos')
          .select('id, nombre, stock, stock_minimo, precio')
          .eq('user_id', userId)
          .eq('activo', true)
          .order('stock', ascending: true);

      final productos = (response as List).cast<Map<String, dynamic>>();

      // Filtrar donde stock <= stock_minimo
      return productos
          .where((p) => (p['stock'] as int) <= (p['stock_minimo'] as int))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener productos con stock bajo: $e');
    }
  }
}
