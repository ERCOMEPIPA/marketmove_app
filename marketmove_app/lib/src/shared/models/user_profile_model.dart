import 'user_role.dart';

/// Modelo de perfil de usuario que extiende la información de auth.users
class UserProfileModel {
  final String id;
  final String email;
  final String? nombreNegocio;
  final String? telefono;
  final UserRole rol;
  final String? negocioId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfileModel({
    required this.id,
    required this.email,
    this.nombreNegocio,
    this.telefono,
    required this.rol,
    this.negocioId,
    this.createdAt,
    this.updatedAt,
  });

  /// Verifica si el usuario es superadmin
  bool get isSuperadmin => rol.isSuperadmin;

  /// Verifica si el usuario es dueño
  bool get isDueno => rol.isDueno;

  /// Verifica si el usuario es admin (superadmin o dueño)
  bool get isAdmin => rol.isAdmin;

  /// Crea un UserProfileModel desde un Map (JSON)
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      nombreNegocio: json['nombre_negocio'] as String?,
      telefono: json['telefono'] as String?,
      rol: UserRole.fromString(json['rol'] as String? ?? 'empleado'),
      negocioId: json['negocio_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convierte el UserProfileModel a un Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre_negocio': nombreNegocio,
      'telefono': telefono,
      'rol': rol.toStringValue(),
      'negocio_id': negocioId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Crea una copia del UserProfileModel con campos actualizados
  UserProfileModel copyWith({
    String? id,
    String? email,
    String? nombreNegocio,
    String? telefono,
    UserRole? rol,
    String? negocioId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nombreNegocio: nombreNegocio ?? this.nombreNegocio,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
      negocioId: negocioId ?? this.negocioId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfileModel(id: $id, email: $email, rol: ${rol.toStringValue()}, negocioId: $negocioId)';
  }
}
