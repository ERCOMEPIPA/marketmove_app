import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/clientes_service.dart';
import '../../../shared/services/deals_service.dart';
import '../../../shared/services/limites_service.dart';
import '../../../shared/services/export_service.dart';
import '../../../shared/constants/app_colors.dart';

/// Pantalla de gestión de clientes para Dueños
class ClientesScreen extends StatefulWidget {
  final String negocioId;

  const ClientesScreen({super.key, required this.negocioId});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _clientesService = ClientesService();
  final _dealsService = DealsService();
  final _limitesService = LimitesService();
  final _exportService = ExportService();
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 0);

  List<ClienteModel> _clientes = [];
  List<ClienteModel> _clientesFiltrados = [];
  Map<String, int> _estadisticas = {};
  PlanLimites? _limites;
  bool _isLoading = true;
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final clientes = await _clientesService.getClientes(widget.negocioId);
      final stats = await _clientesService.getEstadisticas(widget.negocioId);
      final limites = await _limitesService.getLimitesDueno(widget.negocioId);

      setState(() {
        _clientes = clientes;
        _clientesFiltrados = clientes;
        _estadisticas = stats;
        _limites = limites;
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

  void _filtrarClientes(String query) {
    setState(() {
      _clientesFiltrados = _clientes.where((c) {
        final matchQuery =
            query.isEmpty ||
            c.nombre.toLowerCase().contains(query.toLowerCase()) ||
            (c.email?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (c.empresa?.toLowerCase().contains(query.toLowerCase()) ?? false);

        final matchEstado = _filtroEstado == null || c.estado == _filtroEstado;

        return matchQuery && matchEstado;
      }).toList();
    });
  }

  void _mostrarFormularioCliente([ClienteModel? cliente]) async {
    // Si es nuevo cliente, validar límites
    if (cliente == null) {
      final validacion = await _limitesService.puedeAgregarCliente(
        widget.negocioId,
      );
      if (!validacion.permitido) {
        _mostrarAlertaLimite(validacion.mensaje);
        return;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _ClienteFormDialog(
        negocioId: widget.negocioId,
        cliente: cliente,
        onSave: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  void _mostrarAlertaLimite(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Límite Alcanzado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensaje),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Contacta al administrador para actualizar tu plan.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(ClienteModel cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cliente'),
        content: Text('¿Estás seguro de eliminar a "${cliente.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _clientesService.eliminarCliente(cliente.id);
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cliente eliminado'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
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

  /// Crear un deal desde el detalle del cliente con el cliente pre-seleccionado
  void _crearDealDesdeCliente(ClienteModel cliente) {
    final tituloController = TextEditingController(
      text: 'Deal con ${cliente.nombre}',
    );
    final valorController = TextEditingController(
      text: cliente.valorEstimado.toStringAsFixed(0),
    );
    final descripcionController = TextEditingController();
    String etapa = EtapasPipeline.prospecto;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Deal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cliente pre-seleccionado
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cliente',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              cliente.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título del Deal *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valorController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Valor estimado (€)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.euro),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: etapa,
                  decoration: const InputDecoration(
                    labelText: 'Etapa inicial',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.view_kanban),
                  ),
                  items: EtapasPipeline.activas.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(EtapasPipeline.nombre(e)),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => etapa = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descripcionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
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
                      if (tituloController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El título es requerido'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final deal = DealModel(
                          id: '',
                          negocioId: widget.negocioId,
                          clienteId: cliente.id,
                          titulo: tituloController.text.trim(),
                          descripcion: descripcionController.text.trim().isEmpty
                              ? null
                              : descripcionController.text.trim(),
                          valor: double.tryParse(valorController.text) ?? 0,
                          etapa: etapa,
                          probabilidad: EtapasPipeline.probabilidadDefecto(
                            etapa,
                          ),
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );

                        await _dealsService.crearDeal(deal);

                        if (dialogContext.mounted) Navigator.pop(dialogContext);

                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Deal "${deal.titulo}" creado'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear Deal'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Clientes',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${_clientes.length} registros',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Botón exportar CSV
                            FloatingActionButton.small(
                              heroTag: 'exportClientes',
                              onPressed: _clientes.isEmpty
                                  ? null
                                  : () {
                                      _exportService.exportarClientesCSV(
                                        _clientes,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Exportando clientes a CSV...',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    },
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: Icon(
                                Icons.download,
                                color: _clientes.isEmpty
                                    ? Colors.grey
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Botón añadir cliente
                            FloatingActionButton(
                              heroTag: 'addCliente',
                              onPressed: () => _mostrarFormularioCliente(),
                              backgroundColor: Colors.white,
                              child: Icon(Icons.add, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Barra de búsqueda
                    TextField(
                      controller: _searchController,
                      onChanged: _filtrarClientes,
                      decoration: InputDecoration(
                        hintText: 'Buscar clientes...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    // Barra de uso del plan
                    if (_limites != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Plan: ${_limites!.planNombre}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${_limites!.clientesActuales}/${_limites!.maxClientes} clientes',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _limites!.porcentajeClientes.clamp(
                                  0.0,
                                  1.0,
                                ),
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _limites!.porcentajeClientes > 0.9
                                      ? Colors.red[300]!
                                      : _limites!.porcentajeClientes > 0.7
                                      ? Colors.orange[300]!
                                      : Colors.white,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Estadísticas rápidas
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildStatChip('Todos', null, _clientes.length),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Leads',
                      EstadoCliente.lead,
                      _estadisticas[EstadoCliente.lead] ?? 0,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      'Clientes',
                      EstadoCliente.cliente,
                      _estadisticas[EstadoCliente.cliente] ?? 0,
                    ),
                  ],
                ),
              ),
            ),

            // Lista de clientes
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_clientesFiltrados.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay clientes',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _mostrarFormularioCliente(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Cliente'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildClienteCard(_clientesFiltrados[index]),
                    childCount: _clientesFiltrados.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String? estado, int count) {
    final isSelected = _filtroEstado == estado;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filtroEstado = estado;
          _filtrarClientes(_searchController.text);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildClienteCard(ClienteModel cliente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetalleCliente(cliente),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: _getColorEstado(
                  cliente.estado,
                ).withOpacity(0.1),
                child: Text(
                  cliente.nombre.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: _getColorEstado(cliente.estado),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (cliente.empresa != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        cliente.empresa!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getColorEstado(
                              cliente.estado,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            EstadoCliente.nombre(cliente.estado),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _getColorEstado(cliente.estado),
                            ),
                          ),
                        ),
                        if (cliente.valorEstimado > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            _currencyFormat.format(cliente.valorEstimado),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Acciones
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'editar':
                      _mostrarFormularioCliente(cliente);
                      break;
                    case 'eliminar':
                      _confirmarEliminar(cliente);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.red),
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

  Color _getColorEstado(String estado) {
    switch (estado) {
      case EstadoCliente.lead:
        return Colors.grey;
      case EstadoCliente.contactado:
        return Colors.blue;
      case EstadoCliente.calificado:
        return Colors.purple;
      case EstadoCliente.cliente:
        return AppColors.success;
      case EstadoCliente.inactivo:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _mostrarDetalleCliente(ClienteModel cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getColorEstado(
                      cliente.estado,
                    ).withOpacity(0.1),
                    child: Text(
                      cliente.nombre.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: _getColorEstado(cliente.estado),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombre,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (cliente.empresa != null)
                          Text(
                            cliente.empresa!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getColorEstado(cliente.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      EstadoCliente.nombre(cliente.estado),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _getColorEstado(cliente.estado),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Info de contacto
              _buildInfoRow(Icons.email, 'Email', cliente.email ?? 'Sin email'),
              _buildInfoRow(
                Icons.phone,
                'Teléfono',
                cliente.telefono ?? 'Sin teléfono',
              ),
              _buildInfoRow(Icons.work, 'Cargo', cliente.cargo ?? 'Sin cargo'),
              _buildInfoRow(
                Icons.source,
                'Fuente',
                cliente.fuente ?? 'Sin fuente',
              ),
              _buildInfoRow(
                Icons.attach_money,
                'Valor Estimado',
                _currencyFormat.format(cliente.valorEstimado),
              ),

              if (cliente.notas != null && cliente.notas!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notas',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(cliente.notas!),
                ),
              ],

              const SizedBox(height: 24),

              // Acciones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _mostrarFormularioCliente(cliente);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _crearDealDesdeCliente(cliente);
                      },
                      icon: const Icon(Icons.add_business),
                      label: const Text('Crear Deal'),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Diálogo para crear/editar cliente
class _ClienteFormDialog extends StatefulWidget {
  final String negocioId;
  final ClienteModel? cliente;
  final VoidCallback onSave;

  const _ClienteFormDialog({
    required this.negocioId,
    this.cliente,
    required this.onSave,
  });

  @override
  State<_ClienteFormDialog> createState() => _ClienteFormDialogState();
}

class _ClienteFormDialogState extends State<_ClienteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clientesService = ClientesService();

  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _empresaController;
  late TextEditingController _cargoController;
  late TextEditingController _valorController;
  late TextEditingController _notasController;

  String _estado = EstadoCliente.lead;
  String? _fuente;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente?.nombre);
    _emailController = TextEditingController(text: widget.cliente?.email);
    _telefonoController = TextEditingController(text: widget.cliente?.telefono);
    _empresaController = TextEditingController(text: widget.cliente?.empresa);
    _cargoController = TextEditingController(text: widget.cliente?.cargo);
    _valorController = TextEditingController(
      text: widget.cliente?.valorEstimado.toStringAsFixed(0) ?? '0',
    );
    _notasController = TextEditingController(text: widget.cliente?.notas);
    _estado = widget.cliente?.estado ?? EstadoCliente.lead;
    _fuente = widget.cliente?.fuente;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _empresaController.dispose();
    _cargoController.dispose();
    _valorController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.cliente == null) {
        // Crear nuevo
        final cliente = ClienteModel(
          id: '',
          negocioId: widget.negocioId,
          nombre: _nombreController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          telefono: _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim(),
          empresa: _empresaController.text.trim().isEmpty
              ? null
              : _empresaController.text.trim(),
          cargo: _cargoController.text.trim().isEmpty
              ? null
              : _cargoController.text.trim(),
          estado: _estado,
          fuente: _fuente,
          valorEstimado: double.tryParse(_valorController.text) ?? 0,
          notas: _notasController.text.trim().isEmpty
              ? null
              : _notasController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _clientesService.crearCliente(cliente);
      } else {
        // Actualizar
        await _clientesService.actualizarCliente(widget.cliente!.id, {
          'nombre': _nombreController.text.trim(),
          'email': _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          'telefono': _telefonoController.text.trim().isEmpty
              ? null
              : _telefonoController.text.trim(),
          'empresa': _empresaController.text.trim().isEmpty
              ? null
              : _empresaController.text.trim(),
          'cargo': _cargoController.text.trim().isEmpty
              ? null
              : _cargoController.text.trim(),
          'estado': _estado,
          'fuente': _fuente,
          'valor_estimado': double.tryParse(_valorController.text) ?? 0,
          'notas': _notasController.text.trim().isEmpty
              ? null
              : _notasController.text.trim(),
        });
      }

      widget.onSave();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.cliente == null ? 'Nuevo Cliente' : 'Editar Cliente'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _empresaController,
                  decoration: const InputDecoration(
                    labelText: 'Empresa',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cargoController,
                  decoration: const InputDecoration(
                    labelText: 'Cargo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _estado,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                        ),
                        items: EstadoCliente.todos
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(EstadoCliente.nombre(e)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _estado = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _valorController,
                        decoration: const InputDecoration(
                          labelText: 'Valor €',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _fuente,
                  decoration: const InputDecoration(
                    labelText: 'Fuente',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin fuente'),
                    ),
                    const DropdownMenuItem(value: 'web', child: Text('Web')),
                    const DropdownMenuItem(
                      value: 'referido',
                      child: Text('Referido'),
                    ),
                    const DropdownMenuItem(
                      value: 'llamada',
                      child: Text('Llamada'),
                    ),
                    const DropdownMenuItem(
                      value: 'evento',
                      child: Text('Evento'),
                    ),
                    const DropdownMenuItem(value: 'otro', child: Text('Otro')),
                  ],
                  onChanged: (v) => setState(() => _fuente = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notasController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
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
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
