import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/venta_model.dart';
import '../models/producto_model.dart';
import 'productos_service.dart';

/// Servicio para gestionar ventas
class VentasService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _productosService = ProductosService();

  /// Obtiene todas las ventas del usuario
  Future<List<VentaModel>> getVentas(
    String userId, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      var query = _supabase
          .from('ventas')
          .select('*, detalle_ventas(*, productos(nombre))')
          .eq('user_id', userId);

      if (desde != null) {
        query = query.gte('fecha', desde.toIso8601String());
      }
      if (hasta != null) {
        query = query.lte('fecha', hasta.toIso8601String());
      }

      final response = await query.order('fecha', ascending: false);

      return (response as List)
          .map((json) => VentaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener ventas: $e');
    }
  }

  /// Obtiene una venta específica
  Future<VentaModel> getVenta(String ventaId) async {
    try {
      final response = await _supabase
          .from('ventas')
          .select('*, detalle_ventas(*, productos(nombre))')
          .eq('id', ventaId)
          .single();

      return VentaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener venta: $e');
    }
  }

  /// Crea una nueva venta con sus detalles
  /// Actualiza automáticamente el stock de productos
  Future<VentaModel> crearVenta({
    required String userId,
    required List<DetalleVentaInput> detalles,
    MetodoPago? metodoPago,
    String? notas,
    String? clienteId,
  }) async {
    try {
      // Calcular monto total
      final montoTotal = detalles.fold<double>(
        0,
        (sum, detalle) => sum + (detalle.precioUnitario * detalle.cantidad),
      );

      // Generar concepto automático
      final cantidadProductos = detalles.fold<int>(
        0,
        (sum, d) => sum + d.cantidad,
      );
      final concepto =
          'Venta de $cantidadProductos producto${cantidadProductos != 1 ? 's' : ''}';

      // Crear la venta
      final ventaResponse = await _supabase
          .from('ventas')
          .insert({
            'user_id': userId,
            'concepto': concepto,
            'fecha': DateTime.now().toIso8601String(),
            'monto': montoTotal,
            'notas': notas,
            'metodo_pago': metodoPago?.toStringValue(),
            'cliente_id': clienteId,
          })
          .select()
          .single();

      final ventaId = ventaResponse['id'] as String;

      // Crear detalles de venta y actualizar stock
      for (final detalle in detalles) {
        // Insertar detalle (subtotal se calcula automáticamente en BD)
        await _supabase.from('detalle_ventas').insert({
          'venta_id': ventaId,
          'producto_id': detalle.productoId,
          'cantidad': detalle.cantidad,
          'precio_unitario': detalle.precioUnitario,
        });

        // Actualizar stock (restar cantidad vendida)
        await _productosService.ajustarStock(
          detalle.productoId,
          -detalle.cantidad,
        );
      }

      // Obtener la venta completa con detalles
      return await getVenta(ventaId);
    } catch (e) {
      throw Exception('Error al crear venta: $e');
    }
  }

  /// Actualiza una venta existente
  /// NOTA: No actualiza los detalles ni el stock (requiere lógica más compleja)
  Future<VentaModel> actualizarVenta({
    required String ventaId,
    MetodoPago? metodoPago,
    String? notas,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (metodoPago != null) {
        updates['metodo_pago'] = metodoPago.toStringValue();
      }
      if (notas != null) updates['notas'] = notas;

      await _supabase.from('ventas').update(updates).eq('id', ventaId);

      return await getVenta(ventaId);
    } catch (e) {
      throw Exception('Error al actualizar venta: $e');
    }
  }

  /// Elimina una venta
  /// IMPORTANTE: También devuelve el stock a los productos
  Future<void> eliminarVenta(String ventaId) async {
    try {
      // Obtener la venta con detalles
      final venta = await getVenta(ventaId);

      // Devolver stock de cada producto
      if (venta.detalles != null) {
        for (final detalle in venta.detalles!) {
          await _productosService.ajustarStock(
            detalle.productoId,
            detalle.cantidad, // Devolver el stock
          );
        }
      }

      // Eliminar venta (los detalles se eliminan en cascada)
      await _supabase.from('ventas').delete().eq('id', ventaId);
    } catch (e) {
      throw Exception('Error al eliminar venta: $e');
    }
  }

  /// Obtiene estadísticas de ventas
  Future<Map<String, dynamic>> getEstadisticas(
    String userId, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      final ventas = await getVentas(userId, desde: desde, hasta: hasta);

      final totalVentas = ventas.length;
      final montoTotal = ventas.fold<double>(0, (sum, v) => sum + v.monto);
      final promedioVenta = totalVentas > 0 ? montoTotal / totalVentas : 0.0;

      return {
        'total_ventas': totalVentas,
        'monto_total': montoTotal,
        'promedio_venta': promedioVenta,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}

/// Clase auxiliar para crear detalles de venta
class DetalleVentaInput {
  final String productoId;
  final int cantidad;
  final double precioUnitario;

  DetalleVentaInput({
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
  });
}
