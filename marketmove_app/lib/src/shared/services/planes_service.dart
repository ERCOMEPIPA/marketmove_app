import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

/// Tipos de facturación para planes
enum TipoFacturacion {
  mensual, // Pago cada mes
  trimestral, // Pago cada 3 meses
  unico, // Pago único (lifetime)
}

/// Exensión para TipoFacturacion
extension TipoFacturacionExtension on TipoFacturacion {
  String get label {
    switch (this) {
      case TipoFacturacion.mensual:
        return '/mes';
      case TipoFacturacion.trimestral:
        return '/trimestre';
      case TipoFacturacion.unico:
        return ' (pago único)';
    }
  }

  String get nombre {
    switch (this) {
      case TipoFacturacion.mensual:
        return 'Mensual';
      case TipoFacturacion.trimestral:
        return 'Trimestral';
      case TipoFacturacion.unico:
        return 'Pago único';
    }
  }

  static TipoFacturacion fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'trimestral':
        return TipoFacturacion.trimestral;
      case 'unico':
        return TipoFacturacion.unico;
      default:
        return TipoFacturacion.mensual;
    }
  }
}

/// Modelo de Plan de Suscripción
class PlanModel {
  final String id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int maxEmpleados;
  final int maxClientes;
  final bool activo;
  final DateTime createdAt;
  final String? stripePriceId; // ID del precio en Stripe
  final TipoFacturacion tipoFacturacion; // Tipo de facturación

  PlanModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.maxEmpleados,
    required this.maxClientes,
    required this.activo,
    required this.createdAt,
    this.stripePriceId,
    this.tipoFacturacion = TipoFacturacion.mensual,
  });

  /// Texto para mostrar el precio con su período
  String get precioLabel => tipoFacturacion.label;

  /// Si es pago único (no recurrente)
  bool get esPagoUnico => tipoFacturacion == TipoFacturacion.unico;

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      precio: (json['precio'] as num?)?.toDouble() ?? 0,
      maxEmpleados: json['max_empleados'] ?? 5,
      maxClientes: json['max_clientes'] ?? 100,
      activo: json['activo'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      stripePriceId: json['stripe_price_id'],
      tipoFacturacion: TipoFacturacionExtension.fromString(
        json['tipo_facturacion'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'max_empleados': maxEmpleados,
      'max_clientes': maxClientes,
      'activo': activo,
      'stripe_price_id': stripePriceId,
      'tipo_facturacion': tipoFacturacion.name,
    };
  }
}

/// Servicio para gestión de planes (Superadmin)
class PlanesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtener todos los planes
  Future<List<PlanModel>> getPlanes() async {
    try {
      final response = await _supabase.from('planes').select().order('precio');

      return (response as List)
          .map((json) => PlanModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener planes: $e');
    }
  }

  /// Crear un nuevo plan
  Future<PlanModel> crearPlan(PlanModel plan) async {
    try {
      final response = await _supabase
          .from('planes')
          .insert(plan.toJson())
          .select()
          .single();

      return PlanModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear plan: $e');
    }
  }

  /// Actualizar un plan
  Future<PlanModel> actualizarPlan(
    String id,
    Map<String, dynamic> datos,
  ) async {
    try {
      final response = await _supabase
          .from('planes')
          .update(datos)
          .eq('id', id)
          .select()
          .single();

      return PlanModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar plan: $e');
    }
  }

  /// Eliminar un plan
  Future<void> eliminarPlan(String id) async {
    try {
      await _supabase.from('planes').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar plan: $e');
    }
  }

  /// Asignar plan a un dueño
  Future<void> asignarPlan(String duenoId, String planId) async {
    try {
      await _supabase
          .from('perfiles')
          .update({'plan_id': planId})
          .eq('id', duenoId);
    } catch (e) {
      throw Exception('Error al asignar plan: $e');
    }
  }

  /// Obtener el plan básico (el más barato o el que se llame "Básico")
  /// Se usa para asignar automáticamente a nuevos dueños
  Future<PlanModel?> getPlanBasico() async {
    try {
      final planes = await getPlanes();
      if (planes.isEmpty) return null;

      // Buscar primero por nombre "Básico"
      final planBasico = planes
          .where(
            (p) =>
                p.nombre.toLowerCase().contains('básico') ||
                p.nombre.toLowerCase().contains('basico'),
          )
          .firstOrNull;

      if (planBasico != null) return planBasico;

      // Si no hay plan "Básico", retornar el más barato activo
      final planesActivos = planes.where((p) => p.activo).toList();
      if (planesActivos.isEmpty) return planes.first;

      planesActivos.sort((a, b) => a.precio.compareTo(b.precio));
      return planesActivos.first;
    } catch (e) {
      return null;
    }
  }

  /// Asignar plan básico a un nuevo dueño
  Future<void> asignarPlanBasico(String duenoId) async {
    try {
      final planBasico = await getPlanBasico();
      if (planBasico != null) {
        await asignarPlan(duenoId, planBasico.id);
      }
    } catch (e) {
      // Si falla, continuar sin plan (usará límites por defecto)
    }
  }
}

/// Servicio extendido para Superadmin
class SuperadminServiceExtended {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtener todos los dueños con info de plan
  Future<List<DuenoInfo>> getAllDuenos() async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select('*, plan:plan_id(nombre, precio)')
          .eq('rol', 'dueno')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DuenoInfo.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener dueños: $e');
    }
  }

  /// Obtener empleados de un dueño
  Future<List<UserProfileModel>> getEmpleadosDeDueno(String duenoId) async {
    try {
      final response = await _supabase
          .from('perfiles')
          .select()
          .eq('negocio_id', duenoId)
          .eq('rol', 'empleado')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfileModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener empleados: $e');
    }
  }

  /// Cambiar estado de suscripción
  Future<void> cambiarEstadoSuscripcion(String duenoId, String estado) async {
    try {
      await _supabase
          .from('perfiles')
          .update({'suscripcion_estado': estado})
          .eq('id', duenoId);
    } catch (e) {
      throw Exception('Error al cambiar estado: $e');
    }
  }

  /// Activar/Desactivar dueño
  Future<void> toggleActivoDueno(String duenoId, bool activo) async {
    try {
      await _supabase
          .from('perfiles')
          .update({'activo': activo})
          .eq('id', duenoId);
    } catch (e) {
      throw Exception('Error al cambiar estado: $e');
    }
  }

  /// Obtener estadísticas globales extendidas
  Future<SuperadminStats> getStats() async {
    try {
      // Contar dueños
      final duenos = await _supabase
          .from('perfiles')
          .select()
          .eq('rol', 'dueno');

      // Contar empleados
      final empleados = await _supabase
          .from('perfiles')
          .select()
          .eq('rol', 'empleado');

      // Contar clientes/leads
      int totalClientes = 0;
      try {
        final clientes = await _supabase.from('clientes').select();
        totalClientes = clientes.length;
      } catch (_) {}

      // Contar deals
      int totalDeals = 0;
      double valorDeals = 0;
      try {
        final deals = await _supabase.from('deals').select('valor');
        totalDeals = deals.length;
        for (var d in deals) {
          valorDeals += (d['valor'] as num?)?.toDouble() ?? 0;
        }
      } catch (_) {}

      // Contar actividades
      int totalActividades = 0;
      try {
        final actividades = await _supabase.from('actividades').select();
        totalActividades = actividades.length;
      } catch (_) {}

      return SuperadminStats(
        totalDuenos: duenos.length,
        totalEmpleados: empleados.length,
        totalClientes: totalClientes,
        totalDeals: totalDeals,
        valorTotalDeals: valorDeals,
        totalActividades: totalActividades,
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}

/// Modelo de información de Dueño
class DuenoInfo {
  final String id;
  final String email;
  final String? nombreNegocio;
  final String? telefono;
  final String? planNombre;
  final double? planPrecio;
  final String? suscripcionEstado;
  final bool activo;
  final DateTime? createdAt;

  DuenoInfo({
    required this.id,
    required this.email,
    this.nombreNegocio,
    this.telefono,
    this.planNombre,
    this.planPrecio,
    this.suscripcionEstado,
    required this.activo,
    this.createdAt,
  });

  factory DuenoInfo.fromJson(Map<String, dynamic> json) {
    return DuenoInfo(
      id: json['id'],
      email: json['email'] ?? '',
      nombreNegocio: json['nombre_negocio'],
      telefono: json['telefono'],
      planNombre: json['plan']?['nombre'],
      planPrecio: (json['plan']?['precio'] as num?)?.toDouble(),
      suscripcionEstado: json['suscripcion_estado'],
      activo: json['activo'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}

/// Modelo de estadísticas globales
class SuperadminStats {
  final int totalDuenos;
  final int totalEmpleados;
  final int totalClientes;
  final int totalDeals;
  final double valorTotalDeals;
  final int totalActividades;

  SuperadminStats({
    required this.totalDuenos,
    required this.totalEmpleados,
    required this.totalClientes,
    required this.totalDeals,
    required this.valorTotalDeals,
    required this.totalActividades,
  });
}
