import '../models/venta_model.dart'; // For MetodoPago

/// Modelo de gasto
class GastoModel {
  final String id;
  final String userId;
  final String concepto;
  final double monto;
  final DateTime fecha;
  final String? notas;
  final String? categoriaId;
  final MetodoPago? metodoPago;
  final String? fotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Categoría relacionada (no en BD)
  final String? categoriaNombre;

  const GastoModel({
    required this.id,
    required this.userId,
    required this.concepto,
    required this.monto,
    required this.fecha,
    this.notas,
    this.categoriaId,
    this.metodoPago,
    this.fotoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.categoriaNombre,
  });

  factory GastoModel.fromJson(Map<String, dynamic> json) {
    return GastoModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      concepto: json['concepto'] as String,
      monto: (json['monto'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String),
      notas: json['notas'] as String?,
      categoriaId: json['categoria_id'] as String?,
      metodoPago: json['metodo_pago'] != null
          ? MetodoPago.fromString(json['metodo_pago'] as String)
          : null,
      fotoUrl: json['foto_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      categoriaNombre: json['categorias'] != null
          ? json['categorias']['nombre'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'concepto': concepto,
      'monto': monto,
      'fecha': fecha.toIso8601String(),
      'notas': notas,
      'categoria_id': categoriaId,
      'metodo_pago': metodoPago?.toStringValue(),
      'foto_url': fotoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
