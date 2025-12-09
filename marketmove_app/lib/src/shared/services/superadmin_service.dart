import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

/// Servicio exclusivo para Superadmin
/// Permite gestionar y ver todos los dueños (negocio registrados)
class SuperadminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene todos los perfiles de tipo DUEÑO (dueños de negocios registrados)
  Future<List<UserProfileModel>> getAllAdmins() async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select()
          .eq('rol', 'dueno')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfileModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener lista de dueños: $e');
    }
  }

  /// Obtiene métricas generales de todos los negocios
  Future<GlobalMetrics> getGlobalMetrics() async {
    try {
      // Total de negocios (dueños)
      final duenosResponse = await _supabase
          .from('perfiles')
          .select()
          .eq('rol', 'dueno');

      final adminsCount = duenosResponse.length;

      // Total de ventas globales
      final ventasTotal = await _supabase.from('ventas').select('monto').then((
        data,
      ) {
        double total = 0;
        for (var venta in data) {
          total += (venta['monto'] as num).toDouble();
        }
        return total;
      });

      // Total de productos en todos los negocios
      final productosResponse = await _supabase
          .from('productos')
          .select();

      final productosCount = productosResponse.length;

      return GlobalMetrics(
        totalNegocios: adminsCount,
        totalVentasGlobales: ventasTotal,
        totalProductos: productosCount,
      );
    } catch (e) {
      throw Exception('Error al obtener métricas globales: $e');
    }
  }

  /// Obtiene detalles de un negocio específico (admin)
  Future<BusinessDetails> getBusinessDetails(String adminId) async {
    try {
      // Perfil del admin
      final profile = await _supabase
          .from('perfiles')
          .select()
          .eq('id', adminId)
          .single();

      // Estadísticas del negocio
      final ventasTotal = await _supabase
          .from('ventas')
          .select('monto')
          .eq('user_id', adminId)
          .then((data) {
            double total = 0;
            for (var venta in data) {
              total += (venta['monto'] as num).toDouble();
            }
            return total;
          });

      final productosResponse = await _supabase
          .from('productos')
          .select()
          .eq('user_id', adminId);

      final productosCount = productosResponse.length;

      return BusinessDetails(
        profile: UserProfileModel.fromJson(profile),
        totalVentas: ventasTotal,
        totalProductos: productosCount,
      );
    } catch (e) {
      throw Exception('Error al obtener detalles del negocio: $e');
    }
  }
}

/// Modelo para métricas globales
class GlobalMetrics {
  final int totalNegocios;
  final double totalVentasGlobales;
  final int totalProductos;

  GlobalMetrics({
    required this.totalNegocios,
    required this.totalVentasGlobales,
    required this.totalProductos,
  });
}

/// Modelo para detalles de un negocio
class BusinessDetails {
  final UserProfileModel profile;
  final double totalVentas;
  final int totalProductos;

  BusinessDetails({
    required this.profile,
    required this.totalVentas,
    required this.totalProductos,
  });
}
