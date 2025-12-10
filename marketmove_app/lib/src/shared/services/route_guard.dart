import '../models/user_role.dart';
import '../services/auth_service.dart';

/// Guard para validar permisos de acceso a rutas
/// Solo existen 2 roles: Superadmin y Dueño
class RouteGuard {
  final AuthService _authService = AuthService();

  /// Valida que el usuario tenga el rol requerido
  Future<bool> hasRole(UserRole requiredRole) async {
    final userRole = await _authService.getCurrentUserRole();
    if (userRole == null) return false;

    switch (requiredRole) {
      case UserRole.superadmin:
        return userRole.isSuperadmin;
      case UserRole.dueno:
        return userRole.isDueno || userRole.isSuperadmin;
    }
  }

  /// Valida que el usuario sea admin (superadmin o dueño)
  Future<bool> isAdmin() async {
    final userRole = await _authService.getCurrentUserRole();
    return userRole?.isAdmin ?? false;
  }

  /// Valida que el usuario sea superadmin
  Future<bool> isSuperadmin() async {
    final userRole = await _authService.getCurrentUserRole();
    return userRole?.isSuperadmin ?? false;
  }

  /// Valida que el usuario sea dueño
  Future<bool> isDueno() async {
    final userRole = await _authService.getCurrentUserRole();
    return userRole?.isDueno ?? false;
  }
}
