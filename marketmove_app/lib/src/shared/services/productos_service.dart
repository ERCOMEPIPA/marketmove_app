import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto_model.dart';

/// Servicio para gestionar productos
class ProductosService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene todos los productos del usuario
  Future<List<ProductoModel>> getProductos(
    String userId, {
    bool soloActivos = false,
  }) async {
    try {
      final query = _supabase
          .from('productos')
          .select('*, categorias(*)')
          .eq('user_id', userId);

      final response = soloActivos
          ? await query.eq('activo', true).order('nombre', ascending: true)
          : await query.order('nombre', ascending: true);

      final productos = (response as List)
          .map((json) => ProductoModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return productos;
    } catch (e) {
      throw Exception('Error al obtener productos: $e');
    }
  }

  /// Busca productos por nombre o código de barras
  Future<List<ProductoModel>> buscarProductos(
    String userId,
    String query,
  ) async {
    try {
      // Buscar por nombre usando ilike
      final responseNombre = await _supabase
          .from('productos')
          .select('*, categorias(*)')
          .eq('user_id', userId)
          .ilike('nombre', '%$query%');

      // Buscar por código de barras usando ilike
      final responseBarras = await _supabase
          .from('productos')
          .select('*, categorias(*)')
          .eq('user_id', userId)
          .ilike('codigo_barras', '%$query%');

      // Combinar resultados y eliminar duplicados
      final productosMap = <String, ProductoModel>{};

      for (final json in responseNombre as List) {
        final producto = ProductoModel.fromJson(json as Map<String, dynamic>);
        productosMap[producto.id] = producto;
      }

      for (final json in responseBarras as List) {
        final producto = ProductoModel.fromJson(json as Map<String, dynamic>);
        productosMap[producto.id] = producto;
      }

      final productos = productosMap.values.toList();
      productos.sort((a, b) => a.nombre.compareTo(b.nombre));

      return productos;
    } catch (e) {
      throw Exception('Error al buscar productos: $e');
    }
  }

  /// Obtiene un producto por ID
  Future<ProductoModel> getProducto(String productoId) async {
    try {
      final response = await _supabase
          .from('productos')
          .select('*, categorias(*)')
          .eq('id', productoId)
          .single();

      return ProductoModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener producto: $e');
    }
  }

  /// Crea un nuevo producto
  Future<ProductoModel> crearProducto({
    required String userId,
    required String nombre,
    String? descripcion,
    required double precio,
    required int stock,
    int stockMinimo = 10,
    String? categoriaId,
    String? codigoBarras,
    String? imagenUrl,
  }) async {
    try {
      final response = await _supabase
          .from('productos')
          .insert({
            'user_id': userId,
            'nombre': nombre,
            'descripcion': descripcion,
            'precio': precio,
            'stock': stock,
            'stock_minimo': stockMinimo,
            'categoria_id': categoriaId,
            'codigo_barras': codigoBarras,
            'imagen_url': imagenUrl,
            'activo': true,
          })
          .select('*, categorias(*)')
          .single();

      return ProductoModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear producto: $e');
    }
  }

  /// Actualiza un producto
  Future<ProductoModel> actualizarProducto({
    required String productoId,
    String? nombre,
    String? descripcion,
    double? precio,
    int? stock,
    int? stockMinimo,
    String? categoriaId,
    String? codigoBarras,
    String? imagenUrl,
    bool? activo,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (nombre != null) updates['nombre'] = nombre;
      if (descripcion != null) updates['descripcion'] = descripcion;
      if (precio != null) updates['precio'] = precio;
      if (stock != null) updates['stock'] = stock;
      if (stockMinimo != null) updates['stock_minimo'] = stockMinimo;
      if (categoriaId != null) updates['categoria_id'] = categoriaId;
      if (codigoBarras != null) updates['codigo_barras'] = codigoBarras;
      if (imagenUrl != null) updates['imagen_url'] = imagenUrl;
      if (activo != null) updates['activo'] = activo;

      final response = await _supabase
          .from('productos')
          .update(updates)
          .eq('id', productoId)
          .select('*, categorias(*)')
          .single();

      return ProductoModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar producto: $e');
    }
  }

  /// Elimina un producto (soft delete - marca como inactivo)
  Future<void> eliminarProducto(String productoId) async {
    try {
      await _supabase
          .from('productos')
          .update({'activo': false})
          .eq('id', productoId);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  /// Elimina permanentemente un producto
  Future<void> eliminarProductoPermanente(String productoId) async {
    try {
      await _supabase.from('productos').delete().eq('id', productoId);
    } catch (e) {
      throw Exception('Error al eliminar producto permanentemente: $e');
    }
  }

  /// Ajusta el stock de un producto
  Future<void> ajustarStock(String productoId, int cantidad) async {
    try {
      // Obtener stock actual
      final producto = await getProducto(productoId);
      final nuevoStock = producto.stock + cantidad;

      if (nuevoStock < 0) {
        throw Exception('Stock no puede ser negativo');
      }

      await actualizarProducto(productoId: productoId, stock: nuevoStock);
    } catch (e) {
      throw Exception('Error al ajustar stock: $e');
    }
  }

  /// Obtiene categorías de productos
  Future<List<CategoriaModel>> getCategorias(String userId) async {
    try {
      final response = await _supabase
          .from('categorias')
          .select()
          .eq('user_id', userId)
          .eq('tipo', 'producto')
          .order('nombre', ascending: true);

      return (response as List)
          .map((json) => CategoriaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener categorías: $e');
    }
  }

  /// Crea una nueva categoría
  Future<CategoriaModel> crearCategoria({
    required String userId,
    required String nombre,
    String color = '#6366f1',
  }) async {
    try {
      final response = await _supabase
          .from('categorias')
          .insert({
            'user_id': userId,
            'nombre': nombre,
            'tipo': 'producto',
            'color': color,
          })
          .select()
          .single();

      return CategoriaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }
}
