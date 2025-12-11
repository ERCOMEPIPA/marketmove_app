import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/limites_service.dart';

/// Widget que muestra el estado de suscripción y uso del plan
class PlanUsageWidget extends StatelessWidget {
  final PlanLimites limites;
  final VoidCallback? onUpgrade;

  const PlanUsageWidget({super.key, required this.limites, this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: limites.suscripcionActiva
              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
              : [Colors.grey[600]!, Colors.grey[700]!],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    limites.suscripcionActiva ? Icons.verified : Icons.warning,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Plan ${limites.planNombre}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!limites.suscripcionActiva)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'INACTIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Uso de clientes
          _buildUsageBar(
            context,
            'Clientes',
            limites.clientesActuales,
            limites.maxClientes,
            Icons.people,
          ),
          const SizedBox(height: 12),

          // Uso de empleados
          _buildUsageBar(
            context,
            'Empleados',
            limites.empleadosActuales,
            limites.maxEmpleados,
            Icons.badge,
          ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.go('/admin/planes');
              },
              icon: const Icon(Icons.upgrade, color: Colors.white),
              label: const Text(
                'Actualizar Plan',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBar(
    BuildContext context,
    String label,
    int actual,
    int maximo,
    IconData icon,
  ) {
    final porcentaje = maximo > 0 ? actual / maximo : 0.0;
    final color = porcentaje > 0.9
        ? Colors.red[300]!
        : porcentaje > 0.7
        ? Colors.orange[300]!
        : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            Text(
              '$actual / $maximo',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: porcentaje.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

/// Widget compacto para mostrar el plan en el dashboard
class PlanBadge extends StatelessWidget {
  final String planNombre;
  final bool activo;

  const PlanBadge({super.key, required this.planNombre, this.activo = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: activo
              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
              : [Colors.grey[400]!, Colors.grey[500]!],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            activo ? Icons.verified : Icons.warning,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            planNombre,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
