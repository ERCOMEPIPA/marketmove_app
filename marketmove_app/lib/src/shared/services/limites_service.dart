import 'package:supabase_flutter/supabase_flutter.dart';
import 'planes_service.dart';

/// Servicio para validar límites de planes
/// Verifica que los dueños no excedan los límites de su plan
class LimitesService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PlanesService _planesService = PlanesService();

  /// Obtener información del plan actual del dueño
  Future<PlanLimites> getLimitesDueno(String duenoId) async {
    try {
      // Obtener el perfil del dueño con su plan
      final perfil = await _supabase
          .from('perfiles')
          .select('plan_id, suscripcion_estado')
          .eq('id', duenoId)
          .single();

      final planId = perfil['plan_id'] as String?;
      final estado = perfil['suscripcion_estado'] as String? ?? 'activa';

      // Si no tiene plan, usar límites por defecto (plan básico)
      if (planId == null) {
        return PlanLimites(
          planNombre: 'Sin Plan',
          maxEmpleados: 3,
          maxClientes: 50,
          empleadosActuales: await _contarEmpleados(duenoId),
          clientesActuales: await _contarClientes(duenoId),
          suscripcionActiva: estado == 'activa',
        );
      }

      // Obtener el plan
      final planes = await _planesService.getPlanes();
      final plan = planes.firstWhere(
        (p) => p.id == planId,
        orElse: () => PlanModel(
          id: '',
          nombre: 'Básico',
          precio: 0,
          maxEmpleados: 3,
          maxClientes: 50,
          activo: true,
          createdAt: DateTime.now(),
        ),
      );

      return PlanLimites(
        planNombre: plan.nombre,
        maxEmpleados: plan.maxEmpleados,
        maxClientes: plan.maxClientes,
        empleadosActuales: await _contarEmpleados(duenoId),
        clientesActuales: await _contarClientes(duenoId),
        suscripcionActiva: estado == 'activa',
      );
    } catch (e) {
      // Por defecto, límites de plan básico
      return PlanLimites(
        planNombre: 'Sin Plan',
        maxEmpleados: 3,
        maxClientes: 50,
        empleadosActuales: 0,
        clientesActuales: 0,
        suscripcionActiva: true,
      );
    }
  }

  /// Contar empleados actuales del dueño
  Future<int> _contarEmpleados(String duenoId) async {
    try {
      final empleados = await _supabase
          .from('perfiles')
          .select()
          .eq('negocio_id', duenoId)
          .eq('rol', 'empleado');
      return empleados.length;
    } catch (e) {
      return 0;
    }
  }

  /// Contar clientes actuales del dueño
  Future<int> _contarClientes(String duenoId) async {
    try {
      final clientes = await _supabase
          .from('clientes')
          .select()
          .eq('negocio_id', duenoId);
      return clientes.length;
    } catch (e) {
      return 0;
    }
  }

  /// Verificar si puede agregar más empleados
  Future<ValidacionLimite> puedeAgregarEmpleado(String duenoId) async {
    final limites = await getLimitesDueno(duenoId);

    if (!limites.suscripcionActiva) {
      return ValidacionLimite(
        permitido: false,
        mensaje: 'Tu suscripción no está activa. Contacta al administrador.',
      );
    }

    if (limites.empleadosActuales >= limites.maxEmpleados) {
      return ValidacionLimite(
        permitido: false,
        mensaje:
            'Has alcanzado el límite de ${limites.maxEmpleados} empleados de tu plan ${limites.planNombre}. Actualiza tu plan para agregar más.',
      );
    }

    return ValidacionLimite(
      permitido: true,
      mensaje:
          'Puedes agregar empleados (${limites.empleadosActuales}/${limites.maxEmpleados})',
    );
  }

  /// Verificar si puede agregar más clientes
  Future<ValidacionLimite> puedeAgregarCliente(String duenoId) async {
    final limites = await getLimitesDueno(duenoId);

    if (!limites.suscripcionActiva) {
      return ValidacionLimite(
        permitido: false,
        mensaje: 'Tu suscripción no está activa. Contacta al administrador.',
      );
    }

    if (limites.clientesActuales >= limites.maxClientes) {
      return ValidacionLimite(
        permitido: false,
        mensaje:
            'Has alcanzado el límite de ${limites.maxClientes} clientes de tu plan ${limites.planNombre}. Actualiza tu plan para agregar más.',
      );
    }

    return ValidacionLimite(
      permitido: true,
      mensaje:
          'Puedes agregar clientes (${limites.clientesActuales}/${limites.maxClientes})',
    );
  }

  /// Obtener límites del usuario actual (autenticado)
  Future<PlanLimites> getLimitesActual() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return PlanLimites(
        planNombre: 'Sin Plan',
        maxEmpleados: 0,
        maxClientes: 0,
        empleadosActuales: 0,
        clientesActuales: 0,
        suscripcionActiva: false,
      );
    }
    return getLimitesDueno(userId);
  }
}

/// Modelo con los límites del plan
class PlanLimites {
  final String planNombre;
  final int maxEmpleados;
  final int maxClientes;
  final int empleadosActuales;
  final int clientesActuales;
  final bool suscripcionActiva;

  PlanLimites({
    required this.planNombre,
    required this.maxEmpleados,
    required this.maxClientes,
    required this.empleadosActuales,
    required this.clientesActuales,
    required this.suscripcionActiva,
  });

  bool get puedeAgregarEmpleado =>
      empleadosActuales < maxEmpleados && suscripcionActiva;
  bool get puedeAgregarCliente =>
      clientesActuales < maxClientes && suscripcionActiva;

  double get porcentajeEmpleados =>
      maxEmpleados > 0 ? empleadosActuales / maxEmpleados : 0;
  double get porcentajeClientes =>
      maxClientes > 0 ? clientesActuales / maxClientes : 0;
}

/// Resultado de validación de límite
class ValidacionLimite {
  final bool permitido;
  final String mensaje;

  ValidacionLimite({required this.permitido, required this.mensaje});
}
