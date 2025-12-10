import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/deals_service.dart';
import '../../../shared/constants/app_colors.dart';

/// Pantalla de deals asignados para empleados
/// Vista restringida: solo puede ver deals asignados a él
class MisDealsScreen extends StatefulWidget {
  const MisDealsScreen({super.key});

  @override
  State<MisDealsScreen> createState() => _MisDealsScreenState();
}

class _MisDealsScreenState extends State<MisDealsScreen> {
  final _dealsService = DealsService();
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 0);

  String? _empleadoId;
  List<DealModel> _deals = [];
  List<DealModel> _dealsFiltrados = [];
  String _filtroEtapa = 'todos';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _empleadoId = user.id;
    _loadData();
  }

  Future<void> _loadData() async {
    if (_empleadoId == null) return;

    setState(() => _isLoading = true);
    try {
      final deals = await _dealsService.getDealsAsignados(_empleadoId!);

      setState(() {
        _deals = deals;
        _aplicarFiltros();
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

  void _aplicarFiltros() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _dealsFiltrados = _deals.where((d) {
        final matchQuery =
            query.isEmpty ||
            d.titulo.toLowerCase().contains(query) ||
            (d.clienteNombre?.toLowerCase().contains(query) ?? false);

        final matchEtapa = _filtroEtapa == 'todos' || d.etapa == _filtroEtapa;

        return matchQuery && matchEtapa;
      }).toList();
    });
  }

  double get _valorTotal => _dealsFiltrados.fold(0, (sum, d) => sum + d.valor);

  int get _dealsActivos => _deals
      .where(
        (d) =>
            d.etapa != EtapasPipeline.ganado &&
            d.etapa != EtapasPipeline.perdido,
      )
      .length;

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
                      AppColors.success,
                      AppColors.success.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mis Deals',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_dealsActivos deals activos • ${_currencyFormat.format(_valorTotal)} en pipeline',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 16),
                    // Barra de búsqueda
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => _aplicarFiltros(),
                      decoration: InputDecoration(
                        hintText: 'Buscar por título o cliente...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filtros por etapa
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildFiltroChip('Todos', 'todos'),
                    const SizedBox(width: 8),
                    ...EtapasPipeline.activas.map(
                      (etapa) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFiltroChip(
                          EtapasPipeline.nombre(etapa),
                          etapa,
                        ),
                      ),
                    ),
                    _buildFiltroChip('Ganados', EtapasPipeline.ganado),
                    const SizedBox(width: 8),
                    _buildFiltroChip('Perdidos', EtapasPipeline.perdido),
                  ],
                ),
              ),
            ),

            // Lista de Deals
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_dealsFiltrados.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.handshake_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _deals.isEmpty
                            ? 'No tienes deals asignados'
                            : 'No hay deals con este filtro',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                    (context, index) => _buildDealCard(_dealsFiltrados[index]),
                    childCount: _dealsFiltrados.length,
                  ),
                ),
              ),

            // Espacio al final
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String label, String valor) {
    final isSelected = _filtroEtapa == valor;
    final color = valor == 'todos'
        ? AppColors.primary
        : _parseColor(EtapasPipeline.color(valor));

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filtroEtapa = valor);
        _aplicarFiltros();
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDealCard(DealModel deal) {
    final etapaColor = _parseColor(EtapasPipeline.color(deal.etapa));
    final isCerrado =
        deal.etapa == EtapasPipeline.ganado ||
        deal.etapa == EtapasPipeline.perdido;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetalleDeal(deal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Indicador de etapa
                  Container(
                    width: 4,
                    height: 50,
                    decoration: BoxDecoration(
                      color: etapaColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (deal.clienteNombre != null)
                          Text(
                            deal.clienteNombre!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(deal.valor),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: etapaColor,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${deal.probabilidad}%',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: etapaColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      EtapasPipeline.nombre(deal.etapa),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: etapaColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isCerrado) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      ),
                      onPressed: () => _cerrarDealGanado(deal),
                      tooltip: 'Marcar como ganado',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: () => _cerrarDealPerdido(deal),
                      tooltip: 'Marcar como perdido',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
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

              // Título y valor
              Text(
                deal.titulo,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currencyFormat.format(deal.valor),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),

              const SizedBox(height: 24),

              // Información
              _buildInfoRow(
                Icons.person,
                'Cliente',
                deal.clienteNombre ?? 'Sin cliente',
              ),
              _buildInfoRow(
                Icons.view_kanban,
                'Etapa',
                EtapasPipeline.nombre(deal.etapa),
              ),
              _buildInfoRow(
                Icons.percent,
                'Probabilidad',
                '${deal.probabilidad}%',
              ),
              if (deal.fechaCierreEstimada != null)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Cierre estimado',
                  DateFormat('dd/MM/yyyy').format(deal.fechaCierreEstimada!),
                ),

              if (deal.descripcion != null && deal.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Descripción',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(deal.descripcion!),
                ),
              ],

              const SizedBox(height: 24),

              // Acciones de cambio de etapa
              if (deal.etapa != EtapasPipeline.ganado &&
                  deal.etapa != EtapasPipeline.perdido) ...[
                const Text(
                  'Mover a:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EtapasPipeline.todas.map((etapa) {
                    final isSelected = etapa == deal.etapa;
                    final color = _parseColor(EtapasPipeline.color(etapa));
                    return FilterChip(
                      label: Text(EtapasPipeline.nombre(etapa)),
                      selected: isSelected,
                      selectedColor: color.withOpacity(0.3),
                      onSelected: isSelected
                          ? null
                          : (_) async {
                              Navigator.pop(context);
                              if (etapa == EtapasPipeline.perdido) {
                                _cerrarDealPerdido(deal);
                              } else {
                                await _dealsService.moverEtapa(deal.id, etapa);
                                _loadData();
                              }
                            },
                    );
                  }).toList(),
                ),
              ],
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

  Future<void> _cerrarDealGanado(DealModel deal) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.celebration, color: AppColors.success, size: 48),
        title: const Text('¡Felicidades!'),
        content: Text('¿Confirmar que el deal "${deal.titulo}" fue ganado?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('¡Sí, Ganado!'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _dealsService.cerrarGanado(deal.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡${deal.titulo} cerrado como ganado! 🎉'),
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
    }
  }

  Future<void> _cerrarDealPerdido(DealModel deal) async {
    final motivoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.sentiment_dissatisfied,
          color: AppColors.error,
          size: 48,
        ),
        title: const Text('Marcar como Perdido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Por qué se perdió "${deal.titulo}"?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Marcar Perdido'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _dealsService.cerrarPerdido(
          deal.id,
          motivoController.text.trim(),
        );
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deal marcado como perdido'),
              backgroundColor: AppColors.error,
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
    }
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }
}
