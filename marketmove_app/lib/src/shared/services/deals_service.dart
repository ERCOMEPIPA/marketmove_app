import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de Deal/Oportunidad
class DealModel {
  final String id;
  final String negocioId;
  final String? clienteId;
  final String? empleadoAsignadoId;
  final String titulo;
  final String? descripcion;
  final double valor;
  final String etapa;
  final int probabilidad;
  final DateTime? fechaCierreEstimada;
  final DateTime? fechaCierreReal;
  final String? motivoPerdida;
  final String? notas;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Datos relacionados
  final String? clienteNombre;
  final String? empleadoNombre;

  DealModel({
    required this.id,
    required this.negocioId,
    this.clienteId,
    this.empleadoAsignadoId,
    required this.titulo,
    this.descripcion,
    this.valor = 0,
    required this.etapa,
    this.probabilidad = 10,
    this.fechaCierreEstimada,
    this.fechaCierreReal,
    this.motivoPerdida,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
    this.clienteNombre,
    this.empleadoNombre,
  });

  factory DealModel.fromJson(Map<String, dynamic> json) {
    return DealModel(
      id: json['id'],
      negocioId: json['negocio_id'],
      clienteId: json['cliente_id'],
      empleadoAsignadoId: json['empleado_asignado_id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      valor: (json['valor'] as num?)?.toDouble() ?? 0,
      etapa: json['etapa'] ?? 'prospecto',
      probabilidad: json['probabilidad'] ?? 10,
      fechaCierreEstimada: json['fecha_cierre_estimada'] != null
          ? DateTime.parse(json['fecha_cierre_estimada'])
          : null,
      fechaCierreReal: json['fecha_cierre_real'] != null
          ? DateTime.parse(json['fecha_cierre_real'])
          : null,
      motivoPerdida: json['motivo_perdida'],
      notas: json['notas'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      clienteNombre: json['cliente']?['nombre'],
      empleadoNombre: json['empleado']?['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'negocio_id': negocioId,
      'cliente_id': clienteId,
      'empleado_asignado_id': empleadoAsignadoId,
      'titulo': titulo,
      'descripcion': descripcion,
      'valor': valor,
      'etapa': etapa,
      'probabilidad': probabilidad,
      'fecha_cierre_estimada': fechaCierreEstimada?.toIso8601String(),
      'notas': notas,
    };
  }

  DealModel copyWith({
    String? titulo,
    String? descripcion,
    double? valor,
    String? etapa,
    int? probabilidad,
    String? clienteId,
    String? empleadoAsignadoId,
    DateTime? fechaCierreEstimada,
    String? notas,
  }) {
    return DealModel(
      id: id,
      negocioId: negocioId,
      clienteId: clienteId ?? this.clienteId,
      empleadoAsignadoId: empleadoAsignadoId ?? this.empleadoAsignadoId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      valor: valor ?? this.valor,
      etapa: etapa ?? this.etapa,
      probabilidad: probabilidad ?? this.probabilidad,
      fechaCierreEstimada: fechaCierreEstimada ?? this.fechaCierreEstimada,
      fechaCierreReal: fechaCierreReal,
      motivoPerdida: motivoPerdida,
      notas: notas ?? this.notas,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Valor ponderado (valor * probabilidad / 100)
  double get valorPonderado => valor * probabilidad / 100;
}

/// Etapas del pipeline por defecto
class EtapasPipeline {
  static const String prospecto = 'prospecto';
  static const String calificado = 'calificado';
  static const String propuesta = 'propuesta';
  static const String negociacion = 'negociacion';
  static const String ganado = 'ganado';
  static const String perdido = 'perdido';

  static List<String> get todas => [
    prospecto,
    calificado,
    propuesta,
    negociacion,
    ganado,
    perdido,
  ];
  static List<String> get activas => [
    prospecto,
    calificado,
    propuesta,
    negociacion,
  ];

  static String nombre(String etapa) {
    switch (etapa) {
      case prospecto:
        return 'Prospecto';
      case calificado:
        return 'Calificado';
      case propuesta:
        return 'Propuesta';
      case negociacion:
        return 'Negociación';
      case ganado:
        return 'Ganado';
      case perdido:
        return 'Perdido';
      default:
        return etapa;
    }
  }

  static int probabilidadDefecto(String etapa) {
    switch (etapa) {
      case prospecto:
        return 10;
      case calificado:
        return 30;
      case propuesta:
        return 50;
      case negociacion:
        return 70;
      case ganado:
        return 100;
      case perdido:
        return 0;
      default:
        return 0;
    }
  }

  static String color(String etapa) {
    switch (etapa) {
      case prospecto:
        return '#9CA3AF';
      case calificado:
        return '#3B82F6';
      case propuesta:
        return '#8B5CF6';
      case negociacion:
        return '#F59E0B';
      case ganado:
        return '#10B981';
      case perdido:
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }
}

/// Servicio para gestionar deals/oportunidades
class DealsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtener todos los deals del negocio
  Future<List<DealModel>> getDeals(String negocioId) async {
    try {
      final response = await _supabase
          .from('deals')
          .select(
            '*, cliente:cliente_id(nombre), empleado:empleado_asignado_id(email)',
          )
          .eq('negocio_id', negocioId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DealModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener deals: $e');
    }
  }

  /// Obtener deals asignados a un empleado
  Future<List<DealModel>> getDealsAsignados(String empleadoId) async {
    try {
      final response = await _supabase
          .from('deals')
          .select(
            '*, cliente:cliente_id(nombre), empleado:empleado_asignado_id(email)',
          )
          .eq('empleado_asignado_id', empleadoId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DealModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener deals asignados: $e');
    }
  }

  /// Obtener deals por etapa
  Future<Map<String, List<DealModel>>> getDealsPorEtapa(
    String negocioId,
  ) async {
    try {
      final deals = await getDeals(negocioId);
      final porEtapa = <String, List<DealModel>>{};

      for (var etapa in EtapasPipeline.todas) {
        porEtapa[etapa] = deals.where((d) => d.etapa == etapa).toList();
      }

      return porEtapa;
    } catch (e) {
      throw Exception('Error al obtener deals por etapa: $e');
    }
  }

  /// Crear un nuevo deal
  Future<DealModel> crearDeal(DealModel deal) async {
    try {
      final response = await _supabase
          .from('deals')
          .insert(deal.toJson())
          .select()
          .single();

      return DealModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear deal: $e');
    }
  }

  /// Actualizar un deal
  Future<DealModel> actualizarDeal(
    String id,
    Map<String, dynamic> datos,
  ) async {
    try {
      datos['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('deals')
          .update(datos)
          .eq('id', id)
          .select()
          .single();

      return DealModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al actualizar deal: $e');
    }
  }

  /// Mover deal a otra etapa
  Future<void> moverEtapa(String dealId, String nuevaEtapa) async {
    try {
      final datos = {
        'etapa': nuevaEtapa,
        'probabilidad': EtapasPipeline.probabilidadDefecto(nuevaEtapa),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nuevaEtapa == EtapasPipeline.ganado ||
          nuevaEtapa == EtapasPipeline.perdido) {
        datos['fecha_cierre_real'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('deals').update(datos).eq('id', dealId);
    } catch (e) {
      throw Exception('Error al mover deal: $e');
    }
  }

  /// Cerrar deal como ganado
  Future<void> cerrarGanado(String dealId) async {
    await moverEtapa(dealId, EtapasPipeline.ganado);
  }

  /// Cerrar deal como perdido
  Future<void> cerrarPerdido(String dealId, String motivo) async {
    try {
      await _supabase
          .from('deals')
          .update({
            'etapa': EtapasPipeline.perdido,
            'probabilidad': 0,
            'fecha_cierre_real': DateTime.now().toIso8601String(),
            'motivo_perdida': motivo,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', dealId);
    } catch (e) {
      throw Exception('Error al cerrar deal: $e');
    }
  }

  /// Eliminar un deal
  Future<void> eliminarDeal(String id) async {
    try {
      await _supabase.from('deals').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar deal: $e');
    }
  }

  /// Obtener estadísticas del pipeline
  Future<PipelineStats> getEstadisticas(String negocioId) async {
    try {
      final deals = await getDeals(negocioId);

      double totalValor = 0;
      double valorPonderado = 0;
      int ganados = 0;
      int perdidos = 0;
      double valorGanado = 0;

      for (var deal in deals) {
        totalValor += deal.valor;
        valorPonderado += deal.valorPonderado;

        if (deal.etapa == EtapasPipeline.ganado) {
          ganados++;
          valorGanado += deal.valor;
        } else if (deal.etapa == EtapasPipeline.perdido) {
          perdidos++;
        }
      }

      final cerrados = ganados + perdidos;
      final tasaConversion = cerrados > 0 ? (ganados / cerrados * 100) : 0.0;

      return PipelineStats(
        totalDeals: deals.length,
        totalValor: totalValor,
        valorPonderado: valorPonderado,
        dealsGanados: ganados,
        dealsPerdidos: perdidos,
        valorGanado: valorGanado,
        tasaConversion: tasaConversion,
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}

/// Modelo para estadísticas del pipeline
class PipelineStats {
  final int totalDeals;
  final double totalValor;
  final double valorPonderado;
  final int dealsGanados;
  final int dealsPerdidos;
  final double valorGanado;
  final double tasaConversion;

  PipelineStats({
    required this.totalDeals,
    required this.totalValor,
    required this.valorPonderado,
    required this.dealsGanados,
    required this.dealsPerdidos,
    required this.valorGanado,
    required this.tasaConversion,
  });
}
