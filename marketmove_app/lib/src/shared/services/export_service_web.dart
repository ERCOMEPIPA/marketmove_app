// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

/// Exportar archivo en web usando descarga del navegador
Future<void> exportarArchivo(String contenido, String nombreArchivo) async {
  try {
    final bytes = utf8.encode(contenido);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', nombreArchivo)
      ..style.display = 'none';

    html.document.body!.children.add(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(url);
    mostrarMensaje('Archivo "$nombreArchivo" descargado correctamente');
  } catch (e) {
    mostrarMensaje('Error al descargar: $e');
  }
}

void mostrarMensaje(String mensaje) {
  // ignore: avoid_print
  print(mensaje);
}
