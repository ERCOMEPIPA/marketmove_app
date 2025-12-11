import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/services/planes_service.dart';
import '../../shared/constants/app_colors.dart';

/// Pantalla de gestión de planes para Superadmin
class PlanesScreen extends StatefulWidget {
  const PlanesScreen({super.key});

  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

class _PlanesScreenState extends State<PlanesScreen> {
  final _planesService = PlanesService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

  List<PlanModel> _planes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final planes = await _planesService.getPlanes();
      setState(() {
        _planes = planes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _mostrarFormularioPlan([PlanModel? plan]) {
    final nombreController = TextEditingController(text: plan?.nombre);
    final descripcionController = TextEditingController(
      text: plan?.descripcion,
    );
    final precioController = TextEditingController(
      text: plan?.precio.toString() ?? '0',
    );
    final maxEmpleadosController = TextEditingController(
      text: plan?.maxEmpleados.toString() ?? '5',
    );
    final maxClientesController = TextEditingController(
      text: plan?.maxClientes.toString() ?? '100',
    );
    final stripePriceIdController = TextEditingController(
      text: plan?.stripePriceId ?? '',
    );
    bool activo = plan?.activo ?? true;
    TipoFacturacion tipoFacturacion =
        plan?.tipoFacturacion ?? TipoFacturacion.mensual;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(plan == null ? 'Nuevo Plan' : 'Editar Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(
                    labelText: 'Precio (€)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.euro),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                // Selector de tipo de facturación
                DropdownButtonFormField<TipoFacturacion>(
                  initialValue: tipoFacturacion,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Facturación',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: TipoFacturacion.values.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo.nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => tipoFacturacion = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: maxEmpleadosController,
                        decoration: const InputDecoration(
                          labelText: 'Máx. Empleados',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxClientesController,
                        decoration: const InputDecoration(
                          labelText: 'Máx. Clientes',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Campo para Stripe Price ID
                TextField(
                  controller: stripePriceIdController,
                  decoration: InputDecoration(
                    labelText: 'Stripe Price ID',
                    hintText: 'price_xxxxx...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.payment),
                    helperText: 'ID del precio en Stripe Dashboard',
                    helperStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Activo'),
                  value: activo,
                  onChanged: (v) => setDialogState(() => activo = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nombreController.text.trim().isEmpty) return;

                      setDialogState(() => isLoading = true);

                      try {
                        final stripePriceId =
                            stripePriceIdController.text.trim().isEmpty
                            ? null
                            : stripePriceIdController.text.trim();

                        if (plan == null) {
                          final nuevoPlan = PlanModel(
                            id: '',
                            nombre: nombreController.text.trim(),
                            descripcion:
                                descripcionController.text.trim().isEmpty
                                ? null
                                : descripcionController.text.trim(),
                            precio: double.tryParse(precioController.text) ?? 0,
                            maxEmpleados:
                                int.tryParse(maxEmpleadosController.text) ?? 5,
                            maxClientes:
                                int.tryParse(maxClientesController.text) ?? 100,
                            activo: activo,
                            createdAt: DateTime.now(),
                            stripePriceId: stripePriceId,
                            tipoFacturacion: tipoFacturacion,
                          );
                          await _planesService.crearPlan(nuevoPlan);
                        } else {
                          await _planesService.actualizarPlan(plan.id, {
                            'nombre': nombreController.text.trim(),
                            'descripcion':
                                descripcionController.text.trim().isEmpty
                                ? null
                                : descripcionController.text.trim(),
                            'precio':
                                double.tryParse(precioController.text) ?? 0,
                            'max_empleados':
                                int.tryParse(maxEmpleadosController.text) ?? 5,
                            'max_clientes':
                                int.tryParse(maxClientesController.text) ?? 100,
                            'activo': activo,
                            'stripe_price_id': stripePriceId,
                            'tipo_facturacion': tipoFacturacion.name,
                          });
                        }

                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        _loadData();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            this.context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(PlanModel plan) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Plan'),
        content: Text('¿Estás seguro de eliminar el plan "${plan.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _planesService.eliminarPlan(plan.id);
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Gestión de Planes'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _planes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.subscriptions,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text('No hay planes creados'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _mostrarFormularioPlan(),
                            icon: const Icon(Icons.add),
                            label: const Text('Crear Plan'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _planes.length,
                      itemBuilder: (context, index) =>
                          _buildPlanCard(_planes[index]),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioPlan(),
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlanCard(PlanModel plan) {
    final color = plan.precio == 0
        ? Colors.grey
        : plan.precio < 50
        ? Colors.blue
        : Colors.purple;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (plan.descripcion != null)
                      Text(
                        plan.descripcion!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      plan.precioLabel,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLimitItem(
                      Icons.people,
                      '${plan.maxEmpleados}',
                      'Empleados',
                    ),
                    _buildLimitItem(
                      Icons.person,
                      '${plan.maxClientes}',
                      'Clientes',
                    ),
                    _buildLimitItem(
                      plan.activo ? Icons.check_circle : Icons.cancel,
                      plan.activo ? 'Activo' : 'Inactivo',
                      'Estado',
                      color: plan.activo ? AppColors.success : AppColors.error,
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _mostrarFormularioPlan(plan),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmarEliminar(plan),
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitItem(
    IconData icon,
    String value,
    String label, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
