import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../shared/models/gasto_model.dart';
import '../../shared/models/producto_model.dart';
import '../../shared/models/venta_model.dart';
import '../../shared/services/gastos_service.dart';
import '../../shared/services/auth_service.dart';

/// Pantalla de gestión de gastos
class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final _gastosService = GastosService();
  final _authService = AuthService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<GastoModel> _gastos = [];
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
      final gastos = await _gastosService.getGastos(user.id);

      setState(() {
        _gastos = gastos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _eliminarGasto(GastoModel gasto) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar gasto "${gasto.concepto}"?'),
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
        await _gastosService.eliminarGasto(gasto.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gasto eliminado')));
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
          : _gastos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay gastos registrados',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text('Registra tu primer gasto'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _gastos.length,
                itemBuilder: (context, index) {
                  final gasto = _gastos[index];
                  return _buildGastoCard(gasto);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioGasto(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Gasto'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildGastoCard(GastoModel gasto) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Icon(Icons.money_off, color: Colors.red.shade700),
        ),
        title: Row(
          children: [
            Expanded(child: Text(gasto.concepto)),
            if (gasto.metodoPago != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  gasto.metodoPago!.displayName,
                  style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_dateFormat.format(gasto.fecha)),
            if (gasto.categoriaNombre != null)
              Text(
                gasto.categoriaNombre!,
                style: const TextStyle(fontSize: 12),
              ),
            if (gasto.notas != null)
              Text(
                gasto.notas!,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (gasto.fotoUrl != null)
              Row(
                children: [
                  Icon(Icons.photo, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Con foto adjunta',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currencyFormat.format(gasto.monto),
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'eliminar') {
                  _eliminarGasto(gasto);
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
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _mostrarFormularioGasto() {
    showDialog(
      context: context,
      builder: (context) => _NuevoGastoDialog(
        onSaved: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }
}

/// Diálogo para crear nuevo gasto
class _NuevoGastoDialog extends StatefulWidget {
  final VoidCallback onSaved;

  const _NuevoGastoDialog({required this.onSaved});

  @override
  State<_NuevoGastoDialog> createState() => _NuevoGastoDialogState();
}

class _NuevoGastoDialogState extends State<_NuevoGastoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _gastosService = GastosService();
  final _authService = AuthService();
  final _conceptoController = TextEditingController();
  final _montoController = TextEditingController();
  final _notasController = TextEditingController();

  List<CategoriaModel> _categorias = [];
  String? _categoriaId;
  MetodoPago? _metodoPago;
  Uint8List? _fotoBytes;
  String? _fotoNombre;
  bool _isLoading = false;
  bool _loadingCategorias = true;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    try {
      final user = _authService.currentUser!;
      final categorias = await _gastosService.getCategoriasGastos(user.id);
      setState(() {
        _categorias = categorias;
        _loadingCategorias = false;
      });
    } catch (e) {
      setState(() => _loadingCategorias = false);
    }
  }

  Future<void> _seleccionarFoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _fotoBytes = result.files.first.bytes;
          _fotoNombre = result.files.first.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar foto: $e')),
        );
      }
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser!;

      // Subir foto si existe
      String? fotoUrl;
      if (_fotoBytes != null && _fotoNombre != null) {
        fotoUrl = await _gastosService.subirFoto(
          user.id,
          _fotoBytes!,
          _fotoNombre!,
        );
      }

      await _gastosService.crearGasto(
        userId: user.id,
        concepto: _conceptoController.text.trim(),
        monto: double.parse(_montoController.text),
        notas: _notasController.text.trim().isEmpty
            ? null
            : _notasController.text.trim(),
        categoriaId: _categoriaId,
        metodoPago: _metodoPago,
        fotoUrl: fotoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto registrado exitosamente')),
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
    return AlertDialog(
      title: const Text('Nuevo Gasto'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _conceptoController,
                decoration: const InputDecoration(
                  labelText: 'Concepto *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoController,
                decoration: const InputDecoration(
                  labelText: 'Monto *',
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Requerido';
                  if (double.tryParse(value!) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _categoriaId,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  ..._categorias.map(
                    (cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.nombre),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _categoriaId = value),
              ),
              const SizedBox(height: 16),
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
                onChanged: (value) => setState(() => _metodoPago = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notasController,
                decoration: const InputDecoration(
                  labelText: 'Comentarios',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _seleccionarFoto,
                icon: const Icon(Icons.photo_camera),
                label: Text(_fotoNombre ?? 'Adjuntar foto (opcional)'),
              ),
              if (_fotoNombre != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Foto seleccionada: $_fotoNombre',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _guardar,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
