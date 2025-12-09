import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Convertir a JSON para persistencia
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
      'imagen': imagen,
    };
  }

  // Crear desde JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      cantidad: json['cantidad'] as int,
      imagen: json['imagen'] as String,
    );
  }
}

/// Servicio para manejar el carrito con persistencia
class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];
  late SharedPreferences _prefs;
  static const String _cartKey = 'cart_items';
  bool _initialized = false;

  CartService() {
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadCart();
  }

  List<CartItem> get items => _items;

  double get total => _items.fold(0, (sum, item) => sum + item.total);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.cantidad);

  // Cargar carrito desde almacenamiento local
  Future<void> _loadCart() async {
    try {
      final String? cartJson = _prefs.getString(_cartKey);
      if (cartJson != null) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _items.clear();
        _items.addAll(
          decoded.map((item) => CartItem.fromJson(item as Map<String, dynamic>)),
        );
        _initialized = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error al cargar carrito: $e');
    }
  }

  // Guardar carrito en almacenamiento local
  Future<void> _saveCart() async {
    try {
      final List<Map<String, dynamic>> itemsJson = _items.map((item) => item.toJson()).toList();
      await _prefs.setString(_cartKey, jsonEncode(itemsJson));
    } catch (e) {
      print('Error al guardar carrito: $e');
    }
  }

  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].cantidad += item.cantidad;
    } else {
      _items.add(item);
    }
    _saveCart();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String id, int cantidad) {
    final item = _items.firstWhere((i) => i.id == id);
    if (cantidad > 0) {
      item.cantidad = cantidad;
    } else {
      removeItem(id);
      return;
    }
    _saveCart();
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    await _prefs.remove(_cartKey);
    notifyListeners();
  }

  bool hasItem(String id) => _items.any((item) => item.id == id);
}
