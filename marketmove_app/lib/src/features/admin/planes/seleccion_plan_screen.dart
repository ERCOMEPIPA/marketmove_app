import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/planes_service.dart';
import '../../../shared/services/stripe_service.dart';
import '../../../shared/services/limites_service.dart';

/// Pantalla para que los dueños seleccionen y se suscriban a un plan
class SeleccionPlanScreen extends StatefulWidget {
  const SeleccionPlanScreen({super.key});

  @override
  State<SeleccionPlanScreen> createState() => _SeleccionPlanScreenState();
}

class _SeleccionPlanScreenState extends State<SeleccionPlanScreen> {
  final _planesService = PlanesService();
  final _stripeService = StripeService();
  final _limitesService = LimitesService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

  List<PlanModel> _planes = [];
  PlanLimites? _limitesActuales;
  bool _isLoading = true;
  String? _processingPlanId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final planes = await _planesService.getPlanes();
      final limites = await _limitesService.getLimitesActual();
      setState(() {
        _planes = planes.where((p) => p.activo).toList();
        _limitesActuales = limites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _suscribirseAPlan(PlanModel plan) async {
    if (plan.stripePriceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este plan no tiene configurado Stripe'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _processingPlanId = plan.id);

    try {
      final success = await _stripeService.openCheckout(
        priceId: plan.stripePriceId!,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el checkout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingPlanId = null);
      }
    }
  }

  Future<void> _abrirPortalCliente() async {
    try {
      final success = await _stripeService.openCustomerPortal();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el portal de cliente'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Planes de Suscripción'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        actions: [
          if (_limitesActuales?.suscripcionActiva == true)
            TextButton.icon(
              onPressed: _abrirPortalCliente,
              icon: const Icon(Icons.settings, color: Colors.white),
              label: const Text(
                'Gestionar',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan actual
                    if (_limitesActuales != null) _buildPlanActual(),
                    const SizedBox(height: 24),

                    // Lista de planes disponibles
                    Text(
                      'Planes Disponibles',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._planes.map((plan) => _buildPlanCard(plan)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPlanActual() {
    final limites = _limitesActuales!;
    final isActive = limites.suscripcionActiva;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
              : [Colors.grey[600]!, Colors.grey[700]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? Icons.verified : Icons.warning,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Tu Plan Actual',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            limites.planNombre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLimitBadge(
                '${limites.clientesActuales}/${limites.maxClientes}',
                'Clientes',
              ),
              const SizedBox(width: 16),
              _buildLimitBadge(
                '${limites.empleadosActuales}/${limites.maxEmpleados}',
                'Empleados',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLimitBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(PlanModel plan) {
    final isCurrentPlan = _limitesActuales?.planNombre == plan.nombre;
    final isProcessing = _processingPlanId == plan.id;
    final hasStripe = plan.stripePriceId != null;

    final color = plan.precio == 0
        ? Colors.grey
        : plan.precio < 50
        ? Colors.blue
        : Colors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentPlan
            ? Border.all(color: const Color(0xFF6366F1), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con gradiente
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCurrentPlan)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PLAN ACTUAL',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      plan.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _currencyFormat.format(plan.precio),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      plan.precioLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (plan.descripcion != null) ...[
                  Text(
                    plan.descripcion!,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                // Límites
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeature(
                      Icons.people,
                      '${plan.maxEmpleados}',
                      'Empleados',
                    ),
                    _buildFeature(
                      Icons.person,
                      '${plan.maxClientes}',
                      'Clientes',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Botón de suscripción
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isCurrentPlan || !hasStripe || isProcessing
                        ? null
                        : () => _suscribirseAPlan(plan),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            isCurrentPlan
                                ? 'Plan Actual'
                                : !hasStripe
                                ? 'No disponible'
                                : 'Suscribirse',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
