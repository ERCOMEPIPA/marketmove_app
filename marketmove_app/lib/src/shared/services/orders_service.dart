import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Order {
  final String id;
  final List<OrderItem> items;
  final double total;
  final DateTime fecha;
  final String estado; // "Procesando", "Aceptada" o "Entregada"
  final String userId;
  final String ownerId;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.fecha,
    required this.estado,
    required this.userId,
    required this.ownerId,
  });

  factory Order.fromJson(Map<String, dynamic> json, List<OrderItem> items) {
    return Order(
      id: json['id'] as String,
      items: items,
      total: (json['total'] as num).toDouble(),
      fecha: DateTime.parse(json['created_at'] as String),
      estado: json['estado'] as String,
      userId: json['user_id'] as String,
      ownerId: json['owner_id'] as String,
    );
  }
}

class OrderItem {
  final String nombre;
  final int cantidad;
  final double precio;
  final String imagen;

  OrderItem({
    required this.nombre,
    required this.cantidad,
    required this.precio,
    required this.imagen,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      nombre: json['nombre'] as String,
      cantidad: json['cantidad'] as int,
      precio: (json['precio'] as num).toDouble(),
      imagen: json['imagen'] as String? ?? '📦',
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'cantidad': cantidad,
    'precio': precio,
    'imagen': imagen,
  };
}

class OrdersService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final List<Order> _orders = [];
  bool _isLoading = false;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;

  double get totalSpent =>
      _orders.fold(0.0, (sum, order) => sum + order.total);

  int get totalOrders => _orders.length;

  int get deliveredCount =>
      _orders.where((order) => order.estado == 'Entregada').length;

  int get processingCount =>
      _orders.where((order) => order.estado == 'Procesando').length;

  // Cargar órdenes desde Supabase
  Future<void> loadOrders(String userId, String userRole) async {
    try {
      _isLoading = true;
      notifyListeners();

      List<dynamic> data;

      if (userRole == 'empleado') {
        // Los empleados ven solo sus propias órdenes
        data = await _supabase
            .from('ordenes')
            .select('*, detalle_ordenes(*)')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
      } else if (userRole == 'dueño') {
        // Los dueños ven las órdenes de sus empleados
        data = await _supabase
            .from('ordenes')
            .select('*, detalle_ordenes(*)')
            .eq('owner_id', userId)
            .order('created_at', ascending: false);
      } else {
        data = [];
      }

      _orders.clear();
      for (var item in data) {
        final items = (item['detalle_ordenes'] as List)
            .map((x) => OrderItem.fromJson(x as Map<String, dynamic>))
            .toList();

        _orders.add(Order.fromJson(item as Map<String, dynamic>, items));
      }

      notifyListeners();
    } catch (e) {
      print('Error loading orders: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Agregar una nueva orden a Supabase
  Future<void> addOrderFromCart(
    List<Map<String, dynamic>> cartItems,
    double total,
    String userId,
    String ownerId,
  ) async {
    try {
      // Insertar la orden
      final orderResponse = await _supabase
          .from('ordenes')
          .insert({
            'user_id': userId,
            'owner_id': ownerId,
            'total': total,
            'estado': 'Procesando',
          })
          .select()
          .single();

      final orderId = orderResponse['id'] as String;

      // Insertar detalles de la orden
      for (var item in cartItems) {
        await _supabase.from('detalle_ordenes').insert({
          'orden_id': orderId,
          'nombre': item['nombre'],
          'cantidad': item['cantidad'],
          'precio': item['precio'],
          'imagen': item['imagen'],
        });
      }

      // Recargar las órdenes
      await loadOrders(userId, 'empleado');
    } catch (e) {
      print('Error adding order: $e');
      rethrow;
    }
  }

  // Actualizar estado de una orden
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('ordenes')
          .update({'estado': newStatus})
          .eq('id', orderId);

      notifyListeners();
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }
}
