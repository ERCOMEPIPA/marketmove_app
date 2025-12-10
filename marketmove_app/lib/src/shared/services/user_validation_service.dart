import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

/// Servicio para validar y asegurar la integridad de datos de usuarios
/// Solo existen 2 tipos de usuario: Superadmin y Dueño
class UserValidationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Valida que el rol de un usuario sea válido
  /// Solo se aceptan: superadmin o dueno
  Future<bool> validateUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select('rol')
          .eq('id', userId)
          .single();

      final rol = response['rol'] as String;
      return ['superadmin', 'dueno'].contains(rol.toLowerCase());
    } catch (e) {
      return false;
    }
  }

  /// Asegura que un usuario tenga acceso a un recurso
  /// Un SUPERADMIN puede acceder a todo
  /// Un DUEÑO solo puede acceder a su propio negocio
  Future<bool> canAccessResource({
    required String userId,
    required String resourceType, // 'negocio', 'catalogo', 'perfil'
    String? resourceId,
  }) async {
    try {
      final profile = await _getProfile(userId);
      if (profile == null) return false;

      switch (resourceType) {
        case 'negocio':
          // Solo SUPERADMIN y DUEÑO del negocio
          return profile.isSuperadmin || profile.id == resourceId;
        case 'catalogo':
          // Solo DUEÑO
          return profile.isDueno;
        case 'perfil':
          // Todos pueden ver su perfil
          return profile.id == userId;
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Obtiene el perfil de un usuario
  Future<UserProfileModel?> _getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfileModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Valida que un DUEÑO sea el propietario de un negocio
  Future<bool> isDuenoOfNegocio(String userId, String negocioId) async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select('id, rol')
          .eq('id', userId)
          .single();

      if (response['rol'] == 'superadmin') return true;
      return response['id'] == negocioId;
    } catch (e) {
      return false;
    }
  }

  /// Valida que un usuario pertenezca a un negocio
  Future<bool> isUserOfNegocio(String userId, String negocioId) async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select('negocio_id, rol')
          .eq('id', userId)
          .single();

      if (response['rol'] == 'superadmin') return true;
      return response['negocio_id'] == negocioId;
    } catch (e) {
      return false;
    }
  }
}
