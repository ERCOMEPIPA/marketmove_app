import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/services/superadmin_service.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/constants/app_colors.dart';
import '../../shared/models/user_profile_model.dart';

/// Dashboard para Superadmin
/// Muestra lista de todos los negocios (admins) registrados y métricas globales
class SuperadminDashboard extends StatefulWidget {
  const SuperadminDashboard({super.key});

  @override
  State<SuperadminDashboard> createState() => _SuperadminDashboardState();
}

class _SuperadminDashboardState extends State<SuperadminDashboard> {
  final _superadminService = SuperadminService();
  final _currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);

  List<UserProfileModel> _admins = [];
  GlobalMetrics? _metrics;
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
      final admins = await _superadminService.getAllAdmins();
      final metrics = await _superadminService.getGlobalMetrics();

      setState(() {
        _admins = admins;
        _metrics = metrics;
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
        body: ErrorState(message: _error!, onRetry: _loadData),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                'Panel Superadmin',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gestión de todos los negocios registrados',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Métricas Globales
              _buildGlobalMetrics(),
              const SizedBox(height: 32),

              // Lista de Negocios
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Negocios Registrados (${_admins.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_admins.isEmpty)
                const EmptyState(
                  icon: Icons.business,
                  title: 'No hay negocios registrados',
                  subtitle: 'Los negocios aparecerán aquí cuando se registren',
                )
              else
                _buildBusinessList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalMetrics() {
    final metrics = _metrics!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Métricas Globales',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Negocios',
                  '${metrics.totalNegocios}',
                  Icons.business,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricItem(
                  'Ventas Totales',
                  _currencyFormat.format(metrics.totalVentasGlobales),
                  Icons.attach_money,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricItem(
            'Productos Totales',
            '${metrics.totalProductos}',
            Icons.inventory_2,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _admins.length,
      itemBuilder: (context, index) {
        final admin = _admins[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              child: const Icon(Icons.business, color: Color(0xFF6366F1)),
            ),
            title: Text(
              admin.nombreNegocio ?? admin.email,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(admin.email, style: const TextStyle(fontSize: 12)),
                if (admin.telefono != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tel: ${admin.telefono}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Chip(
              label: Text(
                'ID: ${admin.id.substring(0, 8)}',
                style: const TextStyle(fontSize: 10),
              ),
              backgroundColor: AppColors.surfaceVariant,
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
