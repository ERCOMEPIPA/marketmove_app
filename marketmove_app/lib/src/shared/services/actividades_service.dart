import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de Actividad
class ActividadModel {
  final String id;
  final String negocioId;
  final String empleadoId;
  final String? clienteId;
  final String? dealId;
  final String tipo;
  final String titulo;
  final String? descripcion;
  final DateTime? fechaProgramada;
  final DateTime? fechaCompletada;
  final int? duracionMinutos;
  final bool completada;
  final String? resultado;
  final DateTime createdAt;

  // Datos relacionados
  final String? clienteNombre;
  final String? dealTitulo;

  ActividadModel({
    required this.id,
    required this.negocioId,
    required this.empleadoId,
    this.clienteId,
    this.dealId,
    required this.tipo,
    required this.titulo,
    this.descripcion,
    this.fechaProgramada,
    this.fechaCompletada,
    this.duracionMinutos,
    this.completada = false,
    this.resultado,
    required this.createdAt,
    this.clienteNombre,
    this.dealTitulo,
  });

  factory ActividadModel.fromJson(Map<String, dynamic> json) {
    return ActividadModel(
      id: json['id'],
      negocioId: json['negocio_id'],
      empleadoId: json['empleado_id'],
      clienteId: json['cliente_id'],
      dealId: json['deal_id'],
      tipo: json['tipo'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fechaProgramada: json['fecha_programada'] != null
          ? DateTime.parse(json['fecha_programada'])
          : null,
      fechaCompletada: json['fecha_completada'] != null
          ? DateTime.parse(json['fecha_completada'])
          : null,
      duracionMinutos: json['duracion_minutos'],
      completada: json['completada'] ?? false,
      resultado: json['resultado'],
      createdAt: DateTime.parse(json['created_at']),
      clienteNombre: json['cliente']?['nombre'],
      dealTitulo: json['deal']?['titulo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'negocio_id': negocioId,
      'empleado_id': empleadoId,
      'cliente_id': clienteId,
      'deal_id': dealId,
      'tipo': tipo,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_programada': fechaProgramada?.toIso8601String(),
      'duracion_minutos': duracionMinutos,
    };
  }
}

/// Tipos de actividades
class TipoActividad {
  static const String llamada = 'llamada';
  static const String email = 'email';
  static const String reunion = 'reunion';
  static const String nota = 'nota';
  static const String tarea = 'tarea';

  static List<String> get todos => [llamada, email, reunion, nota, tarea];

  static String nombre(String tipo) {
    switch (tipo) {
      case llamada:
        return 'Llamada';
      case email:
        return 'Email';
      case reunion:
        return 'Reunión';
      case nota:
        return 'Nota';
      case tarea:
        return 'Tarea';
      default:
        return tipo;
    }
  }

  static String icono(String tipo) {
    switch (tipo) {
      case llamada:
        return '📞';
      case email:
        return '📧';
      case reunion:
        return '📅';
      case nota:
        return '📝';
      case tarea:
        return '✅';
      default:
        return '📋';
    }
  }
}

/// Servicio para gestionar actividades
class ActividadesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtener actividades del negocio
  Future<List<ActividadModel>> getActividades(String negocioId) async {
    try {
      final response = await _supabase
          .from('actividades')
          .select('*, cliente:cliente_id(nombre), deal:deal_id(titulo)')
          .eq('negocio_id', negocioId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ActividadModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener actividades: $e');
    }
  }

  /// Obtener actividades de un empleado
  Future<List<ActividadModel>> getActividadesEmpleado(String empleadoId) async {
    try {
      final response = await _supabase
          .from('actividades')
          .select('*, cliente:cliente_id(nombre), deal:deal_id(titulo)')
          .eq('empleado_id', empleadoId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ActividadModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener actividades: $e');
    }
  }

  /// Obtener actividades de un cliente
  Future<List<ActividadModel>> getActividadesCliente(String clienteId) async {
    try {
      final response = await _supabase
          .from('actividades')
          .select('*, deal:deal_id(titulo)')
          .eq('cliente_id', clienteId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ActividadModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener actividades del cliente: $e');
    }
  }

  /// Obtener actividades de un deal
  Future<List<ActividadModel>> getActividadesDeal(String dealId) async {
    try {
      final response = await _supabase
          .from('actividades')
          .select('*, cliente:cliente_id(nombre)')
          .eq('deal_id', dealId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ActividadModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener actividades del deal: $e');
    }
  }

  /// Obtener tareas pendientes
  Future<List<ActividadModel>> getTareasPendientes(String empleadoId) async {
    try {
      final response = await _supabase
          .from('actividades')
          .select('*, cliente:cliente_id(nombre), deal:deal_id(titulo)')
          .eq('empleado_id', empleadoId)
          .eq('completada', false)
          .order('fecha_programada');

      return (response as List)
          .map((json) => ActividadModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener tareas pendientes: $e');
    }
  }

  /// Crear una nueva actividad
  Future<ActividadModel> crearActividad(ActividadModel actividad) async {
    try {
      final response = await _supabase
          .from('actividades')
          .insert(actividad.toJson())
          .select()
          .single();

      return ActividadModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear actividad: $e');
    }
  }

  /// Registrar llamada rápida
  Future<ActividadModel> registrarLlamada({
    required String negocioId,
    required String empleadoId,
    required String clienteId,
    String? dealId,
    required String titulo,
    String? descripcion,
    int? duracionMinutos,
    String? resultado,
  }) async {
    try {
      final response = await _supabase
          .from('actividades')
          .insert({
            'negocio_id': negocioId,
            'empleado_id': empleadoId,
            'cliente_id': clienteId,
            'deal_id': dealId,
            'tipo': TipoActividad.llamada,
            'titulo': titulo,
            'descripcion': descripcion,
            'duracion_minutos': duracionMinutos,
            'resultado': resultado,
            'completada': true,
            'fecha_completada': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ActividadModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al registrar llamada: $e');
    }
  }

  /// Marcar actividad como completada
  Future<void> completarActividad(String id, String? resultado) async {
    try {
      await _supabase
          .from('actividades')
          .update({
            'completada': true,
            'fecha_completada': DateTime.now().toIso8601String(),
            'resultado': resultado,
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al completar actividad: $e');
    }
  }

  /// Eliminar actividad
  Future<void> eliminarActividad(String id) async {
    try {
      await _supabase.from('actividades').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar actividad: $e');
    }
  }

  /// Obtener estadísticas de actividades
  Future<ActividadStats> getEstadisticas(
    String empleadoId, {
    DateTime? desde,
  }) async {
    try {
      var query = _supabase
          .from('actividades')
          .select('tipo, completada')
          .eq('empleado_id', empleadoId);

      if (desde != null) {
        query = query.gte('created_at', desde.toIso8601String());
      }

      final response = await query;

      int llamadas = 0;
      int emails = 0;
      int reuniones = 0;
      int tareas = 0;
      int completadas = 0;

      for (var act in response) {
        switch (act['tipo']) {
          case TipoActividad.llamada:
            llamadas++;
            break;
          case TipoActividad.email:
            emails++;
            break;
          case TipoActividad.reunion:
            reuniones++;
            break;
          case TipoActividad.tarea:
            tareas++;
            break;
        }
        if (act['completada'] == true) completadas++;
      }

      return ActividadStats(
        totalActividades: response.length,
        llamadas: llamadas,
        emails: emails,
        reuniones: reuniones,
        tareas: tareas,
        completadas: completadas,
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}

/// Modelo para estadísticas de actividades
class ActividadStats {
  final int totalActividades;
  final int llamadas;
  final int emails;
  final int reuniones;
  final int tareas;
  final int completadas;

  ActividadStats({
    required this.totalActividades,
    required this.llamadas,
    required this.emails,
    required this.reuniones,
    required this.tareas,
    required this.completadas,
  });

  int get pendientes => totalActividades - completadas;
}
