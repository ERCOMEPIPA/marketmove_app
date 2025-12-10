import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Servicio para integración con Stripe
/// Maneja checkout, portal de cliente y webhooks
class StripeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// URL base de las Edge Functions de Supabase
  String get _functionsUrl =>
      '${_supabase.rest.url.replaceAll('/rest/v1', '')}/functions/v1';

  /// Obtener headers de autenticación
  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
    'Content-Type': 'application/json',
  };

  /// Crea una sesión de Stripe Checkout para suscribirse a un plan
  /// Retorna la URL del checkout o null si hay error
  Future<String?> createCheckoutSession({
    required String priceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-checkout',
        body: {
          'priceId': priceId,
          'successUrl': successUrl,
          'cancelUrl': cancelUrl,
        },
      );

      if (response.status != 200) {
        throw Exception('Error al crear sesión de checkout');
      }

      final data = response.data as Map<String, dynamic>;
      return data['url'] as String?;
    } catch (e) {
      throw Exception('Error al crear checkout: $e');
    }
  }

  /// Abre el checkout de Stripe en el navegador
  Future<bool> openCheckout({
    required String priceId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    try {
      final currentUrl = Uri.base.toString();
      final checkoutUrl = await createCheckoutSession(
        priceId: priceId,
        successUrl: successUrl ?? '$currentUrl?success=true',
        cancelUrl: cancelUrl ?? '$currentUrl?canceled=true',
      );

      if (checkoutUrl == null) return false;

      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Crea un enlace al portal de cliente de Stripe
  /// Permite al usuario gestionar su suscripción (cambiar plan, cancelar, etc.)
  Future<String?> createPortalSession({String? returnUrl}) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-portal',
        body: {'returnUrl': returnUrl ?? Uri.base.toString()},
      );

      if (response.status != 200) {
        throw Exception('Error al crear sesión de portal');
      }

      final data = response.data as Map<String, dynamic>;
      return data['url'] as String?;
    } catch (e) {
      throw Exception('Error al crear portal: $e');
    }
  }

  /// Abre el portal de cliente de Stripe
  Future<bool> openCustomerPortal({String? returnUrl}) async {
    try {
      final portalUrl = await createPortalSession(returnUrl: returnUrl);

      if (portalUrl == null) return false;

      final uri = Uri.parse(portalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Verifica si el usuario actual tiene una suscripción activa
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return SubscriptionStatus(isActive: false, status: 'no_user');
      }

      final response = await _supabase
          .from('perfiles')
          .select('suscripcion_estado, stripe_subscription_id, plan_id')
          .eq('id', userId)
          .single();

      return SubscriptionStatus(
        isActive: response['suscripcion_estado'] == 'activa',
        status: response['suscripcion_estado'] ?? 'inactive',
        subscriptionId: response['stripe_subscription_id'],
        planId: response['plan_id'],
      );
    } catch (e) {
      return SubscriptionStatus(isActive: false, status: 'error');
    }
  }

  /// Cancela la suscripción del usuario actual
  Future<bool> cancelSubscription() async {
    try {
      final response = await _supabase.functions.invoke(
        'cancel-subscription',
        body: {},
      );

      return response.status == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Estado de suscripción del usuario
class SubscriptionStatus {
  final bool isActive;
  final String status; // 'activa', 'cancelada', 'pendiente', 'no_user', 'error'
  final String? subscriptionId;
  final String? planId;

  SubscriptionStatus({
    required this.isActive,
    required this.status,
    this.subscriptionId,
    this.planId,
  });

  bool get hasSubscription => subscriptionId != null;
  bool get canUpgrade => isActive;
  bool get needsSubscription => !isActive && subscriptionId == null;
}
