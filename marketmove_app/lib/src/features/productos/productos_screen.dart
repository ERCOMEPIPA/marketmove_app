import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de Productos
///
/// Permite gestionar el inventario de productos
/// Maqueta MVP - Datos de ejemplo
class ProductosScreen extends StatelessWidget {
  const ProductosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo para el MVP
    final productosEjemplo = [
      {'nombre': 'Producto A', 'stock': 50, 'precio': 25.00},
      {'nombre': 'Producto B', 'stock': 30, 'precio': 15.50},
      {'nombre': 'Producto C', 'stock': 10, 'precio': 45.00},
      {'nombre': 'Producto D', 'stock': 5, 'precio': 60.00},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: productosEjemplo.length,
        itemBuilder: (context, index) {
          final producto = productosEjemplo[index];
          final stock = producto['stock'] as int;
          final stockBajo = stock < 15;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: stockBajo
                    ? Colors.orange.shade100
                    : Colors.blue.shade100,
                child: Icon(
                  Icons.inventory_2,
                  color: stockBajo ? Colors.orange : Colors.blue,
                ),
              ),
              title: Text(producto['nombre'] as String),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Precio: €${(producto['precio'] as double).toStringAsFixed(2)}',
                  ),
                  Text(
                    'Stock: $stock unidades',
                    style: TextStyle(
                      color: stockBajo ? Colors.orange.shade700 : null,
                      fontWeight: stockBajo ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
              trailing: stockBajo
                  ? const Icon(Icons.warning, color: Colors.orange)
                  : null,
              isThreeLine: true,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _mostrarDialogoNuevoProducto(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Producto'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _mostrarDialogoNuevoProducto(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Producto'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Precio',
                prefixText: '€ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Stock inicial',
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
              // TODO: Implementar guardar producto en Supabase
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
