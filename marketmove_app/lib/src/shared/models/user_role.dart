/// Enum que define los roles de usuario en la aplicación
/// Roles: Superadmin (ve todo), Dueño (ve su negocio), Empleado (acceso limitado)
enum UserRole {
  superadmin,
  dueno, // Dueño del negocio
  empleado; // Empleado de un negocio

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

  /// Verifica si el rol tiene acceso admin (superadmin o dueño)
  bool get isAdmin => isSuperadmin || isDueno;

  /// Verifica si el rol puede acceder al panel de negocio (dueño o empleado)
  bool get canAccessBusiness => isDueno || isEmpleado;
}
