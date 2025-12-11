import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Exportar archivo en móvil usando share_plus
Future<void> exportarArchivo(String contenido, String nombreArchivo) async {
  try {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$nombreArchivo';

    final file = File(filePath);
    await file.writeAsString(contenido, encoding: utf8);

    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Exportación: $nombreArchivo',
      text: 'Archivo CSV exportado desde MarketMove',
    );

    mostrarMensaje('Archivo "$nombreArchivo" listo para compartir');
  } catch (e) {
    mostrarMensaje('Error al exportar: $e');
  }
}

void mostrarMensaje(String mensaje) {
  // ignore: avoid_print
  print(mensaje);
}
