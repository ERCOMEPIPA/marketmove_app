import 'package:flutter/material.dart';

/// Dashboard simplificado para clientes
/// Muestra bienvenida y resumen de actividad
class ClienteDashboardScreen extends StatelessWidget {
  const ClienteDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¡Bienvenido!',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Explora nuestros productos y gestiona tus compras',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            // Tarjetas de resumen
            _buildSummaryCard(
              context: context,
              icon: Icons.shopping_bag,
              title: 'Mis Compras',
              subtitle: '0 compras realizadas',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(
              context: context,
              icon: Icons.store,
              title: 'Catálogo',
              subtitle: 'Explora los productos',
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            // Sección de acciones rápidas
            Text(
              'Acciones Rápidas',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navegar a catálogo
                },
                icon: const Icon(Icons.store),
                label: const Text('Ver Catálogo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
