/// Enum para métodos de pago
enum MetodoPago {
  efectivo,
  tarjetaDebito,
  tarjetaCredito,
  transferencia,
  otro;

  String get displayName {
    switch (this) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.tarjetaDebito:
        return 'Tarjeta de Débito';
      case MetodoPago.tarjetaCredito:
        return 'Tarjeta de Crédito';
      case MetodoPago.transferencia:
        return 'Transferencia';
      case MetodoPago.otro:
        return 'Otro';
    }
  }

  static MetodoPago fromString(String value) {
    switch (value.toLowerCase()) {
      case 'efectivo':
        return MetodoPago.efectivo;
      case 'tarjeta_debito':
        return MetodoPago.tarjetaDebito;
      case 'tarjeta_credito':
        return MetodoPago.tarjetaCredito;
      case 'transferencia':
        return MetodoPago.transferencia;
      default:
        return MetodoPago.otro;
    }
  }

  String toStringValue() {
    switch (this) {
      case MetodoPago.efectivo:
        return 'efectivo';
      case MetodoPago.tarjetaDebito:
        return 'tarjeta_debito';
      case MetodoPago.tarjetaCredito:
        return 'tarjeta_credito';
      case MetodoPago.transferencia:
        return 'transferencia';
      case MetodoPago.otro:
        return 'otro';
    }
  }
}

/// Modelo de detalle de venta (producto vendido)
class DetalleVentaModel {
  final String id;
  final String ventaId;
  final String productoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  // Información del producto (no en BD)
  final String? productoNombre;

  const DetalleVentaModel({
    required this.id,
    required this.ventaId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.productoNombre,
  });

  factory DetalleVentaModel.fromJson(Map<String, dynamic> json) {
    return DetalleVentaModel(
      id: json['id'] as String,
      ventaId: json['venta_id'] as String,
      productoId: json['producto_id'] as String,
      cantidad: json['cantidad'] as int,
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      productoNombre: json['productos'] != null
          ? json['productos']['nombre'] as String?
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venta_id': ventaId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }
}

/// Modelo de venta
class VentaModel {
  final String id;
  final String userId;
  final DateTime fecha;
  final double monto;
  final String? notas;
  final MetodoPago? metodoPago;
  final String? clienteId;
  final DateTime createdAt;

  // Detalles de la venta (no en BD principal)
  final List<DetalleVentaModel>? detalles;

  const VentaModel({
    required this.id,
    required this.userId,
    required this.fecha,
    required this.monto,
    this.notas,
    this.metodoPago,
    this.clienteId,
    required this.createdAt,
    this.detalles,
  });

  factory VentaModel.fromJson(Map<String, dynamic> json) {
    List<DetalleVentaModel>? detalles;
    if (json['detalle_ventas'] != null) {
      detalles = (json['detalle_ventas'] as List)
          .map((d) => DetalleVentaModel.fromJson(d as Map<String, dynamic>))
          .toList();
    }

    return VentaModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      monto: (json['monto'] as num).toDouble(),
      notas: json['notas'] as String?,
      metodoPago: json['metodo_pago'] != null
          ? MetodoPago.fromString(json['metodo_pago'] as String)
          : null,
      clienteId: json['cliente_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      detalles: detalles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'fecha': fecha.toIso8601String(),
      'monto': monto,
      'notas': notas,
      'metodo_pago': metodoPago?.toStringValue(),
      'cliente_id': clienteId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
