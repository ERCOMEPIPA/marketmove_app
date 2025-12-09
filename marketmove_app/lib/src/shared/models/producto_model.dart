/// Modelo de Categoría
class CategoriaModel {
  final String id;
  final String userId;
  final String nombre;
  final String tipo; // 'producto' o 'gasto'
  final String color;
  final DateTime createdAt;

  const CategoriaModel({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.tipo,
    required this.color,
    required this.createdAt,
  });

  factory CategoriaModel.fromJson(Map<String, dynamic> json) {
    // Manejar tanto user_id como negocio_id
    final userId = json['user_id'] ?? json['negocio_id'] ?? '';
    
    return CategoriaModel(
      id: json['id'] as String,
      userId: userId as String,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String? ?? 'producto',
      color: json['color'] as String? ?? '#6366f1',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'tipo': tipo,
      'color': color,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Modelo de Producto
class ProductoModel {
  final String id;
  final String userId;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;
  final int stockMinimo;
  final String? categoriaId;
  final String? codigoBarras;
  final String? imagenUrl;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Campos relacionados (no en BD)
  final CategoriaModel? categoria;

  const ProductoModel({
    required this.id,
    required this.userId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
    required this.stockMinimo,
    this.categoriaId,
    this.codigoBarras,
    this.imagenUrl,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
    this.categoria,
  });

  bool get stockBajo => stock <= stockMinimo;

  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    // Manejar tanto user_id como negocio_id
    final userId = json['user_id'] ?? json['negocio_id'] ?? '';
    
    return ProductoModel(
      id: json['id'] as String,
      userId: userId as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precio: (json['precio'] as num).toDouble(),
      stock: json['stock'] as int,
      stockMinimo: json['stock_minimo'] as int? ?? 10,
      categoriaId: json['categoria_id'] as String?,
      codigoBarras: json['codigo_barras'] as String?,
      imagenUrl: json['imagen_url'] as String?,
      activo: json['activo'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      categoria: json['categorias'] != null
          ? CategoriaModel.fromJson(json['categorias'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'stock': stock,
      'stock_minimo': stockMinimo,
      'categoria_id': categoriaId,
      'codigo_barras': codigoBarras,
      'imagen_url': imagenUrl,
      'activo': activo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProductoModel copyWith({
    String? id,
    String? userId,
    String? nombre,
    String? descripcion,
    double? precio,
    int? stock,
    int? stockMinimo,
    String? categoriaId,
    String? codigoBarras,
    String? imagenUrl,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
    CategoriaModel? categoria,
  }) {
    return ProductoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      categoriaId: categoriaId ?? this.categoriaId,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoria: categoria ?? this.categoria,
    );
  }
}
