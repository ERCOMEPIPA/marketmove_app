import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/services/planes_service.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/widgets/loading_indicator.dart';

/// Dashboard mejorado para Superadmin
/// Muestra métricas globales, lista de dueños y acceso a gestión
class SuperadminDashboardV2 extends StatefulWidget {
  const SuperadminDashboardV2({super.key});

  @override
  State<SuperadminDashboardV2> createState() => _SuperadminDashboardV2State();
}

class _SuperadminDashboardV2State extends State<SuperadminDashboardV2> {
  final _superadminService = SuperadminServiceExtended();
  final _planesService = PlanesService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 0);

  SuperadminStats? _stats;
  List<DuenoInfo> _duenos = [];
  List<PlanModel> _planes = [];
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
      final stats = await _superadminService.getStats();
      final duenos = await _superadminService.getAllDuenos();
      final planes = await _planesService.getPlanes();

      setState(() {
        _stats = stats;
        _duenos = duenos;
        _planes = planes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con gradiente
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                              'Panel Superadmin',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Control total del CRM',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 28,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Métricas globales
                    if (_stats != null) ...[
                      Row(
                        children: [
                          _buildStatCard(
                            'Negocios',
                            '${_stats!.totalDuenos}',
                            Icons.business,
                            const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Empleados',
                            '${_stats!.totalEmpleados}',
                            Icons.people,
                            Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(
                            'Clientes',
                            '${_stats!.totalClientes}',
                            Icons.person,
                            Colors.teal,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Deals',
                            '${_stats!.totalDeals}',
                            Icons.handshake,
                            Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatCard(
                            'Valor Total',
                            _currencyFormat.format(_stats!.valorTotalDeals),
                            Icons.attach_money,
                            AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Actividades',
                            '${_stats!.totalActividades}',
                            Icons.task_alt,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Acciones rápidas
                    const Text(
                      'Gestión',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.business,
                            title: 'Dueños',
                            subtitle: 'Gestionar negocios',
                            color: const Color(0xFF6366F1),
                            onTap: () => context.push('/superadmin/duenos'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.subscriptions,
                            title: 'Planes',
                            subtitle: 'Suscripciones',
                            color: Colors.orange,
                            onTap: () => context.push('/superadmin/planes'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Planes actuales
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Planes Disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/superadmin/planes'),
                          child: const Text('Gestionar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _planes.length,
                        itemBuilder: (context, index) =>
                            _buildPlanCard(_planes[index]),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Lista de dueños recientes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Negocios Recientes (${_duenos.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/superadmin/duenos'),
                          child: const Text('Ver todos'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._duenos.take(5).map((dueno) => _buildDuenoCard(dueno)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(PlanModel plan) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: plan.precio == 0
              ? [Colors.grey[400]!, Colors.grey[500]!]
              : plan.precio < 50
              ? [Colors.blue[400]!, Colors.blue[600]!]
              : [Colors.purple[400]!, Colors.purple[600]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            plan.nombre,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currencyFormat.format(plan.precio),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${plan.maxEmpleados} empleados',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDuenoCard(DuenoInfo dueno) {
    final estadoColor = dueno.suscripcionEstado == 'activa'
        ? AppColors.success
        : dueno.suscripcionEstado == 'suspendida'
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
          child: Text(
            (dueno.nombreNegocio ?? dueno.email).substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF6366F1),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          dueno.nombreNegocio ?? dueno.email,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            if (dueno.planNombre != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dueno.planNombre!,
                  style: const TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                dueno.suscripcionEstado ?? 'activa',
                style: TextStyle(fontSize: 10, color: estadoColor),
              ),
            ),
          ],
        ),
        trailing: dueno.activo
            ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
            : const Icon(Icons.block, color: Colors.red, size: 20),
        onTap: () => _mostrarDetalleDueno(dueno),
      ),
    );
  }

  void _mostrarDetalleDueno(DuenoInfo dueno) {
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

              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                    child: const Icon(
                      Icons.business,
                      color: Color(0xFF6366F1),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dueno.nombreNegocio ?? 'Sin nombre',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dueno.email,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildInfoRow(Icons.email, 'Email', dueno.email),
              if (dueno.telefono != null)
                _buildInfoRow(Icons.phone, 'Teléfono', dueno.telefono!),
              _buildInfoRow(
                Icons.subscriptions,
                'Plan',
                dueno.planNombre ?? 'Sin plan',
              ),
              _buildInfoRow(
                Icons.paid,
                'Precio',
                _currencyFormat.format(dueno.planPrecio ?? 0),
              ),
              _buildInfoRow(
                Icons.toggle_on,
                'Estado',
                dueno.suscripcionEstado ?? 'activa',
              ),

              const SizedBox(height: 24),

              // Acciones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _superadminService.toggleActivoDueno(
                          dueno.id,
                          !dueno.activo,
                        );
                        _loadData();
                      },
                      icon: Icon(
                        dueno.activo ? Icons.block : Icons.check_circle,
                      ),
                      label: Text(dueno.activo ? 'Desactivar' : 'Activar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _mostrarCambiarPlan(dueno);
                      },
                      icon: const Icon(Icons.upgrade),
                      label: const Text('Cambiar Plan'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final empleados = await _superadminService
                        .getEmpleadosDeDueno(dueno.id);
                    if (mounted) {
                      _mostrarEmpleados(dueno, empleados);
                    }
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Ver Empleados'),
                ),
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

  void _mostrarCambiarPlan(DuenoInfo dueno) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar Plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _planes
              .map(
                (plan) => ListTile(
                  title: Text(plan.nombre),
                  subtitle: Text(_currencyFormat.format(plan.precio)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    Navigator.pop(dialogContext);
                    await PlanesService().asignarPlan(dueno.id, plan.id);
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Plan cambiado a ${plan.nombre}'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _mostrarEmpleados(DuenoInfo dueno, List empleados) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Empleados de ${dueno.nombreNegocio ?? dueno.email}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (empleados.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No hay empleados registrados'),
                ),
              )
            else
              ...empleados.map(
                (emp) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(emp.email),
                  subtitle: Text('ID: ${emp.id.substring(0, 8)}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
