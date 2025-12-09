import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de Cliente/Lead
class ClienteModel {
  final String id;
  final String negocioId;
  final String? empleadoAsignadoId;
  final String nombre;
  final String? email;
  final String? telefono;
  final String? empresa;
  final String? cargo;
  final String estado;
  final String? fuente;
  final List<String> etiquetas;
  final String? notas;
  final double valorEstimado;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Datos relacionados
  final String? empleadoNombre;

  ClienteModel({
    required this.id,
    required this.negocioId,
    this.empleadoAsignadoId,
    required this.nombre,
    this.email,
    this.telefono,
    this.empresa,
    this.cargo,
    required this.estado,
    this.fuente,
    this.etiquetas = const [],
    this.notas,
    this.valorEstimado = 0,
    required this.createdAt,
    required this.updatedAt,
    this.empleadoNombre,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: json['id'],
      negocioId: json['negocio_id'],
      empleadoAsignadoId: json['empleado_asignado_id'],
      nombre: json['nombre'],
      email: json['email'],
      telefono: json['telefono'],
      empresa: json['empresa'],
      cargo: json['cargo'],
      estado: json['estado'] ?? 'lead',
      fuente: json['fuente'],
      etiquetas: json['etiquetas'] != null
          ? List<String>.from(json['etiquetas'])
          : [],
      notas: json['notas'],
      valorEstimado: (json['valor_estimado'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      empleadoNombre: json['empleado']?['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'negocio_id': negocioId,
      'empleado_asignado_id': empleadoAsignadoId,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'empresa': empresa,
      'cargo': cargo,
      'estado': estado,
      'fuente': fuente,
      'etiquetas': etiquetas,
      'notas': notas,
      'valor_estimado': valorEstimado,
    };
  }

  ClienteModel copyWith({
    String? id,
    String? negocioId,
    String? empleadoAsignadoId,
    String? nombre,
    String? email,
    String? telefono,
    String? empresa,
    String? cargo,
    String? estado,
    String? fuente,
    List<String>? etiquetas,
    String? notas,
    double? valorEstimado,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      negocioId: negocioId ?? this.negocioId,
      empleadoAsignadoId: empleadoAsignadoId ?? this.empleadoAsignadoId,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      empresa: empresa ?? this.empresa,
      cargo: cargo ?? this.cargo,
      estado: estado ?? this.estado,
      fuente: fuente ?? this.fuente,
      etiquetas: etiquetas ?? this.etiquetas,
      notas: notas ?? this.notas,
      valorEstimado: valorEstimado ?? this.valorEstimado,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Estados posibles de un cliente
class EstadoCliente {
  static const String lead = 'lead';
  static const String contactado = 'contactado';
  static const String calificado = 'calificado';
  static const String cliente = 'cliente';
  static const String inactivo = 'inactivo';

  static List<String> get todos => [
    lead,
    contactado,
    calificado,
    cliente,
    inactivo,
  ];

  static String nombre(String estado) {
    switch (estado) {
      case lead:
        return 'Lead';
      case contactado:
        return 'Contactado';
      case calificado:
        return 'Calificado';
      case cliente:
        return 'Cliente';
      case inactivo:
        return 'Inactivo';
      default:
        return estado;
    }
  }
}

/// Servicio para gestionar clientes/leads
class ClientesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtener todos los clientes del negocio
  Future<List<ClienteModel>> getClientes(String negocioId) async {
    try {
      final response = await _supabase
          .from('clientes')
          .select('*, empleado:empleado_asignado_id(email)')
          .eq('negocio_id', negocioId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ClienteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  /// Obtener clientes asignados a un empleado
  Future<List<ClienteModel>> getClientesAsignados(String empleadoId) async {
    try {
      final response = await _supabase
          .from('clientes')
          .select('*, empleado:empleado_asignado_id(email)')
          .eq('empleado_asignado_id', empleadoId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ClienteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener clientes asignados: $e');
    }
  }

  /// Obtener un cliente por ID
  Future<ClienteModel> getCliente(String id) async {
    try {
      final response = await _supabase
          .from('clientes')
          .select('*, empleado:empleado_asignado_id(email)')
          .eq('id', id)
          .single();

      return ClienteModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener cliente: $e');
    }
  }

  /// Crear un nuevo cliente
  Future<ClienteModel> crearCliente(ClienteModel cliente) async {
    try {
      final response = await _supabase
          .from('clientes')
          .insert(cliente.toJson())
          .select()
          .single();

      return ClienteModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear cliente: $e');
    }
  }

  /// Actualizar un cliente
  Future<ClienteModel> actualizarCliente(
    String id,
    Map<String, dynamic> datos,
  ) async {
    try {
      datos['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('clientes')
          .update(datos)
          .eq('id', id)
          .select()
          .single();

      return ClienteModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  /// Eliminar un cliente
  Future<void> eliminarCliente(String id) async {
    try {
      await _supabase.from('clientes').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar cliente: $e');
    }
  }

  /// Asignar cliente a empleado
  Future<void> asignarEmpleado(String clienteId, String? empleadoId) async {
    try {
      await _supabase
          .from('clientes')
          .update({'empleado_asignado_id': empleadoId})
          .eq('id', clienteId);
    } catch (e) {
      throw Exception('Error al asignar empleado: $e');
    }
  }

  /// Cambiar estado del cliente
  Future<void> cambiarEstado(String clienteId, String nuevoEstado) async {
    try {
      await _supabase
          .from('clientes')
          .update({
            'estado': nuevoEstado,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', clienteId);
    } catch (e) {
      throw Exception('Error al cambiar estado: $e');
    }
  }

  /// Buscar clientes
  Future<List<ClienteModel>> buscarClientes(
    String negocioId,
    String query,
  ) async {
    try {
      final response = await _supabase
          .from('clientes')
          .select('*, empleado:empleado_asignado_id(email)')
          .eq('negocio_id', negocioId)
          .or(
            'nombre.ilike.%$query%,email.ilike.%$query%,empresa.ilike.%$query%',
          )
          .order('nombre');

      return (response as List)
          .map((json) => ClienteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar clientes: $e');
    }
  }

  /// Obtener estadísticas de clientes
  Future<Map<String, int>> getEstadisticas(String negocioId) async {
    try {
      final response = await _supabase
          .from('clientes')
          .select('estado')
          .eq('negocio_id', negocioId);

      final stats = <String, int>{};
      for (var cliente in response) {
        final estado = cliente['estado'] as String;
        stats[estado] = (stats[estado] ?? 0) + 1;
      }
      return stats;
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}
