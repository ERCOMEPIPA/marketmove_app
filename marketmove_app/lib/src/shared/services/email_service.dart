import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para enviar emails mediante Edge Functions de Supabase
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Enviar email de bienvenida a un nuevo empleado
  Future<bool> enviarEmailBienvenida({
    required String empleadoEmail,
    String? empleadoNombre,
    String? negocioNombre,
    String? duenoNombre,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-welcome-email',
        body: {
          'empleadoEmail': empleadoEmail,
          'empleadoNombre': empleadoNombre ?? '',
          'negocioNombre': negocioNombre ?? 'MarketMove',
          'duenoNombre': duenoNombre ?? 'el administrador',
        },
      );

      if (response.status == 200) {
        // ignore: avoid_print
        print('EmailService: Email de bienvenida enviado a $empleadoEmail');
        return true;
      } else {
        // ignore: avoid_print
        print('EmailService: Error al enviar email - ${response.data}');
        return false;
      }
    } catch (e) {
      // ignore: avoid_print
      print('EmailService: Error - $e');
      return false;
    }
  }

  /// Enviar email de notificación genérico
  Future<bool> enviarNotificacion({
    required String destinatario,
    required String asunto,
    required String mensaje,
  }) async {
    // TODO: Implementar cuando sea necesario
    return false;
  }
}
