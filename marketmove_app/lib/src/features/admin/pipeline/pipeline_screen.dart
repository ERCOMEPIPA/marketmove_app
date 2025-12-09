import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/services/deals_service.dart';
import '../../../shared/services/clientes_service.dart';
import '../../../shared/constants/app_colors.dart';

/// Pantalla de Pipeline de Ventas para Dueños
class PipelineScreen extends StatefulWidget {
  final String negocioId;

  const PipelineScreen({super.key, required this.negocioId});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  final _dealsService = DealsService();
  final _clientesService = ClientesService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 0);

  Map<String, List<DealModel>> _dealsPorEtapa = {};
  List<ClienteModel> _clientes = [];
  PipelineStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final deals = await _dealsService.getDealsPorEtapa(widget.negocioId);
      final stats = await _dealsService.getEstadisticas(widget.negocioId);
      final clientes = await _clientesService.getClientes(widget.negocioId);

      setState(() {
        _dealsPorEtapa = deals;
        _stats = stats;
        _clientes = clientes;
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

  void _mostrarFormularioDeal([DealModel? deal]) {
    showDialog(
      context: context,
      builder: (context) => _DealFormDialog(
        negocioId: widget.negocioId,
        deal: deal,
        clientes: _clientes,
        onSave: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // Header con stats
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8B5CF6),
                            const Color(0xFF6366F1),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Pipeline de Ventas',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              FloatingActionButton.small(
                                heroTag: 'addDeal',
                                onPressed: () => _mostrarFormularioDeal(),
                                backgroundColor: Colors.white,
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Stats row
                          if (_stats != null)
                            Row(
                              children: [
                                _buildStatCard(
                                  'Total Pipeline',
                                  _currencyFormat.format(_stats!.totalValor),
                                  Icons.trending_up,
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  'Ponderado',
                                  _currencyFormat.format(
                                    _stats!.valorPonderado,
                                  ),
                                  Icons.calculate,
                                ),
                                const SizedBox(width: 12),
                                _buildStatCard(
                                  'Conversión',
                                  '${_stats!.tasaConversion.toStringAsFixed(1)}%',
                                  Icons.check_circle,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Pipeline columns
                  SliverFillRemaining(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: EtapasPipeline.activas.map((etapa) {
                          return _buildPipelineColumn(etapa);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineColumn(String etapa) {
    final deals = _dealsPorEtapa[etapa] ?? [];
    final color = _parseColor(EtapasPipeline.color(etapa));
    final totalValor = deals.fold(0.0, (sum, d) => sum + d.valor);

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header de columna
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: color, width: 3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      EtapasPipeline.nombre(etapa),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${deals.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Total de la columna
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey[100],
            child: Text(
              _currencyFormat.format(totalValor),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
          // Lista de deals
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: deals.isEmpty
                  ? Center(
                      child: Text(
                        'Sin deals',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: deals.length,
                      itemBuilder: (context, index) =>
                          _buildDealCard(deals[index], color),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(DealModel deal, Color etapaColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => _mostrarDetalleDeal(deal),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deal.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (deal.clienteNombre != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        deal.clienteNombre!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currencyFormat.format(deal.valor),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: etapaColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${deal.probabilidad}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: etapaColor,
                      ),
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

  void _mostrarDetalleDeal(DealModel deal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.titulo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (deal.clienteNombre != null)
                          Text(
                            deal.clienteNombre!,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormat.format(deal.valor),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Etapa actual
              Row(
                children: [
                  const Text(
                    'Etapa actual:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _parseColor(
                        EtapasPipeline.color(deal.etapa),
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      EtapasPipeline.nombre(deal.etapa),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _parseColor(EtapasPipeline.color(deal.etapa)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Mover etapa
              const Text(
                'Mover a:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EtapasPipeline.todas.map((etapa) {
                  final isCurrentEtapa = etapa == deal.etapa;
                  final color = _parseColor(EtapasPipeline.color(etapa));

                  return ActionChip(
                    label: Text(EtapasPipeline.nombre(etapa)),
                    backgroundColor: isCurrentEtapa
                        ? color
                        : color.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: isCurrentEtapa ? Colors.white : color,
                      fontWeight: FontWeight.w500,
                    ),
                    onPressed: isCurrentEtapa
                        ? null
                        : () async {
                            Navigator.pop(context);
                            if (etapa == EtapasPipeline.perdido) {
                              _mostrarDialogoPerdido(deal);
                            } else {
                              await _dealsService.moverEtapa(deal.id, etapa);
                              _loadData();
                            }
                          },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Acciones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _mostrarFormularioDeal(deal);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        _confirmarEliminar(deal);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Eliminar',
                        style: TextStyle(color: Colors.red),
                      ),
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

  void _mostrarDialogoPerdido(DealModel deal) {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Por qué se perdió?'),
        content: TextField(
          controller: motivoController,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dealsService.cerrarPerdido(deal.id, motivoController.text);
              _loadData();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Marcar como Perdido'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(DealModel deal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Deal'),
        content: Text('¿Estás seguro de eliminar "${deal.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dealsService.eliminarDeal(deal.id);
              _loadData();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }
}

/// Diálogo para crear/editar deal
class _DealFormDialog extends StatefulWidget {
  final String negocioId;
  final DealModel? deal;
  final List<ClienteModel> clientes;
  final VoidCallback onSave;

  const _DealFormDialog({
    required this.negocioId,
    this.deal,
    required this.clientes,
    required this.onSave,
  });

  @override
  State<_DealFormDialog> createState() => _DealFormDialogState();
}

class _DealFormDialogState extends State<_DealFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dealsService = DealsService();

  late TextEditingController _tituloController;
  late TextEditingController _valorController;
  late TextEditingController _descripcionController;

  String? _clienteId;
  String _etapa = EtapasPipeline.prospecto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.deal?.titulo);
    _valorController = TextEditingController(
      text: widget.deal?.valor.toStringAsFixed(0) ?? '0',
    );
    _descripcionController = TextEditingController(
      text: widget.deal?.descripcion,
    );
    _clienteId = widget.deal?.clienteId;
    _etapa = widget.deal?.etapa ?? EtapasPipeline.prospecto;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.deal == null) {
        final deal = DealModel(
          id: '',
          negocioId: widget.negocioId,
          clienteId: _clienteId,
          titulo: _tituloController.text.trim(),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          valor: double.tryParse(_valorController.text) ?? 0,
          etapa: _etapa,
          probabilidad: EtapasPipeline.probabilidadDefecto(_etapa),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _dealsService.crearDeal(deal);
      } else {
        await _dealsService.actualizarDeal(widget.deal!.id, {
          'titulo': _tituloController.text.trim(),
          'descripcion': _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
          'valor': double.tryParse(_valorController.text) ?? 0,
          'cliente_id': _clienteId,
          'etapa': _etapa,
          'probabilidad': EtapasPipeline.probabilidadDefecto(_etapa),
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
      title: Text(widget.deal == null ? 'Nuevo Deal' : 'Editar Deal'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorController,
                  decoration: const InputDecoration(
                    labelText: 'Valor €',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _clienteId,
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin cliente'),
                    ),
                    ...widget.clientes.map(
                      (c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _clienteId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _etapa,
                  decoration: const InputDecoration(
                    labelText: 'Etapa',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.view_kanban),
                  ),
                  items: EtapasPipeline.activas
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(EtapasPipeline.nombre(e)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _etapa = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
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
