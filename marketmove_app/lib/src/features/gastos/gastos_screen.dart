import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de Gastos
///
/// Permite registrar nuevos gastos y ver el listado
/// Maqueta MVP - Datos de ejemplo
class GastosScreen extends StatelessWidget {
  const GastosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo para el MVP
    final gastosEjemplo = [
      {'concepto': 'Alquiler local', 'monto': 800.00, 'fecha': '2025-12-01'},
      {
        'concepto': 'Servicios (luz, agua)',
        'monto': 150.00,
        'fecha': '2025-11-30',
      },
      {'concepto': 'Compra inventario', 'monto': 450.00, 'fecha': '2025-11-29'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: gastosEjemplo.length,
        itemBuilder: (context, index) {
          final gasto = gastosEjemplo[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: const Icon(Icons.money_off, color: Colors.red),
              ),
              title: Text(gasto['concepto'] as String),
              subtitle: Text(gasto['fecha'] as String),
              trailing: Text(
                '€${(gasto['monto'] as double).toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarDialogoNuevoGasto(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Gasto'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _mostrarDialogoNuevoGasto(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Gasto'),
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
              // TODO: Implementar guardar gasto en Supabase
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
