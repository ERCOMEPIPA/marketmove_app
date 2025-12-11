import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/limites_service.dart';

/// Widget banner que muestra alerta cuando se está cerca del límite del plan
class LimiteAlertWidget extends StatelessWidget {
  final PlanLimites limites;
  final String tipo; // 'clientes' o 'empleados'
  final VoidCallback? onUpgrade;

  const LimiteAlertWidget({
    super.key,
    required this.limites,
    required this.tipo,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = tipo == 'clientes'
        ? limites.porcentajeClientes
        : limites.porcentajeEmpleados;

    final actual = tipo == 'clientes'
        ? limites.clientesActuales
        : limites.empleadosActuales;

    final max = tipo == 'clientes' ? limites.maxClientes : limites.maxEmpleados;

    // No mostrar si está por debajo del 80%
    if (porcentaje < 0.8) return const SizedBox.shrink();

    // Color según el porcentaje
    final Color bannerColor;
    final IconData icon;
    if (porcentaje >= 1.0) {
      bannerColor = AppColors.error;
      icon = Icons.error_outline;
    } else if (porcentaje >= 0.9) {
      bannerColor = Colors.orange[700]!;
      icon = Icons.warning_amber;
    } else {
      bannerColor = Colors.amber[700]!;
      icon = Icons.info_outline;
    }

    final porcentajeTexto = (porcentaje * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: bannerColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  porcentaje >= 1.0
                      ? '¡Límite de $tipo alcanzado!'
                      : 'Límite de $tipo al $porcentajeTexto%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: bannerColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$actual de $max ${tipo == 'clientes' ? 'clientes' : 'empleados'} usados. '
                  '${porcentaje >= 1.0 ? 'Actualiza tu plan.' : 'Considera actualizar.'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          if (onUpgrade != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onUpgrade,
              style: TextButton.styleFrom(
                backgroundColor: bannerColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Actualizar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget indicador para deals próximos a vencer
class DealUrgenteBadge extends StatelessWidget {
  final DateTime fechaCierre;

  const DealUrgenteBadge({super.key, required this.fechaCierre});

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final diasRestantes = fechaCierre.difference(ahora).inDays;

    // No mostrar si faltan más de 7 días
    if (diasRestantes > 7) return const SizedBox.shrink();

    String texto;
    Color color;

    if (diasRestantes <= 0) {
      texto = 'HOY';
      color = AppColors.error;
    } else if (diasRestantes == 1) {
      texto = 'MAÑANA';
      color = Colors.orange[700]!;
    } else if (diasRestantes <= 3) {
      texto = '$diasRestantes días';
      color = Colors.orange[600]!;
    } else {
      texto = '$diasRestantes días';
      color = Colors.amber[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            texto,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
