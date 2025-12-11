import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gasto_model.dart';
import '../models/producto_model.dart'; // For CategoriaModel
import '../models/venta_model.dart'; // For MetodoPago
import '../constants/categorias_predefinidas.dart';

/// Servicio para gestionar gastos
class GastosService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Obtiene todos los gastos del usuario
  Future<List<GastoModel>> getGastos(
    String userId, {
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      var query = _supabase
          .from('gastos')
          .select('*, categorias(nombre)')
          .eq('user_id', userId);

      if (desde != null) {
        query = query.gte('fecha', desde.toIso8601String());
      }
      if (hasta != null) {
        query = query.lte('fecha', hasta.toIso8601String());
      }

      final response = await query.order('fecha', ascending: false);

      return (response as List)
          .map((json) => GastoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener gastos: $e');
    }
  }

  /// Obtiene un gasto específico
  Future<GastoModel> getGasto(String gastoId) async {
    try {
      final response = await _supabase
          .from('gastos')
          .select('*, categorias(nombre)')
          .eq('id', gastoId)
          .single();

      return GastoModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener gasto: $e');
    }
  }

  /// Sube una foto al storage de Supabase
  Future<String?> subirFoto(
    String userId,
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'gastos/$userId/$timestamp-$fileName';

      await _supabase.storage
          .from('gastos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final url = _supabase.storage.from('gastos').getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Error al subir foto: $e');
    }
  }

  /// Crea un nuevo gasto
  Future<GastoModel> crearGasto({
    required String userId,
    required String concepto,
    required double monto,
    String? notas,
    String? categoriaId,
    MetodoPago? metodoPago,
    String? fotoUrl,
  }) async {
    try {
      final response = await _supabase
          .from('gastos')
          .insert({
            'user_id': userId,
            'concepto': concepto,
            'monto': monto,
            'fecha': DateTime.now().toIso8601String(),
            'notas': notas,
            'categoria_id': categoriaId,
            'metodo_pago': metodoPago?.toStringValue(),
            'foto_url': fotoUrl,
          })
          .select('*, categorias(nombre)')
          .single();

      return GastoModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear gasto: $e');
    }
  }

  /// Actualiza un gasto
  Future<GastoModel> actualizarGasto({
    required String gastoId,
    String? concepto,
    double? monto,
    String? notas,
    String? categoriaId,
    MetodoPago? metodoPago,
    String? fotoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (concepto != null) updates['concepto'] = concepto;
      if (monto != null) updates['monto'] = monto;
      if (notas != null) updates['notas'] = notas;
      if (categoriaId != null) updates['categoria_id'] = categoriaId;
      if (metodoPago != null) {
        updates['metodo_pago'] = metodoPago.toStringValue();
      }
      if (fotoUrl != null) updates['foto_url'] = fotoUrl;

      await _supabase.from('gastos').update(updates).eq('id', gastoId);

      return await getGasto(gastoId);
    } catch (e) {
      throw Exception('Error al actualizar gasto: $e');
    }
  }

  /// Elimina un gasto
  Future<void> eliminarGasto(String gastoId) async {
    try {
      await _supabase.from('gastos').delete().eq('id', gastoId);
    } catch (e) {
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  /// Obtiene categorías de gastos, incluyendo las predefinidas
  Future<List<CategoriaModel>> getCategoriasGastos(String userId) async {
    try {
      // Primero asegurar que las categorías predefinidas existan
      await _asegurarCategoriasPredefinidas(userId);

      final response = await _supabase
          .from('categorias')
          .select()
          .eq('user_id', userId)
          .eq('tipo', 'gasto')
          .order('nombre', ascending: true);

      return (response as List)
          .map((json) => CategoriaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener categorías de gastos: $e');
    }
  }

  /// Asegura que las categorías predefinidas existan para el usuario
  Future<void> _asegurarCategoriasPredefinidas(String userId) async {
    try {
      // Obtener categorías existentes
      final existentes = await _supabase
          .from('categorias')
          .select('nombre')
          .eq('user_id', userId)
          .eq('tipo', 'gasto');

      final nombresExistentes = (existentes as List)
          .map((c) => c['nombre'] as String)
          .toSet();

      // Insertar las que falten
      for (final nombre in categoriasGastosPredefinidas) {
        if (!nombresExistentes.contains(nombre)) {
          await _supabase.from('categorias').insert({
            'user_id': userId,
            'nombre': nombre,
            'tipo': 'gasto',
            'color': '#ef4444',
          });
        }
      }
    } catch (e) {
      // Si falla, continuar sin las predefinidas
      debugPrint('Error al insertar categorías predefinidas de gastos: $e');
    }
  }

  /// Crea una categoría de gasto
  Future<CategoriaModel> crearCategoriaGasto({
    required String userId,
    required String nombre,
    String color = '#ef4444',
  }) async {
    try {
      final response = await _supabase
          .from('categorias')
          .insert({
            'user_id': userId,
            'nombre': nombre,
            'tipo': 'gasto',
            'color': color,
          })
          .select()
          .single();

      return CategoriaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }
}
