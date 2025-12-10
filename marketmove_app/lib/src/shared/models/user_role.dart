/// Enum que define los roles de usuario en la aplicación
/// Solo existen 2 roles: Superadmin (ve todo) y Dueño (ve solo lo suyo)
enum UserRole {
  superadmin,
  dueno; // Dueño del negocio

  /// Convierte un string a UserRole
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return UserRole.superadmin;
      case 'dueno':
      case 'dueño':
        return UserRole.dueno;
      // Compatibilidad con roles antiguos (todos mapean a dueno)
      case 'admin':
      case 'empleado':
      case 'cliente':
        return UserRole.dueno;
      default:
        return UserRole.dueno; // Por defecto
    }
  }

  /// Convierte el UserRole a string
  String toStringValue() {
    switch (this) {
      case UserRole.superadmin:
        return 'superadmin';
      case UserRole.dueno:
        return 'dueno';
    }
  }

  /// Verifica si el rol es superadmin
  bool get isSuperadmin => this == UserRole.superadmin;

  /// Verifica si el rol es dueño
  bool get isDueno => this == UserRole.dueno;

  /// Verifica si el rol es admin (superadmin o dueño)
  bool get isAdmin => isSuperadmin || isDueno;
}
