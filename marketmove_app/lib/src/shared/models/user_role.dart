/// Enum que define los roles de usuario en la aplicación
enum UserRole {
  superadmin,
  dueno, // Dueño del negocio
  empleado; // Empleado

  /// Convierte un string a UserRole
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return UserRole.superadmin;
      case 'dueno':
      case 'dueño':
        return UserRole.dueno;
      case 'empleado':
        return UserRole.empleado;
      // Compatibilidad con roles antiguos
      case 'admin':
        return UserRole.dueno;
      case 'cliente':
        return UserRole.empleado;
      default:
        return UserRole.empleado; // Por defecto
    }
  }

  /// Convierte el UserRole a string
  String toStringValue() {
    switch (this) {
      case UserRole.superadmin:
        return 'superadmin';
      case UserRole.dueno:
        return 'dueno';
      case UserRole.empleado:
        return 'empleado';
    }
  }

  /// Verifica si el rol es superadmin
  bool get isSuperadmin => this == UserRole.superadmin;

  /// Verifica si el rol es dueño
  bool get isDueno => this == UserRole.dueno;

  /// Verifica si el rol es empleado
  bool get isEmpleado => this == UserRole.empleado;

  /// Verifica si el rol es admin (superadmin o dueño)
  bool get isAdmin => isSuperadmin || isDueno;
}
