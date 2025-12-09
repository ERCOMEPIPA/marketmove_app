import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para manejar subida de archivos a Supabase Storage
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _productosFolder = 'productos';
  static const String _bucketName = 'images';

  /// Subir imagen de producto
  Future<String?> uploadProductImage({
    required String productId,
    required Uint8List imageData,
    required String fileName,
  }) async {
    try {
      final path = '$_productosFolder/$productId/$fileName';
      
      await _supabase.storage.from(_bucketName).uploadBinary(
        path,
        imageData,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      // Obtener la URL pública
      final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  /// Eliminar imagen de producto
  Future<bool> deleteProductImage({
    required String productId,
    required String fileName,
  }) async {
    try {
      final path = '$_productosFolder/$productId/$fileName';
      await _supabase.storage.from(_bucketName).remove([path]);
      return true;
    } catch (e) {
      print('Error al eliminar imagen: $e');
      return false;
    }
  }

  /// Obtener URL pública de una imagen
  String getPublicUrl(String productId, String fileName) {
    final path = '$_productosFolder/$productId/$fileName';
    return _supabase.storage.from(_bucketName).getPublicUrl(path);
  }
}
