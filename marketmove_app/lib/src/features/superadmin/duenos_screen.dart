import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/services/planes_service.dart';
import '../../shared/constants/app_colors.dart';

/// Pantalla para gestionar todos los dueños/negocios (Superadmin)
class DuenosScreen extends StatefulWidget {
  const DuenosScreen({super.key});

  @override
  State<DuenosScreen> createState() => _DuenosScreenState();
}

class _DuenosScreenState extends State<DuenosScreen> {
  final _superadminService = SuperadminServiceExtended();
  final _planesService = PlanesService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 0);

  List<DuenoInfo> _duenos = [];
  List<PlanModel> _planes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final duenos = await _superadminService.getAllDuenos();
      final planes = await _planesService.getPlanes();
      setState(() {
        _duenos = duenos;
        _planes = planes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<DuenoInfo> get _filteredDuenos {
    if (_searchQuery.isEmpty) return _duenos;
    return _duenos.where((d) {
      final query = _searchQuery.toLowerCase();
      return (d.nombreNegocio?.toLowerCase().contains(query) ?? false) ||
          d.email.toLowerCase().contains(query);
    }).toList();
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
                  // Header
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Botón de retroceso
                          Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    context.go('/superadmin/dashboard'),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                tooltip: 'Volver',
                              ),
                              const Expanded(
                                child: Text(
                                  'Gestión de Negocios',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_duenos.length} negocios registrados',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Buscador
                          TextField(
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre o email...',
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

                  // Lista de negocios
                  if (_filteredDuenos.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: Text('No se encontraron negocios')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildDuenoCard(_filteredDuenos[index]),
                          childCount: _filteredDuenos.length,
                        ),
                      ),
                    ),
                ],
              ),
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetalleDueno(dueno),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                child: Text(
                  (dueno.nombreNegocio ?? dueno.email)
                      .substring(0, 1)
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      dueno.email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (dueno.planNombre != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dueno.planNombre!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: estadoColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dueno.suscripcionEstado ?? 'activa',
                            style: TextStyle(
                              fontSize: 11,
                              color: estadoColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    dueno.activo ? Icons.check_circle : Icons.block,
                    color: dueno.activo ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dueno.activo ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 10,
                      color: dueno.activo ? Colors.green : Colors.red,
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

              // Header
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

              // Info
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
                'Estado Suscripción',
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
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                dueno.activo
                                    ? 'Negocio desactivado'
                                    : 'Negocio activado',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
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
