import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/models/venta_model.dart';
import '../../shared/models/producto_model.dart';
import '../../shared/services/ventas_service.dart';
import '../../shared/services/productos_service.dart';
import '../../shared/services/auth_service.dart';

/// Pantalla de gestión de ventas
class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final _ventasService = VentasService();
  final _authService = AuthService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<VentaModel> _ventas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _authService.currentUser!;
      final ventas = await _ventasService.getVentas(user.id);

      setState(() {
        _ventas = ventas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _eliminarVenta(VentaModel venta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Eliminar venta del ${_dateFormat.format(venta.fecha)}?\n\n'
          'El stock de los productos será restaurado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _ventasService.eliminarVenta(venta.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta eliminada y stock restaurado')),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _ventas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.point_of_sale, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay ventas registradas',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text('Registra tu primera venta'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ventas.length,
                itemBuilder: (context, index) {
                  final venta = _ventas[index];
                  return _buildVentaCard(venta);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioVenta(),
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nueva Venta'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildVentaCard(VentaModel venta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(Icons.point_of_sale, color: Colors.green.shade700),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venta.notas ?? 'Venta de productos',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currencyFormat.format(venta.monto),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (venta.metodoPago != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  venta.metodoPago!.displayName,
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
              ),
          ],
        ),
        subtitle: Text(_dateFormat.format(venta.fecha)),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'eliminar') {
              _eliminarVenta(venta);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        children: [
          if (venta.detalles != null && venta.detalles!.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Productos:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...venta.detalles!.map(
                    (detalle) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${detalle.productoNombre ?? "Producto"} x${detalle.cantidad}',
                            ),
                          ),
                          Text(
                            _currencyFormat.format(detalle.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (venta.notas != null && venta.notas!.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      venta.notas!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _mostrarFormularioVenta() {
    showDialog(
      context: context,
      builder: (context) => _NuevaVentaDialog(
        onSaved: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }
}

/// Diálogo para crear una nueva venta
class _NuevaVentaDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const _NuevaVentaDialog({required this.onSaved});

  @override
  State<_NuevaVentaDialog> createState() => _NuevaVentaDialogState();
}

class _NuevaVentaDialogState extends State<_NuevaVentaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ventasService = VentasService();
  final _productosService = ProductosService();
  final _authService = AuthService();
  final _notasController = TextEditingController();

  List<ProductoModel> _productos = [];
  final List<_ProductoVenta> _productosVenta = [];
  MetodoPago? _metodoPago;
  bool _isLoading = false;
  bool _loadingProductos = true;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _loadProductos() async {
    try {
      final user = _authService.currentUser!;
      final productos = await _productosService.getProductos(
        user.id,
        soloActivos: true,
      );
      setState(() {
        _productos = productos.where((p) => p.stock > 0).toList();
        _loadingProductos = false;
      });
    } catch (e) {
      setState(() => _loadingProductos = false);
    }
  }

  void _agregarProducto() {
    if (_productos.isEmpty) return;

    setState(() {
      _productosVenta.add(
        _ProductoVenta(producto: _productos.first, cantidad: 1),
      );
    });
  }

  void _eliminarProducto(int index) {
    setState(() => _productosVenta.removeAt(index));
  }

  double get _total {
    return _productosVenta.fold(
      0,
      (sum, pv) => sum + (pv.producto.precio * pv.cantidad),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productosVenta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser!;

      final detalles = _productosVenta
          .map(
            (pv) => DetalleVentaInput(
              productoId: pv.producto.id,
              cantidad: pv.cantidad,
              precioUnitario: pv.producto.precio,
            ),
          )
          .toList();

      await _ventasService.crearVenta(
        userId: user.id,
        detalles: detalles,
        metodoPago: _metodoPago,
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta registrada exitosamente')),
        );
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_shopping_cart, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nueva Venta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Lista de productos
              Expanded(
                child: _loadingProductos
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Productos',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _productos.isEmpty
                                      ? null
                                      : _agregarProducto,
                                  icon: const Icon(Icons.add, size: 20),
                                  label: const Text('Agregar'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (_productosVenta.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    'No hay productos en la venta',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              )
                            else
                              ..._productosVenta.asMap().entries.map((entry) {
                                final index = entry.key;
                                final pv = entry.value;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child:
                                                  DropdownButtonFormField<
                                                    ProductoModel
                                                  >(
                                                    initialValue: pv.producto,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Producto',
                                                          border:
                                                              OutlineInputBorder(),
                                                          isDense: true,
                                                        ),
                                                    items: _productos.map((p) {
                                                      return DropdownMenuItem(
                                                        value: p,
                                                        child: Text(
                                                          '${p.nombre} (€${p.precio.toStringAsFixed(2)})',
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        setState(() {
                                                          _productosVenta[index] =
                                                              _ProductoVenta(
                                                                producto: value,
                                                                cantidad:
                                                                    pv.cantidad,
                                                              );
                                                        });
                                                      }
                                                    },
                                                  ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () =>
                                                  _eliminarProducto(index),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            SizedBox(
                                              width: 120,
                                              child: TextFormField(
                                                initialValue: pv.cantidad
                                                    .toString(),
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Cantidad',
                                                      border:
                                                          OutlineInputBorder(),
                                                      isDense: true,
                                                    ),
                                                keyboardType:
                                                    TextInputType.number,
                                                validator: (value) {
                                                  if (value?.isEmpty ?? true) {
                                                    return 'Requerido';
                                                  }
                                                  final cant = int.tryParse(
                                                    value!,
                                                  );
                                                  if (cant == null || cant <= 0) {
                                                    return 'Inválido';
                                                  }
                                                  if (cant >
                                                      pv.producto.stock) {
                                                    return 'Stock: ${pv.producto.stock}';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (value) {
                                                  final cant = int.tryParse(
                                                    value,
                                                  );
                                                  if (cant != null &&
                                                      cant > 0) {
                                                    setState(() {
                                                      _productosVenta[index] =
                                                          _ProductoVenta(
                                                            producto:
                                                                pv.producto,
                                                            cantidad: cant,
                                                          );
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Subtotal: €${(pv.producto.precio * pv.cantidad).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                            const SizedBox(height: 16),

                            // Método de pago
                            DropdownButtonFormField<MetodoPago>(
                              initialValue: _metodoPago,
                              decoration: const InputDecoration(
                                labelText: 'Método de pago',
                                border: OutlineInputBorder(),
                              ),
                              items: MetodoPago.values.map((mp) {
                                return DropdownMenuItem(
                                  value: mp,
                                  child: Text(mp.displayName),
                                );
                              }).toList(),
                              onChanged: (value) =>
                                  setState(() => _metodoPago = value),
                            ),
                            const SizedBox(height: 16),

                            // Notas
                            TextFormField(
                              controller: _notasController,
                              decoration: const InputDecoration(
                                labelText: 'Comentarios (opcional)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '€${_total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _guardar,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Registrar Venta'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clase auxiliar para productos en la venta
class _ProductoVenta {
  final ProductoModel producto;
  final int cantidad;

  _ProductoVenta({required this.producto, required this.cantidad});
}
