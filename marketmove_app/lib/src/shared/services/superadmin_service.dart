import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

/// Servicio exclusivo para Superadmin
/// Permite gestionar y ver todos los negocios registrados
class SuperadminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene todos los perfiles de tipo ADMIN (negocios registrados)
  Future<List<UserProfileModel>> getAllAdmins() async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select()
          .eq('rol', 'admin')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfileModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener lista de admins: $e');
    }
  }

  /// Obtiene métricas generales de todos los negocios
  Future<GlobalMetrics> getGlobalMetrics() async {
    try {
      // Total de negocios (admins)
      final adminsCount = await _supabase
          .from('perfiles')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('rol', 'admin');

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
      final productosCount = await _supabase
          .from('productos')
          .select('id', const FetchOptions(count: CountOption.exact));

      return GlobalMetrics(
        totalNegocios: adminsCount.count ?? 0,
        totalVentasGlobales: ventasTotal,
        totalProductos: productosCount.count ?? 0,
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

      final productosCount = await _supabase
          .from('productos')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('user_id', adminId);

      return BusinessDetails(
        profile: UserProfileModel.fromJson(profile),
        totalVentas: ventasTotal,
        totalProductos: productosCount.count ?? 0,
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
