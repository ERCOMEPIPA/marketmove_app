import 'package:flutter/material.dart';

/// Modelo para items del carrito
class CartItem {
  final String id;
  final String nombre;
  final double precio;
  int cantidad;
  final String imagen;

  CartItem({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.imagen,
  });

  double get total => precio * cantidad;
}

/// Servicio para manejar el carrito
class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get total => _items.fold(0, (sum, item) => sum + item.total);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.cantidad);

  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].cantidad += item.cantidad;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int cantidad) {
    final item = _items.firstWhere((i) => i.id == id);
    if (cantidad > 0) {
      item.cantidad = cantidad;
    } else {
      removeItem(id);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool hasItem(String id) => _items.any((item) => item.id == id);
}
