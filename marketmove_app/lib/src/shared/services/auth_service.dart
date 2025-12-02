import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../models/user_role.dart';

/// Servicio de autenticación que maneja login, logout y gestión de perfiles con roles
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene el usuario actualmente autenticado
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream de cambios en el estado de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Verifica si hay un usuario autenticado
  bool get isAuthenticated => currentUser != null;

  /// Inicia sesión con email y contraseña
  /// Retorna el perfil del usuario con su rol
  Future<UserProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Autenticar con Supabase
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error al iniciar sesión');
      }

      // Obtener el perfil del usuario con su rol
      final profile = await getUserProfile(response.user!.id);

      return profile;
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Registra un nuevo usuario
  /// Por defecto, los usuarios se registran como 'empleado'
  Future<UserProfileModel> signUp({
    required String email,
    required String password,
    String? nombreNegocio,
    String? telefono,
    UserRole rol = UserRole.empleado,
  }) async {
    try {
      // Crear usuario en auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Error al registrar usuario');
      }

      // Actualizar el perfil con información adicional
      await _supabase
          .from('perfiles')
          .update({
            'nombre_negocio': nombreNegocio,
            'telefono': telefono,
            'rol': rol.toStringValue(),
          })
          .eq('id', response.user!.id);

      // Obtener el perfil actualizado
      final profile = await getUserProfile(response.user!.id);

      return profile;
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  /// Obtiene el perfil del usuario por ID
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener perfil: $e');
    }
  }

  /// Obtiene el perfil del usuario actual
  Future<UserProfileModel?> getCurrentUserProfile() async {
    try {
      if (!isAuthenticated) return null;

      return await getUserProfile(currentUser!.id);
    } catch (e) {
      return null;
    }
  }

  /// Actualiza el perfil del usuario actual
  Future<void> updateProfile({String? nombreNegocio, String? telefono}) async {
    try {
      if (!isAuthenticated) {
        throw Exception('Usuario no autenticado');
      }

      final updates = <String, dynamic>{};
      if (nombreNegocio != null) updates['nombre_negocio'] = nombreNegocio;
      if (telefono != null) updates['telefono'] = telefono;

      if (updates.isEmpty) return;

      await _supabase
          .from('perfiles')
          .update(updates)
          .eq('id', currentUser!.id);
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Verifica si el usuario actual tiene rol de admin
  Future<bool> isUserAdmin() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si el usuario actual tiene rol de empleado
  Future<bool> isUserEmpleado() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.isEmpleado ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el rol del usuario actual
  Future<UserRole?> getCurrentUserRole() async {
    try {
      final profile = await getCurrentUserProfile();
      return profile?.rol;
    } catch (e) {
      return null;
    }
  }
}
