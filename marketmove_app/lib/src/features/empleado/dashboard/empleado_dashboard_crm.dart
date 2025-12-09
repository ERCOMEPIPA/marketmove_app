import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/clientes_service.dart';
import '../../../shared/services/deals_service.dart';
import '../../../shared/services/actividades_service.dart';
import '../../../shared/constants/app_colors.dart';

/// Dashboard personal del empleado (CRM)
/// Muestra métricas personales, tareas pendientes y acceso rápido
class EmpleadoDashboardCRM extends StatefulWidget {
  const EmpleadoDashboardCRM({super.key});

  @override
  State<EmpleadoDashboardCRM> createState() => _EmpleadoDashboardCRMState();
}

class _EmpleadoDashboardCRMState extends State<EmpleadoDashboardCRM> {
  final _clientesService = ClientesService();
  final _dealsService = DealsService();
  final _actividadesService = ActividadesService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 0);

  String? _empleadoId;
  List<ClienteModel> _misClientes = [];
  List<DealModel> _misDeals = [];
  List<ActividadModel> _tareasPendientes = [];
  ActividadStats? _actividadStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _empleadoId = Supabase.instance.client.auth.currentUser?.id;
    _loadData();
  }

  Future<void> _loadData() async {
    if (_empleadoId == null) return;

    setState(() => _isLoading = true);
    try {
      final clientes = await _clientesService.getClientesAsignados(
        _empleadoId!,
      );
      final deals = await _dealsService.getDealsAsignados(_empleadoId!);
      final tareas = await _actividadesService.getTareasPendientes(
        _empleadoId!,
      );
      final stats = await _actividadesService.getEstadisticas(
        _empleadoId!,
        desde: DateTime.now().subtract(const Duration(days: 30)),
      );

      setState(() {
        _misClientes = clientes;
        _misDeals = deals;
        _tareasPendientes = tareas;
        _actividadStats = stats;
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

  @override
  Widget build(BuildContext context) {
    final userName =
        Supabase.instance.client.auth.currentUser?.email?.split('@').first ??
        'Usuario';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
                          Text(
                            '¡Hola, $userName!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tu resumen de hoy',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Métricas rápidas
                          Row(
                            children: [
                              _buildMetricCard(
                                'Mis Clientes',
                                '${_misClientes.length}',
                                Icons.people,
                                AppColors.info,
                              ),
                              const SizedBox(width: 12),
                              _buildMetricCard(
                                'Mis Deals',
                                '${_misDeals.length}',
                                Icons.handshake,
                                AppColors.success,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildMetricCard(
                                'Valor Pipeline',
                                _currencyFormat.format(
                                  _misDeals.fold(
                                    0.0,
                                    (sum, d) => sum + d.valor,
                                  ),
                                ),
                                Icons.attach_money,
                                AppColors.warning,
                              ),
                              const SizedBox(width: 12),
                              _buildMetricCard(
                                'Tareas Pendientes',
                                '${_tareasPendientes.length}',
                                Icons.task_alt,
                                Colors.orange,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Actividad del mes
                          if (_actividadStats != null) ...[
                            const Text(
                              'Mi Actividad (30 días)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildActivityStat(
                                    '📞',
                                    'Llamadas',
                                    _actividadStats!.llamadas,
                                  ),
                                  _buildActivityStat(
                                    '📧',
                                    'Emails',
                                    _actividadStats!.emails,
                                  ),
                                  _buildActivityStat(
                                    '📅',
                                    'Reuniones',
                                    _actividadStats!.reuniones,
                                  ),
                                  _buildActivityStat(
                                    '✅',
                                    'Completadas',
                                    _actividadStats!.completadas,
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Tareas pendientes
                          if (_tareasPendientes.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tareas Pendientes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // TODO: Navegar a lista completa
                                  },
                                  child: const Text('Ver todas'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._tareasPendientes
                                .take(5)
                                .map((tarea) => _buildTareaCard(tarea)),
                          ],

                          const SizedBox(height: 24),

                          // Mis deals activos
                          if (_misDeals.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Mis Deals Activos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // TODO: Navegar a mis deals
                                  },
                                  child: const Text('Ver todos'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._misDeals
                                .where(
                                  (d) =>
                                      d.etapa != 'ganado' &&
                                      d.etapa != 'perdido',
                                )
                                .take(5)
                                .map((deal) => _buildDealCard(deal)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityStat(String emoji, String label, int count) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTareaCard(ActividadModel tarea) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(TipoActividad.icono(tarea.tipo)),
        ),
        title: Text(
          tarea.titulo,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: tarea.clienteNombre != null
            ? Text(tarea.clienteNombre!)
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          onPressed: () async {
            await _actividadesService.completarActividad(tarea.id, null);
            _loadData();
          },
        ),
      ),
    );
  }

  Widget _buildDealCard(DealModel deal) {
    final color = _parseColor(EtapasPipeline.color(deal.etapa));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          deal.titulo,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(EtapasPipeline.nombre(deal.etapa)),
        trailing: Text(
          _currencyFormat.format(deal.valor),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.success,
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }
}
