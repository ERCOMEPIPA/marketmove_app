/// Stub para exportación - usado como fallback
Future<void> exportarArchivo(String contenido, String nombreArchivo) async {
  throw UnsupportedError('Platform not supported');
}

void mostrarMensaje(String mensaje) {
  // ignore: avoid_print
  print(mensaje);
}
