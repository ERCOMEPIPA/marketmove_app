import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla principal - Dashboard/Resumen
///
/// Muestra el balance general (ventas - gastos) y accesos rápidos
/// Maqueta MVP - Datos de ejemplo
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo para el MVP
    const double ventasTotales = 15000.00;
    const double gastosTotales = 8500.00;
    const double balance = ventasTotales - gastosTotales;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.go('/login');
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tarjeta de balance principal
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Balance Total',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '€${balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: balance >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tarjetas de ventas y gastos
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.green.shade700,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ventas',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '€${ventasTotales.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.trending_down,
                            color: Colors.red.shade700,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gastos',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '€${gastosTotales.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Accesos rápidos
            Text(
              'Accesos Rápidos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _buildQuickAccessCard(
              context,
              title: 'Registrar Venta',
              icon: Icons.point_of_sale,
              color: Colors.green,
              onTap: () => context.go('/ventas'),
            ),
            const SizedBox(height: 12),

            _buildQuickAccessCard(
              context,
              title: 'Registrar Gasto',
              icon: Icons.money_off,
              color: Colors.red,
              onTap: () => context.go('/gastos'),
            ),
            const SizedBox(height: 12),

            _buildQuickAccessCard(
              context,
              title: 'Gestionar Productos',
              icon: Icons.inventory_2,
              color: Colors.blue,
              onTap: () => context.go('/productos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
