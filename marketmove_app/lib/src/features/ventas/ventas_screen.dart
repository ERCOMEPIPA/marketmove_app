import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de Ventas
///
/// Permite registrar nuevas ventas y ver el listado
/// Maqueta MVP - Datos de ejemplo
class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo para el MVP
    final ventasEjemplo = [
      {
        'concepto': 'Venta de productos',
        'monto': 150.00,
        'fecha': '2025-12-01',
      },
      {'concepto': 'Servicio técnico', 'monto': 250.00, 'fecha': '2025-11-30'},
      {'concepto': 'Venta mayorista', 'monto': 500.00, 'fecha': '2025-11-29'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: ventasEjemplo.length,
        itemBuilder: (context, index) {
          final venta = ventasEjemplo[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.attach_money, color: Colors.green),
              ),
              title: Text(venta['concepto'] as String),
              subtitle: Text(venta['fecha'] as String),
              trailing: Text(
                '€${(venta['monto'] as double).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarDialogoNuevaVenta(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
      ),
    );
  }

  void _mostrarDialogoNuevaVenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Venta'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Concepto',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Implementar guardar venta en Supabase
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad próximamente')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
